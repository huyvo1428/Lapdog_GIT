% Add new key-value pair to key-value list and return the result.
%
% Assumes that kvl does not already contain the key.
%
% function kvl = add_kv_pair(kvl, key, value)
function   kvl = add_kv_pair(kvl, key, value)

    if ismember(key, kvl.keys)
        error(sprintf('Can not add key which is already in key-value list (key = "%s").', key))
    end
    
    % NOTE: Add components in the "column direction".
    kvl.keys  {end+1, 1} = key;
    kvl.values{end+1, 1} = value;
    
end
