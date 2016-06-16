% 
% For every key in kvl_src,
% (1) assumes that the same key DOES exist in kvl_dest (error otherwise), and
% (2) sets the corresponding value in kvl_dest.
%
% NOTE: Compare KVPL_add_kv_pairs
%
% function kvl_dest = createLBL_KVPL_overwrite_values(kvl_dest, kvl_src)
function   kvl_dest = createLBL_KVPL_overwrite_values(kvl_dest, kvl_src)
%
% PROPOSAL: New name. Want something that implies only preexisting keys, and overwriting old values.
%   set_values
%   import_values
%   override_values
%   overwrite_values
%
    for i_kv_src = 1:length(kvl_src.keys)
        
        key_src   = kvl_src.keys{i_kv_src};
        value_src = kvl_src.values{i_kv_src};
        i_kvl_dest = find(strcmp(key_src, kvl_dest.keys));        

        if isempty(i_kvl_dest)            
            error(sprintf('ERROR: Tries to set key that does not yet exist in kvl_dest: (key, value) = (%s, %s)', key_src, value_src));
        elseif length(i_kvl_dest) > 1            
            error(sprintf('ERROR: Found multiple keys with the same value in kvl_dest: (key, value) = (%s, %s)', key_src, value_src));            
        end
            
        kvl_dest.values{i_kvl_dest, 1} = value_src;      % No error ==> Set value.
            
    end
    
end
