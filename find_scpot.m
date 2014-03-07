%FIND_SCPOT Approximate spacecraft potential
%
% [Vsc1,Vsc2,Vsc3] = find_scpot(Vb,Ib,z)
%
% returns an approximation of the spacecraft potential. Vsc1 is just a
% global determination while Vsc2 is a determination around the
% zero-point z. Vsc3 is a determination based on where the curve
% "shoots up" from a line
%
% Vb is the bias potential, Ib the bias current and z the
% zero-crossing of the current.
%
% z is used as a first location of the vicinity in which Vsc should be,
% then the maximum of the absolute of the second derivative of the
% current is taken as Vsc, i.e. Vsc = max(abs((d2I))
function [Vsc1,Vsc2,Vsc3] = find_scpot(Vb,Ib,z)
Vsc1 = [];
Vsc2 = [];
Vsc3 = [];
lV = length(Vb);
lI = length(Ib);
if lV == lI
% Ib_smooth(1:lI-1) = (Ib(1:lI-1)+Ib(2:lI))./2;
% Ib_smooth(lI) = Ib(lI);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%To smooth the data the mean value of each datapoint with its neighbour is%
%taken. %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
points = length(Vb);
lgolay = max([(2*floor(points/12)+1) 5]);
Ib_smooth = smooth(Ib,lgolay,'sgolay');
Vb2 = Vb;
Ib2 = Ib_smooth;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Taking the second derivative%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
d2Ib = d2(Vb2,Ib2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%"Global" Vsc as the maximum of the second derivative%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Vsc1 = -Vb2(max(find(abs(d2Ib) == max(abs(d2Ib)))));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Now an interval around z is used to look for Vsc, this is done as a%
%"quality" check on the spacecraft potential found. %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if z ~= 0
interval = 2; %Size of interval (up and down)
ind1 = find(Vb2 > z-interval);
ind2 = find(Vb2 < z+interval);
ind1 = ind1(1);
ind2 = ind2(length(ind2));
V2 = Vb2(ind1:ind2);
d2Ib2 = d2Ib(ind1:ind2);
Vsc2 = -V2(max(find(abs(d2Ib2) == max(abs(d2Ib2)))));

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Look for an approximate Vsc by comparing a straight line (given%
%from the low 10% of the sweep) to the real data, seeing %
%where it "shoots up" %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
ind = floor(0.1*length(Vb2));
P = polyfit(Vb2(1:ind),Ib2(1:ind)',1); %Its a line
max_er = max(abs(diff(Ib2(1:ind))));
m = P(2)+max_er*4; %to take care of noise
I_err = linspace(m,m,length(Vb2));
err = I_err - Ib2;
indi = find(err < 0, 1, 'first');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Now that we have an approximate Vsc lets look at the current %
%values that are located around this point. Using derivatives to%
%get Vsc %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
interval = 3;
ind1 = find(Vb2 > Vb2(indi)-interval);
ind2 = find(Vb2 < Vb2(indi)+interval);
ind1 = ind1(1);
ind2 = ind2(length(ind2));
V3 = Vb2(ind1:ind2);
d2Ib3 = d2Ib(ind1:ind2);
Vsc3 = -V3(max(find(abs(d2Ib3) == max(abs(d2Ib3)))));
catch
Vsc3 = 0;
end
end
