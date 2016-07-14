% Read ODL/LBL file "header", i.e. all the keywords from the beginning of
% the file up until the first OBJECT statement.
%
% kvl                    : Key-value (pair) list
% delete_header_key_list : Cell array of keys which are removed if found (must not be found).
% 
% NOTE: CALIB_LBL_str    keeps   quotes.
%       CALIB_LBL_struct removes quotes.
% NOTE: Can not handle empty lines.
%
function [kvl_header, CALIB_LBL_struct] = createLBL_read_LBL_file(file_path, delete_header_key_list, probe_nbr)
%
% PROPOSAL: Move keyword compatibility subsitution code (createLBL_compatibility_substitute_LBL_keys) into this function.
%    NOTE: createLBL_compatibility_substitute_LBL_keys is only called from here.
% PROPOSAL: Change name to something implying only reading CALIB LBL files?
%
% PROPOSAL: Remove all quotes from values.
%    CON: createLBL_write_LBL_header must determine which keys should have quotes. ==> Another long list which might not capture all keywords.

    [CALIB_LBL_str, CALIB_LBL_struct] = EJ_read_ODL_to_structs(file_path);   % Read CALIB LBL file.
    kvl_header = [];
    kvl_header.keys   = CALIB_LBL_str.keys  (1:end-1);    % NOTE: CALIB_LBL_str includes OBJECT = TABLE as last key-value pair.
    kvl_header.values = CALIB_LBL_str.values(1:end-1);
    
    %for i = 1:length(kvl_header.values)
    %    value = kvl_header.values{i};
    %    kvl_header.values{i} = value(value ~= '"');    % Remove all quotes.
    %end
    
    % kvl_header = createLBL_compatibility_substitute_LBL_keys(kvl_header, probe_nbr);
    kvl_header = createLBL_KVPL_delete_keys(kvl_header, delete_header_key_list, 'may have keys');
end
