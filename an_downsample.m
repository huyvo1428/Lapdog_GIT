%an_daily



function []= an_downsample(an_ind,tabindex,intval)
count = 0;
oldUTCpart1 ='shirley,you must be joking';

global an_tabindex;

antemp ='';

foutarr=cell(1,7);

%fprintf(awID,'%s,%16.6f,,,,\n',UTC_time,(0.5*intval+tday0+(j-1)*intval));
%outputarr =
%





for i=1:length(an_ind)
    
    arID = fopen(tabindex{an_ind(i),1},'r');
    scantemp=textscan(arID,'%s%f%f%f','delimiter',',');
    fclose(arID);
    
    UTCpart1 = scantemp{1,1}{1,1}(1:11);
    
    
    i
    
    if count ~= 0 && ~strcmp(UTCpart1,oldUTCpart1) %%not the first time, and we have a new file going, let's print!
       
        %For LBL file genesis later, we need an index with name, shortname,
        %original file  
        an_tabindex{end+1,1} = afname;
        an_tabindex{end,2} = strrep(afname,affolder,'');
        an_tabindex{end,3} = tabindex{an_ind(i-count),3}; %first calib data file index of first derived file in this set
        an_tabindex{end,4} = length(foutarr{1,3}); %number of rows
        an_tabindex{end,5} = 6; %number of columns
        
        
        
        for j=0:count
            antemp = sprintf('%s,%i',antemp,an_ind(i-count+j));
            
        end
        
        an_tabindex{end,6} = antemp; %all tabindex indicies of this set.
        
        
        
        
        
        awID= fopen(afname,'w');
        
        for j =1:length(foutarr{1,3})
            
            if foutarr{1,7}(j)~=1 %check if measurement data exists on row
                
                fprintf(awID,'%s,%16.6f,,,,\n',foutarr{1,1}{j,1},foutarr{1,2}(j));     
                
            else
                fprintf(awID,'%s,%16.6f,%14.7e,%14.7e,%14.7e,%14.7e\n',foutarr{1,1}{j,1},foutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j));
                
            end%if
            
            
        end%for
        fclose(awID);
        count = 0; %reset counter
        clear foutarr
        foutarr=cell(1,7);
        
        
        
   %     tabindex
    end%if print new file
    

    
    %set starting spaceclock time to (UTC) 00:00:00.000000
    ah =str2double(scantemp{1,1}{1,1}(12:13));
    am =str2double(scantemp{1,1}{1,1}(15:16));
    as =str2double(scantemp{1,1}{1,1}(18:end)); %including fractions of seconds
    hms = ah*3600 + am*60 + as;
    tday0=scantemp{1,2}(1)-hms; %%UTC and Spaceclock must be correctly defined
    
    
    
        
    if count == 0 %first time going through loop! initialise things!
        %afname = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),1}(end-6:end),sprintf('%s%i%s%iSEC.TAB',flag1,p,flag3,intval));
        
       
        afname = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),1}(end-17:end-8),sprintf('DWNSMPL_%03i',intval));
        affolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
        
        
        for j=1:3600*24/intval;
            
            UTCpart2= datestr((0.5*intval+(j-1)*intval)/(24*60*60), 'HH:MM:SS.FFF'); %calculate time of each interval, as fraction of a day
            UTC_time =sprintf('%s%s',UTCpart1,UTCpart2); %collect date and time in one variable
           
            
            foutarr{1,1}{j,1} = UTC_time;
            foutarr{1,2}(j) = tday0+ 0.5*intval+(j-1)*intval; %spaceclock time of measurement mean ( 
            
        end
        
    end
    
    
    
    
    
    
    
    %t=scantemp{1,2}(:);
    
    
    %  tt = ( tday0+intval*floor((t(1)-tday0)/intval):1*intval:tday0+intval*ceil((t(end)-tday0)/intval) )'; %tidst?mplar med 32 sekunder mellan varje st?mpel, startar p? en multipel av 32 p? dygnet
    %tt = ( floor(t(1)):1*spacing:ceil(t(end)) )';
    % //        I would do this in three fully vectorized lines of code. First, if the breaks were arbitrary and potentially unequal in spacing,
    %//I would use histc to determine which intervals the data series falls in. Given they are uniform, just do this:
    
    
    
    
%    inter = 1 + floor((t - tday0)/intval); %prepare subset selection to accumarray    
     inter = 1 + floor((scantemp{1,2}(:) - tday0)/intval); %prepare subset selection to accumarray   
     
     %intervals specified from beginning of day, in intervals of intval,
     %and the variable inter marks which interval the data in the file is related to
   
    
    
    imu = accumarray(inter,scantemp{1,3}(:),[],@mean); %select measurements during specific intervals, accumulate mean to array and print zero otherwise
    isd = accumarray(inter,scantemp{1,3}(:),[],@std); %select measurements during specific intervals, accumulate standard deviation to array and print zero otherwise
    
    vmu = accumarray(inter,scantemp{1,4}(:),[],@mean);
    vsd = accumarray(inter,scantemp{1,4}(:),[],@std);
    
    
    
    
    foutarr{1,3}(inter(1):inter(end),1)=imu(inter(1):inter(end)); %prepare for printing results
    foutarr{1,4}(inter(1):inter(end),1)=isd(inter(1):inter(end));
    foutarr{1,5}(inter(1):inter(end),1)=vmu(inter(1):inter(end));
    foutarr{1,6}(inter(1):inter(end),1)=vsd(inter(1):inter(end));
    foutarr{1,7}(inter(1):inter(end),1)=1; %%flag to determine if row should be written.
    
    
    
    
    clear imu isd vmu vsd inter %save electricity kids!

  
    
    if i ==length(an_ind) %only print if  this is last file of the loop, otherwise perform print check at beginning of loop
        

        %For LBL file genesis later, we need an index with name, shortname,
        %original file  
        an_tabindex{end+1,1} = afname;%start new line of an_tabindex, and record file name
        an_tabindex{end,2} = strrep(afname,affolder,''); %shortfilename
        an_tabindex{end,3} = tabindex{an_ind(i-count),3}; %first calib data file index of first derived file in this set
        an_tabindex{end,4} = length(foutarr{1,3}); %number of rows
        an_tabindex{end,5} = 6; %number of columns
        
         
        for j=0:count
            antemp = sprintf('%s,%i',antemp,an_ind(i-count+j));
            
        end
        
        an_tabindex{end,6} = antemp; %all tabindex indicies of this set.
        
                  
        
        
        
        awID= fopen(afname,'w');
        for j =1:length(foutarr{1,3})
            
            if foutarr{1,7}(j)~=1 %check if measurement data exists on row
                fprintf(awID,'%s,%16.6f,,,,\n',foutarr{1,1}{j,1},foutarr{1,2}(j));
                
            else
                fprintf(awID,'%s,%16.6f,%14.7e,%14.7e,%14.7e,%14.7e\n',foutarr{1,1}{j,1},foutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j));
                
            end%if
            
        end%for
        
        
        
        
        
        
      
        fclose(awID);
        %clear foutarr %not really needed, will not exist outside of function anyway.
    end%if
    
    
    
    oldUTCpart1 = UTCpart1; %stuff to remember next loop iteration
    count = count +1; %increment counter
    
        

    

    
end%for main for loops
end%function










