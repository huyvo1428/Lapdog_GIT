% Return Lapdog default metakernel. Use default file in Lapdog directory which the rest of Lapdog uses.
% 
% ASSUMPTION: Current script is located in Lapdog directory.
% NOTE: Partly created so that code external to Lapdog can easily obtain the Lapdog metakernel.
%
%
% Initially created by Erik P G Johansson, IRF Uppsala.
function metakernel = get_lapdog_metakernel()
    % PROPOSAL: Use readlink -f to de-reference symlinks?!!
    
    currentMFile = mfilename('fullpath');
    [lapdogDir, basenameJunk, extJunk] = fileparts(currentMFile);
    metakernel = fullfile(lapdogDir, 'metakernel_rosetta.txt');
    if ~exist(metakernel, 'file')
        error('Can not find kernel file "%s"', metakernelFile)
        % Call error too?
    end
    
end