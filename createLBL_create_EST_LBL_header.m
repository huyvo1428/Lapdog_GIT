%=========================================================================================
% Create LBL header for EST in the form of a key-value (kv) list.
% 
% Combines information from one or two LBL file headers.
% to produce information for new combined header (without writing to file).
% 
% ASSUMES: The two label files have identical keys on identical positions (line numbers).
%
% PROPOSAL: Move out ODL variables that are in common (key+value) for all LBL files.
% PROPOSAL: Move collision-handling code into separate general-purpose function(s).
%     NOTE: The code should preferably try to maintain the order of key-value pairs.
%=========================================================================================
function kv_new = createLBL_create_EST_LBL_header(an_tabindex_record, index, kv_set)
% PROPOSAL: Change to only accept a "an_tabindex_record" instead, i.e. effectively an_tabindex{i_ant, :}.
% PROPOSAL: Change to accept LBL_file_path instead of "index".

    %N_src_files = length(an_tabindex{i_ant, 3});
    N_src_files = length(an_tabindex_record{3});
    if ~ismember(N_src_files, [1,2])
        error('Wrong number of TAB file paths.');
    end

    kv_list = {};
    START_TIME_list = {};
    STOP_TIME_list = {};
    for i_index = 1:N_src_files
        file_path = index(an_tabindex_record{3}(i_index)).lblfile;    % Find CALIB LBL files.
        kv = createLBL_read_LBL_header(file_path);

        kv_list{end+1} = kv;            
        START_TIME_list{end+1} = createLBL_read_kv_value(kv, 'START_TIME');
        STOP_TIME_list{end+1}  = createLBL_read_kv_value(kv, 'STOP_TIME');
    end

    % Determine and set start time.
    [junk, i_sort] = sort(START_TIME_list);
    i_start = i_sort(1);
    kv_set = createLBL_add_copy_of_kv_pair(kv_list{i_start}, kv_set, 'START_TIME');
    kv_set = createLBL_add_copy_of_kv_pair(kv_list{i_start}, kv_set, 'SPACECRAFT_CLOCK_START_COUNT');

    % Determine and set stop time.
    [junk, i_sort] = sort(STOP_TIME_list);
    i_stop = i_sort(end);
    kv_set = createLBL_add_copy_of_kv_pair(kv_list{i_stop}, kv_set, 'STOP_TIME');
    kv_set = createLBL_add_copy_of_kv_pair(kv_list{i_stop}, kv_set, 'SPACECRAFT_CLOCK_STOP_COUNT');

    
    
    %===================
    % Handle collisions
    %===================
    kv1 = kv_list{1};
    if (N_src_files == 1)
        kv_new = kv1;
    else
        kv_new = [];
        kv_new.keys = {};
        kv_new.values = {};
        
        kv2 = kv_list{2};
        for i1 = 1:length(kv1.keys)             % For every key in kv1...

            if strcmp(kv1.keys{i1}, kv2.keys{i1})     % If key collision...

                key = kv1.keys{i1};
                kvset_has_key = ~isempty(find(strcmp(key, kv_set.keys)));
                if kvset_has_key                                    % If kv_set contains information on how to set value...
                    % IMPLEMENTATION NOTE: Can not set values here since this only covers the case of having two source LBL files.
                    kv_new.keys  {end+1, 1} = key;
                    kv_new.values{end+1, 1} = '<Temporary - This value should be overwritten automatically.>';

                elseif strcmp(kv1.values{i1}, kv2.values{i1})       % If key AND value collision... (No problem)
                    kv_new.keys  {end+1, 1} = kv1.keys  {i1};
                    kv_new.values{end+1, 1} = kv1.values{i1};

                else                                      % If has no information on how to resolve collision...
                    error_msg = sprintf('ERROR: Does not know what to do with LBL/ODL key collision for key="%s".\n', key);
                    error_msg = [error_msg, sprintf('with two different values: value="%s", value="%s\n".', kv1.values{i1}, kv2.values{i1})];
                    error_msg = [error_msg, sprintf('an_tabindex_record{1} = %s\n', an_tabindex_record{1})];
                    error(error_msg)
                end            

            else  % If not key collision....
                kv_new.keys  {end+1,1} = kv1.keys  {i1};
                kv_new.values{end+1,1} = kv1.values{i1};
                kv_new.keys  {end+1,1} = kv2.keys  {i1};
                kv_new.values{end+1,1} = kv2.values{i1};
            end
        end
    end

    kv_new = createLBL_set_values_for_selected_preexisting_keys(kv_new, kv_set);
end

