%==============================================================================================
% Create LBL header for EST in the form of a key-value (kv) list.
% 
% Combines information from ONE OR TWO LBL file headers.
% to produce information for ONE new combined header (without writing to file).
%
%
% ARGUMENTS
% =========
% estTabPath          : Path to EST TAB file.
% calib1LblPathList   : Cell array of paths to the (one or two) CALIB files containing PDS keywords for the AxS files.
% probeNbrList        : Array of probe numbers for the corresponding (one or two) CALIB/AxS files.
% KvlOverwrite        : Keys-values which overwrite keys-values found in the CALIB LBL files.
% deleteHeaderKeyList : Cell array of keys which are removed if found (must not be found).
% 
%
% ASSUMES: The two LBL files have identical header keys on identical positions (line numbers)!
%==============================================================================================
function KvlEstHeader = create_EST_LBL_header(estTabPath, calib1LblPathList, probeNbrList, KvlOverwrite, deleteHeaderKeyList)
%
% PROPOSAL: Move out ODL variables that are in common (key+value) for all LBL files.
% PROPOSAL: Move collision-handling code into separate general-purpose function(s).
%     NOTE: The code should preferably try to maintain the order of key-value pairs
%           which should be easy now when has code to enforce order of keys with
%           "KVPL_order_by_key_list_INTERNAL" in "write_LBL_header".
%
% PROPOSAL: Accept the LBL files for the AxS files instead of CALIB files. Should give the same result already.
%    CON: Calling code has no way of finding the source AxS files from tabindex/an_tab_index(?).
%    

    nSrcFiles = length(calib1LblPathList);
    if ~ismember(nSrcFiles, [1,2])
        error('Wrong number of TAB file paths.');
    end

    %===========================================
    % Read headers from source LBL files (AxS).
    %===========================================
    kvlSrcList = {};
    START_TIME_list = {};
    STOP_TIME_list  = {};
    for j = 1:nSrcFiles   % For every source file (A1S, A2S)...
        [KvlLblSrc, junk] = createLBL.read_LBL_file(calib1LblPathList{j}, deleteHeaderKeyList);
        
        kvlSrcList{end+1} = KvlLblSrc;            
        START_TIME_list{end+1} = lib_shared_EJ.KVPL.read_value(KvlLblSrc, 'START_TIME');
        STOP_TIME_list{end+1}  = lib_shared_EJ.KVPL.read_value(KvlLblSrc, 'STOP_TIME');
    end

    %=====================================================
    % Determine start & stop times from the source files.
    %=====================================================
    [junk, iSort] = sort(START_TIME_list);   iStart = iSort(1);
    [junk, iSort] = sort( STOP_TIME_list);   iStop  = iSort(end);
    KvlOverwrite = lib_shared_EJ.KVPL.add_copy_of_kv_pair( kvlSrcList{iStart}, KvlOverwrite, 'START_TIME');
    KvlOverwrite = lib_shared_EJ.KVPL.add_copy_of_kv_pair( kvlSrcList{iStart}, KvlOverwrite, 'SPACECRAFT_CLOCK_START_COUNT');
    KvlOverwrite = lib_shared_EJ.KVPL.add_copy_of_kv_pair( kvlSrcList{iStop},  KvlOverwrite, 'STOP_TIME');
    KvlOverwrite = lib_shared_EJ.KVPL.add_copy_of_kv_pair( kvlSrcList{iStop},  KvlOverwrite, 'SPACECRAFT_CLOCK_STOP_COUNT');



    %=======================
    % Handle key collisions
    % ---------------------
    % ASSUMES: The two LBL files have identical header keys on identical positions (line numbers).
    %=======================
    Kvl1 = kvlSrcList{1};
    if (nSrcFiles == 1)
        KvlEstHeader = Kvl1;
    else
        KvlEstHeader = [];
        KvlEstHeader.keys   = {};
        KvlEstHeader.values = {};
        
        % DEBUG
        %iPerm = randperm(length(Kvl1.keys));
        %Kvl1.keys   = Kvl1.keys(iPerm);
        %Kvl1.values = Kvl1.values(iPerm);
        
        Kvl2 = kvlSrcList{2};
        for i1 = 1:length(Kvl1.keys)             % For every key in Kvl1...

            if strcmp(Kvl1.keys{i1}, Kvl2.keys{i1})    
                % CASE: Key collision

                key = Kvl1.keys{i1};
                KvlOverwriteHasKey = ~isempty(find(strcmp(key, KvlOverwrite.keys)));
                if KvlOverwriteHasKey                                    
                    % CASE: KvlOverwrite contains information on how to set value... ==> Use KvlOverwrite later...                    
                    % IMPLEMENTATION NOTE: Can not set values here since this only covers the case of having two source LBL files.
                    KvlEstHeader.keys  {end+1, 1} = key;
                    KvlEstHeader.values{end+1, 1} = '<TEMPORARY - This value should be overwritten automatically.>';

                elseif strcmp(Kvl1.values{i1}, Kvl2.values{i1})
                    % CASE: Key collision AND value collision ==> No problem, use value.
                    KvlEstHeader.keys  {end+1, 1} = Kvl1.keys  {i1};
                    KvlEstHeader.values{end+1, 1} = Kvl1.values{i1};

                else
                    % CASE: Has no information on how to resolve collision ==> Problem, error
                    errorMsg = sprintf('ERROR: Does not know what to do with LBL/ODL key collision for key="%s".\n', key);
                    errorMsg = [errorMsg, sprintf('with two different values: value="%s", value="%s\n".', Kvl1.values{i1}, Kvl2.values{i1})];
                    errorMsg = [errorMsg, sprintf('estTabPath = %s\n', estTabPath)];
                    error(errorMsg)
                end

            else
                % CASE: Not key collision
                KvlEstHeader.keys  {end+1,1} = Kvl1.keys  {i1};
                KvlEstHeader.values{end+1,1} = Kvl1.values{i1};
                KvlEstHeader.keys  {end+1,1} = Kvl2.keys  {i1};
                KvlEstHeader.values{end+1,1} = Kvl2.values{i1};
            end
        end
    end

    KvlEstHeader = lib_shared_EJ.KVPL.overwrite_values(KvlEstHeader, KvlOverwrite, 'require preexisting keys');   % NOTE: Must do this for both nSrcFiles == 1, AND == 2.

end

