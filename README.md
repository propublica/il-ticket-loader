# Illinois Ticket Data Loader

## Requirements

* GNU make
* ProPublica Illinois S3 bucket credentials

## Configuration

You must set some environment variables.

```
export ILTICKETS_DB_URL=postgres://localhost/iltickets
export ILTICKETS_DB_ROOT_URL=postgres://localhost
export ILTICKETS_DB_NAME=iltickets
```

(I know, they kind of violate DRY.)

## Running

### One shot

```
make all
```

### Reset the database

```
make drop_db
```

### Download

```
make download_parking
```

### Load into DB

```
make load_parking
```

### Remove files

*Not implemented. You must do this manually.*

## Duplicate handling

To load, we first load the data into a `tmp` PostgreSQL schema (we can't use "real" temporary tables because of some limitations with how RDS handles the copy command, so to keep things portable use just use schemas).

We then copy from the `tmp` schema to the `public` schema, ignoring duplicates. We currently keep the existing record and throw out the old one (`ON CONFLICT DO NOTHING`) but could replace.

Dupes are written to the `dupes` directory as CSVs for each year where dupes were found.


