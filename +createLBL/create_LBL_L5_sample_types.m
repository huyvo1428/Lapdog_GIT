%
% NOTE: At present, this is a free-standing program that is to be run independently of Lapdog.
% It might be turned into, or merged into, a replacement for createLBL.m .
%
%
% NOTE: Will not overwrite old LBL files.
%
%
% Initially created 2018-08-27 by Erik P G Johansson, IRF Uppsala.
%
function create_LBL_L5_sample_types(deriv1Path)
    % createLBL.create_LBL_L5_sample_types('/home/data/ROSETTA/datasets/RO-A-RPCLAP-5-AST2-DERIV-V2.0___LBL_L5_sample_test')
    
    
    objInfoList = EJ_lapdog_shared.utils.glob_files_dirs(deriv1Path, {'.*', '.*', '.*', '.*.TAB'});
    
    
    for i = 1:numel(objInfoList)    
        tabFilePath = objInfoList(i).fullPath;
        lblFilePath = regexprep(tabFilePath, '.TAB$', '.LBL');
        
        fprintf('Found %s\n', tabFilePath);
        
        if ~exist(lblFilePath, 'file')
            fprintf('Found no corresponding LBL file - Trying to create one\n');        
        
            LblHeaderKvpl = struct('keys', {}, 'values', {});             % TEMP
            canClassifyTab = createLBL.create_LBL_file(tabFilePath, LblHeaderKvpl);
            
            if ~canClassifyTab
                fprintf('Can not classify TAB file ==> Can not create LBL file\n');
                continue
            end            
            
        end
    end
end
