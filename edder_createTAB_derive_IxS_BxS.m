%
% Create the content for a pair IxS and IxS TAB files for EDDER.
%
%
% ARGUMENTS
% =========
% rawUtcArrays              : {iFile}{jSample} = UTC string
% rawObtArrays              : {iFile}{jSample} = OBT value (numeric)
% rawCurrentArrays          : {iFile}(jSample) = double
% rawVoltageArrays          : {iFile}(jSample) = double
% INITIAL_SWEEP_SMPLS_array : Array of the values of PDS keyword LAP_Px_INITIAL_SWEEP_SMPLS.
% nFinalPresweepSamples     : Number of positions of pre-sweep samples+ (fill values or not) that the output should
%                             contain.
% MISSING_CONSTANT          : PDS keyword MISSING_CONSTANT value. Used as fill value to represent missing values.
% 
%
% RETURN VALUES
% =============
% BxS_relativeTime      : (iTime)
% BxS_voltageArray      : (iTime)
% IxS_utc12             : {iBeginEnd}{iSweep}. iBeginEnd = 1 (begin of sweep) or 2 (end of sweep).
% IxS_obt12             : {iBeginEnd}(iSweep)
% IxS_currentArrays     : {iEdited1File}(iTime)
%
%
% Terminology, definitions of terms
% =================================
% true sweep              = The actual, intended sweep during which the bias changes in regular, same-sized steps.
%                           All true sweeps (within a command block) should have the same length.
% true pre-sweep samples  = Samples taken before the true sweep. There should be INITIAL_SWEEP_SMPLS of these in a given
%                           sweep.
% raw sweep/sequence      = "true sweep" + "true pre-sweep samples" = Sequence of samples read from EDITED1/CALIB1 (also arguments to this function).
% final sweep/sequence    = "true sweep" + "final pre-sweep samples"
%                           All final sweeps (within a command block) should have the same length, preferably also within all datasets.
%                           These sweeps are return values from the function.
% final pre-sweep samples = "true pre-sweep samples" + (optionally) fill values preceeding them. 
%
%
% NOTE: As I recall, LAP_Px_INITIAL_SWEEP_SMPLS can be wrong sometimes (very, very large values). Unclear if bug in pds
% or bitstream/TM. /Erik P G Johansson 2018-07-20.
% NOTE: Function should be able to handle (correct for) one bad INITIAL_SWEEP_SMPLS value.
% NOTE: Function should not be able to handle zero sweeps.
% IMLEMENTATION NOTE: Does not directly reference global variable N_FINAL_PRESWEEP_SAMPLES to simplify automatic testing.
% Receives values via argument instead.
%
%
% Initially created 2018-07-17 by Erik P G Johansson, IRF Uppsala, Sweden.
%
function [BxS_relativeTime, BxS_voltageArray, IxS_utc12, IxS_obt12, IxS_currentArrays] = ...
        edder_createTAB_derive_IxS_BxS(...
        rawUtcArrays, rawObtArrays, rawCurrentArrays, rawVoltageArrays, INITIAL_SWEEP_SMPLS_array, ...
        nFinalPresweepSamples, MISSING_CONSTANT)
    
    % ASSERTIONS    
    if numel(unique([numel(rawUtcArrays), numel(rawObtArrays), numel(rawVoltageArrays), numel(rawCurrentArrays), numel(INITIAL_SWEEP_SMPLS_array)])) > 1
        error('Illegal arguments. Argument arrays have different sizes.')
    end

    
    
    % Correct for very rare, badly set INITIAL_SWEEP_SMPLS values due to bug in pds or bad bitstream/TM.
    % Uses the assumption that all true sweeps should have the same length and modify the INITIAL_SWEEP_SMPLS value to fix it.
    % NOTE: If the true sweep length is (somewhat) wrong, then that will also be inadvertantly "fixed" here by adjusting INITIAL_SWEEP_SMPLS.
    rawSweepLengthArray  = cellfun(@length, rawUtcArrays);
    trueSweepLengthArray = rawSweepLengthArray(:) - INITIAL_SWEEP_SMPLS_array(:);   % Force column array.
    trueSweepLength      = mode(trueSweepLengthArray);    % The most common true sweep length. (All true sweep lengths should, ideally, be identical.)
    iOutliers = find(trueSweepLengthArray ~= trueSweepLength);
    nOutliers = numel(iOutliers);
    if nOutliers > 0        
        % ASSERTION
        if nOutliers >= 2
            error('Found sweeps with true sweep length that is inconsistent with other sweeps within command block. Too many (%i) to automatically fix. -- Aborting', ...
                nOutliers)
        end
        
        warning('Found one sweep with true sweep length that is inconsistent with other sweeps within command block. INITIAL_SWEEP_SMPLS_array(iOutliers) = [%s] -- Correcting it by correcting INITIAL_SWEEP_SMPLS_array value(s)', ...
            sprintf('%i ', INITIAL_SWEEP_SMPLS_array(iOutliers)))
        INITIAL_SWEEP_SMPLS_array(iOutliers) = rawSweepLengthArray(iOutliers) - trueSweepLength;    % NOTE: Should work for all indices (not just iOutliers).
    end
    clear trueSweepLengthArray
    

    
    % ASSERTION
    if nFinalPresweepSamples < max(INITIAL_SWEEP_SMPLS_array)
        error('Too low nFinalPresweepSamples=%i < max(INITIAL_SWEEP_SMPLS_array)=%i', nFinalPresweepSamples, max(INITIAL_SWEEP_SMPLS_array))
    end
    
    
    
    finalSweepLength = trueSweepLength + nFinalPresweepSamples;
    IxS_utc12 = {};
    IxS_obt12 = {};
    for i = 1:numel(rawUtcArrays)
        IxS_utc12{1}{i} = rawUtcArrays{i}{INITIAL_SWEEP_SMPLS_array(i)+1};   % Timestamp from first TRUE sweep sample.
        IxS_utc12{2}{i} = rawUtcArrays{i}{end};
        
        IxS_obt12{1}(i) = rawObtArrays{i}(INITIAL_SWEEP_SMPLS_array(i)+1);   % Timestamp from first TRUE sweep sample.
        IxS_obt12{2}(i) = rawObtArrays{i}(end);

        %======================================================================================================
        % Produce equally long, "clean" sweep sequences of everything, but with MISSING_CONSTANT filling out
        % the missing values.
        %======================================================================================================
        % IMPLEMENTATION NOTE: In principle unnecessary to produce multiple
        % final voltage arrays (BxS) since they should all be identical. Just
        % doing this for ~consistency/ and for the possibility of adding later assertions based on this identity.
        finalVoltageArrays{i} = pad_array(rawVoltageArrays{i}(INITIAL_SWEEP_SMPLS_array(i)+1 : end), finalSweepLength, MISSING_CONSTANT);
        finalCurrentArrays{i} = pad_array(rawCurrentArrays{i},                                       finalSweepLength, MISSING_CONSTANT);
        
        finalSweepRelativeTimeZeroObt = IxS_obt12{1}(i);   % The absolute timestamp that should represent relative sweep time=0 (BxS).
        
        % IMPLEMENTATION NOTE: Not really necessary to pad array already here since only one array will be used in the end.
        % This however makes it easier to manually compare these arrays which should, ideally be identical except for fill
        % values. (They are not (yet) identical in practice due to pds bug. /Erik P G Johansson 2018-07-20).
        % Also doing this for the possibility of later adding assertion based on this.
        finalSweepRelativeTimeArrays{i} = pad_array(rawObtArrays{i} - finalSweepRelativeTimeZeroObt, finalSweepLength, MISSING_CONSTANT);
    end
    IxS_currentArrays = finalCurrentArrays(:);   % Renaming variable. Force column vector.
    
    %===========================================
    % Derive the subset that should go into BxS
    %===========================================
    [junk, iMax] = max(INITIAL_SWEEP_SMPLS_array);
    BxS_voltageArray = finalVoltageArrays{iMax};
    BxS_relativeTime = finalSweepRelativeTimeArrays{iMax};
    %BxS_relativeTime = BxS_relativeTime(:);   % Force column vector.
end



function array = pad_array(array, newLength, padValue)
    assert(newLength >= length(array))
    
    n = newLength - length(array);
    array = [ones(n,1) * padValue; array(:)];   % Force column vector.
end
