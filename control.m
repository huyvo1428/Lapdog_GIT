%
%control.m -- set control parameters

% Contents:
% 1. User info
% 2. Control section
% 3. Versioning
% 4. Dataset selection and description

% 1. User info
% ============
ume_user = 'liza';  % Your username on vroom.irf.umea.se

producerfullname='Fredrik Johansson';
producershortname='FJ';


% 2. Control section
% ==================
do_geom = 0;  % Geometry file preparation off/on
do_mill = 1;  % Data processing (experimental) off/on
fix_geom_bug = 1;  % To change signs of position and velocity coordinates

% 3. Versioning
% =============

% Info for geometry labels
lbltime = '2013-02-03T12:00:00';  % label revision time
lbleditor = 'FJ';
lblrev = '4th draft';

% 4. Dataset selection and description
% ====================================



% ESB1 calibrated (aie test):
%shortphase = 'EAR1';
%archivepath = '/home/aie/RO-E-RPCLAP-3-EAR1-CALIB-V1.0';

% ESB2 calibrated:
shortphase = 'EAR2';
archivepath = '/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/RO-E-RPCLAP-3-EAR2-CALIB-V1.0';


% ESB3 edited:
%shortphase = 'EAR3';
%archivepath = '/data/LAP_ARCHIVE/RO-E-RPCLAP-2-EAR3-EDITED-V1.0';

% ESB3 calibrated:
%shortphase = 'EAR3';
%archivepath = '/data/LAP_ARCHIVE/RO-E-RPCLAP-3-EAR3-CALIB-V1.0';

% Lutetia edited:
%shortphase = 'AST2';
%archivepath = '/data/LAP_ARCHIVE/RO-A-RPCLAP-2-AST2-EDITED-V1.0';

% Lutetia calibrated:
 %shortphase = 'AST2';
% archivepath = '/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/RO-A-RPCLAP-3-AST2-CALIB-V2.0';

% RVM1 edited:
%shortphase = 'RVM1';
%archivepath = '/data/LAP_ARCHIVE/RO-SS-RPCLAP-2-RVM1-EDITED-V1.0';

% RVM1 calibrated:
%shortphase = 'RVM1';
%archivepath = '/data/LAP_ARCHIVE/RO-SS-RPCLAP-3-RVM1-CALIB-V1.0';

% Available mission phase short names:
% GRND  LEOP   CVP  EAR1
%  CR2  MARS   CR3  EAR2
% CR4A  AST1  CR4B  EAR3
%  CR5  AST2  RVM1   CR6  
% RVM2   GMP   SSP    CE
%  EXT

% 5. Mission Calendar
% ====================================

% (this path should really be dynamically read from user's pds.conf file)
% !!!
missioncalendar = '/Users/frejon/Documents/RosettaArchive/Lapdog_GIT/Mission_Calendar.txt';

