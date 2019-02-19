with alltickets as (select
  p.ticket_number,
  p.issue_date,
  p.violation_location,
  p.license_hash as license_plate_number,
  p.license_plate_state,
  p.license_plate_type,
  p.zipcode,
  p.violation_code,
  p.violation_description,
  p.unit,
  p.unit_description,
  p.vehicle_make,
  p.fine_level1_amount,
  p.fine_level2_amount,
  p.current_amount_due,
  p.total_payments,
  p.ticket_queue,
  p.ticket_queue_date,
  p.notice_level,
  p.notice_number,
  p.hearing_disposition,
  p.officer,
  p.address as normalized_address,
  p.year,
  p.month,
  p.hour,
  b.ward,
  g.geocode_accuracy,
  g.geocode_accuracy_type,
  g.geocoded_address,
  g.geocoded_lng,
  g.geocoded_lat
from parking p
left join
  geocodes g on
    p.address = g.address
left join blocks b on
  g.geocoded_address = b.address
where
  p.year = 2017 and
  (p.violation_code = '0964125' or p.violation_code = '0976170' or p.violation_code = '0964125B')
)

select * from alltickets
order by random()
limit 50000
