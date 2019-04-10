%
% Set LABEL_REVISION_NOTE (LRN) key value in KVPL in a compact, standardized, and somewhat well-formatted way. Not properly line-broken though.
%
% NOTE: Requires key "LABEL_REVISION_NOTE" to already pre-exist in  KVPL
%
% ARGUMENTS
% =========
% contentCellArray : 1D cell array of 1D (length 3) cell arrays.
%                    {i}{1} = date string, CCYY-MM-DD
%                    {i}{2} = author initials
%                    {i}{3} = message
% 
%
% RATIONALE
% =========
% -- Makes sure one does not forget to add quotes.
% -- Can (potentially) force common format: ~indentation, rows, date, author.
% -- Can potentially limit to only the last N label revisions (items).
% -- Force correct spelling of LABEL_REVISION_NOTE (which would otherwise be hardcoded in multiple places, although
%    ".set_value" requires keyword to pre-exist in KVPL, which should help).
%
%
% Initially created 2019-03-18 by Erik P G Johansson based on older method.
%
function Kvpl = set_LABEL_REVISION_NOTE(Kvpl, indentLength, contentCellArray)
    % PROPOSAL: Set hardcoded "author" here. Remove as argument.
    
    LINE_BREAK  = sprintf('\r\n');
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
        assert(~isempty(regexp(dateStr, '^20[0-9]{2}-[0-1][0-9]-[0-3][0-9]$', 'once')))
        assert(~isempty(regexp(author,  '^[A-ZÅÄÖ]+$', 'once')))
        
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
    
    Kvpl = Kvpl.set_value('LABEL_REVISION_NOTE', sprintf('"%s"', rowStr));    % NOTE: Adds quotes.
end
