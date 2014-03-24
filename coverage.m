function [] = coverage(kernelfile)
%COVERAGE Display epoch coverage for all objects in a kernel file
%   coverage(orbitfile) finds the time covered for all objcets included in
%   the kernel file 'orbitfile' and prints them in the MATLAB terminal.

%--------------------------------------------------------------------------

% Set parent directory of mice and kernel folders
spiceDirectory = paths();
% Load kernels
cspice_furnsh('metakernel_rosetta.txt');
orbitfile = [spiceDirectory '/' kernelfile];
% Get id codes of covered objects in the orbitfile kernel
if (strcmpi(orbitfile(end-2:end), 'bsp'))
    ids = cspice_spkobj(orbitfile,1000);    % For SPK (ephemeris) kernel
elseif (strcmpi(orbitfile(end-1:end), 'bc'))
    ids = cspice_ckobj(orbitfile,1000);     % For CK (orientation) kernel
end

% Find and print coverage of all objects in the orbitfile kernel
num = length(ids);
for i = 1:num
    % Find coverage of object i
    if (strcmpi(orbitfile(end-2:end), 'bsp'))
        cover = cspice_spkcov(orbitfile, ids(i), 1000); % For SPK kernel
    elseif (strcmpi(orbitfile(end-1:end), 'bc'))
        cover = cspice_ckcov(orbitfile, ids(i), 0, 'INTERVAL', 0.0, 'TDB', ...
            1000);  % For CK kernel
    end
    % Get number of covered windows for object i (=row/2)
    [row,~] = size(cover);
    % Print name of body i
    fprintf( '========================================\n')
    [name, ~] = cspice_bodc2n(ids(i));
    % If no name found, print id code instead
    if (strcmpi(name, ''))
        name = num2str(ids(i));
    end
    fprintf(['Coverage for object ', name, '\n'])
    % Print start and stop times of all covered intervals for object i
    for j=1:2:row
        timstr = cspice_timout( cover(j:j+1)', ...
                                 'YYYY MON DD HR:MN:SC.### (TDB) ::TDB');
        fprintf('Interval: %d\n'  , (j+1)/2)
        fprintf('   Start: %s\n'  , timstr(1,:))
        fprintf('    Stop: %s\n\n', timstr(2,:))
    end
    
end

% Unload all kernels
cspice_kclear

end

