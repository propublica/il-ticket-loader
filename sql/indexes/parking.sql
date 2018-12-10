create index if not exists parking_cluster on parking (address, violation_code, year);
create index if not exists parking_address on parking (address);
create index if not exists parking_year on parking (year);
