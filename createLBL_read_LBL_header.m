% Read ODL/LBL file "header", i.e. all the variables from the beginning of the file up until
% the first OBJECT statement.
%
% kvl = key-value (pair) list
% 
% NOTE: Can not handle empty lines.
%
function kvl = createLBL_read_LBL_header(file_path)
    [fid, errmess] = fopen(file_path, 'r');
    if fid < 0
        error(sprintf('Error, cannot open file %s', file_path))
    end
    %fprintf(1, 'Reading LBL file header: %s\n', fopen(fid))    % Log message

    % DEBUG/log message
    % NOTE: Not ideal place to write log message but useful for debugging. Disable?
    %fprintf(1, 'Read LBL header from file: %s\n', file_path);
    
    file_contents = textscan(fid,'%s %s','Delimiter','=');
    fclose(fid);
    
    file_contents{1} = strtrim(file_contents{1});
    file_contents{2} = strtrim(file_contents{2});

    i_OBJECT = find(strcmp(file_contents{1,1}(), 'OBJECT'), 1, 'first');
    kvl.keys   = file_contents{1}(1:i_OBJECT-1, :);
    kvl.values = file_contents{2}(1:i_OBJECT-1, :);
end
