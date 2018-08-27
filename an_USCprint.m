
function [] = an_USCprint(USCfname,USCshort,time_arr,foutarr, index_nr_of_firstfile,timing,probenr,mode)


global usc_tabindex


%%%--------illumination check------------------------%%%
dynampath = strrep(mfilename('fullpath'),'/an_USCprint','');
kernelFile = strcat(dynampath,'/metakernel_rosetta.txt');
paths(); 

cspice_furnsh(kernelFile);
[junk,SEA,SAA]=orbit('Rosetta',Tarr(1:2,:),target,'ECLIPJ2000','preloaded');
cspice_kclear;



   % *My values* (from photoemission study):
           % Phi11 = 131.2;%degrees
            %Phi12 = 179.2;
if probenr==1
    Phi11 = 131;
    Phi12 = 181;
    illuminati = ((SAA < Phi11) | (SAA > Phi12));

    % *Anders values* (+90 degrees)
    
else
    
    
    Phi21 = 18;
    Phi22 = 82;
    Phi23 = 107;
    illuminati = ((SAA < Phi21) | (SAA > Phi22)) - 0.6*((SAA > Phi22) & (SAA < Phi23));
end
SEA_OK = abs(SEA)<1; %  <1 degree  = nominal pointing
illuminati(~SEA_OK)=0.3;

dark_ind=illuminati<0.9;
foutarr{1,7}(dark_ind)=1; %won't be printed.
%%%----------------------------------------------%%% 



fprintf(1,'printing: %s \r\n',USCfname)
USCwID= fopen(USCfname,'w');
N_rows = 0;

if strcmp(mode,'vfloat')
    for j =1:length(foutarr{1,3})
        
        if foutarr{1,7}(j)~=1 %check if measurement data exists on row
            %fprintf(awID,'%s, %16.6f,,,,\r\n',tfoutarr{1,1}{j,1},tfoutarr{1,2}(j));
            % Don't print zero values.
        else
            %if foutarr{1,6}(j)/foutarr{1,5}(j)) >0.5, qvalue = 0.5
            %if foutarr{1,6}(j)/foutarr{1,5}(j)) <0.5, qvalue = 1- foutarr{1,6}(j)/foutarr{1,5}(j))
            qvalue=max(1-abs((foutarr{1,6}(j)/foutarr{1,5}(j))),0.5);
            
            
            
            row_byte= fprintf(awID,'%s, %16.6f, %14.7e, %3.1f, %05i\r\n',time_arr{1,1}(j,:),time_arr{1,2}(j),foutarr{1,5}(j),qvalue,sum(foutarr{1,8}(j)));
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
    usc_tabindex(end).type = 'USC'; % Type
    usc_tabindex(end).timing = timing;
    usc_tabindex(end).row_byte = row_byte;
    
else
    
    fprintf(1,'error, wrong mode: %s\r\n',mode');
end

end

