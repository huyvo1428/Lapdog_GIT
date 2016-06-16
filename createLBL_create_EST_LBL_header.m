%==============================================================================================
% Create LBL header for EST in the form of a key-value (kv) list.
% 
% Combines information from ONE OR TWO LBL file headers.
% to produce information for new combined header (without writing to file).
%
% EST_TAB_path    : Path to EST TAB file.
% CALIB_LBL_paths : Cell array of paths to the (one or two) CALIB files containing PDS keywords for the AxS files.
% i_probes        : Array of probe numbers for the corresponding (one or two) CALIB/AxS files.
% kvl_set         : Keys-values which overwrite keys-values found in the CALIB LBL files.
% delete_header_key_list : Cell array of keys which are removed if found (must not be found).
% 
% ASSUMES: The two LBL files have identical header keys on identical positions (line numbers)!
%==============================================================================================
function kvl_EST_header = createLBL_create_EST_LBL_header(EST_TAB_path, CALIB_LBL_paths, i_probes, kvl_set, delete_header_key_list)
%
% PROPOSAL: Move out ODL variables that are in common (key+value) for all LBL files.
% PROPOSAL: Move collision-handling code into separate general-purpose function(s).
%     NOTE: The code should preferably try to maintain the order of key-value pairs
%           which should be easy now when has code to enforce order of keys with
%           "KVPL_order_by_key_list_INTERNAL" in "createLBL_write_LBL_header".
%
% PROPOSAL: Accept the LBL files for the AxS files instead of CALIB files. Should give the same result already.
%    CON: Calling code has no way of finding the source AxS files from tabindex/an_tab_index(?).
%    

    N_src_files = length(CALIB_LBL_paths);
    if ~ismember(N_src_files, [1,2])
        error('Wrong number of TAB file paths.');
    end

    %===========================================
    % Read headers from source LBL files (AxS).
    %===========================================
    kvl_src_list = {};
    START_TIME_list = {};
    STOP_TIME_list  = {};
    for j = 1:N_src_files   % For every source file (A1S, A2S)...
        [kvl_LBL_src, junk] = createLBL_read_LBL_file(...
            CALIB_LBL_paths{j}, delete_header_key_list, ...
            i_probes(j));
        
        kvl_src_list{end+1} = kvl_LBL_src;            
        START_TIME_list{end+1} = createLBL_KVPL_read_value(kvl_LBL_src, 'START_TIME');
        STOP_TIME_list{end+1}  = createLBL_KVPL_read_value(kvl_LBL_src, 'STOP_TIME');
    end

    %=====================================================
    % Determine start & stop times from the source files.
    %=====================================================
    [junk, i_sort] = sort(START_TIME_list);   i_start = i_sort(1);
    [junk, i_sort] = sort(STOP_TIME_list);    i_stop  = i_sort(end);
    kvl_set = createLBL_KVPL_add_copy_of_kv_pair( kvl_src_list{i_start}, kvl_set, 'START_TIME');
    kvl_set = createLBL_KVPL_add_copy_of_kv_pair( kvl_src_list{i_start}, kvl_set, 'SPACECRAFT_CLOCK_START_COUNT');
    kvl_set = createLBL_KVPL_add_copy_of_kv_pair( kvl_src_list{i_stop},  kvl_set, 'STOP_TIME');
    kvl_set = createLBL_KVPL_add_copy_of_kv_pair( kvl_src_list{i_stop},  kvl_set, 'SPACECRAFT_CLOCK_STOP_COUNT');
    
    
    
    %=======================
    % Handle key collisions
    % ---------------------
    % ASSUMES: The two LBL files have identical header keys on identical positions (line numbers).
    %=======================
    kv1 = kvl_src_list{1};
    if (N_src_files == 1)
        kvl_EST_header = kv1;
    else
        kvl_EST_header = [];
        kvl_EST_header.keys = {};
        kvl_EST_header.values = {};
        
        % DEBUG
        %i_perm = randperm(length(kv1.keys));
        %kv1.keys   = kv1.keys(i_perm);
        %kv1.values = kv1.values(i_perm);
        
        kv2 = kvl_src_list{2};
        for i1 = 1:length(kv1.keys)             % For every key in kv1...

            if strcmp(kv1.keys{i1}, kv2.keys{i1})     % If key collision...

                key = kv1.keys{i1};
                kvset_has_key = ~isempty(find(strcmp(key, kvl_set.keys)));
                if kvset_has_key                                    % If kvl_set contains information on how to set value... ==> Use kvl_set later...
                    % IMPLEMENTATION NOTE: Can not set values here since this only covers the case of having two source LBL files.
                    kvl_EST_header.keys  {end+1, 1} = key;
                    kvl_EST_header.values{end+1, 1} = '<TEMPORARY - This value should be overwritten automatically.>';

                elseif strcmp(kv1.values{i1}, kv2.values{i1})       % If key AND value collision... ==> No problem, use value.
                    kvl_EST_header.keys  {end+1, 1} = kv1.keys  {i1};
                    kvl_EST_header.values{end+1, 1} = kv1.values{i1};

                else                                      % If has no information on how to resolve collision... ==> Problem, error.
                    error_msg = sprintf('ERROR: Does not know what to do with LBL/ODL key collision for key="%s".\n', key);
                    error_msg = [error_msg, sprintf('with two different values: value="%s", value="%s\n".', kv1.values{i1}, kv2.values{i1})];
                    error_msg = [error_msg, sprintf('EST_TAB_path = %s\n', EST_TAB_path)];
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

