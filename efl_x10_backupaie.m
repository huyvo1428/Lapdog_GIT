function [tl,efl,tm,efm] = efl_x10(t1l,v1l,t2l,v2l)
% efl_x10 -- function to be used for generating LF and MF E-field from macro
% 710 and 910. These macros are special in that the VxL sampling frequency
% varies between a slow (L, 57.8/256 S/s) and a fast (M, 57.8/4 S/s)
% sampling. The function therefore separates these into separate [tl,efl]
% and [tm,efm] pairs. These can then be saved to separate files.
%
% The input vectors MUST contain data ONLY from when both probes are
% SUNLIT!
%
% As there may be data gaps, the safest way to identify L and M is to
% just use the timing. From the time t0 of the first sample in a macro
% cycle, we should have the following:
% t0 <= t < t0+96s: L interval (3 AQPs with Efloat on both probes); in
% practice t0+91s is enough (last sample at 90.57s)
% t0+96s <= t < t0+128s: M interval (1 AQP with Efloat on both probes); in
% practice t0+105 s is enough (last sample at 104.2s)
% Then follows a data gap of about 1.5 AQPs for 910, 2.5 AQPs for 710
% before next cycle start. The macro cycle length is 160 and 192 s,
% respectively.
%
% anders.eriksson@irfu.se 2019-02-14

% For macro 710, there are more floating potential data for P1 than P2
% (P2 is in Vbias mode during one AQP). For 910 the opposite is true.
% We can find which is which without knowing the macro:
l1 = length(v1l);
l2 = length(v2l);
if(l1 > l2) % Macro 0x710
     tb = t2l; % Will become the common timeline
     ind1 = 1:l1;
     ind = interp1(t1l,ind1,t2l,'nearest');
     % v1l(ind) will now be simultaneous with v2l
     eraw = 1000*(v2l-v1l(ind))/5;  % Raw E in mV/m
     cycle = 6; % 6 AQPs in each macro 0x710 cycle
else        % Macro 0x910
     tb = t1l; % Will become the common timeline
     ind1 = 1:l2;
     ind = interp1(t2l,ind1,t1l,'nearest');
     % v2l(ind) will now be simultaneous with v1l
     eraw = 1000*(v2l(ind)-v1l)/5;  % Raw E in mV/m
     cycle = 5; % 5 AQPs in each macro 0x910 cycle
end
% Note that the case l1 == l2 is also OK: it just means the macro block
% is so short that none of the probes ever goes into Vbias mode; can
% happen e.g. if the macro is started just before midnight, and then
% v1l and v2l are equal.

% We can now separate the L and M data as follows:
t0 = min(tb);
naqps = ceil((max(tb) - t0)*86400/32); % Number of AQPs in block
gap = min(find(diff(tb) > 32/86400)); % Find a long gap, after which
% we know L sampling follows. The start of that L segment is defined as
% the "reference AQP", where a macro cycle starts.
t_refaqp = tb(gap+1); % Time of first sample in ref AQP
t1 = (t_refaqp-t0)*86400;
mfind = find(tb > t_refaqp-96.003/86400 & tb < t_refaqp);
lfind = find(tb < t_refaqp-96/86400);
% We have used 3 ms tolerances for possible matlab roundoff errors
if(find(tb < t_refaqp - 192.003/86400))
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
naqp = ceil((max(tb)-t_refaqp)*86400/32);  % # of AQPs from the ref, the
         % last one perhaps truncated
for(aqp = 1:naqp)  % Loop over all AQPs from ref AQP to end of block
     ind = find(tb > t_refaqp+(aqp-1)*32/86400-0.002/86400 & tb < 
t_refaqp+aqp*32/86400-0.002/86400);
     if(ind) % Only do something if the AQP is non-empty
         if(mod(aqp,cycle) == 1)  % First L data AQP
             eflraw = eraw(ind);
             if(aqp == naqp)
                 efl = [efl; eflraw-mean(eflraw)];
             end
             tl = [tl; tb(ind)];
         elseif(mod(aqp,cycle) == 2) % 2nd L data AQP
             eflraw = [eflraw; eraw(ind)];
             if(aqp == naqp)
                 efl = [efl; eflraw-mean(eflraw)];
             end
             tl = [tl; tb(ind)];
         elseif(mod(aqp,cycle) == 3) % 3rd L data AQP
             eflraw = [eflraw; eraw(ind)];
             efl = [efl; eflraw-mean(eflraw)];
             tl = [tl; tb(ind)];
         else  % M data
             efm = [efm; eraw(ind)-mean(eflraw)];
             % We adjust the DC level of the M data to
             % the DC level of the L preceding L data.
             tm = [tm; tb(ind)];
         end
     end
end
% That's all, folks!