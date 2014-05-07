%batch_control.m


%dynpath = strrep(mfilename('fullpath'),'/Lapdog_GIT/batch_control','');
%pathtopds = strcat(dynpath,'/pds.conf');

% 
% [status,home] = unix('$HOME')
% 
% 
% pdsconf =strcat('~/','pds.conf');
% 
% 
% 
% tmprID = fopen(pdsconf,'r');
% 
% conf = textscan(tmprID, '%s %*[^\n]');
% 
% 
% temp = textscan(tmprID, '%s %*[^\n]','HeaderLines',5);
% 
% 
% % %scantemp = textscan(tmprID,'%s','delimiter',',');
% fclose(tmprID);
% 
% % 
% 
% 
% 
% ind= find(ismember(conf{1,1},'%')); %find last header line
% 
% m = sprintf('\''%s\''',conf{1,1}{ind(end)+7,1});
% missioncalendar= conf{1,1}{ind(end)+7,1};



%missioncalendar = '/Users/frejon/Documents/RosettaArchive/Lapdog_GIT/Mission_Calendar.txt';






% Define the dataset:

%'lapdog: calling control...'
%control;

producerfullname='Fredrik Johansson';
producershortname='FJ';


% 2. Control section
% ==================
do_geom = 0;  % Geometry file preparation off/on
do_mill = 1;  % Data processing  off/on
fix_geom_bug = 1;  % To change signs of position and velocity coordinates

% 3. Versioning
% =============

% Info for geometry labels
lbltime = '2013-02-03T12:00:00';  % label revision time
lbleditor = 'FJ';
lblrev = '4th draft';

% 4. Dataset selection and description
% ====================================

% RVM2 calibrated:
%shortphase = 'RVM2';
%archivepath = '/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/RO-SS-RPCLAP-3-RVM2-CALIB-V1.0';

archivepath = archpath;
shortphase = archID;


% % % Available mission phase short names:
% % GRND  LEOP   CVP  EAR1
% %  CR2  MARS   CR3  EAR2
% % CR4A  AST1  CR4B  EAR3
% %  CR5  AST2  RVM1   CR6  
% % RVM2   GMP   SSP    CE
%  EXT

% 5. Mission Calendar
% ====================================

% (this path should really be dynamically read from user's pds.conf file)
% !!!


%set when lapdog is called


% 6. Output path
% ====================================

derivedpath = strrep(archivepath,'RPCLAP-3','RPCLAP-5');
derivedpath = strrep(derivedpath,'CALIB','DERIV');
