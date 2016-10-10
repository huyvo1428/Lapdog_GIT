function []= createTAB(derivedpath,tabind,index,macrotime,fileflag,sweept)
%function [] = createTAB(derivedpath,tabind,index,macrotime,fileflag,sweept)
% derivedpath   =  filepath
% tabind         = data block indices for each measurement type, array
% index          = index array from earlier creation - Ugly way to remember index
%                  inside function.
% macrotime      = Date & time that will be used for the filename
% fileflag       = identifier for type of data
% sweept         = start&stop times for sweep in macroblock
%    FILE GENESIS

% After Discussion 24/1 2014, updated 10/7 2014 FJ, updated 2015-06-09 EJ
% FILE CONVENTION for three file types: RPCLAP_YYMMDD_hhmmss_###_QPO.TAB
% (OR RPCLAP_YYMMDD_hhmmss_###_QPO.LBL OR RPCLAP_YYMMDD_hhmmss_BLKLIST.TAB)
% where
% ### is either:
% 	MacroID (hexadecimal number between 000-FFF)
% 	?PSD?,power spectrum of high frequency data (only for mode 'H')
% 	'FRQ',corresponding frequency list to PSD data (only for mode ?H?)
% 	Downsample period, number from 00-99 and letter U, where U is the unit (S = seconds, M = minutes, H = hours),
%
% Q= measured Quantity (?B?/?I?/?V?/?A?), where:
%
%     B = probe bias voltage, exists only for mode = S
%     I = Current, all modes
%     V = Potential, only for mode = H/L
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
% QUALITYFLAG:
% is an 3 digit integer
% from 000 (best) to 999 (worst quality)
%
% any of the following events will add to the qualityflag accordingly:
%
% Rotation "  "    "        = +10
% Bias change " "           = +20
% LDL Macro                 = +40
% Sweep during measurement  = +100
% Bug during measurement    = +200
%
% low sample size(for avgs) = +2
% zeropadding(for psd)	    = +2
% poor analysis fit	        = +1
% e.g. QF = 320 -> Sweep during measurement, bug during measurement, bias change during measurement
%      QF = 000 -> ALL OK.


macroNo = index(tabind(1)).macro;
diag = 0;
diag2 = 0;

dirY = datestr(index(tabind(1)).t0,'YYYY');
dirM = upper(datestr(index(tabind(1)).t0,'mmm'));
dirD = strcat('D',datestr(index(tabind(1)).t0,'dd'));
tabfolder = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD,'/');

% Offset handling
% Now with hardcoded current offset (possibly due to a constant stray
% current during calibration which is not present during measurements)
Offset = [];
Offset.I1L = 0;   % The old value -23E-9 is now part of pds ADC20 calibration ("Delta").
Offset.B1S = +1E-9;
%Offset.I2L = -23E-9;
Offset.I2L = 0;   % The old value -23E-9 is now part of pds ADC20 calibration ("Delta").
Offset.B2S = +6.5E-9;
Offset.I3L = 0;
Offset.V1L = 0;
Offset.V2L = 0;
Offset.V3L = 0;


% NOTE: fileflag = B1S/B2S really refers to BxS + IxS.
% For that case, CURRENTOFFSET refers to the IxS files (not the BxS files which only contain voltages).
switch fileflag     %we have detected different offset on different modes
    case 'I1L'
        if macroNo == hex2dec('604')
            CURRENTOFFSET = -12E-9 +23E-9; % Approximate new calibration offset due to moving ADC20 delta calibration to pds (all macros).
        else
            CURRENTOFFSET = Offset.I1L;
        end
    case 'B1S'
        CURRENTOFFSET = Offset.B1S;
    case 'I2L'
        if macroNo == hex2dec('604')
            CURRENTOFFSET = -12E-9 +23E-9; % Approximate new calibration offset due to moving ADC20 delta calibration to pds (all macros).
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



filename = sprintf('%sRPCLAP_%s_%s_%03x_%s.TAB', tabfolder, datestr(macrotime,'yyyymmdd'), datestr(macrotime,'HHMMSS'), macroNo, fileflag);
filenamep = strrep(filename,tabfolder,'');
twID = fopen(filename,'w');

global tabindex;  %global index
global LDLMACROS; %global constant list


%tabindex has format:
%{ ,1} filename
%{ ,2} short filename
%{ ,3} first index number
%{ ,4} end time(UTC)
%{ ,5} end time (S/C clock)
%{ ,6} number of columns
%{ ,7} number of rows
%{ ,8} number of bytes per row (including CR+LF)
%{ ,9} last index number

% NOTE: This is not the only location where tabindex is set, even for fields set here.
tabindex{end+1,1} = filename; %% Let's remember all TAB files we create
tabindex{end,2} = filenamep; %%their shortform name
tabindex{end,3} = tabind(1); %% and the first index number
tabindex{end,9} = tabind(end);  % Last "index" number.

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

                        %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\r\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                        fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, %14.7e, %03i\r\n'...
                            ,scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),scantemp{1,5}(j),qualityF);
                    end
                else

                    for (j=1:scanlength)       %print

                        %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\r\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                        fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, %03i\r\n'...
                            ,scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),qualityF);
                    end%for
                end%if fileflag
            end%if scanlength

            if (i==len) %finalisation

                fileinfo = dir(filename);
                if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
                    if delfile == 1 %doublecheck!
                        delete(filename); %will this work on any OS, any user?
                        tabindex(end,:) = []; %delete tabindex listing to prevent errors.
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



        % Read & write loop. Iterate over all files, create B*S.TAB and I*S.TAB
        for(i=1:len);   
            qualityF = 0;     % qualityfactor initialised!
            trID = fopen(index(tabind(i)).tabfile);

            if trID > 0
                scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
                fclose(trID); %close read file
            else            % if I/O error
                fprintf(1,'Error, cannot open file %s', index(tabind(i)).tabfile);
                break
            end

            step1 = index(tabind(i)).pre_sweep_samples; %some steps are not in actual sweep, but number is listed in LBL file
            step2 = find(diff(scantemp{1,4}(1:end)),1,'first');

      %     if step1 > 40 %foolproofing this after 24 June 2016 bug
      %        step1 = step2;
      %        continue; %continue passes control to the next iteration of a for or while loop. It skips any remaining statements in the body of the loop for the current iteration. The program continues execution from the next iteration. continue applies only to the body of the loop where it is called. In nested loops, continue skips remaining statements only in the body of the loop in which it occurs.
      %      end

            scantemp{1,1}(1:step1)    = [];
            scantemp{1,2}(1:step1)    = [];
            scantemp{1,3}(1:step1)    = [];
            scantemp{1,4}(1:step1)    = [];



            if (i==1) %do this only once + bugfix

                %first values are problematic, often not in the sweep at all since
                %spacecraft starts recording too early


                %[potbias, junk, ic] = unique(scantemp{1,4}(:),'stable'); %group potbias uniquely,get mean

                %slightly more complicated way of getting the mean
                nStep= find(diff(scantemp{1,4}(1:end)),1,'first'); %find the number of measurements on each sweep
                inter = 1+ floor((0:1:length(scantemp{1,2})-1)/nStep).'; %find which values to average together

                potbias = accumarray(inter,scantemp{1,4}(:),[],@mean); %average
                scan2temp=accumarray(inter,scantemp{1,2}(:),[],@mean); %average time

                reltime = scan2temp(:)-scan2temp(1); %relative time stamps

                potout(1:2:2*length(reltime)) = reltime;
                potout(2:2:2*length(reltime)) = potbias;

                b1= fprintf(twID, '%14.7e, %14.7e\r\n', potout);

%
            end %if first iteration +bugfix



            %if(step2 ~= step1 &&( step2-nStep ~= step1))
          %      fprintf(1,'old calculation method-> %d --%d <- new indexed method ',step2,step1);
          %      fprintf(1,'Error in file %s\n', index(tabind(i)).tabfile);
          %  end


            %checks if macro is LDL macro, and downsamples current measurement
            if any(ismember(macroNo,LDLMACROS)) %if macro is any of the LDL macros
                qualityF = qualityF+40; %LDL macro measurement

                %filter LDL sweep for noisy points. the last two number
                %dictate how heavy filtering is needed. 3 & 1 are good from
                %experience.

                curArray= sweepcorrection(scantemp{1,3}(:),nStep,0.1,1);

                if nStep> 1  %if nStep == 1, then nanmean will not work as intended and just output a single value
             %     curArray= sweepcorrection(scantemp{1,3}(:),potbias,nStep,3,1);
                    curArray = nanmean(curArray,1); %final downsampled product
                    qualityF = qualityF +2; %lower samplesize quality marker
                %else
                %  curArray = accumarray(inter,scantemp{1,3}(:),[],@mean,NaN);
                end



                if diag



                    A = vec2mat(curArray,nStep,NaN); %reformat curArray to matrix, fill with NaN values if needed on last steps

                    %[A,pad] = vec2mat(curArray,nSteps,NaN); %reformat curArray to matrix, fill with NaN values if needed on last steps

                    curOut=A.';

                    test1 = smooth(nanmean(curOut,1),0.08,'rloess').';
                    test_std= nanstd(test1,0);
                    largeK = 0.1;


                    figure(164)

                    plot(scantemp{1,4}(:),scantemp{1,3}(:),'g',potbias,curArray,'b',potbias,test1+test_std*largeK,'r--',potbias,test1-test_std*largeK,'r--');
                    xlabel('Vp [V]');
                    ylabel('I');
                    title('LDL Sweep filtering, factor 3 & 1, std*0.2, 0.2 span');
                    grid on;
                    legend('input','output','cutoff from rloess smoothing','Location','North')

                    figure(163);

                    subplot(2,2,1)
                    plot(scantemp{1,4}(:),scantemp{1,3}(:),'g',potbias,curArray,'b',potbias,test1+test_std*1,'r--',potbias,test1-test_std*1,'r--');
                    xlabel('Vp [V]');
                    ylabel('I');
                    title('LDL Sweep filtering, factor 3 & 1, 68% confidence, 68% confidence');
                    grid on;
                    legend('input','output','cutoff from rloess smoothing','Location','North')

                    % curTmp = accumarray(inter,scantemp{1,3}(:),[],@mean,NaN);

                    subplot(2,2,2)
                    plot(scantemp{1,4}(:),scantemp{1,3}(:),'b',potbias,(mean(scantemp{1,3}(:)) + 2*std(scantemp{1,3}(:))),'r',potbias,(mean(scantemp{1,3}(:)) - 2*std(scantemp{1,3}(:))),'r')
                    %plot(potbias,curTmp)

                    %hold all
                    %      plot(potbias,(mean(scantemp{1,3}(:)) + 3*std(scantemp{1,3}(:))));
                    xlabel('Vp [V]');
                    ylabel('I');
                    title('unedited sweep, old filter');
                    grid on;


                    subplot(2,2,3)
                    plot(potbias,nanmean(sweepcorrection(scantemp{1,3}(:),nStep,3,3),1))
                    xlabel('Vp [V]');
                    ylabel('I');
                    title('unedited sweep, factor 3&3 99% confidence, 99%confidene ');
                    grid on;

                    subplot(2,2,4)
                    plot(potbias,sweepcorrection(scantemp{1,3}(:),nStep,2,0.8),'bo',potbias,curArray,'r')
                    %        plot(potbias,curArray);
                    xlabel('Vp [V]');
                    ylabel('I');
                    title('unedited sweep, factor 1&0.8');
                    grid on;



                end

            else
                curArray = accumarray(inter,scantemp{1,3}(:),[],@mean,NaN);


            end%if LDL macro check & downsampling



            curArray=curArray+ CURRENTOFFSET;

            b2 = fprintf(twID2,'%s, %s, %16.6f, %16.6f, %03i',scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end),qualityF);
            b3 = fprintf(twID2,', %14.7e',curArray.'); %some steps could be "NaN" values if LDL macro
            b4 = fprintf(twID2, '\r\n');

            %%Finalise

            if (i==len) %if last iteration

                tabindex(end,4:7)= {scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),length(potbias),2}; %one index for bias voltages
                tabindex{end,8}=b1;


                tabindex(end+1,1:7)={filename2,strrep(filename2,tabfolder,''),tabind(1),scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),len,length(potbias)+5};
                tabindex{end,8} = b2+b3+b4;
                tabindex{end,9} = tabind(end);
                %           tabindex(end+1,1:6)={filename3,strrep(filename3,tabfolder,''),tabind(1),scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),len};
                %one index for currents and two timestamps

                %remember stop time in universal time and spaceclock time
                %subset scantemp{1,1} is a cell array, but scantemp{1,2} is a normal array
                %%remember stop time in universal time (WITH ONLY 3 DECIMALS!)
                %and spaceclock time for sweep current data, store number of
                %rows & no of columns (+4)
            end

            clear scantemp;
        end  % loop to create B*S.TAB and I*S.TAB (?)
        fclose(twID2); %write file nr 2, condensed data, terminated asap

    end
    fclose(twID); %write file nr 1



catch err


    fprintf(1,'\nlapdog:createTAB error message:%s\n',err.message);


    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i,',err.stack(i).name,err.stack(i).line);
        end
    end

    fprintf(1,'\nlapdog: skipping file, continuing...\n');
    return


end


end
