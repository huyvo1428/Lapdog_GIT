import os
import re


def check_resource_name(line):
    convention_pattern = r"resource\s+([^\s]+)_([a-z0-9_]+)"
    match = re.search(convention_pattern, line)

    return bool(match and match.group(1) and match.group(2))


def find_inconsistent_files(directory):
    inconsistent_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".tf"):
                file_path = os.path.join(root, file)
                with open(file_path, 'r') as f:
                    for line in f:
                        if check_resource_name(line) == False:
                            inconsistent_files.append(file_path)
                            break

    return inconsistent_files


def check(file_path):
    try:
        with open(file_path, 'r') as file:
            contents = file.read()

        matches = re.findall('resource.*\s+?', contents)

        for match in matches:
            result = re.search(r'((resource)\s+"(.+)"\s+"(.+)")', match)
            if result:
                final = re.findall('([a-z0-9_][a-z0-9]+)', result.group(4))
                if len(final) > 1:
                    return True
    except Exception as e:
        print(e)

    return False


if __name__ == '__main__':
    file_path = "../terraform/anshulc55/terraform/terraform/casestudy#1/module/rds/rds.tf"

    check(file_path=file_path)
