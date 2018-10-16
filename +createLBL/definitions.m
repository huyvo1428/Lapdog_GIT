%
% DESIGN INTENT
% =============
% Class which stores hard-coded data related to specific LBL files, at least columns. Presently a bit unclear exactly
% what hard-coded data should be incldued.
% Should at least collects functions which define and return data structures defining LBL files, one file/data type per function.
%
% The class is instantiated with variable values which are likely constant during a session, and can be used by
% the methods (e.g. whether EDDER/DERIV1, MISSING_CONSTANT).
%
%
% NAMING CONVENTIONS, CONVENTIONS
% ===============================
% data      : Refers to LBL file data
% OCL       : Object Column List
% KVL, KVPL : Key-Value (pair) List
% --
% Only uses argument flags for density mode (true/false). It is implicit that E field is the inverse.
%
%
% Initially created 2018-09-12 by Erik P G Johansson, IRF Uppsala.
%
classdef definitions < handle
    % PROPOSAL: POLICY; Should collect hard-coded data.
    %           ==> Should not write LBL files.
    % NEED: The caller should have control over error-handling, LBL-TAB consistency checks.
    %
    % TODO-DECISION: Use filenaming conventions consistently for naming corresponding functions.
    %
    % PROPOSAL: Better name.
    %   PROPOSAL: definition_creator, LBL_definition_creator.
    %       CON: Bad if using class for updating LBL header in the future.
    %
    % TODO-DECISION: These functions set the "useFor" field. Should they? The field does not define columns as such but is
    %                related to LBL start & stop timestamps which are otherwise set outside of this class.
    % PROPOSAL: Submit (instance of) createLBL.constants instead of having field for MISSING_CONSTANT.
    %   TODO-DECISION: Are there other similar cases? N_FINAL_SWEEP_SAMPLES? 
    %
    % PROPOSAL: Help functions for setting specific types of column descriptions.
    %   PRO: Does not need to write out struct field names: NAME, DESCRIPTION etc.
    %   PRO: Automatically handle EDDER/DERIV1 differences.
    %   --
    %   TODO-DECISION: How handle MISSING_CONSTANT?
    %   TODO-DECISION: Need to think about how to handle DERIV2 TAB columns (here part of DERIV1)?
    %   --
    %   PROPOSAL: Automatically set constants for BYTES, DATA_TYPE, UNIT.
    %   PROPOSAL: OPTIONAL sprintf options for NAME ?
    %       PROBLEM: How implement optionality?
    %   PROPOSAL: UTC, OBT (separately to also be able to handle sweeps)
    %       PROPOSAL: oc_UTC(name, bytes, descrStr)
    %           NOTE: There is ~TIME_UTC with either BYTES=23 or 26.
    %               PROPOSAL: Have assertion for corresponding argument.
    %               PROPOSAL: Modify TAB files to always have BYTES=26?!!
    %           PROPOSAL: Assertion that name ends with "TIME_UTC".
    %       PROPOSAL: oc_OBT(name, descrStr)
    %           NOTE: BYTES=16 always
    %   --
    

    
    properties(Access=private)
        NO_ODL_UNIT        = [];
        ODL_VALUE_UNKNOWN  = 'UNKNOWN';   %'<Unknown>';  % Unit is unknown. Should NOT be used for official deliveries.

        MISSING_CONSTANT
        nFinalPresweepSamples
        generatingDeriv1
        
        MC_DESC_AMENDM       % Generic description string of MISSING_CONSTANT (MC). Is added at end of DESCRIPTION.
        QFLAG1_DESCRIPTION = 'QUALITY FLAG CONSTRUCTED AS THE SUM OF MULTIPLE TERMS, DEPENDING ON WHAT QUALITY RELATED EFFECTS ARE PRESENT. FROM 00000 (BEST) TO 77777 (WORST).';    % For older quality flag (version "1").
        QVALUE_DESCRIPTION = 'Quality value in the range 0 (worst) to 1 (best). Corresponds to goodness of fit or how well the model fits the data.';
        
        DATA_DATA_TYPE
        DATA_UNIT_CURRENT
        DATA_UNIT_VOLTAGE
        VOLTAGE_BIAS_DESC
        VOLTAGE_MEAS_DESC
        CURRENT_BIAS_DESC
        CURRENT_MEAS_DESC
    end
    
    
    
    methods(Access=public)
        
        % Constructor
        function obj = definitions(generatingDeriv1, MISSING_CONSTANT, nFinalPresweepSamples)
            % ASSERTIONS
            assert(isscalar(nFinalPresweepSamples) && isnumeric(nFinalPresweepSamples))
            assert(isscalar(MISSING_CONSTANT)      && isnumeric(MISSING_CONSTANT))
            
            
            
            obj.MISSING_CONSTANT      = MISSING_CONSTANT;
            obj.nFinalPresweepSamples = nFinalPresweepSamples;
            obj.generatingDeriv1      = generatingDeriv1;
            
            obj.MC_DESC_AMENDM        = sprintf(' A value of %e refers to that there is no value.', obj.MISSING_CONSTANT);
            
            % Set PDS keywords to use for column descriptions which differ between EDITED2/EDDER and DERIV/CALIB2
            % ---------------------------------------------------------------------------------------------------
            % IMPLEMENTATION NOTE: Some are meant to be used on the form obj.DATA_UNIT_CURRENT{:} in object column description struct declaration/assignment, "... = struct(...)".
            % This makes it possible to optionally omit the keyword, besides shortening the assignment when non-empty. This is not
            % currently used though.
            %       TODO-NEED-INFO: Are constants these really used in a ways such that the form DATA_UNIT_CURRENT{:} is
            %                       needed/useful?
            % NOTE: Also useful for standardizing the values used, even for values which are only used for e.g. DERIV1 but not EDDER.
            if obj.generatingDeriv1
                obj.DATA_DATA_TYPE    = {'DATA_TYPE', 'ASCII_REAL'};
                obj.DATA_UNIT_CURRENT = {'UNIT', 'AMPERE'};
                obj.DATA_UNIT_VOLTAGE = {'UNIT', 'VOLT'};
                obj.VOLTAGE_BIAS_DESC =          'CALIBRATED VOLTAGE BIAS.';
                obj.VOLTAGE_MEAS_DESC = 'MEASURED CALIBRATED VOLTAGE.';
                obj.CURRENT_BIAS_DESC =          'CALIBRATED CURRENT BIAS.';
                obj.CURRENT_MEAS_DESC = 'MEASURED CALIBRATED CURRENT.';
            else
                % CASE: EDDER run
                obj.DATA_DATA_TYPE    = {'DATA_TYPE', 'ASCII_INTEGER'};
                obj.DATA_UNIT_CURRENT = {'UNIT', 'N/A'};
                obj.DATA_UNIT_VOLTAGE = {'UNIT', 'N/A'};
                obj.VOLTAGE_BIAS_DESC =          'VOLTAGE BIAS.';
                obj.VOLTAGE_MEAS_DESC = 'MEASURED VOLTAGE.';
                obj.CURRENT_BIAS_DESC =          'CURRENT BIAS.';
                obj.CURRENT_MEAS_DESC = 'MEASURED CURRENT.';
            end
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_BLKLIST_data(obj)
            table_DESCRIPTION = 'BLOCKLIST DATA. START & STOP TIME OF MACRO BLOCK AND MACRO ID.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECONDS',       'DESCRIPTION', 'START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',  'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECONDS',       'DESCRIPTION', 'LAST START TIME OF MACRO BLOCK FILE YYYY-MM-DD HH:MM:SS.sss');
            ocl{end+1} = struct('NAME', 'MACRO_ID',       'DATA_TYPE', 'CHARACTER', 'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'HEXADECIMAL MACRO IDENTIFICATION NUMBER.');
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        % IMPLEMENTATION NOTE: Just using table_DESCRIPTION as argument and return value without modification to maintain similarity
        % with other functions for the moment. Might want to eliminate later.
        %
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_IVxHL_data(obj, isDensityMode, probeNbr, table_DESCRIPTION)
            table_DESCRIPTION = table_DESCRIPTION;   % No modification(!)
            
            ocl = {};
            ocl{end+1} = struct('NAME', 'TIME_UTC', 'DATA_TYPE', 'TIME',       'UNIT', 'SECONDS', 'BYTES', 26, 'DESCRIPTION', 'UTC TIME');
            ocl{end+1} = struct('NAME', 'TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'UNIT', 'SECONDS', 'BYTES', 16, 'DESCRIPTION', 'SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)');
            
            if probeNbr ~=3
                
                % CASE: P1 or P2
                currentOc = struct('NAME', sprintf('P%i_CURRENT', probeNbr), obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14);
                voltageOc = struct('NAME', sprintf('P%i_VOLTAGE', probeNbr), obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14);
                if isDensityMode
                    currentOc.DESCRIPTION = obj.CURRENT_MEAS_DESC;   % measured
                    voltageOc.DESCRIPTION = obj.VOLTAGE_BIAS_DESC;   % bias
                    currentOc = createLBL.optionally_add_MISSING_CONSTANT(obj.generatingDeriv1, obj.MISSING_CONSTANT, currentOc, ...
                        sprintf('A value of %g means that the original sample was saturated.', obj.MISSING_CONSTANT));   % NOTE: Modifies currentOc.
                else   %if isEFieldMode
                    currentOc.DESCRIPTION = obj.CURRENT_BIAS_DESC;   % bias
                    voltageOc.DESCRIPTION = obj.VOLTAGE_MEAS_DESC;   % measured
                    voltageOc = createLBL.optionally_add_MISSING_CONSTANT(obj.generatingDeriv1, obj.MISSING_CONSTANT, voltageOc, ...
                        sprintf('A value of %g means that the original sample was saturated.', obj.MISSING_CONSTANT));   % NOTE: Modifies voltageOc.
                %else
                %    error('Error, bad combination of values isDensityMode and isEFieldMode.');
                end
                ocl{end+1} = currentOc;
                ocl{end+1} = voltageOc;
                
            else
                
                % CASE: P3
                %error('This code segment has not yet been completed for P3. Can not create LBL file for "%s".', stabindex(i).path)
                if isDensityMode
                    % This case occurs at least on 2005-03-04 (EAR1). Appears to be the only day with V3x data for the
                    % entire mission. Appears to only happen for HF, but not LF.
                    oc1 = struct('NAME', 'P1_P2_CURRENT', obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', 'MEASURED CURRENT DIFFERENCE.');
                    oc2 = struct('NAME', 'P1_VOLTAGE',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                    oc3 = struct('NAME', 'P2_VOLTAGE',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                    
                    oc1 = createLBL.optionally_add_MISSING_CONSTANT(obj.generatingDeriv1, obj.MISSING_CONSTANT, oc1, ...
                        sprintf('A value of %g means that the original sample was saturated.', obj.MISSING_CONSTANT));
                else    %if isEFieldMode
                    % This case occurs at least on 2007-11-07 (EAR2), which appears to be the first day it occurs.
                    % This case does appear to occur for HF, but not LF.
                    oc1 = struct('NAME', 'P1_CURRENT',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', obj.CURRENT_BIAS_DESC);
                    oc2 = struct('NAME', 'P2_CURRENT',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', obj.CURRENT_BIAS_DESC);
                    oc3 = struct('NAME', 'P1_P2_VOLTAGE', obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', 'MEASURED VOLTAGE DIFFERENCE.');
                    
                    oc3 = createLBL.optionally_add_MISSING_CONSTANT(obj.generatingDeriv1, obj.MISSING_CONSTANT, oc3, ...
                        sprintf('A value of %g means that the original sample was saturated.', obj.MISSING_CONSTANT));
                %else
                %    error('Error, bad combination of values isDensityMode and isEFieldMode.');
                end
                ocl(end+1:end+3) = {oc1; oc2; oc3};
                
            end
            
            % Add quality flag column.
            if obj.generatingDeriv1
                ocl{end+1} = struct('NAME', 'QUALITY_FLAG', 'DATA_TYPE', 'ASCII_INTEGER', 'UNIT', obj.NO_ODL_UNIT, 'BYTES',  5, ...
                    'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            end
            
            OBJECT_COLUMN_list = ocl;
            
        end
        
        
        
        % BxS
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_BxS_data(obj, probeNbr, table_DESCRIPTION_prefix)
            table_DESCRIPTION = sprintf('%s Sweep step bias and time between each step', table_DESCRIPTION_prefix);   % Remove ref. to old DESCRIPTION? (Ex: D_SWEEP_P1_RAW_16BIT_BIP)
            
            
            
            %ocl = [];
            oc1 = struct('NAME', 'SWEEP_TIME',                     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'SECONDS');     % NOTE: Always ASCII_REAL, including for EDDER!!!
            oc2 = struct('NAME', sprintf('P%i_VOLTAGE', probeNbr), obj.DATA_DATA_TYPE{:},     'BYTES', 14, obj.DATA_UNIT_VOLTAGE{:});
            
            if ~obj.generatingDeriv1
                oc1.DESCRIPTION = sprintf(['Elapsed time (s/c clock time) from first sweep measurement. ', ...
                    'Negative time refers to samples taken just before the actual sweep for technical reasons. ', ...
                    'A value of %g refers to that there was no such pre-sweep sample for any sweep in this command block.'], obj.MISSING_CONSTANT);
                oc1.MISSING_CONSTANT = obj.MISSING_CONSTANT;
                
                oc2.DESCRIPTION = sprintf('Bias voltage. A value of %g refers to that the bias voltage is unknown (all pre-sweep bias voltages).', obj.MISSING_CONSTANT);
                oc2.MISSING_CONSTANT = obj.MISSING_CONSTANT;
            else
                oc1.DESCRIPTION = 'Elapsed time (s/c clock time) from first sweep measurement.';
                oc2.DESCRIPTION = obj.VOLTAGE_BIAS_DESC;
            end
            
            %ocl{end+1} = oc1;
            %ocl{end+1} = oc2;
            
            OBJECT_COLUMN_list = {oc1, oc2};
        end
        
        
        
        % IMPLEMENTATION NOTE: Just using table_DESCRIPTION as argument and return value without modification to maintain similarity
        % with other functions for the moment. Might want to eliminate later.
        %
        % nTabColumns : Total number of columns in TAB file. Used to set ITEMS (number of other columns is first
        % subtracted internally).
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_IxS_data(obj, probeNbr, table_DESCRIPTION, bxsTabFilename, nTabColumns)
            table_DESCRIPTION = table_DESCRIPTION;   % No modification(!)
            
            
            
            ocl = {};
            
            oc1 = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'Sweep start UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.');
            oc2 = struct('NAME',  'STOP_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION',  'Sweep stop UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.');
            oc3 = struct('NAME', 'START_TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION', 'Sweep start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            oc4 = struct('NAME',  'STOP_TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION',  'Sweep stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            if ~obj.generatingDeriv1
                oc1.DESCRIPTION = [oc1.DESCRIPTION, sprintf(' This effectively refers to the %g''th sample.', obj.nFinalPresweepSamples+1)];
                oc3.DESCRIPTION = [oc3.DESCRIPTION, sprintf(' This effectively refers to the %g''th sample.', obj.nFinalPresweepSamples+1)];
            end
            ocl(end+1:end+4) = {oc1, oc2, oc3, oc4};
            
            if obj.generatingDeriv1
                ocl{end+1} = struct('NAME', 'QUALITY_FLAG', 'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            end
            
            % NOTE: The file referenced in column DESCRIPTION is expected to have the wrong name since files are renamed by other code
            % before delivery. The delivery code should already correct for this.
            oc = struct(...
                'NAME', sprintf('P%i_SWEEP_CURRENT', probeNbr), obj.DATA_DATA_TYPE{:}, 'ITEM_BYTES', 14, obj.DATA_UNIT_CURRENT{:}, ...
                'ITEMS', nTabColumns - length(ocl), ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            
            if ~obj.generatingDeriv1
                oc.DESCRIPTION = sprintf([...
                    'One current for each of the voltage potential sweep steps described by %s. ', ...
                    'A value of %g refers to that no such sample was ever taken.'], bxsTabFilename, obj.MISSING_CONSTANT);
            else
                oc.DESCRIPTION = sprintf([...
                    'One current for each of the voltage potential sweep steps described by %s. ', ...
                    'Each current is the average over one or multiple measurements on a single potential step. ', ...
                    'A value of %g refers to ', ...
                    '(1) that the underlying set of samples contained at least one saturated value, and/or ', ...
                    '(2) there were no samples which were not disturbed by RPCMIP left to make an average over.'], bxsTabFilename, obj.MISSING_CONSTANT);
            end
            ocl{end+1} = oc;
            
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        % IxD, VxD.
        % NOTE: Both for density mode and E field mode.
        %
        % IMPLEMENTATION NOTE: Start & stop timestamps in header PDS keywords cover a smaller time interval than
        % the actual content of downsampled files. Therefore using the actual content of the TAB file to derive
        % these values.
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_IVxD_data(obj, probeNbr, table_DESCRIPTION_prefix, samplingRateSeconds, isDensityMode)
            
            mcDescrAmendment = sprintf('A value of %g means that the underlying time period which was averaged over contained at least one saturated value.', obj.MISSING_CONSTANT);
            
            
            
            table_DESCRIPTION = sprintf('%s %g SECONDS DOWNSAMPLED', table_DESCRIPTION_prefix, samplingRateSeconds);
            
            ocl = {};
            % IMPLEMENTATION NOTE: The LBL start and stop timestamps of the source EDITED1/CALIB1 files often do
            % NOT cover the time interval of the downsampled time series. This is due to downsampling creating its
            % own timestamps. Must therefore actually read the LBL start & stop timestamps from the actual content
            % of the TAB file.
            % IMPLEMENTATION NOTE: Columns TIME_UTC and TIME_OBT match for the first timestamp, but not do not match
            % well enough for the last timestamp for DVAL-NG not to give a warning. This is due to(?) the
            % downsampling code taking some shortcuts in producing the sequence of OBT+UTC values, i.e. manually
            % producing the series and NOT using SPICE for every such pair. Therefore using the last TIME_OBT value
            % for both SPACECRAFT_CLOCK_STOP_COUNT and STOP_TIME.
            ocl{end+1} = struct('NAME', 'TIME_UTC', 'UNIT', 'SECONDS',   'BYTES', 23, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFF',                              'useFor', {{'START_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT', 'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT', 'STOP_TIME_from_OBT'}});
            
            oc1 = struct('NAME', sprintf('P%i_CURRENT',        probeNbr), obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, obj.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'AVERAGED CURRENT.');
            oc2 = struct('NAME', sprintf('P%i_CURRENT_STDDEV', probeNbr), obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, obj.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'CURRENT STANDARD DEVIATION.');
            oc3 = struct('NAME', sprintf('P%i_VOLTAGE',        probeNbr), obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, obj.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'AVERAGED VOLTAGE.');
            oc4 = struct('NAME', sprintf('P%i_VOLTAGE_STDDEV', probeNbr), obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, obj.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'VOLTAGE STANDARD DEVIATION.');
            
            oc1 = createLBL.optionally_add_MISSING_CONSTANT(isDensityMode,  obj.MISSING_CONSTANT, oc1 , mcDescrAmendment);
            oc2 = createLBL.optionally_add_MISSING_CONSTANT(isDensityMode,  obj.MISSING_CONSTANT, oc2 , mcDescrAmendment);
            oc3 = createLBL.optionally_add_MISSING_CONSTANT(~isDensityMode, obj.MISSING_CONSTANT, oc3 , mcDescrAmendment);
            oc4 = createLBL.optionally_add_MISSING_CONSTANT(~isDensityMode, obj.MISSING_CONSTANT, oc4 , mcDescrAmendment);
            ocl(end+1:end+4) = {oc1; oc2; oc3; oc4};
            
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG', 'BYTES', 5, 'DATA_TYPE', 'ASCII_INTEGER', 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_FRQ_data(obj, nTabColumnsTotal, psdTabFilename)
            table_DESCRIPTION = 'FREQUENCY LIST OF PSD SPECTRA FILE';
            
            ocl = {};
            % NOTE: References file (filename) in DESCRIPTION which could potentially be wrong name in delivered
            % data sets which uses other filenaming convention. However, the delivery code should update this string
            % to contain the correct filename when building final datasets for delivery.
            ocl{end+1} = struct('NAME', 'FREQUENCY_LIST', 'ITEMS', nTabColumnsTotal, 'UNIT', 'Hz', 'ITEM_BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', ...
                'DESCRIPTION', sprintf('FREQUENCY LIST OF PSD SPECTRA FILE %s', psdTabFilename));
            LblData.OBJTABLE.OBJCOL_list = ocl;
            
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_PSD_data(obj, probeNbr, isDensityMode, nTabColumns, modeStr)
            % PROPOSAL: Expand "PSD" to "POWER SPECTRAL DENSITY" (correct according to EAICD).
            table_DESCRIPTION = sprintf('%s PSD SPECTRA OF HIGH FREQUENCY MEASUREMENT', modeStr);
            
            
            
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_UTC', 'UNIT', 'SECONDS',       'BYTES', 26, 'DATA_TYPE', 'TIME',          'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_UTC',  'UNIT', 'SECONDS',       'BYTES', 26, 'DATA_TYPE', 'TIME',          'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_OBT', 'UNIT', 'SECONDS',       'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',    'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_OBT',  'UNIT', 'SECONDS',       'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',    'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)');
            ocl1{end+1} = struct('NAME', 'QUALITY_FLAG',           'UNIT', obj.NO_ODL_UNIT, 'BYTES',  5, 'DATA_TYPE', 'ASCII_INTEGER', 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            
            ocl2 = {};
            mcDescrAmendment = sprintf('A value of %g means that there was at least one saturated sample in the same time interval uninterrupted by RPCMIP disturbances.', obj.MISSING_CONSTANT);
            if isDensityMode
                
                if probeNbr == 3
                    ocl2{end+1} = struct('NAME', 'P1_P2_CURRENT_MEAN',                  obj.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', ['MEASURED CURRENT DIFFERENCE MEAN. ', mcDescrAmendment], 'MISSING_CONSTANT', obj.MISSING_CONSTANT);
                    ocl2{end+1} = struct('NAME', 'P1_VOLTAGE_MEAN',                     obj.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                    ocl2{end+1} = struct('NAME', 'P2_VOLTAGE_MEAN',                     obj.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                else
                    ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', probeNbr), obj.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', ['MEASURED CURRENT MEAN. ', mcDescrAmendment], 'MISSING_CONSTANT', obj.MISSING_CONSTANT);
                    ocl2{end+1} = struct('NAME', sprintf('P%i_VOLTAGE_MEAN', probeNbr), obj.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                end
                PSD_DESCRIPTION = 'PSD CURRENT SPECTRUM';
                PSD_UNIT        = 'NANOAMPERE^2/Hz';
                
            else    %if isEFieldMode
                
                if probeNbr == 3
                    ocl2{end+1} = struct('NAME', 'P1_CURRENT_MEAN',    obj.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', obj.CURRENT_BIAS_DESC);
                    ocl2{end+1} = struct('NAME', 'P2_CURRENT_MEAN',    obj.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', obj.CURRENT_BIAS_DESC);
                    ocl2{end+1} = struct('NAME', 'P1_P2_VOLTAGE_MEAN', obj.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', ['MEASURED VOLTAGE DIFFERENCE MEAN. ', mcDescrAmendment], 'MISSING_CONSTANT', obj.MISSING_CONSTANT);
                else
                    ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', probeNbr), obj.DATA_UNIT_CURRENT{:}, 'DESCRIPTION',      'BIAS CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('P%i_VOLTAGE_MEAN', probeNbr), obj.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', ['MEASURED VOLTAGE MEAN', mcDescrAmendment], 'MISSING_CONSTANT', obj.MISSING_CONSTANT);
                end
                PSD_DESCRIPTION = 'PSD VOLTAGE SPECTRUM';
                PSD_UNIT        = 'VOLT^2/Hz';
                
            %else
            %    error('Error, bad combination of isDensityMode and isEFieldMode.');
            end
            nSpectrumColumns = nTabColumns - (length(ocl1) + length(ocl2));
            ocl2{end+1} = struct('NAME', sprintf('PSD_%s', modeStr), 'ITEMS', nSpectrumColumns, 'UNIT', PSD_UNIT, 'DESCRIPTION', PSD_DESCRIPTION);
            
            % For all columns: Set ITEM_BYTES/BYTES.
            for iOc = 1:length(ocl2)
                if isfield(ocl2{iOc}, 'ITEMS')    ocl2{iOc}.ITEM_BYTES = 14;
                else                              ocl2{iOc}.BYTES      = 14;
                end
                ocl2{iOc}.DATA_TYPE = 'ASCII_REAL';
            end
            
            OBJECT_COLUMN_list = [ocl1, ocl2];
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_PHO_data(obj)
            table_DESCRIPTION = 'Photosaturation current derived collectively from multiple sweeps (not just an average of multiple estimates).';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',            'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME', 'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',            'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'I_PH0',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'AMPERE',    'DESCRIPTION', ...
                ['Photosaturation current derived collectively from multiple sweeps (not just an average of multiple estimates).', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'I_PH0_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',        'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        % NOTE: BUG in Lapdog. UTC sometimes has 3 and sometimes 6 decimals. ==> Assertions will fail sometimes.
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_USC_data(obj)
            table_DESCRIPTION = 'Proxy for spacecraft potential, derived from either (1) zero current crossing in sweep, or (2) floating potential measurement (downsampled). Time interval can thus refer to either sweep or individual sample.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',                     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFF. Middle point for sweeps.',                              'useFor', {{'START_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',                     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point). Middle point for sweeps.', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT', 'STOP_TIME_from_OBT'}});
            ocl{end+1} = struct('NAME', 'V_SC_POT_PROXY',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',      'DESCRIPTION', ...
                ['Proxy for spacecraft potential derived from either (1) photoelectron knee in sweep, or (2) floating potential measurement (downsampled), depending on available data.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_SC_POT_PROXY_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',                 'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            
            OBJECT_COLUMN_list = ocl;
        end
        

        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_ASW_data(obj)
            % ASW = Analyzed sweep parameters
            table_DESCRIPTION = 'Analyzed sweeps (ASW). Miscellaneous physical high-level quantities derived from individual sweeps.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Start UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME'}});
            ocl{end+1} = struct('NAME',  'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION',  'Stop UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT'}});
            ocl{end+1} = struct('NAME',  'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION',  'Stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'N_E',                           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'cm**-3',    'DESCRIPTION', ['Electron density derived from individual sweep.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'N_E_QUALITY_VALUE',             'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'I_PH0',                         'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'AMPERE',    'DESCRIPTION', ...
                ['Photosaturation current derived from individual sweep.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'I_PH0_QUALITY_VALUE',           'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'V_ION_BULK_XCAL',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'm/s',       ...
                'DESCRIPTION', ['Ion bulk speed derived from individual sweep (speed; always non-negative scalar). Cross-calibrated with RPCMIP.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_ION_BULK_XCAL_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'T_E',                           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'eV',        ...
                'DESCRIPTION', ['Electron temperature derived from exponential part of sweep.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'T_E_QUALITY_VALUE',             'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'T_E_XCAL',                      'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'eV',        ...
                'DESCRIPTION', ['Electron temperature, derived by using the linear part of the electron current of the sweep, and density measurement from RPCMIP.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'T_E_XCAL_QUALITY_VALUE',        'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'V_PH_KNEE',                     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',      ...
                'DESCRIPTION', ['Photoelectron knee potential.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_PH_KNEE_QUALITY_VALUE',       'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',                  'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_NPL_data(obj)
            table_DESCRIPTION = 'Plasma density derived from individual fix-bias density mode (current) measurements.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',       'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME', 'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',       'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'N_PL',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'cm**-3',    'DESCRIPTION', ...
                ['Plasma density derived from individual fix-bias density mode (current) measurements. Parameter derived from low time resolution estimates of the plasma density from either RPCLAP or RPCMIP (changes over time).', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'QUALITY_VALUE',  'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',   'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_AxS_data(obj, ixsFilename)
            table_DESCRIPTION = sprintf('MODEL FITTED ANALYSIS OF %s SWEEP FILE', ixsFilename);
            
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'START_TIME_UTC',  'UNIT', 'SECONDS',       'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Start time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_UTC',   'UNIT', 'SECONDS',       'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION',  'Stop time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'START_TIME_OBT',  'UNIT', 'SECONDS',       'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Start time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_OBT',   'UNIT', 'SECONDS',       'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION',  'Stop time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
            ocl1{end+1} = struct('NAME', 'Qualityfactor',   'UNIT', obj.NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Quality factor from 0-100.');   % TODO: Correct?
            ocl1{end+1} = struct('NAME', 'SAA',             'UNIT', 'degrees',       'BYTES',  7, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Solar aspect angle in spacecraft XZ plane, measured from Z+ axis.');
            ocl1{end+1} = struct('NAME', 'Illumination',    'UNIT', obj.NO_ODL_UNIT, 'BYTES',  4, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl1{end+1} = struct('NAME', 'direction',       'UNIT', obj.NO_ODL_UNIT, 'BYTES',  1, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            % ----- (NOTE: Switching from ocl1 to ocl2.) -----
            ocl2 = {};
            ocl2{end+1} = struct('NAME', 'old_Vsi',                'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old_Vx',                 'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential + Te from electron current fit. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vsg',                    'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'sigma_Vsg',              'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'old_Tph',                'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron temperature. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old_Iph0',               'UNIT', 'A',         'DESCRIPTION', 'Photosaturation current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vb_lastnegcurrent',      'UNIT', 'V',         'DESCRIPTION', 'bias potential below zero current.');
            ocl2{end+1} = struct('NAME', 'Vb_firstposcurrent',     'UNIT', 'V',         'DESCRIPTION', 'bias potential above zero current.');
            ocl2{end+1} = struct('NAME', 'Vbinfl',                 'UNIT', 'V',         'DESCRIPTION', 'Bias potential of inflection point in current.');
            ocl2{end+1} = struct('NAME', 'dIinfl',                 'UNIT', 'A/V',       'DESCRIPTION', 'Derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'd2Iinfl',                'UNIT', 'A/V^2',     'DESCRIPTION', 'Second derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'Iph0',                   'UNIT', 'A',         'DESCRIPTION', 'Photosaturation current.');
            ocl2{end+1} = struct('NAME', 'Tph',                    'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron temperature.');
            ocl2{end+1} = struct('NAME', 'Vsi',                    'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current.');
            ocl2{end+1} = struct('NAME',       'Vph_knee',         'UNIT', 'V',         'DESCRIPTION',                               'Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');
            ocl2{end+1} = struct('NAME', 'sigma_Vph_knee',         'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');
            ocl2{end+1} = struct('NAME',       'Te_linear',        'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ne_linear',        'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_ne_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ion_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_slope',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential');
            ocl2{end+1} = struct('NAME',       'ion_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_intersect',    'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_slope',          'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_slope',          'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_intersect',      'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_intersect',      'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'ion_Vb_intersect', 'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_Vb_intersect', 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'e_Vb_intersect',   'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_Vb_intersect',   'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable).');
            ocl2{end+1} = struct('NAME', 'nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable).');
            ocl2{end+1} = struct('NAME',       'phc_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_slope',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'phc_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_intersect',    'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'ne_5eV',                 'UNIT', 'cm^-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming electron temperature Te = 5 eV.');
            ocl2{end+1} = struct('NAME', 'ni_v_dep',               'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity.');
            ocl2{end+1} = struct('NAME', 'ni_v_indep',             'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate.');
            ocl2{end+1} = struct('NAME', 'v_ion',                  'UNIT', 'm/s',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate.');
            ocl2{end+1} = struct('NAME',       'Te_exp',           'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ne_exp',           'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_ne_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron density derived from fit of exponential part of the thermal electron current.');
            
            ocl2{end+1} = struct('NAME', 'Rsquared_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current.');
            ocl2{end+1} = struct('NAME', 'Rsquared_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current.');
            
            ocl2{end+1} = struct('NAME',       'Vbar',             'UNIT', obj.ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'sigma_Vbar',             'UNIT', obj.ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');
            
            ocl2{end+1} = struct('NAME', 'ASM_Iph0',                   'UNIT', 'A',         'DESCRIPTION', 'Assumed photosaturation current used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'ASM_Tph',                    'UNIT', 'eV',        'DESCRIPTION', 'Assumed photoelectron temperature used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Vsi',                    'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_Te_linear',        'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ne_linear',        'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'sigma_asm_ne_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_slope',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_intersect',    'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_slope',          'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_slope',          'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_intersect',      'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_intersect',      'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_Vb_intersect', 'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_intersect', 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_Vb_intersect',   'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_intersect',   'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_phc_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_slope',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_phc_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_intersect',    'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ne_5eV',                 'UNIT', 'cm^-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming Te= 5eV. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_dep',               'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_indep',             'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_v_ion',                  'UNIT', 'm/s',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_Te_exp',           'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ne_exp',           'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron density derived from fit of exponential part of the thermal electron current.');
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
            ocl2{end+1} = struct('NAME', 'ASM_m_ion',      'BYTES', 3, 'UNIT', 'amu',               'DESCRIPTION', 'Assumed ion mass for all ions.');
            ocl2{end+1} = struct('NAME', 'ASM_Z_ion',      'BYTES', 2, 'UNIT', 'Elementary charge', 'DESCRIPTION', 'Assumed ion charge for all ions.');
            ocl2{end+1} = struct('NAME', 'ASM_v_ion',                  'UNIT', 'm/s',               'DESCRIPTION', 'Assumed ion ram speed in used in *_v_dep variables.');
            ocl2{end+1} = struct('NAME',     'Vsc_ni_ne',              'UNIT', 'V',                 'DESCRIPTION', 'Spacecraft potential needed to produce identical ion (ni_v_indep) and electron (ne_linear) densities.');
            ocl2{end+1} = struct('NAME', 'asm_Vsc_ni_ne',              'UNIT', 'V',                 'DESCRIPTION', 'Spacecraft potential needed to produce identical ion (asm_ni_v_indep) and electron (asm_ne_linear) densities. Fixed photoelectron current assumption.');
            
            ocl2{end+1} = struct('NAME', 'Vsc_aion',                  'UNIT', 'V',      'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'ni_aion',                   'UNIT', 'cm^-3',  'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'v_aion',                    'UNIT', 'm/s',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_Vsc_aion',              'UNIT', 'V',      'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_ni_aion',               'UNIT', 'cm^-3',  'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_v_aion',                'UNIT', 'm/s',    'DESCRIPTION', '');
            %---------------------------------------------------------------------------------------------------
            
            ocl2{end+1} = struct('NAME',           'Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',     'sigma_Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',           'ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',     'sigma_ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',       'asm_Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp_belowVknee', 'UNIT', 'eV',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',       'asm_ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp_belowVknee', 'UNIT', 'cm^-3', 'DESCRIPTION', '');
            
            for iOc = 1:length(ocl2)
                if ~isfield(ocl2{iOc}, 'BYTES')
                    ocl2{iOc}.BYTES = 14;
                end
                ocl2{iOc}.DATA_TYPE = 'ASCII_REAL';
            end
            
            OBJECT_COLUMN_list = [ocl1, ocl2];
            
        end    % get_AxS_data()
        
        
        
        % NOTE: Label files are not delivered.
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_EST_data(obj)
            table_DESCRIPTION = sprintf('BEST ESTIMATES OF PHYSICAL VALUES FROM MODEL FITTED ANALYSIS.');   % Bad description? To specific?
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',       'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',       'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',       'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
            ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',       'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',       'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'npl',                'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'CM**-3',        'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of plasma number density.');
            ocl{end+1} = struct('NAME', 'Te',                 'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'eV',            'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of electron temperature.');
            ocl{end+1} = struct('NAME', 'Vsc',                'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'V',             'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of spacecraft potential.');
            ocl{end+1} = struct('NAME', 'Probe_number',       'DATA_TYPE', 'ASCII_REAL',    'BYTES',  1, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Probe number. 1 or 2.');
            ocl{end+1} = struct('NAME', 'Direction',          'DATA_TYPE', 'ASCII_REAL',    'BYTES',  1, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            ocl{end+1} = struct('NAME', 'Illumination',       'DATA_TYPE', 'ASCII_REAL',    'BYTES',  4, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl{end+1} = struct('NAME', 'Sweep_group_number', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', ...
                ['Number signifying which group of sweeps the data comes from. ', ...
                'Groups of sweeps are formed for the purpose of deriving/selecting values to be used in best estimates. ', ...
                'All sweeps with the same group number are almost simultaneous. For every type of best estimate, at most one is chosen from each group.' ...
                ]);  % NOTE: Causes trouble by making such a long line in LBL file?!!
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        % NOTE: Label files are not delivered.
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_A1P_data(obj)
            table_DESCRIPTION = 'ANALYZED PROBE 1 PARAMETERS';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',       'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME',  'STOP_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',       'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',       'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME',  'STOP_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',       'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME', 'QUALITY',            'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  4, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (BEST) TO 777 (WORST).');
            ocl{end+1} = struct('NAME', 'Vph_knee',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',         'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Potential at probe position from photoelectron current knee (gaussian fit of second derivative).');
            ocl{end+1} = struct('NAME', 'Te_exp_belowVknee',  'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'ELECTRONVOLT', 'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Electron temperature from an exponential fit to the slope of the retardation region of the electron current.');
            OBJECT_COLUMN_list = ocl;
            
        end
        
        
        
    end    % methods(...)
    
end   % classdef