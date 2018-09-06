%
% Convert (relative/absolute) path to an absolute (canonical) path.
% (MATLAB does indeed seem to NOT have a function for doing this(!).)
% Also converts "~" to the home directory.
%
% IMPORTANT NOTE: Only works for objects whose parent directory exists. The object itself does not have to exist.
%
% NOTE: MATLAB does indeed seem to NOT have a function for getting the absolute path!
% NOTE: Will work with ~ (home directory). Will not work with which otherwise contain ~ in directory/object names.
% NOTE: The resulting path will NOT end with slash/backslash unless it is the system root directory on Linux ("/").
% NOTE: Not entirely sure how it works with symlinks but it probably works correctly.
% NOTE: Will replace symlinks with non-symlinks.
%
%
% Author: Erik P G Johansson
% First created 2016-06-09.
%
function path = get_abs_path(path)
% PROPOSAL: Uses Linux's "readlink -f".
%       CON: Platform dependent.
% PROPOSAL: Use "fileparts" to make it work for files in existing directories.

% ~BUG/NOTE: Will convert the "~" in filenames/directory names to the home directory. Such files exist on Linux.
%       NOTE: Function does not yet work on regular files anyway.

try
    homeDir = getenv('HOME');
    path = strrep(path, '~', homeDir);
    
    if ~exist(path, 'dir')
        [dirPath, basename, suffix] = fileparts(path);   % NOTE: If ends with slash, then everything is assigned to dirPath!
   
        % Uses MATLAB trick to convert path to absolute path.
        dirPath = cd(cd(dirPath));
        path = fullfile(dirPath, [basename, suffix]);
    else
        path = cd(cd(path));
    end
catch exc
    error('Failed to convert path "%s" to absolute path.\nException message: "%s"', path, exc.message)
end

end
