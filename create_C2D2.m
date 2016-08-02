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
function create_C2D2(CALIB1_path, DERIV1_path, EG_files_dir, result_parent_path, kernel_file)
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
    %   QUESTION: Is it a problem? Are there any tasks that are different for C2,D2?
    %
    % PROPOSAL: Separate function/file for data_set_info from geometry code. For reuse?
    %
    % BUG/PROPOSAL: Update VOLDESC.CAT
    % BUG/PROPOSAL: Update DATASET.CAT
    %
    % TODO: Change name "descr" --> DATA_SET_ID_descr.
    %
    %===================================================================================================
    % Variable naming convention:
    % ---------------------------
    % C1,C2 = CALIB1/2
    % D1,D2 = DERIV1/2
    % E2 = Either one of CALIB2 or DERIV2.
    %===================================================================================================
    
    ODL_INDENTATION_LENGTH = 4;
    
    
    
    C1_path = get_abs_path(CALIB1_path);
    D1_path = get_abs_path(DERIV1_path);
    
    
    
    %==================================================
    % Extract data set information from CALIB1, DERIV1
    %==================================================
    C1_VOLDESC_path = [C1_path, filesep, 'VOLDESC.CAT'];
    C1_DATASET_path = [C1_path, filesep, 'CATALOG', filesep, 'DATASET.CAT'];
    [junk, C1_VOLDESC] = EJ_read_ODL_to_structs(C1_VOLDESC_path);
    [junk, C1_DATASET] = EJ_read_ODL_to_structs(C1_DATASET_path);
    C1_DATA_SET_ID   = C1_VOLDESC.OBJECT___VOLUME{1}.DATA_SET_ID;
    C1_DATA_SET_NAME = C1_DATASET.OBJECT___DATA_SET{1}.OBJECT___DATA_SET_INFORMATION{1}.DATA_SET_NAME;
    
    [junk, part1, part2] = fileparts(D1_path);   % NOTE: Interprets the period in the version number as beginning of file suffix.
    D1_DATA_SET_ID = [part1, part2];
    
    % Example DATA_SET_ID: RO-E-RPCLAP-5-EAR1-DERIV-V0.5
    [c1_target_ID, c1_DPL, c1_mission_phase_abbrev, c1_descr, c1_version] = strread(C1_DATA_SET_ID, 'RO-%[^-]-RPCLAP-%[^-]-%[^-]-%[^-]-V%[^-]');
    [d1_target_ID, d1_DPL, d1_mission_phase_abbrev, d1_descr, d1_version] = strread(D1_DATA_SET_ID, 'RO-%[^-]-RPCLAP-%[^-]-%[^-]-%[^-]-V%[^-]');
    % Example DATA_SET_NAME: ROSETTA-ORBITER EARTH RPCLAP 5 EAR1 DERIV V0.5
    [c1_DATA_SET_NAME___target_name, junk1, junk2, junk3, junk4] = strread(C1_DATA_SET_NAME, 'ROSETTA-ORBITER %[^ ] RPCLAP %[^ ] %[^ ] %[^ ] V%[^ ]');
    
    
    
    %=========================================================================
    % Check that the DPLs are correct and that the data sets
    % match in everything else (except the description strings).
    %=========================================================================
    if ~strcmp(c1_target_ID, d1_target_ID) || ~strcmp(c1_mission_phase_abbrev, d1_mission_phase_abbrev) || ~strcmp(c1_version, d1_version)
        error('CALIB1 and DERIV1 data sets do not match.')
    elseif ~strcmp(c1_DPL, '3') || ~strcmp(d1_DPL, '5')
        error('Data sets have the wrong archiving levels?')
    end
    
    
    
    % Information common/necessary for creating both CALIB2 and DERIV2.
    % Better name? Change name to CD?
    % NOTE: ROSETTA_INSTHOST.CAT, ROSETTA_MSN.CAT should not contain anything that should be updated.
    % They also contain ODL comments (which would be removed).
    CD2.CALIB1_path        = C1_path;
    CD2.DERIV1_path        = D1_path;
    CD2.EG_files_dir       = EG_files_dir;
    CD2.result_parent_path = get_abs_path(result_parent_path);
    CD2.no_update_ODL_filenames_regex = {};
    CD2.no_update_ODL_filenames_regex{end+1} = 'RPCLAP030101_CALIB_FRQ_[DE]_P[12]\.TXT';
    CD2.no_update_ODL_filenames_regex{end+1} = 'ROSETTA_INSTHOST\.CAT';
    CD2.no_update_ODL_filenames_regex{end+1} = 'ROSETTA_MSN\.CAT';
    CD2.kernel_file  = kernel_file;
    CD2.EG_files_dir = EG_files_dir;
    CD2.indentation_length = ODL_INDENTATION_LENGTH;
    CD2.PDS_data = [];
    CD2.PDS_data.target_ID                   = c1_target_ID{1};
    CD2.PDS_data.DATA_SET_NAME___target_name = c1_DATA_SET_NAME___target_name{1};
    CD2.PDS_data.mission_phase_abbrev        = c1_mission_phase_abbrev{1};   % E.g. EAR1.
    CD2.PDS_data.version_str                 = c1_version{1};
    CD2.PDS_data.PUBLICATION_DATE            = datestr(now, 'YYYY-mm-dd');
    CD2.PDS_data.DATA_SET_RELEASE_DATE       = CD2.PDS_data.PUBLICATION_DATE;

    
    
    % Information specific for CALIB2.
    C2 = CD2;
    C2.PDS_data.descr = 'CAL';
    C2.PDS_data.PROCESSING_LEVEL_ID = '3';
    C2.data_file_selection_func = @select_CALIB2_DATA_files;
    fprintf('-------- Creating CALIB2 data set --------\n');
    create_skeleton_data_set(C2, result_parent_path);
    
    % Information specific for DERIV2.
    D2 = CD2;    
    D2.PDS_data.descr = 'DER';
    D2.PDS_data.PROCESSING_LEVEL_ID = '5';
    D2.data_file_selection_func = @select_DERIV2_DATA_files;
    %fprintf('-------- Creating DERIV2 data set --------\n');
    %create_skeleton_data_set(CD2, D2, result_parent_path);
    
end



%=========================================================================================
% Create a first version of a CALIB2 or DERIV2 data set. 
% Intended to do all the operations which are common to both data sets.
% NOTE: Sets the name of the data set root directory.
%
% CD2 = Struct containing all information common for both the CALIB2 and DERIV2 data set.
% E2  = Struct containing information specific for the data set to create.
%=========================================================================================
function E2_path = create_skeleton_data_set(E2, E2_parent_path)
    % QUESTION: How select DATA file selection function?
    %    PROPOSAL: Caller chooses.
    %    PROPOSAL: E2 struct chooses.
    %

    % TEMPORARY ############################################################################################ TEMPORARY
    E2.PDS_data.MISSION_PHASE_NAME  = 'xxxxx';
    E2.PDS_data.TARGET_NAME         = 'xxxxx';
    E2.PDS_data.VOLUME_ID_nbr       = 0;   % ROLAP number.
    %--
    E2.PDS_data.DATA_SET_ID         = construct_DATA_SET_ID  (E2.PDS_data);
    E2.PDS_data.DATA_SET_NAME       = construct_DATA_SET_NAME(E2.PDS_data);
    E2.PDS_data.VOLDESC___PUBLICATION_DATE = datestr(now, 'yyyy-mm-dd');
    E2.PDS_data = get_PDS_data(E2.PDS_data);
    
    
    
    create_dir(E2_parent_path, E2.PDS_data.DATA_SET_ID);
    E2_path = [E2_parent_path, filesep, E2.PDS_data.DATA_SET_ID];

    
    
    %============================================
    % Copy (regular) files in the ROOT directory
    %============================================
    copy_dir_files_nonrecursively(E2.CALIB1_path, E2_path);
    
    %===========================================
    % Copy CATALOG, DOCUMENT, CALIB directories
    %===========================================
    copy_file([E2.CALIB1_path, filesep, 'CATALOG'],  [E2_path, filesep, 'CATALOG']);
    copy_file([E2.CALIB1_path, filesep, 'DOCUMENT'], [E2_path, filesep, 'DOCUMENT']);
    copy_file([E2.CALIB1_path, filesep, 'CALIB'],    [E2_path, filesep, 'CALIB']);
    
    %===============================
    % Copy subset of DATA/ to DATA/
    %===============================
    E2_DATA_subdir_path = [E2_path, filesep, 'DATA', filesep, E2.PDS_data.DATA_subdir];
    create_dir(E2_DATA_subdir_path, '.');
    copy_dir_selectively(E2.DERIV1_path, E2_DATA_subdir_path, @E2.data_file_selection_func);
    
    
    
    %==================
    % Update ODL files
    %==================
    kvl_updates = struct('keys', {{}}, 'values', {{}});
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'DATA_SET_ID',         ['"', E2.PDS_data.DATA_SET_ID,   '"']);
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'DATA_SET_NAME',       ['"', E2.PDS_data.DATA_SET_NAME, '"']);
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'PROCESSING_LEVEL_ID', ['"', E2.PDS_data.PROCESSING_LEVEL_ID,   '"']);
    kvl_updates = createLBL_KVPL_add_kv_pair(kvl_updates, 'PRODUCT_TYPE',        ['"', E2.PDS_data.PRODUCT_TYPE, '"']);
    update_generic_ODL_files(E2_path, kvl_updates, E2.no_update_ODL_filenames_regex, E2.indentation_length);
    update_DATASET_VOLDESC(E2_path, E2.PDS_data, E2.indentation_length)
    
    
    
    %====================
    % Add geometry files
    %====================
    cspice_furnsh(get_abs_path(E2.kernel_file));  % For some reason cspice_furnsh does not appear to understand ~ in a path.
    geometry_addToDataSet(E2_path, E2.PDS_data, E2.EG_files_dir);
    
    % "CSPICE_KCLEAR clears the KEEPER system: unload all kernels, clears
    % the kernel pool, and re-initialize the system."
    cspice_kclear
end



%==========================================================================================
% Update all LBL, CAT, TXT files (assumes that they are ODL) found in a directory subtree
% If they match the exceptions then they are not altered.
%
% NOTE: Delegates actual ODL updating to "update_generic_single_ODL_file".
%
% Recursive.
%==========================================================================================
function update_generic_ODL_files(dir_path, kvl_updates, no_updates_filenames_regex, indentation_length)
    
    files_info = dir(dir_path);

    for i=1:length(files_info)
        fi = files_info(i);
        filename = fi.name;
        file_path = [dir_path, filesep, filename];        
        [junk1, junk2, suffix] = fileparts(filename);
        
        if strcmp(filename, '.') || strcmp(filename, '..')
            % Do nothing
            %;
        elseif fi.isdir
            update_generic_ODL_files(file_path, kvl_updates, no_updates_filenames_regex, indentation_length)    % NOTE: RECURSIVE CALL
        elseif any(strcmp(suffix, {'.LBL', '.CAT', '.TXT'}))
            %try
            if regexpp(filename, no_updates_filenames_regex)
                %fprintf('SKIPPING ODL file    "%s"\n', file_path)
                
            else
                update_generic_single_ODL_file(file_path, kvl_updates, indentation_length)     % NOTE: Update ONE file.
            end
            %catch e
                %x = 1;
            %end
        end
    end
end



%===================================================================================================
% Updates PDS keywords.
%
% NOTE: Only sets PDS keywords at the root level, not deeper in the "data tree" within an ODL file.
% Hence NOT intended for VOLDESC.VAT and DATASET.CAT
% NOTE: Name "update_generic_single_ODL_file" is to distinguish it from "update_generic_ODL_files".
%===================================================================================================
function update_generic_single_ODL_file(file_path, kvl_updates, indentation_length)
    %fprintf('Updating ODL file "%s"\n', file_path)
    [s_str_lists, junk, end_lines] = EJ_read_ODL_to_structs(file_path);
        
    % NOTE: Strictly speaking, "s_str_lists" is NOT a key-value list only.
    s_str_lists = createLBL_KVPL_overwrite_values(s_str_lists, kvl_updates, 'overwrite only when has keys');    
    
    EJ_write_ODL_from_struct(file_path, s_str_lists, end_lines, indentation_length);
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
        
        s.include_in_CALIB2 = regexpp(s.data_type, CALIB2_INCLUDE_DATA_TYPES) && ~regexpp(s.macro_or_support_type, CALIB2_EXCLUDE_SUPPORT_TYPES);
        
        s.include_in_DERIV2 = ~s.include_in_CALIB2 && ~regexpp(s.data_type, DERIV2_EXCLUDE_DATA_TYPES);
        
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
        
    elseif ~isempty(regexp(filename, '^RPCLAP_\d\d\d\d\d\d\d\d_\d\d\d\d\d\d_[A-Z0-9][A-Z0-9][A-Z0-9]_[A-Z][A-Z0-9][A-Z].(LBL|TAB)'));
        
        % NOTE: strread throws exception if it the pattern does not match.
        [s.date, s.time, macro_or_support_type, data_type, file_type] = strread(filename, 'RPCLAP_%u_%u_%[^_]_%[^.].%s');
        
        s.file_category = 'data';
        s.data_type = data_type{1};
        s.macro_or_support_type = macro_or_support_type{1};
        
    else
        
        s.file_category = 'unknown';
        
    end
end



function DATA_SET_ID = construct_DATA_SET_ID(data)
    % Example DATA_SET_ID: RO-E-RPCLAP-5-EAR1-DERIV-V0.5
    DATA_SET_ID = sprintf('RO-%s-RPCLAP-%s-%s-%s-V%s', ...
        data.target_ID, data.PROCESSING_LEVEL_ID, data.mission_phase_abbrev, data.descr, data.version_str);
end



function DATA_SET_ID = construct_DATA_SET_NAME(data)
    % Example DATA_SET_NAME: ROSETTA-ORBITER EARTH RPCLAP 5 EAR1 DERIV V0.5
    DATA_SET_ID = sprintf('ROSETTA-ORBITER %s RPCLAP %s %s %s V%s', ...
        data.DATA_SET_NAME___target_name, data.PROCESSING_LEVEL_ID, data.mission_phase_abbrev, data.descr, data.version_str);
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
function copy_dir_selectively(src_parent_dir, dest_parent_dir, selection_func)
    % Use for other copying than just DATA/ ?

    files_info = dir(src_parent_dir);
    for i=1:length(files_info)
        fi = files_info(i);
        if strcmp(fi.name, '.') || strcmp(fi.name, '..')
            continue
        end

        src_dir_child  = [src_parent_dir,  filesep, fi.name];
        dest_dir_child = [dest_parent_dir, filesep, fi.name];
        
        if fi.isdir
            % CASE: It is a subdirectory.

            copy_dir_selectively(...
                src_dir_child, ...
                dest_dir_child, ...       % NOTE: Calling with the destination (parent) directory.
                selection_func);      % NOTE: RECURSIVE CALL
        else
            % CASE: It is a regular (non-directory) file.

            if selection_func(fi.name)
                %fprintf('Including %s\n', fi.name)

                if ~exist(dest_parent_dir, 'dir')
                    create_dir(dest_parent_dir, '.');
                end
                copy_file(src_dir_child, dest_dir_child);
            else
                %fprintf('( Excluding %s )\n', fi.name)
            end
        end
    end
end
%===============================================================================================================================
% Selectively copy files from one directory structure to another analogous one. Will only create those destination directories
% which are required for copying files to them. Might therefore not create any destination directory at all. Primarily intended
% for copying files from DATA/*/ to DATA/*/.
%
% Recursive. Generic function.
%
% src_dir         : E.g. RO-E-RPCLAP-5-EAR1-DERIV-V0.5/2005/
% dest_parent_dir : E.g. RO-E-RPCLAP-3-EAR1-CAL-V0.5/DATA/CALIBRATED/    # NOTE: Excludes subdirectory "2005".
%                   Does not have to exist and might not even be created if there are no files/directories to copy to it.
% selection_func  : Function of a file name. Returns true for files which should be copied.
%===============================================================================================================================
% function copy_dir_selectively(src_dir, dest_parent_dir, selection_func)    
%     % Use for other copying than just DATA/ ?
% 
%     [junk, basename, suffix] = fileparts(src_dir);
%     src_dir_name = [basename, suffix];
%     dest_dir     = [dest_parent_dir, filesep, src_dir_name];
%     
%     files_info = dir(src_dir);
% 
%     for i=1:length(files_info)
%         fi = files_info(i);
%         if strcmp(fi.name, '.') || strcmp(fi.name, '..')
%             continue
%         end
% 
%         src_dir_child  = [src_dir,  filesep, fi.name];
%         dest_dir_child = [dest_dir, filesep, fi.name];
%         
%         if fi.isdir
%             % CASE: It is a subdirectory.
% 
%             copy_dir_selectively(...
%                 src_dir_child, ...
%                 dest_dir, ...       % NOTE: Calling with the destination (parent) directory.
%                 selection_func);
%         else
%             % CASE: It is a regular (non-directory) file.
% 
%             if selection_func(fi.name)
%                 %fprintf('Including %s\n', fi.name)
% 
%                 if ~exist(dest_dir, 'dir')
%                     create_dir(dest_dir, '.');
%                 end
%                 copy_file(src_dir_child, dest_dir_child);
%             else
%                 %fprintf('( Excluding %s )\n', fi.name)
%             end
%         end
%     end
% end



%=========================================================
% Copy all regular files in a directory, but nothing else
%=========================================================
function copy_dir_files_nonrecursively(src_dir, dest_dir)
    files_info = dir(src_dir);    
    for i=1:length(files_info)
        fi = files_info(i);
        if strcmp(fi.name, '.') || strcmp(fi.name, '..') || fi.isdir
            continue
        end
        copy_file([src_dir, filesep, fi.name], dest_dir)        
    end
end



%====================================================================================================
% Wrapper around expressions since this combination of commands, combined with even more ones, has proven bug-prone. The meaning
% of compund statemens becomes too confusing to use correctly on the fly.
%
% patterns = Cell array of strings
% match = true iff str, matches at least one of the patterns.
%
% regexpp = regexp prime
%====================================================================================================
function match = regexpp(str, patterns)
    % NOTE: regexp returns cell array of ones or EMPTY depending on matches/non-matches.
    %match = ~isempty(regexp(str, patterns));
    match = ~all(cellfun(@isempty, regexp(str, patterns)));
end



%=====================================================================================
% Create directory. - Wrapper around mkdir for better erro handling.
%
% NOTE: Can create multiple nested directories.
% NOTE: Some of directories may already exist.
% NOTE: Can effectively set absolute paths by settings parent_path='/'.
% NOTE: Can effectively create a directory from one path relative_new_dir_path="." .
%=====================================================================================
function create_dir(parent_path, relative_new_dir_path)
    % PROPOSAL: Remake into creating directory only if necessary. (Avoid warning)
    %   CON: Only one call(?) wants that functionality.
    
    new_dir = [parent_path, filesep, relative_new_dir_path];
    if exist(new_dir, 'file')
        error('Can not create directory "%s" since there already is a file or directory by that name.', new_dir)
    end
    [success, msg, msgid] = mkdir(parent_path, relative_new_dir_path);
    if ~success
        error('Failed to create directory "%s". %s', new_dir_path, msg)
    end
end



% Wrapper around "copyfile" to produce better error behaviour.
% NOTE: Can copy regular files as well as directories (recursively).
function copy_file(source_path, dest_parent_dir)
    [success, msg, msgid] = copyfile(source_path, dest_parent_dir);
    if ~success
        error('Can not copy file/directory "%s". %s', dest_parent_dir, msg)
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

