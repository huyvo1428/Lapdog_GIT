%Vplasma
%takes an sweep potential array and current array, and optionally a guess for the
%Vplasma and its sigma (suggested sigma 3 V), outputs an estimate for the
%plasma potential and it's confidence level (std)
function [vKnee,sigma] = an_Vplasma(Vb,Ib,vGuess,sigmaGuess)

global an_debug ; 
% should VSC etc be decided here? Why? 

%narginchk(2,4); %nargin should be between 2 and 4, this throws an error if else
%undefined function in old MATLAB........!!




len= length(Vb);

[di,d2i]= leapfd(Ib,Vb,0.28);



[Vb,ind]=sort(Vb);
d2i=d2i(ind);
di=di(ind);

posd2i =(abs(d2i)+d2i)/2;

%sort absolute values of derivative

if nargin>2   %if a guess is given
    
%    vSC=vGuess/VSC_TO_VPLASMA;
%    vbGuess=vGuess-vSC;

    vbGuess=-vGuess;
    

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
    [sigma,vbKnee] =gaussfit(Vb(ind),posd2i(ind),sigmaGuess,Vb(chosen));
    
    
else
    [sigma,vbKnee] =gaussfit(Vb(ind),posd2i(ind));
   

end


if isnan(vbKnee)
    %if it's NaN, try the whole spectrum, no fancy guesswork.
    [sigma,vbKnee] =gaussfit(Vb,posd2i);
end




if an_debug > 9
    
    
%just for diagnostics
    Ib5 = smooth(Ib,0.14,'sgolay');
    figure(3)
    subplot(2,2,1)
    x = Vb(1):0.2:Vb(end);
    y = gaussmf(x,[sigma vbKnee]);
    plot(x,y*max(d2i/mean(abs(d2i))),'--r',Vb,d2i/mean(abs(d2i)),'--b',Vb,4*Ib/mean(abs(Ib)),'black')
    
    subplot(2,2,3)
    plot(Vb,Ib5);


    
    
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
    


vKnee = -vbKnee;

%vPlasma=vSC+vbPlasma;


if nargin>2 && isnan(vbKnee)
    vKnee=vGuess;  %don't guess anymore, just output input value.
    sigma = NaN;
        
end


end
