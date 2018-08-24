%
% Create LBL files for A1P TAB files.
%
%
% ARGUMENTS
% =========
% index                     : Lapdog's "index" variable.
% der_struct                : Global variable "der_struct" defined by other Lapdog code. The function does NOT read
%                             the corresponding global variable by itself.
% dontReadHeaderKeyList     : Cell array of strings. PDS keys to not READ from source data set LBL file.
% tabLblInconsistencyPolicy : String. As defined in createLBL.create_OBJTABLE_LBL_file.
%
%
function write_A1P(kvlLblAll, HeaderOptions, index, der_struct, NO_ODL_UNIT, MISSING_CONSTANT, indentationLength, dontReadHeaderKeyList, tabLblInconsistencyPolicy)
%
% PROPOSAL: Do not write LBL file. Return ~lblData instead.
%   CON: Would be nice to have all dependence on "der_struct" here.
    
    for iFile = 1:numel(der_struct.file)
        startStopTimes = der_struct.timing(iFile, :);
        
        iIndex = der_struct.firstind(iFile);        
        
        %--------------------------
        % Read the CALIB1 LBL file
        %--------------------------
        [kvlLblCalib1, junk] = createLBL.read_LBL_file(index(iIndex).lblfile, dontReadHeaderKeyList);
        
        kvlLbl = kvlLblAll;
        kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'START_TIME',                   startStopTimes{1});        % UTC start time
        kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl,  'STOP_TIME',                   startStopTimes{2});        % UTC stop time
        kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'SPACECRAFT_CLOCK_START_COUNT', startStopTimes{3});
        kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'SPACECRAFT_CLOCK_STOP_COUNT',  startStopTimes{4});

        kvlLbl = EJ_lapdog_shared.utils.KVPL.overwrite_values(kvlLblCalib1, kvlLbl, 'require preexisting keys');

        lblData = [];
        lblData.indentationLength = indentationLength;
        lblData.HeaderKvl = kvlLbl;
        clear   kvlLbl   kvlLblCalib1

        %lblData.nTabFileRows                     = der_struct.rows(iFile);
        %lblData.ConsistencyCheck.nTabBytesPerRow = der_struct.bytes;
        %lblData.ConsistencyCheck.nTabColumns     = der_struct.cols(iFile);
        
        lblData.OBJTABLE = [];
        lblData.OBJTABLE.DESCRIPTION = 'ANALYZED PROBE 1 PARAMETERS';
        
        ocl = [];
        ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
        ocl{end+1} = struct('NAME',  'STOP_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
        ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
        ocl{end+1} = struct('NAME',  'STOP_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
        ocl{end+1} = struct('NAME', 'QUALITY',            'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  4, 'UNIT', NO_ODL_UNIT, 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (BEST) TO 999.');
        ocl{end+1} = struct('NAME', 'Vph_knee',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',         'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Potential at probe position from photoelectron current knee (gaussian fit of second derivative).');
        ocl{end+1} = struct('NAME', 'Te_exp_belowVknee',  'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'ELECTRONVOLT', 'MISSING_CONSTANT', MISSING_CONSTANT, 'DESCRIPTION', 'Electron temperature from an exponential fit to the slope of the retardation region of the electron current.');
        lblData.OBJTABLE.OBJCOL_list = ocl;
        clear   ocl
        
        createLBL.create_OBJTABLE_LBL_file(der_struct.file{iFile}, lblData, HeaderOptions, tabLblInconsistencyPolicy);
        clear   lblData
        
    end   % for
    
end
