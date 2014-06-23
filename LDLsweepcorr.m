function [curr] = LDLsweepcorr(curArray,inter,potbias,nSteps)


diag = 1;

curStd = accumarray(inter,curArray,[],@std);



%accumarray(
%inter(

curTemp = accumarray(inter,curArray,[],@mean);

B=find(curStd(:)>mean(curStd));

%temp2 = curTemp;
%temp2(B)=[];


for i=1:length(B)

    A=[curArray((B(i):B(i)+nSteps-1))]; %A is all current values on suspicious LDL distrubed potatial step
    
    stdA=std(A);
  %  F = find( A(:) > 
    
    
end






[A,pad] = vec2mat(curArray,nSteps,NaN);

count=A.';

extOutlier = abs(count - mean(curArray)) > 3*std(curArray);

count(extOutlier)= NaN; %need to exclude from mean & std calculations



mu = nanmean(count); %function that ignores NaN values
sigma = nanstd(count); %function that ignores NaN values
[n,p] = size(count);
% Create a matrix of mean values by
% replicating the mu vector for n rows
MeanMat = repmat(mu,n,1);
% Create a matrix of standard deviation values by
% replicating the sigma vector for n rows
SigmaMat = repmat(sigma,n,1);


% Create a matrix of zeros and ones, where ones indicate
% the location of outliers
outliers = abs(count - MeanMat) > 1*SigmaMat; % 66% chance on normal sigma mode

outliers(extOutlier) = 1; % all extreme outliers should also be in this array

% Calculate the number of outliers in each column
nout = sum(sum(outliers));

figure(162);
plot(count(~outliers));


count(outliers) = NaN;


% A=zeros(length(potbias),nSteps);
% 
% for i=1:length(potbias)
% 
%     A(i)=curArray(i:i+nSteps-1); %A is all current values on suspicious LDL distrubed potatial step   
%     
% end

% 
% 
% inter = floor(1:1/nSteps:(length(potbias)+(nSteps-1)/nSteps)));
% 
% 
% inter = floor(1:0.25:(length(potbias)+0.75));


i=5;

A=[curArray(i:i+nSteps-1)];



figure(160);
plot(potbias,curTemp);


figure(161);
plot(curStd);


'hello'



curr = nanmean(count);

end
