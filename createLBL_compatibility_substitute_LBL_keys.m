%
% Function for substituting old PDS/PSA LBL keywords (keys in key-value pairs) for new ones.
%
% This is to ensure compatibility with CALIB archives that still contain old keywords.
% At some point, when all CALIB archives with obsoleted keywords are gone, then this
% code can be modified, disabled or removed.
%
% NOTE: Disabled for "probe 3" since the meaning might be ambiguous. Otherwise no problem.
% NOTE: This code can NOT be moved to createLBL_write_LBL_header.m since it has to be run before
% the best estimates LBL code merges keywords from two LBL files.
%
% function kvl = createLBL_compatibility_substitute_LBL_keys(kvl, probe_nbr)
function   kvl = createLBL_compatibility_substitute_LBL_keys(kvl, probe_nbr)
%
% PROPOSAL: Move functionality into createLBL_read_LBL_file.
%

    kvl = main_INTERNAL(kvl, probe_nbr);

    %=============================================================================================
    
    function kvl = main_INTERNAL(kvl, probe_nbr)
        if ~ismember(probe_nbr, [1 2])
            error(sprintf('Illegal probe number. probe_nbr=%d', probe_nbr))
        end
        
        old_keys = { ...
            'ROSETTA:LAP_INITIAL_SWEEP_SMPLS', ...
            'ROSETTA:LAP_SWEEP_PLATEAU_DURATION', ...
            'ROSETTA:LAP_SWEEP_STEPS', ...
            'ROSETTA:LAP_SWEEP_START_BIAS', ...
            'ROSETTA:LAP_SWEEP_FORMAT', ...
            'ROSETTA:LAP_SWEEP_RESOLUTION', ...
            'ROSETTA:LAP_SWEEP_STEP_HEIGHT'};
        replacement_keys = { ...
            sprintf('ROSETTA:LAP_P%i_INITIAL_SWEEP_SMPLS',    probe_nbr), ...
            sprintf('ROSETTA:LAP_P%i_SWEEP_PLATEAU_DURATION', probe_nbr), ...
            sprintf('ROSETTA:LAP_P%i_SWEEP_STEPS',            probe_nbr), ...
            sprintf('ROSETTA:LAP_P%i_SWEEP_START_BIAS',       probe_nbr), ...
            sprintf('ROSETTA:LAP_P%i_LAP_SWEEP_FORMAT',       probe_nbr), ...
            sprintf('ROSETTA:LAP_P%i_SWEEP_RESOLUTION',       probe_nbr), ...
            sprintf('ROSETTA:LAP_P%i_SWEEP_STEP_HEIGHT',      probe_nbr) };

        N_substitutions = 0;
        for i = 1:length(replacement_keys)
            [kvl, N_s] = KVPL_substitute_key_name_INTERNAL(kvl, old_keys{i}, replacement_keys{i});
            N_substitutions = N_substitutions + N_s;
        end
        if N_substitutions > 0
            msg = sprintf('NOTE: CALIB archive file contains obsoleted PDS LBL keywords. Renamed %i PDS keywords.', N_substitutions);
            disp(msg)     % Disable log message?
            %warning(msg)    % Disable log message?
        end
    end
    
    %=============================================================================================

    % Rename specific old keyword for new keyword if the old keyword can be found.
    %
    % NOTE: If kvl.keys contains both the old keyword and the new keyword there is an error.
    % NOTE: Is really a generic library function.
    %
    function [kvl, N_substitutions] = KVPL_substitute_key_name_INTERNAL(kvl, key_name_old, key_name_new)
        
        N_substitutions = 0;
        
        i_kv_new = find(strcmp(key_name_new, kvl.keys));
        i_kv_old = find(strcmp(key_name_old, kvl.keys));        
        
        % Check whether old keyword exists.
        if length(i_kv_old) > 1
            error('Key-value list has multiple identical keys."')
            
        %else if length(i_kv_old) == 0
        %    error(sprintf('Key-value list does not have the specified key_name_old="%s".', key_name_old))
        elseif length(i_kv_old) == 1
            
            % Check whether the new keyword change results in key collision.
            if ~isempty(i_kv_new)
                error(sprintf('Can not substitute a key name for a key name that the key-value list already contains: key_name_new="%s".', key_name_new))
            end
            
            % Change name of key.
            kvl.keys{i_kv_old} = key_name_new;
            N_substitutions = 1;
            %fprintf(1, '%s: Renaming keywords for compatibility with old archives: %s --> %s\n', mfilename, key_name_old, key_name_new)    % Disable log message?
        end
        
    end

end
