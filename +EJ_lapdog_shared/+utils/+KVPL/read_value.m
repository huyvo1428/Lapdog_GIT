%
% Return value associated with a particular key.
%
function value = read_value(kvl, key)
    iKv = find(strcmp(key, kvl.keys));
    if length(iKv) ~= 1
        error('Key-value list does not have exactly one of the specified key="%s".', key)
    end
    value = kvl.values{iKv};
end
