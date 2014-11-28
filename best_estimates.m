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
%     EST = Estimates
%     BES = Best estimates
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

    an_tabindex = main_INTERNAL_OLD(an_tabindex);
    %an_tabindex = main_INTERNAL_NEW(an_tabindex);

    % ---------------------------------------------------------------------
    
    % UNFINISHED
%     function an_tabindex = main_INTERNAL_NEW(an_tabindex)
%         error('Implementation of function not finished yet.')              % TEMPORARY
%         % BEHÖVER PARAMETRAR: (nob), obe, index
%         nob = length(obe);
%         
%         i_ant_list = find(strcmp(an_tabindex(:,7),'sweep'));     % ant = an_tabindex
%         
%         % Create table of AxS files with indicies (<ops block>, <probe number>).
%         % NOTE: Not all entries will necessarily be assigned.
%         % Some ops blocks may not contain sweeps, some may be sweep on only one probe.
%         %i_ant_table = cell(nob, 2);
%         AxS_data_table = cell(nob, 2);
%         for i_ant = i_ant_list
%             i_ind = an_tabindex{i_ant, 3};
%             i_ob = find(obe >= i_ind, 1);                   % Operations block.
%             i_probe = index(an_tabindex{i_ant, 3}).probe;
%                         
%             EST_TAB_file_path = A1S_TAB_file_path;
%             EST_TAB_file_path(end-6:end-4) = 'EST';     % NOTE: Ugly, but works.
%             EST_TAB_file_name = an_tabindex_selection{i, 2};
%             EST_TAB_file_name(end-6:end-4) = 'EST';     % NOTE: Ugly, but works.
%             
%             AxS_file_path = an_tabindex{i_ant, 1};
%             %probe = [];
%             [probe.data, probe.N_rows] = read_AxS_file(AxS_file_path);
%             probe.EST_file_path = EST_TAB_file_path;
%             AxS_data_table{i_ob, i_probe} = probe;
%                         
%             warning('INCOMPLETE IMPLEMENTATION: Does not update an_tabindex.')
%             % Update an_tabindex.
%             %an_tabindex_amendment = an_tabindex_selection(i, :);           % Copy entry from an_tabindex to use as template.
%             %an_tabindex_amendment{1, 1} = EST_TAB_file_path;    % File path
%             %an_tabindex_amendment{1, 2} = EST_TAB_file_name;    % Filename
%             %%an_tabindex_amendment{1, 3}   % Keep index back to corresponding "index" file
%             %an_tabindex_amendment{1, 4} = N_rows;
%             %an_tabindex_amendment{1, 5} = N_columns;
%             %%an_tabindex_amendment{1, 6}   % Keep index back to corresponding "tabindex" file.
%             %an_tabindex_amendment{1, 7} = 'best_estimates';
%             %%an_tabindex_amendment{1, 8}   % Keep timing
%             %an_tabindex_amendment{1, 9} = row_bytes;
%             %an_tabindex(end+1, :) = an_tabindex_amendment;         
%         end
% 
%         for i_ob = 1:nob
%             write_EST_file_NEW(EST_TAB_file_path, AxS_data_table{i_ob, 1}, AxS_data_table{i_ob, 2})
%         end
%         
%     end

    % ---------------------------------------------------------------------

    % QUESTION: Does it really need N_rows (input)?!! Can that no be derived from "data"?
    % CASES: 
    %   P1, but not P2
    %   ...
    % NOTE: ops block might not contain any sweeps at all. ==> Do not generate EST file.
%     function [row_bytes, N_columns] = write_EST_file_NEW(EST_TAB_file_path, data_P1, data_P2)
% 
%         data = {data_P1, data_P2};
%         
%         %EST_data = cell(data_P1.N_rows + data_P2.N_rows, 6+1);
%         %i_EST_row = 1;
%         
%         
%         %field_list = {'START_TIME_UTC', 'STOP_TIME_UTC', 'quality_factor', 'asm_ni_v_indep', 'asm_Vsg', 'asm_Te_exp'};
%         field_list_shared = {'START_TIME_UTC', 'STOP_TIME_UTC', 'quality_factor'};
%         field_list_P1 = {'asm_ni_v_indep', 'asm_Vsg', 'asm_Te_exp'};
%         field_list_P2 = {                             'asm_Te_exp'};
%         %data_P1P2 = [];
%         for i_field = 1:length(field_list)
%             fn = field_list{i_field};
%             data_P1P2.(fn) = [];
%         end
%         if ~isempty(data_P1)    % If there is probe 1 data ...            
%             for i_field = 1:length(field_list_shared)
%                 fn = field_list{i_field};
%                 data_P1P2.(fn) = [data_P1P2.(fn); data_P1.(fn)];
%             end
%             for i_field = 1:length(field_list_P1)
%                 fn = field_list{i_field};
%                 data_P1P2.(fn) = [data_P1P2.(fn); data_P1.(fn)];
%             end            
%             for i_field = 1:length(field_list_P2)
%                 fn = field_list{i_field};
%                 data_P1P2.(fn) = [data_P1P2.(fn); cell(data_P1.N_rows, 1)];    % Fill with empty cells.
%             end            
%         end
%         if ~isempty(data_P2)    % If there is probe 2 data ...            
%             for i_field = 1:length(field_list_shared)
%                 fn = field_list{i_field};
%                 data_P1P2.(fn) = [data_P1P2.(fn); data_P2.(fn)];
%             end
%         end
%         
%         
%         
%         
%         %for i_row_P2=1:data_P2.N_rows
% %                if    % If probe 2 shaded ...                   
% %                else    % if probe 2 shaded ...
% %                end
% %        end
% 
%     end

    % ==========================================================================================

    % Old version of function. To be replaced by newer one when that one works.
    % QUESTION: Does it really need N_rows?!! Can that no be derived from "data"?
    function [row_bytes, N_columns] = write_EST_file_OLD(EST_TAB_file_path, data, N_rows)
        fid = fopen(EST_TAB_file_path, 'w');
        
        for i = 1:N_rows            
            %----------------------------------------------------------------------------------------
            % Convert strings to numbers.
            % NOTE: str2double converts both empty strings and the string "NaN" to the "number" NaN.
            %----------------------------------------------------------------------------------------
            quality_factor = str2double(data.Qualityfactor{i});
            n   = str2double(data.asm_ni_v_indep{i});        % NOTE: Variable FK recommended 2014-11-26.
            Te  = str2double(data.asm_Te_exp{i});            % NOTE: Variable FK recommended 2014-11-26.
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

    % ---------------------------------------------------------------------
    
    % Old version of function. To be replaced by newer one when that one works.
    function an_tabindex = main_INTERNAL_OLD(an_tabindex)
        
        % Extract analyzed sweep files.
        i_sweep = find(strcmp(an_tabindex(:,7),'sweep'));
        an_tabindex_selection = an_tabindex(i_sweep, :);        
        
        % Extract subset of an_tabindex for probe 1.
        probe_list = cellfun(@(x) x(end-5), an_tabindex_selection(:,2), 'UniformOutput', 0);    % Extract probe number from file name!!
        i_probe1 = find(strcmp('1', probe_list));
        %i_probe2 = find(strcmp('2', probe_list));
        an_tabindex_selection = an_tabindex_selection(i_probe1, :);
        
        for i = 1:size(an_tabindex_selection, 1)
            A1S_TAB_file_path = an_tabindex_selection{i, 1};
            
            EST_TAB_file_path = A1S_TAB_file_path;
            EST_TAB_file_path(end-6:end-4) = 'EST';     % NOTE: Ugly, but works.
            EST_TAB_file_name = an_tabindex_selection{i, 2};
            EST_TAB_file_name(end-6:end-4) = 'EST';     % NOTE: Ugly, but works.
            
            %A1S_TAB_file_path   % DEBUG
            
            [data, N_rows] = read_AxS_file(A1S_TAB_file_path);
            [row_bytes, N_columns] = write_EST_file_OLD(EST_TAB_file_path, data, N_rows);
         
            % Update an_tabindex.
            an_tabindex_amendment = an_tabindex_selection(i, :);           % Copy entry from an_tabindex to use as template.
            an_tabindex_amendment{1, 1} = EST_TAB_file_path;    % path
            an_tabindex_amendment{1, 2} = EST_TAB_file_name;    % name
            %an_tabindex_amendment{1, 3}   % Keep index back to corresponding "index" file
            an_tabindex_amendment{1, 4} = N_rows;
            an_tabindex_amendment{1, 5} = N_columns;
            %an_tabindex_amendment{1, 6}   % Keep index back to corresponding "tabindex" file.
            an_tabindex_amendment{1, 7} = 'best_estimates';
            %an_tabindex_amendment{1, 8}   % Keep timing
            an_tabindex_amendment{1, 9} = row_bytes;
            an_tabindex(end+1, :) = an_tabindex_amendment;
        end
    end
    
    % ---------------------------------------------------------------------

    %=============================================================================
    % Reads AxS file 
    % --------------
    % NOTE: Uses the non-PDS compliant first row
    % of column headers to label variables (struct fields).
    % NOTE: Returns only strings. No conversion strings-to-numbers since that
    % would involve interpreting the meaning of values.
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
            
            if isfield(data, skey)
                error('Trying to add the same structure field name a second time.');
                skey
                data
            end
            data.(skey) = strtrim(file_data(1:end, i));     % NOTE: Trimming and copying strings. No conversion strings-to-numbers.
        end
 
        N_rows = N_rows - 1;    % Return number of rows of data, not lines in the file.
    end
    
    % ---------------------------------------------------------------------
    
end
