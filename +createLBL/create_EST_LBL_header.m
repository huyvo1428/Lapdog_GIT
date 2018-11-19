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
% OverwriteKvpl       : Keys-values which overwrite keys-values found in the CALIB LBL files.
% deleteHeaderKeyList : Cell array of keys which are removed if found (must not be found).
% 
%
% ASSUMES: The two LBL files have identical header keys on identical positions (line numbers)!
%
%
% Initially created <=2017 by Erik P G Johansson, IRF Uppsala.
%==============================================================================================
function EstHeaderKvpl = create_EST_LBL_header(estTabPath, calib1LblPathList, probeNbrList, OverwriteKvpl, deleteHeaderKeyList)
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
%
% PROPOSAL: Move into createLBL.definitions.

    nSrcFiles = length(calib1LblPathList);
    if ~ismember(nSrcFiles, [1,2])
        error('Wrong number of TAB file paths.');
    end

    %===========================================
    % Read headers from source LBL files (AxS).
    %===========================================
    SrcKvplList = {};
    START_TIME_list = {};
    STOP_TIME_list  = {};
    for j = 1:nSrcFiles   % For every source file (A1S, A2S)...
        [KvplLblSrc, junk] = createLBL.read_LBL_file(calib1LblPathList{j}, deleteHeaderKeyList);
        
        SrcKvplList{end+1} = KvplLblSrc;            
        START_TIME_list{end+1} = KvplLblSrc.get_value('START_TIME');
        STOP_TIME_list{end+1}  = KvplLblSrc.get_value('STOP_TIME');
    end

    %=====================================================
    % Determine start & stop times from the source files.
    %=====================================================
    [junk, iSort] = sort(START_TIME_list);   iStart = iSort(1);
    [junk, iSort] = sort( STOP_TIME_list);   iStop  = iSort(end);
    OverwriteKvpl = OverwriteKvpl.append(SrcKvplList{iStart}.subset({                 'START_TIME' }));
    OverwriteKvpl = OverwriteKvpl.append(SrcKvplList{iStart}.subset({'SPACECRAFT_CLOCK_START_COUNT'}));
    OverwriteKvpl = OverwriteKvpl.append(SrcKvplList{iStop} .subset({                 'STOP_TIME'  }));
    OverwriteKvpl = OverwriteKvpl.append(SrcKvplList{iStop} .subset({'SPACECRAFT_CLOCK_STOP_COUNT' }));



    %================================================================================================================
    % Handle key collisions
    % ---------------------
    % IMPLEMENTATION NOTE: Must use overwrite_subset on Kvpl1 and Kvpl2 separately before combining them, to make sure
    % that key values are identical for the intersection before combining the two. (Although one could also remove
    % OverwriteKvpl, then join, then add OverwriteKvpl.)
    %================================================================================================================
    Kvpl1 = SrcKvplList{1};
    Kvpl1 = Kvpl1.overwrite_subset(OverwriteKvpl);
    if (nSrcFiles == 1)
        EstHeaderKvpl = Kvpl1;
    else
        % CASE: There are two source files.
        Kvpl2 = SrcKvplList{2};
        Kvpl2 = Kvpl2.overwrite_subset(OverwriteKvpl);
        
        % ASSERTION: Intersection of keys also have the same values.
        Int1Kvpl = Kvpl1.intersection(Kvpl2.keys);
        Int2Kvpl = Kvpl2.intersection(Kvpl1.keys);
        if ~Int1Kvpl.equals(Int2Kvpl)
            error('ERROR: Does not know what to do with LBL/ODL key collision for "%s"\n', estTabPath)
        end
        
        EstHeaderKvpl = Kvpl1.append(Kvpl2.diff(Kvpl1.keys));    % NOTE: Removes intersection of keys, assuming that it is identical anyway.
    end
