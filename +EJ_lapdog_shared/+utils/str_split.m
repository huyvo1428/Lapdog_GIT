%
% Split string using delimiter string.
%
% IMPLEMENTATION NOTE: strsplit could do the same job, but it does not exist in MATLAB R2009a.
%
%
% ARGUMENTS
% =========
% delimiter : String.
%
%
% Initially created 2018-10-30 by Erik P G Johansson.
%
function strList = str_split(str, delimiter)
    % NOTE: There is also "findstr" but MathWorks recommends against using it.
    %strfind(str, delimiter)
    
    strList = regexp(str, regexptranslate('escape', delimiter), 'split');
end