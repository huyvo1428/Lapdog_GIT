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
% varargin
%   <Empty>  : Use Lapdog variable for dataset path.
%   1 string : Dataset path to use. Not needed by Lapdog, but by separate code that runs createLBL for potentially moved
%              dataset.
%
%
% IMPLEMENTATION NOTES, RATIONALE
% ===============================
% The division between this script and the main function exists to
% (1) separate many ugly hacks and assumptions from the main LBL file-creating code code due to the interface between
%     Lapdog and ~createLBL:
%   (1a) make it explicit which part of the Lapdog workspace variables are used,
%   (1b) separate out the dependence on global variables,
%   (1c) making assumptions on where the metakernel is,
%   (1d) figure out the output dataset type (EDDER, DERIV1),
% (2) optionally save the necessary input to a .mat file to make it possible to rerun the createLBL (or its main function) separately
%     from Lapdog (without saving Lapdog variables to .mat file).
% (3) make it possible to use consistent naming conventions in the main LBL code.
% --
% NOTE: Due to what the function needs to do, it make many ugly calls to "evalin" for the CALLER WORKSPACE to
% (1) declare GLOBAL variables (in the caller workspace) so that they can be accessed and saved to file,
% (2) save the Lapdog variables (in the caller workspace),
% (3) retrieve variable values (from the caller workspace; they are many).
%
%
% Initially created (reorganized) 2018-11-01 by Erik P G Johansson, IRF Uppsala.
%
function createLBL(failFastDebugMode, saveCallerWorkspace, varargin)
    % BOGIQ
    % =====
    % ~NEED: One "clean" internal main function (create_LBL_files) that (1) does not use global variables, and (2) does not
    %        save .mat file, (3)? does not detect EDDER,DERIV1.
    % NEED: Be able to easily call createLBL from main.m, lapdog.m, edder_lapdog.m, rerunlapdog.m, old_rerunlapdog.m,
    %       lapdogrerun_old.m, rerunlapdog_test.m and (1) save .mat, (2) have less stringent errors (?).
    % NEED: Be able to call ~createLBL from rerun_createLBL.m (1) without saving .mat, (2a) using loaded workspace and/or
    %       (2b) proper call to main LBL function, (3) with stringent errors.
    % NEED?: Caller decides if DERIV1 or EDDER.
    % NEED: Save ALL(?) Lapdog workspace variables, including globals which have to be declared/accessible before
    % saving.
    % --
    % PROPOSAL: Change name of Lapdog-wide variable names: usc_tabindex --> USC_tabindex, der_struct --> A1P_tabindex.
    % PROPOSAL: Only save input to create_LBL_files in .mat file.
    %   PRO: Avoids problem of saving/loading global variables.
    %   CON: Sensitive to problems with .mat files not being backward-compatible.
    %
    % PROPOSAL: Save exakt metakernel used?!! De-reference symlink.
    %   TODO-DECISION: How save? Set variable in caller workspace?! Architecture not designed to save additional info.
    %
    % PROPOSAL: createLBL (script) always saves .mat file, then calls function which loads file and hence loads all
    %           Lapdog workspace into its own function workspace.
    %
    % PROPOSAL: Iterate over who('global') and declare all global variables accessible (before saving to .mat).
    %   PRO: Prevents misspelling
    %   PRO: Prevents mistakenly not saving global Lapdog state.
    %       PRO: More important than other kinds of bugs, since cannot fix saved .mat file without rerunning Lapdog (for every file).
    
    
    
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
    global SATURATION_CONSTANT
    global N_FINAL_PRESWEEP_SAMPLES    
    C = createLBL.constants(SATURATION_CONSTANT, N_FINAL_PRESWEEP_SAMPLES);
    clear SATURATION_CONSTANT
    clear N_FINAL_PRESWEEP_SAMPELS

    %===============================================================
    % Derive datasetPath
    % ------------------
    % NOTE: Needed for saving .mat file, and must hence precede it.
    %===============================================================
    if length(varargin) == 0
        datasetPath = evalin(MWS, 'derivedpath');    % Value used twice. NOTE: evalin
    elseif length(varargin) == 1
        datasetPath = varargin{1};
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
    %===================================================================================================================
    globalVarsList = who('global');
    % globalVarsList = {'N_FINAL_PRESWEEP_SAMPLES', 'SATURATION_CONSTANT', 'tabindex', 'an_tabindex', ...
    % 'ASW_tabindex', 'PHO_tabindex', 'usc_tabindex'};   % "index" is not a global variable.
    for iVar = 1:numel(globalVarsList)
        cmd = sprintf('global %s', globalVarsList{iVar});
        evalin(MWS, cmd);                                          % NOTE: evalin
        %fprintf('Declare global variable in caller workspace: "%s"\n', cmd)    % DEBUG
        %eval(       sprintf('global %s', globalVarsList{iVar}));
    end
    %======================================================================================================================
    % Save MATLAB workspace to file in dataset directory
    % --------------------------------------------------
    % Save all Lapdog variables needed for createLBL to function.
    % This file can be used for re-running createLBL (fast) without rerunning Lapdog (slow) for large datasets.
    % NOTE: Must include relevant global variables.
    % MATLAB "save" command only includes global variables which have been declared as such with a "global statement" in
    % the current workspace, but not if they have only been declared as such in OTHER workspaces (other parts of the
    % code)!! Must therefore declare relevant variables as "global" before saving file.
    %======================================================================================================================
    if saveCallerWorkspace
        savedWorkspaceFile = fullfile(datasetPath, C.PRE_CREATELBL_SAVED_WORKSPACE_FILENAME);
        fprintf('Saving ~pre-createLBL MATLAB workspace+globals in "%s"\n', savedWorkspaceFile);
        evalin(MWS, sprintf('save(''%s'')', savedWorkspaceFile))                                  % NOTE: evalin
        fprintf('    Done\n');
    end
    

    
    %===================================================================================================================
    % Derive "der_struct"
    % -------------------
    % NOTE: In the past, Lapdog has sometimes defined, and sometimes NOT defined an_tabindex, meaning that the code must
    % be able to handle both possibilities.
    % Ex: Lapdog run where analysis.m is disabled (useful for CALIB2 generation).
    % Ex: EDDER does not call analysis.m.
    % In principle, the same problem could exist for other global variables (e.g. when disabling an_outputscience) but
    % it does not appear to do so, except "der_struct" (which is in reality disabled).
    %===================================================================================================================
    if evalin(MWS, 'exist(''der_struct'')')
        der_struct = evalin(MWS, 'der_struct');              % NOTE: evalin
    else
        der_struct = [];
    end
    
    %=====================================================================================
    % Determine what "archiving level" dataset is produced:
    %   (1) Lapdog's EDDER (for producing EDITED2), or
    %   (2) Lapdog's DERIV (for producing CALIB2, DERIV2).
    % -----------------------------------------------------
    % IMPLEMENTATION NOTE: "fileparts" does not work as intended if path ends with slash.
    % ASSUMES: datasetPath is ~DATA_SET_ID.
    %=====================================================================================
    datasetPathModifCell = regexp(datasetPath, '.*[^/]', 'match');         % Remove trailing slashes (i.e. Linux only).
    [parentPath, basename, suffixJunk] = fileparts(datasetPathModifCell{1});    % NOTE: fileparts interprets the period in DATA_SET_ID as separating basename from suffix.
    if strfind(basename, 'EDDER')
        generatingDeriv1 = 0;
    elseif strfind(basename, 'DERIV')
        generatingDeriv1 = 1;
    else
        error('Can not determine whether code generating (Lapdog''s) EDDER or (Lapdog''s) DERIV1 dataset. basename=%s', basename)
    end
    
    
    
    clfd = [];   % CLFD = create_LBL_files data
    clfd.datasetPath       = datasetPath;
    clfd.lblTime           = evalin(MWS, 'lbltime');
    clfd.lblEditor         = evalin(MWS, 'lbleditor');
    clfd.lblRev            = evalin(MWS, 'lblrev');
    clfd.metakernel        = get_lapdog_metakernel();   % NOTE: Technically not part of the Lapdog state. Useful.
    
    clfd.index             = evalin(MWS, 'index');
    clfd.tabindex          = evalin(MWS, 'tabindex');
    clfd.an_tabindex       = evalin(MWS, 'an_tabindex');    
    clfd.blockTAB          = evalin(MWS, 'blockTAB');
    clfd.ASW_tabindex      = evalin(MWS, 'ASW_tabindex');
    clfd.USC_tabindex      = evalin(MWS, 'usc_tabindex');   % Changing variable name slightly.
    clfd.PHO_tabindex      = evalin(MWS, 'PHO_tabindex');
    
    clfd.A1P_tabindex      = der_struct;     % Changing variable name.
    clfd.C                 = C;
    clfd.failFastDebugMode = failFastDebugMode;
    clfd.generatingDeriv1  = generatingDeriv1;
    clear C



    % NOTE: Some variables (both global and non-global) may be initialized during one run of Lapdog and then not be defined during a later run, due to
    % (1) re-running for a different mission phase
    % (1) re-running for a different archiving level (EDDER, DERIV1)
    % (2) disabling part of Lapdog (e.g. all analysis.m, or output_science.m, or parts thereof)
    % Therefore, older versions of variables may be available when there should be no data and it is not possible for the calling code to tell the difference. If possible, create_LBL_files
    % should try to ignore these data.
    createLBL.create_LBL_files(clfd)
    
end
