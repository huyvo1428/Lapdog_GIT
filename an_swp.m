function AP = an_swp(vb,ip,ts,probenr,illuminati)
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

AP = [];

%cspice_et2utc(ts,'ISOC',6)

probenr =str2double(probenr);
% Set default output:

% initialise and clear output struct
AP.ts       = NaN;
AP.vx       = NaN;
AP.Tph      = NaN;
AP.Iph0      = NaN;
AP.vs       = NaN;
AP.lastneg  = NaN;
AP.firstpos = NaN;
AP.poli1    = NaN;
AP.poli2    = NaN;
AP.pole1    = NaN;
AP.pole2    = NaN;
AP.probe    = NaN;
AP.vbinf    = NaN;
AP.diinf    = NaN;
AP.d2iinf   = NaN;
       
diag = 0;  % Set to one if diagnostic
if(diag)
    figure(159);
end


% Constants:
% vb and ip should be equally long row vectors:
[rv,cv] = size(vb);
[ri,ci] = size(ip);
if(rv > cv)
    vb = vb';
end
if(ri > ci)
    ip = ip';
end
if((min(ri,ci) ~=1) || (min(rv,cv) ~= 1))
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


%edit  26/6 2014 FJ sometimes there's kinks in the plot, e.g 
%2007-11-13T20:23:39 . let's smooth the currents before calculating
%something drastic like d2i.
%cspice_et2utc(ts,'ISOC',6)

% if ts > 2.482574842192299e+08 -1
% 
%     'hello'
% end
Iarray = smooth(ip,0.14,'sgolay'); %rloess is really slow
%Iarray = smooth(ip,0.14,'rloess'); %gentle moving average (4% steps) needed for error prone statistics like 2nd deriv


%ind = find(diff(vb) ~= 0); %useless now
%vb = vb(ind);
di = gradient(Iarray,vb);
d2i = gradient(di,vb);

%indMin= find(d2i==min(d2i),1); %absolute minimum is always right after the peak we want, (or later, in case of noise on e?side 
%indmin= min(find(d2i == min(d2i));
indMax = max(find(d2i == max(d2i),1));
vbinf = vb(indMax);
diinf = di(indMax);
d2iinf = d2i(indMax);

% Use part of interval below/above vbinf some first
% and last samples for linear ion/electron limits.
lolim = max(floor(0.8*indMax),8);
hilim = min(ceil(0.6*indMax + 0.4*len),len-8);
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


if (illuminati>0) %can be 1, 0.4(maybe sunlit) or 0
    
    if((poli(2) < -5e-9) && (poli(1) < 2e-9));
%         if (poli(1) < 1e-9)
%             illuminati
%             'hello'
%         end
        
        
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
            titstr = sprintf('P%.0f %s',probenr,cspice_et2utc(ts,'ISOC',6));% time
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
            plot(vb(1:pos),ip(1:pos),'r',vb(pos:end),ip(pos:end),'g',vb,d2i,'b')
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
              %  vs
            end
        end
        % Calculate If0:
        If0 = Iftmp * exp(vs/Tph);
        if(diag)
%             If0
%             Iftmp
%             vs
%             vbinf
        end
        
    else
%        'hello'
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
        titstr = sprintf('P%.0f %sT%s',probenr,datestr(ts,29),datestr(ts,13)); %time
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


AP.ts       = ts;
AP.vx       = vx;
AP.Tph      =Tph;
AP.Iph0      =If0;
AP.vs       =vs;
AP.lastneg  = vb(lastneg);
AP.firstpos = vb(firstpos);
AP.poli1    = poli(1);
AP.poli2    = poli(2);
AP.pole1    = pole(1);
AP.pole2    = pole(2);
AP.probe    =probenr;
AP.vbinf    =vbinf;
AP.diinf    =diinf;
AP.d2iinf   =d2iinf;



% 
% params = [ts vb(lastneg) vb(firstpos) vx poli(1) poli(2) pole(1) pole(2) probenr vbinf diinf d2iinf Tph If0 vs];

%p_out= num2cell(params);
% ind = isnan(params);
% p_out(1,ind)={'N/A'};


end






