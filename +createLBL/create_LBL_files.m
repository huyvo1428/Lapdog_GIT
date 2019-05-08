%
% Create .LBL files for all .TAB files.
%
% This function's outward interface (arguments, return values) is intended to (1) be the "interface" between Lapdog
% variables, and (2) not contain (or minimize) the amount of configuration code of LBL files.
%
%
% ARGUMENTS
% =========
% Data : Struct containing fields, mostly corresponding to the needed Lapdog variables, including global variables.
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
%           Data.index(Stabindex.iIndexFirst/Last) instead.
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
% PROPOSAL: Replace strrep with own version which assert exactly N string replacements.
%   PRO: Good for changes in filename convention.
%===================================================================================================

function create_LBL_files(Data)
    
    % ASSERTIONS
    EJ_library.utils.assert.struct(Data, {...
        'ldDatasetPath', 'pdDatasetPath', 'metakernel', 'C', 'failFastDebugMode', 'generatingDeriv1', ...
        'index', 'blockTAB', 'tabindex', 'an_tabindex', 'A1P_tabindex', 'PHO_tabindex', 'USC_tabindex', 'ASW_tabindex', ...
        'EFL_tabindex', 'NPL_tabindex'})
    if isnan(Data.failFastDebugMode)    % Check if field set to temporary value.
        error('Illegal argument Data.failFastDebugMode=%g', Data.failFastDebugMode)
    end
    
    
    % ASSERTION
    % NOTE 2019-02-27: This assertion should theoretically only be triggered for macro 910 until FJ fixes USC_tabindex.
    % Macro 910 only runs 2016-07-15 and 2016-07-27.
    % IMPLEMENTATION NOTE: 2019-02-28: USC_tabindex can contain empty values (double; not char/strings) as .fname value.
    %   Ex: 2016-02 (month). Bug?
    if ~isempty(Data.USC_tabindex)
        hasEmptyUscFname = any(cellfun(@isempty, {Data.USC_tabindex(:).fname}));
        assert(~hasEmptyUscFname, 'Data.USC_tabindex contains empty .fname values.')
        assert( ...
            numel(Data.USC_tabindex) == numel(unique({Data.USC_tabindex(:).fname})), ...
            'Data.USC_tabindex contains duplicate USC files (.fname).')
    end



    executionBeginDateVec = clock;    % NOTE: NOT a scalar (e.g. number of seconds), but [year month day hour minute seconds].
    prevWarningsSettings = warning('query');
    warning('on', 'all')



    COTLF_SETTINGS = struct('indentationLength', Data.C.ODL_INDENTATION_LENGTH);



    % Set policy for errors/warning
    % (1) when failing to generate a file,
    % (2) when LBL files are (believed to be) inconsistent with TAB files.
    if Data.failFastDebugMode
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
        Data.generatingDeriv1, ...
        Data.C.MISSING_CONSTANT, ...
        Data.C.N_FINAL_PRESWEEP_SAMPLES, ...
        Data.C.ODL_INDENTATION_LENGTH, ...
        Data.C.get_LblHeaderAllKvpl());
    


    cspice_furnsh(Data.metakernel);



    %================================================================================================================
    % Convert tabindex and an_tabindex into equivalent structs
    %================================================================================================================
    Stabindex    = createLBL.convert_tabindex(Data.tabindex);         % Can handle arbitrarily sized empty tabindex.
    San_tabindex = createLBL.convert_an_tabindex(Data.an_tabindex);   % Can handle arbitrarily sized empty an_tabindex.
    
    
    
    %===============================================================
    %
    % Create LBL files for (TAB files in) tabindex: IBxS, IVxHL
    %
    %===============================================================
    createLblFileFuncPtr = @(LblData, tabFile) (createLBL.create_OBJTABLE_LBL_file(...
        convert_LD_TAB_path(Data.ldDatasetPath, tabFile), ...
        LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY));
    create_tabindex_files(createLblFileFuncPtr, Data.pdDatasetPath, Data.index, Stabindex, ...
        LblDefs)
    
    
    
    %===============================================
    %
    % Create LBL files for TAB files in blockTAB.
    %
    %===============================================
    for i = 1:length(Data.blockTAB)
                
        % NOTE: Does NOT rely on reading old LBL file.
        % BUG?/NOTE: Can not find any block list files with macro block beginning before/ending after midnight (due to
        % "rounding") but should they not? /2018-10-19
        START_TIME = datestr(Data.blockTAB(i).tmac0,   'yyyy-mm-ddT00:00:00.000');
        STOP_TIME  = datestr(Data.blockTAB(i).tmac1+1, 'yyyy-mm-ddT00:00:00.000');   % Slightly unsafe (leap seconds, and in case macro block goes to or just after midnight).
        LhtKvpl = get_timestamps_KVPL(...
            START_TIME, ...
            STOP_TIME, ...
            cspice_sce2s(Data.C.ROSETTA_NAIF_ID, cspice_str2et(START_TIME)), ...
            cspice_sce2s(Data.C.ROSETTA_NAIF_ID, cspice_str2et(STOP_TIME)));

        %=======================================
        % LBL file: Create OBJECT TABLE section
        %=======================================
        LblData = LblDefs.get_BLKLIST_data(LhtKvpl);

        createLBL.create_OBJTABLE_LBL_file(...
            convert_LD_TAB_path(Data.ldDatasetPath, Data.blockTAB(i).blockfile), ...
            LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
        
        clear   START_TIME   STOP_TIME   LhtKvpl   LblData
    end   % for



    if Data.generatingDeriv1
        %===============================================
        %
        % Create LBL files for TAB files in an_tabindex
        %
        %===============================================
        createLblFileFuncPtr = @(LblData, tabFile, tabLblInconsistencyPolicy) (createLBL.create_OBJTABLE_LBL_file(...
                convert_LD_TAB_path(Data.ldDatasetPath, tabFile), ...
                LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, tabLblInconsistencyPolicy));
        create_antabindex_files(createLblFileFuncPtr, Data.ldDatasetPath, Data.pdDatasetPath, Data.index, Stabindex, San_tabindex, ...
            LblDefs, GENERATE_FILE_FAIL_POLICY, GENERAL_TAB_LBL_INCONSISTENCY_POLICY, AxS_TAB_LBL_INCONSISTENCY_POLICY)



        %=============================================================
        %
        % Create LBL files for files in der_struct/A1P_tabindex (A1P)
        %
        %=============================================================
        if ~isempty(Data.A1P_tabindex)
            % IMPLEMENTATION NOTE: "der_struct"/A1P_tabindex is only defined/set when
            % (1) running Lapdog (DERIV1), not edder_lapdog, and
            % (2) analysis.m is not disabled
            % Since it is a global variable, it may survive from a Lapdog DERIV1 run to a run where it should not be
            % defined. NOTE: In that case, Data.A1P_tabindex.file{iFile} will contain paths to the DERIV1-data set (the
            % wrong data set) which may thus lead to overwriting LBL files in DERIV1 data set if called when writing
            % EDDER data set!!! Therefore important to NOT RUN this code for EDDER.
            % IMPLEMENTATION NOTE: "der_struct"/A1P_tabindex can be empty (size 0x0 array) and thus have no fields.
            % ==> Must check for A1P_tabindex being empty.
            
            for iFile = 1:numel(Data.A1P_tabindex.file)
                try
                    startStopTimes = Data.A1P_tabindex.timing(iFile, :);   % NOTE: Stores UTC+SCCS.
                    LhtKvpl        = get_timestamps_KVPL(...
                        startStopTimes{1}, ...
                        startStopTimes{2}, ...
                        startStopTimes{3}, ...
                        startStopTimes{4});
                    
                    iIndex  = Data.A1P_tabindex.firstind(iFile);
                    LblData = LblDefs.get_A1P_data(LhtKvpl, Data.index(iIndex).lblfile);
                    
                    createLBL.create_OBJTABLE_LBL_file(...
                        convert_LD_TAB_path(Data.ldDatasetPath, Data.A1P_tabindex.file{iFile}), ...
                        LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
                    
                    clear   startStopTimes   LhtKvpl   iIndex   LblData
                    
                catch Exception
                    EJ_library.utils.exception_message(Exception, GENERATE_FILE_FAIL_POLICY)
                    fprintf(1,'Aborting A1P LBL file for A1P_tabindex - Continuing\n');
                end
            end
        end
        

        
        %==========================
        %
        % Create LBL files for ASW
        %
        %==========================
        if ~isempty(Data.ASW_tabindex)
            for iFile = 1:numel(Data.ASW_tabindex)
                try                    
                    startStopTimes = Data.ASW_tabindex(iFile).timing;    % NOTE: Stores UTC+OBT.
                    LhtKvpl = get_timestamps_KVPL(...
                        startStopTimes{1}, ...
                        startStopTimes{2}, ...
                        obt2sctrc(str2double(startStopTimes{3})), ...
                        obt2sctrc(str2double(startStopTimes{4})));
                    
                    LblData = LblDefs.get_ASW_data(...
                        LhtKvpl, ...
                        convert_PD_TAB_path(Data.pdDatasetPath, Data.index(Data.ASW_tabindex(iFile).first_index).lblfile));
                    
                    createLBL.create_OBJTABLE_LBL_file(...
                        convert_LD_TAB_path(Data.ldDatasetPath, Data.ASW_tabindex(iFile).fname), ...
                        LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, ASW_TAB_LBL_INCONSISTENCY_POLICY);
                    
                    clear   startStopTimes   LhtKvpl   LblData
                    
                catch Exception
                    EJ_library.utils.exception_message(Exception, GENERATE_FILE_FAIL_POLICY);
                    fprintf(1,'Aborting LBL file for ASW_tabindex - Continuing\n');
                end
            end
        end
        
        
        
        %==========================
        %
        % Create LBL files for USC
        %
        %==========================
        if ~isempty(Data.USC_tabindex)
            for iFile = 1:numel(Data.USC_tabindex)
                try
                    % NOTE: Data.USC_tabindex(iFile).timing{3:4} are sometimes numbers, and sometimes numbers as
                    % strings.
                    startStopTimes = Data.USC_tabindex(iFile).timing;    % NOTE: Stores UTC+OBT.
                    LhtKvpl = get_timestamps_KVPL(...
                        startStopTimes{1}, ...
                        startStopTimes{2}, ...
                        obt2sctrc(strOrNbr2nbr(startStopTimes{3})), ...
                        obt2sctrc(strOrNbr2nbr(startStopTimes{4})));

                    LblData = LblDefs.get_USC_data(...
                        LhtKvpl, ...
                        convert_PD_TAB_path(Data.pdDatasetPath, Data.index(Data.USC_tabindex(iFile).first_index).lblfile));
                    
                    createLBL.create_OBJTABLE_LBL_file(...
                        convert_LD_TAB_path(Data.ldDatasetPath, Data.USC_tabindex(iFile).fname), ...
                        LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
                    
                    clear   startStopTimes   LhtKvpl   LblData
                    
                catch Exception
                    EJ_library.utils.exception_message(Exception, GENERATE_FILE_FAIL_POLICY);
                    fprintf(1,'Aborting LBL file for USC_tabindex - Continuing\n');
                end
            end
        end
        
        %==========================
        %
        % Create LBL files for PHO
        %
        %==========================
        % NOTE: PHO_tabindex has been observed to contain the same file multiple times (commit 9648939), test phase TDDG. Likely
        % because entries are re-added for every run.
        if ~isempty(Data.PHO_tabindex)
            for iFile = 1:numel(Data.PHO_tabindex)
                try
                    % Data.PHO_tabindex(iFile).timing;    % ~BUG: Not implemented/never assigned (yet).
                    
                    % IMPLEMENTATION NOTE: TEMPORARY SOLUTION. Timestamps are set via the columns, not here. Submitting
                    % empty values forces the rest of the code to overwrite the values though (assertions are triggered
                    % otherwise).
                    LhtKvpl = get_timestamps_KVPL('not set', 'not set', 'not set', 'not set');
                    
                    LblData = LblDefs.get_PHO_data(LhtKvpl);
                    
                    createLBL.create_OBJTABLE_LBL_file(...
                        convert_LD_TAB_path(Data.ldDatasetPath, Data.PHO_tabindex(iFile).fname), ...
                        LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
                    
                    clear   LhtKvpl   LblData
                    
                catch Exception
                    EJ_library.utils.exception_message(Exception, GENERATE_FILE_FAIL_POLICY);
                    fprintf(1,'Aborting LBL file for PHO_tabindex - Continuing\n');
                end
            end
        end
        
        
        
        %==========================
        %
        % Create LBL files for EFL
        %
        %==========================
        for iFile = 1:numel(Data.EFL_tabindex)
            try
                startStopTimes = Data.EFL_tabindex(iFile).timing;    % NOTE: Stores UTC+OBT.
                LhtKvpl = get_timestamps_KVPL(...
                    startStopTimes{1}, ...
                    startStopTimes{2}, ...
                    obt2sctrc(startStopTimes{3}), ...
                    obt2sctrc(startStopTimes{4}));
                
                LblData = LblDefs.get_EFL_data(...
                    LhtKvpl, ...
                    convert_PD_TAB_path(Data.pdDatasetPath, Data.index(Data.EFL_tabindex(iFile).first_index).lblfile));
                
                createLBL.create_OBJTABLE_LBL_file(...
                    convert_LD_TAB_path(Data.ldDatasetPath, Data.EFL_tabindex(iFile).fname), ...
                    LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
                
                clear   startStopTimes   LhtKvpl   LblData
                
            catch Exception
                EJ_library.utils.exception_message(Exception, GENERATE_FILE_FAIL_POLICY);
                fprintf(1,'Aborting LBL file for EFL_tabindex - Continuing\n');
            end
        end
        
        
        
        %==========================
        %
        % Create LBL files for NPL
        %
        %==========================
        for iFile = 1:numel(Data.NPL_tabindex)
            try
                startStopTimes = Data.NPL_tabindex(iFile).timing;    % NOTE: Stores UTC+OBT.
                LhtKvpl = get_timestamps_KVPL(...
                    startStopTimes{1}, ...
                    startStopTimes{2}, ...
                    obt2sctrc(strOrNbr2nbr(startStopTimes{3})), ...
                    obt2sctrc(strOrNbr2nbr(startStopTimes{4})));
                % NOTE: Not sure if always, or only sometimes, string instead of number.
                
                LblData = LblDefs.get_NPL_data(...
                    LhtKvpl, ...
                    convert_PD_TAB_path(Data.pdDatasetPath, Data.index(Data.NPL_tabindex(iFile).first_index).lblfile));
                
                createLBL.create_OBJTABLE_LBL_file(...
                    convert_LD_TAB_path(Data.ldDatasetPath, Data.NPL_tabindex(iFile).fname), ...
                    LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
                
                clear   startStopTimes   LhtKvpl   LblData
                
            catch Exception
                EJ_library.utils.exception_message(Exception, GENERATE_FILE_FAIL_POLICY);
                fprintf(1,'Aborting LBL file for NPL_tabindex - Continuing\n');
            end
        end

    end    % if Data.generatingDeriv1
    
    
    
    cspice_unload(Data.metakernel);
    warning(prevWarningsSettings)
    fprintf(1, '%s: %.0f s (elapsed wall time)\n', mfilename, etime(clock, executionBeginDateVec));

end



function create_tabindex_files(createLblFileFuncPtr, pdDatasetPath, index, Stabindex, LblDefs)
    
    for i = 1:length(Stabindex)
        
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
        %assert()
        LhtKvpl = get_timestamps_KVPL(...
            'not set', ...
            Stabindex(i).utcStop, ...
            'not set', ...
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
                ixsTabFilename(28) = 'I';
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
        %    convert_LD_TAB_path(Data.ldDatasetPath, Stabindex(i).path), ...
        %    LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
        createLblFileFuncPtr(LblData, Stabindex(i).path);
        
        clear   firstPlksSs   LhtKvpl   LblData
        
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
                    'not set', ...
                    Stabindex(San_tabindex(i).iTabindex).utcStop, ...
                    'not set', ...
                    obt2sctrc(Stabindex(San_tabindex(i).iTabindex).sctStop));

                if strcmp(San_tabindex(i).dataType, 'downsample')
                    % CASE: IVxD
                    samplingRateSeconds = str2double(tabFilename(end-10:end-9));
                    LblData = LblDefs.get_IVxD_data(LhtKvpl, firstPlksFile, probeNbr, samplingRateSeconds, isDensityMode);

                elseif strcmp(San_tabindex(i).dataType, 'spectra')
                    % CASE: PSD
                    frqTabFilename = strrep(San_tabindex(i).filename, 'PSD', 'FRQ');
                    LblData = LblDefs.get_PSD_data(LhtKvpl, firstPlksFile, probeNbr, isDensityMode, San_tabindex(i).nTabColumns, mode, frqTabFilename);

                elseif strcmp(San_tabindex(i).dataType, 'frequency')
                    % CASE: FRQ
                    psdTabFilename = strrep(San_tabindex(i).filename, 'FRQ', 'PSD');
                    LblData = LblDefs.get_FRQ_data(LhtKvpl, firstPlksFile, San_tabindex(i).nTabColumns, psdTabFilename);

                elseif strcmp(San_tabindex(i).dataType, 'sweep')
                    % CASE: AxS (analyzed sweeps)
                    LblData = LblDefs.get_AxS_data(LhtKvpl, firstPlksFile, Stabindex(San_tabindex(i).iTabindex).filename);
                    tabLblInconsistencyPolicy = AxS_TAB_LBL_INCONSISTENCY_POLICY;   % NOTE: Different policy for A?S.LBL files.

                else
                    error('Error, bad identifier in an_tabindex{%i,7} = San_tabindex(%i).dataType = "%s"', i, i, San_tabindex(i).dataType);
                end
                
            end   % if-else
            
            
            
            %createLBL.create_OBJTABLE_LBL_file(...
            %    convert_LD_TAB_path(Data.ldDatasetPath, San_tabindex(i).path), ...
            %    LblData, Data.C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, tabLblInconsistencyPolicy);
            createLblFileFuncPtr( LblData, convert_LD_TAB_path(ldDatasetPath, San_tabindex(i).path), tabLblInconsistencyPolicy );
            clear   plksFileList   firstPlksFile   LblData   tabLblInconsistencyPolicy   HeaderKvpl
            
            
            
        catch Exception
            EJ_library.utils.exception_message(Exception, GENERATE_FILE_FAIL_POLICY)
            fprintf(1,'lapdog: Skipping LBL file (an_tabindex) - Continuing\n');
        end

    end    % for
end



% Utility function to shorten code.
%
% START_TIME, STOP_TIME, SPACECRAFT_CLOCK_START_COUNT,
% SPACECRAFT_CLOCK_STOP_COUNT : 'not set' (i.e. value not set here), or corresponding string.
%
% IMPLEMENTATION NOTE: Using special string for not setting value, instead
% of [], in order to have assertion which captures when an unintended (and
% illegal) [] is submitted. This assertion captures bugs/exceptions which
% would otherwise trigger exceptions much later, deep down in
% "convert_struct_to_ODL>construct_key_assignment at 183".
% 
% IMPLEMENTATION NOTE: From experience, Data.A1P_tabindex.timing, asw_tabindex.timing, Data.USC_tabindex.timing can have
% UTC values with 6 decimals which DVAL-NG does not permit. Must therefore truncate or round to 3 decimals.
% 
function Kvpl = get_timestamps_KVPL(START_TIME, STOP_TIME, SPACECRAFT_CLOCK_START_COUNT, SPACECRAFT_CLOCK_STOP_COUNT)

    Kvpl = EJ_library.utils.KVPL2({ ...
        'START_TIME',                   interpret_arg(shorten_UTC(START_TIME)); ...
        'STOP_TIME',                    interpret_arg(shorten_UTC(STOP_TIME)); ...
        'SPACECRAFT_CLOCK_START_COUNT', interpret_arg(SPACECRAFT_CLOCK_START_COUNT); ...
        'SPACECRAFT_CLOCK_STOP_COUNT',  interpret_arg(SPACECRAFT_CLOCK_STOP_COUNT)}  );
    
    function str = interpret_arg(argStr)
        EJ_library.utils.assert.castring(argStr)
        if strcmp(argStr, 'not set')
            str = [];
        else
            str = argStr;
        end
    end
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



function x = strOrNbr2nbr(x)
    if ischar(x)
        x = str2double(x);
    elseif isnumeric(x)
        ;
    else
        assert(0, 'Expected x to be either (1) string, or (2) number.')
    end
end
    
