# Indexing speed

Run against 2017-2018 parking data.

## Without presorting

### Index creation

```
iltickets=# create index if not exists parking_cluster on parking (address, violation_code, year);

CREATE INDEX
Time: 61561.402 ms (01:01.561)


iltickets=# cluster parking using parking_cluster;

CLUSTER
Time: 65946.112 ms (01:05.946)


iltickets=# analyze parking;
ANALYZE
Time: 2616.422 ms (00:02.616)
```

### End-to-end

```
✗ time make YEARS="2017 2018" all
...
1.90s user 0.98s system 1% cpu 4:01.65 total
```

(Full output:)

```
✗ time make YEARS="2017 2018" all
psql postgresql://localhost/iltickets -c "select 1;" > /dev/null 2>&1 || psql postgresql://localhost -c "create database iltickets" && \
	psql postgresql://localhost/iltickets -c "CREATE EXTENSION IF NOT EXISTS postgis;"
CREATE DATABASE
CREATE EXTENSION
psql postgresql://localhost/iltickets -c "\d public.parking" > /dev/null 2>&1 || psql postgresql://localhost/iltickets -f sql/tables/parking.sql
CREATE TABLE
psql postgresql://localhost/iltickets -c "CREATE SCHEMA IF NOT EXISTS tmp;"
CREATE SCHEMA
psql postgresql://localhost/iltickets -c "\d public.geocodes" > /dev/null 2>&1 || psql postgresql://localhost/iltickets -f sql/tables/geocodes.sql
CREATE TABLE
psql postgresql://localhost/iltickets -c "\d public.raw_geocodes" > /dev/null 2>&1 || \
	pg_restore -d "postgresql://localhost/iltickets" --no-acl --no-owner --clean -t geocodes data/dumps/geocodes-city-stickers.dump && \
 	psql postgresql://localhost/iltickets -c "alter table if exists geocodes rename to raw_geocodes"
ALTER TABLE
ogr2ogr -f "PostgreSQL" PG:"dbname=iltickets" "data/geodata/communityareas.json" -nln communityareas -overwrite
ogr2ogr -f "PostgreSQL" PG:"dbname=iltickets" "data/geodata/wards2015.json" -nln wards2015 -overwrite
psql postgresql://localhost/iltickets -c "\d tmp.tmp_table_parking_2017" > /dev/null 2>&1 || psql postgresql://localhost/iltickets -c "CREATE TABLE tmp.tmp_table_parking_2017 AS SELECT * FROM public.parking WITH NO DATA;"
CREATE TABLE AS
psql postgresql://localhost/iltickets -c "\copy tmp.tmp_table_parking_2017 FROM '/Users/DE-Admin/Code/il-ticket-loader/data/processed/A50951_PARK_Year_2017_clean.csv' with (delimiter ',', format csv, header);"
COPY 2190763
psql postgresql://localhost/iltickets -c "INSERT INTO public.parking SELECT * FROM tmp.tmp_table_parking_2017 ON CONFLICT DO NOTHING;"
INSERT 0 2190763
psql postgresql://localhost/iltickets -c	"DROP TABLE tmp.tmp_table_parking_2017;"
DROP TABLE
touch data/processed/A50951_PARK_Year_2017_clean.csv
psql postgresql://localhost/iltickets -c "\d tmp.tmp_table_parking_2018" > /dev/null 2>&1 || psql postgresql://localhost/iltickets -c "CREATE TABLE tmp.tmp_table_parking_2018 AS SELECT * FROM public.parking WITH NO DATA;"
CREATE TABLE AS
psql postgresql://localhost/iltickets -c "\copy tmp.tmp_table_parking_2018 FROM '/Users/DE-Admin/Code/il-ticket-loader/data/processed/A50951_PARK_Year_2018_clean.csv' with (delimiter ',', format csv, header);"
COPY 769219
psql postgresql://localhost/iltickets -c "INSERT INTO public.parking SELECT * FROM tmp.tmp_table_parking_2018 ON CONFLICT DO NOTHING;"
INSERT 0 769219
psql postgresql://localhost/iltickets -c	"DROP TABLE tmp.tmp_table_parking_2018;"
DROP TABLE
touch data/processed/A50951_PARK_Year_2018_clean.csv
psql postgresql://localhost/iltickets -f sql/indexes/parking.sql
CREATE INDEX
CLUSTER
psql postgresql://localhost/iltickets -f sql/views/geocodes.sql
SELECT 40053
ALTER TABLE
CREATE INDEX
CREATE INDEX
psql postgresql://localhost/iltickets -f sql/views/blocksummary_intermediate.sql
SELECT 553142
CREATE INDEX
psql postgresql://localhost/iltickets -f sql/views/blocksummary_yearly.sql
SELECT 206975
ALTER TABLE
CREATE INDEX
psql postgresql://localhost/iltickets -f sql/views/blocksummary_total.sql
SELECT 26007
ALTER TABLE
make YEARS="2017 2018" all  1.90s user 0.98s system 1% cpu 4:01.65 total
```

## With presorting

### Indexes

```
iltickets=# create index if not exists parking_cluster on parking (address, violation_code, year);
CREATE INDEX
Time: 22441.525 ms (00:22.442)

iltickets=# cluster parking using parking_cluster;
CLUSTER
Time: 42005.141 ms (00:42.005)


iltickets=# analyze parking;
ANALYZE
Time: 2669.688 ms (00:02.670)
```

### End-to-end

```
✗ time make YEARS="2017 2018" all
...

1.86s user 0.94s system 1% cpu 4:30.16 total
```

(Full output:)

```
✗ time make YEARS="2017 2018" all
psql postgresql://localhost/iltickets -c "select 1;" > /dev/null 2>&1 || psql postgresql://localhost -c "create database iltickets" && \
	psql postgresql://localhost/iltickets -c "CREATE EXTENSION IF NOT EXISTS postgis;"
CREATE DATABASE
CREATE EXTENSION
psql postgresql://localhost/iltickets -c "\d public.parking" > /dev/null 2>&1 || psql postgresql://localhost/iltickets -f sql/tables/parking.sql
CREATE TABLE
psql postgresql://localhost/iltickets -c "CREATE SCHEMA IF NOT EXISTS tmp;"
CREATE SCHEMA
psql postgresql://localhost/iltickets -c "\d public.geocodes" > /dev/null 2>&1 || psql postgresql://localhost/iltickets -f sql/tables/geocodes.sql
CREATE TABLE
psql postgresql://localhost/iltickets -c "\d public.raw_geocodes" > /dev/null 2>&1 || \
	pg_restore -d "postgresql://localhost/iltickets" --no-acl --no-owner --clean -t geocodes data/dumps/geocodes-city-stickers.dump && \
 	psql postgresql://localhost/iltickets -c "alter table if exists geocodes rename to raw_geocodes"
ALTER TABLE
ogr2ogr -f "PostgreSQL" PG:"dbname=iltickets" "data/geodata/communityareas.json" -nln communityareas -overwrite
ogr2ogr -f "PostgreSQL" PG:"dbname=iltickets" "data/geodata/wards2015.json" -nln wards2015 -overwrite
psql postgresql://localhost/iltickets -c "\d tmp.tmp_table_parking_2017" > /dev/null 2>&1 || psql postgresql://localhost/iltickets -c "CREATE TABLE tmp.tmp_table_parking_2017 AS SELECT * FROM public.parking WITH NO DATA;"
CREATE TABLE AS
psql postgresql://localhost/iltickets -c "\copy tmp.tmp_table_parking_2017 FROM '/Users/DE-Admin/Code/il-ticket-loader/data/processed/A50951_PARK_Year_2017_clean.csv' with (delimiter ',', format csv, header);"
COPY 2190763
psql postgresql://localhost/iltickets -c "INSERT INTO public.parking SELECT * FROM tmp.tmp_table_parking_2017 ORDER BY address, violation_code, year ON CONFLICT DO NOTHING;"
INSERT 0 2190763
psql postgresql://localhost/iltickets -c	"DROP TABLE tmp.tmp_table_parking_2017;"
DROP TABLE
touch data/processed/A50951_PARK_Year_2017_clean.csv
psql postgresql://localhost/iltickets -c "\d tmp.tmp_table_parking_2018" > /dev/null 2>&1 || psql postgresql://localhost/iltickets -c "CREATE TABLE tmp.tmp_table_parking_2018 AS SELECT * FROM public.parking WITH NO DATA;"
CREATE TABLE AS
psql postgresql://localhost/iltickets -c "\copy tmp.tmp_table_parking_2018 FROM '/Users/DE-Admin/Code/il-ticket-loader/data/processed/A50951_PARK_Year_2018_clean.csv' with (delimiter ',', format csv, header);"
COPY 769219
psql postgresql://localhost/iltickets -c "INSERT INTO public.parking SELECT * FROM tmp.tmp_table_parking_2018 ORDER BY address, violation_code, year ON CONFLICT DO NOTHING;"
INSERT 0 769219
psql postgresql://localhost/iltickets -c	"DROP TABLE tmp.tmp_table_parking_2018;"
DROP TABLE
touch data/processed/A50951_PARK_Year_2018_clean.csv
psql postgresql://localhost/iltickets -f sql/indexes/parking.sql
CREATE INDEX
CLUSTER
psql postgresql://localhost/iltickets -f sql/views/geocodes.sql
SELECT 40053
ALTER TABLE
CREATE INDEX
CREATE INDEX
psql postgresql://localhost/iltickets -f sql/views/blocksummary_intermediate.sql
SELECT 553142
CREATE INDEX
psql postgresql://localhost/iltickets -f sql/views/blocksummary_yearly.sql
SELECT 206975
ALTER TABLE
CREATE INDEX
psql postgresql://localhost/iltickets -f sql/views/blocksummary_total.sql
SELECT 26007
ALTER TABLE
make YEARS="2017 2018" all  1.86s user 0.94s system 1% cpu 4:30.16 total
```


# Bigger tests

End to end with 2013-2018 data.

## Unsorted

Screwed up running the views, so have to do it in two parts

```
3.98s user 3.34s system 0% cpu 20:21.28 total
0.04s user 0.05s system 0% cpu 5:17.98 total
```

## Presorted


```
4.24s user 3.58s system 0% cpu 28:01.67 total
```


# C collation


