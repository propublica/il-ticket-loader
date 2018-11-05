
with wards_stats as (
  select
    min(ticket_count) as min_ticket_count,
    max(ticket_count) as max_ticket_count
  from wardstotals
)

select
  ward,
  ticket_count,
  ticket_count_rank,
  width_bucket(ticket_count, min_ticket_count, max_ticket_count, 10) as ticket_count_bucket

;
