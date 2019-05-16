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
%   1/True  : Try to save MATLAB workspace to file(s). Will overwrite any old state files.
%   0/False : Do not save MATLAB workspace to file(s).
% varargin : Either
%   (1) <Empty>  : Use Lapdog variable for dataset path.
%   (2) varargin{1} : pds    dataset path to use.
%       varargin{2} : Lapdog dataset path to use.
%
%
% IMPLEMENTATION NOTES, RATIONALE
% ===============================
% The division between this script and the main function exists to:
% (1) separate many ugly hacks and assumptions from the main LBL file-creating code code due to the interface between
%     Lapdog and ~createLBL:
%   (1a) make it explicit which of the Lapdog workspace variables are used,
%   (1b) isolate/concentrate the dependence on global variables,
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
    % PROPOSAL: Change name of Lapdog-wide variable names: usc_tabindex --> USC_tabindex, der_struct --> A1P_tabindex.
    %
    % PROPOSAL: Save exakt metakernel used?!! De-reference symlink.
    %   TODO-DECISION: How save? Set variable in caller workspace?! Architecture not designed to save additional info.
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

    
    
    % Workspace used for Lapdog variables must be correct for createLBL being called from (1) the command line, (2)
    % main.m (a script), (3) lapdog.m (function), (4) rerun_createLBL (function, outside git repo). Can thus not be
    % 'base'.
    MWS = 'caller';    % MWS = MATLAB Workspace



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
        pdDatasetPath = evalin(MWS, 'archivepath');                      % NOTE: evalin
        ldDatasetPath = evalin(MWS, 'derivedpath');    % Value used twice. NOTE: evalin
    elseif length(varargin) == 2
        pdDatasetPath = varargin{1};
        ldDatasetPath = varargin{2};
    else
        error('Illegal number of arguments.')
    end



    if saveCallerWorkspace
        %===============================================================================================================
        % Save MATLAB VARIABLES to files
        % ------------------------------
        % Save all "Lapdog variables" to disk. The saved variables can be used for re-running createLBL (fast) without
        % rerunning all of Lapdog (slow) for large datasets.
        %===============================================================================================================
        evalin(MWS, sprintf('save_Lapdog_state(''%s'', true, ''pre-createLBL'')', ldDatasetPath))    % true = permitOverwrite
    end



    %===================================================================================================================
    % Set variables (local workspace) which are needed but might not be defined (in caller's workspace)
    % -------------------------------------------------------------------------------------------------
    % Ex: Due to different TAB files disabled inside an_outputscience.m
    % Ex: Due to an_outputscience.m disabled
    % Ex: Lapdog run where analysis.m is disabled (useful for CALIB2 generation)
    % Ex: EDDER does not call analysis.m
    % In principle, the same problem could exist for other global variables (e.g. when disabling an_outputscience) but
    % it does not appear to do so from testing.
    %
    % NOTE: Can not write an (elegant) function for this, since evalin can only work on the caller's workspace, not the
    % caller's caller.
    %===================================================================================================================
%     POT_UNDEF_VARS = {'der_struct', 'an_tabindex', 'ASW_tabindex', 'PHO_tabindex', 'efl_tabindex', 'NPL_tabindex'};   % Potentially undefined variables.
%     for i = 1:length(POT_UNDEF_VARS)
%         % IMPLEMENTATION NOTE: There are Lapdog subdirectories "index" and "an_tabindex" which the function "exist"
%         %                      may detect/respond to if not specifying "var".
%         if evalin(MWS, sprintf('exist(''%s'', ''var'')', POT_UNDEF_VARS{i}))
%             temp = evalin(MWS, POT_UNDEF_VARS{i});                            % NOTE: evalin
%         else
%             temp = [];
%         end
%         WorkspaceVars.(POT_UNDEF_VARS{i}) = temp;
%     end
    
    
    
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
    Clfd.metakernel        = get_lapdog_metakernel();   % NOTE: Technically not part of the Lapdog state. Useful though.
    
    Clfd.index             = evalin(MWS, 'index');
    Clfd.tabindex          = evalin(MWS, 'tabindex');
    Clfd.an_tabindex       = evalin(MWS, 'get_Lapdog_var(''an_tabindex'')');     % WorkspaceVars.an_tabindex;
    Clfd.blockTAB          = evalin(MWS, 'blockTAB');
    Clfd.ASW_tabindex      = evalin(MWS, 'get_Lapdog_var(''ASW_tabindex'')');    %  WorkspaceVars.ASW_tabindex;
    Clfd.USC_tabindex      = evalin(MWS, 'usc_tabindex');                        % Changing variable case for consistency.
    Clfd.PHO_tabindex      = evalin(MWS, 'get_Lapdog_var(''PHO_tabindex'')');    % WorkspaceVars.PHO_tabindex;
    Clfd.EFL_tabindex      = evalin(MWS, 'get_Lapdog_var(''efl_tabindex'')');    % WorkspaceVars.efl_tabindex;    % Changing variable case for consistency.
    Clfd.NPL_tabindex      = evalin(MWS, 'get_Lapdog_var(''NPL_tabindex'')');    % WorkspaceVars.NPL_tabindex;
    
    Clfd.A1P_tabindex      = evalin(MWS, 'get_Lapdog_var(''der_struct'')');      % WorkspaceVars.der_struct;      % Changing variable name for consistency.
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



% Return
% (a) value of named variable in caller workspace, if there is exists exactly one such among the accessible & inaccessible, global & non-global variables, or
% (b) a default value if the named variable does not pre-exist.
% Assertion error, if there is both a non-global accessible variable and an inaccessible variable of the same name.
%
% RATIONALE
% =========
% Function is useful for variables which may or may not exist depending on the Lapdog configuration, the type of
% dataset, and EDDER/DERIV1.
%
% NOTE: It is dangerous to misspell variable names, since they will be silently accepted (not a bug but a feature).
%
function value = get_Lapdog_var(name)
    % PROPOSAL: Move to Vars_state.
    
    DEFAULT_VALUE = [];
    
    VarsInfo = evalin('caller', 'EJ_library.utils.Vars_state.get_all_vars_info()');    
    VarsInfo = VarsInfo(strcmp(name, {VarsInfo.name}));    % Only keep entries with the right name.
    
    if numel(VarsInfo) < 1
        % CASE: There is no such variable.
        value = DEFAULT_VALUE;
    elseif numel(VarsInfo) == 1
        if VarsInfo.global
            % CASE: There is such a global variable.
            value = EJ_library.utils.Vars_state.get_global_var(name);
        else
            % CASE: There is such a non-global accessible variable.
            value = evalin('caller', name);
        end        
    else
        % ASSERTION
        error('Can not read Lapdog variable "%s" due to ambiguity: There is one accessible non-global variable, and on inaccessible global variable by the same name.', name)
    end
end
