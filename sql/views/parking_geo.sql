create table parking_geo as

select
  p.*,
	g.geocoded_address,
  b.ward
from parking p
join
  geocodes g on
    p.address = g.address
full join blocks b on
		g.geocoded_address = b.address;
