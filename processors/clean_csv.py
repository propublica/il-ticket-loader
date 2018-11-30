import csv
import re
import sys
from Crypto.Hash import SHA256


block_re = re.compile(r"0*(\d*)(\d{2})(\s)", re.IGNORECASE)
twodigit_re = re.compile(r"^(00 )(.*)", re.IGNORECASE)


def clean_quotes(row):
    """
    Handle unquoted quotes in fields from CANVAS.
    """
    if row[8].startswith('WINDOWS MISSING OR CRACKED BEYOND') or row[8].startswith('SUSPENSION MODIFIED BEYOND'):
        fixed_cols = row[8].replace('"', '').split('$')
        row = row[:8] + fixed_cols + row[9:]
    return row


def clean_location(row, corrections):
    """
    Clean up a parking address for geocoding by adding the Chicago, IL stuff to the end.
    """
    address = row[2].strip().lower()
    address = clean_address(address, corrections)
    address = normalize_block(address)
    address = "{}, Chicago, IL".format(address)
    row.append(address)
    return row


def clean_address(address, corrections):
    """
    Use Matt Chapman's manual mapping
    """
    parts = block_re.split(address)
    street_part = parts[-1]
    if street_part in corrections.keys():
        parts[-1] = corrections[street_part]
    ret = ''.join(parts)
    return ret


def normalize_block(address):
    """
    Block-level address normalization

    6232 S. Loomis -> 6200 S. Loomis
    15 North State St -> 1 North State St
    """
    ret = block_re.sub(r'\g<1>00\g<3>', address)
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


def extract_hour(datestring):
    """
    Return hour part of date string as integer.
    """
    hour = int(datestring[11:13])
    cycle = datestring[17:19]
    if hour == 12 and cycle == 'am':
        hour = 0
    if cycle == 'pm':
        hour += 12
    return hour


def calculate_penalty(row):
    """
    Calculate penalty as `(current_amount_due + total_paid) - fine_level1_amount`
    """

    # If current amount due is negative or ticket was dismissed,
    # penalty is null
    if float(row[14]) < 0 or row[16] == 'Dismissed':
        penalty = None
    else:
        penalty = (float(row[14]) + float(row[15])) - float(row[12])

    return penalty

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


def add_hour(row):
    """
    Add month to row.
    """
    row.append(extract_hour(row[1]))
    return row


def add_penalty(row):
    """
    Add penalty to row.
    """
    row.append(calculate_penalty(row))
    return row


def get_corrections(datafile='data/geodata/corrections.csv'):
    """
    Get corrections
    """
    with open(datafile, 'r') as f:
        corrections_reader = csv.reader(f)
        next(corrections_reader)
        corrections = { bad: good for good, bad in corrections_reader }
    return corrections


def clean(data_filename, salt_filename):
    """
    Clean up parking CSV.
    """
    with open(salt_filename, 'r') as f:
        salt = f.read()

    corrections = get_corrections()

    writer = csv.writer(sys.stdout, quoting=csv.QUOTE_ALL)

    with open(data_filename) as f:
        addcol = False

        reader = csv.reader((line.replace('\0','') for line in f), delimiter="$", quotechar='"')
        headers = next(reader)

        # 1996-2006 have this field, newer records do not
        if 'Reason for Dismissal' not in headers:
            headers = headers[:-1] + ['Reason for Dismissal'] + headers[-1:]
            addcol = True
        headers += ['address', 'license_hash', 'year', 'month', 'hour', 'penalty']
        writer.writerow(headers)

        for row in reader:
            try:
                row = clean_quotes(row)
                if addcol:
                    row = row[:-1] + [''] + row[-1:]
                row = clean_location(row, corrections)
                row = hash_plates(row, salt)
                row = add_year(row)
                row = add_month(row)
                row = add_hour(row)
                row = add_penalty(row)
                writer.writerow(row)
            except IndexError:
                print(row, file=sys.stderr)


if __name__ == '__main__':
    clean(sys.argv[1], sys.argv[2])
