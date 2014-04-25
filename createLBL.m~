%createLBL.m

%%DATAFILE .LBL FILES

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
        tempfp = textscan(fp,'%s %s','Delimiter','=');
        fclose(fp);
        
        dl = fopen(strrep(tabindex{i,1},'TAB','LBL'),'w');
        
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
        
        tempfp{1,2}{7,1}= strrep(tempfp{1,2}{7,1},sprintf('-3-%s-CALIB',shortphase),sprintf('-4-%s-DERIV',shortphase));
        tempfp{1,2}{8,1}= strrep(tempfp{1,2}{8,1},sprintf('3 %s CALIB',shortphase),sprintf('4 %s DERIV',shortphase));
        
        tempfp{1,2}{14,1}=producershortname;
        tempfp{1,2}{15,1}=sprintf('"%s"',producerfullname);
        
        
        
        %        tempfp{1,2}{16,1} = sprintf('"%s, %s, %s"',lbltime,lbleditor,lblrev);
        %     tempfp{1,2}(17:18) = [];
        %    tempfp{1,1}(17:18) =[]; % should be deleted?
        
        tempfp{1,2}{17} = tname(1:end-4);
        tempfp{1,2}{18} = '"DDR"';
        
        tempfp{1,2}{19,1} = datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'); %product creation time
        tempfp{1,2}{29,1} = '"4"'; %% processing level ID
        tempfp{1,2}{30,1} = index(tabindex{i,3}).t0str(1:23); %UTC start time
        tempfp{1,2}{31,1} = tabindex{i,4}(1:23);             % UTC stop time
        %         tmpsct0 = index(tabindex{i,3}).sct0str(5:end-1);
        %      atmpsct0 = index(tabindex{46,3}).sct0str;
        
        
        tempfp{1,2}{32,1} = strcat(index(tabindex{i,3}).sct0str(1:17),'"');  %% sc start time
        tempfp{1,2}{33,1} = sprintf('"%s/%014.3f"',index(tabindex{i,3}).sct0str(2),tabindex{i,5}); %% sc stop time
        %   tempfp{1,2}{56,1} = sprintf('%i',tabindex{i,6}); %% rows
        
        
        
        ind= find(ismember(strrep(tempfp{1,1},' ', ''),'ROWS'));% lots of whitespace often
        tempfp{1,2}{ind,1}= sprintf('%i',tabindex{i,6}); %% rows
        
        colind= find(ismember(strrep(tempfp{1,2},' ', ''),'TABLE'));% find table start and end
        
%         for (j=1:colind(end)-1) %skip last row
%             fprintf(dl,'%s = %s\n',tempfp{1,1}{j,1},tempfp{1,2}{j,1});
%         end
        
        
        if (tname(30)=='S') % special format for sweep files...
            
            for (j=1:colind(1)-1) %skip last row
                fprintf(dl,'%s = %s\n',tempfp{1,1}{j,1},tempfp{1,2}{j,1});
            end
            if (tname(28)=='B')
                
                
                
                fprintf(dl,'OBJECT = TABLE\n');
                fprintf(dl,'INTERCHANGE_FORMAT = ASCII\n');
                fprintf(dl,'ROWS = %d\n',tabindex{i,6});
                fprintf(dl,'COLUMNS = %d\n',tabindex{i,7});
                fprintf(dl,'ROW_BYTES = 30\n');   %%row_bytes here!!!
                
                fprintf(dl,'DESCRIPTION = %s\n', strcat(tempfp{1,2}{34,1}(1:end-1),'Sweep step bias and time between each step'));
                
                
                fprintf(dl,'OBJECT = COLUMN\n');
                fprintf(dl,'NAME = SWEEP_TIME\n');
                fprintf(dl,'DATA_TYPE = TIME\n');
                fprintf(dl,'START_BYTE = 1\n');
                fprintf(dl,'BYTES = 14\n');
                fprintf(dl,'UNIT = SECONDS\n');
                fprintf(dl,'FORMAT = E14.7\n');
                fprintf(dl,'DESCRIPTION = "LAPSED TIME (S/C CLOCK TIME) FROM FIRST SWEEP MEASUREMENT"\n');
                fprintf(dl,'END_OBJECT  = COLUMN\n');
                               
                fprintf(dl,'OBJECT = COLUMN\n');
                fprintf(dl,'NAME = P%i_VOLTAGE\n',Pnum);
                fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
                fprintf(dl,'START_BYTE = 16\n');
                fprintf(dl,'BYTES = 14\n');
                fprintf(dl,'UNIT = VOLT\n');
                fprintf(dl,'FORMAT = E14.7\n');
                fprintf(dl,'DESCRIPTION = "CALIBRATED VOLTAGE BIAS"\n');
                fprintf(dl,'END_OBJECT  = COLUMN\n');
              
                
            else %% if tname(28) =='I'
                
                
                fprintf(dl,'OBJECT = TABLE\n');
                fprintf(dl,'INTERCHANGE_FORMAT = ASCII\n');
                fprintf(dl,'ROWS = %d\n',tabindex{i,6});
                fprintf(dl,'COLUMNS = %d\n',tabindex{i,7});
                fprintf(dl,'ROW_BYTES = 115\n');   %%row_bytes here!!!                
                fprintf(dl,'DESCRIPTION = %s\n',tempfp{1,2}{34,1}(1:end-1));
                
                
                
                
                
                Bfile = tname;
                Bfile(28)='B';
                
                fprintf(dl,'OBJECT = COLUMN\n');
                fprintf(dl,'NAME = START_TIME_UTC\n');
                fprintf(dl,'DATA_TYPE = TIME\n');
                fprintf(dl,'START_BYTE = 1\n');
                fprintf(dl,'BYTES = 26\n');
                fprintf(dl,'UNIT = SECONDS\n');
                fprintf(dl,'DESCRIPTION = "START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF"\n');
                fprintf(dl,'END_OBJECT  = COLUMN\n');
                
                fprintf(dl,'OBJECT = COLUMN\n');
                fprintf(dl,'NAME = STOP_TIME_UTC\n');
                fprintf(dl,'DATA_TYPE = TIME\n');
                fprintf(dl,'START_BYTE = 29\n');
                fprintf(dl,'BYTES = 26\n');
                fprintf(dl,'UNIT = SECONDS\n');
                fprintf(dl,'DESCRIPTION = "STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF"\n');
                fprintf(dl,'END_OBJECT  = COLUMN\n');
                
                fprintf(dl,'OBJECT = COLUMN\n');
                fprintf(dl,'NAME = START_TIME_OBT\n');
                fprintf(dl,'START_BYTE = 57\n');
                fprintf(dl,'BYTES = 16\n'); %
                fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
                fprintf(dl,'UNIT = SECONDS\n');
                fprintf(dl,'DESCRIPTION = "START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
                fprintf(dl,'END_OBJECT  = COLUMN\n');
                                
                fprintf(dl,'OBJECT = COLUMN\n');
                fprintf(dl,'NAME = STOP_TIME_OBT\n');
                fprintf(dl,'START_BYTE = 76\n');
                fprintf(dl,'BYTES = 16\n'); %
                fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
                fprintf(dl,'UNIT = SECONDS\n');
                fprintf(dl,'FORMAT = F16.6\n');
                fprintf(dl,'DESCRIPTION = " STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
                fprintf(dl,'END_OBJECT  = COLUMN\n');
                                
                fprintf(dl,'OBJECT = COLUMN\n');
                fprintf(dl,'NAME = QUALITY\n');
                fprintf(dl,'START_BYTE = 95\n');
                fprintf(dl,'BYTES = 3\n'); %
                fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
                fprintf(dl,'UNIT = N/A\n');
                fprintf(dl,'DESCRIPTION = " QUALITYFACTOR FROM 000(best) to 999"\n');
                fprintf(dl,'END_OBJECT  = COLUMN\n');
                                
                fprintf(dl,'OBJECT = COLUMN\n');
                fprintf(dl,'ITEMS = %i\n',tabindex{i,6}-5);
                fprintf(dl,'NAME = P%s_SWEEP_CURRENT\n',Pnum);
                fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
                fprintf(dl,'START_BYTE = 101\n');
                fprintf(dl,'BYTES = 14\n');
                fprintf(dl,'UNIT = AMPERE\n');
                fprintf(dl,'FORMAT = E14.7\n');
                fprintf(dl,'DESCRIPTION = "Averaged current measured of potential sweep, at different potential steps as described by %s\n"',Bfile);
                fprintf(dl,'END_OBJECT  = COLUMN\n');
                                              
            end
            
            
        else %if anything but a sweep file
            
            
            ind= find(ismember(strrep(tempfp{1,1},' ', ''),'START_BYTE'));% lots of whitespace often
            
            tempfp{1,2}(ind)=
                    tempfp{1,2}{ind,1}= sprintf('%i',tabindex{i,6}); %% rows
             
            for (j=1:colind(end)-1) %s
                fprintf(dl,'%s = %s\n',tempfp{1,1}{j,1},tempfp{1,2}{j,1});
            end
            
            
            
            
            %ind= find(ismember(strrep(tempfp{1,1},' ', ''),'START_BYTE'));% lots of whitespace often
            start_byte= str2double(tempfp{1,2}(ind(end),1)) + str2double(tempfp{1,2}(ind(end)+1,1)) + 3;

            fprintf(dl,'OBJECT = COLUMN\n');
            fprintf(dl,'NAME = QUALITY\n');
            fprintf(dl,'START_BYTE = %i\n',start_byte);
            fprintf(dl,'BYTES = 3\n'); %
            fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
            fprintf(dl,'UNIT = N/A\n');
            fprintf(dl,'DESCRIPTION = " QUALITYFACTOR FROM 000(best) to 999"\n');
            fprintf(dl,'END_OBJECT  = COLUMN\n');
                                   
        end
        
        fprintf(dl,'END_OBJECT  = TABLE\n');
        fprintf(dl,'END');
        fclose(dl);
        
        
        
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
        %             fprintf(dl,'%s = %s\n',tempfp{1,1}{i,1},tempfp{1,2}{i,1});
        %         end
        %
        %         fprintf(dl,'END');% Ends file
        %         fclose(dl);
        
    end
    
end

%% BLOCK LIST .LBL FILES

if(~isempty(blockTAB));
    len=length(blockTAB(:,3));
    for(i=1:len)
        
        tname = blockTAB{i,2};
        lname=strrep(tname,'TAB','LBL');
        bl = fopen(strrep(blockTAB{i,1},'TAB','LBL'),'w');
        
        fprintf(bl,'PDS_VERSION_ID = PDS3\n');
        fprintf(bl,'RECORD_TYPE = FIXED_LENGTH\n');
        fileinfo = dir(blockTAB{i,1});
        fprintf(bl,'RECORD_BYTES = %d\n',fileinfo.bytes);
        fprintf(bl,'FILE_RECORDS = %d\n',blockTAB{i,3});
        fprintf(bl,'FILE_NAME = "%s"\n',lname);
        fprintf(bl,'^TABLE = "%s"\n',tname);
        
        fprintf(bl,'DATA_SET_ID = "%s"\n', strrep(datasetid,sprintf('-3-%s-CALIB',shortphase),sprintf('-4-%s-DERIV',shortphase)));
        fprintf(bl,'DATA_SET_NAME = "%s"\n',strrep(datasetname,sprintf('3 %s CALIB',shortphase),sprintf('4 %s DERIV',shortphase)));
        fprintf(bl,'DATA_QUALITY_ID = 1\n');
        fprintf(bl,'MISSION_ID = ROSETTA\n');
        fprintf(bl,'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\n');
        fprintf(bl,'MISSION_PHASE_NAME = "%s"\n',missionphase);
        fprintf(bl,'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\n');
        fprintf(bl,'PRODUCER_ID = %s\n',producershortname);
        fprintf(bl,'PRODUCER_FULL_NAME = "%s"\n',producerfullname);
        fprintf(bl,'LABEL_REVISION_NOTE = "%s, %s, %s"\n',lbltime,lbleditor,lblrev);
        % mm = length(tname);
        fprintf(bl,'PRODUCT_ID = "%s"\n',tname(1:(end-4)));
        fprintf(bl,'PRODUCT_TYPE = "DDR"\n');  % No idea what this means...
        fprintf(bl,'PRODUCT_CREATION_TIME = %s\n',datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'));
        fprintf(bl,'INSTRUMENT_HOST_ID = RO\n');
        fprintf(bl,'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\n');
        fprintf(bl,'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\n');
        fprintf(bl,'INSTRUMENT_ID = RPCLAP\n');
        fprintf(bl,'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\n');
        fprintf(bl,'TARGET_NAME = "%s"\n',targetfullname);
        fprintf(bl,'TARGET_TYPE = "%s"\n',targettype);
        fprintf(bl,'PROCESSING_LEVEL_ID = %d\n',4);
        
        
        fprintf(bl,'OBJECT = TABLE\n');
        fprintf(bl,'INTERCHANGE_FORMAT = ASCII\n');
        fprintf(bl,'ROWS = %d\n',blockTAB{i,3});
        fprintf(bl,'COLUMNS = 3\n');
        fprintf(bl,'ROW_BYTES = 59\n');
        fprintf(bl,'DESCRIPTION = "BLOCKLIST DATA. START & STOP TIME OF MACROBLOCK AND MACROID."\n');                
        
        fprintf(bl,'OBJECT = COLUMN\n');
        fprintf(bl,'NAME = TIME_UTC\n');
        fprintf(bl,'DATA_TYPE = TIME\n');
        fprintf(bl,'START_BYTE = 1\n');
        fprintf(bl,'BYTES = 23\n');
        fprintf(bl,'UNIT = SECONDS\n');
        fprintf(bl,'DESCRIPTION = "START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss"\n');
        fprintf(bl,'END_OBJECT  = COLUMN\n');
        
        fprintf(bl,'OBJECT = COLUMN\n');
        fprintf(bl,'NAME = TIME_UTC\n');
        fprintf(bl,'DATA_TYPE = TIME\n');
        fprintf(bl,'START_BYTE = 25\n');
        fprintf(bl,'BYTES = 23\n');
        fprintf(bl,'UNIT = SECONDS\n');
        fprintf(bl,'DESCRIPTION = "END TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss"\n');
        fprintf(bl,'END_OBJECT  = COLUMN\n');
        
        fprintf(bl,'OBJECT = COLUMN\n');
        fprintf(bl,'NAME = MACRO_ID\n');
        fprintf(bl,'DATA_TYPE = ASCII_REAL\n');
        fprintf(bl,'START_BYTE = 49\n');
        fprintf(bl,'BYTES = 3\n');
        fprintf(bl,'DESCRIPTION = "MACRO IDENTIFICATION NUMBER"\n');
        fprintf(bl,'END_OBJECT  = COLUMN\n');
        fprintf(bl,'END_OBJECT  = TABLE\n');
        fprintf(bl,'END');
        fclose(bl);
        
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
        tempfp{1,2}{29,1} ='"4"';
        %
        
        %         ind = find(strcmp(tempfp{1,1}(),'PRODUCT_CREATION_TIME '),1,'first');
        %         tempfp{1,2}{ind,1} = datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'); %product creation time
        %
        
        tempfp{1,2}{19,1} = datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'); %product creation time
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
        
        
        al = fopen(strrep(an_tabindex{i,1},'TAB','LBL'),'w');
        
         %%%%%PRINT HEADER                  
         ind = find(strcmp(tempfp{1,2}(),'TABLE'),1,'first');
         
         for (j=1:ind-1) %print header of analysis file
             fprintf(al,'%s = %s\n',tempfp{1,1}{j,1},tempfp{1,2}{j,1});
         end
         
         
         
              
            %% Customise the rest!
        %%% TAB FILE TYPE CUSTOMISATION
        
        if strcmp(an_tabindex{i,7},'downsample') %%%%%%%%DOWNSAMPLED FILE%%%%%%%%%%%%%%%
            

            
            fprintf(al,'OBJECT = TABLE\n');
            fprintf(al,'INTERCHANGE_FORMAT = ASCII\n');
            fprintf(al,'ROWS = %d\n',an_tabindex{i,4});
            fprintf(al,'COLUMNS = %d\n',an_tabindex{i,5});
            
            fprintf(al,'ROW_BYTES = 110\n');   %%row_bytes here!!!
            fprintf(al,'DESCRIPTION = %s\n', strcat(tempfp{1,2}{34,1}(1:end-1),sprintf(' %s SECONDS DOWNSAMPLED"',lname(end-10:end-9))));
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = TIME_UTC\n');
            fprintf(al,'DATA_TYPE = TIME\n');
            fprintf(al,'START_BYTE = 1\n');
            fprintf(al,'BYTES = 23\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "UTC TIME YYYY-MM-DD HH:MM:SS.FFF"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = OBT_TIME\n');
            fprintf(al,'START_BYTE = 26\n');
            fprintf(al,'BYTES = 16\n'); %
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_CURRENT\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 44\n');
            fprintf(al,'BYTES = 14\n');
            fprintf(al,'UNIT = AMPERE\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "AVERAGED CURRENT"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_CURRENT_STDDEV\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 60\n');
            fprintf(al,'BYTES = 14\n');
            fprintf(al,'UNIT = AMPERE\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "CURRENT STANDARD DEVIATION"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_VOLT\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 76\n');
            fprintf(al,'BYTES = 14\n');
            fprintf(al,'UNIT = VOLT\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "AVERAGED MEASURED VOLTAGE"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_VOLT_STDDEV\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 92\n');
            fprintf(al,'BYTES = 14\n');
            fprintf(al,'UNIT = VOLT\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "VOLTAGE STANDARD DEVIATION"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'END_OBJECT  = TABLE\n');
            fprintf(al,'END');
            
            
        elseif strcmp(an_tabindex{i,7},'spectra') %%%%%%%%%%%%%%%%SPECTRA FILE%%%%%%%%%%
       
            
                 
            
            
            fprintf(al,'OBJECT = TABLE\n');
            fprintf(al,'INTERCHANGE_FORMAT = ASCII\n');
            fprintf(al,'ROWS = %d\n',an_tabindex{i,4});
            fprintf(al,'COLUMNS = %d\n',an_tabindex{i,5});
            
            
            
            if Pnum=='3'
                row_byte = (an_tabindex{i,5}-6)*17 +169;
                
                
%               fprintf(al,'ROW_BYTES = 169\n');   %%row_bytes here!!!
                
            else
                
                row_byte = (an_tabindex{i,5}-6)*17 +152;
                
            end
            
            fprintf(al,'ROW_BYTES = %f',row_byte);   %%row_bytes here!!!
            
            fprintf(al,'DESCRIPTION = "%s PSD SPECTRA OF HIGH FREQUENCY MEASUREMENT\n"',mode);
             
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = SPECTRA_START_TIME_UTC\n');
            fprintf(al,'DATA_TYPE = TIME\n');
            fprintf(al,'START_BYTE = 1\n');
            fprintf(al,'BYTES = 26\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
                      
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = SPECTRA_STOP_TIME_UTC\n');
            fprintf(al,'DATA_TYPE = TIME\n');
            fprintf(al,'START_BYTE = 29\n');
            fprintf(al,'BYTES = 26\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "SPECTRA STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = SPECTRA_START_TIME_OBT\n');
            fprintf(al,'START_BYTE = 57\n');
            fprintf(al,'BYTES = 16\n'); %
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = SPECTRA_STOP_TIME_OBT\n');
            fprintf(al,'START_BYTE = 76\n');
            fprintf(al,'BYTES = 16\n'); %
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = " STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = QUALITY\n');
            fprintf(al,'START_BYTE = 95\n');
            fprintf(al,'BYTES = 3\n'); %
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'UNIT = N/A\n');
            fprintf(al,'DESCRIPTION = " QUALITYFACTOR FROM 000(best) to 999"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            
            if strcmp(mode(1),'I')
                
                
                if Pnum=='3'
                    
                    fprintf(al,'OBJECT = COLUMN\n');                    
                    fprintf(al,'NAME = P1-P2_CURRENT MEAN\n');
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 101\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'UNIT = VOLT\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "BIAS VOLTAGE"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                    
                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'NAME = P1_VOLT\n');
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 118\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'UNIT = VOLT\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "BIAS VOLTAGE"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(al,'NAME = P2_VOLT\n');
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 135\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'UNIT = VOLT\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "BIAS VOLTAGE"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'ITEMS = %i\n',an_tabindex{i,5}-7);
                    fprintf(al,'NAME = PSD\n');
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 152\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "PSD CURRENT SPECTRUM"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                    
                else


                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'NAME = P%s_CURRENT_MEAN\n',Pnum);
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 101\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'UNIT = AMPERE\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "CURRENT MEAN"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');

                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'NAME = P%s_VOLT_MEAN\n',Pnum);
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 118\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'UNIT = VOLT\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "VOLTAGE MEAN"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'ITEMS = %i\n',an_tabindex{i,5}-6);
                    fprintf(al,'NAME = PSD\n');
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 135\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "PSD CURRENT SPECTRUM"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                end
                
                
            elseif strcmp(mode(1),'V')
                
                if Pnum=='3'
                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'NAME = P1_CURRENT_MEAN\n');
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 101\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'UNIT = AMPERE\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "CURRENT MEAN"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'NAME = P2_CURRENT_MEAN\n');
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 118\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'UNIT = AMPERE\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "CURRENT MEAN"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                    
                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'NAME = P1-P2 VOLTAGE MEAN\n');
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 135\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'UNIT = VOLT\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "MEAN VOLTAGE DIFFERENCE"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                    
                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'ITEMS = %i\n',an_tabindex{i,5}-7);
                    fprintf(al,'NAME = PSD\n');
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 152\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "PSD VOLTAGE SPECTRUM"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                    
                else
                    
                    
                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'NAME = P%s_CURRENT\n',Pnum);
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 101\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'UNIT = AMPERE\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "CURRENT MEAN"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'NAME = P%s_VOLT_MEAN\n',Pnum);
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 118\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'UNIT = VOLT\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "VOLTAGE MEAN"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');                                        
                    
                    fprintf(al,'OBJECT = COLUMN\n');
                    fprintf(al,'ITEMS = %i\n',an_tabindex{i,5}-6);
                    fprintf(al,'NAME = PSD\n');
                    fprintf(al,'DATA_TYPE = ASCII_REAL\n');
                    fprintf(al,'START_BYTE = 135\n');
                    fprintf(al,'BYTES = 14\n');
                    fprintf(al,'FORMAT = E14.7\n');
                    fprintf(al,'DESCRIPTION = "PSD VOLTAGE SPECTRUM"\n');
                    fprintf(al,'END_OBJECT  = COLUMN\n');
                end
                
                
                
                
            else
                fprintf(1,'error, bad mode identifier in an_tabindex{%i,1}',i);
                
            end
            
   
        elseif  strcmp(an_tabindex{i,7},'frequency') %%%%%%%%%%%%FREQUENCY FILE%%%%%%%%%
            
           % tempfp{1,2}{34,1} = sprintf('"%s FREQUENCY LIST OF PSD SPECTRA FILE"',lname(end-10:end-9));
            
            %             ind = find(strcmp(tempfp{1,2}(),'TABLE'),1,'first');
            %             %%%%%PRINT HEADER
            %             for (j=1:ind-1) %print header of analysis file
            %                 fprintf(al,'%s=%s\n',tempfp{1,1}{j,1},tempfp{1,2}{j,1});
            %             end
            %             %%%%% Customise the rest!
            %
            
            fprintf(al,'OBJECT = TABLE\n');
            fprintf(al,'INTERCHANGE_FORMAT = ASCII\n');
            fprintf(al,'ROWS = %d\n',an_tabindex{i,4});
            fprintf(al,'COLUMNS = %d\n',an_tabindex{i,5});
            fprintf(al,'ROW_BYTES = 14\n');   %%row_bytes here!!!
            
            fprintf(al,'DESCRIPTION = "%s FREQUENCY LIST OF PSD SPECTRA FILE\n"',lname(end-10:end-9));
            
            
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = FREQUENCY LIST\n');
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 0\n');
            fprintf(al,'BYTES = 14\n');
            fprintf(al,'UNIT = kHz\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "FREQUENCY LIST FOR CORRESPONDING PSD SPECTRA FILE"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'END_OBJECT  = TABLE\n');
            fprintf(al,'END');
            
        else
            fprintf(1,'error, bad identifier in an_tabindex{%i,7}',i);
            
        end
        fclose(al);
        
        
        
        
    end
end




%if(~isempty(an_tabindex));

if(0)
    len=length(an_tabindex(:,1));
    
    for(i=1:len)
        
        %tabindex cell array = {tab file name, first index number of batch,
        % UTC time of last row, S/C time of last row, row counter}
        %    units: [cell array] =  {[string],[double],[string],[float],[integer]
        
        % Write label file:
        
        
        %[fp,errmess] = fopen(index(an_tabindex{i,3}).lblfile,'r'); %Problematic for indices created in indexcorr (Files split at midnight)
        %tempfp = textscan(fp,'%s %s','Delimiter','=');
        %fclose(fp);
        
        tname = an_tabindex{i,2};
        %  tabi0 = str2double(an_tabindex{i,6}(1:2)); %%tabindex index of first tabfilein
        %  tabi1 = str2double(an_tabindex{i,6}(end-1:end)); %%tabindex of last tabfile
        lname=strrep(tname,'TAB','LBL');
        
        al = fopen(strrep(an_tabindex{i,1},'TAB','LBL'),'w');
        
        
        fprintf(al,'PDS_VERSION_ID = PDS3\n');
        fprintf(al,'RECORD_TYPE = FIXED_LENGTH\n');
        fileinfo = dir(an_tabindex{i,1});
        fprintf(al,'RECORD_BYTES = %d\n',fileinfo.bytes);
        fprintf(al,'FILE_RECORDS = %d\n',an_tabindex{i,4});
        fprintf(al,'FILE_NAME = "%s"\n',lname);
        fprintf(al,'^TABLE = "%s"\n',tname);
        fprintf(al,'DATA_SET_ID = "%s"\n',datasetid);
        fprintf(al,'DATA_SET_NAME = "%s"\n',datasetname);
        fprintf(al,'DATA_QUALITY_ID = 1\n');
        fprintf(al,'MISSION_ID = ROSETTA\n');
        fprintf(al,'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\n');
        fprintf(al,'MISSION_PHASE_NAME = "%s"\n',missionphase);
        fprintf(al,'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\n');
        fprintf(al,'PRODUCER_ID = %s\n',producershortname);
        fprintf(al,'PRODUCER_FULL_NAME = "%s"\n',producerfullname);
        fprintf(al,'LABEL_REVISION_NOTE = "%s, %s, %s"\n',lbltime,lbleditor,lblrev);
        % mm = length(tname);
        fprintf(al,'PRODUCT_ID = "%s"\n',tname(1:(end-4)));
        fprintf(al,'PRODUCT_TYPE = "DDR"\n');  % No idea what this means...
        fprintf(al,'PRODUCT_CREATION_TIME = %s\n',datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'));
        fprintf(al,'INSTRUMENT_HOST_ID = RO\n');
        fprintf(al,'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\n');
        fprintf(al,'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\n');
        fprintf(al,'INSTRUMENT_ID = RPCLAP\n');
        fprintf(al,'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\n');
        fprintf(al,'TARGET_NAME = "%s"\n',targetfullname);
        fprintf(al,'TARGET_TYPE = "%s"\n',targettype);
        fprintf(al,'PROCESSING_LEVEL_ID = %d\n',4);
        
        %looks messy, but I'm finding the first original index used in this
        %file, and outputting it's start time, as well as the index of the
        %last file used, to output the stop time. There are easier ways, but
        %not as accurate.
        
        %  fprintf(al,'START_TIME  = %s\n',index(tabindex{tabi0,3}).t0str);
        % fprintf(al,'STOP_TIME  = %s\n',tabindex{tabi1,4});
        %        fprintf(al,'SPACECRAFT_CLOCK_START_COUNT  = %s\n',index(tabindex{tabi0,3}).sct0str(5:end-1));
        %       fprintf(al,'SPACECRAFT_CLOCK_STOP_COUNT  = %16.6f\n',tabindex{tabi1,5});
        fprintf(al,'OBJECT = TABLE\n');
        fprintf(al,'INTERCHANGE_FORMAT = ASCII\n');
        fprintf(al,'ROWS = %d\n',an_tabindex{i,4});
        fprintf(al,'COLUMNS = %d\n',an_tabindex{i,5});
        
        
        
        %     tempfp{1,2}{28,1} = index(tabindex{tabi0,3}).t0str; %UTC start time
        %     tempfp{1,2}{29,1} = tabindex{tabi1,4};             % UTC stop time
        %     tmpsct0 = index(tabindex{tabi0,3}).sct0str(5:end-1);
        %     tempfp{1,2}{30,1} = tmpsct0;                    %% sc start time
        %     tempfp{1,2}{31,1} = sprintf('%16.6f',tabindex{tabi1,5}); %% sc stop time
        
        if strcmp(an_tabindex{i,7},'downsample')
            
            mode = tname(end-6:end-4);
            Pnum = tname(end-5);
            %  fprintf(awID,'%s, %16.6f, %14.7e, %14.7e, %14.7e, %14.7e\n',foutarr{1,1}{j,1},foutarr{1,2}(j),foutarr{1,3}(j),foutarr{1,4}(j),foutarr{1,5}(j),foutarr{1,6}(j));
            %      23, 16+1, 14+1, 14+1, 14+1, 14+1
            %      = 2*5+23+17+15*4 = 110
            
            fprintf(al,'ROW_BYTES = 110\n');   %%row_bytes here!!!
            
            fprintf(al,'DESCRIPTION = "%s SECONDS DOWNSAMPLED MEASUREMENT"\n',lname(end-10:end-9));
            
            
            
            %%Varf?r finns det tv? "DESCRIPTION" i LBL filerna?
            
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = TIME_UTC\n');
            fprintf(al,'DATA_TYPE = TIME\n');
            fprintf(al,'START_BYTE = 1\n');
            fprintf(al,'BYTES = 23\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.FFF"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = OBT_TIME\n');
            fprintf(al,'START_BYTE = 26\n');
            fprintf(al,'BYTES = 16\n'); %
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'UNIT = SECONDS\n');
            fprintf(al,'DESCRIPTION = "SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_CURRENT\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 45\n');
            fprintf(al,'BYTES = 14\n');
            fprintf(al,'UNIT = AMPERE\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "AVERAGED CURRENT"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_CURRENT_STDDEV\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 62\n');
            fprintf(al,'BYTES = 14\n');
            fprintf(al,'UNIT = AMPERE\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "CURRENT STANDARD DEVIATION"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_VOLT\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 79\n');
            fprintf(al,'BYTES = 14\n');
            fprintf(al,'UNIT = VOLT\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "AVERAGED MEASURED VOLTAGE"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'OBJECT = COLUMN\n');
            fprintf(al,'NAME = P%s_VOLT_STDDEV\n',Pnum);
            fprintf(al,'DATA_TYPE = ASCII_REAL\n');
            fprintf(al,'START_BYTE = 96\n');
            fprintf(al,'BYTES = 14\n');
            fprintf(al,'UNIT = VOLT\n');
            fprintf(al,'FORMAT = E14.7\n');
            fprintf(al,'DESCRIPTION = "VOLTAGE STANDARD DEVIATION"\n');
            fprintf(al,'END_OBJECT  = COLUMN\n');
            
            fprintf(al,'END_OBJECT  = TABLE\n');
            fprintf(al,'END');
            fclose(al);
            
        end
        
    end
end

