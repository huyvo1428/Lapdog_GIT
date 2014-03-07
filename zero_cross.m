%ZERO_CROSS determines the zero crossing of the current (i.e. I = 0)
%
% z = zero_cross(Vb,I)
function z = zero_cross(Vb,I)
lenV = length(Vb);
lenI = length(I);
z = 0;
if lenV ~= lenI
disp('Vb and I need to be same length')
return;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Find datapoints lower and higher than zero, the following is Reine Gills%
%code (unless otherwise stated) %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lt = find(I < 0);
gt = find(I > 0);
Dlt = [Vb(lt), I(lt)]; %Data with current lower than zero
Dgt = [Vb(gt), I(gt)]; %Data with current higher than zero
if(~isempty(Dlt) && ~isempty(Dgt))
Dlt=sortrows(Dlt,2); % Sort by current
Dlt=flipud(Dlt);
% Select atmost the 4 lowest curr. values and sort by bias
ui=size(Dlt,1);
if(ui>4)
ui=4;
end
Dlt=sortrows(Dlt(1:ui,:),1);
Dlt=flipud(Dlt);
% At this point the first row in Dlt is a data point with
% high probability to be close and to the left of the rightmost
% zero crossing..second value has lower probability and so on
Dgt=sortrows(Dgt,2); % Sort by current
% Select atmost the 4 lowest
% curr. values and sort by bias
ui=size(Dgt,1);
if(ui>4)
ui=4;
end
Dgt=sortrows(Dgt(1:ui,:),1);
% At this point the first row in Dlt is a data point with
% high probability to be close and to the right of the rightmost
% zero crossing..second value has lower probability and so on
% Use most probable points draw a line between them
% and return bias at zero current
vp=Dgt(1,1);
ip=Dgt(1,2);
vn=Dlt(1,1);
in=Dlt(1,2);
z=vp-ip*(vp-vn)./(ip-in);
else
disp('Error, all data above or below zero!');
z = [];
end
