%===============================================================================================
%
% Code for generating geometry files (TAB+LBL) based on Elias' informal geometry files.
% Takes a selection of Elias geometry files and generates LBL/TAB file pairs in subdirectories
% /<YEAR>/<MONTH>/<DATE>/ relative to a specified directory, eg. inside a data set.
%
% NOTE: This code is NOT (currently) intended to be run with
% the rest of Lapdog but may use general utility functions, in particular for generating LBL files.
% This is a "script", which is not intended to be "nice" although it indirectly makes use of
% (calls) other code which is properly written. Therefore it uses a "user interface" based on editing
% hardcoded variables in a function.
% NOTE: This generates geometry files for processing levels (EDITED, CALIB, DERIV), not just DERIV.
% NOTE: Code does NOT update any INDEX.TAB/LBL files.
% EG = Elias geometry file.
%
% Created by: Erik P G Johansson, 2015-08-xx, IRF Uppsala, Sweden
% Major rewrite: Erik P G Johansson, 2015-12-15, IRF Uppsala, Sweden
%===============================================================================================
function geometry_addToDataSet_EG_manual()
    % PROPOSAL: Check that dest_dir fits with the DATA_SET_ID? Display warning?
    
    [kernel_file, EG_files_dir, data_set_path, data_set_info] = CONTROL_PARAMETERS();
    cspice_furnsh(kernel_file);
    
    geometry_addToDataSet(data_set_path, data_set_info, EG_files_dir);
    
    % "CSPICE_KCLEAR clears the KEEPER system: unload all kernels, clears
    % the kernel pool, and re-initialize the system."
    cspice_kclear
end



%=======================================================================
% Function which defines all parameters that are to be set by the user.
%=======================================================================
function [kernel_file, EG_files_dir, data_set_path, data_set_info] = CONTROL_PARAMETERS()
    
    di = [];      % di = dataset info
    target_ID         = 'C';           % E.g. "C".
    di.TARGET_TYPE    = 'COMET';       % E.g. "COMET".
    target_name_short = '67P';         % E.g. "67P":
    di.TARGET_NAME    = '67P/CHURYUMOV-GERASIMENKO 1 (1969 R1)';
    
    data_set_version       = '1.0';       % NOTE: Do not include "V" (for "Version").
    di.PROCESSING_LEVEL_ID = '2';   % NOTE: String, not number. 2=EDITED, 3=CALIB, 5=DERIV
    short_mp               = 'ESC3';
    description_str        = 'MTP021';
    di.MISSION_PHASE_NAME  = ['COMET ESCORT 3 ', description_str];   % Long name, e.g. PRELANDING.
    %-------------------------------------------------------------------------------------------
    switch di.PROCESSING_LEVEL_ID
        case '2'
            di.PRODUCT_TYPE = 'EDR';
        case '3'
            di.PRODUCT_TYPE = 'RDR';
        case '5'
            di.PRODUCT_TYPE = 'DDR';
        otherwise
            error('Can not interpret PROCESSING_LEVEL_ID.')
    end
    %-------------------------------------------------------------------------------------------
    di.DATA_SET_ID =   ['RO-',              target_ID,         '-RPCLAP-', di.PROCESSING_LEVEL_ID, '-', short_mp, '-', description_str, '-V', data_set_version];
    di.DATA_SET_NAME = ['ROSETTA-ORBITER ', target_name_short, ' RPCLAP ', di.PROCESSING_LEVEL_ID, ' ', short_mp, ' ', description_str, ' V', data_set_version];
    data_set_info = di;
    %-------------------------------------------------------------------------------------------
    
    % birra
    %kernel_file = '/home/erjo/work_files/ROSETTA/Lapdog_GIT/metakernel_rosetta.txt';
    %EG_files_dir = '/home/erjo/temp/EO_geometry_files';
    %data_set_path = '/home/erjo/temp/data_set/';
    
    % spis:
    kernel_file = '/home/erjo/lapdog_squid_copy/metakernel_rosetta.txt';
    EG_files_dir = '/homelocal/erjo/rosetta_data_sets/delivery/ESC3/EO_geometry_files';
    data_set_path = ['/homelocal/erjo/rosetta_data_sets/delivery/', short_mp,'/', di.DATA_SET_ID];
    
end
