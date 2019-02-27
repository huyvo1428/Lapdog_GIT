function [out] = efl_x10(input)
% efl_x10 -- function to be used for generating LF and MF E-field from macro
% 710 and 910. These macros are special in that the VxL sampling frequency
% varies between a slow (L, 57.8/256 S/s) and a fast (M, 57.8/4 S/s)
% sampling. The function therefore separates these into separate [tl,efl]
% and [tm,efm] pairs. These can then be saved to separate files.
%
%  The E-field is defined as positive when pointing from P2 to P1 and
%  is returned in mV/m.
%
%   Input and output times are in Matlab units (days).
%
%   The input vectors MUST ONLY contain data from when both probes are 
%   SUNLIT! 
%
%   Rosetta LAP team/aie140214
%   Changed for new centering of time stamps on MA centre/aie190227

%
% As there may be data gaps, the safest way to identify L and M is to
% use the timing. From the time t0 of the first sample in a macro
% cycle, we should have the following:
% t0 <= t < t0+96s: L interval (3 AQPs with Efloat on both probes); last 
% sample at 90.57s.
% t0+96s <= t < t0+128s: M interval (1 AQP with Efloat on both probes); 
% last sample at 104.2s.
% Then follows a data gap before next cycle start. The macro cycle 
% length is 160 and 192 s, respectively.
%
% anders.eriksson@irfu.se 2019-02-14

%Rewrote this function to give more outputs and to take a less messy
%input. A bit obfusciated, but less messy, I hope. FKJN 2019-02-19
t1l=input.t1l;
v1l=input.v1l;
t2l=input.t2l;
v2l=input.v2l;
%             input=[];
%             input.v1l=v1l;
%             input.v2l=v2l;
%             input.t1l=scantemp{1,2};
%             input.t2l=scantemp2{1,2};
%             input.t1utc=scantemp{1,1};
%             input.t2utc=scantemp{1,1};
%prepare output:
out=[];
out.ef_out=[]; %the output field
out.t_obt=[];  % the output time in OBT
out.t_utc={};  % the output time in UTC


% For macro 710, there are more floating potential data for P1 than P2 
% (P2 is in Vbias mode during one AQP). For 910 the opposite is true. 
% So we can find out what the macro we have and treat data accordingly:


l1 = length(v1l);
l2 = length(v2l);
if(l1 > l2) % Macro 0x710
     tb = t2l; % Will become the common timeline
     out.t_utc=input.t2utc;
     indb = 1:l1;
     ind = interp1(t1l,indb,tb,'nearest');
     % v1l(ind) will now be simultaneous with v2l
     eraw = 1000*(v2l-v1l(ind))/5;  % Raw E-field in mV/m
     cycle = 6; % 6 AQPs in each macro 0x710 cycle
     out.qfraw=[input.qf1(ind) input.qf2];
else        % Macro 0x910
     tb = t1l; % Will become the common timeline
     out.t_utc=input.t1utc;
     indb = 1:l2;
     ind = interp1(t2l,indb,tb,'nearest');
     % v2l(ind) will now be simultaneous with v1l
     eraw = 1000*(v2l(ind)-v1l)/5;  % Raw E-field in mV/m
     cycle = 5; % 5 AQPs in each macro 0x910 cycle
     out.qfraw=[input.qf1 input.qf2(ind)];
     
end
% Note that the case l1 == l2 is also OK: it just means the macro block
% is so short that none of the probes ever goes into Vbias mode; can
% happen e.g. if the macro is started just before midnight, and then
% v1l and v2l are equal.

% We can now separate the L and M data as follows:
t0 = min(tb);
naqps = ceil((max(tb) - t0)*1.00/32); % Number of AQPs in block
gap = min(find(diff(tb) > 32/1.00)); % Find a long gap, after which
% we know L sampling follows. The start of that L segment is defined as
% the "reference AQP", where a macro cycle starts.
t_refaqp = tb(gap+1); % Time of first sample in ref AQP
t_refaqp = t_refaqp - 4/1.00; % To adjust for new centering of timestamps
% datestr(t_refaqp,'HH:MM:SS.FFF')
mfind = find(tb > t_refaqp-32*(cycle-3)/1.00 & tb < t_refaqp);
lfind = find(tb < t_refaqp-32*(cycle-3)/1.00);
aqp = 0;
% 4 sec necessary since we centred time stamps on MA centre!
if(find(tb < t_refaqp - (cycle*32+0.003)/1.00))
    error('This should not happen! More than full cycle before ref AQP.');
end

efl = eraw(lfind)-mean(eraw(lfind)); % DC level removed from all L data
         %before ref AQP
if(lfind)
     % If there are L data before the M data, we adjust the DC level of the
     % M data to those L data to make them consistent
     efm = eraw(mfind)-mean(eraw(lfind));
else
     % If there are no L data before the M data, we remove their own DC
     % level
     efm = eraw(mfind)-mean(eraw(mfind)); % All M data before ref AQP
end
tl = tb(lfind);
tm = tb(mfind);
%fp = fopen('ee_x10_log.txt','w');
%ltl = length(tl); lef = length(efl); fprintf(fp,'AQP %.0f,  %.0f times, %.0f E-fields\n',aqp,length(tl),length(efl));

save_ind=false(1,length(indb));
save_ind(lfind)=true;

naqp = ceil((max(tb)-t_refaqp)*1.00/32);  % # of AQPs from the ref, the
         % last one perhaps truncated       
caqp = 1;

for(aqp = 1:naqp)  % Loop over all AQPs from ref AQP to end of block
    ind = find(tb > t_refaqp+(aqp-1)*32/1.00 & tb < t_refaqp+aqp*32/1.00);
    if(ind) % Only do something if the AQP is non-empty
        save_ind(ind)=true;
        
        if(caqp == 1)  % First L data AQP
            %if(mod(aqp,cycle) == 1)  % First L data AQP
            eflraw = eraw(ind);
            tl = [tl; tb(ind)];
            
            if(aqp == naqp)
                efl = [efl; eflraw-mean(eflraw)];
            end
            %ltl = length(tl); lef = length(efl); fprintf(fp,'AQP1 %.0f,  %.0f times, %.0f E-fields\n',aqp,length(tl),length(efl));
            caqp = 2;
            %[aqp length(tl) length(efl)]
        elseif(caqp == 2) % 2nd L data AQP
            eflraw = [eflraw; eraw(ind)];
            tl = [tl; tb(ind)];
            if(aqp == naqp)
                efl = [efl; eflraw-mean(eflraw)];
            end
            %ltl = length(tl); lef = length(efl); fprintf(fp,'AQP2 %.0f,  %.0f times, %.0f E-fields\n',aqp,length(tl),length(efl));
            caqp = 3;
            %[aqp length(tl) length(efl)]
        elseif(caqp == 3) % 3rd L data AQP
            eflraw = [eflraw; eraw(ind)];
            efl = [efl; eflraw-mean(eflraw)];
            tl = [tl; tb(ind)];
            %ltl = length(tl); lef = length(efl); fprintf(fp,'AQP3 %.0f,  %.0f times, %.0f E-fields\n',aqp,ltl,lef);
            caqp = 4;
            %[aqp length(tl) length(efl)]
        else  % M data
            efm = [efm; eraw(ind)-mean(eflraw)];
            % We adjust the DC level of the M data to
            % the DC level of the L preceding L data.
            tm = [tm; tb(ind)];
            %fprintf(fp,'AQPM %.0f,  M data\n',aqp);
            caqp = 1;
        end
    %else % Empty AQP
        % fprintf(fp,'AQP %.0f is not E-field\n',aqp);
    end
end % End of loop over AQPs
%fclose(fp);



out.t_obt=[tl;tm];%vertcat should work
out.ef_out = [efl;efm];%vertcat should work
[junk,ascind]=sort(out.t_obt,'ascend');
out.ef_out=out.ef_out(ascind);
out.t_obt=out.t_obt(ascind);
out.freq_flag=9*ones(length(out.t_obt),1);
out.freq_flag(ismemberf(out.t_obt,tm))=3; %see mail" kombinationer MA_LENGTH & DOWNSAMPLE 18/2 2019"
end

% That's all, folks!