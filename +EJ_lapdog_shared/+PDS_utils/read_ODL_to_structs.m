%
% General-purpose tool for reading ODL (LBL/CAT) files. Read ODL/LBL file and return contents in the form of two
% recursive structs, each of them separately representing the contents of the ODL file.
%
%
% RETURN VALUES
% =============
% NOTE: ssl preserves correctly formatted, non-implicit ODL contents (keys/values) "exactly", while sSimple
% does not but is easier to work with when retrieving specific values (with hard-coded "logical locations") instead.
% ssl : 
%    "string-lists struct": Struct with ODL keys/values as arrays of strings, ODL OBJECT statements
%    recursively in list of such objects.
%    - Preserves exact order of everything.
%    - "OBJECT = ...", but not "END_OBJECT = ...", are represented as key-value pairs.
%       ssl.keys    : Cell vector of key names as strings
%       ssl.values  : Cell vector of key values as strings, including any surrounding quotes
%       ssl.objects : Cell vector of (1) empty components, and (2) the same type of structure, recursively.
% sSimple : 
%    "simple struct": Struct with fields corresponding to ODL keys and values corresponding
%    to ODL values, converted to matlab numbers and strings without quotes.
%    ODL OBJECTS segments are stored as similar structs (recursively).
%    - Quotes values are kept as strings without quotes.
%    - Unquoted values are interpreted as numbers if possible, otherwise as strings.
%    - Keys which are not allowed as MATLAB fieldnames (color, circumflex) are converted to something
%      that MATLAB does accept.
%    - Preserves order of OBJECT for same type (COLUMN, TABLE etc) on the same recursive level
%      ("branch") but not their location in any other way, e.g. if switching between OBJECT types.
%    - NOTE: Always puts "substructures" (OBJECT...END_OBJECT) in cell arrays,
%      whether there is only one or several substructures (of same type, e.g. COLUMN) for consistency
%      (good for loops with arbitrary number of iterations).
%      Therefore one has to always use one index to break out of the cell, even
%      if there is only one "substructure", e.g. "s.OBJECT___TABLE{1}.OBJECT___COLUMN{5}".
%    Example:
%      s.PDS_VERSION_ID
%      s.RECORD_TYPE
%      ...
%      s.OBJECT___TABLE{1}.INTERCHANGE_FORMAT
%      s.OBJECT___TABLE{1}.ROWS
%      ...
%      s.OBJECT___TABLE{1}.OBJECT___COLUMN
%      s.OBJECT___TABLE{1}.OBJECT___COLUMN{1}.NAME
%      s.OBJECT___TABLE{1}.OBJECT___COLUMN{1}.START_BYTE
%      ...
%      s.OBJECT___TABLE{1}.OBJECT___COLUMN{2}.NAME
%      s.OBJECT___TABLE{1}.OBJECT___COLUMN{2}.START_BYTE
%      ...
% endTestRowsList : Cell array of strings, one for every line after the final "END" statement (without CR, LF).
%
%
% ODL FORMAT HANDLING
% ===================
% Can handle:
% (1) Can handle quoted ODL values that span multiple lines (and which ODL does permit).
%       Line breaks in multiline value strings are stored as CR+LF.
% (2) Can handle (ignore) comments /*...*/ on one line. I think the PDS standard forces them to be on one line.
% (3) Can handle indentation (ignored).
% Can NOT handle:
% (1) Can still NOT handle values like INDEX.LBL: INDEXED_FILE_NAME = {"DATA/*.LBL"}
% ODL syntax error not checked for:
% (1) Does not check if keys occur multiple times, except OBJECT for which cell arrays are used.
% (2) Does not check if there are too many END_OBJECT (only checks the reverse).
%
%
% NOTES
% =====
% NOTE: Designed to fail, give error for non-ODL files so that it can be used when one does not know
% whether it is an ODL file or not, e.g. iterate over .TXT files (both ODL and non-ODL) in data sets.
% NOTE: Only handles the ODL formatted content, not content pointed to by it.
% NOTE: "END" statement is not included in the returned representations, but implied.
% NOTE: Designed to work under MATLAB2009a (because of Lapdog).
%
%
%
% Initially created by Erik P G Johansson, IRF Uppsala, 2014-11-18.
%
function [ssl, sSimple, endTestRowsList] = read_ODL_to_structs(filePath)
    %
    % QUESTION: How handle ODL/PDS distinction?
    % QUESTION: How handle ODL format errors?
    %
    % PROPOSAL: Check for reading the same ODL key/field twice.
    % PROPOSAL: Flag for error modes: error, quit & warning.
    % PROPOSAL: Flag for keeping/removing quotes around string values.
    %
    % PROPOSAL: Somehow keep distinguishing between ODL keys with/without quotes?!!
    % PROPOSAL: Also return data on the format of non-hierarchical list of key-value pairs?!
    %
    % PROPOSAL: Reorg. code into (1) read file to cell array of rows, (2) interpret cell array of rows.
    %   PRO: Can more easily write test code.
    %   PRO: Can reuse file reading code.
    
    % Check if file (not directory) exists.
    % -------------------------------------
    % It is useful for the user to know which ODL file is missing so that he/she can more quickly
    % determine where in pds, lapdog etc. the original error lies (e.g. a ODL file produced by pds,
    % or lapdog code producing or I2L.LBL files, or A?S.LBL files, or EST.LBL files).
    if (~exist(filePath, 'file'))
        error('Can not find file: "%s"', filePath)
    end
    try
        % Read list of lines/rows. No parsing. 
        rowStrList = read_file_to_line_list(filePath);
    catch e
        error('Can not read file: %s', filePath)
    end
    
    %try
        [kvl, endTestRowsList] = read_keys_values_list_INTERNAL(rowStrList);
        [ssl, sSimple, junk]   = construct_structs_INTERNAL(kvl, 1);
    %catch e
        %error([e.message, sprintf(' File "%s"', filePath)])
        %e.message = [e.message, sprintf(' File "%s"', filePath)];
        %rethrow(e)
    %end
end

%###################################################################################################

% Extract assignments VARIABLE_NAME = VALUE from list of lines.
% Empty lines and "END" are permitted but are not represented in the returned result.
% Makes not other interpretation.
function [kvl, endTestRowsList] = read_keys_values_list_INTERNAL(rowStrList)
    
    LINE_BREAK = sprintf('\r\n');   % String that represents line break in value strings.
    
    % Preallocate cell arrays. As large as possibly needed.
    kvl.keys   = cell(length(rowStrList), 1);
    kvl.values = cell(length(rowStrList), 1);
    
    iKv = 0;
    iRow = 0;
    
    %----------------------------------------------------------------
    function next_line()
        iRow = iRow + 1;
        if iRow > length(rowStrList)
            error('Reached end of file sooner than syntax implied.')
        end
        rowStr = rowStrList{iRow};
    end
    %----------------------------------------------------------------
    
    state = 'new_statement';    % Value represents "where the algorithm thinks it is", "what it expects".
    rowStr = [];    % Must define to prevent overloading with some MATLAB function.
    while true
            
        switch state
            
            % Assume key = value, END, or empty line.
            case 'new_statement'

                next_line();
                line_trimmed = strtrim(rowStr);
                if strcmp(line_trimmed, '')
                    % CASE: Empty line
                    state = 'new_statement';
                elseif strcmp(line_trimmed, 'END')
                    % CASE: "END"
                    state = 'end';
                else
                    iComment1 = regexp(rowStr, '/\*', 'once');
                    if ~isempty(iComment1)
                        i_comment2 = regexp(rowStr(iComment1+2:end), '\*/', 'once');   % NOTE: Star is escaped with backslash.
                        if isempty(i_comment2)
                            error('Row %i: Can not find end of comment.', iRow);
                        end
                        state = 'new_statement';
                    else                    
                        state = 'begin_assignment';
                    end
                end
                
            case 'begin_assignment'
                
                % CASE: key = value
                iEq = regexp(rowStr, '=', 'once');
                if isempty(iEq)
                    error('Row %i: Can not find the expected equals ("=") character on the same row.', iRow)
                end
                
                key = strtrim(rowStr(1:(iEq-1)));
                rowStr = rowStr((iEq+1):end);
                
                iQuote1 = regexp(rowStr, '"', 'once');
                if isempty(iQuote1)
                    % CASE: Unquoted value
                    
                    value = strtrim(rowStr);
                    state = 'key_value_done';
                    
                else                    
                    % CASE: Quoted value
                    
                    rowStr = rowStr(iQuote1:end);   % INCLUDE THE QUOTE!
                    
                    iQuote2 = 1+regexp(rowStr(2:end), '"', 'once');   % Search for SECOND quote.
                    if ~isempty(iQuote2)
                        % CASE: Second quote on the SAME line.
                        value = rowStr(1:iQuote2);    % INCLUDE THE QUOTE
                        state = 'key_value_done';
                    else
                        % CASE: Second quote on OTHER line.
                        value = rowStr;
                        state = 'quoted_value_nonfirst_line';
                    end

                end

            case 'quoted_value_nonfirst_line'

                next_line();
                iQuote2 = regexp(rowStr, '"', 'once');
                if isempty(iQuote2)
                    valueAddition = rowStr;
                    state = 'quoted_value_nonfirst_line';
                else
                    valueAddition = rowStr(1:iQuote2);   % INCLUDE THE QUOTE
                    state = 'key_value_done';
                end
                value = [value, LINE_BREAK, valueAddition];

            case 'key_value_done'

                iKv = iKv + 1;
                kvl.values{iKv} = value;
                kvl.keys{iKv}   = key;
                state = 'new_statement';
                
            case 'end'
                
                endTestRowsList = rowStrList(iRow+1:end);
                break   % Break the while loop.
                
            otherwise
                
                error('Unknown state');
        end
        
        
        
    end

    % Shorten cell arrays to remove unused entries (since these are preallocated variables).
    kvl.keys   = kvl.keys(1:iKv);
    kvl.values = kvl.values(1:iKv);
end

%###################################################################################################

%-------------------------------------------------------------------------------------------------
% Convert lists of key-value assignments (only strings; kvl.keys, kvl.values)
% from an ODL file into two structs, each representing the entire file contents.
%
% Assumes complete kvl for entire file, but will only analyze the "tree"
% which has its "root" at iFirst, i.e. either
% (1) the entire list of key-value pairs, or
% (2) the sequence between (but excluding) "OBJECT = ..." and the corresponding "END_OBJECT = ...".
%
% RECURSIVE
%
% ARGUMENTS
% =========
% kvl    : Unaltered key-value list representing an entire ODL file, or a part of it.
%          Only includes "assignments" (excludes empty rows, END).
% iFirst : Index into kvl fields where to start. Not an OBJECT statement which triggered
%          the call to the function.
% 
% iLast  : The last index into kvl fields which was analyzed.
%          Excludes any ENB_OBJECT which triggered ending the function.
%-------------------------------------------------------------------------------------------------
function [ssl, sSimple, iLast] = construct_structs_INTERNAL(kvl, iFirst)

    sSimple = [];

    ssl         = [];
    ssl.keys    = {};
    ssl.values  = {};
    ssl.objects = {};
    
    if length(kvl.keys) < 1
        error('Too few (less than one) key-value assignments.')
    elseif ~strcmp(kvl.keys{1}, 'PDS_VERSION_ID') || ~strcmp(kvl.values{1}, 'PDS3')
        % Extra check for "PDS_VERSION_ID = PDS3".
        % "Planetary Data System Standards Reference", Version 3.6 specifies that the first key-value
        % should always be this. This is included to be more sure that the code will fail/error
        % for a non-ODL file, in case the previous parsing did not fail.
        error('This is not an ODL file. Does not begin with PDS_VERSION_ID = PDS3.')
    end
    
    
    i = iFirst;     % Current index into kvl.
    while true
        
        key   = kvl.keys{i};
        value = kvl.values{i};
        %disp(['Reconstructed line : ', key, ' === ', value])  % DEBUG
        
        if strcmp(key, 'OBJECT')
            
            [ss_str_lists, ss_simple, iLast] = construct_structs_INTERNAL(kvl, i+1);    % NOTE: RECURSIVE CALL.
            
            i = iLast + 1;
            
            %--------------
            % Error checks
            %--------------
            if ~strcmp(kvl.keys{i}, 'END_OBJECT')
                error('Found OBJECT statement without corresponding END_OBJECT statement.')
            end
            OBJECT_value = value;
            END_OBJECT_value = kvl.values{i};
            if ~strcmp(OBJECT_value, END_OBJECT_value)
                error('"OBJECT = %s" and "END_OBJECT = %s" do not match.', OBJECT_value, END_OBJECT_value)
            end
            
            %-----------------
            % Update sSimple
            %-----------------
            % IMPLEMENTATION NOTE: There might be multiple OBJECTs of the same kind,
            % e.g. OBJECT = TABLE. Must therefore add to a cell array.
            skey = ['OBJECT___', value];
            if ~isfield(sSimple, skey)
                sSimple.(skey) = {ss_simple};         % Start new cell array.
            else
                sSimple.(skey){end+1} = ss_simple;    % Add to existing cell array.
            end
            
            %---------------------
            % Update ss_str_lists
            %---------------------
            ssl.keys{end+1}    = key;
            ssl.values{end+1}  = value;
            ssl.objects{end+1} = ss_str_lists;
            
        %elseif sum(strcmp(key, {'END_OBJECT', 'END'}))
        elseif sum(strcmp(key, {'END_OBJECT'}))
            
            % Make ssl' fields COLUMN vectors.
            ssl.keys    = ssl.keys(:);
            ssl.values  = ssl.values(:);
            ssl.objects = ssl.objects(:);
            
            iLast = i-1;
            return                 % NOTE: Exit function (recursive calls).
            
        else
            skey   = derive_struct_key(key);
            svalue = derive_struct_value(value);
            sSimple.(skey) = svalue;
            
            ssl.keys{end+1}    = key;
            ssl.values{end+1}  = value;
            ssl.objects{end+1} = [];
        end
        
        if i == length(kvl.keys)
            iLast = i - 1;
            return
        end
        i = i+1;        
        
    end   % while
end

%###################################################################################################

% Derive a string to be used as a structure fields, from the ODL variable/key name.
% These are usually the same, but this avoids errors due to MATLAB not permitting certain character that ODL does permit.
function skey = derive_struct_key(key)
    skey = strrep(key, ':', '___');
    if key(1) == '^'
        skey = ['POINTER___', key(2:end)];   % The "^" feature is called "Pointer statement" in ODL.
    end
end

%###################################################################################################

% Derive a string/number to be used as a structure field value from the ODL variable/key value (string).
% Value is quoted ==> Save unquoted value as string
% Value not quoted ==> Try to save as number. If fails, save as (unquoted) string.
% Value is empty ==> Save as empty string.
function svalue = derive_struct_value(value)
    n = length(value);
    if n < 1
        svalue = '';                    % NOTE: [] is not a string (ischar() returns false).
        %error('Finds no value for ODL key.')
        
    elseif (n >= 2) && (value(1) == '"') && (value(end) == '"')     % if string surrounded by quotes ...
        
        % Keep as string.
        % NOTE: ALWAYS removes quotes around string, if the quotes can be found.
        svalue = value(2:end-1);        
        
    elseif strcmp(value, 'NaN')
        
        svalue = NaN;
        
    else
        % CASE: value ~= "NaN"
        
        % NOTE: Both (1) the string "NaN", and (2) non-numerically interpretable strings result in NaN.
        svalue = str2double(value);     
        if isnan(svalue)
            % CASE: Could not interpret as string.
            svalue = value;             % Keep as string.
        end
        
    end
end

%###################################################################################################

% Has not managed to make importdata och textscan work with
% empty rows, CR+LF, without delimiter, keeping leading and trailing whitespace.
% E.g. rowStrList = importdata(filePath, '\n');
%
% Handles both CR+LF and LF as linebreak.
function rowStrList = read_file_to_line_list(filePath)
% PROPOSAL: Separate function file?

    rowStrList = {};
    fid = fopen(filePath);
    rowStr = fgetl(fid);
    while ischar(rowStr)        
        rowStrList{end+1} = rowStr;
        rowStr = fgetl(fid);
    end
    fclose(fid);
end
