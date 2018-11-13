%
% General-purpose tool for reading ODL (LBL/CAT) files. Read ODL/LBL file and return contents in the form of two
% recursive structs, each of them separately representing the contents of the ODL file.
%
%
% RETURN VALUES
% =============
% NOTE: Ssl preserves correctly formatted, non-implicit ODL contents (keys/values) "exactly", while Ss
% does not but is easier to work with when retrieving specific values (with hard-coded "logical locations") instead.
% Ssl : An SSL struct
% Ss  : An SS struct
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
% (1) Can still NOT handle array-like values like INDEX.LBL: INDEXED_FILE_NAME = {"DATA/*.LBL"}
% ODL syntax error not checked for:
% (1) Does not check if keys occur multiple times, except OBJECT for which cell arrays are used.
% (2) Does not check if there are too many END_OBJECT (only checks the reverse).
%
%
% DEFINITIONS OF TERMS
% ====================
% AsgList = Assignment List
%           IMPLEMENTATION NOTE: Data struct is similar but not the same as KVPL="Key-Value Pair List" class. The
%           difference is that KVPL only contains unique keys, AsgList does not.
% SS  = "Simple Struct" (historical)
%    Data struct that approximately represents the structured part of an ODL file. This format is easy to use for
%    retrieving specific values.
%    MATLAB struct where the fields correspond to ODL keys and their values correspond
%    to ODL values, converted to MATLAB numbers and strings without quotes.
%    ODL OBJECT=... segments are stored as similar structs (recursively; see below).
%    - Quoted values are kept as strings without quotes.
%    - Unquoted values are interpreted as numbers if possible, otherwise as strings.
%    - Keys which are not allowed as MATLAB struct field names (colon, circumflex) are converted to something
%      that MATLAB does accept.
%    - For every type of OBJECT=X segments (OBJECT...END_OBJECT), it creates a field OBJECT___X{i} (X=COLUMN, TABLE etc)
%      containing a 1D cell array where every component is an SS data structure (recursive).
%      Therefore one has to always use one index to break out of the cell, even
%      if there is only one "substructure", e.g. "s.OBJECT___TABLE{1}.OBJECT___COLUMN{5}".
%    - Preserves order of OBJECT for same type (COLUMN, TABLE etc) on the same recursive level
%      ("branch") but not their location in any other way, e.g. if switching between OBJECT types.
%    - NOTE: There is no guarantee that the SS MATLAB struct fields are in the same order as the assignments in the file
%      (although it is possible).
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
% SSL = "Struct String Lists" (or "string lists struct")
%   Data struct that represents the structured part of an ODL file.
%   ODL keys/values as arrays of strings, ODL OBJECT statements recursively in list of such objects.
%    - Preserves exact order of everything.
%    - "OBJECT = ...", but not "END_OBJECT = ...", are represented as key-value pairs.
%       Ssl.keys    : Cell vector of key names as strings
%       Ssl.values  : Cell vector of key values as strings, including any surrounding quotes
%       Ssl.objects : Cell vector where every component is:
%           For non-"OBJECT = ..." statements: Empty, [].
%           For     "OBJECT = ..." statements: An SSL struct, recursively.
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
% Initially created 2014-11-18 by Erik P G Johansson, IRF Uppsala.
%
function [Ssl, Ss, endTestRowsList] = read_ODL_to_structs(filePath)
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
    %
    % PROPOSAL: Have derive_SS_key also derive SS keys for "OBJECT = ..." statements.
    
    
    % ASSERTION: Check if file (not directory) exists
    % -----------------------------------------------
    % It is useful for the user to know which ODL file is missing so that he/she can more quickly
    % determine where in pds, lapdog etc. the original error lies (e.g. a ODL file produced by pds,
    % or lapdog code producing or I2L.LBL files, or A?S.LBL files, or EST.LBL files).
    if (~exist(filePath, 'file'))
        error('Can not find file: "%s"', filePath)
    end
    
    try
        % Read list of lines/rows. No parsing. 
        rowStrList = read_file_to_line_list(filePath);
    catch Exception
        error('Can not read file: %s', filePath)
    end
    
    %try
        [AsgList, endTestRowsList] = read_keys_values_list_INTERNAL(rowStrList);
        [Ssl, Ss, junk]            = construct_structs_INTERNAL(AsgList, 1);
    %catch Exception
        %error([Exception.message, sprintf(' File "%s"', filePath)])
        %Exception.message = [Exception.message, sprintf(' File "%s"', filePath)];
        %rethrow(Exception)
    %end
end

%###################################################################################################

% Extract assignments VARIABLE_NAME = VALUE from list of lines.
% Empty lines and "END" are permitted but are not represented in the returned result.
% Makes not other interpretation.
function [AsgList, endTestRowsList] = read_keys_values_list_INTERNAL(rowStrList)
    
    LINE_BREAK = sprintf('\r\n');   % String that represents line break in value strings.
    
    % Preallocate cell arrays. As large as possibly needed.
    keys   = cell(length(rowStrList), 1);
    values = cell(length(rowStrList), 1);
    
    iKv  = 0;
    iRow = 0;
    
    %----------------------------------------------------------------
    % NOTE: Uses variables defined outside of function equivalent to
    % "[rowStr, iRow] = new_row(rowStrList, iRow)".
    % This is only to simplify and speed up the calls.
    %   PROPOSAL: Change?!
    function next_row()
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

                next_row();
                rowTrimmed = strtrim(rowStr);
                if strcmp(rowTrimmed, '')
                    % CASE: Empty line
                    state = 'new_statement';
                elseif strcmp(rowTrimmed, 'END')
                    % CASE: "END"
                    state = 'end';
                else
                    iComment1 = regexp(rowStr, '/\*', 'once');
                    if ~isempty(iComment1)
                        iComment2 = regexp(rowStr(iComment1+2:end), '\*/', 'once');   % NOTE: Star is escaped with backslash.
                        if isempty(iComment2)
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
                
                key    = strtrim(rowStr(1:(iEq-1)));
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

                next_row();
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
                values{iKv} = value;
                keys{iKv}   = key;
                state = 'new_statement';
                
            case 'end'
                
                endTestRowsList = rowStrList(iRow+1:end);
                break   % Break the while loop.
                
            otherwise
                
                error('Unknown state');
        end
        
        
        
    end

    % Shorten cell arrays to remove unused entries (since these are preallocated variables).
    AsgList.keys   = keys(1:iKv);
    AsgList.values = values(1:iKv);
    
end

%###################################################################################################

%-------------------------------------------------------------------------------------------------
% Convert lists of key-value assignments (only strings; AsgList.keys, AsgList.values)
% from an ODL file into two structs, each representing the entire file contents.
% NOTE: This is NOT a KVPL since the keys are not unique.
%
% Assumes complete AsgList for entire file, but will only analyze the "tree"
% which has its "root" at iFirst, i.e. either
% (1) the entire list of key-value pairs, or
% (2) the sequence between (but excluding) "OBJECT = ..." and the corresponding "END_OBJECT = ...".
%
% RECURSIVE
%
%x
% ARGUMENTS
% =========
% AsgList   : Unaltered key-value list representing an entire ODL file, or a part of it.
%             Only includes "assignments" (excludes empty rows, END).
% iFirst    : Index into AsgList fields where to start. Not an OBJECT statement which triggered
%             the call to the function.
% iLast     : The last index into AsgList fields which was analyzed.
%             Excludes any ENB_OBJECT which triggered ending the function.
%-------------------------------------------------------------------------------------------------
function [Ssl, Ss, iLast] = construct_structs_INTERNAL(AsgList, iFirst)

    Ss = [];

    Ssl         = [];
    Ssl.keys    = {};
    Ssl.values  = {};
    Ssl.objects = {};
    
    if length(AsgList.keys) < 1
        error('Too few (less than one) key-value assignments.')
    elseif ~strcmp(AsgList.keys{1}, 'PDS_VERSION_ID') || ~strcmp(AsgList.values{1}, 'PDS3')
        % Extra check for "PDS_VERSION_ID = PDS3".
        % "Planetary Data System Standards Reference", Version 3.6 specifies that the first key-value
        % should always be this. This is included to be more sure that the code will fail/error
        % for a non-ODL file, in case the previous parsing did not fail.
        error('This is not an ODL file. Does not begin with PDS_VERSION_ID = PDS3.')
    end



    i = iFirst;     % Current index into AsgList.
    while true

        key   = AsgList.keys{i};
        value = AsgList.values{i};
        %disp(['Reconstructed line : ', key, ' === ', value])  % DEBUG
        
        if strcmp(key, 'OBJECT')
            
            [Ssl2, Ss2, iLast] = construct_structs_INTERNAL(AsgList, i+1);    % NOTE: RECURSIVE CALL.
            
            i = iLast + 1;
            
            % ASSERTIONS            
            if ~strcmp(AsgList.keys{i}, 'END_OBJECT')
                error('Found OBJECT statement without corresponding END_OBJECT statement.')
            end
            OBJECT_value     = value;
            END_OBJECT_value = AsgList.values{i};
            if ~strcmp(OBJECT_value, END_OBJECT_value)
                error('"OBJECT = %s" and "END_OBJECT = %s" do not match.', OBJECT_value, END_OBJECT_value)
            end
            
            %-----------
            % Update Ss
            %-----------
            % IMPLEMENTATION NOTE: There might be multiple OBJECTs of the same kind,
            % e.g. OBJECT = TABLE. Must therefore add to a cell array.
            ssKey = ['OBJECT___', value];
            if ~isfield(Ss, ssKey)
                Ss.(ssKey) = {Ss2};         % Start new cell array.
            else
                Ss.(ssKey){end+1} = Ss2;    % Add to existing cell array.
            end
            
            %---------------------
            % Update Ssl2
            %---------------------
            Ssl.keys{end+1}    = key;
            Ssl.values{end+1}  = value;
            Ssl.objects{end+1} = Ssl2;
            
        %elseif sum(strcmp(key, {'END_OBJECT', 'END'}))
        elseif sum(strcmp(key, {'END_OBJECT'}))

            % Make Ssl's fields COLUMN vectors.
            Ssl.keys    = Ssl.keys(:);
            Ssl.values  = Ssl.values(:);
            Ssl.objects = Ssl.objects(:);
            
            iLast = i-1;
            return                 % NOTE: Exit function (recursive calls).
            
        else
            ssKey   = derive_SS_key(key);
            ssValue = derive_SS_value(value);
            Ss.(ssKey) = ssValue;
            
            Ssl.keys{end+1}    = key;
            Ssl.values{end+1}  = value;
            Ssl.objects{end+1} = [];
        end
        
        if i == length(AsgList.keys)
            iLast = i - 1;
            return
        end
        i = i+1;        
        
    end   % while
end

%###################################################################################################

% Derive a string to be used as a "simple structure" fields, from the ODL variable/key name.
% These are usually the same, but this avoids errors due to MATLAB not permitting certain character that ODL does permit.
function ssKey = derive_SS_key(key)
    ssKey = strrep(key, ':', '___');
    if key(1) == '^'
        ssKey = ['POINTER___', key(2:end)];   % The "^" feature is called "Pointer statement" in ODL.
    end
end

%###################################################################################################

% Derive a string/number to be used as a structure field value from the ODL variable/key value (string).
% Value is quoted ==> Save unquoted value as string
% Value not quoted ==> Try to save as number. If fails, save as (unquoted) string.
% Value is empty ==> Save as empty string.
function ssValue = derive_SS_value(value)
    n = length(value);
    if n < 1
        ssValue = '';                    % NOTE: [] is not a string (ischar() returns false).
        %error('Finds no value for ODL key.')
        
    elseif (n >= 2) && (value(1) == '"') && (value(end) == '"')     % if string surrounded by quotes ...
        
        % Keep as string.
        % NOTE: ALWAYS removes quotes around string, if the quotes can be found.
        ssValue = value(2:end-1);        
        
    elseif strcmp(value, 'NaN')
        
        ssValue = NaN;
        
    else
        % CASE: value ~= "NaN"
        
        % NOTE: Both (1) the string "NaN", and (2) non-numerically interpretable strings result in NaN.
        ssValue = str2double(value);     
        if isnan(ssValue)
            % CASE: Could not interpret as string.
            ssValue = value;             % Keep as string.
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
    fid        = fopen(filePath);
    rowStr     = fgetl(fid);
    while ischar(rowStr)        
        rowStrList{end+1} = rowStr;
        rowStr            = fgetl(fid);
    end
    fclose(fid);
end
