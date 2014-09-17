%Vplasma
%takes an potential array and current array, and optionally a guess for the
%Vplasma and its sigma (suggested sigma 3 V), outputs an estimate for the
%plasma potential and it's confidence level (std)
function [vPlasma,sigma] = Vplasma(Vb2,Ib2,vGuess,sigmaGuess)

%narginchk(2,4); %nargin should be between 2 and 4, this throws an error if else
%undefined function in old MATLAB........!!


diag = 0;

[Vb, junk, ic] = unique(Vb2);

Ib = accumarray(ic,Ib2,[],@mean);

% %don't do it here, silly. it's done in d2i if you ask it too

%vbzero= find(le(Vb,0));
[junk,d2i]= leapfd(Ib,Vb,0.28);



[Vb,ind]=sort(Vb);
d2i=d2i(ind);

posd2i =(abs(d2i)+d2i)/2;

% ind0= find(~d2i,1,'first');
% ind1 = find(~d2i,1,'last');
% ind0 = 1;


%nd2i = d2i(ind0:ind1)/(sum(d2i(ind0:ind1)));



if nargin>2

%[sigma,Vplasma] =gaussfit(Vb(ind0:ind1),d2i(ind0:ind1),sigmaGuess,vGuess);
%these vGuesses are never agood!
[sigma,vbPlasma] =gaussfit(Vb,posd2i,sigmaGuess) ;
else
    
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
    


vPlasma = -vbPlasma; 


end
