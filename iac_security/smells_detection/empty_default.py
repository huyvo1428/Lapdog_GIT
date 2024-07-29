import re


def check(file_path):
    matches = None
    try:
        with open(file_path, 'r') as file:
            contents = file.read()

        matches = re.findall('(default\s*?=\s*?"\s*")', contents)
    except Exception as e:
        print(e)

    if not matches:
        return False

    return True
