PARKINGYEARS = 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018
CAMERAYEARS = 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018
DATATABLES = parking cameras
METADATA = wardmeta
GEOTABLES = communityareas wards2015
VIEWS = violations blocks blockstotals wardsyearly wardstotals wardstotals5yr wardscommunityareas
DATADIRS = analysis cameras geodata parking processed

# Id,Id2,Geography,Estimate; Total:,Margin of Error; Total:,Estimate; Total: - White alone,Margin of Error; Total: - White alone,Estimate; Total: - Black or African American alone,Margin of Error; Total: - Black or African American alone,Estimate; Total: - American Indian and Alaska Native alone,Margin of Error; Total: - American Indian and Alaska Native alone,Estimate; Total: - Asian alone,Margin of Error; Total: - Asian alone,Estimate; Total: - Native Hawaiian and Other Pacific Islander alone,Margin of Error; Total: - Native Hawaiian and Other Pacific Islander alone,Estimate; Total: - Some other race alone,Margin of Error; Total: - Some other race alone,Estimate; Total: - Two or more races:,Margin of Error; Total: - Two or more races:,Estimate; Total: - Two or more races: - Two races including Some other race,Margin of Error; Total: - Two or more races: - Two races including Some other race,"Estimate; Total: - Two or more races: - Two races excluding Some other race, and three or more races","Margin of Error; Total: - Two or more races: - Two races excluding Some other race, and three or more races" 

.PHONY: all clean bootstrap tables indexes views analysis parking cameras load download_parking download_cameras zip_n_ship
.INTERMEDIATE: processors/salt.txt

all: bootstrap geo parking meta indexes views

bootstrap : create_db tables schema
geo: load_geocodes $(patsubst %, load_geodata_%, $(GEOTABLES))
tables : $(patsubst %, table_%, $(DATATABLES)) $(patsubst %, table_%, $(METADATA))
indexes : $(patsubst %, index_%, $(DATATABLES))
views : $(patsubst %, view_%, $(VIEWS))
meta : $(patsubst %, load_meta_%, $(METADATA))
appgeo : bootstrap load_geodata_wards2015

parking : $(patsubst %, dupes/parking-%.csv, $(PARKINGYEARS))
cameras : $(patsubst %, dupes/cameras-%.csv, $(CAMERAYEARS))

download_parking : $(patsubst %, data/parking/A50951_PARK_Year_%.txt, $(PARKINGYEARS))
download_cameras : $(patsubst %, data/cameras/A50951_AUCM_Year_%.txt, $(CAMERAYEARS))

zip_n_ship : processors/salt.txt upload_zip

drop_views: $(patsubst %, drop_view_%, $(VIEWS))
clean: drop_db $(patsubst %, clean_%, $(DATADIRS)) processors/salt.txt

define check_database
 psql $(ILTICKETS_DB_URL) -c "select 1;" > /dev/null 2>&1
endef


define check_public_relation
 psql $(ILTICKETS_DB_URL) -c "\d public.$*" > /dev/null 2>&1
endef


define check_tmp_parking_relation
 psql $(ILTICKETS_DB_URL) -c "\d tmp.tmp_table_parking_$*" > /dev/null 2>&1
endef


define check_tmp_cameras_relation
 psql $(ILTICKETS_DB_URL) -c "\d tmp.tmp_table_cameras_$*" > /dev/null 2>&1
endef


create_db :
	$(check_database) || psql $(ILTICKETS_DB_ROOT_URL) -c "create database $(ILTICKETS_DB_NAME) lc_collate \"C\" lc_ctype \"C\" template template0" && \
	psql $(ILTICKETS_DB_URL) -c "CREATE EXTENSION IF NOT EXISTS postgis;"


table_% : sql/tables/%.sql
	$(check_public_relation) || psql $(ILTICKETS_DB_URL) -f $<


view_% : sql/views/%.sql
	$(check_public_relation) || psql $(ILTICKETS_DB_URL) -f $<


populate_addresses : sql/geocodes/populate_addresses.sql
	psql $(ILTICKETS_DB_URL) -f $<


index_% : sql/indexes/%.sql
	psql $(ILTICKETS_DB_URL) -f $<


schema :
	psql $(ILTICKETS_DB_URL) -c "CREATE SCHEMA IF NOT EXISTS tmp;"


drop_db :
	psql $(ILTICKETS_DB_ROOT_URL) -c "drop database $(ILTICKETS_DB_NAME);" && rm -f dupes/*


drop_view_% :
	psql $(ILTICKETS_DB_URL) -c "drop table $*;"


data/geodata/communityareas.json :
	curl "https://data.cityofchicago.org/api/geospatial/cauq-8yn6?method=export&format=GeoJSON" > $@


data/geodata/wards2015.json :
	curl "https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON" > $@


data/metadata/wardmeta.csv :
	curl "https://data.cityofchicago.org/api/views/htai-wnw4/rows.csv?accessType=DOWNLOAD" > $@


load_geodata_% : data/geodata/%.json
	$(check_public_relation) || ogr2ogr -f "PostgreSQL" PG:"$(ILTICKETS_DB_STRING)" "$<" -nln $* -overwrite


load_geodata_% : data/geodata/%.shp
	$(check_public_relation) || ogr2ogr -f "PostgreSQL" PG:"$(ILTICKETS_DB_STRING)" "$<" -nln $* -t_srs EPSG:4326 -overwrite


data/parking/A50951_PARK_Year_%.txt :
	aws s3 cp s3://data.il.propublica.org/il-tickets/parking/$(@F) $@


data/cameras/A50951_AUCM_Year_%.txt :
	aws s3 cp s3://data.il.propublica.org/il-tickets/cameras/$(@F) $@


data/dumps/geocodes-city-stickers.dump :
	aws s3 cp s3://data.il.propublica.org/il-tickets/dumps/geocodes-city-stickers.dump data/dumps/geocodes-city-stickers.dump


load_geocodes : data/dumps/geocodes-city-stickers.dump
	psql $(ILTICKETS_DB_URL) -c "\d public.geocodes" > /dev/null 2>&1 || \
	(psql $(ILTICKETS_DB_URL) -f sql/tables/geocodes.sql && \
	pg_restore -d "$(ILTICKETS_DB_URL)" --no-acl --no-owner --clean -t geocodes data/dumps/geocodes-city-stickers.dump)


.PRECIOUS: processors/salt.txt
processors/salt.txt :
	python processors/create_salt.py


.PRECIOUS: data/processed/A50951_PARK_Year_%_clean.csv
data/processed/A50951_PARK_Year_%_clean.csv : data/parking/A50951_PARK_Year_%.txt processors/salt.txt
	python processors/clean_csv.py $^ > data/processed/A50951_PARK_Year_$*_clean.csv 2> data/processed/A50951_PARK_Year_$*_err.txt


data/processed/parking_tickets.csv :
	psql $(ILTICKETS_DB_URL) -c "\copy parking TO '$(CURDIR)/$@' with (delimiter ',', format csv, header);"


data/processed/parking_tickets.zip : data/data_dictionary.txt data/unit_key.csv data/processed/parking_tickets.csv
	zip $@ $^


upload_zip : data/processed/parking_tickets.zip
	aws s3 cp $^ s3://data-publica/il_parking_tickets_20180822.zip


dupes/parking-%.csv : data/processed/A50951_PARK_Year_%_clean.csv
	$(check_tmp_parking_relation) || psql $(ILTICKETS_DB_URL) -c "CREATE TABLE tmp.tmp_table_parking_$* AS SELECT * FROM public.parking WITH NO DATA;"
	psql $(ILTICKETS_DB_URL) -c "\copy tmp.tmp_table_parking_$* FROM '$(CURDIR)/$<' with (delimiter ',', format csv, header, force_null(penalty));"
	psql $(ILTICKETS_DB_URL) -c "INSERT INTO public.parking SELECT * FROM tmp.tmp_table_parking_$* ON CONFLICT DO NOTHING;"
	psql $(ILTICKETS_DB_URL) -c	"DROP TABLE tmp.tmp_table_parking_$*;"
	touch $@


dupes/cameras-%.csv : data/cameras/A50951_AUCM_Year_%.txt
	$(check_tmp_cameras_relation) || psql $(ILTICKETS_DB_URL) -c "CREATE TABLE tmp.tmp_table_cameras_$* AS SELECT * FROM public.cameras WITH NO DATA;"
	sed \$$d $< | psql $(ILTICKETS_DB_URL) -c "\copy tmp.tmp_table_cameras_$* FROM STDIN with (delimiter '$$', format csv, header);"
	psql $(ILTICKETS_DB_URL) -c "INSERT INTO public.cameras SELECT * FROM tmp.tmp_table_cameras_$* ON CONFLICT DO NOTHING;"
	psql $(ILTICKETS_DB_URL) -c	"DROP TABLE tmp.tmp_table_cameras_$*;"
	touch $@


load_meta_% : data/metadata/%.csv
	$(check_public_relation) && psql $(ILTICKETS_DB_URL) -c "\copy $* from '$(CURDIR)/$<' with (delimiter ',', format csv, header);"


data/geojson/%.json :
	$(check_public_relation) || ogr2ogr -f GeoJSON $@ PG:"$(ILTICKETS_DB_STRING)" -sql "select * from $*;"


upload_geojson_% : data/geojson/%.json
	mapbox upload propublica.il-tickets-$* $<


data/exports/%.csv : sql/exports/%.sql
	psql $(ILTICKETS_DB_URL) -c "\copy ($(shell cat $<)) to '$(CURDIR)/$@'"


clean_% :
	rm -Rf data/$*/*
