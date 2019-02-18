%
% Assertion on an SSL that it represents a proper PDS3 ODL file.
%
function assert_SSL_is_PDS3(Ssl)
% PROPOSAL: Add other PDS3 checks.
%   TODO-NEED-INFO: Which ones? Ideas?
%   Ex: What DVAL indicates: ODL arrays must not be empty.
    
    % ASSERTION
    % ---------
    % Extra check for "PDS_VERSION_ID = PDS3".
    % "Planetary Data System Standards Reference", Version 3.6, Section 5.3.1 specifies that the first key-value
    % should always be this, unless using some unknown feature "Standard Formatted Data Unit (SFDU)".
    if length(Ssl.keys) < 1
        error('This is not ODL data. Does not begin with PDS_VERSION_ID = PDS3. Less than one key-value assignment.')
    elseif ~strcmp(Ssl.keys{1}, 'PDS_VERSION_ID') || ~strcmp(Ssl.values{1}, 'PDS3')
        error('This is not ODL data. Does not begin with PDS_VERSION_ID = PDS3.')
    end
end