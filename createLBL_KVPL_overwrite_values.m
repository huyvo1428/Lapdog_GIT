% 
% For every key in kvl_src,
% (1) assumes that the same key DOES exist in kvl_dest (error otherwise), and
% (2) sets the corresponding value in kvl_dest.
%
% NOTE: Compare KVPL_add_kv_pairs
%
% function kvl_dest = createLBL_KVPL_overwrite_values(kvl_dest, kvl_src, policy)
function   kvl_dest = createLBL_KVPL_overwrite_values(kvl_dest, kvl_src, policy)
%
% PROPOSAL: New name. Want something that implies only preexisting keys, and overwriting old values.
%   set_values
%   import_values
%   override_values
%   overwrite_values
%

switch(policy)
    case 'overwrite only when has keys'
        require_overwrite = 0;
    case 'require preexisting keys'
        require_overwrite = 1;
    otherwise
        error('Illegal "policy" argument.')
end

for i_kv_src = 1:length(kvl_src.keys)
    
    key_src   = kvl_src.keys{i_kv_src};
    value_src = kvl_src.values{i_kv_src};
    i_kvl_dest = find(strcmp(key_src, kvl_dest.keys));
    
    if isempty(i_kvl_dest)
        if require_overwrite
            error('ERROR: Tries to set key that does not yet exist in kvl_dest: (key, value) = (%s, %s)', key_src, value_src);
        end
    elseif numel(i_kvl_dest) == 1
        % CASE: There is exactly one of the key that was sought.
        kvl_dest.values{i_kvl_dest} = value_src;      % No error ==> Set value.
    else
        error('ERROR: Found multiple keys with the same value in kvl_dest: (key, value) = (%s, %s)', key_src, value_src);
    end
    
end

end
