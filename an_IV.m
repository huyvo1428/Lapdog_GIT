
% analysis




global an_tabindex;
an_tabindex = [];

%for i=1:length(tabindex);

%andate = tabindex{:,1}(end-47:end-35);
antype = cellfun(@(x) x(end-6:end-4),tabindex(:,2),'un',0);
andate = str2double(cellfun(@(x) x(8:15),tabindex(:,2),'un',0));

%end
%tab_I1H =find(strfind(antype,'I1H'));%strfind(antype,'I2H'));

%ind_I1H= find(strcmp('I1H', antype)|strcmp('I2H', antype));



%find datasets of different modes
ind_I1H= find(strcmp('I1H', antype));
ind_I2H= find(strcmp('I2H', antype));
ind_I1L= find(strcmp('I1L', antype));
ind_I2L= find(strcmp('I2L', antype));


ind_V1L= find(strcmp('V1L', antype));
ind_V2L= find(strcmp('V2L', antype));
ind_V1H= find(strcmp('V1H', antype));
ind_V2H= find(strcmp('V2H', antype));




% 


%send mode datatasets to downsampler function
if(~isempty(ind_I1L))
    %an_downsample(ind_I1L,tabindex,8)
    an_downsample(ind_I1L,tabindex,32)
end

if(~isempty(ind_I2L))

   % an_downsample(ind_I2L,tabindex,8)
    an_downsample(ind_I2L,tabindex,32)
end

if(~isempty(ind_V1L))

   % an_downsample(ind_V1L,tabindex,8)
    an_downsample(ind_V1L,tabindex,32)
end

if(~isempty(ind_V2L))

  %  an_downsample(ind_V2L,tabindex,8)
    an_downsample(ind_V2L,tabindex,32)
end

% 
% No downsampling of **H files....

% if(~isempty(ind_V2H))
% 

% end
% 
% if(~isempty(ind_V1H))
% 

% end
% 
% 
% if(~isempty(ind_I1H))
% 

% end
% if(~isempty(ind_I2H))
% 

% 
% end
% 
% 






an_ind= ind_I2L;
an_ind = [];

for i=1:length(an_ind)
    
    
    arID = fopen(tabindex{an_ind(i),1},'r');
    scantemp=textscan(arID,'%s%f%f%f','delimiter',',');
    fclose(arID);
    
    j=i+1;
    while le(j,length(an_ind))
        
        if andate(an_ind(i)) ==andate(an_ind(j))
            %scantemp2
            arID = fopen(tabindex{an_ind(j),1},'r');
            scantemp2=textscan(arID,'%s%f%f%f','delimiter',',');
            fclose(arID);
            
            scantemp{1,1}=[scantemp{1,1}(:);scantemp2{1,1}(:)];
            scantemp{1,2}=[scantemp{1,2}(:);scantemp2{1,2}(:)];
            scantemp{1,3}=[scantemp{1,3}(:);scantemp2{1,3}(:)];
            scantemp{1,4}=[scantemp{1,4}(:);scantemp2{1,4}(:)];
            clear scantemp2
            an_ind(j)=[];
            
            
        else
            j=length(an_ind)+1;
            
            
        end
        
        
    end
    
    
    
    
    %UTCpart1 = scantemp{1,1}{1,1}(1:11);
    intval = 32;
    
    
    %set starting spaceclock time to (UTC) 00:00:00.000000
    ah =str2double(scantemp{1,1}{1,1}(12:13));
    am =str2double(scantemp{1,1}{1,1}(15:16));
    as =str2double(scantemp{1,1}{1,1}(18:end)); %including fractions of seconds
    hms = ah*3600 + am*60 + as;
    tday0=scantemp{1,2}(1)-hms; %%UTC and Spaceclock must be correctly defined
    
    UTCpart1 = scantemp{1,1}{1,1}(1:10);
    
    
    
    
    
    %inter = 1 + floor((scantemp{1,2}(:) - tday0)/intval); %prepare subset selection to accumarray
    %inter = inter - inter(1)+1;
    %intervals specified from beginning of day, in intervals of intval,
    %and the variable inter marks which interval the data in the file is related to
    t=scantemp{1,2}(:);
    
    
    
    
    inter = 1 + floor((scantemp{1,2}(:) - scantemp{1,2}(1))/intval); %prepare subset selection to accumarray  
  
    
    %tt = ( tday0+intval*floor((t(1)-tday0)/intval):1*intval:tday0+intval*ceil((t(end)-tday0)/intval) )'; %tidst?mplar med 32 sekunder mellan varje st?mpel, startar p? en multipel av 32 p? dygnet
    tt = ( floor(t(1)/intval)*intval:1*intval:intval*ceil(t(end)/intval) )';
    
    
    imu = accumarray(inter,scantemp{1,3}(:),[],@mean,NaN); %select measurements during specific intervals, accumulate mean to array and print zero otherwise
    isd = accumarray(inter,scantemp{1,3}(:),[],@std); %select measurements during specific intervals, accumulate standard deviation to array and print zero otherwise
    
    vmu = accumarray(inter,scantemp{1,4}(:),[],@mean);
    vsd = accumarray(inter,scantemp{1,4}(:),[],@std);
    
    tmu =accumarray(inter,scantemp{1,2}(:),[],@mean); %this is just to get rough time positions, disregarding times where we have no measurement.
    
    del= find(isnan(imu));
    
    imu(del)=[];
    isd(del)=[];
    vsd(del)=[];
    vmu(del)=[];
    tmu(del)=[];
    
   
    tmu= 0.5*intval*floor((tmu-tday0)*2/intval); %averages are taken at centre of interval, using 
    

    tmu = datenum(datestr((tmu)/(3600*24), 'HH:MM:SS.FFF')) + datenum(UTCpart1,'yyyy-mm-dd')-datenum('00:00','HH:MM');
  
    
    
    
    
   % tUTC=datenum(datestr((tmu+tmu(1))/(3600*24), 'HH:MM:SS.FFF'));
    
    
    
    %tUTC = sprintf('%s %s',UTCpart1,UTCpart2);
    
 Ap = 0.0078539816; %Probe area [m^2]
rp = 0.025; %Probe radius [m]
qe = 1.60217733e-19; %elementary charge [C]
kBe = 8.617385e-5; %Boltzmanns constant [eV/K]
kB = 1.380658e-23; %Boltzmanns constant [J/K]
me = 9.1093897e-31; %electron mass [kg]   
    

    
    
 figure(16)
    

    
    subplot(2,1,1)
    plot(tmu,1e9*imu);
   datetick('x',15);
    ylabel('Ip [nA]');
    
    subplot(2,1,2)
    plot(tmu,vmu);
     datetick('x',15);
    ylabel('Vmu [V]');
 %    title(UTCpart1)
    
    
    samexaxis('join');
    
    figure(17)
  subplot(1,1,1)
    plot(vmu,1e9*imu);
    xlabel('Vb [V]');
    ylabel('Ip [nA]');
    titstr ='hello';
    drawnow;
    
    
        
    for k=1:length(imu)
        
        if vmu(k) >0
       
            
        gradimu = (imu(k)-imu(k+1))/(tmu(k)-tmu(k+1))
        K = Ap*sqrt(kBe/(2*pi*me));
        Te0 =0.5;
        ne0 = imu(k)/(K*sqrt(Te0)*(1+vmu(k)/Te0));
        dne0 = gradimu*ne0/imu(k);
        
        Te1 = imu(k)/(2*K*ne0)-sqrt((imu(k)/(2*K*ne0))^2 -vmu(k));
        Te2 = imu(k)/(2*K*ne0)+sqrt((imu(k)/(2*K*ne0))^2 -vmu(k));
        
        %gradimu/
        
        
        
        end
    end
    
    
    
    
%     
%     % Summary plot
%     figure(160)
%     %     sr = 5;
%     %     subplot(sr,1,1)
%     subplot(2,2,4);
%     plot(tmu,imu)
%     datetick('x',31);
%     %     plot(t321,v321,'k.',t322,v322,'r.');
%     %     datetick('x','HH:MM');
%     %     ylabel('Vps [V]');
% 
%     %titstr = sprintf('P%.0f %sT%s',p,datestr(t,29),datestr(t,13));% time
%     title(UTCpart1); %time
%     
%     
%     figure(154);
% 
%     subplot(4,1,1);
%        % plot(derived(:,1),1e9*derived(:,15),'k.',p2s_params(:,1),1e9*p2s_params(:,15)+7,'r.');
%     ylim([-15 0])
%     grid on;
%     datetick('x',15);
%     ylabel('If0 [nA]');
%     if(~isempty(derived))
%       titstr = sprintf('Sweep summary %s',datestr(derived(1,1),29));
%     else
%       titstr = sprintf('Sweep summary %s',datestr(p2s_params(1,1),29));
%     end
%     title(titstr);
% 
%     subplot(4,1,2);
%     plot(derived(:,1),-derived(:,11),'ko',p2s_params(:,1),-p2s_params(:,11),'ro');
%     hold on;
%     plot(derived(:,1),derived(:,16),'k.',p2s_params(:,1),p2s_params(:,16),'r.');
%     hold off;
%     grid on;
%     datetick('x',15);
%     ylim([-5 5]);
%     ylabel('Vps [V]');
% 
%     subplot(4,1,3);
%     Te1 = derived(:,12)./derived(:,13);
%     Te2 = p2s_params(:,12)./p2s_params(:,13);
%     semilogy(derived(:,1),Te1,'k.',p2s_params(:,1),Te2,'r.',derived(:,1),derived(:,14),'ko',p2s_params(:,1),p2s_params(:,14),'ro');
%     ylim([0.01 10]);
%     grid on;
%     datetick('x',15);
%     ylabel('Te [V]');
% 
%     subplot(4,1,4)
%     % Cal fact n/(dI/dV): (1.6e-19)^1.5 * 4 * pi * 0.025 / sqrt(2*pi*Te*9.1e-31); 
%     k = sqrt(2*pi*9.1e-31) ./ ((1.6e-19)^1.5 * 4 * pi * 0.025^2);
%     semilogy(derived(:,1),1e-6*k*derived(:,8).*sqrt(Te1),'k.',p2s_params(:,1),1e-6*k*p2s_params(:,8).*sqrt(Te2),'r.');
%     ylim([0.1 100]);
%     grid on;
%     datetick('x',15);
%     ylabel('ne [cm-3]');
%     
%     samexaxis('join');
%     drawnow;
%     
    
    
    
    
    clear scantemp
    
    
end













