%
% Function for substituting old PDS/PSA LBL header keywords (keys in key-value pairs) for new ones.
%
% This is to ensure compatibility with CALIB archives that still contain old keywords.
% At some point, when all CALIB archives with obsoleted keywords are gone, then this
% code can be modified or removed.
%
% function kvl = createLBL_compatibility_substitute_LBL_keys(kvl, probe_nbr)
function   kvl = createLBL_compatibility_substitute_LBL_keys(kvl, probe_nbr)

    old_keys = { ...
        'ROSETTA:LAP_INITIAL_SWEEP_SMPLS', ...
        'ROSETTA:LAP_SWEEP_PLATEAU_DURATION', ...
        'ROSETTA:LAP_SWEEP_STEPS', ...
        'ROSETTA:LAP_SWEEP_START_BIAS' };
    replacement_keys = { ...
        sprintf('ROSETTA:LAP_P%i_INITIAL_SWEEP_SMPLS',    probe_nbr), ...
        sprintf('ROSETTA:LAP_P%i_SWEEP_PLATEAU_DURATION', probe_nbr), ...
        sprintf('ROSETTA:LAP_P%i_SWEEP_STEPS',            probe_nbr), ...
        sprintf('ROSETTA:LAP_P%i_SWEEP_START_BIAS',       probe_nbr) };

    for i = 1:length(replacement_keys)
        kvl = KVPL_substitute_key_name_INTERNAL(kvl, old_keys{i}, replacement_keys{i});
    end
    
    %=============================================================================================

    function   kvl = KVPL_substitute_key_name_INTERNAL(kvl, key_name_old, key_name_new)
        
        i_kv_new = find(strcmp(key_name_new, kvl.keys));
        i_kv_old = find(strcmp(key_name_old, kvl.keys));
        
        % Check whether the new key name results in key collision.
        if length(i_kv_new) > 0
            error(sprintf('Can not substitute a key name for a key name that the key-value list already contains: key_name_new="%s".', key_name_new))
        end
        
        % Check whether old key name exists.
        if length(i_kv_old) > 1
            error('Key-value list has multiple identical keys."')
        %else if length(i_kv_old) == 0
        %    error(sprintf('Key-value list does not have the specified key_name_old="%s".', key_name_old))
        elseif length(i_kv_old) == 1
            % Change name of key.
            kvl.keys{i_kv_old} = key_name_new;
        end
        
    end

end
