create table if not exists blocksyearlytotals as
  select
    p.year,
    b.address,
    count(ticket_number) as ticket_count,
    sum(p.total_payments) as total_payments,
    sum(p.current_amount_due) as current_amount_due,
    sum(p.fine_level1_amount) as fine_level1_amount
  from
    blocks b
  join
    geocodes g
    on b.address = g.geocoded_address
  join
    parking p
    on p.address = g.address
  GROUP BY b.address, p.year
;

