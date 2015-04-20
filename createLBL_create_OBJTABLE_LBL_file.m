% Create LBL file for TAB file.
% Only for LBL files based on one OBJECT = TABLE section plus headers.
%
% NOTE: NOT INTEGRATED INTO CODE YET / NOT USED YET.
%       Does not "fit in" yet as should rely on adding keys to kvl_header, but kvl_header
%       is often constructed by reading from LBL file, i.e. includes FILE_NAME
%       Best estimates uses a kvl_set list to handle collisions. ==> May require ignore list there.
%
function createLBL_create_OBJTABLE_LBL_file(TAB_file_path, kvl_header, OBJTABLE_data)
% PROPOSAL: Should set RECORD_BYTES if it really is the TAB file size.
% PROPOSAL: Should set FILE, ^TABLE, PRODUCT_ID
% PROPOSAL: Set or check RECORD_TYPE=FIXED_LENGTH.
% PROPOSAL: Should set PRODUCT_ID.
%    NOTE: Rosetta Archive Conventions specifies that it should be filename without extension.
%
% PROPOSAL: Create ignore list for deleting keys after reading LBL file header key-values?

% IMPLEMENTATION NOTE: Keeps createLBL_writeObjectTable and createLBL_write_LBL_header as separate functions to
%   1) keep code in smaller logical modules,
%   2) still be able to recycle createLBL_write_LBL_header for other kinds of LBL files.

    error('IMPLEMENTATION NOT FINISHED.')

    [file_path, file_basename, TAB_file_ext] = fileparts(TAB_file_path);
    TAB_filename = [file_basename, TAB_file_ext]
    LBL_filename = [file_basename, '.LBL']
    LBL_file_path = [file_path, filesep, LBL_filename]
    
    fileinfo = dir(TAB_file_path);

    kvl_set = [];   % NOTE: Can not initialize with "struct(...)". That gives an unintended result due to a special interpretation for arrays.
    kvl_set.keys = {};
    kvl_set.values = {};
    kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'RECORD_BYTES', sprintf('%i',   fileinfo.bytes));
    kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'FILE_NAME',    sprintf('"%s"', LBL_filename));
    kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, '^TABLE',       sprintf('"%s"', TAB_filename));
    kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'PRODUCT_ID',   sprintf('"%s"', file_basename));

    kvl_header = createLBL_KVPL_merge(kvl_header, kvl_set);
    

    fid = fopen(LBL_file_path, 'w');   % Open LBL file to create/write to.
    createLBL_writeObjectTable(fid, kvl_header);
    createLBL_write_LBL_header(fid, OBJTABLE_data);
    fprintf(fid,'END');    
    fclose(fid);
end
