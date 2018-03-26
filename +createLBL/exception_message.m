%
% Prints message based on the information in an exception.
% Generates no MATLAB error.
%
% NOTE: Uses hardcoded reference to createLBL (text) in error message.
% IMPLEMENTATION NOTE: I have tried to implement printing stack trace with "dbstack" but not been able to make it work.
% 
function exception_message(exception, policy)
% PROPOSAL: Remake into more general function.
%   PROPOSAL: Optionally ("policy") be able to generate error?!
%   PROPOSAL: Remove reference to createLBL.
%   PROPOSAL: Extra parameter for prefix instead of "createLBL".
%
% PROPOSAL: Implement using warnings, and MATLAB system for selecting warnings/errors (does that exist?)
%   CON: Can not select to print/not print stack trace that way.
%
% PROPOSAL: Print extra message, depending on policy.
%   Ex: What the code was trying to do (on a higher level).
%   Ex: What the code will do instead, e.g. "Skip LBL file".
%   CON: Complicated policy.

    % Default setting so that the function fails "nicely" in case "policy" is e.g. misspelled.
    if ~any(strcmp(policy, {'nothing', 'message', 'message+stack trace'}))
        warning('Did not set correct "policy".')
        policy = 'message+stack trace';
    end
    
    
    
    if any(strcmp(policy, {'message', 'message+stack trace'}))
        fprintf(1,'lapdog: createLBL exception: %s\n', exception.message);    
    end

    if any(strcmp(policy, {'message+stack trace'}))
        len = length(exception.stack);
        if (~isempty(len))
            for i=1:len
                fprintf(1,'%s, row %i,\n', exception.stack(i).name, exception.stack(i).line);
            end
        end
    end

end
