function [] = time_comp(varargin)
%TIME_COMP compares the S/C clock time conversions of the archive and SPICE
%   time_comp converts the S/C clock string timestamps of the data in the 
%   archive to ephemeris seconds past J2000 (ET) using cspice routines and
%   compares the result to the ephemeris times produced when converting
%   from the UTC strings in the archive. The differences are plotted vs
%   time.
%
%   Also, the time increments between successive samples are calculated and
%   plotted for the two ET sequences.
%
%   (Different SCLK kernels can be used by changing metakernel_rosetta.txt.)

%--------------------------------------------------------------------------
% Set up paths
paths();



%--------------------------------------------------------------------------
% Load SPICE kernel files
kernelFile = 'metakernel_rosetta.txt';
cspice_furnsh(kernelFile);

%--------------------------------------------------------------------------
% Get path to archive directory
if(nargin == 1)
    archivePath = cell2mat(varargin);
else
    archivePath = cd;
end

%--------------------------------------------------------------------------
% Import data


archivePath = '~/Rosetta/temp/20Sep/RPCLAP_20160920_124156_412_V1L.TAB';
archivePath = '~/Rosetta/temp/20Sep/';

%/mnt/squid/RO-C-RPCLAP-5-1608-DERIV-V0.8/2016/AUG/D16/RPCLAP_20160816_182211_416_V1L.TAB
archivePath='/mnt/squid/RO-C-RPCLAP-5-1608-DERIV-V0.8/2016/AUG/D16/';
V1L_files = dir([archivePath '/*_V1L.TAB']);
V1L = importdata([archivePath '/' V1L_files(1).name]);

% V2L_files = dir([archivePath '/*_V2L.TAB']);
% V2L = importdata(V2L_files.name);

%--------------------------------------------------------------------------
% Time conversions

% S/C clock string to ephemeris seconds past J2000 (ET)
 
% Encoded S/C clock 'ticks' to string conversion, then to ET

for i = 1:length(V1L.data(:,1))
    sct{i}=obt2sct(V1L.data(i,1));    
    
end
scdecd_V1L = cspice_scs2e(-226, cspice_scdecd(-226, sct.'));



scs2e_V1L=scdecd_V1L;
% Encoded S/C clock 'ticks' to ephemeris seconds past J2000 (ET)
sct2e_V1L = cspice_sct2e(-226, sct');

% Convert all above ET:s to UTC for readability
utc_scs2e = cspice_et2utc(sct2e_V1L, 'ISOC', 6);
utc_scdecd = cspice_et2utc(scdecd_V1L, 'ISOC', 6);
utc_sct2e = cspice_et2utc(sct2e_V1L, 'ISOC', 6);

%--------------------------------------------------------------------------
% Output

% Display for comparison with archive UTC:s
A = [V1L.textdata cellstr(utc_scs2e) cellstr(utc_scdecd) cellstr(utc_sct2e)];
% disp(A);

% Plot
% Convert archive UTC times to Ephemeris Time (ET)
ET_archive = cspice_str2et(V1L.textdata);

% Plot difference
H = irf_plot(1, 'newfigure');
irf_plot(H(1), [irf_time(scs2e_V1L, 'et2epoch')' ET_archive'-scs2e_V1L'], 'k', ...
    'LineWidth', 1.2)
set(H(1), 'FontSize', 18)
set(get(H, 'xlabel'), 'FontSize', get(H(1), 'FontSize'))
ylabel('Time difference (s)', 'FontSize', get(H(1), 'FontSize'))
axes(H(1));
limY = ylim;
axis tight;
ylim(limY);


% Plot increments
% h = irf_plot(4, 'newfigure');
h = irf_plot(2, 'newfigure');

irf_plot(h(1), [irf_time(scs2e_V1L(1:end-1), 'et2epoch')' diff(ET_archive)'], 'k', 'LineWidth', 1.2)
set(h(1), 'FontSize', 18);
ylabel(h(1), 'Archive time increment (s)', 'FontSize', get(h(1), 'FontSize'));
axes(h(1));
limY = ylim;
axis tight;
ylim(limY);
irf_timeaxis(h(1), 'nolabels');

irf_plot(h(2), [irf_time(scs2e_V1L(1:end-1), 'et2epoch')' diff(scs2e_V1L)'], 'k', 'LineWidth', 1.2)
set(h(2), 'FontSize', get(h(1), 'FontSize'));
set(get(h(2), 'xlabel'), 'FontSize', get(h(2), 'FontSize'))
ylabel(h(2), 'SPICE time increment (s)', 'FontSize', get(h(2), 'FontSize'));
axes(h(2));
limY = ylim;
axis tight;
ylim(limY);
% irf_timeaxis(h(2), 'nolabels');

% irf_plot(h(3), [irf_time(scs2e_V1L(1:end-1), 'et2epoch')' 10^6*diff(scdecd_V1L)'], 'k', 'LineWidth', 1.2)
% set(h(3), 'FontSize', get(h(1), 'FontSize'));
% ylabel(h(3), 'Time increment (\mus)', 'FontSize', get(h(3), 'FontSize'));
% axes(h(3));
% limY = ylim;
% axis tight;
% ylim(limY);
% irf_timeaxis(h(3), 'nolabels');
% 
% irf_plot(h(4), [irf_time(scs2e_V1L(1:end-1), 'et2epoch')' 10^6*diff(sct2e_V1L)'], 'k', 'LineWidth', 1.2)
% set(h(4), 'FontSize', get(h(1), 'FontSize'));
% set(get(h(4), 'xlabel'), 'FontSize', get(h(4), 'FontSize'))
% ylabel(h(4), 'Time increment (\mus)', 'FontSize', get(h(4), 'FontSize'));
% axes(h(4));
% limY = ylim;
% axis tight;
% ylim(limY);

end

















