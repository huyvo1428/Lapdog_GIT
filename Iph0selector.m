%Selects Iph0 to be used in analysis, function takes a filepath and OBT 
%time and returns the associated Iph0 to be used for that point in time
%The filepath is most probably Iph0.txt and should be in the lapdog folder
function [iph0_out]= Iph0selector(filepath,OBT_timeofsweep,probenr)

%'probenr: ';
%probenr

iph0_out = -6.647e-09; % default value; %just in case of error.

%iph0file='Iph0.txt';            

trID = fopen(filepath);

if trID < 0
    fprintf(1,'Error, cannot open file %s', filepath);
    return
end % if I/O error

scantemp=textscan(trID,'%s%f%f%f%*s','commentStyle', '%','delimiter',','); %continues to read, skips '%'marked lines and input floats into scantemp cellarray

%tscsweep =2E8;

scanmat = cell2mat(scantemp(1,2:4));

switch probenr
    
    case 1
        scanmat = scanmat(~isnan(scanmat(:,2)),:);
        iph0vec = scanmat(:,2);
        
    case 2
        scanmat = scanmat(~isnan(scanmat(:,3)),:);
        iph0vec = scanmat(:,3);

end

   


len = length(scanmat(:,1));

for i=1:len

    
    if i == len %loop finished, exit
        iph0_out = iph0vec(i); %
    end
    
    if OBT_timeofsweep < scanmat(i,1); %have we passed that date in the iph0 list?

        now = max([i-1,1]);  %move to i-1, but don't go below 1      
        iph01 = iph0vec(now);   %previously valid measurement
        %iph02 = scantemp{1,3}(i+1); %may be useful for interpolation at some point
        iph0_out = iph01;  % delete this if interpolation is interesting
   	break
    end
    
      
        
end;
return;
