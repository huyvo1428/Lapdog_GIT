%
% Join cell array of strings (and delimiter into one long string).
%
% IMPLEMENTATION NOTE: join, strjoin would do the same job, but they do not exist in MATLAB R2009a.
%
%
% ARGUMENTS
% =========
% strList   : Cell array of strings.
% delimiter : String.
%
%
% Initially created 2018-08-27 by Erik P G Johansson.
%
function str = str_join(strList, delimiter)
    assert(iscell(strList))
    EJ_library.utils.assert.castring(delimiter)
    
    str = '';
    for i = 1 : numel(strList)
        if i == numel(strList)
            delimiter = '';
        end
        %assert(ischar(strList{i}))
        str = [str, strList{i}, delimiter];    % Can fail (i.e. NOT give error) if strList{i} is numeric vector.
    end
end
