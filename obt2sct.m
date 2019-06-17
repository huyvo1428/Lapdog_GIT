% Convert OBT time (true decimal point) to the SCT/SCCS number part (not reset count, string).
% Compare sct2obt.m
%
%
%
% ARGUMENTS AND RETURN VALUE
% ==========================
% obt    : OBT as a double (true decimals).
% sctStr : String, e.g. 386207924.64832 where decimals are "fake". NOTE: No reset count.
%
%
% NOTE: Here SCT (SPICE terminology) = SCCS ("SpaceCraft Clock String"; Erik Johansson's terminology in pds s/w).
%
function sctStr = obt2sct(obt)

%if length(obt)<2

    obtInt = floor(obt);
    obtFraction = obt - obtInt;
    falseDecimals = round(obtFraction*2^16);
    
    % Handle overflow (e.g. fraction = 0.999999 ==> falseDecimals = 1)
    if (falseDecimals >= 2^16)
        falseDecimals = 0;
        obtInt = obtInt + 1;
    end
    
    sctStr = sprintf('%i.%i', obtInt, falseDecimals);
    
    
    
% else
%     obtInt = floor(obt);
%     obtFraction = obt - obtInt;
%     falseDecimals = round(obtFraction*2^16);
%     
%     % Handle overflow (e.g. fraction = 0.999999 ==> falseDecimals = 1)
%     if (falseDecimals >= 2^16)
%         obtInt(falseDecimals >= 2^16) = obtInt(falseDecimals >= 2^16) + 1;
%         falseDecimals(falseDecimals >= 2^16) = 0;
%     end
%     for i = 1:length( obt)
%         
%         sctStr{1,i}=sprintf('%i.%i', obtInt(i), falseDecimals(i));
%     end
%     
% %     sctStr = sprintf('%i.%i', obtInt, falseDecimals);
% %     sctStr = strcat(obtInt.','.',sprintf('%i',falseDecimals))
% %     
%     
%     
% end


end
