%function modeled frm an_downsample. Removed all the downsample part.
%suggestion: move an_EFL here as well?
function []= an_NPL(an_ind,tabindex,index)
%function []= an_downsample(an_ind,tabindex,intval)

%%count = 0;
%oldUTCpart1 ='shirley,you must be joking';

%global an_tabindex;
global target

%antemp ='';

%foutarr=cell(1,7);

dynampath = strrep(mfilename('fullpath'),'/an_NPL','');

kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
hold_flag=0;
i=1; %
j=0;

global SATURATION_CONSTANT VFLOATMACROS


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
        %macroNodex=dec2hex(macroNo);
        %macroNostr=dec2hex(index(tabindex{an_ind(i) ,3}).macro);
        %          dec2hex(index(tabindex{ind_V1L(1),3}).macro)




        %%%%-----------------USC/NPL CHECK------------------------------------%
        %fprintf(1,'checking %x, vs %x',macroNo,VFLOATMACROS(:,probenr))
        if  mode =='V' && ismember(macroNo,VFLOATMACROS{probenr})



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

        timing={scantemp{1,1}{1,1},scantemp{1,1}{end,1},scantemp{1,2}(1),scantemp{1,2}(end)};


        afname =tabindex{an_ind(i),1};
        %afname(end-10:end-8) =sprintf('%02iS',intval);


        %afname = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),1}(end-10:end-8),sprintf('%02iS',intval));
        %afname(end-4) = 'D';
        affolder = strrep(tabindex{an_ind(i),1},tabindex{an_ind(i),2},'');

        mode = afname(end-6);


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
%             USCfname(end-6:end-4)='USC';
            NPLfname=tabindex{an_ind(i),1};
            NPLfname(end-6:end-4)='NPL';

%             USCshort=strrep(USCfname,affolder,'');
            NPLshort=strrep(NPLfname,affolder,'');
% 
% 
%             foutarr{1,2}=foutarr{1,7};
             %scantemp{1,3}(:) = probenr; % I'm hijacking this array to show the probenumber


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
                    else
                        scantemp_2=scantemp;
                        dark_ind_2=dark_ind;
                        %tfoutarr_2=tfoutarr; %only need this for debug
                    end
  
                    
                    %%% PROBLEM HERE. V1L AND V2L DOES NEED TO BE EQUALLY
                    %%% LONG. ESPECIALLY 710, 910.
                    replace_these_lap1= (dark_ind_1~=1);
                    ok_tokeep_theselap2 = (dark_ind_2==1);
                    %the indices that are ok to keep is replaceind_lap1
                    if length(scantemp_1{1,4})~=length(scantemp_2{1,4})
                        fprintf(1,'error wrong lengths %i vs lap2 %i',length(scantemp_1{1,4}),length(scantemp_2{1,4}))
                    end
                    indz=replace_these_lap1&ok_tokeep_theselap2; %only true if both lap1 in shadow and lap 2 in sunlight.

                    if sum(indz)>0
                        fprintf(1,'LAP1 sometimes shadowed, switching to LAP2 in file:%s \n',NPLfname);
                    end

                    %initialise foutarr.
                        data_arr=[];
                        data_arr.V=scantemp_1{1,4};
                        data_arr.t_utc=scantemp_1{1,1};
                        data_arr.t_obt=scantemp_1{1,2};
                        data_arr.qf=scantemp_1{1,5};
                        data_arr.printboolean=~dark_ind_1;
                        data_arr.probe=dark_ind_1;
                        data_arr.probe(:)=1;

                        %%default == probe 1.
                        %here we went from LAP1 to LAP2,
                        data_arr.probe(indz)=2;  %change probenumberflag
                        data_arr.V(indz)=scantemp_2{1,4}(indz);%  %this is vf2
                        data_arr.printboolean(indz)=dark_ind_2(indz);  %print boolean
                        data_arr.qf(indz)=scantemp_2{1,5}(indz);   %qflag

                    %print NPL special case
                    an_NPLprint(NPLfname,NPLshort,data_arr,t_et,tabindex{an_ind(i),3},timing,'vfloat');


                    clear scantemp_1 scantemp_2

                else% hold_flag
                    %hold_flag default is 0. So this is 1st iteration

                    if probenr==1
                        scantemp_1=scantemp;
                        dark_ind_1=dark_ind;
                    else
                        scantemp_2=scantemp;
                        dark_ind_2=dark_ind;
                    end

                    hold_flag = 1;

                end% hold_flag

            else%no problem, just output data.
            %print NPL normal case
            %initialise foutarr.
            data_arr=[];
            data_arr.V=scantemp{1,4};
            data_arr.t_utc=scantemp{1,1};
            data_arr.t_obt=scantemp{1,2};
            data_arr.qf=scantemp{1,5};
            data_arr.printboolean=~dark_ind;
            data_arr.probe=dark_ind;
            data_arr.probe(:)=1;

            an_NPLprint(NPLfname,NPLshort,data_arr,t_et,tabindex{an_ind(i),3},timing,'vfloat');

            end


        else

              %This is either VxL macros that have current bias or
              %I1L, I2L, either ion or current data.
              
            
            


        end







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


%Copy of an_USCprint.m but tweaked for NPL.TAB files
%FKJN: 14 March 2019
%frejon at irfu.se
%Input: filename, filenameshort, time, data,
%index_nr_of_of_first_file,timing for NPL_TABINDEX, and mode
%mode = 'vfloat' or 'ion' or 'electron'
%Outputs NPL.TAB files for the RPCLAP archive
%Depending on the mode, pre-made fits will be applied to create a density
%estimate. These fits should have large impact on quality values
%
function [] = an_NPLprint(NPLfname,NPLshort,data_arr,t_et,index_nr_of_firstfile,timing,mode)

global NPL_tabindex SATURATION_CONSTANT

fprintf(1,'printing %s, mode: %s\n',NPLfname, mode);
%'hello'
%fprintf(1,'%s',time_arr{1,1}(1,:));





%fprintf(1,'printing: %s \r\n',NPLfname)
NPLwID= fopen(NPLfname,'w');
N_rows = 0;
row_byte=0;
switch mode
        
        
    case 'vfloat'        
%if strcmp(mode,'vfloat')

    load('usc_resampled_fit.mat', 'USC_FIT');

    
    %BASIC SOLUTION ONLY LOOKS FOR CLOSEST POINT
    [junk,ind]= min(abs(USC_FIT.t_et-t_et(1)));
        
    p1=USC_FIT.P(ind,1);
    p2=USC_FIT.P(ind,2);
    %y1 = exp(p2)*exp(usc.usc(indz)*p1);
    data_arr.NPL=data_arr.V;
    satind=data_arr.V==SATURATION_CONSTANT;
    
    data_arr.NPL(~satind)=exp(p2)*exp(data_arr.V(~satind)*p1);
    %factor=1; 
    %data_arr.V(~satind)=data_arr.V(~satind)*factor;
    NPL_flag=data_arr.probe;%This is the probenumber/product type flag
    for j =1:length(data_arr.V)
        
        if data_arr.printboolean(j)~=1 %check if measurement data exists on row
            %fprintf(awID,'%s, %16.6f,,,,\r\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
            % Don't print zero values.
        else
            qvalue=1;
            %data_arr.V(j)=SATURATION_CONSTANT;
            row_byte= fprintf(NPLwID,'%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',data_arr.t_utc{j,1}(1:26),data_arr.t_obt(j), data_arr.NPL(j),qvalue,NPL_flag(j),data_arr.qf(j));
            N_rows = N_rows + 1;
        end%if
        
    end%for
    fclose(NPLwID);
    
    
    NPL_tabindex(end+1).fname = NPLfname;                   % Start new line of an_tabindex, and record file name
    NPL_tabindex(end).fnameshort = NPLshort; % shortfilename
    NPL_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
    NPL_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
    NPL_tabindex(end).no_of_columns = 6;            % Number of columns
    NPL_tabindex(end).type = 'Vfloat'; % Type
    NPL_tabindex(end).timing = timing;
    NPL_tabindex(end).row_byte = row_byte;
    
    
    
    case 'Ion'
        
        
        factor=-1; %Vz data is being outputted by bias potential it is identified on,
        %so opposite sign applies. However, if we want to change this from 
        %a proxy to a Spacecraft potential, we could manipulate this factor.
        %possibly to something like 1/0.8, or something.
        
        satind=data_arr.Vz(:,1)==SATURATION_CONSTANT;
        %data_arr.Vz(satind,1)=data_arr.Vz(satind,1)*sign(factor); %either -1 or 1. will later be multiplied with 1, such that -1000 is still the only valid saturation constant
        data_arr.Vz(~satind,1)=factor*data_arr.Vz(~satind,1);
        %Vz= data_arr.Vz;
        %time= data_arr.Tarr_mid
        %qvalue=0.7;
        
        %find all extrapolation points: I don't want to change the an_swp
        %routine, so let's do the conversion here instead
        extrap_indz=data_arr.Vz(:,2)==0.2;
        data_arr.Vz(extrap_indz,2)=0.7; % change 0.2 to 0.7. I mean, it's clearly not several intersections. 
        %and it survived ICA validation. It's clearly not as good quality as a detected zero-crossing though
        
        %prepare NPL_flag
        NPL_flag=3*ones(1,length(data_arr.qf));
        NPL_flag(extrap_indz)=4;
        
        for j = 1:length(data_arr.qf)
            
            if data_arr.lum(j) > 0.9 %shadowed probe data is not allowed
                % NOTE: data_arr.Tarr_mid{j,1}(j,1) contains UTC strings with 6 second decimals. Truncates to have the same
                % number of decimals as for case "vfloat". /Erik P G Johansson 2018-11-16
                row_byte= fprintf(NPLwID,'%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2},data_arr.Vz(j,1),data_arr.Vz(j,2),NPL_flag(j),data_arr.qf(j));
                %row_byte= fprintf(NPLwID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',data_arr.Tarr_mid{j,1},data_arr.Tarr_mid{j,2},factor*data_arr.Vz(j),qvalue,data_arr.qf(j));
                N_rows = N_rows + 1;
            end
            
            
        end
        


            
end        
            NPL_tabindex(end+1).fname = NPLfname;                   % Start new line of an_tabindex, and record file name
            NPL_tabindex(end).fnameshort = NPLshort; % shortfilename
            NPL_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
            NPL_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
            NPL_tabindex(end).no_of_columns = 6;            % Number of columns
            % NPL_tabindex{end,6] = an_ind(i);
            NPL_tabindex(end).type = 'Ion'; % Type
            NPL_tabindex(end).timing = timing;
            NPL_tabindex(end).row_byte = row_byte;
        
    
fileinfo = dir(NPLfname);
if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
  %  if N_rows > 0 %doublecheck!
        delete(NPLfname); %will this work on any OS, any user?
        NPL_tabindex(end) = []; %delete tabindex listing to prevent errors.
   % end
    
else

end


        
        


%elseif  strcmp(mode,'vfloat')


    %fprintf(1,'error, wrong mode: %s\r\n',mode');
end






