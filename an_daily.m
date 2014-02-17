%an_daily



function []= an_daily(an_ind,flag1,p,flag3,tabindex,intval)
count = 0;
oldUTCpart1 ='shirley,you must be joking';


foutarr=cell(1,6);

%fprintf(awID,'%s,%16.6f,,,,\n',UTC_time,(0.5*intval+tday0+(j-1)*intval));
%outputarr =
%





for i=1:length(an_ind)
    
    arID = fopen(tabindex{an_ind(i),1},'r');
    scantemp=textscan(arID,'%s%f%f%f','delimiter',',');
    fclose(arID);
    
    UTCpart1 = scantemp{1,1}{1,1}(1:11);
    
    
    i
    
    if count == 1 && ~strcmp(UTCpart1,oldUTCpart1) %%not the first time, and we have a new file going, let's print!
        
        
        awID= fopen(afname,'w');
        %         'first loop (multiple files!)'
        %         tic
        %         for j =1:length(foutarr{1,1})
        %
        %
        %
        %
        %             % fprintf(awID,'%s,%16.6f,%14.7e,%14.7e,%14.7e,%14.7e\n',UTC_time,tt(j-inter(1)+1),imu(j),isd(j),vmu(j),vsd(j));
        %             fprintf(awID,'%s,%16.6f,%14.7e,%14.7e,%14.7e,%14.7e\n',foutarr{1,1}{j,1},foutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j));
        %
        %         end%for
        %         toc
        
        for j =1:length(foutarr{1,3})
            if (foutarr{1,4}(j)==0)
                fprintf(awID,'%s,%16.6f,,,,\n',foutarr{1,1}{j,1},foutarr{1,2}(j));
                
            else
                fprintf(awID,'%s,%16.6f,%14.7e,%14.7e,%14.7e,%14.7e\n',foutarr{1,1}{j,1},foutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j));
                
                
                
            end%if
            
            
        end%for
        
        
        
        fclose(awID);
        count = 0;
        clear foutarr
        foutarr=cell(1,6);
    end%if print new file
    
    
    
    ah =str2double(scantemp{1,1}{1,1}(12:13));
    am =str2double(scantemp{1,1}{1,1}(15:16));
    as =str2double(scantemp{1,1}{1,1}(18:end)); %including fractions of seconds
    hms = ah*3600 + am*60 + as;
    
    tday0=scantemp{1,2}(1)-hms; %%UTC and Spaceclock must be correctly defined
    
    
    t=scantemp{1,2}(:);
    tt = ( tday0+intval*floor((t(1)-tday0)/intval):1*intval:tday0+intval*ceil((t(end)-tday0)/intval) )'; %tidst?mplar med 32 sekunder mellan varje st?mpel, startar p? en multipel av 32 p? dygnet
    %tt = ( floor(t(1)):1*spacing:ceil(t(end)) )';
    
    % //        I would do this in three fully vectorized lines of code. First, if the breaks were arbitrary and potentially unequal in spacing,
    %//I would use histc to determine which intervals the data series falls in. Given they are uniform, just do this:
    
    
    inter = 1 + floor((t - tday0)/intval); %prepare subset selection to accumarray
    
    
    
    %// if the elements of t were not known to be sorted, I would have used min(t) instead of t(1). Having done that, use accumarray to reduce the results into a mean and standard deviation.
    
    
    
    
    imu = accumarray(inter,scantemp{1,3}(:),[],@mean);
    isd = accumarray(inter,scantemp{1,3}(:),[],@std);
    
    vmu = accumarray(inter,scantemp{1,4}(:),[],@mean);
    vsd = accumarray(inter,scantemp{1,4}(:),[],@std);
    
    
    
    
    foutarr{1,3}(inter(1):inter(end),1)=imu(inter(1):inter(end));
    foutarr{1,4}(inter(1):inter(end),1)=isd(inter(1):inter(end));
    foutarr{1,5}(inter(1):inter(end),1)=vmu(inter(1):inter(end));
    foutarr{1,6}(inter(1):inter(end),1)=vsd(inter(1):inter(end));
    
    clear imu isd vmu vsd inter %save electricity kids!
    
    
    
    % UTCpart1 = cellfun(@(x) x(1:11),scantemp{1,1}(:,1),'un',0);
    
    
    
    
    if count == 0 %first time going through loop! initialise things!
        afname = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),1}(end-6:end),sprintf('%s%i%s%iSEC.TAB',flag1,p,flag3,intval));
        
        for j=1:3600*24/intval;
            
            UTCpart2= datestr((0.5*intval+(j-1)*intval)/(24*60*60), 'HH:MM:SS.FFF');
            UTC_time =sprintf('%s%s',UTCpart1,UTCpart2);
            
            foutarr{1,1}{j,1} = UTC_time;
            foutarr{1,2}(j) = 0.5*intval+tday0+(j-1)*intval;
            %         foutarr{1,3}(j) = []; shouldn't be needed
            %         foutarr{1,4}(j) = [];
            %         foutarr{1,5}(j) = [];
            %         foutarr{1,6}(j) = [];
            
            
            
            
            
            %     fprintf(awID,'%s,%16.6f,,,,\n',UTC_time,(0.5*intval+tday0+(j-1)*intval);
        end
        
    end
    
    oldUTCpart1 = UTCpart1;
    count = 1;
    
    
    
    if i ==length(an_ind) %Let's print before the function ends!
        
        
        
        awID= fopen(afname,'w');
        %         'first loop'
        %
        %         tic
        %         for j =1:length(foutarr{1,1})
        %
        %
        %
        %
        %             % fprintf(awID,'%s,%16.6f,%14.7e,%14.7e,%14.7e,%14.7e\n',UTC_time,tt(j-inter(1)+1),imu(j),isd(j),vmu(j),vsd(j));
        %             fprintf(awID,'%s,%16.6f,%14.7e,%14.7e,%14.7e,%14.7e\n',foutarr{1,1}{j,1},foutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j));
        %
        %         end%for
        %         toc
        %         'second loop!'
        %
     
        for j =1:length(foutarr{1,3})
            
            if foutarr{1,4}(j)==0
                fprintf(awID,'%s,%16.6f,,,,\n',foutarr{1,1}{j,1},foutarr{1,2}(j));
                
            else
                fprintf(awID,'%s,%16.6f,%14.7e,%14.7e,%14.7e,%14.7e\n',foutarr{1,1}{j,1},foutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j));
                   
            end%if
            
        end%for
        
        fclose(awID);
        clear foutarr
        
        
        
        
    end%if
    
    
end%for main for loops
end%function










