insert into geocodes (address) select distinct(address) from parking;
alter table geocodes add column id serial primary key;
