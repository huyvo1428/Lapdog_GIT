function []= an_downsample(an_ind,intval,tabindex,index)
%function []= an_downsample(an_ind,tabindex,intval)

%%count = 0;
%oldUTCpart1 ='shirley,you must be joking';

global an_tabindex;
global target
global eog_32S

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

dynampath = strrep(mfilename('fullpath'),'/an_downsample','');

kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
hold_flag=0;
i=1; %
j=0;


%%%------ MAKE E-FIELD FILES FIRST -------------------------------- %%%%
global MISSING_CONSTANT VFLOATMACROS
k=0;
tabfilez=([tabindex{an_ind(:) ,3}]);

debug=[0 0 0];

Illumination_HEAVY_FIX=false;

if ~debug(1)

   
    
while k<length(an_ind) % alternatively length(tabfilez)
    k=k+1;

    %is this file from a macro where we float both probes?
    if    ismember(index(tabfilez(k)).macro,VFLOATMACROS{1}(ismember(VFLOATMACROS{1},VFLOATMACROS{2})))

        %pass only parts of the indices that I need:
        %an_Efld_debug(tabindex(an_ind(k:k+1),:), index(tabfilez(k:k+1)),kernelFile)
        an_Efld(tabindex(an_ind(k:k+1),:), index(tabfilez(k:k+1)),kernelFile)

        k=k+1;% k increased by two in this loop. The wanted files are subesequent
    end

end
end


%%%----------------------------------------------------------------- %%%%


try
        %fileflag = tabindex{an_ind(i),1}(end-6:end-4);

        mode = tabindex{an_ind(i),1}(end-6);


        %calling this inside the loop was madness
        paths();
        cspice_furnsh(kernelFile);


        if mode =='V'  % Voltage  data
            test_column = 4;
        else % Current  data
            test_column = 3;
        end

    for i=1:length(an_ind)     % Iterate over files (indices).

        
        probenr = str2double(tabindex{an_ind(i),1}(end-5));
        macroNo=index(tabindex{an_ind(i) ,3}).macro;
        %macroNo=hex2dec(tabindex{an_ind(i),1}(end-10:end-8));
        %tabindex{an_ind(i),1}=strrep(tabindex{an_ind(i),1},'/data/rosetta/','/mnt/spis/');
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
        scantemp{1,test_column}(scantemp{1,test_column}==MISSING_CONSTANT) = NaN;
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

        %Bugfix Issue #10. 
        inter(inter>2700)=2700;
        
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

                vsd_limit = 7.62940181E-5/1800; % 1789 samples maximum per AQP. 7.63e-5 V accuracy (20bit accuracy)
                %isd_limit = 1.90735045E-11/1800; % 1789 samples maximum per AQP. 1.9E-11 Amps accuracy (20bit accuracy)

                 % abs() probably unnecessary.
                vsd(abs((vsd)) < vsd_limit) = 0; %find all values below treshold. Values lower than this is noise from MATLAB precision error.

                % ROSETTA:LAP_VOLTAGE_CAL_16B = "1.22072175E-3"
                % ROSETTA:LAP_VOLTAGE_CAL_20B = "7.62940181E-5"
                % ROSETTA:LAP_CURRENT_CAL_16B_G1 = "3.05180438E-10"
                % ROSETTA:LAP_CURRENT_CAL_20B_G1 = "1.90735045E-11"
                % ROSETTA:LAP_CURRENT_CAL_16B_G0_05 = "6.10360876E-9"
                % ROSETTA:LAP_CURRENT_CAL_20B_G0_05 = "3.81470090E-10"



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
                    qf(qind) = qf(qind)+10;% add + 20  qualityfactor for bias changes

                    isd(qind) = sdtemp(qind); %this might be interesting to know. or not.
                end


            case 'I'



                isd_limit = 1.90735045E-11/1800; % 1789 samples maximum per AQP. 1.9E-11 Amps accuracy (20bit accuracy)
                isd(abs((isd)) < isd_limit) = 0; %find all values below treshold. Values lower than this will be noise from MATLAB precision error.


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
                    qf(qind) = qf(qind)+10;% add + 20  qualityfactor for bias changes

                    vsd(qind) = sdtemp(qind); %this might be interesting to know. or not.
                end

        end  % switch


        %  sumunique= @(x) sum(unique(x));

        %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%

        if mode =='V'  % Voltage  data
            vsd(isnan(vmu))=MISSING_CONSTANT;
            vmu(isnan(vmu))=MISSING_CONSTANT;
        else
            isd(isnan(imu))=MISSING_CONSTANT;
            imu(isnan(imu))=MISSING_CONSTANT;
        end

        %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%



        foutarr{1,3}( inter(1):inter(end), 1 ) = imu( inter(1):inter(end) ); %prepare for printing results
        foutarr{1,4}( inter(1):inter(end), 1 ) = isd( inter(1):inter(end) );
        foutarr{1,5}( inter(1):inter(end), 1 ) = vmu( inter(1):inter(end) );
        foutarr{1,6}( inter(1):inter(end), 1 ) = vsd( inter(1):inter(end) );
        %foutarr{1,7}( inter(1):inter(end),1 ) = 1; %%flag to determine if row should be written.
        foutarr{1,8}( inter(1):inter(end), 1 ) = qf(inter(1):inter(end));
        foutarr{1,7}(unique(inter))=1; %%flag to determine if row should be written.



     %   clear scantemp imu isd vmu vsd inter junk %save electricity kids!
        clear  imu isd vmu vsd  junk %save electricity kids!

        %EDIT FKJN 3/12 2019
        qf_v2= (foutarr{1,8}(:)); %new qualityfactor variable. The other was annoying

        %I considered comparing OBT-> ET, but it involves a middlestep with
        %creating SCT via string modifications, and that's just too much
        %hassle.
        t_et32S= cspice_str2et(tfoutarr{1,1}); % this is checking the entire file, somewhat needlessly
        [eog_bool, id] = ismemberf(t_et32S,eog_32S.tt);
        %eog_bool now is of length (t_et32S) and is 1 if any
        %time stamp is within some tolerance of eachother. I can set the
        %tolerance to 1 second by setting ,'tol',1)

        

        
        switch probenr
            
            case 1
                ill1=double(eog_bool);
                ill1(eog_bool)=eog_32S.lap1ill(id);
                darkeog_list= find(ill1<1); %look for all shadowed probe conditions
                max_darkeog_list = unique([darkeog_list-1;darkeog_list+1]); %find neighbouring points
                max_darkeog_list(max_darkeog_list<1 | max_darkeog_list>2700)=[]; %stay within limits of vector     
                ill1(max_darkeog_list)=0; %set allneighbouring points as shadowed.
                dark_eog_ind=ill1<1; %find shadowed points
                
                qf_v2=qf_v2+uint32(dark_eog_ind(1:length(qf_v2)).'*20); %set qualityflag,
            case 2
                darkeog_list= find(ill2<1);
                max_darkeog_list = unique([darkeog_list; darkeog_list-1;darkeog_list+1]);
                max_darkeog_list(max_darkeog_list<1 | max_darkeog_list>length(qf_v2))=[];
                ill2(max_darkeog_list)=0;
                dark_eog_ind=ill2<1;              
                qf_v2=qf_v2+uint32(dark_eog_ind(1:length(qf_v2)).'*20); %set qualityflag
                ill2=double(eog_bool);
                ill2(eog_bool)=eog_32S.lap2ill(id);
                
        end
        
        
        %         
%                 %EDIT FKJN 3/12 2019
%         %t_et32S = cspice_scs2e(-226,tfoutarr{1,2})
%         t_et32S_temp= cspice_str2et(tfoutarr{1,1}); % this is checking the entire file, somewhat needlessly
%         t_et32S= t_et32S_temp(1:inter(end));
% %        t_et32S(length(foutarr{1,7})+1:end)=[]; %sadly, tampering with tfoutarr is annoying in Matlab 2015. So we reduce the array here
%         [eog_bool, id] = ismemberf(t_et32S,eog_32S.tt);
%         ill1=double(eog_bool);
%         ill1(eog_bool)=eog_32S.lap1ill(id); %I hope eog_bool and id have equal lengths
%         ill2=double(eog_bool);
%         ill2(eog_bool)=eog_32S.lap2ill(id); %I hope eog_bool and id have equal lengths
%         
%         
% 
%         
%         switch probenr
%             
%             case 1
%                 darkeog_list= find(ill1<1); %look for all shadowed probe conditions
%                 max_darkeog_list = unique([darkeog_list-1;darkeog_list+1]); %find neighbouring points
%                 max_darkeog_list(max_darkeog_list<inter(1) | max_darkeog_list>inter(end))=[]; %stay within limits of vector     
%                 ill1(max_darkeog_list)=0; %set allneighbouring points as shadowed.
%                 dark_eog_ind=ill1<1; %find shadowed points
%                 %qf_v2=qf_v2+dark_eog_ind.'*20; %set qualityflag
%                 %qf_v2=qf_v2+uint32(dark_eog_ind(1:length(qf_v2)).'*20); %set qualityflag,
%                 qf_v2=qf_v2+uint32(dark_eog_ind.'*20); %set qualityflag,
%             case 2
%                 darkeog_list= find(ill2<1);
%                 max_darkeog_list = unique([darkeog_list; darkeog_list-1;darkeog_list+1]);
%                 % max_darkeog_list(max_darkeog_list<1 | max_darkeog_list>length(qf_v2))=[];
%                 max_darkeog_list(max_darkeog_list<inter(1) | max_darkeog_list>inter(end))=[]; %stay within limits of vector     
% 
%                 ill2(max_darkeog_list)=0;
%                 dark_eog_ind=ill2<1;
%                 
%                 qf_v2=qf_v2+dark_eog_ind*20; %set qualityflag
% 
%         end

        
        %eog_bool is now of length (t_et32S) and is true if t_et32S is
        %within some tolerance from eog_32S.tt. I can set the tolerance to
        %1 second by adding: by,'tol,1)

        
        
if Illumination_HEAVY_FIX && probenr==1
            t_etfull= cspice_str2et(scantemp{1,1}(:)); %I'll use this  in the print function later

            %New method  12/2 2019 check for all values, not just the downsampled timestamps.
            [junk,SEA,SAA]=orbit('Rosetta',t_etfull,target,'ECLIPJ2000','preloaded');
%             lent = length(foutarr{1,7});
%             SEA=SEA(1:lent); %fix
%             SAA=SAA(1:lent);

         % *Elias values* (from photoemission study):
            %if probenr==1
                Phi11 = 131.2;
                Phi12 = 179.2;
                illuminati = ((SAA < Phi11) | (SAA > Phi12));
              % foutarr{1,8}=foutarr{1,8}+100;
% 
%             else
%                 %foutarr{1,8}=foutarr{1,8}+200;
%                 Phi21 = 18;
%                 Phi22 = 82;
%                 Phi23 = 107;
%                 illuminati = ((SAA < Phi21) | (SAA > Phi22)) - 0.6*((SAA > Phi22) & (SAA < Phi23));             
            %end
            SEA_OK = abs(SEA)<1; %  0 ?1 degree  = nominal pointing
            illuminati(~SEA_OK)=0.3;


             lum_temp  = accumarray(inter,illuminati,[],@mean,NaN);
             t_et_temp = accumarray(inter,t_etfull,[],@mean,NaN);
             %SAA_temp = accumarray(inter,SAA,[],@mean,NaN);
             lum_mu(inter(1):inter(end),1) = lum_temp(inter(1):inter(end));
            %SEA_mu(inter(1):inter(end),1) = SEA_temp(inter(1):inter(end));
             t_et(inter(1):inter(end),1) = t_et_temp(inter(1):inter(end));

            dark_ind=lum_mu<1; 

            qf_v2(dark_ind)=qf_v2+20;
            
end



        awID= fopen(afname,'w');
        N_rows = 0;
        for j =1:length(foutarr{1,3})

            if foutarr{1,7}(j)~=1 %check if measurement data exists on row
                %fprintf(awID,'%s, %16.6f,,,,\r\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
                % Don't print zero values.
            else

                row_byte= fprintf(awID,'%s, %16.6f, %14.7e, %14.7e, %14.7e, %14.7e, %03i\r\n',tfoutarr{1,1}(j,:),tfoutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j),qf_v2(j));

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
            %%% ALL THIS SHOULD BE MOVED TO BE PART OF WHOLE DOWNSAMPLED
            %%% ALGORITHM. SO WE CAN PUT SHADOW CONDITIONS IN QUALITYFLAG
            %%% 13/2 2019 FKJN

if ~(Illumination_HEAVY_FIX && probenr==1)
%             tfoutarr
%             foutarr
            t_etfull= cspice_str2et(scantemp{1,1}(:)); %I'll use this  in the print function later

            %New method  12/2 2019 check for all values, not just the downsampled timestamps.
            [junk,SEA,SAA]=orbit('Rosetta',t_etfull,target,'ECLIPJ2000','preloaded');
            %[junk,SEA,SAA]=orbit('Rosetta',tfoutarr{1,1},target,'ECLIPJ2000','preloaded');

%             lent = length(foutarr{1,7});
%             SEA=SEA(1:lent); %fix
%             SAA=SAA(1:lent);

         % *Elias values* (from photoemission study):
            if probenr==1
                Phi11 = 131.2;
                Phi12 = 179.2;
                illuminati = ((SAA < Phi11) | (SAA > Phi12));
              % foutarr{1,8}=foutarr{1,8}+100;

            else
                %foutarr{1,8}=foutarr{1,8}+200;
                Phi21 = 18;
                Phi22 = 82;
                Phi23 = 107;
                illuminati = ((SAA < Phi21) | (SAA > Phi22)) - 0.6*((SAA > Phi22) & (SAA < Phi23));
            end
            SEA_OK = abs(SEA)<1; %  0 ?1 degree  = nominal pointing
            illuminati(~SEA_OK)=0.3;


             lum_temp = accumarray(inter,illuminati,[],@mean,NaN);
             t_et_temp     = accumarray(inter,t_etfull,[],@mean,NaN);
             %SAA_temp = accumarray(inter,SAA,[],@mean,NaN);
             lum_mu(inter(1):inter(end),1) = lum_temp(inter(1):inter(end));
            %SEA_mu(inter(1):inter(end),1) = SEA_temp(inter(1):inter(end));
             t_et(inter(1):inter(end),1) = t_et_temp(inter(1):inter(end));



            %clear scantemp inter; % i don't remember why I need to clear this anymore, but let's do it for the kids

            dark_ind=lum_mu<1; %   I HAVE TO DELETE LUM_MU AFTER THIS
end
            foutarr{1,7}(dark_ind)=0; %won't be printed.

            %%%----------------------------------------------%%%


            USCfname= tabindex{an_ind(i),1};
            USCfname(end-6:end-4)='USC';
            USCshort=strrep(USCfname,affolder,'');
            NEDfname= tabindex{an_ind(i),1};
            NEDfname(end-6:end-4)='NED';
            NEDshort=strrep(NEDfname,affolder,'');


            foutarr{1,2}=foutarr{1,7};
            foutarr{1,2}(:) = probenr; % I'm hijacking this array to show the probenumber


            if ismember(macroNo,VFLOATMACROS{1}(ismember(VFLOATMACROS{1},VFLOATMACROS{2})))
            %is LAP2 % LAP1 floating in this macro? 710,910,802,801...
            %then we need to save the data, wait for the next iteration (which, since it's a sorted list, will hold the corresponding probe number)


                if(hold_flag) %ugh have to check which probe to use.
                    %hold_flag default is 0. So we are now in the 2nd iteration

                    %time_arr{1,1}(j,:)
                    hold_flag = 0; %reset
                    if probenr==1
                        foutarr_1=foutarr;
                        tfoutarr_1=tfoutarr;
                        dark_ind_1=dark_ind;

                    else
                        foutarr_2=foutarr;
                        dark_ind_2=dark_ind;

                        %tfoutarr_2=tfoutarr; %only need this for debug
                    end
                       % fprintf(1,'\n tfoutarr_2{1,1}(1,:)=%s \n tfoutarr_1{1,1}(1,:)=%s \n', tfoutarr_2{1,1}(1,:),tfoutarr_1{1,1}(1,:));
                        %fprintf(1,'\n tfoutarr_2{1,1}(end,:)=%s \n tfoutarr_1{1,1}(end,:)=%s \n', tfoutarr_2{1,1}(end,:),tfoutarr_1{1,1}(end,:));

                        %tfoutarr
                        %tfoutarr_1
                        %tfoutarr_2
                        %probenr

                        %length(dark_ind)


                    replace_these_lap1= (foutarr_1{1,7}(:)~=1);
                    ok_tokeep_theselap2 = (foutarr_2{1,7}(:)==1);
                    %the indices that are ok to keep is replaceind_lap1
                    if length(foutarr_1{1,7})~=length(foutarr_2{1,7})
                        fprintf(1,'error wrong lengths %i vs lap2 %i',length(foutarr_1{1,7}),length(foutarr_2{1,7}))
                    end
                    indz=replace_these_lap1&ok_tokeep_theselap2; %only true if both lap1 in shadow and lap 2 in sunlight.

                    if sum(indz)>0
                        fprintf(1,'LAP1 sometimes shadowed, switching to LAP2 in file:%s \n',USCfname);
                    end

                    %initialise foutarr.
                        foutarr=foutarr_1; %default == probe 1.
                        tfoutarr=tfoutarr_1; %default == probe 1.
                        %here we went from LAP1 to LAP2,
                        foutarr{1,2}(indz)=foutarr_2{1,2}(indz);    %change probenumberflag
                        foutarr{1,5}(indz)=foutarr_2{1,5}(indz);%   %this is vf2
                        foutarr{1,6}(indz)=foutarr_2{1,6}(indz);%   this is the sigma vf2
                        foutarr{1,7}(indz)=foutarr_2{1,7}(indz);   %print boolean
                        foutarr{1,8}(indz)=foutarr_2{1,8}(indz); 
                        
                        data_arr=[];
%                         data_arr.V=scantemp_1{1,4};
%                         data_arr.t_utc=scantemp_1{1,1};
%                         data_arr.t_obt=scantemp_1{1,2};
%                         data_arr.qf=scantemp_1{1,5};
%                         data_arr.printboolean=~dark_ind_1;
%                         data_arr.probe=dark_ind_1;
%                         data_arr.probe(:)=1;%qflag
                        
                        data_arr.V=foutarr{1,5};
                        data_arr.V_sigma=foutarr{1,6};
                        data_arr.t_utc=tfoutarr{1,1};
                        data_arr.t_obt=tfoutarr{1,2};
                        data_arr.qf=foutarr{1,8};
                        data_arr.printboolean=foutarr{1,7};
                        data_arr.probe=dark_ind_1;
                        data_arr.probe(:)=1;%qflag

                        %%default == probe 1.
                        %here we went from LAP1 to LAP2,
                        data_arr.probe(indz)=2;  %change probenumberflag
                        data_arr.V(indz)=foutarr_2{1,5}(indz);%  %this is vf2
                        data_arr.V_sigma(indz)=foutarr_2{1,6}(indz);%  %this is sigma vf2
                        data_arr.printboolean(indz)=foutarr_2{1,7}(indz);  %print boolean
                        data_arr.qf(indz)=foutarr_2{1,8}(indz);   %qflag

                    %print USC special case
                    an_USCprint(USCfname,USCshort,tfoutarr,foutarr,tabindex{an_ind(i),3},timing,'vfloat');
                   % an_NEDprint(NEDfname,NEDshort,tfoutarr,foutarr,tabindex{an_ind(i),3},timing,'vfloat');
                    an_NEDprint(NEDfname,NEDshort,data_arr,t_et,tabindex{an_ind(i),3},timing,'vfloat');

                    %clear scantemp_1 scantemp_2
                    clear foutarr_2 tfoutarr_2 foutarr_1 tfoutarr_1 data_arr dark_ind lum_mu t_et %These are important
 
                else% hold_flag
                    %hold_flag default is 0. So this is 1st iteration

                    if probenr==1
                        foutarr_1=foutarr;
                        tfoutarr_1=tfoutarr;
                        dark_ind_1=dark_ind;

                    else
                        foutarr_2=foutarr;
                        dark_ind_2=dark_ind;
                       % tfoutarr_2=tfoutarr; %I only need this to debug
                    end
                    hold_flag = 1;

                end% hold_flag

            else%no problem, just output data.
            %print USC normal case
            %initialise foutarr.
            data_arr=[];
            data_arr.V=foutarr{1,5};
            data_arr.V_sigma=foutarr{1,6};
            data_arr.t_utc=tfoutarr{1,1};
            data_arr.t_obt=tfoutarr{1,2};
            data_arr.qf=foutarr{1,8};
            data_arr.printboolean=foutarr{1,7};
            data_arr.probe=dark_ind;
            data_arr.probe(:)=probenr;%qflag
            
            
            an_USCprint(USCfname,USCshort,tfoutarr,foutarr, tabindex{an_ind(i),3},timing,'vfloat');
            %an_NEDprint(NEDfname,NEDshort,tfoutarr,foutarr,tabindex{an_ind(i),3},timing,'vfloat');
            an_NEDprint(NEDfname,NEDshort,data_arr,t_et,tabindex{an_ind(i),3},timing,'vfloat');

            end



        else    
            clear dark_ind lum_mu t_et %These are important
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

    cspice_kclear;

end   % try-catch
    cspice_kclear;

end   %function



function []=an_Efld(red_tabindex,red_index,kernelFile)

global efl_tabindex MISSING_CONSTANT target


%calling this inside the loop was madness
paths();
cspice_furnsh(kernelFile);


row_byte=0;
debug=0;
if debug

    red_tabindex{1,1}=strrep(red_tabindex{1,1},'/homelocal/frejon/squidcopy/','/mnt/spis/');
    red_tabindex{2,1}=strrep(red_tabindex{2,1},'/homelocal/frejon/squidcopy/','/mnt/spis/');


end

probenr(1) = str2double(red_tabindex{1,1}(end-5));
probenr(2) = str2double(red_tabindex{2,1}(end-5));

macroNo(1) = red_index(1).macro;
macroNo(2) = red_index(2).macro;
fprintf(1,'macrono1=%s, 2=%s \n',dec2hex(macroNo(1)),dec2hex(macroNo(2)))

p_ind=false(1,2);
if probenr(1) == 1 && probenr(2) == 2
    p_ind(1)=true;
elseif probenr(1) == 2 && probenr(2) == 1
    p_ind(2)=true;
else


    fprintf(1,'error, check files 1=%s, 2=%s \n',red_tabindex{1,1},red_tabindex{2,1})

end


        ErID = fopen(red_tabindex{p_ind,1},'r'); %probe 1
        if ErID < 0
            fprintf(1,'Error, cannot open file1 %s\n',red_tabindex{p_ind,1});
            return;
        end % if I/O error
        %    scantemp=textscan(arID,'%s%f%f%f%i','delimiter',',');
        scantemp=textscan(ErID,'%s%f%f%f%d','delimiter',',');
        fclose(ErID);

%       %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
        test_column = 4;
        scantemp{1,test_column}(scantemp{1,test_column}==MISSING_CONSTANT) = NaN;
%       %-------------------------------------------------------------%



        ErID = fopen(red_tabindex{~p_ind,1},'r');%probe 2
        if ErID < 0
            fprintf(1,'Error, cannot open file2 %s\n', red_tabindex{~p_ind,1});
            return;
        end % if I/O error
        %    scantemp=textscan(arID,'%s%f%f%f%i','delimiter',',');
        scantemp2=textscan(ErID,'%s%f%f%f%d','delimiter',',');
        fclose(ErID);

%       %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
        scantemp2{1,test_column}(scantemp{1,test_column}==MISSING_CONSTANT) = NaN;
%       %-------------------------------------------------------------%


    %read files, handled NaNs. let's compute
   %lent1=length(scantemp{1,5});

    % prep output


           %%%--------illumination check------------------------%%%

        if ~debug %I don't want to do this while debugging at the moment
            %dynampath = strrep(mfilename('fullpath'),'/an_Efld','');



            if ismemberf(macroNo(1),hex2dec({'710'}))
                [junk,SEA,SAA]=orbit('Rosetta',scantemp2{1,1},target,'ECLIPJ2000','preloaded');
                len=length(scantemp2{1,5});
                timing={scantemp2{1,1}{1,1},scantemp2{1,1}{end,1},scantemp2{1,2}(1),scantemp2{1,2}(end)};



            else
                [junk,SEA,SAA]=orbit('Rosetta',scantemp{1,1},target,'ECLIPJ2000','preloaded');
                len=length(scantemp{1,5});
                timing={scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end)};

            end

            SEA=SEA(1:len); %fix
            SAA=SAA(1:len);
         % *Elias values* (from photoemission study):
                Phi11 = 131.2;
                Phi12 = 179.2;
                illuminati1 = ((SAA < Phi11) | (SAA > Phi12));

                Phi21 = 18;
                Phi22 = 82;
                Phi23 = 107;
                illuminati2 = ((SAA < Phi21) | (SAA > Phi22)) - 0.6*((SAA > Phi22) & (SAA < Phi23));
            SEA_OK = abs(SEA)<1; %  0 ?1 degree  = nominal pointing

            illuminati1(~SEA_OK)=0.3;

            dark_ind=illuminati1<0.9| illuminati2<0.9; %not sure about the illumination of these measurements
            printbooleanind=~dark_ind; %print everything else

            %printbooleanind(dark_ind)=false; %won't be printed.
            %%%----------------------------------------------%%%
        else
            %plot? % sprintf('%d','E') =69
            figure(69);plot(scantemp{1,2}-scantemp{1,2}(1),scantemp2{1,4}-scantemp{1,4})
            ax=gca;ax.XLabel.String='Seconds [s]';ax.YLabel.String='V2-V1 [V]';ax.Title.String=sprintf('%s',red_tabindex{1,1});
            grid on;

        end%~debug



        efname =red_tabindex{1,1};
        efname(end-6:end-4) = 'EFL';
        efolder = strrep(red_tabindex{1,1},red_tabindex{1,2},'');

        if  ismemberf(macroNo(1),hex2dec({'710','910'}))


            %v1l=
            %v1l(printbooleanind)=nan;
            %v2l=scantemp2{1,4};
            %v2l(printbooleanind)=nan;
            x10_input=[];
            x10_input.v1l=scantemp{1,4};
            x10_input.v2l=scantemp2{1,4};
            x10_input.t1l=scantemp{1,2};
            x10_input.t2l=scantemp2{1,2};
            x10_input.t1utc=scantemp{1,1};
            x10_input.t2utc=scantemp2{1,1};
            x10_input.qf1=uint64(scantemp{1,5});
            x10_input.qf2=uint64(scantemp2{1,5});
           % x10_input.SAA=SAA;



            efl = efl_x10(x10_input);
            %fprintf(1,'macrono1=%s, 2=%s \n',dec2hex(macroNo(1)),dec2hex(macroNo(2)))
            efl.qf=frejonbitor(efl.qfraw(:,1),efl.qfraw(:,2));
        else




            if length(scantemp{1,5})~= length(scantemp2{1,5})
                fprintf(1,'Error, files not equally long. file1: %s, \n file2: %s \n', red_tabindex{1,1}, red_tabindex{2,1});

            end
            efl=[];


%
%             out.t_obt=[tl;tm];%vertcat should work
%             out.ef_out = [efl;efm];%vertcat should work
%             [junk,ascind]=sort(out.t_obt,'ascend');
%             out.ef_out=out.ef_out(ascind);
%             out.t_obt=out.t_obt(ascind);
%             out.t_utc=tb_utc(save_ind);
%             out.freq_flag=9*ones(1,length(out.t_obt);
%             out.freq_flag(out.t_obt==tm)=3; %see mail" kombinationer MA_LENGTH & DOWNSAMPLE 18/2 2019"
%             out.qfraw=qfraw(save_ind);
%
            efl.t_utc=scantemp{1,1};
            efl.t_obt=scantemp{1,2};
            %efl.qf= bitor(scantemp{1,5},scantemp2{1,5}); %qualityflag!    % Does not work on MATLAB R2009a since bitor then does not accept arguments of class/type int32 (but uint32, uint64 work).
            efl.qf= frejonbitor(uint64(scantemp{1,5}),uint64(scantemp2{1,5})); %qualityflag!
            %efl.ef_out = 1000*(scantemp2{1,4}-scantemp{1,4})/5;
            efl.ef_out = efl_most(efl.t_obt,scantemp{1,4},scantemp2{1,4});


            %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%
            efl.ef_out(isnan(efl.ef_out))=MISSING_CONSTANT;
            %----------- SATURATION HANDLING FKJN 6/3 2018 ---------------%


            if macroNo(1)==hex2dec('801')
                efl.freq_flag=7*ones(1,length(efl.t_obt)); %7 = 64 Dwnsmpl 64 Moving average
            elseif macroNo(1)==hex2dec('802')
                efl.freq_flag=0*ones(1,length(efl.t_obt)); %0 = full resolution
            else
                efl.freq_flag=nan;
                'error. I didnt think we would get other this E-field macro'
            end

        end


        fill_indz=efl.qf>=200;
        
        efl.ef_out(fill_indz)=MISSING_CONSTANT;
        %or remove it completely by using
        %printbooleanind(fill_indz)=0;
        
        if any(fill_indz)

             fprintf(1,'some removal of saturation or contamination signatures. ')

             if all(fill_indz)
              fprintf(1,'all measurements removed..This might cause problems... \n')

             end
             
        end
        


%         diffI =abs((scantemp2{1,3})-(scantemp{1,3}));
%         printbooleanind(diffI>3e-11)=false;  % bias not consistent.
%
%         if any(~printbooleanind)
%             fprintf(1,' some shadowed values, or current bias values do not match')
%         end
%




        ewID= fopen(efname,'w');
        N_rows = 0;
        fprintf(1,'printing %s, macro: %s\n',efname, dec2hex(macroNo(1)));
        for j = 1:len

            if printbooleanind(j) %
                                  %UTC   %OBT      Efield, frequencyflag, qf
                row_byte= fprintf(ewID,'%s, %16.6f, %18.6f, %1i, %03i\r\n',efl.t_utc{j,1},efl.t_obt(j),efl.ef_out(j),efl.freq_flag(j),efl.qf(j));
                N_rows = N_rows + 1;
            end


        end
        fclose(ewID);
        cspice_kclear;

        fileinfo = dir(efname);

        if N_rows==0 || fileinfo.bytes==0
       % if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
            %  if N_rows > 0 %doublecheck!

            fprintf(1,'empty file?: %s \n bytes: %i, deleting...\n',efname,fileinfo.bytes);

            delete(efname); %will this work on any OS, any user?
            % end

        else % catalogue file





            efl_tabindex(end+1).fname = efname;                   % Start new line of an_tabindex, and record file name
            efl_tabindex(end).fnameshort =  strrep(efname,efolder,''); % shortfilename
            efl_tabindex(end).first_index = red_tabindex{1,3}; % First calib data file index
            efl_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
            efl_tabindex(end).no_of_columns = 5;            % Number of columns
            % efl_tabindex{end,6] = an_ind(i);
            efl_tabindex(end).type = 'Efield'; % Type
            efl_tabindex(end).timing = timing;
            efl_tabindex(end).row_byte = row_byte;
        end




end
