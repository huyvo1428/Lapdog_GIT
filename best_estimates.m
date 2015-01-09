% Create TAB files containing the current best estimates of plasma parameters.
% 
% NOTE: Very preliminary best estimates (physics).
% NOTE: Presently only based on probe 1 sweeps, one estimate per (probe 1) sweep.
%
% IMPORTANT NOTE: Uses the non-PDS compliant first row
% of column headers in AxS to label variables (struct fields).
% When that becomes PDS compliant, this code WILL NOT WORK!
%    
% IMPORTANT NOTE: Uses file existence to check for existence of pre-sweep low-freq. bias potential.

function an_tabindex = best_estimates(an_tabindex, tabindex, index, obe)

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
% NOTE: In principle: Not one EST file per A1S/A2S file, but
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
%
% PROPOSAL: Change to model with all sweep analysis data in one table (add probe number field to distinguish probes)
% PROPOSAL: Change to using cell arrays instead of structs with array fields.
%     data.data, data.col_names
%     PROPOSAL: Separate cell arrays for strings and numeric values.
%         PRO: Can easily search/select sweeps depending on parameters (time, direction, probe). 
%
% TODO: Check whether to expect low-freq bias potential using macro, instead of checking file existence?
%
% TODO: Remove references to "et" times. Use OBT.
%===========================================================================================

    an_tabindex = main_INTERNAL(an_tabindex, tabindex, index, obe);

    % ---------------------------------------------------------------------
    
    % UNFINISHED
    function an_tabindex = main_INTERNAL(an_tabindex, tabindex, index, obe)

        nob = length(obe);
  
        
        
        %------------------------------------------------------------------------------
        % Create table of data from resp. probes. Table has indicies (<ops block>, <probe number>).
        % NOTE: Not all entries will necessarily be assigned.
        % Some ops blocks may not contain sweeps, some may sweep on only one probe, or none.
        %------------------------------------------------------------------------------
        i_ant_list = find(strcmp(an_tabindex(:,7), 'sweep'));   % ant = "an_tabindex"
        PO_table = cell(nob, 2);               % PO = probe-operations block. Data for one probe during one ops block.
        O_list = cell(nob, 1);                 % O  = operations block. Data for one operations block (in practice EST, if contains sweeps).
        for i_ant = i_ant_list(:)'      % for every 'sweep' file ...   (List of values must be row vector for iteration to work.)
            PO = [];
            PO.i_ant = i_ant;
            
            % Find i_ob and i_probe.
            i_ind = an_tabindex{i_ant, 3};                  % ind = "index" (the index of CALIB files)
            i_ob = find(obe >= i_ind, 1);                   % ob = Operations block.
            i_probe = index(an_tabindex{i_ant, 3}).probe;
            
            % Determine AxS, EST, IxL filenames & paths.
            % NOTE: Ugly. Uses previous file name/path.
            AxS_file_path = an_tabindex{i_ant, 1};
            AxS_file_name = an_tabindex{i_ant, 2};
            EST_file_path = AxS_file_path;
            EST_file_path(end-6:end-4) = 'EST';
            EST_file_name = AxS_file_name;
            EST_file_name(end-6:end-4) = 'EST';
            IxL_file_path = AxS_file_path;
            IxL_file_path(end-6:end-4) = sprintf('I%iL', i_probe);
            IxH_file_path = AxS_file_path;
            IxH_file_path(end-6:end-4) = sprintf('I%iH', i_probe);

            [PO.data, N_sw] = read_AxS_file_INTERNAL(AxS_file_path, i_probe);
            
            % Add most recent low frequency bias potential before every individual sweep.
            % ---------------------------------------------------------------------------
            % (Might not be relevant if sweep is preceeded by other sweep but that is not decided here in the code.)
            % NOTE: Special case: First sweep might not have a preceeding low freq. bias potential in the same ops block.            
            % NOTE: Special case: It takes time to change/set bias and the immediately following value(s) may be faulty.
            % 
            % IMPORTANT NOTE: Code uses tabindex to check for existence of pre-sweep LF/HF data. TODO: Change?
            %
            IxLH_data = [];
            if     sum(strcmp({tabindex{:,1}}, IxL_file_path))
                IxLH_data = read_IxLH_file_bias_voltage_INTERNAL(IxL_file_path, i_probe);
            elseif sum(strcmp({tabindex{:,1}}, IxH_file_path))
                IxLH_data = read_IxLH_file_bias_voltage_INTERNAL(IxH_file_path, i_probe);
            end
            if ~isempty(IxLH_data)
                for i_sw = 1:N_sw
                    i_IxLH = find(IxLH_data.TIME_OBT < PO.data.START_TIME_OBT(i_sw), 1, 'last');    % Intermediate value, for clarity and debugging.
                    if ~isempty(i_IxLH)
                        PO.data.V_LF_HF_before_sweep(i_sw, 1) = IxLH_data.V_bias(   i_IxLH   );
                    else
                        PO.data.V_LF_HF_before_sweep(i_sw, 1) = NaN;
                    end
                end
            else
                PO.data.V_LF_HF_before_sweep = zeros(N_sw, 1) + NaN;
            end
            
            
            
            % NOTE: May overwrite the component with the same EST path (but that is not a problem).
            O_list{i_ob}.EST_file_path = EST_file_path;
            O_list{i_ob}.EST_file_name = EST_file_name;
            
            PO_table{i_ob, i_probe} = PO;            
        end

        
        
        %---------------------------------------------------------------------
        % Iterate over operations blocks and ignore those without sweep data,
        % i.e. iterate over EST files.
        %---------------------------------------------------------------------
        for i_ob = 1:nob    % for every ops block ...
            
            
            %----------------------------------------------------------
            % DEBUG:
            % Filter out sweeps to test code.
            %PO_table{i_ob, 1} = [];
            %----------------------------------------------------------            
            
            PO1 = PO_table{i_ob, 1};
            PO2 = PO_table{i_ob, 2};
            
            if isempty(PO1) && isempty(PO2)
                continue
            end



            %------------------------------------
            % Compile all sweeps into one table.
            %------------------------------------
            sweep_data = [];
            if ~isempty(PO1)
                sweep_data = PO1.data;
            end
            if ~isempty(PO2)
                sweep_data = merge_structs_arrays_INTERNAL({sweep_data, PO2.data});
            end
            N_sw = length(sweep_data.MIDDLE_TIME_OBT);

            
            
            %--------------------------------
            % Derive best estimates ("est").
            %--------------------------------
            sim_sweep_data_grps_list = group_simultaneous_sweeps_INTERNAL(sweep_data);
            N_grps = length(sim_sweep_data_grps_list);
            if (N_grps == 0)                
                % In case there are not enough sweeps for a single group of sweeps, do not even try to
                % create an EST file. The below code would break anyway as "est_sweep_data" will
                % contain no fields.
                % NOTE: If no EST file is produced there should also be no LBL file.
                % ---------------------------------------------------------------------------------
                % I think the data archiving policy is that when there is no data,
                % there should also be no file. (Source?) /Erik P G Johansson 2015-01-08.
                fprintf(1, 'Too few sweeps in ops block for best estimates - skipping.\n')
                continue
            end
            
            est_sweep_data_grps_list = cell(N_grps, 1);
            for i_grp = 1:N_grps
                est_sweep_data_grps_list{i_grp} = select_best_estimates_INTERNAL(sim_sweep_data_grps_list{i_grp});
            end
            est_sweep_data = merge_structs_arrays_INTERNAL(est_sweep_data_grps_list);


            
            [row_bytes, N_columns, N_rows] = write_EST_file_INTERNAL(O_list{i_ob}.EST_file_path, est_sweep_data);            
            
            

            %------------------------------------------------------
            % Update an_tabindex.
            % -------------------
            % Time start/stop is the only one that is non-trivial.
            % Two values can not be set to anything (?).
            %------------------------------------------------------
            timing_start_list = [];
            timing_stop_list  = [];
            timing_list       = {};
            i_index           = [];
            for i_P = 1:2
                P = PO_table{i_ob, i_P};
                if ~isempty(P)
                    timing_start_list(end+1) = str2num(an_tabindex{P.i_ant, 8}{3});
                    timing_stop_list(end+1)  = str2num(an_tabindex{P.i_ant, 8}{4});
                    timing_list(end+1)       = an_tabindex(P.i_ant, 8);
                    i_index(end+1)           = an_tabindex{P.i_ant, 3};
                end
            end
            [junk, i_start] = min(timing_start_list);
            [junk, i_stop]  = max(timing_stop_list);
            an_tabindex_timing = { ...
                timing_list{i_start}{1}, ...
                timing_list{i_stop }{2}, ...
                timing_list{i_start}{3}, ...
                timing_list{i_stop }{4} ...
                };
            an_tabindex_amendment{1, 1} = O_list{i_ob}.EST_file_path;    % File path
            an_tabindex_amendment{1, 2} = O_list{i_ob}.EST_file_name;    % Filename
            an_tabindex_amendment{1, 3} = i_index;      % Index back to corresponding "index" file. ARRAY. Otherwise not meaningful?!!
            an_tabindex_amendment{1, 4} = N_rows;
            an_tabindex_amendment{1, 5} = N_columns;
            an_tabindex_amendment{1, 6} = [];               % Index back to corresponding "tabindex" file. - CAN NOT SET MEANINGFULLY?!!
            an_tabindex_amendment{1, 7} = 'best_estimates';
            an_tabindex_amendment{1, 8} = an_tabindex_timing;
            an_tabindex_amendment{1, 9} = row_bytes;
            an_tabindex(end+1, :) = an_tabindex_amendment;
        end
        
        %warning('Implementation of function not finished yet.')              % TEMPORARY
    end

    % ---------------------------------------------------------------------
    
    %------------------------------------------------------------------------------------------------
    % TASK TO BE SOLVED BY THIS FUNCTION:
    % Given a set of sweeps, return groups of approximately simultaneous sweeps for
    % "select_best_estimates_INTERNAL" to work on (one group at a time), i.e. what is relevant for.
    %
    % NOTE: The grouped sweeps should preferably/probably not overlap,
    % and preferably/probably together represent all sweeps.
    % This depends on the exact implementation of "select_best_estimates_INTERNAL".
    %
    % sim = simultaneous; sw = sweep
    %------------------------------------------------------------------------------------------------
    function [sim_sweep_data_grps_list] = group_simultaneous_sweeps_INTERNAL(sw_data)
    % QUESTION: How handle situation if number of sweeps is not an even multiple of natural "groups"? How handle such an ending?
    % QUESTION: Expect time-sorted data or sort oneself?    
    %
        
        N_sw = length(sw_data.MIDDLE_TIME_OBT);
                
        %--------------------
        % Sort data by time.
        %--------------------
        [junk, i_sort] = sort(sw_data.MIDDLE_TIME_OBT);
        sw_data = select_structs_arrays_INTERNAL(sw_data, i_sort);
        
        

        % Determine (1) which probes for which there is data, and (2) which probes for which there are pairs of sweeps.        
        has_Pi       = [];
        has_Pi_pairs = [];
        sw_data.pair_first = zeros(N_sw, 1);      % Index to next sweep in pair, if there is any.
        for i_P = 1:2
            i_Pi = find(sw_data.probe_nbr == i_P);
            has_Pi(i_P) = length(i_Pi);
            
            if has_Pi(i_P)
                j_swp1 = find(   sw_data.STOP_TIME_OBT(i_Pi(1:end-1)) == sw_data.START_TIME_OBT(i_Pi(2:end))   );    % j_swp1 : Sweeps which are first in pairs.
                sw_data.pair_first(i_Pi(j_swp1)) = 1;
                has_Pi_pairs(i_P) = length(j_swp1) > 0;
            else
                has_Pi_pairs(i_P) = 0;
            end
        end



        %--------------------------------------------------------------------------
        % Sort sweeps in groups.
        % Current algorithm will (intentionally) omit some sweeps for sufficiently
        % strange macros, but such macros probably do not exist. Should be robust.
        %--------------------------------------------------------------------------
        i_sw = 1;
        i_grp = 0;
        sim_sweep_data_grps_list = {};
        while true    % Iterate over groups of sweeps.

            Pi_complete = ~has_Pi;
            i_Pi_prev = [0, 0];      % Previous sweep for given probe.
            i_sw_group = [];
            while (~Pi_complete(1) | ~Pi_complete(2)) & (i_sw <= N_sw)     % Iterate over sweeps until one has collected a group of sweeps.

                for i_P = 1:2              % For every probe...
                    
                    if   ~Pi_complete(i_P)   &&   (sw_data.probe_nbr(i_sw) == i_P)
                        
                        if has_Pi_pairs(i_P)                            
                            if   (i_Pi_prev(i_P) ~= 0)   &&   sw_data.pair_first( i_Pi_prev(i_P) )
                             % If this sweep and preceeding sweep for the same probe are a pair...
                                i_sw_group(end+1) = i_Pi_prev(i_P);
                                i_sw_group(end+1) = i_sw;
                                Pi_complete(i_P) = 1;
                                i_Pi_prev(i_P) = 0;
                            else                            
                                i_Pi_prev(i_P) = i_sw;
                            end
                        elseif has_Pi(i_P)
                            i_sw_group(end+1) = i_sw;
                            Pi_complete(i_P) = 1;
                        else
                            Pi_complete(i_P) = 1;
                        end
                        
                    end
                end
                
                i_sw = i_sw + 1;                
                
            end



            if (i_sw > N_sw)
                break
            end
            
            sim_sweep_data = select_structs_arrays_INTERNAL(sw_data, i_sw_group');
            sim_sweep_data.sweep_group_nbr = ones(length(i_sw_group), 1) * i_grp;  % For debugging. Save which group every sweep belongs to.
            sim_sweep_data_grps_list{end+1} = sim_sweep_data;
            i_grp = i_grp + 1;
        end
        
        %error('FUNCTION NOT IMPLEMENTED YET.')
        
    end
    
    % ---------------------------------------------------------------------
    
    %-------------------------------------------------------------------------------------------------------------------------
    % TASK TO BE SOLVED BY THIS FUNCTION:
    % Given a set of sweeps sim_sweep_data which are to be regarded as "approximately simultaneous",
    % return a set of best estimates based upon them.
    % Exact assumptions for the set of sweeps in the argument depends on "group_simultaneous_sweeps_INTERNAL".
    %
    % CURRENT IMPLEMENTATION: Assumes 0-2 sweeps from each probe.
    % NOTE: Does not take into account that no value might be found on a selected probe & sweep (analysis returned no value).
    % If there are two sweeps on same probe, then they are a pair (immediately adjacent in time).
    % NOTE: Several index variables (values are indices into other variables) also function
    % as boolean flags ([] = false; 1 or greater = true), but one has to use ~isempty() to be sure they work as intended.
    % NOTE: It is possible to assign a variable at index [] without error. Nothing happens but MATLAB permits it.
    %-------------------------------------------------------------------------------------------------------------------------
    function data_est = select_best_estimates_INTERNAL(sim_sweep_data)

        data = sim_sweep_data;
        data.direction = str2double(data.direction);        
    
        % up/dn = up/down sweep.
        i_P1_up = find((data.probe_nbr == 1) & (data.direction == 1));
        i_P1_dn = find((data.probe_nbr == 1) & (data.direction == 0));
        
        i_P2_up = find((data.probe_nbr == 2) & (data.direction == 1));
        i_P2_dn = find((data.probe_nbr == 2) & (data.direction == 0));

        % Find index to first/second sweep in pair for P2.
        % p1/p2 = first/second sweep (of sweep pair on the same probe).
        % BUG: Can NOT handle only one sweep.    (false??? /2015-01-09)
        m = sort(find(data.probe_nbr == 2));     % ASSUMES: data/sweeps sorted in ascending time-order, so that index increases with time.
        i_P2_p1 = [];
        i_P2_p2 = [];
        if length(m) >= 1
            i_P2_p1 = m(1);
        end
        if length(m) == 2
            i_P2_p2 = m(2);
        end
        
        
        
        % ----------------------------
        % Select P1 sweep to use: i_P1
        % ----------------------------
        if     ~isempty(i_P1_up)
            i_P1 = i_P1_up;
        elseif ~isempty(i_P1_dn)
            i_P1 = i_P1_dn;
        else
            i_P1 = [];
        end
        
        

        % ----------------------------
        % Select P2 sweep to use: i_P2
        % ----------------------------
        % NOTE: Can probably be shortened if the idea is to select sweep with
        % preceeding voltage (low freq. bias or sweep) positive.
        % NOTE: Uses && so not to require i_P2_p1.
        has_P2_updn_pair = ~isempty(i_P2_p1) && (data.direction(i_P2_p1) == 1) && ~isempty(i_P2_p2) && (data.direction(i_P2_p2) == 0);   % NOTE: Uses && so not to require i_P2_p1.
        if has_P2_updn_pair && (data.V_LF_HF_before_sweep(i_P2_p1) > 0)
            i_P2 = i_P2_p2;
        elseif ~isempty(i_P2_up)
            i_P2 = i_P2_up;
        else
            i_P2 = i_P2_dn;
        end
        
        
        
        i_selected = [i_P1; i_P2];    % Sweeps selected to be used for best estimatas.
       
        % Clear fields that are to be used, both to be sure they exist and that they are "empty".
        data.npl_est = zeros(size(data.START_TIME_UTC)) + NaN;
        data.Te_est  = zeros(size(data.START_TIME_UTC)) + NaN;
        data.Vsc_est = zeros(size(data.START_TIME_UTC)) + NaN;



        % Choose probe to use for n_plasma, then select data.
        %
        % NOTE: Zero is a common non-sensical value for asm_ni_v_indep.
        % -------------------------------------------------------------
        data.asm_ni_v_indep = str2double(data.asm_ni_v_indep);
        if ~isempty(i_P2)   &&   ~isnan(data.asm_ni_v_indep(i_P2))    &&    (data.asm_ni_v_indep(i_P2) ~= 0)
            i = i_P2;
        else
            i = i_P1;
        end
        npl = data.asm_ni_v_indep(i);                       % NOTE: May assign/return empty matrix if i = [].
        if ~isempty(npl) && ~isnan(npl) && (npl ~= 0)            % Use value if not obviously nonsensical...
            data.npl_est(i) = npl;
        end

        

        % Choose probe to use for T_e & V_sc, then select data.
        % -----------------------------------------------------
        % NOTE: j_P = Probe number
        data.asm_Te_exp = str2double(data.asm_Te_exp);
        data.asm_Vsg    = str2double(data.asm_Vsg);
        if ~isempty(i_P2) && ~str2num(data.Illumination{i_P2})
            i = i_P2;
        elseif ~isempty(i_P1)
            i = i_P1;
        else
            i = i_P2;
        end
        data.Te_est(i)  = data.asm_Te_exp(i);
        data.Vsc_est(i) = data.asm_Vsg   (i);
        
        data_est = select_structs_arrays_INTERNAL(data, i_selected);
    end   

    % ---------------------------------------------------------------------    
    
    % NOTE: Can/should handle handle empty values in the form of [].
    %       str2double([]) = NaN,
    %       str2num([]) ==> Syntax error
    %       length(sprintf('%14.7e', NaN)) = 14
    %       length(sprintf('%14s',   [] )) = 14
    function [row_bytes, N_columns, N_rows] = write_EST_file_INTERNAL(EST_file_path, data)
    
        fprintf(1, 'Writing file: %s\n', EST_file_path);
        
        %--------------------
        % Sort data by time.
        %--------------------
        [junk, i] = sort(data.START_TIME_UTC);
        O_data = select_structs_arrays_INTERNAL(data, i);        
        N_rows = length(data.START_TIME_UTC);
        
        

        %----------------
        % Write to file.
        %----------------
        fid = fopen(EST_file_path, 'w');
        for i = 1:N_rows
            % NOTE: Most (but not all) variables are STRINGS!
            line = [];
            line = [line, sprintf('%s, %s, ',                 data.START_TIME_UTC{i}, data.STOP_TIME_UTC{i})];
            line = [line, sprintf('%16.6f, %16.6f, %s, ',     data.START_TIME_OBT(i), data.STOP_TIME_OBT(i),   data.Qualityfactor{i})];
            line = [line, sprintf('%14.7e, %14.7e, %14.7e, ', O_data.npl_est(i), O_data.Te_est(i), O_data.Vsc_est(i))];
            
            line = [line, sprintf('%1i, ', data.probe_nbr(i))];             % DEBUG
            line = [line, sprintf('%5i',   data.sweep_group_nbr(i))];       % DEBUG
            line = strrep(line, 'NaN', '   ');
            N_columns = 8+1+1;
            row_bytes = fprintf(fid, [line, '\n']);
            
            %disp(line)                     % DEBUG. Preferably no extra linebreak in string.
        end
        fclose(fid);
        
    end

    % ---------------------------------------------------------------------

    %=============================================================================
    % Reads AxS file 
    % --------------
    % IMPORTANT NOTE: Uses the non-PDS compliant first row
    % of column headers in AxS to label variables (struct fields).
    % When that becomes PDS compliant, this code WILL NOT WORK!
    % ---------------------------------------------------------
    % NOTE: Returns only strings, except for added fields.
    % No conversion strings-to-numbers since that
    % would involve interpreting the meaning of values.
    % -------------------------------------------------------
    % Quite general function for files with first row as column headers. Could in
    % principle be repurposed as a general function for general use.
    %=============================================================================
    function [data, N_rows] = read_AxS_file_INTERNAL(file_path, probe_nbr)
    % 
    % PROPOSAL: Assume all (unspecified) fields are numerical and convert to numeric.
    % PROPOSAL: Remove return value N_rows?
    % 
    % PROPOSAL: Rename _et to _arbitrary since probably no particular offset/origin and misleading.
    
        line_list = importdata(file_path, '\n');               % Read file into cell array, one line per cell.
        line_value_list = regexp(line_list, ',', 'Split');     % Split strings using delimiter.
        value_list = vertcat(line_value_list{:});              % Concatenate (cell) array of (cell) arrays to create one long vector (Nx1).
    
        N_rows = length(line_value_list);
        N_cols = length(line_value_list{1});                   % NOTE: Requires at least one row.
        file_contents = reshape(value_list, N_rows, N_cols);   % Derive 2D table from 1D vector. NOTE: Incomplete test of equal number of columns per line.
        
        N_rows = N_rows - 1;                         % Number of rows of DATA (excluding first line of column headers).
        file_column_name_list = file_contents(1,:);
        file_data             = file_contents(2:end, :);

        data = [];
        for i = 1:N_cols     % For every column ...
            % DEBUG
            %disp(['i = ', num2str(i)])
            %disp(['file_column_name_list{i} = ', file_column_name_list{i}])
            
            col_name = file_column_name_list{i};    % skey = struct key/field name
            skey = strrep(col_name, '(', '_');
            skey = strrep(skey,     ')', '' );     % NOTE: Remove right bracket (as opposed to left bracket which is replaced).
            skey = strrep(skey,     '=', '' );
            skey = strrep(skey,     '.', '_');
            skey = strrep(skey,     ' ', '' );
            
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
 
        
        % Add extra fields that may be needed by algorithms that choose information from
        % the different probes at only approximately the same time.
        %---------------------------------------------------------------------------------------
        %for i_row = 1:N_rows
        %    START_TIME_et(i_row, 1) = cspice_str2et(data.START_TIME_UTC(i_row));
        %    STOP_TIME_et(i_row, 1)  = cspice_str2et(data.STOP_TIME_UTC(i_row));
        %end
        %data.START_TIME_et = START_TIME_et;    % NOTE: Adds additional field.
        %data.STOP_TIME_et  = STOP_TIME_et;     % NOTE: Adds additional field.
        %data.MIDDLE_TIME_et = (START_TIME_et + STOP_TIME_et) * 0.5;    % NOTE: Adds additional field.
        data.START_TIME_OBT = str2double(data.START_TIME_OBT);
        data.STOP_TIME_OBT  = str2double(data.STOP_TIME_OBT);        
        data.MIDDLE_TIME_OBT = (data.START_TIME_OBT + data.STOP_TIME_OBT) * 0.5;    % NOTE: Adds additional field.
        data.probe_nbr = zeros(N_rows, 1) + probe_nbr;
    end

    % ---------------------------------------------------------------------
    
    % WARNING: Relies on hardcoded column numbers.
    % IxL and IxH files have the same format.
    function data = read_IxLH_file_bias_voltage_INTERNAL(file_path, probe_nbr)
        %[file_contents, N_rows, N_cols] = read_TAB_file_INTERNAL(file_path);
        %data.TIME_UTC  =            file_contents(:, 1);     % Useful for inspecting variables when debugging?
        %tic
        %N_rows
        %file_path
        %data.TIME_OBT_str = strtrim(   file_contents(:, 2));
        %data.TIME_OBT     = str2double(file_contents(:, 2));
        %data.V_bias_str   = strtrim(   file_contents(:, 4));
        %data.V_bias       = str2double(file_contents(:, 4));
        %toc
        
        
        
        % Read file
        % ---------
        % Letting textscan parse numbers is much faster (about ~7 times)
        % than doing so manually with str2double after having read file into strings.
        % IxL files can be so large that speed matters.
        fid = fopen(file_path, 'r');
        if fid < 0
            warning(sprintf('Can not read file: %s', file_path))
        end
        %fprintf(1, 'Reading file: %s\n', file_path)
        file_contents = textscan(fid, '%s%f%s%f%s', 'delimiter', ',');        
        N_rows = length(file_contents{1});
        fclose(fid);
        
        
        data.UTC_TIME = file_contents{1};    % For debugging.
        data.TIME_OBT = file_contents{2};
        data.V_bias   = file_contents{4};               
        
        

        % Add extra fields that may be needed by algorithms.
        data.probe_nbr = zeros(N_rows, 1) + probe_nbr;
%        t = tic;
%        for i_row = 1:N_rows
%            data.TIME_et(i_row, 1) = cspice_str2et(data.TIME_UTC{i_row});    % Very slow for large files.
%        end
%        toc(t)
    end
    
    % ---------------------------------------------------------------------
    
    % Generic utility function.
    % s_list : 1D cell array, where every component is either a structs or empty.
    % Every struct has the same set of fields of the same type.
    % All fields within a struct are same-sized column vectors.
    %
    % NOTE: Treats empty matrices, [], as empty structures.
    function s_merged = merge_structs_arrays_INTERNAL(s_list)
    % PROPOSAL: Use vararg instead of cell array.
    % PROPOSAL: Require empty structs (created with "struct" command), not empty matrices.
    %
        s_merged = [];
        for i = 1:length(s_list)
            if ~isempty(s_list{i})
                s = s_list{i};
                
                if isempty(s_merged)
                    s_merged = s;
                else
                    for fnc = fieldnames(s)'
                        fn = fnc{1};
                        s_merged.(fn) = [s_merged.(fn);  s.(fn)];
                    end
                end
            end
        end   % for
    end

    % ---------------------------------------------------------------------
    
    % Generic utility function
    function s = select_structs_arrays_INTERNAL(s, i)
        for fn = fieldnames(s)'
            s.(fn{1}) = s.(fn{1})(i, 1);
        end
    end
    
end
