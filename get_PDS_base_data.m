% Initially created by Erik P G Johansson, IRF Uppsala, 2016-08-01.
%
% Either interpret
%
% ARGUMENTS
% =========
% base_data: Structure with fields describing a specific data set to which fields will be added.
%    The argument must have a certain set of struct fields. Either
%    (1) .VOLUME_ID_nbr_str
%        .DATA_SET_ID,
%    or the same information expressed as separate PDS "keywords", i.e.
%    (2) .VOLUME_ID_nbr_str
%        .DATA_SET_NAME_target
%        .PROCESSING_LEVEL_ID
%        .mission_phase_abbrev
%        .DATA_SET_ID_descr
%        .version_str.
%
% RETURN VALUES
% =============
% base_data : All the fields of the argument "base_data", both (1) and (2).
%
%
% IMPLEMENTATION NOTE: The function requires base_data.VOLUME_ID_nbr_str to be "compatible" with "get_PDS_data".
% Should possibly be moved to "get_PDS_data" some time.
%
function base_data = get_PDS_base_data(base_data)
    % PROPOSAL: Split up into functions that
    %   1) Split up DATA_SET_ID
    %   2) Assemble DATA_SET_ID
    %   NOTE: Not obvious that this works well with the usage, and with get_PDS_data.
    % PROPOSAL: Remove VOLUME_ID_nbr_str from function.
    

    %===================================================================
    % Derive the fields the function does not have from the ones it has
    %===================================================================
    base_fields1 = {'VOLUME_ID_nbr_str', 'DATA_SET_ID_target_ID', 'PROCESSING_LEVEL_ID', 'mission_phase_abbrev', 'DATA_SET_ID_descr', 'version_str'};
    base_fields2 = {'VOLUME_ID_nbr_str', 'DATA_SET_ID'};
    %if isempty(setdiff(fieldnames(base_data), base_fields1))
    if isempty(setxor(fieldnames(base_data), base_fields1))
        
        base_data.DATA_SET_ID = sprintf('RO-%s-RPCLAP-%s-%s-%s-V%s', ...
            base_data.DATA_SET_ID_target_ID, ...
            base_data.PROCESSING_LEVEL_ID, ...
            base_data.mission_phase_abbrev, ...
            base_data.DATA_SET_ID_descr, ...
            base_data.version_str);
        
    %elseif isempty(setdiff(fieldnames(base_data), base_fields2))
    elseif isempty(setxor(fieldnames(base_data), base_fields2))
        
        [   base_data.DATA_SET_ID_target_ID, ...
            base_data.PROCESSING_LEVEL_ID, ...
            base_data.mission_phase_abbrev, ...
            base_data.DATA_SET_ID_descr, ...
            base_data.version_str] ...
            = ...
            strread(base_data.DATA_SET_ID, 'RO-%[^-]-RPCLAP-%[^-]-%[^-]-%[^-]-V%[^-]');
        for f = {'DATA_SET_ID_target_ID', 'PROCESSING_LEVEL_ID', 'mission_phase_abbrev', 'DATA_SET_ID_descr', 'version_str'}
            base_data.(f{1}) = base_data.(f{1}){1};
        end
        
    else
        error('The input data variable has a disallowed set of fields.')
    end
end
