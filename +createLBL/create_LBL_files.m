%
% Create .LBL files for all .TAB files.
% This function is intended to (1) be the "interface" between Lapdog variables, and (2) not contain (or minimize) the
% amount of configuration code of LBL files.
%
%
% ARGUMENTS
% =========
% data : Struct containing fields, mostly corresponding to the needed Lapdog variables, including global variables.
%
%
% VARIABLE NAMING CONVENTIONS
% ===========================
% KVPL : Key-Value Pair List (a class)
% IDP  : Input Dataset Pds (pds s/w, as opposed to Lapdog)
% LHT  : Label Header Timestamps (START_TIME etc)
% PLKS : Pds (s/w) Label Keyword Source file
%
%
% CONVENTIONS
% ===========
% This code should not use global variables. createLBL.m does it instead, and submits the needed values.
%

%===================================================================================================
% PROPOSAL: Stop/disable generating AxS, EST, A1P LBL files.
%   PRO: Will never be used (but lead to work).
%   PRO: AxS are not up-to-date and generate errors/warnings which are typically ignored.
%
% PROPOSAL: Write function for obtaining number of columns in TAB file.
%   NOTE: Bad for combining TAB file assertions and extracting values from TAB file.
%   PRO: Can use for obtaining number of IxS columns ==> Does not need corresponding tabindex field.
%       PRO: Makes code more reliable.
%   --
%   PRO: Can use as assertion in create_OBJTABLE_LBL_file.
%   PRO: Can simultaneously obtain nBytesPerRow and derive nRows (with file size).
%       ==> Somewhat better TAB file assertion in create_OBJTABLE_LBL_file than using just column descriptions.
%   CON: Slower.
%   CON: Slightly unsafe. Would need to search for strings ', '.
%
% PROPOSAL: Make code independent of Stabindex.utcStop, Stabindex.sctStop by just using
%           data.index(Stabindex.iIndexFirst/Last) instead.
%   PRO: Makes code more reliable.
%   TODO-NEED-INFO: Need info if correct understanding of index timestamps.
%
% PROPOSAL: Read STOP_TIME from the last CALIB1/EDITED1 file, just like IdpLblSs does.
% PROPOSAL: Read first & LAST start & stop timestamps from EDITED1/CALIB1 LBL files using centralized function(s).
%   NOTE: Would be implemented in the createLBL.definitions methods.
%
% PROPOSAL: Function for converting Lapdog's TAB file structs to standard structs (most cases, if not all).
%   PRO: Can take care of adjusting paths to always use the current dataset path as root.
%   PRO: Can be submitted to one function to handle all iterations, one filetype at a time(?).
%   CON: Conversions and structs vary.
%       tabindex: IBxS, IVxHL
%           Uses IDP LBL files for start timestamps, IDP LBL files for SPACECRAFT_CLOCK_STOP_COUNT, Stabindex for STOP_TIME.
%       blockTAB: BLK
%           Uses UTC midnight (slightly incorrect?) for timestamps.
%       an_tabindex: EST
%           ALL: Has .dataType field for separating xxD, PSD+FRQ, AxS, EST
%           EST:            Uses createLBL.create_EST_prel_LBL_header to initialize header KVPL (mixing timestamps with other keywords).
%           ALL except EST: IDP LBL for all timestamps.
%       der_struct: A1P
%           Struct for timestamps.
%       ASW_tabindex: ASW
%           Struct for timestamps.
%       usc_tabindex: USC
%           Struct for timestamps.
%       PHO_tabindex: PHO
%           Struct has no timestamps (yet; later maybe). Timestamps set from columns.
%   CON: Several things are different for different loops.
%       Ex: Calls to different definitions.* column description functions. Calls also have different arguments.
%       Ex: Creation of filenames (parses old filenames)
%           Ex: IxS: BxS from IxS so that can mention file in PDS description.
%           Ex: PSD: FRQ from PSD so that can mention file in PDS description.
%       Ex: Take action depending on San_tabindex(i).dataType
%       Ex: Different TAB-LBL inconsistency policy.
%       Ex: Parse filenames:
%           IVxD, sampling rate seconds
%           CON: Could replace with assertions.
%
% PROPOSAL: Print/log number of LBL files of each type.
%   PRO: Can see which parts of code that is tested and which is not.
%
% PROPOSAL: Better name for LblDefs. ~LblCreator? ~LblFactory?!
%
% PROPOSAL: Have block lists use TAB columns for start & stop timestamps.
%===================================================================================================

function create_LBL_files(data)
    
    % ASSERTIONS
    EJ_lapdog_shared.utils.assert.struct(data, {...
        'ldDatasetPath', 'pdDatasetPath', 'metakernel', 'C', 'failFastDebugMode', 'generatingDeriv1', ...
        'index', 'blockTAB', 'tabindex', 'an_tabindex', 'A1P_tabindex', 'PHO_tabindex', 'USC_tabindex', 'ASW_tabindex'})
    if isnan(data.failFastDebugMode)    % Check if field set to temporary value.
        error('Illegal argument data.failFastDebugMode=%g', data.failFastDebugMode)
    end



    executionBeginDateVec = clock;    % NOTE: NOT a scalar (e.g. number of seconds), but [year month day hour minute seconds].
    prevWarningsSettings = warning('query');
    warning('on', 'all')
    

    
    COTLF_SETTINGS = struct('indentationLength', data.C.ODL_INDENTATION_LENGTH);
    
    
    
    % Set policy for errors/warning
    % (1) when failing to generate a file,
    % (2) when LBL files are (believed to be) inconsistent with TAB files.
    if data.failFastDebugMode
        GENERATE_FILE_FAIL_POLICY = 'message+stack trace';
        
        GENERAL_TAB_LBL_INCONSISTENCY_POLICY = 'error';
        %AxS_TAB_LBL_INCONSISTENCY_POLICY     = 'warning';
        AxS_TAB_LBL_INCONSISTENCY_POLICY     = 'nothing';
        %ASW_TAB_LBL_INCONSISTENCY_POLICY     = 'nothing';
        ASW_TAB_LBL_INCONSISTENCY_POLICY     = 'error';
    else
        GENERATE_FILE_FAIL_POLICY = 'message';
        %GENERATE_FILE_FAIL_POLICY = 'nothing';    % Somewhat misleading. Something may still be printed.
        
        GENERAL_TAB_LBL_INCONSISTENCY_POLICY = 'warning';
        AxS_TAB_LBL_INCONSISTENCY_POLICY     = 'nothing';
        ASW_TAB_LBL_INCONSISTENCY_POLICY     = 'nothing';
    end
    
    
    
    LblDefs = createLBL.definitions(...
        data.generatingDeriv1, ...
        data.C.MISSING_CONSTANT, ...
        data.C.N_FINAL_PRESWEEP_SAMPLES, ...
        data.C.ODL_INDENTATION_LENGTH, ...
        data.C.get_LblHeaderAllKvpl());
    


    cspice_furnsh(data.metakernel);



    %================================================================================================================
    % Convert tabindex and an_tabindex into equivalent structs
    %================================================================================================================
    Stabindex    = createLBL.convert_tabindex(data.tabindex);         % Can handle arbitrarily sized empty tabindex.
    San_tabindex = createLBL.convert_an_tabindex(data.an_tabindex);   % Can handle arbitrarily sized empty an_tabindex.
    
    
    
    %===============================================================
    %
    % Create LBL files for (TAB files in) tabindex: IBxS, IVxHL
    %
    %===============================================================
    createLblFileFuncPtr = @(LblData, tabFile) (createLBL.create_OBJTABLE_LBL_file(...
        convert_LD_TAB_path(data.ldDatasetPath, tabFile), ...
        LblData, data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY));
    create_tabindex_files(createLblFileFuncPtr, data.pdDatasetPath, data.index, Stabindex, GENERATE_FILE_FAIL_POLICY, ...
        LblDefs)
    
    
    
    %===============================================
    %
    % Create LBL files for (TAB files in) blockTAB.
    %
    %===============================================
    for i = 1:length(data.blockTAB)
                
        % NOTE: Does NOT rely on reading old LBL file.
        % BUG?/NOTE: Can not find any block list files with command block beginning before/ending after midnight (due to
        % "rounding") but should they not? /2018-10-19
        START_TIME = datestr(data.blockTAB(i).tmac0,   'yyyy-mm-ddT00:00:00.000');
        STOP_TIME  = datestr(data.blockTAB(i).tmac1+1, 'yyyy-mm-ddT00:00:00.000');   % Slightly unsafe (leap seconds, and in case macro block goes to or just after midnight).
        LhtKvpl = get_timestamps_KVPL(...
            START_TIME, ...
            STOP_TIME, ...
            cspice_sce2s(data.C.ROSETTA_NAIF_ID, cspice_str2et(START_TIME)), ...
            cspice_sce2s(data.C.ROSETTA_NAIF_ID, cspice_str2et(STOP_TIME)));

        %=======================================
        % LBL file: Create OBJECT TABLE section
        %=======================================
        LblData = LblDefs.get_BLKLIST_data(LhtKvpl);

        createLBL.create_OBJTABLE_LBL_file(...
            convert_LD_TAB_path(data.ldDatasetPath, data.blockTAB(i).blockfile), ...
            LblData, data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
        
        clear   START_TIME   STOP_TIME   LhtKvpl   LblData
    end   % for
    
    
    
    if data.generatingDeriv1
        %===============================================
        %
        % Create LBL files for TAB files in an_tabindex
        %
        %===============================================
        createLblFileFuncPtr = @(LblData, tabFile, tabLblInconsistencyPolicy) (createLBL.create_OBJTABLE_LBL_file(...
                convert_LD_TAB_path(data.ldDatasetPath, tabFile), ...
                LblData, data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, tabLblInconsistencyPolicy));
        create_antabindex_files(createLblFileFuncPtr, data.ldDatasetPath, data.pdDatasetPath, data.index, Stabindex, San_tabindex, ...
            LblDefs, GENERATE_FILE_FAIL_POLICY, GENERAL_TAB_LBL_INCONSISTENCY_POLICY, AxS_TAB_LBL_INCONSISTENCY_POLICY)

        
        
        %=============================================================
        %
        % Create LBL files for files in der_struct/A1P_tabindex (A1P)
        %
        %=============================================================
        if ~isempty(data.A1P_tabindex)
            % IMPLEMENTATION NOTE: "der_struct"/A1P_tabindex is only defined/set when running Lapdog (DERIV1). However, since it is a
            % global variable, it may survive from a Lapdog DERIV1 run until a edder_lapdog run. If so,
            % data.A1P_tabindex.file{iFile} will contain paths to a DERIV1-data set. May thus lead to overwriting LBL files in
            % DERIV1 data set if called when writing EDDER data set!!! Therefore important to NOT RUN this code for
            % EDDER.
            
            for iFile = 1:numel(data.A1P_tabindex.file)
                try
                    startStopTimes = data.A1P_tabindex.timing(iFile, :);   % NOTE: Stores UTC+SCCS.
                    LhtKvpl        = get_timestamps_KVPL(...
                        startStopTimes{1}, ...
                        startStopTimes{2}, ...
                        startStopTimes{3}, ...
                        startStopTimes{4});
                    
                    iIndex  = data.A1P_tabindex.firstind(iFile);
                    LblData = LblDefs.get_A1P_data(LhtKvpl, data.index(iIndex).lblfile);
                    
                    createLBL.create_OBJTABLE_LBL_file(...
                        convert_LD_TAB_path(data.ldDatasetPath, data.A1P_tabindex.file{iFile}), ...
                        LblData, data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
                    
                    clear   startStopTimes   LhtKvpl   iIndex   LblData                    
                catch Exception
                    createLBL.exception_message(Exception, GENERATE_FILE_FAIL_POLICY)
                    fprintf(1,'\nlapdog:A1P LBL failed. Error message: %s\n', Exception.message);
                end
            end
        end
        
        
        
        %==========================
        %
        % Create LBL files for ASW
        %
        %==========================
        if ~isempty(data.ASW_tabindex)
            for iFile = 1:numel(data.ASW_tabindex)

                startStopTimes = data.ASW_tabindex(iFile).timing;    % NOTE: Stores UTC+OBT.
                LhtKvpl = get_timestamps_KVPL(...
                    startStopTimes{1}, ...
                    startStopTimes{2}, ...
                    obt2sctrc(str2double(startStopTimes{3})), ...
                    obt2sctrc(str2double(startStopTimes{4})));

                LblData = LblDefs.get_ASW_data(...
                    LhtKvpl, ...
                    convert_PD_TAB_path(data.pdDatasetPath, data.index(data.USC_tabindex(iFile).first_index).lblfile));
                
                createLBL.create_OBJTABLE_LBL_file(...
                    convert_LD_TAB_path(data.ldDatasetPath, data.ASW_tabindex(iFile).fname), ...
                    LblData, data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, ASW_TAB_LBL_INCONSISTENCY_POLICY);
                
                clear   startStopTimes   LhtKvpl   LblData
            end
        end
        
        %==========================
        %
        % Create LBL files for USC
        %
        %==========================
        if ~isempty(data.USC_tabindex)
            for iFile = 1:numel(data.USC_tabindex)
                
                startStopTimes = data.USC_tabindex(iFile).timing;    % NOTE: Stores UTC+OBT.
                LhtKvpl = get_timestamps_KVPL(...
                    startStopTimes{1}, ...
                    startStopTimes{2}, ...
                    obt2sctrc(str2double(startStopTimes{3})), ...
                    obt2sctrc(str2double(startStopTimes{4})));

                LblData = LblDefs.get_USC_data(...
                    LhtKvpl, ...
                    convert_PD_TAB_path(data.pdDatasetPath, data.index(data.USC_tabindex(iFile).first_index).lblfile));
                
                createLBL.create_OBJTABLE_LBL_file(...
                    convert_LD_TAB_path(data.ldDatasetPath, data.USC_tabindex(iFile).fname), ...
                    LblData, data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
                
                clear   startStopTimes   LhtKvpl   LblData
            end
        end
        
        %==========================
        %
        % Create LBL files for PHO
        %
        %==========================
        % NOTE: PHO_tabindex has been observed to contain the same file multiple times (commit 9648939), test phase TDDG. Likely
        % because entries are re-added for every run.
        if ~isempty(data.PHO_tabindex)
            try
                for iFile = 1:numel(data.PHO_tabindex)
                    % data.PHO_tabindex(iFile).timing;    % ~BUG: Not implemented/never assigned (yet).
                    
                    % IMPLEMENTATION NOTE: TEMPORARY SOLUTION. Timestamps are set via the columns, not here. Submitting
                    % empty values forces the rest of the code to overwrite the values though (assertions are triggered
                    % otherwise).
                    LhtKvpl = get_timestamps_KVPL([], [], [], []);

                    LblData = LblDefs.get_PHO_data(LhtKvpl);

                    createLBL.create_OBJTABLE_LBL_file(...
                        convert_LD_TAB_path(data.ldDatasetPath, data.PHO_tabindex(iFile).fname), ...
                        LblData, data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
                    
                    clear   LhtKvpl   LblData
                end
            catch Exception
                createLBL.exception_message(Exception, GENERATE_FILE_FAIL_POLICY);
                fprintf(1,'Skipping LBL file (tabindex)index - Continuing\n');
            end
        end
        
        %==============================================================
        %
        % Create LBL files for NPL files. (DERIV1 only)
        %
        %==============================================================
        % TEMPORARY SOLUTION.
        % DELETE?!! Still creates NPL LBL files from found TAB files.
        createLBL.create_LBL_L5_sample_types(data.ldDatasetPath)
    end
    
    
    
    cspice_unload(data.metakernel);
    warning(prevWarningsSettings)
    fprintf(1, '%s: %.0f s (elapsed wall time)\n', mfilename, etime(clock, executionBeginDateVec));

end



function create_tabindex_files(createLblFileFuncPtr, pdDatasetPath, index, Stabindex, generateFileFailPolicy, LblDefs)
    
    for i = 1:length(Stabindex)
        try
            
            %=========================================
            %
            % LBL file: Create header/key-value pairs
            %
            %=========================================
            
            tabFilename = Stabindex(i).filename;
            iIndexFirst = Stabindex(i).iIndexFirst;
            iIndexLast  = Stabindex(i).iIndexLast;     % PROPOSAL: Use for reading CALIB1/EDITED1 file for obtaining end timestamps?
            probeNbr    = index(iIndexFirst).probe;
            
            isSweep       = (tabFilename(30)=='S');
            isSweepTable  = (tabFilename(28)=='B') && isSweep;
            isDensityMode = (tabFilename(28)=='I');
            %isEFieldMode  = (tabFilename(28)=='V');
            isLf          = (tabFilename(30)=='L');
            
            % NOTE: One can obtain a stop/ending SCT value from index(Stabindex(i).iIndexLast).sct1str; too, but experience
            % shows that it is wrong on rare occasions (and in disagreement with the UTC value) for unknown reason.
            % Therefore not using it. LBL header start timestamps are set later.
            % Example: LAP_20150503_210047_525_I2L.LBL
            firstPlksSs = convert_PD_TAB_path(pdDatasetPath, index(iIndexFirst).lblfile);
            LhtKvpl = get_timestamps_KVPL(...
                [], ...
                Stabindex(i).utcStop, ...
                [], ...
                obt2sctrc(Stabindex(i).sctStop));


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
                    ixsTabFilename     = tabFilename;
                    ixsTabFilename(28) = 'S';
                    LblData = LblDefs.get_BxS_data(LhtKvpl, firstPlksSs, ...
                        probeNbr, ixsTabFilename);
                else
                    % CASE: IxS                    
                    bxsTabFilename     = tabFilename;
                    bxsTabFilename(28) = 'B';
                    LblData = LblDefs.get_IxS_data(LhtKvpl, firstPlksSs, ...
                        probeNbr, bxsTabFilename, Stabindex(i).nColumns);
                end
                
            else
                %===============================================================
                % CASE: Anything EXCEPT sweep files (NOT [IB]xS) <==> [IV]x[HL]
                %===============================================================
                LblData = LblDefs.get_IVxHL_data(LhtKvpl, firstPlksSs, ...
                    isDensityMode, probeNbr, isLf);
            end
            
            %createLBL.create_OBJTABLE_LBL_file(...
            %    convert_LD_TAB_path(data.ldDatasetPath, Stabindex(i).path), ...
            %    LblData, data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
            createLblFileFuncPtr(LblData, Stabindex(i).path);
            
            clear   firstPlksSs   LhtKvpl   LblData
            
        catch Exception
            createLBL.exception_message(Exception, generateFileFailPolicy);
            fprintf(1,'Skipping LBL file (tabindex)index - Continuing\n');
        end
    end    % for
end



function create_antabindex_files(createLblFileFuncPtr, ldDatasetPath, pdDatasetPath, index, Stabindex, San_tabindex, LblDefs, ...
        GENERATE_FILE_FAIL_POLICY, GENERAL_TAB_LBL_INCONSISTENCY_POLICY, AxS_TAB_LBL_INCONSISTENCY_POLICY)
    
    for i = 1:length(San_tabindex)
        try
            tabLblInconsistencyPolicy = GENERAL_TAB_LBL_INCONSISTENCY_POLICY;   % Default value, unless overwritten for specific data file types.
            
            tabFilename   = San_tabindex(i).filename;
            mode          = tabFilename(end-6:end-4);
            probeNbr      = index(San_tabindex(i).iIndex).probe;     % Probe number
            isDensityMode = (mode(1) == 'I');
            %isEFieldMode  = (mode(1) == 'V');

            %=========================================
            %
            % LBL file: Create header/key-value pairs
            %
            %=========================================

            if strcmp(San_tabindex(i).dataType, 'best_estimates')
                %======================
                % CASE: Best estimates
                %======================

                iIndexSrc    = San_tabindex(i).iIndex;
                estTabPath   = San_tabindex(i).path;
                probeNbrList = [index(iIndexSrc).probe];
                plksFileList = {index(iIndexSrc).lblfile};                
                for j = 1:numel(plksFileList)
                    plksFileList{j} = convert_PD_TAB_path(pdDatasetPath, plksFileList{j});
                end

                LblData = LblDefs.get_EST_data(...
                    convert_LD_TAB_path(ldDatasetPath, estTabPath), ...
                    plksFileList, probeNbrList);

            else
                %===============================================
                % CASE: Any type of file EXCEPT best estimates.
                %===============================================

                % NOTE: One can obtain a stop/ending SCT value from index(Stabindex(i).iIndexLast).sct1str; too, but experience
                % shows that it is wrong on rare occasions (and in disagreement with the UTC value) for unknown reason.
                % Example: LAP_20150503_210047_525_I2L.LBL
                % BUG: Does not work for 32S_IVxD. Produces too narrow time limits.
                firstPlksFile = convert_PD_TAB_path(pdDatasetPath, index(San_tabindex(i).iIndex).lblfile);
                LhtKvpl = get_timestamps_KVPL(...
                    [], ...
                    Stabindex(San_tabindex(i).iTabindex).utcStop, ...
                    [], ...
                    obt2sctrc(Stabindex(San_tabindex(i).iTabindex).sctStop));

                if strcmp(San_tabindex(i).dataType, 'downsample')
                    % CASE: IVxD
                    samplingRateSeconds = str2double(tabFilename(end-10:end-9));   % Move to "createLBL.definitions" method?
                    LblData = LblDefs.get_IVxD_data(LhtKvpl, firstPlksFile, probeNbr, samplingRateSeconds, isDensityMode);

                elseif strcmp(San_tabindex(i).dataType, 'spectra')
                    % CASE: PSD
                    LblData = LblDefs.get_PSD_data(LhtKvpl, firstPlksFile, probeNbr, isDensityMode, San_tabindex(i).nTabColumns, mode);

                elseif  strcmp(San_tabindex(i).dataType, 'frequency')
                    % CASE: FRQ
                    psdTabFilename = strrep(San_tabindex(i).filename, 'FRQ', 'PSD');
                    LblData = LblDefs.get_FRQ_data(LhtKvpl, firstPlksFile, San_tabindex(i).nTabColumns, psdTabFilename);

                elseif  strcmp(San_tabindex(i).dataType, 'sweep')
                    % CASE: AxS (analyzed sweeps)
                    LblData = LblDefs.get_AxS_data(LhtKvpl, firstPlksFile, Stabindex(San_tabindex(i).iTabindex).filename);
                    tabLblInconsistencyPolicy = AxS_TAB_LBL_INCONSISTENCY_POLICY;   % NOTE: Different policy for A?S.LBL files.

                else
                    error('Error, bad identifier in an_tabindex{%i,7} = San_tabindex(%i).dataType = "%s"', i, i, San_tabindex(i).dataType);
                end
                
            end   % if-else
            
            
            
            %createLBL.create_OBJTABLE_LBL_file(...
            %    convert_LD_TAB_path(data.ldDatasetPath, San_tabindex(i).path), ...
            %    LblData, data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, tabLblInconsistencyPolicy);
            createLblFileFuncPtr( LblData, convert_LD_TAB_path(ldDatasetPath, San_tabindex(i).path), tabLblInconsistencyPolicy );
            clear   plksFileList   firstPlksFile   LblData   tabLblInconsistencyPolicy   HeaderKvpl
            
            
            
        catch Exception
            createLBL.exception_message(Exception, GENERATE_FILE_FAIL_POLICY)
            fprintf(1,'lapdog: Skipping LBL file (an_tabindex) - Continuing\n');
        end

    end    % for
end



% Utility function to shorten code.
%
% IMPLEMENTATION NOTE: From experience, data.A1P_tabindex.timing, asw_tabindex.timing, data.USC_tabindex.timing can have
% UTC values with 6 decimals which DVAL-NG does not permit. Must therefore truncate or round to 3 decimals.
function Kvpl = get_timestamps_KVPL(START_TIME, STOP_TIME, SPACECRAFT_CLOCK_START_COUNT, SPACECRAFT_CLOCK_STOP_COUNT)
    Kvpl = EJ_lapdog_shared.utils.KVPL2({ ...
        'START_TIME',                   shorten_UTC(START_TIME); ...
        'STOP_TIME',                    shorten_UTC(STOP_TIME); ...
        'SPACECRAFT_CLOCK_START_COUNT', SPACECRAFT_CLOCK_START_COUNT; ...
        'SPACECRAFT_CLOCK_STOP_COUNT',  SPACECRAFT_CLOCK_STOP_COUNT});
end



% Shorten UTC strings to be at most 23 characters (3 decimals).
% YYYY-MM-DDThh:mm:ss.mmm
% 12345678901234567890123
%
% NOTE: Must handle for value "<UNSET>".
function utc = shorten_UTC(utc)
    if length(utc) > 23
        utc = utc(1:23);
    end
end



% LD = Lapdog Dataset
function tabPath = convert_LD_TAB_path(datasetPath, tabPath)
    tabPath = createLBL.convert_TAB_path(datasetPath, tabPath, 3);
end



% PD = PDS Dataset
function tabPath = convert_PD_TAB_path(datasetPath, tabPath)
    tabPath = createLBL.convert_TAB_path(datasetPath, tabPath, 5);
end
