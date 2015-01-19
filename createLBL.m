%createLBL.m
%CREATE .LBL FILES, FROM PREVIOUS LBL FILES


strnow = datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF');

% "Constants"
NO_ODL_UNIT = [];   % Constant to be used for LBL "UNIT" fields meaning that there is no unit. To distinguish that it is know that the quantity has no unit rather than that the unit is unknown at present.
ODL_VALUE_UNKNOWN = [];   %'<Unknown>';
            


if(~isempty(tabindex));
    len= length(tabindex(:,3));
    
    for(i=1:len)
        try

            %tabindex cell array = {tab file name, first index number of batch,
            % UTC time of last row, S/C time of last row, row counter}
            %    units: [cell array] =  {[string],[double],[string],[float],[integer]

            % Write label file:
            tname = tabindex{i,2};
            lname=strrep(tname,'TAB','LBL');
            Pnum = tname(end-5);

            fid = fopen(strrep(tabindex{i,1},'TAB','LBL'),'w');   % Open DERIV LBL file to create/write to.
            %         if fid < 0
            %             fprintf(1,'Error, cannot open file %s', strrep(tabindex{i,1},'TAB','LBL'));
            %             break
            %         end % if I/O error
            
%             %------------------------------------------------------------------------------------------------------
%             % Read CALIB LBL file.
%             [fp,errmess] = fopen(index(tabindex{i,3}).lblfile,'r');
%             if fp < 0
%                 fprintf(1,'Error, cannot open file %s', index(tabindex{i,3}).lblfile);
%                 break
%             end % if I/O error
%             tempfp = textscan(fp,'%s %s','Delimiter','=');
%             fclose(fp);
% 
% 
%             %This version is not very pretty, but efficient. It reads the first LBL
%             %file of the mode in the batch and edits line for line. Sometimes
%             %copying some lines and pasting them in the correct position, from
%             %bottom to top (to prevent unwanted overwrites).
%             
%             %Assuming no changes to line number order (!!!!)
% 
%             fileinfo = dir(tabindex{i,1});
%             tempfp{1,2}{3,1}  = sprintf('%d',fileinfo.bytes);   % RECORD_BYTES
%             tempfp{1,2}{4,1}  = sprintf('%d',tabindex{i,6});    % FILE_RECORDS
%             tempfp{1,2}{5,1}  = lname;    % FILE_NAME
%             tempfp{1,2}{6,1}  = tname;    % ^TABLE
%             tempfp{1,2}{7,1}  = strrep(tempfp{1,2}{7,1},sprintf('-3-%s-CALIB',shortphase),sprintf('-5-%s-DERIV',shortphase));   % DATA_SET_ID
%             tempfp{1,2}{8,1}  = strrep(tempfp{1,2}{8,1},sprintf('3 %s CALIB',shortphase),sprintf('5 %s DERIV',shortphase));    % DATA_SET_NAME
%             tempfp{1,2}{14,1} = producershortname;                      % PRODUCER_ID
%             tempfp{1,2}{15,1} = sprintf('"%s"',producerfullname);      % PRODUCER_FULL_NAME
%             %%%%%%    tempfp{1,2}{16,1} = sprintf('"%s, %s, %s"',lbltime,lbleditor,lblrev);  LABEL_REVISION_NOTE
%             tempfp{1,2}{17} = tname(1:end-4);     % PRODUCT_ID
%             tempfp{1,2}{18} = '"DDR"';          % PRODUCT_TYPE
%             tempfp{1,2}{19,1} = strnow; %product creation time  PRODUCT_CREATION_TIME    
%             tempfp{1,2}{29,1} = '"5"'; %% processing level ID     PROCESSING_LEVEL_ID
%             tempfp{1,2}{30,1} = index(tabindex{i,3}).t0str(1:23); %UTC start time    START_TIME 
%             tempfp{1,2}{31,1} = tabindex{i,4}(1:23);             % UTC stop time      STOP_TIME
%             %%%%%% tmpsct0 = index(tabindex{i,3}).sct0str(5:end-1);
%             %%%%%% tempfp{1,2}{32,1} = strcat(index(tabindex{i,3}).sct0str(1:end-1),'"');  %% sc start time   SPACECRAFT_CLOCK_START_COUNT
%             tempfp{1,2}{32,1} = index(tabindex{i,3}).sct0str;     % SPACECRAFT_CLOCK_START_COUNT
%             tempfp{1,2}{33,1} = sprintf('"%s/%014.3f"',index(tabindex{i,3}).sct0str(2),obt2sct(tabindex{i,5})); % SPACECRAFT_CLOCK_STOP_COUNT  get resetcount from above, and calculate obt from sct
%             %%%%%% tempfp{1,2}{33,1} = obt2sct(tabindex{i,5},scResetCount);
%             %%%%%% tempfp{1,2}{33,1} = sprintf('"%s/%017.6f"',index(tabindex{i,3}).sct0str(2),tabindex{i,5}); %% sc stop time
%             %%%%%%   tempfp{1,2}{56,1} = sprintf('%i',tabindex{i,6}); %% rows    ROSETTA:LAP_P1P2_ADC20_MA_LENGTH!!
%             % -----------
%             ind = find(ismember(strrep(tempfp{1,1}, ' ', ''), 'ROWS'));  % lots of whitespace often
%             tempfp{1,2}{ind,1} = sprintf('%i', tabindex{i,6});          % ROWS
%             colind = find(ismember(strrep(tempfp{1,2}, ' ', ''), 'TABLE')); % find table start and end
%             %---------------------------------------------------------------------------------------
            fileinfo = dir(tabindex{i,1});
            [CALIB_LBL_str, CALIB_LBL_struct] = createLBL_read_ODL_to_structs(index(tabindex{i,3}).lblfile);   % Read CALIB LBL file.         
            CALIB_LBL_kvl = [];
            CALIB_LBL_kvl.keys   = CALIB_LBL_str.keys(1:end-1);    % NOTE: CALIB_LBL_str includes OBJECT = TABLE as last key-value pair.
            CALIB_LBL_kvl.values = CALIB_LBL_str.values(1:end-1);
            DATA_SET_ID   = createLBL_read_kv_value(CALIB_LBL_kvl, 'DATA_SET_ID');
            DATA_SET_NAME = createLBL_read_kv_value(CALIB_LBL_kvl, 'DATA_SET_NAME');
            DATA_SET_ID   = strrep(DATA_SET_ID,   sprintf('-3-%s-CALIB', shortphase), sprintf('-5-%s-DERIV', shortphase));
            DATA_SET_NAME = strrep(DATA_SET_NAME, sprintf('3 %s CALIB',  shortphase), sprintf('5 %s DERIV',  shortphase));
            SPACECRAFT_CLOCK_STOP_COUNT = sprintf('"%s/%014.3f"', index(tabindex{i,3}).sct0str(2), obt2sct(tabindex{i,5})); % get resetcount from above, and calculate obt from sct
            LBL_kvl_set = [];
            LBL_kvl_set.keys = {};
            LBL_kvl_set.values = {};
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'RECORD_BYTES',  num2str(fileinfo.bytes));
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'FILE_RECORDS',  num2str(tabindex{i,6}));
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'FILE_NAME',     lname);
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, '^TABLE',        tname);
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'DATA_SET_ID',   DATA_SET_ID);
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'DATA_SET_NAME', DATA_SET_NAME);
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'PRODUCER_ID',   producershortname);
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'PRODUCER_FULL_NAME',    sprintf('"%s"', producerfullname));
            %LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'LABEL_REVISION_NOTE', sprintf('"%s, %s, %s"',lbltime,lbleditor,lblrev));  % 
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'PRODUCT_ID',            tname(1:end-4));
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'PRODUCT_TYPE',          '"DDR"');
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'PRODUCT_CREATION_TIME', strnow);
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'PROCESSING_LEVEL_ID',   '"5"');
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'START_TIME',            index(tabindex{i,3}).t0str(1:23)); % UTC start time
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'STOP_TIME',             tabindex{i,4}(1:23));              % UTC stop time
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'SPACECRAFT_CLOCK_START_COUNT', index(tabindex{i,3}).sct0str);
            LBL_kvl_set = createLBL_add_new_kv_pair(LBL_kvl_set, 'SPACECRAFT_CLOCK_STOP_COUNT',  SPACECRAFT_CLOCK_STOP_COUNT);
            LBL_kvl = createLBL_set_values_for_selected_preexisting_keys(CALIB_LBL_kvl, LBL_kvl_set);
            createLBL_write_LBL_header(fid, LBL_kvl)
            

            if (tname(30)=='S')     % special format for sweep files...

                
                if (tname(28)=='B')

                    OBJTABLE_data = [];
                    OBJTABLE_data.ROWS        = tabindex{i, 6};
                    OBJTABLE_data.COLUMNS     = tabindex{i, 7};
                    OBJTABLE_data.ROW_BYTES   = 30;                       % NOTE: HARDCODED! TODO: Fix.
                    %OBJTABLE_data.ROW_BYTES   = tabindex{i, 8};          % Does not work!
                    OBJTABLE_data.DESCRIPTION = sprintf('%s Sweep step bias and time between each step', CALIB_LBL_struct.OBJECT___TABLE{1}.DESCRIPTION);
                    ocl = [];
                    ocl{end+1} = struct('NAME', 'SWEEP_TIME',                 'FORMAT', 'E14.7', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'SECONDS', 'DESCRIPTION', 'LAPSED TIME (S/C CLOCK TIME) FROM FIRST SWEEP MEASUREMENT');
                    ocl{end+1} = struct('NAME', sprintf('P%s_VOLTAGE', Pnum), 'FORMAT', 'E14.7', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'VOLT',    'DESCRIPTION', 'CALIBRATED VOLTAGE BIAS');
                    OBJTABLE_data.OBJCOL_list = ocl;   
                    createLBL_writeObjectTable(fid, OBJTABLE_data)

                else %% if tname(28) =='I'

                    Bfile = tname;
                    Bfile(28) = 'B';
                    
                    OBJTABLE_data = [];
                    OBJTABLE_data.ROWS        = tabindex{i, 6};
                    OBJTABLE_data.COLUMNS     = tabindex{i, 7};
                    %OBJTABLE_data.ROW_BYTES   = 880;                   % NOTE: HARDCODED! TODO: Fix.
                    OBJTABLE_data.ROW_BYTES   = tabindex{i, 8};
                    %fprintf(1, 'fopen(fid) = %s\n',     fopen(fid))      % DEBUG
                    %fprintf(1, 'tabindex{i, 8} = %i\n', tabindex{i, 8})  % DEBUG
                    OBJTABLE_data.DESCRIPTION = sprintf('%s', CALIB_LBL_struct.OBJECT___TABLE{1}.DESCRIPTION);
                    OBJTABLE_data.DELIMITER = ', ';
                    ocl = [];
                    ocl{end+1} = struct('NAME', 'START_TIME_UTC',                   'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
                    ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',                    'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
                    ocl{end+1} = struct('NAME', 'START_TIME_OBT',                   'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
                    ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',                    'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION', 'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
                    ocl{end+1} = struct('NAME', 'QUALITY',                          'DATA_TYPE', 'ASCII_REAL', 'BYTES', 3,  'UNIT', 'N/A',     'DESCRIPTION', 'QUALITY FACTOR FROM 000(best) to 999');
                    ocl{end+1} = struct('NAME', sprintf('P%s_SWEEP_CURRENT', Pnum), 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'AMPERE', 'ITEMS', tabindex{i,7}-5, 'FORMAT', 'E14.7', ...
                        'DESCRIPTION', sprintf('Averaged current measured of potential sweep, at different potential steps as described by %s', Bfile));
                    
                    OBJTABLE_data.OBJCOL_list = ocl;
                    createLBL_writeObjectTable(fid, OBJTABLE_data)
                end


            else     % if anything but a sweep file

                
                OBJTABLE_data = [];
                OBJTABLE_data.ROWS        = tabindex{i, 6};
                %OBJTABLE_data.COLUMNS     = tabindex{i, 7};   % Does not work. Value (tabindex{...}) can be empty.
                OBJTABLE_data.COLUMNS     = 5;                % NOTE: Hardcoded. TODO: Fix!
                OBJTABLE_data.DESCRIPTION = CALIB_LBL_struct.OBJECT___TABLE{1}.DESCRIPTION;    % BUG: Possibly double quotation marks.
                %OBJTABLE_data.DELIMITER = ', ';
                if Pnum ~= '3'
                    OBJTABLE_data.ROW_BYTES = 82;
                else
                    OBJTABLE_data.ROW_BYTES = 98;
                end                
                %OBJTABLE_data.ROW_BYTES   = tabindex{i, 8};    % Can be empty. ==> Does not work.
                
                % Recycle OBJCOL info/columns from CALIB LBL file and then add one.
                ocl = CALIB_LBL_struct.OBJECT___TABLE{1}.OBJECT___COLUMN;
                for i_oc = 1:length(ocl)
                    oc = ocl{i_oc};
                    ocl{i_oc} = rmfield(oc, 'START_BYTE');
                    
                    % Add UNIT for UTC_TIME since it does not seem to have it already in the CALIB LBL file.
                    if strcmp(oc.NAME, 'UTC_TIME') && ~isfield(oc, 'UNIT')
                        ocl{i_oc}.UNIT = 'SECONDS';
                    end
                end
                ocl{end+1} = struct('NAME', 'QUALITY', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 3, 'UNIT', NO_ODL_UNIT, ...
                    'DESCRIPTION', 'QUALITY FACTOR FROM 000(best) to 999');
                
                OBJTABLE_data.OBJCOL_list = ocl;
                createLBL_writeObjectTable(fid, OBJTABLE_data)
                %-----------------------------------------------------------------------------------

            end

            fprintf(fid,'END');
            fclose(fid);

        catch err
            
            fprintf(1,'\nlapdog:createLBL error message:%s\n',err.message);    
    
            len = length(err.stack);
            if (~isempty(len))
                for i=1:len
                    fprintf(1,'%s, %i,\n',err.stack(i).name,err.stack(i).line);
                end
            end
    
            fprintf(1,'\nlapdog: Skipping LBL file, continuing...\n');    
        end
    end
end

%% BLOCK LIST .LBL FILES

if(~isempty(blockTAB));
    len=length(blockTAB(:,3));
    for(i=1:len)
        
        tname = blockTAB{i,2};
        lname=strrep(tname,'TAB','LBL');
        fid = fopen(strrep(blockTAB{i,1},'TAB','LBL'),'w');
        
        fileinfo = dir(blockTAB{i,1});

        kvl = [];   % NOTE: Can not initialize with "struct(...)". That gives an unintended result due to a special interpretation for arrays.
        kvl.keys = {};
        kvl.values = {};
        kvl = createLBL_add_new_kv_pair(kvl, 'PDS_VERSION_ID', 'PDS3');
        kvl = createLBL_add_new_kv_pair(kvl, 'RECORD_TYPE',    'FIXED_LENGTH');
        kvl = createLBL_add_new_kv_pair(kvl, 'RECORD_BYTES',   sprintf('%i', fileinfo.bytes));
        kvl = createLBL_add_new_kv_pair(kvl, 'FILE_RECORDS',   sprintf('%i', blockTAB{i,3}));
        kvl = createLBL_add_new_kv_pair(kvl, 'FILE_NAME',      sprintf('"%s"', lname));
        kvl = createLBL_add_new_kv_pair(kvl, '^TABLE',         sprintf('"%s"', tname));
        kvl = createLBL_add_new_kv_pair(kvl, 'DATA_SET_ID',    ['"', strrep(datasetid,   sprintf('-3-%s-CALIB', shortphase), sprintf('-5-%s-DERIV', shortphase)), '"']);
        kvl = createLBL_add_new_kv_pair(kvl, 'DATA_SET_NAME',  ['"', strrep(datasetname, sprintf('3 %s CALIB',  shortphase),  sprintf('5 %s DERIV', shortphase)), '"']);
        
        kvl = createLBL_add_new_kv_pair(kvl, 'DATA_QUALITY_ID',           '1');
        kvl = createLBL_add_new_kv_pair(kvl, 'MISSION_ID',                'ROSETTA');
        kvl = createLBL_add_new_kv_pair(kvl, 'MISSION_NAME',              sprintf('"%s"', 'INTERNATIONAL ROSETTA MISSION'));
        kvl = createLBL_add_new_kv_pair(kvl, 'MISSION_PHASE_NAME',        sprintf('"%s"', missionphase));
        kvl = createLBL_add_new_kv_pair(kvl, 'PRODUCER_INSTITUTION_NAME', '"SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"');
        kvl = createLBL_add_new_kv_pair(kvl, 'PRODUCER_ID',               producershortname);
        kvl = createLBL_add_new_kv_pair(kvl, 'PRODUCER_FULL_NAME',        sprintf('"%s"', producerfullname));
        kvl = createLBL_add_new_kv_pair(kvl, 'LABEL_REVISION_NOTE',       sprintf('"%s, %s, %s"', lbltime, lbleditor, lblrev));
        
        kvl = createLBL_add_new_kv_pair(kvl, 'PRODUCT_ID',                sprintf('"%s"', tname(1:(end-4))));
        kvl = createLBL_add_new_kv_pair(kvl, 'PRODUCT_TYPE',              '"DDR"');
        kvl = createLBL_add_new_kv_pair(kvl, 'PRODUCT_CREATION_TIME',     strnow);
        kvl = createLBL_add_new_kv_pair(kvl, 'INSTRUMENT_HOST_ID',        'RO');
        kvl = createLBL_add_new_kv_pair(kvl, 'INSTRUMENT_HOST_NAME',      '"ROSETTA-ORBITER"');
        kvl = createLBL_add_new_kv_pair(kvl, 'INSTRUMENT_NAME',           '"ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"');
        kvl = createLBL_add_new_kv_pair(kvl, 'INSTRUMENT_ID',             'RPCLAP' );
        kvl = createLBL_add_new_kv_pair(kvl, 'INSTRUMENT_TYPE',           '"PLASMA INSTRUMENT"' );
        kvl = createLBL_add_new_kv_pair(kvl, 'TARGET_NAME',               sprintf('"%s"', targetfullname));
        kvl = createLBL_add_new_kv_pair(kvl, 'TARGET_TYPE',               sprintf('"%s"', targettype));
        kvl = createLBL_add_new_kv_pair(kvl, 'PROCESSING_LEVEL_ID',       '5');
        
        createLBL_write_LBL_header(fid, kvl)

        OBJTABLE_data = [];
        OBJTABLE_data.ROWS      = blockTAB{i,3};
        OBJTABLE_data.COLUMNS   = 3;
        OBJTABLE_data.ROW_BYTES = 54;                   % NOTE: HARDCODED! TODO: Fix.
        OBJTABLE_data.DESCRIPTION = 'BLOCKLIST DATA. START & STOP TIME OF MACROBLOCK AND MACROID.';    % BUG: Possibly double quotation marks.
        %OBJTABLE_data.DELIMITER = ', ';
        ocl = [];
        ocl{end+1} = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss');
        ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',  'DATA_TYPE', 'TIME',       'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'LAST START TIME OF MACRO BLOCK FILE YYYY-MM-DD HH:MM:SS.sss');
        ocl{end+1} = struct('NAME', 'MACRO_ID',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'MACRO IDENTIFICATION NUMBER');
        OBJTABLE_data.OBJCOL_list = ocl;
        createLBL_writeObjectTable(fid, OBJTABLE_data)
        
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
        
        
        if strcmp(an_tabindex{i,7}, 'best_estimates')
            
            try
                kvl = createLBL_create_EST_LBL_header(an_tabindex(i, :), index);
            catch exc
                fprintf(1, ['ERROR: ', exc.message])
                fprintf(1, exc.getReport)
                %break
                continue
            end
            
        else
            
            fileinfo = dir(an_tabindex{i,1});
            %fprintf(1, 'tabindex{i,3} = %s\n', tabindex{i,3});     % DEBUG
            %fprintf(1, 'length(tabindex{:,3}) = %i\n', length(tabindex{:,3}));     % DEBUG
            [CALIB_LBL_str, CALIB_LBL_struct] = createLBL_read_ODL_to_structs(index(an_tabindex{i,3}).lblfile);   % Read CALIB LBL file.         
            CALIB_LBL_kvl = [];
            CALIB_LBL_kvl.keys   = CALIB_LBL_str.keys(1:end-1);    % NOTE: CALIB_LBL_str includes OBJECT = TABLE as last key-value pair.
            CALIB_LBL_kvl.values = CALIB_LBL_str.values(1:end-1);            
            kvl_set = [];
            kvl_set.keys = {};
            kvl_set.values = {};
            kvl_set = createLBL_add_new_kv_pair(kvl_set, 'RECORD_BYTES',          num2str(fileinfo.bytes));
            kvl_set = createLBL_add_new_kv_pair(kvl_set, 'FILE_RECORDS',          num2str(an_tabindex{i,4}));
            kvl_set = createLBL_add_new_kv_pair(kvl_set, 'FILE_NAME',             lname);
            kvl_set = createLBL_add_new_kv_pair(kvl_set, '^TABLE',                tname);
            kvl_set = createLBL_add_new_kv_pair(kvl_set, 'PRODUCT_TYPE',          '"DDR"');
            kvl_set = createLBL_add_new_kv_pair(kvl_set, 'PROCESSING_LEVEL_ID',   '"5"' );
            kvl_set = createLBL_add_new_kv_pair(kvl_set, 'PRODUCT_CREATION_TIME', strnow);
            kvl = createLBL_set_values_for_selected_preexisting_keys(CALIB_LBL_kvl, kvl_set);

        end
        LBL_file_path = strrep(an_tabindex{i,1}, 'TAB', 'LBL');
        fid = fopen(LBL_file_path,'w');
        createLBL_write_LBL_header(fid, kvl)
        
        
        
        %% Customise the rest!
        %%% TAB FILE TYPE CUSTOMISATION
        
        if strcmp(an_tabindex{i,7},'downsample') %%%%%%%%DOWNSAMPLED FILE%%%%%%%%%%%%%%%
            
           
            
            OBJTABLE_data = [];
            OBJTABLE_data.ROWS      = an_tabindex{i,4};
            OBJTABLE_data.ROW_BYTES = an_tabindex{i,9};
            OBJTABLE_data.COLUMNS = an_tabindex{i,5};
            OBJTABLE_data.DESCRIPTION = sprintf('"%s %s SECONDS DOWNSAMPLED"', CALIB_LBL_struct.DESCRIPTION, lname(end-10:end-9));
            %OBJTABLE_data.DELIMITER   = ', ';
            ocl = {};
            ocl{end+1} = struct('NAME', 'TIME_UTC',                          'UNIT', 'SECONDS',   'BYTES', 23, 'DATA_TYPE', 'TIME',                          'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl{end+1} = struct('NAME', 'OBT_TIME',                          'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',                    'DESCRIPTION', 'SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
            ocl{end+1} = struct('NAME', sprintf('P%s_CURRENT', Pnum),        'UNIT', 'AMPERE',    'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'AVERAGED CURRENT');
            ocl{end+1} = struct('NAME', sprintf('P%s_CURRENT_STDDEV', Pnum), 'UNIT', 'AMPERE',    'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'CURRENT STANDARD DEVIATION');
            ocl{end+1} = struct('NAME', sprintf('P%s_VOLT', Pnum),           'UNIT', 'VOLT',      'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'AVERAGED MEASURED VOLTAGE');
            ocl{end+1} = struct('NAME', sprintf('P%s_VOLT_STDDEV', Pnum),    'UNIT', 'VOLT',      'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', 'VOLTAGE STANDARD DEVIATION');
            ocl{end+1} = struct('NAME', 'QUALITY',                           'UNIT', NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL',                    'DESCRIPTION', 'QUALITY FACTOR FROM 000(best) to 999');
            OBJTABLE_data.OBJCOL_list = ocl;
            createLBL_writeObjectTable(fid, OBJTABLE_data)
            fprintf(fid,'END');
            
            
            
        elseif strcmp(an_tabindex{i,7},'spectra') %%%%%%%%%%%%%%%%SPECTRA FILE%%%%%%%%%%
            
            
                    
            OBJTABLE_data = [];
            OBJTABLE_data.ROWS      = an_tabindex{i,4};
            OBJTABLE_data.COLUMNS   = an_tabindex{i,5};
            OBJTABLE_data.ROW_BYTES = an_tabindex{i,9};
            OBJTABLE_data.DESCRIPTION = sprintf('%s PSD SPECTRA OF HIGH FREQUENCY MEASUREMENT', mode);
            OBJTABLE_data.DELIMITER   = ', ';
            %---------------------------------------------
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_UTC', 'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_UTC',  'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'SPECTRA STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_OBT', 'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_OBT',  'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT)');
            ocl1{end+1} = struct('NAME', 'QUALITY',                'UNIT', NO_ODL_UNIT, 'BYTES', 3,  'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'QUALITY FACTOR FROM 000(best) to 999');
            %---------------------------------------------
            ocl2 = {};
            if strcmp(mode(1),'I')
                
                if Pnum=='3'
                    ocl2{end+1} = struct('NAME', 'P1-P2_CURRENT MEAN',                                 'UNIT', 'VOLT',            'DESCRIPTION', 'BIAS VOLTAGE');
                    ocl2{end+1} = struct('NAME', 'P1_VOLT',                                            'UNIT', 'VOLT',            'DESCRIPTION', 'BIAS VOLTAGE');
                    ocl2{end+1} = struct('NAME', 'P2_VOLT',                                            'UNIT', 'VOLT',            'DESCRIPTION', 'BIAS VOLTAGE');
                    ocl2{end+1} = struct('NAME', sprintf('PSD_%s', mode), 'ITEMS', an_tabindex{i,5}-7, 'UNIT', ODL_VALUE_UNKNOWN, 'DESCRIPTION', 'PSD CURRENT SPECTRUM');
                else                    
                    ocl2{end+1} = struct('NAME', sprintf('P%s_CURRENT_MEAN', Pnum),                    'UNIT', 'AMPERE',          'DESCRIPTION', 'CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('P%s_VOLT_MEAN', Pnum),                       'UNIT', 'VOLT',            'DESCRIPTION', 'VOLTAGE MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('PSD_%s', mode), 'ITEMS', an_tabindex{i,5}-7, 'UNIT', ODL_VALUE_UNKNOWN, 'DESCRIPTION', 'PSD CURRENT SPECTRUM');
                end
                
            elseif strcmp(mode(1),'V')
                
                if Pnum=='3'
                    ocl2{end+1} = struct('NAME', 'P1_CURRENT_MEAN',                                   'UNIT', 'AMPERE',          'DESCRIPTION', 'CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', 'P2_CURRENT_MEAN',                                   'UNIT', 'AMPERE',          'DESCRIPTION', 'CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', 'P1-P2 VOLTAGE MEAN',                                'UNIT', 'VOLT',            'DESCRIPTION', 'MEAN VOLTAGE DIFFERENCE');
                    ocl2{end+1} = struct('NAME', sprintf('PSD_%s',mode), 'ITEMS', an_tabindex{i,5}-7, 'UNIT', ODL_VALUE_UNKNOWN, 'DESCRIPTION', 'PSD VOLTAGE SPECTRUM');
                else
                    ocl2{end+1} = struct('NAME', sprintf('P%s_CURRENT', Pnum),                        'UNIT', 'AMPERE',          'DESCRIPTION', 'CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('P%s_VOLT_MEAN', Pnum),                      'UNIT', 'VOLT',            'DESCRIPTION', 'VOLTAGE MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('PSD_%s',mode), 'ITEMS', an_tabindex{i,5}-7, 'UNIT', ODL_VALUE_UNKNOWN, 'DESCRIPTION', 'PSD VOLTAGE SPECTRUM');
                end                
                
            else
                fprintf(1,'error, bad mode identifier in an_tabindex{%i,1}',i);
            end
            for i_oc = 1:length(ocl2)
                ocl2{i_oc}.BYTES     = 14;
                ocl2{i_oc}.DATA_TYPE = 'ASCII_REAL';
                ocl2{i_oc}.FORMAT    = 'E14.7';
            end

            OBJTABLE_data.OBJCOL_list = [ocl1, ocl2];
            createLBL_writeObjectTable(fid, OBJTABLE_data)
            fprintf(fid,'END');
            
            
            
        elseif  strcmp(an_tabindex{i,7},'frequency')    %%%%%%%%%%%% FREQUENCY FILE %%%%%%%%%
            
            
            
            psdname = strrep(an_tabindex{i,2},'FRQ','PSD');
            
            OBJTABLE_data = [];
            OBJTABLE_data.ROWS      = an_tabindex{i,4};
            OBJTABLE_data.COLUMNS   = an_tabindex{i,5};
            OBJTABLE_data.ROW_BYTES = an_tabindex{i,9};
            OBJTABLE_data.DESCRIPTION = 'FREQUENCY LIST OF PSD SPECTRA FILE';
            OBJTABLE_data.DELIMITER   = ', ';
            ocl = {};
            ocl{end+1} = struct('NAME', 'FREQUENCY LIST', 'ITEMS', an_tabindex{i,5}, 'UNIT', 'kHz', 'BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', 'FORMAT', 'E14.7', 'DESCRIPTION', sprintf('FREQUENCY LIST OF PSD SPECTRA FILE %s', psdname));
            OBJTABLE_data.OBJCOL_list = ocl;            
            createLBL_writeObjectTable(fid, OBJTABLE_data)            
            fprintf(fid,'END');
            
            
            
        elseif  strcmp(an_tabindex{i,7},'sweep')    %%%%%%%%%%%% SWEEP ANALYSIS FILE %%%%%%%%%
            
            
            
            OBJTABLE_data = [];
            OBJTABLE_data.ROWS      = an_tabindex{i,4};
            OBJTABLE_data.COLUMNS   = an_tabindex{i,5};
            OBJTABLE_data.ROW_BYTES = an_tabindex{i,9};
            OBJTABLE_data.DESCRIPTION = sprintf('MODEL FITTED ANALYSIS OF %s SWEEP FILE',tabindex{an_tabindex{i,6},2});

            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'START_TIME(UTC)', 'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Start time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'STOP_TIME(UTC)',  'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Stop time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'START_TIME_OBT',  'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Start time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_OBT',   'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Stop time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');            
            ocl1{end+1} = struct('NAME', 'Qualityfactor',   'UNIT', NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Quality factor from 0-100');
            ocl1{end+1} = struct('NAME', 'SAA',             'UNIT', 'degrees',   'BYTES',  7, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Solar aspect angle from x-axis of spacecraft');
            ocl1{end+1} = struct('NAME', 'Illumination',    'UNIT', NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl1{end+1} = struct('NAME', 'direction',       'UNIT', NO_ODL_UNIT, 'BYTES',  1, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            % -- (Changing from ocl1 to ocl2.) --
            ocl2 = {};
            ocl2{end+1} = struct('NAME', 'old.Vsi',                'UNIT', 'V',     'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old.Vx',                 'UNIT', 'V',     'DESCRIPTION', 'Spacecraft potential + Te from electron current fit. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vsg',                    'UNIT', 'V',     'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'sigma_Vsg',              'UNIT', 'V',     'DESCRIPTION', 'Standard deviation of spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'old.Tph',                'UNIT', 'eV',    'DESCRIPTION', 'Photoelectron temperature. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old.Iph0',               'UNIT', 'A',     'DESCRIPTION', 'Photosaturation current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vb_lastnegcurrent',      'UNIT', 'V',     'DESCRIPTION', 'bias potential below zero current.');
            ocl2{end+1} = struct('NAME', 'Vb_firstposcurrent',     'UNIT', 'V',     'DESCRIPTION', 'bias potential above zero current.');
            ocl2{end+1} = struct('NAME', 'Vbinfl',                 'UNIT', 'V',     'DESCRIPTION', 'Bias potential of inflection point in current.');
            ocl2{end+1} = struct('NAME', 'dIinfl',                 'UNIT', 'A/V',   'DESCRIPTION', 'Derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'd2Iinfl',                'UNIT', 'A/V^2', 'DESCRIPTION', 'Second derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'Iph0',                   'UNIT', 'A',     'DESCRIPTION', 'Photosaturation current.');
            ocl2{end+1} = struct('NAME', 'Tph',                    'UNIT', 'eV',    'DESCRIPTION', 'Photoelectron temperature.');
            ocl2{end+1} = struct('NAME', 'Vsi',                    'UNIT', 'V',     'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current.');
            ocl2{end+1} = struct('NAME', 'Vph_knee',               'UNIT', 'V',     'DESCRIPTION', 'Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');            
            ocl2{end+1} = struct('NAME', 'sigma_Vph_knee',         'UNIT', 'V',     'DESCRIPTION', []);   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'Te_linear',              'UNIT', 'eV',    'DESCRIPTION', 'Electron temperature from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_linear',        'UNIT', 'eV',    'DESCRIPTION', []);   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'ne_linear',              'UNIT', 'cm^-3', 'DESCRIPTION', 'Electron (plasma) density from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_ne_linear',        'UNIT', 'cm^-3', 'DESCRIPTION', []);   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'ion_slope',              'UNIT', 'A/V',   'DESCRIPTION', 'Slope of ion current fit as a function of absolute potential.');            
            ocl2{end+1} = struct('NAME', 'sigma_ion_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of slope of ion current fit as a function of absolute potential');
            ocl2{end+1} = struct('NAME', 'ion_intersect',          'UNIT', 'A',         'DESCRIPTION', 'Y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'e_slope',                'UNIT', 'A/V',       'DESCRIPTION', 'Slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_slope',          'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'e_intersect',            'UNIT', 'A',         'DESCRIPTION', 'Y-intersection of linear electron current fit as a function of absolute potential ');
            ocl2{end+1} = struct('NAME', 'sigma_e_intersect',      'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'ion_Vb_intersect',       'UNIT', 'A',         'DESCRIPTION', 'Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_Vb_intersect', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'e_Vb_intersect',         'UNIT', 'A',         'DESCRIPTION', 'Y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_Vb_intersect',   'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable).');
            ocl2{end+1} = struct('NAME', 'nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable).');
            ocl2{end+1} = struct('NAME', 'phc_slope',              'UNIT', 'A/V',       'DESCRIPTION', 'Slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'phc_intersect',          'UNIT', 'A',         'DESCRIPTION', 'Y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'ne_5eV',                 'UNIT', 'cm^-3', 'DESCRIPTION', 'Electron density from linear electron current fit, assuming Te= 5eV.');
            ocl2{end+1} = struct('NAME', 'ni_v_dep',               'UNIT', 'cm^-3', 'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity');
            ocl2{end+1} = struct('NAME', 'ni_v_indep',             'UNIT', 'cm^-3', 'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate.');
            ocl2{end+1} = struct('NAME', 'v_ion',                  'UNIT', 'm/s',   'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate.');
            ocl2{end+1} = struct('NAME', 'Te_exp',                 'UNIT', 'eV',    'DESCRIPTION', 'Electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_exp',           'UNIT', 'eV',    'DESCRIPTION', 'Fractional error estimate of electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME', 'ne_exp',                 'UNIT', 'cm^-3', 'DESCRIPTION', 'Electron density derived from fit of exponential part of the thermal electron current.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'sigma_ne_exp',           'UNIT', 'cm^-3', 'DESCRIPTION', 'Fractional error estimate for electron density derived from fit of exponential part of the thermal electron current.');  % New from commit 3dce0a0, 2014-12-16 or earlier.          
                        
            ocl2{end+1} = struct('NAME', 'Rsquared_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'Rsquared_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
            ocl2{end+1} = struct('NAME', 'asm_Vsg',                    'UNIT', 'V',  'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Vsg',              'UNIT', 'V',  'DESCRIPTION', 'Standard deviation of spacecraft potential from gaussian fit to second derivative. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_Iph0',                   'UNIT', 'A',  'DESCRIPTION', 'Photosaturation current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Iph0',                   'UNIT', 'A',  'DESCRIPTION', 'Assumed photosaturation current used (referred to) in the Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_Tph',                    'UNIT', 'eV', 'DESCRIPTION', 'Photoelectron temperature. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Tph',                    'UNIT', 'eV', 'DESCRIPTION', 'Assumed photoelectron temperature used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Vsi',                    'UNIT', 'V',  'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Vph_knee',               'UNIT', 'V',  'DESCRIPTION', 'Potential at probe position from photoelectron current knee (gaussian fit to second derivative). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Vph_knee',         'UNIT', 'eV', 'DESCRIPTION', []);    % New  from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Te_linear',              'UNIT', 'eV', 'DESCRIPTION', 'Electron temperature from linear fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_linear',        'UNIT', 'eV', 'DESCRIPTION', []);   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_ne_linear',              'UNIT', 'cm^-3', 'DESCRIPTION', 'Electron (plasma) density from linear fit to electron current . Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'sigma_asm_ne_linear',        'UNIT', 'cm^-3', 'DESCRIPTION', []);   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_ion_slope',              'UNIT', 'A/V',   'DESCRIPTION', 'Slope of ion current fit as a function of absolute potential . Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ion_intersect',          'UNIT', 'A',     'DESCRIPTION', 'Y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_e_slope',                'UNIT', 'A/V',   'DESCRIPTION', 'Slope of linear electron current fit as a function of absolute potential . Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_slope',          'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of slope of linear electron current fit as a function of absolute potential . Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_e_intersect',            'UNIT', 'A',     'DESCRIPTION', 'Y-intersection of linear electron current fit as a function of absolute potential . Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_intersect',      'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of y-intersection of linear electron current fit as a function of absolute potential . Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME', 'asm_ion_Vb_intersect',       'UNIT', 'A',     'DESCRIPTION', 'Y-intersection of ion current fit as a function of bias potential . Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_intersect', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of Y-intersection of ion current fit as a function of bias potential . Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME', 'asm_e_Vb_intersect',         'UNIT', 'A',     'DESCRIPTION', 'Y-intersection of linear electron current fit as a function of bias potential . Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_intersect',   'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of y-intersection of linear electron current fit as a function of bias potential . Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Tphc',                   'UNIT', 'eV',    'DESCRIPTION', 'Photoelectron cloud temperature (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_nphc',                   'UNIT', 'cm^-3', 'DESCRIPTION', 'Photoelectron cloud density (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_phc_slope',              'UNIT', 'A/V',   'DESCRIPTION', 'Slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_phc_intersect',          'UNIT', 'A',     'DESCRIPTION', 'Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ne_5eV',                 'UNIT', 'cm^-3', 'DESCRIPTION', 'Electron density from linear electron current fit, assuming Te= 5eV  . Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_dep',               'UNIT', 'cm^-3', 'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_indep',             'UNIT', 'cm^-3', 'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate. Fixed photoelectron current assumption.');           
            ocl2{end+1} = struct('NAME', 'asm_v_ion',                  'UNIT', 'm/s',   'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Te_exp',                 'UNIT', 'eV',    'DESCRIPTION', 'Electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate of electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            
            ocl2{end+1} = struct('NAME', 'asm_ne_exp',                 'UNIT', 'cm^-3',   'DESCRIPTION', 'Electron density derived from fit of exponential part of the thermal electron current.');    % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp',           'UNIT', 'cm^-3',   'DESCRIPTION', 'Fractional error estimate for electron density derived from fit of exponential part of the thermal electron current.');    % New from commit 3dce0a0, 2014-12-16 or earlier.
          
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
            %---------------------------------------------------------------------------------------------------
            % Removed from commit 3dce0a0, 2014-12-16, or earlier.
            %ocl2{end+1} = struct('NAME', 'asm_e_Vb_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of linear electron current fit as a function of bias potential . Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of linear electron current fit as a function of bias potential . Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_ion_Vb_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of ion current fit as a function of bias potential . Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'ion_Vb_slope',   'UNIT', '', 'DESCRIPTION', 'Slope of ion current fit as a function of bias potential ');
            %ocl2{end+1} = struct('NAME', 'sigma_ion_Vb_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of ion current fit as a function of bias potential');
            %ocl2{end+1} = struct('NAME', 'e_Vb_slope',   'UNIT', 'A/V', 'DESCRIPTION', 'Slope of linear electron current fit as a function of bias potential ');
            %ocl2{end+1} = struct('NAME', 'sigma_e_Vb_slope',   'UNIT', [], 'DESCRIPTION', 'Fractional error estimate of slope of linear electron current fit as a function of bias potential ');
            %---------------------------------------------------------------------------------------------------

            for i_oc = 1:length(ocl2)
                ocl2{i_oc}.BYTES     = 14;
                ocl2{i_oc}.DATA_TYPE = 'ASCII_REAL';
            end
            OBJTABLE_data.OBJCOL_list = [ocl1, ocl2];
            createLBL_writeObjectTable(fid, OBJTABLE_data)            
            fprintf(fid,'END');
            
            
            
        elseif  strcmp(an_tabindex{i,7},'best_estimates') %%%%%%%%%%%% BEST ESTIMATES FILE %%%%%%%%%%%%
            
            
            
            OBJTABLE_data = [];
            OBJTABLE_data.ROWS      = an_tabindex{i,4};
            OBJTABLE_data.COLUMNS   = an_tabindex{i,5};
            OBJTABLE_data.ROW_BYTES = an_tabindex{i,9};
            OBJTABLE_data.DESCRIPTION = sprintf('BEST ESTIMATES OF PHYSICAL VALUES FROM MODEL FITTED ANALYSIS.');   % Bad description? To specific?
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION', 'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME', 'QUALITY',            'DATA_TYPE', 'ASCII_REAL', 'BYTES',  3, 'UNIT', [],        'DESCRIPTION', 'QUALITY FACTOR FROM 000(best) to 999');
            ocl{end+1} = struct('NAME', 'npl',                'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'CM**-3',  'DESCRIPTION', 'Best estimate of plasma number density.');
            ocl{end+1} = struct('NAME', 'Te',                 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'eV',      'DESCRIPTION', 'Best estimate of electron temperature.');
            ocl{end+1} = struct('NAME', 'Vsc',                'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'V',       'DESCRIPTION', 'Best estimate of spacecraft potential.');
            ocl{end+1} = struct('NAME', 'Probe_number',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  1, 'UNIT', [],        'DESCRIPTION', 'Probe number. 1 or 2');
            ocl{end+1} = struct('NAME', 'Sweep_group_number', 'DATA_TYPE', 'ASCII_REAL', 'BYTES',  5, 'UNIT', []',       'DESCRIPTION', ...
                'Number signifying which group of the sweeps the data comes from. Groups of sweeps are formed for the purpose of deriving/selecting best estimates. All sweeps with the same group number are almost simultaneous. Mostly intended for debugging.');
            OBJTABLE_data.OBJCOL_list = ocl;            
            createLBL_writeObjectTable(fid, OBJTABLE_data)            
            fprintf(fid,'END');
            
            
            
        else
            
            fprintf(1,'error, bad identifier in an_tabindex{%i,7}',i);
            
        end
        fclose(fid);
               
        
        
    end   % for 
end     % if


