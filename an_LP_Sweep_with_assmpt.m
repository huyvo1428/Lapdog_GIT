%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Name: an_LP_Sweep.m
% Author: Fredrik Johansson, developed from original script by Claes Weyde
%
% Description:
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
%   
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

%with assumptions
function DP = an_LP_Sweep_with_assmpt(V, I,assmpt,illuminated)




%global IN;         % Instrument information
%global LP_IS;      % Instrument constants
%global CO          % Physical constants
%global ALG;        % Various algorithm constants

global an_debug VSC_TO_VPLASMA VSC_TO_VKNEE;
%VSC_TO_VPLASMA=0.64; %from SPIS simulation experiments
%VSC_TO_VKNEE = 0.36;
VSC_TO_VPLASMA=1; 
VSC_TO_VKNEE = 1;

global diag_info


warning off; % For unnecessary warnings (often when taking log of zero, these values are not used anyways)
Q    = [0 0 0 0];   % Quality vector


% Initialize DP to ensure a return value:
DP = [];

DP.Iph0     = NaN;
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


try
    
  
    
    
    % Sort the data
    [V,I] = LP_Sort_Sweep(V',I');
    
    %dv = S.step_height*IN.VpTM_DAC; % Step height in volt.
    dv = V(2)-V(1);
    
    
    % I've given up on analysing unfiltered data, it's just too nosiy.
    %Let's do a classic LP moving average, that doesn't move the knee
    
    I = LP_MA(I);
    
    
    
    
    % Now the actual fitting starts
    %---------------------------------------------------
    
    % First determine the spacecraft potential
    %Vsc = LP_Find_SCpot(V,I,dv);  % The spacecraft potential is denoted Vsc
    [Vknee, Vsigma] = an_Vplasma(V,I);
    
    
        
    
    if isnan(Vknee)
        Vknee = assmpt.Vknee;        
    end
       
    %test these partial shadow conditions
    if illuminated > 0 && illuminated < 1
        Q(1)=1;
        test= find(abs(V +Vknee)<1.5,1,'first');
        if I_50(test) > 0 %if current is positive, then it's not sunlit
            illuminated = 0;
        else %current is negative, so we see photoelectron knee.
            illuminated = 1;
        end
    end
    
    
    if(illuminated)
        Vsc= Vknee/VSC_TO_VKNEE;
        Vplasma=Vsc*VSC_TO_VPLASMA;
        
        %VSC_TO_VPLASMA=0.64; %from SPIS simulation experiments
%VBSC_TO_VSC = -1/(1-VSC_TO_VPLASMA); %-1/0.36
        
    else
        
        Vsc=Vknee; %no photoelectrons, so current only function of Vp (absolute)
        Vplasma=NaN;
        
    end
    
    Itemp = I;
    
    
    
    % Next we determine the ion current, Vsc need to be included in order
    % to determine the probe potential. However Vsc do not need to be that
    % accurate here.In addition to the ion current, the coefficients from
    % the linear fit  are also returned
    % [Ii,ia,ib] = LP_Ion_curr(V,LP_MA(I),Vsc);
    [Ii,ia,ib,Q] = LP_Ion_curr(V,Itemp,Vsc,Q); % The ion current is denoted Ii,
    % the coefficients a and b
    
    
    %ib is a good guess for Iph0;
    
    
    % Now, removing the linearly fitted ion-current from the
    % current will leave the collected plasma electron current & photoelectron current
    Itemp = Itemp - Ii; %
    
    if (an_debug>1)
        subplot(2,2,1),plot(V,I,'b',V,Itemp,'g');grid on;
        title('I & I - ion current');
    end
    
    
    
    
    
    
    if illuminated
        Iph = gen_ph_current(V,-Vplasma,assmpt.Iph0,assmpt.Tph,1);
        
        Itemp = Itemp - Iph;
        
        [Vsc, Vsigma2] = an_Vplasma(V,Itemp);
        
        
        if (an_debug>1)
            subplot(2,2,4),plot(V,I,'b',V,Itemp,'g');grid on;
            title('I & I - Iph current');
        end
    
                Tph = assmpt.Tph;
        Iftmp = assmpt.Iph0;
        
        %get V intersection:
        
        %diph = abs(  ion current(tempV)  - photelectron log current(Vdagger) )
        diph = abs(ia(1)*V + ib(1) -Iftmp*exp(-(V+Vsc-Vplasma)/Tph));
        %find minimum
        idx1 = find(diph==min(diph),1);
        
        % add 1E5 accuracy on min, and try it again
        tempV = V(idx1)-1:1E-5:(V(idx1)+1);
        diph = abs(ia(1)*tempV + ib(1) -Iftmp*exp(-(tempV+Vsc-Vplasma)/Tph));
        eps = abs(Iftmp)/1000;  %good order estimate of minimum accuracy
        idx = find(diph==min(diph) & diph < eps,1);
        
        
        
        if(isempty(idx))
            DP.Vintersect = NaN;
            Q(4) = 1;
            DP.Iph0 = NaN;
        else
            DP.Vintersect = tempV(idx);
            DP.Iph0 = Iftmp * exp(-(tempV(idx)+Vsc-Vplasma)/Tph);
        end
        
        
    end

    
    
        
    %Determine the electron current (above Vsc and positive), use a moving average
    [Te,ne,Ie,ea,eb]=LP_Electron_curr(V,Itemp,Vsc,illuminated);
    
    
    %if the plasma electron current fail, try the spacecraft photoelectron
    %cloud current analyser
    if isnan(Te)
        

        cloudflag = 1;
        
        [Ts,ns,Ie,sa,sb]=LP_S_curr(V,Itemp,Vplasma,illuminated);
        
        DP.Ts      = Ts;
        DP.ns      = ns;
        DP.sa      = sa(1);
        DP.sb      = sb(1);
        
        %note that Ie is now current from photo electron cloud
        
    end
    
    
    %[Te,ne,Ie,ea,eb,rms]=LP_Electron_curr(V,LP_MA(Itemp),Vsc);
    
    Itemp = Itemp - Ie; %the resultant current should only be photoelectron current (or zero)
    
    
    
    if (an_debug>1)
        
        subplot(2,2,1),plot(V,I,'b',V,Itemp,'g');grid on;
        title('I & I - ions - electrons');
    end
    
    
    % Redetermine s/c potential, without ions and plasma electron /photoelectron cloud currents
    %[vPlasma, Vsigma, Vsc] = an_Vplasma(V,Itemp,vPlasma,Vsigma);
    %if unsuccesful, Vplasma returns our guess
    
    
    if(illuminated)

        Iph = Itemp;
        
        

        %     Iph0 = Iftmp * exp(vs/Tph);
        
        
        Vdagger = V + Vsc - Vplasma;
        
        phind = find(Vdagger < 6 & Vdagger>0);
        
        [phpol,S]=polyfit(Vdagger(phind),log(abs(Iph(phind))),1);
        S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df);
        
        Tph = -1/phpol(1);
        Iftmp = -exp(phpol(2));
        
        %get V intersection:
        
        %diph = abs(  ion current(tempV)  - photelectron log current(Vdagger) )
        diph = abs(ia(1)*V + ib(1) -Iftmp*exp(-(V+Vsc-Vplasma)/Tph));
        %find minimum
        idx1 = find(diph==min(diph),1);
        
        % add 1E5 accuracy on min, and try it again
        tempV = V(idx1)-1:1E-5:(V(idx1)+1);
        diph = abs(ia(1)*tempV + ib(1) -Iftmp*exp(-(tempV+Vsc-Vplasma)/Tph));
        eps = abs(Iftmp)/1000;  %good order estimate of minimum accuracy
        idx = find(diph==min(diph) & diph < eps,1);
        
        
        if(isempty(idx))
            DP.Vintersect = NaN;
            Q(4) = 1;
            DP.Iph0 = NaN;
        else
            DP.Vintersect = tempV(idx);
            DP.Iph0 = Iftmp * exp(-(tempV(idx)+Vsc-Vplasma)/Tph);
        end
        
        DP.Tph     = Tph;
        
        
        Iph(:) = 0;  %set everything to zero
        
        %idx is the at point where Iion and Iph converges
        Iph(idx1:end)=Iftmp*exp(-(V(idx1:end)+Vsc-Vplasma)/Tph);
        %Iph0 and Ii is both an approximation of that part of the sweep, so we
        %remove that region of the Iph current (and maybe add it later)
        
    end
    
    %DP.Iph0     = NaN;
    %DP.Tph     = NaN;%defined elsewhere...
    
    DP.Te      = Te;
    DP.ne      = ne;
    DP.Vsc     = Vsc;
    DP.Vplasma = Vplasma;
    DP.Vsigma  = Vsigma;
    DP.ia      = ia(1);
    DP.ib      = ib(1);
    DP.ea      = ea(1);
    DP.eb      = eb(1);
    DP.Quality = sum(Q);
    
    if (an_debug>1)
        
        if(illuminated)
            subplot(2,2,4)
            %
            %          Iph=Itemp;    %just to get the dimension right)
            %          len=length(Itemp);
            %
            %          pos=find(V>-DP.Vintersect,1,'first');
            %          Iph(1:pos)=DP.Iph0;
            %
            %          for i=pos:1:len
            %              Iph(i)=(DP.Iph0*(1+((V(i)+Vsc-DP.Vintersect)/Tph))*exp(-(V(i)+Vsc-DP.Vintersect)/Tph));
            %          end
            
            Iph(1:idx1)=ib(1); %add photosaturation current
            %            Itot(idx:end)=Iph(idx:end)
            Itot=Iph+Ie+Ii;
            
            %            Itot= Ie+Ii+Iph;
            
            Izero = I-Itot;
            
            
            %         Izero=Itemp-Iph;
            %         Itot = Ii+Ie+Iph;
            
            %      Izero(pos:end)=Itemp(pos:end)-(Iph0*(1+((V(pos:end)-vs)/Tph))*exp(-(V(pos:end)-vs)/Tph));
            %
            %      a=exp((V(pos:len)-vs)/Tph);
            %      adsasd=(Iph0(1+((V(pos:len)-vs)/Tph))*a);
            %      Izero(pos:len)=Itemp(pos:len)-adsasd;
            
            
            
        else
            
            Izero = Itemp;
            Itot = Ie+Ii;
            
        end
        subplot(2,2,2)
        plot(V,Izero,'og');
        grid on;
        %  title('V vs I - ions - electrons-photoelectrons');
        title([sprintf('V vs I - ions -elec -ph macro: %s',diag_info{1})])
        axis([-30 30 -5E-9 5E-9])
        axis 'auto x'
        subplot(2,2,4)
        plot(V+Vsc,I,'b',V+Vsc,Itot,'g');
        %        title('Vp vs I & Itot ions ');
        title([sprintf('Vp vs I & Itot ions macro: %s',diag_info{1})])
        
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
    
catch err
    
    
    fprintf(1,'\nlapdog:Analysis Error for %s, \nVguess= %f , illum=%2.1f\n error message:%s\n',diag_info{2},assmpt.Vknee,illuminated,err.message);
    
    
    
    len = length(err.stack);
    if (~isempty(len))
        for i=1:len
            fprintf(1,'%s, %i,',err.stack(i).name,err.stack(i).line);
        end
    end
    
    fprintf(1,'V & I = \n');
    fprintf(1,'%e,',V);
    fprintf(1,'\n');
    fprintf(1,'%e,',I);
    
    DP.Quality = sum(Q)+200;

    fprintf(1,'\nlapdog: continuing analysis...');
    return
    
    
end



end

