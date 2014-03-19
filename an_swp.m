function params = an_swp(vb,ip,t,probenr)
% an_swp.m -- analyze sweep data

% Analyze sweep
% Input:
%   ts = sweep sample times
%   p = probe number (not yet used)
%   vb = bias [V], should be monotonic
%   ip = probe current [A]
% Output:
% params = [t len vb(lastneg) vb(firstpos) vx poli(1) poli(2) pole(1) pole(2) p vbinf diinf d2iinf Tph If0 vs];
% Output if unsuccesful:
%   par = zeros(1,16): vb or ip not a vector
%   par = ones(1,16): vp or ip different length
p =str2num(probenr);
% Set default output:
params = [NaN NaN NaN NaN NaN NaN NaN NaN NaN p NaN NaN NaN NaN NaN NaN];

diag = 1;  % Set to one if diagnostic
if(diag)
  figure(159);
end

% Constants:

ok = 1;

% vb and ip should be equally long row vectors:
[rv,cv] = size(vb);
[ri,ci] = size(ip);
if(rv > cv) 
	vb = vb'; 
end
if(ri > ci) 
	ip = ip'; 
end
if((min(ri,ci) ~=1) | (min(rv,cv) ~= 1))
   par = zeros(1,16);
   return;
end
if(max(ri,ci) ~= max(rv,cv))
   par = ones(1,16);
   return;
end
len = length(vb);

%t = mean(ts);% time

% Sort on bias to get upward sweep:
[vb,ind] = sort(vb);
ip = ip(ind);



% Look for zero crossing interval:
if((min(ip) >= 0) || (max(ip) <= 0))
    % No zero crossing in this case
	lastneg = NaN;
	firstpos = NaN;
else
	lastneg = max(find(ip<0));
	firstpos = min(find(ip>0));
end
if(isnan(lastneg) || isnan(firstpos))
	par = 2;
	return;
end

% Analyze derivatives:
% Find inflexion point (maximum in d2I/dV2), calculate derivatives there:
ind = find(diff(vb) ~= 0);
vb2 = vb(ind);
di = gradient(ip(ind),vb2);
d2i = gradient(di,vb2);
ind2 = max(find(d2i == max(d2i)));
vbinf = vb2(ind2);
diinf = di(ind2);
d2iinf = d2i(ind2);

% Use part of interval below/above vbinf some first 
% and last samples for linear ion/electron limits.
lolim = max(floor(0.8*ind(ind2)),8);
hilim = min(ceil(0.6*ind(ind2) + 0.4*len),len-8);
indi = 1:lolim;
inde = hilim:len;
echeck = find(ip(inde) > 0);
if(sum(size(inde)) == 0)
	par = 3;
	return;
end
poli = polyfit(vb(indi),ip(indi),1);
pole = polyfit(vb(inde),ip(inde),1);

% Get vx = vsat + Te from zero crossing of e- fit:
vx = -pole(2)/pole(1);
if(abs(vx) > 25)
	par = 4;
	return;
end

Tph = NaN;
If0 = NaN;
vs = NaN;

% Do fit for sunlit probe if:
% (a) offset value in linear fit is < -5 nA, and
% (b) slope in linear ion fit is < 1e-9 mho (1 Gohm)

if((poli(2) < -5e-9) & (poli(1) < 1e-9));

  % Use curve above vinf:
  pos = find(vb >= vbinf);

  % Subtract collected electrons, whose current is put to zero if
  % linear fit gives negative value:
  iecoll = polyval(pole,vb(pos));
  iecoll = (iecoll + abs(iecoll))/2;
  iph = ip(pos) - iecoll;
  vbh = vb(pos);
  if(diag)
    subplot(2,2,1)
    plot(vb,1e9*ip);
    xlabel('Vb [V]');
    ylabel('Ip [nA]');
    titstr = sprintf('P%.0f %sT%s',p,datestr(t,29),datestr(t,13));% time
    title(titstr); %time
    grid on;
    subplot(2,2,2)
    plot(vbh-vbinf,iph)
    xlabel('Vp [V]');
    ylabel('I-Ie [nA]');
    title('Photoemission');
    grid on;
    subplot(2,2,3)
    plot(vbh-vbinf,log10(abs(iph)))
    xlabel('Vp [V]');
    ylabel('lg(I-Ie) [A]');
    title('Log photoemission');
    grid on;
    subplot(2,2,4)
    
  end

  % Do log fit to first 4 V:
  phind = find(vbh < vbinf + 4);
  phpol = polyfit(vbh(phind),log(abs(iph(phind))),1);
  Tph = -1/phpol(1);
  Iftmp = -exp(phpol(2));
  
  % Find Vsc as intersection of ion and photoemission current:
  % Iterative solution:
  vs = -vbinf;
  for(i=1:10)
    vs = -(log(-polyval(poli,-vs)) - phpol(2))/phpol(1);
    if(diag)
      vs
    end
  end
  % Calculate If0:
  If0 = Iftmp * exp(vs/Tph);
  if(diag)
     If0
     Iftmp
     vs
     vbinf
  end
else  % End of sunlit case, start no photoemission case:

  % Assume we can forget the photoemission.
  % Remove ions below vinf:
  neg = find(vb <= vbinf);

  % Subtract collected ions, whose current is put to zero if
  % linear fit gives positive value:
  iicoll = polyval(poli,vb(neg));
  iicoll = (iicoll - abs(iicoll))/2;
  ie = ip(neg) - iicoll;
  vbi = vb(neg);
  if(diag)
    subplot(2,2,1)
    plot(vb,1e9*ip);
    xlabel('Vb [V]');
    ylabel('Ip [nA]');
    grid on;
    titstr = sprintf('P%.0f %sT%s',p,datestr(t,29),datestr(t,13)); %time
    title(titstr); %time
    subplot(2,2,2)
    plot(vbi,1e9*ie);
    xlabel('Vb [V]');
    ylabel('I-Ii [nA]');
    grid on;
    title('Eclipse model');
    subplot(2,2,3)
    plot(vbi-vbinf,log10(abs(ie)))
    xlabel('Vp [V]');
    ylabel('lg(I-Ii) [A]');
    grid on;
    subplot(2,2,4)
  end
end   % Case of no photoemission


% Collect parameters:
params = [t len vb(lastneg) vb(firstpos) vx poli(1) poli(2) pole(1) pole(2) p vbinf diinf d2iinf Tph If0 vs];
