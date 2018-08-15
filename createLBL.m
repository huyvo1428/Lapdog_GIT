
%function createLBL_main(derivedpath, datasetid, shortphase, datasetname, ...
%        lbltime, lbleditor, lblrev, ...
%        producerfullname, producershortname, targetfullname, targettype, missionphase, tabindex, blockTAB, index, an_tabindex)

%
% Create .LBL files for all .TAB files.
% NOTE: Uses global variable "der_struct"
%
% VARIABLE NAMING CONVENTIONS
% ===========================
% OCL = Object Column List
% KVL = Key-Value (pair) List

%===================================================================================================
% PROPOSAL/TODO: Have one MISSING_CONSTANT for createLBL.m and one for ~best_estimates.m.
%    QUESTION: How?
% PROPOSAL: Different LABEL_REVISION_NOTE för CALIB2, DERIV2. Multiple rows?
% PROPOSAL: Use get_PDS.m.
%   TODO-NEED-INFO: Why? What needed for?
%
% PROPOSAL: Stop/disable generating AxS LBL files.
%   PRO: Will never be used (but lead to work).
%   PRO: Are not up-to-date and generate errors/warnings which are typically ignored.
%
%
%
% PROPOSAL: Move different sections into separate functions.
%   PRO: No need to clear variables.
%   PRO: Smaller code sections.
%   PROPOSAL: for-loops, or that which is iterated over.
%
% PROPOSAL: Make into script that simply calls separate main function (other file).
%   PRO: Better encapsulation/modularization.
%   PRO: Can use own variable names.
%   PRO: Better for testing since arguments are more transparent.
%   PRO: Can have local functions (instead of separate files).
%   CON: Too many arguments (16).
%       PROPOSAL: Set struct which is passed to function.
%   --
%   PROPOSAL: Move some +createLB/* functions into it.
%   PROPOSAL: Do not reference any global variables in main function.
%       CON/PROBLEM: der_struct is not defined for non-EDDER and can thus not just be added as argument.
%
% TODO: Make work with EDDER and DERIV at the same time.
%   TODO: Make sure DATA_SET_ID is correct.
%       NOTE: 2018-03-26: Ex:
%           Directory RO-C-RPCLAP-99-TDDG-EDDER-V0.1/
%           DATA_SET_ID="RO-A-RPCLAP-3-AST2-CALIB-V2.0 ??" (including question marks)
%       PROPOSAL: Set by ro_create_delivery.
%           NOTE: Might already be done.
%
% TODO-DECISION: What kind of information should be set in
%   (1) createLBL, and
%   (2) ~create_C2D2_from_CALIB1/create_E2C2D2_from_CALIB1_EDITED1,
%   respectively? What philosophy should one use?
%   NOTE: Want to avoid setting the same information twice. Avoid first setting in createLBL, and then overwriting in
%         ~create_E2C2D2_*.
%   --
%   Ex: Column description differences.
%   Ex: DATA_SET_ID + DATA_SET_NAME
%   Ex: PRODUCT_TYPE + PROCESSING_LEVEL_ID (level)
%   Ex: ^EAICD_DESC/ARCHIVE_CONTENT_DESC, MISSING_CONSTANT
%   Ex: PRODUCER_ID, PRODUCER_FULL_NAME, PRODUCER_INSTITUTION_NAME, INSTRUMENT_* (5 keywords)
%   Ex: Ordering of header keywords.
%       NOTE: Best done together with checking for forbidden keys (and enforcing quotes?) ==> Lapdog.
%   --
%   PROPOSAL:
%       Lapdog/createLBL should handle:
%           - Philosophically:
%               - All metadata which naturally (could) vary between individdual data products (not just between PDS data sets)
%                   Ex: TODO-DECISION: Common within PDS data set, i.e. DATA_SET_ID/-NAME, 
%               - All metadata close to the TAB contents.
%           - Explicitly: 
%               - Column description differences (between EDDER/LAPDOG); columns present, widths of columns).
%               - MISSION_CONSTANT
%       ~create_E2C2D2 should handle
%           - Philosophically: Metadata which has to do with how to select Lapdog/Edder data products to be included in
%             delivery data sets.
%       NOTE: Assumes that all delivery/PDS data sets pass through ~create_E2C2D2.
%
%   PROPOSAL: Values NOT set by createLBL, should be set to invalid placeholder values, e.g. ^EAICD_DESC = <unset>.
%       PRO: Makes it clear in createLBL what information is not set (but not the reverse).
%       PROPOSAL: ~create_E2C2D2 should only be allowed to overwrite such placeholder values (assertion).
%   PROPOSAL: createLBL should NEVER set unused/overwritten keywords (not even to placeholder values).
%       ~create_E2C2D2 should add the keys instead and check for collisions.
%
% PROPOSAL: Write function for obtaining number of columns in TAB file.
%   PRO: Can use for obtaining number of IxS columns ==> Does not need corresponding tabindex field.
%       PRO: Makes code more reliable.
%   --
%   PRO: Can use as assertion in create_OBJTABLE_LBL_file.
%   PRO: Can simultaneously obtain nBytesPerRow and derive nRows (with file size).
%       ==> Somewhat better TAB file assertion in create_OBJTABLE_LBL_file than using just column descriptions.
%   CON: Slower.
%   CON: Slightly unsafe. Would need to search for strings ', '.
%
% PROPOSAL: Make code independent of stabindex.utcStop, stabindex.sctStop by just using
%           index(stabindex.iIndexFirst/Last) instead.
%   PRO: Makes code more reliable.
%   TODO-NEED-INFO: Need info if correct understanding of index timestamps.
%
% PROPOSAL: Read STOP_TIME from the last CALIB1/EDITED1 file, just like Calib1LblSs does.
%
% PROPOSAL: Help functions for setting specific types of column descriptions.
%   PRO: Does not need to write out struct field names: NAME, DESCRIPTION etc.
%   PRO: Automatically handle EDDER/DERIV1 differences.
%   --
%   TODO-DECISION: How handle MISSING_CONSTANT?
%   TODO-DECISION: Need to think about how to handle DERIV2 TAB columns (here part of DERIV1)?
%   --
%   PROPOSAL: Automatically set constants for BYTES, DATA_TYPE, UNIT.
%   PROPOSAL: OPTIONAL sprintf options for NAME ?
%       PROBLEM: How implement optionality?
%   PROPOSAL: UTC, OBT (separately to also be able to handle sweeps)
%       PROPOSAL: oc_UTC(name, bytes, descrStr)
%           NOTE: There is ~TIME_UTC with either BYTES=23 or 26.
%               PROPOSAL: Have assertion for corresponding argument.
%               PROPOSAL: Modify TAB files to always have BYTES=26?!!
%           PROPOSAL: Assertion that name ends with "TIME_UTC".
%       PROPOSAL: oc_OBT(name, descrStr)
%           NOTE: BYTES=16 always
%   --
%   PROPOSAL: Standard single current/voltage, measured/bias column which varies with EDDER/DERIV1.
%       PROPOSAL: Argument which selects: "bias", "meas"
%   PROPOSAL: Take hard-coded constants struct "C" as argument.
%       TODO-DECISION: Should struct depend on EDDER/DERIV1 or contain info for both?
%===================================================================================================

executionBeginDateVec = clock;    % NOTE: NOT a scalar (e.g. number of seconds), but [year month day hour minute seconds].
prevWarningsSettings = warning('query');
warning('on', 'all')

global SATURATION_CONSTANT
global N_FINAL_PRESWEEP_SAMPLES

%========================================================================================
% "Constants"
% -----------
% NO_ODL_UNIT: Constant to be used for LBL "UNIT" fields meaning that there is no unit.
% This means that it is known that the quantity has no unit rather than that the unit
% is simply unknown at present.
%========================================================================================
NO_ODL_UNIT       = [];
ODL_VALUE_UNKNOWN = 'UNKNOWN';   %'<Unknown>';  % Unit is unknown. Should not be used for official deliveries.
DONT_READ_HEADER_KEY_LIST = {'FILE_NAME', '^TABLE', 'PRODUCT_ID', 'RECORD_BYTES', 'FILE_RECORDS', 'RECORD_TYPE'};
MISSING_CONSTANT = SATURATION_CONSTANT;
%MISSING_CONSTANT_DESCRIPTION_AMENDMENT = sprintf('A value of %g refers to that the original value was saturated, or that it was an average over at least one saturated value.', MISSING_CONSTANT);
ROSETTA_NAIF_ID  = -226;     % Used for SPICE.
INDENTATION_LENGTH = 4;
DEBUG_ON = 1;
%EAICD_FILE_NAME  = 'RO-IRFU-LAP-EAICD.PDF';    % NOTE: Must match EJ_rosetta.delivery.create_DOCINFO.m (EJ's code).



%==================================================================
% LBL Header keys which should preferably come in a certain order.
% Not all of them are required to be present.
%==================================================================
% Keywords which are quite independent of type of file.
GENERAL_KEY_ORDER_LIST = { ...
    'PDS_VERSION_ID', ...    % The PDS standard requires this to be first, I think.
    ...
    'RECORD_TYPE', ...
    'RECORD_BYTES', ...
    'FILE_RECORDS', ...
    'FILE_NAME', ...
    '^TABLE', ...
    'DATA_SET_ID', ...
    'DATA_SET_NAME', ...
    'DATA_QUALITY_ID', ...
    'MISSION_ID', ...
    'MISSION_NAME', ...
    'MISSION_PHASE_NAME', ...
    'PRODUCER_INSTITUTION_NAME', ...
    'PRODUCER_ID', ...
    'PRODUCER_FULL_NAME', ...
    'LABEL_REVISION_NOTE', ...
    'PRODUCT_ID', ...
    'PRODUCT_TYPE', ...
    'PRODUCT_CREATION_TIME', ...
    'INSTRUMENT_HOST_ID', ...
    'INSTRUMENT_HOST_NAME', ...
    'INSTRUMENT_NAME', ...
    'INSTRUMENT_ID', ...
    'INSTRUMENT_TYPE', ...
    'INSTRUMENT_MODE_ID', ...
    'INSTRUMENT_MODE_DESC', ...
    'TARGET_NAME', ...
    'TARGET_TYPE', ...
    'PROCESSING_LEVEL_ID', ...
    'START_TIME', ...
    'STOP_TIME', ...
    'SPACECRAFT_CLOCK_START_COUNT', ...
    'SPACECRAFT_CLOCK_STOP_COUNT', ...
    'DESCRIPTION'};
% Keywords which refer to very specific settings.
RPCLAP_KEY_ORDER_LIST = { ...
    'ROSETTA:LAP_TM_RATE', ...
    'ROSETTA:LAP_BOOTSTRAP', ...
    ...
    'ROSETTA:LAP_FEEDBACK_P1', ...
    'ROSETTA:LAP_P1_ADC20', ...
    'ROSETTA:LAP_P1_ADC16', ...
    'ROSETTA:LAP_P1_RANGE_DENS_BIAS', ...
    'ROSETTA:LAP_P1_STRATEGY_OR_RANGE', ...
    'ROSETTA:LAP_P1_RX_OR_TX', ...
    'ROSETTA:LAP_P1_ADC16_FILTER', ...
    'ROSETTA:LAP_IBIAS1', ...
    'ROSETTA:LAP_VBIAS1', ...
    'ROSETTA:LAP_P1_BIAS_MODE', ...
    'ROSETTA:LAP_P1_INITIAL_SWEEP_SMPLS', ...
    'ROSETTA:LAP_P1_SWEEP_PLATEAU_DURATION', ...
    'ROSETTA:LAP_P1_SWEEP_STEPS', ...
    'ROSETTA:LAP_P1_SWEEP_START_BIAS', ...
    'ROSETTA:LAP_P1_SWEEP_FORMAT', ...
    'ROSETTA:LAP_P1_SWEEP_RESOLUTION', ...
    'ROSETTA:LAP_P1_SWEEP_STEP_HEIGHT', ...
    'ROSETTA:LAP_P1_ADC16_DOWNSAMPLE', ...
    'ROSETTA:LAP_P1_DENSITY_FIX_DURATION', ...
    ...
    'ROSETTA:LAP_FEEDBACK_P2', ...
    'ROSETTA:LAP_P2_ADC20', ...
    'ROSETTA:LAP_P2_ADC16', ...
    'ROSETTA:LAP_P2_RANGE_DENS_BIAS', ...
    'ROSETTA:LAP_P2_STRATEGY_OR_RANGE', ...
    'ROSETTA:LAP_P2_RX_OR_TX', ...
    'ROSETTA:LAP_P2_ADC16_FILTER', ...
    'ROSETTA:LAP_IBIAS2', ...
    'ROSETTA:LAP_VBIAS2', ...
    'ROSETTA:LAP_P2_BIAS_MODE', ...
    'ROSETTA:LAP_P2_INITIAL_SWEEP_SMPLS', ...
    'ROSETTA:LAP_P2_SWEEP_PLATEAU_DURATION', ...
    'ROSETTA:LAP_P2_SWEEP_STEPS', ...
    'ROSETTA:LAP_P2_SWEEP_START_BIAS', ...
    'ROSETTA:LAP_P2_SWEEP_FORMAT', ...
    'ROSETTA:LAP_P2_SWEEP_RESOLUTION', ...
    'ROSETTA:LAP_P2_SWEEP_STEP_HEIGHT', ...
    'ROSETTA:LAP_P2_ADC16_DOWNSAMPLE', ...
    'ROSETTA:LAP_P2_DENSITY_FIX_DURATION', ...
    ...
    'ROSETTA:LAP_P1P2_ADC20_STATUS', ...
    'ROSETTA:LAP_P1P2_ADC20_MA_LENGTH', ...
    'ROSETTA:LAP_P1P2_ADC20_DOWNSAMPLE'
    };
KEY_ORDER_LIST = [GENERAL_KEY_ORDER_LIST, RPCLAP_KEY_ORDER_LIST];

% Give error if encountering any of these keys.
% Useful for obsoleted keys that should not exist anymore.
FORBIDDEN_KEYS = { ...
    'ROSETTA:LAP_INITIAL_SWEEP_SMPLS', ...
    'ROSETTA:LAP_SWEEP_PLATEAU_DURATION', ...
    'ROSETTA:LAP_SWEEP_STEPS', ...
    'ROSETTA:LAP_SWEEP_START_BIAS', ...
    'ROSETTA:LAP_SWEEP_FORMAT', ...
    'ROSETTA:LAP_SWEEP_RESOLUTION', ...
    'ROSETTA:LAP_SWEEP_STEP_HEIGHT'};

%         ADD_QUOTES_KEYS = { ...
%             'DESCRIPTION', ...
%             'SPACECRAFT_CLOCK_START_COUNT', ...
%             'SPACECRAFT_CLOCK_STOP_COUNT', ...
%             'INSTRUMENT_MODE_DESC', ...
%             'ROSETTA:LAP_TM_RATE', ...
%             'ROSETTA:LAP_BOOTSTRAP', ...
%             'ROSETTA:LAP_FEEDBACK_P1', ...
%             'ROSETTA:LAP_FEEDBACK_P2', ...
%             'ROSETTA:LAP_P1_ADC20', ...
%             'ROSETTA:LAP_P1_ADC16', ...
%             'ROSETTA:LAP_P1_RANGE_DENS_BIAS', ...
%             'ROSETTA:LAP_P1_STRATEGY_OR_RANGE', ...
%             'ROSETTA:LAP_P1_RX_OR_TX', ...
%             'ROSETTA:LAP_P1_ADC16_FILTER', ...
%             'ROSETTA:LAP_P1_BIAS_MODE', ...
%             'ROSETTA:LAP_P2_ADC20', ...
%             'ROSETTA:LAP_P2_ADC16', ...
%             'ROSETTA:LAP_P2_RANGE_DENS_BIAS', ...
%             'ROSETTA:LAP_P2_STRATEGY_OR_RANGE', ...
%             'ROSETTA:LAP_P2_RX_OR_TX', ...
%             'ROSETTA:LAP_P2_ADC16_FILTER', ...
%             'ROSETTA:LAP_P2_BIAS_MODE', ...
%             'ROSETTA:LAP_P1P2_ADC20_STATUS', ...
%             'ROSETTA:LAP_P1P2_ADC20_MA_LENGTH', ...
%             'ROSETTA:LAP_P1P2_ADC20_DOWNSAMPLE', ...
%             'ROSETTA:LAP_VBIAS1', ...
%             'ROSETTA:LAP_VBIAS2', ...
%             ...
%             'ROSETTA:LAP_P1_INITIAL_SWEEP_SMPLS', ...
%             'ROSETTA:LAP_P1_SWEEP_PLATEAU_DURATION', ...
%             'ROSETTA:LAP_P1_SWEEP_STEPS', ...
%             'ROSETTA:LAP_P1_SWEEP_START_BIAS', ...
%             'ROSETTA:LAP_P1_SWEEP_FORMAT', ...
%             'ROSETTA:LAP_P1_SWEEP_RESOLUTION', ...
%             'ROSETTA:LAP_P1_SWEEP_STEP_HEIGHT', ...
%             'ROSETTA:LAP_P1_ADC16_DOWNSAMPLE', ...
%             'ROSETTA:LAP_SWEEPING_P1', ...
%             ...
%             'ROSETTA:LAP_P2_FINE_SWEEP_OFFSET', ...
%             'ROSETTA:LAP_P2_INITIAL_SWEEP_SMPLS', ...
%             'ROSETTA:LAP_P2_SWEEP_PLATEAU_DURATION', ...
%             'ROSETTA:LAP_P2_SWEEP_STEPS', ...
%             'ROSETTA:LAP_P2_SWEEP_START_BIAS', ...
%             'ROSETTA:LAP_P2_SWEEP_FORMAT', ...
%             'ROSETTA:LAP_P2_SWEEP_RESOLUTION', ...
%             'ROSETTA:LAP_P2_SWEEP_STEP_HEIGHT', ...
%             'ROSETTA:LAP_P2_ADC16_DOWNSAMPLE', ...
%             'ROSETTA:LAP_SWEEPING_P2', ...
%             'ROSETTA:LAP_P2_FINE_SWEEP_OFFSET'};

% Keys for which quotes are added to the value if the values does not already have quotes.
FORCE_QUOTE_KEYS = {...
    'DESCRIPTION', ...
    'SPACECRAFT_CLOCK_START_COUNT', ...
    'SPACECRAFT_CLOCK_STOP_COUNT'};

LBL_HEADER_OPTIONS = struct('keyOrderList', {KEY_ORDER_LIST}, 'forbiddenKeysList', {FORBIDDEN_KEYS}, 'forceQuotesKeysList', {FORCE_QUOTE_KEYS});



% Set policy for errors/warning
% (1) when failing to generate a file, 
% (2) when LBL files are (believed to be) inconsistent with TAB files.
if DEBUG_ON
    GENERATE_FILE_FAIL_POLICY = 'message+stack trace';
    
    GENERAL_TAB_LBL_INCONSISTENCY_POLICY = 'error';
    AxS_TAB_LBL_INCONSISTENCY_POLICY     = 'nothing';
else
    GENERATE_FILE_FAIL_POLICY = 'message';
    %GENERATE_FILE_FAIL_POLICY = 'nothing';    % Somewhat misleading. Something may still be printed.
    
    GENERAL_TAB_LBL_INCONSISTENCY_POLICY = 'warning';
    AxS_TAB_LBL_INCONSISTENCY_POLICY     = 'nothing';
end



%=====================================================================================
% Determine whether 
% (1) Lapdog's EDDER (for producing EDITED2), or
% (2) Lapdog's DERIV (for producing CALIB2, DERIV2).
% IMPLEMENTATION NOTE: "fileparts" does not work as intended if path ends with slash.
%=====================================================================================
derivedPathModifCell = regexp(derivedpath, '.*[^/]', 'match');       % Remove trailing slashes (i.e. Linux only).
[parentPath, basename, suffixJunk] = fileparts(derivedPathModifCell{1});    % NOTE: fileparts interprets the period in DATA_SET_ID as separating basename from suffix.
if strfind(basename, 'EDDER')
    generatingDeriv1 = 0;
elseif strfind(basename, 'DERIV')
    generatingDeriv1 = 1;
else
    error('Can not interpret whether generating (Lapdog''s) EDDER or (Lapdog''s) DERIV1 data set. basename=%s', basename)
end



% Set PDS keywords to use for column descriptions which differ between EDITED2/EDDER and DERIV/CALIB2
% ---------------------------------------------------------------------------------------------------
% IMPLEMENTATION NOTE: Some are meant to be used on the form DATA_UNIT_CURRENT{:} in object column description struct declaration/assignment, "... = struct(...)".
% This makes it possible to optionally omit the keyword, besides shortening the assignment when non-empty. This is not
% currently used though.
% NOTE: Also useful for standardizing the values used, even for values which are only used for e.g. DERIV1 but not EDDER.
if generatingDeriv1
    DATA_DATA_TYPE    = {'DATA_TYPE', 'ASCII_REAL'};
    DATA_UNIT_CURRENT = {'UNIT', 'AMPERE'};
    DATA_UNIT_VOLTAGE = {'UNIT', 'VOLT'};
    VOLTAGE_BIAS_DESC =          'CALIBRATED VOLTAGE BIAS.';
    VOLTAGE_MEAS_DESC = 'MEASURED CALIBRATED VOLTAGE.';
    CURRENT_BIAS_DESC =          'CALIBRATED CURRENT BIAS.';
    CURRENT_MEAS_DESC = 'MEASURED CALIBRATED CURRENT.';
else
    % CASE: EDDER run
    DATA_DATA_TYPE    = {'DATA_TYPE', 'ASCII_INTEGER'};
    DATA_UNIT_CURRENT = {'UNIT', 'N/A'};
    DATA_UNIT_VOLTAGE = {'UNIT', 'N/A'};
    VOLTAGE_BIAS_DESC =          'VOLTAGE BIAS.';
    VOLTAGE_MEAS_DESC = 'MEASURED VOLTAGE.';
    CURRENT_BIAS_DESC =          'CURRENT BIAS.';
    CURRENT_MEAS_DESC = 'MEASURED CURRENT.';
end



%====================================================================================================
% Construct list of key-value pairs to use for all LBL files.
% -----------------------------------------------------------
% Keys must not collide with keys set for specific file types.
% For file types that read CALIB LBL files, must overwrite old keys(!).
% 
% NOTE: Only keys that already exist in the CALIB files that are read (otherwise intentional error)
%       and which are thus overwritten.
% NOTE: Might not be complete.
% NOTE: Contains many hardcoded constants, but not only.
%====================================================================================================
KvlLblAll = [];
KvlLblAll.keys = {};
KvlLblAll.values = {};
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'PDS_VERSION_ID',            'PDS3');
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'DATA_QUALITY_ID',           '"1"');
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'PRODUCT_CREATION_TIME',     datestr(now, 'yyyy-mm-ddTHH:MM:SS.FFF'));
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'PRODUCT_TYPE',              '"DDR"');
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'PROCESSING_LEVEL_ID',       '"5"');

KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'DATA_SET_ID',               ['"', strrep(datasetid,   sprintf('-3-%s-CALIB', shortphase), sprintf('-5-%s-DERIV', shortphase)), '"']);
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'DATA_SET_NAME',             ['"', strrep(datasetname, sprintf( '3 %s CALIB', shortphase), sprintf( '5 %s DERIV', shortphase)), '"']);
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'LABEL_REVISION_NOTE',       sprintf('"%s, %s, %s"', lbltime, lbleditor, lblrev));
%KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'NOTE',                      '"... Cheops Reference Frame."');  % Include?!!
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'PRODUCER_FULL_NAME',        sprintf('"%s"', producerfullname));
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'PRODUCER_ID',               producershortname);
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'PRODUCER_INSTITUTION_NAME', '"SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"');
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'INSTRUMENT_HOST_ID',        'RO');
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'INSTRUMENT_HOST_NAME',      '"ROSETTA-ORBITER"');
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'INSTRUMENT_NAME',           '"ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"');
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'INSTRUMENT_TYPE',           '"PLASMA INSTRUMENT"');
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'INSTRUMENT_ID',             'RPCLAP');
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'TARGET_NAME',               sprintf('"%s"', targetfullname));
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'TARGET_TYPE',               sprintf('"%s"', targettype));
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'MISSION_ID',                'ROSETTA');
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'MISSION_NAME',              sprintf('"%s"', 'INTERNATIONAL ROSETTA MISSION'));
KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, 'MISSION_PHASE_NAME',        sprintf('"%s"', missionphase));
% ^EAICD_DESC = Filename of file under DOCUMENT directory (or subdirectory under it) in final PDS-compliant data set.
% NOT relative path, NOT data product name.
%KvlLblAll = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLblAll, '^EAICD_DESC',               sprintf('"%s"', EAICD_FILE_NAME));



%=======================================================================================
% Read kernel file - Use default file in Lapdog directory which the rest of Lapdog uses
%=======================================================================================
currentMFile = mfilename('fullpath');
[lapdogDir, basenameJunk, extJunk] = fileparts(currentMFile);
metakernelFile = fullfile(lapdogDir, 'metakernel_rosetta.txt');
if ~exist(metakernelFile, 'file')
    fprintf(1, 'Can not find kernel file "%s" (pwd="%s")', metakernelFile, pwd)
    % Call error too?
end
cspice_furnsh(metakernelFile);



%==========================================================
% Convert tabindex and an_tabindex into equivalent structs
%==========================================================
[stabindex] = createLBL.convert_tabindex(tabindex);
if generatingDeriv1
    % IMPLEMENTATION NOTE: Variable an_tabindex never defined during EDDER runs?
    [san_tabindex] = createLBL.convert_an_tabindex(an_tabindex);
end



%===============================================
%
% Create LBL files for (TAB files in) tabindex.
%
%===============================================
for i = 1:length(stabindex)
    try
        
        LblData = [];
        LblData.indentationLength = INDENTATION_LENGTH;
        %LblData.ConsistencyCheck.nTabColumns = stabindex(i).nColumns;
        % "LblData.ConsistencyCheck.nTabBytesPerRow" can not be set centrally here
        % since it is hardcoded for some TAB file types.
        
        %=========================================
        %
        % LBL file: Create header/key-value pairs
        %
        %=========================================
        
        tabFilename = stabindex(i).filename;
        iIndexFirst = stabindex(i).iIndexFirst;
        iIndexLast  = stabindex(i).iIndexLast;
        probeNbr    = index(iIndexFirst).probe;
        
        %--------------------------
        % Read the CALIB1 LBL file
        %--------------------------
        [KvlLblCalib1, Calib1LblSs] = createLBL.read_LBL_file(...
            index(iIndexFirst).lblfile, DONT_READ_HEADER_KEY_LIST);

        
        
        % NOTE: One can obtain a stop/ending SCT value from index(stabindex(i).iIndexLast).sct1str; too, but experience
        % shows that it is wrong on rare occasions (and in disagreement with the UTC value) for unknown reason.
        % Example: LAP_20150503_210047_525_I2L.LBL
        SPACECRAFT_CLOCK_STOP_COUNT = sprintf('%s/%s', index(iIndexLast).sct0str(2), obt2sct(stabindex(i).sctStop));
        
        KvlLbl = KvlLblAll;
        KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'START_TIME',                   Calib1LblSs.START_TIME);        % UTC start time
        KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'STOP_TIME',                    stabindex(i).utcStop(1:23));    % UTC stop  time
        KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'SPACECRAFT_CLOCK_START_COUNT', Calib1LblSs.SPACECRAFT_CLOCK_START_COUNT);
        KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'SPACECRAFT_CLOCK_STOP_COUNT',  SPACECRAFT_CLOCK_STOP_COUNT);

        KvlLbl = EJ_lapdog_shared.utils.KVPL.overwrite_values(KvlLblCalib1, KvlLbl, 'require preexisting keys');
        
        LblData.HeaderKvl = KvlLbl;
        clear   KvlLbl KvlLblCalib1
        
        
        
        %LblData.nTabFileRows = stabindex(i).nTabFileRows;
        
        isSweep       = (tabFilename(30)=='S');
        isSweepTable  = (tabFilename(28)=='B') && isSweep;
        isDensityMode = (tabFilename(28)=='I');
        isEFieldMode  = (tabFilename(28)=='V');
        %isHf          = (tabFilename(30)=='H');
        
        %=======================================
        %
        % LBL file: Create OBJECT TABLE section
        %
        %=======================================
        if (isSweep)
            
            %==============================
            % CASE: Sweep files (IxS, BxS)
            %==============================
            
            if (isSweepTable)
                % CASE: BxS
                
                LblData.OBJTABLE = [];
                %LblData.ConsistencyCheck.nTabBytesPerRow = 32;   % NOTE: HARDCODED! Can not trivially take value from creation of file and read from tabindex.
                LblData.OBJTABLE.DESCRIPTION = sprintf('%s Sweep step bias and time between each step', Calib1LblSs.OBJECT___TABLE{1}.DESCRIPTION);   % Remove ref. to old DESCRIPTION? (Ex: D_SWEEP_P1_RAW_16BIT_BIP)
                ocl = [];
                oc1 = struct('NAME', 'SWEEP_TIME',                     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'SECONDS');     % NOTE: Always ASCII_REAL, including for EDDER!!!
                oc2 = struct('NAME', sprintf('P%i_VOLTAGE', probeNbr),  DATA_DATA_TYPE{:},        'BYTES', 14, DATA_UNIT_VOLTAGE{:});
                if ~generatingDeriv1
                    oc1.DESCRIPTION = sprintf(['Elapsed time (s/c clock time) from first sweep measurement. ', ...
                        'Negative time refers to samples taken just before the actual sweep for technical reasons. ', ...
                        'A value of %g refers to that there was no such pre-sweep sample for any sweep in this command block.'], MISSING_CONSTANT);
                    oc1.MISSING_CONSTANT = MISSING_CONSTANT;
                    oc2.DESCRIPTION = sprintf('Bias voltage. A value of %g refers to that the bias voltage is unknown (all pre-sweep bias voltages).', MISSING_CONSTANT);
                    oc2.MISSING_CONSTANT = MISSING_CONSTANT;
                else
                    oc1.DESCRIPTION = 'Elapsed time (s/c clock time) from first sweep measurement.';
                    oc2.DESCRIPTION = VOLTAGE_BIAS_DESC;
                end                
                ocl{end+1} = oc1;
                ocl{end+1} = oc2;
                LblData.OBJTABLE.OBJCOL_list = ocl;
                clear   ocl

            else
                % CASE: IxS

                bxsTabFilename = tabFilename;
                bxsTabFilename(28) = 'B';

                LblData.OBJTABLE = [];
                %LblData.ConsistencyCheck.nTabBytesPerRow = stabindex(i).nTabBytesPerRow;
                LblData.OBJTABLE.DESCRIPTION = sprintf('%s', Calib1LblSs.OBJECT___TABLE{1}.DESCRIPTION);
                ocl = {};
                oc1 = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'Sweep start UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.');
                oc2 = struct('NAME',  'STOP_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION',  'Sweep stop UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.');
                oc3 = struct('NAME', 'START_TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION', 'Sweep start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
                oc4 = struct('NAME',  'STOP_TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION',  'Sweep stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
                if ~generatingDeriv1
                    oc1.DESCRIPTION = [oc1.DESCRIPTION, sprintf(' This effectively refers to the %g''th sample.', N_FINAL_PRESWEEP_SAMPLES+1)];
                    oc3.DESCRIPTION = [oc3.DESCRIPTION, sprintf(' This effectively refers to the %g''th sample.', N_FINAL_PRESWEEP_SAMPLES+1)];
                end
                ocl(end+1:end+4) = {oc1, oc2, oc3, oc4};                
                if generatingDeriv1
                    ocl{end+1} = struct('NAME', 'QUALITY', 'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (BEST) TO 999.');
                end
                % NOTE: The file referenced in column DESCRIPTION is expected to have the wrong name since files are renamed by other code
                % before delivery. The delivery code should already correct for this.
                oc = struct(...
                        'NAME', sprintf('P%i_SWEEP_CURRENT', probeNbr), DATA_DATA_TYPE{:}, 'ITEM_BYTES', 14, DATA_UNIT_CURRENT{:}, ...
                        'ITEMS', stabindex(i).nColumns - length(ocl), ...
                        'MISSING_CONSTANT', MISSING_CONSTANT);
                        
                if ~generatingDeriv1
                    oc.DESCRIPTION = sprintf([...
                            'One current for each of the voltage potential sweep steps described by %s. ', ...
                            'A value of %g refers to that no such sample was ever taken.'], bxsTabFilename, MISSING_CONSTANT);
                else
                    oc.DESCRIPTION = sprintf([...
                            'One current for each of the voltage potential sweep steps described by %s. ', ...
                            'Each current is the average over one or multiple measurements on a single potential step. ', ...
                            'A value of %g refers to ', ...
                            '(1) that the underlying set of samples contained at least one saturated value, and/or ', ...
                            '(2) there were no samples which were not disturbed by RPCMIP left to make an average over.'], bxsTabFilename, MISSING_CONSTANT);
                end                    
                ocl{end+1} = oc;
                
                LblData.OBJTABLE.OBJCOL_list = ocl;
                clear   ocl oc
            end

        else
            %============================================================
            % CASE: Anything EXCEPT sweep files (NOT [IB]xS) <==> [IV]x[HL]
            %============================================================

            LblData.OBJTABLE = [];
            LblData.OBJTABLE.DESCRIPTION = Calib1LblSs.OBJECT___TABLE{1}.DESCRIPTION;    % BUG: Possibly double quotation marks.
            
            %-----------------------------------------------------------------------------
            % HARD-CODED constants, to account for that these values are not set by other
            % Lapdog code as they are for other data products.
            %-----------------------------------------------------------------------------
%             if probeNbr ~= 3
%                 LblData.ConsistencyCheck.nTabColumns     =  5;
%                 LblData.ConsistencyCheck.nTabBytesPerRow = 83;
%             else
%                 LblData.ConsistencyCheck.nTabColumns     =  6;
%                 LblData.ConsistencyCheck.nTabBytesPerRow = 99;
%             end
%             if ~generatingDeriv1
%                 LblData.ConsistencyCheck.nTabColumns     = LblData.ConsistencyCheck.nTabColumns     - 1;
%                 LblData.ConsistencyCheck.nTabBytesPerRow = LblData.ConsistencyCheck.nTabBytesPerRow - 5;
%             end

            ocl = {};
            ocl{end+1} = struct('NAME', 'TIME_UTC', 'DATA_TYPE', 'TIME',       'UNIT', 'SECONDS', 'BYTES', 26, 'DESCRIPTION', 'UTC TIME');
            ocl{end+1} = struct('NAME', 'TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'UNIT', 'SECONDS', 'BYTES', 16, 'DESCRIPTION', 'SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)');
            if probeNbr ~=3
                % CASE: P1 or P2
                currentOc = struct('NAME', sprintf('P%i_CURRENT', probeNbr), DATA_DATA_TYPE{:}, DATA_UNIT_CURRENT{:}, 'BYTES', 14);
                voltageOc = struct('NAME', sprintf('P%i_VOLTAGE', probeNbr), DATA_DATA_TYPE{:}, DATA_UNIT_VOLTAGE{:}, 'BYTES', 14);
                if isDensityMode
                    currentOc.DESCRIPTION = CURRENT_MEAS_DESC;   % measured
                    voltageOc.DESCRIPTION = VOLTAGE_BIAS_DESC;   % bias
                    currentOc = createLBL.optionally_add_MISSING_CONSTANT(generatingDeriv1, MISSING_CONSTANT, currentOc, ...
                        sprintf('A value of %g means that the original sample was saturated.', MISSING_CONSTANT));   % NOTE: Modifies currentOc.
                else
                    currentOc.DESCRIPTION = CURRENT_BIAS_DESC;   % bias
                    voltageOc.DESCRIPTION = VOLTAGE_MEAS_DESC;   % measured
                    voltageOc = createLBL.optionally_add_MISSING_CONSTANT(generatingDeriv1, MISSING_CONSTANT, voltageOc, ...
                        sprintf('A value of %g means that the original sample was saturated.', MISSING_CONSTANT));   % NOTE: Modifies voltageOc.
                end
                ocl{end+1} = currentOc;
                ocl{end+1} = voltageOc;
                clear   currentOc voltageOc
            else
                % CASE: P3
                %error('This code segment has not yet been completed for P3. Can not create LBL file for "%s".', stabindex(i).path)
                if isDensityMode
                    % This case occurs at least on 2005-03-04 (EAR1). Appears to be the only day with V3x data for the
                    % entire mission. Appears to only happen for HF, but not LF.
                    oc1 = struct('NAME', 'P1_P2_CURRENT', DATA_DATA_TYPE{:}, DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', 'MEASURED CURRENT DIFFERENCE.');
                    oc2 = struct('NAME', 'P1_VOLTAGE',    DATA_DATA_TYPE{:}, DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', VOLTAGE_BIAS_DESC);
                    oc3 = struct('NAME', 'P2_VOLTAGE',    DATA_DATA_TYPE{:}, DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', VOLTAGE_BIAS_DESC);
                    
                    oc1 = createLBL.optionally_add_MISSING_CONSTANT(generatingDeriv1, MISSING_CONSTANT, oc1, ...
                        sprintf('A value of %g means that the original sample was saturated.', MISSING_CONSTANT));
                elseif isEFieldMode
                    % This case occurs at least on 2007-11-07 (EAR2), which appears to be the first day it occurs.
                    % This case does appear to occur for HF, but not LF.
                    oc1 = struct('NAME', 'P1_CURRENT',    DATA_DATA_TYPE{:}, DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', CURRENT_BIAS_DESC);
                    oc2 = struct('NAME', 'P2_CURRENT',    DATA_DATA_TYPE{:}, DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', CURRENT_BIAS_DESC);
                    oc3 = struct('NAME', 'P1_P2_VOLTAGE', DATA_DATA_TYPE{:}, DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', 'MEASURED VOLTAGE DIFFERENCE.');
                    
                    oc3 = createLBL.optionally_add_MISSING_CONSTANT(generatingDeriv1, MISSING_CONSTANT, oc3, ...
                        sprintf('A value of %g means that the original sample was saturated.', MISSING_CONSTANT));
                else
                    error('Error, bad mode identifier in an_tabindex{%i,2} = san_tabindex(%i).filename = "%s".', i, i, san_tabindex(i).filename);
                end
                ocl(end+1:end+3) = {oc1; oc2; oc3};
            end
            if generatingDeriv1
                ocl{end+1} = struct('NAME', 'QUALITY', 'DATA_TYPE', 'ASCII_INTEGER', 'UNIT', NO_ODL_UNIT, 'BYTES',  3, ...
                    'DESCRIPTION', 'QUALITY FACTOR FROM 000 (BEST) TO 999.');
            end
            
            LblData.OBJTABLE.OBJCOL_list = ocl;
            clear   ocl
        end
        
        createLBL.create_OBJTABLE_LBL_file(stabindex(i).path, LblData, LBL_HEADER_OPTIONS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
        clear   LblData
        
    catch exception
        createLBL.exception_message(exception, GENERATE_FILE_FAIL_POLICY);
        fprintf(1,'lapdog: Skipping LBL file (tabindex)index - Continuing\n');
    end    % try-catch
end    % for



%===============================================
%
% Create LBL files for (TAB files in) blockTAB.
%
%===============================================
for i = 1:length(blockTAB)
    
    LblData = [];
    LblData.indentationLength = INDENTATION_LENGTH;
    %LblData.ConsistencyCheck.nTabColumns     =  3;
    %LblData.ConsistencyCheck.nTabBytesPerRow = 55;                   % NOTE: HARDCODED! TODO: Fix.
    
    
    
    %==============================================
    %
    % LBL file: Create header/key-value pairs
    %
    % NOTE: Does NOT rely on reading old LBL file.
    %==============================================
    START_TIME = datestr(blockTAB(i).tmac0,   'yyyy-mm-ddT00:00:00.000');
    STOP_TIME  = datestr(blockTAB(i).tmac1+1, 'yyyy-mm-ddT00:00:00.000');   % Slightly unsafe (leap seconds, and in case macro block goes to or just after midnight).
    KvlLbl = KvlLblAll;
    KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'START_TIME',                   START_TIME);       % UTC start time
    KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'STOP_TIME',                    STOP_TIME);        % UTC stop time
    KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'SPACECRAFT_CLOCK_START_COUNT', cspice_sce2s(ROSETTA_NAIF_ID, cspice_str2et(START_TIME)));
    KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'SPACECRAFT_CLOCK_STOP_COUNT',  cspice_sce2s(ROSETTA_NAIF_ID, cspice_str2et(STOP_TIME)));
    LblData.HeaderKvl = KvlLbl;
    clear   KvlLbl
    
    
    
    %=======================================
    % LBL file: Create OBJECT TABLE section
    %=======================================
    
    %LblData.nTabFileRows = blockTAB(i).rcount;
    LblData.OBJTABLE = [];
    LblData.OBJTABLE.DESCRIPTION = 'BLOCKLIST DATA. START & STOP TIME OF MACRO BLOCK AND MACRO ID.';
    ocl = [];
    ocl{end+1} = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss');
    ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',  'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'LAST START TIME OF MACRO BLOCK FILE YYYY-MM-DD HH:MM:SS.sss');
    ocl{end+1} = struct('NAME', 'MACRO_ID',       'DATA_TYPE', 'CHARACTER', 'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'HEXADECIMAL MACRO IDENTIFICATION NUMBER.');
    LblData.OBJTABLE.OBJCOL_list = ocl;
    clear   ocl
    
    createLBL.create_OBJTABLE_LBL_file(blockTAB(i).blockfile, LblData, LBL_HEADER_OPTIONS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
    clear   LblData
    
end   % for



%===============================================
%
% Create LBL files for TAB files in an_tabindex
%
%===============================================
if generatingDeriv1
    for i = 1:length(san_tabindex)
        try
            tabLblInconsistencyPolicy = GENERAL_TAB_LBL_INCONSISTENCY_POLICY;   % Default value, unless overwritten for specific data file types.
            
            tabFilename = san_tabindex(i).filename;
            
            mode          = tabFilename(end-6:end-4);
            probeNbr      = index(san_tabindex(i).iIndex).probe;     % Probe number
            isDensityMode = (mode(1) == 'I');
            isEFieldMode  = (mode(1) == 'V');
            
            LblData = [];
            LblData.indentationLength = INDENTATION_LENGTH;
            %LblData.nTabFileRows = san_tabindex(i).nTabFileRows;
            %LblData.ConsistencyCheck.nTabBytesPerRow = san_tabindex(i).nTabBytesPerRow;
            %LblData.ConsistencyCheck.nTabColumns     = san_tabindex(i).nTabColumns;
            
            
            
            %=========================================
            %
            % LBL file: Create header/key-value pairs
            %
            %=========================================
            
            if strcmp(san_tabindex(i).dataType, 'best_estimates')
                %======================
                % CASE: Best estimates
                %======================
                
                %TAB_file_info = dir(san_tabindex(i).path);
                KvlLbl = KvlLblAll;
                KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'DESCRIPTION', 'Best estimates of physical quantities based on sweeps.');
                try
                    %===============================================================
                    % NOTE: createLBL.create_EST_LBL_header(...)
                    % sets certain LBL/ODL variables to handle collisions:
                    %    START_TIME / STOP_TIME,
                    %    SPACECRAFT_CLOCK_START_COUNT / SPACECRAFT_CLOCK_STOP_COUNT
                    %===============================================================
                    iIndexSrc         = san_tabindex(i).iIndex;
                    estTabPath        = san_tabindex(i).path;
                    probeNbrList      = [index(iIndexSrc).probe];
                    calib1LblPathList = {index(iIndexSrc).lblfile};
                    KvlLbl = createLBL.create_EST_LBL_header(estTabPath, calib1LblPathList, probeNbrList, KvlLbl, DONT_READ_HEADER_KEY_LIST);    % NOTE: Reads LBL file(s).
                    
                    LblData.HeaderKvl = KvlLbl;
                    clear   KvlLbl
                    
                catch exception
                    createLBL.exception_message(exception, GENERATE_FILE_FAIL_POLICY)
                    continue
                end

            else
                %===============================================
                % CASE: Any type of file EXCEPT best estimates.
                %===============================================
                
                iIndexFirst = stabindex(san_tabindex(i).iTabindex).iIndexFirst;
                iIndexLast  = stabindex(san_tabindex(i).iTabindex).iIndexLast;
        
                [KvlLblCalib1, Calib1LblSs] = createLBL.read_LBL_file(...
                    index(san_tabindex(i).iIndex).lblfile, DONT_READ_HEADER_KEY_LIST);
                
                
                % NOTE: One can obtain a stop/ending SCT value from index(stabindex(i).iIndexLast).sct1str; too, but experience
                % shows that it is wrong on rare occasions (and in disagreement with the UTC value) for unknown reason.
                % Example: LAP_20150503_210047_525_I2L.LBL
                %SPACECRAFT_CLOCK_STOP_COUNT = sprintf('%s/%s', index(iIndexLastXXX).sct0str(2), obt2sct(stabindexXXX(i).sctStop));
                SPACECRAFT_CLOCK_STOP_COUNT = sprintf('%s/%s', index(iIndexLast).sct0str(2), obt2sct(stabindex(san_tabindex(i).iTabindex).sctStop));
                
                % BUG: Does not work for 32S. Too narrow time limits.
                KvlLbl = KvlLblAll;
                KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'START_TIME',                   Calib1LblSs.START_TIME);                                % UTC start time
                KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'STOP_TIME',                    stabindex(san_tabindex(i).iTabindex).utcStop(1:23));    % UTC stop  time
                KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'SPACECRAFT_CLOCK_START_COUNT', Calib1LblSs.SPACECRAFT_CLOCK_START_COUNT);
                KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'SPACECRAFT_CLOCK_STOP_COUNT',  SPACECRAFT_CLOCK_STOP_COUNT);
                
                KvlLbl = EJ_lapdog_shared.utils.KVPL.overwrite_values(KvlLblCalib1, KvlLbl, 'require preexisting keys');
                
                
                
                LblData.HeaderKvl = KvlLbl;
                clear   KvlLbl KvlLblCalib1  % Calib1LblSs is used later (once).
                
            end   % if-else
            
            
            
            %=======================================
            %
            % LBL file: Create OBJECT TABLE section
            %
            %=======================================
            
            if strcmp(san_tabindex(i).dataType, 'downsample')   %%%%%%%% DOWNSAMPLED FILE %%%%%%%%%%%%%%%
                
                
                
                mcDescrAmendment = sprintf('A value of %g means that the underlying time period which was averaged over contained at least one saturated value.', MISSING_CONSTANT);
                
                LblData.OBJTABLE = [];
                samplingRateSecondsStr = tabFilename(end-10:end-9);
                % NOTE: Empirically, Calib1LblSs.DESCRIPTION is something technical, like "D_P1_TRNC_20_BIT_RAW_BIP". Keep?
                LblData.OBJTABLE.DESCRIPTION = sprintf('%s %s SECONDS DOWNSAMPLED', Calib1LblSs.DESCRIPTION, samplingRateSecondsStr);
                ocl = {};
                ocl{end+1} = struct('NAME', 'TIME_UTC', 'UNIT', 'SECONDS',   'BYTES', 23, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
                ocl{end+1} = struct('NAME', 'TIME_OBT', 'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)');
                
                oc1 = struct('NAME', sprintf('P%i_CURRENT',        probeNbr), DATA_UNIT_CURRENT{:}, 'BYTES', 14, DATA_DATA_TYPE{:}, 'DESCRIPTION', 'AVERAGED CURRENT.');
                oc2 = struct('NAME', sprintf('P%i_CURRENT_STDDEV', probeNbr), DATA_UNIT_CURRENT{:}, 'BYTES', 14, DATA_DATA_TYPE{:}, 'DESCRIPTION', 'CURRENT STANDARD DEVIATION.');
                oc3 = struct('NAME', sprintf('P%i_VOLTAGE',        probeNbr), DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, DATA_DATA_TYPE{:}, 'DESCRIPTION', 'AVERAGED VOLTAGE.');
                oc4 = struct('NAME', sprintf('P%i_VOLTAGE_STDDEV', probeNbr), DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, DATA_DATA_TYPE{:}, 'DESCRIPTION', 'VOLTAGE STANDARD DEVIATION.');
                oc1 = createLBL.optionally_add_MISSING_CONSTANT(isDensityMode, MISSING_CONSTANT, oc1 , mcDescrAmendment);
                oc2 = createLBL.optionally_add_MISSING_CONSTANT(isDensityMode, MISSING_CONSTANT, oc2 , mcDescrAmendment);
                oc3 = createLBL.optionally_add_MISSING_CONSTANT(isEFieldMode,  MISSING_CONSTANT, oc3 , mcDescrAmendment);
                oc4 = createLBL.optionally_add_MISSING_CONSTANT(isEFieldMode,  MISSING_CONSTANT, oc4 , mcDescrAmendment);
                ocl(end+1:end+4) = {oc1; oc2; oc3; oc4};
                
                ocl{end+1} = struct('NAME', 'QUALITY', 'BYTES', 3, 'DATA_TYPE', 'ASCII_INTEGER', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (BEST) TO 999.');
                
                LblData.OBJTABLE.OBJCOL_list = ocl;
                clear   ocl oc1 oc2 oc3 oc4
                
                
                
            elseif strcmp(san_tabindex(i).dataType, 'spectra')   %%%%%%%%%%%%%%%% SPECTRA FILE %%%%%%%%%%
                
                
                
                LblData.OBJTABLE = [];
                LblData.OBJTABLE.DESCRIPTION = sprintf('%s PSD SPECTRA OF HIGH FREQUENCY MEASUREMENT', mode);
                %---------------------------------------------
                ocl1 = {};
                ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_UTC', 'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',          'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
                ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_UTC',  'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',          'DESCRIPTION', 'SPECTRA STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
                ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_OBT', 'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',    'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)');
                ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_OBT',  'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',    'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)');
                ocl1{end+1} = struct('NAME', 'QUALITY',                'UNIT', NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_INTEGER', 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (BEST) TO 999.');
                %---------------------------------------------
                ocl2 = {};
                mcDescrAmendment = sprintf('A value of %g means that there was at least one saturated sample in the same time interval uninterrupted by RPCMIP disturbances.', MISSING_CONSTANT);
                if isDensityMode
                    
                    if probeNbr == 3
                        ocl2{end+1} = struct('NAME', 'P1_P2_CURRENT_MEAN',                  DATA_UNIT_CURRENT{:}, 'DESCRIPTION', ['MEASURED CURRENT DIFFERENCE MEAN. ', mcDescrAmendment], 'MISSING_CONSTANT', MISSING_CONSTANT);
                        ocl2{end+1} = struct('NAME', 'P1_VOLTAGE_MEAN',                     DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', VOLTAGE_BIAS_DESC);
                        ocl2{end+1} = struct('NAME', 'P2_VOLTAGE_MEAN',                     DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', VOLTAGE_BIAS_DESC);
                    else
                        ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', probeNbr), DATA_UNIT_CURRENT{:}, 'DESCRIPTION', ['MEASURED CURRENT MEAN. ', mcDescrAmendment], 'MISSING_CONSTANT', MISSING_CONSTANT);
                        ocl2{end+1} = struct('NAME', sprintf('P%i_VOLTAGE_MEAN', probeNbr), DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', VOLTAGE_BIAS_DESC);
                    end
                    PSD_DESCRIPTION = 'PSD CURRENT SPECTRUM';
                    PSD_UNIT        = 'NANOAMPERE^2/Hz';
                    
                elseif isEFieldMode
                    
                    if probeNbr == 3
                        ocl2{end+1} = struct('NAME', 'P1_CURRENT_MEAN',    DATA_UNIT_CURRENT{:}, 'DESCRIPTION', CURRENT_BIAS_DESC);
                        ocl2{end+1} = struct('NAME', 'P2_CURRENT_MEAN',    DATA_UNIT_CURRENT{:}, 'DESCRIPTION', CURRENT_BIAS_DESC);
                        ocl2{end+1} = struct('NAME', 'P1_P2_VOLTAGE_MEAN', DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', ['MEASURED VOLTAGE DIFFERENCE MEAN. ', mcDescrAmendment], 'MISSING_CONSTANT', MISSING_CONSTANT);
                    else
                        ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', probeNbr), DATA_UNIT_CURRENT{:}, 'DESCRIPTION',      'BIAS CURRENT MEAN');
                        ocl2{end+1} = struct('NAME', sprintf('P%i_VOLTAGE_MEAN', probeNbr), DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', ['MEASURED VOLTAGE MEAN', mcDescrAmendment], 'MISSING_CONSTANT', MISSING_CONSTANT);
                    end
                    PSD_DESCRIPTION = 'PSD VOLTAGE SPECTRUM';
                    PSD_UNIT        = 'VOLT^2/Hz';
                    
                else
                    error('Error, bad mode identifier in an_tabindex{%i,2} = san_tabindex(%i).filename = "%s".', i, i, san_tabindex(i).filename);
                end
                N_spectrum_cols = san_tabindex(i).nTabColumns - (length(ocl1) + length(ocl2));
                ocl2{end+1} = struct('NAME', sprintf('PSD_%s', mode), 'ITEMS', N_spectrum_cols, 'UNIT', PSD_UNIT, 'DESCRIPTION', PSD_DESCRIPTION);
                
                
                % For all columns: Set ITEM_BYTES/BYTES.
                for iOc = 1:length(ocl2)
                    if isfield(ocl2{iOc}, 'ITEMS')    ocl2{iOc}.ITEM_BYTES = 14;
                    else                              ocl2{iOc}.BYTES      = 14;
                    end
                    ocl2{iOc}.DATA_TYPE = 'ASCII_REAL';
                end
                
                LblData.OBJTABLE.OBJCOL_list = [ocl1, ocl2];
                clear   ocl1 ocl2
                
                
                
            elseif  strcmp(san_tabindex(i).dataType, 'frequency')    %%%%%%%%%%%% FREQUENCY FILE %%%%%%%%%
                
                
                
                psdTabFilename = strrep(san_tabindex(i).filename, 'FRQ', 'PSD');
                
                LblData.OBJTABLE = [];
                LblData.OBJTABLE.DESCRIPTION = 'FREQUENCY LIST OF PSD SPECTRA FILE';
                ocl = {};
                % NOTE/BUG: The file referenced in DESCRIPTION may have the wrong name since it is renamed by other code before delivery.
                ocl{end+1} = struct('NAME', 'FREQUENCY_LIST', 'ITEMS', san_tabindex(i).nTabColumns, 'UNIT', 'Hz', 'ITEM_BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', ...
                    'DESCRIPTION', sprintf('FREQUENCY LIST OF PSD SPECTRA FILE %s', psdTabFilename));
                LblData.OBJTABLE.OBJCOL_list = ocl;
                clear   ocl pdsname



            elseif  strcmp(san_tabindex(i).dataType, 'sweep')    %%%%%%%%%%%% SWEEP ANALYSIS FILE %%%%%%%%%



                LblData.OBJTABLE = [];
                LblData.OBJTABLE.DESCRIPTION = sprintf('MODEL FITTED ANALYSIS OF %s SWEEP FILE', stabindex(san_tabindex(i).iTabindex).filename);
                
                ocl1 = {};
                ocl1{end+1} = struct('NAME', 'START_TIME(UTC)', 'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Start time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
                ocl1{end+1} = struct('NAME', 'STOP_TIME(UTC)',  'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION',  'Stop time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
                ocl1{end+1} = struct('NAME', 'START_TIME_OBT',  'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Start time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
                ocl1{end+1} = struct('NAME', 'STOP_TIME_OBT',   'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION',  'Stop time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
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
                
                ocl2{end+1} = struct('NAME', 'Rsquared_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current.');   % New from commit f89c62b, 2015-01-09 or earlier.
                ocl2{end+1} = struct('NAME', 'Rsquared_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current.');   % New from commit f89c62b, 2015-01-09 or earlier.
                
                ocl2{end+1} = struct('NAME',       'Vbar',             'UNIT', ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');  % New from commit, aa33268 2015-03-26 or earlier.
                ocl2{end+1} = struct('NAME', 'sigma_Vbar',             'UNIT', ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');  % New from commit, aa33268 2015-03-26 or earlier.
                
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
                
                for iOc = 1:length(ocl2)
                    if ~isfield(ocl2{iOc}, 'BYTES')
                        ocl2{iOc}.BYTES = 14;
                    end
                    ocl2{iOc}.DATA_TYPE = 'ASCII_REAL';
                end
                LblData.OBJTABLE.OBJCOL_list = [ocl1, ocl2];
                clear   ocl1 ocl2
                
                tabLblInconsistencyPolicy = AxS_TAB_LBL_INCONSISTENCY_POLICY;   % NOTE: Different policy for A?S.LBL files.
                
                
                
            elseif  strcmp(san_tabindex(i).dataType,'best_estimates')    %%%%%%%%%%%% BEST ESTIMATES FILE %%%%%%%%%%%%
                
                
                
                LblData.OBJTABLE = [];
                LblData.OBJTABLE.DESCRIPTION = sprintf('BEST ESTIMATES OF PHYSICAL VALUES FROM MODEL FITTED ANALYSIS.');   % Bad description? To specific?
                ocl = [];
                ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
                ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
                ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
                ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
                ocl{end+1} = struct('NAME', 'QUALITY',            'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (BEST) TO 999.');
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
                LblData.OBJTABLE.OBJCOL_list = ocl;
                clear   ocl
                
                
                
            else
                
                error('Error, bad identifier in an_tabindex{%i,7} = san_tabindex(%i).dataType = "%s"',i, i, san_tabindex(i).dataType);
                
            end
            
            
            
            createLBL.create_OBJTABLE_LBL_file(san_tabindex(i).path, LblData, LBL_HEADER_OPTIONS, tabLblInconsistencyPolicy);
            clear   LblData   tabLblInconsistencyPolicy
            
            
            
        catch exception
            createLBL.exception_message(exception, GENERATE_FILE_FAIL_POLICY)
            fprintf(1,'lapdog: Skipping LBL file (an_tabindex) - Continuing\n');
        end    % try-catch
        
        
        
    end    % for
end    % if generatingDeriv1



%=================================================
%
% Create LBL files for files in der_struct (A1P).
%
%=================================================
if generatingDeriv1
    try
        global der_struct    % Global variable with info on A1P files.
        if ~isempty(der_struct)
            % IMPLEMENTATION NOTE: "der_struct" is only defined/set when running Lapdog DERIV. However, since it is a
            % global variable, it may survive from a Lapdog DERIV run until a edder_lapdog run. If so,
            % der_struct.file{iFile} will contain paths to a DERIV-data set. May thus lead to overwriting LBL files in
            % DERIV data set if called when writing EDDER data set!!! Therefore important to NOT RUN this code for
            % EDDER.
            createLBL.write_A1P(KvlLblAll, LBL_HEADER_OPTIONS, index, der_struct, NO_ODL_UNIT, MISSING_CONSTANT, INDENTATION_LENGTH, ...
                DONT_READ_HEADER_KEY_LIST, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
        end
        
    catch exception
        createLBL.exception_message(exception, GENERATE_FILE_FAIL_POLICY)
        fprintf(1,'\nlapdog:createLBL.write_A1P error message: %s\n',exception.message);
    end
end



cspice_unload(metakernelFile);
warning(prevWarningsSettings)
fprintf(1, '%s: %.0f s (elapsed wall time)\n', mfilename, etime(clock, executionBeginDateVec));

%end   % createLBL_main
