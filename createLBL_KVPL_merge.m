% Generic utility function.
% 
% (1) Assumes that kvl_1 and kvl_2 have no keys in common (error otherwise), and
% (2) return key-value pair list with the key-value pairs of kvl_1 and kvl_2 combined.
%
% NOTE: Compare with KVPL_overwrite_values.m .
%
% function kvl_dest = createLBL_KVPL_merge(kvl_1, kvl_2)
function   kvl_dest = createLBL_KVPL_merge(kvl_1, kvl_2)

    keys_intersect = intersect(kvl_1.keys, kvl_2.keys);
    if ~isempty(keys_intersect)
        error(sprintf('ERROR: kvl_1 and kvl_2 have %i keys in common, e.g. key = "%s".', numel(keys_intersect), keys_intersect{1}));
    end
    
    kvl_dest = [];
    kvl_dest.keys   = [kvl_1.keys;   kvl_2.keys  ];
    kvl_dest.values = [kvl_1.values; kvl_2.values];

end
