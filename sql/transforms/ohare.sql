-- from map click
-- -87.89638770082189, 41.9813643497081

update geocodes
  set
    geocoded_address = 'O''hare International Airport',
    geocoded_lat = 41.9818,
    geocoded_lng = -87.8982,
    geocode_accuracy = 1,
    geocoded_city = 'Chicago',
    geocoded_state = 'IL',
    geocode_accuracy_type = 'ohare',
    geocoded_zip = null,
    geocode_geojson = null,
    geom = ST_SetSRID(ST_MakePoint(-87.8982, 41.9818), 4326)
  where
    address like '%ohare%' or
    address like '%o''hare' or
    address like '%terminal%' or
    address like '% ord,%' or
    address like '% hare,%'
;

