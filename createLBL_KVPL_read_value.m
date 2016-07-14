%
% Return value associated with a particular key.
%
function value = createLBL_KVPL_read_value(kvl, key)
    i_kv = find(strcmp(key, kvl.keys));
    if length(i_kv) ~= 1
        error(sprintf('Key-value list does not have exactly one of the specified key="%s".', key))
    end
    value = kvl.values{i_kv};
end
