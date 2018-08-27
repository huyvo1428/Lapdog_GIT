
% anything with a % sign is a comment and will be ignored
% Author: Fredrik Johansson 01-Aug 2015
% Iph0.txt is a file that lists the photosaturation current as detected by semi-automatic or manual routines and is used by an_sweepmain.m for sweep analysis
% the format is:
% UTC, OBT, LAP1_Iph0, LAP2_Iph0, description
% where:
% UTC= "UTC TIME YYYY-MM-DDThh:mm:ss.ffffff"
% OBT= SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"
% LAP1_Iph0 = Photosaturation value in Ampere for LAP 1 or NaN if no measurement on that date
% LAP2_Iph0 = Photosaturation value in Ampere for LAP 2 or NaN if no measurement on that date
% description = Human readable description of the Iph0 value specified
% first iteration of Iph0.txt should list the photosaturation ampere that should be used from respective point in time.
% further iterations of this file or the routine that uses this file should incorprate an interpolation routine, preferably as a function of distance to Sun and/or a function of a relevant sunflux estimate, like Mg-II band F10.7
% 2005-01-01T00:00:00.0,63072000.0000000,-6.647e-09,-6.647e-09,'LAP1 before first Earth swing by- preliminary'
% 2014-10-01T00:00:00.0,370915207.526316,-8.55e-09,-8.55e-09,'LAP1 after arrival at comet'
% 2015-01-01T00:00:00.0,378691127.436616,-1.19e-08,-1.19e-08,'LAP1 new measurement of Iph0'
% 2015-08-01T00:00:00.0,397007922.439373,-2.4e-8,-2.4e-8,'LAP1 preliminary measurement of Iph0 from 3Aug 2015'
% 2015-08-31T08:39:48.0,399631109.572591,-2.82e-8,NaN,'LAP1 measurement of Iph0 from 31 Aug 2015'


%need to load iph0, starttimes.
%load('~/Downloads/iph0-16V_2014may-2016_00rms_v6_LAP2.mat');
% load('~/Downloads/Iph0_-16V_20140509-20160830_LAP2.mat');
% stoptime2=stoptime;iph02=iph0;macro2=macro;N2=N;rms2=rms;starttime2=starttime;
% %load('~/Downloads/iph0-16V_2014may-2016_00rms_v6.mat');
% load('~/Downloads/Iph0_-16V_20140509-20160830_LAP1.mat');
% %need to EUV.
% load('~/Downloads/EUV_rosetta.mat');
%need OBT time of first measurement!

%load('~/Rosetta/Rosetta_EUV+iph0.mat');
iph02=LAP2.iph0_raw;
starttime2=LAP2.starttime;
rms2 =  LAP2.rms;
stoptime2= LAP2.stoptime;
macro2= LAP2.macro;
%N2= LAP2.N;
iph0=LAP1.iph0_raw;
starttime=LAP1.starttime;
rms =  LAP1.rms;
stoptime= LAP1.stoptime;
macro= LAP1.macro;
%N= LAP1.N;
iph0_probe1=iph0;iph0_probe2=iph02;


ind=find(macro == 204 | macro == 817 | macro == 900 | macro ==  903 | macro ==  905 | macro ==  917 | macro ==   922 | macro ==   1101); %macro a11 renamed to 1101 due to some trouble with string/num. Quick fix.
iph0_probe1(ind)=NaN;
ind=find(macro2 == 204 | macro2 == 817 | macro2 == 900 | macro2 ==  903 | macro2 ==  905 | macro2 ==  917 | macro2 ==   922 | macro2 ==   1101); %macro a11 renamed to 1101 due to some trouble with string/num. Quick fix.
iph0_probe2(ind)=NaN;

ind=find(rms > 1E-7);
iph0_probe1(ind)=NaN;
ind=find(rms2 > 1E-7);
iph0_probe2(ind)=NaN;

clear ind



%starttime(1) = 09-May 2014 15:23:00  = 358269715.294412.

starttime_s = seconds(seconds(starttime)); % convert to seconds, convert to double array instead of duration array
%starttime_obt = (starttime_s-(starttime_s(1)))*24*60*60 +  213051714.703159-34;
starttime_obt = (starttime_s-(starttime_s(1)))*24*60*60 +  358269715.294412-34;

filename='iph0_probe1_temp.txt';

twID = fopen(filename,'w');

%                        fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, %05i\r\n'...
%                            ,scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),qualityF);




for i = 1:length(starttime)
    
    if ~isnan(iph0_probe1(i))
        fprintf(twID,'%s,%16.6f,%14.7e,%s\r\n',datestr(starttime(i),'yyyy-mm-ddTHH:MM:SS.fff000'),starttime_obt(i),iph0_probe1(i),'generated 9 Aug 2016');
    end
    
end
fclose(twID);

filename='iph0_probe2_temp.txt';

twID = fopen(filename,'w');
starttime_s2 = seconds(seconds(starttime2)); % convert to seconds, convert to double array instead of duration array
%starttime_obt2 = starttime_s2-(starttime_s2(1)) + 358269747.294412-1;

%starttime_obt2 = (starttime_s2-(starttime_s2(1)))*24*60*60 + 213051746.703145-34;
starttime_obt2 = (starttime_s2-(starttime_s2(1)))*24*60*60 + 358269747.294412 -34;



%starttime(1) = 09-May 2014 15:23:00 358269747.294412
for i = 1:length(starttime2)
    if ~isnan(iph0_probe2(i))
        fprintf(twID,'%s,%16.6f,%14.7e,%s\r\n',datestr(starttime2(i),'yyyy-mm-ddTHH:MM:SS.fff000'),starttime_obt2(i),iph0_probe2(i),'generated 9 Aug 2016');
    end
    
end
fclose(twID);

%EUV_rosetta.Rosetta_epoch2=irf_time(EUV_rosetta.Rosetta_epoch,'tt>epoch');

figure(67)
subplot(2,1,1)
plot(starttime,iph0,'+',starttime2,iph02,'+',starttime,iph0_probe1,'o',starttime2,iph0_probe2,'o',EUV_rosetta.Rosetta_epoch, sum(EUV_rosetta.photon_flux(:,EUV_rosetta.wavelength <= 120), 2))

%irf_timeaxis(gca, 'usefig');
%irf_timeaxis(gca, irf_time(0, 'utc>epoch'));

grid on;
%set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
%datetick('x',20)
subplot(2,1,2)
plot(starttime,macro,'+',starttime2,macro2,'o')
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20)
grid on;

figure(545)
plot(starttime,iph0,'+',starttime2,iph02,'+',starttime,iph0_probe1,'o',starttime2,iph0_probe2,'o')
grid on;
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto')
datetick('x',20)

%irf_time(datestr(starttime2,'yyyy-mm-ddTHH:MM:SS.fff000'),'utc>epoch');


figure(68)
% LAP1=[];
% LAP1.iph0_raw=iph0;
% LAP1.starttime = starttime;
% LAP1.t_epoch = irf_time(datestr(starttime,'yyyy-mm-ddTHH:MM:SS.fff000'),'utc>epoch');
% LAP1.iph0_filt1=iph0_probe1;

% LAP2=[];
% LAP2.iph0_raw=iph02;
% LAP2.starttime = starttime2;
% LAP2.t_epoch = irf_time(datestr(starttime2,'yyyy-mm-ddTHH:MM:SS.fff000'),'utc>epoch');
% LAP2.iph0_filt2=iph0_probe2;

EUV_rosetta.proxyupto120nm=sum(EUV_rosetta.photon_flux(EUV_rosetta.is_weighted_mean,EUV_rosetta.wavelength <= 120), 2);

EUV_rosetta.proxyupto120nm=EUV_rosetta.proxyupto120nm*nanmean([LAP1.iph0_raw LAP2.iph0_raw])/mean(EUV_rosetta.proxyupto120nm);
%EUV_rosetta.proxyupto120nm=EUV_rosetta.proxyupto120nm;

%plot(LAP1.t_epoch,LAP1.iph0_raw,'+',LAP2.t_epoch,LAP2.iph0_raw,'+',LAP1.t_epoch,LAP1.iph0_filt1,'o',LAP2.t_epoch,LAP2.iph0_filt2,'o',EUV_rosetta.Rosetta_epoch,EUV_rosetta.proxyupto120nm)
%plot(LAP1.t_epoch,-LAP1.iph0_filt1,'o',LAP2.t_epoch,-LAP2.iph0_filt2,'o',EUV_rosetta.Rosetta_epoch(EUV_rosetta.is_weighted_mean),-EUV_rosetta.proxyupto120nm,'black')
plot(LAP1.t_epoch,-LAP1.iph0_filt1,'o',LAP2.t_epoch,-LAP2.iph0_filt2,'o',EUV_rosetta.Rosetta_epoch(EUV_rosetta.is_weighted_mean),-EUV_rosetta.proxyupto120nm,'black',mediand1.t_epoch,-mediand1.Iph0,'.',mediand2.t_epoch,-mediand2.Iph0,'.')

irf_timeaxis(gca, irf_time(0, 'epoch'));
ax=gca;
title('Probe saturation current vs TIMED/SEE EUV data, normalised to mean photoemission from 2014 August to 31 September 2016')
grid on;
ax.YLabel.String= 'Current from probe (A)';
%legend('LAP1','LAP2','LAP1','LAP2','EUV normalised to mean Iph0')

legend('LAP1 -Iph0','LAP2 -Iph0','EUV normalised to mean -Iph0','A1S Iph_0','A2S Iph_0')



figure(69)

subplot(1,2,1)

plot(EUV_rosetta.Rosetta_epoch(EUV_rosetta.is_weighted_mean), 3E-2*sum(EUV_rosetta.photon_flux(EUV_rosetta.is_weighted_mean,EUV_rosetta.wavelength >= 120), 2),EUV_rosetta.Rosetta_epoch(EUV_rosetta.is_weighted_mean), sum(EUV_rosetta.photon_flux(EUV_rosetta.is_weighted_mean,EUV_rosetta.wavelength <= 120), 2))
irf_timeaxis(gca, irf_time(0, 'et>epoch'));

subplot(1,2,2)
plot(EUV_rosetta.Rosetta_epoch, 3E-2*sum(EUV_rosetta.photon_flux(:,EUV_rosetta.wavelength >= 120), 2),EUV_rosetta.Rosetta_epoch, sum(EUV_rosetta.photon_flux(:,EUV_rosetta.wavelength <= 120), 2))

irf_timeaxis(gca, irf_time(0, 'et>epoch'));
title('Probe photoemission vs TIMED/SEE EUV data, normalised to mean photoemission from 2014 August to 1 September 2016')
grid on;



start = LAP1.t_epoch(1);
dt = mean(diff(LAP1.t_epoch))*12/14;
len= length(LAP1.t_epoch);

inter = 1 + 0:1:floor(((LAP1.t_epoch-start)/dt+0.5));
%LAP1.iph0_raw_test= accumarray(inter,LAP1.iph0_raw,[],@mean); %average
%LAP2.iph0_raw_test= accumarray(inter,LAP2.iph0_raw,[],@mean); %average

interEUV = 1+ floor((EUV_rosetta.Rosetta_epoch(EUV_rosetta.is_weighted_mean)-start)/dt+0.5);
interLAP2 = 1+  floor((LAP2.t_epoch-start)/dt+0.5);
interLAP1 =1+ floor((LAP1.t_epoch-start)/dt+0.5);


%EUV_rosetta.proxyupto120nm=sum(EUV_rosetta.photon_flux(EUV_rosetta.is_weighted_mean,EUV_rosetta.wavelength <= 120), 2);

accuEUV = accumarray(interEUV,EUV_rosetta.proxyupto120nm,[],@nanmean); %average
accuLAP1 = accumarray(interLAP1,LAP1.iph0_filt1,[],@nanmean); %average
accuLAP2 = accumarray(interLAP2,LAP2.iph0_filt2,[],@nanmean); %average
accutime = accumarray(interLAP1,LAP1.t_epoch,[],@nanmean); %average
accuKC_Q = accumarray(interLAP1,KC_Q,[],@nanmean); %average
accuAU = accumarray(interLAP1,LAP1.AU,[],@nanmean); %average
stdEUV = accumarray(interEUV,EUV_rosetta.proxyupto120nm,[],@std); %std
stdLAP1 = accumarray(interLAP1,LAP1.iph0_filt1,[],@std); %std
stdLAP2 = accumarray(interLAP2,LAP2.iph0_filt2,[],@std); %std


%indend=max(interLAP1);
indend=min([max(interLAP1) max(interLAP2) max(interEUV)]);

ind1= 1;

aEp1=[];
aEp2=[]; 
for i= 1:indend
    aEp1(i) = log10(-accuLAP1(i)/accuEUV(i));
    aEp2(i) = log10(-accuLAP2(i)/accuEUV(i));

end

aind=(accutime>0);
aind(indend+1:end)=[];



figure(71)
%plot(accutime(accutime>0),aEp1(accutime>0),'o',accutime(accutime>0),aEp2(accutime>0),'o')
plot(accutime(aind),aEp1(aind),'o',accutime(aind),aEp2(aind),'o')
irf_timeaxis(gca, irf_time(0, 'epoch'));
ax1 = gca;
ax1.Title.String = 'Photosaturation current/ EUV flux. in bins of 14 hours each';
grid on;
legend('LAP1','LAP2')

 %               nStep= find(diff(scantemp{1,4}(1:end)),1,'first'); %find the number of measurements on each sweep
 %               inter = 1+ floor((0:1:length(scantemp{1,2})-1)/nStep).'; %find which values to average together
                
  %              potbias = accumarray(inter,scantemp{1,4}(:),[],@mean); %average
   %             scan2temp=accumarray(inter,scantemp{1,2}(:),[],@mean); %average time


EUV_rosetta.proxy2=sum(EUV_rosetta.photon_flux(EUV_rosetta.is_weighted_mean,EUV_rosetta.wavelength <= 120), 2);
EUV_rosetta.proxy2=EUV_rosetta.proxy2*nanmean([LAP1.iph0_raw LAP2.iph0_raw])/mean(EUV_rosetta.proxyupto120nm);





%size = 10E9*stdLAP1((accutime(1:indend)>0));


figure(72)

%plot(accuEUV(1:indend),accuLAP1(1:indend),'o',accuEUV(1:indend),accuLAP2(1:indend),'o')
title('Probe photoemission vs TIMED/SEE EUV data,from August 2014  to 1 September 2016')

subplot(1,2,1)
scatter(accuEUV(accutime(1:indend)>0),-1E9*accuLAP1(accutime(1:indend)>0), 10, accutime(accutime(1:indend)>0));
%set(gca,'CLim',[0 1]);
title('LAP1 photoemission vs TIMED/SEE EUV data,from August 2014  to 1 September 2016')

ax1 =gca;
ax1.XLabel.String='TIMED summed EUV flux, propagated to Rosetta';
ax1.YLabel.String='Photosaturation current *-1 (nA)';
ac1= colorbar;
ac1.Label.String = 'Label Text Goes Here';
ac1.TicksMode='manual';

t_diff=accutime(1)-accutime(indend);
t_mid=-floor(t_diff/2)+accutime(1);

% ac1.Ticks= [accutime(1) t_mid accutime(indend)];
% ac1.TickLabels={'Aug 2014', 'Aug 2015','Sep 2016'};
    


%

grid on;

subplot(1,2,2)
scatter(accuEUV(accutime(1:indend)>0),-1E9*accuLAP2(accutime(1:indend)>0), 10, accutime(accutime(1:indend)>0));
title('LAP2 photoemission (nA) vs TIMED/SEE EUV data,from August 2014  to 1 September 2016')

ax2 =gca;
ax2.XLabel.String='TIMED summed EUV flux, propagated to Rosetta';
ax2.YLabel.String='Photosaturation current *-1 (nA)';
ac1= colorbar;
ac1.Label.String = 'Label Text Goes Here';
ac1.TicksMode='manual';

t_diff=accutime(1)-accutime(indend);
t_mid=-floor(t_diff/2)+accutime(1);
% 
% ac1.Ticks= [accutime(1) t_mid accutime(indend)];
% ac1.TickLabels={'Aug 2014', 'Aug 2015','Sep 2016'};
%     
grid on;

%length(accutime(accutime((1:indend))>0)))
%plot(accutime(accutime>0),aEp1(accutime>0),'o',accutime(accutime>0),aEp2(accutime>0),'o')
%irf_timeaxis(gca, irf_time(0, 'et>epoch'));
%ax1 = gca;
%ax1.Title.String = 'Photosaturation current/ EUV flux. in bins of 14 hours each';
%grid on;
%legend('LAP1','LAP2')


temptime=EUV_rosetta.Rosetta_epoch(EUV_rosetta.is_weighted_mean);
euvKC_Q= interp1(LAP1.t_epoch,KC_Q,temptime);
shit=[];
for i=1:length(temptime)
%    shit(i) = EUV_rosetta.proxyupto120nm(i)*exp(-euvKC_Q(i)/(10*mean(euvKC_Q)));

    shit(i) = EUV_rosetta.proxyupto120nm(i)/-euvKC_Q(i);

end

    
%shit = accuEUV(aind)/accuKC_Q(aind);
%EUV_rosetta.proxy2=EUV_rosetta.proxy2*nanmean([LAP1.iph0_raw LAP2.iph0_raw])/mean(EUV_rosetta.proxyupto120nm);
shit = shit*nanmean([LAP1.iph0_raw LAP2.iph0_raw])/nanmean(shit);

figure(699)

%plot(LAP1.t_epoch,LAP1.iph0_raw,'+',LAP2.t_epoch,LAP2.iph0_raw,'+',LAP1.t_epoch,LAP1.iph0_filt1,'o',LAP2.t_epoch,LAP2.iph0_filt2,'o',EUV_rosetta.Rosetta_epoch,EUV_rosetta.proxyupto120nm)
plot(LAP1.t_epoch,LAP1.iph0_filt1,'o',LAP2.t_epoch,LAP2.iph0_filt2,'o',temptime,shit,'black')

irf_timeaxis(gca, irf_time(0, 'epoch'));
ax=gca;
title('Probe photoemission vs TIMED/SEE EUV data, normalised to mean photoemission from 2014 August to 1 September 2016')
grid on;
ax.YLabel.String= 'Current from probe (A)';
%legend('LAP1','LAP2','LAP1','LAP2','EUV normalised to mean Iph0')

legend('LAP1 Iph0','LAP2 Iph0','EUV/Q normalised to mean Iph0')



figure(700)


LAP2.AU=interp1(LAP1.t_epoch,LAP1.AU,LAP2.t_epoch);
EUV_rosetta.AU=interp1(LAP1.t_epoch,LAP1.AU,EUV_rosetta.Rosetta_epoch);

ql2=[];
ql1=[];
qe1=[];
for i = 1:length(LAP2.AU);
    ql2(i)=LAP2.iph0_filt2(i)*(LAP2.AU(i).^2);
end
for i = 1:length(LAP1.AU);
    ql1(i)=LAP1.iph0_filt1(i)*(LAP1.AU(i).^2);
end

temp = EUV_rosetta.AU((EUV_rosetta.is_weighted_mean));
for i = 1:length(EUV_rosetta.AU(EUV_rosetta.is_weighted_mean));
    qe1(i)=EUV_rosetta.proxyupto120nm(i)*temp(i).^2;
end

figure(700)
plot(LAP1.t_epoch,-ql1,'o',LAP2.t_epoch,-ql2,'o',EUV_rosetta.Rosetta_epoch(EUV_rosetta.is_weighted_mean),-qe1*10/7,'black')

title(' Probe photoemission * R_{sun}.^2') 
grid on;
legend ('LAP1 Iph0 * R_{Sun}^2','LAP2 Iph0 * R_{Sun}^2','EUV *R_{Sun}^2,scaled')
ax=gca;
ax.YLabel.String='Iph0*r_{sun} [AxAU^2]';
irf_timeaxis(gca, irf_time(0, 'epoch'));


accuqe1 = accumarray(interEUV,qe1,[],@nanmean); %average
accuql1 = accumarray(interLAP1,ql1,[],@nanmean); %average
accuql2 = accumarray(interLAP2,ql2,[],@nanmean); %average

ql1e=[];
ql2e=[];
for i = 1:indend;
    ql1e(i)=-accuql1(i)/accuqe1(i);
end

for i = 1:indend;
    ql2e(i)=-accuql2(i)/accuqe1(i);
end



figure(701)
plot(accutime(aind),ql1e(aind),'o')
%plot(LAP1.t_epoch,LAP1.iph0_filt1(i)*(LAP1.AU(i).^2);,'o',LAP2.t_epoch,ql2,'o',EUV_rosetta.Rosetta_epoch(EUV_rosetta.is_weighted_mean),qe1*10/7,'black')

title(' Probe photoemission * R_{sun}.^2') 
grid on;
legend ('LAP1 Iph0 * R_{Sun}^2','LAP2 Iph0 * R_{Sun}^2','EUV *R_{Sun}^2,scaled')
ax=gca;
ax.YLabel.String='Iph0*r_{sun} [AxAU^2]';
irf_timeaxis(gca, irf_time(0, 'epoch'));


temp1 = accuAU(aind);
temp2= accuqe1(aind);



figure(702)

scatter(accuAU(aind),log(-ql1e(aind)),10,accutime(aind))
grid on;
title('LAP1 photoemission *R_{sun}^2 / EUV Flux (arbitrary units)')
colorbar
title('LAP1 photoemission *R_{sun}^2 / EUV Flux (arbitrary units) vs R_{sun}[AU] vs time (colour bar)')

ax=gca;
ax.YLabel.String='ln(Iph0/EUVflux)';
ax.XLabel.String='Sun distance (AU)';

%what happens if we split the inbound and outbound leg around perihelion?
figure(703)
subplot(1,2,1)
%plot(accuAU(1:873),ql1e(1:873),2*accuAU(873)-accuAU(873:end),ql1e(873:end),'o')
plot(-accuAU(1:873)+1*accuAU(874),ql1e(1:873),'o',-1*accuAU(874)+accuAU(873:1613),ql1e(873:1613),'o')

grid on;
legend('inbound','outbound');
title('LAP1 photoemission *R_{sun}^2 / EUV Flux (arbitrary units) vs R_{sun}[AU]-r_{perihelion}, mirrored before perihelion')
subplot(1,2,2)
plot(accuAU(1:873),ql1e(1:873),'o',accuAU(873:1613),ql1e(873:1613),'o')
grid on;
legend('inbound','outbound');
title('LAP1 photoemission *R_{sun}^2 / EUV Flux (arbitrary units) vs R_{sun}[AU]-r_{perihelion}, mirrored before perihelion')



%y = 0.3287*x -0.3145

%we find some kind of (linear) relation with AU, so we can try to
%compensate that on the EUV, and see how good or bad the curves match

%but the plot says that we're way off on the early inbound and late outbound leg,
%where the EUV clearly does not actually depend linearly on AU
EUV_rosetta.AU_2=EUV_rosetta.AU(EUV_rosetta.is_weighted_mean);
Comp_factor = EUV_rosetta.AU_2*0.3287 - 0.3145;
EUV_rosetta.compensated=[];
for i=1:length(EUV_rosetta.proxyupto120nm)
    
Comp_factor = EUV_rosetta.AU*0.3287 ;%- 0.3145;
EUV_rosetta.compensated(i) = Comp_factor(i)*EUV_rosetta.proxyupto120nm(i);

    
end
factor=1.25;


%EUV_rosetta.compensated = diag(Comp_factor(EUV_rosetta.is_weighted_mean).'*EUV_rosetta.proxyupto120nm);
figure(268)
plot(LAP1.t_epoch,-LAP1.iph0_filt1,'o',LAP2.t_epoch,-LAP2.iph0_filt2,'o',EUV_rosetta.Rosetta_epoch(EUV_rosetta.is_weighted_mean),-factor*EUV_rosetta.compensated,'black',mediand1.t_epoch,-mediand1.Iph0,'.',mediand2.t_epoch,-mediand2.Iph0,'.')



irf_timeaxis(gca, irf_time(0, 'epoch'));
ax=gca;
title('Probe saturation current vs TIMED/SEE EUV data, normalised to mean photoemission from 2014 August to 31 September 2016')
grid on;
ax.YLabel.String= 'Current from probe (A)';
legend('LAP1 -Iph0','LAP2 -Iph0','EUV normalised to mean -Iph0','A1S Iph_0','A2S Iph_0')
%ax.YLabel.String= 'Current from probe (A)';
ax.YLim=[0 6e-8];
legend('LAP1','EUV normalised to mean Iph0','EUV with yield fn,normalised','A1S -I_{ph0}')





figure(703)
subplot(2,2,1)
plot(LAP1.altitude,LAP1.iph0_filt1,'o',LAP2.altitude,LAP2.iph0_filt2,'o')
grid on;
legend('LAP1','LAP2')
ax1=gca;
ax1.YLabel.String='iph0 (A)';
ax1.XLabel.String='comet altitude(km)';
ax1.XLim=[0 1600];

subplot(2,2,2)
plot(LAP1.AU,LAP1.iph0_filt1,'o',LAP2.AU,LAP2.iph0_filt2,'o')
grid on;
legend('LAP1','LAP2')
ax2=gca;
ax2.YLabel.String='iph0 (A)';
ax2.XLabel.String='Sun distance(AU)';

subplot(2,2,3)
plot(KC_Q,LAP1.iph0_filt1,'o')
grid on;
legend('LAP1')
ax2=gca;
ax2.YLabel.String='iph0 (A)';
ax2.XLabel.String='KC-Hansen Q';



