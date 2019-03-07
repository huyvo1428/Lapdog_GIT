%
% (1) Check consistency (assertions) of TAB file from file size, first & last row.
% (2) Functionality for retrieving column values from first & last row.
%     In particular meant for reading first & last, UTC & OBT value from TAB files.
% Reads as little as possible from TAB file to be as fast as possible for large TAB files (hundreds of MiB).
%
% Meant to be used when writing LBL file.
%
%
% NOTES
% =====
% NOTE: Can not handle empty files (zero bytes). All return values except nRows would be undefined for this case anyway.
% NOTE: Not all TAB files contain timestamps. Ex: Frequency tables, sweep bias tables.
% NOTE: Not all TAB files are intended to be PDS compliant. Ex: AxS files.
% NOTE: Some TAB files only contain UTC. Ex: Block lists.
%
% NOTE: Could be amended to check the right number of column separators (non-rigorously, since column separator could be part of string value). 
% NOTE: Design somewhat "odd", "unnatural" since it mixes assertions (checking TAB file format) and returning data from TAB file.
%
%
% ARGUMENTS
% =========
% iFirstByteArray, iLastByteArray : Same sized 1D array with indices to first and last byte of strings in first/last TAB
%                                   file row.
%
%
% RETURN VALUES
% =============
% firstRowStringArray, lastRowStringArray  : Cell arrays of strings. Content from TAB file.
%
%
% Initially created 2018-08-15 by Erik P G Johansson, IRF Uppsala.
%
function [firstRowStringArray, lastRowStringArray, nBytesPerRow, nRows] = analyze_TAB_file(filePath, iFirstByteArray, iLastByteArray)
% PROPOSAL: Move to delivery code if setting LBL start & stop time.
%
% PROPOSAL: Retrieve number of columns.
%   PRO: Can set ITEMS automatically.
%   CON: Does not work for empty files.
%       PRO: Problem anyway if treating empty files as possibly valid.
%
% PROPOSAL: Separate functions for (1) verifying TAB file format (assertions) and (2) extracting data from first & last
% row.
%
% PROPOSAL: Separate treatment of empty files since (the caller) can not say that the TAB file is inconsistent with the
%       LBL file.

    temp     = dir(filePath);
    fileSize = temp.bytes;

    % ASSERTION
    if fileSize == 0
        error('Empty TAB file (0 bytes). Can not analyze.\n    File: "%s"', filePath)
    end



    % Read first and last row of file.
    % NOTE: Strings include trailing CR+LF.
    firstRow = EJ_library.utils.read_first_file_row(filePath);
    lastRow  = EJ_library.utils.read_last_file_row(filePath);
    
    % ASSERTION
    if length(firstRow) ~= length(lastRow)
        error('First and last row of TAB file have different lengths.\n    File: "%s"', filePath)
    end

    nBytesPerRow = length(firstRow);

    % ASSERTION
    if rem(fileSize, nBytesPerRow) ~= 0
        msg = sprintf(['TAB file appears to not have rows of uniform length. File size is NOT an integer multiple of the first/last rows length:\n', ...
            '    File: "%s"\n', ...
            '    fileSize                 = %g\n', ...
            '    nBytesPerRow             = %g'], ...
            tabFilePath, fileSize, nBytesPerRow);
        error(msg)
    end
    
    nRows = round(fileSize / nBytesPerRow);
    
    firstRowStringArray = extract_strings(firstRow, iFirstByteArray, iLastByteArray);
    lastRowStringArray  = extract_strings(lastRow,  iFirstByteArray, iLastByteArray);
end



% NOTE: Seems to work for byteRangeArray == [].
function [stringArray] = extract_strings(s, iFirstByteArray, iLastByteArray)
    stringArray = {};
    
    for i = 1:numel(iFirstByteArray)
        stringArray{i} = s(iFirstByteArray(i):iLastByteArray(i));
    end
end

