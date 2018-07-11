import geocoder
import records
import sys

db = records.Database('postgres://localhost/iltickets')

def process(offset):
    rows = db.query("""
        select
            distinct violation_location, zipcode
        from parking
        limit :offset
        offset :offset
    """, offset=offset)
    import ipdb; ipdb.set_trace();
    # geocoder.google(
    pass


if __name__ == '__main__':
    offset = sys.argv[1]
    process(offset)
