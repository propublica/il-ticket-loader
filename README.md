# Illinois Ticket Data Loader

## Requirements

* GNU make
* Python 3
* GDAL
* PostgreSQL + PostGIS
* ProPublica Illinois S3 bucket credentials

Run `pip install -r requirements.txt` to install Python dependencies.

## Configuration

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

## Running

### One shot

Slow version:

```
make all
```

Fast version:

```
make bootstrap geo && make -j 8 parking && make indexes views
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

### Remove files

To clean out one of the subdirectories in the data directory:

```
make clean_<subdirectory>
```

E.g. `make clean_processed` or `make clean_geodata`.

### Error handling

Bad CSV rows are written to `data/processed/<FILENAME>_err.csv`. These should only ever be the final "total" line from each file.

## Working with data

### Tables

* `parking`: Raw parking ticket data
* `communityareas`: Chicago Community Area geographic data
* `wards2015`: Chicago Aldermanic Ward geographic data
* `geocodes`: Data from original geocoding run. **Use `blocks` for most queries.**
* `geocodes`: De-duplicated version of `geocodes` table, enhanced with additional fields: cardinal direction, zipcode, and geographies this block is part of (currently just wards). Join through this table (see below).
  against this table.
* `wardsyearly`: Counts and sums of block tickets, fees, and debt, aggregated to the ward level. Grouped by year, violation code, ticket queue, hearing disposition, unit description, and notice level.
* `blocksyearly`: Counts and sums of block tickets, fees, and debt. Grouped by year, violation code, ticket queue, hearing disposition, unit description, and notice level.

## Data dictionary

The City of Chicago has told us that an official data dictionary does not exist. But through interviews with finance department officials and other reporting, this is how we can best describe the data contained in these records:
• `ticket_number`: a unique ID for each citation
* `issue_date`: date and time the ticket was issued
* `violation_location`: street address where the ticket was issued
* `license_plate_number`: contains a hash, making it possible to determine whether tickets were issued to the same vehicle, while anonymizing the actual license plate numbers.
* `license_plate_state`: what state the license plate is from, expressed as a two-letter abbreviation 
* `license_plate_type`: the vast majority of license plates are for passenger vehicles. But also included are trucks, temporary plates and taxi cabs, among many others.
* `zipcode`: the ZIP code associated with the vehicle registration
* `violation_code`: municipal code associated with violation; these have changed slightly over time
* `violation_description`: name of violation
* `unit`: This number relates to subcategories within units, such as police precincts or private contractors. A file with a unit crosswalk obtained from the Department of Finance is included in the data download. 
* `unit_description`: the agency that issued the ticket, typically “CPD” for Chicago Police Department or “DOF” for Department of Finance, which can include subcontractors.
* `vehicle_make`: vehicle make
* `fine_level1_amount`: original cost of citation
* `fine_level2_amount`: price of citation plus any late penalties or collections fees. Unpaid tickets can double in price and accrue a 22-percent collection charge.
* `current_amount_due`: total amount due for that citation and any related late penalties as of May 14, 2018, when data was last updated.
* `total_payments`: total amount paid for ticket and associated penalties as of May 14, 2018, when data was last updated.
* `ticket_queue`: This category describes the most recent status of the ticket. These are marked “Paid” if the ticket was paid; “Dismissed” if the ticket was dismissed, (either internally or as a result of an appeal); “Hearing Req” if the ticket was contested and awaiting a hearing at the time the data was pulled; “Notice” if the ticket was not yet paid and the city sent a notice to the address on file for that vehicle; “Court” if the ticket is involved in some sort of court case, not including bankruptcy; “Bankruptcy” if the ticket was unpaid and included as a debt in a consumer bankruptcy case; and “Define” if the city cannot identify the vehicle owner and collect on a debt. Current as of May 14, 2018, when the data was last updated.
* `ticket_queue_date`: when the “ticket_queue” was last updated.
* `notice_level`: This field describes the type of notice the city has sent a motorist. The types of notices include: “VIOL,” which means a notice of violation was sent; “SEIZ” indicates the vehicle is on the city’s boot list; “DETR” indicates a hearing officer found the vehicle owner was found liable for the citation; “FINL” indicates the unpaid ticket was sent to collections; and “DLS” means the city intends to seek a license suspension. If the field is blank, no notice was sent.
• `hearing_disposition`: outcome of a hearing, either “Liable” or “Not Liable.” If the ticket was not contested this field is blank.
• `notice_number`: a unique ID attached to the notice, if one was sent.
• `officer`: a unique ID for the specific police officer or parking enforcement aide who issued the ticket.
• `address`: full address of the form “<XXXX Streetname>, Chicago, IL <ZIP code>”. Addresses in this field are normalized to the block level (e.g. 1983 N. Ashland is transformed to 1900 N. Ashland) for more efficient geocoding and analysis. This field was computed by ProPublica and does not exist in the original data.


