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
print32S =1; %enable this for 32S downsampled ion NEL files (32S_NEL.TAB)

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
 
                 if print32S
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
                 end%if print32S
                 
                 
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
    data_arr.probe=1*ones(1,length(dark_ind_1));
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
    data_arr.printboolean(replace_these)=~dark_ind_short(with_these);  %print boolean. It could be that both probes have invalid measurements.
    data_arr.qf(replace_these)=scantemp_short{1,5}(with_these);   %qflag
end



                         
