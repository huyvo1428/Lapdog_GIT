

%FIT_SINGLE_E fits the upper part of the electron side as a line assuming
% one electron population
%
% [Ie0,Te,k] = fit_single_e(Vb,I,Vsc)
function [Ie0,Te,k,Vsc1] = fit_single_e(Vb,I,Vsc0)
Ie0 = [];
Te = [];
Vp = Vb + Vsc0;
%Take the last 70% as the data to fit to
indp = find(Vp > 0);
V = Vp(indp);
I = I(indp);

lenV = length(V);
indl = ceil(lenV*0.30);
Vh = V(indl:lenV);
Ih = I(indl:lenV);
%Now fit using a polynomial of degree 1, i.e. a line
P = polyfit(Vh,Ih,1);
k = P(1);
m = P(2);
Te0 = 0.5;
if (k > 25e-9)
Vsc1 = Vsc0-Te0+m/k;
else
Vsc1 = Vsc0;
end
m = k*Te0;
Ie0 = m;
Te = Te0;