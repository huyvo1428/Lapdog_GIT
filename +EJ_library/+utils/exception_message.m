%
% Prints message based on the information in an exception.
% Should by itself generate no MATLAB error.
%
% NOTE: Recursive wrt. exception.cause{i}.
% exception.cause is an array and in principle, .cause thus defines a tree structure. The printout does print out
% all the nodes (Exceptions) but does not print out the relationsships between them in any clear way. The printout is
% sensible when there is zero or one causes for an exception, but will still print every exception also when there is
% more than one cause.
%
%
% IMPLEMENTATION NOTE: I have tried to implement printing stack trace with "dbstack" but not been able to make it work.
%
%
% ARGUMENTS
% =========
% policy : String constant. One of the following: 'nothing', 'message', 'message+stack trace'.
%
%
% Initially created ~<2016-04-07 by Erik P G Johansson.
% 
function exception_message(Exception, policy)
% PROPOSAL: Implement using warnings, and MATLAB system for selecting warnings/errors (does that exist?)
%   CON: Can not select to print/not print stack trace that way.
%
%
% PROPOSAL: Use Exception.getReport?
% PROPOSAL: Allow function to rethrow exception.
%   PROPOSAL: Add submitted exception as cause.
% PROPOSAL: replace policy with Settings (interpret_settings).
% PROPOSAL: Change constant: "nothing" --> "ignore", "ignore error"
% PROPOSAL: Use increasing indentation for cause exceptions.
% PROPOSAL: Use print_variable_recursively.


    % ASSERTION
    % NOTE: Fails nicely (not error) with default setting in case "policy" is e.g. misspelled.
    if ~any(strcmp(policy, {'nothing', 'message', 'message+stack trace'}))
        warning('Illegal "policy" argument.')
        policy = 'message+stack trace';
    end
    
    
    
    if any(strcmp(policy, {'message', 'message+stack trace'}))
        % Print error message.
        fprintf(1, '======== An exception has occurred ========\n')
        fprintf(1, 'Exception.message    = "%s"\n', Exception.message);    
        fprintf(1, 'Exception.identifier = "%s"\n', Exception.identifier);    
    end

    if any(strcmp(policy, {'message+stack trace'}))
        % Print stack trace (for this exception, not "cause exceptions".
        len = length(Exception.stack);
        if (~isempty(len))
            for i=1:len
                % NOTE: Must print .name since it could refer to an internal function, i.e. one might not be able to
                % derive it from .file.
                fprintf(1,'row %3i, %s: %s\n', Exception.stack(i).line, Exception.stack(i).file, Exception.stack(i).name);
            end
        end
    end
    
    for iCause = 1:numel(Exception.cause)
        % NOTE: Not printing this log message as a "header" since the recursive call trigger another "header" log
        % message (above).
        fprintf(1, 'Displaying cause of exception (recursive): Exception.cause{%i}\n', iCause)
        EJ_library.utils.exception_message(Exception.cause{iCause}, policy);    % RECURSIVE CALL
    end

end
