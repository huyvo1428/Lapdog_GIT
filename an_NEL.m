%function modeled frm an_downsample. Removed all the downsample part.
%suggestion: move an_EFL here as well?
function []= an_NEL(an_ind,tabindex,index)
%function []= an_downsample(an_ind,tabindex,intval)

%%count = 0;
%oldUTCpart1 ='shirley,you must be joking';

%global an_tabindex;
global target

%antemp ='';

%foutarr=cell(1,7);

dynampath = strrep(mfilename('fullpath'),'/an_NEL','');

kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
hold_flag=0;
i=1; %
j=0;

global MISSING_CONSTANT VFLOATMACROS


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
        macroNodex=dec2hex(macroNo);
        %macroNostr=dec2hex(index(tabindex{an_ind(i) ,3}).macro);
        %          dec2hex(index(tabindex{ind_V1L(1),3}).macro)




        %%%%-----------------USC/NED CHECK------------------------------------%
        %fprintf(1,'checking %x, vs %x',macroNo,VFLOATMACROS(:,probenr))
        if  (mode =='V' && ismember(macroNo,VFLOATMACROS{probenr}) )||  (mode =='I' && probenr)


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

        timing={scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end)};

        
        if mode =='I'
        
            print_bool= scantemp{1,4}(:)<-17;%V
            
            if sum(print_bool)==0 % no ion current?
            %if any(scantemp{1,3}<-18) % no ion current?

                continue; %moves to the next step in for loop
                
            end
            
            
        end
        

        afname =tabindex{an_ind(i),1};
        %afname(end-10:end-8) =sprintf('%02iS',intval);


        %afname = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),1}(end-10:end-8),sprintf('%02iS',intval));
        %afname(end-4) = 'D';
        affolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');

        mode = afname(end-6);
        NELfname=tabindex{an_ind(i),1};
        NELfname(end-6:end-4)='NEL';
        NELshort=strrep(NELfname,affolder,'');

% 
%         %    inter = 1 + floor((t - tday0)/intval); %prepare subset selection to accumarray
%         inter = 1 + floor((scantemp{1,2}(:) - tday0)/intval); %prepare subset selection to accumarray
% 
%         %intervals specified from beginning of day, in intervals of intval,
%         %and the variable inter marks which interval the data in the file is related to
% 
% 
% 
% % 
% % 
% 
% 
%         %this @mean function will output mean even if there is a single NaN
%         %value in the interval. This is what we want in this case, I
%         %believe.
%         imu = accumarray(inter,scantemp{1,3}(:),[],@mean,NaN); %select measurements during specific intervals, accumulate mean to array and print NaN otherwise
%         isd = accumarray(inter,scantemp{1,3}(:),[],@nanstd); %select measurements during specific intervals, accumulate standard deviation to array and print zero otherwise
% 
%         vmu = accumarray(inter,scantemp{1,4}(:),[],@mean,NaN);
%         vsd = accumarray(inter,scantemp{1,4}(:),[],@std);
% %        qf  = accumarray(inter,scantemp{1,5}(:),[],@(x) sum(unique(x)));
%         qf  = accumarray(inter,scantemp{1,5}(:),[],@(x) frejonbitor(x));
% 

        switch mode   %find bias changes and fix terrible std function

            case 'V'
                
                qind = find(abs(diff(scantemp{1,3})/nanmean(scantemp{1,3})) > 1E-10); % find bias changes (NB, length(diff(imu))=length(imu) -1 )
                if ~isempty(qind)
                    qind = qind +1;       % correction
                    scantemp{1,5}(qind) = scantemp{1,5}(qind)+10;% add + 10  qualityfactor for bias changes

                    %vsd(qind) = sdtemp(qind); %this might be interesting to know. or not.
                end


            case 'I'

                %be wary of precision errors
                qind = find(abs(diff(scantemp{1,4})/nanmean(scantemp{1,4})) > 1E-10); % find bias changes (NB, length(diff(imu))=length(imu) -1 )
                if ~isempty(qind)
                    qind = qind +1;       % correction
                    scantemp{1,5}(qind) = scantemp{1,5}(qind)+10;% add + 10  qualityfactor for bias changes
                    %vsd(qind) = sdtemp(qind); %this might be interesting to know. or not.
                end

        end  % switch


          %%%--------illumination check------------------------%%%
           
            t_et= cspice_str2et(scantemp{1,1}(:)); %I'll use this  in the print function later
            %New method  12/2 2019 check for all values, not just the downsampled timestamps.
            [junk,SEA,SAA]=orbit('Rosetta',t_et,target,'ECLIPJ2000','preloaded');
            %[junk,SEA,SAA]=orbit('Rosetta',tfoutarr{1,1},target,'ECLIPJ2000','preloaded');

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
            dark_ind=illuminati<1;
%             
%             lum_temp = accumarray(inter,illuminati,[],@mean,NaN);
%             %SAA_temp = accumarray(inter,SAA,[],@mean,NaN);
%             lum_mu(inter(1):inter(end),1) = lum_temp(inter(1):inter(end));
%             %SEA_mu(inter(1):inter(end),1) = SEA_temp(inter(1):inter(end));
%                      
%             dark_ind=lum_mu<1; %
%             foutarr{1,8}(dark_ind)=foutarr{1,8}(dark_ind)+20;% probe in partial or full shadow

          %%%--------illumination check------------------------%%%
            
         %   clear scantemp inter; % i don't remember why I need to clear this anymore, but let's do it for the kids
           
       % clear scantemp imu isd vmu vsd inter junk %save electricity kids!
     %   clear imu isd vmu vsd inter junk %save electricity kids!




% 
%         awID= fopen(afname,'w');
%         N_rows = 0;
%         for j =1:length(foutarr{1,3})
% 
%             if foutarr{1,7}(j)~=1 %check if measurement data exists on row
%                 %fprintf(awID,'%s, %16.6f,,,,\r\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
%                 % Don't print zero values.
%             else
% 
%                 row_byte= fprintf(awID,'%s, %16.6f, %14.7e, %14.7e, %14.7e, %14.7e, %03i\r\n',tfoutarr{1,1}(j,:),tfoutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j),sum(foutarr{1,8}(j)));
% 
%                 N_rows = N_rows + 1;
%             end%if
% 
%         end%for
% 
% 
%         an_tabindex{end+1,1} = afname;                   % Start new line of an_tabindex, and record file name
%         an_tabindex{end,2} = strrep(afname,affolder,''); % shortfilename
%         an_tabindex{end,3} = tabindex{an_ind(i),3}; % First calib data file index
%         an_tabindex{end,4} = N_rows;                % length(foutarr{1,3}); % Number of rows
%         an_tabindex{end,5} = 7;            % Number of columns
%         an_tabindex{end,6} = an_ind(i);
%         an_tabindex{end,7} = 'downsample'; % Type
%         an_tabindex{end,8} = timing;
%         an_tabindex{end,9} = row_byte;
%         fclose(awID);
%         
%         
        
%           
%             dark_ind=lum_mu<1; %
%             foutarr{1,7}(dark_ind)=0; %won't be printed.
% % 
% 
%             USCfname= tabindex{an_ind(i),1};

% 
% 
%             foutarr{1,2}=foutarr{1,7};
             %scantemp{1,3}(:) = probenr; % I'm hijacking this array to show the probenumber
             
             
             if mode =='V'
                 
                 if ismember(macroNo,VFLOATMACROS{1}(ismember(VFLOATMACROS{1},VFLOATMACROS{2})))
                     %is LAP2 % LAP1 floating in this macro? 710,910,802,801...
                     %then we need to save the data, wait for the next iteration (which, since it's a sorted list, will hold the corresponding probe number)
                     
                     
                     
                     if(hold_flag) %ugh have to check which probe to use.
                         %hold_flag default is 0. So we are now in the 2nd iteration
                         
                         %time_arr{1,1}(j,:)
                         hold_flag = 0; %reset
                         if probenr==1
                             scantemp_1=scantemp;
                             dark_ind_1=dark_ind;
                             t_et1=t_et;

                         else
                             scantemp_2=scantemp;
                             dark_ind_2=dark_ind;
                             t_et2=t_et;

                             %tfoutarr_2=tfoutarr; %only need this for debug
                         end
                         
                         
                         data_arr=NEL_combine_LAP1_LAP2(scantemp_1,scantemp_2,dark_ind_1,dark_ind_2,t_et1,t_et2);
                         %print NEL special case
                         data_arr_out=an_NELprint(NELfname,NELshort,data_arr,data_arr.t_et,tabindex{an_ind(i),3},timing,'vfloat');
                         
                         
                         clear scantemp_1 scantemp_2
                         
                     else% hold_flag
                         %hold_flag default is 0. So this is 1st iteration
                         
                         if probenr==1
                             scantemp_1=scantemp;
                             dark_ind_1=dark_ind;
                             t_et1=t_et;
                         else
                             scantemp_2=scantemp;
                             dark_ind_2=dark_ind;
                             t_et2=t_et;

                         end
                         
                         hold_flag = 1;
                         
                     end% hold_flag
                     
                 else%no problem, just output data.
                     %print NED normal case
                     %initialise foutarr.
                     data_arr=[];
                     data_arr.V=scantemp{1,4};
                     data_arr.t_utc=scantemp{1,1};
                     data_arr.t_obt=scantemp{1,2};
                     data_arr.qf=scantemp{1,5};
                     data_arr.printboolean=~dark_ind;
                     data_arr.probe=dark_ind;
                     data_arr.probe(:)=1;
                     
                    data_arr_out= an_NELprint(NELfname,NELshort,data_arr,t_et,tabindex{an_ind(i),3},timing,'vfloat');
                     
                 end%problematic macros
                 
                 
             else %if MODE == V
                 
                 %This is either VxL macros that have current bias or
                 %I1L, I2L, either ion or electron data.
                 
                 
                 data_arr=[];
                 data_arr.I=scantemp{1,3};
                 data_arr.t_utc=scantemp{1,1};
                 data_arr.t_obt=scantemp{1,2};
                 data_arr.qf=scantemp{1,5};
                 data_arr.printboolean=print_bool;
                 %data_arr.printboolean=~dark_ind&print_bool;
                 data_arr.dark_ind=dark_ind;
                 data_arr.probe(:)=1;
                 
                 data_arr_out=an_NELprint(NELfname,NELshort,data_arr,t_et,tabindex{an_ind(i),3},timing,'Ion');
                 
                 %%PRINT DOWNSAMPLED NEL?
                 UTCpart1 = scantemp{1,1}{1,1}(1:11);
                 % timing={scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end)};
                 % Set starting spaceclock time to (UTC) 00:00:00.000000
                 ah =str2double(scantemp{1,1}{1,1}(12:13));
                 am =str2double(scantemp{1,1}{1,1}(15:16));
                 as =str2double(scantemp{1,1}{1,1}(18:end)); %including fractions of seconds
                 hms = ah*3600 + am*60 + as;
                 tday0=scantemp{1,2}(1)-hms; %%UTC and Spaceclock must be correctly defined
                 
                 intval=32;
                 UTCpart2 = datestr(((1:3600*24/intval)-0.5)*intval/(24*60*60), 'HH:MM:SS.FFF'); % Calculate time of each interval, as fraction of a day
                 tfoutarr{1,1} = strcat(UTCpart1,UTCpart2);
                 tfoutarr{1,2} = [tday0 + ((1:3600*24/intval)-0.5)*intval];
                 
                 
                 afname =NELfname;
                 afname(end-10:end-8) =sprintf('%02iS',32);
                 
                 %affolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');
                 inter = 1 + floor((scantemp{1,2}(:) - tday0)/intval); %prepare subset selection to accumarray
                 
                 %Bugfix Issue #10.
                 inter(inter>2700)=2700;
                 
                 
                 fprintf(1,'printing %s, mode: %s\n',afname, mode);
                 
                 %this @mean function will output mean even if there is a single NaN
                 %value in the interval. This is what we want in this case, I
                 %believe.
                 N_ELmu = accumarray(inter,data_arr_out.N_EL,[],@mean,NaN); %select measurements during specific intervals, accumulate mean to array and print NaN otherwise
                 N_ELsd = accumarray(inter,data_arr_out.N_EL,[],@nanstd); %select measurements during specific intervals, accumulate mean to array and print NaN otherwise
                 N_ELqv = accumarray(inter,data_arr_out.qv,[],@mean); %select measurements during specific intervals, accumulate standard deviation to array and print zero otherwise
                 %        qf  = accumarray(inter,scantemp{1,5}(:),[],@(x) sum(unique(x)));
                 N_ELqf  = accumarray(inter,scantemp{1,5}(:),[],@(x) frejonbitor(x));
                 
                 N_ELmu(isnan(N_ELmu))=MISSING_CONSTANT;
                 
                 foutarr{1,3}( inter(1):inter(end), 1 ) = N_ELmu( inter(1):inter(end) ); %prepare for printing results
                 foutarr{1,4}( inter(1):inter(end), 1 ) = N_ELsd( inter(1):inter(end) );
                 foutarr{1,5}( inter(1):inter(end), 1 ) = N_ELqv( inter(1):inter(end) );
                 %foutarr{1,7}( inter(1):inter(end),1 ) = 1; %%flag to determine if row should be written.
                 foutarr{1,8}( inter(1):inter(end), 1 ) = N_ELqf(inter(1):inter(end));
                 foutarr{1,7}(unique(inter))=1; %%flag to determine if row should be written.
                 awID= fopen(afname,'w');
                 for j =1:length(foutarr{1,3})
                     
                     if foutarr{1,7}(j)~=1 %check if measurement data exists on row
                         %fprintf(awID,'%s, %16.6f,,,,\r\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
                         % Don't print zero values.
                     else
                         
                         fprintf(awID,'%s, %16.6f, %14.7e, %14.7e, %6.4f, %03i\r\n',tfoutarr{1,1}(j,:),tfoutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,8}(j));
                         
                     end%if
                     
                 end%for
                 
                 
                 
                 %                  an_tabindex{end+1,1} = afname;                   % Start new line of an_tabindex, and record file name
                 %                  an_tabindex{end,2} = strrep(afname,affolder,''); % shortfilename
                 %                  an_tabindex{end,3} = tabindex{an_ind(i),3}; % First calib data file index
                 %                  an_tabindex{end,4} = N_rows;                % length(foutarr{1,3}); % Number of rows
                 %                  an_tabindex{end,5} = 7;            % Number of columns
                 %                  an_tabindex{end,6} = an_ind(i);
                 %                  an_tabindex{end,7} = 'downsample'; % Type
                 %                  an_tabindex{end,8} = timing;
                 %                  an_tabindex{end,9} = row_byte;
                 fclose(awID);
                 clear tfoutarr foutarr
                 
                 %%PRINT DOWNSAMPLED NEL?
                 
             end %if MODE == V
             
             
        end%%if  NEL CONDTION
        
        






        %    oldUTCpart1 = UTCpart1; %stuff to remember next loop iteration
        %   count = count +1; %increment counter


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




%Copy of an_NEDprint.m but tweaked for NEL.TAB files
%FKJN: 24 May 2019
%frejon at irfu.se
%Input: filename, filenameshort, time, data,
%index_nr_of_of_first_file,timing for NED_TABINDEX, and mode
%mode = 'vfloat' or 'ion' or 'electron'
%Outputs NED.TAB files for the RPCLAP archive
%Depending on the mode, pre-made fits will be applied to create a density
%estimate. These fits should have large impact on quality values
%
function data_arr = an_NELprint(NELfname,NELshort,data_arr,t_et,index_nr_of_firstfile,timing,mode)

global NEL_tabindex MISSING_CONSTANT
fprintf(1,'printing %s, mode: %s\n',NELfname, mode);
%'hello'
%fprintf(1,'%s',time_arr{1,1}(1,:));


%fprintf(1,'printing: %s \r\n',NEDfname)
N_rows = 0;
row_byte=0;

switch mode
                
    
    
    
    case 'vfloat'
        
        load('NED_FIT.mat', 'NED_FIT');
        [t_et_end,NED_FIT_end]=max(NED_FIT.t_et);
        [t_et_min,NED_FIT_start]=min(NED_FIT.t_et);

    P_interp1= interp1(NED_FIT.t_et,NED_FIT.P(:,1),t_et);
    P_interp2= interp1(NED_FIT.t_et,NED_FIT.P(:,2),t_et);
    interp_qv= interp1(NED_FIT.t_et,NED_FIT.qv,t_et);

    indz_end=t_et>t_et_end;
    P_interp1(indz_end)= NED_FIT.P(NED_FIT_end,1);
    P_interp2(indz_end)= NED_FIT.P(NED_FIT_end,2);
    interp_qv(indz_end)= NED_FIT.qv(NED_FIT_end);

    indz_start=t_et<t_et_min;
    P_interp1(indz_start)= NED_FIT.P(NED_FIT_start,1);
    P_interp2(indz_start)= NED_FIT.P(NED_FIT_start,2);
    interp_qv(indz_start)= NED_FIT.qv(NED_FIT_start);


    data_arr.N_EL=data_arr.V;
    satind=data_arr.V==MISSING_CONSTANT;
    vj = -3;

    VS1 = -data_arr.V+5.5*exp(-data_arr.V/8); % correct USC to VS1 according to Anders' model. 
    VS1(-data_arr.V>0)=nan;  
    %del_ind=-data_arr.Vz>0;
    
    %I think we can safely assume that there are no Vph_knee data in Vfloat
    %mode. hopefully. Atleast it doesn't make sense to ffrom different
    %sources here

    
    data_arr.N_EL(~satind)=exp(P_interp2(~satind)).*exp((VS1(~satind).').*P_interp1(~satind));

    data_arr.N_EL(isnan(VS1))=MISSING_CONSTANT;
   
    %data_arr.N_EL(~satind)=exp(p2)*exp(-data_arr.V(~satind)*p1);
   % data_arr.N_EL(~satind)=exp(P_interp2(~satind)).*exp(-data_arr.V(~satind).*P_interp1(~satind));

    %factor=1; 
    %data_arr.V(~satind)=data_arr.V(~satind)*factor;
    NEL_flag=data_arr.probe;%This is the probenumber/product type flag
    %take this out of the loop
    qvalue=max(1-abs(2./data_arr.V(:)),0.5);
    %qvalue(satind)=0;
    
    data_arr.qv= qvalue.*interp_qv.';
    data_arr.qv(data_arr.N_EL<0) =0; 
    %qvalue(data_arr.N_EL<0) =0; 

    NELwID= fopen(NELfname,'w');

    for j =1:length(data_arr.V)
        
        if data_arr.printboolean(j)~=1 %check if measurement data exists on row
            % Don't print zero values.
        else

            row_byte= fprintf(NELwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.t_utc{j,1},data_arr.t_obt(j), data_arr.N_EL(j),data_arr.qv(j),NEL_flag(j),data_arr.qf(j));
%            row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',time_arr{1,1}(j,:),time_arr{1,2}(j),data_arr{1,5}(j),qvalue,usc_flag(j),data_arr{1,8}(j));

            N_rows = N_rows + 1;
        end%if
        
    end%for
    fclose(NELwID);
    
    
    NEL_tabindex(end+1).fname = NELfname;                   % Start new line of an_tabindex, and record file name
    NEL_tabindex(end).fnameshort = NELshort; % shortfilename
    NEL_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
    NEL_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
    NEL_tabindex(end).no_of_columns = 6;            % Number of columns
    NEL_tabindex(end).type = 'Vfloat'; % Type
    NEL_tabindex(end).timing = timing;
    NEL_tabindex(end).row_byte = row_byte;
    
    
    
    case 'vz'
        
        load('NED_FIT.mat', 'NED_FIT');
        [t_et_end,NED_FIT_end]=max(NED_FIT.t_et);
        [t_et_min,NED_FIT_start]=min(NED_FIT.t_et);
        
        P_interp1= interp1(NED_FIT.t_et,NED_FIT.P(:,1),t_et);
        P_interp2= interp1(NED_FIT.t_et,NED_FIT.P(:,2),t_et);
        interp_qv= interp1(NED_FIT.t_et,NED_FIT.qv,t_et);
        
        indz_end=t_et>t_et_end;
        P_interp1(indz_end)= NED_FIT.P(NED_FIT_end,1);
        P_interp2(indz_end)= NED_FIT.P(NED_FIT_end,2);
        interp_qv(indz_end)= NED_FIT.qv(NED_FIT_end);
        
        indz_start=t_et<t_et_min;
        P_interp1(indz_start)= NED_FIT.P(NED_FIT_start,1);
        P_interp2(indz_start)= NED_FIT.P(NED_FIT_start,2);
        interp_qv(indz_start)= NED_FIT.qv(NED_FIT_start);
        
        data_arr.N_EL=data_arr.Vz(:,1);
        satind=data_arr.Vz(:,1)==MISSING_CONSTANT;
        
        
        % Model normalizing to Vph:
        % vs = usc_v09.usc;
        % ind_map=(usc_v09.usc<0); %problems for usc>0, which only happens for misidentified vz
        % vs(ind_map) = usc_v09.usc(ind_map) + 5.5*exp(usc_v09.usc(ind_map)/8);
        % vj = -3;
        % %vs(vz > vj) = vph(vz > vj);
        % ind_vph= usc_v09.usc>vj&~isnan(usc_v09.Vph_knee)&usc_v09.Vph_knee_qv>0.3&usc_v09.Vph_knee>vj;
        % vs(ind_vph) = usc_v09.Vph_knee(ind_vph);
        VS1qv = data_arr.Vz(:,2);
        vj = -3;
        
        VS1 = -data_arr.Vz+5.5*exp(-data_arr.Vz/8);
        VS1(-data_arr.Vz>0)=nan; % these will be picked up soon
        ind_vph= data_arr.Vz(:,1)>vj&~isnan(data_arr.Vph_knee(:,1))&data_arr.Vph_knee(:,2)>0.3&data_arr.Vph_knee(:,1)>vj;
        VS1(ind_vph)=data_arr.Vph_knee(ind_vph,1);
        VS1qv(ind_vph) = data_arr.Vph_knee(ind_vph,2);
        
        data_arr.N_EL(~satind)=exp(P_interp2(~satind)).*exp(VS1(~satind).*P_interp1(~satind));
        %data_arr.N_EL(~satind)=exp(p2)*exp(-data_arr.V(~satind)*p1);
        % data_arr.N_EL(~satind)=exp(P_interp2(~satind)).*exp(-data_arr.Vz(~satind).*P_interp1(~satind));
        %data_arr.N_EL(~satind)=exp(p2)*exp(-data_arr.Vz(~satind,1)*p1);
        
        data_arr.N_EL(isnan(VS1))=MISSING_CONSTANT; %here we map them back to missing constant
        
        
        %find all extrapolation points: I don't want to change the an_swp
        %routine, so let's do the conversion here instead
        extrap_indz=data_arr.Vz(:,2)==0.2;
        data_arr.Vz(extrap_indz,2)=0.7; % change 0.2 to 0.7. I mean, it's clearly not several intersections.
        %and it survived ICA validation. It's clearly not as good quality as a detected zero-crossing though
        
        %prepare NED_flag
        NEL_flag=3*ones(1,length(data_arr.qf));
        NEL_flag(extrap_indz)=4;
        
        data_arr.qv= VS1qv.*interp_qv.';
        VS1qv(data_arr.N_EL<0) =0;
        data_arr.qv(data_arr.N_EL<0) =0;
        
        
        NELwID= fopen(NELfname,'w');
        
        for j = 1:length(data_arr.qf)
            % row_byte= sprintf('%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2},data_arr.N_EL(j),data_arr.Vz(j,2),NED_flag(j),data_arr.qf(j));
            
            if data_arr.lum(j) > 0.9 %shadowed probe data is not allowed
                % NOTE: data_arr.Tarr_mid{j,1}(j,1) contains UTC strings with 6 second decimals. Truncates to have the same
                % number of decimals as for case "vfloat". /Erik P G Johansson 2018-11-16
                row_byte= fprintf(NELwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2},data_arr.N_EL(j),data_arr.qv(j),NEL_flag(j),data_arr.qf(j));
                %row_byte= fprintf(NEDwID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',data_arr.Tarr_mid{j,1},data_arr.Tarr_mid{j,2},factor*data_arr.Vz(j),qvalue,data_arr.qf(j));
                N_rows = N_rows + 1;
            end
            
            
        end
        fclose(NELwID);
        
        
        NEL_tabindex(end+1).fname = NELfname;                   % Start new line of an_tabindex, and record file name
        NEL_tabindex(end).fnameshort = NELshort; % shortfilename
        NEL_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
        NEL_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
        NEL_tabindex(end).no_of_columns = 6;            % Number of columns
        NEL_tabindex(end).type = 'Vz'; % Type
        NEL_tabindex(end).timing = timing;
        NEL_tabindex(end).row_byte = row_byte;
        
        
            
            
    case 'Ion'
        
        
        
        load('NED_I_FIT.mat', 'NED_I_FIT');
        NED_FIT=NED_I_FIT;
        [t_et_end,NED_FIT_end]=max(NED_FIT.t_et);
        [t_et_min,NED_FIT_start]=min(NED_FIT.t_et);
        
        data_arr.N_EL=data_arr.I;
        satind=data_arr.I==MISSING_CONSTANT;

        
        P_interp1= interp1(NED_FIT.t_et,NED_FIT.P(:,1),t_et);
        P_interp2= interp1(NED_FIT.t_et,NED_FIT.P(:,2),t_et);
        interp_qv= interp1(NED_FIT.t_et,NED_FIT.qv,t_et);

        indz_end=t_et>t_et_end;
        P_interp1(indz_end)= NED_FIT.P(NED_FIT_end,1);
        P_interp2(indz_end)= NED_FIT.P(NED_FIT_end,2);
        interp_qv(indz_end)= NED_FIT.qv(NED_FIT_end);

        indz_start=t_et<t_et_min;
        P_interp1(indz_start)= NED_FIT.P(NED_FIT_start,1);
        P_interp2(indz_start)= NED_FIT.P(NED_FIT_start,2);
        interp_qv(indz_start)= NED_FIT.qv(NED_FIT_start);
        
        data_arr.N_EL(~satind)=(data_arr.I(~satind).'-P_interp2(~satind))./P_interp1(~satind);

        data_arr.N_EL(data_arr.dark_ind)=(data_arr.I(data_arr.dark_ind).')./P_interp1(data_arr.dark_ind);

        %prepare NED_flag
        NEL_flag=5;%This is the probenumber/product type flag
        
        qvalue=(data_arr.I);
%        qvalue(:)=1;
        
        %qvalue(~satind)=max(1-2*exp(-abs((data_arr.I(~satind).'./P_interp2(~satind)))),0);
        %qv = [0-1] = 1- exp(-(I-p2)/p2);

        %qvalue(~satind)=max(1-exp(1-(data_arr.I(~satind).'./P_interp2(~satind))),0);
        width= -2e-9;%1nA?
        qvalue(~satind)=max(1-exp(-(data_arr.I(~satind).'-P_interp2(~satind))./width),0);
        
        qvalue(data_arr.N_EL<0) =0;
        qvalue(data_arr.dark_ind)=0.9;
        
        data_arr.qv= qvalue.*interp_qv.';
        NELwID= fopen(NELfname,'w');

        for j =1:length(data_arr.I)
            
            if data_arr.printboolean(j)~=1 %check if measurement data exists on row

            else

                row_byte= fprintf(NELwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.t_utc{j,1},data_arr.t_obt(j), data_arr.N_EL(j),qvalue(j),NEL_flag,data_arr.qf(j));
                %            row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',time_arr{1,1}(j,:),time_arr{1,2}(j),data_arr{1,5}(j),qvalue,usc_flag(j),data_arr{1,8}(j));
                N_rows = N_rows + 1;
            end%if
            
        end%for
        fclose(NELwID);
        
        
        NEL_tabindex(end+1).fname = NELfname;                   % Start new line of an_tabindex, and record file name
        NEL_tabindex(end).fnameshort = NELshort; % shortfilename
        NEL_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
        NEL_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
        NEL_tabindex(end).no_of_columns = 6;            % Number of columns
        NEL_tabindex(end).type = 'Ion'; % Type
        NEL_tabindex(end).timing = timing;
        NEL_tabindex(end).row_byte = row_byte;
      
    otherwise
        fprintf(1,'Unknown Method:%s',mode);
     
end%switch mode        


    
fileinfo = dir(NELfname);
if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
  %  if N_rows > 0 %doublecheck!
        delete(NELfname); %will this work on any OS, any user?
        NEL_tabindex(end) = []; %delete tabindex listing to prevent errors.
   % end
    
else

end
end



function data_arr=NEL_combine_LAP1_LAP2(scantemp_1,scantemp_2,dark_ind_1,dark_ind_2,t_et1,t_et2)
data_arr=[];
                   
if length(scantemp_1{1,4}) < length(scantemp_2{1,4})
    data_arr.V=scantemp_2{1,4};
    data_arr.t_utc=scantemp_2{1,1};
    data_arr.t_obt=scantemp_2{1,2};
    data_arr.qf=scantemp_2{1,5};
    data_arr.printboolean=~dark_ind_2;
    data_arr.probe=2*ones(1,length(dark_ind_2));
    data_arr.t_et=t_et2;

 
    

else %default to LAP1, unless LAP2 is longer
    
    data_arr.V=scantemp_1{1,4};
    data_arr.t_utc=scantemp_1{1,1};
    data_arr.t_obt=scantemp_1{1,2};
    data_arr.qf=scantemp_1{1,5};
    data_arr.printboolean=~dark_ind_1;
    data_arr.probe=1*ones(1,length(dark_ind_2));

    data_arr.t_et=t_et1;
    

end



    if all(data_arr.printboolean)% is everything in sunlight on the longest (or default, LAP1) probe?
        
        return;
        %then return
    else
            fprintf(1,'Probe sometimes shadowed, switching probes \n');

        if length(scantemp_1{1,4}) < length(scantemp_2{1,4})
            scantemp_short=scantemp_1;
            dark_ind_short=dark_ind_1;
            %t_et_short = t_et1;
            probe_short=1;
        else
            scantemp_short=scantemp_2;
            dark_ind_short=dark_ind_2;
            %t_et_short = t_et2;
            probe_short=2;

        end
    end
    
    
    replace_these = ((~data_arr.printboolean).'&ismember(data_arr.t_obt,scantemp_short{1,2}));%  logical index of shadowed measurements, where measurements also exists in the other probe data
    
    %with_these= interp1(data_arr.t_et(replace_these),1:length(data_arr.t_et),t_et_short)
    
    %The other probe should not be in shadow if the other probe is in shadow.
    with_these= (ismember(scantemp_short{1,2},data_arr.t_obt(replace_these)));% works if the timing is EXACT. logical index
    %ismember gives a logical index of size(scantemp_short);
    
    if sum(replace_these)~=sum(with_these)
        fprintf(1,'error wrong lengths %i vs %i, continuing anyway with longest file\n',length(with_these),length(replace_these));
        return
    end
    data_arr.probe(replace_these)=probe_short;  %change probenumberflag
    data_arr.V(replace_these)=scantemp_short{1,4}(with_these);%  %this is vf2
    data_arr.printboolean(replace_these)=dark_ind_short(with_these);  %print boolean. It could be that both probes have invalid measurements.
    data_arr.qf(replace_these)=scantemp_short{1,5}(with_these);   %qflag
end

%     
% %%% PROBLEM HERE. V1L AND V2L DOES NEED TO BE EQUALLY
% %%% LONG. ESPECIALLY 710, 910.
% replace_these_lap1= (dark_ind_1~=1);
% ok_tokeep_theselap2 = (dark_ind_2==1);
% %the indices that are ok to keep is replaceind_lap1
% if length(scantemp_1{1,4})~=length(scantemp_2{1,4})
%     fprintf(1,'error wrong lengths %i vs lap2 %i',length(scantemp_1{1,4}),length(scantemp_2{1,4}))
% end
% indz=replace_these_lap1&ok_tokeep_theselap2; %only true if both lap1 in shadow and lap 2 in sunlight.
% 
% if sum(indz)>0
%     fprintf(1,'LAP1 sometimes shadowed, switching to LAP2 in file:%s \n',NELfname);
% end
% 
% %initialise foutarr.
% data_arr=[];
% data_arr.V=scantemp_1{1,4};
% data_arr.t_utc=scantemp_1{1,1};
% data_arr.t_obt=scantemp_1{1,2};
% data_arr.qf=scantemp_1{1,5};
% data_arr.printboolean=~dark_ind_1;
% data_arr.probe=dark_ind_1;
% data_arr.probe(:)=1;
% 
% %%default == probe 1.
% %here we went from LAP1 to LAP2,
% data_arr.probe(indz)=2;  %change probenumberflag
% data_arr.V(indz)=scantemp_2{1,4}(indz);%  %this is vf2
% data_arr.printboolean(indz)=dark_ind_2(indz);  %print boolean
% data_arr.qf(indz)=scantemp_2{1,5}(indz);   %qflag

%print NEL special case
%data_arr_out=an_NELprint(NELfname,NELshort,data_arr,data_arr.t_et,tabindex{an_ind(i),3},timing,'vfloat');
         
%end


                         
