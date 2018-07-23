# Illinois Ticket Data Loader

## Requirements

* GNU make
* Python 3
* PostgreSQL
* ProPublica Illinois S3 bucket credentials
* CSVKit (with Homebrew already installed, run: `pip install csvkit`)

## Configuration

A default configuration can be imported by running:

```
source env/dev.sh
```

Or you can set environment variables:

```
export ILTICKETS_DB_URL=postgres://localhost/iltickets
export ILTICKETS_DB_ROOT_URL=postgres://localhost
export ILTICKETS_DB_NAME=iltickets
export ILTICKETS_DB_STRING="dbname=iltickets"
```

This variables are a bit repetitive. Of note is `ILTICKETS_DB_STRING`, which is the [`ogr2ogr`](http://www.gdal.org/drv_pg.html) connection string.

## Running

### One shot

Slow version:

```
make all
```

Fast version:

```
make bootstrap geo && make -j 8 parking && make indexes views analysis
```

Set `-j N` to reflect the number of processors available on your system.

### Reset the database

```
make drop_db
```

### Download

**This is currently broken.**

```
make download
```

### Load into DB

```
make load
```

Or:

```
make load_parking
make load_cameras
```

### Remove files

*Not implemented. You must do this manually.*

## Error handling

Bad CSV rows are written to `data/processed/<FILENAME>_err.csv`. These should only ever be the final "total" line from each file.

## Duplicate handling

To load, we first load the data into a `tmp` PostgreSQL schema (we can't use "real" temporary tables because of some limitations with how RDS handles the copy command, so to keep things portable use just use schemas).

We then copy from the `tmp` schema to the `public` schema, ignoring duplicates. We currently keep the existing record and throw out the old one (`ON CONFLICT DO NOTHING`) but could replace.

Dupes are written to the `dupes` directory as CSVs for each year where dupes were found.

## Notes

* `sql/tables/community_area_stats.sql` was generated with CSVKit's `csvsql` command like so:  `csvsql data/geodate/community_area_stats.csv > sql/tables/community_area_stats.sql`


