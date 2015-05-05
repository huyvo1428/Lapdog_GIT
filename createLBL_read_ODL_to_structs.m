%
% Read ODL/LBL file and return contents in the form of two recursive structs:
%
% 1) "simple struct": Struct with fields corresponding to ODL keys and values corresponding
%    to ODL values, converted to matlab numbers and strings without quotes.
%    ODL OBJECTS segments are stored as similar structs (recursively).
%
% 2) "string-list struct": Struct with ODL keys/values as arrays of strings, ODL OBJECT statements
%    recursively in list of such objects.
%
% The latter preserves correctly formatted, non-implicit ODL contents (keys/values) "exactly",
% while the former does not but is easier to work with instead.
% Examples of differences: conversion from ODL strings to matlab numbers,
% quotes around ODL values, colons and circumflexes in ODL keys.
%
% NOTE: Only handles the ODL formatted content, not content pointed to by it.
%
% NOTE: s_simple always removes quotes around string values.
%
% NOTE: Simple structs preserve order of OBJECT for same type (COLUMN, TABLE etc) on the same
% recursive level ("branch") but not their location in any other way, e.g. if switching between OBJECT types.
% String-list structs preserve exact order of everything.
%
% NOTE: Simple structs always puts "substructures" (OBJECT...END_OBJECT) in cell arrays,
% whether there is only one or several substructures (of same type) for consistency
% (good for loops with arbitrary number of iterations).
% Therefore one has to always use one index to break out of the cell, even
% if there is only one "substructure", e.g.
% "s.OBJECT___TABLE{1}.OBJECT___COLUMN{5}".
%
% NOTE: Can not handle ODL values that span multiple lines (and which ODL does permit).
%
% NOTE: Does not check whether/handle if key values occur multiple times, except OBJECT
% for which arrays are used.
%
% NOTE: Does not check if there are too many END_OBJECT (only checks the
% reverse).
%
%
%
% NOTE: Adapted from pre-existing general-purpose tool "read_ODL_to_structs" for reading ODL
% files by Erik P G Johansson, IRF Uppsala. May therefore be somewhat overkill for the purposes of lapdog.
% Initially created 2014-11-18.
%
function [s_str_lists, s_simple] = createLBL_read_ODL_to_structs(file_path)
%
% NOTE: Having functions not inside the functions from which they are
% called means variables are local to functions and not shared.
%
% QUESTION: How handle ODL format errors?
%
% PROPOSAL: Check for reading the same ODL key/field twice.
%
% PROPOSAL: Somehow keep distinguishing between ODL keys with/without quotes?!!
% PROPOSAL: Flag for keeping/removing quotes around string values.
%
% PROPOSAL: Flag for error modes: error, quit & warning.
%
    kv_list = read_keys_values_list_INTERNAL(file_path);
    [s_str_lists, s_simple, i_last] = construct_structs_INTERNAL(kv_list, 1);

    %----------------------------------------------------------------------

    function kv_list = read_keys_values_list_INTERNAL(file_path)
    %
    % kv = key-value (pair)
    %
    % PROPOSAL: Check for error, not reading file.
    % QUESTION: Should kv_list be a...
    %      1) cell array of structures, or
    %      2) structure with cell array fields?
    %      3) both (return both)?!!
    % PROPOSAL: Parameter for how to handle errors/warnings.
    % PROPOSAL: Name "read_ODL_file_key_values"
    % PROPOSAL: Use textscan for parsing, e.g. textscan(line_list{i}, '%s = %s');
    %    CON: It interprets space (in the formatting string) as one
    %         or more spaces/tabs etc (but not zero spaces).
    %    CON: It chooses the last "=" if there are several.
    %    ==> Do not use textscan.
    % PROPOSAL: Use textscan for reading list of lines (no parsing of lines).
    %    (CON: Must fopen/fclose.)
    % QUESTION: How handle file format errors (and not only related to ODL)?

        % Check if file exists.
        % ---------------------
        % It is useful for the user to know which LBL file is missing so that he/she can more quickly 
        % determine where in pds or lapdog the original error lies (e.g. a LBL file produced by pds, 
        % or lapdog code producing or I2L.LBL files, or A?S.LBL files, or EST.LBL files).
        if (exist(file_path) ~= 2)
            error(sprintf('Can not find file: "%s"', file_path))
        end        
        line_list = importdata(file_path, '\n');      % Read list of lines/rows. No parsing.

        kv_list.keys   = cell(length(line_list), 1);
        kv_list.values = cell(length(line_list), 1);

        i_kv = 0;
        i_line = 1;
        for i_line = 1:length(line_list)

            % disp('----- New iteration -----')    % DEBUG

            str = strtrim(line_list{i_line});

            if (strcmp(str, ''))
                continue
            elseif (strcmp(str, 'END'))
                i_kv = i_kv + 1;
                kv_list.keys{i_kv}   = str;
                kv_list.values{i_kv} = [];
                break
            end
            ieq = find(str == '=');
            if (length(ieq) < 1)
                error(['Can not interpret line: found no equal sign: ', str])
                continue
            end
            ieq = ieq(1);    % Extract _FIRST_ equal sign.
            if (ieq < 2)
                error(['Can not interpret line: found first equal sign too early: ', str])
                continue
            end        

            str_L = strtrim(str(1:ieq-1));    % Remove leading and trailing whitespace and null characters (e.g. indentation). 
            str_R = strtrim(str(ieq+1:end));

            if length(str_L) < 1
                error('Empty key string.');
            end
            
            i_kv = i_kv + 1;
            kv_list.keys{i_kv}   = str_L;        
            kv_list.values{i_kv} = str_R;

            % DEBUG
            %disp(['Reconstructed line : ', str_L, ' === ', str_R])
        end

        % Remove unused entries (since these are preallocated variables).
        kv_list.keys   = kv_list.keys(1:i_kv);
        kv_list.values = kv_list.values(1:i_kv);
        
    end

    %----------------------------------------------------------------------
    % Convert lists of keys and values (strings; kv_list.keys, kv_list.values)
    % from an ODL file into two structs, each representing the entire file contents.
    % Assumes complete kv_list for entire file, but will only analyze the "tree"
    % which has its "root" at i_first, i.e. between "OBJECT = ..." and corresponding "END_OBJECT = ...".
    %----------------------------------------------------------------------    

    function [s_str_lists, s_simple, i_last] = construct_structs_INTERNAL(kv_list, i_first)

        s_simple = [];
        %
        s_str_lists             = [];
        s_str_lists.keys        = {};
        s_str_lists.values      = {};
        %s_str_lists.object_type = [];
        s_str_lists.objects     = {};



        i = i_first;
        while (i <= length(kv_list.keys))

            key = kv_list.keys{i};
            value = kv_list.values{i};        
            %disp(['Reconstructed line : ', key, ' === ', value])  % DEBUG

            if strcmp(key, 'OBJECT')
                
                [ss_str_lists, ss_simple, i_last] = construct_structs_INTERNAL(kv_list, i+1);    % NOTE: Recursive call.
                
                %--------------
                % Error checks
                %--------------
                if ~strcmp(kv_list.keys{i_last}, 'END_OBJECT')
                    error('Found OBJECT statement without corresponding END_OBJECT statement.')
                end
                if ~strcmp(kv_list.values{i_last}, value)
                    error('OBJECT value does not match END_OBJECT value.')
                end
                                
                i = i_last;                
                
                %-----------------
                % Update s_simple
                %-----------------
                skey = ['OBJECT___', value];
                
                if isfield(s_simple, skey)
                    s_simple.(skey){end+1} = ss_simple;
                else
                    s_simple.(skey) = {ss_simple};
                end                
                
                %---------------------
                % Update ss_str_lists
                %---------------------
                s_str_lists.keys{end+1}    = key;
                s_str_lists.values{end+1}  = value;
                s_str_lists.objects{end+1} = ss_str_lists;                
                
            elseif sum(strcmp(key, {'END_OBJECT', 'END'}))
                
%                 if strcmp(key, 'END')
%                     s_str_lists.keys{end+1}    = key;
%                     s_str_lists.values{end+1}  = value;
%                     s_str_lists.objects{end+1} = [];
%                 end
                
                % Make s_str_lists' fields column vectors.
                s_str_lists.keys    = s_str_lists.keys';
                s_str_lists.values  = s_str_lists.values';
                s_str_lists.objects = s_str_lists.objects';
        
                i_last = i;
                return                 % NOTE: Exit function (recursive calls).
                
            else
                skey   = derive_struct_key(key);
                svalue = derive_struct_value(value);
                s_simple.(skey) = svalue;
                
                s_str_lists.keys{end+1}    = key;
                s_str_lists.values{end+1}  = value;
                s_str_lists.objects{end+1} = [];
            end

            i = i+1;

        end   % while
        
        error('ERROR: Reached end of ODL data without finding END statement.')

    end
        
    %----------------------------------------------------------------------    
    
    function skey = derive_struct_key(key)
        skey = strrep(key, ':', '___');
        if key(1) == '^'
            skey = ['POINTER___', key(2:end)];   % The "^" feature is called "Pointer statement" in ODL.
        end
    end

    %----------------------------------------------------------------------    

    function svalue = derive_struct_value(value)
        n = length(value);
        if n < 1
            svalue = [];                    % NOTE: [] is not a string (ischar() returns false).
            %error('Finds no value for ODL key.')
            
        elseif (n >= 2) && (value(1) == '"') && (value(end) == '"')     % if string surrounded by quotes ...
            
            svalue = value(2:end-1);        % Keep as string. NOTE: ALWAYS removes quotes around string, if the quotes can be found.
            
        elseif strcmp(value, 'NaN')
            
            svalue = NaN;
            
        else
            
            svalue = str2double(value);     % NOTE: Both the string "NaN" and non-numerically interpretable strings return NaN.
            if isnan(svalue)
                svalue = value;             % Keep as string.
            end
            
        end
    end
end
