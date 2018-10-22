"""
Test database access.

Assumes 2018 parking ticket data has been loaded. Run:

```
YEARS=2018 make all
```

Tests may be run against a full dataset.
"""
import os
import pytest
import records


START_DATE = '2018-01-01'


@pytest.fixture
def db():
    return records.Database(os.environ.get('ILTICKETS_DB_URL'))


def test_record_length(db):
    results = db.query("""
        select
            count(*) as count
        from
            parking
        where
            issue_date >= :start
    """, start=START_DATE)

    # The number of rows imported should be the number of lines in the source file,
    # minus 2 for the header and total rows included in the files.
    num_rows = results.first().get('count')
    assert num_rows == 769219
