% geometry.m -- create daily geometry file
%
% Assumes index has been generated and exists in workspace

% anders.eriksson@irfu.se 2012-03-29

% Path to geometry files:
gpath = 'geofiles/';

% Define file start times:
t0 = [index.t0]';

% Find days for which data exist in archive:
%   (need not be consecutive)
dayjumps = find(diff(floor(t0)));
days = floor(t0(1));
if(~isempty(dayjumps))
  days = [days; floor(t0(dayjumps+1))];
end
ndays = length(days); % Number of days with data

for d = 1:ndays % Create daily geometry files
    day = days(d);
    fprintf(1,'Processing %s...\n',datestr(day,1));
    m = min(find(floor(t0) == day));
    n = max(find(floor(t0) == day));
    
    % All file start times during day d
    t = t0(m:n); 
  
    % Start and stop s/c clock for later use when writing label:
    sct0 = index(m).sct0str;
    sct1 = index(n).sct0str; % Note: should not be sct1str (geometry calculated for start of data file)
    
    % Only use times differing > 16 s (others considered duplicated):
    ind = find(diff(t) > 16/86400);
    ind = [1; ind+1];
    gt = t(ind);
    
    % Write these times to file gtimes.txt:
    tf = fopen('gtimes.txt','w');
    for i=1:length(gt)
        %fprintf(tf,'%sT%s\n',datestr(gt(i),29),datestr(gt(i),13));
        fprintf(tf,'%sT%s\n',datestr(gt(i),29),datestr(gt(i),'HH:MM:SS.FFF'));
    end
    fclose(tf);
    
    % Geometry file name:
    gtname = sprintf('RPCLAP%s_%d_GEOM.TAB',datestr(day,'yymmdd'),processlevel);
    glname = sprintf('RPCLAP%s_%d_GEOM.LBL',datestr(day,'yymmdd'),processlevel);
    
    % Upload gtimes, call geometry routines and make raw version of daily geometry file:
    fprintf(1,'Uploading gtimes...\n');
    str1 = sprintf('scp -P 431 gtimes.txt %s@vroom.umea.irf.se:.',ume_user);
    unix(str1);
    fprintf(1,'Running SPICE...\n');
    str = sprintf('ssh -p 431 %s@vroom.umea.irf.se ''ros_spice_pds -target %s -list gtimes.txt -noverbose'' > gout.txt',ume_user,target);
    unix(str);
    % unix('rm gtimes.txt');

    % Reformat raw file to final geometry tab file:
    gr = fopen('gout.txt','r');
    gt = fopen(strcat(gpath,gtname),'w');
    r = fgetl(gr);
    ir = 0;
    gtime0 = sprintf('%s-%s-%sT%s:%s:%s.%s',r(1:4),r(5:6),r(7:8),r(12:13),r(14:15),r(16:17),r(22:24));
    while(ischar(r))
      gtime1 = sprintf('%s-%s-%sT%s:%s:%s.%s',r(1:4),r(5:6),r(7:8),r(12:13),r(14:15),r(16:17),r(22:24));
      fprintf(gt,'%s',gtime1);
      rr = sscanf(r(29:length(r)),'%f');
      if(fix_geom_bug)
        % Fix to get positions and velocity of s/c wrt target, not the reverse:
        rr(1:9) = -rr(1:9);
      end
      for(rrr=1:22)
        fprintf(gt,', %16f',rr(rrr));
      end
      fprintf(gt,'\n');
      ir = ir+1;
      r = fgetl(gr);
    end
    fclose(gr);
    fclose(gt);
    unix('rm gout.txt');
    str = sprintf('todos %s',strcat(gpath,gtname));
    unix(str);  % unix2dos on tab file
 
    % Write label file:
    gl = fopen(strcat(gpath,glname),'w');
    fprintf(gl,'PDS_VERSION_ID = PDS3\n');
    fprintf(gl,'RECORD_TYPE = FIXED_LENGTH\n');
    fprintf(gl,'RECORD_BYTES = 422\n');  % Now counting linefeed
    fprintf(gl,'FILE_RECORDS = %d\n',ir);
    fprintf(gl,'FILE_NAME = "%s"\n',glname);
    fprintf(gl,'^TABLE = "%s"\n',gtname);
    fprintf(gl,'DATA_SET_ID = "%s"\n',datasetid);
    fprintf(gl,'DATA_SET_NAME = "%s"\n',datasetname);
    fprintf(gl,'DATA_QUALITY_ID = 1\n');
    fprintf(gl,'MISSION_ID = ROSETTA\n');
    fprintf(gl,'MISSION_NAME = "INTERNATIONAL ROSETTA MISSION"\n');
    fprintf(gl,'MISSION_PHASE_NAME = "%s"\n',missionphase);
    fprintf(gl,'PRODUCER_INSTITUTION_NAME = "SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"\n');
    fprintf(gl,'PRODUCER_ID = RG\n');
    fprintf(gl,'PRODUCER_FULL_NAME = "REINE GILL"\n');
    fprintf(gl,'LABEL_REVISION_NOTE = "%s, %s, %s"\n',lbltime,lbleditor,lblrev);
    mm = length(gtname);
    fprintf(gl,'PRODUCT_ID = "%s"\n',gtname(1:(mm-4)));
    fprintf(gl,'PRODUCT_TYPE = "EDR"\n');  % No idea what this means...
    fprintf(gl,'PRODUCT_CREATION_TIME = %s\n',datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'));
    fprintf(gl,'INSTRUMENT_HOST_ID = RO\n');
    fprintf(gl,'INSTRUMENT_HOST_NAME = "ROSETTA-ORBITER"\n');
    fprintf(gl,'INSTRUMENT_NAME = "ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"\n');
    fprintf(gl,'INSTRUMENT_ID = RPCLAP\n');
    fprintf(gl,'INSTRUMENT_TYPE = "PLASMA INSTRUMENT"\n');
    fprintf(gl,'INSTRUMENT_MODE_ID = "N/A"\n');
    fprintf(gl,'TARGET_NAME = "%s"\n',targetfullname);
    fprintf(gl,'TARGET_TYPE = "%s"\n',targettype);
    fprintf(gl,'PROCESSING_LEVEL_ID = %d\n',processlevel);
    fprintf(gl,'START_TIME = %s\n',gtime0); 
    fprintf(gl,'STOP_TIME = %s\n',gtime1);
    fprintf(gl,'SPACECRAFT_CLOCK_START_COUNT = %s\n',sct0);
    fprintf(gl,'SPACECRAFT_CLOCK_STOP_COUNT =  %s\n',sct1);
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = TABLE\n');
    fprintf(gl,'NAME = "RPCLAP-%d-%s-GEOM"\n',processlevel,shortphase);
    fprintf(gl,'INTERCHANGE_FORMAT = ASCII\n');
    fprintf(gl,'ROWS = %d\n',ir);
    fprintf(gl,'COLUMNS = 23\n');
    fprintf(gl,'ROW_BYTES = 422\n');
    fprintf(gl,'DESCRIPTION = "GEOMETRY DATA. TIME AND 22 GEOMETRY PARAMETERS."\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = TIME_UTC\n');
    fprintf(gl,'DATA_TYPE = TIME\n');
    fprintf(gl,'START_BYTE = 1\n');
    fprintf(gl,'BYTES = 23\n');
    fprintf(gl,'UNIT = SECONDS\n');
    fprintf(gl,'DESCRIPTION = "TIME OF GEOMETRY DATA YYYY-MM-DDTHH:MM:SS.sss"\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_SUN_POS_X\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 26\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km"\n');
    fprintf(gl,'DESCRIPTION = "HELIOCENTRIC ECLIPJ2000 POSITION X"\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_SUN_POS_Y\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 44\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km"\n');
    fprintf(gl,'DESCRIPTION = "HELIOCENTRIC ECLIPJ2000 POSITION Y"\n'); 
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_SUN_POS_Z\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 62\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km"\n');
    fprintf(gl,'DESCRIPTION = "HELIOCENTRIC ECLIPJ2000 POSITION Z"\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_TGT_POS_X\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 80\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km"\n');
    fprintf(gl,'DESCRIPTION = "TARGET CENTRED ECLIPJ2000 POSITION X. ZERO WHEN NO TARGET."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_TGT_POS_Y\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 98\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km"\n');
    fprintf(gl,'DESCRIPTION = "TARGET CENTRED ECLIPJ2000 POSITION Y. ZERO WHEN NO TARGET."\n'); 
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_TGT_POS_Z\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 116\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km"\n');
    fprintf(gl,'DESCRIPTION = "TARGET CENTRED ECLIPJ2000 POSITION Z. ZERO WHEN NO TARGET."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_TGT_VEL_X\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 134\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km/s"\n');
    fprintf(gl,'DESCRIPTION = "ECLIPJ2000 VELOCITY X RELATIVE TO TARGET. ZERO WHEN NO TARGET."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_TGT_VEL_Y\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 152\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km/s"\n');
    fprintf(gl,'DESCRIPTION = "ECLIPJ2000 VELOCITY Y RELATIVE TO TARGET. ZERO WHEN NO TARGET."\n'); 
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_TGT_VEL_Z\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 170\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km/s"\n');
    fprintf(gl,'DESCRIPTION = "ECLIPJ2000 VELOCITY Z RELATIVE TO TARGET. ZERO WHEN NO TARGET."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = ALTITUDE\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 188\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km"\n');
    fprintf(gl,'DESCRIPTION = "DISTANCE TO SURFACE OF CURRENT TARGET. ZERO WHEN NO TARGET."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = LATITUDE\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 206\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "degrees"\n');
    fprintf(gl,'DESCRIPTION = "LATITUDE ON SURFACE OF CURRENT TARGET. ZERO WHEN NO TARGET."\n'); 
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = LONGITUDE\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 224\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "degrees"\n');
    fprintf(gl,'DESCRIPTION = "LONGITUDE ON SURFACE OF CURRENT TARGET. ZERO WHEN NO TARGET."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_TGT_SPEED\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 242\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "km/s"\n');
    fprintf(gl,'DESCRIPTION = "SPEED RELATIVE TO CURRENT TARGET. ZERO WHEN NO TARGET."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_X_ECLIPJ2000FR_X\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 260\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "N/A"\n');
    fprintf(gl,'DESCRIPTION = "SPACECRAFT FRAME X EXPRESSED IN ECLIPTIC J2000 FRAME X."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_X_ECLIPJ2000FR_Y\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 278\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "N/A"\n');
    fprintf(gl,'DESCRIPTION = "SPACECRAFT FRAME X EXPRESSED IN ECLIPTIC J2000 FRAME Y."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_X_ECLIPJ2000FR_Z\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 296\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "N/A"\n');
    fprintf(gl,'DESCRIPTION = "SPACECRAFT FRAME X EXPRESSED IN ECLIPTIC J2000 FRAME Z."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_Y_ECLIPJ2000FR_X\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 314\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "N/A"\n');
    fprintf(gl,'DESCRIPTION = "SPACECRAFT FRAME Y EXPRESSED IN ECLIPTIC J2000 FRAME X."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_Y_ECLIPJ2000FR_Y\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 332\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "N/A"\n');
    fprintf(gl,'DESCRIPTION = "SPACECRAFT FRAME Y EXPRESSED IN ECLIPTIC J2000 FRAME Y."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_Y_ECLIPJ2000FR_Z\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 350\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "N/A"\n');
    fprintf(gl,'DESCRIPTION = "SPACECRAFT FRAME Y EXPRESSED IN ECLIPTIC J2000 FRAME Z."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_Z_ECLIPJ2000FR_X\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 368\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "N/A"\n');
    fprintf(gl,'DESCRIPTION = "SPACECRAFT FRAME Z EXPRESSED IN ECLIPTIC J2000 FRAME X."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_Z_ECLIPJ2000FR_Y\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 386\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "N/A"\n');
    fprintf(gl,'DESCRIPTION = "SPACECRAFT FRAME Z EXPRESSED IN ECLIPTIC J2000 FRAME Y."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'OBJECT = COLUMN\n');
    fprintf(gl,'NAME = SC_Z_ECLIPJ2000FR_Z\n');
    fprintf(gl,'DATA_TYPE = ASCII_REAL\n');
    fprintf(gl,'START_BYTE = 404\n');
    fprintf(gl,'BYTES = 16\n');
    fprintf(gl,'UNIT = "N/A"\n');
    fprintf(gl,'DESCRIPTION = "SPACECRAFT FRAME Z EXPRESSED IN ECLIPTIC J2000 FRAME Z."\n');
    fprintf(gl,'END_OBJECT  = COLUMN\n');
    fprintf(gl,'\n');
    fprintf(gl,'END_OBJECT = TABLE\n');
    fprintf(gl,'\n');
    fprintf(gl,'END');
    fclose(gl);
    str = sprintf('todos %s',strcat(gpath,glname));
    unix(str);  % unix2dos on lbl file

    % Copy geometry file and label to original data set directory:
    if(export_geometry)
      switch(processlevel)
      case 2
         levstr = 'EDITED';
      case 3
         levstr = 'CALIBRATED';
      end
      dstr = datestr(day);
      pth = strcat('/',dstr(8:11),'/',upper(dstr(4:6)),'/D',dstr(1:2));
      ptht = sprintf('cp %s %s/DATA/%s%s/%s',strcat(gpath,gtname),archivepath,levstr,pth,gtname);
      pthl = sprintf('cp %s %s/DATA/%s%s/%s',strcat(gpath,glname),archivepath,levstr,pth,glname);
      unix(ptht);
      unix(pthl);
    end

end  % End of day loop

% End of geometry.m
