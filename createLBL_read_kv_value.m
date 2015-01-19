function value = createLBL_read_kv_value(kv, key)
    i_kv = strcmp(key, kv.keys);
    value = kv.values{i_kv};
end
