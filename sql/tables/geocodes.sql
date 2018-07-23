CREATE TABLE public.geocodes (
  id serial primary key,
  address character varying,
  geocoded_address character varying,
  geocoded_lng double precision,
  geocoded_lat double precision,
  geocoded_city character varying,
  geocoded_state character varying,
  geocode_accuracy character varying,
  geocode_geojson jsonb,
  geom geometry(Geometry,4326)
)
