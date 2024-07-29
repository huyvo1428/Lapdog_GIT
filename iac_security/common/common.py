import os


def list_file_paths_in_all_level_of_directory(directory, filetype):
    file_directories = []

    for path, subdirs, files in os.walk(directory):
        for name in files:
            if name.endswith(filetype):
                file_directories.append(os.path.join(path, name))

    return file_directories
