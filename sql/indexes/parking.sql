create index if not exists parking_cluster on parking (address, violation_code, year);
cluster parking using parking_cluster;
