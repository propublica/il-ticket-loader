create table public.wardmeta (
  ward character varying(2) primary key,
  alderman character varying,
  address character varying,
  city character varying,
  state character varying,
  zipcode character varying(5),
  ward_phone character varying(14),
  ward_fax character varying(14),
  email character varying,
  website character varying,
  location character varying,
  city_hall_address character varying,
  city_hall_city character varying,
  city_hall_state character varying,
  city_hall_zipcode character varying,
  city_hall_phone character varying(14)
);
