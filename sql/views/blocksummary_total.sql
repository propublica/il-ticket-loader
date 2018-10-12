create table blocksummary_total
as
  SELECT
      b.geocoded_address,
      sum(b.ticket_count) AS ticket_count,
      sum(b.amount_due) AS amount_due,
      sum(b.fine_level1_amount) AS fine_level1_amount,
      sum(b.fine_level2_amount) AS fine_level2_amount,
      sum(b.total_payments) AS total_payments
    FROM blocksummary_yearly b
    GROUP BY b.geocoded_address
    ORDER BY (sum(b.ticket_count)) DESC
    ;

alter table blocksummary_total
  add constraint blocksummary_total_pk primary key (geocoded_address);
