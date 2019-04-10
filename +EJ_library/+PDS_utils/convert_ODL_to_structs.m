% Generic function for converting a list of rows corresponding to an ODL file (without linebreak), into structs.
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
% ODL syntax error not checked for:
% (1) Does not check if keys occur multiple times, except OBJECT for which cell arrays are used.
% (2) Does not check if there are too many END_OBJECT (only checks the reverse).     # STILL TRUE WITH NEW IMPLEMENTATION!
%
%
% DEFINITIONS OF TERMS
% ====================
% ODL = Object Definition Language, the language (or a superset of) used for formatting PDS3 label files (.LBL) and
%       catalogue (.CAT) files.
%
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
%       Ssl.values  : Cell vector of key values as strings, including surrounding quotes if any
%       Ssl.objects : Cell vector where every component is:
%           For non-"OBJECT = ..." statements: Empty, [].
%           For     "OBJECT = ..." statements: An SSL struct, recursively.
%
%
% NOTES
% =====
% NOTE: Designed to fail, give error for non-ODL files so that it can be used when one does not know
% whether it is an ODL file or not, e.g. iterate over .TXT files (both ODL and non-ODL) in data sets.
% NOTE: Only handles the ODL formatted content, not content that it points to.
% NOTE: "END" statement is not included in the returned representations, but implied.
% NOTE: Designed to work under MATLAB2009a (because of Lapdog).
% NOTE: Not entirely analogous with convert_struct_to_ODL, since
% - that function does not handle end rows, while this one does,
% - that function does not require PDS_VERSION_ID = PDS3, while this one does.
% - that function can specify linebreak string, while this can not.
% NOTE: Permits empty ODL arrays, despite that DVALNG seems to require that ODL arrays are not empty.
%
% BUG?: Can not handle quoted values beginning on next row?
%
% IMPLEMENTATION NOTE: This functionality is implemented separately (instead of mixed with file-reading code) to make
% the code more easily testable.
%
%
function [Ssl, Ss, endRowsList] = convert_ODL_to_structs(rowStrList)
    % PROPOSAL: Change name to "interpret_*".
    %   PRO: More consistent with other code.
    %       CON: Other code has used "interpret", but there is no obvious analogue for conversion in the opposite direction.
    %   PRO: Clearer
    %       CON: Does not imply so clearly that there is an input and output.
    %
    % PROPOSAL: Change name to convert_ODL_structs   / convert_structs_ODL.
    % PROPOSAL: Change name to convert_ODL_2_structs / convert_structs_2_ODL.
    % PROPOSAL: Change name to convert_ODL2structs.
    %
    % PROPOSAL: Modify to permit ODL comments.
    
    % Convert to list of key-value assignments.
    [AsgList, endRowsList] = read_keys_values_list(rowStrList);
    % Interpret list of key-value assignments.
    [Ssl, Ss, junk]        = construct_structs(AsgList, 0);
    
    EJ_library.PDS_utils.assert_SSL_is_PDS3(Ssl)
end



% Extract assignments VARIABLE_NAME = VALUE from list of lines.
% Empty lines and "END" are permitted but are not represented in the returned result.
% Makes no other interpretation.
function [AsgList, endRowsList] = read_keys_values_list(rowStrList)
    
    LINE_BREAK = sprintf('\r\n');   % String that represents line break in value strings. NOTE: Additionally hardcoded in various regexp..
    WSLB_RE         = '[ \t\r\n]*';                   % WSLB = Whitespace (and tab), Line Break. RE = Regular expression.
    KEYWORD_RE      = '[A-Za-z0-9^:_]+';              % NOTE: Must include ":" due to "ROSETTA:". Includes lower case, which PDS3 does not allow?
    VALUE_STRING_RE = '([A-Za-z0-9_:.+-]+|"[^"]*")';  % NOTE: Must include ":", "-", and "." due to e.g. START_TIME = 2016-06-28T23:58:10.148.  "+" due to MISSING_CONSTANT = -1.0e+09.
    
    keyList   = cell(0, 1);
    valueList = cell(0, 1);
    
    str = EJ_library.utils.str_join(rowStrList, LINE_BREAK);
    
    % State in the state machine. Notation is that the string ~describes what has just been done, not what will be done
    % for the corresponding case, e.g. 'KEYWORD' means that a keyword has just been read (i.e. already been read).
    state = 'OUTSIDE_OF_ASSIGNMENT_BEGIN_NEW_ROW';
    while true
        
        switch state
            case 'OUTSIDE_OF_ASSIGNMENT_BEGIN_NEW_ROW'
                str             = read_token_opt(str, WSLB_RE);              % Read indentation, empty rows.
                [str, token, n] = read_token_req(str, 'END(?![A-Za-z0-9_])', KEYWORD_RE);    % Read (1) END, or (2) key.
                %[str, token, n] = read_token_req(str, 'END[ \t]*\r\n', KEYWORD_RE);    % Read (1) END, or (2) key.
                % IMPLEMENTATION NOTE: Must check for END first, so that algorithm does not think that END is the name of a
                % keyword.
                
                
                switch n
                    case 1
                        state = 'END';
                    case 2
                        state = 'KEYWORD';
                end
                
            case 'KEYWORD'
                key = token;
                str             = read_token_req(str, [WSLB_RE, '=', WSLB_RE]);            % Read equals.
                [str, token, n] = read_token_req(str, VALUE_STRING_RE, ['{', WSLB_RE]);    % Read (1) value string, or (2) left curly brace.
                
                switch n
                    case 1
                        % CASE: Unquoted/quoted value
                        value = token;                        
                        state = 'VALUE_STRING';
                        
                    case 2
                        state = 'VALUE_ARRAY_BEGIN_BRACKET';
                end
                
            case 'VALUE_STRING'
                % NOTE: PDS/ODL requires at most one keyword assignment per row. Therefore reads at AT LEAST ONE LINE
                %       BREAK.
                str   = read_token_req(str, [WSLB_RE, '\r\n']);
                state = 'DONE_PARSING_ASSIGNMENT';
                
            case 'VALUE_ARRAY_BEGIN_BRACKET'
                value = cell(0,1);
                [str, arrayCompValue, n] = read_token_req(str, [WSLB_RE, '}'], VALUE_STRING_RE);    % Read (1) right curly bracket, or (2) value string.
                
                switch n
                    case 1
                        % CASE: Has read right curly bracket (immediately after left curly bracket) <=> end of EMPTY ODL array.
                        state = 'DONE_PARSING_ASSIGNMENT';
                        
                    case 2
                        % CASE: Has read one ODL array component value (the first).
                        state = 'VALUE_ARRAY_COMPONENT';
                        
                end   % switch
                
            case 'VALUE_ARRAY_COMPONENT'
                value{end+1, 1} = arrayCompValue;
                [str, junk, n] = read_token_req(str, [WSLB_RE, ',' WSLB_RE], [WSLB_RE, '}']);    % Read (1) comma, or (2) right curly bracket
                switch n
                    case 1
                        % CASE: Has read comma.
                        [str, arrayCompValue] = read_token_req(str, VALUE_STRING_RE);    % Read (1) value string, or (2) right curly bracket.
                        state = 'VALUE_ARRAY_COMPONENT';
                        
                    case 2
                        % CASE: Reached end of ODL array.
                        state = 'DONE_PARSING_ASSIGNMENT';
                end
                
            case 'DONE_PARSING_ASSIGNMENT'
                keyList{end+1, 1}   = key;
                valueList{end+1, 1} = value;
                state = 'OUTSIDE_OF_ASSIGNMENT_BEGIN_NEW_ROW';
                
            case 'END'
                
                str = read_token_opt(str, '[ \t]*');    % Read remainder of row containing END.
                
                % IMPLEMENTATION NOTE: Hidden ASSERTION since requires either one of two alternatives of the remaining string:
                % (1) nothing left in string, or
                % (2) string begins with line break, but without any restrictions on what comes after.
                % Thus checks that nothing illegal comes after END. Can not use read_token_req since it can not check
                % for empty string (a regexp "$" does not work).
                if isempty(str)
                    endRowsList = cell(0,1);
                else
                    str = read_token_req(str, '\r\n');        % Read (1) line break, or (2) anything else
                
                    % IMPLEMENTATION NOTE: Splitting string will always result in at least one substring that does NOT
                    % represent a row NOT followed by line break. It is doubtful whether such strings/rows should be
                    % regarded as rows when empty. Therefore removing them.
                    % Ex: String being split is empty ==> splitting will result in one empty string.
                    endRowsList = EJ_library.utils.str_split(str, '\r\n');
                    if isempty(endRowsList{end})
                        endRowsList(end) = [];
                    end
                    endRowsList = endRowsList(:);   % Make column vector.
                end
                break

            otherwise
                assert(0)
                
        end    % switch
        
    end    % while
    
    AsgList.keys   = keyList;
    AsgList.values = valueList;
    


%  ##############################
%   OLD IMPLEMENTATION - DELETE?
%  ##############################
%     iKv  = 0;
%     iRow = 0;
%     
%     %----------------------------------------------------------------
%     % NOTE: Uses variables defined outside of function equivalent to
%     % "[rowStr, iRow] = new_row(rowStrList, iRow)".
%     % This is only to simplify and speed up the calls.
%     %   PROPOSAL: Change?!
%     function next_row()
%         iRow = iRow + 1;
%         if iRow > length(rowStrList)
%             error('Reached end of file sooner than syntax implied.')
%         end
%         rowStr = rowStrList{iRow};
%     end
%     %----------------------------------------------------------------
%     
%     state = 'new_statement';    % Value represents "where the algorithm thinks it is", "what it expects".
%     rowStr = [];    % Must define to prevent overloading with some MATLAB function.
%     while true
% 
%         switch state
% 
%             % Assume key = value, END, or empty line.
%             case 'new_statement'
% 
%                 next_row();
%                 rowTrimmed = strtrim(rowStr);
%                 if strcmp(rowTrimmed, '')
%                     % CASE: Empty line
%                     state = 'new_statement';
%                 elseif strcmp(rowTrimmed, 'END')
%                     % CASE: "END"
%                     state = 'end';
%                 else
%                     iComment1 = regexp(rowStr, '/\*', 'once');
%                     if ~isempty(iComment1)
%                         iComment2 = regexp(rowStr(iComment1+2:end), '\*/', 'once');   % NOTE: Star is escaped with backslash.
%                         if isempty(iComment2)
%                             error('Row %i: Can not find end of comment.', iRow);
%                         end
%                         state = 'new_statement';
%                     else                    
%                         state = 'begin_assignment';
%                     end
%                 end
% 
%             case 'begin_assignment'
% 
%                 % CASE: key = value
%                 iEq = regexp(rowStr, '=', 'once');
%                 if isempty(iEq)
%                     error('Row %i: Can not find the expected equals ("=") character on the same row.', iRow)
%                 end
%                 
%                 key    = strtrim(rowStr(1:(iEq-1)));
%                 rowStr = rowStr((iEq+1):end);
%                 
%                 iQuote1 = regexp(rowStr, '"', 'once');
%                 if isempty(iQuote1)
%                     % CASE: Unquoted value
%                     
%                     value = strtrim(rowStr);
%                     state = 'key_value_done';
% 
%                 else                    
%                     % CASE: Quoted value
% 
%                     rowStr = rowStr(iQuote1:end);   % INCLUDE THE QUOTE!
% 
%                     iQuote2 = 1+regexp(rowStr(2:end), '"', 'once');   % Search for SECOND quote.
%                     if ~isempty(iQuote2)
%                         % CASE: Second quote on the SAME line.
%                         value = rowStr(1:iQuote2);    % INCLUDE THE QUOTE
%                         state = 'key_value_done';
%                     else
%                         % CASE: Second quote on OTHER line.
%                         value = rowStr;
%                         state = 'quoted_value_nonfirst_line';
%                     end
% 
%                 end
% 
%             case 'quoted_value_nonfirst_line'
% 
%                 next_row();
%                 iQuote2 = regexp(rowStr, '"', 'once');
%                 if isempty(iQuote2)
%                     valueAddition = rowStr;
%                     state = 'quoted_value_nonfirst_line';
%                 else
%                     valueAddition = rowStr(1:iQuote2);   % INCLUDE THE QUOTE
%                     state = 'key_value_done';
%                 end
%                 value = [value, LINE_BREAK, valueAddition];
% 
%             case 'key_value_done'
% 
%                 iKv = iKv + 1;
%                 values{iKv} = value;
%                 keys{iKv}   = key;
%                 state = 'new_statement';
%                 
%             case 'end'
%                 
%                 endRowsList = rowStrList(iRow+1:end);
%                 break   % Break the while loop.
%                 
%             otherwise
%                 
%                 error('Unknown state');
%         end
%         
%         
%         
%     end
%
%     % Shorten cell arrays to remove unused entries (since these are preallocated variables).
%     AsgList.keys   = keys(1:iKv);
%     AsgList.values = values(1:iKv);
    
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
% iBeforeFirst : Index into AsgList fields, one before where to start. Not an OBJECT statement which triggered
%                the call to the function. 
% iLast     : The last index into AsgList fields which was analyzed.
%             Excludes any ENB_OBJECT which triggered ending the function.
%-------------------------------------------------------------------------------------------------
function [Ssl, Ss, iLast] = construct_structs(AsgList, iBeforeFirst)

    Ss = struct;

    Ssl         = [];
    Ssl.keys    = cell(0,1);
    Ssl.values  = cell(0,1);
    Ssl.objects = cell(0,1);
    
    % ASSERTION: Replaced by other assertion
    %if length(AsgList.keys) < 1
    %    error('Too few (less than one) key-value assignments.')
    %elseif ~strcmp(AsgList.keys{1}, 'PDS_VERSION_ID') || ~strcmp(AsgList.values{1}, 'PDS3')
    %    % Extra check for "PDS_VERSION_ID = PDS3".
    %    % "Planetary Data System Standards Reference", Version 3.6 specifies that the first key-value
    %    % should always be this. This is included to be more sure that the code will fail/error
    %    % for a non-ODL file, in case the previous parsing did not fail.
    %    error('This is not an ODL file. Does not begin with PDS_VERSION_ID = PDS3.')
    %end



    i = iBeforeFirst;     % Current index into AsgList.
    while true

        if i == length(AsgList.keys)
            iLast = i - 1;
            return
        end
        i = i+1;
        
        key   = AsgList.keys{i};
        value = AsgList.values{i};
        %disp(['Reconstructed line : ', key, ' === ', value])  % DEBUG
        
        if strcmp(key, 'OBJECT')
            
            [Ssl2, Ss2, iLast] = construct_structs(AsgList, i);    % NOTE: RECURSIVE CALL.
            
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
            Ssl.keys{end+1, 1}    = key;
            Ssl.values{end+1, 1}  = value;
            Ssl.objects{end+1, 1} = Ssl2;
            
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
            
            Ssl.keys{end+1, 1}    = key;
            Ssl.values{end+1, 1}  = value;
            Ssl.objects{end+1, 1} = [];
        end
        
        
    end   % while
end

%###################################################################################################

% Utility function for parsing ODL content.
% If possible, match the regex to the beginning of the string.
% Return substring beginning after the match (or original string if no match).
%
% opt = optional
function str = read_token_opt(str, regex)
    i = regexp(str, ['^', regex], 'end', 'once') + 1;
    if isempty(i)
        i = 1;
    end
    str = str(i:end);
end

%###################################################################################################

% Utility function for parsing ODL content.
% Find first regex that matches to the beginning of the string.
% Return substring beginning after the match.
% If there is no match, error (should indicate bad syntax in data).
%
% req = required
%
% ARGUMENTS AND RETURN VALUES
% ===========================
% varargin : Regular expressions.
% n        : Index into varargin for the matching regex.
function [str, token, n] = read_token_req(str, varargin)
    N_CHAR_QUOTE = 300; 
    
    for n = 1:length(varargin)
        token = regexp(str, ['^', varargin{n}], 'match', 'once');
        i = length(token) + 1;
        if i >= 2
            str = str(i:end);
            return
        end
    end
    
    reDisplayList = ['"', EJ_library.utils.str_join(varargin, '" , "'), '"'];
    error('Can not find required token defined by any of the reg.expressions %s\nwhen interpreting the following string (first %i characters) :\n%s".', ...
        reDisplayList, N_CHAR_QUOTE, str(1:min(N_CHAR_QUOTE, length(str))))
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
    if ischar(value)
        n = length(value);
        if n < 1
            ssValue = '';                    % NOTE: [] is not a string (ischar() returns false).
            %error('Finds no value for ODL key.')
            
        elseif EJ_library.utils.is_quoted(value)     % if string surrounded by quotes ...
            %(n >= 2) && (value(1) == '"') && (value(end) == '"')     % if string surrounded by quotes ...
            
            % Keep as string.
            % NOTE: ALWAYS removes quotes around string, if the quotes can be found.
            ssValue = value(2:end-1);
            
%        elseif strcmp(value, 'NaN')
            % Unnecessary? "NaN" is not PDS/ODL standard anyway?
%            ssValue = NaN;
            
        else
            % CASE: value ~= "NaN"
            
            % NOTE: Both (1) the string "NaN", and (2) non-numerically interpretable strings result in NaN.
            ssValue = str2double(value);
            if isnan(ssValue)
                % CASE: Could not interpret as string.
                ssValue = value;             % Keep as string.
            end
            
        end
        
    elseif iscell(value)
        for i = 1:numel(value)
            value{i} = derive_SS_value(value{i});   % NOTE: RECURSIVE CALL. Though only meant to be made one level deep.
        end
        ssValue = value;
        
    else
        assert(false, 'Argument is neither char nor cell array.')
        
    end
end
