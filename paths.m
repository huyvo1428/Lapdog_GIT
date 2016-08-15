function [spiceDirectory] = paths()
% PATHS Gives paths to SPICE kernels directory and sets up MICE paths.
%   spiceDirectory = path() returns the path to the parent directory of the
%   Rosetta SPICE kernels as a string.
%   
%   NOTE: It also extracts the paths to MICE and irfu-matlab from the metakernel file (!!)
%   and adds them to the MATLAB path.
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
i_irfu = strcmpi(s, 'irfu-matlab');
% 
% 
% 
% p = strrep(p,p{1,1},dynampath);


spiceDirectory = cell2mat(cellstr(p(i_spk)));    % NOTE: Assigning the function's return value.
micePath = cell2mat(cellstr(p(i_mice)));
irfuPath = cell2mat(cellstr(p(i_irfu)));

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
addpath([micePath '/src/mice']);
addpath([micePath '/lib']);

% Add irfu-matlab path
addpath(irfuPath);


end

