import geocoder
import records
import json
import sys

db = records.Database('postgres://localhost/iltickets')

def process(limit, offset):
    rows = db.query("""
        select
            distinct address
        from parking
        where geocode is null
        limit :limit
        offset :offset
    """, offset=offset, limit=limit)

    for row in rows:
        geocode = geocoder.google(row['address'])
        db.query("""
            update
                parking
            set
                geocode=:geocode
            where
                address=:address
        """, geocode=json.dumps(geocode.geojson), address=row['address'])


if __name__ == '__main__':
    limit = sys.argv[1]
    offset = sys.argv[2]
    process(limit, offset)
