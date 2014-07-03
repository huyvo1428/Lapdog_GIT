function [curOut] = sweepcorrection(curArray,potBias,nSteps,largeK,smallK)
%sweepcorrection takes an array of currents with nSteps measurements at every
%potential step potBias, and removes noisy values compared at each step,
%disregarding and removing extremely noisy values for standard deviation comparisons
%using largeK and smallK
%suggested values for largeK = 3, and smallK = 1.
%curArray must have nSteps current measurements at each potential step
%except the last entries.

A = vec2mat(curArray,nSteps,NaN); %reformat curArray to matrix, fill with NaN values if needed on last steps

%[A,pad] = vec2mat(curArray,nSteps,NaN); %reformat curArray to matrix, fill with NaN values if needed on last steps

curOut=A.';
extOutlier = abs(curOut - mean(curArray)) > largeK*std(curArray); %extreme outliers lies outside of 99% confidence for the entire sweep

curOut(extOutlier)= NaN; %need to exclude from mean & std calculations

mu = nanmean(curOut); %function that ignores NaN values
sigma = nanstd(curOut); %function that ignores NaN values
[n,junk] = size(curOut);
% Create a matrix of mean & std values by replicating the mu/std vector for n rows
MeanMat = repmat(mu,n,1);
SigmaMat = repmat(sigma,n,1);


% Create a matrix of zeros and ones, where ones indicate the location of outliers
outliers = abs(curOut - MeanMat) > smallK*SigmaMat; % 66% chance on normal sigma mode

%outliers(extOutlier) = 1; % all extreme outliers should also be in this array% no need


curOut(outliers) = NaN;
%curOut = nanmean(curOut); %destructive downsampling, let's do this outside function


end
