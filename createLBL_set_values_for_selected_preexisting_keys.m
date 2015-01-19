%
% Set key-value pairs (kvl_set) for the corresponding, already existing, keys in other key-value list (kvl).
% Error otherwise.
%
function kvl = createLBL_set_values_for_selected_preexisting_keys(kvl, kvl_set)

    for i_kv_set = 1:length(kvl_set.keys)
        key   = kvl_set.keys{i_kv_set};
        value = kvl_set.values{i_kv_set};
        
        i_kvl = find(strcmp(key, kvl.keys));

        if isempty(i_kvl)
            error(sprintf('ERROR: Tries to set LBL/ODL key that does not yet exist in source: (key, value) = (%s, %s)', key, value));
        elseif length(i_kvl) > 1
            error(sprintf('ERROR: Found multiple keys with the same value in kvl: key = %s', key));
        else
            kvl.values{i_kvl} = value;
        end
    end
    
end
