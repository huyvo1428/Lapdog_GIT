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


IN.spisprobe_A= 0.0076791868;
IN.spisprobe_r= sqrt(IN.spisprobe_A/(4*pi));
IN.spisprobe_cA= pi*IN.spisprobe_r^2;



% Some macros need to be handled with special care
% Constant list known everywhere
% Must be interpreted the same way as index(:).macro, i.e.
% the macro interpreted as a hexadecimal number.
global LDLMACROS;
LDLMACROS = hex2dec({'807','814','816','817','827','805','804','803','617','703','704','715','716'});    % NOTE: Must use cell array with strings for hex2dec ({} not []).




global MISSING_CONSTANT
MISSING_CONSTANT=-1e9;%-1000000000;
global SATURATION_CONSTANT
SATURATION_CONSTANT=MISSING_CONSTANT;


global VFLOATMACROS;

VFLOATMACROS{1} = hex2dec({'410','411','412','413','416','616','710','715','716','801','802','910'});    % NOTE: Must use cell array with strings for hex2dec ({} not []).
%VFLOATMACROS(:,2) = hex2dec({'410','415','417','615','617','710','801','802','910'});
VFLOATMACROS{2} = hex2dec({'415','417','615','617','710','801','802','910'});

%global LAP2Ionmacros;

%LAP2Ionmacros{1} = hex2dec({'410','411','412','413','416','515','516','525','610','624','900','904','905','926'});    % NOTE: Must use cell array with strings for hex2dec ({} not []).
%LAP2Ionmacros{1} = hex2dec({'515','516','525','610','624','900','904','905','926'});    % NOTE: Must use cell array with strings for hex2dec ({} not []).


global usc_tabindex
usc_tabindex=[];








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
            error('Can not identify mission phase in mission calendar file "%s".', missioncalendar);
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


global WOL V2C eog_32S

load('WOL.mat','WOL');
load('V2_contamination_times.mat','V2C');
load('eog_minimal.mat','eog_32S');

% Read info from DATASET.CAT:
dname = strcat(archivepath,'/CATALOG/DATASET.CAT'); 
dp = fopen(dname,'r');
if dp == -1
    error('Can not find DATASET.CAT (%s). This usually due to not being able to find the CALIB data set directory.\n    Is the DATA_SET_ID target correct ("A", "C" etc)?', dname)
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
