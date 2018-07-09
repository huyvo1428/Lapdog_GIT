% 
% (1) Assumes that kvl1 and kvl2 have no keys in common (error otherwise), and
% (2) return key-value pair list with the key-value pairs of kvl1 and kvl2 combined.
%
% NOTE: Compare KVPL.overwrite_values
%
% function kvlDest = merge(kvl1, kvl2)
function   kvlDest = merge(kvl1, kvl2)
%
% PROPOSAL: Policy argument
%    (1) Accept no duplicate keys.
%       NOTE: Current implementation.
%    (2) Accept duplicate keys when the values are identical.
%       PRO: Useful for createLBL_create_EST_LBL_header.
%    QUESTION: How handle ordering?

    intersectingKeysList = intersect(kvl1.keys, kvl2.keys);
    if ~isempty(intersectingKeysList)
        error('ERROR: kvl1 and kvl2 have %i keys in common, e.g. key = "%s".', numel(intersectingKeysList), intersectingKeysList{1});
    end
    
    kvlDest = [];
    kvlDest.keys   = [kvl1.keys(:);   kvl2.keys(:)  ];
    kvlDest.values = [kvl1.values(:); kvl2.values(:)];

end
