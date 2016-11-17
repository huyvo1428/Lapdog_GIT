% Initially created by Erik P G Johansson, IRF Uppsala, 2016-07-29.
%
% Update DATASET.CAT, VOLDESC.CAT associated with a data set.
% Primarily intended to be used by create_C2D2.
%
% Takes a general "standardized" struct with fields with standard names which can be obtained from e.g. get_PDS_data plus some fields that have to be added separately.
%
% NOTE: It is not entirely unambiguous how much should be set automatically. It is likely that there always some things
% that should be done manually.
% NOTE: No submitted field values should be quoted. The function adds that itself.
% NOTE: The code does derive any values from other values.
% NOTE: Does not update DATASET.CAT:START_TIME, STOP_TIME. Relies on old values of these to be correct (should work for
% MTP-data sets created with pds).
%
% NOTE: The current implementation overwrites the ROLAP number (VOLUME_ID_nbr_str) which might be underdesirable for
% EDITED where it might have been set correctly.
%
% IMPLEMENTATION NOTE: Functionality is implemented as a separate code so that it could also (maybe) be used for
% updating VOLDESC.CAT and DATASET.CAT, in any data set.
%
% ARGUMENTS
% =========
% PDS_data           : Struct with "standardized" fields for PDS keys or parts thereof.
%                      Accepts the struct returned from get_PDS with the fields VOLDESC___PUBLICATION_DATE and
%                      DATA_SET_RELEASE_DATE added to it.
% indentation_length : Indendation length used when writing the ODL files.
%
function update_DATASET_VOLDESC(dataset_path, PDS_data, indentation_length)
    %
    % PROPOSAL: Add functionality for MTP split data sets. Add that data was acquired during MTPxxx of the xxx phase.
    % QUESTION: Uncertain which fields should be updated when updating data set version and one may have old versions
    % that should be (manually) amended to rather than set.
    %
    % PROPOSAL: Add support for the type of target (comet, asteroid, planet).
    %
    
    %================================================
    % ASSERTION: Check that fields contain no quotes
    %================================================
    fn_list = fieldnames(PDS_data);
    for i = 1:length(fn_list)
        fn = fn_list{i};
        if ismember('"', PDS_data.(fn));
            error('Structure field" %s" contains disallowed quotation mark.', fn)
        end
    end

    
    
    %===============================================
    % Add quotes to fields which should have quotes
    %===============================================
    QUOTED_FIELDS = {...
        'VOLUME_NAME', 'VOLUME_VERSION_ID', 'VOLDESC___DESCRIPTION', 'DATA_SET_ID', ...    % VOLDESC.CAT
        'DATA_SET_NAME', 'ABSTRACT_DESC', 'CONFIDENCE_LEVEL_NOTE', 'CITATION_DESC', 'DATA_SET_TERSE_DESC', 'TARGET_NAME', ...    % DATASET.CAT
        };
    for i = 1:length(QUOTED_FIELDS)
        fn = QUOTED_FIELDS{i};
        PDS_data.(fn) = ['"', PDS_data.(fn), '"'];
    end

    policy = 'replace';
    
    VOLDESC_path = [dataset_path, filesep, 'VOLDESC.CAT'];
    DATASET_path = [dataset_path, filesep, 'CATALOG', filesep, 'DATASET.CAT'];
    
    %-------------------------------------------------------------------------------------------------------------------
    
    [s_str_lists, junk, end_lines] = EJ_read_ODL_to_structs(VOLDESC_path);
    
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'VOLUME', 'VOLUME_NAME',       PDS_data.VOLUME_NAME);                  % Quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'VOLUME', 'VOLUME_ID',         PDS_data.VOLUME_ID);                    % NOT quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'VOLUME', 'VOLUME_VERSION_ID', PDS_data.VOLUME_VERSION_ID);            % Quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'VOLUME', 'DESCRIPTION',       PDS_data.VOLDESC___DESCRIPTION);        % Quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'VOLUME', 'PUBLICATION_DATE',  PDS_data.VOLDESC___PUBLICATION_DATE);   % Not quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'VOLUME', 'DATA_SET_ID',       PDS_data.DATA_SET_ID);                  % Quoted
    
    EJ_write_ODL_from_struct(VOLDESC_path, s_str_lists, end_lines, indentation_length);
    clear s_str_lists end_lines
    
    %-------------------------------------------------------------------------------------------------------------------
    
    [s_str_lists, junk, end_lines] = EJ_read_ODL_to_structs(DATASET_path);
    
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'DATA_SET', 'DATA_SET_ID', PDS_data.DATA_SET_ID);    % Quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'DATA_SET_NAME',         PDS_data.DATA_SET_NAME);           % Quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'DATA_SET_RELEASE_DATE', PDS_data.DATA_SET_RELEASE_DATE);   % Not quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'ABSTRACT_DESC',         PDS_data.ABSTRACT_DESC);           % Quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'CONFIDENCE_LEVEL_NOTE', PDS_data.CONFIDENCE_LEVEL_NOTE);   % Quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'CITATION_DESC',         PDS_data.CITATION_DESC);           % Quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'DATA_SET_TERSE_DESC',   PDS_data.DATA_SET_TERSE_DESC);     % Quoted
    s_str_lists = set_value(policy, s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_TARGET',      'TARGET_NAME',           PDS_data.TARGET_NAME);   % Quoted
    
    EJ_write_ODL_from_struct(DATASET_path, s_str_lists, end_lines, indentation_length);
end




%==========================================================================================================
% Set a specific value an arbitrary number of levels into a ODL tree structure.
%
% policy
%    'replace' : Replace the value of preexisting key. Error if does not already exist.
%    'new key' : Add new key. "new key" refers to a "leaf", i.e. not OBJECTS. Error if key already exists.
% varargin : object_key_1, object_value_1, ..., object_key_N, object_value_N, key, value
%
% NOTE: Can not handle multiple OBJECT with the same value, e.g. OBJECT=COLUMN within OBJECT=TABLE.
%==========================================================================================================
function s_str_lists = set_value(policy, s_str_lists, varargin)
    % PROPOSAL: Separate out as generic function?
    % PROPOSAL: Omit "OBJECT" in calls, since multiple arguments implies OBJECT anyway.
    
    if length(varargin) == 2
        key   = varargin{1};
        value = varargin{2};
        
        i = find(strcmp(s_str_lists.keys, key));
        
        if strcmp(policy, 'replace')
            if length(i) ~= 1 
                error('Did not find exactly one matching key for "%s".', key)
            end
            s_str_lists.values{i} = value;
        elseif strcmp(policy, 'new key')
            if length(i) ~= 0
                error('Found pre-existing key for "%s".', key)
            end
            s_str_lists.keys{end+1}    = key;
            s_str_lists.value{end+1}   = value;
            s_str_lists.objects{end+1} = [];
        else
            error('Illegal policy.')
        end
        
    elseif length(varargin) >= 4
        
        object_key   = varargin{1};
        object_value = varargin{2};
        
        i = find(and(strcmp(s_str_lists.keys, object_key), strcmp(s_str_lists.values, object_value)));
        if length(i) ~= 1
            error('Did not find exactly one matching key-value pair for "%s"-"%s".', object_key, object_value)
        end
        s_str_lists.objects{i} = set_value(policy, s_str_lists.objects{i}, varargin{3:end});   % NOTE: RECURSIVE CALL.
        
    else
        error('Not same number of keys and values.')
    end
    
end
