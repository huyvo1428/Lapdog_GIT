%
% Read last row of text file, only.
% This can be useful for only extracting the first row from very large files.
%
%
% ALGORITHM
% =========
% Read byte-by-byte from the end of the file until reaching either
% (1) the first line feed (excluded from string) that is not at the end of the file, or
% (2) beginning of file.
%
%
% NOTE: Can handle empty files. Empty file (zero bytes) ==> Empty string
% NOTE: Returned string includes trailing LF (e.g. CR+LF).
% NOTE/BUG: Does NOT work for symbolic links, since "dir" returns the file size of the symlink, not the file.
%   (Reading the file works though.)
%
%
% Initially created ~2018-08-15 by Erik P G Johansson.
%
function lastRow = read_last_file_row(filePath)
    temp     = dir(filePath);
    fileSize = temp.bytes;

    LF = sprintf('\n');
    
    fileId = fopen(filePath,'r');         % Open the file as a binary
    lastRow = '';                         % Initialize to empty
    
    offset = 1;                           % Offset from the end of file
    
    while (offset <= fileSize)
        
        fseek(fileId, -offset, 'eof');         % Seek to the file end, minus the offset
        newChar = fread(fileId, 1, '*char');   % Read one character
        
        if (strcmp(newChar, LF)) && (offset ~= 1)
            break
        end
        
        lastRow = [newChar lastRow];   % Add the character to beginning of string
        offset  = offset+1;
    end
    
    fclose(fileId);
end