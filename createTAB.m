function []= createTAB(derivedpath,tabind,index,macrotime,fileflag)
%derivedpath   =  filepath
%tabind         = data block indices for each measurement type, array
%index          = index array from earlier creation - Ugly way to remember index
%inside function.
%fileflag       = identifier for type of data

%    FILE GENESIS

%After Discussion 24/1 2014
%FILE CONVENTION: RPCLAP_YYMMDD_hhmmss_MMM_QPO
% MMM = MacroID,
% Q= Measured quantity (B/I/V/A)
% P=Probe number(1/2/3),
% O = Mode (H/L/S)
%
% B = probe bias voltage, exists only for mode = S
% I = Current , all modes
% V = Potential , only for mode = H/L
% A = Derived (analysed) variables results, all modes
%
% H = High frequency measurements
% L = Low frequency measurements
% S = Voltage sweep measurements 

% TIME STAMP example : 2011-09-05T13:45:20.026075
%YYYY-MM-DDThh:mm:ss.ffffff % double[s],double[A],double [V],int


dirY = datestr(index(tabind(1)).t0,'YYYY');
dirM = upper(datestr(index(tabind(1)).t0,'mmm'));
dirD = strcat('D',datestr(index(tabind(1)).t0,'dd'));
tabfolder = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD,'/');



filename = sprintf('%sRPCLAP_%s_%s_%d_%s.TAB',tabfolder,datestr(macrotime,'yyyymmdd'),datestr(macrotime,'HHMMSS'),index(tabind(1)).macro,fileflag); %%
filenamep = strrep(filename,tabfolder,'');
twID = fopen(filename,'w');

global tabindex;
tabindex{end+1,1} = filename; %% Let's remember all TABfiles we create
tabindex{end,2} = filenamep; %%their shorter name
tabindex{end,3} = tabind(1); %% and the first index number



len = length(tabind);
counttemp = 0;
%tot_bytes = 0;
if(~index(tabind(1)).sweep); %% if not a sweep, do:
    for(i=1:len);
        trID = fopen(index(tabind(i)).tabfile);
        
        scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
        scanlength = length(scantemp{1,1});
        counttemp = counttemp + scanlength;
        
      
       % bytes = 0;
        
       
       
        for (j=1:scanlength)        

            %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
            fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\n',scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
            %fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
        end
        
        
        
        
        
        
        if (i==len)
            tabindex{end,4}= scantemp{1,1}{end,1}; %%remember stop time in universal time and spaceclock time
            tabindex{end,5}= scantemp{1,2}(end); %subset scantemp{1,1} is a cell array, but scantemp{1,2} is a normal array
            tabindex{end,6}= counttemp;
            %tabindex{end,7}= tot_bytes;
        end
        
        fclose(trID);
        clear scantemp scanlength
        
        
        
    end
else %% if sweep, do:
    
    filename2 = filename;
    filename2(end-6) = 'I'; %current data file name according to convention%   
    filename3 = filename;
    filename3(end-6) = 'A'; %A for derived  analysis
    
%     if exist(filename2,'file')==2 %this doesn't work!
%         delete('filename2');
%     end
    tmpf = fopen(filename2,'w');
    fclose(tmpf); %ugly way of deleting if it exists, we need appending filewrite
    tmpf = fopen(filename3,'w');
    fclose(tmpf); %ugly way of deleting if it exists, we need appending filewrite
    condfile = fopen(filename2,'a');
 
    
    
    
    for(i=1:len); %read&write loop
        trID = fopen(index(tabind(i)).tabfile);
        scantemp = textscan(trID,'%s%f%f%f','delimiter',',');  
        
        %first values are not in the defined sweep, delete all rows will cause trouble if first
        %potential values change during 4-5 time periods
        step1 = find(diff(scantemp{1,4}(1:end)),1,'first');       

%         scantemp{1,:}(1:step1)    = []; didnt work..., do separate:
        scantemp{1,1}(1:step1)    = []; 
        scantemp{1,2}(1:step1)    = [];
        scantemp{1,3}(1:step1)    = [];
        scantemp{1,4}(1:step1)    = [];


        
        
        
        if (i==1) %do this only once
            stepnr= find(diff(scantemp{1,4}(1:end)),1,'first'); %find the number of measurements on each sweep
            
            
            %downsample sweep
            
            scan2temp =downsample(scantemp{1,2},stepnr); %needed once
            potbias =downsample(scantemp{1,4},stepnr); %needed once
            
            potlength=length(potbias);
%             potbias = scan2temp{1,4}(1:end);
            reltime = scan2temp(:)-scan2temp(1);
            pottemp = [reltime(:),potbias];
            dlmwrite(filename,pottemp,'-append','precision', '%14.7e'); %also writes \n
            
        end
        
        %due to a bug, the first deleted measurements will lead to a shortage of measurements on the final sweep step 
        %also, the first erroneous measurements + the number of measurements on
        %the final step is equal to 8.
        
        
        leee = length(scantemp{1,3});
        
        if mod(leee,stepnr)~=0 %if bug didn't end after step completion
            
        %otherwise pad matrix with mean value of last row
            mooo=mod(leee,stepnr);
            meee = scantemp{1,3}(end-mooo+1:end);
            scantemp{1,3}(end+1:end+stepnr-mooo) = mean(meee);
            
        end


        
        B = reshape(scantemp{1,3}.',stepnr,potlength);    %I need only one transpose!
        curtemp = mean(B); %curtemp is now a row vector
        clear B mooo meee 
%        scantemp{1,3}(:) = [];
        
        
        %     curtemp = curtemp.'; %transpose..
        fprintf(condfile,'%s,%s,%16.6f,%16.6f,',scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end));
        dlmwrite(filename2,curtemp,'-append','precision', '%14.7e'); %appends to end of row, column 4. pretty neat.
        
        
        
        
        %excellent time for some analysis!
        %
        %         filename3 = filename;
        %         filename3(end-6) = 'A'; %A for derived  analysis
        %
        derived = an_swp(potbias,curtemp,scantemp{1,2}(1,1),filename(end-5));
        % dlmwrite(filename3,derived,'-append','precision','%14,7e');
        dlmwrite(filename3,derived,'-append');
        
    
        if (i==len)
            scanlength = length(scantemp{1,1});

            tabindex(end,4:6)= {scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),scanlength}; %one index for bias voltages
            tabindex(end+1,1:7)={filename2,strrep(filename2,tabfolder,''),tabind(1),scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),len,scanlength};
 %           tabindex(end+1,1:6)={filename3,strrep(filename3,tabfolder,''),tabind(1),scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),len};
            %one index for currents and two timestamps
            
            %remember stop time in universal time and spaceclock time
            %subset scantemp{1,1} is a cell array, but scantemp{1,2} is a normal array
            %%remember stop time in universal time (WITH ONLY 3 DECIMALS!) 
            %and spaceclock time for sweep current data, store number of 
            %rows & no of columns (+4)
        end
        fclose(trID); %close read file, terminated each new read iteration
        clear scantemp;
    end
    fclose(condfile); %write file nr 2, condensed data, terminated asap
    
end
fclose(twID); %write file nr 1


end



