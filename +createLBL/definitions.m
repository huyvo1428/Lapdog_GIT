%
% DESIGN INTENT
% =============
% Class which, at least for the moment (2018-09-12), is meant to collect public (static) functions which define and
% return data structures defining LBL files, one file/data type per function.
%
% The long-term plan is that all such code in createLBL.m is moved here.
%
%
% NAMING CONVENTIONS
% ==================
% data : Refers to LBL file data.
%
%
% Initially created 2018-09-12 by Erik P G Johansson, IRF Uppsala.
%
classdef definitions
    % NEED: The caller should have control over error-handling, LBL-TAB consistenct checks.
    %
    % TODO-DECISION: Use filenaming conventions consistently for naming corresponding functions.
    %
    % PROPOSAL: Make instantiated (like createLBL.constants)
    %   PRO: Can initialize with "constants" for a particular session.
    %       Ex: generatingDeriv1, MISSING_CONSTANT, N_FINAL_SWEEP_SAMPLES.
    %       PRO: Can indirectly initialize internal constants based on this.
    %           Ex: DATA_DATA_TYPE, DATA_UNIT_CURRENT/VOLTAGE, CURRENT/VOLTAGE_BIAS_DESC, etc.
    
    methods(Access=public, Static)
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_BLKLIST_data(C2)
            table_DESCRIPTION = 'BLOCKLIST DATA. START & STOP TIME OF MACRO BLOCK AND MACRO ID.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECONDS',      'DESCRIPTION', 'START TIME OF MACRO BLOCK YYYY-MM-DD HH:MM:SS.sss');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',  'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECONDS',      'DESCRIPTION', 'LAST START TIME OF MACRO BLOCK FILE YYYY-MM-DD HH:MM:SS.sss');
            ocl{end+1} = struct('NAME', 'MACRO_ID',       'DATA_TYPE', 'CHARACTER', 'BYTES',  3, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'HEXADECIMAL MACRO IDENTIFICATION NUMBER.');
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        % IMPLEMENTATION NOTE: Just using table_DESCRIPTION as argument and return value without modification to maintain similarity
        % with other functions for the moment. Might want to eliminate later.
        %
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_IVxHL_data(C2, generatingDeriv1, isDensityMode, probeNbr, table_DESCRIPTION)
            table_DESCRIPTION = table_DESCRIPTION;   % No modification(!)
            
            ocl = {};
            ocl{end+1} = struct('NAME', 'TIME_UTC', 'DATA_TYPE', 'TIME',       'UNIT', 'SECONDS', 'BYTES', 26, 'DESCRIPTION', 'UTC TIME');
            ocl{end+1} = struct('NAME', 'TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'UNIT', 'SECONDS', 'BYTES', 16, 'DESCRIPTION', 'SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)');
            
            if probeNbr ~=3
                
                % CASE: P1 or P2
                currentOc = struct('NAME', sprintf('P%i_CURRENT', probeNbr), C2.DATA_DATA_TYPE{:}, C2.DATA_UNIT_CURRENT{:}, 'BYTES', 14);
                voltageOc = struct('NAME', sprintf('P%i_VOLTAGE', probeNbr), C2.DATA_DATA_TYPE{:}, C2.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14);
                if isDensityMode
                    currentOc.DESCRIPTION = C2.CURRENT_MEAS_DESC;   % measured
                    voltageOc.DESCRIPTION = C2.VOLTAGE_BIAS_DESC;   % bias
                    currentOc = createLBL.optionally_add_MISSING_CONSTANT(generatingDeriv1, C2.MISSING_CONSTANT, currentOc, ...
                        sprintf('A value of %g means that the original sample was saturated.', C2.MISSING_CONSTANT));   % NOTE: Modifies currentOc.
                elseif isEFieldMode
                    currentOc.DESCRIPTION = C2.CURRENT_BIAS_DESC;   % bias
                    voltageOc.DESCRIPTION = C2.VOLTAGE_MEAS_DESC;   % measured
                    voltageOc = createLBL.optionally_add_MISSING_CONSTANT(generatingDeriv1, C2.MISSING_CONSTANT, voltageOc, ...
                        sprintf('A value of %g means that the original sample was saturated.', C2.MISSING_CONSTANT));   % NOTE: Modifies voltageOc.
                else
                    error('Error, bad combination of values isDensityMode and isEFieldMode.');
                end
                ocl{end+1} = currentOc;
                ocl{end+1} = voltageOc;
                
            else
                
                % CASE: P3
                %error('This code segment has not yet been completed for P3. Can not create LBL file for "%s".', stabindex(i).path)
                if isDensityMode
                    % This case occurs at least on 2005-03-04 (EAR1). Appears to be the only day with V3x data for the
                    % entire mission. Appears to only happen for HF, but not LF.
                    oc1 = struct('NAME', 'P1_P2_CURRENT', C2.DATA_DATA_TYPE{:}, C2.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', 'MEASURED CURRENT DIFFERENCE.');
                    oc2 = struct('NAME', 'P1_VOLTAGE',    C2.DATA_DATA_TYPE{:}, C2.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', C2.VOLTAGE_BIAS_DESC);
                    oc3 = struct('NAME', 'P2_VOLTAGE',    C2.DATA_DATA_TYPE{:}, C2.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', C2.VOLTAGE_BIAS_DESC);
                    
                    oc1 = createLBL.optionally_add_MISSING_CONSTANT(generatingDeriv1, C2.MISSING_CONSTANT, oc1, ...
                        sprintf('A value of %g means that the original sample was saturated.', C2.MISSING_CONSTANT));
                elseif isEFieldMode
                    % This case occurs at least on 2007-11-07 (EAR2), which appears to be the first day it occurs.
                    % This case does appear to occur for HF, but not LF.
                    oc1 = struct('NAME', 'P1_CURRENT',    C2.DATA_DATA_TYPE{:}, C2.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', C2.CURRENT_BIAS_DESC);
                    oc2 = struct('NAME', 'P2_CURRENT',    C2.DATA_DATA_TYPE{:}, C2.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', C2.CURRENT_BIAS_DESC);
                    oc3 = struct('NAME', 'P1_P2_VOLTAGE', C2.DATA_DATA_TYPE{:}, C2.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', 'MEASURED VOLTAGE DIFFERENCE.');
                    
                    oc3 = createLBL.optionally_add_MISSING_CONSTANT(generatingDeriv1, C2.MISSING_CONSTANT, oc3, ...
                        sprintf('A value of %g means that the original sample was saturated.', C2.MISSING_CONSTANT));
                else
                    error('Error, bad combination of values isDensityMode and isEFieldMode.');
                end
                ocl(end+1:end+3) = {oc1; oc2; oc3};
                
            end
            
            % Add quality flag column.
            if generatingDeriv1
                ocl{end+1} = struct('NAME', 'QUALITY_FLAG', 'DATA_TYPE', 'ASCII_INTEGER', 'UNIT', C2.NO_ODL_UNIT, 'BYTES',  5, ...
                    'DESCRIPTION', C2.QFLAG1_DESCRIPTION);
            end
            
            OBJECT_COLUMN_list = ocl;
            
        end
        
        
        
        % BxS
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_BxS_data(C2, probeNbr, generatingDeriv1, table_DESCRIPTION_prefix)
            table_DESCRIPTION = sprintf('%s Sweep step bias and time between each step', table_DESCRIPTION_prefix);   % Remove ref. to old DESCRIPTION? (Ex: D_SWEEP_P1_RAW_16BIT_BIP)
            
            
            
            %ocl = [];
            oc1 = struct('NAME', 'SWEEP_TIME',                     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'SECONDS');     % NOTE: Always ASCII_REAL, including for EDDER!!!
            oc2 = struct('NAME', sprintf('P%i_VOLTAGE', probeNbr), C2.DATA_DATA_TYPE{:},      'BYTES', 14, C2.DATA_UNIT_VOLTAGE{:});
            
            if ~generatingDeriv1
                oc1.DESCRIPTION = sprintf(['Elapsed time (s/c clock time) from first sweep measurement. ', ...
                    'Negative time refers to samples taken just before the actual sweep for technical reasons. ', ...
                    'A value of %g refers to that there was no such pre-sweep sample for any sweep in this command block.'], C2.MISSING_CONSTANT);
                oc1.MISSING_CONSTANT = C2.MISSING_CONSTANT;
                
                oc2.DESCRIPTION = sprintf('Bias voltage. A value of %g refers to that the bias voltage is unknown (all pre-sweep bias voltages).', C2.MISSING_CONSTANT);
                oc2.MISSING_CONSTANT = C2.MISSING_CONSTANT;
            else
                oc1.DESCRIPTION = 'Elapsed time (s/c clock time) from first sweep measurement.';
                oc2.DESCRIPTION = C2.VOLTAGE_BIAS_DESC;
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
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_IxS_data(C2, generatingDeriv1, probeNbr, table_DESCRIPTION, bxsTabFilename, nTabColumns, nFinalPresweepSamples)
            table_DESCRIPTION = table_DESCRIPTION;   % No modification(!)
            
            
            
            ocl = {};
            
            oc1 = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION', 'Sweep start UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.');
            oc2 = struct('NAME',  'STOP_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS', 'DESCRIPTION',  'Sweep stop UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.');
            oc3 = struct('NAME', 'START_TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION', 'Sweep start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            oc4 = struct('NAME',  'STOP_TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS', 'DESCRIPTION',  'Sweep stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            if ~generatingDeriv1
                oc1.DESCRIPTION = [oc1.DESCRIPTION, sprintf(' This effectively refers to the %g''th sample.', nFinalPresweepSamples+1)];
                oc3.DESCRIPTION = [oc3.DESCRIPTION, sprintf(' This effectively refers to the %g''th sample.', nFinalPresweepSamples+1)];
            end
            ocl(end+1:end+4) = {oc1, oc2, oc3, oc4};
            
            if generatingDeriv1
                ocl{end+1} = struct('NAME', 'QUALITY_FLAG', 'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QFLAG1_DESCRIPTION);
            end
            
            % NOTE: The file referenced in column DESCRIPTION is expected to have the wrong name since files are renamed by other code
            % before delivery. The delivery code should already correct for this.
            oc = struct(...
                'NAME', sprintf('P%i_SWEEP_CURRENT', probeNbr), C2.DATA_DATA_TYPE{:}, 'ITEM_BYTES', 14, C2.DATA_UNIT_CURRENT{:}, ...
                'ITEMS', nTabColumns - length(ocl), ...
                'MISSING_CONSTANT', C2.MISSING_CONSTANT);
            
            if ~generatingDeriv1
                oc.DESCRIPTION = sprintf([...
                    'One current for each of the voltage potential sweep steps described by %s. ', ...
                    'A value of %g refers to that no such sample was ever taken.'], bxsTabFilename, C2.MISSING_CONSTANT);
            else
                oc.DESCRIPTION = sprintf([...
                    'One current for each of the voltage potential sweep steps described by %s. ', ...
                    'Each current is the average over one or multiple measurements on a single potential step. ', ...
                    'A value of %g refers to ', ...
                    '(1) that the underlying set of samples contained at least one saturated value, and/or ', ...
                    '(2) there were no samples which were not disturbed by RPCMIP left to make an average over.'], bxsTabFilename, C2.MISSING_CONSTANT);
            end
            ocl{end+1} = oc;
            
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        % IxD, VxD.
        % NOTE: Both for density mode and E field mode.
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_IVxD_data(C2, probeNbr, table_DESCRIPTION_prefix, samplingRateSeconds, isDensityMode, isEFieldMode)
            
            mcDescrAmendment = sprintf('A value of %g means that the underlying time period which was averaged over contained at least one saturated value.', C2.MISSING_CONSTANT);
            
            
            
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
            
            oc1 = struct('NAME', sprintf('P%i_CURRENT',        probeNbr), C2.DATA_UNIT_CURRENT{:}, 'BYTES', 14, C2.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'AVERAGED CURRENT.');
            oc2 = struct('NAME', sprintf('P%i_CURRENT_STDDEV', probeNbr), C2.DATA_UNIT_CURRENT{:}, 'BYTES', 14, C2.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'CURRENT STANDARD DEVIATION.');
            oc3 = struct('NAME', sprintf('P%i_VOLTAGE',        probeNbr), C2.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, C2.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'AVERAGED VOLTAGE.');
            oc4 = struct('NAME', sprintf('P%i_VOLTAGE_STDDEV', probeNbr), C2.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, C2.DATA_DATA_TYPE{:}, 'DESCRIPTION', 'VOLTAGE STANDARD DEVIATION.');
            
            oc1 = createLBL.optionally_add_MISSING_CONSTANT(isDensityMode, C2.MISSING_CONSTANT, oc1 , mcDescrAmendment);
            oc2 = createLBL.optionally_add_MISSING_CONSTANT(isDensityMode, C2.MISSING_CONSTANT, oc2 , mcDescrAmendment);
            oc3 = createLBL.optionally_add_MISSING_CONSTANT(isEFieldMode,  C2.MISSING_CONSTANT, oc3 , mcDescrAmendment);
            oc4 = createLBL.optionally_add_MISSING_CONSTANT(isEFieldMode,  C2.MISSING_CONSTANT, oc4 , mcDescrAmendment);
            ocl(end+1:end+4) = {oc1; oc2; oc3; oc4};
            
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG', 'BYTES', 5, 'DATA_TYPE', 'ASCII_INTEGER', 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QFLAG1_DESCRIPTION);
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_FRQ_data(nTabColumnsTotal, psdTabFilename)
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
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_PSD_data(C2, probeNbr, isDensityMode, isEFieldMode, nTabColumns, modeStr)
            % PROPOSAL: Expand "PSD" to "POWER SPECTRAL DENSITY" (correct according to EAICD).
            table_DESCRIPTION = sprintf('%s PSD SPECTRA OF HIGH FREQUENCY MEASUREMENT', modeStr);
            
            
            
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_UTC', 'UNIT', 'SECONDS',      'BYTES', 26, 'DATA_TYPE', 'TIME',          'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_UTC',  'UNIT', 'SECONDS',      'BYTES', 26, 'DATA_TYPE', 'TIME',          'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_OBT', 'UNIT', 'SECONDS',      'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',    'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_OBT',  'UNIT', 'SECONDS',      'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',    'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT)');
            ocl1{end+1} = struct('NAME', 'QUALITY_FLAG',           'UNIT', C2.NO_ODL_UNIT, 'BYTES',  5, 'DATA_TYPE', 'ASCII_INTEGER', 'DESCRIPTION', C2.QFLAG1_DESCRIPTION);
            
            ocl2 = {};
            mcDescrAmendment = sprintf('A value of %g means that there was at least one saturated sample in the same time interval uninterrupted by RPCMIP disturbances.', C2.MISSING_CONSTANT);
            if isDensityMode
                
                if probeNbr == 3
                    ocl2{end+1} = struct('NAME', 'P1_P2_CURRENT_MEAN',                  C2.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', ['MEASURED CURRENT DIFFERENCE MEAN. ', mcDescrAmendment], 'MISSING_CONSTANT', C2.MISSING_CONSTANT);
                    ocl2{end+1} = struct('NAME', 'P1_VOLTAGE_MEAN',                     C2.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', C2.VOLTAGE_BIAS_DESC);
                    ocl2{end+1} = struct('NAME', 'P2_VOLTAGE_MEAN',                     C2.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', C2.VOLTAGE_BIAS_DESC);
                else
                    ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', probeNbr), C2.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', ['MEASURED CURRENT MEAN. ', mcDescrAmendment], 'MISSING_CONSTANT', C2.MISSING_CONSTANT);
                    ocl2{end+1} = struct('NAME', sprintf('P%i_VOLTAGE_MEAN', probeNbr), C2.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', C2.VOLTAGE_BIAS_DESC);
                end
                PSD_DESCRIPTION = 'PSD CURRENT SPECTRUM';
                PSD_UNIT        = 'NANOAMPERE^2/Hz';
                
            elseif isEFieldMode
                
                if probeNbr == 3
                    ocl2{end+1} = struct('NAME', 'P1_CURRENT_MEAN',    C2.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', C2.CURRENT_BIAS_DESC);
                    ocl2{end+1} = struct('NAME', 'P2_CURRENT_MEAN',    C2.DATA_UNIT_CURRENT{:}, 'DESCRIPTION', C2.CURRENT_BIAS_DESC);
                    ocl2{end+1} = struct('NAME', 'P1_P2_VOLTAGE_MEAN', C2.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', ['MEASURED VOLTAGE DIFFERENCE MEAN. ', mcDescrAmendment], 'MISSING_CONSTANT', C2.MISSING_CONSTANT);
                else
                    ocl2{end+1} = struct('NAME', sprintf('P%i_CURRENT_MEAN', probeNbr), C2.DATA_UNIT_CURRENT{:}, 'DESCRIPTION',      'BIAS CURRENT MEAN');
                    ocl2{end+1} = struct('NAME', sprintf('P%i_VOLTAGE_MEAN', probeNbr), C2.DATA_UNIT_VOLTAGE{:}, 'DESCRIPTION', ['MEASURED VOLTAGE MEAN', mcDescrAmendment], 'MISSING_CONSTANT', C2.MISSING_CONSTANT);
                end
                PSD_DESCRIPTION = 'PSD VOLTAGE SPECTRUM';
                PSD_UNIT        = 'VOLT^2/Hz';
                
            else
                error('Error, bad combination of isDensityMode and isEFieldMode.');
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
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_PHO_data(C,C2)
            table_DESCRIPTION = 'Photosaturation current derived collectively from multiple sweeps (not just an average of multiple estimates).';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',            'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME', 'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',            'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'I_PH0',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'AMPERE',    'DESCRIPTION', ...
                ['Photosaturation current derived collectively from multiple sweeps (not just an average of multiple estimates).', C2.MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'I_PH0_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',        'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QFLAG1_DESCRIPTION);
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_USC_data(C,C2)
            table_DESCRIPTION = 'Proxy for spacecraft potential, derived from either (1) zero current crossing in sweep, or (2) floating potential measurement (downsampled). Time interval can thus refer to either sweep or individual sample.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',                     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFF. Middle point for sweeps.',                              'useFor', {{'START_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',                     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point). Middle point for sweeps.', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT', 'STOP_TIME_from_OBT'}});
            ocl{end+1} = struct('NAME', 'V_SC_POT_PROXY',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',      'DESCRIPTION', ...
                ['Proxy for spacecraft potential derived from either (1) photoelectron knee in sweep, or (2) floating potential measurement (downsampled), depending on available data.', C2.MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_SC_POT_PROXY_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',                 'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QFLAG1_DESCRIPTION);
            
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_ASW_data(C,C2)
            % ASW = Analyzed sweep parameters
            table_DESCRIPTION = 'Analyzed sweeps (ASW). Miscellaneous physical high-level quantities derived from individual sweeps.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Start UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME'}});
            ocl{end+1} = struct('NAME',  'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION',  'Stop UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT'}});
            ocl{end+1} = struct('NAME',  'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION',  'Stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'N_E',                           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'cm**-3',    'DESCRIPTION', ['Electron density derived from individual sweep.', C2.MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'N_E_QUALITY_VALUE',             'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'I_PH0',                         'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'AMPERE',    'DESCRIPTION', ...
                ['Photosaturation current derived from individual sweep.', C2.MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'I_PH0_QUALITY_VALUE',           'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'V_ION_BULK_XCAL',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'm/s',       ...
                'DESCRIPTION', ['Ion bulk speed derived from individual sweep (speed; always non-negative scalar). Cross-calibrated with RPCMIP.', C2.MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_ION_BULK_XCAL_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'T_E',                           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'eV',        ...
                'DESCRIPTION', ['Electron temperature derived from exponential part of sweep.', C2.MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'T_E_QUALITY_VALUE',             'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'T_E_XCAL',                      'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'eV',        ...
                'DESCRIPTION', ['Electron temperature, derived by using the linear part of the electron current of the sweep, and density measurement from RPCMIP.', C2.MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'T_E_XCAL_QUALITY_VALUE',        'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'V_PH_KNEE',                     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',      ...
                'DESCRIPTION', ['Photoelectron knee potential.', C2.MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_PH_KNEE_QUALITY_VALUE',       'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',                  'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QFLAG1_DESCRIPTION);
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_NPL_data(C,C2)
            table_DESCRIPTION = 'Plasma density derived from individual fix-bias density mode (current) measurements.';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',       'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME', 'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',       'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'N_PL',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'cm**-3',    'DESCRIPTION', ...
                ['Plasma density derived from individual fix-bias density mode (current) measurements. Parameter derived from low time resolution estimates of the plasma density from either RPCLAP or RPCMIP (changes over time).', C2.MC_DESC], ...
                'MISSING_CONSTANT', C.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'QUALITY_VALUE',  'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',   'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QFLAG1_DESCRIPTION);
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_AxS_data(C2, ixsFilename)
            table_DESCRIPTION = sprintf('MODEL FITTED ANALYSIS OF %s SWEEP FILE', ixsFilename);
            
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'START_TIME_UTC',  'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Start time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_UTC',   'UNIT', 'SECONDS',   'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION',  'Stop time of sweep. UTC TIME YYYY-MM-DD HH:MM:SS.FFF');
            ocl1{end+1} = struct('NAME', 'START_TIME_OBT',  'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Start time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_OBT',   'UNIT', 'SECONDS',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION',  'Stop time of sweep. SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
            ocl1{end+1} = struct('NAME', 'Qualityfactor',   'UNIT', C2.NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Quality factor from 0-100.');   % TODO: Correct?
            ocl1{end+1} = struct('NAME', 'SAA',             'UNIT', 'degrees',   'BYTES',  7, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Solar aspect angle in spacecraft XZ plane, measured from Z+ axis.');
            ocl1{end+1} = struct('NAME', 'Illumination',    'UNIT', C2.NO_ODL_UNIT, 'BYTES',  4, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl1{end+1} = struct('NAME', 'direction',       'UNIT', C2.NO_ODL_UNIT, 'BYTES',  1, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            % ----- (NOTE: Switching from ocl1 to ocl2.) -----
            ocl2 = {};
            ocl2{end+1} = struct('NAME', 'old_Vsi',                'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old_Vx',                 'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential + Te from electron current fit. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vsg',                    'UNIT', 'V',         'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'sigma_Vsg',              'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for spacecraft potential from gaussian fit to second derivative.');
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
            ocl2{end+1} = struct('NAME', 'sigma_Vph_knee',         'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');
            ocl2{end+1} = struct('NAME',       'Te_linear',        'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_linear',        'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ne_linear',        'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_ne_linear',        'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ion_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_slope',        'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential');
            ocl2{end+1} = struct('NAME',       'ion_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_intersect',    'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_slope',          'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_slope',          'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_intersect',      'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_intersect',      'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'ion_Vb_intersect', 'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_Vb_intersect', 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'e_Vb_intersect',   'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_Vb_intersect',   'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable).');
            ocl2{end+1} = struct('NAME', 'nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable).');
            ocl2{end+1} = struct('NAME',       'phc_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_slope',        'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'phc_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_intersect',    'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'ne_5eV',                 'UNIT', 'cm^-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming electron temperature Te = 5 eV.');
            ocl2{end+1} = struct('NAME', 'ni_v_dep',               'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity.');
            ocl2{end+1} = struct('NAME', 'ni_v_indep',             'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate.');
            ocl2{end+1} = struct('NAME', 'v_ion',                  'UNIT', 'm/s',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate.');
            ocl2{end+1} = struct('NAME',       'Te_exp',           'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_exp',           'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ne_exp',           'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_ne_exp',           'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron density derived from fit of exponential part of the thermal electron current.');
            
            ocl2{end+1} = struct('NAME', 'Rsquared_linear',        'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current.');
            ocl2{end+1} = struct('NAME', 'Rsquared_exp',           'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current.');
            
            ocl2{end+1} = struct('NAME',       'Vbar',             'UNIT', C2.ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'sigma_Vbar',             'UNIT', C2.ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');
            
            ocl2{end+1} = struct('NAME', 'ASM_Iph0',                   'UNIT', 'A',         'DESCRIPTION', 'Assumed photosaturation current used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'ASM_Tph',                    'UNIT', 'eV',        'DESCRIPTION', 'Assumed photoelectron temperature used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Vsi',                    'UNIT', 'V',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_Te_linear',        'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_linear',        'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ne_linear',        'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'sigma_asm_ne_linear',        'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_slope',        'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_intersect',    'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_slope',          'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_slope',          'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_intersect',      'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_intersect',      'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_Vb_intersect', 'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_intersect', 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_Vb_intersect',   'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_intersect',   'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Tphc',                   'UNIT', 'eV',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_nphc',                   'UNIT', 'cm^-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_phc_slope',        'UNIT', 'A/V',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_slope',        'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_phc_intersect',    'UNIT', 'A',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_intersect',    'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ne_5eV',                 'UNIT', 'cm^-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming Te= 5eV. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_dep',               'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_indep',             'UNIT', 'cm^-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_v_ion',                  'UNIT', 'm/s',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_Te_exp',           'UNIT', 'eV',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp',           'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ne_exp',           'UNIT', 'cm^-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp',           'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron density derived from fit of exponential part of the thermal electron current.');
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_linear',        'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_exp',           'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
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
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_EST_data(C2)
            table_DESCRIPTION = sprintf('BEST ESTIMATES OF PHYSICAL VALUES FROM MODEL FITTED ANALYSIS.');   % Bad description? To specific?
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',      'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',      'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',      'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
            ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',      'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMAL POINT).');
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',       'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', C2.QFLAG1_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'npl',                'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'CM**-3',    'MISSING_CONSTANT', C2.MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of plasma number density.');
            ocl{end+1} = struct('NAME', 'Te',                 'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'eV',        'MISSING_CONSTANT', C2.MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of electron temperature.');
            ocl{end+1} = struct('NAME', 'Vsc',                'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'V',         'MISSING_CONSTANT', C2.MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of spacecraft potential.');
            ocl{end+1} = struct('NAME', 'Probe_number',       'DATA_TYPE', 'ASCII_REAL',    'BYTES',  1, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Probe number. 1 or 2.');
            ocl{end+1} = struct('NAME', 'Direction',          'DATA_TYPE', 'ASCII_REAL',    'BYTES',  1, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            ocl{end+1} = struct('NAME', 'Illumination',       'DATA_TYPE', 'ASCII_REAL',    'BYTES',  4, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl{end+1} = struct('NAME', 'Sweep_group_number', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  5, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', ...
                ['Number signifying which group of sweeps the data comes from. ', ...
                'Groups of sweeps are formed for the purpose of deriving/selecting values to be used in best estimates. ', ...
                'All sweeps with the same group number are almost simultaneous. For every type of best estimate, at most one is chosen from each group.' ...
                ]);  % NOTE: Causes trouble by making such a long line in LBL file?!!
            OBJECT_COLUMN_list = ocl;
        end
        
        
        
        function [OBJECT_COLUMN_list, table_DESCRIPTION] = get_A1P_data(C2)
            lblData.OBJTABLE.DESCRIPTION = 'ANALYZED PROBE 1 PARAMETERS';
            
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME',  'STOP_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP UTC TIME YYYY-MM-DD HH:MM:SS.FFFFFF');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION', 'START SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME',  'STOP_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECONDS',   'DESCRIPTION',  'STOP SPACECRAFT ONBOARD TIME SSSSSSSSS.FFFFFF (TRUE DECIMALPOINT).');
            ocl{end+1} = struct('NAME', 'QUALITY',            'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  4, 'UNIT', C2.NO_ODL_UNIT, 'DESCRIPTION', 'QUALITY FACTOR FROM 000 (BEST) TO 999.');
            ocl{end+1} = struct('NAME', 'Vph_knee',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',         'MISSING_CONSTANT', C2.MISSING_CONSTANT, 'DESCRIPTION', 'Potential at probe position from photoelectron current knee (gaussian fit of second derivative).');
            ocl{end+1} = struct('NAME', 'Te_exp_belowVknee',  'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'ELECTRONVOLT', 'MISSING_CONSTANT', C2.MISSING_CONSTANT, 'DESCRIPTION', 'Electron temperature from an exponential fit to the slope of the retardation region of the electron current.');
            lblData.OBJTABLE.OBJCOL_list = ocl;
            clear   ocl
        end
        
        
        
    end    % methods(...)
    
end   % classdef