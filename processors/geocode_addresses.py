import geocoder
import records
import json
import sys


db = records.Database('postgres://localhost/iltickets')

def process(limit, offset):
    rows = db.query("""
        select
            id,
            address
        from
            geocodes
        where
            geocode_geojson is null and
            id >= :min and
            id < :max
    """, min=offset, max=offset+limit)

    for row in rows:
        geocode = geocoder.google(row['address'])
        geojson = geocode.geojson

        try:
            db.query("""
                update geocodes set
                    geocoded_address=:geocoded_address,
                    geocoded_lng=:geocoded_lng,
                    geocoded_lat=:geocoded_lat,
                    geocoded_city=:geocoded_city,
                    geocoded_state=:geocoded_state,
                    geocode_accuracy=:geocode_accuracy,
                    geocode_geojson=:geocode_geojson
                where
                    id=:id
            """,
                geocode_geojson=json.dumps(geocode.geojson),
                geocoded_address=geojson['features'][0]['properties']['address'],
                geocoded_lng=geojson['features'][0]['geometry']['coordinates'][0],
                geocoded_lat=geojson['features'][0]['geometry']['coordinates'][1],
                geocoded_city=geojson['features'][0]['properties'].get('city'),
                geocoded_state=geojson['features'][0]['properties'].get('state'),
                geocode_accuracy=geojson['features'][0]['properties'].get('accuracy'),
                id=row['id']
            )
            print('geocoded %s -> %s (id# %s)' % (row['address'], geojson['features'][0]['properties']['address'], row['id']))
        except:
            print('error w/ %s' % row['address'], file=sys.stderr)


if __name__ == '__main__':
    limit = sys.argv[1]
    offset = sys.argv[2]
    process(limit, offset)
