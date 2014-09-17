%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                  
% Name: LP_AnalyseSweep.m                                               
% Author: Claes Weyde
%         Reine Gill modified UV and sunlight or not
% Description:                                                     
%       DP = LP_AnalyseSweep(P,S,probe,time)        
%
%  	This is the main function body. It is the function LP_AnalyseSweep from which all other functions are 
%	called. It returns the determined plasma parameters; Vsc, ne, Te.  
%
%	1. The gain used for the probe is determined.
%
%   2. The calibrated currents are used and any overflows are removed.
%
%   3. The sweep is sorted, changing the direction of sweeping to always be
%       up sweeps. Sweeps with both up and down sweeping is not handled
%       however we do not plan to use this feature.
%  
%   4. Convert TM units to physical SI units.
%
%	5. find the space craft potential by calling Vsc=LP_Find_SCpot(V,I,dv)
%
%	6. Following this LP_GetSunlit(time,probe) is called to get the
%	illumination status of the probe for the present time.
%
%   7. If we are compensating for photo electrons  and we are
%   illuminated then we get the UV intensity LP_GetUVIntensity for the
%   present time and the photo electron current LP_Photo_curr(V,Vsc,F107)
%   is subtracted from the probe current.
%
%	8.Now the ion current is examined by calling "LP_Ion_curr" with the current obtained by removing the 
%	   photo-current in step 7 above. Returned are the ion current and the coefficients for the polynomial 
%	   fitting the low probe potential values.
%
%	9.The Ion current is removed from the combined ion-electron current, hopefully leaving only the plasma 
%	   electron current; Ie = Iie - Ii.
%
%   10. Recompute the space craft potential using Ie, Vsc=LP_Find_SCpot(V,Ie,dv)
%
%	11.The remains are smoothed to reduce the effects of noise, using a function called "LP_MA.m". See
%	   the header for this function for more information.
%
%	12.Now, having the clean electron current, "LP_Electron_curr" is called with this current as input. 
%	   Returned are the electron density and electron temperature as well as the spacecraft potential.
%      
%	13.Now the physical parameters; Vsc, ne and Te as well as the quality vector are returned to the calling 
%	   function.                     
%                                                                  
% Input:  
%    time   UTC time in seconds
%           ISP packet time+instrument timestamp+corrections
%
%	 P      Plasma structure
%    S      Sweep configuration and data structure
%    probe  The probe we are presently analyzing                                                               
%    sm_cal_status    Status if data has been current and offset compensated
% Output: 
%	  DP	 Physical paramater information structure                                                         
%                                                                  
% Notes:                                                           
%	1. The quality vector consists of four elements: the first is a measure of the overflow while 
%	   the second, third and fourth are quality estimates for Vsc, Te and ne respectively.         
%	   The first one is between 0 and 1, the other three are rounded values between 0 and 10.
%
% Changes: 20070920: JK Burchill (University of Calgary): ensure a return
%                    value.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DP = an_LP_Sweep(V, I,time,Vguess,illuminated)

%global IN;         % Instrument information
%global LP_IS;      % Instrument constants
%global CO          % Physical constants
%global ALG;        % Various algorithm constants

global efi_f_io_lp_l1bp; % Verbosity level
efi_f_io_lp_l1bp = 10; %debugging!

warning off; % For unnecessary warnings (often when taking log of zero, these values are not used anyways)

% Initialize DP to ensure a return value:
DP = [];

Q    = [0 0 0 0];   % Quality vector


% Sort the data
[V,I] = LP_Sort_Sweep(V',I');





% %if (length(V) <= ALG.SM_Dta_Points) % Too few data points to do any work
%         if (efi_f_io_lp_l1bp)
% 		disp('Too few data points to do any work');
% 	end
%      	return;
% end

%dv = S.step_height*IN.VpTM_DAC; % Step height in volt.
dv = V(2)-V(1);



% Now the actual fitting starts
%---------------------------------------------------

% First determine the spacecraft potential
%Vsc = LP_Find_SCpot(V,I,dv);  % The spacecraft potential is denoted Vsc
[Vsc, sigma] = Vplasma(V,I,Vguess,3);



if (efi_f_io_lp_l1bp>1)
figure(33);
    
end


%illuminated = LP_GetSunlit(time,probe); % Get illumination for probe "probe"

 % Are we compensating for photo electrons  and are we in sunlight?
%if(efi_lp_photo_emission_model && illuminated) 


% Next we determine the ion current, Vsc need to be included in order 
% to determine the probe potential. However Vsc do not need to be that
% accurate here.In addition to the ion current, the coefficients from 
% the linear fit  are also returned
[Ii,ia,ib] = LP_Ion_curr(V,I,Vsc); % The ion current is denoted Ii,
                                   % the coefficients a and b

% Now, removing the linearly fitted ion-current from the electron ion 
% current will leave the collected electron current, Remember we have 
% already subtracted  Iph
Ie = I - Ii; % The electron current is denoted Ie

%Ie_s = LP_MA(Ie); % Now we smooth the data using a 9-point moving average


[Te,ne,Iph,ea,eb]=LP_Electron_curr(V,Ie_s,Vsc);

[Vsc, sigma] = Vplasma(V,Iph,Vsc,3); %let's try it again



if(illuminated)
    
    
    iph = ip(pos) - iecoll;
    vbh = vb(pos);
    
    
    % Do log fit to first 4 V:
    phind = find(vbh < vbinf + 4);
    phpol = polyfit(vbh(phind),log(abs(iph(phind))),1);
    Tph = -1/phpol(1);
    Iftmp = -exp(phpol(2));
    
    % Find Vsc as intersection of ion and photoemission current:
    % Iterative solution:
    vs = -vbinf;
    for(i=1:10)
        vs = -(log(-polyval(poli,-vs)) - phpol(2))/phpol(1);
        if(diag)
            %  vs
        end
    end
    % Calculate If0:
    If0 = Iftmp * exp(vs/Tph);
    
    
    
else
%  Iie = I; % Skip compensation for photo electrons.
end



if (efi_f_io_lp_l1bp>1)

    
	subplot(2,2,3),plot(V,I,'b',V,Ie,'g');grid on;
	title('electron side for a and b determination');
end

% Redetermine s/c potential, without ions and photo currents
%Vsc = LP_Find_SCpot(V,Ie,dv);  
[Vsc, sigma] = Vplasma(V,I,Vsc,3);



if (efi_f_io_lp_l1bp>1)
    
    
    x = V(1):0.2:V(end);
    y = gaussmf(x,[sigma Vsc]);    
	subplot(2,2,1),plot(V,Ie,'g',x,y*abs(max(I))/4,'b');grid on;
	title('V & I and Vsc Guess');
    
    Vsc2 = LP_Find_SCpot(V,Ie,dv); 
    x = V(1):0.2:V(end);
    y = gaussmf(x,[1, Vsc2]);    
	subplot(2,2,2),plot(V,Ie,'g',x,y*max(I),'b');grid on;
	title('V & I and Vsc Guess number 2');
end



% Having removed the ion current, we use the electron current to determine
% the electron temperature and density
% [Te1,Te2,n1,n2,Ie1,Ie2,f,e,Vsc,Q] = LP_Electron_curr(V,Ie_s,Vsc,dv,Q);



DP.Te      = Te;
DP.ne      = ne;
DP.Vs      = Vsc;
DP.Quality = Q;
end


