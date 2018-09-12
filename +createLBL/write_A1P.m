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
function write_A1P(kvlLblAll, HeaderOptions, cotlfSettings, index, der_struct, dontReadHeaderKeyList, tabLblInconsistencyPolicy)
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
        
        % IMPLEMENTATION NOTE: From experience can der_struct.timing have UTC values with 6 decimals which DVAL-NG does
        % not permit. Must therefore remove.
        kvlLbl = kvlLblAll;
        kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'START_TIME',                   startStopTimes{1}(1:23));        % UTC start time
        kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl,  'STOP_TIME',                   startStopTimes{2}(1:23));        % UTC stop time
        kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'SPACECRAFT_CLOCK_START_COUNT', startStopTimes{3});
        kvlLbl = EJ_lapdog_shared.utils.KVPL.add_kv_pair(kvlLbl, 'SPACECRAFT_CLOCK_STOP_COUNT',  startStopTimes{4});
        
        kvlLbl = EJ_lapdog_shared.utils.KVPL.overwrite_values(kvlLblCalib1, kvlLbl, 'require preexisting keys');
        
        lblData = [];
        lblData.HeaderKvl = kvlLbl;
        clear   kvlLbl   kvlLblCalib1
        
        lblData.OBJTABLE = [];
        [LblData.OBJTABLE.OBJCOL_list, LblData.OBJTABLE.DESCRIPTION] = createLBL.definitions.get_A1P_data();
        
        createLBL.create_OBJTABLE_LBL_file(der_struct.file{iFile}, lblData, HeaderOptions, cotlfSettings, tabLblInconsistencyPolicy);
        
    end   % for
    
end
