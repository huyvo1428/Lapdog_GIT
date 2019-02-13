%
% General-purpose tool for reading ODL (LBL/CAT) files. Read ODL/LBL file and return contents in the form of two
% recursive structs, each of them separately representing the contents of the ODL file.
%
% NOTE: See EJ_library.PDS_utils.convert_ODL_to_structs for documentation on exact formats.
%
%
% RETURN VALUES
% =============
% NOTE: Ssl preserves correctly formatted, non-implicit ODL contents (keys/values) "exactly", while Ss
% does not but is easier to work with when retrieving specific values (with hard-coded "logical locations") instead.
% Ssl         : An SSL struct
% Ss          : An SS struct
% endRowsList : Cell array of strings, one for every line after the final "END" statement (without CR, LF).
%
%
%
% Initially created 2014-11-18 by Erik P G Johansson, IRF Uppsala.
%
function [Ssl, Ss, endRowsList] = read_ODL_file(filePath)
    %
    % QUESTION: How handle ODL/PDS distinction?
    % QUESTION: How handle ODL format errors?
    %
    % PROPOSAL: Check for reading the same ODL key/field twice.
    % PROPOSAL: Flag for error modes: error, quit & warning.
    % PROPOSAL: Flag for keeping/removing quotes around string values.
    %
    % PROPOSAL: Somehow keep distinguishing between ODL keys with/without quotes?!!
    % PROPOSAL: Also return data on the format of non-hierarchical list of key-value pairs?!
    %
    % PROPOSAL: Have derive_SS_key also derive SS keys for "OBJECT = ..." statements.
    % PROPOSAL: Change name: read_ODL_file
    
    
    % ASSERTION: Check if file (not directory) exists
    % -----------------------------------------------
    % It is useful for the user to know which ODL file is missing so that he/she can more quickly
    % determine where in pds, lapdog etc. the original error lies (e.g. a ODL file produced by pds,
    % or lapdog code producing or I2L.LBL files, or A?S.LBL files, or EST.LBL files).
    if (~exist(filePath, 'file'))
        error('Can not find file: "%s"', filePath)
    end
    
    try
        % Read list of lines/rows. No parsing. 
        %rowStrList = read_file_to_line_list(filePath);
        rowStrList = EJ_library.utils.read_text_file(filePath);
    catch Exception
        Me = MException('', sprintf('Can not read file: %s\n    Exception.message="%s"', filePath, Exception.message));
        Me.addCause(Exception);
        throw(Me)
    end
    
    try
        [Ssl, Ss, endRowsList] = EJ_library.PDS_utils.convert_ODL_to_structs(rowStrList);
    catch Exception
        Me = MException('', sprintf('Can not interpret contents of file "%s".\n%s', filePath, Exception.message));
        Me.addCause(Exception);
        throw(Me)
    end
end
