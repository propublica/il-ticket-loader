create table if not exists blocksyearly as
  select
    b.address,
    p.violation_code,
    p.ticket_queue,
    p.hearing_disposition,
    p.year,
    p.unit_description,
    p.notice_level,
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
  GROUP BY b.address, p.year, p.notice_level, p.unit_description, p.hearing_disposition, p.ticket_queue, p.violation_code
;
