%
% Initially created 2016-07-07 by Erik P G Johansson, IRF Uppsala, Sweden.
%
% Generic function for writing ODL (LBL/CAT) files using a "string-lists struct" on the same format
% as returned from read_ODL_from_struct. Does some basic "beautification" (indentation,
% added whitespace to make equal signs and value left-aligned).
%
% NOTE: Overwrites destination file if pre-existing.
% NOTE: Multiline values are not indented (except the key itself).
%
function EJ_write_ODL_from_struct(file_path, s_str_lists, INDENTATION_LENGTH)
    
    c.fid = fopen(file_path, 'w');
    c.INDENTATION_LENGTH = INDENTATION_LENGTH;
    
    write_key_values(c, s_str_lists, 0)
    fprintf(c.fid, 'END\r\n');
    
    fclose(c.fid);    
end


function write_key_values(c, s, indentation_level)

    % ARGUMENT CHECK. Implicitly checks that fields exist.
    if length(s.keys) ~= length(s.values) || length(s.keys) ~= length(s.objects)
        error('.keys, .values, and .objects do not have the same length.')
    end
    
    keys    = s.keys;
    values  = s.values;
    objects = s.objects;

    nonOBJECT_keys           = keys(cellfun(@isempty, objects));    % Create list of keys without OBJECT/subsections.
    max_nonOBJECT_key_length = max(cellfun(@length, nonOBJECT_keys));

    indentation_str = repmat(' ', 1, c.INDENTATION_LENGTH*indentation_level);

    for i = 1:length(keys)        
        
        if isempty(objects{i})
            % CASE: non-OBJECT key
            
            post_key_padding = repmat(' ', 1, max_nonOBJECT_key_length-length(keys{i}));    % Create string of whitespaces.
            fprintf(c.fid, sprintf('%s%s%s = %s\r\n',   indentation_str, keys{i}, post_key_padding, values{i}));
            
        else
            % CASE: OBJECT key.
            
            % Print OBJECT with different "post-key" whitespace padding.
            fprintf(c.fid, sprintf('%s%s = %s\r\n',   indentation_str, keys{i}, values{i}));
            
            write_key_values(c, objects{i}, indentation_level+1);             % RECURSIVE CALL
            fprintf(c.fid, sprintf('%sEND_OBJECT = %s\r\n',   indentation_str, values{i}));
        end
    end
end
