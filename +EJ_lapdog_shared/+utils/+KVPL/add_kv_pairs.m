%
% Add multiple key-value pairs to a KVPL.
% Intended for replacing (shortening) sequences of ~hardcoded calls to EJ_lapdog_shared.utils.KVPL.add_kv_pair.
%
%
% ARGUMENTS
% =========
% Kvl
% kvlContentCellArray : Nx2 cell array of strings.
%                       kvlContentCellArray{iRow,1} = key
%                       kvlContentCellArray{iRow,2} = value
%
%
% Initially created 2018-07-10 by Erik P G Johansson.
%
function Kvl = add_kv_pairs(Kvl, kvlContentCellArray)
% PROPOSAL: Use some generic SFSSC function.

    % ASSERTIONS
    EJ_lapdog_shared.utils.KVPL.assert_KVPL(Kvl);
    if size(kvlContentCellArray, 2) ~= 2
        error('kvlContentCellArray has the wrong number of columns.')
    end
    if ndims(kvlContentCellArray) > 2
        error('kvlContentCellArray has the wrong number of dimensions.')
    end
    
    nNewKeys = size(kvlContentCellArray, 1);
    
    Kvl.keys(  end+1 : end+nNewKeys, 1) = kvlContentCellArray(:, 1);
    Kvl.values(end+1 : end+nNewKeys, 1) = kvlContentCellArray(:, 2);
    
    % ASSERTION
    EJ_lapdog_shared.utils.KVPL.assert_KVPL(Kvl);
end
