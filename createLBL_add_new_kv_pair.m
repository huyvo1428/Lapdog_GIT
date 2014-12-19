function kv = createLBL_add_new_kv_pair(kv, key, value)
    kv.keys  {end+1, 1} = key;
    kv.values{end+1, 1} = value;
end
