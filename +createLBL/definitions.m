%
% DESIGN INTENT
% =============
% Class which stores hard-coded data related to the creation of LBL files. Should at least collect functions which
% define and return data structures defining LBL files, one file/data type per function.
%
% The class is instantiated with variable values which are anyway likely constant during a session, and can be used by
% the methods (e.g. whether EDDER/DERIV1, MISSING_CONSTANT etc).
%
% The class is not supposed to use createLBL.constants (no hard reason).
% The class is supposed to be immutable.
% The class is intended to NOT have an interface to Ladog variables (e.g. tabindex) directly.
%
% The class should not use any global variables, and not know which data product belongs to which archiving level.
% NOTE: The class indirectly "knows" which data products are L5 since it removes ROSETTA:* PDS keywords for these. This
% is otherwise against the design intent.
%
%
% NAMING CONVENTIONS, CONVENTIONS
% ===============================
% data : Refers to LBL file data
% OCL  : Object Column List
% KVPL : Key-Value Pair List
% PLKS : Pds (s/w) Label Keyword Source (file(s)). EDITED1/CALIB1 label file from which information is retrieved.
% LHT  : Label Header Timestamps (START_TIME etc)
% --
% Only uses argument flags for density mode (true/false). It is implicit that E field is the inverse.
%
%
% Initially created 2018-09-12 by Erik P G Johansson, IRF Uppsala.
%
classdef definitions < handle
    % PROPOSAL: Change class to immutable non-handle class.
    %
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
    %   NOTE: Currently done in delivery code.
    %
    % PROPOSAL: Consistent system for lower-/uppercase for class instance fields.
    %
    % PROPOSAL: Function for extracting flags from filename/PRODUCT_ID.
    %   PRO: Can have assertions.
    %   PROPOSAL: Use, combine with delivery code's classification function.
    %       CON: The delievry code does not contain one such function, but several "decision functions" which are very
    %            different. Those do not extract these variables or anything similar.
    %           PRO: They decide on whether to copy file, if HK, if ODL-to-update, new filename.
    %
    % PROPOSAL: Move keyword removal functionality from delivery code to here.
    %   OhChanges.RemoveKeysList   = {'ROSETTA:LAP_P1_INITIAL_SWEEP_SMPLS', 'ROSETTA:LAP_P2_INITIAL_SWEEP_SMPLS'};   % For "all" ODL files.
    %   OhChanges.RemoveKeysListHk = {'INSTRUMENT_MODE_ID', 'INSTRUMENT_MODE_DESC'};    % Specific for HK.
    %   CON: Can not modify HK LBL in Lapdog.
    %
    % PROPOSAL: Move optionally_add_MISSING_CONSTANT into createLBL.definitions.
    %
    % PROPOSAL: Make the data type functions have access to full EDITED1/CALIB1 LBL file contents.
    %   TODO-DECISION: Proper name/term.
    %       PROPOSAL: "source label file", "template label file", "IDP label file"
    %   TODO-DECISION: How handle timestamps (START_TIME etc)?
    %   PROPOSAL: Receive file path and read file itself.
    %       CON: Too much repetition between data products (more than in create_LBL_files, since some loops cover
    %            multiple types).
    %   --
    %   NOTE: Some data types use the same EDITED1/CALIB1 LBL file.
    %       Ex: IxS & BxS, PSD & FRQ (if not removing all keywords stemming from EDITED1/CALIB1).
    %   NOTE: EST uses 1-2 CALIB1 files.
    %   --
    %   CON: Same procedure for many data types. create_LBL_files groups code for many data types.
    %   PRO: Clearer what is done for every data type. Otherwise it is create_LBL_files that decides.
    %       Ex: Some datatypes do and some do not read from EDITED1/CALIB1 LBL files. 
    %           Ex: BLKLIST, ASW etc ignore.
    %       Ex: As is now it is not clear if needs to remove ROSETTA:* keywords or INSTRUMENT_MODE_*.
    %           ASW,USC,PHO,NPL do not read CALIB1 file and hence does not at all have access to those files.
    %
    % 
    %
    % BUG/TODO: Somehow handle that ASW, USC DESCRIPTION (root-level), now inherited from CALIB1 (cryptic pds strings).
    % PROPOSAL: Copy whitelisted values from EDITED1/CALIB1 header: ROSETTA:*, INSTRUMENT_MODE_* instead of current model
    %           (copy all except for blacklist).
    %
    % PROPOSAL: Function for setting/removing the root-level (header) DESCRIPTION and OBJECT=TABLE-level DESCRIPTION.
    %   PRO: Can incorporate a global policy for which DESCRIPTION keywords to actually use: both, or one of them.

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
        HeaderAllKvpl
        
        MC_DESC_AMENDM       % Generic description string for MISSING_CONSTANT (MC). Is added at end of DESCRIPTION.
        %QFLAG1_DESCRIPTION = 'Quality flag constructed as the sum of multiple terms, depending on what quality related effects are present. From 00000 (best) to 77777 (worst).';
        QFLAG1_DESCRIPTION = 'Quality flag constructed as the sum of multiple terms, depending on what quality related effects are present. Each digit is either in the range 0 (best) to 7 (worst), or 9 (not used).';
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
        function obj = definitions(generatingDeriv1, MISSING_CONSTANT, nFinalPresweepSamples, indentationLength, HeaderAllKvpl)
            
            % ASSERTIONS
            assert(isscalar(nFinalPresweepSamples) && isnumeric(nFinalPresweepSamples))
            assert(isscalar(MISSING_CONSTANT)      && isnumeric(MISSING_CONSTANT))
            

            
            obj.MISSING_CONSTANT      = MISSING_CONSTANT;
            obj.nFinalPresweepSamples = nFinalPresweepSamples;
            obj.indentationLength     = indentationLength;
            obj.generatingDeriv1      = generatingDeriv1;
            obj.HeaderAllKvpl         = HeaderAllKvpl;
            
            obj.MC_DESC_AMENDM        = sprintf(' A value of %e refers to that there is no value.', obj.MISSING_CONSTANT);    % Amendment to other strings. Therefore begins with whitespace.
            
            % Set PDS keywords to use for column descriptions which differ between EDDER and DERIV1
            % -------------------------------------------------------------------------------------
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



        function LblData = get_BLKLIST_data(obj, LhtKvpl)
            HeaderKvpl = obj.HeaderAllKvpl.append(LhtKvpl);
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {{'2018-11-27', 'EJ', 'Descriptions clean-up, lowercase'}});
            
            HeaderKvpl = HeaderKvpl.append_kvp('DESCRIPTION', 'Block list. A list of executed macro blocks during one UTC day.');

            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Table containing start and stop times, and macro ID of macro blocks executed during one UTC day.';
            
            %================
            % Define columns
            %================
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECOND',        'DESCRIPTION', 'Start time of macro block, YYYY-MM-DD HH:MM:SS.sss.');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',  'DATA_TYPE', 'TIME',      'BYTES', 23, 'UNIT', 'SECOND',        'DESCRIPTION', 'Last start time of data in macro block, YYYY-MM-DD HH:MM:SS.sss.');    % Correct? "Last start time"?
            ocl{end+1} = struct('NAME', 'MACRO_ID',       'DATA_TYPE', 'CHARACTER', 'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Hexadecimal macro identification number.');
            
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end
        
        
                
        function LblData = get_IVxHL_data(obj, LhtKvpl, firstPlksFile, isDensityMode, probeNbr, isLf)
            
            [HeaderKvpl, FirstPlksSs] = build_header_KVPL_from_single_PLKS(obj, LhtKvpl, firstPlksFile);
            HeaderKvpl = HeaderKvpl.set_value('START_TIME',                   FirstPlksSs.START_TIME);
            HeaderKvpl = HeaderKvpl.set_value('SPACECRAFT_CLOCK_START_COUNT', FirstPlksSs.SPACECRAFT_CLOCK_START_COUNT);
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-11-12', 'EJ', 'Descriptions clean-up, lowercase'}, ...
                {'2018-11-16', 'EJ', 'Removed bias keywords'}, ...
                {'2018-11-27', 'EJ', 'Updated DESCRIPTIONs'}});
            HeaderKvpl = createLBL.definitions.remove_bias_keywords(HeaderKvpl);
            
            % Macros 710, 910 LF changes the downsampling and moving average cyclically. Therefore the true values of
            % these keywords alternate in value over time. Therefore they should be REMOVED (in agreement with LAP team
            % and ESA-PSA).
            % NOTE: No assertion on that removal actually takes place.
            if isLf && any(strcmp(HeaderKvpl.get_value('INSTRUMENT_MODE_ID'), {'MCID0X0710', 'MCID0X0910'}))
                HeaderKvpl = HeaderKvpl.diff({'ROSETTA:LAP_P1P2_ADC20_DOWNSAMPLE', 'ROSETTA:LAP_P1P2_ADC20_MA_LENGTH'});
            end
            
            
            
            %=======================================
            % Define columns and global DESCRIPTION
            %=======================================
            ocl = {};
            ocl{end+1} = struct('NAME', 'TIME_UTC', 'DATA_TYPE', 'TIME',       'UNIT', 'SECOND', 'BYTES', 26, 'DESCRIPTION', 'UTC time.');
            ocl{end+1} = struct('NAME', 'TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'UNIT', 'SECOND', 'BYTES', 16, 'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            
            if probeNbr ~=3
                
                % CASE: P1 or P2
                currentOc = struct('NAME', sprintf('P%i_CURRENT', probeNbr), obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14);
                voltageOc = struct('NAME', sprintf('P%i_VOLTAGE', probeNbr), obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14);
                if isDensityMode
                    % CASE: Density mode
                    DESCRIPTION_columnList = 'Contains timestamps, measured current, and set voltage bias.';
                    
                    currentOc.DESCRIPTION = obj.CURRENT_MEAS_DESC;   % measured
                    voltageOc.DESCRIPTION = obj.VOLTAGE_BIAS_DESC;   % bias
                    currentOc = createLBL.optionally_add_MISSING_CONSTANT(obj.generatingDeriv1, obj.MISSING_CONSTANT, currentOc, ...
                        sprintf('A value of %g means that the original sample was saturated.', obj.MISSING_CONSTANT));   % NOTE: Modifies currentOc.
                else
                    % CASE: E field Mode
                    DESCRIPTION_columnList = 'Contains timestamps, set bias current, and measured voltage.';
                    
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
                    DESCRIPTION_columnList = 'Contains timestamps, measured current difference between probes, and set voltage biases on both probes.';

                    oc1 = struct('NAME', 'P1_P2_CURRENT', obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', 'Measured current difference. The difference is derived digitally onboard.');
                    oc2 = struct('NAME', 'P1_VOLTAGE',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);
                    oc3 = struct('NAME', 'P2_VOLTAGE',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', obj.VOLTAGE_BIAS_DESC);

                    oc1 = createLBL.optionally_add_MISSING_CONSTANT(obj.generatingDeriv1, obj.MISSING_CONSTANT, oc1, ...
                        sprintf('A value of %g means that the original sample was saturated.', obj.MISSING_CONSTANT));
                else
                    % CASE: E field Mode
                    % This case occurs at least on 2007-11-07 (EAR2), which appears to be the first day it occurs.
                    % This case does appear to occur for HF, but not LF.
                    DESCRIPTION_columnList = 'Contains timestamps, set bias currents on both probes, and measured voltage difference between probes.';

                    oc1 = struct('NAME', 'P1_CURRENT',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', obj.CURRENT_BIAS_DESC);
                    oc2 = struct('NAME', 'P2_CURRENT',    obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_CURRENT{:}, 'BYTES', 14, 'DESCRIPTION', obj.CURRENT_BIAS_DESC);
                    oc3 = struct('NAME', 'P1_P2_VOLTAGE', obj.DATA_DATA_TYPE{:}, obj.DATA_UNIT_VOLTAGE{:}, 'BYTES', 14, 'DESCRIPTION', 'Measured voltage difference. The difference is derived digitally onboard.');
                    
                    oc3 = createLBL.optionally_add_MISSING_CONSTANT(obj.generatingDeriv1, obj.MISSING_CONSTANT, oc3, ...
                        sprintf('A value of %g means that the original sample was saturated.', obj.MISSING_CONSTANT));
                end
                ocl(end+1:end+3) = {oc1; oc2; oc3};
                
            end
            
            % Add quality flag column.
            if obj.generatingDeriv1
                ocl{end+1} = struct('NAME', 'QUALITY_FLAG', 'DATA_TYPE', 'ASCII_INTEGER', 'UNIT', obj.NO_ODL_UNIT, 'BYTES',  5, ...
                    'DESCRIPTION', obj.QFLAG1_DESCRIPTION);    % Includes copy of cryptic EDITED1/CALIB1 DESCRIPTION. Ex: D_P1_RAW_16BIT.
            end
            
            LblData.OBJTABLE.OBJCOL_list = ocl;
            
            %==========================================================
            % Derive DESCRIPTION substrings to use for different cases
            %==========================================================
            if isLf ; HF_LF_str = 'LF';
            else      HF_LF_str = 'HF';
            end
            if probeNbr ==3 ; probeStr = 'differential measurements (also known as probe 3, or P3)';
            else              probeStr = sprintf('probe %i', probeNbr);
            end
            if isDensityMode ; modeStr = 'density mode';
            else               modeStr = 'E field mode';
            end
            
            %=========================
            % Set DESCRIPTION strings
            %=========================
            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', ...
                sprintf(...
                    'Time series of %s data in %s for %s. %s.', ...
                    HF_LF_str, modeStr, probeStr, FirstPlksSs.DESCRIPTION));
            
            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = [...
                sprintf(...
                    'Table of %s data in %s for %s. ', ...
                    HF_LF_str, modeStr, probeStr), ...
                DESCRIPTION_columnList];
        end    % function



        % NOTE: Sweeps keep the PDS bias keywords since they give the surrounding bias.
        function LblData = get_BxS_data(obj, LhtKvpl, firstPlksFile, probeNbr, ixsTabFilename)
            
            [HeaderKvpl, FirstPlksSs] = build_header_KVPL_from_single_PLKS(obj, LhtKvpl, firstPlksFile);
            HeaderKvpl = HeaderKvpl.set_value('START_TIME',                   FirstPlksSs.START_TIME);
            HeaderKvpl = HeaderKvpl.set_value('SPACECRAFT_CLOCK_START_COUNT', FirstPlksSs.SPACECRAFT_CLOCK_START_COUNT);
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-11-12', 'EJ', 'Descriptions clean-up, lowercase'}, ...
                {'2018-11-27', 'EJ', 'Updated global DESCRIPTIONs'}, ...
                {'2019-02-04', 'EJ', 'Command block-->macro block'}});

            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', ...
                sprintf(...
                    'Description of the sequence of sweep voltage bias steps. %s.', ...
                    FirstPlksSs.DESCRIPTION));    % Includes copy of cryptic EDITED1/CALIB1 DESCRIPTION. Ex: D_SWEEP_P1_RAW_16BIT_BIP.);

            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = sprintf(...
                ['Table of relative time within sweep, and corresponding voltage bias. This table is shared for all sweeps on', ...
                ' the same probe and is associated with the sweep data in file %s.'], ...
                ixsTabFilename);

            %================
            % Define columns
            %================
            oc1 = struct('NAME', 'SWEEP_TIME',                     'DATA_TYPE', 'ASCII_REAL', 'BYTES', 14, 'UNIT', 'SECOND');     % NOTE: Always ASCII_REAL, also for EDDER!
            oc2 = struct('NAME', sprintf('P%i_VOLTAGE', probeNbr), obj.DATA_DATA_TYPE{:},     'BYTES', 14, obj.DATA_UNIT_VOLTAGE{:});

            if ~obj.generatingDeriv1
                oc1.DESCRIPTION = sprintf(['Elapsed time (s/c clock time) from first sweep measurement. ', ...
                    'Negative time refers to samples taken just before the actual sweep for technical reasons. ', ...
                    'A value of %g refers to that there was no such pre-sweep sample for any sweep in this macro block.'], obj.MISSING_CONSTANT);
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
        %
        % NOTE: Sweeps keep the bias keywords since they give the surrounding bias.
        function LblData = get_IxS_data(obj, LhtKvpl, firstPlksFile, probeNbr, bxsTabFilename, nTabColumns)

            [HeaderKvpl, FirstPlksSs] = build_header_KVPL_from_single_PLKS(obj, LhtKvpl, firstPlksFile);
            HeaderKvpl = HeaderKvpl.set_value('START_TIME',                   FirstPlksSs.START_TIME);
            HeaderKvpl = HeaderKvpl.set_value('SPACECRAFT_CLOCK_START_COUNT', FirstPlksSs.SPACECRAFT_CLOCK_START_COUNT);            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-11-12', 'EJ', 'Descriptions clean-up, lowercase'}, ...
                {'2018-11-27', 'EJ', 'Updated DESCRIPTIONs'}});

            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', ...
                sprintf('Sweep data, i.e. measured currents while the bias voltage sweeps over a continuous range of values (repeatedly). %s.', ...
                FirstPlksSs.DESCRIPTION));    % Includes copy of cryptic EDITED1/CALIB1 DESCRIPTION. Ex: D_SWEEP_P1_RAW_16BIT_BIP.

            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = sprintf(...
                ['Time series of sweep start and sweep stop timestamps, and measured sweep currents for the different sweep bias voltages.', ...
                ' The actual bias voltages are specified in file %s.'], ...
                bxsTabFilename);

            %================
            % Define columns
            %================
            ocl = {};
            
            oc1 = struct('NAME', 'START_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECOND', 'DESCRIPTION', 'Sweep start UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            oc2 = struct('NAME',  'STOP_TIME_UTC', 'DATA_TYPE', 'TIME',       'BYTES', 26, 'UNIT', 'SECOND', 'DESCRIPTION',  'Sweep stop UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            oc3 = struct('NAME', 'START_TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECOND', 'DESCRIPTION', 'Sweep start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            oc4 = struct('NAME',  'STOP_TIME_OBT', 'DATA_TYPE', 'ASCII_REAL', 'BYTES', 16, 'UNIT', 'SECOND', 'DESCRIPTION',  'Sweep stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            if ~obj.generatingDeriv1
                tempStr = sprintf(' This effectively refers to the %g''th sample.', obj.nFinalPresweepSamples+1);
                oc1.DESCRIPTION = [oc1.DESCRIPTION, tempStr];
                oc3.DESCRIPTION = [oc3.DESCRIPTION, tempStr];
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
                    'One current for each of the voltage potential sweep steps described in file %s. ', ...
                    'A value of %g refers to that no such sample was ever taken.'], bxsTabFilename, obj.MISSING_CONSTANT);
            else
                oc.DESCRIPTION = sprintf([...
                    'One current for each of the voltage potential sweep steps described in file %s. ', ...
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
        %
        % NOTE: Has not found any "?3D" (P3, downsampled) data on old datasets. Should not exist since there (empirically) is no ?3L data.
        function LblData = get_IVxD_data(obj, LhtKvpl, firstPlksFile, probeNbr, samplingRateSeconds, isDensityMode)
            if isDensityMode ; modeStr = 'density mode';
            else               modeStr = 'E field mode';
            end
            
            [HeaderKvpl, FirstPlksSs] = build_header_KVPL_from_single_PLKS(obj, LhtKvpl, firstPlksFile);
            HeaderKvpl = HeaderKvpl.set_value('START_TIME',                   FirstPlksSs.START_TIME);
            HeaderKvpl = HeaderKvpl.set_value('SPACECRAFT_CLOCK_START_COUNT', FirstPlksSs.SPACECRAFT_CLOCK_START_COUNT);
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-11-12', 'EJ', 'Descriptions clean-up, lowercase'}, ...
                {'2018-11-16', 'EJ', 'Removed ROSETTA:* keywords'}, ...
                {'2018-11-27', 'EJ', 'Updated global DESCRIPTIONs'}, ...
                {'2019-02-18', 'EJ', 'Added CALIBRATION_SOURCE_ID'}});
            HeaderKvpl = createLBL.definitions.remove_ROSETTA_keywords(HeaderKvpl);            
            %HeaderKvpl = HeaderKvpl.append_kvp('CALIBRATION_SOURCE_ID', {'RPCLAP'});    % NOTE: Not used due to "append_kvp" method bug.
            HeaderKvpl = HeaderKvpl.append(EJ_library.utils.KVPL2({...
                'CALIBRATION_SOURCE_ID',   {'RPCLAP'}}));
            HeaderKvpl = HeaderKvpl.set_value(...
                'DESCRIPTION', ...
                sprintf('Time series of LF %s data downsampled to a period of %g seconds on one probe.', ...
                    modeStr, samplingRateSeconds));

            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = sprintf(...
                ['Table of timestamps, averaged currents, current standard deviation, averaged voltages, and voltage standard deviation for one probe.', ...
                ' Values apply to consecutive %g second periods of LF %s data. Note that the bias is (almost) always constant and hence its standard deviation is zero.'], ...
                samplingRateSeconds, modeStr);

            %================
            % Define columns
            %================
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
            ocl{end+1} = struct('NAME', 'TIME_UTC', 'UNIT', 'SECOND',   'BYTES', 23, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'UTC time YYYY-MM-DD HH:MM:SS.FFF.',                              'useFor', {{'START_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT', 'UNIT', 'SECOND',   'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT', 'STOP_TIME_from_OBT'}});
            
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
        
        
        
        function LblData = get_FRQ_data(obj, LhtKvpl, firstPlksFile, nTabColumnsTotal, psdTabFilename)
            
            [HeaderKvpl, FirstPlksSs] = build_header_KVPL_from_single_PLKS(obj, LhtKvpl, firstPlksFile);
            HeaderKvpl = HeaderKvpl.set_value('START_TIME',                   FirstPlksSs.START_TIME);
            HeaderKvpl = HeaderKvpl.set_value('SPACECRAFT_CLOCK_START_COUNT', FirstPlksSs.SPACECRAFT_CLOCK_START_COUNT);
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-11-13', 'EJ', 'Descriptions clean-up, lowercase'}, ...
                {'2018-11-16', 'EJ', 'Removed ROSETTA:* keywords'}, ...
                {'2018-11-21', 'EJ', 'Updated global DESCRIPTION'}, ...
                {'2019-02-04', 'EJ', 'Updated UNIT'}});
            HeaderKvpl = createLBL.definitions.remove_ROSETTA_keywords(HeaderKvpl);
            
            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', sprintf('Frequencies used for PSD spectra in file %s.', psdTabFilename));

            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = sprintf('Table of frequencies used for the power spectral density (PSD) data in file %s.', psdTabFilename);

            %================
            % Define columns
            %================
            ocl = {};
            % NOTE: References file (filename) in DESCRIPTION which could potentially be wrong name in delivered
            % data sets which uses other filenaming convention. However, the delivery code should update this string
            % to contain the correct filename when building final datasets for delivery.
            ocl{end+1} = struct('NAME', 'FREQUENCY_LIST', 'ITEMS', nTabColumnsTotal, 'UNIT', 'HERTZ', 'ITEM_BYTES', 14, 'DATA_TYPE', 'ASCII_REAL', ...
                'DESCRIPTION', 'Frequency list');
            
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end



        function LblData = get_PSD_data(obj, LhtKvpl, firstPlksFile, probeNbr, isDensityMode, nTabColumns, filenameModeStr, frqTabFilename)
            % PROPOSAL: Expand "PSD" to "POWER SPECTRAL DENSITY" (correct according to EAICD).
            % PROPOSAL: Different LABEL_REVISION_NOTE for different subtypes.
            
            if isDensityMode ; modeStr = 'density mode';
            else               modeStr = 'E field mode';
            end
            
            [HeaderKvpl, FirstPlksSs] = build_header_KVPL_from_single_PLKS(obj, LhtKvpl, firstPlksFile);
            HeaderKvpl = HeaderKvpl.set_value('START_TIME',                   FirstPlksSs.START_TIME);
            HeaderKvpl = HeaderKvpl.set_value('SPACECRAFT_CLOCK_START_COUNT', FirstPlksSs.SPACECRAFT_CLOCK_START_COUNT);
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-11-13', 'EJ', 'Descriptions clean-up, lowercase'}, ...
                {'2018-11-16', 'EJ', 'Removed ROSETTA:* keywords'}, ...
                {'2018-11-27', 'EJ', 'Updated global DESCRIPTIONs'}, ...
                {'2019-02-04', 'EJ', 'Updated UNIT'}, ...
                {'2019-02-18', 'EJ', 'Added DATA_SET_PARAMETER_NAME, CALIBRATION_SOURCE_ID'}});
            HeaderKvpl = createLBL.definitions.remove_ROSETTA_keywords(HeaderKvpl);
            
            % 2018-10-03_EJ_AE_RID_meeting.txt:
            %   Värden på DATA_SET_PARAMETER_NAME att använda
            %       Kan vara flera strängvärden (i array) för varje kolumn.
            %       "PLASMA WAVE SPECTRUM" - Alla PSD
            %       ELECTRIC FIELD SPECTRAL DENSITY - PSD E-fält (inte density)
            %       Övriga uppenbara.
            DATA_SET_PARAMETER_NAME = {'"PLASMA WAVE SPECTRUM"'};
            if ~isDensityMode
                DATA_SET_PARAMETER_NAME{end+1} = '"ELECTRIC FIELD SPECTRAL DENSITY"';
            end
            HeaderKvpl = HeaderKvpl.append(EJ_library.utils.KVPL2({...
                'DATA_SET_PARAMETER_NAME', DATA_SET_PARAMETER_NAME; ...
                'CALIBRATION_SOURCE_ID',   {'RPCLAP'}}));

            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', sprintf('PSD spectra of HF %s data (snapshots) on probe %i for the frequencies described in file %s.', modeStr, probeNbr, frqTabFilename));
            
            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = sprintf(...
                ['Table of snapshot start and stop timestamps, mean current and mean voltage of snapshot, and PSD of the snapshot itself.', ...
                ' The PSD frequencies are the same for every snapshot and are described in file %s.'], ...
                frqTabFilename);
            
            %================
            % Define columns
            %================
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_UTC', 'UNIT', 'SECOND',        'BYTES', 26, 'DATA_TYPE', 'TIME',          'DESCRIPTION', 'Start UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_UTC',  'UNIT', 'SECOND',        'BYTES', 26, 'DATA_TYPE', 'TIME',          'DESCRIPTION',  'Stop UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl1{end+1} = struct('NAME', 'SPECTRA_START_TIME_OBT', 'UNIT', 'SECOND',        'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',    'DESCRIPTION', 'Start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl1{end+1} = struct('NAME', 'SPECTRA_STOP_TIME_OBT',  'UNIT', 'SECOND',        'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL',    'DESCRIPTION',  'Stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
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
                PSD_UNIT        = 'NANOAMPERE**2/HERTZ';
                
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
                PSD_UNIT        = 'VOLT**2/HERTZ';
                
            end
            nSpectrumColumns = nTabColumns - (length(ocl1) + length(ocl2));
            ocl2{end+1} = struct('NAME', sprintf('PSD_%s', filenameModeStr), 'ITEMS', nSpectrumColumns, 'UNIT', PSD_UNIT, 'DESCRIPTION', PSD_DESCRIPTION);

            % For all columns: Set ITEM_BYTES/BYTES.
            for iOc = 1:length(ocl2)
                if isfield(ocl2{iOc}, 'ITEMS')    ocl2{iOc}.ITEM_BYTES = 14;
                else                              ocl2{iOc}.BYTES      = 14;
                end
                ocl2{iOc}.DATA_TYPE = 'ASCII_REAL';
            end

            LblData.OBJTABLE.OBJCOL_list = [ocl1, ocl2];
        end



        function LblData = get_PHO_data(obj, LhtKvpl)
            % IMPLEMENTATION NOTE: Derives timestamps from columns since the Lapdog PHO struct does not contain timing
            % information. TEMPORARY SOLUTION.

            HeaderKvpl = obj.HeaderAllKvpl.append(LhtKvpl);
            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-08-30', 'EJ', 'Initial version'}, ...
                {'2018-11-13', 'EJ', 'Descriptions clean-up, lowercase'}, ...
                {'2018-11-27', 'EJ', 'Updated global DESCRIPTIONs'}, ...
                {'2019-02-18', 'EJ', 'Added DATA_SET_PARAMETER_NAME, CALIBRATION_SOURCE_ID'}});
            HeaderKvpl = createLBL.definitions.modify_PLKS_header(HeaderKvpl);
            HeaderKvpl = createLBL.definitions.remove_ROSETTA_keywords(HeaderKvpl);
            HeaderKvpl = createLBL.definitions.remove_INSTRUMENT_MODE_keywords(HeaderKvpl);
            
            HeaderKvpl = HeaderKvpl.append(EJ_library.utils.KVPL2({...
                'DATA_SET_PARAMETER_NAME', {'"PHOTOSATURATION CURRENT"'}'; ...
                'CALIBRATION_SOURCE_ID',   {'RPCLAP'}}));

            HeaderKvpl = HeaderKvpl.append_kvp('DESCRIPTION', 'Time series of photosaturation current.');
            
            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Table of timestamps and photosaturation current derived collectively from multiple sweeps (not just an average of multiple estimates).';

            %================
            % Define columns
            %================
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',            'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECOND', 'DESCRIPTION', 'UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.',                           'useFor', {{'START_TIME', 'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',            'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECOND', 'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).', 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'I_PH0',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'AMPERE', 'DESCRIPTION', ...
                ['Photosaturation current derived collectively from multiple sweeps (not just an average of multiple estimates).', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'I_PH0_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',        'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end



        % USC = U_sc = Potential, Spacecraft
        %    
        % NOTE: BUG in Lapdog. UTC sometimes has 3 and sometimes 6 decimals. ==> Assertions will fail sometimes.
        %   Still true? /EJ 2018-11-06
        function LblData = get_USC_data(obj, LhtKvpl, firstPlksFile)
            
            [HeaderKvpl, junk] = obj.build_header_KVPL_from_single_PLKS(LhtKvpl, firstPlksFile);
            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-08-29', 'AE', 'Initial version'}, ...
                {'2018-11-13', 'EJ', 'Descriptions clean-up, lowercase. 6 UTC decimals'}, ...
                {'2018-11-16', 'EJ', 'Added INSTRUMENT_MODE_* keywords'}, ...
                {'2018-11-27', 'EJ', 'Updated DESCRIPTIONs'}, ...
                {'2019-02-18', 'EJ', 'Added DATA_SET_PARAMETER_NAME, CALIBRATION_SOURCE_ID'}, ...
                {'2019-02-21', 'EJ', 'Updated DESCRIPTIONs'}});
            HeaderKvpl = createLBL.definitions.remove_ROSETTA_keywords(HeaderKvpl);
            
            HeaderKvpl = HeaderKvpl.append(EJ_library.utils.KVPL2({...
                'DATA_SET_PARAMETER_NAME', {'"SPACECRAFT POTENTIAL"'}; ...
                'CALIBRATION_SOURCE_ID',   {'RPCLAP'}}));

            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', 'Time series of proxy for spacecraft potential.');

            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = ['Table of timestamps, and a proxy for spacecraft potential, derived from either (1) zero current', ...
                ' crossing in sweep, or (2) floating potential measurement (downsampled).', ...
                ' Timestamps can thus refer to either the midpoint of a sweep, or an individual sample.'];    % TODO: Check with FJ/AE if timestamps can refer to individual LF/HF sample, or 32S sample.

            %================
            % Define columns
            %================
            % FJ's proposal: 2019-02-21: V_SC_POT_PROXY: 'Proxy for spacecraft potential derived from either (a) floating potential measurement (downsampled), or (b) negated estimate of bias potential in sweep where the current is zero
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',                     'DATA_TYPE', 'TIME',          'BYTES', 23, 'UNIT', 'SECOND', 'DESCRIPTION', 'UTC time YYYY-MM-DD HH:MM:SS.FFF.');                                % 'useFor', {{'START_TIME'}}
            ocl{end+1} = struct('NAME', 'TIME_OBT',                     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECOND', 'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');   % 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT', 'STOP_TIME_from_OBT'}}
            ocl{end+1} = struct('NAME', 'V_SC_POT_PROXY',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',   'DESCRIPTION', ...
                ['Proxy for spacecraft potential derived from either (a) floating potential measurement (downsampled), or (b) negated estimate of bias potential in sweep where the current is zero.', ...
                ' Actual source of data depends on what is available.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'V_SC_POT_PROXY_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'DATA_SOURCE',                  'DATA_TYPE', 'ASCII_REAL',    'BYTES',  1, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', ...
                'Source of data for the spacecraft potential proxy value. 1 or 2=Floating potential measurement on probe 1 or 2 respectively. 3=Negated voltage in sweep on probe 1 for which current is zero.');
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',                 'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);            
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end



        % ASW = Analyzed sweep parameters
        function LblData = get_ASW_data(obj, LhtKvpl, firstPlksFile)
            % TODO-NEED-INFO: Add SPACECRAFT POTENTIAL for Photoelectron knee potential?
            
            [HeaderKvpl, junk] = obj.build_header_KVPL_from_single_PLKS(LhtKvpl, firstPlksFile);
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-08-30', 'EJ', 'Initial version'}, ...
                {'2018-11-13', 'EJ', 'Descriptions clean-up, lowercase'}, ...
                {'2018-11-16', 'EJ', 'Added INSTRUMENT_MODE_* keywords'}, ...
                {'2018-11-27', 'EJ', 'Updated global DESCRIPTION'}, ...
                {'2019-02-04', 'EJ', 'Updated UNITs, ion bulk speed DESCRIPTION'}, ...
                {'2019-02-18', 'EJ', 'Added DATA_SET_PARAMETER_NAME, CALIBRATION_SOURCE_ID'}, ...
                {'2019-02-20', 'EJ', 'Changed from timestamp interval to single timestamp per row'}});
            HeaderKvpl = createLBL.definitions.remove_ROSETTA_keywords(HeaderKvpl);
            
            HeaderKvpl = HeaderKvpl.append(EJ_library.utils.KVPL2({...
                'DATA_SET_PARAMETER_NAME',  {'"ELECTRON DENSITY"', '"PHOTOSATURATION CURRENT"', '"ION BULK VELOCITY"','"ELECTRON TEMPERATURE"', '"SPACECRAFT POTENTIAL"'}; ...
                'CALIBRATION_SOURCE_ID',    {'RPCLAP', 'RPCMIP'}}));
            
            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', 'Analyzed sweeps (ASW). Miscellaneous physical high-level quantities derived from individual sweeps.');
            
            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Time series of sweep-based estimates of electron density, ion bulk speed, electron temperature, and photoelectron knee potential. Timestamps represent the middle of the corresponding sweeps.';
            
            %================
            % Define columns
            %================
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',                      'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECOND',         'DESCRIPTION', 'UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');   % 'useFor', {{'STOP_TIME'}}
            ocl{end+1} = struct('NAME', 'TIME_OBT',                      'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECOND',         'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');   % 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT'}}

            ocl{end+1} = struct('NAME', 'N_E',                           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'CENTIMETER**-3', 'DESCRIPTION', ['Electron density derived from individual sweep.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DATA_SET_PARAMETER_NAME', {{'"ELECTRON DENSITY"'}} , 'CALIBRATION_SOURCE_ID', {{'RPCLAP'}});
            ocl{end+1} = struct('NAME', 'N_E_QUALITY_VALUE',             'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            
            ocl{end+1} = struct('NAME', 'I_PH0',                         'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'AMPERE',         'DESCRIPTION', ...
                ['Photosaturation current derived from individual sweep.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DATA_SET_PARAMETER_NAME',  {{'"PHOTOSATURATION CURRENT"'}}, 'CALIBRATION_SOURCE_ID', {{'RPCLAP'}});
            ocl{end+1} = struct('NAME', 'I_PH0_QUALITY_VALUE',           'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            
            ocl{end+1} = struct('NAME', 'V_ION_BULK_XCAL',               'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'METER/SECOND',       ...
                'DESCRIPTION', ['Ion bulk speed derived from individual sweep (speed; always non-negative scalar), while assuming a specific ion mass (see documentation). Cross-calibrated with RPCMIP.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DATA_SET_PARAMETER_NAME',  {{'"ION BULK VELOCITY"'}}, 'CALIBRATION_SOURCE_ID', {{'RPCLAP', 'RPCMIP'}});
            ocl{end+1} = struct('NAME', 'V_ION_BULK_XCAL_QUALITY_VALUE', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            
            ocl{end+1} = struct('NAME', 'T_E',                           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'ELECTRONVOLT',        ...
                'DESCRIPTION', ['Electron temperature derived from exponential part of sweep.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DATA_SET_PARAMETER_NAME',  {{'"ELECTRON TEMPERATURE"'}}, 'CALIBRATION_SOURCE_ID', {{'RPCLAP'}});
            ocl{end+1} = struct('NAME', 'T_E_QUALITY_VALUE',             'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            
            ocl{end+1} = struct('NAME', 'T_E_XCAL',                      'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'ELECTRONVOLT',        ...
                'DESCRIPTION', ['Electron temperature, derived by using the linear part of the electron current of the sweep, and density measurement from RPCMIP.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DATA_SET_PARAMETER_NAME',  {{'"ELECTRON TEMPERATURE"'}}, 'CALIBRATION_SOURCE_ID', {{'RPCLAP', 'RPCMIP'}});
            ocl{end+1} = struct('NAME', 'T_E_XCAL_QUALITY_VALUE',        'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            
            ocl{end+1} = struct('NAME', 'V_PH_KNEE',                     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',      ...
                'DESCRIPTION', ['Photoelectron knee potential.', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DATA_SET_PARAMETER_NAME', {{'"SPACECRAFT POTENTIAL"'}}, 'CALIBRATION_SOURCE_ID', {{'RPCLAP'}});
            ocl{end+1} = struct('NAME', 'V_PH_KNEE_QUALITY_VALUE',       'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',                  'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            LblData.OBJTABLE.OBJCOL_list = ocl;
        end



        % NOTE: No LBL timestamps for now, and hence no such arguments.
        function LblData = get_NPL_data(obj)
            
            % IMPLEMENTATION NOTE: As of 2018-11-13, no such data product has ever been produced (except dummy files),
            % and therefore no such label file has ever been produced. Must therefore set LBL header timestamps from
            % columns for now.
            %   NOTE: Currently, not even empty timestamps are properly added to the LBL header.
            % NOTE: Using this code without setting LABEL_REVISION_NOTE should trigger assertion error (overwriting is
            % required).
            
            HeaderKvpl = obj.HeaderAllKvpl;
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2019-02-04', 'EJ', 'Updated UNIT'}, ...
                {'2019-02-18', 'EJ', 'Added DATA_SET_PARAMETER_NAME, CALIBRATION_SOURCE_ID'}});
            HeaderKvpl = HeaderKvpl.append_kvp('START_TIME', []);                    % Set empty header LBL timestamp to remind future reader to explicitly choose how to set timestamps.
            HeaderKvpl = createLBL.definitions.modify_PLKS_header(HeaderKvpl);
            HeaderKvpl = createLBL.definitions.remove_ROSETTA_keywords(HeaderKvpl);
            
            % MB states:
            % """"PLASMA DENSITY [cross-calibration from ion and electron density; in the label, put ELECTRON DENSITY,
            % ION DENSITY and PLASMA DENSITY]""""
            % TODO-NEED-INFO: Use above?
            HeaderKvpl = HeaderKvpl.append(EJ_library.utils.KVPL2({...
                    'DATA_SET_PARAMETER_NAME', {'"ELECTRON DENSITY"', '"ION DENSITY"', '"PLASMA DENSITY"'}'; ...    % Use all three *_DENSITY symbols?
                    'CALIBRATION_SOURCE_ID',   {'RPCLAP', 'RPCMIP'}}));
            
            DESCRIPTION = 'Time series of plasma density.';
            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', DESCRIPTION);
            
            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = 'Table of timestamps and an estimate of plasma density derived from individual fix-bias density mode (current) measurements.';
            
            %================
            % Define columns
            %================
            ocl = [];
            ocl{end+1} = struct('NAME', 'TIME_UTC',       'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECOND',         'DESCRIPTION', 'UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');                             % 'useFor', {{'START_TIME', 'STOP_TIME'}});
            ocl{end+1} = struct('NAME', 'TIME_OBT',       'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECOND',         'DESCRIPTION', 'Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');   % 'useFor', {{'SPACECRAFT_CLOCK_START_COUNT', 'SPACECRAFT_CLOCK_STOP_COUNT'}});
            ocl{end+1} = struct('NAME', 'N_PL',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'CENTIMETER**-3', 'DESCRIPTION', ...
                ['Plasma density derived from individual fix-bias density mode (current) measurements. Parameter derived from low time resolution estimates of the plasma density from either RPCLAP or RPCMIP (changes over time).', obj.MC_DESC_AMENDM], ...
                'MISSING_CONSTANT', obj.MISSING_CONSTANT);
            ocl{end+1} = struct('NAME', 'QUALITY_VALUE',  'DATA_TYPE', 'ASCII_REAL',    'BYTES',  3, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QVALUE_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',   'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            LblData.OBJTABLE.OBJCOL_list = ocl;
            
        end
        
        
        
        %function get_EFL_data(obj)
        %    ELECTRIC_FIELD_COMPONENT
        %end



        function LblData = get_AxS_data(obj, LhtKvpl, firstPlksFile, ixsFilename)
            
            [HeaderKvpl, FirstPlksSs] = build_header_KVPL_from_single_PLKS(obj, LhtKvpl, firstPlksFile);
            HeaderKvpl = HeaderKvpl.set_value('START_TIME',                   FirstPlksSs.START_TIME);
            HeaderKvpl = HeaderKvpl.set_value('SPACECRAFT_CLOCK_START_COUNT', FirstPlksSs.SPACECRAFT_CLOCK_START_COUNT);
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-11-13', 'EJ', 'First documented version'}, ...
                {'2018-11-16', 'EJ', 'Removed ROSETTA:* keywords'}, ...
                {'2018-11-21', 'EJ', 'Update global DESCRIPTION'}, ...
                {'2019-02-04', 'EJ', 'Updated UNITs'}});
            HeaderKvpl = createLBL.definitions.remove_ROSETTA_keywords(HeaderKvpl);

            DESCRIPTION = sprintf('Model fitted analysis of %s sweep file.', ixsFilename);
            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', DESCRIPTION);
            
            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = DESCRIPTION;
            
            %================
            % Define columns
            %================
            ocl1 = {};
            ocl1{end+1} = struct('NAME', 'START_TIME_UTC',  'UNIT', 'SECOND',        'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION', 'Start time of sweep. UTC time YYYY-MM-DD HH:MM:SS.FFF.');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_UTC',   'UNIT', 'SECOND',        'BYTES', 26, 'DATA_TYPE', 'TIME',       'DESCRIPTION',  'Stop time of sweep. UTC time YYYY-MM-DD HH:MM:SS.FFF.');
            ocl1{end+1} = struct('NAME', 'START_TIME_OBT',  'UNIT', 'SECOND',        'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Start time of sweep. Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl1{end+1} = struct('NAME', 'STOP_TIME_OBT',   'UNIT', 'SECOND',        'BYTES', 16, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION',  'Stop time of sweep. Spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl1{end+1} = struct('NAME', 'Qualityfactor',   'UNIT', obj.NO_ODL_UNIT, 'BYTES',  3, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Quality factor from 0-100.');   % TODO: Correct?
            ocl1{end+1} = struct('NAME', 'SAA',             'UNIT', 'DEGREE',        'BYTES',  7, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Solar aspect angle in spacecraft XZ plane, measured from Z+ axis.');
            ocl1{end+1} = struct('NAME', 'Illumination',    'UNIT', obj.NO_ODL_UNIT, 'BYTES',  4, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl1{end+1} = struct('NAME', 'direction',       'UNIT', obj.NO_ODL_UNIT, 'BYTES',  1, 'DATA_TYPE', 'ASCII_REAL', 'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            % ----- (NOTE: Switching from ocl1 to ocl2.) -----
            ocl2 = {};
            ocl2{end+1} = struct('NAME', 'old_Vsi',                'UNIT', 'VOLT',          'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old_Vx',                 'UNIT', 'VOLT',          'DESCRIPTION', 'Spacecraft potential + Te from electron current fit. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vsg',                    'UNIT', 'VOLT',          'DESCRIPTION', 'Spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'sigma_Vsg',              'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for spacecraft potential from gaussian fit to second derivative.');
            ocl2{end+1} = struct('NAME', 'old_Tph',                'UNIT', 'ELECTRONVOLT',  'DESCRIPTION', 'Photoelectron temperature. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'old_Iph0',               'UNIT', 'AMPERE',         'DESCRIPTION', 'Photosaturation current. Older analysis method.');
            ocl2{end+1} = struct('NAME', 'Vb_lastnegcurrent',      'UNIT', 'VOLT',          'DESCRIPTION', 'Bias potential below zero current.');
            ocl2{end+1} = struct('NAME', 'Vb_firstposcurrent',     'UNIT', 'VOLT',          'DESCRIPTION', 'Bias potential above zero current.');
            ocl2{end+1} = struct('NAME', 'Vbinfl',                 'UNIT', 'VOLT',          'DESCRIPTION', 'Bias potential of inflection point in current.');
            ocl2{end+1} = struct('NAME', 'dIinfl',                 'UNIT', 'AMPERE/VOLT',       'DESCRIPTION', 'Derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'd2Iinfl',                'UNIT', 'AMPERE/(VOLT**2)',     'DESCRIPTION', 'Second derivative of current in inflection point.');
            ocl2{end+1} = struct('NAME', 'Iph0',                   'UNIT', 'AMPERE',         'DESCRIPTION', 'Photosaturation current.');
            ocl2{end+1} = struct('NAME', 'Tph',                    'UNIT', 'ELECTRONVOLT',        'DESCRIPTION', 'Photoelectron temperature.');
            ocl2{end+1} = struct('NAME', 'Vsi',                    'UNIT', 'VOLT',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current.');
            ocl2{end+1} = struct('NAME',       'Vph_knee',         'UNIT', 'VOLT',         'DESCRIPTION',                               'Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');
            ocl2{end+1} = struct('NAME', 'sigma_Vph_knee',         'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Potential at probe position from photoelectron current knee (gaussian fit to second derivative).');
            ocl2{end+1} = struct('NAME',       'Te_linear',        'UNIT', 'ELECTRONVOLT',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ne_linear',        'UNIT', 'CENTIMETER**-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_ne_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ion_slope',        'UNIT', 'AMPERE/VOLT',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_slope',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'ion_intersect',    'UNIT', 'AMPERE',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_intersect',    'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_slope',          'UNIT', 'AMPERE/VOLT',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_slope',          'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'e_intersect',      'UNIT', 'AMPERE',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_intersect',      'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential.');
            ocl2{end+1} = struct('NAME',       'ion_Vb_intersect', 'UNIT', 'AMPERE',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_ion_Vb_intersect', 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'e_Vb_intersect',   'UNIT', 'AMPERE',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_e_Vb_intersect',   'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'Tphc',                   'UNIT', 'ELECTRONVOLT',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable).');
            ocl2{end+1} = struct('NAME', 'nphc',                   'UNIT', 'CENTIMETER**-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable).');
            ocl2{end+1} = struct('NAME',       'phc_slope',        'UNIT', 'AMPERE/VOLT',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_slope',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME',       'phc_intersect',    'UNIT', 'AMPERE',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'sigma_phc_intersect',    'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear photoelectron current fit as a function of bias potential.');
            ocl2{end+1} = struct('NAME', 'ne_5eV',                 'UNIT', 'CENTIMETER**-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming electron temperature Te = 5 eV.');
            ocl2{end+1} = struct('NAME', 'ni_v_dep',               'UNIT', 'CENTIMETER**-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity.');
            ocl2{end+1} = struct('NAME', 'ni_v_indep',             'UNIT', 'CENTIMETER**-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate.');
            ocl2{end+1} = struct('NAME', 'v_ion',                  'UNIT', 'METER/SECOND',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate.');
            ocl2{end+1} = struct('NAME',       'Te_exp',           'UNIT', 'ELECTRONVOLT',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_Te_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current.');
            ocl2{end+1} = struct('NAME',       'ne_exp',           'UNIT', 'CENTIMETER**-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');
            ocl2{end+1} = struct('NAME', 'sigma_ne_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron density derived from fit of exponential part of the thermal electron current.');
            
            ocl2{end+1} = struct('NAME', 'Rsquared_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current.');
            ocl2{end+1} = struct('NAME', 'Rsquared_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current.');
            
            ocl2{end+1} = struct('NAME',       'Vbar',             'UNIT', obj.ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'sigma_Vbar',             'UNIT', obj.ODL_VALUE_UNKNOWN,    'DESCRIPTION', '');
            
            ocl2{end+1} = struct('NAME', 'ASM_Iph0',                   'UNIT', 'AMPERE',         'DESCRIPTION', 'Assumed photosaturation current used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'ASM_Tph',                    'UNIT', 'ELECTRONVOLT',        'DESCRIPTION', 'Assumed photoelectron temperature used (referred to) in the Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Vsi',                    'UNIT', 'VOLT',         'DESCRIPTION', 'Bias potential of intersection between photoelectron and ion current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_Te_linear',        'UNIT', 'ELECTRONVOLT',        'DESCRIPTION',                               'Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron temperature from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ne_linear',        'UNIT', 'CENTIMETER**-3',     'DESCRIPTION',                               'Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'sigma_asm_ne_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron (plasma) density from linear fit to electron current with Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_slope',        'UNIT', 'AMPERE/VOLT',       'DESCRIPTION',                               'Slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_slope',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_intersect',    'UNIT', 'AMPERE',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_intersect',    'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of ion current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_slope',          'UNIT', 'AMPERE/VOLT',       'DESCRIPTION',                               'Slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_slope',          'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_intersect',      'UNIT', 'AMPERE',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_intersect',      'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of absolute potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ion_Vb_intersect', 'UNIT', 'AMPERE',         'DESCRIPTION',                               'Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ion_Vb_intersect', 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of ion current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_e_Vb_intersect',   'UNIT', 'AMPERE',         'DESCRIPTION',                               'Y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_e_Vb_intersect',   'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for y-intersection of linear electron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_Tphc',                   'UNIT', 'ELECTRONVOLT',        'DESCRIPTION', 'Photoelectron cloud temperature (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_nphc',                   'UNIT', 'CENTIMETER**-3',     'DESCRIPTION', 'Photoelectron cloud density (if applicable). Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_phc_slope',        'UNIT', 'AMPERE/VOLT',       'DESCRIPTION',                               'Slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_slope',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for slope of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_phc_intersect',    'UNIT', 'AMPERE',         'DESCRIPTION',                               'Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_phc_intersect',    'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Y-intersection of linear photoelectron current fit as a function of bias potential. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ne_5eV',                 'UNIT', 'CENTIMETER**-3',     'DESCRIPTION', 'Electron density from linear electron current fit, assuming Te= 5eV. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_dep',               'UNIT', 'CENTIMETER**-3',     'DESCRIPTION', 'Ion density from slope of ion current fit assuming ions of a certain mass and velocity. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_ni_v_indep',             'UNIT', 'CENTIMETER**-3',     'DESCRIPTION', 'Ion density from slope and intersect of ion current fit assuming ions of a certain mass. velocity independent estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_v_ion',                  'UNIT', 'METER/SECOND',       'DESCRIPTION', 'Ion ram velocity derived from the velocity independent and dependent ion density estimate. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_Te_exp',           'UNIT', 'ELECTRONVOLT',        'DESCRIPTION',                               'Electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for electron temperature from exponential fit to electron current. Fixed photoelectron current assumption.');
            ocl2{end+1} = struct('NAME',       'asm_ne_exp',           'UNIT', 'CENTIMETER**-3',     'DESCRIPTION',                               'Electron density derived from fit of exponential part of the thermal electron current.');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Fractional error estimate for Electron density derived from fit of exponential part of the thermal electron current.');
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_linear',        'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the linear part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            ocl2{end+1} = struct('NAME', 'asm_Rsquared_exp',           'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Coefficient of determination for total modelled current, where the (thermal plasma) electron current is derived from fit for the exponential part of the ideal electron current. Fixed photoelectron current assumption.');   % New from commit f89c62b, 2015-01-09 or earlier.
            
            ocl2{end+1} = struct('NAME', 'ASM_m_ion',      'BYTES', 3, 'UNIT', 'AMU',               'DESCRIPTION', 'Assumed ion mass for all ions.');
            ocl2{end+1} = struct('NAME', 'ASM_Z_ion',      'BYTES', 2, 'UNIT', 'ELEMENTARY CHARGE', 'DESCRIPTION', 'Assumed ion charge for all ions.');
            ocl2{end+1} = struct('NAME', 'ASM_v_ion',                  'UNIT', 'METER/SECOND',               'DESCRIPTION', 'Assumed ion ram speed in used in *_v_dep variables.');
            ocl2{end+1} = struct('NAME',     'Vsc_ni_ne',              'UNIT', 'VOLT',                 'DESCRIPTION', 'Spacecraft potential needed to produce identical ion (ni_v_indep) and electron (ne_linear) densities.');
            ocl2{end+1} = struct('NAME', 'asm_Vsc_ni_ne',              'UNIT', 'VOLT',                 'DESCRIPTION', 'Spacecraft potential needed to produce identical ion (asm_ni_v_indep) and electron (asm_ne_linear) densities. Fixed photoelectron current assumption.');
            
            ocl2{end+1} = struct('NAME', 'Vsc_aion',                  'UNIT', 'VOLT',      'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'ni_aion',                   'UNIT', 'CENTIMETER**-3',  'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'v_aion',                    'UNIT', 'METER/SECOND',    'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_Vsc_aion',              'UNIT', 'VOLT',      'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_ni_aion',               'UNIT', 'CENTIMETER**-3',  'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_v_aion',                'UNIT', 'METER/SECOND',    'DESCRIPTION', '');
            %---------------------------------------------------------------------------------------------------
            
            ocl2{end+1} = struct('NAME',           'Te_exp_belowVknee', 'UNIT', 'ELECTRONVOLT',   'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',     'sigma_Te_exp_belowVknee', 'UNIT', 'ELECTRONVOLT',   'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',           'ne_exp_belowVknee', 'UNIT', 'CENTIMETER**-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',     'sigma_ne_exp_belowVknee', 'UNIT', 'CENTIMETER**-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',       'asm_Te_exp_belowVknee', 'UNIT', 'ELECTRONVOLT',   'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_sigma_Te_exp_belowVknee', 'UNIT', 'ELECTRONVOLT',   'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME',       'asm_ne_exp_belowVknee', 'UNIT', 'CENTIMETER**-3', 'DESCRIPTION', '');
            ocl2{end+1} = struct('NAME', 'asm_sigma_ne_exp_belowVknee', 'UNIT', 'CENTIMETER**-3', 'DESCRIPTION', '');
            
            for iOc = 1:length(ocl2)
                if ~isfield(ocl2{iOc}, 'BYTES')
                    ocl2{iOc}.BYTES = 14;
                end
                ocl2{iOc}.DATA_TYPE = 'ASCII_REAL';
            end
            
            LblData.OBJTABLE.OBJCOL_list = [ocl1, ocl2];
            
        end    % get_AxS_data()
        
        
        
        % NOTE: Label files are not delivered.
        function LblData = get_EST_data(obj, estTabPath, plksFileList, probeNbrList)
            
            %===============================================================
            % NOTE: createLBL.create_EST_prel_LBL_header(...)
            %       sets certain LBL/ODL variables to handle collisions:
            %    START_TIME / STOP_TIME,
            %    SPACECRAFT_CLOCK_START_COUNT / SPACECRAFT_CLOCK_STOP_COUNT
            %    obj.HeaderAllKvpl
            %===============================================================
            HeaderKvpl = createLBL.create_EST_prel_LBL_header(estTabPath, plksFileList, probeNbrList, obj.HeaderAllKvpl);
            HeaderKvpl = createLBL.definitions.modify_PLKS_header(HeaderKvpl);
            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-11-14', 'EJ', 'First documented version'}, ...
                {'2018-11-16', 'EJ', 'Removed ROSETTA:* keywords'}, ...
                {'2019-02-04', 'EJ', 'Updated UNITs'}});
            HeaderKvpl = createLBL.definitions.remove_ROSETTA_keywords(HeaderKvpl);
            
            DESCRIPTION = 'Best estimates of physical values from model fitted analysis based on sweeps.';
            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', DESCRIPTION);

            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = DESCRIPTION;

            %================
            % Define columns
            %================
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECOND',         'DESCRIPTION', 'Start UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl{end+1} = struct('NAME', 'STOP_TIME_UTC',      'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECOND',         'DESCRIPTION',  'Stop UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECOND',         'DESCRIPTION', 'Start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl{end+1} = struct('NAME', 'STOP_TIME_OBT',      'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECOND',         'DESCRIPTION',  'Stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',       'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', obj.QFLAG1_DESCRIPTION);
            ocl{end+1} = struct('NAME', 'npl',                'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'CENTIMETER**-3', 'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of plasma number density.');
            ocl{end+1} = struct('NAME', 'Te',                 'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'ELECTRONVOLT',   'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of electron temperature.');
            ocl{end+1} = struct('NAME', 'Vsc',                'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',           'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Best estimate of spacecraft potential.');
            ocl{end+1} = struct('NAME', 'Probe_number',       'DATA_TYPE', 'ASCII_REAL',    'BYTES',  1, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', 'Probe number. 1 or 2.');
            ocl{end+1} = struct('NAME', 'Direction',          'DATA_TYPE', 'ASCII_REAL',    'BYTES',  1, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', 'Sweep bias step direction. 1 for positive bias step, 0 for negative bias step.');
            ocl{end+1} = struct('NAME', 'Illumination',       'DATA_TYPE', 'ASCII_REAL',    'BYTES',  4, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', 'Sunlit probe indicator. 1 for sunlit, 0 for shadow, partial shadow otherwise.');
            ocl{end+1} = struct('NAME', 'Sweep_group_number', 'DATA_TYPE', 'ASCII_REAL',    'BYTES',  5, 'UNIT', obj.NO_ODL_UNIT,  'DESCRIPTION', ...
                ['Number signifying which group of sweeps the data comes from. ', ...
                'Groups of sweeps are formed for the purpose of deriving/selecting values to be used in best estimates. ', ...
                'All sweeps with the same group number are almost simultaneous. For every type of best estimate, at most one is chosen from each group.' ...
                ]);  % NOTE: Making such a long line in LBL file causes trouble?!!

            LblData.OBJTABLE.OBJCOL_list = ocl;
        end
        
        
        
        % NOTE: TAB+LBL files will likely not be delivered.
        function LblData = get_A1P_data(obj, LhtKvpl, firstPlksFile)
            
            [HeaderKvpl, junk] = obj.build_header_KVPL_from_single_PLKS(LhtKvpl, firstPlksFile);
            
            HeaderKvpl = obj.set_LRN(HeaderKvpl, {...
                {'2018-11-14', 'EJ', 'First documented version'}, ...
                {'2018-11-21', 'EJ', 'Update global DESCRIPTION'}});
            HeaderKvpl = createLBL.definitions.remove_ROSETTA_keywords(HeaderKvpl);
            
            DESCRIPTION = 'Analyzed probe 1 parameters.';
            HeaderKvpl = HeaderKvpl.set_value('DESCRIPTION', DESCRIPTION);            
            
            LblData.HeaderKvpl           = HeaderKvpl;
            LblData.OBJTABLE.DESCRIPTION = DESCRIPTION;
            
            %================
            % Define columns
            %================
            ocl = [];
            ocl{end+1} = struct('NAME', 'START_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECOND',        'DESCRIPTION', 'Start UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl{end+1} = struct('NAME',  'STOP_TIME_UTC',     'DATA_TYPE', 'TIME',          'BYTES', 26, 'UNIT', 'SECOND',        'DESCRIPTION',  'Stop UTC time YYYY-MM-DD HH:MM:SS.FFFFFF.');
            ocl{end+1} = struct('NAME', 'START_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECOND',        'DESCRIPTION', 'Start spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl{end+1} = struct('NAME',  'STOP_TIME_OBT',     'DATA_TYPE', 'ASCII_REAL',    'BYTES', 16, 'UNIT', 'SECOND',        'DESCRIPTION',  'Stop spacecraft onboard time SSSSSSSSS.FFFFFF (true decimal point).');
            ocl{end+1} = struct('NAME', 'QUALITY_FLAG',       'DATA_TYPE', 'ASCII_INTEGER', 'BYTES',  4, 'UNIT', obj.NO_ODL_UNIT, 'DESCRIPTION', 'Quality flag from 000 (best) to 777 (worst).');
            ocl{end+1} = struct('NAME', 'Vph_knee',           'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'VOLT',          'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Potential at probe position from photoelectron current knee (gaussian fit of second derivative).');
            ocl{end+1} = struct('NAME', 'Te_exp_belowVknee',  'DATA_TYPE', 'ASCII_REAL',    'BYTES', 14, 'UNIT', 'ELECTRONVOLT',  'MISSING_CONSTANT', obj.MISSING_CONSTANT, 'DESCRIPTION', 'Electron temperature from an exponential fit to the slope of the retardation region of the electron current.');
            LblData.OBJTABLE.OBJ_COL_list = ocl;
        end
        
    end    % methods(Access=public)



    methods(Access=private)
        
        % Set LABEL_REVISION_NOTE (LRN) key value in KVPL.
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
            % PROPOSAL: Set "author" here. Remove as argument.
            
            LINE_BREAK  = sprintf('\r\n');
            INDENTATION = repmat(' ', 1, obj.indentationLength);
            
            nItems = numel(contentCellArray);
            
            rowList = {};
            for i = 1:nItems
                % ASSERTION
                assert(numel(contentCellArray{i}) == 3)
                
                dateStr = contentCellArray{i}{1};
                author  = contentCellArray{i}{2};
                message = contentCellArray{i}{3};
                
                % ASSERTIONS
                assert(~isempty(regexp(dateStr, '^20[0-9]{2}-[0-1][0-9]-[0-3][0-9]$', 'once')))
                assert(~isempty(regexp(author,  '^[A-ZÅÄÖ]+$', 'once')))
                
                rowList{i} = sprintf('%s, %s: %s', dateStr, author, message);
            end

            if nItems == 0
                error('No info to put in LABEL_REVISION_INFO. nItems == 0.')
            elseif nItems == 1
                rowStr = rowList{1};
            elseif nItems >= 2
                % Do not use the first row (in the ODL file).
                rowStr = EJ_library.utils.str_join(rowList, [LINE_BREAK, INDENTATION]);
                rowStr = [LINE_BREAK, INDENTATION, rowStr];
            end

            Kvpl = Kvpl.set_value('LABEL_REVISION_NOTE', sprintf('"%s"', rowStr));    % NOTE: Adds quotes.
        end

        
        
        % Build basic LBL header KVPL for most data products.
        % 
        % NOTE: PlksSs is used by some data products for setting DESCRIPTION (root-level and/or OBJECT=TABLE-level).
        function [HeaderKvpl, PlksSs] = build_header_KVPL_from_single_PLKS(obj, LhtKvpl, firstPlksFile)
            % PROPOSAL: Add LABEL_REVISION_NOTE.
            %   PROPOSAL: Wait until has implemented and tested use of this function.
            
            EJ_library.utils.assert.castring(firstPlksFile);
            
            [IdpHeaderKvpl, PlksSs] = createLBL.read_LBL_file(firstPlksFile);
            IdpHeaderKvpl = createLBL.definitions.modify_PLKS_header(IdpHeaderKvpl);
            
            HeaderKvpl = obj.HeaderAllKvpl.append(LhtKvpl);
            HeaderKvpl = IdpHeaderKvpl.overwrite_subset(HeaderKvpl);
        end
        
    end    % methods(Access=private)



    methods(Static, Access=private)
        
        % Remove PDS keywords which store the LAP bias value.
        % This should be used for LF and HF data only (not e.g. sweeps).
        function HeaderKvpl = remove_bias_keywords(HeaderKvpl)
            % NOTE: Not all these keywords are present simultaneously.
            HeaderKvpl = createLBL.definitions.remove_keys_by_regex(HeaderKvpl, 'ROSETTA:LAP_[IV]BIAS[12]');
        end
        
        
        
        % Remove all keys which begin with "ROSETTA:":
        % This should be done for all L5 data products.
        function HeaderKvpl = remove_ROSETTA_keywords(HeaderKvpl)
            HeaderKvpl = createLBL.definitions.remove_keys_by_regex(HeaderKvpl, 'ROSETTA:.*');
        end
        
        
        
        % Remove the INSTRUMENT_MODE_(ID|DESC) keywords (not prefixed "ROSETTA:").
        % This is intended to be used for those (L5) data products which can span multiple macros.
        function HeaderKvpl = remove_INSTRUMENT_MODE_keywords(HeaderKvpl)
            HeaderKvpl = createLBL.definitions.remove_keys_by_regex(HeaderKvpl, 'INSTRUMENT_MODE_(ID|DESC)');   % NOTE: No "ROSETTA:" prefix.
        end



        % Helper function
        % Remove all keys that match a regex (entire string).
        function Kvpl = remove_keys_by_regex(Kvpl, regexpStr)
            % Faster if using indices?!
            temp = regexp(Kvpl.keys, ['^', regexpStr, '$'], 'match');
            keysToRemove = [temp{:}];
            
            Kvpl = Kvpl.diff(keysToRemove);
        end
        
        
        
        function HeaderKvpl = modify_PLKS_header(HeaderKvpl)
            % PROPOSAL: Better name.
            
            %========================================================================================================
            % Change ROSETTA:LAP_P[12]_ADC16_FILTER values to upper case
            % ----------------------------------------------------------
            % Stems from 2018 Rosetta Archive Enchancement Science Data Review, RID RPCLAP-US-EL-001, action
            % RPCLAP-US-EL-001-DAT. Should in practise only change "KHz" to "KHZ".
            % NOTE: pds also converts these keyword values to uppercase since commit 28a2b84, 2018-10-04 so over the
            % long term, this should be unnecessary. Maybe change it for an assertion.
            %========================================================================================================
            temp = regexp(HeaderKvpl.keys, '^ROSETTA:LAP_P[12]_ADC16_FILTER$');
            i = find(~cellfun(@isempty, temp));
            values = HeaderKvpl.values;
            values(i) = upper(values(i));
            HeaderKvpl = EJ_library.utils.KVPL2(HeaderKvpl.keys, values);
        end
        
    end    % methods(Static, Access=private)
    
end   % classdef
