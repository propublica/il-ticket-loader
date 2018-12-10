create table if not exists wardsyearlytotals as
  select
    w.ward,
    w.year,
    sum(w.ticket_count) as ticket_count,
    sum(w.total_payments) as total_payments,
    sum(w.current_amount_due) as current_amount_due,
    sum(w.fine_level1_amount) as fine_level1_amount
  from
    wardsyearly w
  GROUP BY w.ward, w.year
;

