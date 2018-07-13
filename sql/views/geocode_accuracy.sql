create or replace view geocode_accuracy
as
  select
    total,
    chicago_total,
    chicago_total::decimal / total as chicago_pct
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
  ) summary;
