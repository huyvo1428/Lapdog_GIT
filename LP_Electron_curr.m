%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Name: LP_Electron_curr.m
% Author:
%         Reine Gill
%         LP_Electron_curr.m to work better with sheath effects.
%
% Description:
%	[Te,ne,Q] = LP_Electron_curr(V,I,Vsc)
%
%	Given the potential and current, as well as the spacecraft potential this function calculates the
%	electron density and the electron temperature.
%
%	1. The probe potential is calculated as the spacecraft potential added to the bias potential;
%	   Vp = V + Vsc.
%
%   2. Find all the currents with bias below Vp=0, or equally when the
%      applied bias V=-Vsc, store in Vr and Ir (r=retarded) (that's harsh)
%
%   3. If any data remains from step 2, then remove all the the data points
%      with Ir<0. More specific it removes all data points to the left of
%      the last Ir<0. This ensures that data points that should have
%      Ir<0 do not get through due to the fact that noise push them
%      to be positive. The reverse scenario that noise pushes data points
%      to become Ir<0 there they should be positive is much less likely
%      since the positive currents have a larger magnitude in the retarded
%      region. The remaining data of the retarded region are stored in Vr and Ir.
%
%   4. Remove data points with a Ir less than a certain magnitude, since to low
%      currents are to noisy to be usable, again the results are stored in
%      Ir and Vr.
%
%   5. Now the logarithm of the current Ir is taken Ilog and a linear fit is done to
%      (Vr,Ilog).
%
%   6. The inverse slope from the fit in step 5 give Te in [eV]
%
%
%   7. The residual is computed by subtracting the real Ir current from the
%      one computed using the coefficients c and d from the fit in step 5.
%
%   8. The RMS value of the residual is computed and scaled by the current
%      at Vp=0, or equally when the applied bias V=-Vsc. Scaling gives a
%      relative error "currvar" of the fit. This is in turn used to determine
%      the quality of the output data.
%
%   9. Now if Te is not negative or inf, we use Te and Ie0 to compute ne
%
%
% Input:
%      Bias potential                        V     [V]
%      Probe current                         I     [A]
%      Spacecraft potential                  Vsc   [V]
%
% Output:
%      Electron temperature                  Te    [eV]
%      Electron density                      ne    [cm-3]
%      Spacecraft potential                  Vsc   [V]
%      Quality parameter vector              Q
%
% Notes:
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = LP_Electron_curr(V,I,Vsc,Vknee,illuminated)

global an_debug VSC_TO_VPLASMA VSC_TO_VKNEE;
global CO IN          % Physical &instrument constants

%init outputs
Te=NaN;
ne=NaN;
Ie=I;
Ie(1:end)=0;
a=nan(1,2);
b=nan(1,2);

out = [];

out.I = Ie;
out.Vpa = nan(1,2); %NaN;
out.Vpb = nan(1,2);
out.a = nan(1,2);
out.b = nan(1,2);
out.Te = nan(1,2);
out.ne = nan(1,2);
out.Q = 0;



% The length of the data set is saved in the variable "len"
len = length(V);

Vp = V+Vsc; % Compute absolute probe potential as bias potential added to spacecraft potential.

% Find the data points above Vknee 

if illuminated
    SM_Above_Vknee= 0.75;

else
    SM_Above_Vknee=0;
end


ind = find(V > -Vknee);% Saving indices of all potential values above the knee.
firstpos=find(V > -Vsc,1,'first');


if (isempty(ind) || length(ind) < 2)
    out.Q = 1;
    ind = len-4:len; %no region found, just try to fit something to the 
    
end
%firstpos = ind(1);


if isempty(firstpos)
    firstpos = len;
end



% Use the lowest ALG.SM_Below_Vs*100% of the bias voltage, below the spacecraft potential
% The data is sorted from lowest bias voltage to highest bias voltage so
% the first ALG.SM_Below_Vs*100% is OK to use
l_ind = length(ind); % Need the number of data points of the vector ind
% the function length returns the length of vector ind

bot = floor(ind(1)+l_ind*SM_Above_Vknee +0.5);

%top = floor(l_ind*ALG.SM_Below_Vs); % The point closest to, but below, ALG.SM_Below_Vs*100% of the
% spacecraft potential. The function floor rounds
% the calling parameter to the nearest integer
% towards minus infinity.


bot= bot -1 + find(I(bot:end)>0,1,'first');    %only choose currents above 0 


%choose starting point some points away from Vsc and has a positive
%current value.

%bot = max([ind(1),bot]);

ind = bot:len; % Only the first ALG.SM_Below_Vs*100% above the spacecraft potential is now

if (isempty(ind) || length(ind) < 2)
    %all values negative
    return
end


if max(I(bot:len)) > 9e-7 % %We can afford to ignore some datapoints for these very sharp currents

    curr_limit = 4e-7;
    
    bot= bot -1 + find(I(bot:end)>curr_limit,1,'first');    %only choose currents above 0 (or curr_limit) for large current. We can afford to ignore some datapoints for these very sharp currents
    
    ind2 = bot:len; % Only the first ALG.SM_Below_Vs*100% above the spacecraft potential is now
    
    if (isempty(ind2) || length(ind2) < 2)
        %all values negative
    else
        
        ind=ind2;
        
    end
end




Vr = V(ind);
Vpr  = Vp(ind);     % kept of the vector ind
Ir  = I(ind);     % The "electron-voltage" and "electron-current" are set. Note that this


%The log doesnt work if V
% Ilog = log(Ir); % Take the logarithm of the retarded current
%
% P = polyfit(Vr,Ilog,1); % Fitting linearly we have the temperature directly as
% a = P(1);
% b = P(2);
% The inverse slope gives Te
%Te = 1/a;
% Compute the residual
%residual = Ir - exp(b+a*Vr); % Retarded current subtracted from fitted current
%Ie0 = exp(b);


[P, S] = polyfit(Vpr,Ir,1);
PVb = P;
PVb(2) = P(1)*Vsc+P(2); %remove Vsc from fit

%[PVb, junk] = polyfit(Vr,Ir,1);


a(1) = P(1); % This is accordingly the slope of the line...
b(1) = P(2); % ...and this is the crossing on the y-axis of the line

S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df); % the std errors in the slope and y-crossing

a(2) = abs(S.sigma(1)/P(1)); %Fractional error
b(2) = abs(S.sigma(2)/P(2)); %Fractional error


%I = Ie0(1+Vp/Te). a = Ie0/Te, b = Ie0.
Ie0 =  b(1);
Te = b(1)/a(1);

s_Te=sqrt(a(2).^2+b(2).^2); %fractional error of Te, 
% 
% residual = Ir - b(1)+a(1)*Vpr; %this equation is bad!! maybe (Ind
% 



% If Te is positive we can get the density as follows
if(Te>=0 && ~isinf(Te))

%    ne = Ie0 / (IN.probe_A*CO.e*sqrt(CO.e*Te/(2*pi*CO.me))); %from
%    intersect, but it is very sensitive to Vsc errors 


    %L^-3 =    M^0.5* V^0.5* Q T^-1 V-1 / (L^2 * Q^1.5 ) = M^0.5*V^-0.5*T^-1*Q^-0.5 * L^-2
    %V = M L^2 T^-2 Q-1 -> 
    % L ^-3 = L^-3, qed.
    
    %m^-3 =    ?kg  ?V  q s-1 V-1     m-2   Q-1.5 
    % V = kg m2s-2 Q-q  > V^-0.5 = kg^-0.5 s m^-1 q^0.5
    %m ^-3 =  ?kg q-0.5 s^-1 m^-2   kg^-0.5 s m^-1 q^0.5 
    %m^-3 = m^-3
    
    
    
    ne = sqrt(2*pi*CO.me*Te)*a(1) / (IN.probe_A*CO.e.^1.5); %sensitivity to Vsc
    % errors still comes from Te, but we can substitute for that with assumptions on Te Later
    
     
    ne = ne /1E6;
    s_ne = sqrt((0.5*s_Te/sqrt(Te)).^2 +a(2).^2);
    
    
    %OBS. LP is not in perfect 0 V vaccuum, so expect the LP to be shielded from low energy electrons
    %i.e. giving a larger mean Te, and a lower ne. (see SPIS simulations)
    %think of it as if the LP is sampling a electron distribution with a
    %cut-off at certain temperatures.
    
    %   ne = Ie0/(IN.probe_area*CO.qe*1e6*sqrt(CO.qe*Te/(2*pi*CO.me)));
    if(ne<0)
        ne=NaN;
    end
    
    out.ne = [ne s_ne];

    Ie(1:firstpos-1)=Ie0*exp(Vp(1:firstpos-1)/Te);
    
    %Ie(1:firstpos)=0;
    %Ie(1:firstpos)=Ie0*exp(Vp(1:firstpos)/Te); %in the absence of
    %spacecraft photoelectrons analysis, this approximation will have a
    %too large effect on the ion side of the sweep.
    Ie(firstpos:len)= Ie0*(1+Vp(firstpos:len)/Te);
    Ie = (Ie+abs(Ie))./2; % The negative part is removed, leaving only a positive
    % current contribution. This is the return current
    % The function abs returns the absolute value of the
    % elements of the calling parameter.
    
else
    
    Te=NaN;
    
end




out.I = Ie;
out.Vpa = a;
out.Vpb = b;
out.Te = [Te s_Te];
out.a = [PVb(1) a(2)];
out.b = [PVb(2) b(2)];




end


