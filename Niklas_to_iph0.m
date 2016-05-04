
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
%need OBT time of first measurement

iph0_probe1=iph0;
iph0_probe2=iph02;

ind=find(macro == 204 | macro == 817 | macro == 900 | macro ==  903 | macro ==  905 | macro ==  917 | macro ==   922 | macro ==   1101); %macro a11 renamed to 1101 due to some trouble with string/num. Quick fix.
iph0_probe1(ind)=NaN;
ind2=find(macro2 == 204 | macro2 == 817 | macro2 == 900 | macro2 ==  903 | macro2 ==  905 | macro2 ==  917 | macro2 ==   922 | macro2 ==   1101); %macro a11 renamed to 1101 due to some trouble with string/num. Quick fix.
iph0_probe2(ind2)=NaN;



%starttime(1) = 09-May 2014 15:23:00  = 358269715.294412.

%starttime_s = seconds(seconds(starttime)); % convert to seconds, convert to double array instead of duration array
starttime_obt = (starttime_s-(starttime_s(1)))*24*60*60 +  213051714.703159-34;

filename='iph0_probe1_temp.txt';

twID = fopen(filename,'w');

%                        fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, %03i\r\n'...
%                            ,scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),qualityF);




for i = 1:length(starttime)
    
    if ~isnan(iph0_probe1(i))
        fprintf(twID,'%s,%16.6f,%14.7e,%s\r\n',datestr(starttime(i),'yyyy-mm-ddTHH:MM:SS.fff000'),starttime_obt(i),iph0_probe1(i),'generated 6 April 2016');
    end
    
end
fclose(twID);

filename='iph0_probe2_temp.txt';

twID = fopen(filename,'w');
%starttime_s2 = seconds(seconds(starttime2)); % convert to seconds, convert to double array instead of duration array
%starttime_obt2 = starttime_s2-(starttime_s2(1)) + 358269747.294412-1;

starttime_obt2 = (starttime_s2-(starttime_s2(1)))*24*60*60 + 213051746.703145-34;

%starttime(1) = 09-May 2014 15:23:00 358269747.294412
for i = 1:length(starttime2)
    if ~isnan(iph0_probe2(i))
        fprintf(twID,'%s,%16.6f,%14.7e,%s\r\n',datestr(starttime2(i),'yyyy-mm-ddTHH:MM:SS.fff000'),starttime_obt2(i),iph0_probe2(i),'generated 6 April 2016');
    end
    
end
fclose(twID);

