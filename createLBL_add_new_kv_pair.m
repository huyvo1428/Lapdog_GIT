% Add new key-value pair to key-value list.
%
% NOTE: Checks that key has not already been set.
function kv = createLBL_add_new_kv_pair(kv, key, value)
    if ismember(key, kv.keys)
        error(sprintf('Can not add key which is already in key-value list (key = "%s").', key))
    end
    kv.keys  {end+1, 1} = key;
    kv.values{end+1, 1} = value;
end
