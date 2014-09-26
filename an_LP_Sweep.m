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
%
%   3. The sweep is sorted, changing the direction of sweeping to always be
%       up sweeps. Sweeps with both up and down sweeping is not handled
%       however we do not plan to use this feature.
%
%	5. find the space craft potential by calling Vplasma
%
%
%
%	8.Now the ion current is examined by calling "LP_Ion_curr". Returned are the ion current and the coefficients for the polynomial 
%	   fitting the low probe potential values.
%
%	9.The Ion current is removed from the combined  current, hopefully leaving only the plasma 
%	   electron current and Iph; Ie+Iph = I - Ii.
%
%   10. Recompute the spacecraft potential using  Vplasma
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
%     V             bias potential
%     I             sweep current
%     Vguess        spacecraft potential guess from previous analysis
%     illuminated   if the probe is sunlit or not (from SPICE Kernel
%     evaluation)
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

function DP = an_LP_Sweep(V, I,Vguess,illuminated)

%global IN;         % Instrument information
%global LP_IS;      % Instrument constants
%global CO          % Physical constants
%global ALG;        % Various algorithm constants

global efi_f_io_lp_l1bp; % Verbosity level
efi_f_io_lp_l1bp = 0; %debugging!

VPLASMA_TO_VSC = 0.64; %from simulation experiments


warning off; % For unnecessary warnings (often when taking log of zero, these values are not used anyways)
Q    = [0 0 0 0];   % Quality vector


% Initialize DP to ensure a return value:
DP = [];

DP.If0     = NaN;
DP.Tph     = NaN;
DP.Vintersect = NaN;
DP.Te       = NaN;
DP.ne      = NaN;

DP.Vsc     = NaN;
DP.Vplasma = NaN;
DP.Vsigma  = NaN;

DP.ia      = NaN;
DP.ib      = NaN;
DP.ea      = NaN;
DP.eb      = NaN;

DP.Ts      = NaN;
DP.ns      = NaN;
DP.sa      = NaN;
DP.sb      = NaN;

DP.Quality = sum(Q);




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
[vPlasma, sigma,Vsc] = an_Vplasma(V,I);

%this is not

if isnan(Vsc)    
   Vsc = Vguess;
   vPlasma=Vsc*VPLASMA_TO_VSC; % from simulations
   
end






if (efi_f_io_lp_l1bp>1)
figure(33);
    
end


% Next we determine the ion current, Vsc need to be included in order 
% to determine the probe potential. However Vsc do not need to be that
% accurate here.In addition to the ion current, the coefficients from 
% the linear fit  are also returned
% [Ii,ia,ib] = LP_Ion_curr(V,LP_MA(I),Vsc);
[Ii,ia,ib] = LP_Ion_curr(V,I,Vsc); % The ion current is denoted Ii,
                                   % the coefficients a and b

                                   
%ib is a good guess for If0;


% Now, removing the linearly fitted ion-current from the 
% current will leave the collected plasma electron current & photoelectron current 
Itemp = I - Ii; %


if (efi_f_io_lp_l1bp>1)
	subplot(2,2,1),plot(V,I,'b',V,Itemp,'g');grid on;
	title('I & I - ion current');
end


%Ie_s = LP_MA(Ie); % Now we smooth the data using a 9-point moving average

%Determine the electron current (above Vsc and positive), use a moving average 
[Te,ne,Ie,ea,eb]=LP_Electron_curr(V,Itemp,Vsc);



%if the plasma electron current fail, try the spacecraft photoelectron
%cloud current analyser
if isnan(Te)

    
    cloudflag = 1;
    
    [Ts,ns,Ie,sa,sb]=LP_S_curr(V,Itemp,Vsc,vPlasma);

    DP.Ts      = Ts;
    DP.ns      = ns;
    DP.sa      = sa;
    DP.sb      = sb;

    %note that Ie is now current from photo electron cloud

end


%[Te,ne,Ie,ea,eb,rms]=LP_Electron_curr(V,LP_MA(Itemp),Vsc);

Itemp = Itemp - Ie; %the resultant current should only be photoelectron current (or zero)



if (efi_f_io_lp_l1bp>1)

    
	subplot(2,2,1),plot(V,I,'b',V,Itemp,'g');grid on;
	title('I & I - ions - electrons');
end


% Redetermine s/c potential, without ions and plasma electron /photoelectron cloud currents
[vPlasma, sigma, Vsc] = an_Vplasma(V,Itemp,vPlasma,sigma); 
%if unsuccesful, Vplasma returns our guess

if(illuminated)
    
    Iph = Itemp;
    
    
%     iph = ip(pos) - iecoll;
%     vbh = vb(pos);
%     
% 
%        
%         % Use curve above vinf:
%         pos = find(V >= Vsc);
%         
%         % Subtract collected electrons, whose current is put to zero if
%         % linear fit gives negative value:
%         iph = ip(pos) - iecoll;
%         vbh = vb(pos);
    
    % Do log fit to first 6 V:
    phind = find(V < (vPlasma-Vsc) + 6 & V>=(vPlasma-Vsc));
    phpol = polyfit(V(phind),log(abs(Iph(phind))),1);
    Tph = -1/phpol(1);
    Iftmp = -exp(phpol(2));
    
    % Find Vsc as intersection of ion and photoemission current:
    % Iterative solution:
    vs = vPlasma-Vsc;
    for(i=1:10)
        vs = -(log(-polyval([ia,ib],-vs)) - phpol(2))/phpol(1);
    end
    % Calculate If0:
    If0 = Iftmp * exp(vs/Tph);
    
    DP.If0     = If0;
    DP.Tph     = Tph;
    DP.Vintersect = vs;

end

%DP.If0     = NaN;
%DP.Tph     = NaN;%defined elsewhere...

DP.Te      = Te;
DP.ne      = ne;
DP.Vsc     = Vsc;
DP.Vplasma = vPlasma;
DP.Vsigma  = sigma;
DP.ia      = ia;
DP.ib      = ib;
DP.ea      = ea;
DP.eb      = eb;
DP.Quality = sum(Q);

 if (efi_f_io_lp_l1bp>1)
     
     if(illuminated)
         subplot(2,2,4)
         
         Iph=Itemp;    %just to get the dimension right)
         len=length(Itemp);
         
         pos=find(V>-vs,1,'first');
         Iph(1:pos)=If0;
         
         for i=pos:1:len
             Iph(i)=(If0*(1+((V(i)+Vsc-vs)/Tph))*exp(-(V(i)+Vsc-vs)/Tph));
         end
         
         Izero=Itemp-Iph;
         Itot = Ii+Ie+Iph;
         
         %      Izero(pos:end)=Itemp(pos:end)-(If0*(1+((V(pos:end)-vs)/Tph))*exp(-(V(pos:end)-vs)/Tph));
         %
         %      a=exp((V(pos:len)-vs)/Tph);
         %      adsasd=(If0(1+((V(pos:len)-vs)/Tph))*a);
         %      Izero(pos:len)=Itemp(pos:len)-adsasd;

         
         
     else
         
         Izero = Itemp;
         Itot = Ie+Ii;
         
     end
     subplot(2,2,2)
     plot(V,Izero,'og');
     grid on;
      title('V vs I - ions - electrons-photoelectrons');
     subplot(2,2,4)
     plot(V-Vsc,I,'b',V-Vsc,Itot,'g');
           title('Vp vs I & Itot ions ');

     grid on;
     
     %
     %
%     x = V(1):0.2:V(end);
%     y = gaussmf(x,[sigma Vsc]);    
% 	subplot(2,2,1),plot(V,Ie,'g',x,y*abs(max(I))/4,'b');grid on;
% 	title('V & I and Vsc Guess');
%     
%     Vsc2 = LP_Find_SCpot(V,Ie,dv); 
%     x = V(1):0.2:V(end);
%     y = gaussmf(x,[1, Vsc2]);    
% 	subplot(2,2,2),plot(V,Ie,'g',x,y*max(I),'b');grid on;
% 	title('V & I and Vsc Guess number 2');
 end



% Having removed the ion current, we use the electron current to determine
% the electron temperature and density
% [Te1,Te2,n1,n2,Ie1,Ie2,f,e,Vsc,Q] = LP_Electron_curr(V,Ie_s,Vsc,dv,Q);


end


