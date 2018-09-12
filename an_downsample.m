function []= an_downsample(an_ind,intval,tabindex,index)
%function []= an_downsample(an_ind,tabindex,intval)

%%count = 0;
%oldUTCpart1 ='shirley,you must be joking';

global an_tabindex;
global target

%antemp ='';

foutarr=cell(1,7);

%fprintf(awID,'%s,%16.6f,,,,\n',UTC_time,(0.5*intval+tday0+(j-1)*intval));
%outputarr =

% QUALITYFLAG:
% is an 3 digit integer
% from 000 (best) to 332 (worst quality)

% sweep during measurement  = +100
% bug during measurement    = +200
% Rotation "  "    "        = +10
% Bias change " "           = +20
%
% low sample size(for avgs) = +2
% some zeropadding(for psd) = +2


hold_flag=0;
i=1; %
j=0;
global SATURATION_CONSTANT VFLOATMACROS

try
        %fileflag = tabindex{an_ind(i),1}(end-6:end-4);
    
        mode = tabindex{an_ind(i),1}(end-6);


        if mode =='V'  % Voltage  data
            test_column = 4;
        else % Current  data
            test_column = 3;
        end
    
    for i=1:length(an_ind)     % Iterate over files (indices).

        
        probenr = str2double(tabindex{an_ind(i),1}(end-5));
        macroNo=index(tabindex{an_ind(i) ,3}).macro;
        %macroNodex=dec2hex(macroNo);
        %macroNostr=dec2hex(index(tabindex{an_ind(i) ,3}).macro);
        %          dec2hex(index(tabindex{ind_V1L(1),3}).macro)
        
        arID = fopen(tabindex{an_ind(i),1},'r');
        if arID < 0
            fprintf(1,'Error, cannot open file %s\n', tabindex{an_ind(i),1});
            break
        end % if I/O error
        %    scantemp=textscan(arID,'%s%f%f%f%i','delimiter',',');
        scantemp=textscan(arID,'%s%f%f%f%d','delimiter',',');
        fclose(arID);
        
%       %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
%       %apparently an if/else case is 2.13 times faster than querying
%       %both columns
        scantemp{1,test_column}(scantemp{1,test_column}==SATURATION_CONSTANT) = NaN;
%       %-------------------------------------------------------------%
        
        UTCpart1 = scantemp{1,1}{1,1}(1:11);
        
        
        
        timing={scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end)};
        
        
        
        
        % Set starting spaceclock time to (UTC) 00:00:00.000000
        ah =str2double(scantemp{1,1}{1,1}(12:13));
        am =str2double(scantemp{1,1}{1,1}(15:16));
        as =str2double(scantemp{1,1}{1,1}(18:end)); %including fractions of seconds
        hms = ah*3600 + am*60 + as;
        tday0=scantemp{1,2}(1)-hms; %%UTC and Spaceclock must be correctly defined
        
        
        UTCpart2 = datestr(((1:3600*24/intval)-0.5)*intval/(24*60*60), 'HH:MM:SS.FFF'); % Calculate time of each interval, as fraction of a day
        tfoutarr{1,1} = strcat(UTCpart1,UTCpart2);
        tfoutarr{1,2} = [tday0 + ((1:3600*24/intval)-0.5)*intval];
        
        
        afname =tabindex{an_ind(i),1};
        afname(end-10:end-8) =sprintf('%02iS',intval);
        
        
        %afname = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),1}(end-10:end-8),sprintf('%02iS',intval));
        afname(end-4) = 'D';
        affolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
        
        mode = afname(end-6);
        
        
        
        %    inter = 1 + floor((t - tday0)/intval); %prepare subset selection to accumarray
        inter = 1 + floor((scantemp{1,2}(:) - tday0)/intval); %prepare subset selection to accumarray
        
        %intervals specified from beginning of day, in intervals of intval,
        %and the variable inter marks which interval the data in the file is related to
        
        
        
        
        
        
        
        %this @mean function will output mean even there is a single NaN
        %value in the interval. This is what we want in this case, I
        %believe.
        imu = accumarray(inter,scantemp{1,3}(:),[],@mean,NaN); %select measurements during specific intervals, accumulate mean to array and print NaN otherwise
        isd = accumarray(inter,scantemp{1,3}(:),[],@nanstd); %select measurements during specific intervals, accumulate standard deviation to array and print zero otherwise
        
        vmu = accumarray(inter,scantemp{1,4}(:),[],@mean,NaN);
        vsd = accumarray(inter,scantemp{1,4}(:),[],@std);
%        qf  = accumarray(inter,scantemp{1,5}(:),[],@(x) sum(unique(x)));
        qf  = accumarray(inter,scantemp{1,5}(:),[],@(x) frejonbitor(x));
        
        
        switch mode   %find bias changes and fix terrible std function
            
            case 'V'
                %let's not do anything fancy, the bias current/potential are written by
                %software, not a measuremeant
                sdtemp = isd;
                isd(:) = 0;
                
                %matlab is terrible with std...
                
                %             meanbias = nanmean(imu); %get mean bias, disregard NaN values.
                %             junk(1:20)=meanbias;    % set 20 values to this value, diff(junk) = 0 everywhere
                %             sdlimit = std(junk)*100; % this should be zero, but it isn't.
                %             isd(isd < sdlimit) = 0;% remove precision error from matlab std function
                
                
                qind = find(abs(diff(imu)/nanmean(imu)) > 1E-10); % find bias changes (NB, length(diff(imu))=length(imu) -1 )
                %be wary of precision errors
                
                %     qind = find(abs(diff(imu)) > 0); % find bias changes (NB, length(diff(imu))=length(imu) -1 )
                if ~isempty(qind);
                    qind = qind +1; % correction
                    qf(qind) = qf(qind)+20;% add + 20  qualityfactor for bias changes
                    
                    isd(qind) = sdtemp(qind); %this might be interesting to know. or not.
                end
                
                
            case 'I'
                
                
                %let's not do anything fancy, the bias current/potential are written by
                %software, not a measuremeant
                
                sdtemp = vsd;
                vsd(:) = 0;
                
                %             meanbias = nanmean(vmu); %get mean bias, disregard NaN values.
                %             junk(1:20)=meanbias;    % set 20 values to this value, diff(junk) = 0 everywhere
                %             sdlimit = std(junk)*100; % this should be zero, but it isn't.
                %             vsd(vsd < sdlimit) = 0;% remove precision error from matlab std function
                
                
                %be wary of precision errors
                qind = find(abs(diff(vmu)/nanmean(vmu)) > 1E-10); % find bias changes (NB, length(diff(imu))=length(imu) -1 )
                if ~isempty(qind);
                    qind = qind +1;       % correction
                    qf(qind) = qf(qind)+20;% add + 20  qualityfactor for bias changes
                    
                    vsd(qind) = sdtemp(qind); %this might be interesting to know. or not.
                end
                
        end  % switch
        
        
        %  sumunique= @(x) sum(unique(x));
        
        %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%

        if mode =='V'  % Voltage  data
            vsd(isnan(vmu))=SATURATION_CONSTANT;
            vmu(isnan(vmu))=SATURATION_CONSTANT;
        else            
            isd(isnan(imu))=SATURATION_CONSTANT;
            imu(isnan(imu))=SATURATION_CONSTANT;
        end

        %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%

        
        
        foutarr{1,3}( inter(1):inter(end), 1 ) = imu( inter(1):inter(end) ); %prepare for printing results
        foutarr{1,4}( inter(1):inter(end), 1 ) = isd( inter(1):inter(end) );
        foutarr{1,5}( inter(1):inter(end), 1 ) = vmu( inter(1):inter(end) );
        foutarr{1,6}( inter(1):inter(end), 1 ) = vsd( inter(1):inter(end) );
        %foutarr{1,7}( inter(1):inter(end),1 ) = 1; %%flag to determine if row should be written.
        foutarr{1,8}( inter(1):inter(end), 1 ) = qf(inter(1):inter(end));
        foutarr{1,7}(unique(inter))=1; %%flag to determine if row should be written.
        
        
        
        if intval ==0 %%analysis if
            
            for j = 2: length(scantemp{1,2})-1
                
                %leapfrog derivative method
                scantemp{1,6}(j)=scantemp{1,3}(j-1)-scantemp{1,3}(j+1)/(scantemp{1,2}(j-1)-scantemp{1,2}(j+1));  %%dI/dt
                scantemp{1,7}(j)=scantemp{1,4}(j-1)-scantemp{1,3}(j+1)/(scantemp{1,2}(j-1)-scantemp{1,2}(j+1));  %%dV/dt
                
            end%for
            
            scantemp{1,6}(1)   = scantemp{1,3}(1) - scantemp{1,3}(1+1)/(scantemp{1,2}(1) - scantemp{1,2}(1+1));  % dI/dt    forward differentiation, larger error
            scantemp{1,6}(j+1) = scantemp{1,3}(j) - scantemp{1,3}(j+1)/(scantemp{1,2}(j) - scantemp{1,2}(j+1));  % dI/dt   backward differentiation, larger error
            scantemp{1,7}(1)   = scantemp{1,4}(1) - scantemp{1,4}(1+1)/(scantemp{1,2}(1) - scantemp{1,2}(1+1));  % dV/dt    forward differentiation, larger error
            scantemp{1,7}(j+1) = scantemp{1,4}(j) - scantemp{1,4}(j+1)/(scantemp{1,2}(j) - scantemp{1,2}(j+1));  % dV/dt   backward differentiation, larger error
            
            
            
            
            dimu = accumarray(inter,scantemp{1,6}(:),[],@mean);
            disd = accumarray(inter,scantemp{1,6}(:),[],@std);
            dvmu = accumarray(inter,scantemp{1,7}(:),[],@mean);
            dvsd = accumarray(inter,scantemp{1,7}(:),[],@std);
            
            
            afoutarr=foutarr;
            
            afoutarr{1,8}( inter(1):inter(end),1) = dimu(inter(1):inter(end));
            afoutarr{1,9}( inter(1):inter(end),1) = disd(inter(1):inter(end));
            afoutarr{1,10}(inter(1):inter(end),1) = dvmu(inter(1):inter(end));
            afoutarr{1,11}(inter(1):inter(end),1) = dvsd(inter(1):inter(end));
            
            
            
            
            if mode == 'V' %analyse electric field mode
                
                
                an_Emode(afoutarr);
                
            elseif mode == 'I' %analyse density mode
                
                an_Nmode(afoutarr);
                
            end%if
            
        end%if
        
        
        
        
        
        
        clear scantemp imu isd vmu vsd inter junk %save electricity kids!
        
        
        
        
        
        awID= fopen(afname,'w');
        N_rows = 0;
        for j =1:length(foutarr{1,3})
            
            if foutarr{1,7}(j)~=1 %check if measurement data exists on row
                %fprintf(awID,'%s, %16.6f,,,,\r\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
                % Don't print zero values.
            else
                
                row_byte= fprintf(awID,'%s, %16.6f, %14.7e, %14.7e, %14.7e, %14.7e, %05i\r\n',tfoutarr{1,1}(j,:),tfoutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j),sum(foutarr{1,8}(j)));

                N_rows = N_rows + 1;
            end%if
            
        end%for
        
        
        an_tabindex{end+1,1} = afname;                   % Start new line of an_tabindex, and record file name
        an_tabindex{end,2} = strrep(afname,affolder,''); % shortfilename
        an_tabindex{end,3} = tabindex{an_ind(i),3}; % First calib data file index
        an_tabindex{end,4} = N_rows;                % length(foutarr{1,3}); % Number of rows
        an_tabindex{end,5} = 7;            % Number of columns
        an_tabindex{end,6} = an_ind(i);
        an_tabindex{end,7} = 'downsample'; % Type
        an_tabindex{end,8} = timing;
        an_tabindex{end,9} = row_byte;                
        fclose(awID);
        
        %%%%-----------------USC CHECK------------------------------------%
        %fprintf(1,'checking %x, vs %x',macroNo,VFLOATMACROS(:,probenr))
        if  mode =='V' && ismember(macroNo,VFLOATMACROS{probenr})
                  
            %%%--------illumination check------------------------%%%
            dynampath = strrep(mfilename('fullpath'),'/an_downsample','');
            kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
            paths();
            
            cspice_furnsh(kernelFile);
            
            tfoutarr
            foutarr
                
            
            lent = length(foutarr{1,7});
            
            [junk,SEA,SAA]=orbit('Rosetta',tfoutarr{1,1},target,'ECLIPJ2000','preloaded');
            cspice_kclear;
            
            SEA=SEA(1:lent); %fix
            SAA=SAA(1:lent);
            
         % *Elias values* (from photoemission study):
            if probenr==1
                Phi11 = 131.2;
                Phi12 = 179.2;
                illuminati = ((SAA < Phi11) | (SAA > Phi12));
               foutarr{1,8}=foutarr{1,8}+100;
                               
            else 
                foutarr{1,8}=foutarr{1,8}+200;
                Phi21 = 18;
                Phi22 = 82;
                Phi23 = 107;
                illuminati = ((SAA < Phi21) | (SAA > Phi22)) - 0.6*((SAA > Phi22) & (SAA < Phi23));
            end
            SEA_OK = abs(SEA)<1; %  0 ?1 degree  = nominal pointing
            illuminati(~SEA_OK)=0.3;

            dark_ind=illuminati<0.9;
            foutarr{1,7}(dark_ind)=0; %won't be printed.
            %%%----------------------------------------------%%%
            

            USCfname= tabindex{an_ind(i),1};
            USCfname(end-6:end-4)='USC';
            USCshort=strrep(USCfname,affolder,'');
            
            if ismember(macroNo,VFLOATMACROS{1}(ismember(VFLOATMACROS{1},VFLOATMACROS{2})))
            %is LAP2 % LAP1 floating in this macro? 710,910,802,801...            
            %then we need to save the data, wait for the next iteration (which, since it's a sorted list, will hold the corresponding probe number)
            
            
                if(hold_flag) %ugh have to check which probe to use.

                    %time_arr{1,1}(j,:)
                    hold_flag = 0; %reset
                    
                    if probenr==1
                        
                        foutarr_1=foutarr;
                        tfoutarr_1=tfoutarr;
                        
                    else
                        
                        foutarr_2=foutarr;
                        %tfoutarr_2=tfoutarr; %only need this for debug
                    end
                       % fprintf(1,'\n tfoutarr_2{1,1}(1,:)=%s \n tfoutarr_1{1,1}(1,:)=%s \n', tfoutarr_2{1,1}(1,:),tfoutarr_1{1,1}(1,:));
                        %fprintf(1,'\n tfoutarr_2{1,1}(end,:)=%s \n tfoutarr_1{1,1}(end,:)=%s \n', tfoutarr_2{1,1}(end,:),tfoutarr_1{1,1}(end,:));

                        %tfoutarr
                        %tfoutarr_1
                        %tfoutarr_2
                        %probenr

                        %length(dark_ind)
                        

                    replaceind_lap1= (foutarr_1{1,7}(:)~=1);
                    ok_tokeeplap2 = (foutarr_2{1,7}(:)==1);
                    %the indices that are ok to keep is replaceind_lap1
                    if length(foutarr_1{1,7})~=length(foutarr_2{1,7})
                        fprintf(1,'error wrong lengths %i vs lap2 %i',length(foutarr_1{1,7}),length(foutarr_2{1,7}))
                    end
                    indz=replaceind_lap1&ok_tokeeplap2;

                    %initialise foutarr.
                        foutarr=foutarr_1; %default == probe 1.
                        tfoutarr=tfoutarr_1; %default == probe 1.

                        foutarr{1,5}(indz)=foutarr_2{1,5}(indz);%
                        foutarr{1,8}(indz)=foutarr_2{1,8}(indz);   %here we went from LAP1 to LAP2, change flag                                             

                    
                    an_USCprint(USCfname,USCshort,tfoutarr,foutarr, tabindex{an_ind(i),3},timing,'vfloat');
                    
                    
                    clear foutarr_2 tfoutarr_2 foutarr_1 tfoutarr_1 
                    
                else
                    if probenr==1
                        foutarr_1=foutarr;
                        tfoutarr_1=tfoutarr;
                    else
                        foutarr_2=foutarr;
                       % tfoutarr_2=tfoutarr; %I only need this to debug
                    end
                    
                    hold_flag = 1; 

                end
            
            else%no problem, just output data.
                
            an_USCprint(USCfname,USCshort,tfoutarr,foutarr, tabindex{an_ind(i),3},timing,'vfloat');
            
            end
            
            
            
            
        end
        
        
        
        
        
        
        
        %    oldUTCpart1 = UTCpart1; %stuff to remember next loop iteration
        %   count = count +1; %increment counter
        
        
        
        
        clear foutarr tfoutarr %not really needed, will not exist outside of function anyway.

        
    end%for main loop
    
catch err
    
    fprintf(1,'Error at loop step %i or  foutarr{}(%i), file %s',i,j,tabindex{an_ind(i),1});
    
    err.identifier
    err.message
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i,',err.stack(i).name,err.stack(i).line);
        end
    end
end   % try-catch

end   %function


function x=frejonbitor(A)

len = length(A);
x=uint32(A(1));


if len>1

    for i = 1:len
    x=bitor(x,uint32(A(i)));
    end
end




end


