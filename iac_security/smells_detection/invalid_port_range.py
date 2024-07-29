import re

from smells_detection import output
from util import invalid_port_ranges


def check(file_path):
    match = None
    try:
        with open(file_path, 'r') as file:
            contents = file.read()

        matches = re.findall('.*port.*\s+=\s+.*', contents)

        for match in matches:
            result = re.search(r'(.*((port).*\s+?=\s+?\D?(\d+)\D?))', match)

            if invalid_port_ranges.check(input=result):
                return True
    except Exception as e:
        print(e)

    return False
