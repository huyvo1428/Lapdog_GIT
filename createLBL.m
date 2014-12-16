%createLBL.m
%CREATE .LBL FILES, FROM PREVIOUS LBL FILES

% save('~/temp.lapdog.createLBL.allvars.mat')   % DEBUG
function createLBL(an_tabindex, tabindex, index, shortphase, producershortname, producerfullname, blockTAB, datasetid, datasetname, missionphase, lbltime, lbleditor, lblrev, targetfullname, targettype)

strnow = datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF');


if(~isempty(tabindex));
    len= length(tabindex(:,3));
    
    
    for(i=1:len)
        
        %tabindex cell array = {tab file name, first index number of batch,
        % UTC time of last row, S/C time of last row, row counter}
        %    units: [cell array] =  {[string],[double],[string],[float],[integer]
        
        % Write label file:
        tname = tabindex{i,2};
        lname=strrep(tname,'TAB','LBL');
        
        
        [fp,errmess] = fopen(index(tabindex{i,3}).lblfile,'r');
        
        if fp < 0
            fprintf(1,'Error, cannot open file %s', index(tabindex{i,3}).lblfile);
            break
        end % if I/O error
        tempfp = textscan(fp,'%s %s','Delimiter','=');
        fclose(fp);
        
        fid = fopen(strrep(tabindex{i,1},'TAB','LBL'),'w');

%         if fid < 0        
%             fprintf(1,'Error, cannot open file %s', strrep(tabindex{i,1},'TAB','LBL'));
%             break
%         end % if I/O error
        
        
        Pnum = tname(end-5);
        
        %This version is not very pretty, but efficient. It reads the first LBL
        %file of the mode in the batch and edits line for line. Sometimes
        %copying some lines and pasting them in the correct position, from
        %bottom to top (to prevent unwanted overwrites).
        
        
        %Assuming no changes to line number order (!!!!)
        
        
        fileinfo = dir(tabindex{i,1});
        tempfp{1,2}{3,1} = sprintf('%d',fileinfo.bytes);
        tempfp{1,2}{4,1} = sprintf('%d',tabindex{i,6});
        tempfp{1,2}{5,1} = lname;
        tempfp{1,2}{6,1} = tname;
        
        tempfp{1,2}{7,1}= strrep(tempfp{1,2}{7,1},sprintf('-3-%s-CALIB',shortphase),sprintf('-5-%s-DERIV',shortphase));
        tempfp{1,2}{8,1}= strrep(tempfp{1,2}{8,1},sprintf('3 %s CALIB',shortphase),sprintf('5 %s DERIV',shortphase));
        
        tempfp{1,2}{14,1}=producershortname;
        tempfp{1,2}{15,1}=sprintf('"%s"',producerfullname);
        
        
        
        %        tempfp{1,2}{16,1} = sprintf('"%s, %s, %s"',lbltime,lbleditor,lblrev);
        %     tempfp{1,2}(17:18) = [];
        %    tempfp{1,1}(17:18) =[]; % should be deleted?
        
        tempfp{1,2}{17} = tname(1:end-4);
        tempfp{1,2}{18} = '"DDR"';
        
        tempfp{1,2}{19,1} = strnow; %product creation time
        tempfp{1,2}{29,1} = '"5"'; %% processing level ID
        tempfp{1,2}{30,1} = index(tabindex{i,3}).t0str(1:23); %UTC start time
        tempfp{1,2}{31,1} = tabindex{i,4}(1:23);             % UTC stop time
        %         tmpsct0 = index(tabindex{i,3}).sct0str(5:end-1);
        
        
        
      %  tempfp{1,2}{32,1} = strcat(index(tabindex{i,3}).sct0str(1:end-1),'"');  %% sc start time
        tempfp{1,2}{32,1} = index(tabindex{i,3}).sct0str;
        tempfp{1,2}{33,1} = sprintf('"%s/%014.3f"',index(tabindex{i,3}).sct0str(2),obt2sct(tabindex{i,5})); %get resetcount from above, and calculate obt from sct

%        tempfp{1,2}{33,1} = obt2sct(tabindex{i,5},scResetCount);
        
       % tempfp{1,2}{33,1} = sprintf('"%s/%017.6f"',index(tabindex{i,3}).sct0str(2),tabindex{i,5}); %% sc stop time
        %   tempfp{1,2}{56,1} = sprintf('%i',tabindex{i,6}); %% rows
        
        
        
        ind= find(ismember(strrep(tempfp{1,1},' ', ''),'ROWS'));% lots of whitespace often
        tempfp{1,2}{ind,1}= sprintf('%i',tabindex{i,6}); %% rows
        
        colind= find(ismember(strrep(tempfp{1,2},' ', ''),'TABLE'));% find table start and end
        
        %         for (j=1:colind(end)-1) %skip last row
        %             fprintf(fid,'%s = %s\n',tempfp{1,1}{j,1},tempfp{1,2}{j,1});
        %         end
        
        byte=1;
        
        
        
        if (tname(30)=='S') % special format for sweep files...
            
            for (j=1:colind(1)-1) %skip last row
                fprintf(fid,'%s = %s\n',tempfp{1,1}{j,1},tempfp{1,2}{j,1});
            end
            if (tname(28)=='B')
                
                data = [];
                data.N_rows      = tabindex{i,6};
                data.N_row_bytes = 30;                   % NOTE: HARDCODED! TODO: Fix.
                data.DESCRIPTION = sprintf('%s Sweep step bias and time between each step', tempfp{1,2}{34,1}(2:end-1));
                cl = [];
                cl{end+1} = struct('NAME', 'SWEEP_TIME',                 'FORMAT', 'E14.7', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'SECONDS', 'DESCRIPTION', 'LAPSED TIME (S/C CLOCK TIME) FROM FIRST SWEEP MEASUREMENT');
                cl{end+1} = struct('NAME', sprintf('P%s_VOLTAGE', Pnum), 'FORMAT', 'E14.7', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'VOLT',    'DESCRIPTION', 'CALIBRATED VOLTAGE BIAS');
                data.column_list = cl;   
                createLBL_writeObjectTable(fid, data)

                
            else %% if tname(28) =='I'
                
                
                fprintf(fid,'OBJECT = TABLE\n');
                fprintf(fid,'INTERCHANGE_FORMAT = ASCII\n');
                fprintf(fid,'ROWS = %d\n',tabindex{i,6});
                fprintf(fid,'COLUMNS = %d\n',tabindex{i,7});
                fprintf(fid,'ROW_BYTES = 115\n');   %%row_bytes here!!!
                fprintf(fid,'DESCRIPTION = %s\n',tempfp{1,2}{34,1});
                fprintf(fid,'DELIMITER = ", "\n');

                
                
                
                
                Bfile = tname;
                Bfile(28)='B';
                
                fprintf(fid,'OBJECT = COLUMN\n');
                fprintf(fid,'NAME = START_TIME_UTC\n');
                fprintf(fid,'DATA_TYPE = TIME\n');
                fprintf(fid,'START_BYTE = %i\n',byte);
                fprintf(fid,'BYTES = 26\n');
                byte=byte+26+2;
                fprintf(fid,'UNIT = SECONDS\n');
                fprintf(fid,'DESCRIPTION = "START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF"\n');
                fprintf(fid,'END_OBJECT  = COLUMN\n');
                
                fprintf(fid,'OBJECT = COLUMN\n');
                fprintf(fid,'NAME = STOP_TIME_UTC\n');
                fprintf(fid,'DATA_TYPE = TIME\n');
                fprintf(fid,'START_BYTE = %i\n',byte);
                fprintf(fid,'BYTES = 26\n');
                byte=byte+26+2;
                fprintf(fid,'UNIT = SECONDS\n');
                fprintf(fid,'DESCRIPTION = "STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF"\n');
                fprintf(fid,'END_OBJECT  = COLUMN\n');
                
                fprintf(fid,'OBJECT = COLUMN\n');
                fprintf(fid,'NAME = START_TIME_OBT\n');
                fprintf(fid,'START_BYTE = %i\n',byte);
                fprintf(fid,'BYTES = 16\n');
                byte=byte+16+2;
                fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                fprintf(fid,'UNIT = SECONDS\n');
                fprintf(fid,'DESCRIPTION = "START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
                fprintf(fid,'END_OBJECT  = COLUMN\n');
                
                fprintf(fid,'OBJECT = COLUMN\n');
                fprintf(fid,'NAME = STOP_TIME_OBT\n');
                fprintf(fid,'START_BYTE = %i\n',byte);
                fprintf(fid,'BYTES = 16\n');
                byte=byte+16+2;                
                fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                fprintf(fid,'UNIT = SECONDS\n');
                %             fprintf(fid,'FORMAT = F16.6\n');
                fprintf(fid,'DESCRIPTION = " STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
                fprintf(fid,'END_OBJECT  = COLUMN\n');
                
                fprintf(fid,'OBJECT = COLUMN\n');
                fprintf(fid,'NAME = QUALITY\n');
                fprintf(fid,'START_BYTE = %i\n',byte);
                fprintf(fid,'BYTES = 3\n');
                byte=byte+3+2;
                fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                fprintf(fid,'UNIT = N/A\n');
                fprintf(fid,'DESCRIPTION = " QUALITY FACTOR FROM 000(best) to 999"\n');
                fprintf(fid,'END_OBJECT  = COLUMN\n');
%                  
                fprintf(fid,'OBJECT = COLUMN\n');
                fprintf(fid,'ITEMS = %i\n',tabindex{i,7}-5);
                fprintf(fid,'NAME = P%s_SWEEP_CURRENT\n',Pnum);
                fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                fprintf(fid,'START_BYTE = %i\n',byte);
                fprintf(fid,'BYTES = 14\n');
                byte=byte+14+2;
                fprintf(fid,'UNIT = AMPERE\n');
                fprintf(fid,'FORMAT = E14.7\n');
                fprintf(fid,'DESCRIPTION = "Averaged current measured of potential sweep, at different potential steps as described by %s"\n',Bfile);
                fprintf(fid,'END_OBJECT  = COLUMN\n');
                
                
                
            end
            
            
        else %if anything but a sweep file
            
            
            ind= find(ismember(strrep(tempfp{1,1},' ', ''),'ROW_BYTES'));
            
            if Pnum ~= '3'
                
                tempfp{1,2}{ind} ='82';
            else
                tempfp{1,2}{ind} ='98';
            end
            
            
            ind= find(ismember(strrep(tempfp{1,1},' ', ''),'START_BYTE'));% lots of whitespace often
            start_byte=[str2double(tempfp{1,2}(ind))];
            
            
            for k =1:length(ind) %Anders wanted spaces between each result
                tempfp{1,2}{ind(k),1}=sprintf('%i',start_byte(k)+k-1);
            end
            
            for (j=1:colind(end)-1) %s
                fprintf(fid,'%s = %s\n',tempfp{1,1}{j,1},tempfp{1,2}{j,1});
            end
            
            
            
            
            %ind= find(ismember(strrep(tempfp{1,1},' ', ''),'START_BYTE'));% lots of whitespace often
            start_byte= str2double(tempfp{1,2}(ind(end),1)) + str2double(tempfp{1,2}(ind(end)+1,1)) + 2;
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = QUALITY\n');
            fprintf(fid,'START_BYTE = %i\n',start_byte);
            fprintf(fid,'BYTES = 3\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = N/A\n');
            fprintf(fid,'DESCRIPTION = " QUALITY FACTOR FROM 000(best) to 999"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
        end
        
        fprintf(fid,'END_OBJECT  = TABLE\n');
        fprintf(fid,'END');
        fclose(fid);
        
        
        
        % %         if (tname(30)=='S') % special format for sweep files...
        % %             if (tname(28)=='B')
        % %
        % %                 tempfp{1,2}{57,1} = '2'; %number of columns
        % %                 tempfp{1,2}{58,1} = '36';% ROW_BYTES
        % %
        % %
        % %                 tempfp{1,2}(76:84) = [];  %remove Current column
        % %                 tempfp{1,1}(76:84) = [];
        % %                 tempfp{1,2}(60:66) = [];  %remove UTC column
        % %                 tempfp{1,1}(60:66) = [];
        % %
        % %
        % %
        % %
        % %                 tempfp{1,2}{61,1} = 'SWEEP_TIME';
        % %                 tempfp{1,2}{63,1} = 'ASCII_REAL';
        % %                 tempfp{1,2}{62,1} = '1';
        % %                 tempfp{1,2}{63,1} = '14';
        % %                 tempfp{1,2}{65,1} = 'SECONDS';
        % %                 tempfp{1,2}{66,1} = '"E14.7"';
        % %                 tempfp{1,2}{67,1} = '"LAPSED TIME (S/C CLOCK TIME) FROM FIRST SWEEP MEASUREMENT SSSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"';
        % %
        % %                 tempfp{1,2}{72,1} = '16';
        % %
        % %             elseif (tname(28)=='I')
        % %                 tempfp{1,2}(92:100) = tempfp{1,2}(76:84); % move sweep current column
        % %                 tempfp{1,1}(92:100) = tempfp{1,1}(76:84);
        % %                 tempfp{1,2}(83:91) = tempfp{1,2}(67:75); %move S/C time column twice
        % %                 tempfp{1,1}(83:91) = tempfp{1,1}(67:75);
        % %                 tempfp{1,2}(74:82) = tempfp{1,2}(67:75);
        % %                 tempfp{1,1}(74:82) = tempfp{1,1}(67:75);
        % %                 tempfp{1,2}(67:73) = tempfp{1,2}(60:66); %copy UTC time column
        % %                 tempfp{1,1}(67:73) = tempfp{1,1}(60:66);
        % %
        % %                 %edit some lines
        % %                 tempfp{1,2}{57,1} = sprintf('%i',tabindex{i,7});  %number of columns
        % %                 tempfp{1,2}{58,1} = '3212'; %row byte size
        % %                 tempfp{1,2}{72,1} = '28';   %second column start byte
        % %
        % %                 tempfp{1,2}{73,1} = '26';   %
        % %                 tempfp{1,2}{78,1} = '56';   %third column start byte
        % %                 tempfp{1,2}{87,1} = '74';   %fourth column start byte
        % %                 tempfp{1,2}{97,1} = '92';   %fifth column start byte
        % %                 tempfp{1,2}{61,1} = '"SWEEP_START_TIME_UTC"';
        % %                 tempfp{1,2}{65,1} = '"START TIME OF SWEEP DATA ROW (UTC)"';
        % %                 tempfp{1,2}{68,1} = '"SWEEP_END_TIME_UTC"';
        % %                 tempfp{1,2}{72,1} = '"END TIME OF SWEEP DATA ROW (UTC)"';
        % %                 tempfp{1,2}{75,1} = '"SWEEP_START_TIME_OBT"';
        % %                 tempfp{1,2}{81,1} = '"START TIME OF SWEEP DATA ROW (SPACECRAFT ONBOARD TIME)"';
        % %                 tempfp{1,2}{84,1} = '"SWEEP_END_TIME_OBT"';
        % %                 tempfp{1,2}{90,1} = '"END TIME OF SWEEP DATA ROW (SPACECRAFT ONBOARD TIME)"';
        % %                 tempfp{1,2}{92,1} = 'COLUMN';
        % %                 tempfp2=tempfp;
        % %                 %% VAD H?LL JAG P? MED H?R!??!
        % %         %        tempfp{1,1}{94,1} = '^STRUCTURE';
        % %          %       Bfile = tname;
        % %           %      Bfile(28)='B';
        % %            %     tempfp{1,2}{94,1} = sprintf('"%s"',Bfile);
        % %                 tempfp{1,1}{95,1} = 'ITEMS';
        % %                 tempfp{1,2}{95,1} = sprintf('%i',tabindex{i,7}-4);
        % %                 tempfp{1,1}(96:end+2) = tempfp2{1,1}(94:end);
        % %                 tempfp{1,2}(96:end+2) = tempfp2{1,2}(94:end);
        % %                 clear tempfp2
        % %                 tempfp{1,2}{101,1} = sprintf('" Averaged current measured of potential sweep, at different potential steps as described by %s"',Bfile);
        % %                 tempfp{1,2}{102,1} = 'COLUMN';
        % %                 tempfp{1,1}{103,1} = 'END_OBJECT';
        % %                 tempfp{1,2}{103,1} = 'TABLE';
        % %                 tempfp{1,1}{104,1} = 'END'; % Ends file, this line is never printed, but we need something on last row
        % %                 %tempfp{1,2}{100,1} = '';%
        % %
        % %             else
        % %                 fprintf(1,'  BAD IDENTIFIER FOUND, %s\n',tname);
        % %             end
        % %
        % %
        % %
        % %         else
        % %
        % %
        % %         end
        % %
        %         for (i=1:length(tempfp{1,1})-1) %skip last row
        %             fprintf(fid,'%s = %s\n',tempfp{1,1}{i,1},tempfp{1,2}{i,1});
        %         end
        %
        %         fprintf(fid,'END');% Ends file
        %         fclose(fid);
        
    end
    
end

%% BLOCK LIST .LBL FILES

if(~isempty(blockTAB));
    len=length(blockTAB(:,3));
    for(i=1:len)
        
        tname = blockTAB{i,2};
        lname=strrep(tname,'TAB','LBL');
        fid = fopen(strrep(blockTAB{i,1},'TAB','LBL'),'w');
        
        fprintf(fid,'PDS_VERSION_ID = PDS3\n');
        fprintf(fid,'RECORD_TYPE = FIXED_LENGTH\n');
        fileinfo = dir(blockTAB{i,1});
        fprintf(fid,'RECORD_BYTES = %d\n',fileinfo.bytes);
        fprintf(fid,'FILE_RECORDS = %d\n',blockTAB{i,3});
        fprintf(fid,'FILE_NAME = "%s"\n',lname);
        fprintf(fid,'^TABLE = "%s"\n',tname);      
        fprintf(fid,'DATA_SET_ID = "%s"\n', strrep(datasetid,sprintf('-3-%s-CALIB',shortphase),sprintf('-5-%s-DERIV',shortphase)));
        fprintf(fid,'DATA_SET_NAME = "%s"\n',strrep(datasetname,sprintf('3 %s CALIB',shortphase),sprintf('5 %s DERIV',shortphase)));
        fprintf(fid,'DATA_QUALITY_ID = 1\n');
        fprintf(fid,'MISSION_ID = ROSETTA\n');
        fprintf(fid,'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\n');
        fprintf(fid,'MISSION_PHASE_NAME = "%s"\n',missionphase);
        fprintf(fid,'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\n');
        fprintf(fid,'PRODUCER_ID = %s\n',producershortname);
        fprintf(fid,'PRODUCER_FULL_NAME = "%s"\n',producerfullname);
        fprintf(fid,'LABEL_REVISION_NOTE = "%s, %s, %s"\n',lbltime,lbleditor,lblrev);
        % mm = length(tname);
        fprintf(fid,'PRODUCT_ID = "%s"\n',tname(1:(end-4)));
        fprintf(fid,'PRODUCT_TYPE = "DDR"\n');  % somewhat of an idea what this means...
        fprintf(fid,'PRODUCT_CREATION_TIME = %s\n',strnow);
        fprintf(fid,'INSTRUMENT_HOST_ID = RO\n');
        fprintf(fid,'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\n');
        fprintf(fid,'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\n');
        fprintf(fid,'INSTRUMENT_ID = RPCLAP\n');
        fprintf(fid,'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\n');
        fprintf(fid,'TARGET_NAME = "%s"\n',targetfullname);
        fprintf(fid,'TARGET_TYPE = "%s"\n',targettype);
        fprintf(fid,'PROCESSING_LEVEL_ID = %d\n',5);
        
        byte = 1;
        
        fprintf(fid,'OBJECT = TABLE\n');
        fprintf(fid,'INTERCHANGE_FORMAT = ASCII\n');
        fprintf(fid,'ROWS = %d\n',blockTAB{i,3});
        fprintf(fid,'COLUMNS = 3\n');
        fprintf(fid,'ROW_BYTES = 59\n');
        fprintf(fid,'DESCRIPTION = "BLOCKLIST DATA. START & STOP TIME OF MACROBLOCK AND MACROID."\n');
        
        
        
        fprintf(fid,'OBJECT = COLUMN\n');
        fprintf(fid,'NAME = START_TIME_UTC\n');
        fprintf(fid,'DATA_TYPE = TIME\n');
        fprintf(fid,'START_BYTE = %i\n',byte);
        fprintf(fid,'BYTES = 23\n');
        byte=byte+23+2;
        fprintf(fid,'UNIT = SECONDS\n');
        fprintf(fid,'DESCRIPTION = "START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss"\n');
        fprintf(fid,'END_OBJECT  = COLUMN\n');
        
        fprintf(fid,'OBJECT = COLUMN\n');
        fprintf(fid,'NAME = STOP_TIME_UTC\n');
        fprintf(fid,'DATA_TYPE = TIME\n');
        fprintf(fid,'START_BYTE = %i\n',byte);
        fprintf(fid,'BYTES = 23\n');
        byte=byte+23+2;
        
        fprintf(fid,'UNIT = SECONDS\n');
        fprintf(fid,'DESCRIPTION = "LAST START TIME OF MACRO BLOCK FILE YYYY-MM-DD HH:MM:SS.sss"\n');
        fprintf(fid,'END_OBJECT  = COLUMN\n');
        
        fprintf(fid,'OBJECT = COLUMN\n');
        fprintf(fid,'NAME = MACRO_ID\n');
        fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
        fprintf(fid,'START_BYTE = %i\n',byte);
        fprintf(fid,'BYTES = 3\n');
        byte=byte+14+2;
        fprintf(fid,'DESCRIPTION = "MACRO IDENTIFICATION NUMBER"\n');
        fprintf(fid,'END_OBJECT  = COLUMN\n');
        fprintf(fid,'END_OBJECT  = TABLE\n');
        fprintf(fid,'END');
        fclose(fid);
        
    end
    
end

%% Derived results .LBL files


if(~isempty(an_tabindex));
    len=length(an_tabindex(:,3));
    
    for(i=1:len)
        
        %%some need-to-know things
        tname = an_tabindex{i,2};
        lname=strrep(tname,'TAB','LBL');
        
        mode = tname(end-6:end-4);
        Pnum = tname(end-5);
        
        
        %%%%%HEADER
        %steal header(line 1:55) from existing LBL file, edit smaller things and write the rest customised by analysis file type.
        
        %this is stupid, I need new LBLfile for spectra% freq, but haven't
        %stored that name anywhere.
        %      if strcmp(an_tabindex{i,7},'downsample')
        %        [fp,errmess] = fopen(index(an_tabindex{i,3}).lblfile,'r');
        %         else
        %
        %             tempn = strrep(an_tabindex{i,1},'TAB','LBL');
        %             tempn = strrep(tempn,tempn(end-10:end-8),sprintf('%d',index(an_tabindex{i,3}).macro));
        %
        %             [fp,errmess] = fopen(tempn);
        %         end
        %
        
        
        if strcmp(an_tabindex{i,7}, 'best_estimates')
            
            try
                kv = create_EST_LBL_header(i);
            catch exc
                fprintf(1, ['ERROR: ', exc.message])
                fprintf(1, exc.getReport)
                break
            end
            
        else
            [fp,errmess] = fopen(index(an_tabindex{i,3}).lblfile,'r');        
            if fp < 0
                fprintf(1,'Error, cannot open file %s', index(an_tabindex{i,3}).lblfile);
                break
            end % if I/O error

            tempfp = textscan(fp,'%s %s','Delimiter','=');
            fclose(fp);

            fileinfo = dir(an_tabindex{i,1});

            tempfp{1,2}{3,1} = sprintf('%d',fileinfo.bytes);
            tempfp{1,2}{4,1} = sprintf('%d',an_tabindex{i,4});
            tempfp{1,2}{5,1} = lname;
            tempfp{1,2}{6,1} = tname;

            %         ind = find(strcmp(tempfp{1,1}(),'PRODUCT_TYPE'),1,'first');
            %         tempfp{1,2}{ind,1} ='"DDR"';
            tempfp{1,2}{18,1} ='"DDR"';
            tempfp{1,2}{29,1} ='"5"';

            %         ind = find(strcmp(tempfp{1,1}(),'PRODUCT_CREATION_TIME '),1,'first');
            %         tempfp{1,2}{ind,1} = strnow; %product creation time
            tempfp{1,2}{19,1} = strnow; %product creation time

            %%%%%PRINT HEADER
            ind = find(strcmp(tempfp{1,2}(),'TABLE'),1,'first');
            kv.keys   = tempfp{1}(1:ind-1);
            kv.values = tempfp{2}(1:ind-1);
        end
        LBL_file_path = strrep(an_tabindex{i,1},'TAB','LBL');
        fid = fopen(LBL_file_path,'w');
        write_LBL_header(fid, kv)
        
        
        %% Customise the rest!
        %%% TAB FILE TYPE CUSTOMISATION
        byte = 1;
        
        if strcmp(an_tabindex{i,7},'downsample') %%%%%%%%DOWNSAMPLED FILE%%%%%%%%%%%%%%%
            
            
            
            fprintf(fid,'OBJECT = TABLE\n');
            fprintf(fid,'INTERCHANGE_FORMAT = ASCII\n');
            fprintf(fid,'ROWS = %d\n',an_tabindex{i,4});
            fprintf(fid,'COLUMNS = %d\n',an_tabindex{i,5});
            fprintf(fid,'ROW_BYTES = %d\n',an_tabindex{i,9});
            %fprintf(fid,'ROW_BYTES = 110\n');   %%row_bytes here!!!
            fprintf(fid,'DESCRIPTION = %s\n', strcat(tempfp{1,2}{34,1}(1:end-1),sprintf(' %s SECONDS DOWNSAMPLED"',lname(end-10:end-9))));
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = TIME_UTC\n');
            fprintf(fid,'DATA_TYPE = TIME\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            fprintf(fid,'BYTES = 23\n');
            byte=byte+23+2;
            fprintf(fid,'UNIT = SECONDS\n');
            fprintf(fid,'DESCRIPTION = "UTC TIME YYYY-MM-DD HH:MM:SS.FFF"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = OBT_TIME\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+16+2;
            fprintf(fid,'BYTES = 16\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = SECONDS\n');
            fprintf(fid,'DESCRIPTION = "SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = P%s_CURRENT\n',Pnum);
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n');
            fprintf(fid,'UNIT = AMPERE\n');
            fprintf(fid,'FORMAT = E14.7\n');
            fprintf(fid,'DESCRIPTION = "AVERAGED CURRENT"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = P%s_CURRENT_STDDEV\n',Pnum);
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n');
            fprintf(fid,'UNIT = AMPERE\n');
            fprintf(fid,'FORMAT = E14.7\n');
            fprintf(fid,'DESCRIPTION = "CURRENT STANDARD DEVIATION"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = P%s_VOLT\n',Pnum);
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n');
            fprintf(fid,'UNIT = VOLT\n');
            fprintf(fid,'FORMAT = E14.7\n');
            fprintf(fid,'DESCRIPTION = "AVERAGED MEASURED VOLTAGE"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = P%s_VOLT_STDDEV\n',Pnum);
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n');
            fprintf(fid,'UNIT = VOLT\n');
            fprintf(fid,'FORMAT = E14.7\n');
            fprintf(fid,'DESCRIPTION = "VOLTAGE STANDARD DEVIATION"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = QUALITY\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            fprintf(fid,'BYTES = 3\n');
            byte=byte+3+2;
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = N/A\n');
            fprintf(fid,'DESCRIPTION = " QUALITY FACTOR FROM 000(best) to 999"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            fprintf(fid,'END_OBJECT  = TABLE\n');
            fprintf(fid,'END');
            
            
        elseif strcmp(an_tabindex{i,7},'spectra') %%%%%%%%%%%%%%%%SPECTRA FILE%%%%%%%%%%
            
            
            
            
            
            fprintf(fid,'OBJECT = TABLE\n');
            fprintf(fid,'INTERCHANGE_FORMAT = ASCII\n');
            fprintf(fid,'ROWS = %d\n',an_tabindex{i,4});
            fprintf(fid,'COLUMNS = %d\n',an_tabindex{i,5});
            
            
            %
            %             if Pnum=='3'
            %                 row_byte = (an_tabindex{i,5}-6)*17 +169;
            %
            %
            % %               fprintf(fid,'ROW_BYTES = 169\n');   %%row_bytes here!!!
            %
            %             else
            %
            %                 row_byte = (an_tabindex{i,5}-6)*17 +152;
            %
            %             end
            
            
            fprintf(fid,'ROW_BYTES = %i\n',an_tabindex{i,9});   %%row_bytes here!!!
            
            fprintf(fid,'DESCRIPTION = "%s PSD SPECTRA OF HIGH FREQUENCY MEASUREMENT"\n',mode);
            fprintf(fid,'DELIMITER = ", "\n');

            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = SPECTRA_START_TIME_UTC\n');
            fprintf(fid,'DATA_TYPE = TIME\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+26+2;
            fprintf(fid,'BYTES = 26\n');
            fprintf(fid,'UNIT = SECONDS\n');
            fprintf(fid,'DESCRIPTION = "START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = SPECTRA_STOP_TIME_UTC\n');
            fprintf(fid,'DATA_TYPE = TIME\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+26+2;
            fprintf(fid,'BYTES = 26\n');
            fprintf(fid,'UNIT = SECONDS\n');
            fprintf(fid,'DESCRIPTION = "SPECTRA STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = SPECTRA_START_TIME_OBT\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+16+2;
            fprintf(fid,'BYTES = 16\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = SECONDS\n');
            fprintf(fid,'DESCRIPTION = "START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = SPECTRA_STOP_TIME_OBT\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+16+2;
            fprintf(fid,'BYTES = 16\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = SECONDS\n');
            fprintf(fid,'DESCRIPTION = " STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = QUALITY\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+3+2;
            fprintf(fid,'BYTES = 3\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = N/A\n');
            fprintf(fid,'DESCRIPTION = " QUALITY FACTOR FROM 000(best) to 999"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            if strcmp(mode(1),'I')
                
                
                if Pnum=='3'
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'NAME = P1-P2_CURRENT MEAN\n');
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'UNIT = VOLT\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "BIAS VOLTAGE"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'NAME = P1_VOLT\n');
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'UNIT = VOLT\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "BIAS VOLTAGE"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(fid,'NAME = P2_VOLT\n');
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'UNIT = VOLT\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "BIAS VOLTAGE"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'ITEMS = %i\n',an_tabindex{i,5}-7);
                    fprintf(fid,'NAME = PSD_%s\n',mode);
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "PSD CURRENT SPECTRUM"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                else
                    
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'NAME = P%s_CURRENT_MEAN\n',Pnum);
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'UNIT = AMPERE\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "CURRENT MEAN"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'NAME = P%s_VOLT_MEAN\n',Pnum);
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'UNIT = VOLT\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "VOLTAGE MEAN"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'ITEMS = %i\n',an_tabindex{i,5}-6);
                    fprintf(fid,'NAME = PSD_%s\n',mode);
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "PSD CURRENT SPECTRUM"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                end
                
                
            elseif strcmp(mode(1),'V')
                
                if Pnum=='3'
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'NAME = P1_CURRENT_MEAN\n');
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'UNIT = AMPERE\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "CURRENT MEAN"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'NAME = P2_CURRENT_MEAN\n');
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'UNIT = AMPERE\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "CURRENT MEAN"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'NAME = P1-P2 VOLTAGE MEAN\n');
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'UNIT = VOLT\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "MEAN VOLTAGE DIFFERENCE"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'ITEMS = %i\n',an_tabindex{i,5}-7);
                    fprintf(fid,'NAME = PSD_%s\n',mode);
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "PSD VOLTAGE SPECTRUM"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                else
                    
                    
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'NAME = P%s_CURRENT\n',Pnum);
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'UNIT = AMPERE\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "CURRENT MEAN"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'NAME = P%s_VOLT_MEAN\n',Pnum);
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'UNIT = VOLT\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "VOLTAGE MEAN"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(fid,'OBJECT = COLUMN\n');
                    fprintf(fid,'ITEMS = %i\n',an_tabindex{i,5}-6);
                    fprintf(fid,'NAME = PSD_%s\n',mode);
                    fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(fid,'START_BYTE = %i\n',byte);
                    byte=byte+14+2;
                    fprintf(fid,'BYTES = 14\n');
                    fprintf(fid,'FORMAT = E14.7\n');
                    fprintf(fid,'DESCRIPTION = "PSD VOLTAGE SPECTRUM"\n');
                    fprintf(fid,'END_OBJECT  = COLUMN\n');
                end
                
                
                
            else
                fprintf(1,'error, bad mode identifier in an_tabindex{%i,1}',i);
                
            end
            fprintf(fid,'END_OBJECT  = TABLE\n');
            fprintf(fid,'END');
            
            
        elseif  strcmp(an_tabindex{i,7},'frequency') %%%%%%%%%%%%FREQUENCY FILE%%%%%%%%%
            
            % tempfp{1,2}{34,1} = sprintf('"%s FREQUENCY LIST OF PSD SPECTRA FILE"',lname(end-10:end-9));
            
            %             ind = find(strcmp(tempfp{1,2}(),'TABLE'),1,'first');
            %             %%%%%PRINT HEADER
            %             for (j=1:ind-1) %print header of analysis file
            %                 fprintf(fid,'%s=%s\n',tempfp{1,1}{j,1},tempfp{1,2}{j,1});
            %             end
            %             %%%%% Customise the rest!
            %
            
            fprintf(fid,'OBJECT = TABLE\n');
            fprintf(fid,'INTERCHANGE_FORMAT = ASCII\n');
            fprintf(fid,'ROWS = %d\n',an_tabindex{i,4});
            fprintf(fid,'COLUMNS = %d\n',an_tabindex{i,5});
            fprintf(fid,'ROW_BYTES = %i\n',an_tabindex{i,9}); 
          %  fprintf(fid,'ROW_BYTES = 14\n');   %%row_bytes here!!!
            
            fprintf(fid,'DESCRIPTION = "FREQUENCY LIST OF PSD SPECTRA FILE"\n');
            fprintf(fid,'DELIMITER = ", "\n');
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = FREQUENCY LIST\n');
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'START_BYTE = 1\n');
            fprintf(fid,'BYTES = 14\n');
            fprintf(fid,'ITEMS = %i\n',an_tabindex{i,5});
            fprintf(fid,'UNIT = kHz\n');
            fprintf(fid,'FORMAT = E14.7\n');
            psdname = strrep(an_tabindex{i,2},'FRQ','PSD');
            fprintf(fid,'DESCRIPTION = "FREQUENCY LIST OF PSD SPECTRA FILE %s"\n', psdname);
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
%             
%             
%             DELIMITER = ", "
% OBJECT = COLUMN
% NAME = FREQUENCY LIST
% DATA_TYPE = ASCII_REAL
% START_BYTE = 1
% BYTES = 13
% ITEMS = 65
% UNIT = kHz
% FORMAT = E14.7
% DESCRIPTION = "FREQUENCY LIST FOR CORRESPONDING PSD SPECTRA FILE"
% END_OBJECT  = COLUMN
% 
%             
            
            
            fprintf(fid,'END_OBJECT  = TABLE\n');
            fprintf(fid,'END');
            
        elseif  strcmp(an_tabindex{i,7},'sweep') %%%%%%%%%%%% SWEEP ANALYSIS FILE %%%%%%%%%

            data = [];
            data.N_rows      = an_tabindex{i,4};
            data.N_row_bytes = an_tabindex{i,9};
            data.DESCRIPTION = sprintf('MODEL FITTED ANALYSIS OF %s SWEEP FILE',tabindex{an_tabindex{i,6},2});

            cl1 = {};
            cl1{end+1} = struct('NAME', 'START_TIME(UTC)', 'UNIT', 'SECONDS', 'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Start time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            cl1{end+1} = struct('NAME', 'STOP_TIME(UTC)',  'UNIT', 'SECONDS', 'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Stop time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            cl1{end+1} = struct('NAME', 'START_TIME_OBT',  'UNIT', 'SECONDS', 'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Start time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            cl1{end+1} = struct('NAME', 'STOP_TIME_OBT',   'UNIT', 'SECONDS', 'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Stop time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');            
            cl1{end+1} = struct('NAME', 'Qualityfactor',   'UNIT', [],        'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Quality factor from 0-100');
            cl1{end+1} = struct('NAME', 'SAA',             'UNIT', 'degrees', 'BYTES',  7, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Solar aspect angle from x-axis of spacecraft');
            cl1{end+1} = struct('NAME', 'Illumination',    'UNIT', [],        'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise');
            cl1{end+1} = struct('NAME', 'direction',       'UNIT', [],        'BYTES',  1, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sweep bias step direction. 1 for positive  bias step, 0 for negative bias step');
            %cl1{end+1} = struct('NAME', 'sweepcomb',       'UNIT', [],        'BYTES',  2, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', '0 = Single sweep. 1 (-1) = Sweep is one of two subsequent sweeps where the first/second sweep has positive/negative (negative/positive) bias steps.');
            % -- (Changing from cl1 to cl2.) --
            cl2 = {};
            cl2{end+1} = struct('NAME', 'old.Vsi',   'UNIT', 'V', 'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. older analysis method ');
            cl2{end+1} = struct('NAME', 'old.Vx',   'UNIT', 'V', 'DESCRIPTION', 'Spacecraft potential + Te from electron current fit. Older analysis method.');
            cl2{end+1} = struct('NAME', 'Vsg',   'UNIT', 'V',   'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative');
            cl2{end+1} = struct('NAME', 'sigma_Vsg',   'UNIT', 'V', 'DESCRIPTION', 'Standard deviation of spacecraft potential from gaussian fit to second derivative');
            cl2{end+1} = struct('NAME', 'old.Tph',   'UNIT', 'eV', 'DESCRIPTION', 'Photoelectron temperature. Older analysis method.  ');
            cl2{end+1} = struct('NAME', 'old.Iph0',   'UNIT', 'A', 'DESCRIPTION', 'Photosaturation current. Older analysis method.');
            cl2{end+1} = struct('NAME', 'Vb_lastnegcurrent',   'UNIT', 'V', 'DESCRIPTION', 'bias potential below zero current');
            cl2{end+1} = struct('NAME', 'Vb_firstposcurrent',   'UNIT', 'V', 'DESCRIPTION', 'bias potential above zero current');
            cl2{end+1} = struct('NAME', 'Vbinfl',   'UNIT', 'V', 'DESCRIPTION', 'Bias potential of inflection point in current');
            cl2{end+1} = struct('NAME', 'dIinfl',   'UNIT', 'A/V', 'DESCRIPTION', 'Derivative of current in inflection point');
            cl2{end+1} = struct('NAME', 'd2Iinfl',   'UNIT', 'A/V^2', 'DESCRIPTION', 'Second derivative of current in inflection point');
            cl2{end+1} = struct('NAME', 'Iph0',   'UNIT', 'A',   'DESCRIPTION', 'Photosaturation current');
            cl2{end+1} = struct('NAME', 'Tph',   'UNIT', 'eV',   'DESCRIPTION', 'Photoelectron temperature');
            cl2{end+1} = struct('NAME', 'Vsi',   'UNIT', 'V',   'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current');
            cl2{end+1} = struct('NAME', 'Vph_knee',   'UNIT', 'V', 'DESCRIPTION', 'Potential at probe position from photoelectron current knee (gaussian fit to second derivative) ');
            cl2{end+1} = struct('NAME', 'Te_linear',   'UNIT', 'eV', 'DESCRIPTION', 'Electron temperature from linear fit to electron current');
            cl2{end+1} = struct('NAME', 'ne_linear',   'UNIT', 'cm^-3', 'DESCRIPTION', 'Electron (plasma) density from linear fit to electron current ');
            cl2{end+1} = struct('NAME', 'ion_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of ion current fit as a function of absolute potential ');
            cl2{end+1} = struct('NAME', 'sigma_ion_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of ion current fit as a function of absolute potential');
            cl2{end+1} = struct('NAME', 'ion_intersect',   'UNIT', 'A', 'DESCRIPTION', 'Y-intersection of ion current fit as a function of absolute potential');
            cl2{end+1} = struct('NAME', 'sigma_ion_intersect',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of y-intersection of ion current fit as a function of absolute potential');
            cl2{end+1} = struct('NAME', 'e_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of linear electron current fit as a function of absolute potential ');
            cl2{end+1} = struct('NAME', 'sigma_e_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of linear electron current fit as a function of absolute potential ');
            cl2{end+1} = struct('NAME', 'e_intersect',   'UNIT', '', 'DESCRIPTION', 'Y-intersection of linear electron current fit as a function of absolute potential ');
            cl2{end+1} = struct('NAME', 'sigma_e_intersect',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of y-intersection of linear electron current fit as a function of absolute potential ');
            cl2{end+1} = struct('NAME', 'ion_Vb_slope',   'UNIT', '', 'DESCRIPTION', 'Slope of ion current fit as a function of bias potential ');
            cl2{end+1} = struct('NAME', 'sigma_ion_Vb_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of ion current fit as a function of bias potential');
            cl2{end+1} = struct('NAME', 'ion_Vb_intersect',   'UNIT', 'A', 'DESCRIPTION', 'Y-intersection of ion current fit as a function of bias potential ');
            cl2{end+1} = struct('NAME', 'sigma_ion_Vb_intersect',   'UNIT', [],   'DESCRIPTION', 'Fractional error estimate of Y-intersection of ion current fit as a function of bias potential ');
            cl2{end+1} = struct('NAME', 'e_Vb_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of linear electron current fit as a function of bias potential ');
            cl2{end+1} = struct('NAME', 'sigma_e_Vb_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of linear electron current fit as a function of bias potential ');
            cl2{end+1} = struct('NAME', 'e_Vb_intersect',   'UNIT', 'A', 'DESCRIPTION', 'Y-intersection of linear electron current fit as a function of bias potential ');
            cl2{end+1} = struct('NAME', 'sigma_e_Vb_intersect',   'UNIT', '',   'DESCRIPTION', 'Fractional error estimate of y-intersection of linear electron current fit as a function of bias potential ');
            cl2{end+1} = struct('NAME', 'Tphc',   'UNIT', 'eV',   'DESCRIPTION', 'Photoelectron cloud temperature (if applicable)');
            cl2{end+1} = struct('NAME', 'nphc',   'UNIT', 'cm^-3',   'DESCRIPTION', 'Photoelectron cloud density (if applicable)');
            cl2{end+1} = struct('NAME', 'phc_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of linear photoelectron current fit as a function of bias potential');
            cl2{end+1} = struct('NAME', 'sigma_phc_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of linear photoelectron current fit as a function of bias potential');
            cl2{end+1} = struct('NAME', 'phc_intersect',   'UNIT', 'A', 'DESCRIPTION', 'Y-intersection of linear photoelectron current fit as a function of bias potential');
            cl2{end+1} = struct('NAME', 'sigma_phc_intersect',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of y-intersection of linear photoelectron current fit as a function of bias potential');
            cl2{end+1} = struct('NAME', 'ne_5eV',   'UNIT', 'cm^-3', 'DESCRIPTION', 'Electron density from linear electron current fit, assuming Te= 5eV  ');
            cl2{end+1} = struct('NAME', 'ni_v_dep',   'UNIT', 'cm^-3', 'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity');
            cl2{end+1} = struct('NAME', 'ni_v_indep',   'UNIT', 'cm^-3', 'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate');
            cl2{end+1} = struct('NAME', 'v_ion',   'UNIT', 'm/s', 'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate ');
            cl2{end+1} = struct('NAME', 'Te_exp',   'UNIT', 'eV', 'DESCRIPTION', 'Electron temperature from exponential fit to electron current');
            cl2{end+1} = struct('NAME', 'sigma_Te_exp',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of electron temperature from exponential fit to electron current');
            cl2{end+1} = struct('NAME', 'asm_Vsg',   'UNIT', 'V', 'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_Vsg',   'UNIT', 'V', 'DESCRIPTION', 'Standard deviation of spacecraft potential from gaussian fit to second derivative. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_Iph0',   'UNIT', 'A',   'DESCRIPTION', 'Photosaturation current. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_Tph',   'UNIT', 'eV',   'DESCRIPTION', 'Photoelectron temperature. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_Vsi',   'UNIT', 'V',   'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_Vph_knee',   'UNIT', 'V', 'DESCRIPTION', 'Potential at probe position from photoelectron current knee (gaussian fit to second derivative) . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_Te_linear',   'UNIT', 'eV', 'DESCRIPTION', 'Electron temperature from linear fit to electron current. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_ne_linear',   'UNIT', 'cm^-3', 'DESCRIPTION', 'Electron (plasma) density from linear fit to electron current . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_ion_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of ion current fit as a function of absolute potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_ion_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_ion_intersect',   'UNIT', 'A', 'DESCRIPTION', 'Y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_ion_intersect',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_e_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of linear electron current fit as a function of absolute potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_e_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of linear electron current fit as a function of absolute potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_e_intersect',   'UNIT', 'A', 'DESCRIPTION', 'Y-intersection of linear electron current fit as a function of absolute potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_e_intersect',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of y-intersection of linear electron current fit as a function of absolute potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_ion_Vb_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of ion current fit as a function of bias potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of ion current fit as a function of bias potential. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_ion_Vb_intersect',   'UNIT', 'A', 'DESCRIPTION', 'Y-intersection of ion current fit as a function of bias potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_intersect',   'UNIT', '',   'DESCRIPTION', 'Fractional error estimate of Y-intersection of ion current fit as a function of bias potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_e_Vb_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of linear electron current fit as a function of bias potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of linear electron current fit as a function of bias potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_e_Vb_intersect',   'UNIT', 'A', 'DESCRIPTION', 'Y-intersection of linear electron current fit as a function of bias potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_intersect',   'UNIT', [],   'DESCRIPTION', 'Fractional error estimate of y-intersection of linear electron current fit as a function of bias potential . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_Tphc',   'UNIT', 'eV',   'DESCRIPTION', 'Photoelectron cloud temperature (if applicable). Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_nphc',   'UNIT', 'cm^-3',   'DESCRIPTION', 'Photoelectron cloud density (if applicable). Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_phc_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_phc_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_phc_intersect',         'UNIT', 'A', 'DESCRIPTION', 'Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_phc_intersect',   'UNIT', [],  'DESCRIPTION', 'Fractional error estimate of y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_ne_5eV',         'UNIT', 'cm^-3', 'DESCRIPTION', 'Electron density from linear electron current fit, assuming Te= 5eV  . Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_ni_v_dep',       'UNIT', 'cm^-3', 'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity. Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_ni_v_indep',     'UNIT', 'cm^-3', 'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate. Fixed photoelectron current assumption');           
            cl2{end+1} = struct('NAME', 'asm_v_ion',          'UNIT', 'm/s',   'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate.Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_Te_exp',         'UNIT', 'eV',    'DESCRIPTION', 'Electron temperature from exponential fit to electron current.Fixed photoelectron current assumption');
            cl2{end+1} = struct('NAME', 'asm_sigma_Te_exp',   'UNIT', [],      'DESCRIPTION', 'Fractional error estimate of electron temperature from exponential fit to electron current.Fixed photoelectron current assumption');

            for i=1:length(cl2)
                cl2{i}.BYTES     = 14;
                cl2{i}.DATA_TYPE = 'ASCII_REAL';
            end
            data.column_list = [cl1, cl2];
            createLBL_writeObjectTable(fid, data)
            
            fprintf(fid,'END');
        elseif  strcmp(an_tabindex{i,7},'best_estimates') %%%%%%%%%%%% BEST ESTIMATES FILE %%%%%%%%%%%%
            
            data = [];
            data.N_rows      = an_tabindex{i,4};
            data.N_row_bytes = an_tabindex{i,9};
            data.DESCRIPTION = sprintf('BEST ESTIMATES OF PHYSICAL VALUES FROM MODEL FITTED ANALYSIS.');   % Bad description? To specific?
            cl = [];
            cl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            cl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            cl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            cl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            cl{end+1} = struct('NAME', 'QUALITY',            'DATA_TYPE', 'ASCII_REAL', 'BYTES',  3, 'UNIT', [],        'DESCRIPTION', 'QUALITY FACTOR FROM 000(best) to 999');
            cl{end+1} = struct('NAME', 'npl',                'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'CM**-3',  'DESCRIPTION', 'Best estimate of plasma number density.');
            cl{end+1} = struct('NAME', 'Te',                 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'eV',      'DESCRIPTION', 'Best estimate of electron temperature.');
            cl{end+1} = struct('NAME', 'Vsc',                'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'V',       'DESCRIPTION', 'Best estimate if spacecraft potential.');
            cl{end+1} = struct('NAME', 'Probe_number',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  1, 'UNIT', [],        'DESCRIPTION', 'Probe number. 1 or 2');
            cl{end+1} = struct('NAME', 'Sweep_group_number', 'DATA_TYPE', 'ASCII_REAL', 'BYTES',  5, 'UNIT', []',       'DESCRIPTION', ...
                'Number signifying which group of the sweeps the data comes from. Groups of sweeps are formed for the purpose of deriving/selecting best estimates. All sweeps with the same group number are almost simultaneous. Mostly intended for debugging.');
            data.column_list = cl;
            
            createLBL_writeObjectTable(fid, data)
            
            fprintf(fid,'END');
        else
            fprintf(1,'error, bad identifier in an_tabindex{%i,7}',i);
            
        end
        fclose(fid);
               
        
        
    end   % for 
end     % if


    %------------------------------------------------------------------------------------------

    %=========================================================================================
    % Create LBL header for EST.
    % Combines information from one or two LBL file headers
    % to produce information for new combined header (without writing to file).
    % 
    % ASSUMES: The two label files have identical keys on identical positions (line numbers).
    %=========================================================================================
    function kv_new = create_EST_LBL_header(i_ant)
        
        N_src_files = length(an_tabindex{i_ant, 3});
        if ~ismember(N_src_files, [1,2])
            error('Wrong number of TAB file paths.');
        end
        
        kv_list = {};
        START_TIME_list = {};
        STOP_TIME_list = {};
        for i_index = 1:N_src_files
            file_path = index(an_tabindex{i_ant, 3}(i_index)).lblfile;            
            kv = read_LBL_header(file_path);
            
            kv_list{end+1} = kv;            
            START_TIME_list{end+1} = read_kv_value(kv, 'START_TIME');
            STOP_TIME_list{end+1}  = read_kv_value(kv, 'STOP_TIME');
        end
        
        TAB_file_info = dir(an_tabindex{i_ant, 1});
        kv_set.keys   = {};
        kv_set.values = {};
        kv_set = add_new_kv_pair(kv_set, 'FILE_NAME',           strrep(an_tabindex{i_ant, 2}, '.TAB', '.LBL'));
        kv_set = add_new_kv_pair(kv_set, '^TABLE',              an_tabindex{i_ant, 2});
        kv_set = add_new_kv_pair(kv_set, 'FILE_RECORDS',        num2str(an_tabindex{i_ant, 4}));
        kv_set = add_new_kv_pair(kv_set, 'PRODUCT_TYPE',        'DDR');
        kv_set = add_new_kv_pair(kv_set, 'PRODUCT_ID',          sprintf('"%s"', strrep(an_tabindex{i_ant, 2}, '.TAB', '')));
        kv_set = add_new_kv_pair(kv_set, 'PROCESSING_LEVEL_ID', '5');
        kv_set = add_new_kv_pair(kv_set, 'DESCRIPTION',         '"Best estimates of physical quantities based on sweeps."');
        kv_set = add_new_kv_pair(kv_set, 'RECORD_BYTES',        num2str(TAB_file_info.bytes));
        
        % TODO: Find out correct value. Have observed collisions (different values in different CALIB files).
        kv_set = add_new_kv_pair(kv_set, 'ROSETTA:LAP_INITIAL_SWEEP_SMPLS', ...
            '<Does not know how set this value as there are separate values for P1 and P2.>');
        
        % Set start time.
        [junk, i_sort] = sort(START_TIME_list);
        i_start = i_sort(1);
        kv_set = add_copy_of_kv_pair(kv_list{i_start}, kv_set, 'START_TIME');
        kv_set = add_copy_of_kv_pair(kv_list{i_start}, kv_set, 'SPACECRAFT_CLOCK_START_COUNT');
       
        % Set stop time.
        [junk, i_sort] = sort(STOP_TIME_list);
        i_stop = i_sort(end);
        kv_set = add_copy_of_kv_pair(kv_list{i_stop}, kv_set, 'STOP_TIME');
        kv_set = add_copy_of_kv_pair(kv_list{i_stop}, kv_set, 'SPACECRAFT_CLOCK_STOP_COUNT');
        
        %===================
        % Handle collisions
        %===================
        kv1 = kv_list{1};
        if (N_src_files == 1)
            kv_new = kv1;
        else
            kv_new = [];
            kv_new.keys = {};
            kv_new.values = {};
            kv2 = kv_list{2};
            for i1 = 1:length(kv1.keys)             % For every key in kv1...

                if strcmp(kv1.keys{i1}, kv2.keys{i1})     % If key collision...

                    key = kv1.keys{i1};
                    kvset_has_key = ~isempty(find(strcmp(key, kv_set.keys)));
                    if kvset_has_key                                    % If kv_set contains information on how to set value...
                        % IMPLEMENTATION NOTE: Can not set values here since this only covers the case of having two source LBL files.
                        kv_new.keys  {end+1, 1} = key;
                        kv_new.values{end+1, 1} = '<Temporary - This value should be overwritten automatically.>';

                    elseif strcmp(kv1.values{i1}, kv2.values{i1})       % If key AND value collision... (No problem)
                        kv_new.keys  {end+1, 1} = kv1.keys  {i1};
                        kv_new.values{end+1, 1} = kv1.values{i1};
                        
                    else                                      % If has no information on how to resolve collision...
                        error(sprintf('ERROR: Does not know what to do with LBL/ODL key collision for "%s"', key))
                        
                    end            

                else  % If not key collision....
                    kv_new.keys  {end+1,1} = kv1.keys  {i1};
                    kv_new.values{end+1,1} = kv1.values{i1};
                    kv_new.keys  {end+1,1} = kv2.keys  {i1};
                    kv_new.values{end+1,1} = kv2.values{i1};
                end
            end
        end

        kv_new = set_values_for_selected_preexisting_keys(kv_new, kv_set);
    end

    %------------------------------------------------------------------------------------------
    
    function file_contents = read_LBL_header(file_path)
        [fid, errmess] = fopen(file_path, 'r');        
        if fid < 0
            error(sprintf('Error, cannot open file %s', file_path))
        end
        
        fc = textscan(fid,'%s %s','Delimiter','=');
        fclose(fid);
       
        i_TABLE = find(strcmp(fc{1,2}(),'TABLE'), 1, 'first');
        file_contents.keys   = strtrim(fc{1}(1:i_TABLE-1, :));
        file_contents.values = strtrim(fc{2}(1:i_TABLE-1, :));
    end

    %------------------------------------------------------------------------------------------
    
    function write_LBL_header(fid, kv)
        % PROPOSAL: Set RECORD_BYTES (file size)
        % PROPOSAL: Set (overwrite) values for PRODUCT_TYPE, PROCESSING_LEVEL_ID and other values which are the same for all files.
        fprintf(1, 'Write LBL header to file: %s\n', LBL_file_path);   % NOTE: Not ideal place to write log message.
        for j = 1:length(kv.keys) % Print header of analysis file
            fprintf(fid, '%s = %s\n', kv.keys{j}, kv.values{j});
        end
    end

    %------------------------------------------------------------------------------------------
    
    function kv = set_values_for_selected_preexisting_keys(kv, kv_set)
        for i_kvs = 1:length(kv_set.keys)
            key   = kv_set.keys{i_kvs};
            value = kv_set.values{i_kvs};
            i_kv = find(strcmp(key, kv.keys));
            
            if ~isempty(i_kv)
                kv.values{i_kv} = value;
            else
                error(sprintf('ERROR: Tries to set LBL/ODL key that does not yet exist in source: (key, value) = (%s, %s)', key, value));
            end
        end
    end

    %------------------------------------------------------------------------------------------

%     function kv = add_key_value_pairs(kv, kv_new)        
%         for i_kvn = 1:length(kv_new.keys)
%             key   = kv_new.keys{i_kvn};
%             value = kv_new.values{i_kvn};            
%             i_kv = find(strcmp(key, kv.keys));            
%             
%             if ~isempty(i_kv)
%                 error(sprintf('ERROR: Tries to set LBL/ODL key that already exist in source: (key, value) = (%s, %s)', key, value));
%             else
%                 kv.keys{end+1}   = key
%                 kv.values{end+1} = value;
%             end
%         end        
%     end

    %------------------------------------------------------------------------------------------
    
    function value = read_kv_value(kv, key)
        i_kv = strcmp(key, kv.keys);
        value = kv.values{i_kv};
    end

    %------------------------------------------------------------------------------------------
    
    function kv = add_new_kv_pair(kv, key, value)
        kv.keys  {end+1, 1} = key;
        kv.values{end+1, 1} = value;
    end
    
    %------------------------------------------------------------------------------------------
    
    function kv_dest = add_copy_of_kv_pair(kv_src, kv_dest, key)
        value = read_kv_value(kv_src, key);
        kv_dest = add_new_kv_pair(kv_dest, key, value);
    end
    
    
end % function

