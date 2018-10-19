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


@pytest.mark.parametrize("input,expected", TEST_ADDRESSES)
def test_clean_address(input, expected):
    assert clean_csv.clean_address(input) == expected
