%===============================================================================================
%
% Script, not intended to be made nice (probably). / fulkod
%
% Code for generating geometry files (TAB+LBL) based on Elias' informal geometry files.
% Takes a selection of Elias geometry files and generates LBL/TAB file pairs in subdirectories
% /<YEAR>/<MONTH>/<DATE>/ relative to a specified directory, eg. inside a data set.
%
% NOTE: Uses a somewhat temporary "user interface" based on editing hardcoded variables in a function.
%
% NOTE: This code is not (currently) intended to be run with the rest of lapdog but may use general
% utility functions, in particular for generating LBL files.
% 
% NOTE: This generates geometry files for processing levels (EDITED, CALIB, DERIV), not just DERIV.
%
% NOTE: Does not update any INDEX.TAB/LBL files.
%
% Created by: Erik  P G Johansson, 2015-08-xx
%===============================================================================================
function geometry_from_EliasGeometryFiles()
    %===============================================================================================
    % NOTE: Can not just copy Elias' geometry files to the datasets.
    % Must (1) remove first line, (2) add CR, (3) make every line have the same length.
    %
    % QUESTION: How obtain values for common keywords: DATASET_ID, DATASET_NAME, PRODUCER_FULL_NAME, PRODUCER_*?
    %    PROPOSAL: Some could be hardcoded in a file common to lapdog+geometry. All values common for all mission phases, and
    %    predictable from precessing level.
    %    shortphase, datasetid, datasetname, targetfullname, targettype, missionphase
    %===============================================================================================
    
    [kernel_file, source_dir, dest_date_root_path, dataset_info] = CONTROL_PARAMETERS();
    convert_EGfiles_dir(kernel_file, source_dir, dataset_info)
    
    
    %=======================================================================
    % Function which defines all parameters that are to be set by the user.
    %=======================================================================
    function [kernel_file, source_dir, dest_date_root_path, dataset_info] = CONTROL_PARAMETERS()
        %kernel_file = '/home/erjo/work_files/Lapdog_GIT/metakernel_rosetta.txt';
        %source_dir = '/home/erjo/work_files/ROSETTA/temp_geometry';
        %dest_date_root_path = '/home/erjo/temp';
        kernel_file = '/home/erjo/lapdog_squid_copy/metakernel_rosetta.txt';
        source_dir = '/home/erjo/temp_Elias_geometry_ESC1';
        %dest_date_root_path = '/homelocal/erjo/rosetta_data_sets/delivery/RO-C-RPCLAP-2-ESC1-EDITED-V1.0/DATA/EDITED';
        dest_date_root_path = '/homelocal/erjo/rosetta_data_sets/delivery/RO-C-RPCLAP-3-ESC1-CALIB-V1.0/DATA/CALIBRATED';
        
        di = [];      % di = dataset info
        di.PROCESSING_LEVEL_ID = '3';   % NOTE: String, not number. 2=EDITED, 3=CALIB, 5=DERIV
        di.short_mp = 'ESC1';
        di.MISSION_PHASE_NAME = 'COMET ESCORT 1';   % Long name, e.g. PRELANDING.
        di.data_set_version = '1.0';        % Do not include "V".
        di.target_ID = 'C';                % E.g. "C".
        di.TARGET_TYPE = 'COMET';          % E.g. "COMET".
        di.target_name_short = '67P';      % E.g. "67P":
        di.TARGET_NAME = '67P/CHURYUMOV-GERASIMENKO 1 (1969 R1)';

        switch di.PROCESSING_LEVEL_ID
            case '2'
                di.PRODUCT_TYPE = 'EDR';
                di.processing_level_name = 'EDITED';
            case '3'
                di.PRODUCT_TYPE = 'RDR';
                di.processing_level_name = 'CALIB';
            case '5'
                di.PRODUCT_TYPE = 'DDR';
                di.processing_level_name = 'DERIV';
            otherwise
                error('Can not interpret PROCESSING_LEVEL_ID.')
        end
        di.DATA_SET_ID =   ['RO-',              di.target_ID,         '-RPCLAP-', di.PROCESSING_LEVEL_ID, '-', di.short_mp, '-', di.processing_level_name, '-V', di.data_set_version];
        di.DATA_SET_NAME = ['ROSETTA-ORBITER ', di.target_name_short, ' RPCLAP ', di.PROCESSING_LEVEL_ID, ' ', di.short_mp, ' ', di.processing_level_name, ' V', di.data_set_version];
        dataset_info = di;
        
    end
    
    
    % ASSUME: All files in source_dir are Elias geometry files.
    % Try to derive LBL/TAB files for all of them.
    function convert_EGfiles_dir(kernel_file, source_dir, dataset_info)
        files = dir(source_dir);
    
        cspice_furnsh(kernel_file);        
        for i = 1:length(files)
            if ~files(i).isdir            
                convert_EGfile([source_dir, '/', files(i).name], dest_date_root_path, dataset_info)
            end
        end
    
        % "CSPICE_KCLEAR clears the KEEPER system: unload all kernels, clears
        % the kernel pool, and re-initialize the system."
        cspice_kclear
    end
    
    
    % Derive TAB/LBL files for one Elias geometry file.
    % EG = Elias geometry
    % NOTE: Derives the date from the contents of the source file, not the
    % filename. File name is therefore not important.
    function convert_EGfile(EGfile_path, dest_date_root_path, dataset_info)
        
        fc = importdata(EGfile_path);        
        if (size(fc.textdata, 2) ~= 9) | (size(fc.data, 2) ~= 8) | (size(fc.data, 1)+1 ~= size(fc.textdata, 1))
            error('Unexpected data in Elias geometry file.')
        end
        UTCstr_list = fc.textdata(2:end, 1);
        num_table = fc.data;
                     
        TAB_info.UTCstr_first = UTCstr_list{1,1};
        TAB_info.UTCstr_last = UTCstr_list{end,1};
        TAB_info.N_rows = size(num_table, 1);
        
        TAB_info.SCS_first = convert_Rosetta_UTC_string_to_SCS(TAB_info.UTCstr_first);
        TAB_info.SCS_last = convert_Rosetta_UTC_string_to_SCS(TAB_info.UTCstr_last);
        
        % Derive TAB file path and filename.
        month_dir_names = {'JAN', 'FEB','MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'};
        yearXXXX_str = TAB_info.UTCstr_first(1:4);
        yearXX_str = TAB_info.UTCstr_first(3:4);
        month_dir_str = month_dir_names{str2double(TAB_info.UTCstr_first(6:7))};
        month_nbr_str = TAB_info.UTCstr_first(6:7);
        dom_str = TAB_info.UTCstr_first(9:10);
        
        TAB_filename = ['RPCLAP', yearXX_str, month_nbr_str, dom_str, '_', dataset_info.PROCESSING_LEVEL_ID, '_GEOM.TAB'];
        TAB_file_dir = [dest_date_root_path, '/', yearXXXX_str, '/', month_dir_str, '/D', dom_str];
        if exist(TAB_file_dir) ~= 7
            fprintf(1, 'Parent directory does not exist. Skipping %s.\n', TAB_file_dir)
            return
        end
        TAB_file_path = [TAB_file_dir, '/', TAB_filename];
            
        %================
        % WRITE TAB FILE
        %================
        fprintf(1, 'Creating TAB file: "%s"\n', TAB_file_path)
        fid = fopen(TAB_file_path, 'w');
        if (fid == -1)
            error('Can not open file to write to. TAB_file_path = "%s".', TAB_file_path)
        end
        TAB_info.N_TAB_bytes_per_row = 23 + 8*(2+14) + 2;  % Including CR+LF.
        for i = 1:TAB_info.N_rows
            line_length = fprintf(fid, '%23s, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e\r\n', UTCstr_list{i, 1}, num_table(i, :));
            if (line_length ~= TAB_info.N_TAB_bytes_per_row)
                error('Wrote TAB file with varying line lengths.');
            end
        end
        fclose(fid);
        
        create_LBL_file(TAB_file_path, dataset_info, TAB_info)
    end


    % NOTE: Should accept the _TAB_ file path, NOT the LBL file path beacuse of the function that writes the LBL file.
    function create_LBL_file(TAB_file_path, dataset_info, TAB_info)
        
        %================
        % WRITE LBL FILE
        %================
        ocl = [];
        ocl{end+1} = struct('NAME', 'TIME_UTC',  'DATA_TYPE', 'TIME',       'BYTES', 23,               'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
        ocl{end+1} = struct('NAME', 'X_TSO',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'KM', 'DESCRIPTION',
            'The spacecraft X coordinate in the target-centric solar orbital coordinate system.');
        ocl{end+1} = struct('NAME', 'Y_TSO',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'KM', 'DESCRIPTION',
            'The spacecraft Y coordinate in the target-centric solar orbital coordinate system.');
        ocl{end+1} = struct('NAME', 'Z_TSO',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'KM', 'DESCRIPTION',
            'The spacecraft Z coordinate in the target-centric solar orbital coordinate system.');
        ocl{end+1} = struct('NAME', 'LATITUDE',  'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', 'The spacecraft latitude on the target.');
        ocl{end+1} = struct('NAME', 'LONGITUDE', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', 'The spacecraft longitude on the target.');
        ocl{end+1} = struct('NAME', 'SZA',       'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', ...
            'Solar zenith angle, the angle between the spacecraft and the Sun as seen from the target.');
        ocl{end+1} = struct('NAME', 'SAA',       'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', ...
            'Solar aspect angle, the angle between the spacecraft Z+ axis and the spacecraft-Sun direction projected on the spacecraft XZ plane. Angle increases toward X+.');
        ocl{end+1} = struct('NAME', 'TAA',       'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', ...
            'Target aspect angle, the angle between the spacecraft Z+ axis and the spacecraft-target direction projected on the spacecraft XZ plane. Angle increases toward X+.');
        

        
        kvl_header = [];
        kvl_header.keys = {};
        kvl_header.values = {};
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PDS_VERSION_ID',               'PDS3');
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'DATA_SET_ID',                  ['"', dataset_info.DATA_SET_ID, '"']);
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'DATA_SET_NAME',                ['"', dataset_info.DATA_SET_NAME, '"']);
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'INSTRUMENT_NAME',              '"ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"');
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'INSTRUMENT_ID',                'RPCLAP');
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'INSTRUMENT_HOST_NAME',         '"ROSETTA-ORBITER"');
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'MISSION_PHASE_NAME',           ['"', dataset_info.MISSION_PHASE_NAME, '"']);
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PROCESSING_LEVEL_ID',          ['"', dataset_info.PROCESSING_LEVEL_ID, '"']);
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PRODUCT_CREATION_TIME',        datestr(now, 'yyyy-mm-ddTHH:MM:SS.FFF'));
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PRODUCT_TYPE',                 ['"', dataset_info.PRODUCT_TYPE, '"']);
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PRODUCER_ID',                  'EJ');
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PRODUCER_FULL_NAME',           '"ERIK P G JOHANSSON"');
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'TARGET_NAME',                  ['"', dataset_info.TARGET_NAME, '"']);
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'TARGET_TYPE',                  ['"', dataset_info.TARGET_TYPE, '"']);
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'START_TIME',                   TAB_info.UTCstr_first);              % UTC start time
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'STOP_TIME',                    TAB_info.UTCstr_last);               % UTC stop time
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'SPACECRAFT_CLOCK_START_COUNT', ['"', TAB_info.SCS_first, '"']);
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'SPACECRAFT_CLOCK_STOP_COUNT',  ['"', TAB_info.SCS_last,  '"']);
        kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'LABEL_REVISION_NOTE',          '"2015-09-04, EJ: Updated descriptions."');
        % NOTE: createLBL_create_OBJTABLE_LBL_file add some fields on its own:
        %    RECORD_TYPE, RECORD_BYTES, FILE_RECORDS, FILE_NAME, ^TABLE, PRODUCT_ID
        
        LBL_data = [];
        LBL_data.N_TAB_file_rows = TAB_info.N_rows;
        LBL_data.consistency_check.N_TAB_columns = 9;
        LBL_data.consistency_check.N_TAB_bytes_per_row = TAB_info.N_TAB_bytes_per_row;
        LBL_data.kvl_header = kvl_header;
        LBL_data.OBJTABLE = [];
        LBL_data.OBJTABLE.DESCRIPTION = 'Geometry information for the spacecraft orientation relative to the target and the Sun, and spacecraft position relative to the target.';
        LBL_data.OBJTABLE.OBJCOL_list = ocl;
        
        %LBL_data.
        createLBL_create_OBJTABLE_LBL_file(TAB_file_path, LBL_data, 'error');
    end
    
    
    %###############################################################################################
    
    % Requires SPICE kernels to be loaded.
    % SCS = Spacecraft clock string. (SPICE uses that terminology.)
    %    Ex: "1/0397007763.15407"
    function scs = convert_Rosetta_UTC_string_to_SCS( UTCstring )

        Rosetta_NAIF_ID = -226;
        scs = cspice_sce2s(Rosetta_NAIF_ID, cspice_str2et(UTCstring));

    end
    
end

