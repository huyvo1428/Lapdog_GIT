% Convert SCT time string (e.g. "1/21339876.23712") to an OBT number (true decimals).
%
% Compare obt2sct.m
%
% NOTE: Time strings can have arbitrary number of zeros before the fake decimals.
% 
% NOTE THAT THERE IS NO 1:1 REVERSAL OF THIS FUNCTION. OBT2SCT IS SLIGHTLY
% DIFFERENT, WITH NO STRING HANDLING.
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
% Seems to work. /Erik P G Johansson 2015-12-14
%
function varargout= sct2obt(str)

% Remove quotes and trim whitespace.
str = strtrim(strrep(str, '"', ' '));

% ASSERTIONS: Verify the very constrained assumptions made by the old code below.
% assert(str( 2) == '/')
% assert(str(13) == '.')
%
% resetCounter = str2double(str(1));
% 
% obtsec  = str2double(str(3:12));
% sctfrac = str(14:end); % don't know how long string it is, but fake decimal at pos 14, and integer afterwards
% 
% frac = str2double(sctfrac);
% 
% frac = frac/2^16;
% 
% obt = obtsec+frac;


s1   = strsplit(str, '/');
s2   = strsplit(s1{2}, '.');
assert(numel(s1) == 2)
assert(numel(s2) == 2)
resetCounter = str2double(s1{1});
obt          = str2double(s2{1}) + str2double(s2{2})/2^16;


if (nargout == 1)

    varargout = {obt};
    
else 
    
    varargout = {obt, resetCounter};
end

end