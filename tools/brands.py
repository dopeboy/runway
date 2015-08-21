import argparse
from datetime import date
import json


def main(args):
    f = open(args.input, 'r')
    brands = []
    for line in f.readlines():
        brand = line.split(',')[0]
        brand_uuid = line.split(',')[1].rstrip('\n')
        brands.append({
            'model': 'apiapp.brand',
            'pk': brand_uuid,
            'fields': {
                'name': brand,
                'created': date.today().isoformat()
                }
            })
    f.close()
    f = open('brands.json', 'w')
    f.write(json.dumps(brands, indent=4, separators=(',', ': ')))
    f.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Brand script')
    parser.add_argument('--input', help='brand csv', required=True)
    args = parser.parse_args()
    main(args)
