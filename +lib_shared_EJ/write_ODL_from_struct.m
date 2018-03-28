%
% Generic function for writing ODL (LBL/CAT) files using a "string-lists struct" on the same format
% as returned from read_ODL_from_struct. Does some basic "beautification" (indentation,
% added whitespace to make equal signs and value left-aligned).
%
% NOTE: Overwrites destination file if pre-existing.
% NOTE: Multiline values are not indented (except the key itself).
% NOTE: Does not quote any value strings. They have to already be quoted.
%
%
% ARGUMENTS
% =========
% s_str_lists         : See lib_shared_EJ.read_ODL_to_structs.
% endRowsList         : Cell array of strings, one for every line after the final "END" statement (without CR, LF).
% contentRowMaxLength : Maximum length of row, excluding line break characters.
%                       70+2 charactes per row applies to Rosetta .CAT files.
%
%
% Initially created 2016-07-07 by Erik P G Johansson, IRF Uppsala, Sweden.
%
function write_ODL_from_struct(filePath, s_str_lists, endRowsList, indentationLength, contentRowMaxLength)
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

    LINE_BREAK = sprintf('\r\n');
    
    % ASSERTION
    if ~isnumeric(indentationLength) || (numel(indentationLength) ~= 1)
        error('Illegal indentationLength argument.')
    end

    [c.fid, errorMsg] = fopen(filePath, 'w');
    c.indentationLength = indentationLength;
    if c.fid == -1
        error('Failed to open file "%s": "%s"', filePath, errorMsg)
    end
    
    write_key_values(c, s_str_lists, 0, contentRowMaxLength, LINE_BREAK)
    
    fprintf(c.fid, 'END\r\n');
    
    for i=1:length(endRowsList)        
        fwrite(c.fid, [endRowsList{i}, LINE_BREAK]);
    end
    
    fclose(c.fid);    
end



% NOTE: Recursive function.
% c : ??!!!
% s : formatted as s_str_lists.
% rowMaxLength : Excludes length of line break.
function write_key_values(c, s, indentationLevel, rowMaxLength, lineBreak)

    % ASSERTION: Implicitly checks that fields exist.
    if length(s.keys) ~= length(s.values) || length(s.keys) ~= length(s.objects)
        error('.keys, .values, and .objects do not have the same length.')
    end
    
    keys    = s.keys;    % TODO: Rationalize away
    values  = s.values;
    objects = s.objects;

    nonObjectKeyList      = keys(cellfun(@isempty, objects));    % Create list of keys without OBJECT/subsections.
    maxNonObjectKeyLength = max(cellfun(@length, nonObjectKeyList));

    indentationStr = repmat(' ', 1, c.indentationLength*indentationLevel);

    for i = 1:length(keys)
        key    = keys{i};
        value  = values{i};
        object = objects{i};
        
        if ~strcmp(key, 'OBJECT') && isempty(object)
            %======================
            % CASE: non-OBJECT key
            %======================
            
            % Create string of whitespaces used for placing "=" so that all "=" line up.
            postKeyPadding = repmat(' ', 1, maxNonObjectKeyLength-length(key));    
            
            % IMPLEMENTATION NOTE: Put together and write string to file without using fprintf/sprintf since the value
            % string may contain characters interpreted by fprintf/sprintf. Code has previously generated warnings
            % when using fprintf/sprintf but this avoids that.
            
            str1 = [indentationStr, key, postKeyPadding, ' = '];
            str2 = lineBreak;
            
            %=======================================
            % Line-break the value string, maybe...
            %=======================================
            % NOTE: To be on the safe side, only line-break keyword values which are both
            % (1) quoted, and
            % (2) not already line broken.
            % NOTE: Line breaks DATA_SET_NAME = e.g. "ROSETTA-ORBITER STEINS RPCLAP 2 AST1 EDITED V1.0"
            %       Not sure if OK.
            if ~isempty(strfind(value, '"')) && isempty(strfind(value, lineBreak))
                value = lib_shared_EJ.break_text(value, ...
                    rowMaxLength-length(str1), ...    % NOTE: String contains beginning quote. Therefore does NOT need to subtract 1 from rowMaxLength.
                    rowMaxLength, ...
                    rowMaxLength, ...    % NOTE: String contains ending quote. Therefore does NOT need to subtract 1 from rowMaxLength.
                    lineBreak, 'Permit longer rows');
            end
            str = [str1, value, str2];
            %str = [indentationStr, key, postKeyPadding, ' = ', value, lineBreak];
            
            fwrite(c.fid, str);
            
        elseif strcmp(key, 'OBJECT') && ~isempty(value) && ~isempty(object) && isstruct(object)
            % CASE: OBJECT key.
            
            % Print OBJECT with different "post-key" whitespace padding.
            fprintf(c.fid, sprintf('%s%s = %s\r\n',   indentationStr, key, value));
            
            write_key_values(c, object, indentationLevel+1, rowMaxLength, lineBreak);             % RECURSIVE CALL
            fprintf(c.fid, sprintf('%sEND_OBJECT = %s\r\n',   indentationStr, value));
        else
            error('Inconsistent combination of key, value and object.')
        end
    end
end
