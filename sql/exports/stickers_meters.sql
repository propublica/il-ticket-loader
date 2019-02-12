with sticker_counts as (
  select
    count(*) as sticker_count
    from parking
    where
      (violation_code = '0964125' or violation_code = '0976170' or violation_code = '0964125B') and year >= 2013 and year <= 2017
),
meter_counts as (
select
count(*) as meter_count
  from parking
  where
    (violation_code = '0976160B' or violation_code = '0976160F') and year >= 2013 and year <= 2017
),
counts as (
  select  
	count(*) 
  from parking
  where
    year >= 2013 and year <= 2017
)
select
  m.meter_count,
  s.sticker_count,
  c.count as total,
  m.meter_count::float / c.count::float as meter_pct,
  s.sticker_count::float / c.count::float as sticker_pct
from sticker_counts s, meter_counts m, counts c
