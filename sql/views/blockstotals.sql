create table if not exists blockstotals as
  select
    b.address,
    sum(ticket_count) as ticket_count,
    sum(b.total_payments) as total_payments,
    sum(b.current_amount_due) as current_amount_due,
    sum(b.fine_level1_amount) as fine_level1_amount
  from
    blocksyearly b
  group by address
;
