import re


def check(file_path):
    match = None
    try:
        with open(file_path, 'r') as file:
            contents = file.read()

        match = re.search('.+\s+=\s+\\"0.0.0.0/0\\"', contents)
    except Exception as e:
        print(e)

    if not match:
        return False

    return True
