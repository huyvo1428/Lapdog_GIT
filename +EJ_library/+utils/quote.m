%
% Add quotes to string. Primarily intended to be useful for handling PDS keywords.
%
% NOTE: Ignores interior quotes in order to permit escaped quotes by almost any syntax.
%
%
% ARGUMENTS AND RETURN VALUE
% ==========================
% s                 : String
% initiallyUnquoted
% 
%
% Initially created 2017-09-27, Erik P G Johansson.
%
function [s, initiallyUnquoted] = quote(s, policy)
% PROPOSAL: Permit different quote characters (single/double quotes).
% PROPOSAL: Permit cell arrays of strings.
% PROPOSAL: Flag for whether or not function should at all quote or not.
%   PROPOSAL: Useful for iteration.
%
% PROPOSAL: Shorter alternative policy strings.
%
% NEED: Want to have this functionality useful for working with lists of strings, where strings should be modified as
%       unquoted --> quoted/unquoted (depending on flags for individual strings)
%       quoted/unquoted --> unquoted (initial state varies from string to string)
%   Ex: Handling PDS keywords & values.
% NEED: Be easy to modify quoted strings, e.g. amend them.
%   Ex:
%       # Alternative initial values for s:
%       s1 =  'Beginning.';
%       s2 = '"Beginning."';
%       [s, strModif] = unquote(s, 'permit unquoted');
%       s = [s, ' End.'];
%       if strModif
%           [s, strModif] = quote(s, 'assert unquoted');
%       end
%       % s is now amended.
%
% TODO-DECISION: How handle interior quotes?
%   NOTE: Interior quotes could be escaped and legal. Depends on syntax.
%   PROPOSAL: Do not check for interior quotes.
%   PROBLEM: Need to be able to determine whether string is quoted/unquoted. ==> How distinguish surrounding quotes from escaped internal quotes?
%       PROPOSAL: Ideally, a separate (arbitrary) function should determine whether string is quoted or not.

isQuoted = EJ_library.utils.is_quoted(s);

switch policy
%    case 'always quote'
%        addQuotes = 1;
        
    case 'permit quoted'
        addQuotes = ~isQuoted;
        
    case 'assert unquoted'
        
        % ASSERTION
        if isQuoted
            error('String is already quoted.')
        end
        addQuotes = 1;
        
    otherwise
        error('Illegal argument policy="%s"', policy)
end

if addQuotes
    s = ['"', s, '"'];
end

initiallyUnquoted = ~isQuoted;

end
