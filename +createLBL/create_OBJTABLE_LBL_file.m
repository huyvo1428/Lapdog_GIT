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
%       .HeaderKvpl               : Key-value list describing PDS keywords in the "ODL header". Some mandatory
%                                   keywords are added automatically by the code and must not overlap with these
%                                   (assertion).
%       .OBJTABLE                 : (OBJTABLE = "OBJECT = TABLE" segment)
%                                   NOTE: Excludes COLUMNS, ROW_BYTES, ROWS which are under the OBJECT = TABLE segment
%                                   since they are are automatically derived.
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
% NOTE: The implementation will add certain keywords to LblData.HeaderKvpl, and derive the values, and assume that
% the caller has not set them. Error otherwise (assertion).
% NOTE: Uses Lapdog's obt2sct function.
% --
% NOTE: Not full general-purpose function for table files, since
%       (1) ASSUMPTION: TAB files are constructed with a fixed number of bytes between columns (and no bytes
%           before/after the first/last string).
%       (2) Does not permit FORMAT field, and there are probably other PDS-keywords which are not supported by this code.
% --
% ASSUMPTION: Metakernel (time conversion) loaded if setting timestamps from columns requiring time conversion (so far
% only STOP_TIME_from_OBT).
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
% T2PK : TAB file to (2) PDS Keyword. Functionality for retrieving LBL header PDS keyword values from TAB file.
%
function create_OBJTABLE_LBL_file(tabFilePath, LblData, HeaderOptions, Settings, tabLblInconsistencyPolicy)
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
    %           consistency check.
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
    % PROPOSAL: Read indentation length, ROSETTA_NAIF_ID, string-between-columns from createLBL.constants class.
    %   CON: Makes code less generalizable outside Lapdog.
    %   PROPOSAL: Argument settings struct which coincides with the createLBL.constants fields?!
    %       CON: Proper assertion would prevent this.
    %           CON-PROPOSAL: Superset struct assertion.
    %
    % PROPOSAL: Consistency check: always verify that begin & end timestamps fit UTC, OBT columns (if they exist).
    %   PROPOSAL: Use extra field(s) to ~always label columns for start & stop timestamps to check consistency with.
    %   CON/NOTE: May require SPICE for UTC.
    %       CON: No. String sorting is enough for comparisons (greater/smaller than).
    %       CON: Not problem since SPICE already needs to be loaded for T2PK functionality.
    %
    % PROPOSAL: Separate argument (struct) with timestamps.
    %   NOTE: CALIB_MEAS (030101) does not have any real timestamps.
    %   --
    %   PROPOSAL: Convert SCCS/SCT --> UTC or reverse.
    %   PROPOSAL: Assertion for consistency SCCS-UTC.
    %   PROPOSAL: Assertion for consistency between columns and separately specified timestamps.
    %       PROPOSAL: useFor (or useFor-like) options for specifying which columns should be used for checking.
    %   PROPOSAL: Does not have to give timestamps as UTC+SCCS. Could be UTC+OBT, or just one (automatically convert to what is missing).
    %   TODO-NEED-INFO: Is it absolutely certain that all TAB files have timestamps?
    %       These files are LBL+TAB and do not have START/STOP_TIME, or SPACECRAFT_CLOCK_STOP_TIME, but hey do have
    %       SPACECRAFT_CLOCK_START_COUNT = "N/A":
    %           CALIB/RPCLAP030101_CALIB_FINE.LBL
    %           CALIB/RPCLAP030101_CALIB_VBIAS.LBL
    %           CALIB/RPCLAP030101_CALIB_IBIAS.LBL



    %===========
    % Constants
    %===========
    D = [];
    % NOTE: Exclude START_BYTE, ITEM_OFFSET which are derived.
    % NOTE: Includes both required and optional fields.
    D.PERMITTED_OBJCOL_FIELD_NAMES   = {'NAME', 'BYTES', 'DATA_TYPE', 'UNIT', 'ITEMS', 'ITEM_BYTES', 'DESCRIPTION', 'MISSING_CONSTANT', ...
        'useFor'};
    
    % "Planetary Data Systems Standards Reference", Version 3.6, p12-11, section 12.3.4.
    % Applies to what PDS defines as identifiers, i.e. "values" without quotes.
    D.PDS_IDENTIFIER_PERMITTED_CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789';
    
    ROSETTA_NAIF_ID = -226;
    %CONTENT_MAX_ROW_LENGTH         = 79;    % Number excludes line break characters.
    CONTENT_MAX_ROW_LENGTH         = 1000;    % Number excludes line break characters.
    
    D.BYTES_BETWEEN_COLUMNS = length(', ');      % ASSUMES absence of quotes in string columns. Lapdog convention.
    BYTES_PER_LINEBREAK     = 2;                 % Carriage return + line feed.
    
    % Constants for (optionally) converting TAB file contents into PDS keywords.
    T2PK_OBT2SCCS_FUNC = @(x) obt2sctrc(str2double(x));    % No quotes. Quotes added later.
    T2PK_UTC2UTC_FUNC  = @(x) [x(1:23)];                         % Has to truncate UTC second decimals according to DVAL-NG.
    T2PK_OBT2UTC_FUNC  = @(x) [cspice_et2utc(cspice_scs2e(ROSETTA_NAIF_ID, obt2sct(str2double(x))), 'ISOC', 3)];    % 3 = 3 UTC second decimals
    T2PK_PROCESSING_TABLE = struct(...
        'argConst',   {'START_TIME',      'STOP_TIME',       'STOP_TIME_from_OBT', 'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}, ...    % Argument value (cell array component of field ".useFor").
        'pdsKeyword', {'START_TIME',      'STOP_TIME',       'STOP_TIME',          'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}, ...    % LBL file header PDS keyword which will be assigned.
        'convFunc',   {T2PK_UTC2UTC_FUNC, T2PK_UTC2UTC_FUNC, T2PK_OBT2UTC_FUNC,    T2PK_OBT2SCCS_FUNC,             T2PK_OBT2SCCS_FUNC           }, ...    % Function string-->string that is applied to the TAB file value.
        'iFlr',       {1,                 2,                 2,                    1,                              2                            });       % 1=First row, 2=Last row. FLR = First/Last Row.



    % ------------------------------------------------------
    % ASSERTIONS: Caller only uses permissible field names.
    % Useful when changing field names.
    % ------------------------------------------------------
    EJ_lapdog_shared.utils.assert.struct(LblData,          {'HeaderKvpl', 'OBJTABLE'})
    EJ_lapdog_shared.utils.assert.struct(LblData.OBJTABLE, {'DESCRIPTION', 'OBJCOL_list'})
    EJ_lapdog_shared.utils.assert.scalar(LblData.HeaderKvpl)    % Common error to initialize empty KVPL the wrong way.



    OBJTABLE_data = LblData.OBJTABLE;

    % ASSERTION: TAB file exists (needed for consistency checks).
    EJ_lapdog_shared.utils.assert.file_exists(tabFilePath)

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
    T2pkArgsTable = struct('argConst', {}, 'iByteFirst', {}, 'iByteLast', {});
    PDS_START_BYTE = 1;    % Used for deriving START_BYTE. Starts with one, not zero.
    for i = 1:length(OBJTABLE_data.OBJCOL_list)
        Cd = OBJTABLE_data.OBJCOL_list{i};       % Temporarily shorten variable name: Cd = column data
        
        % ASSERTION: Check common user/caller error.
        if numel(Cd) ~= 1
            error('One column object is a non-one size array. Guess: Due to defining .useFor value with "struct" command and ~single curly brackets. Must be double curly braces due to MATLAB syntax.')
        end
        
        [Cd, nSubcolumns] = complement_column_data(Cd, D, lblFilePath, tabLblInconsistencyPolicy);
        Cd.START_BYTE  = PDS_START_BYTE;

        % ASSERTION: Keywords do not contain quotes.
        for fnCell = fieldnames(Cd)'
            fn = fnCell{1};
            if ischar(Cd.(fn)) && ~isempty(strfind(Cd.(fn), '"'))
                error('Keyword ("%s") value contains quotes.', fn)
            end
        end

        OBJCOL_namesList{end+1} = Cd.NAME;
        %OBJTABLE_data.COLUMNS   = OBJTABLE_data.COLUMNS + nSubcolumns;    % BUG? Misunderstanding of PDS standard?!!
        OBJTABLE_data.COLUMNS   = OBJTABLE_data.COLUMNS + 1;              % CORRECT according to MB email 2018-08-08 and DVALNG. ITEMS<>1 still counts as 1 column here.
        PDS_START_BYTE = PDS_START_BYTE + Cd.BYTES + D.BYTES_BETWEEN_COLUMNS;
        
        % Collect information for T2PK functionality.
        if isfield(Cd, 'useFor')
            for iT2pk = 1:numel(Cd.useFor)    % PROPOSAL: Change name of for-loop variable.
                T2pkArgsTable(end+1).argConst   = Cd.useFor{iT2pk};
                T2pkArgsTable(end  ).iByteFirst = Cd.START_BYTE;
                T2pkArgsTable(end  ).iByteLast  = Cd.START_BYTE + Cd.BYTES - 1;
            end
        end
        
        OBJTABLE_data.OBJCOL_list{i} = Cd;      % Return updated info to original data structure.
        clear Cd
    end
    OBJTABLE_data.ROW_BYTES = (PDS_START_BYTE-1) - D.BYTES_BETWEEN_COLUMNS + BYTES_PER_LINEBREAK;   % Adds new column to struct. -1 since PDS_START_BYTE=1 refers to first byte.
    
    %################################################################################################
    
    % ---------------------------------------------------------
    % ASSERTION: Check for doubles among the ODL column names.
    % Useful for AxS.LBL files.
    % ---------------------------------------------------------
    if length(unique(OBJCOL_namesList)) ~= length(OBJCOL_namesList)
        error('Found doubles among the ODL column names.')
    end
   
    % ASSERTION: No quotes in OBJECT=TABLE DESCRIPTION keyword.
    assert_nonempty_unquoted(OBJTABLE_data.DESCRIPTION)

    %################################################################################################

    %---------------------------------------------
    % Convert TAB file contents into PDS keywords
    %---------------------------------------------
    
    % ASSERTION: Unique .useFor PDS keywords.
    if numel(unique({T2pkArgsTable.argConst})) ~= numel({T2pkArgsTable.argConst})
        error('Specified the same PDS keyword multiple times in ".useFor" fields.')
    end
    
    [junk, iT2pkArgsTable, iT2pkProcTable] = intersect({T2pkArgsTable.argConst}, {T2PK_PROCESSING_TABLE.argConst});

    % ASSERTION: Arguments only specify implemented-for argument constants.
    if numel(T2pkArgsTable) ~= numel(iT2pkProcTable)
        error('Can not find hard-coded support for at least one of the values specified in ".useFor" fields.')
    end
    
    T2pkArgsTable = T2pkArgsTable(iT2pkArgsTable);    % Potentially modify the ordering so that it is consistent with T2pkExecTable.
    T2pkExecTable = T2PK_PROCESSING_TABLE(iT2pkProcTable);
    [T2pkExecTable(:).iByteFirst] = deal(T2pkArgsTable(:).iByteFirst);
    [T2pkExecTable(:).iByteLast]  = deal(T2pkArgsTable(:).iByteLast);
    
    LblData.nTabFileRows = NaN;   % Field must be created in case deriving the value later fails.
    try
        rowStringArrayArray = {[], []};
        [rowStringArrayArray{:}, nBytesPerRow, LblData.nTabFileRows] = createLBL.analyze_TAB_file(tabFilePath, [T2pkExecTable(:).iByteFirst], [T2pkExecTable(:).iByteLast]);
        
        % ASSERTION: Number of bytes per row.
        if nBytesPerRow ~= OBJTABLE_data.ROW_BYTES
            warning_error___LOCAL(sprintf('TAB file is inconsistent with LBL file. Bytes per row does not fit table description.\n    nBytesPerRow=%g\n    OBJTABLE_data.ROW_BYTES=%g\n    File: "%s"', ...
                nBytesPerRow, OBJTABLE_data.ROW_BYTES, tabFilePath), tabLblInconsistencyPolicy)
        end
        
        T2pkKvpl.keys   = {T2pkExecTable(:).pdsKeyword};
        T2pkKvpl.values = {};
        for iT2pk = 1:numel(T2pkKvpl.keys)
            tabFileValueStr        = rowStringArrayArray{ T2pkExecTable(iT2pk).iFlr }{ iT2pk };
            T2pkKvpl.values{end+1} = T2pkExecTable(iT2pk).convFunc( tabFileValueStr );
        end
        
        % Update selected PDS keyword values.
        LblData.HeaderKvpl = EJ_lapdog_shared.utils.KVPL.overwrite_values(LblData.HeaderKvpl, T2pkKvpl, 'require preexisting keys');
    catch Exception
        warning_error___LOCAL(sprintf('TAB file "%s" is inconsistent with LBL file: "%s"', tabFilename, Exception.message), tabLblInconsistencyPolicy)
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
    
    LblData.HeaderKvpl = EJ_lapdog_shared.utils.KVPL.merge(LblData.HeaderKvpl, HeaderAddKvl);



    %=============================================
    % Construct SSL representing the LBL contents
    %=============================================
    Ssl = create_SSL_header(LblData.HeaderKvpl, HeaderOptions);
    Ssl = add_SSL_OBJECT(Ssl, 'TABLE', create_OBJ_TABLE_content(OBJTABLE_data, LblData.nTabFileRows));



    % Log message
    %fprintf(1, 'Writing LBL file: "%s"\n', lblFilePath);
    EJ_lapdog_shared.PDS_utils.write_ODL_from_struct(lblFilePath, Ssl, {}, Settings.indentationLength, CONTENT_MAX_ROW_LENGTH);    % endRowsList = {};
end



% Complement description of ONE column.
%
% NOTE: Function name somewhat misleading since it contains a lot of useful assertions that have nothing to do with
% complementing the ColumnData struct.
function [ColumnData, nSubcolumns] = complement_column_data(ColumnData, D, lblFilePath, tabLblInconsistencyPolicy)
    
    EMPTY_UNIT_DEFAULT = 'N/A';

    Cd = ColumnData;

    assert(numel(Cd) == 1)
    %---------------------------------------------------------------
    % ASSERTION: Only using permitted fields
    % --------------------------------------
    % Useful for not loosing information in optional arguments/field
    % names by misspelling, or misspelling when overwriting values,
    % or adding fields that are never used by the function.
    %---------------------------------------------------------------
    EJ_lapdog_shared.utils.assert.struct(Cd, D.PERMITTED_OBJCOL_FIELD_NAMES, 'subset')

    
    
    if isfield(Cd, 'BYTES') && ~isfield(Cd, 'ITEMS') && ~isfield(Cd, 'ITEM_BYTES')
        % CASE: Has           BYTES
        %       Does not have ITEMS, ITEM_BYTES
        nSubcolumns = 1;
    elseif ~isfield(Cd, 'BYTES') && isfield(Cd, 'ITEMS') && isfield(Cd, 'ITEM_BYTES')
        % CASE: Does not have BYTES
        %       Has           ITEMS, ITEM_BYTES
        nSubcolumns    = Cd.ITEMS;
        Cd.ITEM_OFFSET = Cd.ITEM_BYTES + D.BYTES_BETWEEN_COLUMNS;
        Cd.BYTES       = nSubcolumns * Cd.ITEM_BYTES + (nSubcolumns-1) * D.BYTES_BETWEEN_COLUMNS;
    else
        warning_error___LOCAL(sprintf('Found disallowed combination of BYTES/ITEMS/ITEM_BYTES. NAME="%s". ABORTING creation of LBL file', Cd.NAME), tabLblInconsistencyPolicy)
        return   % NOTE: ABORTING & EXITING to avoid causing further errors.
    end

    %------------
    % Check UNIT
    %------------
    if isempty(Cd.UNIT)
        Cd.UNIT = EMPTY_UNIT_DEFAULT;     % NOTE: Should add quotes later.
    end    
    % ASSERTIONS
    % Check for presence of "raised minus" in UNIT.
    % This is a common typo when writing cm^-3 which then becomes cm⁻3.
    if any(strfind(Cd.UNIT, '⁻'))
        warning_error___LOCAL(sprintf('Found "raised minus" in UNIT. This is assumed to be a typo. NAME="%s"; UNIT="%s"', Cd.NAME, Cd.UNIT), tabLblInconsistencyPolicy)
    end        
    assert_nonempty_unquoted(Cd.UNIT)

    %------------
    % Check NAME
    %------------
    % ASSERTION: Not empty.
    if isempty(Cd.NAME)
        error('ERROR: Trying to use empty value for NAME.')
    end
    % ASSERTION: Only uses permitted characters.
    usedDisallowedChars = setdiff(Cd.NAME, D.PDS_IDENTIFIER_PERMITTED_CHARS);
    if ~isempty(usedDisallowedChars)
        % NOTE 2016-07-22: The NAME value that triggers this error may come from a CALIB LBL file produced by pds, NAME = P1-P2_CURRENT/VOLTAGE.
        % pds should no longer produce this kind of LBL files since they violate the PDS standard but they may still occur in old data sets.
        % Therefore, there is also value in printing the file name since the user can then (maybe) determine if that is true.
        warning_error___LOCAL(sprintf('Found disallowed character(s) "%s" in NAME. NAME="%s".\n   File: %s', ...
            usedDisallowedChars, Cd.NAME, lblFilePath), tabLblInconsistencyPolicy)
    end

    %-------------------
    % Check DESCRIPTION
    %-------------------
    if isempty(Cd.DESCRIPTION)
        Cd.DESCRIPTION = 'N/A';   % NOTE: Quotes are added later.
    end
    % ASSERTION: Does not contain quotes.    
    assert_nonempty_unquoted(Cd.DESCRIPTION)

    ColumnData = Cd;
end



% Create SSL for the content of the OBJECT=TABLE segment.
function Ssl = create_OBJ_TABLE_content(OBJTABLE_data, nTabFileRows)
    S = struct('keys', {{}}, 'values', {{}}, 'objects', {{}}) ;

    S = add_SSL(S, 'INTERCHANGE_FORMAT','%s',   'ASCII');
    S = add_SSL(S, 'ROWS',              '%d',   nTabFileRows);
    S = add_SSL(S, 'COLUMNS',           '%d',   OBJTABLE_data.COLUMNS);
    S = add_SSL(S, 'ROW_BYTES',         '%d',   OBJTABLE_data.ROW_BYTES);
    S = add_SSL(S, 'DESCRIPTION',       '"%s"', OBJTABLE_data.DESCRIPTION);

    for i = 1:length(OBJTABLE_data.OBJCOL_list)           % Iterate over list of ODL OBJECT COLUMN
        ColumnData = OBJTABLE_data.OBJCOL_list{i};        % Cd = column OBJTABLE_data
        
        [S2, nSubcolumns] = create_OBJ_COLUMN_content(ColumnData);
        S = add_SSL_OBJECT(S, 'COLUMN', S2);
    end
    
    Ssl = S;
end



% Create SSL for the content an OBJECT=COLUMN segment.
% Cd : Column data struct.
function [Ssl, nSubcolumns] = create_OBJ_COLUMN_content(Cd)
    S = struct('keys', {{}}, 'values', {{}}, 'objects', {{}}) ;
    
    S = add_SSL(S, 'NAME',       '%s', Cd.NAME);
    S = add_SSL(S, 'START_BYTE', '%i', Cd.START_BYTE);      % Move down to ITEMS?
    S = add_SSL(S, 'BYTES',      '%i', Cd.BYTES);            % Move down to ITEMS?
    S = add_SSL(S, 'DATA_TYPE',  '%s', Cd.DATA_TYPE);
    
    if isfield(Cd, 'UNIT')
        S = add_SSL(S, 'UNIT', '"%s"', Cd.UNIT);
    end
    if isfield(Cd, 'ITEMS')
        S = add_SSL(S, 'ITEMS',       '%i', Cd.ITEMS);
        S = add_SSL(S, 'ITEM_BYTES',  '%i', Cd.ITEM_BYTES);
        S = add_SSL(S, 'ITEM_OFFSET', '%i', Cd.ITEM_OFFSET);
        nSubcolumns = Cd.ITEMS;
    else
        nSubcolumns = 1;
    end
    S = add_SSL(S, 'DESCRIPTION', '"%s"', Cd.DESCRIPTION);      % NOTE: Added quotes.
    if isfield(Cd, 'MISSING_CONSTANT')
        S = add_SSL(S, 'MISSING_CONSTANT', '%f', Cd.MISSING_CONSTANT);
    end
    
    Ssl = S;
end



function Ssl = add_SSL(Ssl, key, pattern, value)
    Ssl.keys   {end+1} = key;
    Ssl.values {end+1} = sprintf(pattern, value);
    Ssl.objects{end+1} = [];
end

function Ssl = add_SSL_OBJECT(Ssl, objectValue, sslObjectContents)
    Ssl.keys   {end+1} = 'OBJECT';
    Ssl.values {end+1} = objectValue;
    Ssl.objects{end+1} = sslObjectContents;
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
% NOTE: Always interprets Kvpl.value{i} as (matlab) string, not number.
%
%
% RATIONALE: ORDERING OF KEYS
% ===========================
% 1) to make LBL files more "beautiful" (e.g. P1 before P2 keywords,
%    non-ROSETTA before ROSETTA keywords), and
% 2) to ensure that LBL keywords are always in approximately the same order.
%    This is useful when comparing datasets to ensure that a modified/updated
%    lapdog code produces only the desired changes to LBL files.
function Ssl = create_SSL_header(Kvpl, HeaderOptions)   % Kvpl = key-value pair list
    % PROPOSAL: Assert that all KEY_ORDER_LIST keys are unique.
    % PROPOSAL: Should set keywords that apply to all LBL/CAT files (not just OBJECT=TABLE).
    %    Ex: PDS_VERSION_ID
    %
    % PROPOSAL: Determine which keywords should or should not have quotes. Force parameter values to not have quotes.
    %    CON: Another long list which might not capture all keywords.

    % ASSERTION: Parameter error check
    if isempty(Kvpl.keys)                    % Not sure why checks for this specifically. Previously checked before calculating maxKeyLength.
        error('Kvpl.keys is empty.')
    end
    if length(unique(Kvpl.keys)) ~= length(Kvpl.keys)
        error('Found doubles among the keys/ODL attribute names.')
    end



    % Order keys.
    Kvpl = EJ_lapdog_shared.utils.KVPL.order_by_key_list(Kvpl, HeaderOptions.keyOrderList);

    % ASSERTION: Check that there are no forbidden keys.
    for i=1:length(HeaderOptions.forbiddenKeysList)
        if any(strcmp(HeaderOptions.forbiddenKeysList{i}, Kvpl.keys))
            error('Trying to write LBL file header with explicitly forbidden LBL keyword "%s". This indicates that the code has previously failed to substitute these keywords for new ones.', ...
                HeaderOptions.forbiddenKeysList{i})
        end
    end

    % Force certain key values to be quoted.
    for j = 1:length(Kvpl.keys)
        key   = Kvpl.keys{j};
        value = Kvpl.values{j};

        % ASSERTION
        if ~ischar(value)
            error('(key-) value is not a MATLAB string:\n key = "%s", fopen(fid) = "%s"', key, fopen(fid))
        end

        if ismember(key, HeaderOptions.forceQuotesKeysList) && ~any('"' == value)
            Kvpl.values{j} = ['"', value, '"'];
        end
    end
    
    Ssl = struct('keys', {Kvpl.keys}, 'values', {Kvpl.values}, 'objects', {cell(size(Kvpl.keys))});
    
end
