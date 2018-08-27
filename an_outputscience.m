

function []= an_outputscience(XXP)
global SATURATION_CONSTANT;
iph0conditions=[];
iph0conditions.I_Vb=-17.0;%V from generating lap1 vector.
iph0conditions.I_Vb_eps=1.0;%V epsilon, from generating lap1vector
iph0conditions.time_window=3*60*60;%s  time window
iph0conditions.time_samples=20;%minimum samples in time window
iph0conditions.samples=20;%Samples minimum.
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

dataflds= {'t0' 'ion_slope' 'curr' 'B' 'Iph0'};
infoflds= {'macroId'};
PXP= struct_cleanup(XXP,infoflds,dataflds);

PXP= niklas_iph0_resampled(PXP,iph0conditions);


for i = 1:XXP(1).info.nroffiles %AXP generation!
    len =length(XXP(i).data.Tarr(:,1));
    filename=XXP(i).info.file;
    filename(end-6:end-4)='ASW';
    %twID = fopen(filename,'w');
    
    dummy_ne=SATURATION_CONSTANT;
    dummy_Te_XCAL=SATURATION_CONSTANT;
    dummy_qv=1.0;
    dummy_v_ion=SATURATION_CONSTANT;
    %dummy_qualityflag='XXXXXX1'; %use old flags instead of MAG
    for j = 1:len
        
        
        str1=sprintf('%s, %s, %16s, %16s',XXP(i).data.Tarr{1,:});
        %str2=sprintf('%14.7e, %2.1f, %14.7e, %2.1f, %16.6f, %16.6f, %14.7e',dummy_ne,dummy_qv,XXP(i).data.Iph0(j,1),dummy_qv,dummy_v_ion,dummy_qv,XXP(i).data.Te_exp_belowVknee(j,1),dummy_qv,dummy_Te_XCAL,dummy_qv);
        str2=sprintf(' %14.7e, %2.1f,',dummy_ne,dummy_qv);
        str3=sprintf(' %14.7e, %2.1f,',XXP(i).data.Iph0(j,1),dummy_qv);
        str4=sprintf(' %14.7e, %2.1f,',dummy_v_ion,dummy_qv);
        str5=sprintf(' %14.7e, %2.1f,',XXP(i).data.Te_exp_belowVknee(j,1),dummy_qv);
        str6=sprintf(' %14.7e, %2.1f,',dummy_Te_XCAL,dummy_qv);
        str7=sprintf(' %s',XXP(i).qf);
        
        strtot=strcat(str1,str2,str3,str4,str5,str6,str7);
    %    row_bytes= fprintf(twID,'%s',strtot);
    end
    XXP(i).info.row_bytes = row_bytes; 
    XXP(i).info.AXPread_me=  "code used to generate this file: str1=sprintf('%s, %s, %16s, %16s',XXP(i).data.Tarr{1,:});        str2=sprintf(' %14.7e, %2.1f,',dummy_ne,dummy_qv);str3=sprintf(' %14.7e, %2.1f,',XXP(i).data.Iph0(j,1),dummy_qv); str4=sprintf(' %14.7e, %2.1f,',dummy_v_ion,dummy_qv); str5=sprintf(' %14.7e, %2.1f,',XXP(i).data.Te_exp_belowVknee(j,1),dummy_qv);str6=sprintf(' %14.7e, %2.1f,',dummy_Te_XCAL,dummy_qv); str7=sprintf(' %s',dummy_qualityflag);";
    %fclose(twID);
end
end

% 
% 
%             info_struct=[];
%             info_struct.file      =wfile;
%             info_struct.shortname =strrep(wfile,rfolder,'');
%             info_struct.rows      =klen;
%             info_struct.timing=timing;
%             info_struct.macroid=diagmacro;
%             
%             for j=1:klen
%                 XXP_struct.Tarr(j,1:4)=EP(j).Tarr;
%                 XXP_struct.ion_slope(j,1:2)=DP(j).ion_slope;
%                 XXP_struct.ion_slope(j,1:2)=DP(j).ion_slope;
%                 XXP_struct.Vph_knee(j,1:2)=DP(j).Vph_knee;
%                 XXP_struct.Vz(j,1:2)=AP(j).Vz;
%                 XXP_struct.Vsi(j,1:2)=DP(j).Vsi;
%                 XXP_struct.Te_exp_belowVknee(j,1:2)=DP_asm(j).Te_exp_belowVknee;
%                 XXP_struct.Iph0(j,1:2)=DP(j).Iph0;
%                 XXP_struct.Vph_knee(j,1:2)=DP(j).Vph_knee;




function lapfile_with_iph0_niklas = niklas_iph0_resampled(lapstruct,conditions)
%takes a SORTED struct with A1S fields, groups them and computes iph0 via
%niklas multi sweep method.

lapfile_with_iph0_niklas= fixlap1_cont_iph0(lapstruct,conditions.CONT); % check for contamination & prepare output


%niklas iph_calc.m revisited

resampled=[];
resampled.ind=[];
resampled.curr=[];
resampled.ion_slope=[]; 
resampled.conds=conditions;

%resampled.median.iph0=[];
%resampled.median.sigma_iph0=[];
%resampled.mean.iph0=[];
%resampled.mean.sigma_iph0=[];



% 
% resampled.conds=[];
% resampled.conds.I_Vb=-17.0;%V from generating lap1 vector.
% resampled.conds.I_Vb_eps=1.0;%V epsilon, from generating lap1vector
% resampled.conds.time_window=2*60*60;%s  time window
% resampled.conds.time_samples=10;%minimum samples in time window
% resampled.conds.samples=10;%Samples minimum.
% 


    t_start=lapstruct.t0(1);%minimum if the list is SORTED. otherwise shit will hit the fan.
    count=0;
    row=0;
    groupind=[];
for i =1:length(lapstruct.B) % find w
    
    
    if lapstruct.t0(i)-t_start > resampled.conds.time_window %e.g. 2*60*60seconds
            row=row+1;

        
        if count > resampled.conds.time_samples %save index
            resampled.ind(row,1:length(groupind))=groupind;
        else
            %ignore, too few samples.            
        end
        
        %reinitialise variables
        count = 0;
        groupind=[];
        t_start=lapstruct.t0(i);        
    else
        count=count+1;
        groupind=[groupind;i];
    end
   
end

len=row; % row is incremented to max row nr, but incase I forget.
for i=1:len
    
    
    indz= resampled.ind(i,:); % a lot of extra zeroes in resampled.ind... need to get rid of them.
    indz(indz==0)=[]; %array of grouped indices. 
    if ~isempty(indz)
    colz=1:length(indz);
    
    
    %%single sweep method resampling
    
   % resampled.median.iph0(i)=nanmedian(lapstruct.Iph0(indz));
    %resampled.median.sigma_iph0(i)=nanstd(lapstruct.Iph0(indz));
    %resampled.mean.iph0(i)=nanmean(lapstruct.Iph0(indz));
    %resampled.mean.sigma_iph0(i)=nanstd(lapstruct.Iph0(indz));
        
    %%
    curr = lapstruct.curr(indz);
    ion_slope = lapstruct.ion_slope(indz); %need non structure variables.
    resampled.t0(i,colz) = lapstruct.t0(indz);    
    resampled.t_epoch(i)=mean(resampled.t0(indz));
  %  resampled.macroId = mean(lapstruct.macroId(indz));
    
    %remove shadowed, and unrealistic ionslopes
    
    delind=find((lapstruct.Illumination(indz)<0.9 | lapstruct.ion_slope(indz) <0 | isnan(lapstruct.ion_slope(indz))| isnan(lapstruct.curr(indz))));
        
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
        outlierind = (abs(curr-nanmedian(curr))> 3*nanstd(curr))| (abs(ion_slope-nanmedian(ion_slope))>1*nanstd(ion_slope));

        %outliers indicate that the plasma and ion current changed
        %substantially or that the ion_slope estimate was poorly made                     

        curr(outlierind)=[];
        ion_slope(outlierind)=[];
        
       % pfit = polyfit(currprim,curr,1);
       
       if  ge(length(curr),resampled.conds.samples)
           [P2,S2]= polyfit(ion_slope,curr,1);
           resampled.P(i,1:2) = P2;
           %resampled.S(i) = S2;
       end
        
        
        if ge(length(curr),resampled.conds.samples) && P2(1) < 0 %; %if length >= 10 e.g. 
            
            
            resampled.iph0(i) = P2(2);% this is apparently iph0.
            try
                S2.sigma = sqrt(diag(inv(S2.R)*inv(S2.R')).*S2.normr.^2./S2.df);
                resampled.iph0_sigma(i) = S2.sigma(2);
                
            catch err %horrible try catch.
                resampled.iph0_sigma(i) = nan;
            end
            
            resampled.iph0_sigma(i) = S2.sigma(2);
        else
            resampled.iph0(i) = nan;% fill with nan.
            resampled.iph0_sigma(i) = nan;
            
        end
        
    else
        
        resampled.iph0(i) = nan;% fill with nan.
        resampled.iph0_sigma(i) = nan;
        resampled.P(i,1:2) = nan;
        
    end
    

         
%         if length(currprim) > 6 & pfit(1) < 0
%             iph0=[iph0 pfit(2)]; %The sought Iph0 current is the intersection of the polynomial p with the "y-axis"
%         %elseif  length(currprim) > 3 & pfit(1) > 0.03
%             %iph0=[iph0 nanmean(curr)] %Sometimes the slope is positive but the values in the right range, just to try
%         else
%             iph0=[iph0 NaN];
%         end
%         macro=[macro sweep(i).macroname(1)];
%         rms = [rms std(polyval(pfit,currprim)-curr)];
%         N=[N length(curr)];
% 
    
    
    end
end







lapfile_with_iph0_niklas.resampled=resampled; %add to output

end


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

    j
    if j <2
        
        
        for k=1:infolenflds
           % meand1.(sprintf('%s',fields{1,k})) =nanmean([dataraw(j).(sprintf('%s',fields{1,k}))]);
            lapfile.(sprintf('%s',infofields{1,k})) =[dataraw(j).info.(sprintf('%s',infofields{1,k}))];
           % mediand1.(sprintf('%s',fields{1,k})) =nanmedian([dataraw(j).(sprintf('%s',fields{1,k}))]);

        end
        
                
        for k=1:datalenflds
           % meand1.(sprintf('%s',fields{1,k})) =nanmean([dataraw(j).(sprintf('%s',fields{1,k}))]);
            lapfile.(sprintf('%s',datafields{1,k})) =[dataraw(j).data.(sprintf('%s',datafields{1,k}))];
           % mediand1.(sprintf('%s',fields{1,k})) =nanmedian([dataraw(j).(sprintf('%s',fields{1,k}))]);

        end
        
           lapfile.Tarr=dataraw(j).data.Tarr; %special case for this parameter

        
    else
        
          lapfile.Tarr=vertcat(lapfile.Tarr, dataraw(j).data.Tarr); %special case for this parameter

        

        for k=1:infolenflds
          %  meand1.(sprintf('%s',fields{1,k})) = [[meand1.(sprintf('%s',fields{1,k}))];nanmean([dataraw(j).(sprintf('%s',fields{1,k}))])];
          %  mediand1.(sprintf('%s',fields{1,k})) =[[mediand1.(sprintf('%s',fields{1,k}))];nanmedian([dataraw(j).(sprintf('%s',fields{1,k}))])];
            lapfile.(sprintf('%s',infofields{1,k})) = [[lapfile.(sprintf('%s',infofields{1,k}))];[dataraw(j).info.(sprintf('%s',infofields{1,k}))]];
            
       
        end
        for k=1:datalenflds
            k
          %  meand1.(sprintf('%s',fields{1,k})) = [[meand1.(sprintf('%s',fields{1,k}))];nanmean([dataraw(j).(sprintf('%s',fields{1,k}))])];
          %  mediand1.(sprintf('%s',fields{1,k})) =[[mediand1.(sprintf('%s',fields{1,k}))];nanmedian([dataraw(j).(sprintf('%s',fields{1,k}))])];
            lapfile.(sprintf('%s',datafields{1,k})) = [[lapfile.(sprintf('%s',datafields{1,k}))];[dataraw(j).data.(sprintf('%s',datafields{1,k}))]];
            
       
        end
        
        
        
        



        
    end
    
    
end

%lapfile.mean=meand1;
%lapfile.median=mediand1;

end


function out= PXPTABfile(PXP)
%this file needs all lapa1s.t0, DP.ion_slope in archive
%,also. This file needs the potential and current value closest to e.g.
%-17Vb for each sweep.


ind_temp=PXP.resampled.ind(1,:);
indz(ind_temp==0)=[];


%t0=XXP.t0(indz(1,:));
%t1=XXP.t0(indz(end,:));

utcstart=PXP.Tarr(indz(1,:),1);
utcstop=PXP.Tarr(indz(2,:),1);

PXP.Tarr(5,1)
%indz=XXP.resampled.ind(1,:); %first index in each file


t0 = datenum(strrep(utcstart,'T',' '));


dirY = datestr(t0,'YYYY');
dirM = upper(datestr(t0,'mmm'));
dirD = strcat('D',datestr(t0,'dd'));
tabfolder = strcat(PXP(1).info.derivedpath,'/',dirY,'/',dirM,'/',dirD,'/');








global SATURATION_CONSTANT

iph0 =SATURATION_CONSTANT;
iph0_qv=1;




klen= 1;


%%print





for j= 1:length(t0)
    
    filename = sprintf('%sRPCLAP%s_%s_000000_30M_XXP.TAB',fpath,datestr(t0(j),'yymmdd'));
        
    
    if j>1 && ~strcmp(datestr(t0(j-1),'dd'), datestr(t0(j),'dd')) %%new calendar day? (won't check j==1)
        %   newfile =false;
        twID = fopen(filename,'w');
        xcalfile.list{end+1,1} =filename;
    else
        twID = fopen(filename,'a+'); %new file.
    end
    

    %         UTC, MIP_filtered_ne, LAPasmne5ev, ionV, XcalTe, LAP Te, Iph0,
    %          macroID, MIP_instant_ne, Vph_knee
    fprintf(twID,'%.19s, %14.7e, %14.7e, %14.7e, %16.6f, %16.6f, %14.7e, %3d, %14.7e, %16.6f\r\n',...
        xcalfile.t_utc(j,1:end-1),XCAL.mipnefilt(j), LAP.asm_ne_5eV(j),XCAL.ionV(j),XCAL.Te(j),LAP.Te_exp_belowVknee(j),LAP.Iph0(j),LAP.macroId(j),XCAL.MIP_instant_ne(j),LAP.Vph_knee(j));
    
    fclose(twID); %write file nr 1
    
    
end
         
         for k=1:klen
             
             dstr1  = sprintf('%s, %s, %16s, %16s, %04i,', EP(k).Tarr{1,1}, EP(k).Tarr{1,2}, EP(k).Tarr{1,3}, EP(k).Tarr{1,4}, EP(k).qf);
             dstr2 = sprintf(' %14.7e, %14.7e', DP(k).Vph_knee(1),DP(k).Te_exp_belowVknee(1));
             if isnan(DP(k).Vph_knee(1))                 
                 dstrtot=strcat(dstr1,dstr2);
                 dstrtot=strrep(dstrtot,'  0.0000000e+00','       -1.0e+03'); % ugly fix, but this fixes the ni = 0 problem in the least code heavy way & probably most efficient way.
                 dstrtot=strrep(dstrtot,'     NaN','-1.0e+03');                
             end
             
             
             
             
             drow_bytes = fprintf(awID,'%s\r\n',dstrtot);

         end
            fclose(awID);
                                
            der_struct=[];
%             der_struct.file{i}      = dfile;
%             der_struct.shortname{i} =strrep(dfile,rfolder,'');
%             der_struct.firstind(i)  =tabindex{an_ind(i),3};
%             der_struct.rows(i)      =klen;
%             der_struct.cols(i)      =7;
%             der_struct.an_ind_id(i) =an_ind(i);
%             der_struct.timing(i,1:4)=timing;
%             der_struct.bytes=drow_bytes;
%                       
            
            
            out= der_struct;




end



function out= UXPfile(var_ind)
%this file needs all Vph_knee*, and all Vfloat measurements in archive.
%or AP.Vz, V_sc from ion slope
%or DP.Vsi 


end


