import argparse
from datetime import date
import json


def main(args):
    f = open(args.input, 'r')
    clothingtypes = []
    for line in f.readlines():
        clothingtype = line.split(',')[0]
        clothingtype_uuid = line.split(',')[1].rstrip('\n')
        clothingtypes.append({
            'model': 'apiapp.clothingtype',
            'pk': clothingtype_uuid,
            'fields': {
                'label': clothingtype,
                'created': date.today().isoformat()
                }
            })
    f.close()
    f = open('clothingtypes.json', 'w')
    f.write(json.dumps(clothingtypes, indent=4, separators=(',', ': ')))
    f.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='clothingtype script')
    parser.add_argument('--input', help='clothingtype csv', required=True)
    args = parser.parse_args()
    main(args)
