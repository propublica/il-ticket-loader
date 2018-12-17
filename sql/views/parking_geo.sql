create table parking_geo as

select
  p.*,
  b.ward,
  g.geocode_accuracy,
  g.geocode_accuracy_type,
  g.geocoded_address,
  g.geocoded_lng,
  g.geocoded_lat,
  g.geocoded_city,
  g.geocoded_state
from parking p
join
  geocodes g on
    p.address = g.address
join blocks b on
  g.geocoded_address = b.address
where b.ward is not null
;
