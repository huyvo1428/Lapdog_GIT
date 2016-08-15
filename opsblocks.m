% opsblocks.m -- define operation blocks
% 
% Limits of operations blocks are defined by:
% 1. Start/stop of any macro
% 2. Midnight UT
% An ops block thus is defined by the continuous running of a certain
% macro during a certain day.
%
% Assumes index has been generated and exists in workspace.
% Creates data directories under the data set directory.

% Define file start times:
t0 = [index.t0]';

macro = [index.macro]';
n = length(t0);

% Operation blocks are defined by jumps in macros and day:
jumps = find(diff(floor(t0)) | diff(macro));
obe = [jumps; n];    % ops block end points
obs = [1; jumps+1];  % ops block start points
nob = length(obe);   % number of ops blocks

% FKJN edit 4 May 2015, should have done this a long time ago. if the file
% is before the archive calendar times, then we should not have it in
% the archive. Typically happens when we have a packet that starts at
% 23:59:59 the day before the archive starts ends within next day 00:00:04 or something
% that would create a small stub file from 23:59:59 to 23:59:59.99
if t0(obs(1)) < datenum(missioncal_starttime)
    obs(1) = [];
    obe(1) = [];
    nob = nob-1;
end


% Prepare obs block list for all archive
mac = macro(obs);
tmac0 = t0(obs);  % Start time of first file in ops block.
tmac1 = t0(obe);  % Start time of last  file in ops block.

    % str = sprintf('blocklists/block_list_%s.txt',archiveid);
% mf = fopen(str,'w');
% for j=1:nob
%     fprintf(mf,'%s   %s   %.0f\n',datestr(tmac0(j),'yyyy-mm-dd HH:MM:SS.FFF'),datestr(tmac1(j),'yyyy-mm-dd HH:MM:SS.FFF'),mac(j));
%     
% end
% fclose(mf);

%for j=1:nob
%    fprintf(mf,'%s   %s   %.0f\n',datestr(tmac0(j),'yyyy-mm-dd HH:MM:SS.FFF'),datestr(tmac1(j),'yyyy-mm-dd HH:MM:SS.FFF'),mac(j));
    




% Prepare archive with blocklist files

blockTAB = {};
rcount = 0;
cmpdate='';


for j=1:nob    % For every macro block.
    
    
    if(strcmp(datestr(tmac0(j),'yyyymmdd'),cmpdate)) % if adding to an existing block list file (same day).
        
        %append to file
        bf = fopen(blockfile,'a');
        fprintf(bf,'%s, %s, %03x\r\n', datestr(tmac0(j), 'yyyy-mm-ddTHH:MM:SS.FFF'), datestr(tmac1(j), 'yyyy-mm-ddTHH:MM:SS.FFF'), mac(j));
        rcount = rcount + 1; %number of rows
        blockTAB{end,3} = rcount; %change value of rcount of last blockfile
        blockTAB{end,5} = tmac1(j);
        
    else % If starting a new block list file.
        
        rcount = 1; %first row of new file
        %create filepath
        dirY = datestr(tmac0(j),'YYYY');
        dirM = upper(datestr(tmac0(j),'mmm'));
        dirD = strcat('D',datestr(tmac0(j),'dd'));
        
        bfolder = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD);
        
        if exist(bfolder,'dir')~=7
            mkdir(bfolder);    % NOTE: Will create parent directories as needed.
        end
        
        
        bfshort = strcat('RPCLAP_',datestr(tmac0(j),'yyyymmdd'),'_000000_BLKLIST.TAB');
        blockfile = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD,'/',bfshort);
        
        %blockTAB(end+1,1:3)={blockfile,bfshort,rcount}; %new blockfile, with path, shorthand % row count
        blockTAB(end+1, 1:5) = {blockfile, bfshort, rcount, tmac0(j), tmac1(j)}; %new blockfile, with path, shorthand % row count

        %write file
        bf = fopen(blockfile,'w');
        fprintf(bf,'%s, %s, %03x\r\n', datestr(tmac0(j), 'yyyy-mm-ddTHH:MM:SS.FFF'), datestr(tmac1(j), 'yyyy-mm-ddTHH:MM:SS.FFF'), mac(j));
    end%if
    fclose(bf); %close file
    cmpdate =datestr(tmac0(j),'yyyymmdd'); %if
        
end%for

clear rcount cmpdate 




fprintf(1,'opsblock generated\n');

% End of opsblocks.m
