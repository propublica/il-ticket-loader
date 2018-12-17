create table if not exists wardsyearly as
  select
    w.ward,
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
    wards2015 w
  join
    blocks b
    on b.ward = w.ward
  join
    geocodes g
    on b.address = g.geocoded_address
  join
    parking p
    on p.address = g.address
  where
      g.geocoded_city = 'Chicago' and (
        g.geocode_accuracy_type = 'range_interpolation' or
        g.geocode_accuracy_type = 'rooftop' or
        g.geocode_accuracy_type = 'intersection' or
        g.geocode_accuracy_type = 'point'
      )
  GROUP BY w.ward, p.year, p.notice_level, p.unit_description, p.hearing_disposition, p.ticket_queue, p.violation_code
;
