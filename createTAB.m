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
% sweep during measurement  = +100
% bug during measurement    = +200
% Rotation "  "    "        = +10
% Bias change " "           = +20
% LDL Macro                 = +40
%
% low sample size(for avgs) = +2
% zeropadding(for psd)	  = +2
% poor analysis fit	  = +1
% e.g. QF = 320 -> Sweep during measurement, bug during measurement, bias change during measurement
%  QF =000 ALL OK.

%globals
global MISSING_CONSTANT;
global tabindex;  %global index
global LDLMACROS; %global constant list
global WOL V2C%from preamble, here's all start & stop times


try
macroNo = index(tabind(1)).macro;
diag = 0;
diag2 = 0;

dirY = datestr(index(tabind(1)).t0,'YYYY');
dirM = upper(datestr(index(tabind(1)).t0,'mmm'));
dirD = strcat('D',datestr(index(tabind(1)).t0,'dd'));
tabfolder = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD,'/');


%FKJN Offset correction no longer needed 6/3 2018
% % Offset handling
% % Now with hardcoded current offset (possibly due to a constant stray
% % current during calibration which is not present during measurements)
% Offset = [];
% Offset.I1L = 0;   % The old value -23E-9 is now part of pds ADC20 calibration ("Delta").
% %Offset.B1S = +1E-9;
% %Offset.I2L = -23E-9;
% Offset.I2L = 0;   % The old value -23E-9 is now part of pds ADC20 calibration ("Delta").
% %Offset.B2S = +6.5E-9; These values are from  an incorrectly applied old 4kHZ calibration of
% %8kHZ sweeps. They should also be applied to HF data.
% Offset.I3L = 0;
% Offset.V1L = 0;
% Offset.V2L = 0;
% Offset.V3L = 0;
% 
% 
% %Edit FKJN 26e Sept 2016 4/8 khz filter offset calibration. should be moved to pds soon.
% %global of8khzfilterMacros;
% % of4khzfilterMacros = hex2dec({'410','411','412','415','416','417','612','613','615','616','710','910'});    % NOTE: Must be cell array with strings for hex2dec ({} not []).
% % if any(ismember(macroNo,of4khzfilterMacros)) %if macro is any of the LDL macros
% %    Offset.B1S = 0; %calibration from macro 104 is on 4kHZ filters, so these macros are fine and treated in pds
% %    Offset.B2S = 0; %calibration from macro 104 is on 4kHZ filters, so these macros are fine and treated in pds
% %    fprintf(1,'NO 4khz correction macro was %X',macroNo);
% % 
% % else
% %    Offset.B1S = 1.4*1E-9*20000/65535; %0.43 nA
% %    Offset.B2S = 25.35*1E-9*20000/65535;%7.74 nA
% %    %note that old calibration was -1E-9 and -6.5E-9. Maybe due to inexactness of determination, or a temporal thing. 
% %    fprintf(1,'YES 4khz correction macro was %X',macroNo);
% % 
% % end
% % 8 kHz-filter calibration offsets are hereafter handled by pds (takes high-gain/low-gain, density/E field mode, ADC16/ADC20) into account.
% % They should therefore be zero here. /Erik P G Johansson 2017-05-17
% Offset.B1S = 0;
% Offset.B2S = 0;
% 
% Offset.I1H = Offset.B1S;
% Offset.I2H = Offset.B2S; %these offsets are due to a 4/8khz filter calibration.
%     
% NOTE: fileflag = B1S/B2S really refers to BxS + IxS.
% For that case, CURRENTOFFSET refers to the IxS files (not the BxS files which only contain voltages).

 %   case 'I2L'
       % corr_factor_710= 13/16;
%        corr_factor_710= 4/5;
%        CURRENTOFFSET = Offset.I2L;
        %Edit  FKJN 26e Sept 2016, well in time for EOM
        % We have some problem with downsampling on flight S/W, only noticable when
        % downsampling is low (especially on macro 710, 910). This old macro 604 offset calibration should
        % probably have been taken care of with a 2/3 factor or
        % something of the like. we'll see
%         if macroNo == hex2dec('604')
%             CURRENTOFFSET = -12E-9 +23E-9; % Approximate new calibration offset due to moving ADC20 delta calibration to pds (all macros).
%         else
%             CURRENTOFFSET = Offset.I2L;
%         end
    %FKJN Offset correction no longer needed 6/3 2018

% ma_corr_factor= 4/5;
% 
% switch fileflag     %we have detected different offset on different modes
%     case 'I1H'        
%         CURRENTOFFSET = Offset.I1H; %...=Offset.B1S
%         ma_corr_factor= 1;
%     case 'I2H'        
%         CURRENTOFFSET = Offset.I2H;%...=Offset.B2S
%         ma_corr_factor= 1;
%     case 'B1S'
%         CURRENTOFFSET = Offset.B1S;
% 
%     case 'B2S'
%         CURRENTOFFSET = Offset.B2S;        
% 
%     otherwise %I3H,V1L,V2L,V3L
%               
%         %FKJN test implementation
% %          if macroNo == hex2dec('604')
% %              ma_corr_factor = 2/3; %test
% %          end
%             
%         CURRENTOFFSET = 0;
%         
% end


%fprintf(1,'CURRENTOFFSET = %e \n',CURRENTOFFSET);

% I only think I need this for sweep data (since it's averaged in this
% function)

 


filename = sprintf('%sRPCLAP_%s_%s_%03x_%s.TAB', tabfolder, datestr(macrotime,'yyyymmdd'), datestr(macrotime,'HHMMSS'), macroNo, fileflag);
filenamep = strrep(filename,tabfolder,'');
twID = fopen(filename,'w');

%tabindex has format:
%{ ,1} filename
%{ ,2} shortfilename
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


%wol_tol=195/(24*3600);%195s time width of typical WOL
wol_tol=WOL.t_dur;%this is now an array of all WOL/OCM durations.
wol_t_mid= WOL.t0+wol_tol/2; % datetime midpoint of all files
packet_tol= max([index(tabind(:)).t1]-[index(tabind(:)).t0]);
index_t_mid= [index(tabind(:)).t0] + 0.5*packet_tol; % datetime midpoint of all files
% % (given that they have all have the same time width (? is this true?)
% % it should be reasonably true since it's all the same macro and filetype
% % the only exception is 710 & 910 V1L/V2L. in which case the longest packet
% % length is good enough for us. (taken care of by the max argument)

%ismemberf is sufficiently smart to take an array index_t_mid (Nx1),
%wol_t_mid (Jx1), and tolerance (Jx1) to create a boolean WOL_bool of (Nx1)
WOL_bool=ismemberf(index_t_mid,wol_t_mid,'tol',0.5*(wol_tol+packet_tol));%
%WOL_bool now is of length (tabind) and is 1 if any
%WOL.t0 or WOL.t1 is within wol_tol from the file midpoint.
%tot_bytes = 0;


if fileflag(1:2)=='V2' %i.e. either V2L or V2H
    % V0*exp(-4.6052)=0.01.
    v2c_tol=V2C.tol*4.6052;%V2C.tol is the halftime, typically V2C_tol defaults to 64 or 32 seconds, unless a very obvious contamination signature has been detected.
    %instances where there is a macro change (or calendar day change) but
    %no bias change (≈ 40 times during comet phase) has been removed
    v2c_t_mid=V2C.t0+v2c_tol/2;
    V2C_bool=ismemberf(index_t_mid,v2c_t_mid,'tol',0.5*(v2c_tol+packet_tol));%check again!
    %V2C_bool now is of length (tabind) and is 1 if any measurement is
    %inside the tolerance.
else
    V2C_bool(1:len)=0;
end


    if(~index(tabind(1)).sweep) %% if not a sweep, do:

        for (i=1:len)
            qualityF = 0+100*WOL_bool(i)+200*V2C_bool(i);     % qualityfactor initialised! WOL_BOOL and V2C_bool is either 0 or 1;
            trID = fopen(index(tabind(i)).tabfile);

            if trID < 0
                fprintf(1,'Error, cannot open file %s\n', index(tabind(i)).tabfile);
                break
            end % if I/O error




            if fileflag(2) =='3' % read file probe 3

                scantemp = textscan(trID,'%s%f%f%f%f','delimiter',',');
            %FKJN Offset correction no longer needed 6/3 2018

                %apply offset, but keep it in cell array format.
%                 if fileflag(1) =='V'  %for macro 700,701,702,705,706
%                     scantemp(:,3)=cellfun(@(x) x+Offset.V1L,scantemp(:,3),'un',0);
%                     scantemp(:,4)=cellfun(@(x) x+Offset.V2L,scantemp(:,4),'un',0);
%                 else  %hypothetically, we could have I1-I2. (no current macro)
%                     scantemp(:,3)=cellfun(@(x) x+CURRENTOFFSET,scantemp(:,3),'un',0);
%                 end


                    %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
                     %apparently an if/else case is 2.13 times faster than querying
                     %both columns
                if fileflag(1) =='V'  %for macro 700,701,702,705,706
                   % scantemp{1,3}(scantemp{1,3}==MISSING_CONSTANT)    = NaN;    
                   % scantemp{1,4}(scantemp{1,4}==MISSING_CONSTANT)    = NaN;
                   
                    satur_ind = scantemp{1,3} ==MISSING_CONSTANT; 
                    satur_ind2= scantemp{1,4} ==MISSING_CONSTANT; 
                    satur_ind = satur_ind2 | satur_ind; %combine logical matrices
                else  %hypothetically, we could have I1-I2. (no current macro)
                    %scantemp{1,3}(scantemp{1,3}==MISSING_CONSTANT)    = NaN;
                    satur_ind= scantemp{1,3}==MISSING_CONSTANT; 
                end

                     %-------------------------------------------------------------%


            else %other probes


                scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
                
                
                     %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
                     %apparently an if/else case is 2.13 times faster than querying
                     %both columns
                 if fileflag(1) =='V'  % Voltage  data
                   %  scantemp{1,4}(scantemp{1,4}==MISSING_CONSTANT)    = NaN;
                     satur_ind= scantemp{1,4}==MISSING_CONSTANT; 
                 else  %Current data 
                   %  scantemp{1,3}(scantemp{1,3}==MISSING_CONSTANT)    = NaN;
                     satur_ind= scantemp{1,3}==MISSING_CONSTANT; 
                 end

                     %-------------------------------------------------------------%

                %FKJN Offset correction no longer needed 6/3 2018
                %apply offset, but keep it in cell array format.
               % scantemp(:,3) =cellfun(@(x) x+CURRENTOFFSET,scantemp(:,3),'un',0);

            end

             %  qf_tot=qualityF+400*any(satur_ind); %satur_ind is reset every loop until this
      
            %at some macros, we have measurements taken during sweeps, which leads to weird results
            %we need to find these and remove them

            if ~isempty(sweept)

                %lee= length(scantemp{1,2}(:));
                %del = false(1,lee);
                
                
                % We can be more careful later. This is the maximum moving
                % average in the entire mission, and sweeps always start at
                % an AQP. I don't want to slow up this script, so this
                % inexact thing works for now
                eps_ma_dt=256/(2*57.8);
                if scantemp{1,2}(end)<sweept(1,1) || (scantemp{1,2}(1)-eps_ma_dt)>sweept(2,end)

                    %all measurements before first sweep or after last sweep.
                else


                    ma_length = index(tabind(1)).adc20ma_length;
                    if ma_length >1
                        ma_length_corr = ma_length/(2*57.8);
                    else
                        ma_length_corr=0;
                    end
                    
                    
                    tol=sweept(2,1)-sweept(1,1)+ma_length_corr;
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

                        satur_ind(del) = []; %hopefully satur_ind now is the same length as the others 

                    end%if
                end
            end%  sweep window deletions
                
                
                %if macroNo == hex2dec('710') || macroNo == hex2dec('910')                 
                   % trigg_dt = 1;
                    %fprintf(1,'710 correction trigger');
                    
                   % dt_710 =scantemp{1,2}(2) - scantemp{1,2}(1);
                   % if dt_710< trigg_dt
                        %fprintf(1,'710 correction applied');
                        
                   %     scantemp(:,4)=cellfun(@(x) x*ma_corr_factor,scantemp(:,4),'un',0);
                   % end
                    
               % end%if 710/910 bugfix 23/5 2017, no longer needed // FKJN 



            scanlength = length(scantemp{1,1});
            counttemp = counttemp + scanlength;

            if scanlength ~=0 %if not file is empty/all invalid
                delfile = 0; %file will not be deleted
                timing={scantemp{1,1}{end,1},scantemp{1,2}(end)}; %remember last timers
%             %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%

              qf=qualityF+400*(satur_ind); %satur_ind is of length (scanlength), so qf is unique for each row.
               
              %nb: qf here is a vector!  in non-sweep qf is a scalar!
%             %-------------------------------------------------------------%
                        

                if fileflag(2) =='3'

                    for (j=1:scanlength)       %print
                                  

                        %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\r\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                        fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, %14.7e, %03i\r\n'...
                            ,scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),scantemp{1,5}(j),qf(j)); %edit FKJN 8/3 2018. qualityF --> qf(j)
                    end
                else

                    for (j=1:scanlength)       %print

                        %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\r\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
                        fprintf(twID,'%s, %16.6f, %14.7e, %14.7e, %03i\r\n'...
                            ,scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j),qf(j)); %edit FKJN 8/3 2018. qualityF --> qf(j)
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




        for(i=1:len); % read&write loop iterate over all files, create B*S.TAB and I*S.TAB
            %qualityF = 0;     % qualityfactor initialised!
            qualityF = 0+100*WOL_bool(i);     % qualityfactor initialised! WOL_BOOL is either 0 or 1;

            trID = fopen(index(tabind(i)).tabfile);

            if trID > 0
                scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
                fclose(trID); %close read file
            else            % if I/O error
                fprintf(1,'Error, cannot open file %s\n', index(tabind(i)).tabfile);
                break
            end

            step1 = index(tabind(i)).pre_sweep_samples; %some steps are not in actual sweep, but number is listed in LBL file
      %     step2 = find(diff(scantemp{1,4}(1:end)),1,'first');

      %     if step1 > 40 %foolproofing this after 24 June 2016 bug
      %        step1 = step2;
      %        continue; %continue passes control to the next iteration of a for or while loop. It skips any remaining statements in the body of the loop for the current iteration. The program continues execution from the next iteration. continue applies only to the body of the loop where it is called. In nested loops, continue skips remaining statements only in the body of the loop in which it occurs.
      %      end

            scantemp{1,1}(1:step1)    = [];
            scantemp{1,2}(1:step1)    = [];
            scantemp{1,3}(1:step1)    = [];
            scantemp{1,4}(1:step1)    = [];

            
            %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
             satur_ind = scantemp{1,3}==MISSING_CONSTANT; % logical vector which is true if any current is saturated (pds outputs -1000 as of 6/3 2018)
             %scantemp{1,3}(scantemp{1,3}==MISSING_CONSTANT)    = NaN;
             scantemp{1,3}(satur_ind) = NaN;% This should also work, so we don't have to
        
            
            %-------------------------------------------------------------%

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

                b1= fprintf(twID, '%14.7e, %14.7e\r\n', potout);   % Create BxS TAB file.

%
            end %if first iteration +bugfix



            %if(step2 ~= step1 &&( step2-nStep ~= step1))
          %      fprintf(1,'old calculation method-> %d --%d <- new indexed method ',step2,step1);
          %      fprintf(1,'Error in file %s\n', index(tabind(i)).tabfile);
          %  end


            %checks if macro is LDL macro, and downsamples current measurement
            if any(ismember(macroNo,LDLMACROS)) %if macro is any of the LDL macros
                qualityF = qualityF+200; %LDL macro measurement

                %filter LDL sweep for noisy points. the last two number
                %dictate how heavy filtering is needed. 3 & 1 are good from
                %experience.
                if any(ismember(macroNo,hex2dec({'807','817','827','617'})))%turns out that these BM macros needs some looser filtering
                    curArray= sweepcorrection(scantemp{1,3}(:),nStep,3,3,1);
                else
                    curArray= sweepcorrection(scantemp{1,3}(:),nStep,1,1,0);
                end
                
                
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


            %FKJN Offset correction no longer needed 6/3 2018
            %curArray=curArray+ CURRENTOFFSET;

            
            
            %----------- SATURATION un-HANDLING FKJN 6/3 2018 ---------------%
                  %LDL and macrospecific currents apply to all data in
                  %macroblock (and in a file). Saturation only applies to a
                  %sweep. any(satur_ind) can be 0 or 1 from one sweep to 
                  %the next, so qf_tot can vary 400 between rows
                % qf=qualityF+400*any(satur_ind);
                 qualityF= qualityF+400*any(satur_ind);
                 
                 %NEVERMIND this ->obs: qf here is a scalar! in non-sweep data it's a vector!
                  %the awkward handling is due to qualityF being a value


                 curArray(isnan(curArray))  = MISSING_CONSTANT; %not only aturated values, but filtered(LDL offsets) NaN's too.
            %-------------------------------------------------------------%

            
            
            
            
            
            b2 = fprintf(twID2,'%s, %s, %16.6f, %16.6f, %03i',scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end),qualityF);   % Write timestamps (2x2=4) + quality flag.
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
