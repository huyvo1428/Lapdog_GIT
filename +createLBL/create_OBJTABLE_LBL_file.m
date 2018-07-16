%
% Create LBL file for an _existing_ TAB file.
%
% ("OBJTABLE" refers to "OBJECT = TABLE" in ODL files.)
% Only for LBL files based on one OBJECT = TABLE section (plus header keywords).
%
%
% ARGUMENTS
% =========
% tabFilePath                           : Path to TAB file.
% LblData                               : Struct with the following fields.
%       .indentationLength              :
%       .HeaderKvl                      : Key-value list describing PDS keywords in the "ODL header". Some mandatory
%                                         keywords are added automatically by the code and must not overlap with these
%                                         (assertion).
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
% HeaderOptions             : Data on how to modify and check the LBL header keywords.
% tabLblInconsistencyPolicy : 'warning', 'error', or 'nothing'.
%                             Determines how to react in the event of inconsistencies.
%                             NOTE: Function may abort in case of 'warning'/'nothing' if it can not recover.
%
%
% NOTES
% =====
% NOTE: The caller is NOT supposed to surround key value strings with quotes, or units with </>.
% The implementation should add that when appropriate.
% NOTE: The implementation will add certain keywords to LblData.HeaderKvl, and derive the values, and assume that
% the caller has not set them. Error otherwise (assertion).
%
% NOTE: Previous implementations have added a DELIMITER=", " field (presumably not PDS compliant) in
% agreement with Imperial College/Tony Allen to somehow help them process the files
% It appears that at least part of the reason was to make it possible to parse the files before
% we used ITEM_OFFSET+ITEM_BYTES correctly. DELIMITER IS NO LONGER NEEDED AND HAS BEEN PHASED OUT!
% (E-mail Tony Allen->Erik Johansson 2015-07-03 and that thread).
%
% NOTE: Not full general-purpose function for table files, since
%       (1) ASSUMPTION: TAB files are constructed with a fixed number of byets between columns (and no bytes
%           before/after the first/last string).
%       (2) Does not permit FORMAT field, and there are probably other PDS-keywords which are not supported by this code.
%
function create_OBJTABLE_LBL_file(tabFilePath, LblData, HeaderOptions, tabLblInconsistencyPolicy)
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
    % PROPOSAL: Read one TAB file row and count the number of strings ", ", infer number of columns, and use for
    %   consistency check.
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
    %
    % PROPOSAL: Reorg into separate function which creates and returns the SSL with only the needed fields.
    %           Add header using standard SSL function(s) (needs to be created).
    %   PRO: Easier to modify SSL in standardized fashion for not yet written LBL files.
    %       Ex: ^ARCHIVE_CONTENT_DESC for geometry LBL files. (Never read and modified, only created.)
    %   CON/PROBLEM: How/where force quotes? Key reordering (relative to keys required for OBJECT=TABLE)?
    %       PROPOSAL: Standard function for adding header keys.
    

    
    %===========
    % Constants
    %===========
    BYTES_BETWEEN_COLUMNS = length(', ');      % ASSUMES absence of quotes in string columns.
    BYTES_PER_LINEBREAK   = 2;                 % Carriage return + line feed.
    
    PERMITTED_LBLDATA_FIELD_NAMES  = {'indentationLength', 'HeaderKvl', 'OBJTABLE'};
    % NOTE: Exclude COLUMNS, ROW_BYTES, ROWS.
    PERMITTED_OBJTABLE_FIELD_NAMES = {'DESCRIPTION', 'OBJCOL_list'};
    % NOTE: Exclude START_BYTE, ITEM_OFFSET which are derived.
    % NOTE: Includes both required and optional fields.
    PERMITTED_OBJCOL_FIELD_NAMES   = {'NAME', 'BYTES', 'DATA_TYPE', 'UNIT', 'ITEMS', 'ITEM_BYTES', 'DESCRIPTION', 'MISSING_CONSTANT'};
    
    %CONTENT_MAX_ROW_LENGTH         = 70;    % Excludes line break characters.
    CONTENT_MAX_ROW_LENGTH         = 1000;    % Excludes line break characters.
    
    % "Planetary Data Systems Standards Reference", Version 3.6, p12-11, section 12.3.4.
    % Applies to what PDS defines as identifiers, i.e. "values" without quotes.
    PDS_IDENTIFIER_PERMITTED_CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789';



    % --------------------------------------------------------------
    % ASSERTION: Caller only uses permissible field names.
    % Useful when changing field names.
    % --------------------------------------------------------------
    if ~isempty(setxor(fieldnames(LblData), PERMITTED_LBLDATA_FIELD_NAMES))
        fnl = fieldnames(LblData);
        error('ERROR: Found illegal field name(s) in parameter "LblData". fieldnames(LblData) = {%s}', sprintf('"%s"  ', fnl{:}))
    end
    if ~isempty(setxor(fieldnames(LblData.OBJTABLE), PERMITTED_OBJTABLE_FIELD_NAMES))
        fnl = fieldnames(LblData.OBJTABLE);
        error('ERROR: Found illegal field name(s) in parameter "LblData.OBJTABLE". fieldnames(LblData.OBJTABLE): %s', sprintf('"%s  "', fnl{:}))
    end

    
    
    OBJTABLE_data = LblData.OBJTABLE;

    %-----------------------------------------------------------------------------------
    % ASSERTION: Misc. argument check
    % -------------------------------
    % When a caller takes values from tabindex, an_tabindex etc, and they are sometimes
    % mistakenly set to []. Therefore this check is useful. A mistake might
    % otherwise be discovered first when examining LBL files.
    %-----------------------------------------------------------------------------------
%     if isempty(LblData.ConsistencyCheck.nTabColumns) || isempty(LblData.ConsistencyCheck.nTabBytesPerRow) || isempty(LblData.nTabFileRows)
%         error('ERROR: Trying to use empty value when disallowed.')
%     end

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
%     if (OBJTABLE_data.COLUMNS ~= LblData.ConsistencyCheck.nTabColumns)
%         msg =       sprintf('lblFilePath = %s\n', lblFilePath);
%         msg = [msg, sprintf('OBJTABLE_data.COLUMNS (derived)      = %i\n', OBJTABLE_data.COLUMNS)];
%         msg = [msg, sprintf('LblData.ConsistencyCheck.nTabColumns = %i\n', LblData.ConsistencyCheck.nTabColumns)];
%         msg = [msg,         'OBJTABLE_data.COLUMNS deviates from the consistency check value.'];
%         warning_error___LOCAL(msg, tabLblInconsistencyPolicy)
%     end
%     if OBJTABLE_data.ROW_BYTES ~= LblData.ConsistencyCheck.nTabBytesPerRow
%         msg =       sprintf('lblFilePath = %s\n', lblFilePath);
%         msg = [msg, sprintf('OBJTABLE_data.ROW_BYTES (derived)        = %i\n', OBJTABLE_data.ROW_BYTES)];
%         msg = [msg, sprintf('LblData.ConsistencyCheck.nTabBytesPerRow = %i\n', LblData.ConsistencyCheck.nTabBytesPerRow)];
%         msg = [msg,         'OBJTABLE_data.ROW_BYTES deviates from the consistency check value.'];
%         
%         warning_error___LOCAL(msg, tabLblInconsistencyPolicy)
%     end
    
    temp = dir(tabFilePath); tabFileSize = temp.bytes;
    
    % ASSERTION: TAB file size is consistent with (indirectly) ROWS*ROW_BYTES.
%     if tabFileSize ~= (OBJTABLE_data.ROW_BYTES * LblData.nTabFileRows)
%         msg = sprintf(['TAB file size is not consistent with LBL file, "%s":\n', ...
%             '    tabFileSize             = %g\n', ...
%             '    OBJTABLE_data.ROW_BYTES = %g\n', ...
%             '    LblData.nTabFileRows    = %g'], ...
%             tabFilePath, tabFileSize, OBJTABLE_data.ROW_BYTES, LblData.nTabFileRows);
%         warning_error___LOCAL(msg, tabLblInconsistencyPolicy)
%     end

    LblData.nTabFileRows = floor(tabFileSize / OBJTABLE_data.ROW_BYTES);
    
    % ASSERTION: TAB file size is consistent with bytes-per-row (integer multiple).
    if rem(tabFileSize,OBJTABLE_data.ROW_BYTES) ~= 0
        msg = sprintf(['TAB file size is not consistent with LBL file, "%s":\n', ...
            '    tabFileSize                           = %g\n', ...
            '    OBJTABLE_data.ROW_BYTES               = %g\n', ...
            '    tabFileSize / OBJTABLE_data.ROW_BYTES = %g   (must be an integer)'], ...
            tabFilePath, tabFileSize, OBJTABLE_data.ROW_BYTES, tabFileSize / OBJTABLE_data.ROW_BYTES);
        warning_error___LOCAL(msg, tabLblInconsistencyPolicy)
    end
    
    % ASSERTION: No quotes in OBJECT=TABLE DESCRIPTION keyword.
    assert_nonempty_unquoted(OBJTABLE_data.DESCRIPTION)

    %################################################################################################

    %===================================================================
    % Add keywords to the LBL "header" (before first OBJECT statement).
    %===================================================================
    HeaderAddKvl = [];   % NOTE: Can not initialize with "struct(...)". That gives an unintended result due to a special interpretation for arrays.
    HeaderAddKvl.keys   = {};
    HeaderAddKvl.values = {};
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, 'RECORD_TYPE',  'FIXED_LENGTH');   % NOTE: Influences whether one must use RECORD_BYTES, FILE_RECORDS, LABEL_RECORDS.
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, 'RECORD_BYTES', sprintf('%i',   OBJTABLE_data.ROW_BYTES));
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, 'FILE_NAME',    sprintf('"%s"', lblFilename));    % Should be qouted.
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, '^TABLE',       sprintf('"%s"', tabFilename));    % Should be qouted.
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, 'PRODUCT_ID',   sprintf('"%s"', fileBasename));   % Should be qouted.
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, 'FILE_RECORDS', sprintf('%i',   LblData.nTabFileRows));
    
    LblData.HeaderKvl = EJ_lapdog_shared.utils.KVPL.merge(LblData.HeaderKvl, HeaderAddKvl);
    
    
    
    %=============================================
    % Construct SSL representing the LBL contents
    %=============================================
    ssl = create_SSL_header(LblData.HeaderKvl, HeaderOptions);
    ssl = add_SSL_OBJECT(ssl, 'TABLE', create_OBJ_TABLE_content(OBJTABLE_data, LblData.nTabFileRows, BYTES_BETWEEN_COLUMNS));



    % Log message
    %fprintf(1, 'Writing LBL file: "%s"\n', lblFilePath);
    EJ_lapdog_shared.PDS_utils.write_ODL_from_struct(lblFilePath, ssl, {}, LblData.indentationLength, CONTENT_MAX_ROW_LENGTH);    % endRowsList = {};
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
% (2) Add quotes to specific, selected key values (if not already quoted).
% (3) Check that certain keywords are not used.
%     (Ensures that obsoleted keywords are not used by mistake.)
%
% NOTE: Always interprets kvl.value{i} as (matlab) string, not number.
%
%
% RATIONALE: ORDERING OF KEYS
% ===========================
% 1) to make LBL files more "beautiful" (e.g. P1 before P2 keywords,
%    non-ROSETTA before ROSETTA keywords), and
% 2) to ensure that LBL keywords are always in approximately the same order.
%    This is useful when comparing datasets to ensure that a modified/updated
%    lapdog code produces only the desired changes to LBL files.
function ssl = create_SSL_header(kvl, HeaderOptions)   % kvl = key-value list
    % PROPOSAL: Assert that all KEY_ORDER_LIST keys are unique.
    % PROPOSAL: Should set keywords that apply to all LBL/CAT files (not just OBJECT=TABLE).
    %    Ex: PDS_VERSION_ID
    %
    % PROPOSAL: Determine which keywords should or should not have quotes. Force parameter values to not have quotes.
    %    CON: Another long list which might not capture all keywords.
    
    % ASSERTION: Parameter error check
    if isempty(kvl.keys)                    % Not sure why checks for this specifically. Previously checked before calculating maxKeyLength.
        error('kvl.keys is empty.')
    end
    if length(unique(kvl.keys)) ~= length(kvl.keys)
        error('Found doubles among the keys/ODL attribute names.')
    end
    
    
    
    % Order keys.
    kvl = EJ_lapdog_shared.utils.KVPL.order_by_key_list(kvl, HeaderOptions.keyOrderList);

    % ASSERTION: Check that there are no forbidden keys.
    for i=1:length(HeaderOptions.forbiddenKeysList)
        if any(strcmp(HeaderOptions.forbiddenKeysList{i}, kvl.keys))
            error('Trying to write LBL file header with explicitly forbidden LBL keyword "%s". This indicates that the code has previously failed to substitute these keywords for new ones.', ...
                HeaderOptions.forbiddenKeysList{i})
        end
    end

    % Force certain key values to be quoted.
    for j = 1:length(kvl.keys)
        key   = kvl.keys{j};
        value = kvl.values{j};
        
        % ASSERTION
        if ~ischar(value)
            error('(key-) value is not a MATLAB string:\n key = "%s", fopen(fid) = "%s"', key, fopen(fid))
        end
        
        if ismember(key, HeaderOptions.forceQuotesKeysList) && ~any('"' == value)
            kvl.values{j} = ['"', value, '"'];
        end
    end
    
    ssl = struct('keys', {kvl.keys}, 'values', {kvl.values}, 'objects', {cell(size(kvl.keys))});
    
end
