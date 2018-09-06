%
% Add multiple key-value pairs to a KVPL.
% Intended for replacing (shortening) sequences of ~hardcoded calls to EJ_lapdog_shared.utils.KVPL.add_kv_pair.
%
%
% ARGUMENTS
% =========
% Kvpl
% kvplContentCellArray : Nx2 cell array of strings.
%                        kvplContentCellArray{iRow,1} = key
%                        kvplContentCellArray{iRow,2} = value
%
%
% Initially created 2018-07-10 by Erik P G Johansson.
%
function Kvpl = add_kv_pairs(Kvpl, kvplContentCellArray)
% PROPOSAL: Use some generic SFSSC function.

    % ASSERTIONS
    EJ_lapdog_shared.utils.KVPL.assert_KVPL(Kvpl);
    if size(kvplContentCellArray, 2) ~= 2
        error('kvplContentCellArray has the wrong number of columns.')
    end
    if ndims(kvplContentCellArray) > 2
        error('kvplContentCellArray has the wrong number of dimensions.')
    end
    
    nNewKeys = size(kvplContentCellArray, 1);
    
    Kvpl.keys(  end+1 : end+nNewKeys, 1) = kvplContentCellArray(:, 1);
    Kvpl.values(end+1 : end+nNewKeys, 1) = kvplContentCellArray(:, 2);
    
    % ASSERTION
    EJ_lapdog_shared.utils.KVPL.assert_KVPL(Kvpl);
end
