%batch_control.m
%control file for lapdog.m

% Define the dataset:

%'lapdog: calling control...'
%control;

producerfullname='ERIK P G JOHANSSON';
producershortname='EJ';

global N_FINAL_PRESWEEP_SAMPLES
N_FINAL_PRESWEEP_SAMPLES = 16;    % Number of pre-sweep samples to have. Unused samples positions are set to MISSING_CONSTANT.

% 2. Control section
% ==================
do_geom = 0;  % Geometry file preparation off/on
%do_mill = 1;  % Data processing  off/on. always on
fix_geom_bug = 1;  % To change signs of position and velocity coordinates

% 3. Versioning
% =============

% Info for labels
lbltime   = '2018-07-20';  % Label revision time
lbleditor = 'EJ';
lblrev    = 'Initial release';

% 4. Dataset selection and description
% ====================================

archivepath = archpath;
shortphase = archID;


% 5. Mission Calendar
% ====================================

%set when lapdog is called


% 6. Output path
% ====================================

% Derive path to new dataset. Only apply strrep to the directory name, not the entire path.
[temp1,temp2,temp3] = fileparts(archivepath); derivedpath = fullfile(temp1, strrep([temp2, temp3], 'RPCLAP-3', 'RPCLAP-5'));
[temp1,temp2,temp3] = fileparts(derivedpath); derivedpath = fullfile(temp1, strrep([temp2, temp3], 'CALIB',   'DERIV'));

