%Vplasma
function [Vplasma,sigma] = Vplasma(Vb,Ib2)
diag = 0;

[Vb, ~, ic] = unique(Vb);

Ib = accumarray(ic,Ib2,[],@mean);

% points = length(Vb);
% lgolay = max([(2*floor(points/12)+1) 5]);


%%Vplasma
%points = length(Vb);


%vbzero= find(le(Vb,0));
[~,d2i]= leapfd(Ib,Vb,2);



[Vb,ind]=sort(Vb);
d2i=d2i(ind);
tempi=4*d2i/sum(d2i);

d2i=(abs(d2i)+d2i)/2;

ind0= find(~d2i,1,'first');
ind1 = find(~d2i,1,'last');

%nd2i = d2i(ind0:ind1)/(sum(d2i(ind0:ind1)));

[sigma,Vplasma] =gaussfit(Vb(ind0:ind1),d2i(ind0:ind1));

% tind= find(le(d2i,0));
% d2i(tind) =0;
%
% %temp = d2lfvb/mean(d2lfvb);
%

% [gsd,gmu] =gaussfit(Vb(10:end-10),d2i(10:end-10));'
if diag
    figure(3)
    x = Vb(1):0.2:Vb(end);
    y = gaussmf(x,[sigma Vplasma]);
    plot(x,y,Vb,4*d2i/sum(d2i),Vb,tempi)
    
    xlabel('gaussmf, P=[2 5]')
    
end



end
