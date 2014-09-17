%createLBL.m
%CREATE .LBL FILES, FROM PREVIOUS LBL FILES

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
        %      atmpsct0 = index(tabindex{46,3}).sct0str;
        
        
        
        shitstr = index(tabindex{i,3}).sct0str;
      %  tempfp{1,2}{32,1} = strcat(index(tabindex{i,3}).sct0str(1:end-1),'"');  %% sc start time
        tempfp{1,2}{32,1} = index(tabindex{i,3}).sct0str;
        tempfp{1,2}{33,1} = obt2sct(tabindex{i,5},scResetCount);
        
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
                
                
                
                fprintf(fid,'OBJECT = TABLE\n');
                fprintf(fid,'INTERCHANGE_FORMAT = ASCII\n');
                fprintf(fid,'ROWS = %d\n',tabindex{i,6});
                fprintf(fid,'COLUMNS = %d\n',tabindex{i,7});
                fprintf(fid,'ROW_BYTES = 30\n');   %%row_bytes here!!!
                
                fprintf(fid,'DESCRIPTION = %s"\n', strcat(tempfp{1,2}{34,1}(1:end-1),' Sweep step bias and time between each step'));
                %DELIMITER EVERYWHERE???
                fprintf(fid,'OBJECT = COLUMN\n');
                fprintf(fid,'NAME = SWEEP_TIME\n');
                fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                fprintf(fid,'START_BYTE = %i\n',byte);
                fprintf(fid,'BYTES = 14\n');
                byte=byte+14+2;
                
                fprintf(fid,'UNIT = SECONDS\n');
                fprintf(fid,'FORMAT = E14.7\n');
                fprintf(fid,'DESCRIPTION = "LAPSED TIME (S/C CLOCK TIME) FROM FIRST SWEEP MEASUREMENT"\n');
                fprintf(fid,'END_OBJECT  = COLUMN\n');
                
                fprintf(fid,'OBJECT = COLUMN\n');
                fprintf(fid,'NAME = P%i_VOLTAGE\n',Pnum);
                fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
                fprintf(fid,'START_BYTE = %i\n',byte);
                fprintf(fid,'BYTES = 14\n');
                byte=byte+14+2;
                
                fprintf(fid,'UNIT = VOLT\n');
                fprintf(fid,'FORMAT = E14.7\n');
                fprintf(fid,'DESCRIPTION = "CALIBRATED VOLTAGE BIAS"\n');
                fprintf(fid,'END_OBJECT  = COLUMN\n');
                
                
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
        fprintf(fid,'PRODUCT_TYPE = "DDR"\n');  % No idea what this means...
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
        %
        
        %         ind = find(strcmp(tempfp{1,1}(),'PRODUCT_CREATION_TIME '),1,'first');
        %         tempfp{1,2}{ind,1} = strnow; %product creation time
        %
        
        tempfp{1,2}{19,1} = strnow; %product creation time
        % %
        %         %Time Stamps
        %
        %
        %         tempfp{1,2}{30} = an_tabindex{i,8}{1,1}(1:23); %UTC start
        %         tempfp{1,2}{31} = an_tabindex{i,8}{1,2}(1:23); %UTC stop
        %         tempfp{1,2}{32} = sprintf('"%s/%014.3f"',tempfp{1,2}{32}(2),an_tabindex{i,8}{1,3}); %SC start
        %         tempfp{1,2}{33} = sprintf('"%s/%014.3f"',tempfp{1,2}{32}(2),an_tabindex{i,8}{1,4}); %SC stop
        %
        % %         ind = find(strcmp(tempfp{1,1}(),'START_TIME  '),1,'first');
        % %
        % %
        % %         tempfp{1,2}{ind} = an_tabindex{i,8}{1,1}(1:23); %UTC start
        %         tempfp{1,2}{ind+1} = an_tabindex{i,8}{1,2}(1:23); %UTC stop
        %         tempfp{1,2}{ind+2} = sprintf('"%s/%014.3f"',tempfp{1,2}{32}(2),an_tabindex{i,8}{1,3}); %SC start
        %         tempfp{1,2}{ind+3} = sprintf('"%s/%014.3f"',tempfp{1,2}{32}(2),an_tabindex{i,8}{1,4}); %SC stop
        %
        %since this is 1:1 mapping for downsampling, this can stay "as is"
        %28START_TIME =2007-11-07T02:32:42.861
        %29STOP_TIME =2007-11-07T23:59:59.141888
        %30SPACECRAFT_CLOCK_START_COUNT =153023530.1600
        %31SPACECRAFT_CLOCK_STOP_COUNT =153100766.291081
        
        
        fid = fopen(strrep(an_tabindex{i,1},'TAB','LBL'),'w');
        
        %%%%%PRINT HEADER
        ind = find(strcmp(tempfp{1,2}(),'TABLE'),1,'first');
        
        for (j=1:ind-1) %print header of analysis file
            fprintf(fid,'%s = %s\n',tempfp{1,1}{j,1},tempfp{1,2}{j,1});
        end
        
        
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
            
        elseif  strcmp(an_tabindex{i,7},'sweep') %%%%%%%%%%%%SWEEP FILE%%%%%%%%%
            
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
            fprintf(fid,'ROW_BYTES = %d\n',an_tabindex{i,9});   %%row_bytes here!!!
            
            fprintf(fid,'DESCRIPTION = "MODEL FITTED ANALYSIS OF %s SWEEP FILE"\n',tabindex{an_tabindex{i,6},2});
            
            
            
            %
            %              %1:5
            %
            %         %time0,time0,QUALITY FACTOR,mean(SAA),mean(Illuminati)
            %         b1=fprintf(awID,'%s, %s, %03i, %07.4f, %03.2f,',fout{k,5}{1,1},fout{k,5}{1,2},Qfarr(k),fout{k,2},fout{k,3});
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = START_TIME_UTC\n');
            fprintf(fid,'DATA_TYPE = TIME\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+26+2;
            fprintf(fid,'BYTES = 26\n');
            fprintf(fid,'UNIT = SECONDS\n');
            fprintf(fid,'DESCRIPTION = "START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = STOP_TIME_UTC\n');
            fprintf(fid,'DATA_TYPE = TIME\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+26+2;
            fprintf(fid,'BYTES = 26\n');
            fprintf(fid,'UNIT = SECONDS\n');
            fprintf(fid,'DESCRIPTION = "STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF"\n');
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
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = SAA\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+7+2;
            fprintf(fid,'BYTES = 7\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = DEGREES\n');
            fprintf(fid,'DESCRIPTION = " SOLAR ASPECT ANGLE FROM SPICE (DEGREES)"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = SUNLIT\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+4+2;
            fprintf(fid,'BYTES = 4\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = N/A\n');
            fprintf(fid,'DESCRIPTION = "SUNLIT PROBE: 1=YES,0=NO,ELSE: SUNLIT DURING PART OF SWEEP"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            
            
            %         %6:9
            
            %         %,vs,vx,Vsc,VscSigma
            %         b2=fprintf(awID,' %14.7e, %14.7e, %14.7e, %14.7e,',fout{k,1}(15),fout{k,1}(4),fout{k,4}{1},fout{k,4}{2});
            %
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = Vs\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = VOLT\n');
            fprintf(fid,'DESCRIPTION = "Spacecraft potential from ion & photoemission current intersection, iterative solution"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = Vx\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = VOLT\n');
            fprintf(fid,'DESCRIPTION = " Vsat + Te from electron current fit"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = Vsc\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = VOLT\n');
            fprintf(fid,'DESCRIPTION = "Spacecraft potential from 2nd derivative gaussian fit"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = Vsc_sigma\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = VOLT\n');
            fprintf(fid,'DESCRIPTION = "Spacecraft potential sigma from 2nd derivative gaussian fit"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            %10:13
            %         %,Tph,If0,vb(lastneg), vb(firstpos),
            %         b3= fprintf(awID,' %14.7e, %14.7e  %14.7e, %14.7e,', fout{k,1}(13),fout{k,1}(14),fout{k,1}(2),fout{k,1}(3));
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = Tph\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = eV\n');
            fprintf(fid,'DESCRIPTION = "Photoelectron temperature from model fit"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = If0\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = AMPERE\n');
            fprintf(fid,'DESCRIPTION = "If0"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = Vb(lastneg)\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = VOLT\n');
            fprintf(fid,'DESCRIPTION = "Last negative current potential"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = Vb(firstpos)\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = VOLT\n');
            fprintf(fid,'DESCRIPTION = "First positive current potential"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            %         %poli,poli,pole,pole,
            %         b4 =fprintf(awID,' %14.7e, %14.7e, %14.7e, %14.7e,',fout{k,1}(5),fout{k,1}(6),fout{k,1}(7),fout{k,1}(8));
            %         %14:17
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = poli(1)\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = N/A\n');
            fprintf(fid,'DESCRIPTION = "N/A"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = poli(2)\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = N/A\n');
            fprintf(fid,'DESCRIPTION = "N/A"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = pole(1)\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = N/A\n');
            fprintf(fid,'DESCRIPTION = "N/A"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            fprintf(fid,'OBJECT = COLUMN\n');
            
            fprintf(fid,'NAME = pole(2)\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = N/A\n');
            fprintf(fid,'DESCRIPTION = "N/A"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            %         %17:19
            
            %         %  vbinf,diinf,d2iinf
            %         b5 = fprintf(awID,' %14.7e, %14.7e, %14.7e\n',fout{k,1}(10),fout{k,1}(11),fout{k,1}(12));
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = vbinf\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = VOLT\n');
            fprintf(fid,'DESCRIPTION = "inflection point bias potential"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = diinf\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = A/s \n');
            fprintf(fid,'DESCRIPTION = "current derivative at inflection point"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            fprintf(fid,'OBJECT = COLUMN\n');
            fprintf(fid,'NAME = d2iinf\n');
            fprintf(fid,'START_BYTE = %i\n',byte);
            byte=byte+14+2;
            fprintf(fid,'BYTES = 14\n'); %
            fprintf(fid,'DATA_TYPE = ASCII_REAL\n');
            fprintf(fid,'UNIT = A s^-2\n');
            fprintf(fid,'DESCRIPTION = "current 2nd derivative at inflection point"\n');
            fprintf(fid,'END_OBJECT  = COLUMN\n');
            
            
            fprintf(fid,'END_OBJECT  = TABLE\n');
            fprintf(fid,'END');
        else
            fprintf(1,'error, bad identifier in an_tabindex{%i,7}',i);
            
        end
        fclose(fid);
        
        
        
        
    end
end


