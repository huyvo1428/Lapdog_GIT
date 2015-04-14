%
% Read value for "key" in "kvl_src", and
% add new corresponding key-value pair to "kvl_dest".
%
% function kvl_dest = createLBL_KVPL_add_copy_of_kv_pair(kvl_src, kvl_dest, key)
function   kvl_dest = createLBL_KVPL_add_copy_of_kv_pair(kvl_src, kvl_dest, key)
% PROPOSAL: New name. 
% PROPOSAL: Rationalize away this function?

    value    = createLBL_KVPL_read_value( kvl_src,  key);
    kvl_dest = createLBL_KVPL_add_kv_pair(kvl_dest, key, value);
    
end
