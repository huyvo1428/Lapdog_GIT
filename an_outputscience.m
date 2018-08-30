

function []= an_outputscience(XXP)
global SATURATION_CONSTANT;
global ASW_tabindex
ASW_tabindex=[];
CONT_macros=[516;525;610;611;613;615;617;624;816;817;900;901;903;904;905;916;926];

iph0conditions=[];
iph0conditions.I_Vb=-17.0;%V from generating lap1 vector.
iph0conditions.I_Vb_eps=1.0;%V epsilon, from generating lap1vector
iph0conditions.time_window=1*60*60;%s  time window
iph0conditions.time_samples=20;%minimum samples in time window
iph0conditions.samples=11;%Samples minimum.
iph0conditions.CONT = +1.51e-9;
%default value of CONT = +1.51e-9;
% for i= 1:XXP(1).info.nroffiles
%
%       t0 = cellfun(@(x) datenum(strrep(x,'T',' ')),XXP(i).data.Tarr(:,1));
%
%
% % end
% flds= {'data.t0' 'Iph0' 'Tph' 'Te_exp_belowVknee' 'Vph_knee' 'ni_aion'...
%     'Illumination' 'Vbar' 'Vph_knee_lowAc' 'Vbar_lowAc' 'Qualityfactor' ...
%     'asm_ion_slope' 'old_Vx' 'old_Vsi' 'Vsi' 'macroId' 'ion_slope' 'curr' 'B'...
%     'asm_ne_5eV' 'asm_ni_v_dep'};

dataflds= {'t0' 'ion_slope' 'curr' 'B' 'Iph0' 'lum' 'qf'};
infoflds= {'macroId'};
PHO= struct_cleanup(XXP,infoflds,dataflds);

PHO= PHOTABFILE(PHO,iph0conditions,XXP);


for i = 1:XXP(1).info.nroffiles %AXP generation!
    len =length(XXP(i).data.Tarr(:,1));
    filename=XXP(i).info.file;
    filename(end-6:end-4)='ASW';
    
    twID = fopen(filename,'w+');
    
    %quickfix for ASW
    if ismember(XXP(i).info.macroId,CONT_macros)
        XXP(i).data.Iph0(:,1)=XXP(i).data.Iph0(:,1)+iph0conditions.CONT;
    end
    XXP(i).data.Iph0(isnan(XXP(i).data.Iph0(:,1)),1)=SATURATION_CONSTANT;
    
    %fix contamination issues)
    
    
    dummy_ne=SATURATION_CONSTANT;
    dummy_Te_XCAL=SATURATION_CONSTANT;
    dummy_qv=1.0;
    dummy_v_ion=SATURATION_CONSTANT;
    %dummy_qualityflag='XXXXXX1'; %use old flags instead of MAG
    for j = 1:len
        
        
        str1=sprintf('%s, %s, %16s, %16s,',XXP(i).data.Tarr{j,:});
        %str2=sprintf('%14.7e, %2.1f, %14.7e, %2.1f, %16.6f, %16.6f, %14.7e',dummy_ne,dummy_qv,XXP(i).data.Iph0(j,1),dummy_qv,dummy_v_ion,dummy_qv,XXP(i).data.Te_exp_belowVknee(j,1),dummy_qv,dummy_Te_XCAL,dummy_qv);
        str2=sprintf(' %14.7e, %2.1f,',dummy_ne,dummy_qv);
        str3=sprintf(' %14.7e, %2.1f,',XXP(i).data.Iph0(j,1),dummy_qv);
        str4=sprintf(' %14.7e, %2.1f,',dummy_v_ion,dummy_qv);
        str5=sprintf(' %14.7e, %2.1f,',XXP(i).data.Te_exp_belowVknee(j,1),dummy_qv);
        str6=sprintf(' %14.7e, %2.1f,',dummy_Te_XCAL,dummy_qv);
        str7=sprintf(' %14.7e, %2.1f,',XXP(i).data.Vph_knee(j,1),dummy_qv);
        str8=sprintf(' %05i',XXP(i).data.qf(j));
        
        strtot=strcat(str1,str2,str3,str4,str5,str6,str7,str8);
        row_bytes= fprintf(twID,'%s\r\n',strtot);
    end
    folder = strrep(XXP(i).info.file,XXP(i).info.shortname,'');
    
    ASW_tabindex(end+1).fname = filename;                   % Start new line of an_tabindex, and record file name
    ASW_tabindex(end).fnameshort = strrep(filename,folder,''); % shortfilename
    %PHO_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
    ASW_tabindex(end).no_of_rows = len;                % length(foutarr{1,3}); % Number of rows
    ASW_tabindex(end).no_of_columns = 15;            % Number of columns
    % usc_tabindex{end,6] = an_ind(i);
    ASW_tabindex(end).type = 'ASW'; % Type
    ASW_tabindex(end).timing = XXP(i).info.timing;
    ASW_tabindex(end).row_byte = row_bytes;
    
    fclose(twID);
end
end



function resampled = PHOTABFILE(lapstruct,conditions,XXP)
%takes a SORTED struct with A1S fields, groups them and computes iph0 via
%niklas multi sweep method.
global PHO_tabindex
global SATURATION_CONSTANT;

out= fixlap1_cont_iph0(lapstruct,conditions.CONT); % check for contamination & prepare output
an_diag = 0;

%niklas iph_calc.m revisited

resampled=[];
resampled.ind=[];
resampled.curr=[];
resampled.ion_slope=[]; 
resampled.conds=conditions;


%%%--------illumination check------------------------%%%
dynampath = strrep(mfilename('fullpath'),'an_outputscience','');
kernelFile = strcat(dynampath,'metakernel_rosetta.txt');
paths(); 

cspice_furnsh(kernelFile);




intval = resampled.conds.time_window;%seconds


% 
% resampled.conds=[];
% resampled.conds.I_Vb=-17.0;%V from generating lap1 vector.
% resampled.conds.I_Vb_eps=1.0;%V epsilon, from generating lap1vector
% resampled.conds.time_window=2*60*60;%s  time window
% resampled.conds.time_samples=10;%minimum samples in time window
% resampled.conds.samples=10;%Samples minimum.
% 
      %  UTCpart1= XXP(1).info.timing{1,1}(1:11);
        %UTCpart1 = scantemp{1,1}{1,1}(1:11);
      %  utc_str= XXP(1).timing{1,1};
      %  utc_str= XXP(1).info.timing{1,1};%this is start of file
        % utc_str=XXP(1).data.Tarr{1,1}; %this is start of first sweep data point, slightly different
  
        utc_str=cspice_et2utc(lapstruct.t0(1),'ISOC',6)
        
        
        % Set starting spaceclock time to (UTC) 00:00:00.000000
        ah= str2double(utc_str(12:13))
        am= str2double(utc_str(15:16))
        as= str2double(utc_str(18:end))

       % ah =str2double(scantemp{1,1}{1,1}(12:13));
       % am =str2double(scantemp{1,1}{1,1}(15:16));
       % as =str2double(scantemp{1,1}{1,1}(18:end)); %including fractions of seconds
        hms = ah*3600 + am*60 + as;
        %tday0=scantemp{1,2}(1)-hms; %%UTC and Spaceclock must be correctly defined
        t_obt0= str2double(XXP(1).data.Tarr{1,3})-hms; %%epoch UTC and Spaceclock must be correctly defined
        t_et0= lapstruct.t0(1)-hms; %%epoch, UTC and Spaceclock must be correctly defined

     %t0 is "et" time of each measurement (start of sweep)
     inter = 1 + floor((lapstruct.t0(:) - t_et0)/intval); %prepare subset selection to accumarray
     

startind=inter(1);
groupind=[];



rowcount=0;
qf_array  = accumarray(inter,lapstruct.qf,[],@(x) frejonbitor(unique(x)));


%len=row; % row is incremented to max row nr, but incase I forget.
%for i=1:len
k=0;
%for i = inter(1):inter(end)
%sometimes lapstruct.t0 is not sorted...?
%t_etz=floor(t_et0+(intval* (min(inter):max(inter)))+0.5);%maybe slightly incorrect. ugh.
t_etz=t_et0+intval/2+(intval* (min(inter):max(inter)));%midpoint of interval                                        

%                               ((1:3600*24/intval)-0.5)*intval

t_obtz= t_obt0 +intval+(intval*(min(inter):max(inter)));%midpoint of interval
t_utc= cspice_et2utc(t_etz(:).'+0.5, 'ISOC', 6);% buffer up with 0.5 second, before UTC conversion, and then round to closest second later in function
t_matlab_date=nan(length(t_etz),1);
for i = 1:length(t_etz)
    t_matlab_date(i)=datenum(strrep(t_utc(i,:),'T',' '));
end

    
  %  save ~/matlabdump_utc.mat t_utc t_matlab_date
    
for i = min(inter):max(inter) %main for loop

    k=k+1;
    indz=find(inter==i);

    
    %indz= resampled.ind(i,:); % a lot of extra zeroes in resampled.ind... need to get rid of them.
   % indz(indz==0)=[]; %array of grouped indices. 
    if ~isempty(indz)
    colz=1:length(indz);
    
    %%single sweep method resampling
    
   % resampled.median.iph0(i)=nanmedian(lapstruct.Iph0(indz));
    %resampled.median.sigma_iph0(i)=nanstd(lapstruct.Iph0(indz));
    %resampled.mean.iph0(i)=nanmean(lapstruct.Iph0(indz));
    %resampled.mean.sigma_iph0(i)=nanstd(lapstruct.Iph0(indz));
    %%
    
    resampled.curr(k,colz)=lapstruct.curr(indz);
    curr= resampled.curr(k,colz).';
    %curr = lapstruct.curr(indz);
    resampled.ion_slope(k,colz)=lapstruct.ion_slope(indz,1);
    ion_slope = resampled.ion_slope(k,colz).';
   % ion_slope = lapstruct.ion_slope(indz,1); %need non structure variables.
    resampled.t0(k,colz) = lapstruct.t0(indz);    
    resampled.t_epochmean(k)=mean(resampled.t0(k,colz));
    resampled.t_epoch(k)=t_et0+intval*i;
    resampled.t_OBT(k) = t_obt0 + intval*i;
  %  resampled.macroId = mean(lapstruct.macroId(indz));
    
    %remove shadowed, and unrealistic ionslopes
    
    %delind=find((lapstruct.lum(indz)<0.9) | ion_slope <0 | isnan(ion_slope) | isnan(curr));
    delind=(lapstruct.lum(indz)<0.9) | ion_slope <0 | isnan(ion_slope) | isnan(curr);   
    curr(delind)=[]; %delind is the indexes of the group of index indz which are invalid
    ion_slope(delind)=[];
    
    if ge(length(curr),resampled.conds.samples) %if length >= 10 e.g.
        
%         [P,S]= polyfit(ion_slope,curr,1);
%         %       p = polyfit(currprim,curr,1); %
%   
%         rms_tmp = std(polyval(P,ion_slope)-curr);
%         %Remove outliers
%         %ind2 = find(abs(polyval(P,ion_slope)-curr) > 3.5*rms_tmp);
%         



%        ind2 = (abs(polyval(P,ion_slope)-curr) > 3.5*rms_tmp) | (abs(ion_slope-nanmedian(ion_slope))>1*nanstd(ion_slope));
%         outlierind = (abs(curr-nanmedian(curr))> 3*nanstd(curr))| (abs(ion_slope-nanmedian(ion_slope))>1*nanstd(ion_slope));
% 
%         %outliers indicate that the plasma and ion current changed
%         %substantially or that the ion_slope estimate was poorly made                     
% 
%         curr(outlierind)=[];
%         ion_slope(outlierind)=[];
%         
%        % pfit = polyfit(currprim,curr,1);
%               
        % if  ge(length(curr),resampled.conds.samples) 
           %[P2,S2]= polyfit(ion_slope,curr,1);
           
           [P2, outliers,S2] = fit_ols_ESD(ion_slope, curr); %new fitting routine with outlier removal.

           resampled.P(k,1:2) = P2;
           %resampled.S(i) = S2;
      % end
        
        
      if an_diag
      
          figure(2001);plot(ion_slope,curr,'o',ion_slope,polyval(P2,ion_slope),ion_slope,polyval(polyfit(ion_slope,curr,1),ion_slope),'-b')
          ax=gca;
          legend('data','fit OLS ESD','polyfit')
          ax.XLabel.String='ion slope [A/V]';
          ax.YLabel.String='current [A]';
          hline(P2(2),'-','Iph0');
          grid on;

          
      end
      
      
      
        %if too few points remain after outlier removal, or the slope is
        %unphysical, enter nan values. else:
        if ge(length(curr(~outliers)),resampled.conds.samples) && P2(1) < 0 %; %if length >= 10 e.g. 
        %if ge(length(curr),resampled.conds.samples) && P2(1) < 0 %; %if length >= 10 e.g. 
            
            
            resampled.iph0(k) = P2(2);% this is apparently iph0.
            try
                S2.sigma = sqrt(diag(inv(S2.R)*inv(S2.R')).*S2.normr.^2./S2.df);
                resampled.iph0_sigma(k) = S2.sigma(2);
                
            catch err %horrible try catch.
                resampled.iph0_sigma(k) = nan;
            end
            
            %resampled.iph0_sigma(i) = S2.sigma(2);
        else
            resampled.iph0(k) = SATURATION_CONSTANT;% fill with nan.
            resampled.iph0_sigma(k) = nan;
            
        end
        
    else
        
        resampled.iph0(k) = SATURATION_CONSTANT;% fill with nan.
        resampled.iph0_sigma(k) = nan;
        resampled.P(k,1:2) = nan;
        
    end
    
    
    %% add to file
       
    
    

    
    end
    

    dirY = datestr(t_matlab_date(k),'YYYY');
    dirM = upper(datestr(t_matlab_date(k),'mmm'));
    dirD = strcat('D',datestr(t_matlab_date(k),'dd'));

%    dirY = datestr(resampled.t_epoch(k),'YYYY');
%    dirM = upper(datestr(resampled.t_epoch(k),'mmm'));
%    dirD = strcat('D',datestr(resampled.t_epoch(k),'dd'));
    folder = strcat(XXP(1).info.derivedpath,dirY,'/',dirM,'/',dirD,'/');
    
    filename = sprintf('%sRPCLAP_%s_000000_60M_PHO.TAB',folder,datestr(t_matlab_date(k),'yyyymmdd'));
%         
%     
%     if k>1 && ~strcmp(datestr(resampled.t_epoch(k-1),'dd'), datestr(resampled.t_epoch(k),'dd')) %%new calendar day? (won't check j==1)
%         %   newfile =false;
%         twID = fopen(filename,'w');
%         
%     PHO_tabindex(end+1).fname = filename;                   % Start new line of an_tabindex, and record file name
%     PHO_tabindex(end).fnameshort = strrep(filename,folder,''); % shortfilename
%     %PHO_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
%     PHO_tabindex(end).no_of_rows = rowcount;                % length(foutarr{1,3}); % Number of rows
%     PHO_tabindex(end).no_of_columns = 5;            % Number of columns
%     % usc_tabindex{end,6] = an_ind(i);
%     PHO_tabindex(end).type = 'USC'; % Type
%     PHO_tabindex(end).timing = timing;
%     PHO_tabindex(end).row_byte = row_byte;
%         
%         rowcount=0;
% 
%     else
%         twID = fopen(filename,'a+'); %new file.
%     end
%    % utc= cspice_et2utc(resampled.t_epoch(k), 'ISOC', 6);
%     
%    % row_byte= fprintf(twID,'%s, %16.6f, %14.7e, %3.1f, %05i', utc, resampled.t_OBT(k), resampled.iph0(k),dummy_qv,qf_array(k));
%        
%
    if ~(exist(folder,'dir')~=7) %folder doesn't exist, we've gone outside of archive



        if k>1 && ~strcmp(datestr(t_matlab_date(k-1),'dd'), datestr(t_matlab_date(k),'dd')) %%new calendar day? (won't check j==1)
            %   newfile =false;
            fclose(twID); %close old file
            
            twID = fopen(filename,'w'); %open a new file, filename is now a different string.
            

            
            PHO_tabindex(end+1).fname = filename;                   % Start new line of an_tabindex, and record file name
            PHO_tabindex(end).fnameshort = strrep(filename,folder,''); % shortfilename
            %PHO_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
            PHO_tabindex(end).no_of_rows = rowcount;                % length(foutarr{1,3}); % Number of rows
            PHO_tabindex(end).no_of_columns = 5;            % Number of columns
            % usc_tabindex{end,6] = an_ind(i);
            PHO_tabindex(end).type = 'USC'; % Type
            %PHO_tabindex(end).timing = timing;
            PHO_tabindex(end).row_byte = row_byte;

            rowcount=0;
           % fprintf(1,'w+ opening file: %s\r\n',filename)

        else


            twID = fopen(filename,'a+'); %new file.
           %fprintf(1,'a+ opening file: %s\r\n',filename)
        end

        dummy_qv=0.5;

        if (isempty(indz) && (rowcount>0))   % nothing here & file open. fill with SATURATION_CONSTANT
           % t_utc(end-8:end)='59.999797';
            t_utc(k,end-8:end)='00.000000';

            row_byte= fprintf(twID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n', t_utc(k,:), t_obtz(k), SATURATION_CONSTANT,0,qf_array(k));
            rowcount=rowcount+1;

        elseif (~isempty(indz))
            t_utc(k,end-8:end)='00.000000';
            row_byte= fprintf(twID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n', t_utc(k,:), resampled.t_OBT(k), resampled.iph0(k),dummy_qv,qf_array(k));
            rowcount=rowcount+1;

        else
            %first file in array, no valid points.

        end
        
        
        
        
        
    end%folder doesn't exist, we've gone outside of archive

%         if(~isempty(indz))  % Print values!
% 
%             row_byte= fprintf(twID,'%s, %16.6f, %14.7e, %3.1f, %05i', utc, resampled.t_OBT(k), resampled.iph0(k),dummy_qv,qf_array(k));
%             rowcount=rowcount+1;
% 
% 
%         else % nothing here. fill with SATURATION_CONSTANT
%             row_byte= fprintf(twID,'%s, %16.6f, %14.7e, %3.1f, %05i', utc, t_obtz(k), SATURATION_CONSTANT,0,qf_array(k));
%             rowcount=rowcount+1;
% 
% 
%         end%print value or NaN

end%main loop


for i = 1:length(PHO_tabindex)%clean up empty files
    
    if PHO_tabindex(i).no_of_rows == 0
        D= dir(PHO_tabindex(i).fname);
        
        fprintf(1,'%s size is %i',PHO_tabindex(i).fname,D.bytes);
        delete PHO_tabindex(end).fname;
    end
end


 cspice_kclear;

end%function

function lapstruct_fixed = fixlap1_cont_iph0(lapstruct,CONT)
%default value of CONT = +1.51e-9;

% old_iph0.Vbias(ind)=  +20;%          515
% old_iph0.Vbias(ind)=+30;%          516
% old_iph0.Vbias(ind)=+30;%          525
% old_iph0.Vbias(ind)=  +20;%          604
% old_iph0.Vbias(ind)=+30;%          610
% old_iph0.Vbias(ind)=+30;%          611
% old_iph0.Vbias(ind)=+30;%          613
% old_iph0.Vbias(ind)=+30;%          615
% old_iph0.Vbias(ind)=+30;%          617
% old_iph0.Vbias(ind)=+30;%          624
% old_iph0.Vbias(ind)=+30;%          816
% old_iph0.Vbias(ind)=+30;%          817
% old_iph0.Vbias(ind)=+30;%          900
% old_iph0.Vbias(ind)=+30;%          901
% old_iph0.Vbias(ind)=+30;%          903
% old_iph0.Vbias(ind)=+30;%          904
% old_iph0.Vbias(ind)=+30;%          905
% old_iph0.Vbias(ind)=+30;%          916
% old_iph0.Vbias(ind)=+30;%          926
lapstruct_fixed=lapstruct;

cont_macros=[516;525;610;611;613;615;617;624;816;817;900;901;903;904;905;916;926];


ind=ismember(lapstruct.macroId,cont_macros);

lapstruct_fixed.Iph0(ind)=lapstruct_fixed.Iph0(ind)+CONT;
lapstruct_fixed.curr(ind,:) = lapstruct.curr(ind,:)+CONT;

end

function lapfile= struct_cleanup(dataraw,infofields,datafields)
%lapfile takes a horrible massive struct called dataraw from readAxS_prelim
% and polishes, removing any struct field that is not named in the "flds"
% parameter list. The code was made to output averages and medians per file
% as well.
% if the flds listed do not contain "B" or "curr" then
% lapfile_with_iph0_niklas will not work

infolenflds = length(infofields);
datalenflds = length(datafields);

%lenI = length(fldI);

lapfile=[];
% meand1=[];
% mediand1=[];
std1=[];
%std=[];
% 
% for j=1:length(dataraw)
%     
%     if ~isempty(dataraw(j).strID)
% 
%         lapfile.strID=dataraw(j).strID;
%         break; %exit loop early when we find a value that is not erroneous, we only need one.
%     end
% end


for j=1:length(dataraw)

  %  j
    if j <2
        
        
        for k=1:infolenflds
            lapfile.(sprintf('%s',infofields{1,k})) =[dataraw(j).info.(sprintf('%s',infofields{1,k}))];

        end
        
                
        for k=1:datalenflds
            lapfile.(sprintf('%s',datafields{1,k})) =[dataraw(j).data.(sprintf('%s',datafields{1,k}))];

        end
        
           lapfile.Tarr=dataraw(j).data.Tarr; %special case for this parameter

        
    else
        
          lapfile.Tarr=vertcat(lapfile.Tarr, dataraw(j).data.Tarr); %special case for this parameter

        

        for k=1:infolenflds
          lapfile.(sprintf('%s',infofields{1,k})) = [[lapfile.(sprintf('%s',infofields{1,k}))];[dataraw(j).info.(sprintf('%s',infofields{1,k}))]];
            
       
        end
        for k=1:datalenflds
           lapfile.(sprintf('%s',datafields{1,k})) = [[lapfile.(sprintf('%s',datafields{1,k}))];[dataraw(j).data.(sprintf('%s',datafields{1,k}))]];
            
       
        end
        
        
        
        



        
    end
    
    
end

%lapfile.mean=meand1;
%lapfile.median=mediand1;

end

function out = fixlapstruct(lapstruct,CONT)


end

function out= UXPfile(var_ind)
%this file needs all Vph_knee*, and all Vfloat measurements in archive.
%or AP.Vz, V_sc from ion slope
%or DP.Vsi 


end



function x=frejonbitor(A)

len = length(A);
x=uint32(A(1));


if len>1

    for i = 1:len
    x=bitor(x,uint32(A(i)));
    end
end




end
