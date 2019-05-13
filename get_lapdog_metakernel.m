%
% Return the metakernel that _Lapdog_ uses/would use. Always returns the default file in the Lapdog directory which
% the rest of Lapdog uses.
% 
% ASSUMPTION: Current script is located in Lapdog directory.
% NOTE: Partly created so that code external to Lapdog can easily obtain the Lapdog metakernel (e.g. if it uses another
% current directory).
%
%
% Initially created 2018-11-01 by Erik P G Johansson, IRF Uppsala.
%
function metakernel = get_lapdog_metakernel()
    % PROPOSAL: Use readlink -f to de-reference symlinks?!!
    % PROPOSAL: Additionally return Lapdog directory.
    
    currentMFile = mfilename('fullpath');
    [lapdogDir, basenameJunk, extJunk] = fileparts(currentMFile);
    metakernel = fullfile(lapdogDir, 'metakernel_rosetta.txt');
    if ~exist(metakernel, 'file')
        error('Can not find metakernel file "%s"', metakernel)
    end
    
end