import geocoder
import records
import json
import sys

db = records.Database('postgres://localhost/iltickets')

def process(limit, offset):
    rows = db.query("""
        select
            p.address as address
        from
            parking p
        left join
            geocodes g on
                p.address = g.address
        where
            g.address is null
        group by p.address
        order by p.address
        limit :limit
        offset :offset
    """, offset=offset, limit=limit)

    for row in rows:
        geocode = geocoder.google(row['address'])
        geojson = geocode.geojson
        try:
            db.query("""
                insert into
                    geocodes (
                        address,
                        geocoded_address,
                        geocoded_lng,
                        geocoded_lat,
                        geocoded_city,
                        geocoded_state,
                        geocode_accuracy,
                        geocode_geojson
                    ) values (
                        :address,
                        :geocoded_address,
                        :geocoded_lng,
                        :geocoded_lat,
                        :geocoded_city,
                        :geocoded_state,
                        :geocode_accuracy,
                        :geocode_geojson
                    )
                on conflict do nothing
            """,
                geocode_geojson=json.dumps(geocode.geojson),
                geocoded_address=geojson['features'][0]['properties']['address'],
                geocoded_lng=geojson['features'][0]['geometry']['coordinates'][0],
                geocoded_lat=geojson['features'][0]['geometry']['coordinates'][1],
                geocoded_city=geojson['features'][0]['properties']['city'],
                geocoded_state=geojson['features'][0]['properties']['state'],
                geocode_accuracy=geojson['features'][0]['properties']['accuracy'],
                address=row['address']
            )
            print('geocoded %s -> %s' % (row['address'], geojson['features'][0]['properties']['address']))
        except:
            print('error w %s' % row['address'], file=sys.stderr)


if __name__ == '__main__':
    limit = sys.argv[1]
    offset = sys.argv[2]
    process(limit, offset)
