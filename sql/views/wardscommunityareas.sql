create table if not exists wardscommunityareas as 
  select
    w.ward,
    c.community
  from
    wards2015 w
  join communityareas c on
    ST_intersects(c.wkb_geometry, w.wkb_geometry)
  order by ward
