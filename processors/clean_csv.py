import csv
import re
import sys

address_re = re.compile(r"(\d*)(\d{2})(\s)", re.IGNORECASE)

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
    return address_re.sub(r'\g<1>00\g<3>', address).lower()


def clean(filename):
    writer = csv.writer(sys.stdout, quoting=csv.QUOTE_ALL)
    with open(filename) as f:
        reader = csv.reader(f, delimiter="$", quotechar='"')
        headers = next(reader)
        writer.writerow(headers)

        for row in reader:
            try:
                row = clean_commas(row)
                row = clean_location(row)
                writer.writerow(row)
            except IndexError:
                print(row, file=sys.stderr)


if __name__ == '__main__':
    clean(sys.argv[1])
