create or replace view geocodes_communityareas
as
  select
    g.address,
    g.geocoded_address,
    c.community,
    g.geocoded_lat,
    g.geocoded_lng,
    g.geocoded_city,
    g.geocoded_state,
    g.geocode_accuracy
  from
    geocodes g
  inner join
    community_area_geography c on st_within(g.geom, c.wkb_geometry)
  ;
