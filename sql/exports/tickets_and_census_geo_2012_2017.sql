select
  p.*,
  b.ward,
	b.tract_id,
	b.blockgroup_geoid,
  b.community_area_number,
  b.community_area_name,
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
where
  p.year >= 2012 and
	p.year <= 2017
