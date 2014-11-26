%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Name: an_LP_Sweep_with_assmpt.m
% Author: Fredrik Johansson, developed from original script by Claes Weyde
%
% Description:
%
%  	This is the main function body. It is the function an_LP_Sweep_with_assmpt
% from which all other functions are called.
%   
%   differences from an_LP_Sweep:
%   instead of isolating and removing the ion current slope from the
%   current first, we instead remove an assumed photoelectron contribution
%   (if sunlit)
%   
%
%
%   
%
%
% Input:
%     V             bias potential
%     I             sweep current
%     assmpt        structure with various assumptions on Tph Iph0, etc
%     illuminated   if the probe is sunlit or not (from SPICE Kernel
%     evaluation)
%   
% Output:
%	  DP	 Physical parameter information structure
%
% Notes:
%	1. The quality vector consists of four elements: the first is a measure of the overflow while
%	   the second, third and fourth are quality estimates for Vsc, Te and ne respectively.
%	   The first one is between 0 and 1, the other three are rounded values between 0 and 10.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DP = an_LP_Sweep_with_assmpt(V, I,assmpt,illuminated)




%global IN;         % Instrument information
%global LP_IS;      % Instrument constants
global CO          % Physical constants
%global ALG;        % Various algorithm constants

global an_debug VSC_TO_VPLASMA VSC_TO_VKNEE;
%VSC_TO_VPLASMA=0.64; %from SPIS simulation experiments
%VSC_TO_VKNEE = 0.36;
VSC_TO_VPLASMA=1; 
VSC_TO_VKNEE = 1;

global diag_info %contains information of current sweep 

   
    if (an_debug>1)
        figure(34);        
    end

warning off; % For unnecessary warnings (often when taking log of zero, these values are not used anyways)
Q    = [0 0 0 0];   % Quality vector

na = [NaN NaN]; % dummy nan

% Initialize DP to ensure a return value:
DP = [];


DP.Iph0             = assmpt.Iph0;
DP.Tph              = assmpt.Tph;
DP.Vsi              = NaN;
DP.Te               = NaN;
DP.ne               = NaN;

DP.Vsg              = na;
DP.Vph_knee         = NaN;

DP.ion_Vb_slope     = na;
DP.ion_Vb_intersect = na;
DP.ion_slope        = na;
DP.ion_intersect    = na;

DP.e_Vb_slope       = na;
DP.e_Vb_intersect   = na;
DP.e_slope          = na;
DP.e_intersect      = na;

DP.Tphc             = NaN;
DP.nphc             = NaN;
DP.phc_slope        = na;
DP.phc_intersect    = na;

DP.Te_exp           = na;
DP.Ie0_exp          = na;

DP.Quality          = sum(Q);


try
    
  
    
    
    % Sort the data
    [V,I] = LP_Sort_Sweep(V',I');
    
    %dv = S.step_height*IN.VpTM_DAC; % Step height in volt.
    dv = V(2)-V(1);
    
    
    % I've given up on analysing unfiltered data, it's just too nosiy.
    %Let's do a classic LP moving average, that doesn't move the knee
    
   % Is = LP_MA(I); %Terrible for knees near end-4:end
    
    Is = smooth(I,'sgolay',1).'; %pretty heavy sgolay filter. NB transpose

    
    
    % Now the actual fitting starts
    %---------------------------------------------------
    
    % First determine the spacecraft potential
    %Vsc = LP_Find_SCpot(V,I,dv);  % The spacecraft potential is denoted Vsc
    [Vknee, Vsigma] = an_Vplasma(V,Is);
    
    
    if isnan(Vknee)
        Vknee = assmpt.Vknee;  %from first 50 sweeps       
    end
       
    %test partial shadow conditions
    if illuminated > 0 && illuminated < 1
        Q(1)=1;
        test= find(abs(V +Vknee)<1.5,1,'first');
        if Is(test) > 0 %if current is positive, then it's not sunlit
            illuminated = 0;
        else %current is negative, so we see photoelectron knee.
            illuminated = 1;
        end
    end
    
    
    if(illuminated)
        Vsc= Vknee/VSC_TO_VKNEE;
        Vplasma=Vsc*VSC_TO_VPLASMA;                
    else        
        Vsc=Vknee; %no photoelectrons, so current only function of Vp (absolute)
        Vplasma=NaN;         
    end
    

    Itemp = Is;
    

    
    if illuminated
        Iph = gen_ph_current(V,-Vplasma,assmpt.Iph0,assmpt.Tph,2); %model two works better for massive electron bullshit.
        
        Itemp = Itemp - Iph;
        
        [Vsc, Vsigma2] = an_Vplasma(V,Itemp);
        
        
        if (an_debug>1)
            figure(34);
            subplot(2,2,4),plot(V,I,'b',V,Itemp,'g');grid on;

            title('I & I - Iph current');
            legend('I','I-Iph','Location','Northwest')
        end
        
    end
    
    
    
    
    
    
    % Next we determine the ion current, Vsc need to be included in order
    % to determine the probe potential. However Vsc do not need to be that
    % accurate here.In addition to the ion current, the coefficients from
    % the linear fit  are also returned
    % [Ii,ia,ib] = LP_Ion_curr(V,LP_MA(I),Vsc);
    [ion,Q] = LP_Ion_curr(V,Itemp,Vsc,Q); % The ion current is denoted Ii,



    % Now, removing the linearly fitted ion-current from the
    % current will leave the collected plasma electron current 

    Itemp = Itemp - ion.I; 
    
    
    if (an_debug>1)
                figure(34);

        subplot(2,2,1),plot(V,Is,'b',V,Itemp,'g');grid on;
       % title('I & I - ion current -ph');
       
       %      title([sprintf('I & I - ion&ph. illumination=%d',illuminated)])
       
       title([sprintf('Vb vs I %s %s',diag_info{1},strrep(diag_info{1,2}(end-26:end-12),'_',''))])
       
       legend('I','I-(ph+ion)','Location','NorthWest')
    end
    

    
    
        
    %Determine the electron current (above Vsc and positive), use a moving average
    %[Te,ne,Ie,ea,eb]=LP_Electron_curr(V,Itemp,Vsc,illuminated);
    %this time, we have already removed Iph component, so we can assume no
    %sunlight effect
    [elec]=LP_Electron_curr(V,Itemp,Vsc,0);
    
    temp= LP_expfit_Te(V,Itemp,Vsc);
    
    DP.Te_exp = temp.Te;
    DP.Ie0_exp = temp.Ie0;
    
    %if the plasma electron current fail, try the spacecraft photoelectron
    %cloud current analyser
    if isnan(elec.Te)
        

        cloudflag = 1;
        
        [Ts,ns,elec.I,sa,sb]=LP_S_curr(V,Itemp,Vplasma,illuminated);
        
        DP.Tphc             = Ts;
        DP.nphc             = ns;
        DP.phc_slope        = sa;
        DP.phc_intersect    = sb;
        
        %note that Ie is now current from photo electron cloud
        
    end
    
    
    %[Te,ne,Ie,ea,eb,rms]=LP_Electron_curr(V,LP_MA(Itemp),Vsc);
    
    Itemp = Itemp - elec.I; %the resultant current should only be photoelectron current (or zero)
    
    
%     
%     if (an_debug>1)
%         
%         subplot(2,2,1),plot(V,I,'b',V,Itemp,'g');grid on;
%         title('I & I - ions - e - ph');
%     end
%     
    
           
    if illuminated
    
        Tph = assmpt.Tph;
        Iftmp = assmpt.Iph0;
        
        
        
        
        %get V intersection:
        
        %diph = abs(  ion current(tempV)  - photelectron log current(Vdagger) )
        diph = abs(ion.a(1)*V + ion.b(1) -Iftmp*exp(-(V+Vsc-Vplasma)/Tph));
        %find minimum
        idx1 = find(diph==min(diph),1);
        
        % add 1E5 accuracy on min, and try it again for ?1 V.
        tempV = V(idx1)-1:1E-5:(V(idx1)+1);
        diph = abs(ion.a(1)*tempV + ion.b(1) -Iftmp*exp(-(tempV+Vsc-Vplasma)/Tph));
        eps = abs(Iftmp)/1000;  %good order estimate of minimum accuracy
        idx = find(diph==min(diph) & diph < eps,1);
        
        
        
        if(isempty(idx))
            DP.Vsi = NaN;
            Q(4) = 1;
        else
            DP.Vsi = tempV(idx);
        end
        
        
    end
    
    DP.Te      = elec.Te;
    DP.ne      = elec.ne;
    DP.Vsg     = [Vsc Vsigma];
    DP.Vph_knee = Vplasma;

    DP.ion_Vb_slope      = ion.a;
    DP.ion_Vb_intersect  = ion.b;
    DP.ion_slope      = ion.Vpa;
    DP.ion_intersect  = ion.Vpb;

    DP.e_Vb_slope        = elec.a;
    DP.e_Vb_intersect    = elec.b;
    DP.e_slope        = elec.Vpa;
    DP.e_intersect    = elec.Vpb;
    DP.Quality = sum(Q);
    
    
    if (an_debug>1)
        figure(34);

        if(illuminated)
            %
            %          Iph=Itemp;    %just to get the dimension right)
            %          len=length(Itemp);
            %
            %          pos=find(V>-DP.Vsi,1,'first');
            %          Iph(1:pos)=DP.Iph0;
            %
            %          for i=pos:1:len
            %              Iph(i)=(DP.Iph0*(1+((V(i)+Vsc-DP.Vsi)/Tph))*exp(-(V(i)+Vsc-DP.Vsi)/Tph));
            %          end
            %Iph(1:idx1)=Iph(1:idx1)+ion.b(1)
       %     Iph(1:idx1)=ion.b(1); %add photosaturation current
            %            Itot(idx:end)=Iph(idx:end)
            Itot=Iph+elec.I+ion.I;
            
            %            Itot= Ie+ion.I+Iph;
            
            Izero = Is-Itot;
            
            
            %         Izero=Itemp-Iph;
            %         Itot = ion.I+Ie+Iph;
            
            %      Izero(pos:end)=Itemp(pos:end)-(Iph0*(1+((V(pos:end)-vs)/Tph))*exp(-(V(pos:end)-vs)/Tph));
            %
            %      a=exp((V(pos:len)-vs)/Tph);
            %      adsasd=(Iph0(1+((V(pos:len)-vs)/Tph))*a);
            %      Izero(pos:len)=Itemp(pos:len)-adsasd;
            
            
            
        else
            
            Izero = Itemp;
            Itot = elec.I+ion.I;
            
        end
        subplot(2,2,2)
        plot(V+Vsc,Izero,'og');
        grid on;
        %  title('V vs I - ions - electrons-photoelectrons');
        title([sprintf('WITH ASSUMPTIONS lum=%d, %s',illuminated,diag_info{1})])
        legend('IvsVp','I-Itot','Location','NorthWest')

        axis([-30 30 -5E-9 5E-9])
        axis 'auto x'
        subplot(2,2,4)
        plot(V+Vsc,Is,'b',V+Vsc,Itot,'g');
        %        title('Vp vs I & Itot ions ');
        title([sprintf('Vp vs I, macro: %s',diag_info{1})])
        legend('I','Itot','Location','NorthWest')

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
    fprintf(1,'%e,',Is);
    
    DP.Quality = sum(Q)+200;

    fprintf(1,'\nlapdog: continuing analysis...');
    return
    
    
end



end

