%createLBL.m


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
    
    dl = fopen(strrep(tabindex{i,1},'TAB','LBL'),'w');
    
    
    fileinfo = dir(tabindex{i,1});
    tempfp{1,2}{3,1} = sprintf('%d',fileinfo.bytes);
    tempfp{1,2}{4,1} = sprintf('%d',tabindex{i,6});
    tempfp{1,2}{5,1} = lname;
    tempfp{1,2}{6,1} = tname;
    tempfp{1,2}{16,1} = sprintf('"%s, %s, %s"',lbltime,lbleditor,lblrev);
    tempfp{1,2}(17:18) = [];
    tempfp{1,1}(17:18) =[]; % should be deleted?
    tempfp{1,2}{17,1} = datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'); %lbl revision date
    tempfp{1,2}{27,1} = '"4"'; %% processing level ID
    tempfp{1,2}{28,1} = index(tabindex{i,3}).t0str; %UTC start time
    tempfp{1,2}{29,1} = tabindex{i,4};             % UTC stop time
    tmpsct0 = index(tabindex{i,3}).sct0str(5:end-1);
    tempfp{1,2}{30,1} = tmpsct0;                    %% sc start time
    tempfp{1,2}{31,1} = sprintf('%16.6f',tabindex{i,5}); %% sc stop time
    tempfp{1,2}{54,1} = sprintf('%i',tabindex{i,6}); %% rows
    
    a =    tname(30);
    if (tname(30)=='S') % special format for sweep files...
        
        if (tname(28)=='B')
            
            tempfp{1,2}{55,1} = 2;  %number of rows
            tempfp{1,2}{56,1} = 41; % number of cols
            tempfp{1,2}(58:82) = []; % everything except Voltage column deleted
            tempfp{1,1}(58:82) = [];
            tempfp{1,1}(67:77) = tempfp{1,1}(58:68);
            tempfp{1,2}(67:77) = tempfp{1,2}(58:68);
            tempfp{1,2}{61,1} = '1';
            tempfp{1,2}{68,1} = 'SWEEP_TIME';
            tempfp{1,2}{69,1} = 'ASCII_REAL';
            tempfp{1,2}{70,1} = '16';
            tempfp{1,2}{71,1} = '23';
            tempfp{1,2}{72,1} = 'SECONDS';
            tempfp{1,2}{73,1} = '"F16.6"';
            tempfp{1,2}{74,1} = '"RELATIVE TIME BETWEEN SWEEP SSSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"';
            
            
           
   
        elseif (tname(28)=='I')
            
            %current data is harder
           
            
            
        else
            fprintf(1,'  BAD IDENTIFIER FOUND, %s\n',tname);
        end
        
        
    end
    
    
    
    for i=1:length(tempfp{1,1})
        fprintf(dl,'%s=%s\n',tempfp{1,1}{i,1},tempfp{1,2}{i,1});
    end
    fclose(dl);
end




% for(i=1:length(tabindex))
%     tname = tabindex{i,2};
%     
% 
%     %tabindex cell array = {tab file name, first index number of batch,
%     % UTC time of last row, S/C time of last row, row counter}
%     %    units: [cell array] =  {[string],[double],[string],[float],[integer]
%     
%     % Write label file:
%     lname=strrep(tname,'TAB','LBL');
%     dl = fopen(strrep(tabindex{i,1},'TAB','LBL'),'w');
%     % 
%     fprintf(dl,'PDS_VERSION_ID = PDS3\n');
%     fprintf(dl,'RECORD_TYPE = FIXED_LENGTH\n');
%     fileinfo = dir(tabindex{i,1});
%     fprintf(dl,'RECORD_BYTES = %d',fileinfo.bytes);  % Now counting linefeed. Count lines later! What?
%     % FILE_RECORDS = 28
%     fprintf(dl,'FILE_RECORDS = %d\n',tabindex{i,6});%%number of rows??
%     fprintf(dl,'FILE_NAME = "%s"\n',lname);
%     fprintf(dl,'^TABLE = "%s"\n',tname);
%     fprintf(dl,'DATA_SET_ID = "%s"\n',datasetid);
%     fprintf(dl,'DATA_SET_NAME = "%s"\n',datasetname);
%     fprintf(dl,'DATA_QUALITY_ID = 1\n'); % NEEDS A VALUE. inside tabindex?
%     fprintf(dl,'MISSION_ID = ROSETTA\n');
%     fprintf(dl,'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\n');
%     fprintf(dl,'MISSION_PHASE_NAME = "%s"\n',missionphase);
%     fprintf(dl,'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\n');
%     fprintf(dl,'PRODUCER_ID = RG\n');
%     fprintf(dl,'PRODUCER_FULL_NAME = "REINE GILL"\n');
%     fprintf(dl,'LABEL_REVISION_NOTE = "%s, %s, %s"\n',lbltime,lbleditor,lblrev);
%     mm = length(tname);
%     % PRODUCT_ID = "RPCLAP100707_0A0T_CEB28NS"
% 
%     % PRODUCT_TYPE = "RDR"
%     fprintf(dl,'PRODUCT_ID = "RDR"\n'); 
% %    fprintf(dl,'PRODUCT_ID = "%s"\n',gtname(1:(mm-4)));
%     fprintf(dl,'PRODUCT_TYPE = "EDR"\n');  % No idea what this means...
%     fprintf(dl,'PRODUCT_CREATION_TIME = %s\n',datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'));
%     fprintf(dl,'INSTRUMENT_HOST_ID = RO\n');
%     fprintf(dl,'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\n');
%     fprintf(dl,'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\n');
%     fprintf(dl,'INSTRUMENT_ID = RPCLAP\n');
%     fprintf(dl,'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\n');
%     % INSTRUMENT_MODE_ID = MCID0X0503
%     fprintf(dl,'INSTRUMENT_MODE_ID = "%s"\n',index(tabindex{i,3}).macro);
%     % INSTRUMENT_MODE_DESC = "EE Cont. 20 bit down 64, Every 160s 16 Bit P1"
%     fprintf(dl,'INSTRUMENT_MODE_DESC = "N/A"\n');
%     fprintf(dl,'TARGET_NAME = "%s"\n',targetfullname);
%     fprintf(dl,'TARGET_TYPE = "%s"\n',targettype);
%     fprintf(dl,'PROCESSING_LEVEL_ID = 4\n');
%     fprintf(dl,'START_TIME = %s\n',index(tabindex{i,3}).t0str); 
%     fprintf(dl,'STOP_TIME = %s\n',tabindex{i,4});
%     tmpsct0 = index(tabindex{i,3}).sct0str(5:end-1);
%     
%     fprintf(dl,'SPACECRAFT_CLOCK_START_COUNT = %s\n',tmpsct0);
%     fprintf(dl,'SPACECRAFT_CLOCK_STOP_COUNT =  %s\n',sprintf('%f',tabindex{i,5}));
%     fprintf(dl,'\n');
% 
%     
%     % NEED TO FETCH THIS DATA FROM MACRO
%     
% % DESCRIPTION = "E_P1P2INTRL_TRNC_20BIT_RAW_BIP"
% % ROSETTA:LAP_TM_RATE = "NORMAL"
% % ROSETTA:LAP_BOOTSTRAP = "ON"
% % ROSETTA:LAP_FEEDBACK_P2 = "E-FIELD"
% % ROSETTA:LAP_P2_ADC20 = "E-FIELD"
% % ROSETTA:LAP_P2_ADC16 = "E-FIELD"
% % ROSETTA:LAP_P2_RANGE_DENS_BIAS = "+-32"
% % ROSETTA:LAP_P2_STRATEGY_OR_RANGE = "BIAS"
% % ROSETTA:LAP_P2_RX_OR_TX = "ANALOG INPUT"
% % ROSETTA:LAP_P2_ADC16_FILTER = "8 KHz"
% % ROSETTA:LAP_IBIAS2 = "0x00d6"
% % ROSETTA:LAP_P2_BIAS_MODE = "E-FIELD"
% % ROSETTA:LAP_FEEDBACK_P1 = "E-FIELD"
% % ROSETTA:LAP_P1_ADC20 = "E-FIELD"
% % ROSETTA:LAP_P1_ADC16 = "E-FIELD"
% % ROSETTA:LAP_P1_RANGE_DENS_BIAS = "+-32"
% % ROSETTA:LAP_P1_STRATEGY_OR_RANGE = "BIAS"
% % ROSETTA:LAP_P1_RX_OR_TX = "ANALOG INPUT"
% % ROSETTA:LAP_P1_ADC16_FILTER = "8 KHz"
% % ROSETTA:LAP_IBIAS1 = "0x0077"
% % ROSETTA:LAP_P1_BIAS_MODE = "E-FIELD"
% % ROSETTA:LAP_P1P2_ADC20_STATUS = "P1T & P2T"
% % ROSETTA:LAP_P1P2_ADC20_MA_LENGTH = "0x0040"
% % ROSETTA:LAP_P1P2_ADC20_DOWNSAMPLE = "0x0040"
% 
% 
% 
%     fprintf(dl,'OBJECT = TABLE\n');
%     %fprintf(dl,'NAME = "RPCLAP-%d-%s-GEOM"\n',processlevel,shortphase);
%     %only for geometry?
%     
%     fprintf(dl,'INTERCHANGE_FORMAT = ASCII\n');
%     fprintf(dl,'ROWS = %d\n',tabindex{i,5});
%     fprintf(dl,'COLUMNS = 5\n'); % usually two timers, two data rows, 1 quality factor
%     fprintf(dl,'ROW_BYTES = 422\n'); % god damn Byte counter again
%     fprintf(dl,'DESCRIPTION = "SPACECRAFT DATA: UTC TIME, S/C TIME, MEASURED CURRENT, BIAS VOLTAGE, QUALITY."\n');
% % DESCRIPTION        = "E_P1P2INTRL_TRNC_20BIT_RAW_BIP"
%     fprintf(dl,'\n'); % Do i need extra line breaks?
%     
%     
%     fprintf(dl,'OBJECT = COLUMN\n');
%  %   fprintf(dl,'NAME = TIME_UTC\n'); %OBS Anders geometry and calib uses two different names for the same thing
%     fprintf(dl,'NAME = UTC_TIME\n');   
%     fprintf(dl,'DATA_TYPE = TIME\n');
%     fprintf(dl,'START_BYTE = 1\n');
%     fprintf(dl,'BYTES = 23\n'); %goddamn byte
%     %fprintf(dl,'UNIT = SECONDS\n');
%     fprintf(dl,'DESCRIPTION = " UTC TIME YYYY-MM-DDTHH:MM:SS.sss"\n');
%     fprintf(dl,'END_OBJECT  = COLUMN\n');
%     fprintf(dl,'\n');
%    
%     fprintf(dl,'OBJECT = COLUMN\n');
%     fprintf(dl,'NAME = OBT_TIME\n');   
%     fprintf(dl,'START_BYTE = 1\n');
%     fprintf(dl,'BYTES = 23\n'); %goddamn byte
%     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
%     fprintf(dl,'UNIT = SECONDS\n');
%     fprintf(dl,'DESCRIPTION = "SPACE CRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)"\n');
%     fprintf(dl,'END_OBJECT  = COLUMN\n');
%     fprintf(dl,'\n');
%    
%     fprintf(dl,'OBJECT = COLUMN\n');
%     % NAME        = P2_CURRENT
%     fprintf(dl,'NAME = %d_CURRENT\n',index(tabindex{i,2}).probe);   % NEED probe value.
%     
%     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
%     fprintf(dl,'START_BYTE = 1\n');
%     fprintf(dl,'BYTES = 23\n'); %goddamn byte
%     fprintf(dl,'UNIT = AMPERE\n');
%     fprintf(dl,'FORMAT = E14.7\n');
%     fprintf(dl,'DESCRIPTION = "CALIBRATED CURRENT BIAS"\n');
%     fprintf(dl,'END_OBJECT  = COLUMN\n');
%     fprintf(dl,'\n');
%     
%     
%     fprintf(dl,'OBJECT = COLUMN\n');
%     fprintf(dl,'NAME = %d_VOLTAGE\n',index(tabindex{i,3}).probe);   % NEED probe value.
%     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
%     fprintf(dl,'START_BYTE = 1\n');
%     fprintf(dl,'BYTES = 23\n'); %goddamn byte
%     fprintf(dl,'UNIT = VOLT\n');
%     fprintf(dl,'FORMAT = E14.7\n');
%     fprintf(dl,'DESCRIPTION = "MEASURED CALIBRATED VOLTAGE"\n');
%     fprintf(dl,'END_OBJECT  = COLUMN\n');
%     fprintf(dl,'\n');
%     
% % ARE THERE DIFFERENT LBL FILES DEPENDING ON MEASUREMENT MODE?
% 
%     fprintf(dl,'OBJECT = COLUMN\n');
%     fprintf(dl,'NAME = QF\n');   
%     fprintf(dl,'START_BYTE = 1\n');
%     fprintf(dl,'BYTES = 23\n'); %goddamn byte
%     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %    fprintf(dl,'UNIT = SECONDS\n'); No unit on QF
%     fprintf(dl,'DESCRIPTION = "QUALITYFACTOR, FROM 1-3"\n');
%     fprintf(dl,'END_OBJECT  = COLUMN\n');
%     fprintf(dl,'\n');
% 
%     
%     fprintf(dl,'END_OBJECT = TABLE\n');
%     fprintf(dl,'\n');
%     fprintf(dl,'END');
%     fclose(dl);
%   
%     
% %  fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_SUN_POS_X\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 26\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km"\n');
% %     fprintf(dl,'DESCRIPTION = "HELIOCENTRIC ECLIPJ2000 POSITION X"\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_SUN_POS_Y\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 44\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km"\n');
% %     fprintf(dl,'DESCRIPTION = "HELIOCENTRIC ECLIPJ2000 POSITION Y"\n'); 
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_SUN_POS_Z\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 62\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km"\n');
% %     fprintf(dl,'DESCRIPTION = "HELIOCENTRIC ECLIPJ2000 POSITION Z"\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_TGT_POS_X\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 80\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km"\n');
% %     fprintf(dl,'DESCRIPTION = "TARGET CENTRED ECLIPJ2000 POSITION X. ZERO WHEN NO TARGET."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_TGT_POS_Y\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 98\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km"\n');
% %     fprintf(dl,'DESCRIPTION = "TARGET CENTRED ECLIPJ2000 POSITION Y. ZERO WHEN NO TARGET."\n'); 
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_TGT_POS_Z\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 116\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km"\n');
% %     fprintf(dl,'DESCRIPTION = "TARGET CENTRED ECLIPJ2000 POSITION Z. ZERO WHEN NO TARGET."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_TGT_VEL_X\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 134\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km/s"\n');
% %     fprintf(dl,'DESCRIPTION = "ECLIPJ2000 VELOCITY X RELATIVE TO TARGET. ZERO WHEN NO TARGET."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_TGT_VEL_Y\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 152\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km/s"\n');
% %     fprintf(dl,'DESCRIPTION = "ECLIPJ2000 VELOCITY Y RELATIVE TO TARGET. ZERO WHEN NO TARGET."\n'); 
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_TGT_VEL_Z\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 170\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km/s"\n');
% %     fprintf(dl,'DESCRIPTION = "ECLIPJ2000 VELOCITY Z RELATIVE TO TARGET. ZERO WHEN NO TARGET."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = ALTITUDE\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 188\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km"\n');
% %     fprintf(dl,'DESCRIPTION = "DISTANCE TO SURFACE OF CURRENT TARGET. ZERO WHEN NO TARGET."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = LATITUDE\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 206\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "degrees"\n');
% %     fprintf(dl,'DESCRIPTION = "LATITUDE ON SURFACE OF CURRENT TARGET. ZERO WHEN NO TARGET."\n'); 
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = LONGITUDE\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 224\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "degrees"\n');
% %     fprintf(dl,'DESCRIPTION = "LONGITUDE ON SURFACE OF CURRENT TARGET. ZERO WHEN NO TARGET."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_TGT_SPEED\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 242\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "km/s"\n');
% %     fprintf(dl,'DESCRIPTION = "SPEED RELATIVE TO CURRENT TARGET. ZERO WHEN NO TARGET."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_X_ECLIPJ2000FR_X\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 260\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "N/A"\n');
% %     fprintf(dl,'DESCRIPTION = "SPACECRAFT FRAME X EXPRESSED IN ECLIPTIC J2000 FRAME X."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_X_ECLIPJ2000FR_Y\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 278\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "N/A"\n');
% %     fprintf(dl,'DESCRIPTION = "SPACECRAFT FRAME X EXPRESSED IN ECLIPTIC J2000 FRAME Y."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_X_ECLIPJ2000FR_Z\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 296\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "N/A"\n');
% %     fprintf(dl,'DESCRIPTION = "SPACECRAFT FRAME X EXPRESSED IN ECLIPTIC J2000 FRAME Z."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_Y_ECLIPJ2000FR_X\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 314\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "N/A"\n');
% %     fprintf(dl,'DESCRIPTION = "SPACECRAFT FRAME Y EXPRESSED IN ECLIPTIC J2000 FRAME X."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_Y_ECLIPJ2000FR_Y\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 332\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "N/A"\n');
% %     fprintf(dl,'DESCRIPTION = "SPACECRAFT FRAME Y EXPRESSED IN ECLIPTIC J2000 FRAME Y."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_Y_ECLIPJ2000FR_Z\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 350\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "N/A"\n');
% %     fprintf(dl,'DESCRIPTION = "SPACECRAFT FRAME Y EXPRESSED IN ECLIPTIC J2000 FRAME Z."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_Z_ECLIPJ2000FR_X\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 368\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "N/A"\n');
% %     fprintf(dl,'DESCRIPTION = "SPACECRAFT FRAME Z EXPRESSED IN ECLIPTIC J2000 FRAME X."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_Z_ECLIPJ2000FR_Y\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 386\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "N/A"\n');
% %     fprintf(dl,'DESCRIPTION = "SPACECRAFT FRAME Z EXPRESSED IN ECLIPTIC J2000 FRAME Y."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'OBJECT = COLUMN\n');
% %     fprintf(dl,'NAME = SC_Z_ECLIPJ2000FR_Z\n');
% %     fprintf(dl,'DATA_TYPE = ASCII_REAL\n');
% %     fprintf(dl,'START_BYTE = 404\n');
% %     fprintf(dl,'BYTES = 16\n');
% %     fprintf(dl,'UNIT = "N/A"\n');
% %     fprintf(dl,'DESCRIPTION = "SPACECRAFT FRAME Z EXPRESSED IN ECLIPTIC J2000 FRAME Z."\n');
% %     fprintf(dl,'END_OBJECT  = COLUMN\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'END_OBJECT = TABLE\n');
% %     fprintf(dl,'\n');
% %     fprintf(dl,'END');
% %     fclose(dl);
% %     
% %     
% end

