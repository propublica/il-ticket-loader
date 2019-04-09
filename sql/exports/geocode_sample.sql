select
	null as correct_ward,
	null as correct_address,
	null as ambiguous_address,
	null as notes,
	g.address,
	g.geocoded_address,
	b.ward,
  b.tract_id,
  b.community_area_name,
  b.community_area_number,
	g.geocoded_lat,
	g.geocoded_lng,
	g.geocode_accuracy,
	g.geocode_accuracy_type
from blocks b tablesample bernoulli(20)
join geocodes g on
	g.geocoded_address = b.address
where
    g.geocoded_city = 'Chicago' and (
      g.geocode_accuracy_type = 'range_interpolation' or
      g.geocode_accuracy_type = 'rooftop' or
      g.geocode_accuracy_type = 'intersection' or
      g.geocode_accuracy_type = 'point'
    )
limit 400

