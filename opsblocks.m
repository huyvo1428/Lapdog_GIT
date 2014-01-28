% opsblocks.m -- define operation blocks
% 
% Limits of operations blocks are defined by:
% 1. Start/stop of any macro
% 2. Midnight UT
% An ops block thus is defined by the continuous running of a certain
% macro during a certain day.
%
% Assumes index has been generated and exists in workspace.

% Define file start times:
t0 = [index.t0]';
macro = [index.macro]';
n = length(t0);

% Operation blocks are defined by jumps in macros and day:
jumps = find(diff(floor(t0)) | diff(macro));
obe = [jumps; n];    % ops block end points
obs = [1; jumps+1];  % ops block start points
nob = length(obe);   % number of ops blocks

% Prepare obs block list for all archive
mac = macro(obs);
tmac0 = t0(obs);  % Start time of first file in ops block
tmac1 = t0(obe);  % Start time of last file in ops block
macind = [tmac0 tmac1 mac];

str = sprintf('blocklists/block_list_%s.txt',archiveid);
mf = fopen(str,'w');
for j=1:nob
    fprintf(mf,'%s   %s   %.0f\n',datestr(tmac0(j),'yyyy-mm-dd HH:MM:SS.FFF'),datestr(tmac1(j),'yyyy-mm-dd HH:MM:SS.FFF'),mac(j));
end
fclose(mf);
fprintf(1,'opsblock completed\n');

% End of opsblocks.m
