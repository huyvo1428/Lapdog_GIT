% Create TAB files containing the current best estimates of plasma parameters.
% 
% NOTE: Very preliminary best estimates (physics).
% NOTE: Presently only based on probe 1 sweeps, one estimate per (probe 1) sweep.
%
% IMPORTANT NOTE: Uses the non-PDS compliant first row
% of column headers to internally label variables (struct fields).

function an_tabindex = best_estimates(an_tabindex)

%===========================================================================================
% QUESTION: Filenames for new files?
%     BES = best estimates
%     PPS = Plasma parameters.
%     EXS = Estimate (no probe), sweep
%     NOTE: 1/2/3 hints of probe number.
%     NOTE: "S" hints of sweep.
%     NOTE: "B" hints of "bias potential during sweep"
%
% NOTE: In principle: Not one BES file per A1S/A2S file, but
% per operations block (both probes together). 
%
% NOTE: importdata omits columns without numbers.
% ==> Matrices of numbers (not strings) from some AxS files have
% fewer columns ==> Nbr of column names and nbr of columns don't match.
%
% Footnote: Have not found any hard source code which specifies the
% exact length of UTC-time strings. ==> One has to "measure" the
% length manually for now.
% Ex: "2014-08-31T22:14:24.369327" ==> 10 + 1 + 8 + 1 + 6 = 26 bytes
%
% TODO: Better way to connect an_tabindex nbr-of-columns to file-writing code.
%
% TODO: Not rely on non-PDS compliant AxS first-line column headers.
%    PROPOSAL: Use general ODL/LBL reading code?
%       CON: Can not presently (2014-11-25) make use of the corresponding LBL file
%            for finding column names since the LBL file has not yet been created at
%            this stage in the execution of lapdog.
%===========================================================================================

    an_tabindex = main_INTERNAL(an_tabindex);

    % ---------------------------------------------------------------------
    
    function an_tabindex = main_INTERNAL(an_tabindex)
        
        % Extract analyzed sweep files.
        i_sweep = find(strcmp(an_tabindex(:,7),'sweep'));
        an_tabindex_selection = an_tabindex(i_sweep, :);

        % Extract subset of an_tabindex for probe 1.
        probe_list = cellfun(@(x) x(end-5), an_tabindex_selection(:,2), 'UniformOutput', 0);
        i_probe1 = find(strcmp('1', probe_list));       
        an_tabindex_selection = an_tabindex_selection(i_probe1, :);
        
        for i = 1:size(an_tabindex_selection, 1)
            A1S_TAB_file_path = an_tabindex_selection{i, 1};
            
            BES_TAB_file_path = A1S_TAB_file_path;
            BES_TAB_file_path(end-6:end-4) = 'BES';     % NOTE: Ugly, but works.
            BES_TAB_file_name = an_tabindex_selection{i, 2};
            BES_TAB_file_name(end-6:end-4) = 'BES';     % NOTE: Ugly, but works.
            
            %A1S_TAB_file_path   % DEBUG
            
            [data, N_rows] = read_AxS_file(A1S_TAB_file_path);
            [row_bytes, N_columns] = write_BES_file(BES_TAB_file_path, data, N_rows);
         
            % Update an_tabindex.
            an_tabindex_amendment = an_tabindex_selection(i, :);           % Copy entry from an_tabindex to use as template.
            an_tabindex_amendment{1, 1} = BES_TAB_file_path;    % path
            an_tabindex_amendment{1, 2} = BES_TAB_file_name;    % name
            an_tabindex_amendment{1, 4} = N_rows;
            an_tabindex_amendment{1, 5} = N_columns;
            an_tabindex_amendment{1, 7} = 'best_estimates';
            an_tabindex_amendment{1, 9} = row_bytes;
            an_tabindex(end+1, :) = an_tabindex_amendment;
        end
    end
    
    % ---------------------------------------------------------------------

    %=============================================================================
    % Reads AxS file 
    %
    % NOTE: Uses the non-PDS compliant first row
    % of column headers to label variables (struct fields).
    % -------------------------------------------------------
    % Quite general function for files with first row as column headers. Could in
    % principle be repurposed as a general function for general use.
    %=============================================================================
    function [data, N_rows] = read_AxS_file(AxS_TAB_file_path)
        line_list = importdata(AxS_TAB_file_path, '\n');               % Read file into cell array, one line per cell.
        line_value_list = regexp(line_list, ',', 'Split');     % Split strings using delimiter.
        value_list = vertcat(line_value_list{:});              % Concatenate (cell) array of (cell) arrays to create one long vector (Nx1).

        N_rows = length(line_value_list);
        N_cols = length(line_value_list{1});              % NOTE: Requires at least one row.
        file_contents = reshape(value_list, N_rows, N_cols);      % Derive 2D table from 1D vector. NOTE: Incomplete test of equal number of columns per line.
        file_column_name_list = file_contents(1,:);
        file_data = file_contents(2:end, :);

        data = [];
        for i = 1:N_cols     % For every column ...
            % DEBUG
            %disp(['i = ', num2str(i)])
            %disp(['file_column_name_list{i} = ', file_column_name_list{i}])
            
            skey = file_column_name_list{i};    % skey = struct key/field name
            skey = strrep(skey,'(','_');
            skey = strrep(skey,')','');     % NOTE: Remove right bracket (as opposed to left bracket which is replaced).
            skey = strrep(skey,'=','');
            skey = strrep(skey,'.','_');
            skey = strrep(skey,' ','');
            
            % NOTE: Using delimiter ',' to find columns implies one has to
            % trim away leading and trailing white space from columns that could be
            % interpreted as strings. If the real delimiter for writing TAB files
            % is ', ' (comma+whitespace) then the extra whitespace will
            % otherwise end up in the string when reading.
            
            data.(skey) = strtrim(file_data(1:end, i));     % NOTE: Trimming and copying strings. No conversion strings-to-numbers.
        end
 
        N_rows = N_rows - 1;    % Return number of rows of data, not lines in the file.
    end
    
    % ---------------------------------------------------------------------

    function [row_bytes, N_columns] = write_BES_file(BES_TAB_file_path, data, N_rows)
        fid = fopen(BES_TAB_file_path, 'w');
        
        for i = 1:N_rows            
            % Convert strings to numbers.
            % NOTE: str2double converts both empty strings and the string "NaN" to the "number" NaN.
            quality_factor = str2double(data.Qualityfactor{i});
            %ne  = str2double(data.ne_plasma{i});
            n = str2double(data.asm_ni_v_indep{i});        % NOTE: Variable FK recommended 2014-11-26.
            %Te  = str2double(data.Te_plasma{i});
            Te = str2double(data.asm_Texp{i});              % NOTE: Variable FK recommended 2014-11-26.
            %Vsg = str2double(data.Vsc{i});
            Vsc = str2double(data.asm_Vsg{i});               % NOTE: Variable FK recommended 2014-11-26, in particular if probe in shadow.

            line1 = sprintf('%s, %s, %03i, ',         data.START_TIME_UTC{i}, data.STOP_TIME_UTC{i}, quality_factor);
            line2 = sprintf('%14.7e, %14.7e, %14.7e', n, Te, Vsc);
            line = [line1, line2];
            line = strrep(line, 'NaN', '   ');
            N_columns = 6;
            row_bytes = fprintf(fid, [line, '\n']);
            
            %disp(line)                     % DEBUG. Preferably no extra linebreak in string.
        end
        fclose(fid);
    end

end
