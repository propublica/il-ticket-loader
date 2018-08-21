import csv
import re
import sys
from Crypto.Hash import SHA256

block_re = re.compile(r"(\d*)(\d{2})(\s)", re.IGNORECASE)
twodigit_re = re.compile(r"^(00 )(.*)", re.IGNORECASE)


def clean_commas(row):
    if row[8].startswith('WINDOWS MISSING OR CRACKED BEYOND') or row[8].startswith('SUSPENSION MODIFIED BEYOND'):
        fixed_cols = row[8].replace('"', '').split('$')
        row = row[:8] + fixed_cols + row[9:]
    return row


def clean_location(row):
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
    hash = SHA256.new()
    plate = row[3]
    to_hash = (plate + salt).encode('utf-8')
    hash.update(to_hash)
    row[3]= hash.hexdigest()
    return row


def clean(data_filename, salt_filename):
    with open(salt_filename, 'r') as f:
        salt = f.read()
    writer = csv.writer(sys.stdout, quoting=csv.QUOTE_ALL)
    with open(data_filename) as f:
        reader = csv.reader(f, delimiter="$", quotechar='"')
        headers = next(reader)
        writer.writerow(headers)

        for row in reader:
            try:
                row = clean_commas(row)
                row = clean_location(row)
                row = hash_plates(row, salt)
                writer.writerow(row)
            except IndexError:
                print(row, file=sys.stderr)


if __name__ == '__main__':
    clean(sys.argv[1], sys.argv[2])
