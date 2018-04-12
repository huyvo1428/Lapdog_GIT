%
% Create LBL file for TAB file.
%
% ("OBJTABLE" refers to "OBJECT = TABLE" in ODL files.)
% Only for LBL files based on one OBJECT = TABLE section (plus header keywords).
%
%
% ARGUMENTS
% =========
% tabFilePath                           : Path to TAB file.
% LblData                               : Struct with the following fields.
%       .nTabFileRows
%       .KvlHeader                      : 
%       .ConsistencyCheck
%           .nTabBytesPerRow            : Value from when writing TAB file. For double-checking.
%           .nTabColumns                : Value from when writing TAB file. For double-checking.
%       .OBJTABLE                       : (OBJTABLE = "OBJECT = TABLE" segment)
%           .DESCRIPTION                : Description for entire table (PDS keyword).
%           .OBJCOL_list{i}             : Struct containing fields corresponding to various column PDS keywords.
%                                         (OBJCOL = "OBJECT = COLUMN" segment)
%                                         NOTE: The order of the fields does not matter. The implementation specifies
%                                               the order of keywords (within an OBJECT=COLUMN segment) in the label file.
%                                         NOTE: ".FORMAT" explicitly forbidden.
%               .NAME
%               .DATA_TYPE
%               .UNIT                   : Replaced by standardized default value if empty. Automatically quoted.
%                                         (Optional by PDS, required here)
%               .DESCRIPTION            : Replaced by standardized default value if empty. Must not contains quotes.
%                                         (Automatically quoted.)
%               .MISSING_CONSTANT       : Optional
%               Either (1)
%           	  .BYTES
%               or (2)
%                 .ITEMS
%                 .ITEM_BYTES
%
%
% tabLblInconsistencyPolicy : 'warning', 'error', or 'nothing'.
%                             Determines how to react in the event of inconsistencies.
%                             NOTE: Function may abort in case of 'warning'/'nothing' if it can not recover.
%
%
% NOTE: LblData.ConsistencyCheck.* are not actually needed to complete the function's tasks. They are there
% as consistency checks so that the caller can submit those values when they came from code creating
% the TAB file, e.g. fprintf and when setting tabindex{:,6} (number of columns). The code will then
% produce error/warning if they differ from what the other arguments suggest.
%
% NOTE: The caller is NOT supposed to surround key value strings with quotes, or units with </>.
% The implementation should add that when appropriate.
% NOTE: The implementation will add certain keywords to LblData.KvlHeader, and derive the values, and assume that caller has not set them. Error otherwise.
%
% NOTE: Previous implementations have added a DELIMITER=", " field (presumably not PDS compliant) in
% agreement with Imperial College/Tony Allen to somehow help them process the files
% It appears that at least part of the reason was to make it possible to parse the files before
% we used ITEM_OFFSET+ITEM_BYTES correctly. DELIMITER IS NO LONGER NEEDED AND HAS BEEN PHASED OUT!
% (E-mail Tony Allen->Erik Johansson 2015-07-03 and that thread).
%
% NOTE: Not full general-purpose function for table files, since
%       (1) Sorts initial top-level PDS keywords according to hard-coded sorting, adds quotes (to some at least) for hard-coded keywords.
%       (2) Uses OBJTABLE_DELIMITER string.
%       (3) Uses hardcoded indentation length
%       (4) Does not permit FORMAT field, and there are probably other unsupported PDS keywords too.
%
function create_OBJTABLE_LBL_file(tabFilePath, LblData, tabLblInconsistencyPolicy)
    %
    % NOTE: CONCEIVABLE LBL FILE SPECIAL CASES that may have different requirements:
    %    Data measurement files (DATA/)
    %    Block lists   (Does require SPACECRAFT_CLOCK_START_COUNT etc.)
    %    Geometry files
    %    INDEX.LBL   => Does not require SPACECRAFT_CLOCK_START_COUNT etc.
    %
    % PROPOSAL: Only set/require keys that are common for all OBJECT=TABLE files (ODL standard, not PDS standard).
    %     PROPOSAL: Different requirements for different LBL files can be implemented in the form of wrapping functions.
    %         NOTE: Seems the only header fields set are:
    %             Keep
    %                 RECORD_TYPE  = FIXED_LENGTH
    %                 RECORD_BYTES = 153
    %                 FILE_RECORDS = 2700
    %             Move to context-dependent wrapping function.
    %                 FILE_NAME    = "2014-DEC-31orb.LBL"
    %                 ^TABLE       = "2014-DEC-31orb.TAB"
    %                 PRODUCT_ID   = "2014-DEC-31orb"
    %         CON: Works fine as it is.
    %
    % PROPOSAL: Abolish nTabBytesPerRow.
    %   PRO: Same check performed via check against actual file size.
    % PROPOSAL: Read one TAB file row and count the number of strings ", ", infer number of columns, and use for
    %   consistency check.
    %   PRO: Can basically abolish ConsistencyCheck.nTabColumns.
    %
    % TODO-DECISION: How handle UNIT (optional according to PDS)
    %   PROPOSAL: (1) Require caller to set .UNIT and have 'N/A' (or []) represent absence of unit.
    %       PRO: Forces caller to set UNIT.
    %       CON: Longer calls.
    %   PROPOSAL: (2) Optional .UNIT for caller.
    %       CON: Absence of UNIT can otherwise be interpreted as (1) forgetting to set it, or (2) absence of unit.
    %       PRO: Shorter calls.
    %   PROPOSAL: Only include UNIT (in LBL) if caller sets .UNIT to value other than 'N/A'.
    %
    % PROPOSAL: PERMITTED_OBJTABLE_FIELD_NAMES should be exact required set (+assertion).
    


    
    %===========
    % Constants
    %===========
    BYTES_BETWEEN_COLUMNS = length(', ');      % ASSUMES absence of quotes in string columns.
    BYTES_PER_LINEBREAK   = 2;                 % Carriage return + line feed.
    
    % NOTE: Exclude COLUMNS, ROW_BYTES, ROWS.
    PERMITTED_OBJTABLE_FIELD_NAMES = {'DESCRIPTION', 'OBJCOL_list'};
    % NOTE: Exclude START_BYTE, ITEM_OFFSET which are derived.
    % NOTE: Includes both required and optional fields.
    PERMITTED_OBJCOL_FIELD_NAMES   = {'NAME', 'BYTES', 'DATA_TYPE', 'UNIT', 'ITEMS', 'ITEM_BYTES', 'DESCRIPTION', 'MISSING_CONSTANT'};
    INDENTATION_LENGTH             = 4;
    %CONTENT_MAX_ROW_LENGTH         = 70;    % Excludes line break characters.
    CONTENT_MAX_ROW_LENGTH         = 1000;    % Excludes line break characters.
    
    % "Planetary Data Systems Standards Reference", Version 3.6, p12-11, section 12.3.4.
    % Applies to what PDS defines as identifiers, i.e. "values" without quotes.
    PDS_IDENTIFIER_PERMITTED_CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789';
    
    
    
    %disp(['Create LBL table for: ', tabFilePath]);     % DEBUG / log message.
    
    OBJTABLE_data = LblData.OBJTABLE;
    
    % --------------------------------------------------------------
    % ASSERTION: Caller only uses permissible field names.
    % Useful when changing field names.
    % --------------------------------------------------------------
    if any(~ismember(fieldnames(OBJTABLE_data), PERMITTED_OBJTABLE_FIELD_NAMES))
        error('ERROR: Found illegal field name(s) in parameter "OBJTABLE_data".')
    end
    
    %-----------------------------------------------------------------------------------
    % ASSERTION: Misc. argument check
    % -------------------------------
    % When a caller takes values from tabindex, an_tabindex etc, and they are sometimes
    % mistakenly set to []. Therefore this check is useful. A mistake might
    % otherwise be discovered first when examining LBL files.
    %-----------------------------------------------------------------------------------
    if isempty(LblData.ConsistencyCheck.nTabColumns) || isempty(LblData.ConsistencyCheck.nTabBytesPerRow) || isempty(LblData.nTabFileRows)
        error('ERROR: Trying to use empty value when disallowed.')
    end
    
    % ASSERTION: TAB file exists
    if ~(exist(tabFilePath, 'file') && ~exist(tabFilePath, 'dir'))
        % CASE: There is no such non-directory TAB file.
        error('ERROR: Can not find TAB file "%s" (needed for consistency check).', tabFilePath)
    end
    
    
    %################################################################################################
    
    % Extract useful information from TAB file path.
    [filePath, fileBasename, tabFileExt] = fileparts(tabFilePath);
    tabFilename = [fileBasename, tabFileExt];
    lblFilename = [fileBasename, '.LBL'];
    lblFilePath = fullfile(filePath, lblFilename);
    
    %################################################################################################
    
    %--------------------------------------------------------------------------------------------------
    % Iterate over list of ODL "OBJECT=COLUMN" segments
    % ___IN_PREPARATION_FOR___ writing to file
    % -------------------------------------------------------------------------------
    % Calculate "COLUMNS" (taking ITEMS into account) rather than take from argument.
    % Calculate "ROW_BYTES" rather than take from argument.
    % NOTE: ROW_BYTES is only correct if fprintf prints correctly when creating the TAB file.
    %--------------------------------------------------------------------------------------------------
    OBJTABLE_data.ROW_BYTES = 0;   % NOTE: Adds new field to structure.
    OBJTABLE_data.COLUMNS   = 0;   % NOTE: Adds new field to structure.
    OBJCOL_namesList = {};
    for i = 1:length(OBJTABLE_data.OBJCOL_list)
        cd = OBJTABLE_data.OBJCOL_list{i};       % Temporarily shorten variable name: cd = column data
        
        [cd, nSubcolumns] = complement_column_data(cd, ...
            PERMITTED_OBJCOL_FIELD_NAMES, BYTES_BETWEEN_COLUMNS, PDS_IDENTIFIER_PERMITTED_CHARS, ...
            lblFilePath, tabLblInconsistencyPolicy);
        
        % ASSERTION
        for fnCell = fieldnames(cd)'
            fn = fnCell{1};
            if ischar(cd.(fn)) && ~isempty(strfind(cd.(fn), '"'))
                error('Keyword ("%s") value contains quotes.', fn)
            end
        end
        
        OBJCOL_namesList{end+1} = cd.NAME;
        OBJTABLE_data.COLUMNS   = OBJTABLE_data.COLUMNS + nSubcolumns;
        OBJTABLE_data.ROW_BYTES = OBJTABLE_data.ROW_BYTES + cd.BYTES + BYTES_BETWEEN_COLUMNS;     % Multiple subcolumns (ITEMS) have already taken into account.
        
        OBJTABLE_data.OBJCOL_list{i} = cd;      % Return updated info to original data structure.
        clear cd
    end
    OBJTABLE_data.ROW_BYTES = OBJTABLE_data.ROW_BYTES - BYTES_BETWEEN_COLUMNS + BYTES_PER_LINEBREAK;
    
    %################################################################################################
    
    % ---------------------------------------------------------
    % ASSERTION: Check for doubles among the ODL column names.
    % Useful for AxS.LBL files.
    % ---------------------------------------------------------
    if length(unique(OBJCOL_namesList)) ~= length(OBJCOL_namesList)
        error('Found doubles among the ODL column names.')
    end
    
    % -------------------------------------------------------------------------
    % ASSERTIONS: Consistency checks on (1) nbr of columns, (2) bytes per row.
    % -------------------------------------------------------------------------
    if (OBJTABLE_data.COLUMNS ~= LblData.ConsistencyCheck.nTabColumns)
        msg =       sprintf('lblFilePath = %s\n', lblFilePath);
        msg = [msg, sprintf('OBJTABLE_data.COLUMNS (derived)      = %i\n', OBJTABLE_data.COLUMNS)];
        msg = [msg, sprintf('LblData.ConsistencyCheck.nTabColumns = %i\n', LblData.ConsistencyCheck.nTabColumns)];
        msg = [msg,         'OBJTABLE_data.COLUMNS deviates from the consistency check value.'];
        warning_error___LOCAL(msg, tabLblInconsistencyPolicy)
    end
    if OBJTABLE_data.ROW_BYTES ~= LblData.ConsistencyCheck.nTabBytesPerRow
        msg =       sprintf('lblFilePath = %s\n', lblFilePath);
        msg = [msg, sprintf('OBJTABLE_data.ROW_BYTES (derived)        = %i\n', OBJTABLE_data.ROW_BYTES)];
        msg = [msg, sprintf('LblData.ConsistencyCheck.nTabBytesPerRow = %i\n', LblData.ConsistencyCheck.nTabBytesPerRow)];
        msg = [msg,         'OBJTABLE_data.ROW_BYTES deviates from the consistency check value.'];
        
        warning_error___LOCAL(msg, tabLblInconsistencyPolicy)
    end
    
    % ASSERTION: TAB file size is consistent with (indirectly) ROWS*ROW_BYTES.
    temp = dir(tabFilePath); tabFileSize = temp.bytes;
    if tabFileSize ~= (OBJTABLE_data.ROW_BYTES * LblData.nTabFileRows)
        msg = sprintf(['TAB file size is not consistent with LBL file, "%s":\n', ...
            '    tabFileSize             = %g\n', ...
            '    OBJTABLE_data.ROW_BYTES = %g\n', ...
            '    LblData.nTabFileRows    = %g'], ...
            tabFilePath, tabFileSize, OBJTABLE_data.ROW_BYTES, LblData.nTabFileRows);
        warning_error___LOCAL(msg, tabLblInconsistencyPolicy)
    end
    
    % ASSERTION: No quotes in OBJECT=TABLE DESCRIPTION keyword.
    assert_nonempty_unquoted(OBJTABLE_data.DESCRIPTION)

    %################################################################################################

    %===================================================================
    % Add keywords to the LBL "header" (before first OBJECT statement).
    %===================================================================
    KvlHeaderAdd = [];   % NOTE: Can not initialize with "struct(...)". That gives an unintended result due to a special interpretation for arrays.
    KvlHeaderAdd.keys   = {};
    KvlHeaderAdd.values = {};
    KvlHeaderAdd = lib_shared_EJ.KVPL.add_kv_pair(KvlHeaderAdd, 'RECORD_TYPE',  'FIXED_LENGTH');   % NOTE: Influences whether one must use RECORD_BYTES, FILE_RECORDS, LABEL_RECORDS.
    KvlHeaderAdd = lib_shared_EJ.KVPL.add_kv_pair(KvlHeaderAdd, 'RECORD_BYTES', sprintf('%i',   OBJTABLE_data.ROW_BYTES));
    KvlHeaderAdd = lib_shared_EJ.KVPL.add_kv_pair(KvlHeaderAdd, 'FILE_NAME',    sprintf('"%s"', lblFilename));    % Should be qouted.
    KvlHeaderAdd = lib_shared_EJ.KVPL.add_kv_pair(KvlHeaderAdd, '^TABLE',       sprintf('"%s"', tabFilename));    % Should be qouted.
    KvlHeaderAdd = lib_shared_EJ.KVPL.add_kv_pair(KvlHeaderAdd, 'PRODUCT_ID',   sprintf('"%s"', fileBasename));   % Should be qouted.
    KvlHeaderAdd = lib_shared_EJ.KVPL.add_kv_pair(KvlHeaderAdd, 'FILE_RECORDS', sprintf('%i',   LblData.nTabFileRows));
    
    LblData.KvlHeader = lib_shared_EJ.KVPL.merge(LblData.KvlHeader, KvlHeaderAdd);
    
    %################################################################################################
    
    % Log message
    %fprintf(1, 'Writing LBL file: "%s"\n', lblFilePath);
    
    %=========================
    % Write LBL file "header"
    %=========================
    ssl = create_SSL_header(LblData.KvlHeader);
    
    
    
    ssl = add_SSL_OBJECT(ssl, 'TABLE', create_OBJ_TABLE_content(OBJTABLE_data, LblData.nTabFileRows, BYTES_BETWEEN_COLUMNS));
    
    lib_shared_EJ.write_ODL_from_struct(lblFilePath, ssl, {}, INDENTATION_LENGTH, CONTENT_MAX_ROW_LENGTH);    % endRowsList = {};
end



% NOTE: Function name somewhat misleading since it contains a lot of useful assertions that have nothing to do with
% complementing the columnData struct.
function [columnData, nSubcolumns] = complement_column_data(columnData, ...
        PERMITTED_OBJCOL_FIELD_NAMES, BYTES_BETWEEN_COLUMNS, PDS_IDENTIFIER_PERMITTED_CHARS, ...
        lblFilePath, tabLblInconsistencyPolicy)

    cd = columnData;

    %---------------------------------------------------------------
    % ASSERTION: Only using permitted fields
    % --------------------------------------
    % Useful for not loosing information in optional arguments/field
    % names by misspelling, or misspelling when overwriting values,
    % or adding fields that are never used by the function.
    %---------------------------------------------------------------
    if any(~ismember(fieldnames(cd), PERMITTED_OBJCOL_FIELD_NAMES))
        error('ERROR: Found illegal COLUMN OBJECT field name(s).')
    end

    if isfield(cd, 'BYTES') && ~isfield(cd, 'ITEMS') && ~isfield(cd, 'ITEM_BYTES')
        % CASE: Has           BYTES
        %       Does not have ITEMS, ITEM_BYTES
        nSubcolumns = 1;
    elseif ~isfield(cd, 'BYTES') && isfield(cd, 'ITEMS') && isfield(cd, 'ITEM_BYTES')
        % CASE: Does not have BYTES
        %       Has           ITEMS, ITEM_BYTES
        nSubcolumns    = cd.ITEMS;
        cd.ITEM_OFFSET = cd.ITEM_BYTES + BYTES_BETWEEN_COLUMNS;
        cd.BYTES       = nSubcolumns * cd.ITEM_BYTES + (nSubcolumns-1) * BYTES_BETWEEN_COLUMNS;
    else
        warning_error___LOCAL(sprintf('Found disallowed combination of BYTES/ITEMS/ITEM_BYTES. NAME="%s". ABORTING creation of LBL file', cd.NAME), tabLblInconsistencyPolicy)
        return   % NOTE: ABORTING & EXITING to avoid causing further errors.
    end

    %------------
    % Check UNIT
    %------------
    if isempty(cd.UNIT)
        cd.UNIT = 'N/A';     % NOTE: Should add quotes later.
    end    
    % ASSERTIONS
    % Check for presence of "raised minus" in UNIT.
    % This is a common typo when writing cm^-3 which then becomes cm⁻3.
    if any(strfind(cd.UNIT, '⁻'))
        warning_error___LOCAL(sprintf('Found "raised minus" in UNIT. This is assumed to be a typo. NAME="%s"; UNIT="%s"', cd.NAME, cd.UNIT), tabLblInconsistencyPolicy)
    end        
    assert_nonempty_unquoted(cd.UNIT)
    
    %------------
    % Check NAME
    %------------
    % ASSERTION: Not empty.
    if isempty(cd.NAME)
        error('ERROR: Trying to use empty value for NAME.')
    end
    % ASSERTION: Only uses permitted characters.
    usedDisallowedChars = setdiff(cd.NAME, PDS_IDENTIFIER_PERMITTED_CHARS);
    if ~isempty(usedDisallowedChars)
        % NOTE 2016-07-22: The NAME value that triggers this error may come from a CALIB LBL file produced by pds, NAME = P1-P2_CURRENT/VOLTAGE.
        % pds should no longer produce this kind of LBL files since they violate the PDS standard but they may still occur in old data sets.
        % Therefore, there is also value in printing the file name since the user can then (maybe) determine if that is true.
        warning_error___LOCAL(sprintf('Found disallowed character(s) "%s" in NAME. NAME="%s". (Replacing dash with underscore.)\n   File: %s', ...
            usedDisallowedChars, cd.NAME, lblFilePath), tabLblInconsistencyPolicy)
        
        cd.NAME = strrep(cd.NAME, '-', '_');     % TEMPORARY.
    end
    
    %-------------------
    % Check DESCRIPTION
    %-------------------
    if isempty(cd.DESCRIPTION)
        cd.DESCRIPTION = 'N/A';   % NOTE: Quotes are added later.
    end
    % ASSERTION: Does not contain quotes.    
    assert_nonempty_unquoted(cd.DESCRIPTION)
    
    columnData = cd;
end



% Create SSL for the content of the OBJECT=TABLE segment.
function s = create_OBJ_TABLE_content(OBJTABLE_data, nTabFileRows, bytesBetweenColumns)
    s = struct('keys', {{}}, 'values', {{}}, 'objects', {{}}) ;
    
    s = add_SSL(s, 'INTERCHANGE_FORMAT','%s',   'ASCII');
    s = add_SSL(s, 'ROWS',              '%d',   nTabFileRows);
    s = add_SSL(s, 'COLUMNS',           '%d',   OBJTABLE_data.COLUMNS);
    s = add_SSL(s, 'ROW_BYTES',         '%d',   OBJTABLE_data.ROW_BYTES);
    s = add_SSL(s, 'DESCRIPTION',       '"%s"', OBJTABLE_data.DESCRIPTION);
    
    PDS_START_BYTE = 1;    % Used for deriving START_BYTE. Starts with one, not zero.
    for i = 1:length(OBJTABLE_data.OBJCOL_list)           % Iterate over list of ODL OBJECT COLUMN
        columnData = OBJTABLE_data.OBJCOL_list{i};        % cd = column OBJTABLE_data
        
        [s2, nSubcolumns] = create_OBJ_COLUMN_content(columnData, PDS_START_BYTE);
        s = add_SSL_OBJECT(s, 'COLUMN', s2);
        
        PDS_START_BYTE = PDS_START_BYTE + nSubcolumns*columnData.BYTES + bytesBetweenColumns;
        
        %clear columnData
    end
end



% Create SSL for the content an OBJECT=COLUMN segment.
% cd : Column data struct.
function [s, nSubcolumns] = create_OBJ_COLUMN_content(cd, PDS_START_BYTE)
    s = struct('keys', {{}}, 'values', {{}}, 'objects', {{}}) ;
    
    s = add_SSL(s, 'NAME',       '%s', cd.NAME);
    s = add_SSL(s, 'START_BYTE', '%i', PDS_START_BYTE);      % Move down to ITEMS?
    s = add_SSL(s, 'BYTES',      '%i', cd.BYTES);            % Move down to ITEMS?
    s = add_SSL(s, 'DATA_TYPE',  '%s', cd.DATA_TYPE);
    
    if isfield(cd, 'UNIT')
        s = add_SSL(s, 'UNIT', '"%s"', cd.UNIT);
    end
    if isfield(cd, 'ITEMS')
        s = add_SSL(s, 'ITEMS',       '%i', cd.ITEMS);
        s = add_SSL(s, 'ITEM_BYTES',  '%i', cd.ITEM_BYTES);
        s = add_SSL(s, 'ITEM_OFFSET', '%i', cd.ITEM_OFFSET);
        nSubcolumns = cd.ITEMS;
    else
        nSubcolumns = 1;
    end
    s = add_SSL(s, 'DESCRIPTION', '"%s"', cd.DESCRIPTION);      % NOTE: Added quotes.
    if isfield(cd, 'MISSING_CONSTANT')
        s = add_SSL(s, 'MISSING_CONSTANT', '%f', cd.MISSING_CONSTANT);
    end
end



function s = add_SSL(s, key, pattern, value)
    s.keys   {end+1} = key;
    s.values {end+1} = sprintf(pattern, value);
    s.objects{end+1} = [];
end

function s = add_SSL_OBJECT(s, objectValue, sslObjectContents)
    s.keys   {end+1} = 'OBJECT';
    s.values {end+1} = objectValue;
    s.objects{end+1} = sslObjectContents;
end



%##########################################################################################################



function assert_nonempty_unquoted(str)
% PROPOSAL: Use warning_error___LOCAL?
    if isempty(str)
        error('String value is empty.')
    end
        
    % ASSERTION: No quotes.
    if ~isempty(strfind(str, '"'))
        error('String value contains quotes.')
    end
end



% PROPOSAL: Remake into general function?!
function warning_error___LOCAL(msg, policy)
    if strcmp(policy, 'warning')
        %fprintf(1, '%s\n', msg)     % Print since warning is sometimes turned off automatically. Change?
        warning(msg)
    elseif strcmp(policy, 'error')
        error(msg)
    elseif ~strcmp(policy, 'nothing')
        error('Can not interpret warning/error policy.')
    end
end



%##########################################################################################################



% Create SSL for the "header" (before the OBJECT = TABLE).
%
% (1) Orders the keys
% (2) Add quotes to specific, selected (hard-codoed) key values.
%
% NOTE: Always interprets kvl.value{i} as (matlab) string, not number.
%
function ssl = create_SSL_header(kvl)   % kvl = key-value list
    % PROPOSAL: Take parameter tabFilePath ==> Set RECORD_BYTES (file size), ^TABLE, (RECORDS?!!)
    %
    % PROPOSAL: Set which keywords that should have quoted values or not.
    % PROPOSAL: Assert that all KEY_ORDER_LIST keys are unique.
    % PROPOSAL: Should set keywords that apply to all LBL/CAT files (not just OBJECT=TABLE).
    %    Ex: PDS_VERSION_ID
    %
    % PROPOSAL: Determine which keywords should or should not have quotes. Force parameter values to not have quotes.
    %    CON: Another long list which might not capture all keywords.
    %
    % PROPOSAL: Make *_KEY_ORDER_LIST into parameters, or only the more context-dependent RPCLAP_KEY_ORDER_LIST.
    %    PRO: Makes code more clear.
    %    PRO: Makes code more reusable, also outside lapdog.
    %       CON: Keyword ordering bugs are harmless.
    %    CON: More complicated parameters that need to be initialised.
    %       PRO: Would have to define new global variables in ~preamble.
    % PROPOSAL: Make FORBIDDEN_KEYS into a parameter.
    %    PRO: Makes code more clear.
    %    PRO: Makes code more reusable, also outside lapdog.
    %    CON: More complicated parameters that need to be initialised.
    % PROPOSAL: Make *_KEY_ORDER_LIST, FORBIDDEN_KEYS into parameters and create a wrapper function to set them.
    %
    % PROPOSAL: Order by groups.
    %   Ex: General ODL/PDS. Mission_specific.
    
    %=======================================================
    % Keys which should preferably come in a certain order.
    % Not all of them are required to be present.
    %=======================================================
    % Keywords which are quite independent of type of file.
    GENERAL_KEY_ORDER_LIST = { ...
        'PDS_VERSION_ID', ...    % The PDS standard requires this to be first, I think.
        ...
        'RECORD_TYPE', ...
        'RECORD_BYTES', ...
        'FILE_RECORDS', ...
        'FILE_NAME', ...
        '^TABLE', ...
        'DATA_SET_ID', ...
        'DATA_SET_NAME', ...
        'DATA_QUALITY_ID', ...
        'MISSION_ID', ...
        'MISSION_NAME', ...
        'MISSION_PHASE_NAME', ...
        'PRODUCER_INSTITUTION_NAME', ...
        'PRODUCER_ID', ...
        'PRODUCER_FULL_NAME', ...
        'LABEL_REVISION_NOTE', ...
        'PRODUCT_ID', ...
        'PRODUCT_TYPE', ...
        'PRODUCT_CREATION_TIME', ...
        'INSTRUMENT_HOST_ID', ...
        'INSTRUMENT_HOST_NAME', ...
        'INSTRUMENT_NAME', ...
        'INSTRUMENT_ID', ...
        'INSTRUMENT_TYPE', ...
        'INSTRUMENT_MODE_ID', ...
        'INSTRUMENT_MODE_DESC', ...
        'TARGET_NAME', ...
        'TARGET_TYPE', ...
        'PROCESSING_LEVEL_ID', ...
        'START_TIME', ...
        'STOP_TIME', ...
        'SPACECRAFT_CLOCK_START_COUNT', ...
        'SPACECRAFT_CLOCK_STOP_COUNT', ...
        'DESCRIPTION'};
    % Keywords which refer to very specific settings.
    RPCLAP_KEY_ORDER_LIST = { ...
        'ROSETTA:LAP_TM_RATE', ...
        'ROSETTA:LAP_BOOTSTRAP', ...
        ...
        'ROSETTA:LAP_FEEDBACK_P1', ...
        'ROSETTA:LAP_P1_ADC20', ...
        'ROSETTA:LAP_P1_ADC16', ...
        'ROSETTA:LAP_P1_RANGE_DENS_BIAS', ...
        'ROSETTA:LAP_P1_STRATEGY_OR_RANGE', ...
        'ROSETTA:LAP_P1_RX_OR_TX', ...
        'ROSETTA:LAP_P1_ADC16_FILTER', ...
        'ROSETTA:LAP_IBIAS1', ...
        'ROSETTA:LAP_VBIAS1', ...
        'ROSETTA:LAP_P1_BIAS_MODE', ...
        'ROSETTA:LAP_P1_INITIAL_SWEEP_SMPLS', ...
        'ROSETTA:LAP_P1_SWEEP_PLATEAU_DURATION', ...
        'ROSETTA:LAP_P1_SWEEP_STEPS', ...
        'ROSETTA:LAP_P1_SWEEP_START_BIAS', ...
        'ROSETTA:LAP_P1_SWEEP_FORMAT', ...
        'ROSETTA:LAP_P1_SWEEP_RESOLUTION', ...
        'ROSETTA:LAP_P1_SWEEP_STEP_HEIGHT', ...
        'ROSETTA:LAP_P1_ADC16_DOWNSAMPLE', ...
        'ROSETTA:LAP_P1_DENSITY_FIX_DURATION', ...
        ...
        'ROSETTA:LAP_FEEDBACK_P2', ...
        'ROSETTA:LAP_P2_ADC20', ...
        'ROSETTA:LAP_P2_ADC16', ...
        'ROSETTA:LAP_P2_RANGE_DENS_BIAS', ...
        'ROSETTA:LAP_P2_STRATEGY_OR_RANGE', ...
        'ROSETTA:LAP_P2_RX_OR_TX', ...
        'ROSETTA:LAP_P2_ADC16_FILTER', ...
        'ROSETTA:LAP_IBIAS2', ...
        'ROSETTA:LAP_VBIAS2', ...
        'ROSETTA:LAP_P2_BIAS_MODE', ...
        'ROSETTA:LAP_P2_INITIAL_SWEEP_SMPLS', ...
        'ROSETTA:LAP_P2_SWEEP_PLATEAU_DURATION', ...
        'ROSETTA:LAP_P2_SWEEP_STEPS', ...
        'ROSETTA:LAP_P2_SWEEP_START_BIAS', ...
        'ROSETTA:LAP_P2_SWEEP_FORMAT', ...
        'ROSETTA:LAP_P2_SWEEP_RESOLUTION', ...
        'ROSETTA:LAP_P2_SWEEP_STEP_HEIGHT', ...
        'ROSETTA:LAP_P2_ADC16_DOWNSAMPLE', ...
        'ROSETTA:LAP_P2_DENSITY_FIX_DURATION', ...
        ...
        'ROSETTA:LAP_P1P2_ADC20_STATUS', ...
        'ROSETTA:LAP_P1P2_ADC20_MA_LENGTH', ...
        'ROSETTA:LAP_P1P2_ADC20_DOWNSAMPLE'
        };
    KEY_ORDER_LIST = [GENERAL_KEY_ORDER_LIST, RPCLAP_KEY_ORDER_LIST];
    
    % Give error if encountering any of these keys.
    % Useful for obsoleted keys that should not exist anymore.
    FORBIDDEN_KEYS = { ...
        'ROSETTA:LAP_INITIAL_SWEEP_SMPLS', ...
        'ROSETTA:LAP_SWEEP_PLATEAU_DURATION', ...
        'ROSETTA:LAP_SWEEP_STEPS', ...
        'ROSETTA:LAP_SWEEP_START_BIAS', ...
        'ROSETTA:LAP_SWEEP_FORMAT', ...
        'ROSETTA:LAP_SWEEP_RESOLUTION', ...
        'ROSETTA:LAP_SWEEP_STEP_HEIGHT'};
    
    %         ADD_QUOTES_KEYS = { ...
    %             'DESCRIPTION', ...
    %             'SPACECRAFT_CLOCK_START_COUNT', ...
    %             'SPACECRAFT_CLOCK_STOP_COUNT', ...
    %             'INSTRUMENT_MODE_DESC', ...
    %             'ROSETTA:LAP_TM_RATE', ...
    %             'ROSETTA:LAP_BOOTSTRAP', ...
    %             'ROSETTA:LAP_FEEDBACK_P1', ...
    %             'ROSETTA:LAP_FEEDBACK_P2', ...
    %             'ROSETTA:LAP_P1_ADC20', ...
    %             'ROSETTA:LAP_P1_ADC16', ...
    %             'ROSETTA:LAP_P1_RANGE_DENS_BIAS', ...
    %             'ROSETTA:LAP_P1_STRATEGY_OR_RANGE', ...
    %             'ROSETTA:LAP_P1_RX_OR_TX', ...
    %             'ROSETTA:LAP_P1_ADC16_FILTER', ...
    %             'ROSETTA:LAP_P1_BIAS_MODE', ...
    %             'ROSETTA:LAP_P2_ADC20', ...
    %             'ROSETTA:LAP_P2_ADC16', ...
    %             'ROSETTA:LAP_P2_RANGE_DENS_BIAS', ...
    %             'ROSETTA:LAP_P2_STRATEGY_OR_RANGE', ...
    %             'ROSETTA:LAP_P2_RX_OR_TX', ...
    %             'ROSETTA:LAP_P2_ADC16_FILTER', ...
    %             'ROSETTA:LAP_P2_BIAS_MODE', ...
    %             'ROSETTA:LAP_P1P2_ADC20_STATUS', ...
    %             'ROSETTA:LAP_P1P2_ADC20_MA_LENGTH', ...
    %             'ROSETTA:LAP_P1P2_ADC20_DOWNSAMPLE', ...
    %             'ROSETTA:LAP_VBIAS1', ...
    %             'ROSETTA:LAP_VBIAS2', ...
    %             ...
    %             'ROSETTA:LAP_P1_INITIAL_SWEEP_SMPLS', ...
    %             'ROSETTA:LAP_P1_SWEEP_PLATEAU_DURATION', ...
    %             'ROSETTA:LAP_P1_SWEEP_STEPS', ...
    %             'ROSETTA:LAP_P1_SWEEP_START_BIAS', ...
    %             'ROSETTA:LAP_P1_SWEEP_FORMAT', ...
    %             'ROSETTA:LAP_P1_SWEEP_RESOLUTION', ...
    %             'ROSETTA:LAP_P1_SWEEP_STEP_HEIGHT', ...
    %             'ROSETTA:LAP_P1_ADC16_DOWNSAMPLE', ...
    %             'ROSETTA:LAP_SWEEPING_P1', ...
    %             ...
    %             'ROSETTA:LAP_P2_FINE_SWEEP_OFFSET', ...
    %             'ROSETTA:LAP_P2_INITIAL_SWEEP_SMPLS', ...
    %             'ROSETTA:LAP_P2_SWEEP_PLATEAU_DURATION', ...
    %             'ROSETTA:LAP_P2_SWEEP_STEPS', ...
    %             'ROSETTA:LAP_P2_SWEEP_START_BIAS', ...
    %             'ROSETTA:LAP_P2_SWEEP_FORMAT', ...
    %             'ROSETTA:LAP_P2_SWEEP_RESOLUTION', ...
    %             'ROSETTA:LAP_P2_SWEEP_STEP_HEIGHT', ...
    %             'ROSETTA:LAP_P2_ADC16_DOWNSAMPLE', ...
    %             'ROSETTA:LAP_SWEEPING_P2', ...
    %             'ROSETTA:LAP_P2_FINE_SWEEP_OFFSET'};
    
    % Keys for which quotes are added to the value if the values does not already have quotes.
    FORCE_QUOTE_KEYS = {...
        'DESCRIPTION', ...
        'SPACECRAFT_CLOCK_START_COUNT', ...
        'SPACECRAFT_CLOCK_STOP_COUNT'};
    
    
    
    %===========================================================================
    % Put key-value pairs in certain order.
    % -------------------------------------
    % Look for specified keys and for those found, put them in the given order.
    % NOTE: This is done for at least two reasons:
    % 1) to make LBL files more "beautiful" (e.g. P1 before P2 keywords,
    %    non-ROSETTA before ROSETTA keywords), and
    % 2) to ensure that LBL keywords are always in approximately the same order.
    %    This is useful when comparing datasets to ensure that a modified/updated
    %    lapdog code produces only the desired changes to LBL files.
    %===========================================================================
    kvl = lib_shared_EJ.KVPL.order_by_key_list(kvl, KEY_ORDER_LIST);
    
    % ASSERTION
    % Check that there are no forbidden keys.
    % Ensures that obsoleted keywords are not used by mistake.
    for i=1:length(FORBIDDEN_KEYS)
        if any(strcmp(FORBIDDEN_KEYS{i}, kvl.keys))
            error('Trying to write LBL file header with explicitly forbidden LBL keyword "%s". This indicates that the code has previously failed to substitute these keywords for new ones.', ...
                FORBIDDEN_KEYS{i})
        end
    end
    
    
    % ASSERTION: Parameter error check
    if isempty(kvl.keys)                    % Not sure why checks for this specifically. Previously checked before calculating maxKeyLength.
        error('kvl.keys is empty.')
    end
    if length(unique(kvl.keys)) ~= length(kvl.keys)
        error('Found doubles among the keys/ODL attribute names.')
    end
    
    for j = 1:length(kvl.keys)
        key   = kvl.keys{j};
        value = kvl.values{j};
        
        % ASSERTION
        if ~ischar(value)
            error(sprintf('(key-) value is not a MATLAB string:\n key = "%s", fopen(fid) = "%s"', key, fopen(fid)))
        end
        
        if ismember(key, FORCE_QUOTE_KEYS) && ~any('"' == value)
            kvl.values{j} = ['"', value, '"'];
        end
    end
    
    ssl = struct('keys', {kvl.keys}, 'values', {kvl.values}, 'objects', {cell(size(kvl.keys))});
    
end
