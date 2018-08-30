% 
% For every key in KvplSrc, try to set the corresponding key value in KvplDest if it exists.
%
%
% NOTE: No keys will ever be added to the destination.
% NOTE: Compare add_kv_pairs
%
%
% ARGUMENTS
% =========
% policy : String.
%          'overwrite only when has keys' : If a key in KvplSrc is in KvplDest, then its value is overwritten. Otherwise the key in KvplSrc is ignored.
%          'add if not preexisting'       : If a key in KvplSrc is in KvplDest, then its value is overwritten. Otherwise the key+value are added to KvplDest.
%          'require preexisting keys'     : Every key in KvplSrc, must pre-exist KvplDest, otherwise error (assertion).
%
% function KvplDest = overwrite_values(KvplDest, KvplSrc, policy)
function   KvplDest = overwrite_values(KvplDest, KvplSrc, policy)
%
% PROPOSAL: New name. Want something that implies only preexisting keys, and overwriting old values.
%   set_values
%   import_values
%   override_values
%   overwrite_values
%

switch(policy)
    case 'overwrite only when has keys'
        errorIfNotPreexisting = 0;
        addIfNotPreexisting   = 0;
    case 'add if not preexisting'
        errorIfNotPreexisting = 0;
        addIfNotPreexisting   = 1;
    case 'require preexisting keys'
        errorIfNotPreexisting = 1;
        addIfNotPreexisting   = 0;   % Should be irrelevant.
    otherwise
        error('Illegal "policy" argument.')
end



for iKvSrc = 1:length(KvplSrc.keys)
    
    keySrc   = KvplSrc.keys{iKvSrc};
    valueSrc = KvplSrc.values{iKvSrc};
    iKvplDest = find(strcmp(keySrc, KvplDest.keys));
    
    if isempty(iKvplDest)
        % CASE: KvplSrc key is NOT in KvplDest.
        
        % ASSERTION
        if errorIfNotPreexisting
            error('ERROR: Tries to set key that does not yet exist in KvplDest: (key, value) = (%s, %s)', keySrc, valueSrc);
        elseif addIfNotPreexisting
            KvplDest.keys{end+1}   = keySrc;
            KvplDest.values{end+1} = valueSrc;
        end
    elseif numel(iKvplDest) == 1
        % CASE: KvplSrc key is exactly ONCE in KvplDest.
        
        KvplDest.values{iKvplDest} = valueSrc;      % No error ==> Set value.
    else
        % CASE: KvplSrc key is multiple times in KvplDest.
        
        % ASSERTION
        error('ERROR: Found multiple keys with the same value in KvplDest: (key, value) = (%s, %s)', keySrc, valueSrc);
    end
    
end

end
