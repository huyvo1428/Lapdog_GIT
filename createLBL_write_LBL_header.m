%
% Writes the first list of variables (key-value pairs) to an LBL file, before the OBJECT TABLE etc.
%
% NOTE: Always interprets kvl.value{i} as (matlab) string, not number.
% NOTE: Always prints exact string, without adding quotes.
%
%
function createLBL_write_LBL_header(fid, kvl)   % kvl = key-value list
    % PROPOSAL: Set RECORD_BYTES (file size)
    % PROPOSAL: Set (overwrite) values for PRODUCT_TYPE, PROCESSING_LEVEL_ID and other values which are the same for all files.
    
    LBL_file_path = fopen(fid);
    %fprintf(1, 'Write LBL header %s\n', LBL_file_path);
    
    if length(unique(kvl.keys)) ~= length(kvl.keys)
        error('Found doubles among the keys/ODL attribute names.')
    end
    
    if ~isempty(kvl.keys)
        max_key_length = max(cellfun(@length, kvl.keys));
    end
    
    for j = 1:length(kvl.keys) % Print header of analysis file
        key   = kvl.keys{j};
        value = kvl.values{j};
        
        if ~ischar(value)
            error(sprintf('(key-) value is not a string:\n key = "%s", fopen(fid) = "%s"', key, fopen(fid)))
        end
        
        fprintf(fid, ['%-', num2str(max_key_length), 's = %s\n'], key, value);
    end
end
