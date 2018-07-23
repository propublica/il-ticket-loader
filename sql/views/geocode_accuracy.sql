create or replace view geocode_accuracy
as
  select
    total,
    chicago_total,
    chicago_total::decimal / total as chicago_pct,
    citysticker_total,
    geocode_citysticker_total,
    geocode_citysticker_total::decimal / citysticker_total as geocode_citysticker_pct
  from (
    select
      count(p.ticket_number) as total,
      count(p.ticket_number) FILTER (
        where g.geocode_geojson is not null and
        g.geocode_accuracy != 'GEOMETRIC_CENTER' and
        g.geocoded_city = 'Chicago'
      ) as chicago_total
    from parking p
    join
      geocodes g on p.address = g.address
  ) chicago_summary,
  (
    select
      count(*) as citysticker_total
    from
      parking p
    where
      (p.violation_code = '0964125' or p.violation_code = '0964125B')
  ) citysticker_summary,
  (
    select count(*) as geocode_citysticker_total
    from
      parking p
    inner join
      geocodes g on p.address = g.address
    inner join
      community_area_geography c on st_within(g.geom, c.wkb_geometry)
    where
      (p.violation_code = '0964125' or p.violation_code = '0964125B')
      and g.geocode_accuracy != 'GEOMETRIC_CENTER'
  ) geocode_summary
;
