%
% Load Lapdog's MATLAB "state" from .mat files, so that Lapdog can be rerun
% from those points without having to start over again.
% Loads accessible and inacessible variabes to the caller's workspace.
%
% See Lapdog's save_Lapdog_state, which is analogous and defines the arguments.
%
% 2019-06-20: Not used by Lapdog by itself, but could be a useful tool/utility when working/debugging with Lapdog datasets.
%
%
% Initially created 2019-06-10 by Erik P G Johansson, IRF Uppsala.
%
function load_Lapdog_state(saveDir, stateNaming)

    [accVarsFile, inaccVarsFile, indexPathPrefix] = createLBL.constants.get_state_filenaming(saveDir, stateNaming);

    fprintf('Loading MATLAB workspace+globals\n')
    
    cmd = sprintf('EJ_library.utils.Vars_state.load(''%s'', ''%s'')', accVarsFile, inaccVarsFile);
    %fprintf('cmd = %s\n', cmd)   % DEBUG
    evalin('caller', cmd)
    
    fprintf('    Loading MATLAB variable "index" in "%s*"\n', indexPathPrefix');
    index = EJ_library.utils.Store_split_array2.load(indexPathPrefix);
    assignin('caller', 'index', index)
    
    %fprintf('    Done loading variables from disk: %.0f s (elapsed wall time)\n', etime(clock, executionBeginDateVec));
    
end
