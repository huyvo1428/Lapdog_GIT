% Read first row of text file, only.
% This can be useful for only extracting the first row from very large files.
%
%
% NOTE: Returned string includes trailing LF (or CR+LF).
%
%
% Initially created ~2018-08-15 by Erik P G Johansson.
%
function firstRow = read_first_file_row(filePath)
    fileId = fopen(filePath,'r');
    firstRow = fgets(fileId);
    fclose(fileId);
end