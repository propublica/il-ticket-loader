create table test_data as

with
	all_tickets as (
		select
			g.geocoded_city,
			g.geocode_accuracy_type,
			g.geocode_accuracy,
			p.*
		from parking p
		join geocodes g
			on p.address = g.address
	),
	all_tickets_5yr as (
		select *
		from all_tickets
		where year > 2011 and year < 2017
	),
	total_tickets as (
		select
			count(*) as total_tickets
		from all_tickets
	),
	total_accurate_tickets as (
		select
			count(*) as total_accurate_tickets
		from all_tickets
		where
        geocode_accuracy > 0.7 and
        geocoded_city = 'Chicago' and (
          geocode_accuracy_type = 'range_interpolation' or
          geocode_accuracy_type = 'rooftop' or
          geocode_accuracy_type = 'intersection' or
          geocode_accuracy_type = 'point' or
          geocode_accuracy_type = 'ohare'
        )
	),
	total_tickets_5yr as (
		select
			count(*) as total_tickets_5yr
		from all_tickets_5yr
	),
	total_accurate_tickets_5yr as (
		select
			count(*) as total_accurate_tickets_5yr
		from all_tickets_5yr
		where
      geocode_accuracy > 0.7 and
      geocoded_city = 'Chicago' and (
        geocode_accuracy_type = 'range_interpolation' or
        geocode_accuracy_type = 'rooftop' or
        geocode_accuracy_type = 'intersection' or
        geocode_accuracy_type = 'point' or
        geocode_accuracy_type = 'ohare'
      )
	),
  citywide_totals as (
    select
      sum(current_amount_due) as citywide_amount_due
    from all_tickets
  ),
  ward_totals as (
    select
      sum(current_amount_due) as wards_amount_due
    from wardsyearlytotals
  )
select
	total_tickets,
	total_accurate_tickets,
	total_accurate_tickets::decimal / total_tickets::decimal as accurate_tickets_pct,
	total_tickets_5yr,
	total_accurate_tickets_5yr,
	total_accurate_tickets_5yr::decimal / total_tickets_5yr::decimal as accurate_tickets_5yr_pct,
  citywide_amount_due,
  wards_amount_due,
  wards_amount_due / citywide_amount_due as ward_amount_due_pct
from total_accurate_tickets, total_tickets, total_accurate_tickets_5yr, total_tickets_5yr, citywide_totals, ward_totals;



