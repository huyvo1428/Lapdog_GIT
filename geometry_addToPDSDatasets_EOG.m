%===============================================================================================
%
% Code for generating geometry files (TAB+LBL) based on EOG files.
% Takes a selection of Elias geometry files and generates LBL/TAB file pairs in subdirectories
% <dataset path>/*/*/<YEAR>/<MONTH>/<DATE>/.
%
% This script is written to be used manually from MATLAB, or from bash by first wrapping it in a bash script.
%
% NOTE: This code is NOT (currently) intended to be run with the rest of Lapdog but may use general utility functions.
%       In particular, it generates its own LBL files.
% NOTE: This generates geometry files for all processing levels (EDITED, CALIB, DERIV).
% NOTE: Code does NOT update any INDEX.TAB/LBL files.
% NOTE: Uses VOLDESC.CAT to find the DATASET_ID.
% NOTE: Overwrites old geometry files without warning.
%
% EOG = Elias Odelstad geometry (files).
%
%
%
% ARGUMENTS
% =========
% varargin : Paths to PDS compliant dataset(s).
%
%
% Created by: Erik P G Johansson, 2016-12-19, IRF Uppsala, Sweden
%===============================================================================================
function geometry_addToPDSDatasets_EOG(metakernelPath, eogFilesDir, pdsMissionCalendarPath, varargin)
    cspice_furnsh(metakernelPath);
    
    for i = 1:length(varargin)
        datasetPath = varargin{i};
        addToPDSDataset(eogFilesDir, pdsMissionCalendarPath, datasetPath);
    end
    
    % "CSPICE_KCLEAR clears the KEEPER system: unload all kernels, clears
    % the kernel pool, and re-initialize the system."
    %cspice_kclear
    cspice_unload(metakernelPath);
end



function addToPDSDataset(eogFilesDir, pdsMissionCalendarPath, datasetPath)
    % PROPOSAL: Check that dest_dir fits with the DATA_SET_ID? Display warning?
    % PROPOSAL: Use get_PDS.
    % PROPOSAL: Replace with script called from bash. Use ro_datasets.DAT.
    %   CON?: Can then not use on non-PDS datasets?

    voldescPath = fullfile(datasetPath, 'VOLDESC.CAT');
    [junk, voldescContents] = lib_shared_EJ.read_ODL_to_structs(voldescPath);
    DATA_SET_ID = voldescContents.OBJECT___VOLUME{1}.DATA_SET_ID;
    
    PDS_base_data.DATA_SET_ID       = DATA_SET_ID;
    PDS_base_data.VOLUME_ID_nbr_str = 'xxxx';    % Value is not used.
    PDS_base_data = get_PDS_base_data(PDS_base_data);
    PDS_data      = get_PDS_data(PDS_base_data, pdsMissionCalendarPath);
    
    %[data_set_path, data_set_info] = CONTROL_PARAMETERS();
    
    geometry_addToPDSDataSet(datasetPath, PDS_data, eogFilesDir);
end



%=======================================================================
% Function which defines all parameters that are to be set by the user.
%=======================================================================
% function [data_set_path, data_set_info] = CONTROL_PARAMETERS()
%     
%     di = [];      % di = dataset info
%     target_ID         = 'C';           % E.g. "C".
%     di.TARGET_TYPE    = 'COMET';       % E.g. "COMET".
%     target_name_short = '67P';         % E.g. "67P":
%     di.TARGET_NAME    = '67P/CHURYUMOV-GERASIMENKO 1 (1969 R1)';
%     
%     data_set_version       = '1.0';     % NOTE: Do not include "V" (for "Version").
%     di.PROCESSING_LEVEL_ID = '3';       % NOTE: String, not number. 2=EDITED, 3=CALIB, 5=DERIV
%     short_mp               = 'TDDG';
%     description_str        = 'CALIB2';
%     di.MISSION_PHASE_NAME  = ['COMET ESCORT 3 ', description_str];   % Long name, e.g. PRELANDING.
%     %-------------------------------------------------------------------------------------------
%     switch di.PROCESSING_LEVEL_ID
%         case '2'
%             di.PRODUCT_TYPE = 'EDR';
%         case '3'
%             di.PRODUCT_TYPE = 'RDR';
%         case '5'
%             di.PRODUCT_TYPE = 'DDR';
%         otherwise
%             error('Can not interpret PROCESSING_LEVEL_ID.')
%     end
%     %-------------------------------------------------------------------------------------------
%     di.DATA_SET_ID =   ['RO-',              target_ID,         '-RPCLAP-', di.PROCESSING_LEVEL_ID, '-', short_mp, '-', description_str, '-V', data_set_version];
%     di.DATA_SET_NAME = ['ROSETTA-ORBITER ', target_name_short, ' RPCLAP ', di.PROCESSING_LEVEL_ID, ' ', short_mp, ' ', description_str, ' V', data_set_version];
%     data_set_info = di;
%     %-------------------------------------------------------------------------------------------
%     
%     % birra
%     %data_set_path = fullfile('/home/erjo/temp/data_set/', di.DATA_SET_ID);
%     data_set_path = fullfile('/home/erjo/temp/data_set/');
%     
%     % spis:
%     %data_set_path = ['/homelocal/erjo/rosetta_data_sets/delivery/', short_mp,'/', di.DATA_SET_ID];
%     
% end
