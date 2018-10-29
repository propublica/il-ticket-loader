create table violations as
  select
    distinct
      violation_code,
      trim(violation_description) as violation_description
  from parking
;

create index on violations (violation_code);
