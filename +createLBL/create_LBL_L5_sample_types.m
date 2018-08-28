%
% Create LBL files for TAB files PHO, USC, ASW, NPL.
%
%
% NOTE: At present, this is a free-standing program that can be run independently of Lapdog or in createLBL.
% It might be turned into, or merged into, a replacement for createLBL.m .
%
% NOTE: Will not overwrite old LBL files.
%
%
% Initially created 2018-08-27 by Erik P G Johansson, IRF Uppsala.
%
function create_LBL_L5_sample_types(deriv1Path)
    % createLBL.create_LBL_L5_sample_types('/home/data/ROSETTA/datasets/RO-A-RPCLAP-5-AST2-DERIV-V2.0___LBL_L5_sample_test')
    % createLBL.create_LBL_L5_sample_types('/home/data/ROSETTA/datasets/RO-A-RPCLAP-5-AST2-DERIV-V2.0')
    % createLBL.create_LBL_L5_sample_types('/home/data/ROSETTA/datasets/RO-C-RPCLAP-5-TDDG-DERIV-V0.1')

    
    
    objInfoList = EJ_lapdog_shared.utils.glob_files_dirs(deriv1Path, {'.*', '.*', '.*', '.*.TAB'});
    C = createLBL.constants;
    
    
    
    % TEMPORARY source constants.
    lbltime   = '2018-08-03';  % Label revision time
    lbleditor = 'EJ';
    lblrev    = 'Misc. descriptions clean-up';
    LblHeaderKvpl = C.get_LblAllKvpl(sprintf('%s, %s, %s', lbltime, lbleditor, lblrev));
    LblHeaderKvpl = EJ_lapdog_shared.utils.KVPL.add_kv_pairs(LblHeaderKvpl, {...
        'START_TIME',                   ''; ...
        'STOP_TIME',                    ''; ...
        'SPACECRAFT_CLOCK_START_COUNT', ''; ...
        'SPACECRAFT_CLOCK_STOP_COUNT',  '' });    
            
    for i = 1:numel(objInfoList)    
        tabFilePath = objInfoList(i).fullPath;
        lblFilePath = regexprep(tabFilePath, '.TAB$', '.LBL');
        
        fprintf('Found %s\n', tabFilePath);
        
        if ~exist(lblFilePath, 'file')
            
            % TEMP: Delete empty TAB files.
            fileInfo = dir(tabFilePath);
            if fileInfo.bytes == 0
                fprintf('Empty TAB file - Deleting "%s"\n', tabFilePath)
                delete(tabFilePath)
                continue    % Must not try to create TAB file.
            end
            
            fprintf('Found no corresponding LBL file - Trying to create one\n');        
        
            canClassifyTab = createLBL.create_LBL_file(tabFilePath, LblHeaderKvpl);
            
            if ~canClassifyTab
                fprintf('Can not classify TAB file ==> Can not create LBL file\n');
                continue
            end            
            
        end
    end
end
