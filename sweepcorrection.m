%sweepcorrection takes an array of currents with nSteps measurements at every
%potential step potBias, and removes noisy values compared at each step,
%disregarding and removing extremely noisy values for standard deviation comparisons
%using largeK and smallK
%suggested values for largeK = 3, and smallK = 1.
%curArray must have nSteps current measurements at each potential step
%except the last entries.
%note: potBias is no longer in use, remove?
function [curOut] = sweepcorrection(curArray,nSteps,largeK,smallK)


curOut = vec2mat(curArray,nSteps,NaN).'; %reformat curArray to matrix, fill with NaN values if needed on last steps
%curOut=A.';
len = length(curOut);

test1 = smooth(nanmean(curOut,1),0.08,'rloess').'; %very hard smoothening, ignore 'rogue values'

%mu_test1 = nanmean(test1,1); %function that ignores NaN values, row vector
sigma_test1(1:len) = nanstd(test1); %ignores NaN values, unbiased std, SAME SINGLE VALUE TO ALL COLUMNS
%[n,junk] = size(curOut);
% Create a matrix of mean & std values by replicating the mu/std vector for n rows
MeanMat = repmat(test1,nSteps,1);
SigmaMat = repmat(sigma_test1,nSteps,1);

test1Outliers = abs(curOut - MeanMat) > largeK*SigmaMat; % 68% chance on normal sigma mode
%extOutlier = abs(curOut - mean(curArray)) > largeK*std(curArray); %extreme outliers lies outside of 99% confidence for the entire sweep

curOut(test1Outliers)= NaN; %need to exclude from mean & std calculations


if nSteps>1 %it's not meaningful to do this if nSteps == 1.
    
        
%mu_test2 = nanmean(curOut,1);%function that ignores NaN values, row vector
%edit, probably good to weight mean towards test1 values (particularly for low nSteps values)
mu_test2= nanmean([curOut;test1],1); 

sigma_test2 = nanstd(curOut,0,1); %function that ignores NaN values, unbiased std, row vector
[n,junk] = size(curOut);
% Create a matrix of mean & std values by replicating the mu/std vector for n rows
MeanMat = repmat(mu_test2,n,1);
SigmaMat = repmat(sigma_test2,n,1);


% Create a matrix of zeros and ones, where ones indicate the location of outliers
outliers = abs(curOut - MeanMat) > smallK*SigmaMat; % 66% chance on normal sigma mode

curOut(outliers) = NaN;
end

%curOut = nanmean(curOut); %destructive downsampling, let's do this outside function


end
