function []= createTAB(derivedpath,tabind,index,macrotime,fileflag,sweept)
%function [] = createTAB(derivedpath,tabind,index,macrotime,fileflag,sweept)
%derivedpath   =  filepath
%tabind         = data block indices for each measurement type, array
%index          = index array from earlier creation - Ugly way to remember index
%inside function.
%fileflag       = identifier for type of data
%sweept         = start&stop times for sweep in macroblock
%    FILE GENESIS

% After Discussion 24/1 2014, updated 10/7 2014 FJ
% FILE CONVENTION for three file types: RPCLAP_YYMMDD_hhmmss_###_QPO.TAB
% (OR RPCLAP_YYMMDD_hhmmss_###_QPO.LBL OR RPCLAP_YYMMDD_hhmmss_BLKLIST.TAB)
% where
% ### is either:
% 	MacroID (number between 000-999)
% 	?PSD?,power spectrum of high frequency data (only for mode 'H')
% 	'FRQ',corresponding frequency list to PSD data (only for mode ?H?)
% 	Downsample period, number from 00-99 and letter U, where U is the unit (S = seconds, M = minutes, H = hours),
%
% Q= measured Quantity (?B?/?I?/?V?/?A?), where:
%
%     B = probe bias voltage, exists only for mode = S
%     I = Current , all modes
%     V = Potential , only for mode = H/L
%     A = Derived (analysed) variables results, exists only for mode = S
%
% P= Probe number(1/2/3),   (Probe 3 = combined Probe 1 & Probe 2 measurement)
%
% O = mOde ('H'/'L'/'S'/'D')
%
%     H = High frequency measurements
%     L = Low frequency measurements
%     S = Voltage sweep measurements
%     D = low frequency downsampled measurements,
%
% and Y= year, M= month, D = day, h =hour, m = minute , s = second
%
%
% 	QUALITYFLAG:
% is an 3 digit integer
% from 000 (best) to 999 (worst quality)
%
% any of the following events will add to the qualityflag accordingly:
%
% sweep during measurement  = +100
% bug during measurement    = +200
% Rotation "  "    "        = +10
% Bias change " "           = +20
% LDL Macro                 = +40
%
% low sample size(for avgs) = +2
% zeropadding(for psd)	  = +2
% poor analysis fit	  = +1


%e.g. QF = 320 -> Sweep during measurement, bug during measurement, bias change during measurement
%  QF =000 ALL OK.


macroNo = index(tabind(1)).macro;
diag = 0;
diag2 = 0;

dirY = datestr(index(tabind(1)).t0,'YYYY');
dirM = upper(datestr(index(tabind(1)).t0,'mmm'));
dirD = strcat('D',datestr(index(tabind(1)).t0,'dd'));
tabfolder = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD,'/');

%offset handling
% Now with hardcoded current offset (possibly due to a constant stray
% current during calibration which is not present during measurements)
Offset = [];
Offset.I1L = -23E-9;
Offset.B1S = +1E-9;
Offset.I2L = -23E-9;
Offset.B2S = +6.5E-9;
Offset.I3L = 0;
Offset.V1L = 0;
Offset.V2L = 0;
Offset.V3L = 0;


switch fileflag     %we have detected different offset on different modes
    case 'I1L'
        if macroNo == 604
            CURRENTOFFSET = -12E-9;
        else
            CURRENTOFFSET = Offset.I1L;
        end
    case 'B1S'
        CURRENTOFFSET = Offset.B1S;
    case 'I2L'
        if macroNo == 604
            CURRENTOFFSET = -12E-9;
        else
            CURRENTOFFSET = Offset.I2L;
        end
    case 'B2S'
        CURRENTOFFSET = Offset.B2S;
    otherwise
        CURRENTOFFSET = 0;
end
%
%
% CURRENTOFFSET = 0;
% CURRENTO1 = 0;
% CURRENTO2 = 0;
%
% if fileflag(2) =='1'
%     CURRENTOFFSET = +1E-9;
% elseif fileflag(2) =='2'
%     CURRENTOFFSET = 6.5E-9;
% elseif fileflag(2) =='3'
%     CURRENTO1 = +1E-9;
%     CURRENTO2 = 6.5E-9;
% end
% if(~index(tabind(1)).sweep) % if not a sweep
%     CURRENTOFFSET = 0;
%     CURRENTO1 = 0;
%     CURRENTO2 = 0;
% end



filename = sprintf('%sRPCLAP_%s_%s_%d_%s.TAB',tabfolder,datestr(macrotime,'yyyymmdd'),datestr(macrotime,'HHMMSS'),macroNo,fileflag); %%
filenamep = strrep(filename,tabfolder,'');
twID = fopen(filename,'w');

global tabindex;  %global index
global LDLMACROS; %global constant list


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
delfile = 1;

try
    %tot_bytes = 0;
    if(~index(tabind(1)).sweep); %% if not a sweep, do:
        
        for(i=1:len);
            qualityF = 0;     % qualityfactor initialised!
            trID = fopen(index(tabind(i)).tabfile);
            
            if trID < 0
                fprintf(1,'Error, cannot open file %s', index(tabind(i)).tabfile);
                break
            end % if I/O error
            
            
            
            
            if fileflag(2) =='3' % read file probe 3
                
                scantemp = textscan(trID,'%s%f%f%f%f','delimiter',',');
                
                
                %apply offset, but keep it in cell array format.
                if fileflag(1) =='V'  %for macro 700,701,702,705,706
                    scantemp(:,3)=cellfun(@(x) x+Offset.V1L,scantemp(:,3),'un',0);
                    scantemp(:,4)=cellfun(@(x) x+Offset.V2L,scantemp(:,4),'un',0);
                else  %hypothetically, we could have I1-I2. (no current macro)
                    scantemp(:,3)=cellfun(@(x) x+CURRENTOFFSET,scantemp(:,3),'un',0);
                end
                
                
            else %other probes
                
                
                scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
                
                %apply offset, but keep it in cell array format.
                scantemp(:,3) =cellfun(@(x) x+CURRENTOFFSET,scantemp(:,3),'un',0);
                
            end
            
            %at some macros, we have measurements taken during sweeps, which leads to weird results
            %we need to find these and remove them
            
            if ~isempty(sweept)
                
                lee= length(scantemp{1,2}(:));
                del = false(1,lee);
                
                
                if scantemp{1,2}(end)<sweept(1,1) || scantemp{1,2}(1)>sweept(2,end)
                    
                    %all measurements before first sweep or after last sweep.
                else
                    
                    
                    
                    tol=sweept(2,1)-sweept(1,1);
                    sweept2=sweept(1,:)+tol/2;
                    %'ismember time:'
                    del=ismemberf(scantemp{1,2}(:),sweept2,'tol',tol);
                    
                    
                    
                    if sum(unique(del)) %is zero or one
                        
                        % instead of remove, do qualityflag?
                        scantemp{1,1}(del)    = [];
                        scantemp{1,2}(del)    = [];
                        scantemp{1,3}(del)    = [];
                        scantemp{1,4}(del)    = [];
                        if fileflag(2) =='3'
                            scantemp{1,5}(del)    = [];
                        end
                        
                    end%if
                end
                
                
            end%  sweep window deletions
            
            
            
            scanlength = length(scantemp{1,1});
            counttemp = counttemp + scanlength;
            
            if scanlength ~=0 %if not file is empty/all invalid
                delfile = 0; %file will not be deleted
                timing={scantemp{1,1}{end,1},scantemp{1,2}(end)}; %remember last timers
                
                
                if fileflag(2) =='3'
                    
                    for (j=1:scanlength)       %print
                        
                        %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                        fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, %14.7e, %03i\n'...
                            ,scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),scantemp{1,5}(j),qualityF);
                    end
                else
                    
                    for (j=1:scanlength)       %print
                        
                        %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                        fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, %03i\n'...
                            ,scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),qualityF);
                    end%for
                end%if fileflag
            end%if scanlength
            
            if (i==len) %finalisation
                
                fileinfo = dir(filename);
                if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
                    if delfile == 1 %doublecheck!
                        delete(filename); %will this work on any OS, any user?
                    end
                    
                else
                    tabindex{end,4}= timing{1,1}; %%remember stop time in universal time and spaceclock time
                    tabindex{end,5}= timing{1,2}; %remember that obt =/= SCT
                    tabindex{end,6}= counttemp;
                end
                
            end
            
            fclose(trID);
            clear scantemp scanlength
        end
    else %% if sweep, do:
        
        filename2 = filename;
        filename2(end-6) = 'I'; %current data file name according to convention%
        
        %     tmpf = fopen(filename2,'w');
        %     fclose(tmpf); %ugly way of deleting if it exists, we need appending filewrite
        twID2 = fopen(filename2,'w');
        
        
        
        
        for(i=1:len); % Read & write loop. Iterate over selected files in "index" and simultaneously rows in BxS file.
            qualityF = 0;     % qualityfactor initialised!
            trID = fopen(index(tabind(i)).tabfile);
            
            if trID > 0
                scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
                fclose(trID); %close read file
            else
                fprintf(1,'Error, cannot open file %s', index(tabind(i)).tabfile);
                break
            end % if I/O error
            % t0 =scantemp{1,2}(1); %absolute S/C start of measurements for each file.
            if (i==1) % if first iteration ... Do this only once + bugfix
                
                %first values are problematic, often not in the sweep at all since
                %spacecraft starts recording too early
                
                
                step1 = find(diff(scantemp{1,4}(1:end)),1,'first'); %index of first step
                scantemp{1,1}(1:step1)    = [];
                scantemp{1,2}(1:step1)    = [];
                scantemp{1,3}(1:step1)    = [];
                scantemp{1,4}(1:step1)    = [];
                
                
                %[potbias, junk, ic] = unique(scantemp{1,4}(:),'stable'); %group potbias uniquely,get mean
                
                %slightly more complicated way of getting the mean
                nStep= find(diff(scantemp{1,4}(1:end)),1,'first');  % Find the number of consecutive measurements on the same bias voltage on each sweep.
                inter = 1+ floor((0:1:length(scantemp{1,2})-1)/nStep).'; %find which values to average together
                
                potbias = accumarray(inter,scantemp{1,4}(:),[],@mean); %average
                scan2temp=accumarray(inter,scantemp{1,2}(:),[],@mean); %average time
                
                reltime = scan2temp(:)-scan2temp(1); %relative time stamps
                
                potout(1:2:2*length(reltime)) = reltime;
                potout(2:2:2*length(reltime)) = potbias;
                
                b1= fprintf(twID,'%14.7e, %14.7e\n',potout);
                
            elseif scantemp{1,4}(1) == potbias(1); %bugfix special case
                
                %first values are problematic, often not in the sweep at all since
                %spacecraft starts recording too early, and the number of first
                %values varies from file to file, so total number of rows varies
                %unless removed properly
                
                %also, we have found sweep files in the same macro that happen to
                %have the first few values on the first actual sweep step
                %if this happens in the first file (but not necessarily in the rest
                %we currently have no way of not deleting all measurements on that
                %step
                
                step1 = find(diff(scantemp{1,4}(1:end)),1,'first')-nStep;
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
            
            
            
            %checks if macro is LDL macro, and downsamples current measurement
            if any(ismember(macroNo,LDLMACROS)) %if macro is any of the LDL macros
                qualityF = qualityF+40; %LDL macro measurement
                
                curCorr= sweepcorrection(scantemp{1,3}(:),potbias,nStep,3,1);
                curArray = nanmean(curCorr); %final downsampled product
                qualityF = qualityF +2; %lower samplesize
                
                
                if diag
                    
                    figure(163);
                    
                    subplot(2,2,1)
                    plot(potbias,curArray);
                    xlabel('Vp [V]');
                    ylabel('I');
                    title('edited sweep, factor 3 & 1, 99% confidence, 60% confidence');
                    grid on;
                    
                    % curTmp = accumarray(inter,scantemp{1,3}(:),[],@mean,NaN);
                    
                    subplot(2,2,2)
                    plot(scantemp{1,4}(:),scantemp{1,3}(:),'b',potbias,(mean(scantemp{1,3}(:)) + 2*std(scantemp{1,3}(:))),'r',potbias,(mean(scantemp{1,3}(:)) - 2*std(scantemp{1,3}(:))),'r')
                    %plot(potbias,curTmp)
                    
                    %hold all
                    %      plot(potbias,(mean(scantemp{1,3}(:)) + 3*std(scantemp{1,3}(:))));
                    xlabel('Vp [V]');
                    ylabel('I');
                    title('unedited sweep');
                    grid on;
                    
                    
                    subplot(2,2,3)
                    plot(potbias,nanmean(sweepcorrection(scantemp{1,3}(:),potbias,nStep,3,3)))
                    xlabel('Vp [V]');
                    ylabel('I');
                    title('unedited sweep, factor 3&3 99% confidence, 99%confidene ');
                    grid on;
                    
                    subplot(2,2,4)
                    plot(potbias,nanmean(sweepcorrection(scantemp{1,3}(:),potbias,nStep,2,0.8)),'b',potbias,curArray,'r')
                    %        plot(potbias,curArray);
                    xlabel('Vp [V]');
                    ylabel('I');
                    title('unedited sweep, factor 2&0.8');
                    grid on;
                    
                end
                
            else
                curArray = accumarray(inter,scantemp{1,3}(:),[],@mean,NaN);  % Calculate means of current measurements for identical (consecutive) bias voltages.

            end%if LDL macro check & downsampling
            
            %
            %         %%LET'S PRINT!
            %         figure(1)
            %         plot(1:length(curArray),curArray,'b',1:length(curArray),curArray+CURRENTOFFSET,'r',1:length(curArray),0,'og')
            %         grid on;
            %         axis([0 200 -9E-9 10E-9]);
            %
            
            curArray=curArray+ CURRENTOFFSET;
            
            b2= fprintf(twID2,'%s, %s, %16.6f, %16.6f, %03i',scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end),qualityF);
            b3= fprintf(twID2,', %14.7e',curArray.'); % Some steps could be "NaN" values if LDL macro.
            fprintf(twID2,'\n');
            
            %%Finalise
            
            if (i==len)    % if last iteration ...
                
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
        
    end %% if (not sweep) ... else ... end
    fclose(twID); %write file nr 1
    
    
    
catch err
    
    
    fprintf(1,'\nlapdog:createTAB error message:%s\n',err.message);
    
    
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i,',err.stack(i).name,err.stack(i).line);
        end
    end
    
    fprintf(1,'\nlapdog: skipping file, continuing...');
    return
    
    
end


end

