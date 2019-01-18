Files under this directory are ~generic utility functions shared with Erik P G Johansson's private MATLAB files.

These files are kept in a separate MATLAB package with the same directory structure of Erik P G Johansson's files (although under a different "root package") to
(1) keep the files easily recognizable as separate from the rest of the Lapdog code,
(2) make it easy to exchange modifications between Lapdog versions and Erik P G Johansson's private versions (both directions) by being able to easily modify files to copy them in any direction (one search-and-replace on package names in all files), while at the same time
    (2a) simultaneously keeping both versions available on the MATLAB path when developing by avoiding name conflicts by using different MATLAB packages (MATLAB does not call the wrong version), and
    (2b) being able to easily diff files in any one direction (copy Erik's files to Lapdog or vice versa) with as few modifications as possible (e.g. renaming rare function calls).

/Erik P G Johansson 2019-01-18
