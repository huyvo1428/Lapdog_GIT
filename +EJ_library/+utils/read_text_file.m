%
% Reads file as text file and stores lines in cell array.
%
%
% RETURN VALUE
% ============
% Column cell array of strings (one per row). All CR and LF have been removed (not just trailing) so that it works for both Windows-style and Unix-style text files.
%
function [rowsList] = read_text_file(filePath)
% PROPOSAL: Use s=textscan(fileId, '%s', 'delimiter', '\n').
% PROPOSAL: Read entire file as a string, then split it using a specified line-break string.
%   PROPOSAL: Return both string and row string list.
%       CON: Unnecessary to return row string list. Trivial to produce with str_split.
%       CON: Row string list is line break-dependent.
%       CON: Row string list is dependent on how to interpret chars after last line break.

    %CR = char(13);
    %LF = char(10);
    
    fileId = fopen(filePath);
    if fileId == -1
        error(['Failed to open file: ', filePath])
    end
    
    temp = textscan(fileId, '%s', 'delimiter', '\n', 'whitespace', '');
    rowsList = temp{1};
    
%    rowsList = {};
%
%     while 1
%         %===========================================================================
%         %   -- Built-in Function:  fgets (FID, LEN)
%         %       Read characters from a file, stopping after a newline, or EOF, or
%         %       LEN characters have been read.  The characters read, including the
%         %       possible trailing newline, are returned as a string.
%         %
%         %       If LEN is omitted, `fgets' reads until the next newline character.
%         %
%         %       If there are no more characters to read, `fgets' returns -1.
%         %===========================================================================
%         line = fgets(fileId);
%         if ~ischar(line)
%             % CASE: No more characters to read.
%             break
%         end
%         
%         % Remove ALL CR and LF.
%         % The original string includes trailing CR and/or LF.
%         line = strrep(line, CR, '');
%         line = strrep(line, LF, '');
%         
%         rowsList{end+1, 1} = line;
%     end
    
    fclose(fileId);
end
