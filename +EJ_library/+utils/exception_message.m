%
% Prints message based on the information in an exception.
% Should by itself generate no MATLAB error.
%
% NOTE: Recursive wrt. exception.cause{i}.
% Exception.cause is an array and in principle, .cause thus defines a tree structure which is printed as an indented
% tree structure.
% NOTE: Prints all messages to stdout.
%
%
% IMPLEMENTATION NOTE: I have tried to implement printing stack trace with "dbstack" but not been able to make it work.
%
%
% ARGUMENTS
% =========
% Exception : MException object.
% policy    : String constant. One of the following: 'nothing', 'message', 'message+stack trace'.
% (varargin : Only used for internal recursive calls. Do not use from outside.)
%
%
% Initially created ~<2016-04-07 by Erik P G Johansson.
% 
function exception_message(Exception, policy, varargin)
% PROPOSAL: Implement using warnings, and MATLAB system for selecting warnings/errors (does that exist?)
%   CON: Can not select to print/not print stack trace that way.
%
%
% PROPOSAL: Use ~Exception.getReport('extended') instead. Seems to have similar functionality.
%   CON: Can not disable or customize own "policy".
% PROPOSAL: Allow function to rethrow exception.
%   PROPOSAL: Add submitted exception as cause.
% PROPOSAL: replace policy with Settings (interpret_settings).
% PROPOSAL: Change constant: "nothing" --> "ignore", "ignore error"
% PROPOSAL: Use print_variable_recursively.
%   CON: Does not yet handle objects (e.g. MException).

    INDENTATION_LENGTH = 4;


    
    indentationLevel = 0;
    if numel(varargin) == 0
        % Do nothing
    elseif numel(varargin) == 1
        indentationLevel = varargin{1};
    else
        error('Illegal number of arguments')
    end

    is = repmat(' ', 1, INDENTATION_LENGTH*indentationLevel);  % is=indentation string. Short name to shorten iprint() calls.



    % ASSERTION
    % NOTE: Fails nicely (not error) with default setting in case "policy" is e.g. misspelled.
    if ~any(strcmp(policy, {'nothing', 'message', 'message+stack trace'}))
        warning('Illegal argument policy="%s". Automatically modifying policy.', policy)
        policy = 'message+stack trace';
    end
    
    
    
    switch(policy)
        case 'nothing'
            showMsg        = 0;
            showStackTrace = 0;
            showCauses     = 0;
        case 'message'
            showMsg        = 1;
            showStackTrace = 0;
            showCauses     = 1;
        case 'message+stack trace'
            showMsg        = 1;
            showStackTrace = 1;
            showCauses     = 1;
        otherwise
            warning('Illegal argument policy="%s".', policy)
            
    end

    

    if showMsg
        %====================
        % Print error message
        %====================
        iprint(is, '======== An exception has occurred ========\n')
        iprint(is, 'Exception.message    = "%s"\n', Exception.message);    
        iprint(is, 'Exception.identifier = "%s"\n', Exception.identifier);    
    end

    if showStackTrace
        %===============================================================
        % Print stack trace (for this exception, not "cause exceptions"
        %===============================================================
        stackDepth = length(Exception.stack);
        if (~isempty(stackDepth))
            for i=1:stackDepth
                % NOTE: Must print .name since it could refer to an internal function, i.e. one might not be able to
                % derive it from .file.
                iprint(is,'row %3i, %s: %s\n', Exception.stack(i).line, Exception.stack(i).file, Exception.stack(i).name);
            end
        end
    end
    
    if showCauses
        %======================================
        % Print "cause" exceptions RECURSIVELY
        %======================================
        for iCause = 1:numel(Exception.cause)
            % NOTE: Not printing this log message as a "header" since the recursive call trigger another "header" log
            % message (above).
            iprint(is, 'Displaying cause(s) of exception (recursive): Exception.cause{%i}\n', iCause)
            EJ_library.utils.exception_message(Exception.cause{iCause}, policy, indentationLevel+1);    % RECURSIVE CALL
        end
    end

end



% Indented print function.
function iprint(indentStr, varargin)
    varargin{1} = [indentStr, varargin{1}];
    
    fprintf(varargin{:});
end
