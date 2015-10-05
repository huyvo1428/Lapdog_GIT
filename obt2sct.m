% // Convert OBT time to the SCT number part
% NOTE: THERE IS NO OBT2SCT DOESN'T GENERATE A FULL SCT STRING, IT OUTPUTS
% ONLY THE 21339876.237 PART OF THE SCT STRING 
% "1/21339876.237"
% This needs to be added wheneever calling obt2sct.
% // Due to the fact that the point . in:
% //
% // SPACECRAFT_CLOCK_START/STOP_COUNT="1/21339876.237"
% //
% // is not a decimal point.. (NOT specified in PDS) but now specified
% // in PSA to be a fraction of 2^16 thus decimal .00123 seconds is stored as
% // 0.123*2^16 ~ .81
% //
% That's Reine's calculation, although I supect it is wrong, the actual
% calculation should be 0.00123*2^6/100000
%
function sct = obt2sct(value)

    integ = floor(value);
    frac = value-integ;
    sct = integ +(frac/2^16)*100000;
end
