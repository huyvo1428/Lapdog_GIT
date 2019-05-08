%
% General-purpose code for saving and loading the ~state of MATLAB (variables) by saving
% (1) all accessible variables in the caller workspace, and
% (2) all inaccessible variables.
% Primarily made for Lapdog. Could be useful for interfacing between code that uses global variables, and code that does
% not.
%
%
% NOTES
% =====
% NOTE: Can (partly) not handle persistent variables (assertion). Not sure how to handle.
% NOTE/INCOMPLETE: Can not handle variables too big for a single .mat file but one can ignore them and handle
% them manually (e.g. using Store_split_array2) instead.
% NOTE: The original intent was to also implement support for storing large variables separately using
% Store_split_array2, but that has been abandonded for now. The commented code, and the design reflects that.
% NOTE: Overwrites pre-existing .mat files.
%
%
% STORAGE/FILE FORMAT
% ===================
% Variables will be stored in zero to two .mat files.
% If there are accessible   variables (global and non-global), then those will be stored in one file.
% If there are inaccessible variables (only global),           then those will be stored in one file.
% Global variables are somehow tagged as global in .mat files by MATLAB, which is important when variables are loaded.
% MATLAB does not appear to be able to save zero variables to a .mat file.
% Therefore, no .mat files containing zero variables files are ever saved.
% Therefore, the .mat files can not be assumed to exist when looking for them. If one or the other file does not exist,
% then it is assumed that there were not variables of that kind.
%
%
% DEFINITIONS
% ===========
% Global variable       : A global variable, regardless of whether it is accessible or not.
% Non-global variable   : A variable which is not a global variable.
% Accessible variable   : A variable which can be invoked, i.e. read or
%                         assigned. Non-global variables are always accessible in the workspace they are initialized
%                         (until they are cleared and cease to exist). Global variables can be either accessible or
%                         inaccessible, at a particular time and in a particular workspace.
%                         NOTE: A variable is accessible or not depending on the workspace.
%                         NOTE: A global variable can change between being accessible and inaccessible.
%                         NOTE: MATLAB may have some other official term for this.
% Non-accessible/
% inaccessible variable : A variable which is not accessible.
% SSA                   : Store_split_array2. Abandonded functionality implemented through external code for storing
%                         large variables separately.
%
%
% Initially created 2019-04-08 by Erik P G Johansson.
%
classdef Vars_state
    % TEST CODE: clear; clear global; global x; x=2; clear x; x=1; global x
    % TEST CODE: Declare
    %   non-accessible     global variable x
    %   accessible     non-global variable x
    %   accessible         global variable y
    %   non-accessible     global variable z
    %       clear; clear global; global x y z; x=2; y=2; z=2; clear x y; x=1; whos; disp ---; whos global
    %   ==> Can show that
    %       s=whos           : All accessible global and non-global variables.
    %       s=whos('global') : All global variables.
    %
    % NOTE: It appears that calling
    % (1) "global x" for an    EXISTING GLOBAL variable irreversibly(?) deletes any preexisting non-global variable x.
    % (2) "global x" for a  NONEXISTING GLOBAL variable transforms              any preexisting non-global variable into a global one.
    % There can thus not simultaneously exist a non-global and a global variable by the same name (in the same
    % workspace).
    % NOTE: save/load .mat files can store and restore variables as global.
    % NOTE: "save ... -regexp ^(?!(x)$)" excludes all variables named x, both non-global and global.
    % NOTE: "save ... x" always saves the accessible variable. Can not specify non-accessible global variable.

    methods(Static, Access=public)



        % Return array of structs with information on all variables, both accessible and inaccessible, in the caller's
        % workspace.
        %
        %
        % RETURN VALUE
        % ============
        % VarsInfo : Same kind of struct array as returned by "whos", but amended with the field ".accessible".
        %
        function VarsInfo = get_all_vars_info
            
            % Obtain (overlapping) info on existing variables.
            AccVarsInfo  = evalin('caller', 'whos()');   % NOTE: Command can not be put in a local/nested function.
            GlobVarsInfo = whos('global');
            
            % Derive InaccGlobVarsInfo without overlap with AccVarsInfo.
            inaccGlobVarNames = setdiff(...
                {GlobVarsInfo.name}, ...
                {AccVarsInfo([AccVarsInfo.global]).name});
            InaccGlobVarsInfo = GlobVarsInfo(ismember({GlobVarsInfo.name}, inaccGlobVarNames));
            
            [AccVarsInfo(:).accessible      ] = deal(true);
            [InaccGlobVarsInfo(:).accessible] = deal(false);
            
            VarsInfo = [AccVarsInfo; InaccGlobVarsInfo];
            
        end
        
        
        
        % Get the value of an arbitrary global variable. Error if it does not pre-exist.
        %
        % RATIONALE
        % =========
        % Get the value of an arbitrary global variable
        % (1) without risking name collisions when working with arbitrary global variable names,
        % (2) without mistakenly declaring a new empty global variable value if the specificed global variable turns out to not pre-exist.
        function value = get_global_var(name)
            % PROPOSAL: Add optional argument for defaultValue.
            %       No extra argument : Require global var (backward compatible),
            %       Extra argument    : Do not require pre-existing global var.
            
            if ~isempty(whos('global'))
                
                % IMPLEMENTATION NOTE: Want code to be able to function also if there are name collisions between the
                % global variable name, and other variables used in the implementation. Therefore, want to call eval
                % exactly ONCE, so that variable "name" is irrelevant after its execution.
                eval(sprintf('global %s; value = %s;', name, name));
            else
                % ASSERTION
                error('There is no global variable "%s"', name)
            end
        end
        
        
        
        % Save (1) all "accessible variables" in the caller workspace, and (2) all global variables (regardless of
        % workspace) to .mat files.
        %
        %
        % ARGUMENTS
        % =========
        % accVarsFile    : Path and filename to .mat file for saving accessible   variables.
        % inaccVarsFile  : Path and filename to .mat file for saving inaccessible variables.
        % varargin       : Either (1) nothing, or
        %                  (2) Variables which should be ignored. Struct array with fields
        %                  .name   : Name of variable.
        %                  .global : Whether variable is global or not.
        %
        %
        % Initially created 2019-03-20 by Erik P G Johansson.
        %
        function save(accVarsFile, inaccVarsFile, varargin)
            % TODO-DECISION: How test code?
            % PROPOSAL: Save all global variables via function in which they are declared global.
            % PROPOSAL: Save all non-global variables via save and named list of variables (to avoid the global variables)
            % NOTE: Still need to save list of global accessible variables. With global variables?! How??
            % PROPOSAL: Remake into class with two public static methods.
            %   PRO: Will need functions for constructing filenames.
            %
            % PROPOSAL: Separate save/load code into two parts:
            %   (1) Functions for converting caller variables <---> structs
            %   (2) Functions for converting structs          <---> .mat files
            %   NOTE: Can store structs as such in .mat, or as multiple variables in .mat.
            %       NOTE: load permits reading a file so that variables are loaded into a single struct.
            %   CON: Does not make sense, since can only return the variables to the workspace from which it was called.
            %       CON: Can call vars_state_load from function f using evalin and only capture the return value in f (without creating/setting "ans").
            %   CON: Can not use these to save a .mat file which automatically loads global variables as global.
            %
            % PROPOSAL: evalin workspace as argument.
            %
            % TODO-DECISION: How specify special treatment of large variables?
            %   PROPOSAL: List of variable names.
            %   PROPOSAL: All variables larger than N indices.
            %   PROPOSAL: All variables larger than N bytes. (Use ~whos.bytes).



            if isempty(varargin)
                ignoreVarsInfo = struct('name', {} ,'global', {});
            elseif numel(varargin) == 1
                ignoreVarsInfo = varargin{1};
            else
                error('Illegal number of varargin.')
            end
            EJ_library.utils.assert.struct(ignoreVarsInfo, {'name', 'global'})
            
            
            
            VarsInfo = evalin('caller', 'EJ_library.utils.Vars_state.get_all_vars_info');
            
            % Add and set flag .ignore
            %[VarsInfo(:).useSsa]          = deal(false);
            %[VarsInfo(:).nIndicesPerFile] = deal(NaN);
            [VarsInfo(:).ignore]          = deal(false);
            for i = 1:numel(ignoreVarsInfo)
                
                jMatches = strcmp(ignoreVarsInfo(i).name, {VarsInfo.name}) & (ignoreVarsInfo(i).global == [VarsInfo.global]);
                
                % ASSERTION
                if sum(jMatches) ~= 1
                    error('ignoreVarsInfo(%i) matches %i variables (i.e. does not match exactly one variable).', i, numel(jMatches))
                end
                %VarsInfo(jMatches).useSsa = true;
                %VarsInfo(jMatches).nIndicesPerFile  = ssaVarsInfo(i).nIndicesPerFile;
                VarsInfo(jMatches).ignore = true;
            end



            % ASSERTION: No persistant variables.
            assert(~any([VarsInfo.persistent]))



            % Variables to save directly (variable name lists)
            %accVarsToSaveInfo   = VarsInfo( [VarsInfo.accessible] & ~[VarsInfo.useSsa]);
            %inaccVarsToSaveInfo = VarsInfo(~[VarsInfo.accessible] & ~[VarsInfo.useSsa]);
            accVarsToSaveInfo   = VarsInfo( [VarsInfo.accessible] & ~[VarsInfo.ignore]);
            inaccVarsToSaveInfo = VarsInfo(~[VarsInfo.accessible] & ~[VarsInfo.ignore]);
            % Variables to save using Store_split_array.
            %ssaVarsToSaveInfo = VarsInfo([VarsInfo.useSsa]);            



            %======================================================
            % Save the SPECIFIED ACCESSIBLE variables to .mat file
            %======================================================
            if ~isempty(accVarsToSaveInfo)
                saveCmd = [sprintf('save ''%s''', accVarsFile), sprintf(' ''%s''', accVarsToSaveInfo.name)];
                evalin('caller', saveCmd)   % NOTE: Command can not be put in a local/nested function.
            end



            %==================================================
            % Save the SPECIFIED GLOBAL variables to .mat file
            %==================================================
            EJ_library.utils.Vars_state.save_global_variables(inaccVarsFile, {inaccVarsToSaveInfo.name})
            
            
            
            %==================================================
            % Save specified variables using Store_split_array
            %==================================================
%             for i = 1:numel(ssaVarsToSaveInfo)
%                 
%                 metadata = ssaVarsToSaveInfo(i);
%                 ssaVariablePathPrefix = get_ssa_path_prefix(ssaVarsToSaveInfo(i).name, ssaVarsToSaveInfo(i).global);
%                 
%                 EJ_library.utils.Store_split_array2.save(...
%                     evalin('caller', ssaVarsToSaveInfo(i).name), ...
%                     metadata, ...
%                     ssaVariablePathPrefix, ...
%                     ssaVarsToSaveInfo(i).nIndicesPerFile)
%             end
        end
        
        
        
        % Initially created 2019-03-20 by Erik P G Johansson.
        function load(accVarsFile, inaccVarsFile)
            
            %==========================================
            % Load ACCESSIBLE variables from .mat file
            %==========================================
            if exist(accVarsFile, 'file')
                loadCmd = sprintf('load ''%s''', accVarsFile);
                evalin('caller', loadCmd)    % NOTE: Command can not be put in a local/nested function.
            end
            
            %============================================
            % Load INACCESSIBLE variables from .mat file
            %============================================
            EJ_library.utils.Vars_state.load_global_variables(inaccVarsFile)
            
            %========================================================
            % Load variables from .mat files with Store_split_array2
            %========================================================
            %filesInfo = dir([ssaPathPrefix, '*.000000.mat']);
            %for i = 1:numel(filesInfo)
            %    
            %end
        end
        
        
        
    end    % methods(Static, Access=public)
    
    
    
    methods(Static, Access=private)
        
        
        
        % Save SPECIFIED global variables (e.g. only inaccessible global variables).
        function save_global_variables(saveFile, globalVarNameList)
            if ~isempty(globalVarNameList)
                % feval('global', globalVarNameList{:}) % NOTE: Works in MATLAB R2009a, but not R2016a.
                
                for i = 1:numel(globalVarNameList)
                    eval(sprintf('global %s', globalVarNameList{i}))
                end
                
                save(saveFile,  globalVarNameList{:})
            end
        end
        
        
        
        % Load global variables without making them accessible.
        % 
        % Assumes that the .mat file only contains global variables, so that "load" will automatically initialize the
        % loaded variables as global.
        function load_global_variables(globalSaveFile)
            if exist(globalSaveFile, 'file')
                load(globalSaveFile)
            end
        end



        % Return path prefix for specific variable.
        %
        % ssaPathPrefix : Path prefix for Store_split_array variables in general.
%         function ssaVariablePathPrefix = get_ssa_path_prefix(ssaPathPrefix, varName, isGlobal)
%             if isGlobal
%                 globalFlagStr = 'global';
%             else
%                 globalFlagStr = 'nonglobal';
%             end
%             
%             ssaVariablePathPrefix = [ssaPathPrefix, ...
%                 sprintf('.%s.%s.', varName, globalFlagStr)];
%         end
        
        
        
    end    % methods(Static, Access=private)
    
end
