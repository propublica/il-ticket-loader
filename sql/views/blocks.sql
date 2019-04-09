create table if not exists blocks as
  select distinct on (geocoded_address)
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
		bg.tractce,
		bg.geoid as bg_geoid,
    g.geom
  from
    geocodes g
  join
    wards2015 w on st_within(g.geom, w.wkb_geometry)
	join tl_2016_17_bg bg on
		st_within(g.geom, bg.wkb_geometry)
  where
      g.geocode_accuracy > 0.7 and
      g.geocoded_city = 'Chicago' and (
        g.geocode_accuracy_type = 'range_interpolation' or
        g.geocode_accuracy_type = 'rooftop' or
        g.geocode_accuracy_type = 'intersection' or
        g.geocode_accuracy_type = 'point' or
        g.geocode_accuracy_type = 'ohare'
      )
  order by geocoded_address, geocode_accuracy desc
;

create index on blocks (address);
create index on blocks (ward);
create index on wards2015 (ward);
