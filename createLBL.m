%
% Function (not script) called by main Lapdog code (main.m, lapdog.m, edder_lapdog.m etc).
% It serves as a ~bridge/interface between Lapdog and createLBL.create_LBL_files which does the actual core task.
% It is designed to additionally be called separately from Lapdog using saved variables.
%
%
% FUNCTIONS
% =========
% The function:
% (1) optionally saves all non-global and global Lapdog variables in the CALLER WORKSPACE (so that they can later be used to call
% createLBL separately from Lapdog), and then
% (2) uses Lapdog variables in the CALLER WORKSPACE to call create_LBL_files to actually create (overwrite) LBL files.
%
%
% ARGUMENTS
% =========
% failFastDebugMode
%   1/True  : Fail fast, generate errors. Good for debugging and production of datasets for official delivery.
%   0/False : Continue running for errors. Less messages. Useful if one does not really care about LBL files.
% saveCallerWorkspace
%   1/True  : Try to save MATLAB workspace to file. If intended path is already used, do not write but fail silently.
%   0/False : Do not save MATLAB workspace to file.
% varargin
%   <Empty>  : Use Lapdog variable for dataset path.
%   1 string : Dataset path to use.
%              NOTE: Not needed by Lapdog, but by separate code that runs createLBL for potentially moved dataset.
%
%
% IMPLEMENTATION NOTES, RATIONALE
% ===============================
% The division between this script and the main function exists to:
% (1) separate many ugly hacks and assumptions from the main LBL file-creating code code due to the interface between
%     Lapdog and ~createLBL:
%   (1a) make it explicit which of the Lapdog workspace variables are used,
%   (1b) separate the dependence on global variables,
%   (1c) making assumptions on where the metakernel is,
%   (1d) figure out the output dataset type (EDDER, DERIV1),
% (2) optionally save the necessary input to a .mat file to make it possible to rerun the createLBL (or its main function) separately
%     from Lapdog (without saving Lapdog variables to .mat file).
% (3) make it possible to use consistent naming conventions in the main LBL code.
% --
% The function uses the entire Lapdog workspace as "argument" interface" (in addition to the formal function variables)
% in order to:
% (1) keep the number of formal function arguments low (~15 fewer) to make the call simple & safe (Lapdog code contains
%     ~7 calls to createLBL),
% (2) make sure there is "backward-compatibility" with saved .mat files used by createLBL,
% (3) be able to easily save/load the entire interface (Lapdog workspace), so that when one runs createLBL separately
% from Lapdog, it is easy to load it (the Lapdog workspace) and then call createLBL.
% --
% NOTE: Due to what the function needs to do, and to reduce the number of arguments (by ~15), it makes many ugly calls to
% "evalin" for the CALLER WORKSPACE to
% (1) declare GLOBAL variables (in the caller workspace) so that they can be accessed and saved to file,
% (2) save the Lapdog variables (in the caller workspace),
% (3) retrieve variable values (from the caller workspace; they are many).
% 
%
%
% Initially created (reorganized) 2018-11-01 by Erik P G Johansson, IRF Uppsala.
%
function createLBL(failFastDebugMode, saveCallerWorkspace, varargin)
    % BOGIQ
    % =====
    % ~NEED: One "clean" internal main function (create_LBL_files) that (1) does not use global variables, and (2) does not
    %        save/load .mat file, (3)? does not detect EDDER,DERIV1.
    % NEED: Be able to easily call createLBL from main.m, lapdog.m, edder_lapdog.m, rerunlapdog.m, old_rerunlapdog.m,
    %       lapdogrerun_old.m, rerunlapdog_test.m and (1) save .mat, (2) have less stringent errors (?).
    %       Do not want ~17 argument, do not want to assign struct with ~17 fields before calling.
    % NEED: Be able to call createLBL from rerun_createLBL.m
    %       (1) without saving .mat (not overwrite old file),
    %       (2a) using loaded workspace and/or (2b) proper call to create_LBL_files,
    %       (3) with stringent errors.
    %       ==> Pass new arguments
    % NEED: Save ALL Lapdog workspace variables, including globals which have to be declared/accessible before
    % saving (to maximize backward compatibility).
    % (NEED? : Caller decides if DERIV1 or EDDER.)
    % --
    % PROPOSAL: Change name of Lapdog-wide variable names: usc_tabindex --> USC_tabindex, der_struct --> A1P_tabindex, SATURATION_CONSTANT-->MISSING_CONSTANT.
    % PROPOSAL: Only save input to create_LBL_files in .mat file.
    %   PRO: Avoids problem of saving/loading global variables.
    %   CON: Sensitive to problems with .mat files not being backward-compatible.
    %
    % PROPOSAL: Save exakt metakernel used?!! De-reference symlink.
    %   TODO-DECISION: How save? Set variable in caller workspace?! Architecture not designed to save additional info.
    %
    % PROPOSAL: createLBL (script) always saves .mat file, then calls function which loads file and hence loads all
    %           Lapdog workspace into its own function workspace.
    %   PRO: Simplifies code.
    %   ~CON: Ugly
    %   ~CON: Only works if there is a .mat file, i.e. Lapdog generations must save .mat a file just to generate a dataset.
    %
    % PROPOSAL: Iterate over who('global') and declare all global variables accessible (before saving to .mat).
    %   PRO: Prevents misspelling
    %   PRO: Prevents mistakenly not saving global Lapdog state.
    %       PRO: More important than other kinds of bugs, since cannot fix saved .mat file without rerunning Lapdog (for every file).
    %
    % PROPOSAL: Iterate over caller workspace variables and import all of them to a struct, instead of separately.
    %   ~CON: Still do not want to save this struct for backward compatibility.
    %
    % PROPOSAL: Argument for only trying to generate for data products belonging to CALIB2 or DERIV2.
    %   CON: Lapdog should preferably not have any knowledge of which data products belong to which archiving level.
    %
    % TODO-DECISION: What to do about slow save -v7.3?
    %   PROPOSAL: Only use -v7.3 "when necessary" (ESC3, PRL).
    %       PROPOSAL: Seems unreasonably slow even to be used once.
    %   PROPOSAL: Split up variables into multiple files. Store "index" separately, possibly in multiple .mat files.
    %       PROPOSAL: Stora all variables except index in one files, and index in one/several others.
    %           Ex: save('test2.mat', '-regexp', '^(?!(index)$).')
    %   PROPOSAL: Do not store all of "index".
    %       PROPOSAL: Delete indices not mentioned in tabindex, an_tabindex etc.
    %           TODO-NEED-INFO: Find out if saves any space without changing indices.
    %       PROPOSAL: Remove index.lblfile or index.tabfile (assuming they are analogous). (Assertion?)
    %           NOTE: create_LBL_files does not seem to use index.tabfile, .macrostr, .t0str, .t1str, sct0str, .sct1str.
    %               NOTE: The timestamps might be useful some time though.
    %           NOTE: Experiment: Removing .tabfile index-->index2
    %                index       1x781078            2457080816  struct
    %                index2      1x781078            2074399932  struct
    %       PROPOSAL: .t0str, .t1str, .macrostr all have lot of empty whitespace that can likely be removed. Remove the
    %                 whitespace.
    %   PROPOSAL: Save to other data format.
    %   PROPOSAL: Remove certain other variables from saving.
    %       Ex: MIP
    %
    % PROPOSAL: Change to permit overwrite.
    % PROPOSAL: Remove "index" from pre_createLBL_workspace.mat.
    
    
    
    % Workspace used for Lapdog variables must be correct for createLBL being called from (1) the command line, (2)
    % main.m (a script), (3) lapdog.m (function), (4) rerun_createLBL (function, outside git repo). Can thus not be
    % 'base'.
    MWS = 'caller';    % MWS = MATLAB workspace



    %====================================================================
    % Derive C
    % --------
    % Use constructor for checking consistency with global values.
    % NOTE: Needed to find path to .mat file, and must hence precede it.
    %====================================================================
    C = createLBL.constants();

    %===============================================================
    % Derive ldDatasetPath, pdDatasetPath
    % -----------------------------------
    % NOTE: Needed for saving .mat file, and must hence precede it.
    %===============================================================
    if isempty(varargin)
        ldDatasetPath = evalin(MWS, 'derivedpath');    % Value used twice. NOTE: evalin
        pdDatasetPath = evalin(MWS, 'archivepath');                      % NOTE: evalin
    elseif length(varargin) == 2
        ldDatasetPath = varargin{1};
        pdDatasetPath = varargin{2};
    else
        error('Illegal number of arguments.')
    end



    %===================================================================================================================
    % IN THE CALLER WORKSPACE: Declare all global variables as global (accessible) so that:
    %   (1) they can be saved to file,
    %   (2) they are accessible by later commands (in this function)
    % --------------------------------------------------------------------------------------------------------------
    % IMPLEMENTATION NOTE: Variables are declared global in the caller/base workspace so that they can be saved to .mat
    % file. All global variables are declared global, just to make sure that no new ones are missed in case ~createLBL
    % has to be modified after a dataset has been generated.
    % Could iterate over list of specific global variables, but then there are the risks of
    % (1) misspelling, and
    % (2) missing new global variables, leading to .mat incompatibility.
    %===================================================================================================================
    globalVarsList = who('global');
    % globalVarsList = {'N_FINAL_PRESWEEP_SAMPLES', 'SATURATION_CONSTANT', 'tabindex', 'an_tabindex', ...
    % 'ASW_tabindex', 'PHO_tabindex', 'usc_tabindex'};   % "index" is not a global variable.
    for iVar = 1:numel(globalVarsList)
        cmd = sprintf('global %s', globalVarsList{iVar});
        evalin(MWS, cmd);                                                                               % NOTE: evalin
        %fprintf('Declare global variable in caller workspace: "%s"\n', cmd)    % DEBUG
        %eval(       sprintf('global %s', globalVarsList{iVar}));
    end
    index = evalin(MWS, 'index');
    %===================================================================================================================
    % (Optionally) Save MATLAB CALLER WORKSPACE to file
    % -------------------------------------------------
    % Save all Lapdog variables needed for createLBL to function.
    % This file can be used for re-running createLBL (fast) without rerunning Lapdog (slow) for large datasets.
    % NOTE: Must include relevant global variables.
    % MATLAB "save" command only includes global variables which have been declared as such with a "global statement" in
    % the current workspace, but not if they have only been declared as such in OTHER workspaces (other parts of the
    % code)!! Must therefore declare relevant variables as "global" before saving file.
    %===================================================================================================================
    if saveCallerWorkspace
        savedWorkspaceFile = fullfile(ldDatasetPath, C.PRE_CREATELBL_SAVED_WORKSPACE_FILENAME);
        fprintf('Saving pre-createLBL MATLAB workspace+globals in "%s"\n', savedWorkspaceFile);
        if exist(savedWorkspaceFile, 'file')
            fprintf('    Ignoring - There already is such a file/directory. Will not overwrite.\n', savedWorkspaceFile)
        else
            % IMPLEMENTATION NOTE: It has been observed (2018-12-01) that variable "index" can be too large to save to
            % disk for PRL and ESC3, thus generating a warning message "Warning: Variable 'index' cannot be saved to a
            % MAT-file whose version is older than 7.3.". Note that it is a warning, not an error. Lapdog continues to
            % execute, but the .mat file saved to disk simply does not contain the "index" variables. One should in
            % principle be able to solve this by using flag "-v7.3" but experience is that this is (1) impractically
            % slow, and (2) result in much larger .mat files.
            
            saveCmd = sprintf('save(''%s'')', savedWorkspaceFile);    % TEMPORARY. Should really exclude "index" variable.
            executionBeginDateVec = clock;
            evalin(MWS, saveCmd)                         % NOTE: evalin
            fprintf('    Done: %.0f s (elapsed wall time)\n', etime(clock, executionBeginDateVec));
            
            try
                % EXPERIMENTAL CODE
                savedIndexPathPrefix = fullfile(ldDatasetPath, C.PRE_CREATELBL_SAVED_INDEX_PREFIX);
                fprintf('Saving pre-createLBL MATLAB "index" in "%s*"\n', savedIndexPathPrefix);
                EJ_library.utils.store_split_array.save(index, savedIndexPathPrefix, C.N_INDEX_INDICES_PER_PART)
                fprintf('    Done: %.0f s (elapsed wall time)\n', etime(clock, executionBeginDateVec));
            catch Exception
                warning('EJ_library.utils.store_split_array.save failed to save "index" variable to disk.')
            end
        end
    end



    %===================================================================================================================
    % Set variables (local workspace) which are expected but might not be defined (in caller's workspace)
    % ---------------------------------------------------------------------------------------------------
    % Ex: Different TAB files disabled inside an_outputscience.m
    % Ex: an_outputscience.m disabled
    % Ex: Lapdog run where analysis.m is disabled (useful for CALIB2 generation)
    % Ex: EDDER does not call analysis.m
    % In principle, the same problem could exist for other global variables (e.g. when disabling an_outputscience) but
    % it does not appear to do so from testing.
    %
    % NOTE: Can not write a function for this, since evalin can only work on the caller's workspace, not the caller's
    % caller.
    %===================================================================================================================
    POT_UNDEF_VARS = {'der_struct', 'an_tabindex', 'ASW_tabindex', 'PHO_tabindex'};
    for i = 1:length(POT_UNDEF_VARS)
        % IMPLEMENTATION NOTE: There are Lapdog subdirectories "index" and "an_tabindex" which "exist" may respond to
        %                      if not specifying "var".
        if evalin(MWS, sprintf('exist(''%s'', ''var'')', POT_UNDEF_VARS{i}))
            temp = evalin(MWS, POT_UNDEF_VARS{i});                            % NOTE: evalin
        else
            temp = [];
        end
        eval(sprintf('%s = temp;', POT_UNDEF_VARS{i}));                       % NOTE : eval
    end
    
    %=====================================================================================
    % Determine what "archiving level" dataset is produced:
    %   (1) Lapdog's EDDER (for producing EDITED2), or
    %   (2) Lapdog's DERIV (for producing CALIB2, DERIV2).
    % -----------------------------------------------------
    % IMPLEMENTATION NOTE: "fileparts" does not work as intended if path ends with slash.
    % ASSUMES: ldDatasetPath is ~DATA_SET_ID.
    %=====================================================================================
    datasetPathModifCell = regexp(ldDatasetPath, '.*[^/]', 'match');         % Remove trailing slashes (i.e. Linux only).
    [parentPath, basename, suffixJunk] = fileparts(datasetPathModifCell{1});    % NOTE: fileparts interprets the period in DATA_SET_ID as separating basename from suffix.
    if strfind(basename, 'EDDER')
        generatingDeriv1 = 0;
    elseif strfind(basename, 'DERIV')
        generatingDeriv1 = 1;
    else
        error('Can not determine whether code generating (Lapdog''s) EDDER or (Lapdog''s) DERIV1 dataset. basename=%s', basename)
    end
    
    
    
    Clfd = [];   % CLFD = create_LBL_files data
    Clfd.ldDatasetPath     = ldDatasetPath;
    Clfd.pdDatasetPath     = pdDatasetPath;
    Clfd.metakernel        = get_lapdog_metakernel();   % NOTE: Technically not part of the Lapdog state. Useful.
    
    Clfd.index             = evalin(MWS, 'index');
    Clfd.tabindex          = evalin(MWS, 'tabindex');
    Clfd.an_tabindex       = an_tabindex;
    Clfd.blockTAB          = evalin(MWS, 'blockTAB');
    Clfd.ASW_tabindex      = ASW_tabindex;
    Clfd.USC_tabindex      = evalin(MWS, 'usc_tabindex');   % Changing variable case for consistency.
    Clfd.PHO_tabindex      = PHO_tabindex;
    
    Clfd.A1P_tabindex      = der_struct;     % Changing variable name for consistency.
    Clfd.C                 = C;
    Clfd.failFastDebugMode = failFastDebugMode;
    Clfd.generatingDeriv1  = generatingDeriv1;
    clear C



    % NOTE: Some variables (both global and non-global) may be initialized during one run of Lapdog and then not be defined during a later run, due to
    % (1) re-running for a different mission phase
    % (1) re-running for a different archiving level (EDDER, DERIV1)
    % (2) disabling part of Lapdog (e.g. all analysis.m, or output_science.m, or parts thereof)
    % Therefore, older versions of variables may be available when there should be no data and it is not possible for the calling code to tell the difference. If possible, create_LBL_files
    % should try to ignore these data.
    createLBL.create_LBL_files(Clfd)

end
