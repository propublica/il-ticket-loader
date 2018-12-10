# -*- coding: utf-8 -*-
import json
import os
import records
import scrapy

from urllib.parse import urlencode

GEOCODIO_ACCESS_TOKEN = os.environ.get('GEOCODIO_ACCESS_TOKEN', '')
URL_TMPL = 'https://api.geocod.io/v1.3/geocode?{params}'

db = records.Database(os.environ.get('ILTICKETS_DB_URL', 'postgres://localhost/iltickets'))

class GeocodioSpider(scrapy.Spider):
    name = 'geocodio'

    def _clean_address(self, address):
        cleaned = address.replace("'", "")
        return cleaned

    def start_requests(self):
        rows = db.query("""
            select
                address
            from
                geocodes
            where
                (geocode_accuracy_type is null or
                geocode_accuracy_type == 'place' or
                geocode_accuracy_type == 'street_center')
        """)

        for row in rows:
            address = self._clean_address(row['address'])
            params = {
                'q': address,
                'api_key': GEOCODIO_ACCESS_TOKEN,
            }
            url = URL_TMPL.format(params=urlencode(params))
            yield scrapy.Request(url=url, callback=self.parse, meta={'address': row['address']})

    def parse(self, response):
        geojson = json.loads(response.body)
        item = {
            'address': response.meta['address'],
            'geocoded_address': geojson['results'][0]['formatted_address'],
            'geocoded_lng': geojson['results'][0]['location']['lng'],
            'geocoded_lat': geojson['results'][0]['location']['lat'],
            'geocoded_city': geojson['results'][0]['address_components']['city'],
            'geocoded_state': geojson['results'][0]['address_components']['state'],
            'geocoded_zip': geojson['results'][0]['address_components']['zip'],
            'geocode_accuracy': geojson['results'][0]['accuracy'],
            'geocode_accuracy_type': geojson['results'][0]['accuracy_type'],
            'geocode_geojson': response.text,
        }
        yield item


