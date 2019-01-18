% 
% Convert a (likely absolute) path to a TAB file inside a dataset, into the corresponding path for another
% dataset path. In practise, this is used for converting paths to individual files when the dataset has moved.
%
%
% ASSUMPTIONS
% ===========
% TAB file is N levels deep under dataset root path.
%
%
% Initially created 2018-10-30 by Erik P G Johansson, IRF Uppsala.
%
function tabPath = convert_TAB_path(datasetPath, tabPath, nDirLevelsKept)
% PROPOSAL: Move into create_LBL_files since only used there.

    pathPartsList = EJ_library.utils.str_split(tabPath, filesep);
    
    tabPath = fullfile(datasetPath, pathPartsList{(end-nDirLevelsKept) : end});
end
