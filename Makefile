YEARS = 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2017b
ILTICKETS_DB_URL=postgres://localhost/iltickets
ILTICKETS_DB_ROOT_URL=postgres://localhost
ILTICKETS_DB_NAME=iltickets

.PHONY: download_parking

download_parking : $(patsubst %, data/parking/A50951_%.csv, $(YEARS))


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


dupes/parking-%.csv : data/parking/A50951_%.csv
	psql $(ILTICKETS_DB_URL) -c "CREATE TEMPORARY TABLE tmp_table_parking_$* AS SELECT * FROM public.tickets WITH NO DATA; COPY tmp_table_parking_$* FROM '$(CURDIR)/$<' with delimiter ',' csv header; INSERT INTO public.tickets SELECT * FROM tmp_table_parking_$* ON CONFLICT DO NOTHING; COPY (select ticket_number, count(ticket_number) as count from tmp_table_parking_$* group by ticket_number having count(ticket_number) > 1) TO '$(PWD)/dupes/parking-$*.csv' with delimiter ',' csv header;"

#	\copy public.tickets from '$(CURDIR)/$<' with delimiter ',' csv header;" && touch db/parking-$*


data/parking/A505951_%.csv :
	aws s3 cp s3://data.il.propublica.org/il-tickets/parking/$* data/parking/

