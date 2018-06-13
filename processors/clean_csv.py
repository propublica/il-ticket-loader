import csv
import multiprocessing
import sys


def clean(filename):
    pool = multiprocessing.Pool(4)
    writer = csv.writer(sys.stdout, quoting=csv.QUOTE_ALL)
    with open(filename) as f:
        reader = csv.reader(f, delimiter="$", quoting=csv.QUOTE_ALL, quotechar='"')
        headers = next(reader)
        writer.writerow(headers)

        for row in reader:
            try:
                if row[8].startswith('WINDOWS MISSING OR CRACKED BEYOND') or row[8].startswith('SUSPENSION MODIFIED BEYOND'):
                    fixed_cols = row[8].replace('"', '').split('$')
                    row = row[:8] + fixed_cols + row[9:]

                writer.writerow(row)
            except IndexError:
                print(row, file=sys.stderr)

if __name__ == '__main__':
    clean(sys.argv[1])
