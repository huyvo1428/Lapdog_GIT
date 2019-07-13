%
% Create the string used for LABEL_REVISION_NOTE on a standarized format, incl. linebreaks.
%
% ARGUMENTS
% =========
% contentCellArray : 1D cell array of 1D (length 3) cell arrays.
%                    {i}{1} = date string, CCYY-MM-DD
%                    {i}{2} = author initials
%                    {i}{3} = message
%
%
% Initially created 2019-06-28 by Erik P G Johansson, IRF Uppsala.
%
function s = create_LABEL_REVISION_NOTE_value(indentLength, contentCellArray)
    % PROPOSAL: Set hardcoded "author" here. Remove as argument.
    %   PROPOSAL: Use PRODUCER_ID.

    LINE_BREAK      = sprintf('\r\n');
    INDENTATION_STR = repmat(' ', 1, indentLength);
    
    nItems = numel(contentCellArray);
    
    rowList = {};
    for i = 1:nItems
        % ASSERTION
        assert(numel(contentCellArray{i}) == 3)
        
        dateStr = contentCellArray{i}{1};
        author  = contentCellArray{i}{2};
        message = contentCellArray{i}{3};
        
        % ASSERTIONS
        assert(~isempty(regexp(dateStr, '^20[0-9]{2}-[0-1][0-9]-[0-3][0-9]$', 'once')), 'Can not recognize date.')
        assert(~isempty(regexp(author,  '^[A-ZÅÄÖ]+$', 'once')), 'Can not recognize author initials.')
        
        rowList{i} = sprintf('%s, %s: %s', dateStr, author, message);
    end
    
    if nItems == 0
        error('No info to put in LABEL_REVISION_INFO. nItems == 0.')
    elseif nItems == 1
        rowStr = rowList{1};
    elseif nItems >= 2
        % Do not use the first row (in the ODL file).
        rowStr = EJ_library.utils.str_join(rowList, [LINE_BREAK, INDENTATION_STR]);
        rowStr = [LINE_BREAK, INDENTATION_STR, rowStr];
    end
    
    s = rowStr;
    
end
