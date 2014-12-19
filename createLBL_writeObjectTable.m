% Function to write the commands for a table object in an ODL file.
% ("ObjectTable" refers to "OBJECT = TABLE" in ODL files.)
%
% Should ideally be part of createLBL.m but can not yet since createLBL.m is not a function itself.
%
% fid = file identifier of file opened & closed outside of this function.
%
% data = struct with the following fields.
%    data.N_rows              % lapdog: an_tabindex{i,4}
%    data.N_row_bytes         % lapdog: an_tabindex{i,9}
%    data.DESCRIPTION         % Description for entire table
%    data.column_list{i}.NAME            % Automatically quoted.
%    data.column_list{i}.DATA_TYPE
%    data.column_list{i}.BYTES
%    data.column_list{i}.UNIT            % Replaced by standardized default value if empty.
%    data.column_list{i}.DESCRIPTION     % Replaced by standardized default value if empty.
%
% The caller is NOT supposed to surround strings with quotes, or units with </>. The code adds that when it thinks it is
% appropriate.
%
function createLBL_writeObjectTable(fid, data)
%
% TODO: Indentation. Enable/disable.
% TODO: Clarify for when values are quoted or not. Variable prefix? ODL standard syas what?
% TODO: Create entire LBL file.
% 
% PROPOSAL: Derive ROW_BYTES rather than take value from "data".
% PROPOSAL: Use derived ROW_BYTES value to check corresponding value in "data".
% PROPOSAL: Handle FORMAT. What does PDS say?
% PROPOSAL: Handle ITEMS.
% 
% QUESTION: Use ODL field names as structure field names?
%    CON: ODL names can be unclear.
%
% PROPOSAL: Default values for absent fields.
%    CON: Misspelled field names may mistakenly lead to default values. ==> Do not use. Absent fields should always give error.



    BYTES_BETWEEN_COLUMNS = 2;
    BYTES_PER_LINEBREAK = 1;      % Derive using sprint?!!
    INDENTATION = '   ';
    indentation_level = 0;
    
    %disp(['Create LBL file: ', fopen(fid)]);     % DEBUG
    
    
    
    % -------- EXPERIMENTAL / DEBUG (below) --------
    % Calculate "row_bytes" rather than take from argument (which takes from an_tabindex).
    % NOTE: Only works if fprintf prints correctly when creates correct
    if 0
        calc_N_row_bytes = 0;
        for i = 1:length(data.column_list)
            calc_N_row_bytes = calc_N_row_bytes + data.column_list{i}.BYTES + BYTES_BETWEEN_COLUMNS;
        end
        calc_N_row_bytes = calc_N_row_bytes - BYTES_BETWEEN_COLUMNS + BYTES_PER_LINEBREAK;
        disp(['calc_N_row_bytes = ', num2str(calc_N_row_bytes)])
        disp(['data.N_row_bytes = ', num2str(data.N_row_bytes)])
    end
    % -------- EXPERIMENTAL / DEBUG (above) --------
    
    
    
    ip(+1, 'OBJECT = TABLE\n');
    ip( 0,    'INTERCHANGE_FORMAT = ASCII\n');
    ip( 0,    'ROWS = %d\n',          data.N_rows );
    ip( 0,    'COLUMNS = %d\n',       length(data.column_list));
    ip( 0,    'ROW_BYTES = %d\n',     data.N_row_bytes);
    ip( 0,    'DESCRIPTION = "%s"\n', data.DESCRIPTION);

    current_row_byte = 1;    % Starts with one, not zero.
    for i = 1:length(data.column_list)
        cd = data.column_list{i};       % cd = column data
                
        if isempty(cd.UNIT)
            cd.UNIT = '"N/A"';
        end
        if isempty(cd.DESCRIPTION)
            cd.DESCRIPTION = 'N/A';
        end
        
        ip(+1, 'OBJECT = COLUMN\n');
        ip( 0,    'NAME = %s\n',          cd.NAME);
        ip( 0,    'START_BYTE = %i\n',    current_row_byte);
        ip( 0,    'BYTES = %i\n',         cd.BYTES); %
        ip( 0,    'DATA_TYPE = %s\n',     cd.DATA_TYPE);
        ip( 0,    'UNIT = %s\n',          cd.UNIT);
        if isfield(cd, 'FORMAT')
            ip( 0, 'FORMAT = %s\n',       cd.FORMAT);
        end
        ip( 0,    'DESCRIPTION = "%s"\n', cd.DESCRIPTION);      % NOTE: Added quotes.
        ip(-1, 'END_OBJECT  = COLUMN\n');
        
        current_row_byte = current_row_byte + cd.BYTES + BYTES_BETWEEN_COLUMNS;
    end
     
    ip(-1, 'END_OBJECT  = TABLE\n');
    
    % ------------------------------------------------------------------------------------------
    
    % Print with indentation (ip = indent print).
    %
    % Arguments: indentation increment, printf arguments (multiple; no fid)
    % NOTE: Uses "global" variables (fid, INDENTATION, indentation_level)
    % defined in outer function for simplicity & speed(?).
    % NOTE: Indentation increment takes before/after printf depending on decrement/increment.
    function ip(varargin)
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
end



