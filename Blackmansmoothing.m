%Blackmansmoothing.m
%This function takes a sweep, fills NaN values (linear extrapolation),
%creates a finite response filter ('Blackman window'), convolves the sweep 
%with the filter and outputs the filtered sweep 
%Inputs: 
%V = Potential bias array, used for choosing cut off frequency
%I = Current array, to be smoothed
% 
function [I_filtered, badextrapflag] = Blackmansmoothing(V,I,CUT_RATIO)
%CUT_RATIO= 0.10;

badextrapflag =0;
I_filtered=[];
if abs(V(1)) <1e-4
fprintf(1,'check input, Blackmansmoothing(V,I,CUT_RATIO))');
return;
end

    
    
I_z=I;
nanind=find(isnan(I));
%nanind=isnan(I)
if ~isempty(nanind) %
    for i=1:length(nanind)
        ind=nanind(i);
        if ind<7
            extrapind=ind+1:ind+5; %extrapolate backwards
        else
            extrapind=ind-5:ind-1; %else, extrapolate forwards.
        end
        I_z(ind)=interp1(V(extrapind), I(extrapind),V(ind),'linear','extrap');
    end
    
    nanind=find(isnan(I_z)); %
    if ~isempty(nanind) % STILL FILLED WITH NAN? goddamnit
        badextrapflag =1; %let's flag this awful extrapolation        
        for i=1:length(nanind)
            ind=nanind(i);
            if ind<5
                extrapind=ind+1:ind+5; %extrapolate backwards
            else
                extrapind=ind-5:ind-1; %extrapolate forwards.
            end
            %extrapolate from already extrapolated values...
            I_z(ind)=interp1(V(extrapind), I_z(extrapind),V(ind),'linear','extrap'); 
        end
    end
end
%I_z=I;
%I_z(isnan(I))=0;

dV= V(end)-V(end-1); %step length in Volts

samples = length(V); %length of array
sample_freq = abs(V(end)-V(1))/(samples);
fs_nyq = sample_freq/2;  %#Calculate the Nyquist frequency
cut_freq = abs(CUT_RATIO*fs_nyq/dV); %# The cut-off frequency, roughly the frequency of the slope. Mostly found by trial and error.
%also applied a factor 1/dV to account for different nyquist frequency
%handling in python & Matlab
pad_samples=2*floor(samples/4 +0.5);%# Samples to pad

%temp = padarray(I_z,pad_samples,'symmetric');
%new padding
V_temphi= (V(end)+dV:dV:V(end)+15).';
V_templo= (V(1)-15:dV:V(1)-dV).';
I_temphi= polyval(polyfit(V(end-5:end), I(end-5:end),1),V_temphi);
I_templo= polyval(polyfit(V(1:8),       I(1:8),      1), V_templo);
%padlength= length(I_templo) +length(I_temphi);
temp = [I_templo;I_z;I_temphi];
% figure(551)
% plot(temp)


evensamples = samples + mod(samples,2);
oddsamples = evensamples-1; 
filt_resp = fir1(oddsamples,cut_freq,blackman(evensamples)); %
%filt_resp= firwin(samples, cut_freq, window = 'blackman', nyq = fs_nyq)  #Finite impulse response filter using Blackman window


filt_data = conv(filt_resp,temp,'same');%done
%filt_data = filt(filt_resp,1,temp,'same');%done
%filt_data2 = filter(filt_resp,1,temp);%done
%filt_data1 = filtfilt(1, filt_resp,temp);%done
%figure(7)
%plot((1:length(filt_data))+182,filt_data,'o',1:length(filt_data2),filt_data2,'+');
%filt_data2 = conv(filt_resp,temp);%done
%figure(7)
%plot((1:length(filt_data))+182,filt_data,'o',1:length(filt_data2),filt_data2);
%I_filtered = filt_data(end-samples+1:end);
%I_filtered = filt_data(length(temp)-1:length(temp)+samples);


if length(filt_data)==length(I)
    I_filtered=filt_data;
else%in some cases, the filter response creates an extra point.    
    I_filtered=filt_data(1:end-1);
end
end
