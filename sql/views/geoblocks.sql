create table if not exists geoblocks as
  select
    b.geom,
    b.ward,
    b.address,
    t.ticket_count,
    t.total_payments,
    t.current_amount_due,
    t.fine_level1_amount
  from
    blockstotals t
  join
    blocks b
      on b.address = t.address
;

