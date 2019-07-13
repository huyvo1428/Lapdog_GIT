%
% Set LABEL_REVISION_NOTE (LRN) key value in KVPL in a compact, standardized, and somewhat well-formatted way. Not properly line-broken though.
%
% NOTE: Requires key "LABEL_REVISION_NOTE" to already pre-exist in KVPL (assertion).
%
%
% ARGUMENTS
% =========
% contentCellArray : See EJ_library.PDS_utils.create_LABEL_REVISION_NOTE_value .
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
% Initially created 2019-03-18 by Erik P G Johansson, IRF Uppsala.
%
function Kvpl = set_LABEL_REVISION_NOTE(Kvpl, indentLength, contentCellArray)
    
    rowStr = EJ_library.PDS_utils.create_LABEL_REVISION_NOTE_value(indentLength, contentCellArray);
    
    Kvpl = Kvpl.set_value('LABEL_REVISION_NOTE', sprintf('"%s"', rowStr));    % NOTE: Adds quotes.
end
