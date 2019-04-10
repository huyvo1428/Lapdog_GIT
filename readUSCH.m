%read USC.TAB files
% try preamble
% catch err
% end
%function usch=readUSCH
global SATURATION_CONSTANT LDLMACROS MIP
%command = 'ls /mnt/spis/RO-C-RPCLAP-5-1*V0.8/*/*/*/*USC.TAB';
flds= {'t_epoch','t_obt','usc','qv','qf','t_utc','data_source','macroId'};



%cspice_furnsh('/Users/frejon/Rosetta/Lapdog_GIT/metakernel_rosetta_mounted.txt');


command = 'ls /mnt/squid/RO-C-RPCLAP-5-1606*V0.9/*/*/*/*_V1L.TAB';


%[status,command_output] = system(command);
cell_listoffiles=textscan(command_output,'%s');

%v1float=  read_VxL_float(cell_listoffiles{1,1});
% % 
% % command = 'ls /mnt/squid/RO-C-RPCLAP-5-1609*V0.9/*/*/*/*_V2L.TAB';
% % [status,command_output] = system(command);
% % cell_listoffiles=textscan(command_output,'%s');
% % v2float=  read_VxL_float(cell_listoffiles{1,1});
% 
% % 
% 
command = 'ls /mnt/squid/RO-C-RPCLAP-5-1606*V0.9/*/*/*/*USC.TAB';

% [status,command_output] = system(command);
cell_listoffiles=textscan(command_output,'%s');
%tic 
%usc=  read_usc_prelim(cell_listoffiles{1,1},flds);

usch = combine_usc(usc,v1float,[]);


usch.interval=7*24*3600;%seconds = 14 days;
usch=usc_to_ne(usch,MIP,usch.interval);


nanind= abs(usc.usc)==abs(SATURATION_CONSTANT);

usc.usc(nanind)=nan;
%toc'
%LDLMACROS
% 
% 
% figure(1);plot(usc.t_epoch(usc.qv>0.5),usc.usc(usc.qv>0.5),'o')
% irf_timeaxis(gca,'usefig');
% % figure(2);ayy1=histogram(lapa1s.Vph_knee);hold on;ayy2=histogram(usc.usc(usc.qv>0.5));ayy3=histogram(usc.usc(usc.qv<0.6));%ayy4=histogram(usc.usc);hold off;
% % hold off;
% % ayy1.BinWidth=ayy2.BinWidth;ayy3.BinWidth=ayy2.BinWidth;%ayy4.BinWidth=ayy2.BinWidth;
% %figure(3);ayy1=histogram(-lapa1s.Vsi);hold on;ayy2=histogram(usc.usc(usc.qf<1));ayy3=histogram(usc.usc(usc.qf>0.6));ayy4=histogram(usc.usc);hold off;
% %figure(3);histogram(usc.macroId(ismemberf((usc.macroId),str2double(dec2hex(LDLMACROS)))));
% 
% legend('lapa1s Vph\_knee','usc, qv>0.5','usc, qv<0.6')
% % 
% % figure(1);plot(usc.t_epoch(usc.qf<39&usc.qv>0.5),usc.usc(usc.qf<39&usc.qv>0.5),'o',usc.t_epoch(usc.qf>39|usc.qv<0.6),usc.usc(usc.qf>39|usc.qv<0.6),'o')
% % irf_timeaxis(gca,'usefig');
% % %legend('filtered','LDL','qv 0.5/0.4','USCv0.9')
% % 
% % 
% 
% %This plot tells me that qv 0.5/0.4 is a good way to remove poor points
% %figure(1);plot(usc.t_epoch(usc.qf<39&usc.qv>0.5),usc.usc(usc.qf<39&usc.qv>0.5),'o',usc.t_epoch(usc.qf>39),usc.usc(usc.qf>39),'+',usc.t_epoch(usc.qv<0.6),usc.usc(usc.qv<0.6),'o',usc09.t_epoch,usc09.usc,'diamond')
% % figure(1);plot(LAP_USC.t_epoch(LAP_USC.qf<39&LAP_USC.qv>0.5),LAP_USC.usc(LAP_USC.qf<39&LAP_USC.qv>0.5),'o',LAP_USC.t_epoch(LAP_USC.qf>39),LAP_USC.usc(LAP_USC.qf>39),'+',LAP_USC.t_epoch(LAP_USC.qv<0.6),LAP_USC.usc(LAP_USC.qv<0.6),'o',usc.t_epoch,usc.usc,'diamond')
% % irf_timeaxis(gca,'usefig');
% % legend('filtered','LDL','qv 0.5/0.4','USCv0.9')
% figure(31);
% subplot(2,2,[1 2]);
% scatter(usc.t_epoch,usc.usc,15,usc.qv);
% %hold on;scatter(XP2.t_epoch,-XP2.Vz(:,1),10,ones(1,length(XP2.t_epoch))*1.3);hold off;
% ax=gca;
% irf_timeaxis(gca,'usefig');
% grid on;
% ax.YLabel.String='USC [V]';
% colormap 'jet'
% subplot(2,2,3)
% histogram(usc.usc);
% ax2=gca;
% ax2.XLabel.String='Usc';
% subplot(2,2,4)
% histogram(usc.qv);
% ax2=gca;
% ax2.XLabel.String='Usc QV';

%figure(12);plot(usc.t_epoch(indz),usc.usc(indz),'o')
%%irf_timeaxis(gca,'usefig');
%grid on;

function usch = combine_usc(usc,v1float,v2float)
usch=[];
global MIP

shit= Vfloat_to_MIP(v1float,MIP,1/4);


v1float.data_source=v1float.qf;
v1float.data_source(:)=1;
v1float.qv=v1float.data_source;



del_indz=usc.data_source==1;
usc.t_epoch(del_indz)=[];
usc.t_obt(del_indz)=[];
usc.usc(del_indz)=[];
usc.qv(del_indz)=[];
usc.qf(del_indz)=[];
usc.data_source(del_indz)=[];
usc.macroId(del_indz)=[];

usch=v1float;
usch.usc=[usch.usc;usc.usc];
usch.t_epoch=[usch.t_epoch;usc.t_epoch];
usch.qf=[usch.qf;usc.qf];
usch.data_source=[usch.data_source;usc.data_source];
usch.qv=[usch.qv;usc.qv];


[usch.t_epoch,sort_ind] = sort(usch.t_epoch,'ascend');
usch.usc=usch.usc(sort_ind);
usch.qf=usch.qf(sort_ind);
usch.data_source=usch.data_source(sort_ind);
usch.qv=usch.qv(sort_ind);



end



function usc=usc_to_ne(usc,MIP,interval)



%superarray=[];
%superarray.t_epoch= piuhk_clean.t_epoch(1):32:piuhk_clean.t_epoch(end);

%nanindz=isnan(MIP.ne);
%usc.interp_ne = interp1(MIP.t_epoch,MIP.ne,usc.t_epoch);

%usc.interp_ne = interp1(MIP.t_epoch(~nanindz),MIP.ne(~nanindz),usc.t_epoch);
%MIP.interp_ne_uncertainty = interp1(MIP.t_epoch,MIP.ne_uncertainty,MIP.ne,usc.t_epoch);

%superarray.PSUtemp_interp=interp1(piuhk_clean.t_epoch,piuhk_clean.PSUtemp,superarray.t_epoch); %Only using PSU temp(!) % The options here is to use schk maybe
%unique(isnan(superarray.PSUtemp_lo))


% [C,IA,IC] = unique(schk.t_epoch,'sorted'); %apparently we have some timestamps that are dubletter
% 
% schk_clean=[];
% schk_clean.t_epoch=schk.t_epoch(IA);
% schk_clean.t_utc=schk.t_utc(IA);
%schk_clean.PIUmean=schk.PIUmean(IA);


     inter = 1 + floor((usc.t_epoch(:) - usc.t_epoch(1))/interval); %prepare subset selection to accumarray%
     
     MIPinter = 1 + floor((MIP.t_epoch(:) - usc.t_epoch(1))/interval); %prepare subset selection to accumarray

     usc.t0=usc.t_epoch;
     MIP.tt=MIP.t_epoch;
     MIP.mipne_uncertainty=MIP.ne_uncertainty;
     XCAL_L= XCAL_lapdog(usc,MIP);
    % clear MIP.tt MIP.mipne_uncertainty
     
     
     
% startind=inter(1);
% groupind=[];
% 
% 
% 
% rowcount=0;
% %prepare array with a bit or function that adds unique & different
% %qualityflags together
% qf_array  = accumarray(inter,lapstruct.qf,[],@(x) frejonbitor(unique(x)));
% 
% 
% %len=row; % row is incremented to max row nr, but incase I forget.
% %for i=1:len
% k=0;
% %for i = inter(1):inter(end)
% %sometimes lapstruct.t0 is not sorted...?
% %t_etz=floor(t_et0+(intval* (min(inter):max(inter)))+0.5);%maybe slightly incorrect. ugh.
% t_etz=t_et0+intval/2+(intval* (min(inter):max(inter)));%midpoint of interval                                        
% 
% %                               ((1:3600*24/intval)-0.5)*intval
% 
% t_obtz= t_obt0 +intval+(intval*(min(inter):max(inter)));%midpoint of interval
% t_utc= cspice_et2utc(t_etz(:).'+0.5, 'ISOC', 6);% buffer up with 0.5 second, before UTC conversion, and then round to closest second later in function
% t_matlab_date=nan(length(t_etz),1);
% for i = 1:length(t_etz)
%     t_matlab_date(i)=datenum(strrep(t_utc(i,:),'T',' '));
% end

    resampled=[];
    resampled.indz=[];
  %  save ~/matlabdump_utc.mat t_utc t_matlab_date
    k=0;
for i = max(inter):-1:min(inter) %main for loop

    k=k+1;
    indz=find(inter==i);
    mipindz=find(MIPinter==i);

    
    %indz= resampled.ind(i,:); % a lot of extra zeroes in resampled.ind... need to get rid of them.
   % indz(indz==0)=[]; %array of grouped indices. 
    if ~isempty(indz) &&~isempty(mipindz) 
    colz=1:length(indz);
    
    
    resampled.usc(k,colz)=usc.usc(indz);
    %resampled.ne(k,colz)=usc.interp_ne(indz);
    resampled.indz=[resampled.indz;indz];
    
    filt_indz=filter_USC_XCAL(XCAL_L,usc,indz);
    %XCAL_L.mipnefilt((filt_indz.vz))=XCAL_L.mipnefilt((filt_indz.vz)); 
    resampled.ne(k,colz)=XCAL_L.mipnefilt(indz);
    usc.mipne(indz)=XCAL_L.mipnefilt(indz);
    
    

    nan_indz=isnan(XCAL_L.mipnefilt(indz)) | isnan(usc.usc(indz));
   % nan_indz2=isnan(XCAL_L.mipnefilt(indz)) | isnan(usc.usc(indz));

    
    
    %     
    [P1,S1]         = polyfit(usc.usc(indz(~nan_indz)),log(XCAL_L.mipnefilt(indz(~nan_indz))),1);
   % [P2,S2]         = polyfit(usc.usc(indz(~nan_indz2)),log(XCAL_L.mipnefilt(indz(~nan_indz2))),1);
    [Pbest,Sbest]  = polyfit(usc.usc(filt_indz.best),log(XCAL_L.mipnefilt(filt_indz.best)),1);

    resampled.P1(k,1:2)=P1;
   % resampled.P2(k,1:2)=P2;
    resampled.Pbest(k,1:2)=Pbest;
   % resampled.P2(k,1:2)=P2;
    resampled.Pbest(k,1:2)=Pbest;
    resampled.P1_Voff(k,1)=-P1(2)/P1(1);
   % resampled.P2_Voff(k,1)=-P2(2)/P2(1);
    resampled.Pbest_Voff(k,1)=-Pbest(2)/Pbest(1);

    
    resampled.S1(k,1:2)=S1;
    %resampled.S2(k,1:2)=S2;
    resampled.Sbest(k,1:2)=Sbest;   
%     
%    [P1, outliers1,S1] = fit_ols_ESD(usc.usc(indz(~nan_indz)),log(XCAL_L.mipnefilt(indz(~nan_indz))));
%    [P2, outliers2,S2] = fit_ols_ESD(usc.usc(indz(~nan_indz2)),log(XCAL_L.mipnefilt(indz(~nan_indz2))));
%    [Pbest, outliers1,S1] = fit_ols_ESD(usc.usc(filt_indz.best),log(XCAL_L.mipnefilt(filt_indz.best)));
%     [Pbest,S1] = polyfit(usc.usc(filt_indz.best),log(XCAL_L.mipnefilt(filt_indz.best)),1);
%    y1=polyval(Pbest,-usc.usc(indz));
 %   y1=exp(y1);
%  
%  if Pbest(1)>0
%      p1=P2(1);
%      p2=P2(2);
%  else
      p1=Pbest(1);
      p2=Pbest(2);
%  end
%  
%  if p1 == 0
%      p1 =resampled.P2(k-1,1);
%      p2 = resampled.P2(k-1,2);
%  end
   %   p1=P1(1);
   % p2=P1(2);
    y1 = exp(p2)*exp(usc.usc(indz)*p1);
   
   % y1=exp(-p2/p1)*exp(-usc.usc(indz)*p1);
    %max(y1)
    %min(y1)
    %Vs = p1 lg n + p2
    %
    %Teff=-p1/ln10   p2   n0=10^(-p2/p1)
     figure(10001);
    subplot(4,1,[1:2])
    plot(usc.usc(filt_indz.vz),XCAL_L.mipnefilt(filt_indz.vz),'.',usc.usc(filt_indz.vf),XCAL_L.mipnefilt(filt_indz.vf),'.',usc.usc(filt_indz.best),XCAL_L.mipnefilt(filt_indz.best),'o',usc.usc(indz),y1,'-')
    %plot(usc.usc,XCAL_L.mipnefilt,'.',usc.usc(indz),y1,'-')

    ax=gca;
    ax.Title.String=sprintf('Te=%3.3f eV, n0 = %3.2e cm-3,offsetV=%3.3f',-1/p1,exp(p2),-p2/p1);

    %
    ax.XLabel.String='Usc [V]';ax.YLabel.String='ne [cm^{-3}]';
    ax.YScale='log';  
    grid on;
    legend('Vz','Vfloat','best','linear fit');
    subx(1)= subplot(4,1,3);
    plot(usc.t_epoch(indz),usc.usc(indz),'o',usc.t_epoch(filt_indz.vf),usc.usc(filt_indz.vf),'o')
   % plot(usc.t_epoch(filt_indz.vz),usc.usc(filt_indz.vz),'o',usc.t_epoch(filt_indz.vf),usc.usc(filt_indz.vf),'o')

    irf_timeaxis(gca,'usefig');
    ax=gca;ax.YLabel.String='Usc [V]';
    legend('Vz','Vfloat')
      subx(2)= subplot(4,1,4);
    plot(MIP.t_epoch(mipindz),MIP.ne(mipindz),'o',usc.t_epoch(indz),XCAL_L.mipnefilt(indz),'o',XCAL_L.t0(filt_indz.best),XCAL_L.mipnefilt(filt_indz.best),'*',usc.t_epoch(indz),y1)       
    irf_timeaxis(gca,'usefig');
    legend('MIP','filtered','best','uscfit')
    ax=gca;ax.YLabel.String='ne [cm^{-3}]';
    ax.YScale='log';  
linkaxes(subx','x')
    

    usc.ne_fit(indz)=y1;
    usc.vz_ind(indz)=ismember(indz,filt_indz.vz);
    
   % nanindz=isnan(XCAL_L.mipnefilt(indz)) & isnan(usc.usc(indz));

    %[P2, outliers,S2] = fit_ols_ESD(log(XCAL_L.mipnefilt(indz)), usc.usc(indz));

    %ne =  ne0*exp(-Usc/Te)
    %log(ne)= 1/Te * Usc + A
    %ne = ne0 * Usc/Te
    %

    %ax.YScale='log';  
    
   % resampled.median.iph0(i)=nanmedian(lapstruct.Iph0(indz));
    %resampled.median.sigma_iph0(i)=nanstd(lapstruct.Iph0(indz));
    %resampled.mean.iph0(i)=nanmean(lapstruct.Iph0(indz));
    %resampled.mean.sigma_iph0(i)=nanstd(lapstruct.Iph0(indz));
    %%
    
    %%%%resampled.curr(k,colz)=lapstruct.curr(indz);
    %%%curr= resampled.curr(k,colz).';
    %curr = lapstruct.curr(indz);
    %%%resampled.ion_slope(k,colz)=lapstruct.ion_slope(indz,1);

    
    end

    usc.resampled=resampled;
%schk_clean.TEMPheating=interp1(piuhk_clean.t_epoch,piuhk_clean.TEMPheating,schk_clean.t_epoch);





end
end


function out= Vfloat_to_MIP(LAP,MIP,pseudo_int_treshold)


pseudo_int_treshold=2.5e-1; %to filter out most unimportant MIP measurements. Some others will be removed later
%Above worked for 32S data, not for 60hzdata
%pseudo_int_treshold=60;% within 1 second?


%%% below no longer valid -FKJN 21/9. Forgot about split sweeps
%%% 2e-3 WORKssome arbitrary limit, looks good enough. 
% a limit of 2e-3 WORKS, but we can increase it slightly to be sure. 
%1e-3  makes us miss 4 points within 1 second.

LAP.t0=LAP.t_epoch;
XCAL_L=LAP;
%XCAL_L.ionV=LAP.t0;
%XCAL_L.ionV(:)=SATURATION_CONSTANT; %default to missing constant
XCAL_L.t0(:)=nan; %default to nan, for debug plotting
XCAL_L.mipnefilt =XCAL_L.t0;
XCAL_L.mipnefilt(:)=nan; %default to missing constant
XCAL_L.mipne_uncertainty= XCAL_L.mipnefilt;
XCAL_L.qv_a= XCAL_L.mipnefilt;
XCAL_L.qv_b= XCAL_L.mipnefilt;
XCAL_L.qv_c= XCAL_L.mipnefilt;


if isempty(MIP)

%load(path_to_matfile,'MIP'); %loads MIP variable from file
    
end


% 
% 
% 
% superarray=[];
% superarray.t_epoch= LAP.t0(1):32:piuhk_clean.t_epoch(end);
% 
% nanindz=isnan(MIP.ne);
% 
% usc.interp_ne = interp1(MIP.t_epoch(~nanindz),MIP.ne(~nanindz),usc.t_epoch);
% MIP.interp_ne_uncertainty = interp1(MIP.t_epoch,MIP.ne_uncertainty,MIP.ne,usc.t_epoch);



% try
%     preamble;
% catch err
% end
% 
% delind=isnan(MIP.ne);
% 
% MIP.tt(delind)=[];
% MIP.ne(delind)=[];

MIP.tt=MIP.t_epoch;


len = length(MIP.tt);

if len ~=1
    pseudo_ind = interp1(MIP.tt,1:len,LAP.t0);
else    %special case for len == 1, for which interp1 can't handle

    [diff,closest_mip]=min(abs(LAP.t0-MIP.tt));
    pseudo_ind=ones(1,length(MIP.tt))+0.5; %silly vector all filled with 1.5's everywhere
    
    if diff > pseudo_int_treshold       %exit early?
        return;
    else
            pseudo_ind(closest_mip)=1; % filt_inds thing should be able to find this if it exists.
    end
    

end

%pseudo ind interpolates 
%indzz=abs(shit-floor(shit+0.5))< 2e-3; %some arbitrary limit, looks good enough. 
filt_inds=abs(pseudo_ind-floor(pseudo_ind+0.5))< pseudo_int_treshold;
%figure(1);histogram(log10((diff((pseudo_ind)))*min(diff(MIP.t_epoch))))
%seconds away from nearest MIP estimate

%%% below no longer valid -FKJN 21/9. Forgot about split sweeps
%%% 2e-3 WORKssome arbitrary limit, looks good enough. 
% a limit of 2e-3 WORKS, but we can increase it slightly to be sure. 
%1e-3  makes us miss 4 points within 1 second.

XCAL_M=[];
XCAL_M.mipnefilt=MIP.ne(filt_inds);
XCAL_M.ne_uncertainty=MIP.ne_uncertainty(filt_inds);
XCAL_M.qv_a=MIP.qv_a(filt_inds);
XCAL_M.qv_b=MIP.qv_b(filt_inds);
XCAL_M.qv_c=MIP.qv_c(filt_inds);

%XCAL_M.mipID=MIP.ID(filt_inds);
XCAL_M.t1=MIP.tt(filt_inds);
XCAL_M.lapind=nan(1,length(XCAL_M.t1)); %default to nan, useful later
% XCAL_M.ionV             =nan(length(XCAL_M.t1),1);
% XCAL_M.Te               =nan(length(XCAL_M.t1),1);

%XCAL.t1 = LAP.t1;


pts_to_check=pseudo_ind(filt_inds);
indz=[];

if isempty(pts_to_check)
    return;
end

for i = 1:length(pts_to_check)

    lap_ind=floor(pts_to_check(i)+0.5);
    if min(abs(LAP.t0(floor(pts_to_check(i)+0.5))-XCAL_M.t1(i)))>1
        %'shit'
         indz=vertcat(indz,i);
        fprintf(1,'diff is %d sec k=%d, i = %d \n',abs(LAP.t1(floor(pts_to_check(i)+0.5))-XCAL.t1(i)),k,i);        
    else

%    XCAL_M.ionV(i) = XCAL_M.mipnefilt(i)*2*IN.probe_cA*(CO.e).^2/(assmpt.ionM*CO.mp*LAP.asm_ion_slope(lap_ind)*1e-6);
%    XCAL_M.Te(i) = 5* (XCAL_M.mipnefilt(i)/LAP.ne_5eV(lap_ind)).^2;
   XCAL_M.lapind(i) =floor(pts_to_check(i)+0.5);%
    end

end




%change to XCAL_L with LAP indexing, instead of MIP indexing

indz=find(~isnan(XCAL_M.lapind(:))); %

%XCAL_L.ionV(XCAL_M.lapind(indz))            =XCAL_M.ionV(indz);
XCAL_L.t0(XCAL_M.lapind(indz))              =XCAL_M.t1(indz);
%XCAL_L.Te(XCAL_M.lapind(indz))              =XCAL_M.Te(indz);
%I care less about these, so some values will be empty.
%XCAL_L.mipID(XCAL_M.lapind(indz))           =XCAL_M.mipID(indz);
XCAL_L.mipne_uncertainty(XCAL_M.lapind(indz)) =XCAL_M.ne_uncertainty(indz);
XCAL_L.mipnefilt(XCAL_M.lapind(indz))       =XCAL_M.mipnefilt(indz);
XCAL_L.qv_a(XCAL_M.lapind(indz))       =XCAL_M.qv_a(indz);
XCAL_L.qv_b(XCAL_M.lapind(indz))       =XCAL_M.qv_b(indz);
XCAL_L.qv_c(XCAL_M.lapind(indz))       =XCAL_M.qv_c(indz);




end


function XCAL_L= XCAL_lapdog(LAP,MIP,pseudo_int_treshold)
%global MIP %change to persistent later
global CO IN  assmpt


pseudo_int_treshold=2.5e-1; %to filter out most unimportant MIP measurements. Some others will be removed later
%Above worked for 32S data, not for 60hzdata
%pseudo_int_treshold=60;% within 1 second?


%%% below no longer valid -FKJN 21/9. Forgot about split sweeps
%%% 2e-3 WORKssome arbitrary limit, looks good enough. 
% a limit of 2e-3 WORKS, but we can increase it slightly to be sure. 
%1e-3  makes us miss 4 points within 1 second.


XCAL_L=LAP;
%XCAL_L.ionV=LAP.t0;
%XCAL_L.ionV(:)=SATURATION_CONSTANT; %default to missing constant
XCAL_L.t0(:)=nan; %default to nan, for debug plotting
XCAL_L.mipnefilt =XCAL_L.t0;
XCAL_L.mipnefilt(:)=nan; %default to missing constant
XCAL_L.mipne_uncertainty= XCAL_L.mipnefilt;
XCAL_L.qv_a= XCAL_L.mipnefilt;
XCAL_L.qv_b= XCAL_L.mipnefilt;
XCAL_L.qv_c= XCAL_L.mipnefilt;


if isempty(MIP)

%load(path_to_matfile,'MIP'); %loads MIP variable from file
    
end



% 
% 
% superarray=[];
% superarray.t_epoch= LAP.t0(1):32:piuhk_clean.t_epoch(end);
% 
% nanindz=isnan(MIP.ne);
% 
% usc.interp_ne = interp1(MIP.t_epoch(~nanindz),MIP.ne(~nanindz),usc.t_epoch);
% MIP.interp_ne_uncertainty = interp1(MIP.t_epoch,MIP.ne_uncertainty,MIP.ne,usc.t_epoch);
% 
% 



assmpt=[];
assmpt.ionM=19;%a.u.
assmpt.vram=550;%m/s

% try
%     preamble;
% catch err
% end
% 
% delind=isnan(MIP.ne);
% 
% MIP.tt(delind)=[];
% MIP.ne(delind)=[];




len = length(LAP.t0);

if len ~=1
    pseudo_ind = interp1(LAP.t0,1:len,MIP.tt);
else    %special case for len == 1, for which interp1 can't handle

    [diff,closest_mip]=min(abs(LAP.t0-MIP.tt));
    pseudo_ind=ones(1,length(MIP.tt))+0.5; %silly vector all filled with 1.5's everywhere
    
    if diff > pseudo_int_treshold       %exit early?
        return;
    else
            pseudo_ind(closest_mip)=1; % filt_inds thing should be able to find this if it exists.
    end
    

end

%pseudo ind interpolates 
%indzz=abs(shit-floor(shit+0.5))< 2e-3; %some arbitrary limit, looks good enough. 
filt_inds=abs(pseudo_ind-floor(pseudo_ind+0.5))< pseudo_int_treshold;
%%% below no longer valid -FKJN 21/9. Forgot about split sweeps
%%% 2e-3 WORKssome arbitrary limit, looks good enough. 
% a limit of 2e-3 WORKS, but we can increase it slightly to be sure. 
%1e-3  makes us miss 4 points within 1 second.

XCAL_M=[];
XCAL_M.mipnefilt=MIP.ne(filt_inds);
XCAL_M.ne_uncertainty=MIP.ne_uncertainty(filt_inds);
XCAL_M.qv_a=MIP.qv_a(filt_inds);
XCAL_M.qv_b=MIP.qv_b(filt_inds);
XCAL_M.qv_c=MIP.qv_c(filt_inds);

%XCAL_M.mipID=MIP.ID(filt_inds);
XCAL_M.t1=MIP.tt(filt_inds);
XCAL_M.lapind=nan(1,length(XCAL_M.t1)); %default to nan, useful later
% XCAL_M.ionV             =nan(length(XCAL_M.t1),1);
% XCAL_M.Te               =nan(length(XCAL_M.t1),1);

%XCAL.t1 = LAP.t1;


pts_to_check=pseudo_ind(filt_inds);
indz=[];

if isempty(pts_to_check)
    return;
end

for i = 1:length(pts_to_check)

    lap_ind=floor(pts_to_check(i)+0.5);
    if min(abs(LAP.t0(floor(pts_to_check(i)+0.5))-XCAL_M.t1(i)))>1
        %'shit'
         indz=vertcat(indz,i);
        fprintf(1,'diff is %d sec, i = %d \n',abs(LAP.t0(floor(pts_to_check(i)+0.5))-XCAL_L.t0(i)),i);        
    else

%    XCAL_M.ionV(i) = XCAL_M.mipnefilt(i)*2*IN.probe_cA*(CO.e).^2/(assmpt.ionM*CO.mp*LAP.asm_ion_slope(lap_ind)*1e-6);
%    XCAL_M.Te(i) = 5* (XCAL_M.mipnefilt(i)/LAP.ne_5eV(lap_ind)).^2;
   XCAL_M.lapind(i) =floor(pts_to_check(i)+0.5);%
    end

end




%change to XCAL_L with LAP indexing, instead of MIP indexing

indz=find(~isnan(XCAL_M.lapind(:))); %

%XCAL_L.ionV(XCAL_M.lapind(indz))            =XCAL_M.ionV(indz);
XCAL_L.t0(XCAL_M.lapind(indz))              =XCAL_M.t1(indz);
%XCAL_L.Te(XCAL_M.lapind(indz))              =XCAL_M.Te(indz);
%I care less about these, so some values will be empty.
%XCAL_L.mipID(XCAL_M.lapind(indz))           =XCAL_M.mipID(indz);
XCAL_L.mipne_uncertainty(XCAL_M.lapind(indz)) =XCAL_M.ne_uncertainty(indz);
XCAL_L.mipnefilt(XCAL_M.lapind(indz))       =XCAL_M.mipnefilt(indz);
XCAL_L.qv_a(XCAL_M.lapind(indz))       =XCAL_M.qv_a(indz);
XCAL_L.qv_b(XCAL_M.lapind(indz))       =XCAL_M.qv_b(indz);
XCAL_L.qv_c(XCAL_M.lapind(indz))       =XCAL_M.qv_c(indz);




end




function indz_out = filter_USC_XCAL(XCAL_L,usc,indz)

indz_out=[];

ind1=XCAL_L.qv_c(indz)>0.6; %this only really pertains to vfloat data
% ind2=XCAL_L.nrofmippoints(indz)>3;
% ind3=XCAL_L.nrofmippoints(indz)>3;





indz_out.vz=usc.data_source(indz)>2;
indz_out.vf=~indz_out.vz;
indz_out.vf1=usc.data_source(indz)==1;
indz_out.vf2=usc.data_source(indz)==2;


best_indz = (indz_out.vf & ind1) | (indz_out.vz & ind1); %vfloat needs many points and good MIP estimates, vzind just needs instaneous values

%XCAL_L.mipnefilt(indz(vzind==1))=XCAL_L.mipnefilt(indz(vzind==1));

best_indz = best_indz & ~(isnan(usc.usc(indz))) & ~(isnan(usc.usc(indz))) & ~(isnan(XCAL_L.mipnefilt(indz)));
indz_out.best = indz(best_indz);

end





function out = read_VxL_float(list_of_files)

flds = {'t_epoch','usc','qf'};
out = [];
k=0;

for i = 1:length(list_of_files)
    
   
    rfile =list_of_files{i,1};
    
    LBLfile= rfile;
    LBLfile(end-3:end) = '.LBL';
    probe= (rfile(end-5));
    
    
        if exist(LBLfile,'file')

            
            str1= 'grep -rF "ROSETTA:LAP_P';
            
            str2= '_STRATEGY_OR_RANGE"';

            
            command1= [str1,probe,str2,' ',LBLfile];
            
            [status,command_output_lap1] = system(command1);

            
            if strcmp(command_output_lap1(end-7:end-3),'FLOAT')
                k=k+1;
                
                trID=fopen(rfile,'r');
                % scantemp= textscan(trID,'%s','delimiter',',');
                scantemp= textscan(trID,'%s %*f %*f %f %d','delimiter',',');
                        fclose(trID);

                out(k).t_utc   =scantemp{1,1};
                %out(i).t_obt   =scantemp{1,2};
                out(k).t_epoch = irf_time(cell2mat(scantemp{1,1}(:,1)),'utc>epoch');
                out(k).usc = -scantemp{1,2};%-1!!! 
                out(k).qf = scantemp{1,3};
                
                
%                 out.saa= orbit_v2('Rosetta',out(i).t_utc,'CHURYUMOV-GERASIMENKO','ECLIPJ2000','/Users/frejon/Rosetta/Lapdog_GIT/metakernel_rosetta_mounted.txt ');
%                 'help';
                
                
            end
        end
        
    
end


out = structcleanup(out,flds);

end





function out = read_usc_prelim(list_of_files,flds)

out = [];

for i = 1:length(list_of_files)
    
   
    rfile =list_of_files{i,1};

    
    if exist(rfile,'file')
        %macro 411 only gives problems for LAP2
        trID=fopen(rfile,'r');
       % scantemp= textscan(trID,'%s','delimiter',',');                      
         scantemp= textscan(trID,'%s %f %f %f %d %d','delimiter',',');
         
         out(i).t_utc   =scantemp{1,1};
         out(i).t_obt   =scantemp{1,2};
         out(i).t_epoch = irf_time(cell2mat(scantemp{1,1}(:,1)),'utc>epoch');
         out(i).usc     =scantemp{1,3};
         out(i).qv      =scantemp{1,4};
         out(i).data_source  =scantemp{1,5};
         out(i).qf      =scantemp{1,6};
         out(i).macroId(1:length(scantemp{1,2}),1)=str2double(rfile(end-10:end-8));

         
        %row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',data_arr.Tarr_mid{j,1},data_arr.Tarr_mid{j,2},factor*data_arr.Vz(j,1),data_arr.Vz(j,2),data_arr.qf(j));            

         
       % scantemp= textscan(trID,'%f %f','delimiter',',','headerLines',2);       
        fclose(trID);

        
%         
%         
%         sweeps.(sprintf('I%d',count))(:,seqnr) = -scantemp{1,2}; %NOTE MINUS HERE FOR SPIS CONVERSION
%         sweeps.(sprintf('V%d',count))(:,seqnr) = scantemp{1,1};
% 
%         
    else
        fprintf(1,'skipping %s, i=%d\n',rfile,i);
        %        rfile
    end
    
end


out = structcleanup(out,flds);

end



function lapfile= structcleanup(dataraw,fields)
%lapfile takes a horrible massive struct called dataraw from readAxS_prelim
% and polishes, removing any struct field that is not named in the "flds"
% parameter list. The code was made to output averages and medians per file
% as well.
% if the flds listed do not contain "B" or "curr" then
% lapfile_with_iph0_niklas will not work

lenflds = length(fields);
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

    if j <2
        
        
        for k=1:lenflds
           % meand1.(sprintf('%s',fields{1,k})) =nanmean([dataraw(j).(sprintf('%s',fields{1,k}))]);
            lapfile.(sprintf('%s',fields{1,k})) =[dataraw(j).(sprintf('%s',fields{1,k}))];
           % mediand1.(sprintf('%s',fields{1,k})) =nanmedian([dataraw(j).(sprintf('%s',fields{1,k}))]);

        end
        
 
    else
        
        
        for k=1:lenflds
          %  meand1.(sprintf('%s',fields{1,k})) = [[meand1.(sprintf('%s',fields{1,k}))];nanmean([dataraw(j).(sprintf('%s',fields{1,k}))])];
          %  mediand1.(sprintf('%s',fields{1,k})) =[[mediand1.(sprintf('%s',fields{1,k}))];nanmedian([dataraw(j).(sprintf('%s',fields{1,k}))])];
            lapfile.(sprintf('%s',fields{1,k})) = [[lapfile.(sprintf('%s',fields{1,k}))];[dataraw(j).(sprintf('%s',fields{1,k}))]];
            
       
        end

        
    end
    
    
end

%lapfile.mean=meand1;
%lapfile.median=mediand1;

end

%end

