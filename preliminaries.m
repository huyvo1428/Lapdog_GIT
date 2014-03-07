%PRELIMINARIES is a function that should be used in the start of the
% fitting procedure. It calculates starting values of some of
% the parameters, as well as Vsc, z and other usables
%
% [dat_out] = preliminaries(Vb,I)
function [dat_out] = preliminaries(Vb,I)
dat_out = [];
lV = length(Vb);
lI = length(I);

 subplot(2,2,1)
    plot(Vb,I);
    xlabel('Vb [V]');
    ylabel('Ip [nA]');
    
    
if lV == lI
%HERE THE LEAK SHOULD BE SUBTRACTED... PERHAPS
z = zero_cross(Vb,I); %determine zero-crossing
if (isempty(z))
disp('Data possibly corrupt, ending fit')
return;
end
f = -1; %This must be fixed
[Vsc1,Vsc2,Vsc3] = find_scpot(Vb,I,z); %determine Vsc
if (Vsc1+z < -4) %Vsc should be in
Vsc = -z; %vicinity of z
else
Vsc = Vsc1;
end
%Now Ie0 and Te will be determined
[Ie0,Te,k,Vsc] = fit_single_e(Vb,I,Vsc);
c = Ie0;
d = 1/Te;
%Setting b and a (a is used if the probe is in eclipse)
Vp = Vsc + Vb;




    subplot(2,2,2)
    plot(Vp,I);
    xlabel('Vb [V]');
    ylabel('Ip [nA]');
    titstr ='hello';


len = length(Vp);
len2 = length(find(Vp < 0));

V = Vp(1:(floor(len2*0.5))); %50 percent of the negative probe sweep
I = I(1:(floor(len2*0.5)));
P = polyfit(V,I,1); %fitting straight line
b = P(1);
a = P(2);
%Set the output
dat_out(1) = a; %-Ii0
dat_out(2) = b; %Ii0/Ti
dat_out(3) = c; %Ie0
dat_out(4) = d; %1/Te
dat_out(5) = Vsc;
dat_out(6) = f;
dat_out(7) = z;
dat_out(8) = k;
dat_out(9) = Vsc1;
dat_out(10) = Vsc2;
dat_out(11) = Vsc;


    subplot(2,2,4)
    plot(V,I);
    xlabel('Vb [V]');
    ylabel('Ip [nA]');
    titstr ='hello';
    
    
    
end
