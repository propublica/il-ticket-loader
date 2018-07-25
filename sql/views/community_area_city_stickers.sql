create or replace view community_area_city_stickers
as
  select
    c.community,
    count(p.ticket_number) as tickets,
    count(p.ticket_number) / s.tot_hh as per_household,
    s.tot_pop as total_population,
    s.tot_hh as total_households,
    s.white,
    s.white / s.tot_pop as white_pct,
    s.black,
    s.black / s.tot_pop as black_pct,
    s.hisp,
    s.hisp / s.tot_pop as hisp_pct,
    s.asian,
    s.asian / s.tot_pop as asian_pct,
    s.other,
    s.other / s.tot_pop as other_pct,
    s.medinc
  from parking p
  inner join
    geocodes g on p.address = g.address
  inner join
    community_area_geography c on st_within(g.geom, c.wkb_geometry)
  inner join
    community_area_stats s on s.geog = c.community
  where
    (p.violation_code = '0964125' or
    p.violation_code = '0964125B')
    and g.geocode_accuracy != 'GEOMETRIC_CENTER'
  group by
    c.community,
    s.tot_pop,
    s.tot_hh,
    s.white,
    s.black,
    s.hisp,
    s.asian,
    s.other,
    s.medinc
  order by per_household desc;
