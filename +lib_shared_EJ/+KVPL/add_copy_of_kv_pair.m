%
% Read value for "key" in "kvlSrc", and
% add new corresponding key-value pair to "kvlDest".
%
% function kvlDest = add_copy_of_kv_pair(kvlSrc, kvlDest, key)
function   kvlDest = add_copy_of_kv_pair(kvlSrc, kvlDest, key)
% PROPOSAL: New name. 
% PROPOSAL: Rationalize away this function?

    value   = lib_shared_EJ.KVPL.read_value( kvlSrc,  key);
    kvlDest = lib_shared_EJ.KVPL.add_kv_pair(kvlDest, key, value);
    
end
