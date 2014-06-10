%P1 DAT read & downsample


arID = fopen('P1.dat','r'); %open file

scanhead=textscan(arID,'%s',15,'delimiter','\n'); %reads first 15 lines of file
scantemp=textscan(arID,'%f%f','commentStyle', '%'); %continues to read, skips '%'marked lines and input floats into scantemp cellarray

fclose(arID); %close file





%%invalid values detection & deletion
len = length(scantemp{1,2}); %number of data rows
del = false(1,len); %boolean array of zeros
delvalue = 1.57e+09;
for i=1:length(scantemp{1,2}) %loop all rows of column 2
    
    if (scantemp{1,2}(i) == delvalue ) %if value is EXACTLY delvalue
        del(i)=1; %mark row for delition
    end%if
    
end%for

if sum(unique(del)) %delete flagged measurements, if relation is equal to 1 if any delete flags, 0 otherwise
    %need to remove entire row on both columns
    scantemp{1,1}(del)    = []; 
    scantemp{1,2}(del)    = []; 
end


%%timing
t0 = scantemp{1,1}(1); %start time of averaging, chosen to be first time of file
intval = 4; %4 seconds
inter = 1 + floor((scantemp{1,1}(:) - t0)/intval); %prepare subset selection to accumarray

%intervals specified from beginning of file, in intervals of 4 seconds,
%the array inter marks which interval the data in the file is related to
%select measurements during specific intervals, accumulate mean of selected
%measurements to array and print NaN if no measurement taken during period of measurement
vmu = accumarray(inter,scantemp{1,2}(:),[],@mean,NaN); 
%Could also be used for other functions, such as @std

%%print results
awID = fopen('P1DOWNSAMPLED.DAT','w'); 
%header, from P1.DAT
for i=1:length(scanhead{1,1})
    fprintf(awID,'%s\n',scanhead{1,1}{i,1});
end
%body
for i=1:length(vmu)
    %data is evenly spaced at the midpoint of every 4 seconds from t0
    fprintf(awID,'%12.6f %14.3e\n',t0+(i-0.5)*intval,vmu(i));  
end
fclose(awID);



