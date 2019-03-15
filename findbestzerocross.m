%Function takes a sorted (increasing Vb) array of currents with multiple
%zerocrossings, finds the crossing with the furthest distance to a current
%flip (i.e. distance to nearest positive & negative pair.)
%Proposal:actually, all positive currents followed by a negative currents are
%bullshit. Either low signal-to-noise ratio or disturbance.
%This function is called by createTAB.m (for LDL filtering) and by an_swp.m
%for zerocrossing purposes
function [highestrankpos,highestrankneg,filt_indz]=findbestzerocross(ip_no_nans)



        iz_pos= 0<ip_no_nans;
%         iz_neg= 0>ip_no_nans;

        
        %all indices where the current flips positive;
        flipupindz= find(diff(iz_pos)==1);
        %all indices where the current flips negative;
        flipdownindz= find(diff(iz_pos)==-1);
        %matrix of distances between these indices:
        %matrixflipdistances=flipupindz.'-flipdownindz;   % Does not work on MATLAB R2009a (the version installed on squid).
        matrixflipdistances = repmat(flipupindz, length(flipdownindz), 1).'-repmat(flipdownindz, length(flipupindz), 1);   % Works on MATLAB R2009a.

        %max(min(abs(matrixflipdistances),[],2))) finds the column (flipupindz) where the
        %distance to the nearest flipdownindz is farthest away
        [maxdistance,highrankind] = max(min(abs(matrixflipdistances),[],2));

        
        
        highestrankpos= flipupindz(highrankind)+1; %fix the diff 
        highestrankneg= flipupindz(highrankind);
        filt_indz= flipupindz(min(abs(matrixflipdistances),[],2)==1);
        %filt_indz= [noiseinds noiseinds+1]; 
        
        if maxdistance<2% we're a bit unfortunate, LDL disturbance/noise is occuring just at the real zero crossing 
            
            %filt_indz= [flipdownindz flipupindz];
            ip_no_nans([flipdownindz flipupindz])=nan;%remove all these crappy signals
            iz_pos= 0<ip_no_nans; %anything remaining?
            flipupindz= find(diff(iz_pos)==1);% this could be empty
            if isempty(flipupindz) %failsafe. we have a sweep with no positive values left
                highestrankpos=flipdownindz(end);
                highestrankneg=flipdownindz(end)-1;
            else
                
                highestrankpos=flipupindz(1)+1;%should only be one value left
                highestrankneg=flipupindz(1);
                
            end
            
        end
        
 

end