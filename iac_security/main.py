from common import common
from smells_detection import empty_password
from smells_detection import admin_by_default
from smells_detection import empty_default, harcoded_password, inconsistent_naming_convention, invalid_port_range
from smells_detection import long_statement, unrestricted_ip_address
import cProfile


def execute():
    # scan folder
    tf_file_paths = common.list_file_paths_in_all_level_of_directory(directory=".",
                                                                     filetype=".tf")

    no_code_smell_flag = 0

    for tf_file_path in tf_file_paths:
        admin_by_default_result = admin_by_default.check(file_path=tf_file_path)
        empty_default_result = empty_default.check(file_path=tf_file_path)
        empty_password_result = empty_password.check(file_path=tf_file_path)
        harcoded_password_result = harcoded_password.check(file_path=tf_file_path)
        inconsistent_naming_convention_result = inconsistent_naming_convention.check(file_path=tf_file_path)
        invalid_port_range_result = invalid_port_range.check(file_path=tf_file_path)
        long_statement_result = long_statement.check(file_path=tf_file_path)
        unrestricted_ip_address_result = unrestricted_ip_address.check(file_path=tf_file_path)

        if admin_by_default_result:
            print(f"Detected admin by default in file {tf_file_path}")
            no_code_smell_flag = 1

        if empty_default_result:
            print(f"Detected empty_default in file {tf_file_path}")
            no_code_smell_flag = 1

        if empty_password_result:
            print(f"Detected empty_password in file {tf_file_path}")
            no_code_smell_flag = 1

        if harcoded_password_result:
            no_code_smell_flag = 1

        if inconsistent_naming_convention_result:
            no_code_smell_flag = 1

        if invalid_port_range_result:
            no_code_smell_flag = 1

        if long_statement_result:
            no_code_smell_flag = 1

        if unrestricted_ip_address_result:
            no_code_smell_flag = 1

    if no_code_smell_flag == 0:
        print("0 code smells in your source code")


cProfile.run("execute()")
