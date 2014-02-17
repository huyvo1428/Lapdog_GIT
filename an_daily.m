%an_daily

function []= an_daily(an_ind,flag1,p,flag3,tabindex,intval)
count = 0;



i=an_ind(1);

for i=an_ind(1):an_ind(end)
    




    arID = fopen(tabindex{i,1},'r');
    scantemp=textscan(arID,'%s%f%f%f','delimiter',',');
    fclose(arID);
    
    
    ah =str2double(scantemp{1,1}{1,1}(12:13));
    am =str2double(scantemp{1,1}{1,1}(15:16));
    as =str2double(scantemp{1,1}{1,1}(18:end)); %including fractions of seconds
    hms = ah*3600 + am*60 + as;
    
    tday0=scantemp{1,2}(1)-hms; %%UTC and Spaceclock must be correctly defined
    
    
    % intval = 32; %//8 or 32 second spacing)
    
    t=scantemp{1,2}(:);
    tt = ( tday0+intval*floor((t(1)-tday0)/intval):1*intval:tday0+intval*ceil((t(end)-tday0)/intval) )'; %tidst?mplar med 32 sekunder mellan varje st?mpel, startar p? en multipel av 32 p? dygnet
    %tt = ( floor(t(1)):1*spacing:ceil(t(end)) )';
    %//         (Note that I sorted t above.)
    
    % //        I would do this in three fully vectorized lines of code. First, if the breaks were arbitrary and potentially unequal in spacing,
    %//I would use histc to determine which intervals the data series falls in. Given they are uniform, just do this:
    
    
    inter = 1 + floor((t - tday0)/intval); %prepare subset selection to accumarray
	


	%//        Again, if the elements of t were not known to be sorted, I would have used min(t) instead of t(1). Having done that, use accumarray to reduce the results into a mean and standard deviation.
    
    
    
    
    imu = accumarray(inter,scantemp{1,3}(:),[],@mean);
    isd = accumarray(inter,scantemp{1,3}(:),[],@std);
    
    vmu = accumarray(inter,scantemp{1,4}(:),[],@mean);
    vsd = accumarray(inter,scantemp{1,4}(:),[],@std);
    
    



  
   % UTCpart1 = cellfun(@(x) x(1:11),scantemp{1,1}(:,1),'un',0);
   
    
    UTCpart1 = scantemp{1,1}{1,1}(1:11);    
    
    afname = strrep(tabindex{i,1},tabindex{i,1}(end-6:end),sprintf('%s%i%s%iSEC.TAB',flag1,p,flag3,intval));
   


if exist(afname,'file')~=1 && count~=1 %this doesn't work!  
    awID = fopen(afname,'w');
	for j=1:3600*24/intval;
	
	UTCpart2= datestr((0.5*intval+(j-1)*intval)/(24*60*60), 'HH:MM:SS.FFF');
        UTC_time =sprintf('%s%s',UTCpart1,UTCpart2);
	fprintf(awID,'%s,%16.6f,,,,\n',UTC_time,(0.5*intval+tday0+(j-1)*intval);
	end

else
    awID= fopen(afname,'a',inter);

end
   
    

  for(j=inter(1):1:length(imu))
    
        
        UTCpart2= datestr((0.5*intval+(j-1)*intval)/(24*60*60), 'HH:MM:SS.FFF');
        UTC_time =sprintf('%s%s',UTCpart1,UTCpart2);
        
        fprintf(awID,'%s,%16.6f,,,,\n',UTC_time,(0.5*intval+tday0+(j-1)*intval);
        
end

  
    
    
    
    
  %  for(j=1:length(imu))
    
   %     
    %    UTCpart2= datestr((0.5*intval+(j-1)*intval)/(24*60*60), 'HH:MM:SS.FFF');
     %   UTC_time =sprintf('%s%s',UTCpart1,UTCpart2);
        
      %  if le(j,inter(1)-1)
    %        fprintf(awID,'%s,%16.6f,,,,\n',UTC_time,(0.5*intval+tday0+(j-1)*intval);
       % else
     %       fprintf(awID,'%s,%16.6f,%14.7e,%14.7e,%14.7e,%14.7e\n',UTC_time,tt(j-inter(1)+1),imu(j),isd(j),vmu(j),vsd(j));
        %end
        
    %end
    
    fclose(awID);
    count = 1;
    
    
    
    
    
end


end








