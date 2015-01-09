%
% Set key-value pairs (kv_set) for the corresponding, already existing, keys in other key-value list (kv).
% Error otherwise.
%
function kv = createLBL_set_values_for_selected_preexisting_keys(kv, kv_set)
    for i_kvs = 1:length(kv_set.keys)
        key   = kv_set.keys{i_kvs};
        value = kv_set.values{i_kvs};
        i_kv = find(strcmp(key, kv.keys));

        if ~isempty(i_kv)
            kv.values{i_kv} = value;
        else
            error(sprintf('ERROR: Tries to set LBL/ODL key that does not yet exist in source: (key, value) = (%s, %s)', key, value));
        end
    end
end
