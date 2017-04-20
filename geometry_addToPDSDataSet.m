%
% Add geometry files to an existing PDS compliant data set for delivery.
%
% NOTE: For any type of PDS compliant EDITED, CALIB, DERIV data set.
% NOTE: The code is written so that it could some day be turned into code that is run together (is called by) Lapdog
% by exchanging the call to geometry_createFileFromEOGFile with another function that creates
% geometry files from scratch.
% NOTE: The code does NOT update any INDEX.TAB/LBL files.
% NOTE: Overwrites old geometry files without warning.
%
% Created by: Erik P G Johansson, 2015-12-15, IRF Uppsala, Sweden
%
%
% ARGUMENTS
% =========
% data_set_path : Path to the (PDS ~compliant) data set. Will place the geometry files in the DATA/*/*/*/*/ subdirectories.
% PDS_data      : struct with various variables relating to the data set.
% EOG_files_dir : Directory where Elias' geometry files can be located.
%
function geometry_addToPDSDataSet(data_set_path, PDS_data, EOG_files_dir)
    
    path_list = get_dirs(fullfile(data_set_path, 'DATA'), 4);
    
    % This log message is useful in particular in case no directories are found
    % (no other log messages; likely configuration error).
    fprintf(1, 'Adding geometry files to %i directories\n', length(path_list));    
    
    for i = 1:length(path_list)
        path_parts = regexp(path_list{i}, filesep, 'split');
        
        year      = str2double(path_parts{end-2});
        month_nbr = month(datenum(path_parts{end-1}, 'mmm'));    % Can not use "month" as variable name since it overlaps with a standard function.
        day_nbr   = str2double(path_parts{end}(2:3));    
        t = datenum([year, month_nbr, day_nbr]);
        
        % Create ONE LBL+TAB file pair.
        geometry_createFileFromEOGFile(path_list{i}, PDS_data, t, EOG_files_dir);   % NOTE: Requires SPICE kernels to be loaded.
    end
    
end



%============================================================================================================
% Return list (cell array) of directories which are an exact number of directory levels into a subdirectory.
%============================================================================================================
function path_list = get_dirs(path, depth)
    IGNORE_DIRNAME_LIST = {'.', '..'};

    if depth == 0
        
        path_list = path;
        return
        
    elseif depth >= 1

        file_list = dir(path);
        subdir_list = { file_list([file_list.isdir]==1).name }';   % Extract list of names (not paths) of subdirectories.

        path_list = {};
        for i = 1:length(subdir_list)

            if ~ismember(subdir_list{i}, IGNORE_DIRNAME_LIST)
                subdir_paths_list = get_dirs(fullfile(path, subdir_list{i}), depth -1 );   % NOTE: RECURSIVE CALL
                path_list = [path_list; subdir_paths_list];
            end

        end

    end

end
