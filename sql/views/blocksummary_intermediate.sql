create table if not exists blocksummary_intermediate as
  SELECT
      p.address,
      p.violation_code,
      extract(year from p.issue_date) as year,
      count(ticket_number) AS ticket_count,
      sum(p.current_amount_due) AS amount_due,
      sum(p.fine_level1_amount) AS fine_level1_amount,
      sum(p.fine_level2_amount) AS fine_level2_amount,
      sum(p.total_payments) AS total_payments
     FROM parking p
    GROUP BY p.address, p.violation_code, year
;

create index on blocksummary_intermediate (address);
