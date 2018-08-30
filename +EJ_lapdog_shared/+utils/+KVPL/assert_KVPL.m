%
% Effectively ~defines what is a legal KVPL.
%
% Initially created 2018-07-10 by Erik P G Johansson.
%
function Kvpl = assert_KVPL(Kvpl)
    % TODO-DECISION: Include "normalization"?
    % PROPOSAL: Check for strings in keys, unique keys.
    
    % ASSERTION
    EJ_lapdog_shared.utils.assert.struct(Kvpl, {'keys', 'values'})
    %if ~isempty(setxor(fieldnames(Kvpl), {'keys', 'values'}))
    %    error('Argument KVPL does not contain the fields of a legal KVPL.')
    %end    
    if ~is_vector(Kvpl.keys)
        error('Argument Kvpl.keys has illegal dimensions.')
    end    
    if ~is_vector(Kvpl.values)
        error('Argument Kvpl.values has illegal dimensions.')
    end    
    
    if ~(length(Kvpl.keys) == length(Kvpl.values))
        error('Argument KVPL fields have different array sizes.')
    end
    
    
    
    % NORMALIZE
    Kvpl.keys   = Kvpl.keys(:);
    Kvpl.values = Kvpl.values(:);
end



% Unclear if this is a good way of checking/requiring vectors.
function isVec = is_vector(v)
    %isVec = ((size(v, 2) == 1) && (ndims(v) <= 2)) || isempty(v);
    isVec = isvector(v) || isempty(v);
end
