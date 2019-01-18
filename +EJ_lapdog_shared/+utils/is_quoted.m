%
% Determine whether string is quoted. Primarily intended to be useful for handling PDS keywords.
% Function created so that EJ_lapdog_shared.utils.quote and EJ_lapdog_shared.utils.unquote can use it and have a clearly defined and uniform algorithm.
%
% NOTE: Assumes that both first and last character cannot be escaped quotes.
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
