YEARS = 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017

.PHONY: all download_parking load_parking

all: create_db create_table_tickets create_schema download_parking load_parking
download_parking : $(patsubst %, data/parking/A50951_%.csv, $(YEARS))
load_parking : $(patsubst %, dupes/parking-%.csv, $(YEARS))


define check_database
 psql $(ILTICKETS_DB_URL) -c "select 1;" > /dev/null 2>&1 ||
endef


define check_public_relation
 psql $(ILTICKETS_URL) -c "\d public.$*" > /dev/null 2>&1 ||
endef



create_db :
	$(check_database) psql $(ILTICKETS_DB_ROOT_URL) -c "create database $(ILTICKETS_DB_NAME)"


create_table_% : sql/tables/%.sql
	$(check_public_relation) psql  $(ILTICKETS_DB_URL) -f $<


create_schema :
	psql $(ILTICKETS_DB_URL) -c "CREATE SCHEMA tmp;"


drop_db : create_db
	psql $(ILTICKETS_DB_ROOT_URL) -c "drop database $(ILTICKETS_DB_NAME);" && rm -f dupes/*


dupes/parking-%.csv : data/parking/A50951_%.csv
	psql $(ILTICKETS_DB_URL) -c "CREATE TABLE tmp.tmp_table_parking_$* AS SELECT * FROM public.tickets WITH NO DATA;"
	psql $(ILTICKETS_DB_URL) -c "\copy tmp.tmp_table_parking_$* FROM '$(CURDIR)/$<' with delimiter ',' csv header;"
	psql $(ILTICKETS_DB_URL) -c "INSERT INTO public.tickets SELECT * FROM tmp.tmp_table_parking_$* ON CONFLICT DO NOTHING;"
	psql $(ILTICKETS_DB_URL) -c	"\copy (select ticket_number, count(ticket_number) as count from tmp.tmp_table_parking_$* group by ticket_number having count(ticket_number) > 1) TO '$(PWD)/dupes/parking-$*.csv' with delimiter ',' csv header;"
	psql $(ILTICKETS_DB_URL) -c	"DROP TABLE tmp.tmp_table_parking_$*;"


data/parking/A505951_%.csv :
	aws s3 cp s3://data.il.propublica.org/il-tickets/parking/$* data/parking/
