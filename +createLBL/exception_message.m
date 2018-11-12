%
% Prints message based on the information in an exception.
% Should by itself generate no MATLAB error.
% Recursive wrt. exception.cause{i}.
%
% IMPLEMENTATION NOTE: I have tried to implement printing stack trace with "dbstack" but not been able to make it work.
%
% ARGUMENTS
% =========
% policy : String. One of the following: 'nothing', 'message', 'message+stack trace'.
%
%
% 
function exception_message(Exception, policy)
% PROPOSAL: Implement using warnings, and MATLAB system for selecting warnings/errors (does that exist?)
%   CON: Can not select to print/not print stack trace that way.
%
% PROPOSAL: Print extra message, depending on policy.
%   Ex: What the code was trying to do (on a higher level).
%   Ex: What the code will do instead, e.g. "Skip LBL file".
%   CON: Complicated policy.
%
% PROPOSAL: Use Exception.getReport?
% PROPOSAL: Allow function to rethrow exception.
% PROPOSAL: Generic function also for private collection?
% PROPOSAL: policy as cell array of strings.
%   PRO: Simplifies implementation?
% PROPOSAL: replace policy with Settings (interpret_settings).

    % ASSERTION
    % NOTE: Fails nicely (not error) with default setting in case "policy" is e.g. misspelled.
    if ~any(strcmp(policy, {'nothing', 'message', 'message+stack trace'}))
        warning('Illegal "policy" argument.')
        policy = 'message+stack trace';
    end
    
    
    
    if any(strcmp(policy, {'message', 'message+stack trace'}))
        % Print error message.
        fprintf(1,'lapdog: createLBL exception: %s\n', Exception.message);    
    end

    if any(strcmp(policy, {'message+stack trace'}))
        % Print stack trace (for this exception, not "cause exceptions".
        len = length(Exception.stack);
        if (~isempty(len))
            for i=1:len
                fprintf(1,'row %i, %s: %s\n', Exception.stack(i).line, Exception.stack(i).file, Exception.stack(i).name);
            end
        end
    end
    
    for iCause = 1:numel(Exception.cause)
        createLBL.exception_message(Exception.cause{iCause}, policy);    % RECURSIVE CALL
    end
end
