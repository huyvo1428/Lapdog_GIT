function [out] = LP_expfit_Te(V,I,Vknee)
%inputs: 
%   V: sorted(increasing) Voltage bias array 
%   I: sweep current array
%   Vknee: Voltage at the knee of the LP sweep (either sunlit or not)
%takes a LP sweep, finds region 1V below the knee and currents above 0
% weights the arrays with importance on the higher current values (closer
% to Vknee)
%fits the weighted arrays with a VvslogI, outputs Te, Ie0 and sigmas.

global an_debug


out =[]; %init output    
out.Te=[NaN NaN];
out.Ie0 =[NaN NaN];


Vp = V+Vknee;

eps= 1; %moves 0V to the left

try
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
Vr = V(rind);

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


[P,S]= polyfit(V_w,log(I_w),1);



Te = 1/P(1);
Ie0 = exp(P(2)*Te);

try  %super risky sigma calculation. 
    S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df); % the std errors in the slope and y-crossing
    
    s_Te = abs(S.sigma(1)/P(1)); %Fractional error
    s_Ie0 = abs(S.sigma(2)/P(2)); %Fractional error
catch err
    
    s_Te = NaN;
    s_Ie0= NaN;
    
    out.Te=[Te s_Te];
    out.Ie0 =[Ie0 s_Ie0];
    return
    
end

if qbad
    s_Te = NaN;
    s_Ie0 = NaN;
end

out.Te=[Te s_Te];
out.Ie0 =[Ie0 s_Ie0];

if an_debug >7 %any condition
    
    figure(35)
    
    subplot(1,3,1)
    plot(V,I,'b',V(ind(end)),I,'r');
    subplot(1,3,2)
    plot(Vr,log(Ir),'b',Vr,Vr*P(1)+P(2),'--');
    
    axis([Vr(1) Vr(end) log(Ir(1)) log(Ir(end))])

    subplot(1,3,3)


    plot(Vr,Ir,'b');
    axis([Vr(1) Vr(end) Ir(1) Ir(end)])
    title([sprintf('Te:%3.1f fracstd:%1.3f\%',out.Te)]);
    
    %plot(Vr,Ir,'b',Vr(ind(end)),Ir,'r');

end

end




