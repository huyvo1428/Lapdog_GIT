function createLBL_write_LBL_header(fid, kv)
    % PROPOSAL: Set RECORD_BYTES (file size)
    % PROPOSAL: Set (overwrite) values for PRODUCT_TYPE, PROCESSING_LEVEL_ID and other values which are the same for all files.
    
    LBL_file_path = fopen(fid);
    fprintf(1, 'Write LBL header to file: %s\n', LBL_file_path);
    for j = 1:length(kv.keys) % Print header of analysis file
        fprintf(fid, '%s = %s\n', kv.keys{j}, kv.values{j});
    end
end
