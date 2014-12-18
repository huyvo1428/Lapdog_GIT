function kv_dest = createLBL_add_copy_of_kv_pair(kv_src, kv_dest, key)
    value   = createLBL_read_kv_value(kv_src, key);
    kv_dest = createLBL_add_new_kv_pair(kv_dest, key, value);
end