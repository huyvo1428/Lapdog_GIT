function [varargout] = write_CALIB_MEAS_files(pearch,mp,outpath)

% write_CALIB_MEAS_files
%	
%   Given that the path and name of the EDITED archive
%   example: pearch='/data/LAP_ARCHIVE/RO-E-RPCLAP-2-EAR3-EDITED-V1.0'
%   
%   The mission phase example: mp='EAR3'
%
%   And the output path: outpath
%
%   This program computes calibration files and adds them to the 
%   output folder that can then be used by the PDS software
%   to create the calibrated archive. Also, a calibration coefficient list 
%   file is created.
%   
%   SYNTAX:
%       
%                    write_CALIB_MEAS_files(pearch,missionphasename,outpath)
%       
%       offsetData =  write_CALIB_MEAS_files(pearch,missionphasename,outpath)
%       
%       
%                   
%   Author: Martin Ulfvik 
%   Rewritten by Reine Gill
%   third degree polynomial solution by FKJN 28/8 2014
%
%   Usage: However the Swedish Institute of Space Physics sees fit.
%   $Revision: 1.0 $  $Date: 2009/05/21 13:28 $ 
%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Sets the values for the basic parameters.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    DATA_SESSION_RESET_TIME = 1;
    MODE_SESSION_RESET_TIME = 1/(24*2);
    
    MIN_GRADIENT_1 = -4.2;
    MAX_GRADIENT_1 = -3.3;
    
    MIN_INTERCEPT_1 = 410;
    MAX_INTERCEPT_1 = 600;
    
    MIN_GRADIENT_2 = -2.5;
    MAX_GRADIENT_2 = -1.7;
    
    MIN_INTERCEPT_2 = 200;
    MAX_INTERCEPT_2 = 390;
    
    MIN_CORRELATION = 0.99;
 
    diag = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Validates the input/output arguments used.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    error(nargchk(3,3, nargin));
    error(nargoutchk(0, 1, nargout));
   
    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %   * Finds the relevant folders
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  disp('Paths');
  disp('----------------------------------------------------------------');
  epath = fullfile(pearch);        % Full Edited archive path

  fprintf(1,'Edited Archive and path: %s\r\n',epath);
  fprintf(1,'Mission phase: %s\r\n',mp);
  fprintf(1,'Output calibration file path: %s\r\n\r\n',outpath);

  ipath = fullfile(epath,'INDEX'); % Full index file path

  dpath = fullfile(epath,'DATA');  % Full data file path
    
  [dummy,earch]=fileparts(pearch); % Split to get DATA_SET_ID

    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %   * Extracts the information from the index file
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  %   scan.I{1}: Path and filename
  %   scan.I{2}: filename
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                 
    
  index = struct;
    
  filePath = fullfile(ipath,'INDEX.TAB');
  fileID   = fopen(filePath, 'r');

  if(fileID<=0)
    fprintf(1,'Could not open file: %s',filePath);
    return;
  end
     
  index = textscan(fileID,'%s%s%*s%*s%*s%*s','Delimiter',','); 
       
  fclose(fileID);


nfiles = length(index{1});

fprintf(1,'Trimming quotes from index file\n');
for ind=1:nfiles
    index{1}{ind}(1)=' ';
    index{1}{ind}(end)=' ';
    index{1}{ind}=strtrim(index{1}{ind});
       
    if(mod(ind,100)==0)
	fprintf(1,'\rProgress % 04.1f %%',100*ind/nfiles);
    end
end

fprintf(1,'\n');

ind=1;
fprintf(1,'Removing House Keeping files from index file\n');
while(ind<nfiles)
  if(index{1}{ind}(end-4)=='H')
    index{1}(ind)=[];
    index{2}(ind)=[]; 
    nfiles=nfiles-1;
  else
    ind=ind+1;
  end

 if(mod(ind,100)==0)
	fprintf(1,'\rProgress % 04.1f %%',100*ind/nfiles);
 end
end


fprintf(1,'\n');
  
% Extract start and stop time from the data files (no longer in the index file)

fprintf(1,'Opening each file in the index file to get the start, stop time and mode\n');
  
fprintf(1,'This is probably time consuming (This info was removed from index file itself by ESA)\n');


nfiles = length(index{1});

for ind=1:nfiles

  fname=fullfile(pearch,index{1}{ind});
  fileID=fopen(fname,'r');

  if(fileID>0)
    state=0;
    while(~feof(fileID) && state<3)
      
            line = fgetl(fileID);

            if(~isempty(line))

	      if(strncmp(line,'START_TIME',10))
                start_time=line;
                state=state+1;
	      end

              if(strncmp(line,'STOP_TIME',9))
                stop_time=line;
                state=state+1;
              end

	      if(strncmp(line,'INSTRUMENT_MODE_ID',18))
		 mode=line;
		 state=state+1;
              end

            end
    end
    fclose(fileID);
  end

  [tmp,str]=strread(start_time,'%s%s','delimiter','=');
  value=datenum(str,'yyyy-mm-ddTHH:MM:SS.FFF');
  index{3}{ind,1}=value;

  [tmp,str]=strread(stop_time,'%s%s','delimiter','=');
  value=datenum(str,'yyyy-mm-ddTHH:MM:SS.FFF');
  index{4}{ind,1}=value;

  [tmp,value]=strread(mode,'%s%s','delimiter','=');
  index{5}{ind,1}=char(value);

  if(mod(ind,100)==0)
	fprintf(1,'\rProgress % 04.1f %%',100*ind/nfiles);
  end
end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Moves the data from the data cell to the data structure with some
    %     data format change.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    display('Progress: Changing data format.');
    
    data = struct;
    data.mode           = char(index{5});
    data.startTime      = [index{3}{:}]'; %'

    data.stopTime       = [index{4}{:}]'; %'
    data.pathName       = char(index{1});
    data.fileName       = char(index{2});
    
    data.count =  length(data.startTime);
  
    %clear index;
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Finds out when each data session starts.
    %   * For each offset data, it determines which probe, data session and
    %     mode session it belongs to and wether it was run in a cold state.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    display('Progress: Analyzing index data.');
    
    dataSessionStart = zeros(data.count,1);
    
    data.dataSession = zeros(data.count,1);
    data.modeSession = zeros(data.count,1);
    data.cold        = zeros(data.count,1);
    
    dataSession = 0;
    modeSession = 0;
    
    newSession = true;
    coldState  = true;
    
    stopTimeLatest = 0;
    
    indicesToRemove = zeros(data.count,1);
    
    for dataRow = 1:data.count        
       if (dataRow == data.count) || (~strcmp(data.fileName(dataRow,:),data.fileName(dataRow+1,:)))
            
          if data.startTime(dataRow) - stopTimeLatest >= DATA_SESSION_RESET_TIME
                
                dataSession = dataSession + 1;
                dataSessionStart(dataSession) = data.startTime(dataRow);
          end
            
          if strcmp(upper(data.mode(dataRow,:)),'MCID0X0104')
             if data.startTime(dataRow) - stopTimeLatest >= MODE_SESSION_RESET_TIME
                modeSession = modeSession + 1;
                newSession = false;
                    
                coldState = true;
                data.cold(dataRow) = coldState;
                    
             elseif newSession
                modeSession = modeSession + 1;
                newSession = false;
                    
                coldState = false;
                data.cold(dataRow) = coldState;
             else
                data.cold(dataRow) = coldState;
             end
                
                data.dataSession(dataRow) = dataSession;
                data.modeSession(dataRow) = modeSession;
          else
                indicesToRemove(dataRow) = true;
                newSession = true;
          end
            
          if data.stopTime(dataRow) > stopTimeLatest
                stopTimeLatest = data.stopTime(dataRow);
          end
       else
            indicesToRemove(dataRow) = true; % Remove duplicate
       end
     end
  
    dataSessionStart(dataSession+1:data.count) = [];
    

    indr = find(indicesToRemove);
    data.mode(indr,:)         = [];
    data.startTime(indr)      = [];
    data.stopTime(indr)       = [];
    data.pathName(indr,:)     = [];
    data.fileName(indr,:)     = [];
    data.dataSession(indr)    = [];
    data.modeSession(indr)    = [];
    data.cold(indr)           = [];
    
    data.count =  length(data.startTime);
    
    clear indicesToRemove;
    
    if(data.count==0)
           disp('No calibration macros found')
           return;
    end
    
    temp = char(data.fileName);
    data.probe = str2num(temp(:,23));
    clear temp;
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Reads the offset files.
    %   * Gets the offset parameters for each file:
    %       * Gradient
    %       * Intercept
    %       * Coefficient of correlation
    %   * First check for anomaly classification.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    display('Progress: Working the offset data.');
    
    data.gradient    = zeros(data.count,1);
    data.intercept   = zeros(data.count,1);
    data.correlation = zeros(data.count,1);
    data.anomaly     = zeros(data.count,1);
    data.cubeg  	 = zeros(data.count,1);
    data.sqrg         = zeros(data.count,1);
    
    for dataRow = 1:data.count
        filePath = fullfile(pearch,strcat(data.pathName(dataRow,1:end-4),'.TAB'));
        
        fileID = fopen(filePath, 'r');
        
        if(fileID>0)    
          scan = textscan(fileID, '%*s %*f %f %f', 'Delimiter', ',');
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %   scan{1}: Units of current
                %   scan{2}: Units of voltage
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
          fclose(fileID);
        
          voltage = scan{2};
          current = scan{1};
        
          clear scan;
        
          firstVoltageValue = voltage(1);
        
          starterValueCounter = 1;
        
          while voltage(starterValueCounter+1) == firstVoltageValue
            
            starterValueCounter = starterValueCounter + 1;
          end
        
          voltage(1:starterValueCounter) = [];
          current(1:starterValueCounter) = [];
        
          if isempty(voltage)
            data.anomaly(dataRow) = true;
          else
%            polyCoeffs = polyfit(voltage, current, 1);
             polyCoeffs = polyfit(voltage, current, 3);
             %FKJN edit 28/8 2014
                          
             
             if diag
                 
                 
                 polyCoeffs2 = polyfit(voltage, current, 1);
                 figure(22);
                 plot(voltage,current,'b',voltage,(polyCoeffs(1)*voltage.^3+polyCoeffs(2)*voltage.^2+polyCoeffs(3)*voltage+polyCoeffs(4)),'g',voltage,(polyCoeffs2(1)*voltage+polyCoeffs2(2)),'r')
                 
                 figure(23);
                 plot(voltage,current-(polyCoeffs(1)*voltage.^3+polyCoeffs(2)*voltage.^2+polyCoeffs(3)*voltage+polyCoeffs(4)),'g',voltage,current-(polyCoeffs2(1)*voltage+polyCoeffs2(2)),'r')
             end
             
             data.cubeg(dataRow)     = polyCoeffs(1);
            data.sqrg(dataRow)      = polyCoeffs(2);
            data.gradient(dataRow)  = polyCoeffs(3);
            data.intercept(dataRow) = polyCoeffs(4);                       
        
            n = length(voltage);
            
            numerator = n*sum(voltage.*current) - sum(voltage)*sum(current);
            
            denominator = sqrt(n*sum(voltage.^2)-(sum(voltage))^2) * sqrt(n*sum(current.^2)-(sum(current))^2);
            
            data.correlation(dataRow) = abs(numerator / denominator);
          end
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Second check for anomaly classification.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    anomalyIndices = find(((data.gradient < MIN_GRADIENT_1 | data.gradient > MAX_GRADIENT_1 | data.intercept < MIN_INTERCEPT_1 | data.intercept > MAX_INTERCEPT_1) & (data.gradient < MIN_GRADIENT_2 | data.gradient > MAX_GRADIENT_2 | data.intercept < MIN_INTERCEPT_2 | data.intercept > MAX_INTERCEPT_2)) | data.correlation < MIN_CORRELATION);
    
    data.anomaly(anomalyIndices) = true;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Determines data points and associates values to be used from 
    %     actual offset data of good status.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    dataWriteMaxLength = length(dataSessionStart) + max(data.modeSession);
    
    dataWrite = struct;
    dataWrite.count      = 0;
    dataWrite.startTime  = zeros(dataWriteMaxLength,1);
    dataWrite.gradient1 = zeros(dataWriteMaxLength,2);
    dataWrite.gradient2 = zeros(dataWriteMaxLength,2);
    dataWrite.gradient3 = zeros(dataWriteMaxLength,2);
    dataWrite.intercepts = zeros(dataWriteMaxLength,2);
    
    for modeSession = 1:max(data.modeSession)
        
        p1 = find(data.modeSession == modeSession & data.probe == 1 & data.cold == 0 & data.anomaly == 0);
        p2 = find(data.modeSession == modeSession & data.probe == 2 & data.cold == 0 & data.anomaly == 0);
        
        if ~(isempty(p1) || isempty(p2))
            
            dataWrite.count = dataWrite.count + 1;
            
            dataWrite.startTime(dataWrite.count)    = min(min(data.startTime(p1)), min(data.startTime(p2)));
            dataWrite.gradient1(dataWrite.count,:)  = [mean(data.gradient(p1))  mean(data.gradient(p2)) ];
            dataWrite.gradient2(dataWrite.count,:)  = [mean(data.sqrg(p1))      mean(data.sqrg(p2)) ];
            dataWrite.gradient3(dataWrite.count,:)  = [mean(data.cubeg(p1))     mean(data.cubeg(p2)) ];
            dataWrite.intercepts(dataWrite.count,:) = [mean(data.intercept(p1)) mean(data.intercept(p2))];
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Determines data points associated with days of data session
    %     starts that are not covered by days of actual data points.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    actualData = dataWrite.count;
    
    for dataSessionCounter = 1:length(dataSessionStart)
        
        if isempty(find(floor(dataWrite.startTime) == floor(dataSessionStart(dataSessionCounter)), 1, 'first'))
            
            dataWrite.count = dataWrite.count + 1;
            
            earlyIndex = find(dataWrite.startTime <= dataSessionStart(dataSessionCounter) & dataWrite.startTime >  0, 1, 'first');
            lateIndex  = find(dataWrite.startTime >  dataSessionStart(dataSessionCounter), 1, 'first');
            
            dataWrite.startTime(dataWrite.count) = dataSessionStart(dataSessionCounter);
            
            if isempty(earlyIndex)
                
                dataWrite.gradient1(dataWrite.count,:)  = dataWrite.gradient1(1,:);
                dataWrite.gradient2(dataWrite.count,:)  = dataWrite.gradient2(1,:);
                dataWrite.gradient3(dataWrite.count,:)  = dataWrite.gradient3(1,:);
                dataWrite.intercepts(dataWrite.count,:) = dataWrite.intercepts(1,:);
                
            elseif isempty(lateIndex)
                
                dataWrite.gradient1(dataWrite.count,:)  = dataWrite.gradient1(actualData,:);
                dataWrite.gradient2(dataWrite.count,:)  = dataWrite.gradient2(actualData,:);
                dataWrite.gradient3(dataWrite.count,:)  = dataWrite.gradient3(actualData,:);                                
                dataWrite.intercepts(dataWrite.count,:) = dataWrite.intercepts(actualData,:);
                
            else
                
                fractionTime = (dataWrite.startTime(dataWrite.count)-dataWrite.startTime(earlyIndex)) / (dataWrite.startTime(lateIndex)-dataWrite.startTime(earlyIndex));
                
                dataWrite.gradient1(dataWrite.count,:)  = dataWrite.gradient1(earlyIndex,:)  + fractionTime*(dataWrite.gradient1(lateIndex,:) -dataWrite.gradient1(earlyIndex,:) );
                dataWrite.gradient2(dataWrite.count,:)  = dataWrite.gradient2(earlyIndex,:)  + fractionTime*(dataWrite.gradient2(lateIndex,:) -dataWrite.gradient2(earlyIndex,:) );
                dataWrite.gradient3(dataWrite.count,:)  = dataWrite.gradient3(earlyIndex,:)  + fractionTime*(dataWrite.gradient3(lateIndex,:) -dataWrite.gradient3(earlyIndex,:) );
                dataWrite.intercepts(dataWrite.count,:) = dataWrite.intercepts(earlyIndex,:) + fractionTime*(dataWrite.intercepts(lateIndex,:)-dataWrite.intercepts(earlyIndex,:));
            end
        end
    end
    
    dataWrite.startTime(dataWrite.count+1:dataWriteMaxLength)    = [];
    dataWrite.gradient1(dataWrite.count+1:dataWriteMaxLength,:)  = [];
    dataWrite.gradient2(dataWrite.count+1:dataWriteMaxLength,:)  = [];
    dataWrite.gradient3(dataWrite.count+1:dataWriteMaxLength,:)  = [];

    dataWrite.intercepts(dataWrite.count+1:dataWriteMaxLength,:) = [];
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Removes superfluous actual data points from same days.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    indicesToRemove = zeros(actualData,1);
    
   if(actualData>1)

    for actualDataCounter = 1:(actualData-1)
        
        if floor(dataWrite.startTime(actualDataCounter)) == floor(dataWrite.startTime(actualDataCounter+1))
            
            indicesToRemove(actualDataCounter+1) = true;
        end
    end
    
    dataWrite.startTime(find(indicesToRemove))    = [];
    dataWrite.gradient1(find(indicesToRemove),:)  = [];
    dataWrite.gradient2(find(indicesToRemove),:)  = [];
    dataWrite.gradient3(find(indicesToRemove),:)  = [];

    dataWrite.intercepts(find(indicesToRemove),:) = [];
    
   end

    dataWrite.count = length(dataWrite.startTime);
    
    clear indicesToRemove;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Writes all the CALIB_MEAS files for each of the base folders.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for dataWriteCounter = 1:dataWrite.count
        
        startTimeString = datestr(dataWrite.startTime(dataWriteCounter), 'yyyy-mm-ddTHH:MM:SS.FFF');
        
        fileName = strcat('RPCLAP', datestr(dataWrite.startTime(dataWriteCounter), 'yymmdd'), '_CALIB_MEAS');
        fileName2 = strcat('RPCLAP', datestr(dataWrite.startTime(dataWriteCounter), 'yymmdd'), '_CALIB_COEF');

        voltage = 0:1:255;
        
        currentP1 = dataWrite.intercepts(dataWriteCounter,1) + dataWrite.gradient1(dataWriteCounter,1)*voltage +dataWrite.gradient2(dataWriteCounter,1)*voltage.^2 +dataWrite.gradient3(dataWriteCounter,1)*voltage.^3;
        currentP2 = dataWrite.intercepts(dataWriteCounter,2) + dataWrite.gradient1(dataWriteCounter,2)*voltage +dataWrite.gradient2(dataWriteCounter,2)*voltage.^2 +dataWrite.gradient3(dataWriteCounter,2)*voltage.^3;
        
        currentP1 = floor(currentP1+0.5);
        currentP2 = floor(currentP2+0.5);

        filePathLBL = fullfile(outpath, strcat(fileName, '.LBL'));
        filePathTAB = fullfile(outpath, strcat(fileName, '.TAB'));
        filePath2TAB = fullfile(outpath, strcat(fileName2, '.TAB'));
            
        fileID = fopen(filePathLBL, 'wt');
                
                fprintf(fileID, 'PDS_VERSION_ID = PDS3\r\n');
                fprintf(fileID, 'RECORD_TYPE = FIXED_LENGTH\r\n');
                fprintf(fileID, 'RECORD_BYTES = 19\r\n');
                fprintf(fileID, 'FILE_RECORDS = 256\r\n');
                fprintf(fileID, strcat('FILE_NAME = "', fileName, '.LBL"\r\n'));
                fprintf(fileID, strcat('^TABLE = "', fileName, '.TAB"\r\n'));
                fprintf(fileID, 'DATA_SET_ID = "%s"\r\n',earch);
                fprintf(fileID, 'DATA_SET_NAME = "ROSETTA-ORBITER EARTH RPCLAP 3 MARS CALIB V1.0"\r\n');
                fprintf(fileID, 'MISSION_ID = ROSETTA\r\n');
                fprintf(fileID, 'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\r\n');
                fprintf(fileID, 'MISSION_PHASE_NAME = %s\r\n',mp);
                fprintf(fileID, 'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\r\n');
                fprintf(fileID, 'PRODUCER_ID = RG\r\n');
                fprintf(fileID, 'PRODUCER_FULL_NAME = "REINE GILL"\r\n');
                fprintf(fileID, strcat('PRODUCT_ID = "', fileName, '"\r\n'));
                fprintf(fileID, horzcat('PRODUCT_CREATION_TIME = ', datestr(now, 'yyyy-mm-ddTHH:MM:SS'), '\r\n'));
                fprintf(fileID, 'INSTRUMENT_HOST_ID = RO\r\n');
                fprintf(fileID, 'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\r\n');
                fprintf(fileID, 'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\r\n');
                fprintf(fileID, 'INSTRUMENT_ID = RPCLAP\r\n');
                fprintf(fileID, 'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\r\n');
                fprintf(fileID, horzcat('START_TIME = ', startTimeString, '\r\n'));
                fprintf(fileID, 'SPACECRAFT_CLOCK_START_COUNT = "N/A"\r\n');
                fprintf(fileID, 'DESCRIPTION = "CONVERSION FROM TM UNITS TO AMPERES AND VOLTS"\r\n');
                fprintf(fileID, 'ROSETTA:LAP_VOLTAGE_CAL_16B = "1.22072175E-3"\r\n');
                fprintf(fileID, 'ROSETTA:LAP_VOLTAGE_CAL_20B = "7.62940181E-5"\r\n');
                fprintf(fileID, 'ROSETTA:LAP_CURRENT_CAL_16B_G1 = "3.05180438E-10"\r\n');
                fprintf(fileID, 'ROSETTA:LAP_CURRENT_CAL_20B_G1 = "1.90735045E-11"\r\n');
                fprintf(fileID, 'ROSETTA:LAP_CURRENT_CAL_16B_G0_05 = "6.10360876E-9"\r\n');
                fprintf(fileID, 'ROSETTA:LAP_CURRENT_CAL_20B_G0_05 = "3.81470090E-10"\r\n');
                fprintf(fileID, 'OBJECT = TABLE\r\n');
                fprintf(fileID, 'INTERCHANGE_FORMAT = ASCII\r\n');
                fprintf(fileID, 'ROWS = 256\r\n');
                fprintf(fileID, 'COLUMNS = 3\r\n');
                fprintf(fileID, 'ROW_BYTES = 19\r\n');
                fprintf(fileID, 'DESCRIPTION = "THIRD DEGREE POLYNOMIAL OFFSET CORRECTION FOR 16 BIT DENSITY DATA"\r\n');
                fprintf(fileID, 'OBJECT = COLUMN\r\n');
                fprintf(fileID, 'NAME = P1P2_VOLTAGE\r\n');
                fprintf(fileID, 'DATA_TYPE = ASCII_INTEGER\r\n');
                fprintf(fileID, 'START_BYTE = 1\r\n');
                fprintf(fileID, 'BYTES = 3\r\n');
                fprintf(fileID, 'DESCRIPTION = "APPLIED VOLTAGE BIAS P1 AND P2 [TM UNITS]"\r\n');
                fprintf(fileID, 'END_OBJECT = COLUMN\r\n');
                fprintf(fileID, 'OBJECT = COLUMN\r\n');
                fprintf(fileID, 'NAME = P1_CURRENT\r\n');
                fprintf(fileID, 'DATA_TYPE = ASCII_INTEGER\r\n');
                fprintf(fileID, 'START_BYTE = 5\r\n');
                fprintf(fileID, 'BYTES = 6\r\n');
                fprintf(fileID, 'DESCRIPTION = "INSTRUMENT OFFSET [TM UNITS]"\r\n');
                fprintf(fileID, 'END_OBJECT = COLUMN\r\n');
                fprintf(fileID, 'OBJECT = COLUMN\r\n');
                fprintf(fileID, 'NAME = P2_CURRENT\r\n');
                fprintf(fileID, 'DATA_TYPE = ASCII_INTEGER\r\n');
                fprintf(fileID, 'START_BYTE = 12\r\n');
                fprintf(fileID, 'BYTES = 6\r\n');
                fprintf(fileID, 'DESCRIPTION = "INSTRUMENT OFFSET [TM UNITS]"\r\n');
                fprintf(fileID, 'END_OBJECT = COLUMN\r\n');
                fprintf(fileID, 'END_OBJECT = TABLE\r\n');
                fprintf(fileID, 'END\r\n');
                
            fclose(fileID);
            
            fileID = fopen(filePathTAB, 'wt');

                for row = 1:256

                    fprintf(fileID, horzcat(sprintf('%03.0f', voltage(row)), ',', sprintf('%6.0f', currentP1(row)), ',', sprintf('%6.0f', currentP2(row)), '\r\n'));
                end

            fclose(fileID);
            
            fileID = fopen(filePath2TAB, 'wt');
            fprintf(fileID,'3rd order polynomial fit coefficients (current = aV^3+b*V^2+c*V+d), for Probe 1 and Probe 2 in TM units \r\n');
            fprintf(fileID,'P1grad3,P1grad2,P1grad1,P1grad0,P2grad3,P2grad2,P2grad1,P2grad0\r\n');       
            fprintf(fileID,'%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e,%14.7e\r\n',dataWrite.gradient3(dataWriteCounter,1),dataWrite.gradient2(dataWriteCounter,1),dataWrite.gradient1(dataWriteCounter,1),dataWrite.intercepts(dataWriteCounter,1),dataWrite.gradient3(dataWriteCounter,2),dataWrite.gradient2(dataWriteCounter,2),dataWrite.gradient1(dataWriteCounter,2),dataWrite.intercepts(dataWriteCounter,2));
            fclose(fileID);
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Displays the output summary.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    numberCalibration = dataWrite.count;
    numberOffset      = data.count;
    numberAnomaly     = length(find(data.anomaly));
    numberCold        = length(find(data.cold));
    numberGood        = numberOffset - numberCold - numberAnomaly;
    
    display('Progress: Work complete.   ');
    display('                           ');
    display('===========================');
    display('         SUMMARY           ');
    display('===========================');
    display('                           ');
    display(horzcat(' Calibration Files:', sprintf('%7.0f', numberCalibration)));
    display('                           ');
    display('                           ');
    display(horzcat(' Offset Files:     ', sprintf('%7.0f', numberOffset)));
    display('                           ');
    display(horzcat('    Anomalies:     ', sprintf('%7.0f', numberAnomaly)));
    display('                           ');
    display(horzcat('         Cold:     ', sprintf('%7.0f', numberCold)));
    display('                           ');
    display(horzcat('         Good:     ', sprintf('%7.0f', numberGood)));
    display('                           ');
    display('===========================');
    display('                           ');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Determines wether to supply the offset data as output argument.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargout == 1
        
        varargout(1) = {data};
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
