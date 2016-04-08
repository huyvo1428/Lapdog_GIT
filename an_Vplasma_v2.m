%Vplasma
%takes an sweep potential array and current array, and optionally a guess for the
%Vplasma and its sigma (suggested sigma 3 V), outputs an estimate for the
%plasma potential and it's confidence level (std)
%function [Vsg,Sgsigma,Vph_knee,Vph_knee_sigma] = an_VsgVphknee(Vb,Ib,vGuess,sigmaGuess)
function [out] = an_Vplasma_v2(Vb,Ib,vGuess,sigmaGuess)


out = [];
out.Vsc      = nan(1,2);
out.Vph_knee = nan(1,2);
out.Vbar     = nan(1,2);


global an_debug ;


len= length(Vb);

[di,d2i]= centralDD(Ib,Vb,0.28);

[Vb,ind]=sort(Vb);
d2i=d2i(ind);
di=di(ind);



posd2i =(abs(d2i)+d2i)/2;

%sort absolute values of derivative

if nargin>2   %if a guess is given

%    vSC=vGuess/VSC_TO_VPLASMA;
%    vbGuess=vGuess-vSC;

    vbGuess=-vGuess;


[junk,firstpeak] =min(abs(Vb-vbGuess));
else
[junk,pos]= sort(abs(posd2i));
top10ind= floor(len*0.9+0.5); %get top 10 percent of peaks
firstpeak=min(pos(top10ind:end)); % prioritise earlier peaks, because electron side (end) can be noisy
end

%get a region around our chosen guesstimate.
lo= floor(firstpeak-len*0.06 +0.5); %let's try 20% of the whole sweep
hi= floor(firstpeak+len*0.14 +0.5); %+0.5 pointless but good practise

lo = max([lo,1]); %don't move outside 1:len)
hi = min([hi,len]);

ind = lo:hi; %ind is now a region around the earliest of the high abs(derivative) peaks
              %or a region around our Vguess

if nargin>2

    %[sigma,Vplasma] =gaussfit(Vb(ind0:ind1),d2i(ind0:ind1),sigmaGuess,vGuess);
    %these vGuesses are never agood!
    [sigma1,vbKnee1] =gaussfit(Vb(ind),posd2i(ind),sigmaGuess,Vb(firstpeak));


else
    [sigma1,vbKnee1] =gaussfit(Vb(ind),posd2i(ind));


end


if isnan(vbKnee1)
    %if it's NaN, try the whole spectrum, no fancy guesswork.
    [sigma1,vbKnee1] =gaussfit(Vb,posd2i);
end


gaussian_reduction = gaussmf(Vb,[sigma1 vbKnee1]).';
reduced_posd2i = posd2i/mean(abs(posd2i))-gaussian_reduction*max(posd2i/mean(abs(posd2i)));

reduced_posd2i =(abs(reduced_posd2i)+reduced_posd2i)/2; %set negative values to 0

[junk,pos]= sort(abs(reduced_posd2i)); %sort by absolute value)
%top10ind= floor(len*0.9+0.5); %get top 10 percent of peaks
%secondpeak=min(pos(top10ind:end)); % prioritise earlier peaks, because electron side (end) can be noisy
secondpeak=pos(end); %maximum point

epsilon = 2; %the last (and first) two points on the second derivative have larger errors

%-------- Time for logic ---------------------------------------------

%-------- Get out early? ------------------------
if ge(epsilon,length(reduced_posd2i)-secondpeak)||ge(epsilon,secondpeak) %if this position is on the max or min Vb(step),then
    Vsc=-Vb(end);
    Sgsigma = NaN;
        %plot(Vb,posdi,'b',Vb,posd2i*6,'r',Vb,Ib/10,'g',Vb,ad2i*10,'black')

    Vph_knee = -vbKnee1;
    Vph_knee_sigma = abs(sigma1/vbKnee1);

    out.Vsc = [Vsc,Sgsigma];
    out.Vph_knee = [Vph_knee,Vph_knee_sigma];


    if an_debug > 1

        figure(44);
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


%vbKnee2 may be NaN
% if isnan(vbKnee2)
%     %if it's NaN, try the whole spectrum, no fancy guesswork.
% %    [Kneesigma,vbKnee] =gaussfit(Vb,posd2i);
% end

%-------- Time for more logic ---------------------------------------------


%if nan or vbKnee2 and vbKnee1 peaks overlap
%if isnan(vbKnee2) || abs(vbKnee2-vbKnee1) < sigma1+sigma2  sigma 2 is often
%very small...
    if isnan(vbKnee2) || abs(vbKnee2-vbKnee1) < sigma1*2

    vbKnee2=vbKnee1;
    sigma2= sigma1;
end


%if sign(vbKnee1)~= sign(vbKnee2) %if peaks on different sides of Vb = 0, ignore second peak

% Vsc   Vsc = -vbKnee1;
%    Sgsigma = abs(sigma1/vbKnee1);
%    Vph_knee = Vsc;
%    Vph_knee_sigma = Sgsigma;
%
%else



    if vbKnee1>vbKnee2 %abs(Vsc)is always larger than abs(Vph_knee)     x>y -> vsc = -x, vph_knee = -y
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




%    if abs(vbKnee1)>abs(vbKnee2) %abs(Vsc)is always larger than abs(Vph_knee)
%        Vsc = -vbKnee1;
%        Sgsigma=abs(sigma1/vbKnee1);
%        Vph_knee = -vbKnee2;
%        Vph_knee_sigma=abs(sigma2/vbKnee2);
%
%
%    else
%        Vsc = -vbKnee2;
%        Sgsigma=abs(sigma2/vbKnee2);
%        Vph_knee = -vbKnee1;
%        Vph_knee_sigma=abs(sigma1/vbKnee1);
%
%    end


%end



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

    figure(44);
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
    plot(Vb,di/mean(abs(di)),'b',Vb,d2i/mean(abs(d2i)),'g',Vb,reduced_posd2i*max(d2i/mean(abs(d2i))),'r');
    grid on;


    %    Ib5 = smooth(Ib,0.14,'sgolay');

%     Ib3 = accumarray(ic,Ib,[],@mean);
%     [junk,d2i2]= leapfd(Ib3,Vb,0.14);
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
