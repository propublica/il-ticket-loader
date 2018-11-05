import pytest
from processors import clean_csv


TEST_ADDRESSES = [
    ('04 W BLACKHAWK', '1 w blackhawk'),
    ('5627 S CALUMET', '5600 s calumet'),
    ('01800 N NEWCASTLE', '1800 n newcastle'),
    ('2319 W FOSTER', '2300 w foster'),
    ('03634 W SHAKESPEARE', '3600 w shakespeare'),
    ('420 W 63RD ST', '400 w 63rd st'),
]


TEST_BAD_ROWS = [
    ['68862242', '01/01/2018 08:45 am', '8731 S CRANDON', 'V739544', 'IL', 'PAS', '60629', '0976210B', 'WINDOWS MISSING OR CRACKED BEYOND 6"$145"', 'CPD-Other', 'OLDS', '25', '50', '0', '0', 'Dismissed', '04/01/2018', '', '', '0', '17169'],
    ['68783813', '01/01/2018 11:59 pm', '2300 N LAWNDALE', '2219916', 'IL', 'PAS', '606393518', '0976210B', 'WINDOWS MISSING OR CRACKED BEYOND 6"$25"', 'CPD', 'CADI', '25', '50', '0', '0', 'Dismissed', '03/28/2018', '', 'Not Liable', '5210502980', '8242'],
    ['68705090', '01/23/2018 12:46 am', '62 E CERMAK', '867T935', 'IL', 'TMP', '60653', '0976100A', 'SUSPENSION MODIFIED BEYOND 3"$1"', 'CPD', 'FORD', '25', '50', '50', '0', 'Notice', '02/01/2018', 'SEIZ', '', '5211010250', '3377'],
]


TEST_PENALTY_ROWS = [
    (['60607661', '01/03/2012 12:39 pm', '4400 N PULASKI', 'P230623', 'IL', 'PAS', '60609', '0964125', 'NO CITY STICKER OR IMPROPER DISPLAY', '501', 'Miscellaneous', 'JEEP', '120', '240', '292.8', '0', 'Notice', '02/09/2012', 'DLS', '', '5122261100', '83'], 172.8),
    (['58864340', '01/03/2012 12:39 pm', '5951 W COURTLAND', 'A783051', 'IL', 'PAS', '606342633', '0976160F', 'EXPIRED PLATES OR TEMPORARY REGISTRATION', '23', 'CPD', 'GEO', '50', '100', '0', '122', 'Paid', '05/13/2015', 'SEIZ', '', '5145682080', '4112'], 72),
    (['9181812288', '01/03/2012 12:29 pm', '3141 N LINCOLN AV', '3417204', 'IL', 'PAS', '', '0964190', 'EXPIRED METER OR OVERSTAY', '498', 'DOF', 'FORD', '50', '100', '0', '50', 'Paid', '01/10/2012', '', '', '0', '746'], 0),
    (['60355378', '01/01/2012 03:07 am', '211 W DIVISION', 'K635156', 'IL', 'PAS', '600761720', '0964060', '3-7 AM SNOW ROUTE', '18', 'CPD', 'NISS', '60', '120', '-60', '120', 'Paid', '02/21/2012', 'DETR', '', '5146624670', '7013'], None),
    (['57592040', '01/01/2012 12:02 am', '100 N LAKESHORE DR', '184199', 'IL', 'OTH', '', '0964150B', 'PARKING/STANDING PROHIBITED ANYTIME', '145', 'CPD-Other', 'HOND', '60', '120', '0', '0', 'Dismissed', '04/01/2012', '', '', '0', '1568'], None),
]


# (input, (month, year))
TEST_DATES = [
    ('03/05/2005 09:05 pm', (3, 2005)),
    ('06/25/1999 04:00 pm', (6, 1999)),
    ('10/02/2011 03:18 pm', (10, 2011)),
]

@pytest.mark.parametrize("input,expected", TEST_ADDRESSES)
def test_clean_address(input, expected):
    assert clean_csv.clean_address(input) == expected


@pytest.mark.parametrize("row", TEST_BAD_ROWS)
def test_clean_row(row):
    clean_row = clean_csv.clean_quotes(row)
    assert len(clean_row) == len(row) + 1


@pytest.mark.parametrize("input,expected", TEST_DATES)
def test_extract_month(input, expected):
    month = clean_csv.extract_month(input)
    assert month == expected[0]


@pytest.mark.parametrize("input,expected", TEST_DATES)
def test_extract_year(input, expected):
    month = clean_csv.extract_year(input)
    assert month == expected[1]

@pytest.mark.parametrize("input,expected", TEST_PENALTY_ROWS)
def test_penalty(input, expected):
    penalty = clean_csv.calculate_penalty(input)
    assert penalty == expected
