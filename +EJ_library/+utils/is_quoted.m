%
% Determine whether string is quoted. Primarily intended to be useful for handling PDS keywords.
% Function created so that EJ_library.utils.quote and EJ_library.utils.unquote can use it and have a clearly defined and uniform algorithm.
%
% NOTE: Assumes that both first and last character cannot be escaped quotes.
% NOTE: Only checks first and last character (if string length >= 2). Does not check for interior quotes, in case interior escaped quotes are legal.
% NOTE: Does not distinguish badly quoted (e.g. only quote in the beginning, but not the end; quotes in the middle of the string), and entirely without quotes.
%
%
% ARGUMENTS
% =========
% s : String.
% 
%
% Initially created 2018-10-08, Erik P G Johansson.
%
function isQuoted = is_quoted(s)
% NOTE: See erikgjohansson.utils.quote for BOGIQ.
    
    % NOTE: No assertion on interior quotes.
    isQuoted =   (length(s) >= 2)   &&   s(1) == '"'   &&   s(end) == '"';
end
