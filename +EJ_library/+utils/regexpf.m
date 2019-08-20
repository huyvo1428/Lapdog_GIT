%
% Roughly like regexp, except
% (1) it only matches entire strings (not substrings). In practise, it surrounds the submitted regular expressions with ^ and $.
% (2) it returns a more usable logic array.
%
% regexpf = regexp (MATLAB builtin) + f (=full match)
% 
%
% ARGUMENTS
% ========= 
% str          : String. Empty string must be of class char, i.e. e.g. not [] (due to function "regexp").
%                NOTE: Will permit empty strings to match a regular expression.
% regexPattern : CA string or cell array of CA strings. Each CA string is a regexp which may or may not be surrounded by
%                ^ and $.
%
%
% RETURN VALUE
% ============
% isMatch      : Logical array. True iff str is matched by corresponding regexp.
%                NOTE: This is different from "regexp" which returns a cell array of arrays.
%
%
% Initially created 2018-07-12 by Erik P G Johansson.
%
function isMatch = regexpf(str, regexpPattern)
    
    % IMPLEMENTATION NOTE: Empty string must be of class char, i.e. not [] (due to function "regexp").
    % IMPLEMENTATION NOTE: regexp accepts cell array of strings for strings to match (not regexp) which this function is
    % not suppoed to handle (at least not yet). Must therefore explicitly check that str is not a cell array.
    EJ_library.utils.assert.castring(str)
    
    if iscell(regexpPattern)
        
        % IMPLEMENTATION NOTE: regexp option "emptymatch" is required to match empty strings.
        isMatch = cellfun(@(re) (~isempty(regexp(str, ['^', re, '$'], 'once', 'emptymatch'))), regexpPattern);
        
    elseif ischar(regexpPattern)
        
        %EJ_library.utils.assert.castring(regexPattern)
        
        isMatch = EJ_library.utils.regexpf(str, {regexpPattern});    % RECURSIVE CALL
        
    end    
end
