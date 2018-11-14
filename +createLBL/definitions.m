%
% DESIGN INTENT
% =============
% Class which stores hard-coded data related to specific LBL files, at least columns. Presently a bit unclear exactly
% what hard-coded data should be included.
% Should at least collects functions which define and return data structures defining LBL files, one file/data type per function.
%
% The class is instantiated with variable values which are likely constant during a session, and can be used by
% the methods (e.g. whether EDDER/DERIV1, MISSING_CONSTANT).
%
%
% NAMING CONVENTIONS, CONVENTIONS
% ===============================
% data : Refers to LBL file data
% OCL  : Object Column List
% KVPL : Key-Value Pair List
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
    % PROPOSAL: Better name.
    %   PROPOSAL: definition_creator, LBL_definition_creator.
    %       CON: Bad if using class for updating LBL header in the future.
    %
    % PROPOSAL: Submit (instance of) createLBL.constants instead of having field for MISSING_CONSTANT, N_FINAL_SWEEP_SAMPLES.
    % PROPOSAL: Internally call createLBL.constants to eliminate arguments.
    %
    % PROPOSAL: Help functions for setting specific types of column descriptions.
    %   PRO: Does not need to write out struct field names: NAME, DESCRIPTION etc.
    %   PRO: Automatically handle EDDER/DERIV1 differences.
    %   --
    %   TODO-DECISION: Need to think about how to handle DERIV2 TAB columns (here part of DERIV1)?
    %   --
    %   PROPOSAL: Automatically set constants for BYTES, DATA_TYPE, UNIT (implicit from choice of helper function).
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
    %
    % TODO-DECISION: How handle difference root-level and OBJECT=TABLE-level DESCRIPTION ?
    %   PROPOSAL: Eliminate one of them.
    %   PROPOSAL: Have both be identical.
    %   NOTE: Root-level DESCRIPTION can be inherited from pds.
    %
    % PROPOSAL: Modify ROSETTA:LAP_Px_ADC16_FILTER to upper case?


    
    properties(Access=private)
        % NO_ODL_UNIT: Constant to be used for LBL "UNIT" fields meaning that there is no unit.
        % This means that it is known that the quantity has no unit rather than that the unit
        % is simply unknown at present.
        NO_ODL_UNIT        = [];
        
        ODL_VALUE_UNKNOWN  = 'UNKNOWN';   %'<Unknown>';  % Unit is unknown. Should NOT be used for official deliveries.

        % Assigned via constructor argument, not the createLBL.constants object/class. Capitalized since it is a PDS
        % keyword.
        MISSING_CONSTANT
        nFinalPresweepSamples   % Assigned via constructor argument, not the createLBL.constants object/class.
        indentationLength
        
        generatingDeriv1
        
        MC_DESC_AMENDM       % Generic description string for MISSING_CONSTANT (MC). Is added at end of DESCRIPTION.
        QFLAG1_DESCRIPTION = 'Quality flag constructed as the sum of multiple terms, depending on what quality related effects are present. From 00000 (best) to 77777 (worst).';
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
        function obj = definitions(generatingDeriv1, MISSING_CONSTANT, nFinalPresweepSamples, indentationLength)
            
            % ASSERTIONS
            assert(isscalar(nFinalPresweepSamples) && isnumeric(nFinalPresweepSamples))
            assert(isscalar(MISSING_CONSTANT)      && isnumeric(MISSING_CONSTANT))
            

            
            obj.MISSING_CONSTANT      = MISSING_CONSTANT;
            obj.nFinalPresweepSamples = nFinalPresweepSamples;
            obj.indentationLength     = indentationLength;
            obj.generatingDeriv1      = generatingDeriv1;
            
            obj.MC_DESC_AMENDM        = sprintf(' A value of %e refers to that there is no value.', obj.MISSING_CONSTANT);    % Amendment to other strings. Therefore begins with whitespace.
            
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
                obj.VOLTAGE_BIAS_DESC =          'Calibrated voltage bias.';
                obj.VOLTAGE_MEAS_DESC = 'Measured calibrated voltage.';
                obj.CURRENT_BIAS_DESC =          'Calibrated current bias.';
                obj.CURRENT_MEAS_DESC = 'Measured calibrated current.';
            else
                % CASE: EDDER run
                obj.DATA_DATA_TYPE    = {'DATA_TYPE', 'ASCII_INTEGER'};
                obj.DATA_UNIT_CURRENT = {'UNIT', 'N/A'};
                obj.DATA_UNIT_VOLTAGE = {'UNIT', 'N/A'};
                obj.VOLTAGE_BIAS_DESC =          'Voltage bias.';
                obj.VOLTAGE_MEAS_DESC = 'Measured voltage.';
                obj.CURRENT_BIAS_DESC =          'Current bias.';
                obj.CURRENT_MEAS_DESC = 'Measured current.';
            end
        end
        
        
        
        function LblData = get_BLKLIST_data(obj, HeaderKvpl)
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-12', 'EJ', 'Descriptions clean-up, lowercase'}});
            
            LblData.HeaderKvpl = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Blocklist data. Start & stop time and macro ID of executed macro blocks.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECONDS',       'DESCRIPTION', 'Start time of macro block, YYYY-MM-DD HH:MM:SS.sss.');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',  'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECONDS',       'DESCRIPTION', 'Last start time of macro block file YYYY-MM-DD HH:MM:SS.sss.');    % Correct? File?
            ocl{end+1} = struct('NAME', 'MACRO_ID',       'DATA_TYPE', 'CHARACTER', 'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Hexadecimal macro identification number.');
            
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end
        
        
        
        function LblData = get_IVxHL_data(obj, HeaderKvpl, isDensityMode, probeNbr, table_DESCRIPTION)
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-12', 'EJ', 'Descriptions clean-up, lowercase'}});
            
            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = table_DESCRIPTION;   % No modification(!)
            
            ocl = {};
            ocl{end+1} = struct('NAME', 'TIME_UTC', 'DATA_TYPE', 'TIME',       'UNIT', 'SECONDS', 'BYTES', 26, 'DESCRIPTION', 'UTC time.');
            ocl{end+1} = struct('NAME', 'TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'UNIT', 'SECONDS', 'BYTES', 16, 'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            
            if probeNbr ~=3
                
                % CASE: P1 or P2
                currentOc = struct('NAME', sprintf('P%i_CURRENT', probeNbr), obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14);
                voltageOc = struct('NAME', sprintf('P%i_VOLTAGE', probeNbr), obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14);
                if isDensityMode
                    currentOc.DESCRIPTION = obj.CURRENT_MEAS_DESC;   % measured
                    voltageOc.DESCRIPTION = obj.VOLTAGE_BIAS_DESC;   % bias
                    currentOc = createLBL.optionally_add_MISSING_CONSTANT(obj.generatingDeriv1, obj.MISSING_CONSTANT, currentOc, ...
                        sprintf('A value of %g means that the original sample was saturated.', obj.MISSING_CONSTANT));   % NOTE: Modifies currentOc.
                else
                    % CASE: E Field Mode
                    currentOc.DESCRIPTION = obj.CURRENT_BIAS_DESC;   % bias
                    voltageOc.DESCRIPTION = obj.VOLTAGE_MEAS_DESC;   % measured
                    voltageOc = createLBL.optionally_add_MISSING_CONSTANT(obj.generatingDeriv1, obj.MISSING_CONSTANT, voltageOc, ...
                        sprintf('A value of %g means that the original sample was saturated.', obj.MISSING_CONSTANT));   % NOTE: Modifies voltageOc.
                end
                ocl{end+1} = currentOc;
                ocl{end+1} = voltageOc;
                
            else
                
                % CASE: P3
                %error('This code segment has not yet been completed for P3. Can not create LBL file for "%s".', stabindex(i).path)
                if isDensityMode
                    % This case occurs at least on 2005-03-04 (EAR1). Appears to be the only day with V3x data for the
                    % entire mission. Appears to only happen for HF, but not LF.
                    oc1 = struct('NAME', 'P1_P2_CURRENT', obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', 'Measured current difference.');
                    oc2 = struct('NAME', 'P1_VOLTAGE',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                    oc3 = struct('NAME', 'P2_VOLTAGE',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                    
                    oc1 = createLBL.optionally_add_MISSING_CONSTANT(obj.generatingDeriv1, obj.MISSING_CONSTANT, oc1, ...
                        sprintf('A value of %g means that the original sample was saturated.', obj.MISSING_CONSTANT));
                else    %if isEFieldMode
                    % This case occurs at least on 2007-11-07 (EAR2), which appears to be the first day it occurs.
                    % This case does appear to occur for HF, but not LF.
                    oc1 = struct('NAME', 'P1_CURRENT',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', obj.CURRENT_BIAS_DESC);
                    oc2 = struct('NAME', 'P2_CURRENT',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', obj.CURRENT_BIAS_DESC);
                    oc3 = struct('NAME', 'P1_P2_VOLTAGE', obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', 'Measured voltage difference.');
                    
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
            
            LblData.OBJTABLE.OBJCOL_list = ocl;
            
        end
        
        
        
        function LblData = get_BxS_data(obj, HeaderKvpl, probeNbr, table_DESCRIPTION_prefix, ixsTabFilename)
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-12', 'EJ', 'Descriptions clean-up, lowercase'}});
            
            LblData.HeaderKvpl = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = sprintf('%s. Description of the sweep voltage bias steps associated with the measurements in %s.', ...
                table_DESCRIPTION_prefix, ixsTabFilename);   % Remove ref. to old DESCRIPTION? (Ex: D_SWEEP_P1_RAW_16BIT_BIP)
            
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
            
            LblData.OBJTABLE.OBJCOL_list = {oc1, oc2};
        end
        
        
        
        % nTabColumns : Total number of columns in TAB file. Used to set ITEMS (number of other columns is first
        %               subtracted internally).
        function LblData = get_IxS_data(obj, HeaderKvpl, probeNbr, table_DESCRIPTION_prefix, bxsTabFilename, nTabColumns)
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-12', 'EJ', 'Descriptions clean-up, lowercase'}});
                        
            LblData.OBJTABLE.DESCRIPTION = sprintf('%s. Sweep, i.e. measured currents while the bias voltage sweeps over a continuous range of values.', table_DESCRIPTION_prefix);
            LblData.HeaderKvpl = HeaderKvpl;
            
            ocl = {};
            
            oc1 = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'Sweep start UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            oc2 = struct('NAME',  'STOP_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION',  'Sweep stop UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
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
            
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end
        
        
        
        % IxD, VxD.
        % NOTE: Both for density mode and E field mode.
        %
        % IMPLEMENTATION NOTE: Start & stop timestamps in header PDS keywords cover a smaller time interval than
        % the actual content of downsampled files. Therefore using the actual content of the TAB file to derive
        % these values.
        function LblData = get_IVxD_data(obj, HeaderKvpl, probeNbr, table_DESCRIPTION_prefix, samplingRateSeconds, isDensityMode)
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-12', 'EJ', 'Descriptions clean-up, lowercase'}});
            
            LblData.HeaderKvpl = HeaderKvpl;
            
            % Ex: DESCRIPTION = "D_P1P2INTRL_TRNC_20BIT_RAW_BIP, 32 SECONDS DOWNSAMPLED"
            LblData.OBJTABLE.DESCRIPTION = sprintf('%s. Measurements downsampled to a period of %g seconds.', table_DESCRIPTION_prefix, samplingRateSeconds);
            
            mcDescrAmendment = sprintf('A value of %g means that the underlying time period which was averaged over contained at least one saturated value.', obj.MISSING_CONSTANT);
            
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
            ocl{end+1} = struct('NAME', 'TIME_UTC', 'UNIT', 'SECONDS',   'BYTES', 23, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'UTC time YYYY-MM-DD HH:MM:SS.FFF.',                              'useFor', {{'START_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT', 'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT', 'STOP_TIME_from_OBT'}});
            
            oc1 = struct('NAME', sprintf('P%i_CURRENT',        probeNbr), obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, obj.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'Averaged current.');
            oc2 = struct('NAME', sprintf('P%i_CURRENT_STDDEV', probeNbr), obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, obj.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'Current standard deviation.');
            oc3 = struct('NAME', sprintf('P%i_VOLTAGE',        probeNbr), obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, obj.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'Averaged voltage.');
            oc4 = struct('NAME', sprintf('P%i_VOLTAGE_STDDEV', probeNbr), obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, obj.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'Voltage standard deviation.');
            
            oc1 = createLBL.optionally_add_MISSING_CONSTANT(isDensityMode,  obj.MISSING_CONSTANT, oc1 , mcDescrAmendment);
            oc2 = createLBL.optionally_add_MISSING_CONSTANT(isDensityMode,  obj.MISSING_CONSTANT, oc2 , mcDescrAmendment);
            oc3 = createLBL.optionally_add_MISSING_CONSTANT(~isDensityMode, obj.MISSING_CONSTANT, oc3 , mcDescrAmendment);
            oc4 = createLBL.optionally_add_MISSING_CONSTANT(~isDensityMode, obj.MISSING_CONSTANT, oc4 , mcDescrAmendment);
            ocl(end+1:end+4) = {oc1; oc2; oc3; oc4};
            
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG', 'BYTES', 5, 'DATA_TYPE', 'ASCII_INTEGER', 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end
        
        
        
        function LblData = get_FRQ_data(obj, HeaderKvpl, nTabColumnsTotal, psdTabFilename)
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-13', 'EJ', 'Descriptions clean-up, lowercase'}});
            
            LblData.HeaderKvpl = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Frequency list of PSD spectra file.';
            
            ocl = {};
            % NOTE: References file (filename) in DESCRIPTION which could potentially be wrong name in delivered
            % data sets which uses other filenaming convention. However, the delivery code should update this string
            % to contain the correct filename when building final datasets for delivery.
            ocl{end+1} = struct('NAME', 'FREQUENCY_LIST', 'ITEMS', nTabColumnsTotal, 'UNIT', 'Hz', 'ITEM_BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', ...
                'DESCRIPTION', sprintf('Frequenct list of PSD spectra file %s.', psdTabFilename));
            
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end
        
        
        
        function LblData = get_PSD_data(obj, HeaderKvpl, probeNbr, isDensityMode, nTabColumns, modeStr)
            % PROPOSAL: Expand "PSD" to "POWER SPECTRAL DENSITY" (correct according to EAICD).
            % NOTE: Root DESCRIPTION set to pds constant, but OBJECT_TABLE:DESCRIPTION does not use it.
            %   PROPSOAL: Change?
            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-13', 'EJ', 'Descriptions clean-up, lowercase'}});
            
            LblData.HeaderKvpl = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = sprintf('%s PSD spectra of high frequency measurements (snapshots).', modeStr);            
            
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_UTC', 'UNIT', 'SECONDS',       'BYTES', 26, 'DATA_TYPE', 'TIME',          'DESCRIPTION', 'Start UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_UTC',  'UNIT', 'SECONDS',       'BYTES', 26, 'DATA_TYPE', 'TIME',          'DESCRIPTION',  'Stop UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_OBT', 'UNIT', 'SECONDS',       'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',    'DESCRIPTION', 'Start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_OBT',  'UNIT', 'SECONDS',       'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',    'DESCRIPTION',  'Stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl1{end+1} = struct('NAME', 'QUALITY_FLAG',           'UNIT', obj.NO_ODL_UNIT, 'BYTES',  5, 'DATA_TYPE', 'ASCII_INTEGER', 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            
            ocl2 = {};
            mcDescrAmendment = sprintf('A value of %g means that there was at least one saturated sample in the same time interval uninterrupted by RPCMIP disturbances.', obj.MISSING_CONSTANT);
            if isDensityMode
                
                if probeNbr == 3
                    ocl2{end+1} = struct('NAME', 'P1_P2_CURRENT_MEAN',                  obj.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', ['Measured current difference mean. ', mcDescrAmendment], 'MISSING_CONSTANT', obj.MISSING_CONSTANT);
                    ocl2{end+1} = struct('NAME', 'P1_VOLTAGE_MEAN',                     obj.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                    ocl2{end+1} = struct('NAME', 'P2_VOLTAGE_MEAN',                     obj.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                else
                    ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', probeNbr), obj.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', ['Measured current mean. ', mcDescrAmendment], 'MISSING_CONSTANT', obj.MISSING_CONSTANT);
                    ocl2{end+1} = struct('NAME', sprintf('P%i_VOLTAGE_MEAN', probeNbr), obj.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                end
                PSD_DESCRIPTION = 'Current PSD spectrum';
                PSD_UNIT        = 'NANOAMPERE^2/Hz';
                
            else
                % CASE: E-Field Mode
                
                if probeNbr == 3
                    ocl2{end+1} = struct('NAME', 'P1_CURRENT_MEAN',    obj.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', obj.CURRENT_BIAS_DESC);
                    ocl2{end+1} = struct('NAME', 'P2_CURRENT_MEAN',    obj.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', obj.CURRENT_BIAS_DESC);
                    ocl2{end+1} = struct('NAME', 'P1_P2_VOLTAGE_MEAN', obj.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', ['Measured voltage difference mean. ', mcDescrAmendment], 'MISSING_CONSTANT', obj.MISSING_CONSTANT);
                else
                    ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', probeNbr), obj.DATA_UNIT_CURRENT{:}, 'DESCRIPTION',      'Bias current mean');
                    ocl2{end+1} = struct('NAME', sprintf('P%i_VOLTAGE_MEAN', probeNbr), obj.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', ['Measured voltage mean', mcDescrAmendment], 'MISSING_CONSTANT', obj.MISSING_CONSTANT);
                end
                PSD_DESCRIPTION = 'Voltage PSD spectrum';
                PSD_UNIT        = 'VOLT^2/Hz';
                
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
            
            LblData.OBJTABLE.OBJCOL_list = [ocl1, ocl2];
        end
        
        
        
        function LblData = get_PHO_data(obj, HeaderKvpl)
            % IMPLEMENTATION NOTE: Derives timestamps from columns since the Lapdog PHO struct does not contain timing
            % information. TEMPORARY SOLUTION.
            
            %LblKvpl = KVPL_overwrite_add(LblKvpl, ...
            %    {'DATA_SET_PARAMETER_NAME', '{"PHOTOSATURATION CURRENT"}'; ...
            %    'CALIBRATION_SOURCE_ID',    '{"RPCLAP"}'});
            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-08-30', 'EJ', 'Initial version'}, {'2018-11-13', 'EJ', 'Descriptions clean-up, lowercase'}});
            
            LblData.HeaderKvpl = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Photosaturation current derived collectively from multiple sweeps (not just an average of multiple estimates).';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',            'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME', 'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',            'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'I_PH0',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'AMPERE',    'DESCRIPTION', ...
                ['Photosaturation current derived collectively from multiple sweeps (not just an average of multiple estimates).', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'I_PH0_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',        'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end
        

        
        % USC = U_sc = Potential, Spacecraft
            
        % NOTE: BUG in Lapdog. UTC sometimes has 3 and sometimes 6 decimals. ==> Assertions will fail sometimes.
        %   Still true? /EJ 2018-11-06
        function LblData = get_USC_data(obj, HeaderKvpl)
            
            %LblKvpl = KVPL_overwrite_add(LblKvpl, ...
            %    {'DATA_SET_PARAMETER_NAME', '{"SPACECRAFT POTENTIAL"}'; ...
            %    'CALIBRATION_SOURCE_ID',    '{"RPCLAP"}'});
            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-08-29', 'AE', 'Initial version'}, {'2018-11-13', 'EJ', 'Descriptions clean-up, lowercase. 6 UTC decimals'}});
            
            LblData.HeaderKvpl = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Proxy for spacecraft potential, derived from either (1) zero current crossing in sweep, or (2) floating potential measurement (downsampled). Time interval can thus refer to either sweep or individual sample.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',                     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC time YYYY-MM-DD HH:MM:SS.FFF. Middle point for sweeps.');                                % 'useFor', {{'START_TIME'}}
            ocl{end+1} = struct('NAME', 'TIME_OBT',                     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point). Middle point for sweeps.');   % 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT', 'STOP_TIME_from_OBT'}}
            ocl{end+1} = struct('NAME', 'V_SC_POT_PROXY',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',      'DESCRIPTION', ...
                ['Proxy for spacecraft potential derived from either (1) photoelectron knee in sweep, or (2) floating potential measurement (downsampled), depending on available data.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_SC_POT_PROXY_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',                 'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);            
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end
        

        
        % ASW = Analyzed sweep parameters
        function LblData = get_ASW_data(obj, HeaderKvpl)
            % TODO-NEED-INFO: Add SPACECRAFT POTENTIAL for Photoelectron knee potential?
            %LblKvpl = KVPL_overwrite_add(LblKvpl, ...
            %    {'DATA_SET_PARAMETER_NAME', '{"ELECTRON DENSITY", "PHOTOSATURATION CURRENT", "ION BULK VELOCITY", "ELECTRON TEMPERATURE"}'; ...
            %    'CALIBRATION_SOURCE_ID',    '{"RPCLAP", "RPCMIP"}'});
            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-08-30', 'EJ', 'Initial version'}, {'2018-11-13', 'EJ', 'Descriptions clean-up, lowercase'}});
            
            LblData.HeaderKvpl = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Analyzed sweeps (ASW). Miscellaneous physical high-level quantities derived from individual sweeps.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Start UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');   % 'useFor', {{'START_TIME'}}
            ocl{end+1} = struct('NAME',  'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION',  'Stop UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');   % 'useFor', {{'STOP_TIME'}}
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');   % 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT'}}
            ocl{end+1} = struct('NAME',  'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION',  'Stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');   % 'useFor', {{'SPACECRAFT_CLOCK_STOP_COUNT'}}
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
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end
        
        
        
        function LblData = get_NPL_data(obj, HeaderKvpl)
            
            % IMPLEMENTATION NOTE: As of 2018-11-13, no such data product has ever been produced, and therefore no such
            % label file has ever been produced.
            % NOTE: Using this code without setting LABEL_REVISION_NOTE should trigger assertion error (overwriting is
            % required).
            %HeaderKvpl = obj.set_LRN(HeaderKvpl, {});
            
            LblData.HeaderKvpl = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Plasma density derived from individual fix-bias density mode (current) measurements.';
            
            % MB states:
            % """"PLASMA DENSITY [cross-calibration from ion and electron density; in the label, put ELECTRON DENSITY,
            % ION DENSITY and PLASMA DENSITY]""""            
            % TODO-NEED-INFO: Use above?
            
            %LblKvpl = KVPL_overwrite_add(LblKvpl, {...
            %        'DATA_SET_PARAMETER_NAME', '{"ELECTRON_DENSITY", "ION DENSITY", "PLASMA DENSITY"}'; ...
            %        'CALIBRATION_SOURCE_ID',   '{"RPCLAP", "RPCMIP"}'});
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',       'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');                             % 'useFor', {{'START_TIME', 'STOP_TIME'}}
            ocl{end+1} = struct('NAME', 'TIME_OBT',       'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');   % 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}}
            ocl{end+1} = struct('NAME', 'N_PL',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'cm**-3',    'DESCRIPTION', ...
                ['Plasma density derived from individual fix-bias density mode (current) measurements. Parameter derived from low time resolution estimates of the plasma density from either RPCLAP or RPCMIP (changes over time).', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'QUALITY_VALUE',  'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',   'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end



        function LblData = get_AxS_data(obj, HeaderKvpl, ixsFilename)
            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-13', 'EJ', 'First documented version'}});
            
            LblData.HeaderKvpl = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = sprintf('Model fitted analysis of %s sweep file.', ixsFilename);
            
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'START_TIME_UTC',  'UNIT', 'SECONDS',       'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Start time of sweep. UTC time YYYY-MM-DD HH:MM:SS.FFF.');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_UTC',   'UNIT', 'SECONDS',       'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION',  'Stop time of sweep. UTC time YYYY-MM-DD HH:MM:SS.FFF.');
            ocl1{end+1} = struct('NAME', 'START_TIME_OBT',  'UNIT', 'SECONDS',       'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Start time of sweep. Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_OBT',   'UNIT', 'SECONDS',       'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION',  'Stop time of sweep. Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
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
            ocl2{end+1} = struct('NAME', 'Vb_lastnegcurrent',      'UNIT', 'V',         'DESCRIPTION', 'Bias potential below zero current.');
            ocl2{end+1} = struct('NAME', 'Vb_firstposcurrent',     'UNIT', 'V',         'DESCRIPTION', 'Bias potential above zero current.');
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
            ocl2{end+1} = struct('NAME', 'sigma_ion_slope',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential.');
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
            
            LblData.OBJTABLE.OBJCOL_list = [ocl1, ocl2];
            
        end    % get_AxS_data()
        
        
        
        % NOTE: Label files are not delivered.
        function LblData = get_EST_data(obj, HeaderKvpl)
            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-14', 'EJ', 'First documented version'}});
            
            LblData.HeaderKvpl = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = sprintf('Best estimates of physical values from model fitted analysis.');   % Bad description? To specific?
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',       'DESCRIPTION', 'Start UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',       'DESCRIPTION',  'Stop UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',       'DESCRIPTION', 'Start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',       'DESCRIPTION',  'Stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
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
            
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end
        
        
        
        % NOTE: TAB+LBL files will likely not be delivered.
        function LblData = get_A1P_data(obj, HeaderKvpl)

            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-14', 'EJ', 'First documented version'}});

            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Analyzed probe 1 parameters.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',       'DESCRIPTION', 'Start UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl{end+1} = struct('NAME',  'STOP_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',       'DESCRIPTION',  'Stop UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',       'DESCRIPTION', 'Start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl{end+1} = struct('NAME',  'STOP_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',       'DESCRIPTION',  'Stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',       'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  4, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Quality flag from 000 (best) to 777 (worst).');
            ocl{end+1} = struct('NAME', 'Vph_knee',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',         'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Potential at probe position from photoelectron current knee (gaussian fit of second derivative).');
            ocl{end+1} = struct('NAME', 'Te_exp_belowVknee',  'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'ELECTRONVOLT', 'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Electron temperature from an exponential fit to the slope of the retardation region of the electron current.');
            LblData.OBJTABLE.OBJ_COL_list = ocl;
        end
        
        

        % Set LABEL_REVISION_NOTE key value in KVPL.
        % NOTE: Requires key "LABEL_REVISION_NOTE" to already pre-exist in  KVPL
        %
        %
        % RATIONALE
        % =========
        % -- Make sure does not forget to add quotes.
        % -- Can (potentially) force common format: ~indentation, rows, date, author.
        % -- Can potentially limit to only the last N label revisions (items).
        % -- Force correct spelling of LABEL_REVISION_NOTE (which would otherwise be hardcoded in multiple places, although
        %    ".set_value" requires keyword to pre-exist in KVPL, which should help).
        %
        % contentCellArray{iItem} = {dateStr, author, message}
        function Kvpl = set_LRN(obj, Kvpl, contentCellArray)
            % PROPOSAL: Link size of indentation to createLBL.constants.
            % PROPOSAL: Set "author" here. Remove as argument.
            
            LINE_BREAK  = sprintf('\r\n');
            INDENTATION = repmat(' ', 1, obj.indentationLength);
            
            nItems = numel(contentCellArray);
            
            rowList = {};
            for i = 1:nItems
                assert(numel(contentCellArray{i}) == 3)
                
                dateStr = contentCellArray{i}{1};
                author  = contentCellArray{i}{2};
                message = contentCellArray{i}{3};
                rowList{i} = sprintf('%s, %s: %s', dateStr, author, message);
            end

            if nItems == 0
                error('No info to put in LABEL_REVISION_INFO. nItems == 0.')
            elseif nItems == 1
                rowStr = rowList{1};
            elseif nItems >= 2
                % Do not use the first row (in the ODL file).
                rowStr = EJ_lapdog_shared.utils.str_join(rowList, [LINE_BREAK, INDENTATION]);
                rowStr = [LINE_BREAK, INDENTATION, rowStr];
            end

            Kvpl = Kvpl.set_value('LABEL_REVISION_NOTE', sprintf('"%s"', rowStr));    % NOTE: Adds quotes.
        end
    end    % methods
    
end   % classdef
