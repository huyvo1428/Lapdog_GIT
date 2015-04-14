%
% Return value associated with a particular key.
%
function value = createLBL_KVPL_read_value(kvl, key)
    i_kv = find(strcmp(key, kvl.keys));
    value = kvl.values{i_kv};
end
