%===================================================================================================
% Initially created by Erik P G Johansson, IRF Uppsala, 2016-07-xx.
%
% Code that uses an existing CALIB1 dataset and an existing DERIV1 data set to create
% the corresponding CALIB2 (and in the future DERIV2) data set for delivery.
% This code is meant to be run independently of the Rosetta RPCLAP pipeline.
% The script is intended for automating the process of creating datasets for delivery.
%
% NOTE: Does NOT create the INDEX/ directory. dvalng and pvv can do that.
%
% NOTE: PDS prescribes that:
%   - filenames are no longer than "27.3", i.e. 27 (basename) + 1 (period) + 3 (file extension) = 31 characters.
%   - filenames are all upper case. (DERIV1 hexadecimal macro numbers with may contain lowercase letters.)
% Therefore, some filenames have to be altered.
%
% IMPLEMENTATION NOTE: Code is designed to iterate over the bulk of files, and when it gets to a given file, decide what
% to do with it then. One possibility is that it sees that the destination already seems to have the corresponding file
% and thus not do anything to save time. This way the code can be interrupted (deliberately or because of crash/bug) and
% the user can then re-run without the code redoing a lot of work. In particular, copying a lot of TAB files takes a lot
% of time which can then be avoided if running a second time.
%
% DEFINITIONS OF TERMS
% ====================
% CALIB1, DERIV1 = The historical formats of data sets that are used internally at IRF-U.
%                  CALIB1 is produced by the pds software. DERIV1 is produced by Lapdog.
% CALIB2, DERIV2 = The formats of data sets that are used for official delivery to PSA at ESA.
%                  In practise DERIV1 data split up in two.
%
% ARGUMENTS
% =========
% EG_files_dir : Path to directory with Elias' geometry files. The directory must contain at least the required files
%                but may also contain other files.
% CALIB1_path, DERIV1_path : Paths to existing datasets.
%===================================================================================================
function create_C2D2(CALIB1_path, DERIV1_path, EG_files_dir, result_parent_path, kernel_file, pds_mission_calendar_path, C2_VOLUME_ID_nbr_str)
    %===================================================================================================    
    % PROPOSAL: Better name?
    %    create, derive, extract, convert
    %    create_CALIB2DERIV2
    %    create_C2D2_from_CALIB1_DERIV1
    %    delivery data sets = dds, delDS
    %    create Delivery
    %
    % PROPOSAL: Catch exceptions and allow execution to continue (sometimes at least).
    %    Ex: Updating ODL files (in particular .CAT files) fails.
    %    NOTE: Make work with time keeping.
    %
    % PROPOSAL: Modify file classification function to apply to all files.
    %   PRO: Can identify ODL files.
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
    C1_VOLDESC_path = fullfile(C1_path, 'VOLDESC.CAT');
    [junk, C1_VOLDESC] = EJ_read_ODL_to_structs(C1_VOLDESC_path);
    C1_DATA_SET_ID   = C1_VOLDESC.OBJECT___VOLUME{1}.DATA_SET_ID;
    
    [junk, part1, part2] = fileparts(D1_path);   % NOTE: "fileparts" interprets the period in the version number as the beginning of a file suffix.
    D1_DATA_SET_ID = [part1, part2];
    
    PDS_base_data_C1.DATA_SET_ID = C1_DATA_SET_ID;
    PDS_base_data_C1.VOLUME_ID_nbr_str = 'xxxx';
    [junk, PDS_base_data_C1] = get_PDS_data([], PDS_base_data_C1, pds_mission_calendar_path);
    
    PDS_base_data_D1.DATA_SET_ID = D1_DATA_SET_ID;
    PDS_base_data_D1.VOLUME_ID_nbr_str = 'xxxx';
    [junk, PDS_base_data_D1] = get_PDS_data([], PDS_base_data_D1, pds_mission_calendar_path);
    
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
    %CD2.no_update_ODL_filenames_regex{end+1} = 'RPCLAP030101_CALIB_FRQ_[DE]_P[12]\.TXT';
    %CD2.no_update_ODL_filenames_regex{end+1} = 'ROSETTA_INSTHOST\.CAT';
    %CD2.no_update_ODL_filenames_regex{end+1} = 'ROSETTA_MSN\.CAT';
    CD2.kernel_file        = kernel_file;
    CD2.EG_files_dir       = EG_files_dir;
    CD2.indentation_length = ODL_INDENTATION_LENGTH;
    CD2.PDS_data.DATA_SET_RELEASE_DATE      = datestr(now, 'YYYY-mm-dd');
    CD2.PDS_data.VOLDESC___PUBLICATION_DATE = datestr(now, 'yyyy-mm-dd');



    % Information specific for CALIB2.
    C2 = CD2;
    PDS_base_data = rmfield(PDS_base_data_C1, 'DATA_SET_ID');
    PDS_base_data.PROCESSING_LEVEL_ID = '3';
    PDS_base_data.DATA_SET_ID_descr   = 'CALIB2';
    PDS_base_data.VOLUME_ID_nbr_str   = C2_VOLUME_ID_nbr_str;
    [C2.PDS_data, junk] = get_PDS_data(CD2.PDS_data, PDS_base_data, pds_mission_calendar_path);
    C2.data_file_selection_func = @select_CALIB2_DATA_files;
    
    fprintf('-------- Creating CALIB2 data set --------\n');
    create_data_set(C2, result_parent_path);
    
    % Information specific for DERIV2.
    %D2 = CD2;    
    %D2.data_file_selection_func = @select_DERIV2_DATA_files;
    %fprintf('-------- Creating DERIV2 data set --------\n');
    %create_data_set(CD2, D2, result_parent_path);


    t_s = toc;
    fprintf('%s: Wall time used: %.2f s = %.2f min\n', mfilename, t_s, t_s/60)
end



%=========================================================================================
% Create a first version of a CALIB2 or DERIV2 data set. 
% Intended to do all the operations which are common to both data sets.
% NOTE: Sets the name of the data set root directory.
%
% CD2 = Struct containing all information common for both the CALIB2 and DERIV2 data set.
% E2  = Struct containing information specific for the data set to create (CALIB2 OR DERIV2).
%=========================================================================================
function E2_path = create_data_set(E2, E2_parent_path)
    % QUESTION: How select DATA file selection function?
    %    PROPOSAL: Caller chooses.
    %    PROPOSAL: E2 struct chooses.


    E2_parent_path = get_abs_path(E2_parent_path);
    
    create_dir(E2_parent_path, E2.PDS_data.DATA_SET_ID);
    E2_path = fullfile(E2_parent_path, E2.PDS_data.DATA_SET_ID);



    kvl_updates = struct('keys', {{}}, 'values', {{}});
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'DATA_SET_ID',         ['"', E2.PDS_data.DATA_SET_ID,   '"']);
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'DATA_SET_NAME',       ['"', E2.PDS_data.DATA_SET_NAME, '"']);
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'PROCESSING_LEVEL_ID', ['"', E2.PDS_data.PROCESSING_LEVEL_ID,   '"']);
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'PRODUCT_TYPE',        ['"', E2.PDS_data.PRODUCT_TYPE, '"']);



    %============================================
    % Copy (regular) files in the ROOT directory
    %============================================
    fprintf('Copying root directory\n')
    copy_dir_files_nonrecursively(E2.CALIB1_path, E2_path, 'always overwrite');



    %================================================
    % Copy and process CATALOG, DOCUMENT directories
    %================================================
    fprintf('Copying CATALOG/, DOCUMENT/\n')

    file_processing_func = @(root_dir_path, child_relative_path) (CATALOG_DOCUMENT_file_processing_func(...
        root_dir_path, child_relative_path, ...
        fullfile(E2_path, 'CATALOG' ), ...
        kvl_updates, E2.indentation_length));
    process_dir_files_recursively(fullfile(E2.CALIB1_path, 'CATALOG'), file_processing_func);

    file_processing_func = @(root_dir_path, child_relative_path) (CATALOG_DOCUMENT_file_processing_func(...
        root_dir_path, child_relative_path, ...
        fullfile(E2_path, 'DOCUMENT' ), ...
        kvl_updates, E2.indentation_length));
    process_dir_files_recursively(fullfile(E2.CALIB1_path, 'DOCUMENT'), file_processing_func);



    %=============================================================
    % Update CATALOG/DATASET.CAT and VOLDESC.CAT files
    %=============================================================
    fprintf('Update DATASET.CAT and VOLDESC.CAT\n')
    % NOTE: Does not alter DATASET.CAT:START_TIME, STOP_TIME. Relies on old values of START_TIME, STOP_TIME to be correct.
    update_DATASET_VOLDESC(E2_path, E2.PDS_data, E2.indentation_length)



    %==================================
    % Copy and process subset of DATA/
    %==================================
    fprintf('Copy and process subset of DATA/\n')
    E2_DATA_subdir_path = fullfile(E2_path, 'DATA', E2.PDS_data.DATA_subdir);
    file_processing_func = @(root_dir_path, child_relative_path) (CALIB_DATA_file_processing_func(...
        root_dir_path, child_relative_path, ...
        E2_DATA_subdir_path, @E2.data_file_selection_func, ...
        E2.no_update_ODL_filenames_regex, kvl_updates, E2.indentation_length));
    process_dir_files_recursively(E2.DERIV1_path, file_processing_func);

    %===================================
    % Copy and process subset of CALIB/
    %===================================
    E2_CALIB_subdir_path = fullfile(E2_path, 'CALIB');
    file_processing_func = @(root_dir_path, child_relative_path) (CALIB_DATA_file_processing_func(...
        root_dir_path, child_relative_path, ...
        E2_CALIB_subdir_path, [], ...    % NOTE: No "filename accept function" ==> Accept every file.
        E2.no_update_ODL_filenames_regex, kvl_updates, E2.indentation_length));
    process_dir_files_recursively(fullfile(E2.CALIB1_path, 'CALIB'), file_processing_func);



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



%===================================================================================================
% NOTE: Only sets PDS keywords at the root level, not deeper in the "data tree" within an ODL file.
% Is therefore NOT intended for VOLDESC.VAT and DATASET.CAT
%===================================================================================================
function [s_str_lists] = generic_modify_ODL_contents(s_str_lists, s_simple, kvl_updates)
    %===========================================================================================================
    % Shorten filenames (or values derived from filenames) found inside the ODL file if necessary.
    %
    % NOTE: Does not modify the filenames of any actual files.
    %===========================================================================================================

    % NOTE: Removing quotes from values internally.
    % NOTE: ALWAYS SETS PRODUCT_ID TO FILENAME (minus extension).
    if isfield(s_simple, 'POINTER___TABLE')
        POINTER___TABLE = get_dest_filename(strrep(s_simple.POINTER___TABLE, '"', ''));
        [junk, basename, junk] = fileparts(POINTER___TABLE);
        kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, '^TABLE',     ['"', POINTER___TABLE, '"']);
        kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'PRODUCT_ID', ['"', basename,        '"']);
    end
    if isfield(s_simple, 'FILE_NAME')    
        FILENAME = get_dest_filename(strrep(s_simple.FILE_NAME, '"', ''));
        kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'FILE_NAME',   ['"', FILENAME,        '"']);
    end



    %======================================================================
    % Update ODL keywords.
    %======================================================================
    % NOTE: Strictly speaking, "s_str_lists" is NOT a key-value list only for which createLBL_KVPL_overwrite_values is intended but it works anyway.
    s_str_lists = createLBL_KVPL_overwrite_values(s_str_lists, kvl_updates, 'overwrite only when has keys');    
    
end



%=======================================================================================================================
% Add MISSING_CONSTANT to specific column in IxS LBL file. This is quite difficult since there are multiple
% OBJECT=COLUMN objects in the LBL file.
%
% NOTE: Uncertain if one should really use this funtion, although it does work, instead of just setting
% MISSING_CONSTANT (in LBL) in createLBL.
%
% ARGUMENTS
% MISSING_CONSTANT_str : String value used for the MISSING_CONSTANT and for the DESCRIPTION string.
%=======================================================================================================================
function [s_str_lists] = IxS_LBL_add_MISSING_CONSTANT(s_str_lists, MISSING_CONSTANT_str)
% PROPOSAL: Set MISSING_CONSTANT in createLBL.
%    PRO: Simple code.
%       PRO: Must not separately hardcode name of COLUMN NAME.
%    CON: Must set the MISSING_CONSTANT value (e.g. -1000) in two separate codes.
%    CON: DERIV1 LBL files disagree with the contents of the DERIV1 TAB files.
% PROPOSAL: Remake into generic function somehow, or simplifiy by deferring most work to generic function(s).

    COLUMN_OBJECT_NAME___REGEX = 'P._SWEEP_CURRENT';

    i = find(strcmp(s_str_lists.keys,            'OBJECT') & strcmp(s_str_lists.values,            'TABLE' ));
    j = find(strcmp(s_str_lists.objects{i}.keys, 'OBJECT') & strcmp(s_str_lists.objects{i}.values, 'COLUMN'));  % Should return multiple values.
    found_COLUMN = 0;
    
    for jp = j(:)'
        k_NAME = find(strcmp(s_str_lists.objects{i}.objects{jp}.keys, 'NAME'), 1);
        
        if contains_any_regexp(s_str_lists.objects{i}.objects{jp}.values{k_NAME}, {COLUMN_OBJECT_NAME___REGEX});
            
            % Add extra sentence to end of DESCRIPTION string.
            k_DESC = find(strcmp(s_str_lists.objects{i}.objects{jp}.keys, 'DESCRIPTION'));
            desc = strrep(s_str_lists.objects{i}.objects{jp}.values{k_DESC}, '"', '');
            desc = [desc, sprintf(' A value of %s implies the absence of a value.', MISSING_CONSTANT_str)];
            s_str_lists.objects{i}.objects{jp}.values{k_DESC} = ['"', desc, '"'];
            
            % Add MISSING_CONSTANT keyword (error if preexisting).
            k_MISS = find(strcmp(s_str_lists.objects{i}.objects{jp}.keys, 'MISSING_CONSTANT'), 1);
            if ~isempty(k_MISS)
                error('There already is a MISSING_CONSTANT.')
            end
            s_str_lists.objects{i}.objects{jp}.keys{end+1} = 'MISSING_CONSTANT';
            s_str_lists.objects{i}.objects{jp}.values{end+1} = MISSING_CONSTANT_str;
            s_str_lists.objects{i}.objects{jp}.objects{end+1} = [];
            
            found_COLUMN = 1;
        end
    end
    
    % Good to make this check in case of changing name of COLUMN NAME.
    if ~found_COLUMN
        error('Could not find ODL COLUMN object to add MISSING_CONSTANT to.')
    end
end



%====================================================================================================
% Function for "processing" arbitrary source file in the CATALOG/ or DOCUMENT/ directory.
%====================================================================================================
function CATALOG_DOCUMENT_file_processing_func(...
        src_root_path, src_file_relative_path, dest_root_path, ...
        kvl_updates, ODL_indentation_length)
    
    src_path  = fullfile(src_root_path,   src_file_relative_path);
    dest_path = fullfile(dest_root_path,  src_file_relative_path);    
    [junk1, src_basename, src_ext] = fileparts(src_file_relative_path);
    src_filename = [src_basename, src_ext];
    
    if is_ODL_file_to_update(src_filename)
        fprintf('Copying & modifying "%s" to "%s"\n', src_path, dest_path)
        [s_str_lists, s_simple, end_lines] = EJ_read_ODL_to_structs(src_path);
        [s_str_lists]                      = generic_modify_ODL_contents(s_str_lists, s_simple, kvl_updates);
        create_parent_dir(dest_path)
        EJ_write_ODL_from_struct(dest_path, s_str_lists, end_lines, ODL_indentation_length);
    else
        copy_file(src_path, dest_path, 'always overwrite')
    end
end



%====================================================================================================
% Function for "processing" arbitrary source file in CALIB/ or DATA/ directory.
%
% data_file_selection_func : Function with argument list (file_relative_path). If empty, then accept any file.
%
% QUESTION: no_updates_regex_filenames not needed anymore, if only applies to CATALOG/ files?
%====================================================================================================
function CALIB_DATA_file_processing_func(...
        src_root_path, src_file_relative_path, dest_root_path, ...
        data_file_selection_func, ...
        no_updates_regex_filenames, ODL_kvl_updates, ODL_indentation_length)
    
    % DVAL-NG is not satisfied with -1e3 since it is an integer (presumably).
    MISSING_CONSTANT_pre_replacement_NaN_str = '   NaN';
    MISSING_CONSTANT_str                     = '-1.0e3';
    
    % Disassemble/decompose the src file path.
    [src_file_relative_parent_path, src_filebasename, src_suffix] = fileparts(src_file_relative_path);
    src_filename = [src_filebasename, src_suffix];
    
    if isempty(data_file_selection_func) || data_file_selection_func(src_filename)
        % CASE: Include file.
        fprintf('Including %s\n', src_filename)
        
        % Derive path (including filename) for destination file.
        % NOTE: Potentially changes the filename.
        dest_file_relative_path = fullfile(src_file_relative_parent_path, get_dest_filename(src_filename));
        src_file_path  = fullfile( src_root_path,  src_file_relative_path);
        dest_file_path = fullfile(dest_root_path, dest_file_relative_path);
        
        is_IxS = 0;
        under_DATA = contains_any_regexp(dest_root_path, {'DATA/*[A-Z]*/*$'});   % Should match e.g. .../DATA///CALIBRATED///
        if under_DATA
            s = classify_DATA_file(src_filename);    % NOTE: This function only works for files under DATA/.
            is_IxS = strcmp(s.file_category, 'data') && contains_any_regexp(s.data_type, {'I.S'});
        end
            
        if is_ODL_file_to_update(src_filename)
            % CASE: LBL file
            
            [s_str_lists, s_simple, end_lines] = EJ_read_ODL_to_structs(src_file_path);
            [s_str_lists]                      = generic_modify_ODL_contents(s_str_lists, s_simple, ODL_kvl_updates);
            % Add MISSING_CONSTANT to ODL file.
            if is_IxS
                s_str_lists = IxS_LBL_add_MISSING_CONSTANT(s_str_lists, MISSING_CONSTANT_str);
            end
            create_parent_dir(dest_file_path)
            EJ_write_ODL_from_struct(dest_file_path, s_str_lists, end_lines, ODL_indentation_length);
        
        else
            % CASE: TAB file
            
            if is_IxS
                % CASE: IxS TAB file
                    
                %===============================================================
                % Copy and modify file: Replace NaN with MISSING_CONSTANT value
                %===============================================================
                str_1 = MISSING_CONSTANT_pre_replacement_NaN_str;
                str_2 = MISSING_CONSTANT_str;
                % NOTE: The paths in the unix command must NOT contain ~ if they are singly or doubly quoted,
                % or at least not if they lead to non-existent objects.
                cmd = ['sed ''s/', str_1, '/', str_2, '/g'' ''', src_file_path, ''' > ''', dest_file_path, ''''];
                [exit_code, stdout] = unix(cmd);
                if exit_code ~= 0
                    error('Error when copying (and modifying) file "%s". cmd="%s"', cmd)
                end
            else
                % NOTE: Copy file, but only if it seems dissimilar. This saves a lot of time if "overwriting" an old destination
                % data set (copying TAB files takes a lot of time).
                copy_file(src_file_path, dest_file_path, 'overwrite dissimilar');
            end
        end
        
    else
        % CASE: Exclude file.
        %fprintf('( Excluding %s )\n', fi.name)
    end
end



%===============================================================================
% Return a destination filename for a given source filename.
%
% This function effectively decides which filenames should be modified and how.
%===============================================================================
function dest_filename = get_dest_filename(src_filename)

    [junk, basename, extension] = fileparts(src_filename);
    
    if contains_any_regexp(src_filename, {'^RPCLAP_[0-9]'})
        % NOTE: Want to exclude e.g. RPCLAP160627_CALIB_MEAS.LBL and RPCLAP_CALIB_MEAS_EXCEPT.LBL
        dest_filename = upper(src_filename(4:end));    % Remove first three letters. Make all upper case.
    elseif strcmp(basename, 'RPCLAP_CALIB_MEAS_EXCEPTIONS')
        dest_filename = ['RPCLAP_CALIB_MEAS_EXCEPT', extension];
    else
        dest_filename = src_filename;
    end
    
    if length(dest_filename) > 27+1+3
        error('Failed to shorten long filename.')
    end
end



% Return true if-and-only-if file should be included in CALIB2.
function select = select_CALIB2_DATA_files(filename)
    s = select_data_set_for_DATA_file(filename);    select = s.include_in_CALIB2;
end
% Return true if-and-only-if file should be included in DERIV2.
function select = select_DERIV2_DATA_files(filename)
    s = select_data_set_for_DATA_file(filename);    select = s.include_in_DERIV2;
end



%===========================================================================================================
% Function which decides which DATA/ files should be copied to which data sets, if any.
%
% IMPLEMENTATION NOTE: Uses one function for both CALIB2 and DERIV to make sure that the algorithm is safe:
% It is easy to see that data which does not go to CALIB2 goes to DERIV2 (or nowhere).
%
% PROPOSAL: Change algorithm: Define some classes of files (cases) and what happens explicitly for files in those
% classes.
%===========================================================================================================
function s = select_data_set_for_DATA_file(filename)
    CALIB2_INCLUDE_DATA_TYPES    = {'^[IV].[LHS]$', 'B.S'};   % Regexp.
    CALIB2_EXCLUDE_SUPPORT_TYPES = {'^(FRQ|PSD)$'};           % Regexp.
    EXCLUDE_DATA_TYPES           = {'^A.S$'};                 % Regexp.

    fc = classify_DATA_file(filename);   % fc = file classification

    if strcmp(fc.file_category, 'block list')

        s.include_in_CALIB2 = 1;
        s.include_in_DERIV2 = 1;

    elseif strcmp(fc.file_category, 'data')
        
        if contains_any_regexp(fc.data_type, EXCLUDE_DATA_TYPES)
            s.include_in_CALIB2 = 0;
            s.include_in_DERIV2 = 0;            
        elseif contains_any_regexp(fc.data_type, CALIB2_INCLUDE_DATA_TYPES) && ...
            ~contains_any_regexp(fc.macro_or_support_type, CALIB2_EXCLUDE_SUPPORT_TYPES);
        
            s.include_in_CALIB2 = 1;
            s.include_in_DERIV2 = 0;
        else
            % All other ("data") files go to DERIV2.
            s.include_in_CALIB2 = 0;
            s.include_in_DERIV2 = 1;
        end
        
    else
        error('Can not classify/recognize file "%s".', filename);
    end
end



%==============================================================
% Tries to "classify" one DATA/ file by parsing the filename.
%
% PROPOSAL: Work on the full path (relative within data set)?
%    CON: The source data set DERIV2 does not have a proper PDS directory structure, i.e. no DATA/ directory. Only
%    useful if working with the destination directory.
%    PRO: Can have different treatment for different subdirectories, e.g. DATA/.
%==============================================================
function s = classify_DATA_file(filename)
    % Ex: RPCLAP_20050301_000000_BLKLIST.LBL
    % Ex: RPCLAP_20050301_001317_301_A2S.LBL
    % Ex: RPCLAP_20050303_124725_FRQ_I1H.LBL
    
    s = [];
    
    % NOTE: This still fails for exceptions i.e. RPCLAP030101_CALIB_FRQ_D_P1.TXT and counterparts.
    %s.is_ODL = ~isempty(regexp(suffix, '^(LBL|TAB|TXT)$'));
    %s.is_ODL = any(strcmp(suffix, {'LBL', 'TAB', 'TXT'}));
    
    if ~isempty(regexp(filename, '^RPCLAP_\d\d\d\d\d\d\d\d_000000_BLKLIST.(LBL|TAB)'));

        s.file_category = 'block list';

    elseif ~isempty(regexp(filename, '^RPCLAP_\d\d\d\d\d\d\d\d_\d\d\d\d\d\d_[a-zA-Z0-9][a-zA-Z0-9][a-zA-Z0-9]_[A-Z][A-Z1-3][A-Z].(LBL|TAB)'));
        % NOTE: Letters in macro numbers (hex) are lower case, but the "macro" can also be 32S, PSD, FRQ i.e. upper case letters.
        % Therefore the regex has to allow both upper and lower case.

        % NOTE: strread throws exception if it the pattern does not match.
        %[s.date, s.time, macro_or_support_type, data_type, file_type] = strread(filename, 'RPCLAP_%u_%u_%[^_]_%[^.].%s');
        [date_junk, time_junk, macro_or_support_type, data_type, file_type_junk] = strread(filename, 'RPCLAP_%u_%u_%[^_]_%[^.].%s');

        s.file_category         = 'data';
        s.data_type             = data_type{1};
        s.macro_or_support_type = macro_or_support_type{1};

    else

        %s.file_category = 'unknown';
        error('Can not classify file "%s",', filename)

    end
end



% Determine whether a file is an ODL file that should (possibly) be updated.
%
% NOTE: Can not just use file extension since (1) some .TXT files are ODL, and some are not, and (2) some .CAT files
% don't need to be updated, but reading & writing them would unnecessarily remove their comments. DVAL might also react.
function should_update = is_ODL_file_to_update(filename)
    % PROPOSAL: Move constants out of file.
    
    % Regular expressions for files which have the right file extension, but which should not be updated.
    % NOTE: All CATALOG/ files except DATASET.CAT and CATINFO.TXT.
    NON_ODL_FILES_REGEX = {'RPCLAP030101_CALIB_FRQ_[DE]_P[12]\.TXT', 'ROSETTA_INSTHOST\.CAT', 'ROSETTA_MSN\.CAT', ...
        'RPCLAP_INST\.CAT', 'RPCLAP_PERS\.CAT', 'RPCLAP_REF\.CAT', 'RPCLAP_SOFTWARE\.CAT'};

    [relative_parent_path, filebasename, suffix] = fileparts(filename);
    
    if contains_any_regexp(filename, NON_ODL_FILES_REGEX)
        should_update = 0;
        return;
    end
    
    should_update = any(strcmp(suffix, {'.LBL', '.CAT', '.TXT'}));
end



%===============================================================================================================================
% Recurse over directory subtree, and for every file found, call a custom function. Primarily intended for copying and
% "processing" (modifying) files in DATA/ and CALIB/ via the custom function.
%
% Recursive. Generic function.
%
% root_dir_path        : Directory which will be recursed into/over.
%                        E.g. source DERIV1 directory.
% file_processing_func : Function with arguments(root_dir_path, file_relative_path)
%                        file_relative_path : Path relative to root_dir_path.
%===============================================================================================================================
function process_dir_files_recursively(root_dir_path, file_processing_func)
    
    % BUG? Correct initial relative path?!
    process_dir_files_recursively_INTERNAL(root_dir_path, '.', file_processing_func)
    
    % -----------------------------------------------------------------------------------------------------------------
    function process_dir_files_recursively_INTERNAL(root_dir_path, relative_path, file_processing_func)
        
        files_info = dir(fullfile(root_dir_path, relative_path));
        for i=1:length(files_info)
            fi = files_info(i);
            if strcmp(fi.name, '.') || strcmp(fi.name, '..')
                continue
            end
            
            child_relative_path = fullfile(relative_path, fi.name);   % NOTE: If first (argument) string is empty, then no slash is added.
            
            if fi.isdir
                % CASE: "Child" is a subdirectory.
                
                process_dir_files_recursively_INTERNAL(root_dir_path, child_relative_path, file_processing_func);    % NOTE: RECURSIVE CALL
                
            else
                % CASE: "Child" is a regular (non-directory) file.
                
                file_processing_func(root_dir_path, child_relative_path)
            end
        end
    end
    
end



%==========================================================
% Copy all regular files in a directory, but nothing else.
%==========================================================
function copy_dir_files_nonrecursively(src_dir, dest_dir, copy_policy)
    files_info = dir(src_dir);    
    for i=1:length(files_info)
        fi = files_info(i);
        if strcmp(fi.name, '.') || strcmp(fi.name, '..') || fi.isdir
            continue
        end
        copy_file(fullfile(src_dir, fi.name), dest_dir, copy_policy)        
    end
end



%=======================================================================================================
% Determine if string matches at least one of a set given regexes.
%
% Wrapper around expressions since this combination of commands, combined with even more ones, has
% proven bug-prone. The meaning of compund statemens becomes too confusing to use correctly on the fly.
%
% patterns : Cell array of strings
% match    : True iff str, matches (contains) at least one of the patterns.
%=======================================================================================================
function match = contains_any_regexp(str, patterns)
    % NOTE: regexp returns cell array of ones or EMPTY depending on matches/non-matches.
    match = ~all(cellfun(@isempty, regexp(str, patterns)));
end



%=====================================================================================
% Create directory. - Wrapper around mkdir for better erro handling.
%
% NOTE: Can create multiple nested directories.
% NOTE: Permits destination directory to already exist (do nothing).
% NOTE: Some of directories may already exist.
% NOTE: Can effectively set absolute paths by settings parent_path='/'.
% NOTE: Can effectively create a directory from one path relative_new_dir_path="." .
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



% Create the parent directory for a file. It is useful to call this function before writing to a new file in a new data
% set directory structure.
function create_parent_dir(file_path)
     % Create destination parent directory (if necessary).
     file_parent_path = fileparts(file_path);
     %if ~exist(file_parent_path, 'dir')
         create_dir(file_parent_path, '.');
     %end
end



%==============================================================================================================
% Wrapper around "copyfile" to produce better error behaviour.
% NOTE: Can copy regular files as well as directories (recursively).
% NOTE: Will create the parent directory (incl. nested ones) if necessary to copy the file.
%
% dest_path = For files, the destination file. For directories, the parent directory of the new directory. (?)
% policy = How to handle cases where the destination file already exists.
%    'overwrite dissimilar' = Overwrite destination file if it has a different number of bytes.
%    'always overwrite' = ...
%==============================================================================================================
function copy_file(source_path, dest_path, policy)
    % PROPOSAL: Use identical dates as criterion for "overwrite dissimilar"?

    switch(policy)
        case 'overwrite dissimilar'
            [path, basename, extension] = fileparts(source_path);
            src_info  = dir(source_path);
            dest_info = dir(dest_path);
            execute_copy = isempty(dest_info) || src_info.isdir || dest_info.bytes ~= src_info.bytes;
        case 'always overwrite'
            execute_copy = 1;
        otherwise
            error('No such policy.')
    end

    if execute_copy
        
        create_parent_dir(dest_path)
        
        % Copy the file/directory.
        [success, msg, msgid] = copyfile(source_path, dest_path);    
        if ~success
            error('Can not copy file/directory "%s". %s', dest_path, msg)
        end
    else
        fprintf('Not overwriting "%s"\n', source_path)
    end
end



%===================================================================================================================
% Author: Erik P G Johansson, IRF-U, Uppsala, Sweden
% First created 2016-06-09
%
% Convert (relative/absolute) path to an absolute (canonical) path.
%
% NOTE: Will also convert ~ (home directory).
% NOTE: Only works for existing paths.
% NOTE: The resulting path will NOT end with slash/backslash unless it is the system root directory on Linux ("/").
% (MATLAB does indeed seem to NOT have a function for doing this(!).)
%
% NOTE: Originally copied from Lapdog's create_C2D2.m (internal function).
%===================================================================================================================
function path = get_abs_path(path)
% PROPOSAL: Rethrow exception via errorp with amended message somehow?
% PROPOSAL: Separate out as a separate function file?

try
    home_dir = getenv('HOME');
    path = strrep(path, '~', home_dir);
    
    if ~exist(path, 'dir')
        [dir_path, basename, suffix] = fileparts(path);   % NOTE: If ends with slash, then everything is assigned to dir_path!
   
        % Uses MATLAB trick to convert path to absolute path.
        dir_path = cd(cd(dir_path));
        path = fullfile(dir_path, [basename, suffix]);
    else
        path = cd(cd(path));
    end
catch e
    error('Failed to convert path "%s" to absolute path.\nException message: "%s"', path, e.message)
end
end

