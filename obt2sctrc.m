% Convert OBT to SCT/SCCS including reset counter (rc).
%
% Wrapper around obt2sct to add the reset counter to the returned string.
%
function str = obt2sctrc(obt)
    str = ['1/', obt2sct(obt)];
end