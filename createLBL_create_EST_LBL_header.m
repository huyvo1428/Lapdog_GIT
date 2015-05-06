%==============================================================================================
% Create LBL header for EST in the form of a key-value (kv) list.
% 
% Combines information from one or two LBL file headers.
% to produce information for new combined header (without writing to file).
% 
% ASSUMES: The two LBL files have identical header keys on identical positions (line numbers).
%==============================================================================================
function kvl_EST_header = createLBL_create_EST_LBL_header(an_tabindex_record, index, kvl_set, delete_header_key_list)
%
% PROPOSAL: Move out ODL variables that are in common (key+value) for all LBL files.
% PROPOSAL: Move collision-handling code into separate general-purpose function(s).
%     NOTE: The code should preferably try to maintain the order of key-value pairs
%           which should be easy now when has code to enforce order of keys with
%           "KVPL_order_by_key_list_INTERNAL" in "createLBL_write_LBL_header".
%
% PROPOSAL: Change to accept LBL_file_path instead of "index".
%   NOTE: Only uses "index( an_tabindex_record{3}(i_index) ).lblfile" and ".probe".
%
% PROPOSAL: Change to not accept "an_tabindex_record" but only the used information instead.
%   NOTE: Only uses an_tabindex_record{3}, an_tabindex_record{1} (for error message).
% 

    N_src_files = length(an_tabindex_record{3});
    if ~ismember(N_src_files, [1,2])
        error('Wrong number of TAB file paths.');
    end

    %===========================================
    % Read headers from source LBL files (AxS).
    %===========================================
    kvl_src_list = {};
    START_TIME_list = {};
    STOP_TIME_list  = {};
    for i_index = 1:N_src_files   % For every source file (A1S, A2S)...
        %CALIB_LBL_file_path = index(an_tabindex_record{3}(i_index)).lblfile;    % Find CALIB LBL files.
        %kvl_LBL_src = createLBL_read_LBL_header(CALIB_LBL_file_path);
        %kvl_LBL_src = createLBL_compatibility_substitute_LBL_keys(kvl_LBL_src, index(an_tabindex_record{3}(i_index)).probe);    % NOTE: Changes name of selected keys.
        %kvl_LBL_src = createLBL_KVPL_delete_keys(kvl_LBL_src, {'FILE_NAME', '^TABLE', 'PRODUCT_ID', 'RECORD_BYTES', 'FILE_RECORDS', 'RECORD_TYPE'}, 'may have keys');   % Remove keys which will be added later.
        [kvl_LBL_src, junk] = createLBL_read_LBL_file(index(an_tabindex_record{3}(i_index)).lblfile, delete_header_key_list, index(an_tabindex_record{3}(i_index)).probe);
        
        kvl_src_list{end+1} = kvl_LBL_src;            
        START_TIME_list{end+1} = createLBL_KVPL_read_value(kvl_LBL_src, 'START_TIME');
        STOP_TIME_list{end+1}  = createLBL_KVPL_read_value(kvl_LBL_src, 'STOP_TIME');
    end

    %=====================================================
    % Determine start & stop times from the source files.
    %=====================================================
    [junk, i_sort] = sort(START_TIME_list);   i_start = i_sort(1);
    [junk, i_sort] = sort(STOP_TIME_list);    i_stop  = i_sort(end);
    kvl_set = createLBL_KVPL_add_copy_of_kv_pair(kvl_src_list{i_start}, kvl_set, 'START_TIME');
    kvl_set = createLBL_KVPL_add_copy_of_kv_pair(kvl_src_list{i_start}, kvl_set, 'SPACECRAFT_CLOCK_START_COUNT');
    kvl_set = createLBL_KVPL_add_copy_of_kv_pair(kvl_src_list{i_stop},  kvl_set, 'STOP_TIME');
    kvl_set = createLBL_KVPL_add_copy_of_kv_pair(kvl_src_list{i_stop},  kvl_set, 'SPACECRAFT_CLOCK_STOP_COUNT');
    
    
    
    %=======================
    % Handle key collisions
    %=======================
    kv1 = kvl_src_list{1};
    if (N_src_files == 1)
        kvl_EST_header = kv1;
    else
        kvl_EST_header = [];
        kvl_EST_header.keys = {};
        kvl_EST_header.values = {};
        
        kv2 = kvl_src_list{2};
        for i1 = 1:length(kv1.keys)             % For every key in kv1...

            if strcmp(kv1.keys{i1}, kv2.keys{i1})     % If key collision...

                key = kv1.keys{i1};
                kvset_has_key = ~isempty(find(strcmp(key, kvl_set.keys)));
                if kvset_has_key                                    % If kvl_set contains information on how to set value... ==> Use kvl_set later...
                    % IMPLEMENTATION NOTE: Can not set values here since this only covers the case of having two source LBL files.
                    kvl_EST_header.keys  {end+1, 1} = key;
                    kvl_EST_header.values{end+1, 1} = '<Temporary - This value should be overwritten automatically.>';

                elseif strcmp(kv1.values{i1}, kv2.values{i1})       % If key AND value collision... ==> No problem, use value.
                    kvl_EST_header.keys  {end+1, 1} = kv1.keys  {i1};
                    kvl_EST_header.values{end+1, 1} = kv1.values{i1};

                else                                      % If has no information on how to resolve collision... ==> Problem, error.
                    error_msg = sprintf('ERROR: Does not know what to do with LBL/ODL key collision for key="%s".\n', key);
                    error_msg = [error_msg, sprintf('with two different values: value="%s", value="%s\n".', kv1.values{i1}, kv2.values{i1})];
                    error_msg = [error_msg, sprintf('an_tabindex_record{1} = %s\n', an_tabindex_record{1})];
                    error(error_msg)
                end

            else  % If not key collision....
                kvl_EST_header.keys  {end+1,1} = kv1.keys  {i1};
                kvl_EST_header.values{end+1,1} = kv1.values{i1};
                kvl_EST_header.keys  {end+1,1} = kv2.keys  {i1};
                kvl_EST_header.values{end+1,1} = kv2.values{i1};
            end
        end
    end

    kvl_EST_header = createLBL_KVPL_overwrite_values(kvl_EST_header, kvl_set);   % NOTE: Must do this for both N_src_files == 1, AND == 2.

end

