%
% Set a specific value and object an arbitrary number of levels into a s_str_lists structure representing an ODL file.
%
%
% ARGUMENTS AND RETURN VALUE
% ==========================
% policy      : String set to one of two values.
%               'replace' : Replace the value of preexisting key. Error if does not already exist.
%               'new key' : Add new key. "new key" refers to a "leaf", i.e. not OBJECTS. Error if key already exists.
% s_str_lists : See lib_shared_EJ.read_ODL_to_structs.
% location : Cell array with strings, {object_key_1, object_value_1, ..., object_key_N, object_value_N, key}
%
%
% NOTE: Can not handle multiple OBJECT keys with the same value, e.g. OBJECT=COLUMN within OBJECT=TABLE.
%
%
% Initially created by Erik P G Johansson, IRF Uppsala, 2016-08-xx
%
function s_str_lists = set_s_str_lists_value(policy, s_str_lists, location, value, object)
    % PROPOSAL: Omit "OBJECT" in calls, since multiple arguments implies OBJECT anyway.
    
    % ASSERTIONS
    if ~iscell(location) || ~isvector(location)
        error('set_s_str_lists_value is not a cell vector.')
    end
    
    
    
    if length(location) == 1
        % CASE: Cell specifies key-value on current level.
        
        key = location{1};
        
        i = find(strcmp(s_str_lists.keys, key));
        
        if strcmp(policy, 'replace')
            % ASSERTION
            if length(i) ~= 1 
                error('Did not find exactly one matching key for "%s".', key)
            end
            
            % Overwrite value for existing key.
            s_str_lists.values{i}  = value;
            s_str_lists.objects{i} = object;
            
        elseif strcmp(policy, 'new key')
            % ASSERTION
            if ~isempty(i)
                error('Found pre-existing key for "%s".', key)
            end
            
            % Add new key + value.
            s_str_lists.keys{end+1}    = key;
            s_str_lists.value{end+1}   = value;
            s_str_lists.objects{end+1} = object;
        else
            error('Illegal policy.')
        end

    elseif length(location) >= 3
        % CASE: Cell specifies key-value on deeper level.
        
        object_key   = location{1};
        object_value = location{2};
        
        i = find(and(strcmp(s_str_lists.keys, object_key), strcmp(s_str_lists.values, object_value)));
        if numel(i) ~= 1
            error('Did not find exactly one matching key-value pair for "%s"-"%s".', object_key, object_value)
        end
        % NOTE: RECURSIVE CALL
        s_str_lists.objects{i} = lib_shared_EJ.set_s_str_lists_value(policy, s_str_lists.objects{i}, location(3:end), value, object);
        
    else
        error('Illegal location. Does not consist of odd number of strings.')
    end
    
end
