create table blocksummary_yearly
as
  SELECT
      g.geocoded_address,
      b.year,
      b.violation_code,
      b.violation_description,
      sum(b.ticket_count) AS ticket_count,
      sum(b.amount_due) AS amount_due,
      sum(b.fine_level1_amount) AS fine_level1_amount,
      sum(b.fine_level2_amount) AS fine_level2_amount,
      sum(b.total_payments) AS total_payments
     FROM blocksummary_intermediate b
       JOIN geocodes g ON b.address = g.address
    WHERE g.geocoded_address is not null
    GROUP BY g.geocoded_address, b.year, b.violation_code, b.violation_description
    ORDER BY (sum(b.ticket_count)) DESC
    ;

alter table blocksummary_yearly
  add column id serial primary key;

create index on blocksummary_yearly (geocoded_address);
