%
% Effectively ~defines what is a legal KVPL.
%
% Initially created 2018-07-10 by Erik P G Johansson.
%
function Kvl = assert_KVPL(Kvl)
    % TODO-DECISION: Include "normalization"?
    % PROPOSAL: Check for strings in keys, unique keys.
    
    % ASSERTION
    EJ_lapdog_shared.utils.assert.struct(Kvl, {'keys', 'values'})
    %if ~isempty(setxor(fieldnames(Kvl), {'keys', 'values'}))
    %    error('Argument KVPL does not contain the fields of a legal KVPL.')
    %end    
    if ~is_vector(Kvl.keys)
        error('Argument Kvl.keys has illegal dimensions.')
    end    
    if ~is_vector(Kvl.values)
        error('Argument Kvl.values has illegal dimensions.')
    end    
    
    if ~(length(Kvl.keys) == length(Kvl.values))
        error('Argument KVPL fields have different array sizes.')
    end
    
    
    
    % NORMALIZE
    Kvl.keys   = Kvl.keys(:);
    Kvl.values = Kvl.values(:);
end



% Unclear if this is a good way of checking/requiring vectors.
function isVec = is_vector(v)
    %isVec = ((size(v, 2) == 1) && (ndims(v) <= 2)) || isempty(v);
    isVec = isvector(v) || isempty(v);
end
