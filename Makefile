PARKINGYEARS = 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018
#PARKINGYEARS = 2018
CAMERAYEARS = 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018
DATATABLES = parking cameras
CENSUSTABLES = acs_17_5yr_b03002
IMPORTS = wardmeta
GEOJSONTABLES = communityareas wards2015
SHPTABLES = tl_2016_17_bg tl_2016_17_tabblock10
VIEWS = blocks blockstotals wards warddemographics wardsyearly wardsyearlytotals wardstotals wardstotals5yr wardscommunityareas violations
DATADIRS = analysis cameras geodata parking processed

.PHONY: all clean bootstrap tables indexes views analysis parking cameras load download_parking download_cameras zip_n_ship sync geojson_tables shp_tables
.INTERMEDIATE: processors/salt.txt

all: bootstrap geo census parking imports indexes views

bootstrap : create_db tables schema
geo: load_geocodes geojson_tables shp_tables
geojson_tables: $(patsubst %, load_geojson_%, $(GEOJSONTABLES))
shp_tables: $(patsubst %, load_shp_%, $(SHPTABLES))
tables : $(patsubst %, table_%, $(DATATABLES)) $(patsubst %, table_%, $(IMPORTS)) $(patsubst %, table_%, $(CENSUSTABLES))
census : $(patsubst %, load_census_%, $(CENSUSTABLES))
indexes : $(patsubst %, index_%, $(DATATABLES))
views : $(patsubst %, view_%, $(VIEWS))
imports : $(patsubst %, import_%, $(IMPORTS))
appgeo : bootstrap load_geodata_wards2015

parking : $(patsubst %, dupes/parking-%.csv, $(PARKINGYEARS))
cameras : $(patsubst %, dupes/cameras-%.csv, $(CAMERAYEARS))

download_parking : $(patsubst %, data/parking/A50951_PARK_Year_%.txt, $(PARKINGYEARS))
download_cameras : $(patsubst %, data/cameras/A50951_AUCM_Year_%.txt, $(CAMERAYEARS))

zip_n_ship : processors/salt.txt upload_zip

drop_views: $(patsubst %, drop_view_%, $(VIEWS))
clean: drop_db $(patsubst %, clean_%, $(DATADIRS)) processors/salt.txt


define psql
	psql $(ILTICKETS_DB_URL)
endef


define check_database
 $(psql) -c "select 1;" > /dev/null 2>&1
endef


define check_public_relation
 $(psql) -c "\d public.$*" > /dev/null 2>&1
endef


define check_tmp_parking_relation
 $(psql) -c "\d tmp.tmp_table_parking_$*" > /dev/null 2>&1
endef


define check_tmp_cameras_relation
 $(psql) -c "\d tmp.tmp_table_cameras_$*" > /dev/null 2>&1
endef


create_db :
	$(check_database) || psql $(ILTICKETS_DB_ROOT_URL) -c "create database $(ILTICKETS_DB_NAME) lc_collate \"C\" lc_ctype \"C\" template template0" && \
	$(psql) -c "CREATE EXTENSION IF NOT EXISTS postgis;"
	$(psql) -c "CREATE EXTENSION IF NOT EXISTS hstore;"
	$(psql) -c "CREATE EXTENSION IF NOT EXISTS tablefunc;"


table_% : sql/tables/%.sql
	$(check_public_relation) || $(psql) -f $<


view_% : sql/views/%.sql
	$(check_public_relation) || $(psql) -f $<


transform_% : sql/transforms/%.sql
	$(psql) -f $<


populate_addresses : sql/geocodes/populate_addresses.sql
	$(psql) -f $<


index_% : sql/indexes/%.sql
	$(psql) -f $<


schema :
	$(psql) -c "CREATE SCHEMA IF NOT EXISTS tmp;"


drop_db :
	psql $(ILTICKETS_DB_ROOT_URL) -c "drop database $(ILTICKETS_DB_NAME);" && rm -f dupes/*


drop_view_% :
	$(psql) -c "drop table $*;"


data/geodata/communityareas.json :
	curl "https://data.cityofchicago.org/api/geospatial/cauq-8yn6?method=export&format=GeoJSON" > $@


data/geodata/wards2015.json :
	curl "https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON" > $@


data/metadata/wardmeta.csv :
	curl "https://data.cityofchicago.org/api/views/htai-wnw4/rows.csv?accessType=DOWNLOAD" > $@


load_geojson_% : data/geodata/%.json
	$(check_public_relation) || ogr2ogr -f "PostgreSQL" PG:"$(ILTICKETS_DB_STRING)" "$<" -nln $* -overwrite


load_shp_% : data/geodata/%.shp
	$(check_public_relation) || ogr2ogr -f "PostgreSQL" PG:"$(ILTICKETS_DB_STRING)" "$<" -nlt PROMOTE_TO_MULTI -nln $* -t_srs EPSG:4326 -overwrite


dump_geocodes :
	pg_dump $(ILTICKETS_DB_URL) --verbose -t geocodes -Fc -f data/dumps/parking-geocodes-geocodio.dump


dump_parking_geo :
	pg_dump $(ILTICKETS_DB_URL) --verbose -t parking_geo -Fc -f data/dumps/parking-geo.dump


data/parking/A50951_PARK_Year_%.txt :
	aws s3 cp s3://data.il.propublica.org/il-tickets/parking/$(@F) $@


data/cameras/A50951_AUCM_Year_%.txt :
	aws s3 cp s3://data.il.propublica.org/il-tickets/cameras/$(@F) $@


data/dumps/parking-geocodes-geocodio.dump :
	aws s3 cp s3://data.il.propublica.org/il-tickets/dumps/parking-geocodes-geocodio.dump data/dumps/parking-geocodes-geocodio.dump


sync_% :
	aws s3 sync data/$* s3://data.il.propublica.org/il-tickets/$*


load_geocodes : data/dumps/parking-geocodes-geocodio.dump
	$(psql) -c "\d public.geocodes" > /dev/null 2>&1 || \
	($(psql) -f sql/tables/geocodes.sql && \
	pg_restore -d "$(ILTICKETS_DB_URL)" -j 16 --no-acl --no-owner --clean -t geocodes data/dumps/parking-geocodes-geocodio.dump)


load_census_% : data/census/%.csv
	$(check_public_relation) && $(psql) -c "\copy $* from '$(CURDIR)/$<' with (delimiter ',', format csv)"


.PRECIOUS: processors/salt.txt
processors/salt.txt :
	python processors/create_salt.py


.PRECIOUS: data/processed/A50951_PARK_Year_%_clean.csv
data/processed/A50951_PARK_Year_%_clean.csv : data/parking/A50951_PARK_Year_%.txt processors/salt.txt
	python processors/clean_csv.py $^ > data/processed/A50951_PARK_Year_$*_clean.csv 2> data/processed/A50951_PARK_Year_$*_err.txt


data/processed/parking_tickets.csv :
	$(psql) -c "\copy parking TO '$(CURDIR)/$@' with (delimiter ',', format csv, header);"


data/processed/parking_tickets.zip : data/data_dictionary.txt data/unit_key.csv data/processed/parking_tickets.csv
	zip $@ $^


upload_zip : data/processed/parking_tickets.zip
	aws s3 cp $^ s3://data-publica/il_parking_tickets_20180822.zip


dupes/parking-%.csv : data/processed/A50951_PARK_Year_%_clean.csv
	$(check_tmp_parking_relation) || $(psql) -c "CREATE TABLE tmp.tmp_table_parking_$* AS SELECT * FROM public.parking WITH NO DATA;"
	$(psql) -c "\copy tmp.tmp_table_parking_$* FROM '$(CURDIR)/$<' with (delimiter ',', format csv, header, force_null(penalty));"
	$(psql) -c "INSERT INTO public.parking SELECT * FROM tmp.tmp_table_parking_$* ON CONFLICT DO NOTHING;"
	$(psql) -c	"DROP TABLE tmp.tmp_table_parking_$*;"
	touch $@


dupes/cameras-%.csv : data/cameras/A50951_AUCM_Year_%.txt
	$(check_tmp_cameras_relation) || $(psql) -c "CREATE TABLE tmp.tmp_table_cameras_$* AS SELECT * FROM public.cameras WITH NO DATA;"
	sed \$$d $< | $(psql) -c "\copy tmp.tmp_table_cameras_$* FROM STDIN with (delimiter '$$', format csv, header);"
	$(psql) -c "INSERT INTO public.cameras SELECT * FROM tmp.tmp_table_cameras_$* ON CONFLICT DO NOTHING;"
	$(psql) -c	"DROP TABLE tmp.tmp_table_cameras_$*;"
	touch $@


import_% : data/imports/%.csv
	$(check_public_relation) && $(psql) -c "\copy $* from '$(CURDIR)/$<' with (delimiter ',', format csv, header);"


data/geojson/%.json :
	$(check_public_relation) && ogr2ogr -f GeoJSON $@ PG:"$(ILTICKETS_DB_STRING)" -sql "select * from $*;"


data/mbtiles/%.mbtiles : data/geojson/%.json
	tippecanoe -zg --drop-densest-as-needed -o data/mbtiles/$*.mbtiles -f $<


upload_geojson_% : data/geojson/%.json
	mapbox upload propublica.il-tickets-$* $<


upload_mbtiles_% : data/mbtiles/%.mbtiles
	mapbox upload propublica.il-tickets-$* $<


data/exports/%.csv : sql/exports/%.sql
	$(psql) -c "\copy ($(shell cat $<)) to '$(CURDIR)/$@' with (format csv, header);"


import_% : sql/imports/%.csv
	$(psql) -c "\copy $* from '$(CURDIR)/$@' with (format csv, header);"


test_data :
	$(psql) -c "\copy (SELECT (x).key as metric, (x).value \
		FROM \
			( SELECT EACH(hstore($@)) as x \
				FROM $@ \
			) q) to '$(CURDIR)/data/test-results/test-data.csv' with (format csv, header);"


clean_% :
	rm -Rf data/$*/*
