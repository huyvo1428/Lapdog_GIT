%
% Read ODL/LBL file "header", i.e. all the keywords from the beginning of
% the file up until the first OBJECT statement.
%
% ARGUMENTS AND RETURN VALUES
% ===========================
% HeaderKvl           : Key-value (pair) list
% deleteHeaderKeyList : Cell array of keys which are removed if found (must not be found).
% 
%
function [HeaderKvl, SimpleStruct] = read_LBL_file(filePath, deleteHeaderKeyList)
%
% PROPOSAL: Change name to something implying only reading CALIB LBL files?
%
% PROPOSAL: Remove all quotes from values.
%    CON: createLBL.write_LBL_header must determine which keys should have quotes. ==> Another long list which might not capture all keywords.

    % NOTE: LblSsl       keeps   quotes.
    %       SimpleStruct removes quotes.
    [LblSsl, SimpleStruct] = EJ_lapdog_shared.PDS_utils.read_ODL_to_structs(filePath);   % Read CALIB LBL file.
    HeaderKvl = [];
    HeaderKvl.keys   = LblSsl.keys  (1:end-1);    % NOTE: LblSsl includes OBJECT = TABLE as last key-value pair.
    HeaderKvl.values = LblSsl.values(1:end-1);
    
    %for i = 1:length(HeaderKvl.values)
    %    value = HeaderKvl.values{i};
    %    HeaderKvl.values{i} = value(value ~= '"');    % Remove all quotes.
    %end
    
    HeaderKvl = EJ_lapdog_shared.utils.KVPL.delete_keys(HeaderKvl, deleteHeaderKeyList, 'may have keys');
end
