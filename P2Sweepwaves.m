%P2sweepwaves.m

addpath('~/Rosetta/lap_import/')
addpath('~/Documents/MATLAB/irfu-matlab/')

PSW2_160423=lap_import('~/Rosetta/temp/RPCLAP_20160423_030400_914_I1S.csv');
PSW2_160423_B=lap_import('~/Rosetta/temp/RPCLAP_20160423_030400_914_B1S.csv');


pnt =40;
%ind = 240-pnt+1:240;
ind = 1:pnt;


p2Sw.i = PSW2_160423.sweeps(:,ind);
p2Sw.t = PSW2_160423_B.sample_times(ind);

lens = pnt;
nfft=4000;
fsamp = floor(1/mean(diff(PSW2_160423_B.sample_times))+0.5);

pw=[];
T_plot=[];
psd=nan(pnt,fsamp);
p2Sw.pwelch = [];
for j = 1:length(PSW2_160423.qf)

    P= polyfit(p2Sw.t.',p2Sw.i(j,:),1);
    reduced = p2Sw.i(j,:) - polyval(P,p2Sw.t.');
    %reduced = p2Sw.i(j,:)- (p2Sw.t.'*P(1) +P(2));
    [psd,freq] = pwelch(reduced,hanning(lens),[], nfft, fsamp);
    pw = [pw psd];
    T_plot= [T_plot irf_time(PSW2_160423.START_TIME_UTC{j,1}(1:22),'iso2epoch')];
    %figure(1);plot(p2Sw.t,p2Sw.i(j,:),'o',p2Sw.t,polyval(P,p2Sw.t.'))


end


p2Sw.psd = pw;




%PSW2_160423.START_TIME_UTC
figure(4);
imagesc(T_plot,freq,log10(pw));
ax=gca;
set(gca,'YDir', 'normal'); % flip the Y Axis so lower frequencies are at the bottom
colorbar('Location','EastOutside');
irf_timeaxis(ax,irf_time(T_plot(1),'epoch2iso'))

%datetick('x',13);
%xlabel('HH:MM:SS (UT)');
ylabel('Frequency [Hz]');
%titstr = sprintf('LAP %s spectrogram %s',fileflag,datestr(ts(1),29));
%title(titstr);
title('LAP1 23rd April 2016. power spectra of sweep wave behaviour-ion part of sweep')
drawnow;


figure(5)
plot(freq,mean(pw,2))
grid on;
title('Average spectra sweep wave behaviour')
xlabel('Frequency [Hz]');
ylabel('psd');
