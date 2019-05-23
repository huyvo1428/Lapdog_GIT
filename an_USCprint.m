%FKJN: 14 March 2019
%frejon at irfu.se
%Input: filename, filenameshort, time, data,
%index_nr_of_of_first_file,timing for NPL_TABINDEX, and mode
%mode = 'vfloat' or 'ion' or 'electron'
%Outputs USC.TAB files for the RPCLAP archive
function [] = an_USCprint(USCfname,USCshort,time_arr,data_arr, index_nr_of_firstfile,timing,mode)

global usc_tabindex MISSING_CONSTANT

fprintf(1,'printing %s, mode: %s\n',USCfname, mode);
%'hello'
%fprintf(1,'%s',time_arr{1,1}(1,:));


%fprintf(1,'printing: %s \r\n',USCfname)
USCwID= fopen(USCfname,'w');
N_rows = 0;
row_byte=0;
switch mode
        
        
    case 'vfloat'        
%if strcmp(mode,'vfloat')

    satind=data_arr{1,5}==MISSING_CONSTANT;
    factor=-1; 
    data_arr{1,5}(~satind)=data_arr{1,5}(~satind)*factor;
    usc_flag=data_arr{1,2};%This is the probenumber flag
    for j =1:length(data_arr{1,3})
        
        if data_arr{1,7}(j)~=1 %check if measurement data exists on row
            %fprintf(awID,'%s, %16.6f,,,,\r\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
            % Don't print zero values.
        else
            %if foutarr{1,6}(j)/foutarr{1,5}(j)) >0.5, qvalue = 0.5
            %if foutarr{1,6}(j)/foutarr{1,5}(j)) <0.5, qvalue = 1- foutarr{1,6}(j)/foutarr{1,5}(j))
            qvalue=max(1-abs((data_arr{1,6}(j)/data_arr{1,5}(j))),0.5);
            
            % NOTE: time_arr{1,1}(j,:) contains UTC strings with 3 second decimals. This should be the same number of
            % decimals as for case "vz". /Erik P G Johansson 2018-11-16
            row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',time_arr{1,1}(j,:),time_arr{1,2}(j),data_arr{1,5}(j),qvalue,usc_flag(j),data_arr{1,8}(j));
            N_rows = N_rows + 1;
        end%if
        
    end%for
    fclose(USCwID);
    
    
    usc_tabindex(end+1).fname = USCfname;                   % Start new line of an_tabindex, and record file name
    usc_tabindex(end).fnameshort = USCshort; % shortfilename
    usc_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
    usc_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
    usc_tabindex(end).no_of_columns = 6;            % Number of columns
    usc_tabindex(end).type = 'Vfloat'; % Type
    usc_tabindex(end).timing = timing;
    usc_tabindex(end).row_byte = row_byte;
    
    
    
    case 'vz'
        
        
        factor=-1; %Vz data is being outputted by bias potential it is identified on,
        %so opposite sign applies. However, if we want to change this from 
        %a proxy to a Spacecraft potential, we could manipulate this factor.
        %possibly to something like 1/0.8, or something.
        
        satind=data_arr.Vz(:,1)==MISSING_CONSTANT;
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
        
        %prepare usc_flag
        usc_flag=3*ones(1,length(data_arr.qf));
        usc_flag(extrap_indz)=4;
        
        for j = 1:length(data_arr.qf)
            
            if data_arr.lum(j) > 0.9 %shadowed probe data is not allowed
                % NOTE: data_arr.Tarr_mid{j,1}(j,1) contains UTC strings with 6 second decimals. Truncates to have the same
                % number of decimals as for case "vfloat". /Erik P G Johansson 2018-11-16
                row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %4.2f, %01i, %03i\r\n',data_arr.Tarr_mid{j,1}(1:23),data_arr.Tarr_mid{j,2},data_arr.Vz(j,1),data_arr.Vz(j,2),usc_flag(j),data_arr.qf(j));
                %row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',data_arr.Tarr_mid{j,1},data_arr.Tarr_mid{j,2},factor*data_arr.Vz(j),qvalue,data_arr.qf(j));
                N_rows = N_rows + 1;
            end
            
            
        end
        

            usc_tabindex(end+1).fname = USCfname;                   % Start new line of an_tabindex, and record file name
            usc_tabindex(end).fnameshort = USCshort; % shortfilename
            usc_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
            usc_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
            usc_tabindex(end).no_of_columns = 6;            % Number of columns
            usc_tabindex(end).type = 'Vz'; % Type
            usc_tabindex(end).timing = timing;
            usc_tabindex(end).row_byte = row_byte;         
end%switch mode        
        
    
fileinfo = dir(USCfname);
if fileinfo.bytes ==0 %happens if the entire collected file is empty (all invalid values)
  %  if N_rows > 0 %doublecheck!
        delete(USCfname); %will this work on any OS, any user?
        usc_tabindex(end) = []; %delete tabindex listing to prevent errors.
   % end
    
else

end


        
        


%elseif  strcmp(mode,'vfloat')


    %fprintf(1,'error, wrong mode: %s\r\n',mode');
end


