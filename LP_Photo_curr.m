%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                  
% Name: LP_Photo_curr.m                                               
% Author: Claes Weyde
%         Reine Gill modified with F107
% Description:                                                     
%        Iph = LP_Photo_curr(V,Vsc,F107);
%
%	1. First the instrument parameters are loaded by invoking the structure IN. Since it is just the radius 
%	   of the probe that is used one could just hardcode it as well. The probe potential is calculated 
%	   from the bias potential by adding the spacecraft potential; Vp = Vb + Vsc. The photo saturation 
%	   current as well as photoelectron temperature are hardcoded.
%	2. Next, the photocurrent is calculated from the photo saturation current per area by multiplying by 
%	   the area of the probes.
%	3. The indices for the two different intervals are set, the one consisting of negative probe potentials 
%	   is called "indl" and the one consisting of positive probe potentials "indh". The intervals are found 
%	   using the pre-built MATLAB function "find.m", but the same intervals are easily set by using a for- 
%	   or while-structure. 
%	4. Now the photo-current is set. Here we use the simple model below:
%	   Iph = -Iph0               , Vp < 0
%	   Iph = -Iph0*exp(-Vp/Tph)  , Vp >= 0
%	   This model may be altered after calibration. Setting the model above the indices indl and indh are 
%	   used.
%	5. Iph is returned from the function.
%                                                                  
% Input: 
%       Bias potential            V/[V] 
%       The spacecraft potential  Vsc/[V] 
%       UV factor F10.7 
%       Photo.Iph0                Photo saturation current/[nA] at F10.7=100
%       Photo.Tph0                Photo emission e-folding energy [eV]
%                                                      
% Output: 
%     	The photoelectron current,	Iph,	[A]
%                                      
% Notes:  
%	1. This function will be modified after the calibration runs and the actual form of the photo-current has 
%	   been determined. As it stands now a photoelectron current of 40 micro-A/m^2 with a temperature of 1.5 
%	   eV is used. A step-by-step description of the algorithm follows.
%	2. The hardcoded part should be in the plasma structure.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Iph = LP_Photo_curr(V,Vsc,F107)

%global IN;	  % The instrument parameters are set
%global Photo; % Photo electron parameters, that are estimated
Photo_Iph0 = 6e-9;%A
Photo_Tph0 = 1.5; %eV
probe_radius = 25E-3; %m

global efi_f_io_lp_l1bp




Vp = V+Vsc;	  % The probe potential is calculated

%Iph0 = (F107/100) * Photo.Iph0 * pi * IN.probe_radius^2;  % Calculating the actual magnitude of the current
Iph0 = (F107/100) * Photo_Iph0 * pi * probe_radius^2;  % Calculating the actual magnitude of the current

indl = find(Vp < 0);  % Interval 1: everything below probe potential = 0
indh = find(Vp >= 0); % Interval 2: everything above probe potential = 0

Iph(indl) = -Iph0;                            % The current is calculated from 
Iph(indh) = -Iph0*exp(-Vp(indh)/Photo_Tph0);  % plasma probe theory

if (efi_f_io_lp_l1bp>1)    
	subplot(3,3,2),plot(V,Iph,'b',V,I,'g');grid on;
	title('Photoelectrons');
end



end


