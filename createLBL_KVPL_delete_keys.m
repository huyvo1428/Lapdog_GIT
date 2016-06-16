% Delete keys (and corresponding values) from key-value pair list by listing keys.
%
% policy == 'require keys'  : key_list MUST             be a subset of kvl.keys.
% policy == 'may have keys' : key_list DOES NOT HAVE TO be a subset of kvl.keys.
%
% function kvl = createLBL_KVPL_delete_keys(kvl, key_list, policy)
  function kvl = createLBL_KVPL_delete_keys(kvl, key_list, policy)
    % NOTE: Current implementation permits key_list having repeating keys in key_list.

    if strcmp(policy, 'require keys')
        if ~all(ismember(key_list, kvl.keys))
            error('key_list is not a subset of kvl.keys.')
        end
    elseif ~strcmp(policy, 'may have keys')
        error('Value for parameter "policy" not valid.')
    end
        
    keys_to_delete = intersect(kvl.keys, key_list);
    i_delete = ismember(kvl.keys, keys_to_delete);

    kvl.keys(i_delete)   = [];
    kvl.values(i_delete) = [];

end
