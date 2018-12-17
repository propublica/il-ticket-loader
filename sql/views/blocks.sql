create table if not exists blocks as
  SELECT DISTINCT ON (geocoded_address)
    w.ward as ward,
    g.geocoded_address as address,
    g.geocoded_lng as lng,
    g.geocoded_lat as lat,
    g.geocoded_city as city,
    g.geocoded_state as state,
    g.geocode_geojson->'features'->0->'properties'->>'postal' as zip,
    case
     when split_part(g.geocoded_address, ' ', 2) not in ('N', 'E', 'S', 'W') then null
     else split_part(g.geocoded_address, ' ', 2)
    end as cardinal_direction,
    g.geom
  from
    geocodes g
  join
    wards2015 w on st_within(g.geom, w.wkb_geometry)
  where
      g.geocoded_city = 'Chicago' and (
        g.geocode_accuracy_type = 'range_interpolation' or
        g.geocode_accuracy_type = 'rooftop' or
        g.geocode_accuracy_type = 'intersection' or
        g.geocode_accuracy_type = 'point'
      )
  order by geocoded_address, geocode_accuracy desc
;

alter table blocks
  add column id serial primary key;

create index on blocks (address);
create index on blocks (ward);
create index on wards2015 (ward);
