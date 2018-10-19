
function [] = an_USCprint(USCfname,USCshort,time_arr,data_arr, index_nr_of_firstfile,timing,mode)


fprintf(1,'printing %s, mode: %s\n',USCfname, mode);
%'hello'
%fprintf(1,'%s',time_arr{1,1}(1,:));



global usc_tabindex SATURATION_CONSTANT


%fprintf(1,'printing: %s \r\n',USCfname)
USCwID= fopen(USCfname,'w');
N_rows = 0;

switch mode
        
        
    case 'vfloat'        
%if strcmp(mode,'vfloat')

    satind=data_arr{1,5}==SATURATION_CONSTANT;
    factor=-1; 
    data_arr{1,5}(~satind)=data_arr{1,5}(~satind)*factor;
    for j =1:length(data_arr{1,3})
        
        if data_arr{1,7}(j)~=1 %check if measurement data exists on row
            %fprintf(awID,'%s, %16.6f,,,,\r\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
            % Don't print zero values.
        else
            %if foutarr{1,6}(j)/foutarr{1,5}(j)) >0.5, qvalue = 0.5
            %if foutarr{1,6}(j)/foutarr{1,5}(j)) <0.5, qvalue = 1- foutarr{1,6}(j)/foutarr{1,5}(j))
            qvalue=max(1-abs((data_arr{1,6}(j)/data_arr{1,5}(j))),0.5);
            
            row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',time_arr{1,1}(j,:),time_arr{1,2}(j),data_arr{1,5}(j),qvalue,data_arr{1,8}(j));
            N_rows = N_rows + 1;
        end%if
        
    end%for
    fclose(USCwID);
    
    
    usc_tabindex(end+1).fname = USCfname;                   % Start new line of an_tabindex, and record file name
    usc_tabindex(end).fnameshort = USCshort; % shortfilename
    usc_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
    usc_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
    usc_tabindex(end).no_of_columns = 5;            % Number of columns
    % usc_tabindex{end,6] = an_ind(i);
    usc_tabindex(end).type = 'Vfloat'; % Type
    usc_tabindex(end).timing = timing;
    usc_tabindex(end).row_byte = row_byte;
    
    
    
    case 'vz'
        

        factor=-1;      
        satind=data_arr.Vz(:,1)==SATURATION_CONSTANT;
        %data_arr.Vz(satind,1)=data_arr.Vz(satind,1)*sign(factor); %either -1 or 1. will later be multiplied with 1, such that -1000 is still the only valid saturation constant
        data_arr.Vz(~satind,1)=factor*data_arr.Vz(~satind,1);
        %Vz= data_arr.Vz;
        %time= data_arr.Tarr_mid
        %qvalue=0.7;
        
        for j = 1:length(data_arr.qf)
            
            row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',data_arr.Tarr_mid{j,1},data_arr.Tarr_mid{j,2},data_arr.Vz(j,1),data_arr.Vz(j,2),data_arr.qf(j));            
            %row_byte= fprintf(USCwID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',data_arr.Tarr_mid{j,1},data_arr.Tarr_mid{j,2},factor*data_arr.Vz(j),qvalue,data_arr.qf(j));
            N_rows = N_rows + 1;
            
            
        end
        

        
        
    usc_tabindex(end+1).fname = USCfname;                   % Start new line of an_tabindex, and record file name
    usc_tabindex(end).fnameshort = USCshort; % shortfilename
    usc_tabindex(end).first_index = index_nr_of_firstfile; % First calib data file index
    usc_tabindex(end).no_of_rows = N_rows;                % length(foutarr{1,3}); % Number of rows
    usc_tabindex(end).no_of_columns = 5;            % Number of columns
    % usc_tabindex{end,6] = an_ind(i);
    usc_tabindex(end).type = 'Vz'; % Type
    usc_tabindex(end).timing = timing;
    usc_tabindex(end).row_byte = row_byte;
    
    
        
        
end

%elseif  strcmp(mode,'vfloat')


    %fprintf(1,'error, wrong mode: %s\r\n',mode');
end


