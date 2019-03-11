function [efl] = efl_most(t,v1l,v2l)
% efl_x10 -- function to be used for generating LF E-field from all macros
% but 710 and 910.
%
% To give useful output, the input vectors MUST contain data ONLY from
% when both probes are SUNLIT!
%
%
% anders.eriksson@irfu.se 2019-02-27

% The only non-trivial issue is how to properly do high-pass filtering in
% the presence of regular (end of each AQP) datagaps. As the number of
% data points is the same in each 32s period for these macros (in contrast
% to 710 and 910, which are handled separately) we can apply a moving
% mean filter of fixed length.

% Find n = number of data points per AQP:
dt = diff(t);
dtt = median(dt);
gaps = find(dt > dtt+0.002/86400);  % 2 ms margin for roundoff errors
n = median(diff(gaps));
clear dt gaps;
eraw = 1000*(v2l-v1l)/5;
%efl = eraw - movmean(eraw,n);
efl = eraw - conv(eraw,ones(n,1),'same')/n;
%tl = t; %I don't see the need for outputting tl when it's not being operated upon.
