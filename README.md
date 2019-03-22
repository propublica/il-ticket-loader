# Illinois Ticket Data Loader

**Warning: This repository is currently for research and study purposes only. The code is not fully documented and it will not run without talking with ProPublica to gain access to the source data.**

## Introduction

This loader powers [The Ticket Trap](https://projects.propublica.org/chicago-tickets/) and the analysis and visualizations used throughout the [Driven Into Debt](https://www.propublica.org/series/driven-into-debt) series published by ProPublica Illinois. It cleans, loads, and analyzes Chicago parking and camera ticket data (see the [unofficial data dictionary](https://github.com/propublica/il-ticket-loader#data-dictionary) below for more details) in a PostgreSQL database. We have open-sourced this codebase for those who want to study it, use the data themselves, or contribute improvements like compatibility with ProPublica's public ticket data release that we've haven't had time for.

Please note again that this code is not fully documented and *will not run* without access to the source data. If you're interested in using this data and code for research, please jump to [Getting source data](https://github.com/propublica/il-ticket-loader#Getting-source-data).

## Requirements

* GNU make
* Python 3
* GDAL
* PostgreSQL + PostGIS
* ProPublica Illinois S3 bucket credentials or copies of the source data


## Installation

This project uses [Pipenv](https://pipenv.readthedocs.io/) to manage dependencies. 

To install Python dependencies, run:

```
pipenv sync
```

You _must_ have Pipenv to use the Makefile or override the `EXEC_ENV` variable when running `make` with whatever command needs to be run before calling Python to activate your environment.

## Configuration and setup

A default configuration can be imported by running:

```
source env/dev.sh
```

Or you can set environment variables:

```
export ILTICKETS_DB_URL=postgresql://localhost/iltickets
export ILTICKETS_DB_ROOT_URL=postgresql://localhost
export ILTICKETS_DB_NAME=iltickets
export ILTICKETS_DB_STRING="dbname=iltickets"
```

This variables are a bit repetitive. Of note is `ILTICKETS_DB_STRING`, which is the [`ogr2ogr`](http://www.gdal.org/drv_pg.html) connection string.

## Getting source data

Currently, you must have access to the source data for this project, which is different from what's available in the [ProPublica Data Store](https://www.propublica.org/datastore/dataset/chicago-parking-ticket-data). The source data includes improperly quoted fields and a handful of duplicate rows that the loader accounts for. It also includes license plate numbers which we obscure in the public data release with a hashing function, and joins in geographic data that is handled via database relations in this case.

To recieve access to the source data used by the repo, contact ProPublica by [creating an issue](https://github.com/propublica/il-ticket-loader/issues/new) in this repository and we'll be in touch.

If you have access to our S3 bucket, you can run:

```
make download
```

If you have talked with us, follow our instructions to unzip the data files in the `data` directory.


## Running

### One shot

Slow version:

```
make all
```

Fast version:

```
make bootstrap geo census && make -j8 parking && make -j8 cameras && make imports transforms indexes views
```

Set `-j N` to reflect the number of processors available on your system.

### Reset the database

```
make drop_db
```

### Download

```
make download
```

### Remove files

To clean out one of the subdirectories in the data directory:

```
make clean_<subdirectory>
```

E.g. `make clean_processed` or `make clean_geodata`.

`make clean` will clean everything, but use with care as the files in `data/processed` used for database loading take a solid 10 minutes to generate on a 2.7GHz i7 MacBook Pro with 16GB RAM. Don't regenerate those files unless you really need to.

### Error handling

Bad CSV rows are written to `data/processed/<FILENAME>_err.csv`. These should only ever be the final "total" line from each file.

### Rebuild views / regenerate analysis

The data analysis relies heavily on SQL "views" (these aren't real views but simply tables derived from the source data due to a bug with Hasura's handling of materialized views).

To regenerate the full data analysis:

```
make drop_views && make views
```

To regenerate one part of the analysis:

```
make drop_view_warddemographics && make view_warddemographics
```

### Export data

For a SQL file in `sql/exports`, `make export_FILENAME` will export a CSV with the content of the query.

For example, if you create a file called `penalities_2009_to_2011.sql` that queries for penalties from 2009 to 2011, then to export it, you can run:

```
make data/exports/penalities_2009_to_2011.csv
```

### Upload to ProPublica Data Store

To package for the ProPublica Data Store, run:

```
make zip_n_ship
```

## Working with data

### Tables and database structure

Currently undocumented. See `sql/tables` for source table schema, see `sql/views` for transformations and analysis based on source data, and `sql/exports` for exports. In addition, there are SQL files to set up indexes and apply some simple data transformations.


### Bullet proofing

Ask David Eads or Jeff Kao about this.

## Data dictionary

The City of Chicago has told us that an official data dictionary does not exist. But through interviews with finance department officials and other reporting, this is how we can best describe the data contained in these records:

* ticket_number: a unique ID for each citation
* issue_date: date and time the ticket was issued
* violation_location: street address where the ticket was issued
* license_plate_number: contains a hash, making it possible to determine whether tickets were issued to the same vehicle, while anonymizing the actual license plate numbers.
* license_plate_state: what state the license plate is from, expressed as a two-letter abbreviation 
* license_plate_type: the vast majority of license plates are for passenger vehicles. But also included are trucks, temporary plates and taxi cabs, among many others.
* zipcode: the ZIP code associated with the vehicle registration
* violation_code: municipal code associated with violation; these have changed slightly over time
* violation_description: name of violation
* unit: This number relates to subcategories within units, such as police precincts or private contractors. A file with a unit crosswalk obtained from the Department of Finance is included in the data download. 
* unit_description: the agency that issued the ticket, typically “CPD” for Chicago Police Department or “DOF” for Department of Finance, which can include subcontractors.
vehicle_make: vehicle make
* fine_level1_amount: original cost of citation
* fine_level2_amount: price of citation plus any late penalties or collections fees. Unpaid tickets can double in price and accrue a 22-percent collection charge.
current_amount_due: total amount due for that citation and any related late penalties as of May 14, 2018, when data was last updated.
* total_payments: total amount paid for ticket and associated penalties as of May 14, 2018, when data was last updated.
* ticket_queue: This category describes the most recent status of the ticket. These are marked “Paid” if the ticket was paid; “Dismissed” if the ticket was dismissed, (either internally or as a result of an appeal); “Hearing Req” if the ticket was contested and awaiting a hearing at the time the data was pulled; “Notice” if the ticket was not yet paid and the city sent a notice to the address on file for that vehicle; “Court” if the ticket is involved in some sort of court case, not including bankruptcy; “Bankruptcy” if the ticket was unpaid and included as a debt in a consumer bankruptcy case; and “Define” if the city cannot identify the vehicle owner and collect on a debt. Current as of May 14, 2018, when the data was last updated.
* ticket_queue_date: when the “ticket_queue” was last updated.
* notice_level: This field describes the type of notice the city has sent a motorist. The types of notices include: “VIOL,” which means a notice of violation was sent; “SEIZ” indicates the vehicle is on the city’s boot list; “DETR” indicates a hearing officer found the vehicle owner was found liable for the citation; “FINL” indicates the unpaid ticket was sent to collections; and “DLS” means the city intends to seek a license suspension. If the field is blank, no notice was sent.
hearing_disposition: outcome of a hearing, either “Liable” or “Not Liable.” If the ticket was not contested this field is blank.
* notice_number: a unique ID attached to the notice, if one was sent.
* hour: Hour of the day the ticket was issued. Derived from issue_date.
* month: Month the ticket was issued. Derived from issue_date.
* year: Year the ticket was issued. Derived from issue_date.
* officer: a unique ID for the specific police officer or parking enforcement aide who issued the ticket. In the camera data, speed camera violations are marked "SPEED;" red-light camera violations are marked "RDFX" or "XERX," which appear to be references to the company contracted to oversee the program.

These fields are specific to the parking data. These fields were computed by ProPublica and do not exist in the original data:


* normalized_address: full address of the form “<XXXX Streetname>, Chicago, IL <ZIP code>”. Addresses in this field are normalized to the block level (e.g. 1983 N. Ashland is transformed to 1900 N. Ashland) for more efficient geocoding and analysis. This field was computed by ProPublica and does not exist in the original data.
* latitude: Latitude of geocoded results
* longitude: Longitude of geocoded results
* geocoded_address: The address the geocoder resolved from the input address, e.g. 
* geocode_accuracy: Geocodio accuracy score associated with input address.
* geocode_accuracy_type: Geocodio accuracy type associated with input address.
* ward: The Chicago ward the ticket was issued in, derived from the geocoded result.


