% 
% For every key in kvlSrc,
% (1) assumes that the same key DOES exist in kvlDest (error otherwise), and
% (2) sets the corresponding value in kvlDest.
%
% NOTE: Compare KVPL_add_kv_pairs
%
% ARGUMENTS
% =========
% policy : String. 'overwrite only when has keys', 'require preexisting keys'.
%
% function kvlDest = overwrite_values(kvlDest, kvlSrc, policy)
function   kvlDest = overwrite_values(kvlDest, kvlSrc, policy)
%
% PROPOSAL: New name. Want something that implies only preexisting keys, and overwriting old values.
%   set_values
%   import_values
%   override_values
%   overwrite_values
%

switch(policy)
    case 'overwrite only when has keys'
        requireOverwrite = 0;
    case 'require preexisting keys'
        requireOverwrite = 1;
    otherwise
        error('Illegal "policy" argument.')
end

for iKvSrc = 1:length(kvlSrc.keys)
    
    keySrc   = kvlSrc.keys{iKvSrc};
    valueSrc = kvlSrc.values{iKvSrc};
    iKvlDest = find(strcmp(keySrc, kvlDest.keys));
    
    if isempty(iKvlDest)
        % ASSERTION
        if requireOverwrite
            error('ERROR: Tries to set key that does not yet exist in kvlDest: (key, value) = (%s, %s)', keySrc, valueSrc);
        end
    elseif numel(iKvlDest) == 1
        % CASE: There is exactly one of the key that was sought.
        kvlDest.values{iKvlDest} = valueSrc;      % No error ==> Set value.
    else
        error('ERROR: Found multiple keys with the same value in kvlDest: (key, value) = (%s, %s)', keySrc, valueSrc);
    end
    
end

end
