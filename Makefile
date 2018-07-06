YEARS = 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018

.PHONY: all bootstrap_db download_parking load_parking download_cameras load_parking load download clean clean_files

all: bootstrap_db load_parking load_cameras

clean: drop_db clean_files

bootstrap_db : create_db create_table_parking create_table_cameras create_schema

load: load_cameras load_parking

download: download_cameras download_parking

download_parking : $(patsubst %, data/parking/A50951_PARK_Year_%.txt, $(YEARS))
load_parking : $(patsubst %, dupes/parking-%.csv, $(YEARS))

download_cameras : $(patsubst %, data/cameras/A50951_AUCM_Year_%.txt, $(YEARS))
load_cameras : $(patsubst %, dupes/cameras-%.csv, $(YEARS))


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


create_table_% : sql/tables/%.sql
	$(check_public_relation) psql  $(ILTICKETS_DB_URL) -f $<


create_schema :
	psql $(ILTICKETS_DB_URL) -c "CREATE SCHEMA tmp;"


drop_db : create_db
	psql $(ILTICKETS_DB_ROOT_URL) -c "drop database $(ILTICKETS_DB_NAME);" && rm -f dupes/*


data/parking/A50951_PARK_Year_%.txt :
	aws s3 cp s3://data.il.propublica.org/il-tickets/parking/$(@F) $@


data/processed/A50951_PARK_Year_%_clean.csv : data/parking/A50951_PARK_Year_%.txt
	python processors/clean_csv.py $< > data/processed/A50951_PARK_Year_$*_clean.csv 2> data/processed/A50951_PARK_Year_$*_err.csv


data/processed/A50951_AUCM_Year_%_clean.csv : data/cameras/A50951_AUCM_Year_%.txt
	python processors/clean_csv.py $< > data/processed/A50951_AUCM_Year_$*_clean.csv 2> data/processed/A50951_AUCM_Year_$*_err.csv


dupes/parking-%.csv : data/processed/A50951_PARK_Year_%_clean.csv
	$(check_tmp_parking_relation) psql $(ILTICKETS_DB_URL) -c "CREATE TABLE tmp.tmp_table_parking_$* AS SELECT * FROM public.tickets WITH NO DATA;"
	psql $(ILTICKETS_DB_URL) -c "\copy tmp.tmp_table_parking_$* FROM '$(CURDIR)/$<' with (delimiter ',', format csv, header);"
	psql $(ILTICKETS_DB_URL) -c "INSERT INTO public.tickets SELECT * FROM tmp.tmp_table_parking_$* ON CONFLICT DO NOTHING;"
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


clean_files :
	rm -Rf data/cameras/*
	rm -Rf data/parking/*
	rm -Rf data/processed/*
	rm -Rf dupes/*
