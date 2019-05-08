%
% Save Lapdog's MATLAB "state" to .mat files at any given point in the root function/script, so that Lapdog can be rerun
% from those points without having to start over again.
% In particular intended for saving the state before analysis and before createLBL.
% Saves all accessible & inaccessible variables from the caller's workspace.
%
%
% ARGUMENTS
% =========
% permitOverwrite : true/false whether to permit (no assertion) overwriting old files.
%
%
% Initially created 2019-04-09 by Erik P G Johansson, IRF Uppsala.
%
function save_Lapdog_state(saveDir, permitOverwrite, stateNaming)
    
    C = createLBL.constants();
    
    [accVarsFile, inaccVarsFile, indexPathPrefix] = createLBL.constants.get_state_filenaming(saveDir, stateNaming);
    
    fprintf('Saving MATLAB workspace+globals\n');
    
    % ~ASSERTION
    if ~permitOverwrite && (exist(accVarsFile, 'file') || exist(inaccVarsFile, 'file'))
        fprintf('Aborting saving variables - At least one of the files pre-exists. Will not overwrite.\n')
        return
    end



    %==========================================================================================================
    % SAVE STATE
    % ----------
    % IMPLEMENTATION NOTE: It has been observed (2018-12-01) that variable "index" can be too large to save to
    % disk for PRL and ESC3, thus generating a warning message "Warning: Variable 'index' cannot be saved to a
    % MAT-file whose version is older than 7.3.". Note that it is a warning, not an error. Lapdog continues to
    % execute, but the .mat file saved to disk simply does not contain the "index" variable. One should in
    % principle be able to solve this by using flag "-v7.3" but experience is that this is (1) impractically
    % slow, and (2) results in much larger .mat files.
    %==========================================================================================================
    try
        executionBeginDateVec = clock;
        cmd = sprintf('EJ_library.utils.Vars_state.save(''%s'', ''%s'', struct(''name'', ''index'', ''global'', false))', ...
            accVarsFile, inaccVarsFile);
        evalin('caller', cmd)
        
        %fprintf('Saving MATLAB variable "index" in "%s*"\n', indexPathPrefix);
        index = evalin('caller', 'index');
        EJ_library.utils.Store_split_array2.save(index, [], indexPathPrefix, C.N_INDEX_INDICES_PER_PART)
        
        fprintf('    Done saving variables to disk: %.0f s (elapsed wall time)\n', etime(clock, executionBeginDateVec));
        
    catch Exception
        
        EJ_library.utils.exception_message(Exception, 'message+stack trace')
        fprintf(1,'Aborting saving index to files - Continuing\n');
        
    end
    
end
