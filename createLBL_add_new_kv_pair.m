% Add new key-value pair to key-value list.
% NOTE: Does not check if key already exists.
function kv = createLBL_add_new_kv_pair(kv, key, value)
    kv.keys  {end+1, 1} = key;
    kv.values{end+1, 1} = value;
end
