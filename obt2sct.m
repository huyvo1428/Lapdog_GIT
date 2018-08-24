% Convert OBT time (true decimal point) to the SCT/SCCS number part (not reset count, string).
% Compare sct2obt.m
%
%
%
% ARGUMENTS AND RETURN VALUE
% ==========================
% value   : OBT as a double (true decimals).
% sct_str : String, e.g. 386207924.64832 where decimals are "fake". NOTE: No reset count.
%
%
% NOTE: Here SCT = SCCS = "Spacecraft clock string" (SPICE uses that terminology.)
% ===================== OLD COMMENTS BELOW ==========================
%
% NOTE: THERE IS NO OBT2SCT DOESN'T GENERATE A FULL SCT STRING, IT OUTPUTS
% ONLY THE 21339876.237 PART OF THE SCT STRING 
% "1/21339876.237"
% This needs to be added whenever calling obt2sct.
% // Due to the fact that the point . in:
% //
% // SPACECRAFT_CLOCK_START/STOP_COUNT="1/21339876.237"
% //
% // is not a decimal point.. (NOT specified in PDS) but now specified
% // in PSA to be a fraction of 2^16 thus decimal .00123 seconds is stored as
% // 0.123*2^16 ~ .81
% //
% That's Reine's calculation, although I (Fredrik Johansson) suspect it is wrong, the actual
% calculation should be 0.00123*2^6/100000
%
function sct_str = obt2sct(value)

    % Old implementation - Seems wrong/bug. Returned double, not string.
    % Note division by 2^16 rather than multiplication. /Erik P G Johansson 2015-12-14
    %integ = floor(value);
    %frac = value-integ;    
    %sct = integ + (frac*1e5 /2^16);   % NOTE: Can produce initial zeros before the fake non-zero decimal digits (but the format permits it).
    
    
    int = floor(value);
    fraction = value - int;
    fake_decimals = round(fraction*2^16);
    
    % Handle overflow (e.g. fraction = 0.999999 ==> fake_decimals = 1)
    if (fake_decimals >= 2^16)
        fake_decimals = 0;
        int = int + 1;
    end
    
    sct_str = sprintf('%i.%i', int, fake_decimals);
    
end
