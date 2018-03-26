% Delete keys (and corresponding values) from key-value pair list by listing keys.
%
% ARGUMENTS
% =========
% keyList : Cell array of strings.
% policy  : String. How to handle non-existent keys.
%               'require keys'  : keyList MUST             be a subset of kvl.keys.
%               'may have keys' : keyList DOES NOT HAVE TO be a subset of kvl.keys.
%
% function kvl = delete_keys(kvl, keyList, policy)
  function kvl = delete_keys(kvl, keyList, policy)
    % NOTE: Current implementation permits keyList having repeating keys in keyList.

    if strcmp(policy, 'require keys')
        if ~all(ismember(keyList, kvl.keys))
            error('keyList is not a subset of kvl.keys.')
        end
    elseif ~strcmp(policy, 'may have keys')
        error('Value for parameter "policy" not valid.')
    end
        
    keysToDelete = intersect(kvl.keys, keyList);
    iDelete = ismember(kvl.keys, keysToDelete);

    kvl.keys(iDelete)   = [];
    kvl.values(iDelete) = [];

end
