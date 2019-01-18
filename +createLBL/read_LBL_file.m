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
function [HeaderKvpl, LblSs] = read_LBL_file(filePath)
%
% PROPOSAL: Change name to something implying only reading EDDER/CALIB1 (pds) LBL files.
%   CON: There is nothing in its function that prevents it from reading other LBL files.
%       CON: Use of DONT_READ_HEADER_KEY_LIST implies specialized use.
%   PROPOSAL: read_PLKS_file
%
% PROPOSAL: Replace deleteHeaderKeyList with ~of regexes for PERMITTED header keys.
%   Should only need to read ROSETTA:* and timestamps (STOP_TIME etc), INSTRUMENT_MODE_*.
%   Returning SS (simple struct; not SSL) is equivalent to returning timestamps on easy-to-use format.
%
% PROPOSAL: Use whitelist+blacklist (as regexps). Every keywords must match.
%   CON: Somewhat long blacklist (all universal keywords).
%
% PROPOSAL: Move DONT_READ_HEADER_KEY_LIST to constants.

    DONT_READ_HEADER_KEY_LIST = {'FILE_NAME', '^TABLE', 'PRODUCT_ID', 'RECORD_BYTES', 'FILE_RECORDS', 'RECORD_TYPE'};



    % NOTE: LblSsl keeps   quotes.
    %       LblSs  removes quotes.
    [LblSsl, LblSs] = EJ_lapdog_shared.PDS_utils.read_ODL_to_structs(filePath);   % Read CALIB LBL file.
    
    % NOTE: LblSsl includes OBJECT = TABLE as last key-value pair which should be excluded.
    HeaderKvpl = EJ_lapdog_shared.utils.KVPL2(...
        LblSsl.keys  (1:end-1), ...
        LblSsl.values(1:end-1));
    
    HeaderKvpl = HeaderKvpl.diff(DONT_READ_HEADER_KEY_LIST);
end
