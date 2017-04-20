% Initially created by Erik P G Johansson, IRF Uppsala, 2016-08-01.
%
% Obtain various PDS keyword (and keyword-like) values given PDS keyword(-like) values on a specific data set.
% This code is supposed to centralize that type of functionality.
%
%
% ARGUMENTS
% =========
% base_data : Same struct as returned by get_PDS_base_data.
%
%
% RETURN VALUES
% =============
% all_data  : Struct with (1) the fields of "base_data", plus (2) all other derived fields.
%
%
% Variable (field) naming convention
% ==================================
% - Field names which are capitalized refer to PDS keywords.
% - Field names which first part is capitalized and its second part lower case refer to a subset of ONE specific PDS keyword value.
%   NOTE: There are variables which refer to a subset of SEVERAL PDS keyword value. Ex: version_str.
% - Field names which begin with "VOLDESC___" refer to the file VOLDESC.CAT. (VOLDESC___DESCRIPTION would otherwise be ambiguous.)
%
%
% NOTE: All field values are strings.
% NOTE: None of the values supplied and returned should be quoted. (createLBL_create_OBJTABLE_LBL_file,
% update_DATASET_VOLDESC add quotes.)
% NOTE: Does not set DATASET.CAT:START_TIME, STOP_TIME.
% NOTE: ".version_str" refers to the version number (string) in e.g. DATA_SET_ID, DATA_SET_NAME and possibly VOLDESC.CAT:VOLUME_VERSION_ID.
%       ".version_str" should contain no "V".
%
function all_data = get_PDS_data(base_data, pds_mission_calendar_path)
    %
    % PROPOSAL: Include information on whether to quote or not?!
    %    PROPOSAL: Includes list of fields (field names) which should be quoted.
    %
    % PROPOSAL: Add year in data.VOLDESC___DESCRIPTION using mission phase beginning.
    %   CON: Does not work for mission phases spanning over new year.
    %   CON: Does not work for MTP-split mission phases.
    %
    % PROPOSAL: Call from createLBL?
    %   CON: Does not want to involve reading from tables.
    %       CON: Then the function should not read from tables.
    %   CON: Does not want to involve data required to derive unnecessary values.
    %       CON: Example? MISSION_PHASE, TARGET_NAME are available.
    %       CON: Can set to nonsense values.
    %
    % PROPOSAL: Prevent from submitting any other fields?
    %    CON: Makes it more difficult to modify fields (data set) and "rerun" to create values for a new data set.
    %
    % PROPOSAL: Separate "input" fields from derived fields into two different structs.
    %
    % PROPOSAL: Check that manually hard-coded strings here do not lead to DATASET.CAT & VOLDESC.CAT files with line
    % widths greater than 70 characters (excl. CR+LF).
    %
    % PROPOSAL: Use datasets_data.DAT, or mission_phases_data.DAT instead of pds mission calendar.
    %   CON: Requires EJ_generic.read_delimiter_headers_table_file.m
    
    BASE_DATA_FIELDS = {...
        'VOLUME_ID_nbr_str', 'DATA_SET_ID', 'DATA_SET_ID_target_ID', 'PROCESSING_LEVEL_ID', ...
        'mission_phase_abbrev', 'DATA_SET_ID_descr', 'version_str'};
    
    % ASSERTION: Assume that argument "base_data" has exactly the right set of fields. Not fwere, not more.
    if ~isempty(setxor(BASE_DATA_FIELDS, fieldnames(base_data)))        
        error('Argument base_data does not have the correct list of field names.')
    end
    
    
    
    all_data = [];
    
    for fn = fieldnames(base_data)'
        all_data.(fn{1}) = base_data.(fn{1});
    end

    all_data = read_mission_calendar(all_data, pds_mission_calendar_path, 'mission_phase_abbrev', all_data.mission_phase_abbrev);

    % PRODUCT_TYPE based on "ROSETTA Archive Conventions", RO-EST-TN-3372, iss9rev0, Table 3.
    switch(base_data.PROCESSING_LEVEL_ID)
        case '2'
            all_data.DATA_subdir = 'EDITED';
            all_data.PRODUCT_TYPE = 'EDR';
        case '3'
            all_data.DATA_subdir = 'CALIBRATED';
            all_data.PRODUCT_TYPE = 'RDR';
        case '5'
            all_data.DATA_subdir = 'DERIVED';
            all_data.PRODUCT_TYPE = 'DDR';
        otherwise
            error('Can not interpret recognize base_data.PROCESSING_LEVEL_ID.')
    end
    
    % Based on "ROSETTA Archive Conventions", RO-EST-TN-3372, iss9rev0, Table 9.
    % NOTE: DATA_SET_ID_target_ID, TARGET_TYPE do not have unique values for unique targets.
    switch(all_data.DATA_SET_NAME_target)
        case '67P'
            all_data.TARGET_NAME           = '67P/CHURYUMOV-GERASIMENKO 1 (1969 R1)';
            all_data.TARGET_TYPE           = 'COMET';
            all_data.DATA_SET_ID_target_ID = 'C';
        case 'STEINS'
            all_data.TARGET_NAME           = '2867 STEINS';
            all_data.TARGET_TYPE           = 'ASTEROID';
            all_data.DATA_SET_ID_target_ID = 'A';
        case 'LUTETIA'
            all_data.TARGET_NAME           = '21 LUTETIA';
            all_data.TARGET_TYPE           = 'ASTEROID';
            all_data.DATA_SET_ID_target_ID = 'A';
        case 'EARTH'
            all_data.TARGET_NAME           = 'EARTH';
            all_data.TARGET_TYPE           = 'PLANET';
            all_data.DATA_SET_ID_target_ID = 'E';
        case 'MARS'
            all_data.TARGET_NAME           = 'MARS';
            all_data.TARGET_TYPE           = 'PLANET';
            all_data.DATA_SET_ID_target_ID = 'M';
        otherwise
            error('Can not identify base_data.DATA_SET_NAME_target.')
    end

    
    
    all_data.DATA_SET_NAME = sprintf('ROSETTA-ORBITER %s RPCLAP %s %s %s V%s', ...
        all_data.DATA_SET_NAME_target, ...
        all_data.PROCESSING_LEVEL_ID, ...
        all_data.mission_phase_abbrev, ...
        all_data.DATA_SET_ID_descr, ...
        all_data.version_str);
    


    %=====================================
    % Set values only used in VOLDESC.CAT
    %=====================================
    
    % Ex: VOLUME_NAME = "RPCLAP CALIBRATED DATA FOR EARTH SWING-BY 1"
    all_data.VOLUME_NAME = sprintf('RPCLAP %s DATA FOR %s', all_data.DATA_subdir, all_data.MISSION_PHASE_NAME);
    
    % Ex: VOLUME_ID = ROLAP_1099
    if ~ischar(all_data.VOLUME_ID_nbr_str) || length(all_data.VOLUME_ID_nbr_str) ~= 4
        error('all_data.VOLUME_ID_nbr_str is not a string, exactly four characters long.')
    end
    all_data.VOLUME_ID         = sprintf('ROLAP_%s',   all_data.VOLUME_ID_nbr_str);
    all_data.VOLUME_VERSION_ID = sprintf('VERSION %s', all_data.version_str);
        
    % DESCRIPTION = "This volume contains EDITED/CALIBRATED?? data from the Rosetta RPC-LAP instrument,
    % acquired during the xxxxxxx phase in 2015 at asteroid/comet??? xxxxxx."
    mp_year_first = year(all_data.mp_first_day);
    mp_year_last  = year(all_data.mp_last_day );
    if mp_year_first == mp_year_last
        mp_year_interval_str = sprintf('%4i', mp_year_first);
    else
        mp_year_interval_str = sprintf('%4i-%4i', mp_year_first, mp_year_last);
    end
    all_data.VOLDESC___DESCRIPTION = sprintf(['This volume contains %s data from the Rosetta RPC-LAP instrument,\r\n', ...
        'acquired during the %s phase in %s at %s %s.'], ...
        all_data.DATA_subdir, all_data.MISSION_PHASE_NAME, mp_year_interval_str, lower(all_data.TARGET_TYPE), all_data.TARGET_NAME);



    %=====================================
    % Set values only used in DATASET.CAT
    %=====================================
    
    all_data.CITATION_DESC_year_str = datestr(now, 'yyyy');              % Publication year = CURRENT YEAR
    all_data.CITATION_DESC = sprintf(['A. I. Eriksson, \r\n', ...
        'R. Gill, and E. P. G. Johansson, Rosetta RPC-LAP archive of %s data \r\n', ...
        'from the %s mission phase, %s,\r\n', ...
        'ESA Planetary Science Archive and NASA Planetary Data System, %s.'], ...
        lower(all_data.DATA_subdir), all_data.MISSION_PHASE_NAME, all_data.DATA_SET_ID, all_data.CITATION_DESC_year_str);

    % ABSTRACT_DESC = "This dataset contains EDITED/CALIBRATED??? data from Rosetta RPC-LAP, acquired during the xxxxxxxxxxxx."
    all_data.ABSTRACT_DESC = sprintf(['This dataset contains \r\n', ...
        '%s data from Rosetta RPC-LAP, acquired during \r\n', ...
        'the %s mission phase.'], ...
        all_data.DATA_subdir, all_data.MISSION_PHASE_NAME);    
    
    % DATA_SET_TERSE_DESC = "This data set contains EDITED/CALIBRATEDxxx data from Rosetta RPC-LAP, gathered during the
    % xxxxxxxxxxxx."
    all_data.DATA_SET_TERSE_DESC = sprintf(['This data set contains \r\n', ...
        '%s data from Rosetta RPC-LAP, gathered during the \r\n', ...
        '%s mission phase.'], all_data.DATA_subdir, all_data.MISSION_PHASE_NAME);
    
    % CONFIDENCE_LEVEL_NOTE = "UNK"
    % CONFIDENCE_LEVEL_NOTE = "These data are uncalibrated raw data,
    % i.e. digital output of the instrument. As such, the confidence level
    % is very high."
    % CONFIDENCE_LEVEL_NOTE = "Data in this archive are instrument
    % outputs in volts and amperes, calibrated and corrected for instrument
    % offsets to the greatest extent possible. Offsets are determined onboard
    % and removed from CALIBRATED data on ground but still remains in EDITED
    % data."
    switch(all_data.PROCESSING_LEVEL_ID)
        case '2'
            all_data.CONFIDENCE_LEVEL_NOTE = sprintf(['These data are uncalibrated raw data,\r\n', ...
                'i.e. digital output of the instrument. As such, the confidence level\r\n', ...
                'is very high.']);
        case '3'
            all_data.CONFIDENCE_LEVEL_NOTE = sprintf(['Data in this archive are \r\n', ...
                'instrument outputs in volts and amperes, calibrated and corrected for \r\n', ...
                'instrument offsets to the greatest extent possible. Offsets are \r\n', ...
                'determined onboard and removed from CALIBRATED data on ground but still \r\n', ...
                'remains in EDITED data.']);
        case '5'
            all_data.CONFIDENCE_LEVEL_NOTE = 'UNK';
    end
end



% ARGUMENTS AND RETURN VALUE
% ==========================
% data       : Structure to which fields are added.
% field_name : That struct column which is to be read. In practice either MISSION_PHASE_NAME or mission_phase_abbrev.
%
% NOTE: Removes all leading and trailing whitespace, and all quotes from mission calendar values.
%
% NOTE: Time values in the pds mission calendar apply to the official mission phase, not for MTP phase,
% not for the current data set per se.
function data = read_mission_calendar(data, file_path, field_name, field_value)
    % PROPOSAL: Make into a separate, general function?
    
    fid = fopen(file_path);
    if fid == -1
        error('Can not read pds mission calendar file "%s".', file_path)
    end
    fc  = textscan(fid, '%s%s%s%s%s%s%s%s', 'Delimiter', ':', 'Commentstyle', '#');  % fc = file contents. fc{i} = Column i
    fclose(fid);
    
    % Assign columns to struct fields.
    % Useful to have these in case one likes to use all of them for some selection criterion.
    cal.MISSION_PHASE_NAME    = strrep(strtrim(fc{1}), '"', '');
    cal.mission_phase_abbrev  = strtrim(fc{2});
    cal.TARGET_NAME           = strrep(strtrim(fc{5}), '"', '');
    cal.DATA_SET_ID_target_ID = strtrim(fc{6});
    cal.TARGET_TYPE           = strrep(strtrim(fc{7}), '"', '');
    cal.DATA_SET_NAME_target  = strtrim(fc{8});
    cal.mp_first_day          = strtrim(fc{3});
    cal.mp_duration           = num2cell(str2double(fc{4}));    % Must have cell array for later for loop to work (needs consistent fields).
    
    % Select row.
    i = find(strcmp(cal.(field_name), field_value));
    if length(i) ~= 1
        error('Can not find exactly one match in mission calendar for "%s"="%s"', field_name, field_value)
    end
    
    % Copy contents of "cal" to data.
    fn_list = fieldnames(cal);
    for j = 1:length(fn_list)
        data.(fn_list{j}) = cal.(fn_list{j}){i};
    end
    
    % Add field.
    data.mp_last_day = datestr(datenum(data.mp_first_day) + data.mp_duration-1, 29);   % 29 = Format (ISO 8601) 'yyyy-mm-dd'
end

