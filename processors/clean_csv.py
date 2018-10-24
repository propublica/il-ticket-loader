import csv
import re
import sys
from Crypto.Hash import SHA256

block_re = re.compile(r"0*(\d*)(\d{2})(\s)", re.IGNORECASE)
twodigit_re = re.compile(r"^(00 )(.*)", re.IGNORECASE)


def clean_commas(row):
    """
    Handle unquoted commas in fields from CANVAS.
    """
    if row[8].startswith('WINDOWS MISSING OR CRACKED BEYOND') or row[8].startswith('SUSPENSION MODIFIED BEYOND'):
        fixed_cols = row[8].replace('"', '').split('$')
        row = row[:8] + fixed_cols + row[9:]
    return row


def clean_location(row):
    """
    Clean up a parking address for geocoding by adding the Chicago, IL stuff to the end.
    """
    address = "{2}, Chicago, IL".format(*row)
    address = clean_address(address)
    row.append(address.strip())
    return row


def clean_address(address):
    """
    Simplistic block-level address parsing

    6232 S. Loomis -> 6200 S. Loomis
    15 North State St -> 1 North State St
    """
    ret = block_re.sub(r'\g<1>00\g<3>', address).lower()
    ret = twodigit_re.sub(r'1 \g<2>', ret)
    return ret


def hash_plates(row, salt):
    """
    Hash license plate number, with salt.
    """
    hash = SHA256.new()
    plate = row[3]
    to_hash = (plate + salt).encode('utf-8')
    hash.update(to_hash)
    row.append(hash.hexdigest())
    return row


def extract_year(datestring):
    """
    Return year part of date string as integer.
    """
    return int(datestring[6:10])


def extract_month(datestring):
    """
    Return month part of date string as integer.
    """
    return int(datestring[:2])


def add_year(row):
    """
    Add year to row.
    """
    row.append(extract_year(row[1]))
    return row


def add_month(row):
    """
    Add month to row.
    """
    row.append(extract_month(row[1]))
    return row


def clean(data_filename, salt_filename):
    """
    Clean up parking CSV.
    """
    addcol = False  # Some source files have "reason for dismissmal" column
    with open(salt_filename, 'r') as f:
        salt = f.read()
    writer = csv.writer(sys.stdout, quoting=csv.QUOTE_ALL)
    with open(data_filename) as f:
        reader = csv.reader((line.replace('\0','') for line in f), delimiter="$", quotechar='"')
        headers = next(reader)

        # 1996-2006 have this field, newer records do not
        if 'Reason for Dismissal' not in headers:
            headers = headers[:-1] + ['Reason for Dismissal'] + headers[-1:]
            addcol = True
        headers += ['address', 'license_hash', 'year', 'month']
        writer.writerow(headers)

        for row in reader:
            try:
                row = clean_commas(row)
                if addcol:
                    row = row[:-1] + [''] + row[-1:]
                row = clean_location(row)
                row = hash_plates(row, salt)
                row = add_year(row)
                row = add_month(row)
                writer.writerow(row)
            except IndexError:
                print(row, file=sys.stderr)


if __name__ == '__main__':
    clean(sys.argv[1], sys.argv[2])
