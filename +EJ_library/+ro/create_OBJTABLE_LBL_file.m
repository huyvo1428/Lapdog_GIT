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
%                                   (Optional by PDS; required here)
%               .DESCRIPTION      : Replaced by standardized default value if empty. Must not contains quotes.
%                                   (Automatically quoted.)
%               .MISSING_CONSTANT : Optional
%               Either (1)
%           	  .BYTES
%               or (2)
%                 .ITEMS
%                 .ITEM_BYTES
%               .DATA_SET_PARAMETER_NAME : Cell array of values.
%               .CALIBRATION_SOURCE_ID   : Cell array of values.
%               .useFor           : Optional. Cell array of strings representing LBL header PDS keywords. Code
%                                   contains hardcoded info on how to extract the corresponding keyword values
%                                   from the corresponding column.
%                                   Permitted:
%                                       START_STOP, STOP_TIME             : Must be UTC column (at least 3 decimals).
%                                       SPACECRAFT_CLOCK_START/STOP_COUNT : Must be OBT column.
%                                       STOP_TIME_from_OBT                : Must be OBT column.
%               .preBytes         : Number of bytes to add before column data. Optional. Zero used if not present.
%               .postBytes        : Number of bytes to add after  column data. Optional. Zero used if not present.
% varargin : Settings as interpreted by EJ_library.utils.interpret_settings_args.
%   OPTIONAL:
%   .indentationLength          :
%   .tabLblInconsistencyPolicy  : 'warning', 'error', or 'nothing'.
%                                 Determines how to react in the event of inconsistencies between LBL and TAB file.
%                                 NOTE: Function may abort in case of 'warning'/'nothing' if it can not recover.
%   .spacecraftNaifSpiceId      : 
%   .nBytesBetweenColumns       : Number of bytes to add between every column of actual data in TAB file.
%                                 NOTE: Most RPCLAP data uses 2 bytes, but some calibration data uses 1 byte.
%   .tablePointerPdsKey
%   REQUIRED:
%   .headerKeysForbiddenList    : Cell array of ODL header keys that must not be present (assertion).
%   .headerKeysForceQuotesList  : Cell array of ODL header keys that will be quoted, but only if not already quoted.
%   .headerKeysOrderList        : Cell array of ODL header keys that specifies the order of the first keys (when present).
% --
% preBytes, postBytes, nBytesBetweenColumns are all added together to obtain the number of bytes between columns.
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
% NOTE: Is not a full general-purpose function for table files, since
%       (1) ASSUMPTION: TAB files are constructed with a fixed number of bytes between columns (and no bytes
%           before/after the first/last string).
%       (2) Does not permit FORMAT field, and there are probably other PDS-keywords which are not supported by this code.
% --
% ASSUMPTION: Metakernel (time conversion) is loaded if setting timestamps from columns requiring time conversion (so
% far only STOP_TIME_from_OBT).
%
%
% IMPLEMENTATION NOTES
% ====================
% This function could possibly be useful outside of Lapdog (like in EJ's Lapsus code). It should therefore avoid
% calling Lapdog-specific code, e.g. createLBL.constants.
%
%
% NAMING CONVENTIONS
% ==================
% T2PK : TAB file to ("2") PDS Keyword. Functionality for retrieving LBL header PDS keyword values from TAB file.
%
function create_OBJTABLE_LBL_file(tabFilePath, LblData, varargin)
    %
    % NOTE: CONCEIVABLE LBL FILE SPECIAL CASES that may have different requirements:
    %    - Data files (DATA/)
    %    - Block lists   (Does require SPACECRAFT_CLOCK_START_COUNT etc.)
    %    - Geometry files
    %    - HK files
    %    - INDEX.LBL   => Does not require SPACECRAFT_CLOCK_START_COUNT etc.
    %    - Browse index ==> inter-column distance <>4? Varying?
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
    %
    % PROPOSAL/TODO: Check that ~assertion on trying to write non-string key values (HeaderKvpl) to file.
    %   PRO: Can use this to set temporary values in HeaderKvpl which must be overwritten somewhere else in Lapdog.
    %
    % PROPOSAL: Change .iByteLast --> .iByteLength



    DEFAULT_SETTINGS = [];
    DEFAULT_SETTINGS.tabLblInconsistencyPolicy = 'error';
    DEFAULT_SETTINGS.contentRowMaxLength       = 80-2;            % Number excludes line break characters.
    DEFAULT_SETTINGS.formatNotDerivedValue     = '<UNSET>';       % Value used to replace FORMAT, when setting automatically fails.
    DEFAULT_SETTINGS.emptyUnitDefault          = 'N/A';           % Value used to replace empty UNIT value.
    DEFAULT_SETTINGS.nBytesBetweenColumns      = length(', ');    % ASSUMES absence of quotes in string columns. Lapdog convention.
    DEFAULT_SETTINGS.spacecraftNaifSpiceId     = -226;            % Rosetta.
    DEFAULT_SETTINGS.indentationLength         = 4;
    DEFAULT_SETTINGS.tablePointerPdsKey        = '^TABLE';        % ABLE for regular data products, but ^INDEX_TABLE for PDS indexes.
    Settings = EJ_library.utils.interpret_settings_args(DEFAULT_SETTINGS, varargin);
    EJ_library.utils.assert.struct(Settings, union(fieldnames(DEFAULT_SETTINGS), ...
        {'headerKeysOrderList', 'headerKeysForceQuotesList', 'headerKeysForbiddenList'}))
    


    %====================
    % Internal constants
    %====================
    D = [];
    
    % NOTE: Includes both REQUIRED and OPTIONAL fields.
    % NOTE: Exclude START_BYTE, ITEM_OFFSET which are derived.
    D.PERMITTED_OBJCOL_FIELD_NAMES = {...
        'NAME', 'BYTES', 'DATA_TYPE', 'UNIT', 'ITEMS', 'ITEM_BYTES', 'DESCRIPTION', ...
        'MISSING_CONSTANT', 'DATA_SET_PARAMETER_NAME', 'CALIBRATION_SOURCE_ID', ...
        'useFor', 'preBytes', 'postBytes'};
    
    % "Planetary Data Systems Standards Reference", Version 3.6, p12-11, section 12.3.4.
    % Applies to what PDS defines as identifiers, i.e. "values" without quotes.
    D.PDS_IDENTIFIER_PERMITTED_CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789';
    
    D.BYTES_PER_LINEBREAK   = 2;                 % Carriage return + line feed.
    
    % Constants for (optionally) converting TAB file contents into PDS keywords.
    T2PK_OBT2SCCS_FUNC = @(x) obt2sctrc(str2double(x));    % No quotes. Quotes added later.
    T2PK_UTC2UTC_FUNC  = @(x) [x(1:23)];                   % Has to truncate UTC second decimals according to DVAL-NG.
    T2PK_OBT2UTC_FUNC  = @(x) [cspice_et2utc(cspice_scs2e(Settings.spacecraftNaifSpiceId, obt2sct(str2double(x))), 'ISOC', 3)];    % 3 = 3 UTC second decimals
    D.T2PK_PROCESSING_TABLE = struct(...
        'argConst',   {'START_TIME',      'STOP_TIME',       'STOP_TIME_from_OBT', 'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}, ...    % Argument value (cell array component of field ".useFor").
        'pdsKeyword', {'START_TIME',      'STOP_TIME',       'STOP_TIME',          'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}, ...    % LBL file header PDS keyword which will be assigned.
        'convFunc',   {T2PK_UTC2UTC_FUNC, T2PK_UTC2UTC_FUNC, T2PK_OBT2UTC_FUNC,    T2PK_OBT2SCCS_FUNC,             T2PK_OBT2SCCS_FUNC           }, ...    % Function string-->string that is applied to the TAB file value.
        'iFlr',       {1,                 2,                 2,                    1,                              2                            });       % 1/2=First/last TAB row. FLR = First/Last Row.



    % ------------------------------------------------------
    % ASSERTIONS: Caller only uses permissible field names.
    % Useful when changing field names.
    % ------------------------------------------------------
    EJ_library.utils.assert.struct(LblData,          {'HeaderKvpl', 'OBJTABLE'})
    EJ_library.utils.assert.struct(LblData.OBJTABLE, {'DESCRIPTION', 'OBJCOL_list'})
    EJ_library.utils.assert.scalar(LblData.HeaderKvpl)    % Common error to initialize empty KVPL the wrong way.



    % ASSERTION: TAB file exists (needed for consistency checks).
    EJ_library.utils.assert.file_exists(tabFilePath)

    %################################################################################################

    % Extract useful information from TAB file path.
    [filePath, fileBasename, tabFileExt] = fileparts(tabFilePath);
    tabFilename = [fileBasename, tabFileExt];
    lblFilename = [fileBasename, '.LBL'];
    lblFilePath = fullfile(filePath, lblFilename);
    
    
    
    % IMPLEMENTATION NOTE: Catches exceptions from large parts of code to add context (e.g. LBL file) to the original
    % exception. "Requires" that calling code prints exception causes recursively to easily understand the error though.
    try
        [LblData.OBJTABLE, T2pkArgsTable] = adjust_extract_OBJECT_TABLE_data(LblData.OBJTABLE, Settings, D);
        
        %==========================================
        % Extract data from TAB file (+assertions)
        %==========================================
        % IMPLEMENTATION NOTE: Needs try-catch here to determine whether read_TAB_file_info succeeded or not, since the
        % code/function should not automatically exit if it does fail.
        try
            LblData.nTabFileRows = NaN;   % Field must be created in case deriving the value later fails.
            [firstTabRow, lastTabRow, nBytesPerTabRow, LblData.nTabFileRows] = read_TAB_file_info(tabFilePath);
            readingTabSuccessful = true;
        catch Exc
            warning_error___LOCAL(Exc, Settings.tabLblInconsistencyPolicy)
            readingTabSuccessful = false;
        end
        
        %=============================================
        % Continue extracting data from TAB file data
        %=============================================
        if readingTabSuccessful
            % IMPLEMENTATION NOTE: Does not put the following code (in the "if" statement) inside the same try statement
            % that sets readingTabSuccessful since we want errors here to NOT be caught.
            
            % ASSERTION: Number of bytes per TAB row.
            if nBytesPerTabRow ~= LblData.OBJTABLE.ROW_BYTES
                warning_error___LOCAL(sprintf(...
                    ['TAB file is inconsistent with LBL file. Bytes per row does not fit table description.\n', ...
                    '    nBytesPerTabRow=%g\n    LblData.OBJTABLE.ROW_BYTES=%g\n', ...
                    '    File: "%s"'], ...
                    nBytesPerTabRow, LblData.OBJTABLE.ROW_BYTES, tabFilePath), Settings.tabLblInconsistencyPolicy)
            end
            
            % Set FORMAT.
            for iOBJCOL = 1:numel(LblData.OBJTABLE.OBJCOL_list)
                LblData.OBJTABLE.OBJCOL_list{iOBJCOL}.FORMAT = derive_FORMAT(...
                    LblData.OBJTABLE.OBJCOL_list{iOBJCOL}, firstTabRow, lastTabRow, Settings.tabLblInconsistencyPolicy);
            end
            
            T2pkKvpl = derive_T2PK_KVPL(firstTabRow, lastTabRow, T2pkArgsTable, D);
            
            % Update selected PDS keyword values.
            LblData.HeaderKvpl = LblData.HeaderKvpl.overwrite_subset(T2pkKvpl);
            
        end



        %===================================================================
        % Add keywords to the LBL "header" (before first OBJECT statement).
        %===================================================================
        LblData.HeaderKvpl = LblData.HeaderKvpl.append(EJ_library.utils.KVPL2({...
            'RECORD_TYPE',  'FIXED_LENGTH'; ...                  % NOTE: Influences whether one must use RECORD_BYTES, FILE_RECORDS, LABEL_RECORDS.
            'RECORD_BYTES',              sprintf( '%i',  LblData.OBJTABLE.ROW_BYTES); ...
            'FILE_NAME',                 sprintf('"%s"', lblFilename); ...    % Should be qouted.
            Settings.tablePointerPdsKey, sprintf('"%s"', tabFilename); ...    % Should be qouted.
            'PRODUCT_ID',                sprintf('"%s"', fileBasename); ...   % Should be qouted.
            'FILE_RECORDS',              sprintf( '%i',  LblData.nTabFileRows) ...
            }));   % Order not important since later reordered.
        
        
        
        %=============================================
        % Construct SSL representing the LBL contents
        %=============================================
        Ssl = create_SSL_header(LblData.HeaderKvpl, Settings);
        Ssl = add_SSL_OBJECT(Ssl, 'TABLE', create_OBJ_TABLE_content(LblData.OBJTABLE, LblData.nTabFileRows));
        
        
        
        % Log message
        %fprintf(1, 'Writing LBL file: "%s"\n', lblFilePath);
        EJ_library.PDS_utils.write_ODL_file(lblFilePath, Ssl, {}, Settings.indentationLength, Settings.contentRowMaxLength);    % endRowsList = {};
        
    catch Exc
        NewExc = MException('create_OBJTABLE_LBL_file:fail', sprintf('Something wrong with OBJECT=TABLE data. lblFilePath=%s', lblFilePath));
        NewExc = addCause(NewExc, Exc);
        %Exc.getReport()
        throw(NewExc)
    end
end



% Derive the value of the FORMAT keyword using other PDS keywords and the first and last TAB file row.
%
% Implicitly also checks some of the TAB file format through assertions in EJ_library.PDS_utils.derive_FORMAT.
function FORMAT = derive_FORMAT(OBJCOL, firstTabRow, lastTabRow, tabLblInconsistencyPolicy)
    % Derive nBytes taking into account the possibility of multiple columns per OBJECT=COLUMN (only use the first one).
    if isfield(OBJCOL, 'ITEM_BYTES')
        nBytes = OBJCOL.ITEM_BYTES;
    else
        nBytes = OBJCOL.BYTES;
    end
    
    tabValueStr1  = firstTabRow(OBJCOL.START_BYTE : (OBJCOL.START_BYTE+nBytes-1));
    tabValueStr2  = lastTabRow( OBJCOL.START_BYTE : (OBJCOL.START_BYTE+nBytes-1));
    
    FORMAT_1 = EJ_library.PDS_utils.derive_FORMAT(tabValueStr1, OBJCOL.DATA_TYPE, nBytes);    
    FORMAT_2 = EJ_library.PDS_utils.derive_FORMAT(tabValueStr2, OBJCOL.DATA_TYPE, nBytes);
    
    % ASSERTION
    if ~strcmp(FORMAT_1, FORMAT_2)
        warning_error___LOCAL('First and last TAB row imply different values for FORMAT.', tabLblInconsistencyPolicy)
    end
    
    FORMAT = FORMAT_1;
end



% Adjust OBJECT=TABLE data and extract some data from it
% 
% Calculates COLUMNS, START_BYTE, ROW_BYTES. Assertions.
%
function [OBJTABLE_data, T2pkArgsTable] = adjust_extract_OBJECT_TABLE_data(OBJTABLE_data, Settings, D)

    assert(numel(OBJTABLE_data.OBJCOL_list) >= 0)
    
    
    
    OBJTABLE_data.COLUMNS = 0;   % NOTE: Adds new field to structure.
    OBJCOL_namesList      = {};
    T2pkArgsTable         = struct('argConst', {}, 'iByteFirst', {}, 'iByteLast', {});
    
    % Index to starting row byte (as PDS counts them) of the current "padded" column, i.e. including .preBytes and .postBytes.
    % PDS row byte indexing starts with one, not zero.
    paddedColStartByte    = 1;
    
    for i = 1:length(OBJTABLE_data.OBJCOL_list)
        Cd = OBJTABLE_data.OBJCOL_list{i};       % Temporarily shorten variable name: Cd = column data

        % ASSERTION: Check common user/caller error.
        if numel(Cd) ~= 1
            error(['One column struct is a non-one size array. Guess: Caller has definied struct using the "struct"', ...
                ' command and set a field value using cell array(s) using ~single curly brackets instead of double curly brackets.'])
        end

        Cd = adjust_OBJECT_COLUMN_data(Cd, Settings, D);
        %Cd.START_BYTE  = paddedColStartByte;
        Cd.START_BYTE  = paddedColStartByte + Cd.preBytes;

        OBJCOL_namesList{end+1} = Cd.NAME;
        OBJTABLE_data.COLUMNS   = OBJTABLE_data.COLUMNS + 1;              % CORRECT according to MB email 2018-08-08 and DVALNG. ITEMS<>1 still counts as 1 column here.
        
        % Set where the next column should start counting bytes.
        %paddedColStartByte = paddedColStartByte + Cd.BYTES + Settings.nBytesBetweenColumns;
        paddedColStartByte = Cd.START_BYTE + Cd.BYTES + Cd.postBytes + Settings.nBytesBetweenColumns;
        
        %============================================
        % Collect information for T2PK functionality
        %============================================
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
    %OBJTABLE_data.ROW_BYTES = (paddedColStartByte-1) - Settings.nBytesBetweenColumns + D.BYTES_PER_LINEBREAK;   % Adds new column to struct. -1 since PDS_START_BYTE=1 refers to first byte.
    OBJTABLE_data.ROW_BYTES = (paddedColStartByte-1) - Settings.nBytesBetweenColumns + D.BYTES_PER_LINEBREAK;   % Adds new column to struct. -1 since PDS_START_BYTE=1 refers to first byte.
    
    %################################################################################################
    
    % ---------------------------------------------------------
    % ASSERTION: Check for doubles among the ODL column names.
    % Useful for AxS.LBL files.
    % ---------------------------------------------------------
    EJ_library.utils.assert.castring_set(OBJCOL_namesList)
   
    % ASSERTION: No quotes in OBJECT=TABLE DESCRIPTION keyword.
    assert_nonempty_unquoted(OBJTABLE_data.DESCRIPTION)
end



% Adjust the description of ONE column OBJECT.
% by setting default values (UNIT, DESCRIPTION) when none exists, setting FORMAT (preliminary value later overwritten),
% and deriving values (ITEMS, ITEM_BYTES).
%
% NOTE: Function name somewhat misleading since it contains a lot of useful assertions besides "adjusting".
%
function [ColumnData] = adjust_OBJECT_COLUMN_data(ColumnData, Settings, D)
    
    % Shorten variable name.
    Cd = ColumnData;
    clear ColumnData

    % ASSERTIONS
    assert(numel(Cd) == 1)
    %================================================================
    % ASSERTION: Only using permitted fields
    % --------------------------------------
    % Useful for not loosing information in optional arguments/field
    % names by misspelling, or misspelling when overwriting values,
    % or adding fields that are never used by the function.
    %================================================================
    EJ_library.utils.assert.struct(Cd, D.PERMITTED_OBJCOL_FIELD_NAMES, 'subset')    
    
    
    
    %==========================================
    % .preBytes and .postBytes: Default values
    %==========================================
    if ~isfield(Cd, 'preBytes')
        Cd.preBytes = 0;
    end
    if ~isfield(Cd, 'postBytes')
        Cd.postBytes = 0;
    end

    

    %========================================================================================
    % Handle (and assert) the cases of the OBJECT=COLUMN describing
    %   (1) one column, or
    %   (2) multiple columns.
    %========================================================================================
    if isfield(Cd, 'BYTES') && ~isfield(Cd, 'ITEMS') && ~isfield(Cd, 'ITEM_BYTES')
        % CASE: Has           BYTES
        %       Does not have ITEMS, ITEM_BYTES
    elseif ~isfield(Cd, 'BYTES') && isfield(Cd, 'ITEMS') && isfield(Cd, 'ITEM_BYTES')
        % CASE: Does not have BYTES
        %       Has           ITEMS, ITEM_BYTES
        nSubcolumns          = Cd.ITEMS;
        %Cd.ITEM_OFFSET = Cd.ITEM_BYTES + Settings.nBytesBetweenColumns;
        nBytesBetweenColumns = Cd.preBytes + Settings.nBytesBetweenColumns + Cd.postBytes;
        Cd.ITEM_OFFSET       = Cd.ITEM_BYTES + nBytesBetweenColumns;
        Cd.BYTES             = nSubcolumns * Cd.ITEM_BYTES + (nSubcolumns-1) * Settings.nBytesBetweenColumns;
    else
        error('Found disallowed combination of present fields BYTES/ITEMS/ITEM_BYTES. NAME="%s". ABORTING creation of LBL file', Cd.NAME)
    end

    

    %=================================
    % UNIT: Default value, assertions
    %=================================
    if isempty(Cd.UNIT)
        Cd.UNIT = Settings.emptyUnitDefault;     % NOTE: Should add quotes later.
    end    
    % ASSERTIONS
    % Check for presence of "raised minus" in UNIT.
    % This is a common typo when writing cm^-3 which then becomes cm⁻3.
    if any(strfind(Cd.UNIT, '⁻'))
        error('Found "raised minus" in UNIT. This is assumed to be a typo. NAME="%s"; UNIT="%s"', Cd.NAME, Cd.UNIT)
    end        
    assert_nonempty_unquoted(Cd.UNIT)

    
    
    %==================
    % NAME: Assertions
    %==================
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
        error('Found disallowed character(s) "%s" in NAME. NAME="%s".', ...
            usedDisallowedChars, Cd.NAME)
    end

    
    
    %=======================================
    % DESCRIPTION: Default value, assertion
    %=======================================
    if isempty(Cd.DESCRIPTION)
        % NOTE: Quotes are added later. 
        Cd.DESCRIPTION = 'N/A';
    end
    % ASSERTION: Does not contain quotes.    
    assert_nonempty_unquoted(Cd.DESCRIPTION)



    %============
    % Set FORMAT
    %============
    % Add unset FORMAT field in case reading TAB file does not work but error/warning policy permits the code to continue.
    Cd.FORMAT = Settings.formatNotDerivedValue;

    
    
    % ASSERTION: OBJECT=COLUMN keywords do not contain quotes.
    for fnCell = fieldnames(Cd)'
        fn = fnCell{1};
        if ischar(Cd.(fn)) && ~isempty(strfind(Cd.(fn), '"'))
            error('Keyword ("%s") value contains quotes.', fn)
        end
    end

    ColumnData = Cd;
end



% NOTE: Does not work for files with first row consisting of header variable names, e.g. AxS.
function [firstRow, lastRow, nBytesPerRow, nRows] = read_TAB_file_info(tabFile)
    temp     = dir(tabFile);
    fileSize = temp.bytes;

    % ASSERTION
    if fileSize == 0
        error('Empty TAB file (0 bytes). Can not analyze. Data set must not contain empty files.\n    File: "%s"', tabFile)
    end
    
    % Read first and last row of file.
    % NOTE: Strings include trailing CR+LF.
    firstRow = EJ_library.utils.read_first_file_row(tabFile);
    lastRow  = EJ_library.utils.read_last_file_row(tabFile);
    
    % ASSERTION
    if length(firstRow) ~= length(lastRow)
        error('First and last row of TAB file have different lengths.\n    File: "%s"\n    First row: "%s"\n    Last row:  "%s"', tabFile, firstRow, lastRow)
    end

    nBytesPerRow = length(firstRow);

    % ASSERTION: Row length & number of rows match.
    if rem(fileSize, nBytesPerRow) ~= 0
        % CASE: Error has occurred.
        msg = sprintf(['TAB file appears to not have rows of uniform length. File size is NOT an integer multiple of the first/last rows length:\n', ...
            '    File: "%s"\n', ...
            '    fileSize                 = %g\n', ...
            '    nBytesPerRow             = %g'], ...
            tabFile, fileSize, nBytesPerRow);
        error(msg)
    end
    
    nRows = round(fileSize / nBytesPerRow);
end



% Use TAB file contents to assign PDS keywords.
%
function T2pkKvpl = derive_T2PK_KVPL(firstTabRow, lastTabRow, T2pkArgsTable, D)
        
        % ASSERTION: Caller never uses the same .useFor{i} twice.
        % NOTE: Not foolproof, since the same PDS keywords can be set by multiple .useFor{i} values. See later assertion.
        EJ_library.utils.assert.castring_set({T2pkArgsTable.argConst})
        
        [junk, iT2pkArgsTable, iT2pkProcTable] = intersect({T2pkArgsTable.argConst}, {D.T2PK_PROCESSING_TABLE.argConst});
        
        % ASSERTION: Arguments only specify implemented-for argument constants.
        %            ({T2pkArgsTable.argConst} is a subset of {D.T2PK_PROCESSING_TABLE.argConst}.)
        if numel(T2pkArgsTable) ~= numel(iT2pkProcTable)
            error('Can not find hard-coded support for at least one of the values specified in ".useFor" fields.')
        end
        
        % Reduce the size of tables (only keep specified indices) and modify the ordering so that they are consistent with each other.
        T2pkArgsTable = T2pkArgsTable(iT2pkArgsTable);
        T2pkExecTable = D.T2PK_PROCESSING_TABLE(iT2pkProcTable);
        
        % ASSERTION: Set every PDS keyword (at most) once.
        EJ_library.utils.assert.castring_set({T2pkExecTable.pdsKeyword})
        
        % Add/transfer fields T2pkArgsTable-->T2pkExecTable for "overlapping" argConst values so that everything needed is
        % in a single table.
        [T2pkExecTable(:).iByteFirst] = deal(T2pkArgsTable(:).iByteFirst);
        [T2pkExecTable(:).iByteLast]  = deal(T2pkArgsTable(:).iByteLast);
        
        rowStringArrayArray = {[], []};
        rowStringArrayArray{1} = extract_strings(firstTabRow, [T2pkExecTable(:).iByteFirst], [T2pkExecTable(:).iByteLast]);
        rowStringArrayArray{2} = extract_strings(lastTabRow,  [T2pkExecTable(:).iByteFirst], [T2pkExecTable(:).iByteLast]);
        
        T2pkKvpl_keys   = {T2pkExecTable(:).pdsKeyword};
        T2pkKvpl_values = {};
        for iT2pk = 1:numel(T2pkKvpl_keys)
            tabFileValueStr        = rowStringArrayArray{ T2pkExecTable(iT2pk).iFlr }{ iT2pk };
            T2pkKvpl_values{end+1} = T2pkExecTable(iT2pk).convFunc( tabFileValueStr );
        end
        T2pkKvpl = EJ_library.utils.KVPL2(T2pkKvpl_keys, T2pkKvpl_values);    
end



function [stringArray] = extract_strings(s, iFirstByteArray, iLastByteArray)
    stringArray = {};
    
    for i = 1:numel(iFirstByteArray)
        stringArray{i} = s(iFirstByteArray(i):iLastByteArray(i));
    end
end



% Create SSL for the content of the OBJECT=TABLE segment.
function Ssl = create_OBJ_TABLE_content(OBJTABLE_data, nTabFileRows)
    S = struct('keys', {{}}, 'values', {{}}, 'objects', {{}}) ;

    S = add_SSL_form(S, 'INTERCHANGE_FORMAT','%s',   'ASCII');
    S = add_SSL_form(S, 'ROWS',              '%d',   nTabFileRows);
    S = add_SSL_form(S, 'COLUMNS',           '%d',   OBJTABLE_data.COLUMNS);
    S = add_SSL_form(S, 'ROW_BYTES',         '%d',   OBJTABLE_data.ROW_BYTES);
    S = add_SSL_form(S, 'DESCRIPTION',       '"%s"', OBJTABLE_data.DESCRIPTION);

    for i = 1:length(OBJTABLE_data.OBJCOL_list)           % Iterate over list of ODL OBJECT COLUMN
        ColumnData = OBJTABLE_data.OBJCOL_list{i};        % Cd = column OBJTABLE_data
        
        S2 = create_OBJ_COLUMN_content(ColumnData);
        S = add_SSL_OBJECT(S, 'COLUMN', S2);
    end
    
    Ssl = S;
end



% Create SSL for the content an OBJECT=COLUMN segment.
% Cd : Column data struct.
function [Ssl] = create_OBJ_COLUMN_content(Cd)
    S = struct('keys', {{}}, 'values', {{}}, 'objects', {{}}) ;
    
    S = add_SSL_form(S, 'NAME',        '%s',  Cd.NAME);
    S = add_SSL_form(S, 'START_BYTE',  '%i',  Cd.START_BYTE);        % Move down to ITEMS?
    S = add_SSL_form(S, 'BYTES',       '%i',  Cd.BYTES);             % Move down to ITEMS?
    S = add_SSL_form(S, 'DATA_TYPE',   '%s',  Cd.DATA_TYPE);    
    S = add_SSL_form(S, 'FORMAT',     '"%s"', Cd.FORMAT);            % Empirically (pvv label), needs to be quoted if value contains period.
    
    if isfield(Cd, 'UNIT')
        S = add_SSL_form(S, 'UNIT', '"%s"', Cd.UNIT);
    end
    if isfield(Cd, 'ITEMS')
        S = add_SSL_form(S, 'ITEMS',       '%i', Cd.ITEMS);
        S = add_SSL_form(S, 'ITEM_BYTES',  '%i', Cd.ITEM_BYTES);
        S = add_SSL_form(S, 'ITEM_OFFSET', '%i', Cd.ITEM_OFFSET);
    end
    S = add_SSL_form(S, 'DESCRIPTION', '"%s"', Cd.DESCRIPTION);      % NOTE: Added quotes.
    if isfield(Cd, 'MISSING_CONSTANT')
        % IMPLEMENTATION NOTE: Needs %E for printing floating point numbers. %G is not enough since DVALNG appears to
        % require at least one decimal place, i.e. "-1.0E+09" and "-1.000000E+09" work, but not "-1E+09".
        S = add_SSL_form(S, 'MISSING_CONSTANT', '%E', Cd.MISSING_CONSTANT);
    end
    if isfield(Cd, 'DATA_SET_PARAMETER_NAME')
        S = add_SSL_str(S, 'DATA_SET_PARAMETER_NAME', Cd.DATA_SET_PARAMETER_NAME);
    end
    if isfield(Cd, 'CALIBRATION_SOURCE_ID')
        S = add_SSL_str(S, 'CALIBRATION_SOURCE_ID', Cd.CALIBRATION_SOURCE_ID);
    end
    
    Ssl = S;
end



% Add key with plain string value.
function Ssl = add_SSL_str(Ssl, key, value)
    Ssl.keys   {end+1} = key;
    Ssl.values {end+1} = value;
    Ssl.objects{end+1} = [];
end

% Add key with formatted string value.
function Ssl = add_SSL_form(Ssl, key, pattern, value)
    Ssl.keys   {end+1} = key;
    Ssl.values {end+1} = sprintf(pattern, value);     % NOTE: sprintf
    Ssl.objects{end+1} = [];
end

% Add key with OBJECT SSL.
function Ssl = add_SSL_OBJECT(Ssl, objectValue, sslObjectContents)
    Ssl.keys   {end+1} = 'OBJECT';
    Ssl.values {end+1} = objectValue;
    Ssl.objects{end+1} = sslObjectContents;
end



%##########################################################################################################



function assert_nonempty_unquoted(str)
    if isempty(str)
        error('String value is empty.')
    end

    % ASSERTION: No quotes.
    if ~isempty(strfind(str, '"'))
        error('String value contains quotes.')
    end
end



% PROPOSAL: Remake into generic function?!
function warning_error___LOCAL(msgOrException, policy)
    if strcmp(policy, 'warning')
        
        if ischar(msgOrException)
            warning(msgOrException)
        else
            warning(Exception.message)
        end
        
    elseif strcmp(policy, 'error')
        
        if ischar(msgOrException)
            error(msgOrException)
        else
            throw(msgOrException)
        end
        
    elseif ~strcmp(policy, 'nothing')
        % CASE: Error
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
% NOTE: Always interprets Kvpl.value{i} as (MATLAB) string, not number.
% ASSERTION: All key values are strings.
%
%
% RATIONALE: ORDERING OF KEYS
% ===========================
% 1) To make LBL files more "beautiful" (e.g. P1 before P2 keywords,
%    non-ROSETTA before ROSETTA keywords).
% 2) To make it possible to put specific keywords at the top, e.g. PDS_VERSION_ID, LABEL_REVISION_NOTE, DESCRIPTION.
% 3) To ensure that LBL keywords are always in approximately the same order.
%    This is useful when comparing datasets to ensure that a modified/updated
%    lapdog code produces only the desired changes to LBL files.
%
function Ssl = create_SSL_header(Kvpl, Settings)   % Kvpl = key-value pair list
    % PROPOSAL: Assert that all KEY_ORDER_LIST keys are unique.
    % PROPOSAL: Should itself set keywords that apply to all LBL/CAT files (not just OBJECT=TABLE).
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
    Kvpl = Kvpl.reorder(Settings.headerKeysOrderList, 'sorted-unsorted');

    % ASSERTION: Check that there are no forbidden keys.
    for i=1:length(Settings.headerKeysForbiddenList)
        if any(strcmp(Settings.headerKeysForbiddenList{i}, Kvpl.keys))
            error('Trying to write LBL file header with explicitly forbidden LBL keyword "%s". This indicates that the code has previously failed to substitute these keywords for new ones.', ...
                Settings.headerKeysForbiddenList{i})
        end
    end

    % Force certain key values to be quoted.
    kvplForceQuotesKeysList = intersect(Settings.headerKeysForceQuotesList, Kvpl.keys);
    for j = 1:numel(kvplForceQuotesKeysList)
        key      = kvplForceQuotesKeysList{j};
        oldValue = Kvpl.get_value(key);
        
        % ASSERTION: Check that old value is a string.
        EJ_library.utils.assert.castring(oldValue)

        Kvpl = Kvpl.set_value(key, EJ_library.utils.quote(oldValue, 'permit quoted'));
    end
    
    
    
    % Create SSL from KVPL.
    Ssl = struct('keys', {Kvpl.keys}, 'values', {Kvpl.values}, 'objects', {cell(size(Kvpl.keys))});
    
end
