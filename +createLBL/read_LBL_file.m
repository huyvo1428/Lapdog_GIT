%
% Read ODL/LBL file "header", i.e. all the keywords from the beginning of
% the file up until the first OBJECT statement.
%
%
% ARGUMENTS AND RETURN VALUES
% ===========================
% deleteHeaderKeyList : Cell array of keywords which are excluded from HeaderKvpl, if found.
% HeaderKvpl          : Key-value (pair) list. Quotes are kept. 
% LblSs               : Full LBL content on simple struct (SS) format. Quotes are removed
%
function [HeaderKvpl, LblSs] = read_LBL_file(filePath, deleteHeaderKeyList)
%
% PROPOSAL: Change name to something implying only reading EDDER/CALIB1 (pds) LBL files.
%   CON: There is nothing in its function that prevents it from reading other LBL files.
%
% PROPOSAL: Remove all quotes from values in header.
%    CON: createLBL.write_LBL_header must determine which keys should have quotes. ==> Another long list which might not capture all keywords.
%       CON?: createLBL.write_LBL_header no longer exists and has no counterpart?
%
% PROPOSAL: Replace deleteHeaderKeyList with ~of regexes for permitted header keys.
%   Should only need to read ROSETTA:* and timestamps (STOP_TIME etc), INSTRUMENT_MODE_*.
%   Returning SS (simple struct; not SSL) is equivalent to returning timestamps on easy-to-use format.
%
% PROPOSAL: Use whitelist+blacklist (as regexps). Every keywords must match.
%   CON: Somewhat long blacklist (all universal keywords).

    % NOTE: LblSsl keeps   quotes.
    %       LblSs  removes quotes.
    [LblSsl, LblSs] = EJ_lapdog_shared.PDS_utils.read_ODL_to_structs(filePath);   % Read CALIB LBL file.
    HeaderKvpl = [];
    HeaderKvpl.keys   = LblSsl.keys  (1:end-1);    % NOTE: LblSsl includes OBJECT = TABLE as last key-value pair.
    HeaderKvpl.values = LblSsl.values(1:end-1);
    
    %for i = 1:length(HeaderKvpl.values)
    %    value = HeaderKvpl.values{i};
    %    HeaderKvpl.values{i} = value(value ~= '"');    % Remove all quotes.
    %end
    
    HeaderKvpl = EJ_lapdog_shared.utils.KVPL.delete_keys(HeaderKvpl, deleteHeaderKeyList, 'may have keys');
end
