% Initially created by Erik P G Johansson, IRF Uppsala, 2016-08-01.
%
% EXPERIMENTAL
%
% Obtain various values used in ODL files given information on a specific data set (mission phase, archiving level, version).
% This code is supposed to centralize that type of functionality.
%
% NOTE: None of the values supplied and returned should be quoted. (createLBL_create_OBJTABLE_LBL_file,
% update_DATASET_VOLDESC add quotes.)
%
% NOTE: data.version_str should contain no "V".
%
function data = get_PDS_data(data)
    % QUESTION: What should be the input data?
    %
    % PROPOSAL: Call from createLBL?
    %   CON: Does not want to involve reading from tables.
    %       CON: Then the function should not read from tables.
    %   CON: Does not want to involve data required to derive unnecessary values.
    %       Ex: CITATION_DESC_year.
    %       CON: Example? MISSION_PHASE, TARGET_NAME are available.
    %       CON: Can set to nonsense values.
    %
    % PROPOSAL: Parse DATA_SET_ID?
    %   PRO: Can derive version (for VOLUME_VERSION_ID)
    %
    % PROPOSAL: Include information on whether to quote or not?!
    %    PROPOSAL: Includes list of fields (field names) which should be quoted.
    %
    
    switch(data.PROCESSING_LEVEL_ID)
        case '2'
            data.DATA_subdir = 'EDITED';
            data.PRODUCT_TYPE = 'EDR';
        case '3'
            data.DATA_subdir = 'CALIBRATED';
            data.PRODUCT_TYPE = 'RDR';
        case '5'
            data.DATA_subdir = 'DERIVED';
            data.PRODUCT_TYPE = 'DDR';
        otherwise
            error('Can not interpret recognize data.PROCESSING_LEVEL_ID.')
    end



    %=================================
    % Values only used in VOLDESC.CAT
    %=================================
    
    % VOLUME_NAME = "RPCLAP CALIBRATED DATA FOR EARTH SWING-BY 1"
    data.VOLUME_NAME = sprintf('RPCLAP %s DATA FOR %s', data.DATA_subdir, data.MISSION_PHASE_NAME);
    
    % VOLUME_ID = ROLAP_1099
    data.VOLUME_ID         = sprintf('ROLAP_%04i', data.VOLUME_ID_nbr);
    data.VOLUME_VERSION_ID = sprintf('VERSION %s', data.version_str);
    
    % DESCRIPTION = "This volume contains EDITED/CALIBRATED?? data from the Rosetta RPC-LAP instrument,
    % acquired during the xxxxxxx phase in 2015 at asteroid/comet??? xxxxxx."
    data.VOLDESC___DESCRIPTION = sprintf(['This volume contains %s data from the Rosetta RPC-LAP instrument,\r\n', ...
        'acquired during the %s phase in 20xx at asteroid/comet??? xxxxxx.'], data.DATA_subdir, data.MISSION_PHASE_NAME);



    %=================================
    % Values only used in DATASET.CAT
    %=================================
    
    data.CITATION_DESC_year_str = datestr(now, 'yyyy');              % Publication year = CURRENT YEAR
    data.CITATION_DESC = sprintf(['A. I. Eriksson, R. Gill, and E. P. G. Johansson, Rosetta RPC-LAP\r\n', ...
             'archive of %s data from the %s mission phase, %s,\r\n', ...
             'ESA Planetary Science Archive and NASA Planetary Data System, %s.'], ...
             lower(data.DATA_subdir), data.MISSION_PHASE_NAME, data.DATA_SET_ID, data.CITATION_DESC_year_str);
         
    % ABSTRACT_DESC = "This dataset contains EDITED/CALIBRATED??? data from Rosetta RPC-LAP, aquired during the xxxxxxxxxxxx."
    data.ABSTRACT_DESC = sprintf('This dataset contains %s data from Rosetta RPC-LAP, aquired during the %s mission phase.', data.DATA_subdir, data.MISSION_PHASE_NAME);    
    
    % DATA_SET_TERSE_DESC = "This data set contains EDITED/CALIBRATEDxxx data from Rosetta RPC-LAP, gathered during the
    % xxxxxxxxxxxx."
    data.DATA_SET_TERSE_DESC = sprintf('This data set contains %s data from Rosetta RPC-LAP, gathered during the\r\n', ...
        '%s mission phase.', data.DATA_subdir, data.MISSION_PHASE_NAME);
    
    % CONFIDENCE_LEVEL_NOTE = "UNK"    
    % CONFIDENCE_LEVEL_NOTE = "These data are uncalibrated raw data,
    % i.e. digital output of the instrument. As such, the confidence level
    % is very high."
    % CONFIDENCE_LEVEL_NOTE = "Data in this archive are instrument
    % outputs in volts and amperes, calibrated and corrected for instrument
    % offsets to the greatest extent possible. Offsets are determined onboard
    % and removed from CALIBRATED data on ground but still remains in EDITED
    % data."
    switch(data.PROCESSING_LEVEL_ID)
        case '2'
            data.CONFIDENCE_LEVEL_NOTE = ['These data are uncalibrated raw data,\r\n', ...
                'i.e. digital output of the instrument. As such, the confidence level\r\n', ...
                'is very high.'];
        case '3'
            data.CONFIDENCE_LEVEL_NOTE = ['Data in this archive are instrument\r\n', ...
                'outputs in volts and amperes, calibrated and corrected for instrument\r\n', ...
                'offsets to the greatest extent possible. Offsets are determined onboard\r\n', ...
                'and removed from CALIBRATED data on ground but still remains in EDITED\r\n', ...
                'data.'];
        case '5'
            data.CONFIDENCE_LEVEL_NOTE = 'UNK';
    end
end

