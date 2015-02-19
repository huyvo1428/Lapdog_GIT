%createLBL.m
%CREATE .LBL FILES, FROM PREVIOUS LBL FILES

t_start = clock;    % NOTE: Not number of seconds, but [year month day hour minute seconds].



% "Constants"
NO_ODL_UNIT = [];   % Constant to be used for LBL "UNIT" fields meaning that there is no unit. To distinguish that it is know that the quantity has no unit rather than that the unit is unknown at present.
ODL_VALUE_UNKNOWN = [];   %'<Unknown>';  % Unit is unknown.



%====================================================================================================
% Construct list of key-value pairs to use for all LBL files.
% -----------------------------------------------------------
% Keys must not collide with keys set for specific file types.
% For file types that read CALIB LBL files, must overwrite old keys(!).
% 
% NOTE: Only keys that already exist in the CALIB files that are read (otherwise intentional error)
%       and which are thus overwritten.
% NOTE: Might not be complete. PDS_VERSION_ID, RECORD_TYPE
%====================================================================================================
kvl_LBL_all = [];
kvl_LBL_all.keys = {};
kvl_LBL_all.values = {};
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'DATA_SET_ID',               ['"', strrep(datasetid,   sprintf('-3-%s-CALIB', shortphase), sprintf('-5-%s-DERIV', shortphase)), '"']);
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'DATA_SET_NAME',             ['"', strrep(datasetname, sprintf('3 %s CALIB',  shortphase), sprintf('5 %s DERIV',  shortphase)), '"']);
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'LABEL_REVISION_NOTE',       sprintf('"%s, %s, %s"',lbltime,lbleditor,lblrev));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PRODUCT_CREATION_TIME',     datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF'));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'DATA_QUALITY_ID',           '"1"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'MISSION_ID',                'ROSETTA');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PRODUCER_FULL_NAME',        sprintf('"%s"', producerfullname));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PRODUCER_ID',               producershortname);
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PRODUCT_TYPE',              '"DDR"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PROCESSING_LEVEL_ID',       '"5"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PRODUCER_INSTITUTION_NAME', '"SWEDISH INSTITUTE OF SPACE PHYSICS, UPPSALA"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'INSTRUMENT_HOST_ID',        'RO');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'INSTRUMENT_HOST_NAME',      '"ROSETTA-ORBITER"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'INSTRUMENT_NAME',           '"ROSETTA PLASMA CONSORTIUM - LANGMUIR PROBE"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'INSTRUMENT_TYPE',           '"PLASMA INSTRUMENT"');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'INSTRUMENT_ID',             'RPCLAP');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'TARGET_NAME',               sprintf('"%s"', targetfullname));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'TARGET_TYPE',               sprintf('"%s"', targettype));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'MISSION_NAME',              sprintf('"%s"', 'INTERNATIONAL ROSETTA MISSION'));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'MISSION_PHASE_NAME',        sprintf('"%s"', missionphase));
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'PDS_VERSION_ID',            'PDS3');
kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, 'RECORD_TYPE',               'FIXED_LENGTH');
%kvl_LBL_all = createLBL_KVPL_add_kv_pair(kvl_LBL_all, '', );



%===============================================
%
% Create LBL files for (TAB files in) tabindex.
%
%===============================================
if(~isempty(tabindex));
    len= length(tabindex(:,3));
    
    for(i=1:len)
        try

            %tabindex cell array = {tab file name, first index number of batch,
            % UTC time of last row, S/C time of last row, row counter}
            %    units: [cell array] =  {[string],[double],[string],[float],[integer]

            %=========================================
            %
            % LBL file: Create header/key-value pairs
            %
            %=========================================
            
            tname = tabindex{i,2};
            lname=strrep(tname,'TAB','LBL');
            Pnum = tname(end-5);

            fid = fopen(strrep(tabindex{i,1},'TAB','LBL'),'w');   % Open DERIV LBL file to create/write to.
            %         if fid < 0
            %             fprintf(1,'Error, cannot open file %s', strrep(tabindex{i,1},'TAB','LBL'));
            %             break
            %         end % if I/O error
            
            fileinfo = dir(tabindex{i,1});
            [CALIB_LBL_str, CALIB_LBL_struct] = createLBL_read_ODL_to_structs(index(tabindex{i,3}).lblfile);   % Read CALIB LBL file.         
            kvl_LBL_CALIB = [];
            kvl_LBL_CALIB.keys   = CALIB_LBL_str.keys(1:end-1);    % NOTE: CALIB_LBL_str includes OBJECT = TABLE as last key-value pair.
            kvl_LBL_CALIB.values = CALIB_LBL_str.values(1:end-1);
            kvl_LBL_CALIB = createLBL_compatibility_substitute_LBL_keys(kvl_LBL_CALIB, str2num(Pnum));
            
            SPACECRAFT_CLOCK_STOP_COUNT = sprintf('"%s/%014.3f"', index(tabindex{i,3}).sct0str(2), obt2sct(tabindex{i,5})); % get resetcount from above, and calculate obt from sct
            
            kvl_LBL_set = [];
            kvl_LBL_set.keys = {};
            kvl_LBL_set.values = {};
            kvl_LBL_set = createLBL_KVPL_add_kv_pair(kvl_LBL_set, 'RECORD_BYTES',                 num2str(fileinfo.bytes));
            kvl_LBL_set = createLBL_KVPL_add_kv_pair(kvl_LBL_set, 'FILE_RECORDS',                 num2str(tabindex{i,6}));
            kvl_LBL_set = createLBL_KVPL_add_kv_pair(kvl_LBL_set, 'FILE_NAME',                    lname);
            kvl_LBL_set = createLBL_KVPL_add_kv_pair(kvl_LBL_set, '^TABLE',                       tname);
            kvl_LBL_set = createLBL_KVPL_add_kv_pair(kvl_LBL_set, 'PRODUCT_ID',                   tname(1:end-4));
            kvl_LBL_set = createLBL_KVPL_add_kv_pair(kvl_LBL_set, 'START_TIME',                   index(tabindex{i,3}).t0str(1:23)); % UTC start time
            kvl_LBL_set = createLBL_KVPL_add_kv_pair(kvl_LBL_set, 'STOP_TIME',                    tabindex{i,4}(1:23));              % UTC stop time
            kvl_LBL_set = createLBL_KVPL_add_kv_pair(kvl_LBL_set, 'SPACECRAFT_CLOCK_START_COUNT', index(tabindex{i,3}).sct0str);
            kvl_LBL_set = createLBL_KVPL_add_kv_pair(kvl_LBL_set, 'SPACECRAFT_CLOCK_STOP_COUNT',  SPACECRAFT_CLOCK_STOP_COUNT);
            
            kvl_LBL = createLBL_KVPL_merge(kvl_LBL_set, kvl_LBL_all);
            kvl_LBL = createLBL_KVPL_overwrite_values(kvl_LBL_CALIB, kvl_LBL);
            %kvl_LBL = createLBL_KVPL_overwrite_values(kvl_LBL,       kvl_LBL_all);
            createLBL_write_LBL_header(fid, kvl_LBL)
            clear kvl_LBL
            clear kvl_LBL_CALIB

            

            %=======================================
            %
            % LBL file: Create OBJECT TABLE section
            %
            %=======================================
            if (tname(30)=='S')
                
                %=========================
                % CASE: Sweep files (xxS)
                %=========================
                
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
                    ocl{end+1} = struct('NAME', 'QUALITY',                          'DATA_TYPE', 'ASCII_REAL', 'BYTES', 3,  'UNIT', 'N/A',     'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
                    ocl{end+1} = struct('NAME', sprintf('P%s_SWEEP_CURRENT', Pnum), 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'AMPERE', 'ITEMS', tabindex{i,7}-5, 'FORMAT', 'E14.7', ...
                        'DESCRIPTION', sprintf('Averaged current measured of potential sweep, at different potential steps as described by %s', Bfile));
                    
                    OBJTABLE_data.OBJCOL_list = ocl;
                    createLBL_writeObjectTable(fid, OBJTABLE_data)
                end


            else
                %=============================================
                % CASE: Anything EXCEPT sweep files (NOT xxS)
                %=============================================
                
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
                
                % -----------------------------------------------------------------------------
                % Recycle OBJCOL info/columns from CALIB LBL file (!) and then add one column.
                % -----------------------------------------------------------------------------
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
                    'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
                
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
        end    % try
    end    % for
end    % if



%===============================================
%
% Create LBL files for (TAB files in) blockTAB.
%
%===============================================
if(~isempty(blockTAB));
    len=length(blockTAB(:,3));
    for(i=1:len)        
        
        %=========================================
        %
        % LBL file: Create header/key-value pairs
        %
        % NOTE: Does not rely on reading old LBL file.
        %=========================================
        
        tname = blockTAB{i,2};
        lname=strrep(tname,'TAB','LBL');
        fid = fopen(strrep(blockTAB{i,1},'TAB','LBL'),'w');
        
        fileinfo = dir(blockTAB{i,1});

        kvl_set = [];   % NOTE: Can not initialize with "struct(...)". That gives an unintended result due to a special interpretation for arrays.
        kvl_set.keys = {};
        kvl_set.values = {};
        kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'RECORD_BYTES',   sprintf('%i', fileinfo.bytes));
        kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'FILE_RECORDS',   sprintf('%i', blockTAB{i,3}));
        kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'FILE_NAME',      sprintf('"%s"', lname));
        kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, '^TABLE',         sprintf('"%s"', tname));        
        kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'PRODUCT_ID',     sprintf('"%s"', tname(1:(end-4))));

        kvl_LBL = createLBL_KVPL_merge(kvl_set, kvl_LBL_all);            
        createLBL_write_LBL_header(fid, kvl_LBL)
        clear kvl_set
        clear kvl_LBL

        
        
        %=======================================
        % LBL file: Create OBJECT TABLE section
        %=======================================
        
        OBJTABLE_data = [];
        OBJTABLE_data.ROWS      = blockTAB{i,3};
        OBJTABLE_data.COLUMNS   = 3;
        OBJTABLE_data.ROW_BYTES = 54;                   % NOTE: HARDCODED! TODO: Fix.
        OBJTABLE_data.DESCRIPTION = 'BLOCKLIST DATA. START & STOP TIME OF MACROBLOCK AND MACROID.';
        %OBJTABLE_data.DELIMITER = ', ';
        ocl = [];
        ocl{end+1} = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss');
        ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',  'DATA_TYPE', 'TIME',       'BYTES', 23, 'UNIT', 'SECONDS',   'DESCRIPTION', 'LAST START TIME OF MACRO BLOCK FILE YYYY-MM-DD HH:MM:SS.sss');
        ocl{end+1} = struct('NAME', 'MACRO_ID',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'MACRO IDENTIFICATION NUMBER');
        OBJTABLE_data.OBJCOL_list = ocl;
        createLBL_writeObjectTable(fid, OBJTABLE_data)
        
        fprintf(fid,'END');
        fclose(fid);
        
    end   % for
    
end   % if 


%==================================================
%
% Create LBL files for (TAB files in) an_tabindex.
%
%==================================================
if (~isempty(an_tabindex));
    len=length(an_tabindex(:,3));
    
    for (i=1:len)
        
        %%some need-to-know things
        tname = an_tabindex{i,2};
        lname = strrep(tname,'TAB','LBL');
        
        mode = tname(end-6:end-4);
        Pnum = tname(end-5);     % Probe number
        
        
        
        %=========================================
        %
        % LBL file: Create header/key-value pairs
        %
        %=========================================
        
        if strcmp(an_tabindex{i,7}, 'best_estimates')
            %======================
            % CASE: Best estimates
            %======================
            
            TAB_file_info = dir(an_tabindex{i, 1});
            kvl_set = [];
            kvl_set.keys = {};
            kvl_set.values = {};
            kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'FILE_NAME',             strrep(an_tabindex{i, 2}, '.TAB', '.LBL'));
            kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, '^TABLE',                an_tabindex{i, 2});
            kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'FILE_RECORDS',          num2str(an_tabindex{i, 4}));
            kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'PRODUCT_ID',            sprintf('"%s"', strrep(an_tabindex{i, 2}, '.TAB', '')));
            kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'DESCRIPTION',           '"Best estimates of physical quantities based on sweeps."');
            kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'RECORD_BYTES',          num2str(TAB_file_info.bytes));

            try
                %===============================================================
                % NOTE: createLBL_create_EST_LBL_header(...)                
                % sets certain LBL/ODL variables to handle collisions:
                %    START_TIME / STOP_TIME,
                %    SPACECRAFT_CLOCK_START_COUNT / SPACECRAFT_CLOCK_STOP_COUNT
                %===============================================================
                
                kvl_LBL = createLBL_create_EST_LBL_header(an_tabindex(i, :), index, kvl_set);    % NOTE: Reads LBL file(s).
                kvl_LBL = createLBL_KVPL_overwrite_values(kvl_LBL, kvl_LBL_all);
            catch exc
                fprintf(1, ['ERROR: ', exc.message])
                fprintf(1, exc.getReport)
                
                continue
            end
            
        else
            %====================================================
            % CASE: Anything type of file EXCEPT best estimates.
            %====================================================
            
            fileinfo = dir(an_tabindex{i,1});
            [CALIB_LBL_str, CALIB_LBL_struct] = createLBL_read_ODL_to_structs(index(an_tabindex{i,3}).lblfile);   % Read CALIB LBL file. 
            kvl_LBL_CALIB = [];
            kvl_LBL_CALIB.keys   = CALIB_LBL_str.keys  (1:end-1);    % NOTE: CALIB_LBL_str includes OBJECT = TABLE as last key-value pair.
            kvl_LBL_CALIB.values = CALIB_LBL_str.values(1:end-1);
            kvl_LBL_CALIB = createLBL_compatibility_substitute_LBL_keys(kvl_LBL_CALIB, str2num(Pnum));
            
            kvl_set = [];
            kvl_set.keys = {};
            kvl_set.values = {};
            kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'RECORD_BYTES',          num2str(fileinfo.bytes));
            kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'FILE_RECORDS',          num2str(an_tabindex{i,4}));
            kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, 'FILE_NAME',             lname);
            kvl_set = createLBL_KVPL_add_kv_pair(kvl_set, '^TABLE',                tname);
            
            kvl_LBL = createLBL_KVPL_merge(kvl_set, kvl_LBL_all);
            kvl_LBL = createLBL_KVPL_overwrite_values(kvl_LBL_CALIB, kvl_LBL);


        end   % if-else
        LBL_file_path = strrep(an_tabindex{i,1}, 'TAB', 'LBL');
        fid = fopen(LBL_file_path,'w');
        createLBL_write_LBL_header(fid, kvl_LBL)
        clear KVL_set
        clear KVL_LBL
        
        
        
        %=======================================
        %
        % LBL file: Create OBJECT TABLE section
        %
        %=======================================        
        
        if strcmp(an_tabindex{i,7}, 'downsample')   %%%%%%%%DOWNSAMPLED FILE%%%%%%%%%%%%%%%
            
           
            
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
            ocl{end+1} = struct('NAME', 'QUALITY',                           'UNIT', NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL',                    'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
            OBJTABLE_data.OBJCOL_list = ocl;
            createLBL_writeObjectTable(fid, OBJTABLE_data)
            fprintf(fid,'END');
            
            
            
        elseif strcmp(an_tabindex{i,7}, 'spectra')   %%%%%%%%%%%%%%%%SPECTRA FILE%%%%%%%%%%            
            
            
                    
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
            ocl1{end+1} = struct('NAME', 'QUALITY',                'UNIT', NO_ODL_UNIT, 'BYTES', 3,  'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
            %---------------------------------------------
            ocl2 = {};
            if strcmp(mode(1), 'I')
                
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
                fprintf(1, 'error, bad mode identifier in an_tabindex{%i,1}',i);
            end
            for i_oc = 1:length(ocl2)
                ocl2{i_oc}.BYTES     = 14;
                ocl2{i_oc}.DATA_TYPE = 'ASCII_REAL';
                ocl2{i_oc}.FORMAT    = 'E14.7';
            end

            OBJTABLE_data.OBJCOL_list = [ocl1, ocl2];
            createLBL_writeObjectTable(fid, OBJTABLE_data)
            fprintf(fid,'END');
            
            
            
        elseif  strcmp(an_tabindex{i,7}, 'frequency')    %%%%%%%%%%%% FREQUENCY FILE %%%%%%%%%
            
            
            
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
            
            
            
        elseif  strcmp(an_tabindex{i,7}, 'sweep')    %%%%%%%%%%%% SWEEP ANALYSIS FILE %%%%%%%%%
            
            
            
            OBJTABLE_data = [];
            OBJTABLE_data.ROWS      = an_tabindex{i,4};
            OBJTABLE_data.COLUMNS   = an_tabindex{i,5};
            OBJTABLE_data.ROW_BYTES = an_tabindex{i,9};
            OBJTABLE_data.DESCRIPTION = sprintf('MODEL FITTED ANALYSIS OF %s SWEEP FILE', tabindex{an_tabindex{i,6},2});

            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'START_TIME(UTC)', 'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Start time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'STOP_TIME(UTC)',  'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION',  'Stop time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'START_TIME_OBT',  'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Start time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_OBT',   'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION',  'Stop time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');            
            ocl1{end+1} = struct('NAME', 'Qualityfactor',   'UNIT', NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Quality factor from 0-100.');   % TODO: Correct?
            ocl1{end+1} = struct('NAME', 'SAA',             'UNIT', 'degrees',   'BYTES',  7, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Solar aspect angle from x-axis of spacecraft.');
            ocl1{end+1} = struct('NAME', 'Illumination',    'UNIT', NO_ODL_UNIT, 'BYTES',  4, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl1{end+1} = struct('NAME', 'direction',       'UNIT', NO_ODL_UNIT, 'BYTES',  1, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            % -- (Changing from ocl1 to ocl2.) --
            ocl2 = {};
            ocl2{end+1} = struct('NAME', 'old.Vsi',                'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old.Vx',                 'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential + Te from electron current fit. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vsg',                    'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'sigma_Vsg',              'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'old.Tph',                'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron temperature. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old.Iph0',               'UNIT', 'A',         'DESCRIPTION', 'Photosaturation current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vb_lastnegcurrent',      'UNIT', 'V',         'DESCRIPTION', 'bias potential below zero current.');
            ocl2{end+1} = struct('NAME', 'Vb_firstposcurrent',     'UNIT', 'V',         'DESCRIPTION', 'bias potential above zero current.');
            ocl2{end+1} = struct('NAME', 'Vbinfl',                 'UNIT', 'V',         'DESCRIPTION', 'Bias potential of inflection point in current.');
            ocl2{end+1} = struct('NAME', 'dIinfl',                 'UNIT', 'A/V',       'DESCRIPTION', 'Derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'd2Iinfl',                'UNIT', 'A/V^2',     'DESCRIPTION', 'Second derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'Iph0',                   'UNIT', 'A',         'DESCRIPTION', 'Photosaturation current.');
            ocl2{end+1} = struct('NAME', 'Tph',                    'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron temperature.');
            ocl2{end+1} = struct('NAME', 'Vsi',                    'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current.');
            ocl2{end+1} = struct('NAME',       'Vph_knee',         'UNIT', 'V',         'DESCRIPTION',                               'Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');            
            ocl2{end+1} = struct('NAME', 'sigma_Vph_knee',         'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'Te_linear',        'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'ne_linear',        'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_ne_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME',       'ion_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential.');            
            ocl2{end+1} = struct('NAME', 'sigma_ion_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential');
            ocl2{end+1} = struct('NAME',       'ion_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_slope',          'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_slope',          'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_intersect',      'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_intersect',      'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'ion_Vb_intersect', 'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_Vb_intersect', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'e_Vb_intersect',   'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_Vb_intersect',   'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable).');
            ocl2{end+1} = struct('NAME', 'nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable).');
            ocl2{end+1} = struct('NAME',       'phc_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'phc_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'ne_5eV',                 'UNIT', 'cm^-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming electron temperature Te = 5 eV.');
            ocl2{end+1} = struct('NAME', 'ni_v_dep',               'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity.');
            ocl2{end+1} = struct('NAME', 'ni_v_indep',             'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate.');
            ocl2{end+1} = struct('NAME', 'v_ion',                  'UNIT', 'm/s',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate.');
            ocl2{end+1} = struct('NAME',       'Te_exp',           'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ne_exp',           'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');  % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'sigma_ne_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron density derived from fit of exponential part of the thermal electron current.');  % New from commit 3dce0a0, 2014-12-16 or earlier.          
                        
            ocl2{end+1} = struct('NAME', 'Rsquared_linear',            'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'Rsquared_exp',               'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
            ocl2{end+1} = struct('NAME', '      asm_Vsg',              'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Vsg',              'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Standard deviation of spacecraft potential from gaussian fit to second derivative. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'ASM_Iph0',                   'UNIT', 'A',         'DESCRIPTION', 'Assumed photosaturation current used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'ASM_Tph',                    'UNIT', 'eV',        'DESCRIPTION', 'Assumed photoelectron temperature used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Vsi',                    'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', '      asm_Vph_knee',         'UNIT', 'V',         'DESCRIPTION',                               'Potential at probe position from photoelectron current knee (gaussian fit to second derivative) with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Vph_knee',         'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Potential at probe position from photoelectron current knee (gaussian fit to second derivative) with Fixed photoelectron current assumption.');    % New  from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', '      asm_Te_linear',        'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', '      asm_ne_linear',        'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'sigma_asm_ne_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');   % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', '      asm_ion_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', '      asm_ion_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', '      asm_e_slope',          'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_slope',          'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', '      asm_e_intersect',      'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_intersect',      'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME', '      asm_ion_Vb_intersect', 'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_intersect', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME', '      asm_e_Vb_intersect',   'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_intersect',   'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', '      asm_phc_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_slope',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', '      asm_phc_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_intersect',    'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ne_5eV',                 'UNIT', 'cm^-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming Te= 5eV. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_dep',               'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_indep',             'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate. Fixed photoelectron current assumption.');           
            ocl2{end+1} = struct('NAME', 'asm_v_ion',                  'UNIT', 'm/s',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', '      asm_Te_exp',           'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');            
            ocl2{end+1} = struct('NAME', '      asm_ne_exp',           'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');    % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron density derived from fit of exponential part of the thermal electron current.');    % New from commit 3dce0a0, 2014-12-16 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_linear',        'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_exp',           'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
            ocl2{end+1} = struct('NAME', 'ASM_m_ion',      'BYTES', 3, 'UNIT', 'amu',               'DESCRIPTION', 'Assumed ion mass for all ions.');     % New from commit a56c578, 2015-01-22 or earlier.
            ocl2{end+1} = struct('NAME', 'ASM_Z_ion',      'BYTES', 2, 'UNIT', 'Elementary charge', 'DESCRIPTION', 'Assumed ion charge for all ions.');   % New from commit a56c578, 2015-01-22 or earlier.
            ocl2{end+1} = struct('NAME', 'ASM_v_ion',               'UNIT', 'm/s',                  'DESCRIPTION', 'Assumed ion ram speed in used in *_v_dep variables.');   % New from commit a56c578, 2015-01-22 or earlier. Earlier name: ASM_m_vram, ASM_vram_ion.
            ocl2{end+1} = struct('NAME', '    Vsc_ni_ne',              'UNIT', 'V',                 'DESCRIPTION', 'Spacecraft potential needed to produce identical ion (ni_v_indep) and electron (ne_linear) densities.');   % New from commit a56c578, 2015-01-22 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Vsc_ni_ne',              'UNIT', 'V',                 'DESCRIPTION', 'Spacecraft potential needed to produce identical ion (asm_ni_v_indep) and electron (asm_ne_linear) densities. Fixed photoelectron current assumption.');   % New from commit a56c578, 2015-01-22 or earlier.
            
            ocl2{end+1} = struct('NAME', 'Vsc_aion',                  'UNIT', 'V',      'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'ni_aion',                   'UNIT', 'cm^-3',  'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'v_aion',                    'UNIT', 'm/s',    'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Vsc_aion',              'UNIT', 'V',      'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_ni_aion',               'UNIT', 'cm^-3',  'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_v_aion',                'UNIT', 'm/s',    'DESCRIPTION', '');  % New from commit 96660fb, 2015-02-10 or earlier.
            %---------------------------------------------------------------------------------------------------
            % Removed from commit 3dce0a0, 2014-12-16, or earlier.
            %ocl2{end+1} = struct('NAME', 'asm_e_Vb_slope',         'UNIT', 'A/V',       'DESCRIPTION', 'Slope of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_slope',   'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_ion_Vb_slope',       'UNIT', 'A/V',       'DESCRIPTION', 'Slope of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_slope', 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            %ocl2{end+1} = struct('NAME', 'ion_Vb_slope',           'UNIT', 'A/V',       'DESCRIPTION', 'Slope of ion current fit as a function of bias potential ');
            %ocl2{end+1} = struct('NAME', 'sigma_ion_Vb_slope',     'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of bias potential');
            %ocl2{end+1} = struct('NAME', 'e_Vb_slope',             'UNIT', 'A/V',       'DESCRIPTION', 'Slope of linear electron current fit as a function of bias potential ');
            %ocl2{end+1} = struct('NAME', 'sigma_e_Vb_slope',       'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of bias potential ');
            %---------------------------------------------------------------------------------------------------

            for i_oc = 1:length(ocl2)
                if ~isfield(ocl2{i_oc}, 'BYTES')
                    ocl2{i_oc}.BYTES = 14;
                end
                ocl2{i_oc}.DATA_TYPE = 'ASCII_REAL';
            end
            OBJTABLE_data.OBJCOL_list = [ocl1, ocl2];
            createLBL_writeObjectTable(fid, OBJTABLE_data)            
            fprintf(fid,'END');
            
            
            
        elseif  strcmp(an_tabindex{i,7},'best_estimates')    %%%%%%%%%%%% BEST ESTIMATES FILE %%%%%%%%%%%%
            
            
            
            MISSING_CONSTANT = -1000;    % NOTE: This constant must be reflected in the corresponding section in best_estimates!!!
            OBJTABLE_data = [];
            OBJTABLE_data.ROWS      = an_tabindex{i,4};
            OBJTABLE_data.COLUMNS   = an_tabindex{i,5};
            OBJTABLE_data.ROW_BYTES = an_tabindex{i,9};
            OBJTABLE_data.DESCRIPTION = sprintf('BEST ESTIMATES OF PHYSICAL VALUES FROM MODEL FITTED ANALYSIS.');   % Bad description? To specific?
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME', 'QUALITY',            'DATA_TYPE', 'ASCII_REAL', 'BYTES',  3, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (best) to 999.');
            ocl{end+1} = struct('NAME', 'npl',                'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'CM**-3',    'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of plasma number density.');
            ocl{end+1} = struct('NAME', 'Te',                 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'eV',        'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of electron temperature.');
            ocl{end+1} = struct('NAME', 'Vsc',                'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'V',         'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of spacecraft potential.');
            ocl{end+1} = struct('NAME', 'Probe_number',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  1, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Probe number. 1 or 2.');
            ocl{end+1} = struct('NAME', 'Direction',          'DATA_TYPE', 'ASCII_REAL', 'BYTES',  1, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            ocl{end+1} = struct('NAME', 'Illumination',       'DATA_TYPE', 'ASCII_REAL', 'BYTES',  4, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl{end+1} = struct('NAME', 'Sweep_group_number', 'DATA_TYPE', 'ASCII_REAL', 'BYTES',  5, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', ...
                'Number signifying which group of sweeps the data comes from. Groups of sweeps are formed for the purpose of deriving/selecting values to be used in best estimates. All sweeps with the same group number are almost simultaneous. Mostly intended for debugging.');
            OBJTABLE_data.OBJCOL_list = ocl;            
            createLBL_writeObjectTable(fid, OBJTABLE_data)            
            fprintf(fid,'END');            
            
            
            
        else
            
            fprintf(1,'error, bad identifier in an_tabindex{%i,7}',i);
            
        end
        fclose(fid);
               
        
        
    end   % for 
end     % if

fprintf(1, '%s: %.0f s (elapsed wall time)\n', mfilename, etime(clock, t_start));
