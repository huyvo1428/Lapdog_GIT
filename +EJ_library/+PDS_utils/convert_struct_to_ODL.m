% Function for converting an SSL data structure into string of multiline text that can be easily written to file (by
% some other function).
% 
% IMPLEMENTATION NOTE: This functionality is separate, from in particular file-writing code, to make the code more
% easily automatically testable.
%
%
% ARGUMENTS
% =========
% Ssl                : SSL data structure. See EJ_library.PDS_utils.convert_struct_to_ODL.
% contentRowMaxWidth : Max number of characters per row, excluding line break.
%                      NOTE: Not strictly implemented. Could be exceeded in rare special cases with too much
%                      indentation, too long keywords or (non-line-breakable) key values.
% fileStr            : Multiline string (1xN) ending with line break.
%
function fileStr = convert_struct_to_ODL(Ssl, endRowsList, indentationLength, contentRowMaxLength, lineBreak)
    % PROPOSAL: Use "construct_key_assignment" also for OBJECT assignments.
    %   NOTE: The want to use it for END_OBJECT assignments too, with the right whitespace padding.
    % PROPOSAL: Line-break assignments from the very first character (maybe first non-whitespace character).
    %
    % PROPOSAL: Policy for error/warning/nothing.
    
    % ASSERTIONS
    assert(indentationLength < contentRowMaxLength)     % Should catch confusing indentationLength with contentRowMaxLength.
    EJ_library.utils.assert.castring(lineBreak)
    EJ_library.PDS_utils.assert_SSL_is_PDS3(Ssl)
    
    C.indentationLength   = indentationLength;
    C.contentRowMaxLength = contentRowMaxLength;
    C.lineBreak           = lineBreak;
    
    % ASSERTION
    %if Ssl.keys
    
    fileStr = write_key_values(Ssl, C, 0);
    
    fileStr = [fileStr, 'END', C.lineBreak];
    
    if ~isempty(endRowsList)
        fileStr = [fileStr, EJ_library.utils.str_join(endRowsList, C.lineBreak), C.lineBreak];
    end
end



% NOTE: Recursive function for OBJECT segments.
% 
% ARGUMENTS
% =========
% C   : Constants
%       C.rowMaxLength : Excludes length of line break.
% Ssl : SSL data struct.
function fileStr = write_key_values(Ssl, C, indentationLevel)
    % PROPOSAL: Assertions for quoted   values: quotes at boundaries only, no whitespace.
    % PROPOSAL: Assertions for unquoted values: no whitespace.

    % ASSERTION: Check that fields have ~same size. Implicitly checks that fields exist.
    if length(Ssl.keys) ~= length(Ssl.values) || length(Ssl.keys) ~= length(Ssl.objects)
        error('.keys, .values, and .objects do not have the same length.')
    end

    fileStr = '';

    nonObjectKeyList      = Ssl.keys(cellfun(@isempty, Ssl.objects));    % Create list of keys without OBJECT/subsections.
    maxNonObjectKeyLength = max(cellfun(@length, nonObjectKeyList));     % NOTE/BUG?: May be undetermined if there are only OBJECT keys.

    indentationStr = repmat(' ', 1, C.indentationLength*indentationLevel);

    for i = 1:length(Ssl.keys)
        key    = Ssl.keys{i};
        value  = Ssl.values{i};
        object = Ssl.objects{i};
        
        % IMPLEMENTATION NOTE: Check that key and value are strings.
        % Want to do this explicitly for VALUES to make sure that no temporary value (e.g. []) added by one part of the
        % code, and meant to be overwritten by some other part, somehow survives into a LBL file.
        EJ_library.utils.assert.castring(key)
        
        if ~strcmp(key, 'OBJECT') && isempty(object)
            %======================
            % CASE: non-OBJECT key
            %======================
            
            % How many characters shorter the current key is, compared to the longest non-OBJECT key is.
            postKeyPaddingLength = maxNonObjectKeyLength - length(key);

            str = construct_key_assignment(key, value, postKeyPaddingLength, indentationStr, C.contentRowMaxLength, C.lineBreak);
            
            fileStr = [fileStr, str];

        elseif strcmp(key, 'OBJECT') && ~isempty(value) && ~isempty(object) && isstruct(object)
            %==================
            % CASE: OBJECT key
            %==================
            
            % Print OBJECT with different "post-key" whitespace padding.
            fileStr = [fileStr, sprintf('%s%s = %s%s', indentationStr, key, value, C.lineBreak)];

            fileStr = [fileStr, write_key_values(object, C, indentationLevel+1)];             % NOTE: RECURSIVE CALL
            fileStr = [fileStr, sprintf('%sEND_OBJECT = %s%s', indentationStr, value, C.lineBreak)];
        else
            % ASSERTION
            error('Inconsistent combination of key, value, and object.')
        end
    end
end



% Try to construct (potentially) line-broken string for key assignment value.
% Line-breaking will only give error if line-breaking on non-first rows fail.
% The caller must handle line breaking error on first row.
%
% IMPLEMENTATION NOTE: This function exists so that the caller may handle some line-breaking errors by detecting error,
% and then try again with modified input arguments.
% Rows with a lot of post-key padding like
%   'FILE_NAME                            = "LAP_20160629_000000_816_B1S.LBL"'
% have had needed this.
%
% RETURN VALUES
% =============
% fileStr        : String of characters representing multiple rows including linebreaks. To be added to string
%                  representing entire ODL file content.
function [fileStr] = construct_key_assignment(key, value, postKeyPaddingLength, indentationStr, rowMaxLength, lineBreak)
    % PROPOSAL: Separate function (within package).
    %   PRO: Can test automatically.
    % PROPOSAL: If first row of line-broken value does not fit row, and removing post-key padding is not enough, then
    %           try removing indentation.

    EQUALITY_STR = ' = ';

    %==========================================================
    % Handle different cases. Determine whether to line-break.
    %==========================================================
    % The algorithm only line-breaks keyword values which are both
    % (1) quoted, and
    % (2) not already line broken (to be on the safe side; value might have been manually line-broken like a long text
    %     segment, e.g. DATASET.CAT).
    % The algorithm never line-breaks between keyword and "=".
    %
    % NOTE: According to testing with DVALNG (2019-02-04):
    % (1) keyword assignments with non-quoted value can not be line-broken at all (neither before nor after "=")
    % (2) keyword assignments with quoted value can be line-broken, but only (a) between "=" and opening quote, and (b)
    %     between quotes (inside the value).
    % (3) keyword assignments with ODL array can be line-broken first after opening curly bracket.
    %
    % NOTE: ODL arrays: DVALNG seems to accept ODL assignments with
    % (1) linebreaks after the left curly bracket (not earlier),
    % (2) quoted and unquoted individual values (must not be consistent within array).
    %
    if iscell(value)
        % CASE: ODL array
        
        % NOTE: Re-makes ODL array into string (which can be line-broken).
        % NOTE: Whitespace between left curly bracket and first string value, so that algorithm can line break in
        % between if necessary.
        value = ['{ ', EJ_library.utils.str_join(value, ', '), ' }'];
        permitEmptyFirstRow = false;
        shouldLineBreak     = true;
        
    elseif ischar(value)
        % CASE: String value
        
        containsLineBreaks = ~isempty(strfind(value, lineBreak));
        if EJ_library.utils.is_quoted(value)            
            % CASE: Quoted string value
            permitEmptyFirstRow = true;
            shouldLineBreak     = ~containsLineBreaks;
        else
            % CASE: Unquoted string value
            
            % ASSERTION
            if containsLineBreaks
                error('Unquoted value contains line breaks. ODL does not permit this(?).')
            elseif ~isempty(strfind(value, '"'))
                error('Unquoted value contains interior quote character(s).')
            end
            
            shouldLineBreak = false;
        end
    else
        % ASSERTION
        error('Illegal value. Neither cell array, nor string. key="%s", class(value)=%s', key, class(value))
    end
    

    
    firstLbValueRowMaxLength = rowMaxLength - length(indentationStr) - length(key) - postKeyPaddingLength - length(EQUALITY_STR);   % NOTE: Refers to value to submit to "break_text".
    if shouldLineBreak        
        %========================
        % CASE: Line break value
        %========================
        [value, rowList] = EJ_library.utils.break_text(value, ...
            firstLbValueRowMaxLength, ...    % NOTE: String contains beginning quote. Therefore does NOT need to subtract 1 from rowMaxLength.
            rowMaxLength, ...
            rowMaxLength, ...         % NOTE: String contains ending quote. Therefore does NOT need to subtract 1 from rowMaxLength.
            'lineBreakStr',        lineBreak, ...
            'errorPolicy',         'Warning', ...
            'permitEmptyFirstRow', permitEmptyFirstRow);   % NOTE: Permit failed line breaking without error. ==> Check manually instead.        

        firstLbValueRowLength = length(rowList{1});

        % WARNING
        if ~isempty(rowList)
            % NOTE: Excludes first row (separate warning, after trying to obtain extra row space). Includes last row.
            for iRow = 2:length(rowList)
                if length(rowList{iRow}) > rowMaxLength
                    warning('Failed to line-break within row max length.')
                    break
                end
            end
        end
    else
        %===============================
        % CASE: Do not line break value
        %===============================
        firstLbValueRowLength = strfind(value, lineBreak) - 1;  % Exclude line break itself.
        if isempty(firstLbValueRowLength)
            firstLbValueRowLength = length(value);
        else
            % NOTE: strfind can return multiple values, i.e. vector, from which only the first value is used.
            firstLbValueRowLength = firstLbValueRowLength(1);
        end
    end
    
    % Try to handle too long first row by reducing post-key padding.
    firstRowExcess = firstLbValueRowLength - firstLbValueRowMaxLength;
    if firstRowExcess > 0
        postKeyPaddingLength = postKeyPaddingLength  - firstRowExcess;
        if postKeyPaddingLength < 0
            postKeyPaddingLength = 0;
            warning('Failed to line-break within row max length for key row.')
        end
    end
    
    
    
    % Create string of whitespaces used for placing "=" so that all "=" line up.
    postKeyPadding = repmat(' ', 1, postKeyPaddingLength);
    
    % IMPLEMENTATION NOTE: Puts together, and writes, string to file without using fprintf/sprintf since the value
    % string may contain characters interpreted by fprintf/sprintf. Code has previously generated warnings
    % when using fprintf/sprintf but this avoids that.    
    fileStr = [indentationStr, key, postKeyPadding, EQUALITY_STR, value, lineBreak];
end
