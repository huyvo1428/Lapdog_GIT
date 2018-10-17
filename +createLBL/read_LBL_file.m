%
% Read ODL/LBL file "header", i.e. all the keywords from the beginning of
% the file up until the first OBJECT statement.
%
%
% ARGUMENTS AND RETURN VALUES
% ===========================
% deleteHeaderKeyList : Cell array of keys which are removed from HeaderKvl, if found.
% HeaderKvl           : Key-value (pair) list. Quotes are kept. 
% LblSs               : Quotes are removed
%
function [HeaderKvl, LblSs] = read_LBL_file(filePath, deleteHeaderKeyList)
%
% PROPOSAL: Change name to something implying only reading EDDER/CALIB1 LBL files.
%
% PROPOSAL: Remove all quotes from values in header.
%    CON: createLBL.write_LBL_header must determine which keys should have quotes. ==> Another long list which might not capture all keywords.
%
% PROPOSAL: Replace deleteHeaderKeyList with ~of regexes for permitted header keys.
%   Should only need to read ROSETTA:* and certain hardcoded constants (?) like PRODUCER_FULL_NAME, LABEL_REVISION_NOTE (?),
%   INSTRUMENT_HOST_NAME, MISSION_NAME etc.

    % NOTE: LblSsl keeps   quotes.
    %       LblSs  removes quotes.
    [LblSsl, LblSs] = EJ_lapdog_shared.PDS_utils.read_ODL_to_structs(filePath);   % Read CALIB LBL file.
    HeaderKvl = [];
    HeaderKvl.keys   = LblSsl.keys  (1:end-1);    % NOTE: LblSsl includes OBJECT = TABLE as last key-value pair.
    HeaderKvl.values = LblSsl.values(1:end-1);
    
    %for i = 1:length(HeaderKvl.values)
    %    value = HeaderKvl.values{i};
    %    HeaderKvl.values{i} = value(value ~= '"');    % Remove all quotes.
    %end
    
    HeaderKvl = EJ_lapdog_shared.utils.KVPL.delete_keys(HeaderKvl, deleteHeaderKeyList, 'may have keys');
end
