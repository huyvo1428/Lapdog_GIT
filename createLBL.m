%===================================================================================================
% createLBL.m
% 
% Create .LBL files for all .TAB files.
%===================================================================================================
% PROPOSAL: Shorten all error messages except the first one(s).
% 
% PROPOSAL/TODO: Have one MISSING_CONSTANT for createLBL.m and one for ~best_estimates.m.
%    QUESTION: How?
% PROPOSAL: Put code converting tabindex and an_tabindex to structs into separate function(s).
% PROPOSAL: Different LABEL_REVISION_NOTE för CALIB2, DERIV2. Multiple rows?
% PROPOSAL: Use get_PDS.m.
% PROPOSAL: Set MISSING_CONSTANT also for IxS (VxS?) files, despite that NaN is only exchanged for MISSING_CONSTANT in
% create_C2D2_from_CALIB1_DERIV1.
%    CON: TAB and LBL files are inconsistent in DERIV1.
%
% PROPOSAL: Move different for-loops into separate functions.
%   PRO: No need to clear variables.
%   PRO: Smaller code sections.
%===================================================================================================

t_start = clock;    % NOTE: NOT a scalar (e.g. number of seconds), but [year month day hour minute seconds].
previous_warnings_settings = warning('query');
warning('on', 'all')


%=========================================================
% Read kernel file - Use default file in Lapdog directory
%=========================================================
%kernel_file = [dynampath, filesep, 'metakernel_rosetta.txt'];   % dynampath is no longer set for unknown reason.
current_m_file = mfilename('fullpath');
[Lapdog_directory, basename, ext] = fileparts(current_m_file);
kernel_file = fullfile(Lapdog_directory, 'metakernel_rosetta.txt');
if ~exist(kernel_file, 'file')
    fprintf(1, 'Can not find kernel file "%s" (pwd="%s")', kernel_file, pwd)
    % Call error too?
end
cspice_furnsh(kernel_file); 



% Set policy for error messages when failing to generate a file.
% --------------------------------------------------------------
%generate_file_fail_policy = 'message+stack trace';
generate_file_fail_policy = 'message';
%generate_file_fail_policy = 'nothing';    % Somewhat misleading. Something may still be printed.



% Set policy for errors/warning when LBL files are (believed to be) inconsistent with TAB files.
% ----------------------------------------------------------------------------------------------
%general_TAB_LBL_inconsistency_policy = 'error';
general_TAB_LBL_inconsistency_policy = 'warning';
%AxS_TAB_LBL_inconsistency_policy     = 'warning';
AxS_TAB_LBL_inconsistency_policy     = 'nothing';



%========================================================================================
% "Constants"
% -----------
% NO_ODL_UNIT: Constant to be used for LBL "UNIT" fields meaning that there is no unit.
% This means that it is known that the quantity has no unit rather than that the unit
% is simply unknown at present.
%========================================================================================
NO_ODL_UNIT       = [];
ODL_VALUE_UNKNOWN = [];   %'<Unknown>';  % Unit is unknown.
DELETE_HEADER_KEY_LIST = {'FILE_NAME', '^TABLE', 'PRODUCT_ID', 'RECORD_BYTES', 'FILE_RECORDS', 'RECORD_TYPE'};
MISSING_CONSTANT = -1000;   % NOTE: This constant must be reflected in the corresponding section in best_estimates!!!
ROSETTA_NAIF_ID  = -226;    % Used for SPICE.



%====================================================================================================
% Construct list of key-value pairs to use for all LBL files.
% -----------------------------------------------------------
% Keys must not collide with keys set for specific file types.
% For file types that read CALIB LBL files, must overwrite old keys(!).
% 
% NOTE: Only keys that already exist in the CALIB files that are read (otherwise intentional error)
%       and which are thus overwritten.
% NOTE: Might not be complete.
%====================================================================================================
kvl_LBL_all = [];
kvl_LBL_all.keys = {};
kvl_LBL_all.values = {};
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'PDS_VERSION_ID',            'PDS3');
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'DATA_QUALITY_ID',           '"1"');
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'PRODUCT_CREATION_TIME',     datestr(now, 'yyyy-mm-ddTHH:MM:SS.FFF'));
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'PRODUCT_TYPE',              '"DDR"');
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'PROCESSING_LEVEL_ID',       '"5"');

kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'DATA_SET_ID',               ['"', strrep(datasetid,   sprintf('-3-%s-CALIB', shortphase), sprintf('-5-%s-DERIV', shortphase)), '"']);
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'DATA_SET_NAME',             ['"', strrep(datasetname, sprintf( '3 %s CALIB', shortphase), sprintf( '5 %s DERIV', shortphase)), '"']);
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'LABEL_REVISION_NOTE',       sprintf('"%s, %s, %s"', lbltime, lbleditor, lblrev));
%kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'NOTE',                      '"... Cheops Reference Frame."');  % Include?!!
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'PRODUCER_FULL_NAME',        sprintf('"%s"', producerfullname));
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'PRODUCER_ID',               producershortname);
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'PRODUCER_INSTITUTION_NAME', '"SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"');
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'INSTRUMENT_HOST_ID',        'RO');
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'INSTRUMENT_HOST_NAME',      '"ROSETTA-ORBITER"');
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'INSTRUMENT_NAME',           '"ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"');
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'INSTRUMENT_TYPE',           '"PLASMA INSTRUMENT"');
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'INSTRUMENT_ID',             'RPCLAP');
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'TARGET_NAME',               sprintf('"%s"', targetfullname));
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'TARGET_TYPE',               sprintf('"%s"', targettype));
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'MISSION_ID',                'ROSETTA');
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'MISSION_NAME',              sprintf('"%s"', 'INTERNATIONAL ROSETTA MISSION'));
kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, 'MISSION_PHASE_NAME',        sprintf('"%s"', missionphase));
%kvl_LBL_all = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL_all, '', );



% IMPLEMENTATION NOTE: It is useful for the code to interpret the non-existence of "an_tabindex" as an empty variable
% since this is what you get if you disable "analysis" which is useful for speeding up the generation of CALIB2 datasets.
% Old createLBL code also seemed written on the premise that it might eb empty.
if ~exist('an_tabindex', 'var')
    warning('"an_tabindex is not defined. - Creating an empty "an_tabindex".')
    an_tabindex = [];
end
[stabindex, san_tabindex] = createLBL.convert_std_structs(tabindex, an_tabindex);



%===============================================
%
% Create LBL files for (TAB files in) tabindex.
%
%===============================================
for i=1:length(stabindex)
    try
        
        LBL_data = [];
        LBL_data.consistency_check.N_TAB_columns = stabindex(i).N_columns;
        % "LBL_data.consistency_check.N_TAB_bytes_per_row" can not be set centrally here
        % since it is hardcoded for some TAB file types.
        
        %=========================================
        %
        % LBL file: Create header/key-value pairs
        %
        %=========================================
        
        tname = stabindex(i).filename;
        lname = strrep(tname, '.TAB', '.LBL');
        Pnum = index(stabindex(i).i_index_first).probe;
        i_index_first = stabindex(i).i_index_first;
        i_index_last  = stabindex(i).i_index_last;
        
        %--------------------------
        % Read the CALIB1 LBL file
        %--------------------------
        [kvl_LBL_CALIB, CALIB_LBL_struct] = createLBL.read_LBL_file(...
            index(i_index_first).lblfile, DELETE_HEADER_KEY_LIST, ...
            index(i_index_first).probe);

        
        
        % NOTE: One can obtain a stop/ending SCT value from index(stabindex(i).i_index_last).sct1str; too, but experience
        % shows that it is wrong on rare occasions (and in disagreement with the UTC value) for unknown reason.
        % Example: LAP_20150503_210047_525_I2L.LBL
        SPACECRAFT_CLOCK_STOP_COUNT = sprintf('%s/%s', index(i_index_last).sct0str(2), obt2sct(stabindex(i).SCT_stop));
        
        kvl_LBL = kvl_LBL_all;
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'START_TIME',                   CALIB_LBL_struct.START_TIME);        % UTC start time
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'STOP_TIME',                    stabindex(i).UTC_stop(1:23));        % UTC stop time
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'SPACECRAFT_CLOCK_START_COUNT', CALIB_LBL_struct.SPACECRAFT_CLOCK_START_COUNT);
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'SPACECRAFT_CLOCK_STOP_COUNT',  SPACECRAFT_CLOCK_STOP_COUNT);
        
        kvl_LBL = lib_shared_EJ.KVPL.overwrite_values(kvl_LBL_CALIB, kvl_LBL, 'require preexisting keys');
        
        LBL_data.kvl_header = kvl_LBL;
        clear   kvl_LBL kvl_LBL_CALIB
        
        
        
        LBL_data.N_TAB_file_rows = stabindex(i).N_TAB_file_rows;
        
        
        
        %=======================================
        %
        % LBL file: Create OBJECT TABLE section
        %
        %=======================================
        if (tname(30)=='S')
            
            %=========================
            % CASE: Sweep files (xxS)
            %=========================
            
            if (tname(28)=='B')
                
                LBL_data.OBJTABLE = [];
                LBL_data.consistency_check.N_TAB_bytes_per_row = 32;   % NOTE: HARDCODED! Can not trivially take value from creation of file and read from tabindex.
                LBL_data.OBJTABLE.DESCRIPTION = sprintf('%s Sweep step bias and time between each step', CALIB_LBL_struct.OBJECT___TABLE{1}.DESCRIPTION);
                ocl = [];
                ocl{end+1} = struct('NAME', 'SWEEP_TIME',                 'FORMAT', 'E14.7', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'SECONDS', 'DESCRIPTION', 'LAPSED TIME (S/C CLOCK TIME) FROM FIRST SWEEP MEASUREMENT');
                ocl{end+1} = struct('NAME', sprintf('P%i_VOLTAGE', Pnum), 'FORMAT', 'E14.7', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'VOLT',    'DESCRIPTION', 'CALIBRATED VOLTAGE BIAS');
                LBL_data.OBJTABLE.OBJCOL_list = ocl;
                clear ocl
                
            else
                % CASE: tname(28) == 'I'
                
                Bfile = tname;
                Bfile(28) = 'B';
                
                LBL_data.OBJTABLE = [];
                LBL_data.consistency_check.N_TAB_bytes_per_row = stabindex(i).N_TAB_bytes_per_row;
                LBL_data.OBJTABLE.DESCRIPTION = sprintf('%s', CALIB_LBL_struct.OBJECT___TABLE{1}.DESCRIPTION);
                ocl = [];
                ocl{end+1} = struct('NAME', 'START_TIME_UTC',                   'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
                ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',                    'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
                ocl{end+1} = struct('NAME', 'START_TIME_OBT',                   'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
                ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',                    'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
                ocl{end+1} = struct('NAME', 'QUALITY',                          'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  3, 'UNIT', 'N/A',     'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');

                DESC_MISS = {'DESCRIPTION', sprintf('One current for each of the voltage potential sweep steps described by %s. Each current is the average over multiple measurements on a single potential step.', Bfile)};
                ocl{end+1} = struct('NAME', sprintf('P%i_SWEEP_CURRENT', Pnum), 'DATA_TYPE', 'ASCII_REAL', 'ITEM_BYTES', 14, 'UNIT', 'AMPERE', ...
                    'ITEMS', stabindex(i).N_columns-5, 'FORMAT', 'E14.7', DESC_MISS{:});
                % Adding MISSING_CONSTANT since create_C2D2_from_CALIB1_DERIV1 replaces NaN to fit with this.
                
                LBL_data.OBJTABLE.OBJCOL_list = ocl;
                clear ocl
            end
            
        else
            %=============================================
            % CASE: Anything EXCEPT sweep files (NOT xxS)
            %=============================================
            
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = CALIB_LBL_struct.OBJECT___TABLE{1}.DESCRIPTION;    % BUG: Possibly double quotation marks.
            if Pnum ~= 3
                LBL_data.consistency_check.N_TAB_columns       = 5;   % NOTE: Hardcoded. TODO: Fix!
                LBL_data.consistency_check.N_TAB_bytes_per_row = 83;  % NOTE: Hardcoded. TODO: Fix!
            else
                LBL_data.consistency_check.N_TAB_columns       = 6;   % NOTE: Hardcoded. TODO: Fix!
                LBL_data.consistency_check.N_TAB_bytes_per_row = 99;  % NOTE: Hardcoded. TODO: Fix!
            end
            
            % -----------------------------------------------------------------------------
            % Recycle OBJCOL info/columns from CALIB LBL file (!) and then add one column.
            % -----------------------------------------------------------------------------
            ocl = CALIB_LBL_struct.OBJECT___TABLE{1}.OBJECT___COLUMN;
            for i_oc = 1:length(ocl)
                oc = ocl{i_oc};
                ocl{i_oc} = rmfield(oc, 'START_BYTE');
                
                % Add UNIT for UTC_TIME since it does not seem to have it already in the CALIB LBL file.
                if strcmp(oc.NAME, 'UTC_TIME') && ~isfield(oc, 'UNIT')
                    ocl{i_oc}.UNIT = 'SECONDS';
                end
            end
            ocl{end+1} = struct('NAME', 'QUALITY', 'DATA_TYPE', 'ASCII_INTEGER', 'BYTES', 3, 'UNIT', NO_ODL_UNIT, ...
                'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
            
            LBL_data.OBJTABLE.OBJCOL_list = ocl;
            clear ocl
            
        end
        
        createLBL.create_OBJTABLE_LBL_file(stabindex(i).path, LBL_data, general_TAB_LBL_inconsistency_policy);
        clear   LBL_data
        
    catch err
        createLBL.exception_message(err, generate_file_fail_policy)
        fprintf(1,'lapdog: Skipping LBL file (tabindex) - Continuing\n');
    end    % try-catch
end    % for



%===============================================
%
% Create LBL files for (TAB files in) blockTAB.
%
%===============================================
if(~isempty(blockTAB));   % Remove?
    for i=1:length(blockTAB)
        
        LBL_data = [];
        LBL_data.consistency_check.N_TAB_columns       =  3;
        LBL_data.consistency_check.N_TAB_bytes_per_row = 55;                   % NOTE: HARDCODED! TODO: Fix.

        
        
        %==============================================
        %
        % LBL file: Create header/key-value pairs
        %
        % NOTE: Does not rely on reading old LBL file.
        %==============================================
        START_TIME = datestr(blockTAB(i).tmac0,   'yyyy-mm-ddT00:00:00.000');
        STOP_TIME  = datestr(blockTAB(i).tmac1+1, 'yyyy-mm-ddT00:00:00.000');   % Slightly unsafe (leap seconds, and in case macro block goes to or just after midnight).
        kvl_LBL = kvl_LBL_all;
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'START_TIME',                   START_TIME);       % UTC start time
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'STOP_TIME',                    STOP_TIME);        % UTC stop time
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'SPACECRAFT_CLOCK_START_COUNT', cspice_sce2s(ROSETTA_NAIF_ID, cspice_str2et(START_TIME)));
        kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'SPACECRAFT_CLOCK_STOP_COUNT',  cspice_sce2s(ROSETTA_NAIF_ID, cspice_str2et(STOP_TIME)));
        LBL_data.kvl_header = kvl_LBL;
        clear   kvl_LBL
        
        

        %=======================================
        % LBL file: Create OBJECT TABLE section
        %=======================================
        
        LBL_data.N_TAB_file_rows = blockTAB(i).rcount;
        LBL_data.OBJTABLE = [];
        LBL_data.OBJTABLE.DESCRIPTION = 'BLOCKLIST DATA. START & STOP TIME OF MACRO BLOCK AND MACRO ID.';
        ocl = [];
        ocl{end+1} = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss');
        ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',  'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'LAST START TIME OF MACRO BLOCK FILE YYYY-MM-DD HH:MM:SS.sss');
        ocl{end+1} = struct('NAME', 'MACRO_ID',       'DATA_TYPE', 'CHARACTER', 'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'HEXADECIMAL MACRO IDENTIFICATION NUMBER.');
        LBL_data.OBJTABLE.OBJCOL_list = ocl;
        clear   ocl
        
        createLBL.create_OBJTABLE_LBL_file(blockTAB(i).blockfile, LBL_data, general_TAB_LBL_inconsistency_policy);
        clear   LBL_data
        
    end   % for

end   % if 



%==================================================
%
% Create LBL files for (TAB files in) an_tabindex.
%
%==================================================
for i=1:length(san_tabindex)
    try
        TAB_LBL_inconsistency_policy = general_TAB_LBL_inconsistency_policy;   % Default value, unless overwritten for specific data file types.
        
        tname = san_tabindex(i).filename;
        lname = strrep(tname, 'TAB', 'LBL');
        
        mode = tname(end-6:end-4);
        Pnum = index(san_tabindex(i).i_index).probe;     % Probe number
        
        LBL_data = [];
        LBL_data.N_TAB_file_rows = san_tabindex(i).N_TAB_file_rows;
        LBL_data.consistency_check.N_TAB_bytes_per_row = san_tabindex(i).N_TAB_bytes_per_row;
        LBL_data.consistency_check.N_TAB_columns       = san_tabindex(i).N_TAB_columns;
        
        
        
        %=========================================
        %
        % LBL file: Create header/key-value pairs
        %
        %=========================================
        
        if strcmp(san_tabindex(i).data_type, 'best_estimates')
            %======================
            % CASE: Best estimates
            %======================
            
            TAB_file_info = dir(san_tabindex(i).path);
            kvl_LBL = kvl_LBL_all;
            kvl_LBL = lib_shared_EJ.KVPL.add_kv_pair(kvl_LBL, 'DESCRIPTION', 'Best estimates of physical quantities based on sweeps.');
            try
                %===============================================================
                % NOTE: createLBL.create_EST_LBL_header(...)
                % sets certain LBL/ODL variables to handle collisions:
                %    START_TIME / STOP_TIME,
                %    SPACECRAFT_CLOCK_START_COUNT / SPACECRAFT_CLOCK_STOP_COUNT
                %===============================================================
                i_index_src  = san_tabindex(i).i_index;
                EST_TAB_path = san_tabindex(i).path;
                i_probes = [index(i_index_src).probe];
                CALIB_LBL_paths = {index(i_index_src).lblfile};
                kvl_LBL = createLBL.create_EST_LBL_header(EST_TAB_path, CALIB_LBL_paths, i_probes, kvl_LBL, DELETE_HEADER_KEY_LIST);    % NOTE: Reads LBL file(s).
                
                LBL_data.kvl_header = kvl_LBL;
                clear kvl_LBL
                
            catch exc
                fprintf(1, ['ERROR: ', exc.message])
                fprintf(1, exc.getReport)
                
                continue
            end
            
        else
            %===============================================
            % CASE: Any type of file EXCEPT best estimates.
            %===============================================
            
            [kvl_LBL_CALIB, CALIB_LBL_struct] = createLBL.read_LBL_file(...
                index(san_tabindex(i).i_index).lblfile, DELETE_HEADER_KEY_LIST, ...
                index(san_tabindex(i).i_index).probe);
            
            % Add DESCRIPTION?!!
            kvl_LBL = lib_shared_EJ.KVPL.overwrite_values(kvl_LBL_CALIB, kvl_LBL_all, 'require preexisting keys');
            
            LBL_data.kvl_header = kvl_LBL;
            clear kvl_LBL kvl_LBL_CALIB
            
        end   % if-else
        
        
        
        %=======================================
        %
        % LBL file: Create OBJECT TABLE section
        %
        %=======================================
        
        if strcmp(san_tabindex(i).data_type, 'downsample')   %%%%%%%% DOWNSAMPLED FILE %%%%%%%%%%%%%%%
            
            
            
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = sprintf('"%s %s SECONDS DOWNSAMPLED"', CALIB_LBL_struct.DESCRIPTION, lname(end-10:end-9));
            ocl = {};
            ocl{end+1} = struct('NAME', 'TIME_UTC',                          'UNIT', 'SECONDS',   'BYTES', 23, 'DATA_TYPE', 'TIME',                          'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl{end+1} = struct('NAME', 'OBT_TIME',                          'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',                    'DESCRIPTION', 'SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
            ocl{end+1} = struct('NAME', sprintf('P%i_CURRENT',        Pnum), 'UNIT', 'AMPERE',    'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'AVERAGED CURRENT');
            ocl{end+1} = struct('NAME', sprintf('P%i_CURRENT_STDDEV', Pnum), 'UNIT', 'AMPERE',    'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'CURRENT STANDARD DEVIATION');
            ocl{end+1} = struct('NAME', sprintf('P%i_VOLT',           Pnum), 'UNIT', 'VOLT',      'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'AVERAGED MEASURED VOLTAGE');
            ocl{end+1} = struct('NAME', sprintf('P%i_VOLT_STDDEV',    Pnum), 'UNIT', 'VOLT',      'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'VOLTAGE STANDARD DEVIATION');
            ocl{end+1} = struct('NAME', 'QUALITY',                           'UNIT', NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_INTEGER',                    'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
            LBL_data.OBJTABLE.OBJCOL_list = ocl;
            clear ocl
            
            
            
        elseif strcmp(san_tabindex(i).data_type, 'spectra')   %%%%%%%%%%%%%%%% SPECTRA FILE %%%%%%%%%%
            
            
            
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = sprintf('%s PSD SPECTRA OF HIGH FREQUENCY MEASUREMENT', mode);
            %---------------------------------------------
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_UTC', 'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_UTC',  'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'SPECTRA STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_OBT', 'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_OBT',  'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
            ocl1{end+1} = struct('NAME', 'QUALITY',                'UNIT', NO_ODL_UNIT, 'BYTES', 3,  'DATA_TYPE', 'ASCII_INTEGER', 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
            %---------------------------------------------
            ocl2 = {};
            if strcmp(mode(1), 'I')
                
                if Pnum == 3
                    ocl2{end+1} = struct('NAME', 'P1_P2_CURRENT_MEAN',              'UNIT', 'AMPERE', 'DESCRIPTION', 'MEASURED CURRENT DIFFERENCE MEAN');
                    ocl2{end+1} = struct('NAME', 'P1_VOLTAGE_MEAN',                 'UNIT', 'VOLT',   'DESCRIPTION',     'BIAS VOLTAGE');
                    ocl2{end+1} = struct('NAME', 'P2_VOLTAGE_MEAN',                 'UNIT', 'VOLT',   'DESCRIPTION',     'BIAS VOLTAGE');
                else
                    ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', Pnum), 'UNIT', 'AMPERE', 'DESCRIPTION', 'MEASURED CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('P%i_VOLTAGE_MEAN', Pnum), 'UNIT', 'VOLT',   'DESCRIPTION',     'BIAS VOLTAGE');
                end
                PSD_DESCRIPTION = 'PSD CURRENT SPECTRUM';
                PSD_UNIT = 'NANOAMPERE^2/Hz';
                
            elseif strcmp(mode(1),'V')
                
                if Pnum == 3
                    ocl2{end+1} = struct('NAME', 'P1_CURRENT_MEAN',              'UNIT', 'AMPERE',    'DESCRIPTION',     'BIAS CURRENT');
                    ocl2{end+1} = struct('NAME', 'P2_CURRENT_MEAN',              'UNIT', 'AMPERE',    'DESCRIPTION',     'BIAS CURRENT');
                    ocl2{end+1} = struct('NAME', 'P1_P2_VOLTAGE_MEAN',           'UNIT', 'VOLT',      'DESCRIPTION', 'MEASURED VOLTAGE DIFFERENCE MEAN');
                else
                    ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', Pnum), 'UNIT', 'AMPERE',    'DESCRIPTION', '    BIAS CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('P%i_VOLTAGE_MEAN', Pnum), 'UNIT', 'VOLT',      'DESCRIPTION', 'MEASURED VOLTAGE MEAN');
                end
                PSD_DESCRIPTION = 'PSD VOLTAGE SPECTRUM';
                PSD_UNIT        = 'VOLT^2/Hz';
                
            else
                error('Error, bad mode identifier in an_tabindex{%i,2} = san_tabindex(%i).filename = "%s".', i, i, san_tabindex(i).filename);
            end
            N_spectrum_cols = san_tabindex(i).N_TAB_columns - (length(ocl1) + length(ocl2));
            ocl2{end+1} = struct('NAME', sprintf('PSD_%s', mode), 'ITEMS', N_spectrum_cols, ...
                'UNIT', PSD_UNIT, 'DESCRIPTION', PSD_DESCRIPTION);



            for i_oc = 1:length(ocl2)
                if isfield(ocl2{i_oc}, 'ITEMS')
                    ocl2{i_oc}.ITEM_BYTES = 14;
                else
                    ocl2{i_oc}.BYTES = 14;
                end
                ocl2{i_oc}.DATA_TYPE = 'ASCII_REAL';
                ocl2{i_oc}.FORMAT    = 'E14.7';
            end
            
            LBL_data.OBJTABLE.OBJCOL_list = [ocl1, ocl2];
            clear ocl1 ocl2
            
        elseif  strcmp(san_tabindex(i).data_type, 'frequency')    %%%%%%%%%%%% FREQUENCY FILE %%%%%%%%%
            
            
            
            psdname = strrep(san_tabindex(i).filename, 'FRQ', 'PSD');
            
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = 'FREQUENCY LIST OF PSD SPECTRA FILE';
            ocl = {};
            ocl{end+1} = struct('NAME', 'FREQUENCY_LIST', 'ITEMS', san_tabindex(i).N_TAB_columns, 'UNIT', 'Hz', 'ITEM_BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', ...
                'FORMAT', 'E14.7', 'DESCRIPTION', sprintf('FREQUENCY LIST OF PSD SPECTRA FILE %s', psdname));
            LBL_data.OBJTABLE.OBJCOL_list = ocl;
            clear   ocl pdsname
            
            
            
        elseif  strcmp(san_tabindex(i).data_type, 'sweep')    %%%%%%%%%%%% SWEEP ANALYSIS FILE %%%%%%%%%
            
            
            
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = sprintf('MODEL FITTED ANALYSIS OF %s SWEEP FILE', stabindex(san_tabindex(i).i_tabindex).filename);
            
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'START_TIME(UTC)', 'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Start time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'STOP_TIME(UTC)',  'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION',  'Stop time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'START_TIME_OBT',  'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Start time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_OBT',   'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION',  'Stop time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl1{end+1} = struct('NAME', 'Qualityfactor',   'UNIT', NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Quality factor from 0-100.');   % TODO: Correct?
            ocl1{end+1} = struct('NAME', 'SAA',             'UNIT', 'degrees',   'BYTES',  7, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Solar aspect angle in spacecraft XZ plane, measured from Z+ axis.');
            ocl1{end+1} = struct('NAME', 'Illumination',    'UNIT', NO_ODL_UNIT, 'BYTES',  4, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl1{end+1} = struct('NAME', 'direction',       'UNIT', NO_ODL_UNIT, 'BYTES',  1, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            % ----- (NOTE: Switching from ocl1 to ocl2.) -----
            ocl2 = {};
            ocl2{end+1} = struct('NAME', 'old.Vsi',                'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old.Vx',                 'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential + Te from electron current fit. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vsg',                    'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'sigma_Vsg',              'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'old.Tph',                'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron temperature. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old.Iph0',               'UNIT', 'A',         'DESCRIPTION', 'Photosaturation current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vb_lastnegcurrent',      'UNIT', 'V',         'DESCRIPTION', 'bias potential below zero current.');
            ocl2{end+1} = struct('NAME', 'Vb_firstposcurrent',     'UNIT', 'V',         'DESCRIPTION', 'bias potential above zero current.');
            ocl2{end+1} = struct('NAME', 'Vbinfl',                 'UNIT', 'V',         'DESCRIPTION', 'Bias potential of inflection point in current.');
            ocl2{end+1} = struct('NAME', 'dIinfl',                 'UNIT', 'A/V',       'DESCRIPTION', 'Derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'd2Iinfl',                'UNIT', 'A/V^2',     'DESCRIPTION', 'Second derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'Iph0',                   'UNIT', 'A',         'DESCRIPTION', 'Photosaturation current.');
            ocl2{end+1} = struct('NAME', 'Tph',                    'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron temperature.');
            ocl2{end+1} = struct('NAME', 'Vsi',                    'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current.');
            ocl2{end+1} = struct('NAME',       'Vph_knee',         'UNIT', 'V',         'DESCRIPTION',                               'Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');
            ocl2{end+1} = struct('NAME', 'sigma_Vph_knee',         'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'Te_linear',        'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'ne_linear',        'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_ne_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'ion_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential');
            ocl2{end+1} = struct('NAME',       'ion_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_slope',          'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_slope',          'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_intersect',      'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_intersect',      'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'ion_Vb_intersect', 'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_Vb_intersect', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'e_Vb_intersect',   'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_Vb_intersect',   'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable).');
            ocl2{end+1} = struct('NAME', 'nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable).');
            ocl2{end+1} = struct('NAME',       'phc_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'phc_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'ne_5eV',                 'UNIT', 'cm^-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming electron temperature Te = 5 eV.');
            ocl2{end+1} = struct('NAME', 'ni_v_dep',               'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity.');
            ocl2{end+1} = struct('NAME', 'ni_v_indep',             'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate.');
            ocl2{end+1} = struct('NAME', 'v_ion',                  'UNIT', 'm/s',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate.');
            ocl2{end+1} = struct('NAME',       'Te_exp',           'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ne_exp',           'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');  % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'sigma_ne_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron density derived from fit of exponential part of the thermal electron current.');  % New from commit 3dce0a0, 2014-12-16 or earlier.
            
            ocl2{end+1} = struct('NAME', 'Rsquared_linear',            'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'Rsquared_exp',               'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
            ocl2{end+1} = struct('NAME',       'Vbar',              'UNIT', ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');  % New from commit, aa33268 2015-03-26 or earlier.
            ocl2{end+1} = struct('NAME', 'sigma_Vbar',              'UNIT', ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');  % New from commit, aa33268 2015-03-26 or earlier.
            
            ocl2{end+1} = struct('NAME', 'ASM_Iph0',                   'UNIT', 'A',         'DESCRIPTION', 'Assumed photosaturation current used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'ASM_Tph',                    'UNIT', 'eV',        'DESCRIPTION', 'Assumed photoelectron temperature used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Vsi',                    'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_Te_linear',        'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'asm_ne_linear',        'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'sigma_asm_ne_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'asm_ion_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_slope',          'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_slope',          'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_intersect',      'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_intersect',      'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_Vb_intersect', 'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_intersect', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_Vb_intersect',   'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_intersect',   'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_phc_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_phc_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ne_5eV',                 'UNIT', 'cm^-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming Te= 5eV. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_dep',               'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_indep',             'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_v_ion',                  'UNIT', 'm/s',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_Te_exp',           'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ne_exp',           'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');    % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron density derived from fit of exponential part of the thermal electron current.');    % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
            ocl2{end+1} = struct('NAME', 'ASM_m_ion',      'BYTES', 3, 'UNIT', 'amu',               'DESCRIPTION', 'Assumed ion mass for all ions.');     % New from commit a56c578, 2015-01-22 or earlier.
            ocl2{end+1} = struct('NAME', 'ASM_Z_ion',      'BYTES', 2, 'UNIT', 'Elementary charge', 'DESCRIPTION', 'Assumed ion charge for all ions.');   % New from commit a56c578, 2015-01-22 or earlier.
            ocl2{end+1} = struct('NAME', 'ASM_v_ion',                  'UNIT', 'm/s',               'DESCRIPTION', 'Assumed ion ram speed in used in *_v_dep variables.');   % New from commit a56c578, 2015-01-22 or earlier. Earlier name: ASM_m_vram, ASM_vram_ion.
            ocl2{end+1} = struct('NAME',     'Vsc_ni_ne',              'UNIT', 'V',                 'DESCRIPTION', 'Spacecraft potential needed to produce identical ion (ni_v_indep) and electron (ne_linear) densities.');   % New from commit a56c578, 2015-01-22 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Vsc_ni_ne',              'UNIT', 'V',                 'DESCRIPTION', 'Spacecraft potential needed to produce identical ion (asm_ni_v_indep) and electron (asm_ne_linear) densities. Fixed photoelectron current assumption.');   % New from commit a56c578, 2015-01-22 or earlier.
            
            ocl2{end+1} = struct('NAME', 'Vsc_aion',                  'UNIT', 'V',      'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'ni_aion',                   'UNIT', 'cm^-3',  'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'v_aion',                    'UNIT', 'm/s',    'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Vsc_aion',              'UNIT', 'V',      'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_ni_aion',               'UNIT', 'cm^-3',  'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_v_aion',                'UNIT', 'm/s',    'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            %---------------------------------------------------------------------------------------------------
            
            ocl2{end+1} = struct('NAME',           'Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',     'sigma_Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',           'ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',     'sigma_ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',       'asm_Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',       'asm_ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            
            for i_oc = 1:length(ocl2)
                if ~isfield(ocl2{i_oc}, 'BYTES')
                    ocl2{i_oc}.BYTES = 14;
                end
                ocl2{i_oc}.DATA_TYPE = 'ASCII_REAL';
            end
            LBL_data.OBJTABLE.OBJCOL_list = [ocl1, ocl2];
            clear   ocl1 ocl2
            
            TAB_LBL_inconsistency_policy = AxS_TAB_LBL_inconsistency_policy;   % NOTE: Different policy for A?S.LBL files.
            
            
            
        elseif  strcmp(san_tabindex(i).data_type,'best_estimates')    %%%%%%%%%%%% BEST ESTIMATES FILE %%%%%%%%%%%%
            
            
            
            LBL_data.OBJTABLE = [];
            LBL_data.OBJTABLE.DESCRIPTION = sprintf('BEST ESTIMATES OF PHYSICAL VALUES FROM MODEL FITTED ANALYSIS.');   % Bad description? To specific?
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME', 'QUALITY',            'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
            ocl{end+1} = struct('NAME', 'npl',                'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'CM**-3',    'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of plasma number density.');
            ocl{end+1} = struct('NAME', 'Te',                 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'eV',        'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of electron temperature.');
            ocl{end+1} = struct('NAME', 'Vsc',                'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'V',         'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of spacecraft potential.');
            ocl{end+1} = struct('NAME', 'Probe_number',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  1, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Probe number. 1 or 2.');
            ocl{end+1} = struct('NAME', 'Direction',          'DATA_TYPE', 'ASCII_REAL', 'BYTES',  1, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            ocl{end+1} = struct('NAME', 'Illumination',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  4, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl{end+1} = struct('NAME', 'Sweep_group_number', 'DATA_TYPE', 'ASCII_REAL', 'BYTES',  5, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', ...
                ['Number signifying which group of sweeps the data comes from. ', ...
                'Groups of sweeps are formed for the purpose of deriving/selecting values to be used in best estimates. ', ...
                'All sweeps with the same group number are almost simultaneous. For every type of best estimate, at most one is chosen from each group.' ...
                ]);  % NOTE: Causes trouble by making such a long line in LBL file?!!
            LBL_data.OBJTABLE.OBJCOL_list = ocl;
            clear   ocl



        else

            error('Error, bad identifier in an_tabindex{%i,7} = san_tabindex(%i).data_type = "%s"',i, i, san_tabindex(i).data_type);

        end



        createLBL.create_OBJTABLE_LBL_file(san_tabindex(i).path, LBL_data, TAB_LBL_inconsistency_policy);
        clear   LBL_data   TAB_LBL_inconsistency_policy
        
        
        
    catch err
        createLBL.exception_message(err, generate_file_fail_policy)
        fprintf(1,'lapdog: Skipping LBL file (an_tabindex) - Continuing\n');
    end    % try-catch
    
    
    
end   % for



%=================================================
%
% Create LBL files for files in der_struct (A1P).
%
%=================================================


try
    kvl_LBL_all
    index
    NO_ODL_UNIT
    MISSING_CONSTANT
    DELETE_HEADER_KEY_LIST
    general_TAB_LBL_inconsistency_policy
    
    global der_struct    % Global variable with info on A1P files.
    if ~isempty(der_struct)
        createLBL.write_A1P(kvl_LBL_all, index, der_struct, NO_ODL_UNIT, MISSING_CONSTANT, DELETE_HEADER_KEY_LIST, general_TAB_LBL_inconsistency_policy);
    end
catch err
    fprintf(1,'\nlapdog:createLBL.write_A1P error message: %s\n',err.message);    
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i,\n', err.stack(i).name, err.stack(i).line);
        end
    end
end


cspice_unload(kernel_file);
warning(previous_warnings_settings)
fprintf(1, '%s: %.0f s (elapsed wall time)\n', mfilename, etime(clock, t_start));
