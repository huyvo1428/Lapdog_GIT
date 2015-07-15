%Vplasma
%takes an sweep potential array and current array, and optionally a guess for the
%Vplasma and its sigma (suggested sigma 3 V), outputs an estimate for the
%plasma potential, Vsc and Vbar and it's confidence level (std)
function [out] = an_Vplasma_v2(Vb,Ib,vGuess,sigmaGuess)


out = [];


%default every value to [NaN,NaN]. Also if the algorithm doesn't converge, NaN is outputted
out.Vsc      = nan(1,2); %value & relative std
out.Vph_knee = nan(1,2); 
out.Vbar     = nan(1,2); 

%|Vph_knee|???|Vsc| and sign(Vph_knee) = sign(Vph_knee

%Vbar = Vsc unless max(di)==di(end).(hot electrons,maybe Vsc <-30V). 
%we have reasons to distrust results where max(di)==di(end).


global an_debug ; %debug plot variable


len= length(Vb);

[di,d2i]= centralDD(Ib,Vb,0.28); %get central difference of Derivative and 2nd Deriv. Smoothed
%[di,d2i]= centralDD(Ib,Vb); %get central difference of Derivative and 2nd Deriv. Smoothed

%[xdi,xd2i]= centralDD(Ib,Vb);

[Vb,ind]=sort(Vb); %maybe not needed
d2i=d2i(ind);
di=di(ind);



posd2i =(abs(d2i)+d2i)/2;  %ignore negative values

posd2i_filt= posd2i;


posd2i_filt(Ib>0) = 0;


%sort absolute values of derivative

if nargin>2   %if a guess is given
    
    vbGuess=-vGuess;
    
[junk,firstpeak] =min(abs(Vb-vbGuess));
else
    
%[junk,pos]= sort(abs(posd2i));

[junk,pos]= sort(abs(posd2i_filt));

top10ind= floor(len*0.95+0.5); %get top 10 percent of potential peak positions
%firstpeak=min(pos(top10ind:end)); % prioritise earlier left peaks, because electron side (end) can be noisy    
firstpeak= pos(end); % We could also run into giant current derivatives
%after Vph_knee, so let's keep this at early peaks Ib>0;




end

%get a region around our chosen guesstimate.
lo= floor(firstpeak-len*0.1 +0.5); %let's try 20% of the whole sweep
hi= floor(firstpeak+len*0.1 +0.5); %+0.5 pointless but good practise

lo = max([lo,1]); %don't move outside 1:len)
hi = min([hi,len]);
d1v= floor(1/(Vb(2)-Vb(1)));

pox = diff(d2i);

if hi>firstpeak+1 %careful
    for i = firstpeak+d1v:hi
        if ge(pox(i),0)
            hi = i;
            break; % let's stop the region here, we don't want unwanted peaks to the right of the first peak
        end
    end
end



ind = lo:hi; %ind is now a region around the earliest of the high abs(derivative) peaks
              %or a region around our Vguess

if nargin>2
    
    %[sigma,Vplasma] =gaussfit(Vb(ind0:ind1),d2i(ind0:ind1),sigmaGuess,vGuess);
    %these vGuesses are never agood!
    [sigma1,vbKnee1] =gaussfit(Vb(ind),posd2i(ind),sigmaGuess,Vb(firstpeak));
    
    
else
    [sigma1,vbKnee1] =gaussfit(Vb(ind),posd2i(ind));
   

end

%if the algorithm doesn't converge,try the whole spectrum, no fancy guesswork.

if isnan(vbKnee1)  %fall back to older version of analysis. Probably not a sunlit sweep
    
    
    firstpeak=min(pos(top10ind:end)); % prioritise earlier left peaks, because electron side (end) can be noisy    

    lo= floor(firstpeak-len*0.10 +0.5); %let's try 20% of the whole sweep
    hi= floor(firstpeak+len*0.10 +0.5); %+0.5 pointless but good practise

    lo = max([lo,1]); %don't move outside 1:len)    
    hi = min([hi,len]);

    ind = lo:hi; %ind is now a region around the earliest of the high abs(derivative) peaks
            
    [sigma1,vbKnee1] =gaussfit(Vb(ind),posd2i(ind));
    
    
    if isnan(vbKnee1) 
    [sigma1,vbKnee1] =gaussfit(Vb,posd2i);
    end

end

%-------- second peak? ---------------------------------------------
% take first fit, normalize it to 2nd derivative and subtract.

gaussian_reduction = 1*gaussmf(Vb,[sigma1 vbKnee1]).'; %get gaussian from fit.
reduced_posd2i = posd2i/mean(abs(posd2i))-gaussian_reduction*max(posd2i/mean(abs(posd2i)));

reduced_posd2i =(abs(reduced_posd2i)+reduced_posd2i)/2; %set negative values to 0

[junk,pos2]= sort(abs(reduced_posd2i)); %sort by absolute value)

secondpeak=pos2(end); %maximum point 


%-------- Time for logic ---------------------------------------------

%-------- Get out early? ------------------------
epsilon = 2; %the last (and first) two points on the second derivative have larger errors
if ge(epsilon,length(reduced_posd2i)-secondpeak)||ge(epsilon,secondpeak) %if this position is on the max or min Vb(step),then
    Vsc=-Vb(end);
    Sgsigma = NaN;
        %plot(Vb,posdi,'b',Vb,posd2i*6,'r',Vb,Ib/10,'g',Vb,ad2i*10,'black')
        
    Vph_knee = -vbKnee1;
    Vph_knee_sigma = abs(sigma1/vbKnee1);

    out.Vsc = [Vsc,Sgsigma];
    out.Vph_knee = [Vph_knee,Vph_knee_sigma];

    
    if an_debug > 1 %debug plot
    
        figure(444);
        %just for diagnostics
        subplot(1,2,1)
        x = Vb(1):0.2:Vb(end);
        y = gaussmf(x,[sigma1 vbKnee1]);
        %    y2 = gaussmf(x,[sigma2 vbKnee2]);
        plot(x,y*max(d2i/mean(abs(d2i))),'og',Vb,d2i/mean(abs(d2i)),'--b',Vb,4*Ib/mean(abs(Ib)),'black')
        title('anVplasma');
        grid on;
        
        subplot(1,2,2)
        %plot(Vb,  posd2i/trapz(Vb,posd2i)-gaussian_reduction/trapz(Vb,gaussian_reduction),'b',Vb, 0.01*(posd2i/mean(abs(posd2i))-gaussian_reduction*max(posd2i/mean(abs(posd2i)))),'r')
        %   z=posd2i/trapz(Vb,posd2i)-gaussian_reduction/trapz(Vb,gaussian_reduction);
        %   z=z*200;
        plot(Vb,di/mean(abs(di)),'b',Vb,d2i/mean(abs(d2i)),'r',Vb,reduced_posd2i*max(d2i/mean(abs(d2i))),'g');
        grid on;
        
    end
    
    
    
   return
        
end
    
    
    
    
%-------- Get Second Peak! ---------------------------------------------

    %get a region around our chosen guesstimate.
lo= floor(secondpeak-len*0.10 +0.5); %let's try 20% of the whole sweep
hi= floor(secondpeak+len*0.10 +0.5); %+0.5 pointless but good practise

lo = max([lo,1]); %don't move outside 1:len)
hi = min([hi,len]);

ind = lo:hi; %ind is now a region around the earliest of the high abs(derivative) peak

              
[sigma2,vbKnee2] =gaussfit(Vb(ind),reduced_posd2i(ind)); %second knee in sweep!
   



%-------- Time for more logic ---------------------------------------------


%if nan or vbKnee2 and vbKnee1 peaks overlap
%if isnan(vbKnee2) || abs(vbKnee2-vbKnee1) < sigma1+sigma2  sigma 2 is often
%very small...
    if isnan(vbKnee2) || abs(vbKnee2-vbKnee1) < sigma1*2  

    vbKnee2=vbKnee1;
    sigma2= sigma1;
end


if sign(vbKnee1)~= sign(vbKnee2) %if peaks on different sides of Vb = 0, ignore second peak
%maybe have a check if secondpeak>firstpeak. if so, pos(end) == pos2(end). This will be bad if Vsc>>1
    Vsc = -vbKnee1;
    Sgsigma = abs(sigma1/vbKnee1);
    Vph_knee = Vsc;
    Vph_knee_sigma = Sgsigma;

else

    
    if abs(vbKnee1)>abs(vbKnee2) %abs(Vsc)is always larger than abs(Vph_knee)
        Vsc = -vbKnee1;
        Sgsigma=abs(sigma1/vbKnee1);
        Vph_knee = -vbKnee2;
        Vph_knee_sigma=abs(sigma2/vbKnee2);
        
        
    else
        Vsc = -vbKnee2;
        Sgsigma=abs(sigma2/vbKnee2);
        Vph_knee = -vbKnee1;
        Vph_knee_sigma=abs(sigma1/vbKnee1);
        
    end
    

end



if max(di)==di(end) %if current slope is ever increasing in di (i.e. electron current dominated & Vsc > max(-Vb))
    
    out.Vbar = [Vsc,Sgsigma]; %then we found some other potential here.

    Vsc=-Vb(end);
    Sgsigma = NaN;

else
    
        out.Vbar = [Vsc,Sgsigma]; %otherwise... let's output Vsc also in the Vbar variable.

        
end



out.Vsc = [Vsc,Sgsigma];
out.Vph_knee = [Vph_knee,Vph_knee_sigma];


if an_debug > 1
    
    figure(444);
%just for diagnostics
    subplot(1,2,1)
    x = Vb(1):0.2:Vb(end);
    y = gaussmf(x,[sigma1 vbKnee1]);
    y2 = gaussmf(x,[sigma2 vbKnee2]);
    plot(x,y*max(d2i/mean(abs(d2i))),'og',x,y2*max(d2i/mean(abs(d2i))),'--r',Vb,d2i/mean(abs(d2i)),'--b',Vb,4*Ib/mean(abs(Ib)),'black')
    title('anVplasma');
    grid on;

    subplot(1,2,2)
 %   z=posd2i/trapz(Vb,posd2i)-gaussian_reduction/trapz(Vb,gaussian_reduction);
 %   z=z*200;
    plot(Vb,di/mean(abs(di)),'b',Vb,d2i/mean(abs(d2i)),'g',Vb,reduced_posd2i*max(d2i/mean(abs(d2i)))/10,'r');
    grid on;

    
    %    Ib5 = smooth(Ib,0.14,'sgolay');

%     Ib3 = accumarray(ic,Ib,[],@mean);
%     [junk,d2i2]= centralDD(Ib3,Vb,0.14);
%     d2i2=d2i2(ind);
%      posd2i2=(abs(d2i2)+d2i2)/2;
% %     ind02= find(~d2i,1,'first');
% % ind12 = find(~d2i,1,'last');
% 
% 
% %    [sigma2,Vbplasma2] =gaussfit(Vb,posd2i2,sigmaGuess);
%      x = Vb(1):0.2:Vb(end);
%     y = gaussmf(x,[sigma2 Vbplasma2]);
%     subplot(2,2,2)
%      plot(x,y*max(4*d2i2/sum(d2i2)),'r',Vb,4*d2i2/sum(d2i2),'b')
%     subplot(2,2,4)
%     plot(Vb,Ib3);
%    xlabel('gaussmf, P=[2 5]')
    
end
% length(reduced_posd2i)-secondpeak 
  
%tempdelet=1;
%Kneesigma = abs(sigma1/vbKnee1);

%Vph_knee = -vbKnee1;

%vPlasma=vSC+vbPlasma;

