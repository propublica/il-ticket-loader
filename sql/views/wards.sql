create table if not exists wards as
  select
    ogc_fid,
    ward,
    shape_area,
    shape_leng,
    wkb_geometry,
    st_asgeojson(st_extent(wkb_geometry))::jsonb as extent,
    st_asgeojson(st_centroid(wkb_geometry))::jsonb as centroid,
    st_asgeojson(wkb_geometry)::jsonb as geojson_geometry
  from wards2015
  group by (ogc_fid, ward, shape_area, shape_leng)
;
