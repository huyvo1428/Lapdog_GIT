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
AP.Iph0     = NaN;
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
AP.Vz       = nan(1,2); %zero-crossing estimate
AP.Vz(2)=0.5;
AP.VzP= nan(1,2); 

       
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




    ip_no_nans=ip+(1:length(ip))*1e-22; %extremely small values of noise, sometimes needed for extrapolation.
    vb_no_nans=vb;
    vb_no_nans(isnan(ip))=[];
    ip_no_nans(isnan(ip))=[];%remove nans.


    lastneg = max(find(ip_no_nans<0));
    firstpos = min(find(ip_no_nans>0));
% Look for zero crossing interval:
if((min(ip) >= 0) || (max(ip) <= 0)) % NB:There is a "return" command in here
    % No zero crossing in this case. But maybe we can extrapolate a
    % potential anyway.
%     lastneg = NaN;
%     firstpos = NaN;

    AP.Vz(2)=0.2; %INTERPOLATION OUTSIDE SWEEP

    maxneg_bool= (max(ip) <= 0);
    %minpos_bool= (min(ip) >= 0);
    
    
    if(maxneg_bool)
    %if maximum current is negative
    
    
    ind_vz = length(ip_no_nans)-3:length(ip_no_nans); % 4 points
    %ind_vz(isnan(ip(ind_vz)))=[]; %remove nans
    
    P=polyfit(ip_no_nans(ind_vz),vb_no_nans(ind_vz),1);
    AP.Vz(1)=polyval(P,0);
    
    if (AP.Vz(1))<0;       AP.Vz(1)=nan;end %Only a horrible fit would reveal something like this.
    
  %  AP.Vz(1)=interp1(ip_no_nans(ind_vz),vb_no_nans(ind_vz),0,'linear','extrap');

    else % I don't think this is actually necessary. V_S/C will never be >+30V, surely.
        

    ind_vz = 1:4; % 4 points
    %ind_vz(isnan(ip(ind_vz)))=[]; %remove nans
    P=polyfit(ip_no_nans(ind_vz),vb_no_nans(ind_vz),1);
    AP.Vz(1)=polyval(P,0);
    
    %AP.Vz(1)=interp1(ip_no_nans(ind_vz),vb_no_nans(ind_vz),0,'linear','extrap');

    
    end
    

    AP.VzP=P;


    %%%%%%%%%%%%%%
    return; % Don't work any further on these horrible sweeps.
    %%%%%%%%%%%%%%
    
    
    
    
    
else
    %lastneg = max(find(ip<0));
    %firstpos = min(find(ip>0));
    

    
    if lastneg>firstpos
        %then there are multiple zero crossings, extrapolation is more
        %risky
        AP.Vz(2)=0.4; %maybe let this be a function of the Vb distance between lastneg/firstpos
        
        
        eps=2;
        if eps > length(ip_no_nans)-sum(ip_no_nans>0)||  length(ip_no_nans)-eps > sum(ip_no_nans>0)-length(ip_no_nans)
            %if almost no positive currents, or almost all negative
            %currents, then many or both of these crossings can be due to
            %LDL interference
            'this is bad'; 
            
            
        end
        
%         iz_pos= 0<ip_no_nans;
%         iz_neg= 0>ip_no_nans;
        
        %if the value after the first positive is negative, then maybe this
%         %is a false (LDL) positive value
%         tempip_no_nans=ip_no_nans;
%         while tempip_no_nans(firstpos+1)<0 
%             tempip_no_nans(firstpos) = ip_no_nans(firstpos)*-1;%flip sign
%             
%             
%             firstpos = min(find(tempip_no_nans>0));
%         end
%         
%          
%         %if the value before the last negative is positive, then maybe this
%         %is a false (LDL) negative value       
%         
%         while tempip_no_nans(lastneg-1)>0 %iterates 
%             tempip_no_nans(lastneg) = ip_no_nans(lastneg)*-1;%flip sign
%                         
%             lastneg = max(find(tempip_no_nans<0));
%         end
%         
        
        [firstpos,lastneg]=findbestzerocross(ip_no_nans);
    else
        AP.Vz(2)=0.8; %good fit might not be perfect anyway.
    end
    
%     if length(ip)>lastneg && ~isnan(ip(lastneg+1))

%         ind_vz=[lastneg;lastneg+1];
%         P=polyfit(ip(ind_vz),vb(ind_vz),1);
%         AP.Vz=interp1(ip(ind_vz),vb(ind_vz),0);
%                 interp1(
%         %AP.Vz=polyval(P,0);
%                 
%     else


    ind_vz=min([max([lastneg-3;1]),firstpos]):max([min([lastneg+3;length(ip_no_nans)])],firstpos);%stay within limits, but use firstpositive location also. It might be before or after lastneg, depending on the noise
    %ind_vz=max([lastneg-3;1]):min([lastneg+3;length(ip)]);%stay within limits
    %ind_vz(isnan(ip(ind_vz)))=[]; %remove nans
    
    %remove identical current values (interp1 complains otherwise)
    %alternative one, add silly noise 
    %ip2=ip+(1:length(ip))*1e-22; %extremely small values.
    %ip+wgn(1,length(ip),1)*1e-20) white noise generator is random, so
    %uniqueness might be a problem.
    %alternative two, remove all but one of the non-unique values:
    %[~, I] = unique(ip(ind_vz), 'first');
    %delind = 1:length(A);
    %ind_vz(delind(I)) = [];
    
    
   % AP.Vz(1)=interp1(ip_no_nans(ind_vz),vb_no_nans(ind_vz),0,'linear','extrap');
    P=polyfit(ip_no_nans(ind_vz),vb_no_nans(ind_vz),1);
    AP.Vz(1)=polyval(P,0);
    AP.VzP=P;
   
    
%        P=polyfit(ip(ind_vz),vb(ind_vz),1);
%        AP.Vz=polyval(P,0);
    if diag
        figure(358);plot(vb,ip,'.',vb_no_nans(ind_vz),ip_no_nans(ind_vz),'o')
        vline(AP.Vz(1),'black-','AP.Vz')
    end
    
end
%if(isnan(lastneg) || isnan(firstpos))
%    par = 2;
%end

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
% if(abs(vx) > 25)
%     par = 4;
%     return;
% end

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


function [highestrankpos,highestrankneg]=findbestzerocross(ip_no_nans)

%Function takes a sorted (increasing Vb) array of currents with multiple
%zerocrossings, finds the crossing with the furthest distance to a current
%flip (i.e. distance to nearest positive & negative pair.)
%Proposal:actually, all positive currents followed by a negative currents are
%bullshit. Either low signal-to-noise ratio or disturbance.

        iz_pos= 0<ip_no_nans;
%         iz_neg= 0>ip_no_nans;

        
        %all indices where the current flips positive;
        flipupindz= find(diff(iz_pos)==1);
        %all indices where the current flips negative;
        flipdownindz= find(diff(iz_pos)==-1);
        %matrix of distances between these indices:
        matrixflipdistances=flipupindz.'-flipdownindz;

        %max(min(abs(matrixflipdistances),[],2))) finds the column (flipupindz) where the
        %distance to the nearest flipdownindz is farthest away
        [maxdistance,highrankind] = max(min(abs(matrixflipdistances),[],2));

        highestrankpos= flipupindz(highrankind)+1; %fix the diff 
        highestrankneg= flipupindz(highrankind);
        
%         if maxdistance<3 %well, we're a bit unfortunate, with long LDL disturbance exactly around where we cross I=0.
%             
%             highestrankneg = max(find(ip_no_nans<0));
%             highestrankpos = min(find(ip_no_nans>0));
%             
%         end
        
 

end
