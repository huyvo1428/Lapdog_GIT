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
%
%
% Initially created <=2017 by Erik P G Johansson, IRF Uppsala.
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
% ~TODO: Test day for nSrcFiles == 2. Seems ~rare.

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
        START_TIME_list{end+1} = KvlLblSrc.get_value('START_TIME');
        STOP_TIME_list{end+1}  = KvlLblSrc.get_value('STOP_TIME');
    end

    %=====================================================
    % Determine start & stop times from the source files.
    %=====================================================
    [junk, iSort] = sort(START_TIME_list);   iStart = iSort(1);
    [junk, iSort] = sort( STOP_TIME_list);   iStop  = iSort(end);
    KvlOverwrite = KvlOverwrite.append(kvlSrcList{iStart}.subset({                 'START_TIME' }));
    KvlOverwrite = KvlOverwrite.append(kvlSrcList{iStart}.subset({'SPACECRAFT_CLOCK_START_COUNT'}));
    KvlOverwrite = KvlOverwrite.append(kvlSrcList{iStop} .subset({                 'STOP_TIME'  }));
    KvlOverwrite = KvlOverwrite.append(kvlSrcList{iStop} .subset({'SPACECRAFT_CLOCK_STOP_COUNT' }));



    %================================================================================================================
    % Handle key collisions
    % ---------------------
    % IMPLEMENTATION NOTE: Must use overwrite_subset on Kvl1 and Kvl2 separately before combining them, to make sure
    % that key values are identical for the intersection before combining the two. (Although one could also remove
    % KvlOverwrite, then join, then add KvlOverwrite.)
    %================================================================================================================
    Kvl1 = kvlSrcList{1};
    Kvl1 = Kvl1.overwrite_subset(KvlOverwrite);
    if (nSrcFiles == 1)
        KvlEstHeader = Kvl1;
    else
        % CASE: There are two source files.
        Kvl2 = kvlSrcList{2};
        Kvl2 = Kvl2.overwrite_subset(KvlOverwrite);
        
        Kvl1int = Kvl1.intersection(Kvl2.keys);
        Kvl2int = Kvl2.intersection(Kvl1.keys);
        % ASSERTION: Intersection of keys also have the same values.
        if ~Kvl1int.equals(Kvl2int)
            error('ERROR: Does not know what to do with LBL/ODL key collision for "%s"\n', estTabPath)
        end
        
        KvlEstHeader = Kvl1.append(Kvl2.diff(Kvl1.keys));    % NOTE: Removes intersection of keys, assuming that it is identical anyway.
    end
