create table if not exists geoblocks as
  select
    b.geom,
    b.ward,
    b.address,
    sum(t.ticket_count) as ticket_count,
    sum(t.total_payments) as total_payments,
    sum(t.current_amount_due) as current_amount_due,
    sum(t.fine_level1_amount) as fine_level1_amount
  from
    blocksyearly t
  join
    blocks b
      on b.address = t.address
  where t.year >= 2013 and t.year <= 2017
  group by b.geom, b.ward, b.address
;

