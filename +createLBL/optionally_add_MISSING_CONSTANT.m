%
% Modify a column description struct to include a MISSING_CONSTANT.
%
%
% ARGUMENTS AND RETURN VALUES
% ===========================
% addMissingConstant    : True/false.
% oc                    : OC = "OBJECT=COLUMN"
% descriptionAmendement : String which is added to the end of DESCRIPTION (after adding one whitespace).
% missingConstant       : MISSING_CONSTANT value.
%
%
% Initially created 2018-04-10 by Erik P G Johansson, IRF Uppsala.
%
function oc = optionally_add_MISSING_CONSTANT(addMissingConstant, missingConstant, oc, descriptionAmendment)
    if addMissingConstant
        
        % ASSERTION
        if oc.DESCRIPTION(end) ~= '.'
            error('Preexisting un-amended DESCRIPTION does not end with period.')
        end
        
        oc.DESCRIPTION      = [oc.DESCRIPTION, ' ', descriptionAmendment];
        oc.MISSING_CONSTANT = missingConstant;
    end
end
