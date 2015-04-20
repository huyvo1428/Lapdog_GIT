% Function to write the commands for a table object in an ODL file.
% ("ObjectTable" refers to "OBJECT = TABLE" in ODL files.)
%
% Should ideally be part of createLBL.m but can not yet since createLBL.m is not a function itself.
%
% fid = file identifier of file opened & closed outside of this function.
%
% data = struct with the following fields.
%    data.COLUMNS_consistency_check     % Value from when writing TAB file. For double-checking.  tabindex{i, 6};
%    data.ROW_BYTES_consistency_check   % Value from when writing TAB file. For double-checking.  tabindex{i, 7}, an_tabindex{i,9}
%    data.ROWS                          % lapdog: an_tabindex{i,4}
%    data.DESCRIPTION                   % Description for entire table.
%    data.OBJCOL_list{i}.NAME               
%    data.OBJCOL_list{i}.BYTES
%    data.OBJCOL_list{i}.DATA_TYPE
%    data.OBJCOL_list{i}.UNIT               % Replaced by standardized default value if empty.
%    data.OBJCOL_list{i}.FORMAT             % Optional
%    data.OBJCOL_list{i}.ITEMS              % Optional
%    data.OBJCOL_list{i}.DESCRIPTION        % Replaced by standardized default value if empty. Automatically quoted.
%    data.OBJCOL_list{i}.MISSING_CONSTANT   % Optional
%  
% The caller is NOT supposed to surround strings with quotes, or units with </>. The code adds that when it thinks it is
% appropriate.
%
% NOTE: The function does not write a finishing "END".
%
function createLBL_writeObjectTable(fid, data, TAB_LBL_inconsistency_policy)
%
% TODO: Clarify for when values are quoted or not. Variable prefix? ODL standard says what?
%
% TODO: Enforce exact ROW_BYTES=N_row_bytes_calc. Correct CR+LF when writing TAB files.
%   QUESTION: What does this mean?
%
% PROPOSAL: Default values for absent fields (keywords).
%    CON: Misspelled field names may mistakenly lead to default values. ==> Do not use. Absent fields should always give error.
%
% PROBLEM: Replacing [] with 'N/A'. Caller may use [] as a placeholder before knowing the proper value, rather than in the meaning of no value (N/A).
% 
% QUESTION: Use ODL field names as structure field names? ODL names can be unclear.
% QUESTION: If COLUMNS or ROW_BYTES disagree, which one should be used?
%
% PROPOSAL: Calculate ROW_BYTES, but let caller submit a value (in an argument with another name) for what it should be
% from the TAB files actually created ("empirically") for double-checking.

    

    % Constants:
    BYTES_BETWEEN_COLUMNS = 2;
    BYTES_PER_LINEBREAK = 2;      % Carriage return + line feed.
    INDENTATION = '    ';
    PERMITTED_DATA_FIELD_NAMES   = {'COLUMNS_consistency_check', 'ROW_BYTES_consistency_check', 'ROWS', 'DESCRIPTION', 'OBJCOL_list'};  % NOTE: Exclude COLUMNS, ROW_BYTES, DELIMITER.
    PERMITTED_OBJCOL_FIELD_NAMES = {'NAME', 'BYTES', 'DATA_TYPE', 'UNIT', 'FORMAT', 'ITEMS', 'MISSING_CONSTANT', 'DESCRIPTION'};
    
    indentation_level = 0;
    
    % Remove quotes, if there are any. Quotes are added later.
    % NOTE: One does not want to give error on finding quotes since the value may have been read from CALIB LBL file.
    data.DESCRIPTION = strrep(data.DESCRIPTION, '"', '');
    
    %disp(['Create LBL table: ', fopen(fid)]);     % DEBUG / log message.
    
    
    
    % --------------------------------------------------------------
    % Check if caller only uses permissible field names. Disable?
    % Useful when changing field names.
    % --------------------------------------------------------------
    if any(~ismember(fieldnames(data), PERMITTED_DATA_FIELD_NAMES))
        error('ERROR: Found illegal field name(s) in parameter "data".')
    end
    
    %----------------------------------------------------------------------
    % When a caller takes values from tabindex, an_tabindex etc, and they are sometimes
    % mistakenly set to []. Therefore this check is useful. Mistake might
    % otherwise be discovered first when examining LBL files.
    %----------------------------------------------------------------------
    if isempty(data.COLUMNS_consistency_check) || isempty(data.ROW_BYTES_consistency_check) || isempty(data.ROWS)
        error('ERROR: Trying to use empty value.')
    end
    
    %--------------------------------------------------------------------------------------------------
    % Iterate over ODL OBJECT COLUMN
    % ------------------------------
    % Calculate "COLUMNS" (taking ITEMS into account) rather than take from argument.
    % Calculate "ROW_BYTES" rather than take from argument.
    % NOTE: ROW_BYTES is only correct if fprintf prints correctly when creating the TAB file.
    %--------------------------------------------------------------------------------------------------
    %N_row_bytes_calc = 0;
    data.ROW_BYTES = 0;
    %N_TAB_cols_calc = 0;
    data.COLUMNS = 0;
    OBJCOL_names_list = {};
    for i = 1:length(data.OBJCOL_list)
        cd = data.OBJCOL_list{i};       % cd = column data
        
        % --------------------------------------------------------------
        % Check if caller has added fields that can not be used.
        % --------------------------------------------------------------
        % Useful for not loosing information in optional arguments/field
        % names by misspelling, or misspelling when overwrting values,
        % or adding fields that are never used by the function.
        % --------------------------------------------------------------
        if any(~ismember(fieldnames(cd), PERMITTED_OBJCOL_FIELD_NAMES))
            error('ERROR: Found illegal COLUMN OBJECT field name(s).')
        end
        
        if isfield(cd, 'ITEMS')
            N_subcolumns = cd.ITEMS;
        else
            N_subcolumns = 1;
        end
        %N_TAB_cols_calc = N_TAB_cols_calc + N_subcolumns;
        data.COLUMNS = data.COLUMNS + N_subcolumns;
        %N_row_bytes_calc = N_row_bytes_calc + N_subcolumns*(cd.BYTES + BYTES_BETWEEN_COLUMNS);
        data.ROW_BYTES = data.ROW_BYTES + N_subcolumns*(cd.BYTES + BYTES_BETWEEN_COLUMNS);
        OBJCOL_names_list{end+1} = cd.NAME;
    end
    %N_row_bytes_calc = N_row_bytes_calc - BYTES_BETWEEN_COLUMNS + BYTES_PER_LINEBREAK;
    data.ROW_BYTES = data.ROW_BYTES - BYTES_BETWEEN_COLUMNS + BYTES_PER_LINEBREAK;
    
    
    
    % ---------------------------------------------
    % Check for doubles among the ODL column names.
    % Useful for A?S.LBL files.
    % ---------------------------------------------
    if length(unique(OBJCOL_names_list)) ~= length(OBJCOL_names_list)
        error('Found doubles among the ODL column names.')
    end
    
    
    
    % ------------------------------------------------------------
    % Do consistency checks.
    % ------------------------------------------------------------
    % Since it unclear whether ROW_BYTES includes line breaks or not,
    % allow a small difference, for now.
    % /Erik P G Johansson 2015-01-15
    % ------------------------------------------------------------
    %if ~ismember(N_row_bytes_calc - data.ROW_BYTES, [0, -1])
    %if ~ismember(data.ROW_BYTES - data.ROW_BYTES_consistency_check, [0, -1])
    if data.ROW_BYTES ~= data.ROW_BYTES_consistency_check
        msg =       sprintf('fopen(fid) = %s\n', fopen(fid));
        msg = [msg, sprintf('data.ROW_BYTES (derived)         = %i\n', data.ROW_BYTES)];
        msg = [msg, sprintf('data.ROW_BYTES_consistency_check = %i\n', data.ROW_BYTES_consistency_check)];
        msg = [msg,         'data.ROW_BYTES deviates from the consistency check value.'];
        warning_error___LOCAL(msg, TAB_LBL_inconsistency_policy)
    end
    
    %if (N_TAB_cols_calc ~= data.COLUMNS) & (enable_TAB_inconsistency_error_msg)
    if (data.COLUMNS ~= data.COLUMNS_consistency_check)
        msg =       sprintf('fopen(fid) = %s\n', fopen(fid));
        msg = [msg, sprintf('data.COLUMNS (derived)         = %i\n', data.COLUMNS)];
        msg = [msg, sprintf('data.COLUMNS_consistency_check = %i\n', data.COLUMNS_consistency_check)];
        msg = [msg,         'data.COLUMNS deviates from the consistency check value.'];        
        warning_error___LOCAL(msg, TAB_LBL_inconsistency_policy)
    end



    %===============
    % Write to file
    %===============
    ind_print___LOCAL(+1, 'OBJECT = TABLE');
    ind_print___LOCAL( 0,     'INTERCHANGE_FORMAT = ASCII');
    ind_print___LOCAL( 0,     'ROWS               = %d',   data.ROWS );
    ind_print___LOCAL( 0,     'COLUMNS            = %d',   data.COLUMNS);
    ind_print___LOCAL( 0,     'ROW_BYTES          = %d',   data.ROW_BYTES);
    ind_print___LOCAL( 0,     'DESCRIPTION        = "%s"', data.DESCRIPTION);
    %if isfield(data, 'DELIMITER')
    %    ind_print___LOCAL( 0, 'DELIMITER          = "%s"', data.DELIMITER);
    %end

    current_row_byte = 1;    % Starts with one, not zero.
    for i = 1:length(data.OBJCOL_list)
        cd = data.OBJCOL_list{i};       % cd = column data
           
        if isempty(cd.NAME)
            error('ERROR: Trying to use empty value for NAME.')
        end
        if isempty(cd.UNIT) || strcmp(cd.UNIT, '"N/A"')
            cd.UNIT = '"N/A"';     % NOTE: Adds quotes. UNIT is otherwise not printed with quotes (for now). Correct policy?!
        end
        if isempty(cd.DESCRIPTION)
            cd.DESCRIPTION = 'N/A';   % NOTE: Quotes are added later.
        else
            if ~isempty(strfind(cd.DESCRIPTION, '"'))
                error('Parameter field DESCRIPTION contains quotes. This is not needed as quotes are added automatically.')
            end
        end
        
        ind_print___LOCAL(+1, 'OBJECT = COLUMN');
        ind_print___LOCAL( 0,     'NAME             = %s', cd.NAME);
        ind_print___LOCAL( 0,     'START_BYTE       = %i', current_row_byte);
        ind_print___LOCAL( 0,     'BYTES            = %i', cd.BYTES);
        ind_print___LOCAL( 0,     'DATA_TYPE        = %s', cd.DATA_TYPE);
        ind_print___LOCAL( 0,     'UNIT             = %s', cd.UNIT);
        if isfield(cd, 'FORMAT')
            ind_print___LOCAL( 0, 'FORMAT           = %s', cd.FORMAT);
        end
        if isfield(cd, 'MISSING_CONSTANT')
            ind_print___LOCAL( 0, 'MISSING_CONSTANT = %f', cd.MISSING_CONSTANT);
        end
        if isfield(cd, 'ITEMS')
            ind_print___LOCAL( 0, 'ITEMS            = %i', cd.ITEMS);
            N_subcolumns = cd.ITEMS;
        else
            N_subcolumns = 1;
        end
        ind_print___LOCAL( 0,     'DESCRIPTION = "%s"', cd.DESCRIPTION);      % NOTE: Added quotes.
        ind_print___LOCAL(-1, 'END_OBJECT = COLUMN');
        
        current_row_byte = current_row_byte + N_subcolumns*cd.BYTES + BYTES_BETWEEN_COLUMNS;
    end
     
    ind_print___LOCAL(-1, 'END_OBJECT = TABLE');
    
    %##########################################################################################################
    
    %------------------------------------------------------------------------------------------
    % Print with indentation.
    % -----------------------
    % Arguments: indentation increment, printf arguments (multiple; no fid)
    % NOTE: Uses function-"global" variables (fid, INDENTATION, indentation_level)
    % defined in outer function for simplicity & speed(?).
    % NOTE: Indentation increment takes before/after printf depending on decrement/increment.
    %
    % NOTE: Adds correct carriage return and line feed at the end.
    %------------------------------------------------------------------------------------------
    function ind_print___LOCAL(varargin)
        indentation_increment = varargin{1};        
        printf_str = [varargin{2}, '\r\n'];
        printf_arg = varargin(3:end);

        if indentation_increment < 0 
            indentation_level = indentation_level + indentation_increment;        
        end
        
        printf_str = [repmat(INDENTATION, 1, indentation_level), printf_str];    % Add indentation.
        fprintf(fid, printf_str, printf_arg{:});
        
        if indentation_increment > 0 
            indentation_level = indentation_level + indentation_increment;
        end
    end

    %##########################################################################################################
    
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
    
end
