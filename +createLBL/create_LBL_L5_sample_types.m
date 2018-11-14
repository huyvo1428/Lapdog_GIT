%
% Standalone program for creating LBL files for TAB files PHO, USC, ASW, NPL.
%
% Iterates over the TAB files of a DERIV1 dataset. For TAB files that do not have LBL files, try to create LBL files
% (will only succeed for types that create_LBL_file can handle).
%
%
% NOTES
% =====
% NOTE: At present, this is a free-standing program that can be run independently of Lapdog or in createLBL.
% It might be turned into, or merged into, a replacement for createLBL.m .
%
% NOTE: Will overwrite old LBL files.
%
% NOTE: TEMPORARY: Will delete empty TAB files without LBL file.
%
%
% Initially created 2018-08-27 by Erik P G Johansson, IRF Uppsala.
%
function create_LBL_L5_sample_types(deriv1Path)
    % createLBL.create_LBL_L5_sample_types('/home/data/ROSETTA/datasets/RO-A-RPCLAP-5-AST2-DERIV-V2.0___LBL_L5_sample_test')
    % createLBL.create_LBL_L5_sample_types('/home/data/ROSETTA/datasets/RO-A-RPCLAP-5-AST2-DERIV-V2.0')
    % createLBL.create_LBL_L5_sample_types('/home/data/ROSETTA/datasets/RO-C-RPCLAP-5-TDDG-DERIV-V0.1')

    
    
    C = createLBL.constants();
    
    LblHeaderKvpl = C.get_LblAllKvpl();
    LblHeaderKvpl = LblHeaderKvpl.append(EJ_lapdog_shared.utils.KVPL2({...
        'START_TIME',                   ''; ...
        'STOP_TIME',                    ''; ...
        'SPACECRAFT_CLOCK_START_COUNT', ''; ...
        'SPACECRAFT_CLOCK_STOP_COUNT',  '' }));

    
    
    objInfoList = EJ_lapdog_shared.utils.glob_files_dirs(deriv1Path, {'.*', '.*', '.*', '.*.TAB'});

    for i = 1:numel(objInfoList)    
        tabFilePath = objInfoList(i).fullPath;
        tabFilename = objInfoList(i).name;
        lblFilePath = regexprep(tabFilePath, '.TAB$', '.LBL');        

        %fprintf('Found %s\n', tabFilename);

        if ~exist(lblFilePath, 'file')
            
            % TEMP: Delete empty TAB files.
            fileInfo = dir(tabFilePath);
            if fileInfo.bytes == 0
                fprintf('Empty TAB file - Deleting "%s"\n', tabFilename)
                delete(tabFilePath)
                continue    % Must not try to create TAB file.
            end
            
            
            
            %fprintf('Found no corresponding LBL file - Trying to create one for "%s"\n', tabFilename);        
            %canClassifyTab = createLBL.create_LBL_file(tabFilePath, LblHeaderKvpl);
            
            %if ~canClassifyTab
            %    fprintf('Can not classify TAB file ==> Can not create LBL file\n');
            %    continue
            %end            
            
        end
        
        canClassifyTab = createLBL.create_LBL_file(tabFilePath, LblHeaderKvpl);
        if canClassifyTab
            fprintf('Created LBL file for "%s"\n', tabFilename);
        end
    end
end
