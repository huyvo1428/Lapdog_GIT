% 
% Order the key-value pairs according to a list of keys.
% Remaining key-value pairs will be added at the end in their previous internal order.
%
%
% ARGUMENTS
% =========
% keyOrderList : Cell array of strings.
%
%
% NOTE: Does not assume any relationship between kvl.keys and keyOrderList
% (either may contain elements not existing in the other).
%
% function kvl = order_by_key_list(kvl, keyOrderList)
function   kvl = order_by_key_list(kvl, keyOrderList)
%
% PROPOSAL: Policy for relationship between kvl.keys and keyOrderList.
%   Require that all keyOrderList are a subset of kvl.keys.
%   Require that kvl.keys are a subset of keyOrderList.
%   Require that kvl.keys and keyOrderList are identical (except for order of elements).
%
% PROPOSAL: for loop over kvl.keys
%   PRO: Can assign both iOrdered and iRemaining at the same time?


    % ASSERTION
    if length(unique(keyOrderList)) ~= length(keyOrderList)
        error('keyOrderList contains multiple identical keys.')
    end

    % Derive iOrdered.
	% PROPOSAL: Använd read_value? Ger fel om inte hittar key.
	iOrdered = [];
	for iKol = 1:length(keyOrderList)   % KOL = keyOrderList
		iKv = find(strcmp(keyOrderList{iKol}, kvl.keys));
        if length(iKv) == 1
            iOrdered(end+1, 1) = iKv;
        %else if length(iKv) > 1
        %    error('Multiple identical key in kvl.')
        end
	end

	% Derive iRemaining = Indices into kvl.keys that are not already in iOrdered.
    % NOTE: Want to keep the original order.
	b = ones(size(kvl.keys));
	b(iOrdered) = 0;
	iRemaining  = find(b);
    
    iOrderTot = [iOrdered; iRemaining];
    
    % ASSERTION
    % Internal consistency check. Can be disabled.
    if (length(iOrderTot) ~= length(kvl.keys)) || any(sort(iOrderTot) ~= (1:length(kvl.keys))')
        error('ERROR: Likely bug in algorithm');
    end
    
    kvl.keys   = kvl.keys  (iOrderTot);
    kvl.values = kvl.values(iOrderTot);
end
