create table citywideyearly as

with current_amount_due_sum as (
  select
    year,
    sum(current_amount_due) as current_amount_due
  from parking
  group by year
),
other_sums as (
  select
    year,
    count(*) as ticket_count,
    sum(total_payments) as total_payments,
    sum(fine_level1_amount) as fine_level1_amount
  from parking
  group by year
)

select
  c.year,
  c.current_amount_due,
  o.ticket_count,
  o.total_payments,
  o.fine_level1_amount

from current_amount_due_sum c
join other_sums o
	on o.year = c.year

;
