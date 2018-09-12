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
    %       Ex: Indentation
    %   PRO: Can have variables, shared over functions.
    %       CON/NOTE: Must instantiate instance?! Not static class?
    %
    % PROPOSAL: Quality value DESCRIPTION should connect to/mention the variable for which it applies.
    %
    % PROPOSAL: Different LABEL_REVISION_NOTE for different file types.
    % 
    % PROBLEM: How handle ITEMS?
    %   PROPOSAL: Read from TAB files and derive, assuming there is only one column with ITEMS.
    %       PROPOSAL: Do in file type-specific code. Does not need to be done in createLBL.create_OBJTABLE_LBL_file.
    %           CON: Would need to read TAB file twice: in createLBL.create_OBJTABLE_LBL_file and here.
    %
    % TODO: Replace "UNFINISHED" keyword values.
    % TODO: PDS Keywords from MB, DATA_SET_PARAMETER_NAME
    %   E.g. http://chury.sp.ph.ic.ac.uk/rpcwiki/Archiving/EnhancedArchivingTeleconMinutes2018x09x04
    % TODO: "Use the keyword CALIBRATION_SOURCE_ID with one or several values like the example below: CALIBRATION_SOURCE_ID = {“RPCLAP”,“RPCMIP”} "

    C = createLBL.constants();
    COTLF_SETTINGS = struct('indentationLength', C.INDENTATION_LENGTH);

    TAB_LBL_INCONSISTENCY_POLICY = 'error';
    C2.NO_ODL_UNIT               = [];
    C2.QFLAG1_DESCRIPTION = 'QUALITY FLAG CONSTRUCTED AS THE SUM OF MULTIPLE TERMS, DEPENDING ON WHAT QUALITY RELATED EFFECTS ARE PRESENT. FROM 00000 (BEST) TO 99999 (WORST).';    % For older quality flag (version "1").
    C2.QVALUE_DESCRIPTION = 'Quality value in the range 0 (worst) to 1 (best). Corresponds to goodness of fit or how well the model fits the data.';
    C2.MC_DESC            = sprintf(' A value of %e refers to that there is no value.', C.MISSING_CONSTANT);
    


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
            
            [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = createLBL.definitions.get_PHO_data(C, C2);
            
        elseif strcmp(msd2, 'USC')

            canClassifyTab = 1;

            %LblKvpl = KVPL_overwrite_add(LblKvpl, ...
            %    {'DATA_SET_PARAMETER_NAME', '{"SPACECRAFT POTENTIAL"}'; ...
            %    'CALIBRATION_SOURCE_ID',    '{"RPCLAP"}'});
            
            [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = createLBL.definitions.get_USC_data(C, C2);

        elseif strcmp(msd2, 'ASW')
            
            canClassifyTab = 1;

            % TODO-NEED-INFO: Add SPACECRAFT POTENTIAL for Photoelectron knee potential?
            %LblKvpl = KVPL_overwrite_add(LblKvpl, ...
            %    {'DATA_SET_PARAMETER_NAME', '{"ELECTRON DENSITY", "PHOTOSATURATION CURRENT", "ION BULK VELOCITY", "ELECTRON TEMPERATURE"}'; ...
            %    'CALIBRATION_SOURCE_ID',    '{"RPCLAP", "RPCMIP"}'});
            
            [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = createLBL.definitions.get_ASW_data(C, C2);

        elseif strcmp(msd2, 'NPL')
            
            canClassifyTab = 1;

            % MB states:
            % """"PLASMA DENSITY [cross-calibration from ion and electron density; in the label, put ELECTRON DENSITY,
            % ION DENSITY and PLASMA DENSITY]""""            
            % TODO-NEED-INFO: Use above?
            
            %LblKvpl = KVPL_overwrite_add(LblKvpl, {...
            %        'DATA_SET_PARAMETER_NAME', '{"ELECTRON_DENSITY", "ION DENSITY", "PLASMA DENSITY"}'; ...
            %        'CALIBRATION_SOURCE_ID',   '{"RPCLAP", "RPCMIP"}'});
            
            [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = createLBL.definitions.get_NLP_data(C, C2);
            
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

