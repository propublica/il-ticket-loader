create table if not exists wardsviolations5yr as
  select
		distinct on (w.ward, w.violation_code)
		w.ward,
		w.violation_code,
		v.violation_description,
    sum(w.ticket_count) as ticket_count,
		sum(w.fine_level1_amount)::float / sum(w.ticket_count)::float as avg_per_ticket 
  from wardsyearly w
	join violations v
		on w.violation_code = v.violation_code
	where year >= 2013 and year <= 2017
	group by w.ward, w.violation_code, v.violation_description
	order by w.ward, w.violation_code, ticket_count desc
  ;
