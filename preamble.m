% preamble.m -- set PDS keywords etc
%
% Should geometry files be exported to the archive?
%

%export_geometry = input('Export geometry files to archive? (0/1) ');

export_geometry = 0;


global CO IN          % Physical & instrument constants
CO=[];
CO.e = 1.60217657E-19;
CO.me = 9.10938291E-31;
CO.mp = 1.67262178E-27;
CO.kb = 8.6173324E-5; %eV/K

IN.probe_r = 0.025; %rosetta probe radius.
IN.probe_A = 4*pi*IN.probe_r^2;
IN.probe_cA = pi*IN.probe_r^2;




% Set up automatic ssh login on vroom.umea.irf.se (assumes you have generated a
% public rsa key in your .ssh directory on squid and copied it to the known_hosts
% file in your .ssh directory on vroom)
% This will ask you for your ssh password once per session, instead of
% twice per day in the archive...
if(do_geom & ~exist('ssh_ok'))
  unix('eval `ssh-agent`');
  unix('ssh-add ~/.ssh/id_dsa');
  unix('ssh-add -l');
  ssh_ok = 1;
end



% Read mission calendar:
% (this path should really be dynamically read from user's pds.conf file)
fc = fopen(missioncalendar,'r');

if fc < 0
    fprintf(1,'Error, cannot open %s.\n', missioncalendar);
else
    jj = 0;
    while (jj<1000)
        line = fgetl(fc);

        if (line == -1)
            error('Can not identify mission phase in mission calendar.');
        elseif ~(strcmp(line(1),'#') || isempty(line))
            % Parse a line which is neither a comment, nor empty.
            parts = textscan(line,'%s %s %*s %*s %s %s %s %s','delimiter',':');      % * means the field will be skipped.
            shortphase_line = strtrim(strrep(char(parts{2}), '"', ''));  % Need to remove double quotes and trailing blanks from strings (strrep, strtrim)
            if strcmp(shortphase_line, shortphase)
                %need this for opsblocks.m
                missioncal_starttime= textscan(line,'%*s %*s %s %*s %*s %*s %*s %*s','delimiter',':');
                missioncal_starttime=strtrim(missioncal_starttime{1});
                break
            end
        end
        jj = jj + 1;
    end
    fclose(fc);
end

% Need to remove double quotes and trailing blanks from strings (strrep, strtrim)
missionphase   = strtrim(strrep(char(parts{1}), '"', ''));
targetfullname = strtrim(strrep(char(parts{3}), '"', ''));   % Mission calendar: "TARGET_NAME_IN_DATA_SET_ID"
targetid       = strtrim(strrep(char(parts{4}), '"', ''));   % Mission calendar: "TARGET_ID"
targettype     = strtrim(strrep(char(parts{5}), '"', ''));   % Mission calendar: "TARGET_TYPE"
global target;
target         = strtrim(strrep(char(parts{6}), '"', ''));   % Mission calendar: "TARGET_NAME_IN_DATA_SET_NAME"

% Modify "target"
% Special for solar wind, which is not defined as a target in SPICE:
% aie 130313
switch target
    case 'SW'
        target = 'SUN';
    case '67P'
        target = 'CHURYUMOV-GERASIMENKO';
    case 'STEINS'
        target = '2867 STEINS';
    case 'LUTETIA'
        target = '21 LUTETIA';
    otherwise
        %do nothing
end


if(strcmp(shortphase,'MARS')) %bug from older mission calendar
    target = 'MARS';
end

% Some macros need to be handled with special care
% Constant list known everywhere
% Must be interpreted the same way as index(:).macro, i.e.
% the macro interpreted as a hexadecimal number.
global LDLMACROS;
LDLMACROS = hex2dec({'807','816','817','827','805','804','803','617','703','704'});    % NOTE: Must cell array with strings for hex2dec ({} not []).





% Read info from DATASET.CAT:
dname = strcat(archivepath,'/CATALOG/DATASET.CAT');
dp = fopen(dname,'r');
if dp == -1
    error('Can not find DATASET.CAT. This usually due to not being able to find the CALIB data set directory.')
end
datasetcat = textscan(dp,'%s %s','Delimiter','=');
fclose(dp);

var = cellstr(char(datasetcat{1}));
val = char(datasetcat{2});
ind = find(strcmp('DATA_SET_NAME', var));
datasetname = strtrim(strrep(val(ind, :), '"', ''));   % DATA_SET_NAME of CALIB data set.
ind = find(strcmp('DATA_SET_ID', var));
datasetid   = strtrim(strrep(val(ind,:),'"',''));
tmp = textscan(datasetid,'%*s %*s %*s %d %*s %*s %*s', 'delimiter','-');
processlevel = tmp{1};

% archiveid is used internally for keeping track of index files. It is not a PDS thing.
archiveid = sprintf('%s_%d',shortphase,processlevel);

% End of preamble.m
