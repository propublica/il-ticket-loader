YEARS = 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018
DATATABLES = parking
GEOTABLES = communityareas wards2015
VIEWS = violations blocks blocksyearly wardsyearly
DATADIRS = analysis cameras geodata parking processed

.PHONY: all clean bootstrap tables indexes views analysis parking cameras load download_parking download_cameras zip_n_ship
.INTERMEDIATE: processors/salt.txt

all: bootstrap geo parking indexes views
clean: drop_db $(patsubst %, clean_%, $(DATADIRS)) processors/salt.txt

bootstrap : create_db tables schema
geo: load_geocodes $(patsubst %, load_geodata_%, $(GEOTABLES))
tables : $(patsubst %, table_%, $(DATATABLES))
indexes : $(patsubst %, index_%, $(DATATABLES))
views : $(patsubst %, view_%, $(VIEWS))

parking : $(patsubst %, dupes/parking-%.csv, $(YEARS))
cameras : $(patsubst %, dupes/cameras-%.csv, $(YEARS))

download_parking : $(patsubst %, data/parking/A50951_PARK_Year_%.txt, $(YEARS))
download_cameras : $(patsubst %, data/cameras/A50951_AUCM_Year_%.txt, $(YEARS))

zip_n_ship : processors/salt.txt upload_zip


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


index_% : sql/indexes/%.sql
	psql $(ILTICKETS_DB_URL) -f $<


schema :
	psql $(ILTICKETS_DB_URL) -c "CREATE SCHEMA IF NOT EXISTS tmp;"


drop_db :
	psql $(ILTICKETS_DB_ROOT_URL) -c "drop database $(ILTICKETS_DB_NAME);" && rm -f dupes/*


data/geodata/communityareas.json :
	curl "https://data.cityofchicago.org/api/geospatial/cauq-8yn6?method=export&format=GeoJSON" > $@


data/geodata/wards2015.json :
	curl "https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON" > $@


load_geodata_% : data/geodata/%.json
	$(check_public_relation) || ogr2ogr -f "PostgreSQL" PG:"$(ILTICKETS_DB_STRING)" "data/geodata/$*.json" -nln $* -overwrite


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


.PRECIOUS: data/processed/A50951_AUCM_Year_%_clean.csv
data/processed/A50951_AUCM_Year_%_clean.csv : data/cameras/A50951_AUCM_Year_%.txt
	python processors/clean_csv.py $< > data/processed/A50951_AUCM_Year_$*_clean.csv 2> data/processed/A50951_AUCM_Year_$*_err.txt


data/processed/parking_tickets.csv :
	psql $(ILTICKETS_DB_URL) -c "\copy parking TO '$(CURDIR)/$@' with (delimiter ',', format csv, header);"

data/processed/parking_tickets.zip : data/data_dictionary.txt data/unit_key.csv data/processed/parking_tickets.csv
	zip $@ $^

upload_zip : data/processed/parking_tickets.zip
	aws s3 cp $^ s3://data-publica/il_parking_tickets_20180822.zip

dupes/parking-%.csv : data/processed/A50951_PARK_Year_%_clean.csv
	$(check_tmp_parking_relation) || psql $(ILTICKETS_DB_URL) -c "CREATE TABLE tmp.tmp_table_parking_$* AS SELECT * FROM public.parking WITH NO DATA;"
	psql $(ILTICKETS_DB_URL) -c "\copy tmp.tmp_table_parking_$* FROM '$(CURDIR)/$<' with (delimiter ',', format csv, header);"
	psql $(ILTICKETS_DB_URL) -c "INSERT INTO public.parking SELECT * FROM tmp.tmp_table_parking_$* ON CONFLICT DO NOTHING;"
	psql $(ILTICKETS_DB_URL) -c	"DROP TABLE tmp.tmp_table_parking_$*;"
	touch $@


dupes/cameras-%.csv : data/processed/A50951_AUCM_Year_%_clean.csv
	$(check_tmp_cameras_relation) || psql $(ILTICKETS_DB_URL) -c "CREATE TABLE tmp.tmp_table_cameras_$* AS SELECT * FROM public.cameras WITH NO DATA;"
	psql $(ILTICKETS_DB_URL) -c "\copy tmp.tmp_table_cameras_$* FROM '$(CURDIR)/$<' with (delimiter ',', format csv, header);"
	psql $(ILTICKETS_DB_URL) -c "INSERT INTO public.cameras SELECT * FROM tmp.tmp_table_cameras_$* ON CONFLICT DO NOTHING;"
	psql $(ILTICKETS_DB_URL) -c	"DROP TABLE tmp.tmp_table_cameras_$*;"
	touch $@


clean_% :
	rm -Rf data/$*/*
