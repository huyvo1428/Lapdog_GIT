%
% Generic function for writing ODL (LBL/CAT) files using a "struct string lists" (SSL) on the same format as returned
% from read_ODL_from_struct. Does some basic "beautification" (indentation, added whitespace to make equal signs and
% value left-aligned).
%
% NOTE: Overwrites destination file if pre-existing.
% NOTE: Multiline values are not indented (except the key itself).
% NOTE: Does not quote any value strings. They have to be "pre-quoted".
%
%
% ARGUMENTS
% =========
% Ssl                 : SSL data struct. See EJ_library.PDS_utils.convert_ODL_to_structs.
% endRowsList         : Cell array of strings, one for every line after the final "END" statement (without CR, LF).
% contentRowMaxLength : Max row length, excluding line break.
%                       NOTE: This is not a rigorous line breaking for everything; only some things. In particular does
%                       not even try to line break contents of endRowsList.
%
%
% Initially created 2016-07-07 by Erik P G Johansson, IRF Uppsala, Sweden.
%
function write_ODL_file(filePath, Ssl, endRowsList, indentationLength, contentRowMaxLength)
%
% PROPOSAL: Implement additional empty rows before/after OBJECT/END_OBJECT.
%    NOTE: Only one row between END_OBJECT and OBJECT. ==> Non-trivial.
%
% PROPOSAL: Add assertion check for (dis)allowed characters (superscripted hyphen disallowed in particular).
% PROPOSAL: Also accept data on the format of non-hierarchical list of key-value pairs?!
% PROPOSAL: Insert line-breaks (CR+LF) to limit row length.
%   NOTE: DVAL indicates that row length (including CR+LF) should be max 72 for .CAT files and 80 for .LBL files.
%   PROPOSAL: Line-break (quoted) string values.
%       CON: Could potentially mess up, long manually line-broken string values.
%
% PROPOSAL: Change into function producing list of strings instead of writing to file.
%   PRO: Good for testing.
% PROPOSAL: ROW_MAX_LENGTH som argument.
%   PROPOSAL: Optional argument with default value?
% PROPOSAL: Change name: write_ODL_file

    LINE_BREAK = sprintf('\r\n');
    
    % ASSERTION
    if ~isnumeric(indentationLength) || (numel(indentationLength) ~= 1)
        error('Illegal indentationLength argument.')
    end

    [fileId, errorMsg] = fopen(filePath, 'w');
    if fileId == -1
        error('Failed to open file "%s": "%s"', filePath, errorMsg)
    end
    
    
    
    fileStr = EJ_library.PDS_utils.convert_struct_to_ODL(Ssl, endRowsList, indentationLength, contentRowMaxLength, LINE_BREAK);
    fwrite(fileId, fileStr);
    
    %for i=1:length(endRowsList)        
    %    fwrite(fileId, [endRowsList{i}, LINE_BREAK]);
    %end
    
    fclose(fileId);    
end
