%
% Read value for "key" in "kvlSrc", and
% add new corresponding key-value pair to "kvlDest".
%
% function kvlDest = add_copy_of_kv_pair(kvlSrc, kvlDest, key)
function   kvlDest = add_copy_of_kv_pair(kvlSrc, kvlDest, key)
% PROPOSAL: New name. 
% PROPOSAL: Rationalize away this function?

    value   = EJ_lapdog_shared.EJ_utils.KVPL.read_value( kvlSrc,  key);
    kvlDest = EJ_lapdog_shared.EJ_utils.KVPL.add_kv_pair(kvlDest, key, value);
    
end
