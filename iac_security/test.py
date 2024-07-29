from common import common
from smells_detection import empty_password
from smells_detection import admin_by_default
from smells_detection import empty_default, harcoded_password, inconsistent_naming_convention, invalid_port_range
from smells_detection import long_statement, unrestricted_ip_address


def admin_by_default():
    tf_file_paths = common.list_file_paths_in_all_level_of_directory(directory=".",
                                                                     filetype=".tf")

    no_code_smell_flag = 0
    for tf_file_path in tf_file_paths:
        admin_by_default_result = admin_by_default.check(file_path=tf_file_path)
        if admin_by_default_result:
            print(f"Detected admin by default in file {tf_file_path}")
            no_code_smell_flag = 1
    assert no_code_smell_flag == 1
