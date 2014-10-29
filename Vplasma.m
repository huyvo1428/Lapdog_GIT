%Vplasma
%takes an sweep potential array and current array, and optionally a guess for the
%Vplasma and its sigma (suggested sigma 3 V), outputs an estimate for the
%plasma potential and it's confidence level (std)
function [vPlasma,sigma,vSC] = Vplasma(Vb2,Ib2,vGuess,sigmaGuess)

VSC_TO_VPLASMA=0.64; %from SPIS simulation experiments
VB_TO_VSC = -1/(1-VSC_TO_VPLASMA); %-1/0.36


%narginchk(2,4); %nargin should be between 2 and 4, this throws an error if else
%undefined function in old MATLAB........!!


diag = 1;

[Vb, junk, ic] = unique(Vb2);

Ib = accumarray(ic,Ib2,[],@mean);


len= length(Vb);

[di,d2i]= leapfd(Ib,Vb,0.28);



[Vb,ind]=sort(Vb);
d2i=d2i(ind);
di=di(ind);

posd2i =(abs(d2i)+d2i)/2;

% ind0= find(~d2i,1,'first');
% ind1 = find(~d2i,1,'last');
% ind0 = 1;

%sort absolute values of derivative



if nargin>2   %if a guess is given
    
    vSC=vGuess/VSC_TO_VPLASMA;
    vbGuess=vGuess-vSC;
    
[junk,chosen] =min(abs(Vb-vbGuess));
else
[junk,pos]= sort(abs(di));
top10= floor(len*0.9+0.5); %get top 10 percent of peaks
chosen=min(pos(top10:end)); % prioritise earlier peaks, because electron side (end) can be noisy    
end

%get a region around our chosen guesstimate.
lo= floor(chosen-len*0.20 +0.5); %let's try 40% of the whole sweep
hi= floor(chosen+len*0.20 +0.5); %+0.5 pointless but good practise

lo = max([lo,1]); %don't move outside 1:len)
hi = min([hi,len]);

ind = lo:hi; %ind is now a region around the earliest of the high abs(derivative) peaks
              %or a region around our Vguess

if nargin>2
    
    %[sigma,Vplasma] =gaussfit(Vb(ind0:ind1),d2i(ind0:ind1),sigmaGuess,vGuess);
    %these vGuesses are never agood!
    [sigma,vbPlasma] =gaussfit(Vb(ind),posd2i(ind),sigmaGuess,Vb(chosen));
    
    
else
    [sigma,vbPlasma] =gaussfit(Vb(ind),posd2i(ind));
   

end


if isnan(vbPlasma)
    %if it's NaN, try the whole spectrum, no fancy guesswork.
    [sigma,vbPlasma] =gaussfit(Vb,posd2i);
end





% tind= find(le(d2i,0));
% d2i(tind) =0;
%
% %temp = d2lfvb/mean(d2lfvb);
%

% [gsd,gmu] =gaussfit(Vb(10:end-10),d2i(10:end-10));'
if diag
    
    
%just for diagnostics
    Ib5 = smooth(Ib,0.14,'sgolay');
    figure(3)
    subplot(2,2,1)
    x = Vb(1):0.2:Vb(end);
    y = gaussmf(x,[sigma vbPlasma]);
    plot(x,y*max(4*d2i/sum(d2i)),'r',Vb,4*d2i/sum(d2i),'b')
    
    subplot(2,2,3)
    plot(Vb,Ib5);

    
    Ib3 = accumarray(ic,Ib2,[],@mean);
    [junk,d2i2]= leapfd(Ib3,Vb,0.14);
    d2i2=d2i2(ind);
     posd2i2=(abs(d2i2)+d2i2)/2;
%     ind02= find(~d2i,1,'first');
% ind12 = find(~d2i,1,'last');


    [sigma2,Vbplasma2] =gaussfit(Vb,posd2i2,sigmaGuess);
     x = Vb(1):0.2:Vb(end);
    y = gaussmf(x,[sigma2 Vbplasma2]);
    subplot(2,2,2)
     plot(x,y*max(4*d2i2/sum(d2i2)),'r',Vb,4*d2i2/sum(d2i2),'b')
    subplot(2,2,4)
    plot(Vb,Ib3);

    xlabel('gaussmf, P=[2 5]')
    
end
    

% vSC + vbPlasma = vPlasma, since a 10V s/c gives a peak at  -3.6 Vb, or
% 6.4 Vp (Vb = Vp-Vsc)

vSC= vbPlasma*VB_TO_VSC; %vSC = vbplasma * -1 /0.36
vPlasma=vSC*VSC_TO_VPLASMA;  %vPlasma = 0.64*vSC;
sigma = sigma*abs(VB_TO_VSC); %


%vPlasma=vSC+vbPlasma;


if nargin>2 && isnan(vbPlasma)
    vPlasma=vGuess;  %don't guess anymore, just output input value.
    vSC=vPlasma/VSC_TO_VPLASMA;
    sigma = NaN;
%    sigma = sigma*abs(VB_TO_VSC); %

        
end


end
