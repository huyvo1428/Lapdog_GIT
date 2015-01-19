% Function to write the commands for a table object in an ODL file.
% ("ObjectTable" refers to "OBJECT = TABLE" in ODL files.)
%
% Should ideally be part of createLBL.m but can not yet since createLBL.m is not a function itself.
%
% fid = file identifier of file opened & closed outside of this function.
%
% data = struct with the following fields.
%    data.ROWS              % lapdog: an_tabindex{i,4}
%    data.ROW_BYTES           % lapdog: an_tabindex{i,9}
%    data.DESCRIPTION         % Description for entire table
%    data.DELIMITER           % Optional
%    data.OBJCOL_list{i}.NAME            % Automatically quoted.
%    data.OBJCOL_list{i}.BYTES
%    data.OBJCOL_list{i}.DATA_TYPE
%    data.OBJCOL_list{i}.UNIT            % Replaced by standardized default value if empty.<
%    data.OBJCOL_list{i}.FORMAT          % Optional
%    data.OBJCOL_list{i}.ITEMS           % Optional
%    data.OBJCOL_list{i}.DESCRIPTION     % Replaced by standardized default value if empty.
%
% The caller is NOT supposed to surround strings with quotes, or units with </>. The code adds that when it thinks it is
% appropriate.
%
% NOTE: The function does not write a finishing "END".
%
function createLBL_writeObjectTable(fid, data)
%
% TODO: Clarify for when values are quoted or not. Variable prefix? ODL standard says what?
% 
% PROPOSAL: Derive ROW_BYTES rather than take value from "data".
% PROPOSAL: Default values for absent fields.
%    CON: Misspelled field names may mistakenly lead to default values. ==> Do not use. Absent fields should always give error.
% PROPOSAL: Hardcode DELIMITER value?
%
% PROBLEM: Replacing [] with 'N/A'. Caller may use [] as a placeholder before knowing the proper value, rather than in the meaning of no value (N/A).
% 
% QUESTION: Use ODL field names as structure field names? ODL names can be unclear.
% QUESTION: If COLUMNS or ROW_BYTES disagree, which one should be used?


    % Constants:
    BYTES_BETWEEN_COLUMNS = 2;
    BYTES_PER_LINEBREAK = 1;      % Derive using sprint?!!
    INDENTATION = '   ';
    PERMITTED_OBJCOL_FIELD_NAMES = {'NAME', 'BYTES', 'DATA_TYPE', 'UNIT', 'FORMAT', 'ITEMS', 'DESCRIPTION', 'COLUMNS'};
    
    indentation_level = 0;
    data.DESCRIPTION = strrep(data.DESCRIPTION, '"', '');   % Remove quotes, if there are any. Quotes are added later.
    %disp(['Create LBL table: ', fopen(fid)]);     % DEBUG / log message.
    
    
    
    % When a caller takes values from tabindex etc, and they are sometimes
    % mistakenly set to []. Therefore this check is useful. Mistake might
    % otherwise be discovered by by examining LBL files.
    if isempty(data.COLUMNS) || isempty(data.ROW_BYTES) || isempty(data.ROWS)
        error('ERROR: Trying to use empty value.')
    end
    
    % Iterate over ODL OBJECT COLUMN; Consistency checks.
    % Calculate number of TAB file columns (taking ITEMS into account) rather than take from argument.
    % Calculate "ROW_BYTES" rather than take from argument (which takes from tabindex/an_tabindex).
    % NOTE: ROW_BYTES is only correct if fprintf prints correctly when creating the TAB file.
    N_row_bytes_calc = 0;
    N_TAB_cols_calc = 0;
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
            error('ERROR: Found illegal field name(s).')
        end
        
        if isfield(cd, 'ITEMS')
            N_subcolumns = cd.ITEMS;
        else
            N_subcolumns = 1;
        end
        N_TAB_cols_calc = N_TAB_cols_calc + N_subcolumns;
        N_row_bytes_calc = N_row_bytes_calc + N_subcolumns*(cd.BYTES + BYTES_BETWEEN_COLUMNS);
        OBJCOL_names_list{end+1} = cd.NAME;
    end
    N_row_bytes_calc = N_row_bytes_calc - BYTES_BETWEEN_COLUMNS; % + BYTES_PER_LINEBREAK;
    
    % ---------------------------------------------
    % Check for doubles among the ODL column names.
    % Useful for A?S.LBL files.
    % ---------------------------------------------
    if length(unique(OBJCOL_names_list)) ~= length(OBJCOL_names_list)
        error('Found doubles among the ODL column names.')
    end
    
    % ------------------------------------------------------------
    % Check stated ROW_BYTES corresponds to the derived ROW_BYTES.
    % ------------------------------------------------------------
    % Since it unclear whether ROW_BYTES includes line breaks or not,
    % allow a small difference, for now.
    % /Erik P G Johansson 2015-01-15
    if ~ismember(N_row_bytes_calc - data.ROW_BYTES, [0, -1])
        fprintf(1, 'fopen(fid) = %s\n', fopen(fid));
        fprintf(1, 'N_row_bytes_calc = %i\n', N_row_bytes_calc);
        fprintf(1, 'data.ROW_BYTES   = %i\n', data.ROW_BYTES);
        msg = 'data.ROW_BYTES disagrees with the corresponding calculated value.';
        fprintf(1, '%s\n', msg)     % Print since warning does not always work.
        warning(msg)
        %error(msg)
    end
    
    if N_TAB_cols_calc ~= data.COLUMNS
        fprintf(1, 'fopen(fid) = %s\n', fopen(fid));
        fprintf(1, 'N_TAB_cols_calc = %i\n', N_TAB_cols_calc);
        fprintf(1, 'data.COLUMNS    = %i\n', data.COLUMNS);
        msg = 'data.COLUMNS disagrees with the corresponding calculated value.';
        fprintf(1, '%s\n', msg)     % Print since warning does not always work.
        warning(msg)
        %error(msg)
    end
    

    
    %---------------
    % Write to file
    %---------------
    indented_print(+1, 'OBJECT = TABLE\n');
    indented_print( 0,     'INTERCHANGE_FORMAT = ASCII\n');
    indented_print( 0,     'ROWS               = %d\n',   data.ROWS );
    indented_print( 0,     'COLUMNS            = %d\n',   data.COLUMNS);
    indented_print( 0,     'ROW_BYTES          = %d\n',   data.ROW_BYTES);
    indented_print( 0,     'DESCRIPTION        = "%s"\n', data.DESCRIPTION);
    if isfield(data, 'DELIMITER')
        indented_print( 0, 'DELIMITER          = "%s"\n', data.DELIMITER);
    end

    current_row_byte = 1;    % Starts with one, not zero.
    for i = 1:length(data.OBJCOL_list)
        cd = data.OBJCOL_list{i};       % cd = column data
           
        if isempty(cd.NAME)
            error('ERROR: Trying to use empty value for NAME.')
        end
        if isempty(cd.UNIT)
            cd.UNIT = '"N/A"';
        end
        if isempty(cd.DESCRIPTION)
            cd.DESCRIPTION = 'N/A';
        end
        
        indented_print(+1, 'OBJECT = COLUMN\n');
        indented_print( 0,     'NAME        = %s\n', cd.NAME);
        indented_print( 0,     'START_BYTE  = %i\n', current_row_byte);
        indented_print( 0,     'BYTES       = %i\n', cd.BYTES); %
        indented_print( 0,     'DATA_TYPE   = %s\n', cd.DATA_TYPE);
        indented_print( 0,     'UNIT        = %s\n', cd.UNIT);
        if isfield(cd, 'FORMAT')
            indented_print( 0, 'FORMAT      = %s\n', cd.FORMAT);
        end
        if isfield(cd, 'ITEMS')
            indented_print( 0, 'ITEMS       = %i\n', cd.ITEMS);
            N_subcolumns = cd.ITEMS;
        else
            N_subcolumns = 1;
        end
        indented_print( 0,     'DESCRIPTION = "%s"\n', cd.DESCRIPTION);      % NOTE: Added quotes.
        indented_print(-1, 'END_OBJECT = COLUMN\n');
        
        current_row_byte = current_row_byte + N_subcolumns*cd.BYTES + BYTES_BETWEEN_COLUMNS;
    end
     
    indented_print(-1, 'END_OBJECT = TABLE\n');
    
    % ------------------------------------------------------------------------------------------
    
    % Print with indentation.
    % -----------------------
    % Arguments: indentation increment, printf arguments (multiple; no fid)
    % NOTE: Uses "global" variables (fid, INDENTATION, indentation_level)
    % defined in outer function for simplicity & speed(?).
    % NOTE: Indentation increment takes before/after printf depending on decrement/increment.
    function indented_print(varargin)
        indentation_increment = varargin{1};        
        printf_str = varargin{2};
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

    % ------------------------------------------------------------------------------------------
    
end



