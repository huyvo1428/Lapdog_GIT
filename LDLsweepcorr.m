function [outcurr] = LDLsweepcorr(curArray,potbias,nSteps)

%function [curr] = LDLsweepcorr(curArray,inter,potbias,nSteps)


diag = 1;




%curTemp = accumarray(inter,curArray,[],@mean);

%B=find(curStd(:)>mean(curStd));

%temp2 = curTemp;
%temp2(B)=[];


%for i=1:length(B)

%    A=[curArray((B(i):B(i)+nSteps-1))]; %A is all current values on suspicious LDL distrubed potatial step
    
%    stdA=std(A);
  %  F = find( A(:) > 
    
    
%end






[A,junk] = vec2mat(curArray,nSteps,NaN); %reformat curArray to matrix, fill with NaN values if needed on last steps

count=A.';
extOutlier = abs(count - mean(curArray)) > 3*std(curArray); %extreme outliers lies outside of 99% confidence for the entire sweep

count(extOutlier)= NaN; %need to exclude from mean & std calculations

mu = nanmean(count); %function that ignores NaN values
sigma = nanstd(count); %function that ignores NaN values
[n,junk] = size(count);
% Create a matrix of mean & std values by replicating the mu/std vector for n rows
MeanMat = repmat(mu,n,1);
SigmaMat = repmat(sigma,n,1);


% Create a matrix of zeros and ones, where ones indicate the location of outliers
outliers = abs(count - MeanMat) > 1*SigmaMat; % 66% chance on normal sigma mode

%outliers(extOutlier) = 1; % all extreme outliers should also be in this array% no need


count(outliers) = NaN;

outcurr = nanmean(count); %final product



if (diag)

nout = sum(sum(outliers));

figure(162);

        subplot(1,2,1)
	plot(potbias,outcurr);
        xlabel('Vp [V]');
        ylabel(‘I’);

        title(‘edited sweep’);
        grid on;
        subplot(1,2,2)
	plot(potbias,curArray) 
        xlabel('Vp [V]');
        ylabel(‘I’);
        title(‘unedited sweep‘);
        grid on;


%plot mean(curArray) + 3*std(curArray) !!!






curStd = accumarray(inter,curArray,[],@std);

end



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



'hello'



end
