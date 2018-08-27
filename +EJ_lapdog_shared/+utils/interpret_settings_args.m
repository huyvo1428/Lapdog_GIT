% Function for interpreting settings arguments.
% 
% ALGORITHM
% =========
% Works with up to three analogous "settings" structs.
% settingsArg1         = argList{1}, if argList{1} exists and is a struct. Otherwise empty struct.
% settingsArgListPairs = remainder of argList (excluding settingsArg1), interpreted as pairs of field name + field value.
% defaultSettings      = argument.
% --
% Returns struct which is a combination of 
% (1) settingsArgListPairs
% (2) settingsArg1
% (3) defaultSettings
% where fields are taken from the first top-most struct with that field, i.e. a higher one has precedense over a lower
% one, e.g. (1) has precedence over (2).
% 
%
% ARGUMENTS
% =========
% defaultSettings : Struct with default settings (to be processed; not settings for this functions).
% argList         : Cell array of strings representing a sequence of arguments (varargin presumably) from another function that uses this function.
%
%
% RETURN VALUES
% =============
% settings    : Struct. See algorithm.
%
%
% Initially created 2018-07-18 by Erik P G Johansson.
%
function [settings] = interpret_settings_args(defaultSettings, argList)
% PROPOSAL: Assert settingsArg1 and settingsArgListPairs fields to always exist in defaultSettings.
% PROPOSAL: Automatic test code.
    
    %=====================
    % Assign settingsArg1
    %=====================
    if numel(argList) >= 1 && isstruct(argList{1})
        settingsArg1 = argList{1};
        argList = argList(2:end);
    else
        settingsArg1 = struct;
    end
    
    %=============================
    % Assign settingsArgListPairs
    %=============================
    settingsArgListPairs = struct;
    while true
        if numel(argList) == 0
            break
            
        elseif numel(argList) == 1
            error('Uneven number of string-value arguments.')
            
        elseif numel(argList) >= 2
            if ~ischar(argList{1})
                error('Expected string argument is not string.')
            end
            
            settingsArgListPairs.(argList{1}) = argList{2};
            
            argList = argList(3:end);
        end
    end

%=================
% Assign settings
%=================
settings = erikpgjohansson.utils.add_struct_to_struct(settingsArg1, defaultSettings, ...
    struct('noStructs', 'Do nothing', 'aIsStruct', 'Do nothing', 'bIsStruct', 'Do nothing', 'bothAreStructs', 'Do nothing'));
settings = erikpgjohansson.utils.add_struct_to_struct(settings, settingsArgListPairs, ...
    struct('noStructs', 'Do nothing', 'aIsStruct', 'Do nothing', 'bIsStruct', 'Do nothing', 'bothAreStructs', 'Do nothing'));
    
end
