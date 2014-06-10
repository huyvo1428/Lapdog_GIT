function []= createTAB(derivedpath,tabind,index,macrotime,fileflag,sweept)
%derivedpath   =  filepath
%tabind         = data block indices for each measurement type, array
%index          = index array from earlier creation - Ugly way to remember index
%inside function.
%fileflag       = identifier for type of data
%sweept         = start&stop times for sweep in macroblock
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

%probe = str2double(fileflag(2));


% QUALITYFLAG:
% is an 3 digit integer "DDD"
% starting at 000

% sweep during measurement  = +100
% bug during measurement    = +200
% Rotation "  "    "        = +10
% Bias change " "           = +20
%
% low sample size(for avgs) = +2
% some zeropadding (for psd)= +2


%e.g. QF = 320 -> Sweep during measurement, bug during measurement, bias change during measurement
%  QF =000 ALL OK.







dirY = datestr(index(tabind(1)).t0,'YYYY');
dirM = upper(datestr(index(tabind(1)).t0,'mmm'));
dirD = strcat('D',datestr(index(tabind(1)).t0,'dd'));
tabfolder = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD,'/');



filename = sprintf('%sRPCLAP_%s_%s_%d_%s.TAB',tabfolder,datestr(macrotime,'yyyymmdd'),datestr(macrotime,'HHMMSS'),index(tabind(1)).macro,fileflag); %%
filenamep = strrep(filename,tabfolder,'');
twID = fopen(filename,'w');

global tabindex;


%tabindex has format:
%{ ,1} filename
%{ ,2} shortfilename
%{ ,3} first index number
%{ ,4} end time(UTC)
%{ ,5} end time (S/C clock)
%{ ,6} number of columns
%{ ,7} number of rows


tabindex{end+1,1} = filename; %% Let's remember all TABfiles we create
tabindex{end,2} = filenamep; %%their shortform name
tabindex{end,3} = tabind(1); %% and the first index number



len = length(tabind);
counttemp = 0;
%tot_bytes = 0;
if(~index(tabind(1)).sweep); %% if not a sweep, do:
    
    for(i=1:len);
        trID = fopen(index(tabind(i)).tabfile);
        
        if fileflag(2) =='3'
            
            scantemp = textscan(trID,'%s%f%f%f%f','delimiter',',');
            
        else
            
            scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
        end
        
        
        %at some macros, we have measurements taken during sweeps, which leads to weird results
        %we need to find these and remove them
        
        if ~isempty(sweept)
            % don't loop if no sweep during macro or if file starts after last sweep or ends before first sweep
            if scantemp{1,2}(end)<sweept(1,1) || scantemp{1,2}(1)>sweept(2,end)
                %do nothing
            else %do something
                
                dt = scantemp{1,2}(2)-scantemp{1,2}(1); %timestep between measurements.
                
                lee= length(scantemp{1,2}(:));
                del = false(1,lee);
                
                for j =1:length(sweept(1,:))  %try to break this loop as early as possible
                    
                    if scantemp{1,2}(end)+dt <sweept(1,j) %no need to cycle through if we passed point of interest 
                        break     %(if last input is before j:th sweep start, we can safely break j-loop here)
                    end
                    
                    tmpdel=false(1,lee);
                    after  = scantemp{1,2}(:)+dt  >= sweept(1,j);   %measurement window after sweep start
                    tmpdel(after) = scantemp{1,2}(after)   <= sweept(2,j);   %before sweep ends
                    
                    del(tmpdel)=1;        %assign deletion flag to all indices that are within sweep times
                    
                    %NB: sweep stop % start time (from LBL files) seem to be roughly
                    %0.2 seconds before and after first and final measurement, so we
                    %probably won't have to increase "deletion window"
                    %NB2: above comment seems obsolete
                    
                end%for
                
                if sum(unique(del)) %delete flagged measurements, if = 1 if any delete flags, 0 otherwise
                    
                    % instead of remove, do qualityflag?
                    scantemp{1,1}(del)    = [];
                    scantemp{1,2}(del)    = [];
                    scantemp{1,3}(del)    = [];
                    scantemp{1,4}(del)    = [];
                    if fileflag(2) =='3'
                        scantemp{1,5}(del)    = [];
                    end%if
                                        
                    
                end%if delete
            end%if loop
            
               
            
        end%  sweep window deletions
        
        
        
        scanlength = length(scantemp{1,1});
        counttemp = counttemp + scanlength;
        
        if scanlength ~=0 %if file is empty/all invalid, remember last time
        timing={scantemp{1,1}{end,1},scantemp{1,2}(end)};
        end
        
        if fileflag(2) =='3'
            
            for (j=1:scanlength)       %print
                
                %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, %14.7e, 000\n'...
                ,scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),scantemp{1,5}(j));
                
            end
        else
            
            for (j=1:scanlength)       %print
                
                %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, 000\n'...
                ,scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                
            end
        end
         
        if (i==len) %finalisation

            
            tabindex{end,4}= timing{1,1}; %%remember stop time in universal time and spaceclock time
            tabindex{end,5}= timing{1,2};
            tabindex{end,6}= counttemp;
            
            
        end
        
        fclose(trID);
        clear scantemp scanlength
    end
else %% if sweep, do:
    
    filename2 = filename;
    filename2(end-6) = 'I'; %current data file name according to convention%
   
    %     if exist(filename2,'file')==2 %this doesn't work!
    %         delete('filename2');
    %     end
%     tmpf = fopen(filename2,'w');
%     fclose(tmpf); %ugly way of deleting if it exists, we need appending filewrite
     twID2 = fopen(filename2,'w');
    
    
    
    
    for(i=1:len); %read&write loop
        trID = fopen(index(tabind(i)).tabfile);
        scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
        fclose(trID); %close read file, terminated each new read iteration
        
        
        
        
        if (i==1) %do this only once + bugfix
            
            
            
            %first values are problematic, often not in the sweep at all since
            %spacecraft starts recording too early
            
            
            step1 = find(diff(scantemp{1,4}(1:end)),1,'first');
            scantemp{1,1}(1:step1)    = [];
            scantemp{1,2}(1:step1)    = [];
            scantemp{1,3}(1:step1)    = [];
            scantemp{1,4}(1:step1)    = [];
            
            
            %     [potbias, junk, ic] = unique(scantemp{1,4}(:),'stable'); %group potbias uniquely
            
            %slightly more complicated way of getting the mean
            stepnr= find(diff(scantemp{1,4}(1:end)),1,'first'); %find the number of measurements on each sweep
            inter = 1+ floor((0:1:length(scantemp{1,2})-1)/stepnr).'; %find which values to average together
            
            potbias = accumarray(inter,scantemp{1,4}(:),[],@mean); %average
            scan2temp=accumarray(inter,scantemp{1,2}(:),[],@mean); %average
            reltime = scan2temp(:)-scan2temp(1); %relative time stamps
            
  % potout = [reltime(:),potbias]; %won't work with  fprintf
            potout(1:2:2*length(reltime)) = reltime;
            potout(2:2:2*length(reltime)) = potbias;
            b1= fprintf(twID,'%14.7e, %14.7e\n',potout);
 %            dlmwrite(filename,potout,'-append','precision', '%14.7e'); %also writes \n
                
        elseif scantemp{1,4}(1) == potbias(1); %bugfix special case
        
        %first values are problematic, often not in the sweep at all since
        %spacecraft starts recording too early, and the number of first
        %values varies from file to file, so total number of rows varies
        %unless removen properly
        
        %also, we have found sweep files in the same macro that happen to
        %have the first few values on the first actual sweep step
        %if this happens in the first file (but not necessarily in the rest
        %we currently have no way of not deleting all measurements on that
        %step
        
            
            step1 = find(diff(scantemp{1,4}(1:end)),1,'first')-stepnr;
            scantemp{1,1}(1:step1)    = [];
            scantemp{1,2}(1:step1)    = [];
            scantemp{1,3}(1:step1)    = [];
            scantemp{1,4}(1:step1)    = [];
            
            
        else %normal bugfix
            
            
            step1 = find(diff(scantemp{1,4}(1:end)),1,'first');
            scantemp{1,1}(1:step1)    = [];
            scantemp{1,2}(1:step1)    = [];
            scantemp{1,3}(1:step1)    = [];
            scantemp{1,4}(1:step1)    = [];
            
        end %if first iteration +bugfix
        
        
        %
        curtemp = accumarray(inter,scantemp{1,3}(:),[],@mean);
        
        %
        %         %due to a bug, the first deleted measurements will lead to a shortage of measurements on the final sweep step
        %         leee = length(scantemp{1,3});
        %         if mod(leee,stepnr)~=0 %if bug didn't end after step completion
        %         %pad matrix with mean value of last row
        %             mooo=mod(leee,stepnr);
        %             meee = scantemp{1,3}(end-mooo+1:end);
        %            scantemp{1,3}(end+1:end+stepnr-mooo) = mean(meee);
        %         end
        %         B = reshape(scantemp{1,3}.',stepnr,length(potbias));    %I need only one transpose!
        %         curtemp = mean(B); %curtemp is now a row vector
        %         clear B mooo meee leee
        %
        
        
        
        b2= fprintf(twID2,'%s, %s, %16.6f, %16.6f, 000',scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end));
        b3= fprintf(twID2,', %14.7e',curtemp.');
        fprintf(twID2,'\n');
        
   
        
        if (i==len)
            
%             nrpots = length(curtemp);
%             nrfiles = len;
            
            tabindex(end,4:7)= {scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),length(potbias),2}; %one index for bias voltages
                        tabindex{end,8}=b1;

            
            tabindex(end+1,1:7)={filename2,strrep(filename2,tabfolder,''),tabind(1),scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),len,length(potbias)+5};
            tabindex{end,8}=b2+b3;
            %           tabindex(end+1,1:6)={filename3,strrep(filename3,tabfolder,''),tabind(1),scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),len};
            %one index for currents and two timestamps
            
            %remember stop time in universal time and spaceclock time
            %subset scantemp{1,1} is a cell array, but scantemp{1,2} is a normal array
            %%remember stop time in universal time (WITH ONLY 3 DECIMALS!)
            %and spaceclock time for sweep current data, store number of
            %rows & no of columns (+4)
        end
        
        clear scantemp;
    end
    fclose(twID2); %write file nr 2, condensed data, terminated asap
    
end
fclose(twID); %write file nr 1






end



