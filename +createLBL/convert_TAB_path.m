% 
% Convert a (likely absolute) path to a TAB file in a DERIV1 dataset, into the corresponding path for another
% root dataset path.
%
%
% ASSUMPTIONS
% ===========
% TAB file is three levels deep under dataset root path.
%
%
% Initially created 2018-10-30 by Erik P G Johansson, IRF Uppsala.
%
function tabPath = convert_TAB_path(datasetPath, tabPath)
    pathPartsList = EJ_lapdog_shared.utils.str_split(tabPath, filesep);
    
    tabPath = fullfile(datasetPath, pathPartsList{end-3:end});
end