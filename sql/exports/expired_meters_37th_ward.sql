select
  sum(ticket_count) as meter_violations from wardsviolations5yr where
  (violation_description = 'EXPIRED METER CENTRAL BUSINESS DISTRICT' or violation_description = 'EXP. METER NON-CENTRAL BUSINESS DISTRICT')
  and ward='37'
