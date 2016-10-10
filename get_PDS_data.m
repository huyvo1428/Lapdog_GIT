% Initially created by Erik P G Johansson, IRF Uppsala, 2016-08-01.
%
% Obtain various PDS keyword (and keyword-like) values given PDS keyword(-like) values on a specific data set.
% This code is supposed to centralize that type of functionality.
%
% INPUT ARGUMENTS:
% ----------------
% base_data: Structure with fields describing a specific data set to which fields will be added.
%    The argument must have a certain set of struct fields. Either
%    (1) .VOLUME_ID_nbr_str
%        .DATA_SET_ID,
%    or the same information expressed as separate PDS "keywords", i.e.
%    (2) .DATA_SET_NAME_target
%        .PROCESSING_LEVEL_ID
%        .mission_phase_abbrev
%        .DATA_SET_ID_descr
%        .version_str.
%    The return variable will have all the fields above, both (1) and (2).
% all_data: Structure to which (1) the fields of base_data, and (2) other derived fields will be added.
%
%
% Variable (field) naming convention:
% - Field names which are capitalized refer to PDS keywords.
% - Field names which first part is capitalized and its second part lower case refer to a subset of ONE specific PDS keyword value.
%   NOTE: There are variables which refer to a subset of SEVERAL PDS keyword value. Ex: version_str.
% - Field names which begin with "VOLDESC___" refer to the file VOLDESC.CAT. (VOLDESC___DESCRIPTION would otherwise be ambiguous.)
%
% NOTE: All field values are strings.
% NOTE: None of the values supplied and returned should be quoted. (createLBL_create_OBJTABLE_LBL_file,
% update_DATASET_VOLDESC add quotes.)
% NOTE: Does not set DATASET.CAT:START_TIME, STOP_TIME.
% NOTE: ".version_str" refers to the version number (string) in e.g. DATA_SET_ID, DATA_SET_NAME and possibly VOLDESC.CAT:VOLUME_VERSION_ID.
%       ".version_str" should contain no "V".
%
function [all_data, base_data] = get_PDS_data(all_data, base_data, mission_calendar_path)
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
    
    
    
    %===================================================================
    % Derive the fields the function does not have from the ones it has
    %===================================================================
    base_fields1 = {'DATA_SET_ID_target_ID', 'PROCESSING_LEVEL_ID', 'mission_phase_abbrev', 'DATA_SET_ID_descr', 'version_str', 'VOLUME_ID_nbr_str'};
    base_fields2 = {'DATA_SET_ID', 'VOLUME_ID_nbr_str'};
    %base_fields_present = isfield(base_data, base_fields1);
    if isempty(setdiff(fieldnames(base_data), base_fields1))
        base_data.DATA_SET_ID = sprintf('RO-%s-RPCLAP-%s-%s-%s-V%s', ...
            base_data.DATA_SET_ID_target_ID, ...
            base_data.PROCESSING_LEVEL_ID, ...
            base_data.mission_phase_abbrev, ...
            base_data.DATA_SET_ID_descr, ...
            base_data.version_str);
    elseif isempty(setdiff(fieldnames(base_data), base_fields2))
        [   base_data.DATA_SET_ID_target_ID, ...
            base_data.PROCESSING_LEVEL_ID, ...
            base_data.mission_phase_abbrev, ...
            base_data.DATA_SET_ID_descr, ...
            base_data.version_str] ...
            = ...            
            strread(base_data.DATA_SET_ID, 'RO-%[^-]-RPCLAP-%[^-]-%[^-]-%[^-]-V%[^-]');
        for f = {'DATA_SET_ID_target_ID', 'PROCESSING_LEVEL_ID', 'mission_phase_abbrev', 'DATA_SET_ID_descr', 'version_str'}
            base_data.(f{1}) = base_data.(f{1}){1};
        end
    else
        error('The input data variable has a disallowed set of fields.')
    end
    for fn = fieldnames(base_data)'
        all_data.(fn{1}) = base_data.(fn{1});
    end
    
    all_data = read_mission_calendar(all_data, mission_calendar_path, 'mission_phase_abbrev', all_data.mission_phase_abbrev);



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
    


    %=================================
    % Values only used in VOLDESC.CAT
    %=================================
    
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
    all_data.VOLDESC___DESCRIPTION = sprintf(['This volume contains %s data from the Rosetta RPC-LAP instrument,\r\n', ...
        'acquired during the %s phase in 20xx at %s %s.'], all_data.DATA_subdir, all_data.MISSION_PHASE_NAME, lower(all_data.TARGET_TYPE), all_data.TARGET_NAME);



    %=================================
    % Values only used in DATASET.CAT
    %=================================
    
    all_data.CITATION_DESC_year_str = datestr(now, 'yyyy');              % Publication year = CURRENT YEAR
    all_data.CITATION_DESC = sprintf(['A. I. Eriksson, R. Gill, and E. P. G. Johansson, Rosetta RPC-LAP\r\n', ...
             'archive of %s data from the %s mission phase, %s,\r\n', ...
             'ESA Planetary Science Archive and NASA Planetary Data System, %s.'], ...
             lower(all_data.DATA_subdir), all_data.MISSION_PHASE_NAME, all_data.DATA_SET_ID, all_data.CITATION_DESC_year_str);

    % ABSTRACT_DESC = "This dataset contains EDITED/CALIBRATED??? data from Rosetta RPC-LAP, acquired during the xxxxxxxxxxxx."
    all_data.ABSTRACT_DESC = sprintf('This dataset contains %s data from Rosetta RPC-LAP, acquired during the %s mission phase.', all_data.DATA_subdir, all_data.MISSION_PHASE_NAME);    
    
    % DATA_SET_TERSE_DESC = "This data set contains EDITED/CALIBRATEDxxx data from Rosetta RPC-LAP, gathered during the
    % xxxxxxxxxxxx."
    all_data.DATA_SET_TERSE_DESC = sprintf(['This data set contains %s data from Rosetta RPC-LAP, gathered during the\r\n', ...
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
            all_data.CONFIDENCE_LEVEL_NOTE = sprintf(['Data in this archive are instrument\r\n', ...
                'outputs in volts and amperes, calibrated and corrected for instrument\r\n', ...
                'offsets to the greatest extent possible. Offsets are determined onboard\r\n', ...
                'and removed from CALIBRATED data on ground but still remains in EDITED\r\n', ...
                'data.']);
        case '5'
            all_data.CONFIDENCE_LEVEL_NOTE = 'UNK';
    end
end



% data = structure to which fields are added.
% field_name = That struct column which is to be read. In practice either MISSION_PHASE_NAME or mission_phase_abbrev.
%
% NOTE: Removes all leading and trailing whitespace, and all quotes from mission calendar values.
function data = read_mission_calendar(data, file_path, field_name, field_value)
    % PROPOSAL: Separate as general function?
    
    fid = fopen(file_path);
    fc  = textscan(fid, '%s%s%s%s%s%s%s%s', 'Delimiter', ':', 'Commentstyle', '#');  % fc = file contents. One 
    fclose(fid);
    
    % NOTE: Omits mission phase start and duration for now.
    cal.MISSION_PHASE_NAME    = strrep(strtrim(fc{1}), '"', '');
    cal.mission_phase_abbrev  = strtrim(fc{2});
    cal.TARGET_NAME           = strrep(strtrim(fc{5}), '"', '');
    cal.DATA_SET_ID_target_ID = strtrim(fc{6});
    cal.TARGET_TYPE           = strrep(strtrim(fc{7}), '"', '');
    cal.DATA_SET_NAME_target  = strtrim(fc{8});
    
    i = find(strcmp(cal.(field_name), field_value));
    if length(i) ~= 1
        error('Can not find exactly one match in mission calendar for "%s"="%s"', field_name, field_value)
    end
    
    fn_list = fieldnames(cal);
    for j = 1:length(fn_list)
        data.(fn_list{j}) = cal.(fn_list{j}){i};
    end
end
