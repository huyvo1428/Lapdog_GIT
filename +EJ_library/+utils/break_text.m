%
% Take string of ~human-readable text and break it into multiple pieces/"rows" assuming maximum row length.
% Replaces certain substrings (LBC) with a specified string representing a line break.
%
% NOTE: The task of line-breaking is not entirely well defined. A human can see multiple "solutions" to line-breaking
% the same text.
%
%
% RATIONALE
% =========
% Primarily intended to be used for automatically line-breaking keyword values in ODL files. This is ~needed for longer,
% automatically generated text strings in DATASET.CAT and VOLDESC.CAT.
%
%
% ARGUMENTS
% =========
% firstRowMaxLength  : Max length of first row.
% midRowsMaxLength   : Max length of rows which are not first or last.
% lastRowMaxLength   : Max length of last row.
% varargin           : Settings as interpreted by EJ_library.utils.interpret_settings_args.
%   lineBreakStr                : String to be used to represent inserted line break.
%   errorPolicy                 : String constant. Whether to trigger error when can not satisfy the rowMaxLength values.
%       'Error'                     : Error
%       'Warning'                   : Warning. Permit longer rows, but only when necessary to.
%       'Nothing'                   : No error/warning/log message. Permit longer rows, but only when necessary to.
%                                 NOTE: The caller can still give error/warning by analyzing the returned string list.
%   permitEmptyFirstRow         : True/false. Whether to permit first row to be empty.
%   lineBreakCandidateRegexp
%   nonBreakingSpace            : String to identified as non-breaking space. Should not be matched by
%                                 lineBreakCandidateRegexp.
%   nonBreakingSpaceReplacement : Occurrences of nonBreakingSpace are replaced by this string, after the line-breaking.
%
% NOTE: Row max lengths EXCLUDE the length of lineBreakStr.
%
%
% RETURN VALUES
% =============
% str            : String including line breaks.
%                  NOTE: There will be no added line break at the end of the string. This is useful sometimes, eg. for
%                  quoting the entire string when writing ODL file keyword values.
% strList        : String as list of strings ("rows"), separated by the line breaks which are not included in these strings.
% firstRowLength : The actual length of the first row.
%
%
% SPECIAL CASES
% ==============
%  * Variables *MaxLength always exclude length of line break.
%  * Zero-length string ==> Zero length string.
%  * Ignores initial whitespace (kept).
%  * Trailing LBC (one) will be removed.
%  * If errorPolicy permits returning after failure, then the return line-breaking will contain at least one row that is
%    too long. It will never return empty rows, except when permitted by permitEmptyFirstRow (which would then not count
%    as an error/failure in the first place).
%  * Fewer than three rows: Somewhat uncertain, but probably correct behaviour.
%       For two rows: Likely that midRowsMaxLength is not used.
%       For one row:  Likely that firstRowMaxLength is used.
%  * Strings already containing line breaks. The current implementation (2017-11-15) is not aware of preexisting line
%    breaks and will ignore them. The function is not meant to be used on such strings.
%  * Middle rows are never permitted to be empty since it makes no sense. Remaining characters are pushed to the last
%    row.
%  * The last row can always be empty.
%
%
% DEFINITION OF TERMS
% ===================
% LBC = Line Break Candidate = Substring which could potentially be replaced by a line break.
%       Current implementation uses any substring equal to a continuous sequence of whitespace (surrounded by non-whitespace)
%       Exception: Initial substring.
%
%
% Initially created 2017-11-13 by Erik P G Johansson.
%
function [str, strList] = break_text(str, firstRowMaxLength, midRowsMaxLength, lastRowMaxLength, varargin)

% PROPOSAL: Separate function for finding all/next substrings which could be substituted for line breaks.
%   PRO: Could use more sophisticated algorithm for finding line breaks.
%       Ex: Not use whitespaces preceded by a digit.
%       Ex: Zero-length LBCs:
%           Ex: Boundary between { and text (ODL arrays).
%           Ex: Boundary between quote and text (quoted strings).
% QUESTION: How handle ending whitespaces?
% PROPOSAL: Assertion for string containing line breaks.
% PROPOSAL: Do not remove "unnecessary" whitespace. Setting?
%   PRO: Potentially needed for DVAL to accept broken lines of INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE".
%
% PROPOSAL: Special check in case str is shorter than firstRowMaxLength.
%   PRO: Speed up.
%   PRO: Could use firstRowMaxLength = Inf to disable line breaking.
%
% PROPOSAL: Change algorithm to first find all LBCs, then break text.
%   PRO: Might speed up algorithm by reducing calls to find LBCs.
%   PRO: Might be possible to improve algorithm (speed up, clarify).
%
% PROPOSAL: Assertion: search string for linebreaks before algorithm.

    DEFAULT_SETTINGS.lineBreakCandidateRegexp    = '[\t ]*';    % \t = tab.
    DEFAULT_SETTINGS.lineBreakStr                = sprintf('\n');
    DEFAULT_SETTINGS.errorPolicy                 = 'Error';
    DEFAULT_SETTINGS.permitEmptyFirstRow         = false;
    DEFAULT_SETTINGS.nonBreakingSpace            = '';
    DEFAULT_SETTINGS.nonBreakingSpaceReplacement = ' ';
    Settings = EJ_library.utils.interpret_settings_args(DEFAULT_SETTINGS, varargin);
    EJ_library.utils.assert.struct(Settings, fieldnames(DEFAULT_SETTINGS))
    
    

    % ASSERTION: Check row max lengths.
    % Useful to check this in case the row max lengths are automatically calculated by the caller (can go wrong).
    if ~all([firstRowMaxLength, midRowsMaxLength, lastRowMaxLength] > 0)
        error('At least one row-max length argument is non-positive.')
    end
    % ASSERTIONS
    EJ_library.utils.assert.castring(str)    
    % ASSERTION: Check that string contains no linebreaks.
    if ~isempty(regexp(str, Settings.lineBreakStr, 'once'))
        % IMPLEMENTATION NOTE: Does not print Settings.lineBreakStr since it is typically a linebreak etc which
        % typically have to be printed with escape codes to be (easily) human-readable.
        error('str="%s" (first chars) contains at least once matching occurrence of Settings.lineBreakStr.', ...
            str(1:min(numel(str), 60)))
    end
    
    
    
    strList = {};
    
    
    
    % Handle special case that no line-breaking is necessary.
    % IMPLEMENTATION NOTE: Implemented because it should speed up many calls, and is easy to implement.
    %if length(str) <= firstRowMaxLength
    %    %str = str
    %    strList{1} = str;
    %    return
    %end
    
    
    
    %================================
    % Line-break to create first row
    %================================
    [str1, str2, str1TooLong] = line_break_once(str, firstRowMaxLength, Settings.lineBreakCandidateRegexp);
    if str1TooLong
        if Settings.permitEmptyFirstRow
            % Dismiss and replace the result of the call to "line_break_once".
            str1 = '';
            str2 = str;
        else
            report_error('Can not line-break first row to a non-empty string that is short enough.', Settings.errorPolicy)
        end
    end
    strList{end+1} = str1;
    str            = str2;

    %================================================================
    % Line-break middle rows
    % NOTE: Last of middle rows may later be re-defined as last row.
    %================================================================
    while ~isempty(str)    % Iterate over linebreaks.
        
        [str1, str2, str1TooLong] = line_break_once(str, midRowsMaxLength, Settings.lineBreakCandidateRegexp);
        
        if str1TooLong
            % Dismiss the results of the call to "line_break_once".
            break
        end
        
        strList{end+1} = str1;
        str            = str2;
    end
    
    if isempty(str)
        if length(strList{end}) > lastRowMaxLength
            % CASE: Last row so far is too long to be last row.
            strList{end+1} = '';
        else
            % CASE: Last row so far is short enough to be last row.
            
            % "Redefine" last middle row as last row.
            ;
        end
    else
        if length(str) > lastRowMaxLength
            % ASSERTION
            report_error('Can not line-break string to make last row short enough.', Settings.errorPolicy)
        end
        strList{end+1} = str;
    end
    
    
    if ~isempty(Settings.nonBreakingSpace)
        %==========================================
        % Convert non-breaking space to whitespace
        %==========================================
        for i = 1:numel(strList)
            % NOTE: strrep does nothing if the old substring (Settings.nonBreakingSpace) is empty, so in principle one
            % does not need to disable using this condition.
            strList{i} = strrep(strList{i}, Settings.nonBreakingSpace, Settings.nonBreakingSpaceReplacement);
        end
    end
    
        

    % Convert list of strings to string with characters for line breaks.
    str = EJ_library.utils.str_join(strList, Settings.lineBreakStr);
end



% Never line breaks str1 to empty. If the caller thinks empty string is better, then the caller has to use this instead.
% No line break <=> str2 empty.
function [str1, str2, str1TooLong] = line_break_once(str, maxRowLength, lbcRegexp)
    % PROPOSAL: Separate function.
    %   PRO: Can write automatic test.
    
    % Set LBC1 to be a "virtual" LBC just before beginning of string.
    iLbc1Begin = 0;
    iLbc1End   = 0;
    lbc2IsLast = false;
    while true    % Iterate over LBCs.
        
        iLbc2Begin = iLbc1End + regexp(str(iLbc1End+1:end), lbcRegexp, 'start', 'once');
        iLbc2End   = iLbc1End + regexp(str(iLbc1End+1:end), lbcRegexp, 'end',   'once');
        
        if isempty(iLbc2Begin)
            % Set LBC2 to be a "virtual" LBC just after end of string.
            iLbc2Begin = length(str) + 1;
            iLbc2End   = length(str) + 1;
            lbc2IsLast = true;
        elseif iLbc2End == length(str)
            lbc2IsLast = true;
        end
        
        %if (iLbc2Begin-1 > maxRowLength)
        if (iLbc2Begin-1 > maxRowLength)   % NOTE: iLbc2Begin-1 is the length of the row, if algorithm decides to line-break at LBC2.
            % CASE: Using LBC2 would imply having a ROW THAT IS TOO LONG. ==> Try use LBC1 for line breaking.
            if (iLbc1Begin <= 0)
                % CASE: Using LBC1 means having a row of zero length.
                % NOTE: This includes the case of "str" beginning with whitespace.
                str1TooLong    = true;
                iLbcBeginToUse = iLbc2Begin;
                iLbcEndToUse   = iLbc2End;
            else
                str1TooLong    = false;                
                iLbcBeginToUse = iLbc1Begin;
                iLbcEndToUse   = iLbc1End;
            end
            
            str1 = str(1 : (iLbcBeginToUse - 1) );

            if iLbcEndToUse > length(str)
                str2 = '';
            else
                str2 = str((iLbcEndToUse+1) : end);
            end
            
            return
        else
            % CASE: iLbc2Begin-1 <= maxRowLength
            if lbc2IsLast
                % No more LBC than what already has. ==> Try use next LBC (whole string) for line breaking.
                str1TooLong = false;
                str1 = str(1:(iLbc2Begin-1));
                str2 = '';
                return
            end
        end
        
        iLbc1Begin = iLbc2Begin;
        iLbc1End   = iLbc2End;
    end
end



function report_error(msg, errorPolicy)
    switch errorPolicy
        case 'Error'
            error(msg)
        case 'Warning'
            warning(msg)
        case 'Nothing'
            ;
        otherwise
            error('Can not interpret errorPolicy="%s"', errorPolicy)
    end
end
