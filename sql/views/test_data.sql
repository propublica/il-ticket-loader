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
			geocoded_city = 'Chicago'
			and geocode_accuracy_type != 'place'
			and geocode_accuracy_type != 'street_center'
	),
	total_very_accurate_tickets as (
		select
			count(*) as total_very_accurate_tickets
		from all_tickets
		where
			geocoded_city = 'Chicago'
			and geocode_accuracy_type != 'place'
			and geocode_accuracy_type != 'street_center'
			and geocode_accuracy >= 0.7
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
			geocoded_city = 'Chicago'
			and geocode_accuracy_type != 'place'
			and geocode_accuracy_type != 'street_center'
	),
	total_very_accurate_tickets_5yr as (
		select
			count(*) as total_very_accurate_tickets_5yr
		from all_tickets_5yr
		where
			geocoded_city = 'Chicago'
			and geocode_accuracy_type != 'place'
			and geocode_accuracy_type != 'street_center'
			and geocode_accuracy >= 0.7
	)
select
	total_tickets,
	total_accurate_tickets,
	total_very_accurate_tickets,
	total_accurate_tickets::decimal / total_tickets::decimal as accurate_tickets_pct,
	total_very_accurate_tickets::decimal / total_tickets::decimal as very_accurate_tickets_pct,
	total_tickets_5yr,
	total_accurate_tickets_5yr,
	total_very_accurate_tickets_5yr,
	total_accurate_tickets_5yr::decimal / total_tickets_5yr::decimal as accurate_tickets_5yr_pct,
	total_very_accurate_tickets_5yr::decimal / total_tickets_5yr::decimal as very_accurate_tickets_5yr_pct
from total_accurate_tickets, total_very_accurate_tickets, total_tickets, total_accurate_tickets_5yr, total_very_accurate_tickets_5yr, total_tickets_5yr;



