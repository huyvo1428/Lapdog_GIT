%=========================================================================
% Derive ONE pair of TAB/LBL files from one Elias geometry file.
%
% dest_dir      : Path to where the TAB/LBL geometry files will be placed.
% PDS_data      : Struct with various PDS keyword values.
% t             : The date as a double returned by "datenum". Time of day should be irrelevant.
% EG_files_dir  : Directory where Elias' geometry files can be located.
%
% NOTE: The function is chosen such that it could be relatively easily be replaced by a function that
% produces a geometry file from scratch (from SPICE; without Elias' geometry files).
% NOTE: Requires SPICE kernels to be loaded.
% NOTE: Code contains the naming convention for Elias' geomtry files.
% EG = Elias geometry
%
% QUESTION: Should include (add) the NOTE keyword and a reference to the "Cheops Reference Frame"?
% PROPOSAL: Warning/error on overwriting existing file(s).
%
% Reused code created by: Erik P G Johansson, 2015-08-xx, IRF Uppsala, Sweden
% Major rewrite: Erik P G Johansson, 2015-12-15
%=========================================================================
function geometry_createFileFromEliasGeometryFile(dest_dir, PDS_data, t, EG_files_dir)
    %===============================================================================================
    % NOTE: Can not just copy Elias' geometry files to the datasets.
    % Must (1) remove first line, (2) add CR, (3) make every line have the same length.
    %
    % NOTE: Does not specify which columns separately to read from Elias' geometry files using the header.
    %    PROPOSAL: Implements this. Specifiy e.g. "UTC", "X_CSO", "Y_CSO", etc. explicitly and tie to the LBL file column descriptions.
    %===============================================================================================
    % PROPOSAL: Change year-month-day to one time number.
    
    % ASSERTION
    if ~exist(dest_dir, 'dir')      % "exist" returns 7 if argument is a directory.
        fprintf(1, 'Directory does not exist. Skipping %s.\n', dest_dir)
        %error('Destination directory "%s" does not exist.\n', dest_dir)
        return
    end
    
    EG_filename = [upper(datestr(t, 'yyyy-mmm-dd')), 'orb.txt'];
    EG_file_path = fullfile(EG_files_dir, EG_filename);
    
    TAB_file_info = create_TAB_file(dest_dir, PDS_data, EG_file_path, t);
    create_LBL_file(PDS_data, TAB_file_info);
end



function TAB_file_info = create_TAB_file(dest_dir, PDS_data, EG_file_path, t)
    fc = importdata(EG_file_path);         % fc = file contents.
    
    %=======================================================
    % ASSERTION - Basic check on Elias geometry file format
    %=======================================================
    if (size(fc.textdata, 2) ~= 11) | (size(fc.data, 2) ~= 10) | (size(fc.data, 1)+1 ~= size(fc.textdata, 1))
        error('Unexpected data in Elias geometry file. Different file format from what is expected.')
    end
    
    %===================================
    % Derive OBT values to use in file.
    %===================================
    UTCstr_list = fc.textdata(2:end, 1);
    OBT_list = zeros(length(UTCstr_list),1);
    for i = 1:length(UTCstr_list)
        OBT_list(i) = sct2obt(convert_Rosetta_UTC_string_to_SCS(UTCstr_list{i}));
    end
    num_table = fc.data;
    
    
    TAB_file_info = [];
    TAB_file_info.N_rows = size(num_table, 1);
    TAB_file_info.UTCstr_first = UTCstr_list{1};
    TAB_file_info.UTCstr_last  = UTCstr_list{end};
    TAB_file_info.SCS_first = convert_Rosetta_UTC_string_to_SCS(UTCstr_list{1});
    TAB_file_info.SCS_last  = convert_Rosetta_UTC_string_to_SCS(UTCstr_list{end});
    
    
    % ASSERTION - File contains the right time interval.
    t_date_str = datestr(t, 'yyyy-mm-dd');
    if ~strcmp(t_date_str, TAB_file_info.UTCstr_first(1:10)) || ~strcmp(t_date_str, TAB_file_info.UTCstr_last(1:10))
        error('File does not contain data for the expected time interval.')
    end
    
    TAB_filename = ['RPCLAP', datestr(t, 'yymmdd'), '_', PDS_data.PROCESSING_LEVEL_ID, '_GEOM.TAB'];
    TAB_file_info.path = fullfile(dest_dir, TAB_filename);
    


    %================
    % WRITE TAB FILE
    %================
    fprintf(1, 'Writing TAB file: "%s"\n', TAB_file_info.path)
    fid = fopen(TAB_file_info.path, 'w');
    if (fid == -1)
        error('Can not open file to write to. TAB_file_info.path = "%s".', TAB_file_info.path)
    end
    TAB_file_info.N_TAB_bytes_per_row = 23 + 1*(2+16) + 10*(2+14) + 2;    % +2 = Include CR+LF.
    for i = 1:TAB_file_info.N_rows
        line_length = fprintf(fid, ...
            '%23s, %16.6f, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e, %14.7e\r\n', ...
            UTCstr_list{i, 1}, OBT_list(i), num_table(i, 1:10));
        if (line_length ~= TAB_file_info.N_TAB_bytes_per_row)
            % Close the file properly to make sure that the file is actually
            % written to disk so that one can inspect the erroneous file contents.
            fclose(fid);
            
            fprintf('line_length                       = %e\n', line_length);
            fprintf('TAB_file_info.N_TAB_bytes_per_row = %e\n', TAB_file_info.N_TAB_bytes_per_row);
            
            error('Line just written to TAB file had an unexpected line length.');
        end
    end
    fclose(fid);
end



%===============================================================================================
% NOTE: Should accept the _TAB_ file path, NOT the LBL file path beacuse of the function that
% writes the LBL file.
%===============================================================================================
function create_LBL_file(PDS_data, TAB_file_info)
    
    %================
    % WRITE LBL FILE
    %================
    ocl = [];
    ocl{end+1} = struct('NAME', 'TIME_UTC',  'DATA_TYPE', 'TIME',       'BYTES', 23,               'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
    ocl{end+1} = struct('NAME', 'OBT_TIME',  'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16,               'DESCRIPTION', ...
        'SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
    
    ocl{end+1} = struct('NAME', 'X_TSO',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'KM', 'DESCRIPTION', ...
        'The spacecraft X coordinate in the target-centric solar orbital coordinate system.');
    ocl{end+1} = struct('NAME', 'Y_TSO',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'KM', 'DESCRIPTION', ...
        'The spacecraft Y coordinate in the target-centric solar orbital coordinate system.');
    ocl{end+1} = struct('NAME', 'Z_TSO',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'KM', 'DESCRIPTION', ...
        'The spacecraft Z coordinate in the target-centric solar orbital coordinate system.');
    
    ocl{end+1} = struct('NAME', 'LATITUDE',  'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', ...
        'The spacecraft latitude on the target.');
    ocl{end+1} = struct('NAME', 'LONGITUDE', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', ...
        'The spacecraft longitude on the target.');
    
    ocl{end+1} = struct('NAME', 'SZA',       'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', ...
        'Solar zenith angle, the angle between the spacecraft and the Sun as seen from the target.');
    
    ocl{end+1} = struct('NAME', 'SAA',       'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', ...
        'Solar aspect angle, longitude of the Sun in the spacecraft coordinate system, counted positive from +Z toward +X.');
    ocl{end+1} = struct('NAME', 'TAA',       'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', ...
        'Target aspect angle, longitude of the target in the spacecraft coordinate system, counted positive from +Z toward +X.');
    ocl{end+1} = struct('NAME', 'SEA',       'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', ...
        'Solar elevation angle, latitude of the Sun in the spacecraft coordinate system, counted positive above the XZ plane toward +Y.');
    ocl{end+1} = struct('NAME', 'TEA',       'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'DEGREES', 'DESCRIPTION', ...
        'Target elevation angle, latitude of the target in the spacecraft coordinate system, counted positive above the XZ plane toward +Y.');
    
    
    
    kvl_header = [];
    kvl_header.keys = {};
    kvl_header.values = {};
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PDS_VERSION_ID',               'PDS3');
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'DATA_SET_ID',                  ['"', PDS_data.DATA_SET_ID, '"']);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'DATA_SET_NAME',                ['"', PDS_data.DATA_SET_NAME, '"']);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'INSTRUMENT_NAME',              '"ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"');
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'INSTRUMENT_ID',                'RPCLAP');
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'INSTRUMENT_HOST_NAME',         '"ROSETTA-ORBITER"');
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'MISSION_PHASE_NAME',           ['"', PDS_data.MISSION_PHASE_NAME, '"']);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PROCESSING_LEVEL_ID',          ['"', PDS_data.PROCESSING_LEVEL_ID, '"']);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PRODUCT_CREATION_TIME',        datestr(now, 'yyyy-mm-ddTHH:MM:SS.FFF'));
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PRODUCT_TYPE',                 ['"', PDS_data.PRODUCT_TYPE, '"']);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PRODUCER_ID',                  'EJ');
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'PRODUCER_FULL_NAME',           '"ERIK P G JOHANSSON"');
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'TARGET_NAME',                  ['"', PDS_data.TARGET_NAME, '"']);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'TARGET_TYPE',                  ['"', PDS_data.TARGET_TYPE, '"']);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'START_TIME',                   TAB_file_info.UTCstr_first);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'STOP_TIME',                    TAB_file_info.UTCstr_last);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'SPACECRAFT_CLOCK_START_COUNT', ['"', TAB_file_info.SCS_first, '"']);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'SPACECRAFT_CLOCK_STOP_COUNT',  ['"', TAB_file_info.SCS_last,  '"']);
    kvl_header = createLBL_KVPL_add_kv_pair(kvl_header, 'LABEL_REVISION_NOTE',          '"2015-12-15, EJ: Updated descriptions, added OBT_TIME, SEA, TEA."');
    % NOTE: createLBL_create_OBJTABLE_LBL_file adds some fields on its own:
    %    RECORD_TYPE, RECORD_BYTES, FILE_RECORDS, FILE_NAME, ^TABLE, PRODUCT_ID
    
    LBL_data = [];
    LBL_data.N_TAB_file_rows = TAB_file_info.N_rows;
    LBL_data.consistency_check.N_TAB_columns = length(ocl);
    LBL_data.consistency_check.N_TAB_bytes_per_row = TAB_file_info.N_TAB_bytes_per_row;
    LBL_data.kvl_header = kvl_header;
    LBL_data.OBJTABLE = [];
    LBL_data.OBJTABLE.DESCRIPTION = 'Geometry information for some of the relative positions and orientations of the spacecraft, target, and Sun.';
    LBL_data.OBJTABLE.OBJCOL_list = ocl;
    
    %LBL_data.
    createLBL_create_OBJTABLE_LBL_file(TAB_file_info.path, LBL_data, 'error');
end



%===============================================================================================
% Requires SPICE kernels to be loaded.
% SCS = "Spacecraft clock string" (SPICE uses that terminology.)
%    Ex: "1/0397007763.15407"
%===============================================================================================
function scs = convert_Rosetta_UTC_string_to_SCS( UTCstring )
    % PROPOSAL: Separate function.
    % PROPOSAL: Abolish?
    ROSETTA_NAIF_ID = -226;
    scs = cspice_sce2s(ROSETTA_NAIF_ID, cspice_str2et(UTCstring));
end
