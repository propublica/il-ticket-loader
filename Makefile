YEARS = 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018
TABLES = parking cameras geocodes community_area_stats
VIEWS = community_area_city_stickers geocode_accuracy
DATADIRS = analysis cameras geodata parking processed

.PHONY: all clean bootstrap tables indexes views analysis parking cameras load download_parking download_cameras zip_n_ship
.INTERMEDIATE: processors/salt.txt

all: processors/salt.txt bootstrap geo parking indexes views analysis
clean: drop_db $(patsubst %, clean_%, $(DATADIRS))

bootstrap : create_db tables schema
geo: load_geocodes load_geodata_community_area_stats load_community_areas clean_community_areas
tables : $(patsubst %, table_%, $(TABLES))
indexes : $(patsubst %, index_%, $(TABLES))
views : $(patsubst %, view_%, $(VIEWS))
analysis : $(patsubst %, data/analysis/%.csv, $(VIEWS))

parking : $(patsubst %, dupes/parking-%.csv, $(YEARS))
cameras : $(patsubst %, dupes/cameras-%.csv, $(YEARS))
load: cameras parking

download_parking : $(patsubst %, data/parking/A50951_PARK_Year_%.txt, $(YEARS))
download_cameras : $(patsubst %, data/cameras/A50951_AUCM_Year_%.txt, $(YEARS))

zip_n_ship : data/processed/parking_tickets.zip


define check_database
 psql $(ILTICKETS_DB_URL) -c "select 1;" > /dev/null 2>&1 ||
endef


define check_public_relation
 psql $(ILTICKETS_DB_URL) -c "\d public.$*" > /dev/null 2>&1 ||
endef


define check_tmp_parking_relation
 psql $(ILTICKETS_DB_URL) -c "\d tmp.tmp_table_parking_$*" > /dev/null 2>&1 ||
endef


define check_tmp_cameras_relation
 psql $(ILTICKETS_DB_URL) -c "\d tmp.tmp_table_cameras_$*" > /dev/null 2>&1 ||
endef


create_db :
	$(check_database) psql $(ILTICKETS_DB_ROOT_URL) -c "create database $(ILTICKETS_DB_NAME)"
	psql $(ILTICKETS_DB_NAME) -c "CREATE EXTENSION postgis;"


table_% : sql/tables/%.sql
	$(check_public_relation) psql $(ILTICKETS_DB_URL) -f $<


view_% : sql/views/%.sql
	psql $(ILTICKETS_DB_URL) -f $<


index_% :
	$(check_public_relation) psql $(ILTICKETS_DB_URL) -c "create index on $* (address);"


schema :
	psql $(ILTICKETS_DB_NAME) -c "CREATE SCHEMA tmp;"


drop_db :
	psql $(ILTICKETS_DB_ROOT_URL) -c "drop database $(ILTICKETS_DB_NAME);" && rm -f dupes/*


data/geodata/community-areas.json :
	curl "https://data.cityofchicago.org/api/geospatial/cauq-8yn6?method=export&format=GeoJSON" > $@


data/geodata/community_area_stats.csv :
	curl "https://datahub.cmap.illinois.gov/dataset/1d2dd970-f0a6-4736-96a1-3caeb431f5e4/resource/8c4e096e-c90c-4bef-9cf1-9028d094296e/download/ReferenceCCA20112015.csv" | sed -e "s:n/a::g" > data/geodata/community_area_stats.csv


data/analysis/%.csv : view_%
	psql $(ILTICKETS_DB_URL) -c "\copy (select * from public.$*) TO '$(CURDIR)/data/analysis/$*.csv' with (delimiter ',', format csv, header);"


load_geodata_% : data/geodata/community_area_stats.csv
	psql $(ILTICKETS_DB_URL) -c "\copy public.$* FROM '$(CURDIR)/data/geodata/$*.csv' with (delimiter ',', format csv, header);"


load_community_areas : data/geodata/community-areas.json
	ogr2ogr -f "PostgreSQL" PG:"$(ILTICKETS_DB_STRING)" "data/geodata/community-areas.json" -nln community_area_geography -overwrite


clean_community_areas :
	psql $(ILTICKETS_DB_URL) -c "update community_area_stats set "GEOG"=upper("GEOG"); update community_area_stats set geog = 'OHARE' where geog = 'O''HARE'; update community_area_stats set geog = 'LOOP' where geog = 'THE LOOP';"


data/parking/A50951_PARK_Year_%.txt :
	aws s3 cp s3://data.il.propublica.org/il-tickets/parking/$(@F) $@


data/cameras/A50951_AUCM_Year_%.txt :
	aws s3 cp s3://data.il.propublica.org/il-tickets/cameras/$(@F) $@


data/dumps/geocodes-city-stickers.dump :
	aws s3 cp s3://data.il.propublica.org/il-tickets/dumps/geocodes-city-stickers.dump data/dumps/geocodes-city-stickers.dump


load_geocodes : data/dumps/geocodes-city-stickers.dump table_geocodes
	pg_restore -d "$(ILTICKETS_DB_URL)" --no-acl --no-owner --clean -t geocodes data/dumps/geocodes-city-stickers.dump

processors/salt.txt :
	python processors/create_salt.py

data/processed/A50951_PARK_Year_%_clean.csv : data/parking/A50951_PARK_Year_%.txt
	python processors/clean_csv.py $^ processors/salt.txt > data/processed/A50951_PARK_Year_$*_clean.csv 2> data/processed/A50951_PARK_Year_$*_err.txt


data/processed/A50951_AUCM_Year_%_clean.csv : data/cameras/A50951_AUCM_Year_%.txt
	python processors/clean_csv.py $< > data/processed/A50951_AUCM_Year_$*_clean.csv 2> data/processed/A50951_AUCM_Year_$*_err.txt


data/processed/parking_tickets.csv :
	psql $(ILTICKETS_DB_URL) -c "\copy parking TO '$(CURDIR)/$@' with (delimiter ',', format csv, header);"

data/processed/parking_tickets.zip : data/processed/parking_tickets.csv
	zip $@ $^

dupes/parking-%.csv : data/processed/A50951_PARK_Year_%_clean.csv
	$(check_tmp_parking_relation) psql $(ILTICKETS_DB_URL) -c "CREATE TABLE tmp.tmp_table_parking_$* AS SELECT * FROM public.parking WITH NO DATA;"
	psql $(ILTICKETS_DB_URL) -c "\copy tmp.tmp_table_parking_$* FROM '$(CURDIR)/$<' with (delimiter ',', format csv, header);"
	psql $(ILTICKETS_DB_URL) -c "INSERT INTO public.parking SELECT * FROM tmp.tmp_table_parking_$* ON CONFLICT DO NOTHING;"
	psql $(ILTICKETS_DB_URL) -c	"\copy (select ticket_number, count(ticket_number) as count from tmp.tmp_table_parking_$* group by ticket_number having count(ticket_number) > 1) TO '$(PWD)/dupes/parking-$*.csv' with delimiter ',' csv header;"
	psql $(ILTICKETS_DB_URL) -c	"DROP TABLE tmp.tmp_table_parking_$*;"
	touch $<


dupes/cameras-%.csv : data/processed/A50951_AUCM_Year_%_clean.csv
	$(check_tmp_cameras_relation) psql $(ILTICKETS_DB_URL) -c "CREATE TABLE tmp.tmp_table_cameras_$* AS SELECT * FROM public.cameras WITH NO DATA;"
	psql $(ILTICKETS_DB_URL) -c "\copy tmp.tmp_table_cameras_$* FROM '$(CURDIR)/$<' with (delimiter ',', format csv, header);"
	psql $(ILTICKETS_DB_URL) -c "INSERT INTO public.cameras SELECT * FROM tmp.tmp_table_cameras_$* ON CONFLICT DO NOTHING;"
	psql $(ILTICKETS_DB_URL) -c	"\copy (select ticket_number, count(ticket_number) as count from tmp.tmp_table_cameras_$* group by ticket_number having count(ticket_number) > 1) TO '$(PWD)/dupes/parking-$*.csv' with delimiter ',' csv header;"
	psql $(ILTICKETS_DB_URL) -c	"DROP TABLE tmp.tmp_table_cameras_$*;"
	touch $<


clean_% :
	rm -Rf data/$*/*
