%
% ~EXPERIMENTAL
%
%
% Create LBL file for a given Lapdog TAB file (i.e. ONE file that begins with "RPCLAP_").
%
% Derives type of Lbl file from the TAB filename.
% Initially intended for new TAB file types: PHO, USC, ASW, NPL.
%
%
% DESIGN/ARCHITECTURE INTENT
% ==========================
% Design intended to, possibly, in the future, make it possible reorganize createLBL.m to make it possible to easily
% re-generate LBL files without
% rerunning all of Lapdog (without having all of Lapdog's workspace variables available). Intended to make LBL
% generation independent on Lapdog-specific data structs (in particular blockTAB, index, tabindex, an_tabindex,
% der_struct). This should be useful for
% - manual testing (individual LBL files, individual TAB file types)
% - potentially running LBL file re-generation as a separate processing step.
% 
%
% ~EXPERIMENTAL
% =============
% Most/all of the hard-coded info in createLBL will possibly be moved to this function in the future.
% Hence the generic name.
%
%
% VARIABLE NAMING CONVENTIONS
% ===========================
% MSD    = Macro or Support type, and Data type. The two "fields" in LAP data CALIB2/DERIV2 filenames, e.g. PSD_V1H in
%          RPCLAP_20160930_000052_PSD_V1H.TAB.
%
%
% Initially created 2018-08-21 by Erik P G Johansson, IRF Uppsala.
%
function canClassifyTab = create_LBL_file(tabFilePath, OldLblHeaderKvpl)
    % NOTE: Generalizing to EDITED1/CALIB1 data types requires distinguising EDDER / DERIV1.
    % PROPOSAL: Remake into class
    %   PRO: Can have constants, shared over functions.
    %       Ex: Inden
    %   PRO: Can have variables, shared over functions.
    %       CON/NOTE: Must instantiate instance?! Not static class?
    %
    % PROPOSAL: Quality value DESCRIPTION should connect to/mention the variable for which it applies.
    %
    % PROPOSAL: Different LABEL_REVISION_NOTE for different file types.
    %
    % TODO: Update for new data files (4).
    % TODO: Replace "UNFINISHED" keyword values.
    % TODO: PDS Keywords from MB, DATA_SET_PARAMETER_NAME
    %   E.g. http://chury.sp.ph.ic.ac.uk/rpcwiki/Archiving/EnhancedArchivingTeleconMinutes2018x09x04
    % TODO: "Use the keyword CALIBRATION_SOURCE_ID with one or several values like the example below: CALIBRATION_SOURCE_ID = {“RPCLAP”,“RPCMIP”} "

    C = createLBL.constants();
    COTLF_SETTINGS = struct('indentationLength', C.INDENTATION_LENGTH);

    TAB_LBL_INCONSISTENCY_POLICY = 'error';
    NO_ODL_UNIT                  = [];
    QFLAG1_DESCRIPTION = 'QUALITY FLAG CONSTRUCTED AS THE SUM OF MULTIPLE TERMS, DEPENDING ON WHAT QUALITY RELATED EFFECTS ARE PRESENT. FROM 00000 (BEST) TO 99999 (WORST).';    % For older quality flag (version "1").
    QVALUE_DESCRIPTION = 'Quality value in the range 0 (worst) to 1 (best). Corresponds to goodness of fit or how well the model fits the data.';
    MC_DESC            = sprintf(' A value of %e refers to that there is no value.', C.MISSING_CONSTANT);
    


    % TEMPORARY source constants.
    lbltime   = '2018-08-03';  % Label revision time
    lbleditor = 'EJ';
    lblrev    = 'Misc. descriptions clean-up';
    LblAllKvpl = C.get_LblAllKvpl(sprintf('%s, %s, %s', lbltime, lbleditor, lblrev));
    LblKvpl = EJ_lapdog_shared.utils.KVPL.overwrite_values(OldLblHeaderKvpl, LblAllKvpl, 'require preexisting keys');
    
    
    
    [parentDir, fileBasename, fileExt] = fileparts(tabFilePath);
    tabFilename = [fileBasename, fileExt];
    
    if ~isempty(regexp(tabFilename, '^RPCLAP_20[0-9]{6}_[0-9]{6}_[a-zA-Z0-9]{3}_[A-Z][A-Z1-3][A-Z]\.TAB$', 'once'))
        
        % Ex: RPCLAP_20050301_001317_301_A2S.LBL
        % Ex: RPCLAP_20050303_124725_FRQ_I1H.LBL        
        % NOTE: Letters in macro numbers (hex) are lower case, but the "macro" can also be 32S, PSD, FRQ i.e. upper case letters.
        % Therefore, the regex has to allow both upper and lower case.
        
        % NOTE: strread throws exception if the pattern does not match.
        [dateJunk, timeStr, macroOrSupportType, dataType] = strread(tabFilename, 'RPCLAP_%[^_]_%[^_]_%[^_]_%[^.].TAB');
        msd1 = macroOrSupportType{1};
        msd2 = dataType{1};
        msd = [msd1, '_', msd2];

        LblData = [];
        LblData.OBJTABLE = [];
            
        if     strcmp(timeStr, '000000') && strcmp(msd, '60M_PHO')

            canClassifyTab = 1;
            
            %LblKvpl = KVPL_overwrite_add(LblKvpl, ...
            %    {'DATA_SET_PARAMETER_NAME', '{"PHOTOSATURATION CURRENT"}'; ...
            %    'CALIBRATION_SOURCE_ID',    '{"RPCLAP"}'});
            
            LblData.OBJTABLE.DESCRIPTION = 'Photosaturation current derived collectively from multiple sweeps (not just an average of multiple estimates).';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',            'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME', 'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',            'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'I_PH0',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'AMPERE',    'DESCRIPTION', ...
                ['Photosaturation current derived collectively from multiple sweeps (not just an average of multiple estimates).', MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'I_PH0_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',        'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QFLAG1_DESCRIPTION);
            LblData.OBJTABLE.OBJCOL_list = ocl;

        elseif strcmp(msd2, 'USC')

            canClassifyTab = 1;

            %LblKvpl = KVPL_overwrite_add(LblKvpl, ...
            %    {'DATA_SET_PARAMETER_NAME', '{"SPACECRAFT POTENTIAL"}'; ...
            %    'CALIBRATION_SOURCE_ID',    '{"RPCLAP"}'});
            
            LblData.OBJTABLE.DESCRIPTION = 'Proxy for spacecraft potential, derived from either (1) zero current crossing in sweep, or (2) floating potential measurement (downsampled). Time interval can thus refer to either sweep or individual sample.';
            
            ocl = [];
            % NOTE: UTC with 3 decimals for unknown reason.
            ocl{end+1} = struct('NAME', 'TIME_UTC',                     'DATA_TYPE', 'TIME',          'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFF. Middle point for sweeps.',                              'useFor', {{'START_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',                     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point). Middle point for sweeps.', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT', 'STOP_TIME_from_OBT'}});
            ocl{end+1} = struct('NAME', 'V_SC_POT_PROXY',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',      'DESCRIPTION', ...
                ['Proxy for spacecraft potential derived from either (1) photoelectron knee in sweep, or (2) floating potential measurement (downsampled), depending on available data.', MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_SC_POT_PROXY_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',                 'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QFLAG1_DESCRIPTION);
            LblData.OBJTABLE.OBJCOL_list = ocl;
            
        elseif strcmp(msd2, 'ASW')
            
            canClassifyTab = 1;

            % TODO-NEED-INFO: Add SPACECRAFT POTENTIAL for Photoelectron knee potential?
            %LblKvpl = KVPL_overwrite_add(LblKvpl, ...
            %    {'DATA_SET_PARAMETER_NAME', '{"ELECTRON DENSITY", "PHOTOSATURATION CURRENT", "ION BULK VELOCITY", "ELECTRON TEMPERATURE"}'; ...
            %    'CALIBRATION_SOURCE_ID',    '{"RPCLAP", "RPCMIP"}'});
            
            % ASW = Analyzed sweep parameters
            LblData.OBJTABLE.DESCRIPTION = 'Miscellaneous physical high-level quantities derived from individual sweeps.';

            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Start UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME'}});
            ocl{end+1} = struct('NAME',  'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION',  'Stop UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT'}});
            ocl{end+1} = struct('NAME',  'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION',  'Stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'N_E',                           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'cm**-3',    'DESCRIPTION', ['Electron density derived from individual sweep.', MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'N_E_QUALITY_VALUE',             'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'I_PH0',                         'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'AMPERE',    'DESCRIPTION', ...
                ['Photosaturation current derived from individual sweep.', MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'I_PH0_QUALITY_VALUE',           'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'V_ION_BULK_XCAL',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'm/s',       ...
                'DESCRIPTION', ['Ion bulk speed derived from individual sweep (speed; always non-negative scalar). Cross-calibrated with RPCMIP.', MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_ION_BULK_XCAL_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'T_E',                           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'eV',        ...
                'DESCRIPTION', ['Electron temperature derived from exponential part of sweep.', MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'T_E_QUALITY_VALUE',             'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'T_E_XCAL',                      'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'eV',        ...
                'DESCRIPTION', ['Electron temperature, derived by using the linear part of the electron current of the sweep, and density measurement from RPCMIP.', MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'T_E_XCAL_QUALITY_VALUE',        'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'V_PH_KNEE',                     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',      ...
                'DESCRIPTION', ['Photoelectron knee potential.', MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_PH_KNEE_QUALITY_VALUE',       'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',                  'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QFLAG1_DESCRIPTION);
            LblData.OBJTABLE.OBJCOL_list = ocl;

        elseif strcmp(msd2, 'NPL')
            
            canClassifyTab = 1;

            % MB states:
            % """"PLASMA DENSITY [cross-calibration from ion and electron density; in the label, put ELECTRON DENSITY,
            % ION DENSITY and PLASMA DENSITY]""""            
            % TODO-NEED-INFO: Use above?
            
            %LblKvpl = KVPL_overwrite_add(LblKvpl, {...
            %        'DATA_SET_PARAMETER_NAME', '{"ELECTRON_DENSITY", "ION DENSITY", "PLASMA DENSITY"}'; ...
            %        'CALIBRATION_SOURCE_ID',   '{"RPCLAP", "RPCMIP"}'});
            
            LblData.OBJTABLE.DESCRIPTION = 'Plasma density derived from individual fix-bias density mode (current) measurements.';

            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',       'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME', 'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',       'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'N_PL',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'cm**-3',    'DESCRIPTION', ...
                ['Plasma density derived from individual fix-bias density mode (current) measurements. Parameter derived from low time resolution estimates of the plasma density from either RPCLAP or RPCMIP (changes over time).', MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT); 
            ocl{end+1} = struct('NAME', 'QUALITY_VALUE',  'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',   'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', QFLAG1_DESCRIPTION);
            LblData.OBJTABLE.OBJCOL_list = ocl;
            
        else 
            canClassifyTab = 0;
        end
    else
        canClassifyTab = 0;
        
    end
    
    
    
    if canClassifyTab
        LblData.HeaderKvl = LblKvpl;
        createLBL.create_OBJTABLE_LBL_file(tabFilePath, LblData, C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, TAB_LBL_INCONSISTENCY_POLICY);
    else
        %error('Can not identify type of TAB file: "%s"', tabFilePath)
        ;
    end
    
end



% Convenience function for shortening & clarifying code.
function Kvpl = KVPL_overwrite_add(Kvpl, kvplContentCellArray)
    Kvpl = EJ_lapdog_shared.utils.KVPL.overwrite_values(Kvpl, ...
        EJ_lapdog_shared.utils.KVPL.create(kvplContentCellArray), ...
        'add if not preexisting');
end
