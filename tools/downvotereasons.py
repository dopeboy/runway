import argparse
from datetime import date
import json


def main(args):
    f = open(args.input, 'r')
    downvotereasons = []
    for line in f.readlines():
        downvotereason = line.split(',')[0]
        downvotereason_uuid = line.split(',')[1].rstrip('\n')
        downvotereasons.append({
            'model': 'apiapp.downvotereason',
            'pk': downvotereason_uuid,
            'fields': {
                'label': downvotereason,
                'created': date.today().isoformat()
                }
            })
    f.close()
    f = open('downvotereasons.json', 'w')
    f.write(json.dumps(downvotereasons, indent=4, separators=(',', ': ')))
    f.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='downvotereason script')
    parser.add_argument('--input', help='downvotereason csv', required=True)
    args = parser.parse_args()
    main(args)
