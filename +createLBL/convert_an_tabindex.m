%
% Create structure versions of tabindex and an_tabindex (cell arrays; prefix s=struct) for easier-to-use data structures.
%
%
% ARGUMENTS
% =========
% an_tabindex  : Cell array defined by other Lapdog code. Empty (0x0) is interpreted as 0x9.
%
%
% RETURN VALUES
% =============
% san_tabindex : Struct version of an_tabindex. Every field is a cell array corresponding to one
%                column in an_tabindex.
%
%
%
% NOTE: The conversion must work for cell arrays with zero rows (cell(9,0)) and cell arrays with one item (cell(9,1)).
% NOTE: Old createLBL.m code contained a check for whether the tabindex{i,9} (i_index_last) was empty (the cell array
% component, not the whole cell array). Why?
% Could not find any occurences of error message in any of the lap_agility logs (covering time interval 2014-06-13 -- 2016-06-16). /2016-06-16
% NOTE: Old code contained precautions for the cases that an_tabindex was empty. Why? Remove? Assertion?
function san_tabindex = convert_an_tabindex(an_tabindex)

    %=============
    % an_tabindex
    %=============    
    % (Not assertion)
    if isempty(an_tabindex)
        warning('an_tabindex is an EMPTY variable (0x0 array). - Modifying');
        an_tabindex = cell(0, 9);
    end

    san_tabindex = struct(...
        'path',                an_tabindex(:, 1), ...   % Full path to file, including filename.
        'filename',            an_tabindex(:, 2), ...   % Filename, without parent directory.
        'i_index',             an_tabindex(:, 3), ...   % Index into "index". Change name? i_index_first/last?
        'N_TAB_file_rows',     an_tabindex(:, 4), ...
        'N_TAB_columns',       an_tabindex(:, 5), ...
        'i_tabindex',          an_tabindex(:, 6), ...
        'data_type',           an_tabindex(:, 7), ...
        'unused_here',         an_tabindex(:, 8), ...
        'N_TAB_bytes_per_row', an_tabindex(:, 9) ...
        );

end