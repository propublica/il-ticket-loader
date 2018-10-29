create table violations as
  select
    distinct
      violation_code,
      trim(violation_description) as violation_description
  from parking
;

create index if not exists on violations (violation_code);
