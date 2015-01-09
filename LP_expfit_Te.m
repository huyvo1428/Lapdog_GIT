
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Name: LP_expfit_Te.m
% Author: Fredrik Johansson 2014 IRFU
% Description:
%   Function that takes a LP sweep, finds region 1V below the knee and 
%   currents above 0 (assuming it is electron dominated). Weights the arrays 
%   with importance on the higher current values (closer to Vknee).
%   Fits the weighted arrays with a Vp vs logI fit, outputs electron parameters
% Inputs:
%   V: sorted(increasing) Voltage bias array 
%   I: sweep current array
%   Vknee: Voltage at the knee of the LP sweep (either sunlit or not)
% Outputs:
%   out.I: current contribution from electron current?[A]
%   out.Te: electron Temperature [eV]
%   out.ne: electron density [cm^-3]
%   out.Ie0: Ie0 [A]
%   out.Vpa: slope of log I vs Vp fit
%   out.Vpb: y-intersection of log I vs Vp fit.
function [out] = LP_expfit_Te(V_unfilt,I_unfilt,Vknee,filter_ind)


global an_debug IN CO




%init outputs
Ie=I_unfilt;
Ie(1:end)=0;
out =[];

out.I = Ie;
out.Vpa = nan(1,2); %NaN;
out.Vpb = nan(1,2);

out.Te = nan(1,2);
out.ne = nan(1,2);
%out.ne = nan(1,2);
out.Ie0 = nan(1,2);

ne=NaN;



%filter sweep from photoelectron dominant points? 
V = V_unfilt;
I = I_unfilt;

if ~isempty(filter_ind)
    V(filter_ind) = [];
    I(filter_ind) = [];
end

Vp = V+Vknee;
Vp_unfilt = V_unfilt+Vknee;

eps= 0; %moves "0 V" to the left



try
    firstpos=find(Vp_unfilt>0,1,'first');
    if isempty(firstpos)
        firstpos=length(Vp);
    end
    
    

    ind= find(Vp+eps < 0); %this could be empty (not likely)
    
    bot=find(I(ind)<0,1,'last')+1; %this could be empty (possible)
    if isempty(bot)
        bot = 1;
    end
    
    rind = ind(bot):ind(end); %this could be even more empty

    
catch err    
    return
end


if isempty(rind) || length(rind)<2 % fail safe    
    return
end



% len=length(rind);
% bot= ind(end)-floor(0.9*len+0.5); % take away bottom 10% of points.. 
% %suggestion:  weight the current array with increased weight given to
% %higher current values.
% 
% rind= bot:ind(end);





Ir = I(rind);
Vr = Vp(rind);

V_w= Vr;
I_w = Ir;

len=length(Vr);
qbad = 0;
%weight values according to new 
for i=1:8
    b=floor((10-i)*len/10+0.5); %step b from 90% to 20% of len, and round
    if ~(b>0) %this happens if length is less than two
        qbad=1;
    end
    
    b= max(b,1); %b shouldn't be zero at any point.
    V_w = [Vr(b:end) V_w]; %add to V_w, I_w;
    I_w = [Ir(b:end) I_w]; 
    
    
end


[P,junk]= polyfit(V_w,log(I_w),1); %sigma calculation doesn't make sense with weighted fit. Do sigma analysis on Ir,Vr fit



Te = 1/P(1);
Ie0 = exp(P(2));

try  %super risky sigma calculation. 
    [Ps,S]= polyfit(Vr,log(Ir),1);

    S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df); % the std errors in the slope and y-crossing
    
    s_Te = abs(S.sigma(1)/Ps(1)); %Fractional error
    
    s_Ie0 = abs(S.sigma(2)); %Fractional error from function of dq/q=dq/dx * dx. q=e^x-> dq/q=dx
catch err % don't care if this throws error, continue
    
    s_Te = NaN;
    s_Ie0= NaN;
    

    %return
end

if qbad
    s_Te = NaN;
    s_Ie0 = NaN;
end


if(Te>=0 && ~isinf(Te))
    %    ne = Ie0 /(0.25E-3*1.6E-19*sqrt(1.6E-19*Te/(2*pi*9.11E-31)));
    % current = charge*density * area *velocity
    % ne = Ie0 / area*charge*velocity
    ne = Ie0 / (IN.probe_A*CO.e*sqrt(CO.e*Te/(2*pi*CO.me)));
    
    
    
   % ne = sqrt(2*pi*CO.me*Te/CO.e)*a(1) / (IN.probe_A*CO.e.^1.5); %sensitivity to Vsc

    ne = ne /1E6;
            
    %ne2 = Ie0 /(0.25E-3*q_e*sqrt(q_e*Te/(2*pi*m_e)));
    
    %OBS. LP is not in perfect 0 V vaccuum, so expect the LP to be shielded from low energy electrons
    %i.e. giving a larger mean Te, and a lower ne. (see SPIS simulations)
    %think of it as if the LP is sampling a electron distribution with a
    %cut-off at certain temperatures.
    
    %   ne = Ie0/(IN.probe_area*CO.qe*1e6*sqrt(CO.qe*Te/(2*pi*CO.me)));
    if(ne<0)
        ne=NaN;
    end
    
    

    
    Ie(1:firstpos-1)=Ie0*exp(Vp_unfilt(1:firstpos-1)/Te);
    
    %Ie(1:firstpos)=0;
    %Ie(1:firstpos)=Ie0*exp(Vp(1:firstpos)/Te); %in the absence of
    %spacecraft photoelectrons analysis, this approximation will have a
    %too large effect on the ion side of the sweep.
    Ie(firstpos:end)= Ie0*(1+Vp_unfilt(firstpos:end)/Te);
    Ie = (Ie+abs(Ie))./2; % The negative part is removed, leaving only a positive
    % current contribution. This is the return current
    % The function abs returns the absolute value of the
    % elements of the calling parameter.
    
else
    
    Te=NaN;
    
end
s_ne = sqrt(s_Ie0.^2 +(0.5*s_Te/sqrt(Te)).^2);

%s_ne = sqrt(s_Ie0.^2 + 0.5*s_Te.^2);

out.I = Ie;
out.Te=[Te s_Te];
out.Ie0 =[Ie0 s_Ie0];
out.Vpa = [P(1),s_Te];
out.Vpb = [P(2),s_Ie0];
%out.ne = ne;
out.ne = [ne, s_ne];


%out.a = [P2(1) a(2)];
%out.b = [P2(2) b(2)];



if an_debug >7 %debug condition
    
    figure(35)
    
    subplot(1,3,1)
    plot(V,I,'bo',V_unfilt,I_unfilt,'b+',V(ind(end)),I,'black',V_unfilt,Ie,'ro');
        axis([V(1) V(end) I_unfilt(1) max(I_unfilt)])

    subplot(1,3,2)
    plot(Vr,log(Ir),'b',Vr,Vr*P(1)+P(2),'--');
    
    axis([Vr(1) Vr(end) log(Ir(1)) log(Ir(end))])
    title([sprintf('Te:%3.1f fracstd:%1.3f\%',out.Te)]);

    subplot(1,3,3)


    plot(Vr,Ir,'b');
    axis([Vr(1) Vr(end) Ir(1) Ir(end)])
    title([sprintf('Ie0:%4.2e fracstd:%1.3f\%',out.Ie0)]);
    
    %plot(Vr,Ir,'b',Vr(ind(end)),Ir,'r');

end



end




