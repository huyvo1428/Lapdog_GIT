%
% Convert (relative/absolute) path to an absolute path (not necessarily canonical).
% (MATLAB does indeed seem to NOT have a function for doing this(!).)
% Also converts "~" to the home directory.
%
% IMPORTANT NOTE: Only works for objects whose parent directory exists. The object itself does not have to exist.
%
% NOTE: MATLAB does indeed seem to NOT have a function for getting the absolute path!
% NOTE: Will work with ~ (home directory). Will not work with which otherwise contain ~ in directory/object names.
% NOTE: The resulting path will NOT end with slash/backslash unless it is the system root directory on Linux ("/").
%
% ~BUG/NOTE: Will convert the "~" in filenames/directory names to the home directory. Such files exist on Linux.
% NOTE: Only works with filesep = "/"
%
% Author: Erik P G Johansson
% First created 2016-06-09.
%
function path = get_abs_path(path)
% PROPOSAL: Uses Linux's "readlink -f".
%       CON: Platform dependent.
%
% PROPOSAL: Use "what".
%   NOTE: Does not work on files.
% PROPOSAL: Use "fileparts" to make it work for files in existing directories.
%
% NOTE: Different use cases, operations.
%   PROPOSAL: Convert (absolute or relative) to absolute path: add current directory to path.
%       NOTE: Does not require existing object.
%   PROPOSAL: Find canonical path: Replace symlinks with non-links.
%       NOTE: Requires existing object (or at least up to last link).
%   PROPOSAL: Rationalize away .. and .
%       NOTE: Does not require existing object.
%   PROPOSAL: Replace ~ with home dir.
%       NOTE: Does not require existing object.
%
% PROPOSAL: Test code.

try
    homeDir = getenv('HOME');
    path = strrep(path, '~', homeDir);
    
    if ~exist(path, 'dir')
        [dirPath, basename, suffix] = fileparts(path);   % NOTE: If ends with slash, then everything is assigned to dirPath!
   
        % Uses MATLAB trick to convert path to absolute path.
        %dirPath = cd(cd(dirPath));
        whatInfo = what(dirPath);
        dirPath = whatInfo.path;
        path = fullfile(dirPath, [basename, suffix]);
    else
        %path = cd(cd(path));
        whatInfo = what(path);
        path = whatInfo.path;
    end
    
    path = regexp(path, '^(/.*[^/]|/)', 'match');    % Remove trailing slashes, except for system root.
    path = path{1};
    
catch Exc
    error('Failed to convert path "%s" to absolute path.\nException message: "%s"', path, Exc.message)
end

end
