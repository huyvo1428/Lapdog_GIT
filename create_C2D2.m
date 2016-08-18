%===================================================================================================
% Initially created by Erik P G Johansson, IRF Uppsala, 2016-07-xx.
%
% Code that uses a CALIB1 and a DERIV1 data set to create
% corresponding CALIB2 and DERIV2 data set for delivery.
% This code is meant to be run independently of the Rosetta RPCLAP pipeline.
%
% DEFINITIONS OF TERMS
% CALIB1, DERIV1 = The historical formats of data sets that are used internally at IRF-U.
%                  CALIB1 is produced by the pds software. DERIV1 is produced by Lapdog.
% CALIB2, DERIV2 = The formats of data sets that are used for official delivery to PSA at ESA.
%                  In practise DERIV1 data split up in two.
%
% NOTE: Does NOT create the INDEX/ directory. dvalng and pvv can do that.
%===================================================================================================
function create_C2D2(CALIB1_path, DERIV1_path, EG_files_dir, result_parent_path, kernel_file, mission_calendar_path)
    %===================================================================================================
    % PROPOSAL: Better name?
    %    create, derive, extract, convert
    %    create_CALIB2DERIV2_*
    %    create_C2D2
    %    delivery data sets = dd, delDS
    %    create Delivery
    %
    % TODO: Function for updating single ODL file.
    % TODO: Function for updating (selected) ODL files recursively (after copying DATA LBL files). All but selected exceptions?
    % TODO: Copy data files.
    %    QUESTION: How select subsets? How keep directory structures? All but selected exceptions?
    % TODO: Copy VOLDESC.CAT.
    % TODO: Add geometry files.
    %    NOTE: Requires EO geometry files.
    %
    %
    % PROBLEM: How divide task of creating a data set into
    % 1) shared tasks: Copy DATA/, CALIB/, CATALOG/, VOLDE, update ODL files.
    % 2) different tasks: ??
    %   QUESTION: Is it a problem? Are there any tasks that are truly different for C2,D2?
    %
    % PROPOSAL: Print wall time. In particular copying TAB files takes time (ESC2: tens of GB).
    % PROPOSAL: Somehow split up execution into parts (a'la Lapdog) so that partial rerunning is possible in case of
    % failure.
    %   PROPOSAL: Detect when individual destination files (with identical size?) already exist and if so, skip copying.
    %       PROPOSAL: Always re-copy everything except TAB files, since other files might be modified.
    %       CON: Files are renamed after copying.
    %           PROPOSAL: Merge the copying, renaming and modification of TAB/LBL files. Iterate over (DATA/) TAB/LBL files.
    %              CON: Replaces copy_dir_selectively with non-generic function.
    %              PROPOSAL: Function for _iterating_ over TAB/LBL files, and execute arbitrary function there.
    %                 NOTE: Has to iterate over PAIRS of files, not files.
    %   QUESTION: How handle re-modifying LBL files?
    % 
    % PROPOSAL: Catch exceptions and allow execution to continue (sometimes at least).
    %    Ex: Updating ODL files (in particular .CAT files) fails.
    %    NOTE: Make work with time keeping.
    %===================================================================================================
    % Variable naming convention:
    % ---------------------------
    % C1,C2 = CALIB1/2
    % D1,D2 = DERIV1/2
    % E2 = Either one of CALIB2 or DERIV2.
    %===================================================================================================
    
    tic
    ODL_INDENTATION_LENGTH = 4;
    
    
    
    C1_path = get_abs_path(CALIB1_path);
    D1_path = get_abs_path(DERIV1_path);
    
    
    
    %==================================================
    % Extract data set information from CALIB1, DERIV1
    %==================================================
    C1_VOLDESC_path = [C1_path, filesep, 'VOLDESC.CAT'];
    [junk, C1_VOLDESC] = EJ_read_ODL_to_structs(C1_VOLDESC_path);
    C1_DATA_SET_ID   = C1_VOLDESC.OBJECT___VOLUME{1}.DATA_SET_ID;
    
    [junk, part1, part2] = fileparts(D1_path);   % NOTE: "fileparts" interprets the period in the version number as beginning of file suffix.
    D1_DATA_SET_ID = [part1, part2];
    
    PDS_base_data_C1.DATA_SET_ID = C1_DATA_SET_ID;
    PDS_base_data_C1.VOLUME_ID_nbr_str = 'xxxx';
    [junk, PDS_base_data_C1] = get_PDS_data([], PDS_base_data_C1, mission_calendar_path);
    
    PDS_base_data_D1.DATA_SET_ID = D1_DATA_SET_ID;
    PDS_base_data_D1.VOLUME_ID_nbr_str = 'xxxx';
    [junk, PDS_base_data_D1] = get_PDS_data([], PDS_base_data_D1, mission_calendar_path);
    
    %=========================================================================
    % Check that the DPLs are correct and that the data sets
    % match in everything else (except the description strings).
    %=========================================================================
    if ~strcmp(PDS_base_data_C1.DATA_SET_ID_target_ID, PDS_base_data_D1.DATA_SET_ID_target_ID) || ...
       ~strcmp(PDS_base_data_C1.mission_phase_abbrev,  PDS_base_data_D1.mission_phase_abbrev)  || ...
       ~strcmp(PDS_base_data_C1.version_str,           PDS_base_data_D1.version_str)
        error('CALIB1 and DERIV1 data sets do not match.')
    elseif ~strcmp(PDS_base_data_C1.PROCESSING_LEVEL_ID, '3') || ...
           ~strcmp(PDS_base_data_D1.PROCESSING_LEVEL_ID, '5')
        error('Data sets have the wrong archiving levels?')
    end



    %=================================================================================================
    % Information common/necessary for creating both CALIB2 and DERIV2.
    % NOTE: ROSETTA_INSTHOST.CAT, ROSETTA_MSN.CAT should not contain anything that should be updated.
    %       They also contain ODL comments (which would be removed).
    %
    % Better variable name?
    %=================================================================================================
    CD2.CALIB1_path        = C1_path;
    CD2.DERIV1_path        = D1_path;
    CD2.EG_files_dir       = EG_files_dir;
    CD2.result_parent_path = get_abs_path(result_parent_path);
    CD2.no_update_ODL_filenames_regex = {};
    CD2.no_update_ODL_filenames_regex{end+1} = 'RPCLAP030101_CALIB_FRQ_[DE]_P[12]\.TXT';
    CD2.no_update_ODL_filenames_regex{end+1} = 'ROSETTA_INSTHOST\.CAT';
    CD2.no_update_ODL_filenames_regex{end+1} = 'ROSETTA_MSN\.CAT';
    CD2.kernel_file        = kernel_file;
    CD2.EG_files_dir       = EG_files_dir;
    CD2.indentation_length = ODL_INDENTATION_LENGTH;
    CD2.PDS_data.DATA_SET_RELEASE_DATE      = datestr(now, 'YYYY-mm-dd');
    CD2.PDS_data.VOLDESC___PUBLICATION_DATE = datestr(now, 'yyyy-mm-dd');



    % Information specific for CALIB2.
    C2 = CD2;
    PDS_base_data = rmfield(PDS_base_data_C1, 'DATA_SET_ID');
    PDS_base_data.PROCESSING_LEVEL_ID = '3';
    PDS_base_data.DATA_SET_ID_descr   = 'CAL';
    [C2.PDS_data, junk] = get_PDS_data(CD2.PDS_data, PDS_base_data, mission_calendar_path);
    C2.data_file_selection_func = @select_CALIB2_DATA_files;
    
    fprintf('-------- Creating CALIB2 data set --------\n');
    create_data_set(C2, result_parent_path);
    
    % Information specific for DERIV2.
    %D2 = CD2;    
    %D2.data_file_selection_func = @select_DERIV2_DATA_files;
    %fprintf('-------- Creating DERIV2 data set --------\n');
    %create_data_set(CD2, D2, result_parent_path);
    
    toc
end



%=========================================================================================
% Create a first version of a CALIB2 or DERIV2 data set. 
% Intended to do all the operations which are common to both data sets.
% NOTE: Sets the name of the data set root directory.
%
% CD2 = Struct containing all information common for both the CALIB2 and DERIV2 data set.
% E2  = Struct containing information specific for the data set to create.
%=========================================================================================
function E2_path = create_data_set(E2, E2_parent_path)
    % QUESTION: How select DATA file selection function?
    %    PROPOSAL: Caller chooses.
    %    PROPOSAL: E2 struct chooses.



    create_dir(E2_parent_path, E2.PDS_data.DATA_SET_ID);
    E2_path = [E2_parent_path, filesep, E2.PDS_data.DATA_SET_ID];



    %============================================
    % Copy (regular) files in the ROOT directory
    %============================================
    fprintf('Copying root directory\n')
    copy_dir_files_nonrecursively(E2.CALIB1_path, E2_path, 'always overwrite');



    %===========================================
    % Copy CATALOG, DOCUMENT directories
    %===========================================
    fprintf('Copying CATALOG/, DOCUMENT/\n')
    copy_file(fullfile(E2.CALIB1_path, 'CATALOG'),  [E2_path, filesep, 'CATALOG'],  'always overwrite');
    copy_file(fullfile(E2.CALIB1_path, 'DOCUMENT'), [E2_path, filesep, 'DOCUMENT'], 'always overwrite');



    %==================
    % Update ODL files
    %==================    
    fprintf('Update ODL files\n')
    kvl_updates = struct('keys', {{}}, 'values', {{}});
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'DATA_SET_ID',         ['"', E2.PDS_data.DATA_SET_ID,   '"']);
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'DATA_SET_NAME',       ['"', E2.PDS_data.DATA_SET_NAME, '"']);
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'PROCESSING_LEVEL_ID', ['"', E2.PDS_data.PROCESSING_LEVEL_ID,   '"']);
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'PRODUCT_TYPE',        ['"', E2.PDS_data.PRODUCT_TYPE, '"']);
    update_generic_ODL_files_contents(E2_path, kvl_updates, E2.no_update_ODL_filenames_regex, E2.indentation_length);    % NOTE: Updates ALL ODL files copies so far (i.e.g not DATA/).
    % NOTE: Does not alter DATASET.CAT:START_TIME, STOP_TIME. Relies on old values of START_TIME, STOP_TIME to be correct.
    update_DATASET_VOLDESC(E2_path, E2.PDS_data, E2.indentation_length)



    %==================================
    % Copy and process subset of DATA/
    %==================================
    fprintf('Copy and process subset of DATA/\n')
    E2_DATA_subdir_path = fullfile(E2_path, 'DATA', E2.PDS_data.DATA_subdir);
    file_processing_func = @(root_dir_path, child_relative_path) (DATA_CALIB_file_processing_func(...
        root_dir_path, child_relative_path, ...
        E2_DATA_subdir_path, @E2.data_file_selection_func, ...
        E2.no_update_ODL_filenames_regex, kvl_updates, E2.indentation_length));
    process_dir_files_recursively_NEW(E2.DERIV1_path, file_processing_func);

    %===================================
    % Copy and process subset of CALIB/
    %===================================
    E2_CALIB_subdir_path = fullfile(E2_path, 'CALIB');
    file_processing_func = @(root_dir_path, child_relative_path) (DATA_CALIB_file_processing_func(...
        root_dir_path, child_relative_path, ...
        E2_CALIB_subdir_path, [], ...    % NOTE: No "filename accept function".
        E2.no_update_ODL_filenames_regex, kvl_updates, E2.indentation_length));
    process_dir_files_recursively_NEW(fullfile(E2.CALIB1_path, 'CALIB'), file_processing_func);



    %====================
    % Add geometry files
    %====================
    fprintf('Add geometry files\n')
    cspice_furnsh(get_abs_path(E2.kernel_file));     % For some reason cspice_furnsh does not appear to understand ~ in a path.
    geometry_addToDataSet(E2_path, E2.PDS_data, E2.EG_files_dir);
    % "CSPICE_KCLEAR clears the KEEPER system: unload all kernels, clears
    % the kernel pool, and re-initialize the system."
    %cspice_kclear
    cspice_unload(E2.kernel_file);



    fprintf('Finished one data set\n')
end



%==========================================================================================
% Update all LBL, CAT, TXT files (assumes that they are ODL) found in a directory subtree.
%
% NOTE: Delegates the actual updating of ODL files to "update_generic_single_ODL_file_contents_NEW".
%
% Recursive over the directory tree.
%==========================================================================================
function update_generic_ODL_files_contents(dir_path, kvl_updates, no_updates_filenames_regex, indentation_length)
    
    files_info = dir(dir_path);

    for i=1:length(files_info)
        fi = files_info(i);
        filename = fi.name;
        file_path = [dir_path, filesep, filename];        
        [junk1, junk2, suffix] = fileparts(filename);
        
        if strcmp(filename, '.') || strcmp(filename, '..')
            % Do nothing.
        elseif fi.isdir
            update_generic_ODL_files_contents(file_path, kvl_updates, no_updates_filenames_regex, indentation_length)    % NOTE: RECURSIVE CALL
        elseif any(strcmp(suffix, {'.LBL', '.CAT', '.TXT'}))
            % NOTE: Update ONE file.
            update_generic_single_ODL_file_contents_NEW(file_path, kvl_updates, no_updates_filenames_regex, indentation_length);
        end
    end
end



%===================================================================================================
% Updates ODL keywords (inplace) in ODL file.
%
% kvl_updates: key-value list of (root-level) ODL keywords to set if already present.
%
% NOTE: Only sets PDS keywords at the root level, not deeper in the "data tree" within an ODL file.
% Is therefore NOT intended for VOLDESC.VAT and DATASET.CAT
% NOTE: Name "update_generic_single_ODL_file" is to distinguish it from "update_generic_ODL_files_contents".
%===================================================================================================
% function update_generic_single_ODL_file(ODL_file_path, kvl_updates, indentation_length)
%     fprintf('Updating ODL file "%s"\n', ODL_file_path)
%     [s_str_lists, junk, end_lines] = EJ_read_ODL_to_structs(ODL_file_path);
%         
%     %======================================================================
%     % Update ODL keywords.
%     %======================================================================
%     % NOTE: Strictly speaking, "s_str_lists" is NOT a key-value list only for which createLBL_KVPL_overwrite_values is intended but it works anyway.
%     s_str_lists = createLBL_KVPL_overwrite_values(s_str_lists, kvl_updates, 'overwrite only when has keys');    
%     
%     %===========================================================================================================
%     % Shorten RPCLAP_* filenames if necessary.
%     % NOTE: Needs to shorten both the filenames (of the actual files) and the PDS keyword values for ^TABLE and
%     % FILE_NAME.
%     %===========================================================================================================
%     i_TABLE    = find(strcmp(s_str_lists.keys, '^TABLE'  ));
%     i_FILENAME = find(strcmp(s_str_lists.keys, 'FILE_NAME'));
%     if length(i_TABLE) == 1 && length(i_FILENAME) == 1
%         old_TAB_filename = strrep(s_str_lists.values{i_TABLE}, '"', '');
%         
%         if (length(old_TAB_filename) > 27+1+3) && strncmp(old_TAB_filename, 'RPCLAP_', 7)
%             % CASE: Filename is too long.
%             [parent_dir, old_ODL_filename_base, old_ODL_filename_ext] = fileparts(ODL_file_path);
%             
%             old_ODL_filename = [old_ODL_filename_base, old_ODL_filename_ext];            
%             new_ODL_filename = old_ODL_filename(4:end);
%             new_TAB_filename = old_TAB_filename(4:end);
%             
%             old_TAB_file_path = [parent_dir, filesep, old_TAB_filename];
%             new_TAB_file_path = [parent_dir, filesep, new_TAB_filename];
%             
%             % "Change" the name of the ODL file.
%             delete(ODL_file_path);
%             ODL_file_path = [parent_dir, filesep, new_ODL_filename];
%             
%             s_str_lists.values{i_TABLE   } = ['"', new_TAB_filename, '"'];
%             s_str_lists.values{i_FILENAME} = ['"', new_ODL_filename, '"'];
%             
%             movefile(old_TAB_file_path, new_TAB_file_path);
%         end
%     end
%     
%     EJ_write_ODL_from_struct(ODL_file_path, s_str_lists, end_lines, indentation_length);
% end



%===================================================================================================
% Updates ODL keywords (in-place) in ODL file.
%
% kvl_updates: key-value list of (root-level) ODL keywords to set if already present.
%
% NOTE: Only sets PDS keywords at the root level, not deeper in the "data tree" within an ODL file.
% Is therefore NOT intended for VOLDESC.VAT and DATASET.CAT
% NOTE: Name "update_generic_single_ODL_file_contents_NEW" is to distinguish it from "update_generic_ODL_files_contents".
%===================================================================================================
function update_generic_single_ODL_file_contents_NEW(ODL_file_path, kvl_updates, no_updates_filenames_regex, indentation_length)
    fprintf('Updating ODL file "%s"\n', ODL_file_path)
    
    [junk, basename, extension] = fileparts(ODL_file_path);
    if contains_any_regexp([basename, extension], no_updates_filenames_regex)
        return
    end
    
    
    
    [s_str_lists, s_simple, end_lines] = EJ_read_ODL_to_structs(ODL_file_path);
        
    %===========================================================================================================
    % Shorten filenames (or values derived from filenames) found inside the ODL file if necessary.
    %
    % NOTE: Does not modify the filenames of any actual files.
    %===========================================================================================================

    % NOTE: Removing quotes from values internally.
    % NOTE: ALWAYS SETS PRODUCT_ID TO FILENAME (minus extension).
    if isfield(s_simple, 'POINTER___TABLE')
        POINTER___TABLE = get_dest_filename_NEW(strrep(s_simple.POINTER___TABLE, '"', ''));
        [junk, basename, junk] = fileparts(POINTER___TABLE);
        kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, '^TABLE',     ['"', POINTER___TABLE, '"']);
        kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'PRODUCT_ID', ['"', basename,        '"']);
    end
    if isfield(s_simple, 'FILE_NAME')    
        FILENAME = get_dest_filename_NEW(strrep(s_simple.FILE_NAME, '"', ''));
        kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'FILE_NAME',   ['"', FILENAME,        '"']);
    end
    
    
    
    %======================================================================
    % Update ODL keywords.
    %======================================================================
    % NOTE: Strictly speaking, "s_str_lists" is NOT a key-value list only for which createLBL_KVPL_overwrite_values is intended but it works anyway.
    s_str_lists = createLBL_KVPL_overwrite_values(s_str_lists, kvl_updates, 'overwrite only when has keys');    
    
    
    
    EJ_write_ODL_from_struct(ODL_file_path, s_str_lists, end_lines, indentation_length);
end



%=====================================================================
% Return a destination filename for a given source filename.
% This function decides which filenames should be shortened and how.
%=====================================================================
function dest_filename = get_dest_filename_NEW(src_filename)
    
    [junk, basename, extension] = fileparts(src_filename);
    
    %if (length(src_filename) > 27+1+3) && strncmp(src_filename, 'RPCLAP_', 7)
    if contains_any_regexp(src_filename, {'^RPCLAP_[0-9]'})
        % NOTE: Want to exclude e.g. RPCLAP160627_CALIB_MEAS.LBL and RPCLAP_CALIB_MEAS_EXCEPT.LBL
        dest_filename = src_filename(4:end);
    elseif strcmp(basename, 'RPCLAP_CALIB_MEAS_EXCEPTIONS')
        dest_filename = ['RPCLAP_CALIB_MEAS_EXCEPT', extension];
    else
        dest_filename = src_filename;
    end
end



% Return true if-and-only-if file should be included in CALIB2.
function select = select_CALIB2_DATA_files(filename)
    s = select_data_set_for_file(filename);    select = s.include_in_CALIB2;
end
% Return true if-and-only-if file should be included in DERIV2.
function select = select_DERIV2_DATA_files(filename)
    s = select_data_set_for_file(filename);    select = s.include_in_DERIV2;
end



%===========================================================================================================
% Function which decides which DATA/ files should be copied to which data sets, if any.
%
% IMPLEMENTATION NOTE: Uses one function for both CALIB2 and DERIV to make sure that the algorithm is safe:
% It is easy to see that data which does not go to CALIB2 goes to DERIV2 (or nowhere).
%===========================================================================================================
function s = select_data_set_for_file(filename)
    CALIB2_INCLUDE_DATA_TYPES    = {'^[IV].[LHS]$'};    % Regexp.
    CALIB2_EXCLUDE_SUPPORT_TYPES = {'^(FRQ|PSD)$'};     % Regexp.
    DERIV2_EXCLUDE_DATA_TYPES    = {'^A.S$'};           % Regexp.

    s = classify_data_dir_file(filename);

    if strcmp(s.file_category, 'block list')    

        s.include_in_CALIB2 = 1;
        s.include_in_DERIV2 = 1;

    elseif strcmp(s.file_category, 'data')
        
        s.include_in_CALIB2 = contains_any_regexp(s.data_type, CALIB2_INCLUDE_DATA_TYPES) && ~contains_any_regexp(s.macro_or_support_type, CALIB2_EXCLUDE_SUPPORT_TYPES);
        
        s.include_in_DERIV2 = ~s.include_in_CALIB2 && ~contains_any_regexp(s.data_type, DERIV2_EXCLUDE_DATA_TYPES);
        
    else
        error('Can not classify/recognize file "%s".', filename);
    end
end



%==============================================================
% Tries to "classify" one DATA/ file by parsing the file name.
%
% NOTE: Gives errors for files it does not recognize.
%==============================================================
function s = classify_data_dir_file(filename)
    % Ex: RPCLAP_20050301_000000_BLKLIST.LBL
    % Ex: RPCLAP_20050301_001317_301_A2S.LBL
    % Ex: RPCLAP_20050303_124725_FRQ_I1H.LBL
    
    s = [];

    if ~isempty(regexp(filename, '^RPCLAP_\d\d\d\d\d\d\d\d_000000_BLKLIST.(LBL|TAB)'));
        
        s.file_category = 'block list';
        
    elseif ~isempty(regexp(filename, '^RPCLAP_\d\d\d\d\d\d\d\d_\d\d\d\d\d\d_[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]_[A-Z][A-Z0-9][A-Z].(LBL|TAB)'));
        % NOTE: Letters in macro numbers (hex) are lower case, but the "macro" can also be 32S, PSD, FRQ i.e. upper case letters.
        
        % NOTE: strread throws exception if it the pattern does not match.
        [s.date, s.time, macro_or_support_type, data_type, file_type] = strread(filename, 'RPCLAP_%u_%u_%[^_]_%[^.].%s');
        
        s.file_category = 'data';
        s.data_type = data_type{1};
        s.macro_or_support_type = macro_or_support_type{1};
        
    else
        
        s.file_category = 'unknown';
        
    end
end



%===============================================================================================================================
% Selectively copy files from one directory structure to another analogous one. Will only create those destination directories
% which are required for copying files to them. Might therefore not create any destination directory at all. Primarily intended
% for copying files from DATA/*/ to DATA/*/.
%
% Recursive. Generic function.
%
% src_dir         : Directories whose CONTENTS (subdirectories, files) will be copied and put UNDER dest_parent_dir.
%                   E.g. RO-E-RPCLAP-5-EAR1-DERIV-V0.5/
% dest_parent_dir : E.g. RO-E-RPCLAP-3-EAR1-CAL-V0.5/DATA/CALIBRATED/    # NOTE: Excludes subdirectory "2005".
%                   Does not have to exist and might not even be created if there are no files/directories to copy to it.
% selection_func  : Function of a file name. Returns true for files which should be copied.
%===============================================================================================================================
% function copy_dir_selectively(src_parent_dir, dest_parent_dir, selection_func, copy_policy)
%     % Use for other copying than just DATA/ ?
% 
%     files_info = dir(src_parent_dir);
%     for i=1:length(files_info)
%         fi = files_info(i);
%         if strcmp(fi.name, '.') || strcmp(fi.name, '..')
%             continue
%         end
% 
%         src_dir_child  = [src_parent_dir,  filesep, fi.name];
%         dest_dir_child = [dest_parent_dir, filesep, fi.name];
%         
%         if fi.isdir
%             % CASE: It is a subdirectory.
% 
%             copy_dir_selectively(...
%                 src_dir_child, ...
%                 dest_dir_child, ...       % NOTE: Calling with the destination (parent) directory.
%                 selection_func, ...
%                 copy_policy);      % NOTE: RECURSIVE CALL
%         else
%             % CASE: It is a regular (non-directory) file.
% 
%             if selection_func(fi.name)
%                 %fprintf('Including %s\n', fi.name)
% 
%                 if ~exist(dest_parent_dir, 'dir')
%                     create_dir(dest_parent_dir, '.');
%                 end
%                 copy_file(src_dir_child, dest_dir_child, copy_policy);
%             else
%                 %fprintf('( Excluding %s )\n', fi.name)
%             end
%         end
%     end
% end



%===============================================================================================================================
% Recurse over directory subtree, and for every file found, call a custom function. Primarily intended for copying and
% "processing" (modifying) files in DATA/ and CALIB/ although much of the work is done by the custom function.
%
% Recursive. Generic function.
%
% root_dir_path        : Directory which will be recursed into/over.
%                        E.g. source DERIV1 directory.
% file_processing_func : Function with arguments(root_dir_path, file_relative_path)
%===============================================================================================================================
function process_dir_files_recursively_NEW(root_dir_path, file_processing_func)
    % Use for other copying than just DATA/ ?
    
    % BUG? Correct initial relative path?!
    process_dir_files_recursively_INTERNAL_NEW(root_dir_path, '.', file_processing_func)
    
    % -----------------------------------------------------------------------------------------------------------------
    function process_dir_files_recursively_INTERNAL_NEW(root_dir_path, relative_path, file_processing_func)
        
        files_info = dir(fullfile(root_dir_path, relative_path));
        for i=1:length(files_info)
            fi = files_info(i);
            if strcmp(fi.name, '.') || strcmp(fi.name, '..')
                continue
            end
            
            child_relative_path = fullfile(relative_path, fi.name);   % NOTE: If first (argument) string is empty, then no slash is added.
            
            if fi.isdir
                % CASE: "Child" is a subdirectory.
                
                process_dir_files_recursively_INTERNAL_NEW(root_dir_path, child_relative_path, file_processing_func);    % NOTE: RECURSIVE CALL
                
            else
                % CASE: "Child" is a regular (non-directory) file.
                
                file_processing_func(root_dir_path, child_relative_path)
            end
        end
    end
    
end



% "Process" arbitrary source file in DATA/ or CALIB/ directory.
%
% data_file_selection_func : Function with argument list (filename). If empty, then accept any file.
function DATA_CALIB_file_processing_func(...
        src_root_path, src_file_relative_path, dest_root_path, data_file_selection_func, ...
        no_updates_regex_filenames, ODL_kvl_updates, ODL_indentation_length)
    
    [src_file_relative_parent_path, src_filebasename, src_suffix] = fileparts(src_file_relative_path);
    src_filename = [src_filebasename, src_suffix];
    
    if isempty(data_file_selection_func) || data_file_selection_func(src_filename)
        fprintf('Including %s\n', src_filename)
        
        dest_file_parent_path = fileparts(fullfile(dest_root_path, src_file_relative_path));    % NOTE: Independent of any filename change.
        if ~exist(dest_file_parent_path, 'dir')
            create_dir(dest_file_parent_path, '.');
        end

        % Derive path for destination file.
        % NOTE: Potentially changes filename.
        dest_file_relative_path = fullfile(src_file_relative_parent_path, get_dest_filename_NEW([src_filebasename, src_suffix]));   
        
        old_file_path = fullfile( src_root_path,  src_file_relative_path);
        new_file_path = fullfile(dest_root_path, dest_file_relative_path);
        
        % NOTE: Copy file, but only if dissimilar. This saves a lot of time if "overwriting" an old destination data set
        % (copying TAB files takes a lot of time).
        copy_file(old_file_path, new_file_path, 'overwrite dissimilar');
        
        if any(strcmp(src_suffix, {'.LBL', '.CAT', '.TXT'}))
            update_generic_single_ODL_file_contents_NEW(new_file_path, ODL_kvl_updates, no_updates_regex_filenames, ODL_indentation_length);
        end
        
    else
        %fprintf('( Excluding %s )\n', fi.name)
    end
end



%=========================================================
% Copy all regular files in a directory, but nothing else
%=========================================================
function copy_dir_files_nonrecursively(src_dir, dest_dir, copy_policy)
    files_info = dir(src_dir);    
    for i=1:length(files_info)
        fi = files_info(i);
        if strcmp(fi.name, '.') || strcmp(fi.name, '..') || fi.isdir
            continue
        end
        copy_file([src_dir, filesep, fi.name], dest_dir, copy_policy)        
    end
end



%==================================================================================================== 
% contains_any_regexp
%
% Wrapper around expressions since this combination of commands, combined with even more ones, has proven bug-prone. The meaning
% of compund statemens becomes too confusing to use correctly on the fly.
%
% patterns = Cell array of strings
% match = true iff str, matches (contains) at least one of the patterns.
%====================================================================================================
function match = contains_any_regexp(str, patterns)
    % NOTE: regexp returns cell array of ones or EMPTY depending on matches/non-matches.
    match = ~all(cellfun(@isempty, regexp(str, patterns)));
end



%=====================================================================================
% Create directory. - Wrapper around mkdir for better erro handling.
%
% NOTE: Can create multiple nested directories.
% NOTE: Some of directories may already exist.
% NOTE: Can effectively set absolute paths by settings parent_path='/'.
% NOTE: Can effectively create a directory from one path relative_new_dir_path="." .
%
% Permits destination directory to already exist (do nothing).
%=====================================================================================
function create_dir(parent_path, relative_new_dir_path)
    % PROPOSAL: Remake into creating directory only if necessary. (Avoid warning)
    %   CON: Only one call(?) wants that functionality.
    
    %new_dir = [parent_path, filesep, relative_new_dir_path];
    %if exist(new_dir, 'file')
    %    error('Can not create directory "%s" since there already is a file or directory by that name.', new_dir)
    %end
    [success, msg, msgid] = mkdir(parent_path, relative_new_dir_path);
    if ~success
        error('Failed to create directory "%s". %s', new_dir_path, msg)
    end
end



% Wrapper around "copyfile" to produce better error behaviour.
% NOTE: Can copy regular files as well as directories (recursively).
%
% dest_path = For files, the destination file. For directories, the parent directory of the new directory. (?)
function copy_file(source_path, dest_path, policy)

    switch(policy)
        case 'overwrite dissimilar'
            [path,basename,extension] = fileparts(source_path);
            src_info  = dir(source_path);
            %dest_info = dir(fullfile(dest_path, [basename, extension]));
            dest_info = dir(dest_path);
            execute_copy = isempty(dest_info) || src_info.isdir || dest_info.bytes ~= src_info.bytes;
        case 'always overwrite'
            execute_copy = 1;
        otherwise
            error('No such policy.')
    end

    if execute_copy
        [success, msg, msgid] = copyfile(source_path, dest_path);    
        if ~success
            error('Can not copy file/directory "%s". %s', dest_path, msg)
        end
    else
        fprintf('Not overwriting %s\n', source_path)
    end
end



%======================================================================
% Author: Erik P G Johansson, IRF-U, Uppsala, Sweden
% First created 2016-06-09
%
% Convert (relative/absolute) path to an absolute (canonical) path.
%
% NOTE: Will also convert ~ (home directory).
% (MATLAB does indeed seem to NOT have a function for doing this(!).)
%======================================================================
function path = get_abs_path(path)
% PROPOSAL: Rethrow exception via errorp with amended message somehow?
% PROPOSAL: Separate out as a separate function file?

try
    if ~exist(path, 'dir')
        [dir_path, basename, suffix] = fileparts(path);   % NOTE: If ends with slash, then everything is assigned to dir_path!
   
        % Uses MATLAB trick to convert path to absolute path.
        dir_path = cd(cd(dir_path));
        path = [dir_path, filesep, basename, suffix];
    else
        path = cd(cd(path));
    end
catch e
    error('Failed to convert path "%s" to absolute path.\nException message: "%s"', path, e.message)
end
end

