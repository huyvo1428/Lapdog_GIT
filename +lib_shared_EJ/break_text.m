%
% Take string of human-readable text and break it into multiple pieces/"row" assuming maximum row length.
% Replaces certain substrings (LBC) with a specified string representing a line break.
% NOTE: The problem is not entirely well defined. A human can see multiple "solutions" to line-breaking the same text.
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
% lineBreakStr       : String to be used to represent inserted line break.
% errorPolicy        : String that says what to do when can not satisfy the rowMaxLength values.
%   'Error'              : Error
%   'Permit longer rows' : Permit longer rows, but only when necessary to.
%
% NOTE: Row max lengths EXCLUDE the length of lineBreakStr.
%
%
% RETURN VALUES
% =============
% str     : String including line breaks. NOTE: There will be no added line break at the end of the string. This is
%           useful sometimes, eg. for quoting the entire string when writing ODL file keyword values.
% strList : String as list of strings ("rows"), separated by the line breaks which are not included in these strings.
%
%
% SPECIAL CASES
% ==============
%  * Zero-length string ==> Zero length string.
%  * Ignores initial whitespace (kept).
%  * Trailing whitespace will be removed.
%  * If the string begins with something that can not be line-broken within firstRowMaxLength, but which can be line-broken
%    within midRowsMaxLength, then the function will fail rather than begin with line break. Same for midRowsMaxLength
%    and lastRowMaxLength.
%  * Fewer than three rows: Somewhat uncertain, but probably correct behaviour.
%       For two rows: Likely that midRowsMaxLength is not used.
%       For one row:  Likely that firstRowMaxLength is used.
%  * ~BUG: Algorithm can not take advantage of lastRowMaxLength > midRowsMaxLength. Last row will likely be shorter than
%    necessary.
%  * Strings already containing line breaks. The current implementation (2017-11-15) is not aware of preexisting line
%    breaks and will ignore. The function is not meant to be used on such strings.
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
function [str, strList] = break_text(str, firstRowMaxLength, midRowsMaxLength, lastRowMaxLength, lineBreakStr, errorPolicy)

% PROPOSAL: Separate function for finding all/next substrings which could be substituted for line breaks.
%   PRO: Could use more sophisticated algorithm for finding line breaks.
%       Ex: Not use whitespaces preceded by a digit.
% QUESTION: How handle ending whitespaces?
% PROPOSAL: Default errorPolicy.
% PROPOSAL: Assertion for string containing line breaks.
% PROPOSAL: Do not remove "unnecessary" whitespace. Policy?
%   PRO: Potentially needed for DVAL to accept broken lines of INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE".

    % ASSERTION: Check row max lengths.
    % Useful to check this in case the rox max lengths are automatically calculated (can go wrong).
    if ~all([firstRowMaxLength, midRowsMaxLength, lastRowMaxLength] > 0)
        error('At least one row max length argument is non-positive.')
    end
    
    

    strList = {};
    rowMaxLength = firstRowMaxLength;
    while true    % Iterate over linebreaks.

        [str1, str2] = line_break_once(str, rowMaxLength, errorPolicy);
        strList{end+1} = str1;
        
        if isempty(str2)
            break
        end
        str = str2;
    
        rowMaxLength = midRowsMaxLength;
    end
    
    % STATE: length(strList{end}) <= rowMaxLength
    % (rowMaxLength could be either firstRowMaxLength or midRowsMaxLength).
    if length(strList{end}) > lastRowMaxLength
        strList{end+1} = '';
    end
        
    
    % Convert list of strings to string with characters for line breaks.
    str = strList{1};
    for i = 2:numel(strList)
        str = [str, lineBreakStr, strList{i}];
    end
end



% ASSUMES: String does not begin with potential line break.
% No line break <=> str2 empty.
function [str1, str2] = line_break_once(str, maxRowLength, errorPolicy)
    
    LINE_BREAK_CANDIDATE_REGEXP = ' *';
    
    iLbc1Begin = 0;
    iLbc1End   = 0;    
    lbc2IsLast = false;
    while true    % Iterate over line break candidates.
        
        iLbc2Begin = iLbc1End + regexp(str(iLbc1End+1:end), LINE_BREAK_CANDIDATE_REGEXP, 'start', 'once');
        iLbc2End   = iLbc1End + regexp(str(iLbc1End+1:end), LINE_BREAK_CANDIDATE_REGEXP, 'end',   'once');
        
        if isempty(iLbc2Begin)
            % Use "virtual" LBC just after end of string.
            iLbc2Begin = length(str) + 1;
            iLbc2End   = length(str) + 1;
            lbc2IsLast = true;
        elseif iLbc2End == length(str)
            lbc2IsLast = true;
        end
        
        if (iLbc2Begin-1 > maxRowLength)
            % CASE: Using LBC2 would imply having a row that is too long. ==> Try use LBC1 for line breaking.
            if (iLbc1Begin-1 < 1)
                % CASE: Using LBC1 means having a row of zero length.
                % NOTE: This includes the case of "str" beginning with whitespace.
                switch errorPolicy
                    case 'Error'
                        error('Can not line break string. Too far between potential line breaks.')
                    case 'Permit longer rows'
                        warning('Can not line break string. Too far between potential line breaks.')
                        iLbcBeginToUse = iLbc2Begin;
                        iLbcEndToUse   = iLbc2End;
                    otherwise
                        error('Can not interpret errorPolicy="%s"', errorPolicy)
                end
            else
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
                str1 = str(1:(iLbc2Begin-1));
                str2 = '';
                return
            end
        end
        
        iLbc1Begin = iLbc2Begin;
        iLbc1End   = iLbc2End;
    end
end
