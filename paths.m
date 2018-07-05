function [spiceDirectory] = paths()
% PATHS Gives paths to SPICE kernels directory and sets up MICE paths.
%   spiceDirectory = paths() returns the path to the parent directory of the
%   Rosetta SPICE kernels as a string.
%   
%   Code tries to extract the path to MICE from the SPICE metakernel file (!!)
%   in the metakernel as an item under "PATH_VALUES" and "PATH_SYMBOLS" respectively.
%   If the path is found it adds (two) derived MICE paths to the MATLAB path.
%   If the path is not found, then only a log message is given (not warning/error).
%   A caller can thus add MICE to the MATLAB path manually instead
%   of having to construct a ~non-standard metakernel.
%
%   2018-04-12: Removed dependence on irfu-matlab, since Lapdog should not need it anymore.
%--------------------------------------------------------------------------
% Get SPICE kernels parent directory from metakernel file

% Read metakernel file
fid = fopen('metakernel_rosetta.txt');
C = textscan(fid, '%s');
fclose(fid);



% Find path value
ind = 1;
% Skip forward to \begindata
while(strcmp(char(C{1}{ind}), '\begindata') == 0)
    ind = ind + 1;
end
% Skip forward to PATH_VALUES
while(strcmp(char(C{1}{ind}), 'PATH_VALUES') == 0)
    ind = ind + 1;
end
% Skip = and ( signs
ind = ind + 1;
while(strcmp(char(C{1}{ind}), '=') == 1)
    ind = ind + 1;
end
while(strcmp(char(C{1}{ind}), '(') == 1)
    ind = ind + 1;
end

% Read path values
p = (C{1}{ind});
% Remove single quotations (and covert to cell)
p = {p(2:end-1)};
ind = ind + 1;
while(strcmp(char(C{1}{ind}), ')') == 0)
    % Get next path value
    q = (C{1}{ind});
    % Concatenate cell array of path values
    p = [p q(2:end-1)];
    ind = ind + 1;
end

% Skip forward to PATH_SYMBOLS
while(strcmp(char(C{1}{ind}), 'PATH_SYMBOLS') == 0)
    ind = ind + 1;
end
% Skip = and ( signs
ind = ind + 1;
while(strcmp(char(C{1}{ind}), '=') == 1)
    ind = ind + 1;
end
while(strcmp(char(C{1}{ind}), '(') == 1)
    ind = ind + 1;
end

% Read path symbols
s = (C{1}{ind});
% Remove single quotations
s = {s(2:end-1)};
ind = ind + 1;
while(strcmp(char(C{1}{ind}), ')') == 0)
    % Get next path symbol
    t = (C{1}{ind});
    % Concatenate cell array of path symbols
    s = [s t(2:end-1)];
    ind = ind + 1;
end

% Identify SPICE and MICE paths (by comparison to path symbols array)
i_spk  = strcmpi(s, 'SPK');
i_mice = strcmpi(s, 'MICE');
%i_irfu = strcmpi(s, 'irfu-matlab');
% 
% 
% 
% p = strrep(p,p{1,1},dynampath);


spiceDirectory = cell2mat(cellstr(p(i_spk)));    % NOTE: Assigning the function's return value.
micePath = cell2mat(cellstr(p(i_mice)));
%irfuPath = cell2mat(cellstr(p(i_irfu)));

% 
% 
% if strcmp(spiceDirectory(1:49),'/Users/frejon/Documents/RosettaArchive/Lapdog_GIT')
%     dynampath = strrep(mfilename('fullpath'),'/paths','');
% 
% spiceDirectory = strrep(spiceDirectory,'/Users/frejon/Documents/RosettaArchive/Lapdog_GIT',dynampath);
% micePath = strrep(micePath,'/Users/frejon/Documents/RosettaArchive/Lapdog_GIT',dynampath);
% irfuPath = strrep(irfuPath,'/Users/frejon/Documents/RosettaArchive/Lapdog_GIT',dynampath);
%     
% end


%--------------------------------------------------------------------------
% Set up mice paths


% Add mice paths
% NOTE: If above code does not find MICE path in metakernel, then micePath will be an empty string (no errors).
if ~isempty(micePath)
    addpath([micePath '/src/mice']);
    addpath([micePath '/lib']);
else
    % NOTE: Useful not to give errors, so that Lapdog also works with metakernel without MICE path.
    fprintf('Notice: Can not find MICE path in metakernel. Requires MICE to have been added to the MATLAB path by the caller.\n')
end

% Add irfu-matlab path
%addpath(irfuPath);    % Path to irfu-matlab should not be needed anymore.


end

