# -*- coding: utf-8 -*-
import logging
from twisted.enterprise import adbapi


class GeocodeparkingDatabasePipeline(object):
    def __init__(self):
        self.logger = logging.getLogger(__name__)

        dbargs = {
            'host': 'localhost',
            'database': 'iltickets',
        }
        dbpool = adbapi.ConnectionPool('psycopg2', **dbargs)
        self.dbpool = dbpool


    def process_item(self, item, spider):
        d = self.dbpool.runInteraction(self._insert, item, spider)
        d.addErrback(self._handle_error, item, spider)
        d.addBoth(lambda _: item)
        self.logger.info("added {address} to db".format(**item))
        return d

    def _insert(self, conn, item, spider):
        query = """
            update geocodes set
                address='{address}',
                geocoded_address='{geocoded_address}',
                geocoded_lng={geocoded_lng},
                geocoded_lat={geocoded_lat},
                geocoded_city='{geocoded_city}',
                geocoded_state='{geocoded_state}',
                geocoded_zip='{geocoded_zip}',
                geocode_accuracy='{geocode_accuracy}',
                geocode_accuracy_type='{geocode_accuracy_type}',
                geocode_geojson='{geocode_geojson}'
            where
                address='{address}'
        """.format(**item)
        ret = conn.execute(query)

    def _handle_error(self, failure, item, spider):
        self.logger.error(failure)
