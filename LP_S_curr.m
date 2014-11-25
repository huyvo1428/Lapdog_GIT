%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Name: LP_Electron_curr.m
% Author:
%         Fredrik Johansson
%
%
%
% Description:
%	[Ts,ns,Q] = LP_S_curr(V,I,Vsc)
%    instead of plasma electrons, it looks at spacecraft photoelectrons
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

function [Ts,ns,Is,a,b] = LP_S_curr(V,I,Vplasma,illuminated)

global an_debug VSC_TO_VPLASMA VB_TO_VSC;
global CO IN; %constants

%init outputs
Ts=NaN;
ns=NaN;
Is=I;
Is(1:end)=0;
a=[NaN NaN];
b=a;
currvar=NaN;

%start by smoothing current

% The length of the data set is saved in the variable "len"
len = length(V);


%Vp = V+ Vsc,
%V? = Vp -Vplasma.
Vs = V+Vplasma; % Compute potential as a function relative to Vplasma
Vs=V+Vplasma*(-1+1/VSC_TO_VPLASMA); %= V + Vsc - Vplasma


% Find the data points above the spacecraft potential

if illuminated
    SM_Below_Vsc= 0.65;
    %  ind = find(V > Vsc/VBSC_TO_VSC);% Saving indices of all potential values above the knee.
    %  firstpos=find(V > -Vplasma,1,'first');
    
else
    SM_Below_Vsc=0;
    %     ind = find(V > -Vplasma);% Saving indices of all potential values above the knee.
    %     firstpos=ind(1);
    %
end


% Find the data points above the spacecraft potential


ind = find(Vs > 0); % Saving indices of all potential values above the spacecraft potential.
if (isempty(ind) || length(ind) < 2)
    return
end

firstpos=ind(1);


% Use the lowest ALG.SM_Below_Vs*100% of the bias voltage, below the spacecraft potential
% The data is sorted from lowest bias voltage to highest bias voltage so
% the first ALG.SM_Below_Vs*100% is OK to use
l_ind = length(ind); % Need the number of data points of the vector ind
% the function length returns the length of vector ind

bot = floor(ind(1)+l_ind*SM_Below_Vsc +0.5);

%top = floor(l_ind*ALG.SM_Below_Vs); % The point closest to, but below, ALG.SM_Below_Vs*100% of the
% spacecraft potential. The function floor rounds
% the calling parameter to the nearest integer
% towards minus infinity.
bot= bot -1 + find(I(bot:end)>0,1,'first');    %currents above 0
%choose starting point some points away from Vsc and has a positive
%current value.


%bot = max([ind(1),bot]);

ind = bot:len; % Only the first ALG.SM_Below_Vs*100% above the spacecraft potential is now


Vr  = Vs(ind);     % kept of the vector ind
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

if (isempty(ind) || length(ind) < 2)
    return
end

[P,S] = polyfit(Vr,Ir,1);

a(1) = P(1); % This is accordingly the slope of the line...
b(1) = P(2); % ...and this is the crossing on the y-axis of the line

S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df); % the std errors in the slope and y-crossing

a(2) = abs(S.sigma(1)/P(1)); %Fractional error
b(2) = abs(S.sigma(2)/P(2)); %Fractional error

%I = Ie0(1+Vp/Te). a = Ie0/Te, b = Ie0.
Is0 =  b(1);
Ts = b(1)/a(1);


residual = Ir - b(1)+a(1)*Vr;

% Compute the rms error and scale by the current Ie0 at Vr=Vp=0
currvar = sqrt(sum((residual).^2)/len)/Is0; % Compute the relative rms error



% If Te is positive we can get the density as follows
if(Ts>=0 && ~isinf(Ts))
    
    
    ns = Is0 / IN.probe_A*CO.e*sqrt(CO.e*Ts/2*pi*CO.me);
    ns = ns *1e-6;
    
    
    %    ne = Ie0 /(0.25E-3*1.6E-19*sqrt(1.6E-19*Te/(2*pi*9.11E-31)));
%    ns = Is0 /(0.25E-3*q_e*sqrt(q_e*Ts/(2*pi*m_e)));
    
    %OBS. LP is not in perfect 0 V vaccuum, so expect the LP to be shielded from low energy electrons
    %i.e. giving a larger mean Te, and a lower ne. (see SPIS simulations)
    %think of it as if the LP is sampling a electron distribution with a
    %cut-off at certain temperatures.
    
    %   ne = Ie0/(IN.probe_area*CO.qe*1e6*sqrt(CO.qe*Te/(2*pi*CO.me)));
    if(ns<0)
        ns=NaN;
    end
    
    %        Is(1:firstpos)=0;
    Is(1:firstpos-1)=Is0*exp(Vs(1:firstpos-1)/Ts);
    %Ie(1:firstpos)=Ie0*exp(Vp(1:firstpos)/Te); %in the absence of
    %spacecraft photoelectrons analysis, this approximation will have a
    %too large effect on the ion side of the sweep.
    Is(firstpos:len)= Is0*(1+Vs(firstpos:len)/Ts);
    Is = (Is+abs(Is))./2; % The negative part is removed, leaving only a positive
    % current contribution. This is the return current
    % The function abs returns the absolute value of the
    % elements of the calling parameter.
    
else
    if(a>0) % check slope
        %this happens if the Vrelation is wrong, so the y-intersect is on the
        %negative side. The curve is OK, so we still want the positive
        %side of the sweep to be subtracted from the total current.
        
        
        Is(1:firstpos-1)=Is0*exp(Vs(1:firstpos-1)/Ts);
%        Is(1:firstpos)=0;
        Is(firstpos:len)= Is0*(1+Vs(firstpos:len)/Ts);
        Is = (Is+abs(Is))./2; % The negative part is removed, leaving only a positive
        % current contribution. This is the return current
        % The function abs returns the absolute value of the
        % elements of the calling parameter.
    end
    
    
    Ts=NaN;
    
end



%Ie = polyval(P,V);    % The current is calculated across the entire potential
% sweep. The function polyval returns the value of the
% polynomial P evaluated at all the points of the vector V.
%                       Ie = Ie0exp(Vp/Te)








%     q_index=1;
%     second_digit=LP_Quality.SD0_Nominal;
%     if(currvar>LP_Quality.SM_Currv0) q_index=q_index+1; end;
%     if(currvar>LP_Quality.SM_Currv1) q_index=q_index+1; end;
%     if(currvar>LP_Quality.SM_Currv2) q_index=q_index+1; end;
%     if(q_index>1)
%         second_digit=LP_Quality.SD3_LargeVariations;
%     end
% Qtmp =0;
%         Qtmp=LP_Quality.FD(q_index)*10+second_digit;
% end
% end

% % If Te is not NaNs
% if(~isnan(Te))
%     Q(1)=Qtmp;
% end
%
% % If Ne is not NaNs
% if(~isnan(ne))
%     Q(2)=Qtmp;
% end
% % If Vs is not NaNs
% if(~isnan(Vsc))
%     Q(3)=Qtmp;
% end
end


