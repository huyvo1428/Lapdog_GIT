% Initially created by Erik P G Johansson, IRF Uppsala, 2016-07-29.
%
% Update DATASET.CAT, VOLDESC.CAT associated with a data set.
% Primarily intended to be used by create_C2D2.
% Takes a general "standardized" struct with fields with standard names.
%
% NOTE: It is not entirely unambiguous how much should be set automatically. It is likely that there always some things
% that should be done manually.
% NOTE: No field values should be quotes. The function add that itself.
% NOTE: The code does derive any values from other values.
%
% IMPLEMENTATION NOTE: Functionality is implemented as a separate code so that it could also (maybe) be used for
% updating VOLDESC.CAT and DATAET.CAT, any data set, i.e. also EDITED.
%
function update_DATASET_VOLDESC(dataset_path, data, indentation_length)
    % PROPOSAL: Set using table of values.
    % QUESTION: Should this code _derive_ values from other values?
    %   PROPOSAL: Yes, if standalone.
    
    %================================================
    % ASSERTION: Check that fields contain no quotes
    %================================================
    fn_list = fieldnames(data);
    for i = 1:length(fn_list)
        fn = fn_list{i};
        if ismember('"', data.(fn));
            error('Structure field" %s" contais disallowed quotation mark.', fn)
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
        data.(fn) = ['"', data.(fn), '"'];
    end


    
    VOLDESC_path = [dataset_path, filesep, 'VOLDESC.CAT'];
    DATASET_path = [dataset_path, filesep, 'CATALOG', filesep, 'DATASET.CAT'];
    
    %-------------------------------------------------------------------------------------------------------------------
    
    [s_str_lists, junk, end_lines] = EJ_read_ODL_to_structs(VOLDESC_path);
    
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'VOLUME', 'VOLUME_NAME',       data.VOLUME_NAME);                  % Quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'VOLUME', 'VOLUME_ID',         data.VOLUME_ID);                    % NOT quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'VOLUME', 'VOLUME_VERSION_ID', data.VOLUME_VERSION_ID);            % Quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'VOLUME', 'DESCRIPTION',       data.VOLDESC___DESCRIPTION);        % Quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'VOLUME', 'PUBLICATION_DATE',  data.VOLDESC___PUBLICATION_DATE);   % Not quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'VOLUME', 'DATA_SET_ID',       data.DATA_SET_ID);                  % Quoted
    
    EJ_write_ODL_from_struct(VOLDESC_path, s_str_lists, end_lines, indentation_length);
    clear s_str_lists end_lines
    
    %-------------------------------------------------------------------------------------------------------------------
    
    [s_str_lists, junk, end_lines] = EJ_read_ODL_to_structs(DATASET_path);
    
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'DATA_SET', 'DATA_SET_ID', data.DATA_SET_ID);    % Quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'DATA_SET_NAME',         data.DATA_SET_NAME);           % Quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'DATA_SET_RELEASE_DATE', data.DATA_SET_RELEASE_DATE);   % Not quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'ABSTRACT_DESC',         data.ABSTRACT_DESC);           % Quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'CONFIDENCE_LEVEL_NOTE', data.CONFIDENCE_LEVEL_NOTE);   % Quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'CITATION_DESC',         data.CITATION_DESC);           % Quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_INFORMATION', 'DATA_SET_TERSE_DESC',   data.DATA_SET_TERSE_DESC);     % Quoted
    s_str_lists = set_value(s_str_lists, 'OBJECT', 'DATA_SET', 'OBJECT', 'DATA_SET_TARGET',      'TARGET_NAME',           data.TARGET_NAME);   % Quoted
    
    EJ_write_ODL_from_struct(DATASET_path, s_str_lists, end_lines, indentation_length);
end



%========================================================================================
% Set a specific value an arbitrary number of levels into a ODL tree structure.
%
% varargin : object_key_1, object_value_1, ..., object_key_N, object_value_N, key, value
%========================================================================================
function s_str_lists = set_value(s_str_lists, varargin)
    % PROPOSAL: Separate out as generic function?
    
    if length(varargin) == 2
        key   = varargin{1};
        value = varargin{2};
        
        i = find(strcmp(s_str_lists.keys, key));
        if length(i) ~= 1
            error('Did not find exactly one matching key for "%s".', key)
       end
        s_str_lists.values{i} = value;
        
    elseif length(varargin) >= 4
        
        object_key   = varargin{1};
        object_value = varargin{2};
        
        i = find(and(strcmp(s_str_lists.keys, object_key), strcmp(s_str_lists.values, object_value)));
        if length(i) ~= 1
            error('Did not find exactly one matching key-value pair for "%s"-"%s".', object_key, object_value)
        end
        s_str_lists.objects{i} = set_value(s_str_lists.objects{i}, varargin{3:end});   % NOTE: RECURSIVE CALL.
        
    else
        error('Not same number of keys and values.')
    end
    
end
