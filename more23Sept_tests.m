%this file was implemented to test problems with macro 410, 710,etc. In the
%end we found that the culprit was 4/8khz filter offset calibration that
%was not taken into account in old data.



assks= lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D23/RPCLAP_20160923_142804_926_I1S.TAB');
assksb= lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D23/RPCLAP_20160923_142804_926_B1S.TAB');
%LAP2_416= [];
LAP1_926.I =assks.sweeps;
LAP1_926.t_utc = assks.START_TIME_UTC;
LAP1_926.V = assksb.bias_potentials;
len3 = length(LAP1_926.t_utc);
for i=1:len3
    LAP1_926.t_epoch(i) = irf_time(LAP1_926.t_utc{i}(1:26),'utc>epoch');    
end

assks= lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D23/RPCLAP_20160923_142804_926_I2S.TAB');
assksb= lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D23/RPCLAP_20160923_142804_926_B2S.TAB');
%LAP2_416= [];
LAP2_926.I =assks.sweeps;
LAP2_926.t_utc = assks.START_TIME_UTC;
LAP2_926.V = assksb.bias_potentials;
len3 = length(LAP2_926.t_utc);
for i=1:len3
    LAP2_926.t_epoch(i) = irf_time(LAP2_926.t_utc{i}(1:26),'utc>epoch');    
end

Avg_926 = [];
Avg_926.I = mean(LAP2_926.I,1);
Avg_926.Isd = std(LAP2_926.I);
Avg_926.V =LAP2_926.V;

% 
% 
% Avg_926 = [];
% Avg_926.I = mean(temp2.sweeps,2);
% Avg_926.Isd = std(temp2.sweeps.').';
% Avg_926.V =V_P2;

%RPCLAP_20160923_142804_926_I1S.TAB


Avg_710 = [];
Avg_710.I = mean(LAP2Sweeps.I(ind2+59:end,:),1);
Avg_710.Isd = std(LAP2Sweeps.I(ind2+59:end,:));

Avg_710.V = LAP2Sweeps.V;


Avg_710s = [];
Avg_710s.I = mean(LAP2Sweeps.I(ind1+15:ind2+10,:),1);
Avg_710s.V = LAP2Sweeps.V;
Avg_710s.Isd = std(LAP2Sweeps.I(ind1+15:ind2+10,:));



assks= lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D23/RPCLAP_20160923_145204_412_I2S.TAB');
assksb=lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D23/RPCLAP_20160923_145204_412_B2S.TAB');
LAP2_410= [];
LAP2_410.I =assks.sweeps;
LAP2_410.t_utc = assks.START_TIME_UTC;
LAP2_410.V = assksb.bias_potentials;
len2 = length(LAP2_416.t_utc);

% LAP2_410= [];
% LAP2_410.I =RPCLAP20160923145204412I2S;
% LAP2_410.t_utc = VarName3;
% LAP2_410.V = VarName4;
%len2 = length(VarName3);
for i=1:len2
    LAP2_410.t_epoch(i) = irf_time(LAP2_410.t_utc{i}(1:26),'utc>epoch');    
end

Avg_410 = [];
Avg_410.I = mean(LAP2_410.I(1:50,:),1);
Avg_410.V = LAP2_410.V;
Avg_410.Isd = std(LAP2_410.I(1:50,:));


assks= lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D24/RPCLAP_20160924_010212_416_I2S.TAB');
assksb=lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D24/RPCLAP_20160924_010212_416_B2S.TAB');
%LAP2_416= [];
LAP2_416.I =assks.sweeps;
LAP2_416.t_utc = assks.START_TIME_UTC;
LAP2_416.V = assksb.bias_potentials;
len3 = length(LAP2_416.t_utc);
for i=1:len3
    LAP2_416.t_epoch(i) = irf_time(LAP2_416.t_utc{i}(1:26),'utc>epoch');    
end

Avg_416 = [];
Avg_416.I = mean(LAP2_416.I,1);
Avg_416.V = LAP2_416.V;
Avg_416.Isd = std(LAP2_416.I);



assks= lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D24/RPCLAP_20160924_000000_412_I2S.TAB');
%assksb=lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D24/RPCLAP_20160924_010212_416_B2S.TAB');
%LAP2_410.I24Sept =RPCLAP20160924000000412I2S; %is this not macro 412?

LAP2_410.I24Sept =assks.sweeps;
LAP2_410.t_utc24Sept = assks.START_TIME_UTC;
%LAP2_410.V = VarName4; %why?
len4 = length(LAP2_410.t_utc24Sept);

for i=1:len4
    LAP2_410.t_epoch24Sept(i) = irf_time(LAP2_410.t_utc24Sept{i}(1:26),'utc>epoch');    
end
Avg_410.I24Sept = mean(LAP2_410.I24Sept,1);
Avg_410.Isd24Sept = std(LAP2_410.I24Sept);


figure(17)
plot(Avg_926.V,Avg_926.I,'o',Avg_710.V,Avg_710.I,'o',Avg_710s.V,Avg_710s.I,'o',Avg_410.V,Avg_410.I,'o')
ax=gca;
ax.Title.String = 'LAP2 Sweeps binned average on each potential step 23 Sept2016';
ax.YLabel.String = 'Sweep Current (A)';
ax.XLabel.String = 'Vbias (V)';
axL=legend('926 (7 sweeps)','710 shadow (135 sweeps)','710 sunlit (22 sweeps)','410 (510 sweeps)');
axL.Location='northwest';
grid on;



figure(19)
plot(Avg_926.V,Avg_926.I+8E-9,'o',Avg_710.V,Avg_710.I,'o',Avg_710s.V,Avg_710s.I,'o',Avg_410.V,Avg_410.I,'o',Avg_926.V,Avg_926.I+Avg_926.Isd+8E-9,'b:',Avg_926.V,Avg_926.I-Avg_926.Isd+8E-9,'b:',Avg_710.V,Avg_710.I+Avg_710.Isd,'r:',Avg_710.V,Avg_710.I-Avg_710.Isd,'r:',Avg_410.V,Avg_410.I+Avg_410.Isd,'black:',Avg_410.V,Avg_410.I-Avg_410.Isd,'black:')
ax=gca;
ax.Title.String = 'LAP2 Sweeps binned average on each potential step 23 Sept2016';
ax.YLabel.String = 'Sweep Current (A)';
ax.XLabel.String = 'Vbias';
axL=legend('926 (7 sweeps) + 8 nA','710 shadow (135 sweeps)','710 sunlit (22 sweeps)','410 (510 sweeps)',' +-1 sigma (standard deviation)');
axL.Location='northwest';
grid on;


of_s=8E-9;
of_s=0;
figure(20)
plot(Avg_926.V,Avg_926.I+of_s,'o',Avg_710.V,Avg_710.I,'o',Avg_710s.V,Avg_710s.I,'o',Avg_410.V,Avg_410.I,'o',Avg_416.V,Avg_416.I,'o',Avg_926.V,Avg_926.I+Avg_926.Isd+of_s,'b:',Avg_926.V,Avg_926.I-Avg_926.Isd+of_s,'b:',Avg_710.V,Avg_710.I+Avg_710.Isd,'r:',Avg_710.V,Avg_710.I-Avg_710.Isd,'r:',Avg_410.V,Avg_410.I+Avg_410.Isd,'black:',Avg_410.V,Avg_410.I-Avg_410.Isd,'black:')
ax=gca;
ax.Title.String = 'LAP2 Sweeps binned average on each potential step 23 Sept2016';
ax.YLabel.String = 'Sweep Current (A)';
ax.XLabel.String = 'Vbias';
axL=legend('926 (7 sweeps)','710 shadow (last 50 sweeps)','710 sunlit (22 sweeps)','410 (first 50 sweeps)','416 24Sept2016 (20sweeps)',' +-1 sigma (standard deviation)');
axL.Location='northwest';
grid on;



figure(21)
plot(Avg_926.V,Avg_926.I+of_s,'o',Avg_410.V,Avg_410.I,'o',Avg_410.V,Avg_410.I24Sept,'o',Avg_416.V,Avg_416.I,'o',Avg_926.V,Avg_926.I+Avg_926.Isd+of_s,'b:',Avg_926.V,Avg_926.I-Avg_926.Isd+of_s,'b:',Avg_410.V,Avg_410.I+Avg_410.Isd,'r:',Avg_410.V,Avg_410.I-Avg_410.Isd,'r:',Avg_410.V,Avg_410.I24Sept+Avg_410.Isd24Sept,'y:',Avg_410.V,Avg_410.I24Sept-Avg_410.Isd24Sept,'y:',Avg_416.V,Avg_416.I+Avg_416.Isd,'black:',Avg_416.V,Avg_416.I-Avg_416.Isd,'black:')
ax=gca;
ax.Title.String = 'LAP2 Sweeps binned average on each potential step 23 Sept2016';
ax.YLabel.String = 'Sweep Current (A)';
ax.XLabel.String = 'Vbias';
axL=legend('926 (7 sweeps) ','410 23 Sept','410 24 Sept','416 24 Sept',' +-1 sigma (standard deviation)');
axL.Location='northwest';
grid on;




assks= lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D15/RPCLAP_20160915_200404_612_I2S.TAB');
assksb=lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D15/RPCLAP_20160915_200404_612_B2S.TAB');
LAP2_612= [];
LAP2_612.I =assks.sweeps;
LAP2_612.t_utc = assks.START_TIME_UTC;
LAP2_612.V = assksb.bias_potentials;
len2 = length(LAP2_612.t_utc);


%LAP2_612.I =RPCLAP20160915200404612I2S;
%LAP2_612.t_utc = VarName9;
%LAP2_612.V = VarName10;
%len2 = length(VarName9);
for i=1:len2
    LAP2_612.t_epoch(i) = irf_time(LAP2_612.t_utc{i}(1:26),'utc>epoch');    
end


assks= lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D15/RPCLAP_20160915_200404_612_I1S.TAB');
assksb=lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D15/RPCLAP_20160915_200404_612_B1S.TAB');
LAP1_612= [];
LAP1_612.I =assks.sweeps;
LAP1_612.t_utc = assks.START_TIME_UTC;
LAP1_612.V = assksb.bias_potentials;
len2 = length(LAP1_612.t_utc);
% 
% LAP1_612= [];
% LAP1_612.I =RPCLAP20160915200404612I1S;
% LAP1_612.t_utc = VarName11;
% LAP1_612.V = VarName12;
% len2 = length(VarName11);
for i=1:len2
    LAP1_612.t_epoch(i) = irf_time(LAP1_612.t_utc{i}(1:26),'utc>epoch');    
end


AvgLAP2_612 = [];
AvgLAP2_612.I = mean(LAP2_612.I,1);
AvgLAP2_612.V = LAP2_612.V;
AvgLAP2_612.Isd = std(LAP2_612.I);
AvgLAP1_612 = [];
AvgLAP1_612.I = mean(LAP1_612.I,1);
AvgLAP1_612.V = LAP1_612.V;
AvgLAP1_612.Isd = std(LAP1_612.I);






assks= lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D15/RPCLAP_20160915_214348_416_I2S.TAB');
%assksb=lap_import('/mnt/squid/RO-C-RPCLAP-5-1609-DERIV-V0.5/2016/SEP/D24/RPCLAP_20160924_010212_416_B2S.TAB');

LAP2_416.I15Sep =assks.sweeps;
LAP2_416.t_utc15Sep = assks.START_TIME_UTC;
len2 = length(LAP2_416.t_utc15Sep);
%LAP2_416= [];
% LAP2_416.I15Sep =RPCLAP20160915214348416I2S;
% LAP2_416.t_utc15Sep = VarName13;
%LAP2_416.V = VarName14;
% len2 = length(VarName13);
for i=1:len2
    LAP2_416.t_epoch15Sep(i) = irf_time(LAP2_416.t_utc15Sep{i}(1:26),'utc>epoch');    
end




%AvgLAP2_416 = [];
AvgLAP2_416.I15Sep = mean(LAP2_416.I15Sep,1);
AvgLAP2_416.Isd15Sep = std(LAP2_416.I15Sep);



of_s= 0;

figure(23)
plot(Avg_926.V,Avg_926.I+of_s,'o',AvgLAP2_612.V,AvgLAP2_612.I+of_s,'o',AvgLAP1_612.V,AvgLAP1_612.I+of_s,'o',Avg_416.V,AvgLAP2_416.I15Sep,'o')
ax=gca;
ax.Title.String = 'LAP1 & 2 Sweeps binned average on each potential step 15 Sep 2016';
ax.YLabel.String = 'Sweep Current (A)';
ax.XLabel.String = 'Vbias';
axL=legend('926 23sep (7 sweeps) ','LAP2 612 15 Sep','LAP1 612 15 Sep','LAP2 416 15 Sep');
axL.Location='northwest';
grid on;




