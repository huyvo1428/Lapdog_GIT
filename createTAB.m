function []= createTAB(derivedpath,tabind,index,fileflag)
%derivedpath   =  filepath
%tabind         = data block indices for each measurement type, array
%index          = index array from earlier creation - Ugly way to remember index
%inside function.
%fileflag       = identifier for type of data

%    FILE GENESIS
%After Discussion 24/1 2014
%%FILE CONVENTION: RPCLAP_YYMMDD_hhmmss_MMM_APC
%%MMM = MacroID, A= Measured quantity (B/I/V)%% , P=Probe number
%%(1/2/3), C = Mode (H/L/S)
% B = probe bias voltage file
% I = Current file, static Vb
% V = potential
%
% H = High frequency data
% L = Low frequency data
% S = Voltage sweep data (bias voltage file or current file)
% File should contain Time, spacecraft time, current, bias potential
%Qualityfactor
% TIME STAMP example : 2011-09-05T13:45:20.026075
%YYYY-MM-DDThh:mm:ss.ffffff % double[s],double[A],double [V],int


dirY = datestr(index(tabind(1)).t0,'YYYY');
dirM = upper(datestr(index(tabind(1)).t0,'mmm'));
dirD = strcat('D',datestr(index(tabind(1)).t0,'dd'));
tabfolder = strcat(derivedpath,'/',dirY,'/',dirM,'/',dirD,'/');

if (exist(tabfolder, 'dir')~=7)
    mkdir(tabfolder);
end

filename = sprintf('%sRPCLAP_%s_%s_%d_%s.TAB',tabfolder,datestr(index(tabind(1)).t0,'yyyymmdd'),datestr(index(tabind(1)).t0,'HHMMSS'),index(tabind(1)).macro,fileflag); %%
filenamep = strrep(filename,tabfolder,'');
% 
% if exist(filename, 'file')==2
%     delete(filename)  %remove old files already created since
%     %code appends to existing file whenever possible (duplicates!)?
% end

twID = fopen(filename,'w');

global tabindex;
tabindex{end+1,1} = filename; %% Let's remember all TABfiles we create
tabindex{end,2} = filenamep; %%their shorter name
tabindex{end,3} = tabind(1); %% and the first index number



len = length(tabind);
counttemp = 0;
%tot_bytes = 0;
if(~index(tabind(1)).sweep); %% if not a sweep, do:
    for(i=1:len);
        trID = fopen(index(tabind(i)).tabfile);
        
        scantemp = textscan(trID,'%s%f%f%f','delimiter',',');
        scanlength = length(scantemp{1,1});
        counttemp = counttemp + scanlength;
        
      
       % bytes = 0;
        
        for (j=1:scanlength)        
            %scantemp2={scantemp{1,1}{j,1},scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j)};
            %dlmcell(filename,scantemp2,'-a',',');
            %fprintf(t 
            %bytes = fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
            fprintf(twID,'%s,%16.6f,%14.7e,%14.7e,\n',scantemp{1,1}{j,1}(1:23),scantemp{1,2}(j),scantemp{1,3}(j),scantemp{1,4}(j));
            
            %prints out data, remembers the number of bytes written (to be
            %used in LBL file?
        end
        
        
        if (i==len)
            tabindex{end,4}= scantemp{1,1}{end,1}; %%remember stop time in universal time and spaceclock time
            tabindex{end,5}= scantemp{1,2}(end); %subset scantemp{1,1} is a cell array, but scantemp{1,2} is a normal array
            tabindex{end,6}= counttemp;
            %tabindex{end,7}= tot_bytes;
        end
        
        fclose(trID);
        clear scantemp scanlength
        
        
        
    end
else %% if sweep, do!
    
    filename2 = filename;
    filename2(end-6) = 'I'; %current data file name according to convention
%    
%     if exist(filename2,'file')==2 %this doesn't work!
%         delete('filename2');
%     end
    condfile = fopen(filename2,'w');
    fclose(condfile); %ugly way of deleting if it exists, we need appending filewrite
    
    condfile = fopen(filename2,'a');
    for(i=1:len);
        trID = fopen(index(tabind(i)).tabfile);
        scantemp = textscan(trID,'%s%f%f%f','delimiter',',');  
        
        %first values are not in the defined sweep, delete all rows will cause trouble if first
        %potential values change during 4-5 time periods
        step1 = find(diff(scantemp{1,4}(1:end)),1,'first');       

%        scantemp{1,:}(1:step1-1)    = []; didnt work..., do seperate:
        scantemp{1,1}(1:step1)    = []; 
        scantemp{1,2}(1:step1)    = [];
        scantemp{1,3}(1:step1)    = [];
        scantemp{1,4}(1:step1)    = [];

        scanlength = length(scantemp{1,1});

        if (i==1)
            reltime = scantemp{1,2}(:)-scantemp{1,2}(1);
            pottemp = [scantemp{1,4}(1:end),reltime(:)];
            dlmwrite(filename,pottemp,'-append','precision', '%14.7e'); %also writes \n
            
        end
        curtemp = scantemp{1,3}(:).'; %transpose..
        fprintf(condfile,'%s,%s,%16.6f,%16.6f,',scantemp{1,1}{1,1}(1:23),scantemp{1,1}{end,1}(1:23),scantemp{1,2}(1),scantemp{1,2}(end));
        dlmwrite(filename2,curtemp,'-append','precision', '%14.7e'); %appends to end of row, column 4. pretty neat.
        
        if (i==len)
            
            tabindex(end,4:6)= {scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),scanlength}; %one index for bias voltages
            tabindex(end+1,1:6)={filename2,strrep(filename2,tabfolder,''),tabind(1), scantemp{1,1}{end,1}(1:23),scantemp{1,2}(end),len};
            
            %one index for currents and two timestamps
            %%remember stop time in universal time and spaceclock time
            %subset scantemp{1,1} is a cell array, but scantemp{1,2} is a normal array
            %%remember stop time in universal time and spaceclock time
        end
        fclose(trID); %read file, terminated each new read iteratin
    end
    fclose(condfile); %write file nr 2, condensed data, terminated asap
    
end
fclose(twID); %write file nr 1


end



