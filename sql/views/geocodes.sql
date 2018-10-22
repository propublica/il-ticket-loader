create table if not exists geocodes as
  SELECT DISTINCT ON (geocoded_address)
    address,
    geocoded_address,
    geocoded_lng,
    geocoded_lat,
    geocoded_city,
    geocoded_state,
    geocode_geojson->'features'->0->'properties'->>'postal' as geocoded_zip,
    case
     when split_part(geocoded_address, ' ', 2) not in ('N', 'E', 'S', 'W') then null
     else split_part(geocoded_address, ' ', 2)
    end as cardinal_direction
  from raw_geocodes
  order by geocoded_address, id;

alter table geocodes
  add column id serial primary key;

create index on geocodes (address);
create index on geocodes (geocoded_address);