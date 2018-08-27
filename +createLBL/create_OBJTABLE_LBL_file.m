%
% Create LBL file for an _existing_ TAB file.
%
% ("OBJTABLE" refers to "OBJECT = TABLE" in ODL files.)
% Only for LBL files based on one OBJECT = TABLE section (plus header keywords).
%
%
% ARGUMENTS
% =========
% tabFilePath                     : Path to TAB file.
% LblData                         : Struct with the following fields.
%       .HeaderKvl                : Key-value list describing PDS keywords in the "ODL header". Some mandatory
%                                   keywords are added automatically by the code and must not overlap with these
%                                   (assertion).
%       .OBJTABLE                 : (OBJTABLE = "OBJECT = TABLE" segment)
%           .DESCRIPTION          : Description for entire table (PDS keyword).
%           .OBJCOL_list{i}       : Struct containing fields corresponding to various column PDS keywords.
%                                   (OBJCOL = "OBJECT = COLUMN" segment)
%                                   NOTE: The order of the fields does not matter. The implementation specifies
%                                         the order of keywords (within an OBJECT=COLUMN segment) in the label file.
%                                   NOTE: ".FORMAT" explicitly forbidden.
%               .NAME
%               .DATA_TYPE
%               .UNIT             : Replaced by standardized default value if empty. Automatically quoted.
%                                   (Optional by PDS, required here)
%               .DESCRIPTION      : Replaced by standardized default value if empty. Must not contains quotes.
%                                   (Automatically quoted.)
%               .MISSING_CONSTANT : Optional
%               Either (1)
%           	  .BYTES
%               or (2)
%                 .ITEMS
%                 .ITEM_BYTES
%               .useFor           : Optional. Cell array of strings representing LBL header PDS keywords. Code
%                                   contains hardcoded info on how to extract the corresponding keyword values
%                                   from the corresponding column.
%                                   Permitted:
%                                       START_STOP, STOP_TIME             : Must be UTC column (at least 3 decimals).
%                                       SPACECRAFT_CLOCK_START/STOP_COUNT : Must be OBT column.
%                                       STOP_TIME_from_OBT                : Must be OBT column.
% HeaderOptions             : Struct/class. Data on how to modify and check the LBL header keywords. Every field is a
%                             cell array of strings.
%   .forceQuotesKeyList
%   .keyOrderList
%   .forbiddenKeysList
% Settings
%   .indentationLength
% tabLblInconsistencyPolicy : 'warning', 'error', or 'nothing'.
%                             Determines how to react in the event of inconsistencies between LBL and TAB file.
%                             NOTE: Function may abort in case of 'warning'/'nothing' if it can not recover.
%
%
% NOTES
% =====
% NOTE: The caller is NOT supposed to surround key value strings with quotes, or units with </>.
% The implementation should add that when appropriate.
% NOTE: The implementation will add certain keywords to LblData.HeaderKvl, and derive the values, and assume that
% the caller has not set them. Error otherwise (assertion).
% NOTE: Uses Lapdog's obt2sct function.
%
% NOTE: Previous implementations have added a DELIMITER=", " field (presumably not PDS compliant) in
% agreement with Imperial College/Tony Allen to somehow help them process the files
% It appears that at least part of the reason was to make it possible to parse the files before
% we used ITEM_OFFSET+ITEM_BYTES correctly. DELIMITER IS NO LONGER NEEDED AND HAS BEEN PHASED OUT!
% (E-mail Tony Allen->Erik Johansson 2015-07-03 and that thread).
%
% NOTE: Not full general-purpose function for table files, since
%       (1) ASSUMPTION: TAB files are constructed with a fixed number of bytes between columns (and no bytes
%           before/after the first/last string).
%       (2) Does not permit FORMAT field, and there are probably other PDS-keywords which are not supported by this code.
%
%
% IMPLEMENTATION NOTES
% ====================
% This function could possibly be useful outside of Lapdog (like in EJ's delivery code). It should therefore avoid
% calling Lapdog-specific code, e.g. createLBL.constants.
%
%
% NAMING CONVENTIONS
% ==================
% T2PK : TAB file to PDS keyword. Functionality for retrieving LBL header PDS keyword values from TAB file.
%
function create_OBJTABLE_LBL_file(tabFilePath, LblData, HeaderOptions, settings, tabLblInconsistencyPolicy)
    %
    % NOTE: CONCEIVABLE LBL FILE SPECIAL CASES that may have different requirements:
    %    - Data files (DATA/)
    %    - Block lists   (Does require SPACECRAFT_CLOCK_START_COUNT etc.)
    %    - Geometry files
    %    - HK files
    %    - INDEX.LBL   => Does not require SPACECRAFT_CLOCK_START_COUNT etc.
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
    %   CON: Not entirely rigorous.
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
    % PROPOSAL: Read indentation length from central constants class.



    %===========
    % Constants
    %===========
    PERMITTED_LBLDATA_FIELD_NAMES  = {'HeaderKvl', 'OBJTABLE'};
    % NOTE: Exclude COLUMNS, ROW_BYTES, ROWS.
    PERMITTED_OBJTABLE_FIELD_NAMES = {'DESCRIPTION', 'OBJCOL_list'};
    % NOTE: Exclude START_BYTE, ITEM_OFFSET which are derived.
    % NOTE: Includes both required and optional fields.
    PERMITTED_OBJCOL_FIELD_NAMES   = {'NAME', 'BYTES', 'DATA_TYPE', 'UNIT', 'ITEMS', 'ITEM_BYTES', 'DESCRIPTION', 'MISSING_CONSTANT', ...
        'useFor'};
    
    % "Planetary Data Systems Standards Reference", Version 3.6, p12-11, section 12.3.4.
    % Applies to what PDS defines as identifiers, i.e. "values" without quotes.
    PDS_IDENTIFIER_PERMITTED_CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789';
    
    ROSETTA_NAIF_ID = -226;
    %CONTENT_MAX_ROW_LENGTH         = 79;    % Number excludes line break characters.
    CONTENT_MAX_ROW_LENGTH         = 1000;    % Number excludes line break characters.
    
    BYTES_BETWEEN_COLUMNS = length(', ');      % ASSUMES absence of quotes in string columns. Lapdog convention.
    BYTES_PER_LINEBREAK   = 2;                 % Carriage return + line feed.
    
    
    % Constants for (optionally) converting TAB file contents into PDS keywords.
    T2PK_OBT2SCCS_FUNC = @(x) ['1/', obt2sct(str2double(x))];    % No quotes. Quotes added later.
    T2PK_UTC2UTC_FUNC  = @(x) [x(1:23)];                         % Has to truncate UTC second decimals according to DVAL-NG.
    T2PK_OBT2UTC_FUNC  = @(x) [cspice_et2utc(cspice_scs2e(ROSETTA_NAIF_ID, obt2sct(str2double(x))), 'ISOC', 3)];    % 3 = 3 UTC second decimals
    T2PK_PROCESSING_TABLE = struct(...
        'argConst',   {'START_TIME',      'STOP_TIME',       'STOP_TIME_from_OBT', 'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}, ...    % Argument value.
        'pdsKeyword', {'START_TIME',      'STOP_TIME',       'STOP_TIME',          'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}, ...    % LBL file header PDS keyword which will be assigned.
        'convFunc',   {T2PK_UTC2UTC_FUNC, T2PK_UTC2UTC_FUNC, T2PK_OBT2UTC_FUNC,    T2PK_OBT2SCCS_FUNC,             T2PK_OBT2SCCS_FUNC           }, ...    % Function string-->string that is applied to the TAB file value.
        'iFlr',       {1,                 2,                 2,                    1,                              2                            });       % 1=First row, 2=Last row



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
    if ~isscalar(LblData.HeaderKvl)
        error('LblData.HeaderKvl is not scalar.')    % Common error to initialize empty KVPL the wrong way.
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
    OBJTABLE_data.COLUMNS   = 0;   % NOTE: Adds new field to structure.
    OBJCOL_namesList = {};
    t2pkArgsTable = struct('argConst', {}, 'iByteFirst', {}, 'iByteLast', {});
    PDS_START_BYTE = 1;    % Used for deriving START_BYTE. Starts with one, not zero.
    for i = 1:length(OBJTABLE_data.OBJCOL_list)
        cd = OBJTABLE_data.OBJCOL_list{i};       % Temporarily shorten variable name: cd = column data
        
        % ASSERTION: Check common user/caller error.
        if numel(cd) ~= 1
            error('One column object is a non-one size array. Guess: Due to defining .useFor value with ~single curly brackets?')
        end
        
        [cd, nSubcolumns] = complement_column_data(cd, ...
            PERMITTED_OBJCOL_FIELD_NAMES, BYTES_BETWEEN_COLUMNS, PDS_IDENTIFIER_PERMITTED_CHARS, ...
            lblFilePath, tabLblInconsistencyPolicy);
        cd.START_BYTE  = PDS_START_BYTE;

        % ASSERTION: Keywords do not contain quotes.
        for fnCell = fieldnames(cd)'
            fn = fnCell{1};
            if ischar(cd.(fn)) && ~isempty(strfind(cd.(fn), '"'))
                error('Keyword ("%s") value contains quotes.', fn)
            end
        end

        OBJCOL_namesList{end+1} = cd.NAME;
        %OBJTABLE_data.COLUMNS   = OBJTABLE_data.COLUMNS + nSubcolumns;    % BUG? Misunderstanding of PDS standard?!!
        OBJTABLE_data.COLUMNS   = OBJTABLE_data.COLUMNS + 1;              % CORRECT according to MB email 2018-08-08 and DVALNG. ITEMS<>1 still counts as 1 column here.
        PDS_START_BYTE = PDS_START_BYTE + cd.BYTES + BYTES_BETWEEN_COLUMNS;
        
        % Collect information for T2PK functionality.
        if isfield(cd, 'useFor')
            for iT2pk = 1:numel(cd.useFor)    % PROPOSAL: Change name of for-loop variable.
                t2pkArgsTable(end+1).argConst   = cd.useFor{iT2pk};
                t2pkArgsTable(end  ).iByteFirst = cd.START_BYTE;
                t2pkArgsTable(end  ).iByteLast  = cd.START_BYTE + cd.BYTES - 1;
            end
        end
        
        OBJTABLE_data.OBJCOL_list{i} = cd;      % Return updated info to original data structure.
        clear cd
    end
    OBJTABLE_data.ROW_BYTES = (PDS_START_BYTE-1) - BYTES_BETWEEN_COLUMNS + BYTES_PER_LINEBREAK;   % Adds new column to struct. -1 since PDS_START_BYTE=1 refers to first byte.
    
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
    
%    temp = dir(tabFilePath); tabFileSize = temp.bytes;
    
    % ASSERTION: TAB file size is consistent with (indirectly) ROWS*ROW_BYTES.
%     if tabFileSize ~= (OBJTABLE_data.ROW_BYTES * LblData.nTabFileRows)
%         msg = sprintf(['TAB file size is not consistent with LBL file, "%s":\n', ...
%             '    tabFileSize             = %g\n', ...
%             '    OBJTABLE_data.ROW_BYTES = %g\n', ...
%             '    LblData.nTabFileRows    = %g'], ...
%             tabFilePath, tabFileSize, OBJTABLE_data.ROW_BYTES, LblData.nTabFileRows);
%         warning_error___LOCAL(msg, tabLblInconsistencyPolicy)
%     end

%    LblData.nTabFileRows = floor(tabFileSize / OBJTABLE_data.ROW_BYTES);
    
    % ASSERTION: No quotes in OBJECT=TABLE DESCRIPTION keyword.
    assert_nonempty_unquoted(OBJTABLE_data.DESCRIPTION)

    %################################################################################################

    %---------------------------------------------
    % Convert TAB file contents into PDS keywords
    %---------------------------------------------
    
    % ASSERTION: Unique .useFor PDS keywords.
    if numel(unique({t2pkArgsTable.argConst})) ~= numel({t2pkArgsTable.argConst})
        error('Specified the same PDS keyword multiple times in ".useFor" fields.')
    end
    
    [junk, iT2pkArgsTable, iT2pkProcTable] = intersect({t2pkArgsTable.argConst}, {T2PK_PROCESSING_TABLE.argConst});

    % ASSERTION: Arguments only specify implemented-for argument constants.
    if numel(t2pkArgsTable) ~= numel(iT2pkProcTable)
        error('Can not find hard-coded support for at least one of the values specified in ".useFor" fields.')
    end
    
    t2pkArgsTable = t2pkArgsTable(iT2pkArgsTable);    % Potentially modify the ordering so that it is consistent with t2pkExecTable.
    t2pkExecTable = T2PK_PROCESSING_TABLE(iT2pkProcTable);
    [t2pkExecTable(:).iByteFirst] = deal(t2pkArgsTable(:).iByteFirst);
    [t2pkExecTable(:).iByteLast]  = deal(t2pkArgsTable(:).iByteLast);
    
    LblData.nTabFileRows = NaN;   % Field must be created in case deriving the value later fails.
    try
        rowStringArrayArray = {[], []};
        [rowStringArrayArray{:}, nBytesPerRow, LblData.nTabFileRows] = createLBL.analyze_TAB_file(tabFilePath, [t2pkExecTable(:).iByteFirst], [t2pkExecTable(:).iByteLast]);
        
        % ASSERTION: Number of bytes per row.
        if nBytesPerRow ~= OBJTABLE_data.ROW_BYTES
            warning_error___LOCAL(sprintf('TAB file is inconsistent with LBL file. Bytes per row does not fit table description.\n    nBytesPerRow=%g\n    OBJTABLE_data.ROW_BYTES=%g\n    File: "%s"', ...
                nBytesPerRow, OBJTABLE_data.ROW_BYTES, tabFilePath), tabLblInconsistencyPolicy)
        end
        
        t2pkKvpl.keys   = {t2pkExecTable(:).pdsKeyword};
        t2pkKvpl.values = {};
        for iT2pk = 1:numel(t2pkKvpl.keys)
            tabFileValueStr        = rowStringArrayArray{ t2pkExecTable(iT2pk).iFlr }{ iT2pk };
            t2pkKvpl.values{end+1} = t2pkExecTable(iT2pk).convFunc( tabFileValueStr );
        end
        
        % Update selected PDS keyword values.
        LblData.HeaderKvl = EJ_lapdog_shared.utils.KVPL.overwrite_values(LblData.HeaderKvl, t2pkKvpl, 'require preexisting keys');
    catch exc
        warning_error___LOCAL(sprintf('TAB file is inconsistent with LBL file: "%s"', exc.message), tabLblInconsistencyPolicy)
    end
    
    %################################################################################################

    %===================================================================
    % Add keywords to the LBL "header" (before first OBJECT statement).
    %===================================================================
    HeaderAddKvl = [];   % NOTE: Can not initialize with "struct(...)". That gives an unintended result due to a special interpretation for arrays.
    HeaderAddKvl.keys   = {};
    HeaderAddKvl.values = {};
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, 'RECORD_TYPE',  'FIXED_LENGTH');   % NOTE: Influences whether one must use RECORD_BYTES, FILE_RECORDS, LABEL_RECORDS.
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, 'RECORD_BYTES', sprintf( '%i',  OBJTABLE_data.ROW_BYTES));
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, 'FILE_NAME',    sprintf('"%s"', lblFilename));    % Should be qouted.
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, '^TABLE',       sprintf('"%s"', tabFilename));    % Should be qouted.
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, 'PRODUCT_ID',   sprintf('"%s"', fileBasename));   % Should be qouted.
    HeaderAddKvl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(HeaderAddKvl, 'FILE_RECORDS', sprintf( '%i',  LblData.nTabFileRows));
    
    LblData.HeaderKvl = EJ_lapdog_shared.utils.KVPL.merge(LblData.HeaderKvl, HeaderAddKvl);



    %=============================================
    % Construct SSL representing the LBL contents
    %=============================================
    ssl = create_SSL_header(LblData.HeaderKvl, HeaderOptions);
    ssl = add_SSL_OBJECT(ssl, 'TABLE', create_OBJ_TABLE_content(OBJTABLE_data, LblData.nTabFileRows));



    % Log message
    %fprintf(1, 'Writing LBL file: "%s"\n', lblFilePath);
    EJ_lapdog_shared.PDS_utils.write_ODL_from_struct(lblFilePath, ssl, {}, settings.indentationLength, CONTENT_MAX_ROW_LENGTH);    % endRowsList = {};
end



% Complement description of ONE column.
%
% NOTE: Function name somewhat misleading since it contains a lot of useful assertions that have nothing to do with
% complementing the columnData struct.
function [columnData, nSubcolumns] = complement_column_data(columnData, ...
        PERMITTED_OBJCOL_FIELD_NAMES, BYTES_BETWEEN_COLUMNS, PDS_IDENTIFIER_PERMITTED_CHARS, ...
        lblFilePath, tabLblInconsistencyPolicy)
    
    EMPTY_UNIT_DEFAULT = 'N/A';

    cd = columnData;

    assert(numel(cd) == 1)
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
        cd.UNIT = EMPTY_UNIT_DEFAULT;     % NOTE: Should add quotes later.
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
        warning_error___LOCAL(sprintf('Found disallowed character(s) "%s" in NAME. NAME="%s".\n   File: %s', ...
            usedDisallowedChars, cd.NAME, lblFilePath), tabLblInconsistencyPolicy)
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
function s = create_OBJ_TABLE_content(OBJTABLE_data, nTabFileRows)
    s = struct('keys', {{}}, 'values', {{}}, 'objects', {{}}) ;

    s = add_SSL(s, 'INTERCHANGE_FORMAT','%s',   'ASCII');
    s = add_SSL(s, 'ROWS',              '%d',   nTabFileRows);
    s = add_SSL(s, 'COLUMNS',           '%d',   OBJTABLE_data.COLUMNS);
    s = add_SSL(s, 'ROW_BYTES',         '%d',   OBJTABLE_data.ROW_BYTES);
    s = add_SSL(s, 'DESCRIPTION',       '"%s"', OBJTABLE_data.DESCRIPTION);

    for i = 1:length(OBJTABLE_data.OBJCOL_list)           % Iterate over list of ODL OBJECT COLUMN
        columnData = OBJTABLE_data.OBJCOL_list{i};        % cd = column OBJTABLE_data
        
        [s2, nSubcolumns] = create_OBJ_COLUMN_content(columnData);
        s = add_SSL_OBJECT(s, 'COLUMN', s2);
    end
end



% Create SSL for the content an OBJECT=COLUMN segment.
% cd : Column data struct.
function [s, nSubcolumns] = create_OBJ_COLUMN_content(cd)
    s = struct('keys', {{}}, 'values', {{}}, 'objects', {{}}) ;
    
    s = add_SSL(s, 'NAME',       '%s', cd.NAME);
    s = add_SSL(s, 'START_BYTE', '%i', cd.START_BYTE);      % Move down to ITEMS?
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



% Create SSL consisting of "header" only (section before the OBJECT = TABLE).
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
