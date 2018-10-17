%function createLBL_main(derivedpath, datasetid, shortphase, datasetname, ...
%        lbltime, lbleditor, lblrev, ...
%        producerfullname, producershortname, targetfullname, targettype, missionphase, tabindex, blockTAB, index, an_tabindex, der_struct)

%
% Create .LBL files for all .TAB files.
% NOTE: Uses global variable "der_struct"
%
% VARIABLE NAMING CONVENTIONS
% ===========================
% KVL, KVPL = Key-Value (pair) List

%===================================================================================================
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
%               - All metadata which naturally (could) vary between individual data products (not just between PDS data sets)
%                   Ex: TODO-DECISION: Common within PDS data set, i.e. DATA_SET_ID/-NAME, 
%               - All metadata close to the TAB contents.
%           - Explicitly: 
%               - Column description differences (between EDDER/LAPDOG); columns present, widths of columns).
%               - MISSION_CONSTANT
%       ~create_E2C2D2 should handle
%           - Philosophically: Metadata which has to do with how to select Lapdog/Edder data products to be included in
%             delivery data sets.
%       NOTE: Assumes that all delivery/PDS datasets pass through ~create_E2C2D2.
%
%   PROPOSAL: Values NOT set by createLBL, should be set to invalid placeholder values, e.g. ^EAICD_DESC = <unset>.
%       PRO: Makes it clear in createLBL what information is not set (but not the reverse).
%       PROPOSAL: ~create_E2C2D2 should only be allowed to overwrite such placeholder values (assertion).
%   PROPOSAL: createLBL should NEVER set unused/overwritten keywords (not even to placeholder values).
%       ~create_E2C2D2 should add the keys instead and check for collisions.
%       CON: create_E2C2D2 has to know which keywords that which have to be added.
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
% PROPOSAL: Make code independent of stabindex.utcStop, stabindex.sctStop by just using
%           index(stabindex.iIndexFirst/Last) instead.
%   PRO: Makes code more reliable.
%   TODO-NEED-INFO: Need info if correct understanding of index timestamps.
%
% PROPOSAL: Read STOP_TIME from the last CALIB1/EDITED1 file, just like Calib1LblSs does.
%
% PROPOSAL: Load (standard) SPICE metakernel from specific function.
%   PRO: More structured (smaller main code).
%   PRO: Could be used in multiple places in Lapdog.
%
%   PROPOSAL: Standard single current/voltage, measured/bias column which varies with EDDER/DERIV1.
%       PROPOSAL: Argument which selects: "bias", "meas"
%   PROPOSAL: Take hard-coded constants struct "C" as argument.
%       TODO-DECISION: Should struct depend on EDDER/DERIV1 or contain info for both?
%
% PROPOSAL: Make into script that simply calls separate main function (other file).
%   PRO: Better encapsulation/modularization.
%   PRO: Can use own variable names.
%   PRO: Better for testing since arguments are more transparent.
%   PRO: Can have local functions (instead of separate files).
%   CON: Too many arguments (16).
%       PROPOSAL: Set struct which is passed to function.
%   --
%   PROPOSAL: Move some +createLBL/* functions into it.
%   PROPOSAL: Do not reference any global variables in main function.
%       CON/PROBLEM: der_struct is not defined for non-EDDER and can thus not just be added as argument.
%
%
%
% PROPOSAL: Make into separate, independent code that can be run separately from Lapdog, but also as a part of it.
%   Set start & stop timestamps from TAB contents, not EDITED1/CALIB1 files.
%   Find and identify types of files by iterating through DERIV1 data set.
%   NOTE: In naive implementation:
%       - Would/could NOT make use of any table with information on TAB files: blockTAB, index, tabindex, an_tabindex, der_struct.
%         Other arguments could be ~hardcoded or submitted (or reorganized).
%   	- ~Current dependence: function createLBL_main(derivedpath, datasetid, shortphase, datasetname, ...
%         lbltime, lbleditor, lblrev, ...
%         producerfullname, producershortname, targetfullname, targettype, missionphase, tabindex, blockTAB, index,
%         an_tabindex, der_struct)
%   --
%   TODO-DECISION: Relationship with delivery code?
%       Still modify LBL files in delivery code? (change TAB+LBL filenames; search-and-replace filenames in DESCRIPTION; more?)
%       ~Shared code for recognizing & classifying files?!
%       PROPOSAL: Be able to call both before and after TAB+LBL name modification: Call from both Lapdog and delivery
%           code, with different filename prefixes?
%   --
%   PRO: Useful for re-running separately from Lapdog.
%       Ex: When preparing deliveries, and having lots of large datasets at the same time.
%           ==> Prohibitive processing time.
%       Ex: After bugfixes.
%       Ex: After reconfiguring
%           Ex: New DESCRIPTION, UNIT, columns etc.
%       Ex: Amending/refactoring code.
%   CON: Can not read the OBJECT = TABLE DESCRIPTION (not among the LBL header keys).
%   CON: Can not read all the technical LBL header PDS keywords (directly) from EDITED1/CALIB1 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%       PROPOSAL: Some way of choosing whether to retrieve LBL header PDS keywords from (1) EDITED1/CALIB1 (Lapdog), or (2) DERIV1 (running separately).
%           NOTE: Implies still using Lapdog data structs for Lapdog runs.
%   CON: EST LBL requires knowledge of which set of probes was used.
%       CON: EST is low priority since it will probably not be used.
%   --
%   PROPOSAL: Preparatory code refactoring.
%       (1) Make as independent as possible of Lapdog data structs: blockTAB, index, an_tabindex, der_struct.
%       (2) Make completely independent of Lapdog data structs: Identify DERIV1 TAB files by recursing over directory structure.
%       (3) Move as much as possible into function file(s), possibly one major function file.
%   PROPOSAL: Dumb-downed implementation: Have lapdog.m/main.m/edder_lapdog.m (createLBL?) save MATLAB workspace; Reload it to re-run
%             createLBL.
%       CON: Lapdog data structs contain absolute paths. ==> Will not work if moving datasets.
%           PROPOSAL: Can remove those parts of paths. Then combine with known path of dataset.
%       NOTE: createLBL.m can/should not naively save workspace since the caller of createLBL should arrange for
%             workspace to be loaded.
% 
%   PROPOSAL: Functions:
%           - create_LBL_File: Create one LBL file given arguments: Path to TAB file, LBL header PDS keywords, start & stop timestamps (2x2), OBJECT=TABLE DESCRIPTION.
%             Type of file is deduced from TAB filename. Hard-coded info used to call createLBL.create_OBJTABLE_LBL_file
%             (just like createLBL).
%           When used by Lapdog:
%               - createLBL iterates over Lapdog data structs (tabindex etc; like now).
%               - Obtains LBL header keywords (incl. start & stop timestamps) and OBJECT=TABLE: DESCRIPTION.
%               - Calls create_LBL_file to create individual LBL files.
%           When used by delivery code:
%               - Copy, rename selected TAB & LBL files (do not modify).
%               - For copied TAB & LBL file pairs: read LBL file to obtain LBL header keywords, then call create_LBL_file and overwrite LBL file with new version.
%           When used for updating LBL files of EDDER/DERIV1 dataset (without rrunning Lapdog):
%               - Iterate over day subdirectories
%               - For every TAB file found, read the LBL file: Extract LBL header keywords and OBJECT=TABLE: DESCRIPTION.
%           When used for generating initial new sample L5 LBL files (there is no ~an_tabindex equivalent):
%               - Iterate over day subdirectories.
%               - For every TAB file without a LBL file, call create_LBL_file with only standard LBL headers.
%                 create_LBL_file will tell if it cannot classify the file.
%       CON: Difficult to compare LBL files before (EDDER/DERIV1) and after (EDITED2/CALIB2/DERIV2), since different
%            filenames.
%
%
% PROPOSAL: EST has its own try-catch. Abolish(?)
%
% TODO/PROPOSAL: Create LBL for 60M_PHO, USC, ASW, NPL here (not in create_LBL_L5_sample_types).
%
% PROPOSAL: Centralized functionality for setting KVPL for start & stop timestamps.
% PROPOSAL: Read first & LAST start & stop timestamps from EDITED1/CALIB1 LBL files using centralized function(s).
%
% TODO: Consistent variable naming: kvl-->kvpl, Capitalized initials for structs.
%===================================================================================================

executionBeginDateVec = clock;    % NOTE: NOT a scalar (e.g. number of seconds), but [year month day hour minute seconds].
prevWarningsSettings = warning('query');
warning('on', 'all')

%========================================================================================
% "Constants"
% -----------
% NO_ODL_UNIT: Constant to be used for LBL "UNIT" fields meaning that there is no unit.
% This means that it is known that the quantity has no unit rather than that the unit
% is simply unknown at present.
%========================================================================================
global SATURATION_CONSTANT N_FINAL_PRESWEEP_SAMPLES
C = createLBL.constants(SATURATION_CONSTANT, N_FINAL_PRESWEEP_SAMPLES);
clear SATURATION_CONSTANT N_FINAL_PRESWEEP_SAMPLES

DEBUG_ON = 1;
DONT_READ_HEADER_KEY_LIST = {'FILE_NAME', '^TABLE', 'PRODUCT_ID', 'RECORD_BYTES', 'FILE_RECORDS', 'RECORD_TYPE'};
COTLF_SETTINGS = struct('indentationLength', C.INDENTATION_LENGTH);



% Set policy for errors/warning
% (1) when failing to generate a file, 
% (2) when LBL files are (believed to be) inconsistent with TAB files.
if DEBUG_ON
    GENERATE_FILE_FAIL_POLICY = 'message+stack trace';
    
    GENERAL_TAB_LBL_INCONSISTENCY_POLICY = 'error';
    %AxS_TAB_LBL_INCONSISTENCY_POLICY     = 'warning';
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
    error('Can not determine whether code generating (Lapdog''s) EDDER or (Lapdog''s) DERIV1 dataset. basename=%s', basename)
end



% NOTE: Requires "generatingDeriv1" to be defined. Can therefore not be initialized earlier.
defs = createLBL.definitions(generatingDeriv1, C.MISSING_CONSTANT, C.N_FINAL_PRESWEEP_SAMPLES);



LblAllKvpl = C.get_LblAllKvpl(sprintf('%s, %s, %s', lbltime, lbleditor, lblrev));



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



%================================================================================================================
% Convert tabindex and an_tabindex into equivalent structs
% --------------------------------------------------------
% IMPLEMENTATION NOTE: Lapdog never defines an_tabindex if analysis.m is disabled (not called; useful for CALIB2
% generation). Must therefore handle that case. Can not just use generatingDeriv1.
%================================================================================================================
[stabindex] = createLBL.convert_tabindex(tabindex);   % Can handle arbitrarily sized empty tabindex.
%if generatingDeriv1
%    % IMPLEMENTATION NOTE: Variable an_tabindex never defined during EDDER runs?
%    [san_tabindex] = createLBL.convert_an_tabindex(an_tabindex);
%end
if ~exist('an_tabindex', 'var')   % If variable is undefined (not just empty) ...
    [san_tabindex] = createLBL.convert_an_tabindex([]);
else
    [san_tabindex] = createLBL.convert_an_tabindex(an_tabindex);  % Can handle arbitrarily sized empty an_tabindex.
end



%===============================================
%
% Create LBL files for (TAB files in) tabindex.
%
%===============================================
for i = 1:length(stabindex)
    try
        
        LblData = [];
        
        %=========================================
        %
        % LBL file: Create header/key-value pairs
        %
        %=========================================
        
        tabFilename = stabindex(i).filename;
        iIndexFirst = stabindex(i).iIndexFirst;
        iIndexLast  = stabindex(i).iIndexLast;     % PROPOSAL: Use for reading CALIB1/EDITED1 file for obtaining end timestamps?
        probeNbr    = index(iIndexFirst).probe;
        
        %--------------------------------
        % Read the EDDER/CALIB1 LBL file
        %--------------------------------
        [KvlLblCalib1, Calib1LblSs] = createLBL.read_LBL_file(index(iIndexFirst).lblfile, DONT_READ_HEADER_KEY_LIST);

        
        
        % NOTE: One can obtain a stop/ending SCT value from index(stabindex(i).iIndexLast).sct1str; too, but experience
        % shows that it is wrong on rare occasions (and in disagreement with the UTC value) for unknown reason.
        % Example: LAP_20150503_210047_525_I2L.LBL
        SPACECRAFT_CLOCK_STOP_COUNT = sprintf('%s/%s', index(iIndexLast).sct0str(2), obt2sct(stabindex(i).sctStop));
        
        KvlLbl = LblAllKvpl;
        KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'START_TIME',                   Calib1LblSs.START_TIME);        % UTC start time
        KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'STOP_TIME',                    stabindex(i).utcStop(1:23));    % UTC stop  time
        KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'SPACECRAFT_CLOCK_START_COUNT', Calib1LblSs.SPACECRAFT_CLOCK_START_COUNT);
        KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'SPACECRAFT_CLOCK_STOP_COUNT',  SPACECRAFT_CLOCK_STOP_COUNT);

        KvlLbl = EJ_lapdog_shared.utils.KVPL.overwrite_values(KvlLblCalib1, KvlLbl, 'require preexisting keys');
        
        LblData.HeaderKvl = KvlLbl;
        clear   KvlLbl KvlLblCalib1
        
        
        
        isSweep       = (tabFilename(30)=='S');
        isSweepTable  = (tabFilename(28)=='B') && isSweep;
        isDensityMode = (tabFilename(28)=='I');
        isEFieldMode  = (tabFilename(28)=='V');
        
        %=======================================
        %
        % LBL file: Create OBJECT TABLE section
        %
        %=======================================
        LblData.OBJTABLE = [];
        if (isSweep)
            
            %==============================
            % CASE: Sweep files (IxS, BxS)
            %==============================
            
            if (isSweepTable)
                % CASE: BxS
                
                [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_BxS_data(probeNbr, Calib1LblSs.OBJECT___TABLE{1}.DESCRIPTION);
                
            else     % if (isSweepTable) ...
                % CASE: IxS

                bxsTabFilename = tabFilename;
                bxsTabFilename(28) = 'B';

                [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_IxS_data(...
                    probeNbr, Calib1LblSs.OBJECT___TABLE{1}.DESCRIPTION, bxsTabFilename, stabindex(i).nColumns);
                
            end   % if (isSweepTable) ... else ...

        else
            %===============================================================
            % CASE: Anything EXCEPT sweep files (NOT [IB]xS) <==> [IV]x[HL]
            %===============================================================

            [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_IVxHL_data(...
                isDensityMode, probeNbr, Calib1LblSs.OBJECT___TABLE{1}.DESCRIPTION);
        end
        
        createLBL.create_OBJTABLE_LBL_file(stabindex(i).path, LblData, C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
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
    
    %==============================================
    %
    % LBL file: Create header/key-value pairs
    %
    % NOTE: Does NOT rely on reading old LBL file.
    %==============================================
    START_TIME = datestr(blockTAB(i).tmac0,   'yyyy-mm-ddT00:00:00.000');
    STOP_TIME  = datestr(blockTAB(i).tmac1+1, 'yyyy-mm-ddT00:00:00.000');   % Slightly unsafe (leap seconds, and in case macro block goes to or just after midnight).
    KvlLbl = LblAllKvpl;
    KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'START_TIME',                   START_TIME);       % UTC start time
    KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'STOP_TIME',                    STOP_TIME);        % UTC stop time
    KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'SPACECRAFT_CLOCK_START_COUNT', cspice_sce2s(C.ROSETTA_NAIF_ID, cspice_str2et(START_TIME)));
    KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'SPACECRAFT_CLOCK_STOP_COUNT',  cspice_sce2s(C.ROSETTA_NAIF_ID, cspice_str2et(STOP_TIME)));
    LblData.HeaderKvl = KvlLbl;
    clear   KvlLbl
    
    
    
    %=======================================
    % LBL file: Create OBJECT TABLE section
    %=======================================
    
    [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_BLKLIST_data();
    
    createLBL.create_OBJTABLE_LBL_file(blockTAB(i).blockfile, LblData, C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
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
            
            %=========================================
            %
            % LBL file: Create header/key-value pairs
            %
            %=========================================
            
            if strcmp(san_tabindex(i).dataType, 'best_estimates')
                %======================
                % CASE: Best estimates
                %======================
                % NOTE: Has its  own try-catch statement. (Why?)
                
                %TAB_file_info = dir(san_tabindex(i).path);
                KvlLbl = LblAllKvpl;
                KvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(KvlLbl, 'DESCRIPTION', 'Best estimates of physical quantities based on sweeps.');
                try
                    %===============================================================
                    % NOTE: createLBL.create_EST_LBL_header(...)
                    %       sets certain LBL/ODL variables to handle collisions:
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
                KvlLbl = LblAllKvpl;
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
            
            LblData.OBJTABLE = [];
            if strcmp(san_tabindex(i).dataType, 'downsample')   %%%%%%%% DOWNSAMPLED FILE %%%%%%%%%%%%%%%                
                
                samplingRateSeconds = str2double(tabFilename(end-10:end-9));
                [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_IVxD_data(probeNbr, Calib1LblSs.DESCRIPTION, samplingRateSeconds, isDensityMode);
                
            elseif strcmp(san_tabindex(i).dataType, 'spectra')   %%%%%%%%%%%%%%%% SPECTRA FILE %%%%%%%%%%
                
                [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_PSD_data(probeNbr, isDensityMode, san_tabindex(i).nTabColumns, mode);
                
            elseif  strcmp(san_tabindex(i).dataType, 'frequency')    %%%%%%%%%%%% FREQUENCY FILE %%%%%%%%%
                
                psdTabFilename = strrep(san_tabindex(i).filename, 'FRQ', 'PSD');
                [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_FRQ_data(san_tabindex(i).nTabColumns, psdTabFilename);

            elseif  strcmp(san_tabindex(i).dataType, 'sweep')    %%%%%%%%%%%% SWEEP ANALYSIS FILE %%%%%%%%%

                [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_AxS_data(stabindex(san_tabindex(i).iTabindex).filename);

                tabLblInconsistencyPolicy = AxS_TAB_LBL_INCONSISTENCY_POLICY;   % NOTE: Different policy for A?S.LBL files.
                
            elseif  strcmp(san_tabindex(i).dataType,'best_estimates')    %%%%%%%%%%%% BEST ESTIMATES FILE %%%%%%%%%%%%
                
                [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_EST_data();
                
            else
                
                error('Error, bad identifier in an_tabindex{%i,7} = san_tabindex(%i).dataType = "%s"',i, i, san_tabindex(i).dataType);
                
            end
            
            
            
            createLBL.create_OBJTABLE_LBL_file(san_tabindex(i).path, LblData, C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, tabLblInconsistencyPolicy);
            clear   LblData   tabLblInconsistencyPolicy
            
            
            
        catch exception
            createLBL.exception_message(exception, GENERATE_FILE_FAIL_POLICY)
            fprintf(1,'lapdog: Skipping LBL file (an_tabindex) - Continuing\n');
        end    % try-catch



    end    % for
end    % if generatingDeriv1



if generatingDeriv1
    try
        %=================================================
        %
        % Create LBL files for files in der_struct (A1P).
        %
        %=================================================
        global der_struct    % Global variable with info on A1P files.
        if ~isempty(der_struct)
            % IMPLEMENTATION NOTE: "der_struct" is only defined/set when running Lapdog (DERIV1). However, since it is a
            % global variable, it may survive from a Lapdog DERIV1 run until a edder_lapdog run. If so,
            % der_struct.file{iFile} will contain paths to a DERIV1-data set. May thus lead to overwriting LBL files in
            % DERIV1 data set if called when writing EDDER data set!!! Therefore important to NOT RUN this code for
            % EDDER.
            %createLBL.write_A1P(LblAllKvpl, C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, index, der_struct, ...
            %    DONT_READ_HEADER_KEY_LIST, GENERAL_TAB_LBL_INCONSISTENCY_POLICY);
            
            for iFile = 1:numel(der_struct.file)
                startStopTimes = der_struct.timing(iFile, :);   % NOTE: Stores UTC+SCCS
                
                iIndex = der_struct.firstind(iFile);

                %--------------------------
                % Read the CALIB1 LBL file
                %--------------------------
                [kvlLblCalib1, junk] = createLBL.read_LBL_file(index(iIndex).lblfile, DONT_READ_HEADER_KEY_LIST);

                % IMPLEMENTATION NOTE: From experience, der_struct.timing can have UTC values with 6 decimals which DVAL-NG does
                % not permit. Must therefore truncate or round to 3 decimals.
                kvlLbl = kvlLblAll;
                kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'START_TIME',                   startStopTimes{1}(1:23));        % UTC start time
                kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl,  'STOP_TIME',                   startStopTimes{2}(1:23));        % UTC stop time
                kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'SPACECRAFT_CLOCK_START_COUNT', startStopTimes{3});
                kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'SPACECRAFT_CLOCK_STOP_COUNT',  startStopTimes{4});
                
                kvlLbl = EJ_lapdog_shared.utils.KVPL.overwrite_values(kvlLblCalib1, kvlLbl, 'require preexisting keys');
                
                lblData = [];
                lblData.HeaderKvl = kvlLbl;
                clear   kvlLbl   kvlLblCalib1
                
                lblData.OBJTABLE = [];
                [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = createLBL.definitions.get_A1P_data();
                
                createLBL.create_OBJTABLE_LBL_file(der_struct.file{iFile}, lblData, C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, tabLblInconsistencyPolicy);
                
            end
        end
        
    catch exception
        createLBL.exception_message(exception, GENERATE_FILE_FAIL_POLICY)
        fprintf(1,'\nlapdog:createLBL.write_A1P error message: %s\n',exception.message);
    end
end



if generatingDeriv1    
    tabLblInconsistencyPolicy = GENERAL_TAB_LBL_INCONSISTENCY_POLICY;   % Default value, unless overwritten for specific data file types.
    
    %==========================
    %
    % Create LBL files for ASW
    %
    %==========================
    global ASW_tabindex
    if ~isempty(ASW_tabindex)
        for iFile = 1:numel(ASW_tabindex)
            startStopTimes = ASW_tabindex(iFile).timing;    % NOTE: Stores UTC+OBT.
            
            % IMPLEMENTATION NOTE: From experience, asw_tabindex.timing can have UTC values with 6 decimals which DVAL-NG does
            % not permit. Must therefore truncate or round to 3 decimals.
            kvlLbl = LblAllKvpl;
            kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'START_TIME',                   startStopTimes{1}(1:23));
            kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl,  'STOP_TIME',                   startStopTimes{2}(1:23));
            kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'SPACECRAFT_CLOCK_START_COUNT', obt2sct(str2double(startStopTimes{3})));
            kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'SPACECRAFT_CLOCK_STOP_COUNT',  obt2sct(str2double(startStopTimes{4})));
            
            LblData = [];
            LblData.HeaderKvl = kvlLbl;
            clear   kvlLbl   kvlLblCalib1
            
            LblData.OBJTABLE = [];
            [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_ASW_data();
            
            createLBL.create_OBJTABLE_LBL_file(ASW_tabindex(iFile).fname, LblData, C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, tabLblInconsistencyPolicy);
        end
    end
    
    
    %==========================
    %
    % Create LBL files for USC
    %
    %==========================
    global usc_tabindex
    if ~isempty(usc_tabindex)
        for iFile = 1:numel(usc_tabindex)
            startStopTimes = usc_tabindex(iFile).timing;    % NOTE: Stores UTC+OBT.
            
            % IMPLEMENTATION NOTE: From experience, usc_tabindex.timing can have UTC values with 6 decimals which DVAL-NG does
            % not permit. Must therefore truncate or round to 3 decimals.
            kvlLbl = LblAllKvpl;
            kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'START_TIME',                   startStopTimes{1}(1:23));
            kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl,  'STOP_TIME',                   startStopTimes{2}(1:23));
            kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'SPACECRAFT_CLOCK_START_COUNT', obt2sct(str2double(startStopTimes{3})));
            kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'SPACECRAFT_CLOCK_STOP_COUNT',  obt2sct(str2double(startStopTimes{4})));
            
            LblData = [];
            LblData.HeaderKvl = kvlLbl;
            clear   kvlLbl   kvlLblCalib1
            
            LblData.OBJTABLE = [];
            [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = defs.get_USC_data();
            
            createLBL.create_OBJTABLE_LBL_file(usc_tabindex(iFile).fname, LblData, C.COTLF_HEADER_OPTIONS, COTLF_SETTINGS, tabLblInconsistencyPolicy);
        end
    end
    
    
    %==============================================================
    %
    % Create LBL files for PHO, USC, NPL files. (DERIV1 only)
    %
    %==============================================================    
    % TEMPORARY SOLUTION.
    createLBL.create_LBL_L5_sample_types(derivedpath, C.MISSING_CONSTANT, C.N_FINAL_PRESWEEP_SAMPLES)
    
    % TEST    
    % ASW_tabindex (global)
    % usc_tabindex (not global)
    % PHO_tabindex should exist but is not available?
end



cspice_unload(metakernelFile);
warning(prevWarningsSettings)
fprintf(1, '%s: %.0f s (elapsed wall time)\n', mfilename, etime(clock, executionBeginDateVec));



clear C defs    % Not technically required, but useful when debugging and frequently modifying the corresponding class.
