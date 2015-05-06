% Read ODL/LBL file "header", i.e. all the keywords from the beginning of
% the file up until the first OBJECT statement.
%
% kvl = key-value (pair) list
% 
% NOTE: Can not handle empty lines.
%
function [kvl_header, CALIB_LBL_struct] = createLBL_read_LBL_file(file_path, delete_header_key_list, probe_nbr)

    [CALIB_LBL_str, CALIB_LBL_struct] = createLBL_read_ODL_to_structs(file_path);   % Read CALIB LBL file.
    kvl_header = [];
    kvl_header.keys   = CALIB_LBL_str.keys  (1:end-1);    % NOTE: CALIB_LBL_str includes OBJECT = TABLE as last key-value pair.
    kvl_header.values = CALIB_LBL_str.values(1:end-1);
    kvl_header = createLBL_compatibility_substitute_LBL_keys(kvl_header, probe_nbr);
    kvl_header = createLBL_KVPL_delete_keys(kvl_header, delete_header_key_list, 'may have keys');
end


% OLD IMPLEMENTATION, OBSOLETED 2015-05-05
%
% function kvl = createLBL_read_LBL_header(file_path)
%     [fid, errmess] = fopen(file_path, 'r');
%     if fid < 0
%         error(sprintf('Error, cannot open file %s', file_path))
%     end
%     %fprintf(1, 'Reading LBL file header: %s\n', fopen(fid))    % Log message
% 
%     % DEBUG/log message
%     % NOTE: Not ideal place to write log message but useful for debugging. Disable?
%     %fprintf(1, 'Read LBL header from file: %s\n', file_path);
%     
%     file_contents = textscan(fid,'%s %s','Delimiter','=');
%     fclose(fid);
%     
%     file_contents{1} = strtrim(file_contents{1});
%     file_contents{2} = strtrim(file_contents{2});
% 
%     i_OBJECT = find(strcmp(file_contents{1,1}(), 'OBJECT'), 1, 'first');
%     kvl.keys   = file_contents{1}(1:i_OBJECT-1, :);
%     kvl.values = file_contents{2}(1:i_OBJECT-1, :);
% end
