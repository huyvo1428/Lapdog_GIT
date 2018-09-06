%
% Create new KVPL.
%
%
% ARGUMENTS
% =========
% kvplContentCellArray : Nx2 cell array of strings.
%                        kvplContentCellArray{iRow,1} = key
%                        kvplContentCellArray{iRow,2} = value
%
%
% Initially created 2018-08-29 by Erik P G Johansson.
%
function Kvpl = create(kvlContentCellArray)
    if isempty(kvlContentCellArray)
        kvlContentCellArray = cell(0,2);
    end
    
    Kvpl = [];
    Kvpl.keys   = kvlContentCellArray(:,1);
    Kvpl.values = kvlContentCellArray(:,2);
    
    Kvpl = EJ_lapdog_shared.utils.KVPL.assert_KVPL(Kvpl);
end
