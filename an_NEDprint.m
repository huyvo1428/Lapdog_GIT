
%Copy of an_USCprint.m but tweaked for NED.TAB files
%FKJN: 14 March 2019
%frejon at irfu.se
%Input: filename, filenameshort, time, data,
%index_nr_of_of_first_file,timing for NED_TABINDEX, and mode
%mode = 'vfloat' or 'vz'
%Outputs NED.TAB files for the RPCLAP archive
%Depending on the mode, pre-made fits will be applied to create a density
%estimate. These fits should have large impact on quality values
%
function [] = an_NEDprint(NEDfname,NEDshort,data_arr,t_et,index_nr_of_firstfile,timing,mode)

global NED_tabindex MISSING_CONSTANT
fprintf(1,'printing %s, mode: %s\n',NEDfname, mode);

N_rows = 0;
row_byte=0;

%load('NED_FIT.mat', 'NED_FIT');

        
load('NEL_V_FIT.mat', 'NEL_V_FIT');
NED_FIT=NEL_V_FIT;

[t_et_end,NED_FIT_end]=max(NED_FIT.t_et);
[t_et_min,NED_FIT_start]=min(NED_FIT.t_et);
switch mode
        
    case 'vfloat'       
        
        if all(~data_arr.printboolean(:))%if all 0
            fprintf(1,'skipping because of bool %s, mode: %s\n',NEDshort, mode);
            return;
        end
        
        if ismember(NEDshort,{'RPCLAP_20160715_033202_417_NED.TAB','RPCLAP_20160715_020746_615_NED.TAB'})
            fprintf(1,'skipping %s, mode: %s\n',NEDfname, mode);
            return;
        end

    P_interp1= interp1(NED_FIT.t_et,NED_FIT.P(:,1),t_et);
    P_interp2= interp1(NED_FIT.t_et,NED_FIT.P(:,2),t_et);
    interp_qv= interp1(NED_FIT.t_et,NED_FIT.qv,t_et);

    indz_end=t_et>t_et_end;
    P_interp1(indz_end)= NED_FIT.P(NED_FIT_end,1);
    P_interp2(indz_end)= NED_FIT.P(NED_FIT_end,2);
    interp_qv(indz_end)= 0;

    indz_start=t_et<t_et_min;
    P_interp1(indz_start)= NED_FIT.P(NED_FIT_start,1);
    P_interp2(indz_start)= NED_FIT.P(NED_FIT_start,2);
    interp_qv(indz_start)= 0;

    
    %[junk,ind]= min(abs(NED_FIT.t_et-t_et(1)));        
    %p1=NED_FIT.P(ind,1);
    %p2=NED_FIT.P(ind,2);
    %y1 = exp(p2)*exp(usc.usc(indz)*p1);
    data_arr.N_ED=data_arr.V;
    satind=data_arr.V==MISSING_CONSTANT;
    vj = -3;

    VS1 = -data_arr.V+5.5*exp(-data_arr.V/8); % correct USC to VS1 according to Anders' model. 
    VS1(-data_arr.V>0)=nan;  %saturation and strange errors
    %del_ind=-data_arr.Vz>0;
    
    %I think we can safely assume that there are no Vph_knee data in Vfloat
    %mode. hopefully. Atleast it doesn't make sense to ffrom different
    %sources here
%    ind_vph= data_arr.Vz(:,1)>vj&~isnan(data_arr.Vph_knee(:,1))&data_arr.Vph_knee(:,2)>0.3&data_arr.Vph_knee(:,1)>vj;
%     VS1(ind_vph)=data_arr.Vph_knee(ind_vph,1);
%     VS1qv(ind_vph) = data_arr.Vph_knee(ind_vph,2);
    
    data_arr.N_ED(~satind)=exp(P_interp2(~satind)).*exp(VS1(~satind).*P_interp1(~satind));
    data_arr.N_ED(isnan(VS1)|(isnan(data_arr.N_ED)))=MISSING_CONSTANT;
   
    
    
    %data_arr.N_ED(~satind)=exp(p2)*exp(-data_arr.V(~satind)*p1);
   % data_arr.N_ED(~satind)=exp(P_interp2(~satind)).*exp(-data_arr.V(~satind).*P_interp1(~satind));

    %factor=1; 
    %data_arr.V(~satind)=data_arr.V(~satind)*factor;
    NED_flag=data_arr.probe;%This is the probenumber/product type flag
    %take this out of the loop
    qvalue=max(1-abs(data_arr.V_sigma(:)./data_arr.V(:)),0.5);
    qvalue(satind)=0;
    data_arr.qv= qvalue.*interp_qv.';

    NEDwID= fopen(NEDfname,'w');

    for j =1:length(data_arr.V)
        
        if data_arr.printboolean(j)~=1 %check if measurement data exists on row
            %fprintf(awID,'%s, %16.6f,,,,\r\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
            % Don't print zero values.
        else
            %qvalue=max(1-abs(data_arr.V_sigma(j)/data_arr.V(j)),0.5);
            %qvalue=max(1-abs((data_arr{1,6}(j)  /data_arr{1,5}(j))),0.5);

            %data_arr.V(j)=MISSING_CONSTANT;
            row_byte= fprintf(NEDwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.t_utc(j,:),data_arr.t_obt(j), data_arr.N_ED(j),data_arr.qv(j),NED_flag(j),data_arr.qf(j));
%            row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',time_arr{1,1}(j,:),time_arr{1,2}(j),data_arr{1,5}(j),qvalue,usc_flag(j),data_arr{1,8}(j));

            N_rows = N_rows + 1;
        end%if
        
    end%for
    fclose(NEDwID);
    
    
    NED_tabindex(end+1).fname = NEDfname;                   % Start new line of an_tabindex, and record file name
    NED_tabindex(end).fnameshort = NEDshort; % shortfilename
    NED_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
    NED_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
    NED_tabindex(end).no_of_columns = 6;            % Number of columns
    NED_tabindex(end).type = 'Vfloat'; % Type
    NED_tabindex(end).timing = timing;
    NED_tabindex(end).row_byte = row_byte;
    
%     fileinfo = dir(NEDfname);
%     if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
%         %  if N_rows > 0 %doublecheck!
%         delete(NEDfname); %will this work on any OS, any user?
%         NED_tabindex(end) = []; %delete tabindex listing to prevent errors.
%         % end
%                 
%     end

    
    case 'vz'
        
        if all(data_arr.lum(:) < 0.9)
            fprintf(1,'skipping because of bool %s, mode: %s\n',NEDshort, mode);
            return;
        end
    
    %BASIC SOLUTION ONLY LOOKS FOR CLOSEST POINT
    [junk,ind]= min(abs(NED_FIT.t_et-data_arr.t0(1)));
        
    p1=NED_FIT.P(ind,1);
    p2=NED_FIT.P(ind,2);
    %y1 = exp(p2)*exp(usc.usc(indz)*p1);
    data_arr.N_ED=data_arr.Vz;
    satind=data_arr.Vz(:,1)==MISSING_CONSTANT;

    
    P_interp1= interp1(NED_FIT.t_et,NED_FIT.P(:,1),t_et);
    P_interp2= interp1(NED_FIT.t_et,NED_FIT.P(:,2),t_et);
    interp_qv= interp1(NED_FIT.t_et,NED_FIT.qv,t_et);

    indz_end=t_et>t_et_end;
    P_interp1(indz_end)= NED_FIT.P(NED_FIT_end,1);
    P_interp2(indz_end)= NED_FIT.P(NED_FIT_end,2);
    interp_qv(indz_end)= 0;

    indz_start=t_et<t_et_min;
    P_interp1(indz_start)= NED_FIT.P(NED_FIT_start,1);
    P_interp2(indz_start)= NED_FIT.P(NED_FIT_start,2);
    interp_qv(indz_start)= 0;

    
    %[junk,ind]= min(abs(NED_FIT.t_et-t_et(1)));        
    %p1=NED_FIT.P(ind,1);
    %p2=NED_FIT.P(ind,2);
    %y1 = exp(p2)*exp(usc.usc(indz)*p1);
    data_arr.N_ED=data_arr.Vz(:,1);
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
    
    %If I want to show leniency to left-wing activists, this is where I would show it with e.g. (-1)
    vj_vph= vj+5.5*exp(vj/8); %0.7801 needed for swap to Vphknee later.

    %remember that Vz is -Vz(Vb) 
    VS1 = -data_arr.Vz(:,1)+5.5*exp(-data_arr.Vz(:,1)/8);
    VS1(-data_arr.Vz(:,1)>0)=nan; % these will be picked up soon
    
    %   Vz<3 ?   &~isnan(Vphknee(:,1))?     & Vph_knee(:,2)>0.3? changed to vph_knee_qv in an_outputscience.m    &data_arr.Vph_knee(:,1)>vj;

    ind_vph= -data_arr.Vz(:,1)>vj&~isnan(data_arr.Vph_knee(:,1))&data_arr.Vph_knee(:,2)>0.3&data_arr.Vph_knee(:,1)>vj_vph;
    VS1(ind_vph)=data_arr.Vph_knee(ind_vph,1);
    VS1qv(ind_vph) = data_arr.Vph_knee(ind_vph,2);
    data_arr.qv= VS1qv.*interp_qv;

    data_arr.N_ED(~satind)=exp(P_interp2(~satind)).*exp((VS1(~satind)).*P_interp1(~satind));
    data_arr.N_ED(isnan(VS1)|(isnan(data_arr.N_ED)))=MISSING_CONSTANT; %here we map them back to missing constant

    
    
      %  factor=-1; %Vz data is being outputted by bias potential it is identified on,
        %so opposite sign applies. However, if we want to change this from 
        %a proxy to a Spacecraft potential, we could manipulate this factor.
        %possibly to something like 1/0.8, or something.
        

        %find all extrapolation points: I don't want to change the an_swp
        %routine, so let's do the conversion here instead
         extrap_indz=data_arr.Vz(:,2)==0.2;
         %data_arr.Vz(extrap_indz,2)=0.7; % change 0.2 to 0.7. I mean, it's clearly not several intersections. 
        %and it survived ICA validation. It's clearly not as good quality as a detected zero-crossing though
        
        %prepare NED_flag
        NED_flag=3*ones(1,length(data_arr.qf));
        NED_flag(extrap_indz)=4;
        NEDwID= fopen(NEDfname,'w');

        for j = 1:length(data_arr.qf)
                        % row_byte= sprintf('%s, %16.6f, %14.7e, %3.1f, %01i, %03i\r\n',data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2},data_arr.N_ED(j),data_arr.Vz(j,2),NED_flag(j),data_arr.qf(j));
   
            if data_arr.lum(j) > 0.9 %shadowed probe data is not allowed
                % NOTE: data_arr.Tarr_mid{j,1}(j,1) contains UTC strings with 6 second decimals. Truncates to have the same
                % number of decimals as for case "vfloat". /Erik P G Johansson 2018-11-16
                row_byte= fprintf(NEDwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2},data_arr.N_ED(j),data_arr.qv(j),NED_flag(j),data_arr.qf(j));
                %row_byte= fprintf(NEDwID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',data_arr.Tarr_mid{j,1},data_arr.Tarr_mid{j,2},factor*data_arr.Vz(j),qvalue,data_arr.qf(j));
                N_rows = N_rows + 1;
            end
            
            
        end
            fclose(NEDwID);

        

            NED_tabindex(end+1).fname = NEDfname;                   % Start new line of an_tabindex, and record file name
            NED_tabindex(end).fnameshort = NEDshort; % shortfilename
            NED_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
            NED_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
            NED_tabindex(end).no_of_columns = 6;            % Number of columns
            NED_tabindex(end).type = 'Vz'; % Type
            NED_tabindex(end).timing = timing;
            NED_tabindex(end).row_byte = row_byte;
        
%             
%             fileinfo = dir(NEDfname);
%             if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
%                 %  if N_rows > 0 %doublecheck!
%                 delete(NEDfname); %will this work on any OS, any user?
%                 NED_tabindex(end) = []; %delete tabindex listing to prevent errors.
%                 % end
%                                 
%             end

            
    otherwise
        fprintf(1,'Unknown Method:%s',mode);            
end%switch mode        

    
fileinfo = dir(NEDfname);
if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
  %  if N_rows > 0 %doublecheck!
        delete(NEDfname); %will this work on any OS, any user?
        NED_tabindex(end) = []; %delete tabindex listing to prevent errors.
   % end
    
end


end
