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
%   1. The sweep is sorted upwards and smoothed
%
%   2. find the spacecraft potential (Vsc) and Vph_knee by calling an_Vsc and
%   an_Vplasma. if sunlit: Vph_knee = Vplasma is the plasma at the probe 
% potential from finding the knee of the photoelectron current
%
%   3. evaluate if the sweep is truly sunlit or not, in the case of
%   ambiguous illumination input. 
%
%   4. Fitting an ion current to the part of the sweep below the knee (and
%   below Vsc). And then subtracting the current contribution from the ions
%   from the sweep.
%   
%   5. Fitting an electron current by a linear fit (LP_electron_curr.m) 
%   above Vsc or an exponential fit (LP_expfit_Te.m) below Vknee. removing
%   the linear fit electron current contribution from the sweep.
%   
%   6. Fitting a photoelectron current (if sunlit) to the remainding
%   current.
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DP = an_LP_Sweep(V, I,Vguess,illuminated)

%global IN;         % Instrument information
%global LP_IS;      % Instrument constants
global CO          % Physical & Instrument constants
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

DP.Iph0             = NaN;
DP.Tph              = NaN;
DP.Vsi              = NaN;
DP.Te               = nan(1,2);
DP.ne               = nan(1,2);

DP.Vsg              = nan(1,2);
DP.Vph_knee         = nan(1,2);

DP.ion_Vb_slope     = nan(1,2);
DP.ion_Vb_intersect = nan(1,2);
DP.ion_slope        = nan(1,2);
DP.ion_intersect    = nan(1,2);

DP.e_Vb_slope       = nan(1,2);
DP.e_Vb_intersect   = nan(1,2);
DP.e_slope          = nan(1,2);
DP.e_intersect      = nan(1,2);
    
DP.Tphc             = NaN;
DP.nphc             = NaN;
DP.phc_slope        = nan(1,2);
DP.phc_intersect    = nan(1,2);

DP.Te_exp           = nan(1,2);
DP.Ie0_exp          = nan(1,2);
DP.ne_exp           = nan(1,2);

DP.Quality          = sum(Q);

DP.Rsq              = [];
DP.Rsq.linear       = [];
DP.Rsq.exp          = [];

Iph= 0;


try
    
    % Sort the data
    [V,I] = LP_Sort_Sweep(V',I');
    
    %dv = S.step_height*IN.VpTM_DAC; % Step height in volt.
    dv = V(2)-V(1);
    
    
    % I've given up on analysing unfiltered data, it's just too nosiy.
    %Let's do a classic LP moving average, that doesn't move the knee
    
   % Is = LP_MA(I); %Terrible for knees in end-4:end
    
    Is = smooth(I,'sgolay',1).'; %pretty heavy sgolay filter. NB transpose

    
    
    
    % Now the actual fitting starts
    %---------------------------------------------------
    
    % First determine the spacecraft potential
    %Vsc = LP_Find_SCpot(V,I,dv);  % The spacecraft potential is denoted Vsc
    [Vknee, Vknee_sigma] = an_Vplasma(V,Is);
    [Vsc, Vsc_sigma] = an_Vsc(V,Is);
    

    
    if isnan(Vknee)
        Vknee = Vguess;
        
    end

    
    
    %test these partial shadow conditions
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
        if isnan(Vsc)
            Vsc= Vknee/VSC_TO_VKNEE;
            Vsc_sigma =Vknee_sigma/VSC_TO_VKNEE;           
        end       
        Vplasma=(Vknee/VSC_TO_VKNEE)/VSC_TO_VPLASMA;        
     
    else
        %Vsc=Vknee; %no photoelectrons, so current only function of Vp (absolute)
        Vplasma=NaN;
    end
    


    
    
    
    
    
    % Next we determine the ion current, Vsc need to be included in order
    % to determine the probe potential..In addition to the ion current,
    % the coefficients from
    % the linear fit  are also returned
    % [Ii,ia,ib] = LP_Ion_curr(V,LP_MA(I),Vsc);
    
    [ion] = LP_Ion_curr(V,Is,Vsc,Vknee); % The ion current is denoted ion.I,
    %Q(2) = ion.Q;
    %ion.I here doesn't contain the ion.b offset. as it shouldn't if we
    % want to get Iph0 individually.

                        
if (an_debug>1)    
	subplot(3,2,3),plot(V+Vsc,I,'b',V+Vsc,ion.I,'g');grid on;
    title([sprintf('Ion current vs Vp, out.Q(1)=%d',ion.Q(1))])
    legend('I','I_i_o_n')

end


if illuminated
% find region 1 V below knee and 4V above knee
%track positions to be filtered which is in this this region
    
    filter_ind = find(ge(V+Vplasma+1,0) &le(V+Vplasma-4,0));
    
else
    filter_ind = [];
end

    
    %this is all we need to get a good estimate of Te from an
    %exponential fit


    
    expfit= LP_expfit_Te(V,Is-ion.I,Vsc,filter_ind);
    DP.Te_exp           = expfit.Te; %contains both value and sigma frac.
    DP.Ie0_exp          = expfit.Ie0;
    DP.ne_exp           = expfit.ne;

    
    
        
    %%% Now, removing the linearly fitted ion-current from the
    % current will leave the collected plasma electron current & photoelectron current
   
    
    if(illuminated)
        % if we want to determine Iph0 seperately, we need to remove the
        % ion.b component of the ion current before we accidentally remove
        % it everywhere. ion.b is otherwise a good guess for Iph0;
        ion.I = ion.I-ion.b(1);         
    end
    
    Itemp = Is - ion.I; %
    
    %%%
   
    if (an_debug>1)
                figure(33);

        subplot(3,2,6),plot(V,Is,'b',V,Itemp,'g');grid on;

       title([sprintf('Vb vs I %s %s',diag_info{1},strrep(diag_info{1,2}(end-26:end-12),'_',''))])

        legend('I','I-Iion','Location','Northwest')
    end
            


    %Determine the electron current (above Vsc and positive), use a moving average
%    [Te,ne,Ie,ea,eb]=LP_Electron_curr(V,Itemp,Vsc,illuminated);
    [elec]=LP_Electron_curr(V,Itemp,Vsc,Vknee,illuminated);

    
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
    
%    Itemp = Itemp - elec.I; %the resultant current should only be photoelectron current (or ion.b(1));
      %[Te,ne,Ie,ea,eb,rms]=LP_Electron_curr(V,LP_MA(Itemp),Vsc);
    Itemp2 = Itemp -expfit.I;
    Itemp = Itemp - elec.I; %the resultant current should only be photoelectron current (or zero)
    
    
%     
    if (an_debug>1)
                        figure(33);

       % title('I & I - ion current -ph');
       
       %      title([sprintf('I & I - ion&ph. illumination=%d',illuminated)])
       

        subplot(3,2,1),plot(V,Is,'b',V,Itemp,'g',V,Itemp2,'r');grid on;
        
        title([sprintf('I, I-Ii-Ie liner, I-Ii-Ie exp %s %s',diag_info{1},strrep(diag_info{1,2}(end-26:end-12),'_',''))])      
        legend('I','I-I linear','I-I exp','Location','NorthWest')
        title('I & I - ions - e - ph');
    end
    
    
%     if (an_debug>1)
%                 figure(33);
% 
%         subplot(3,2,1),plot(V,Is,'b',V,Itemp,'g');grid on;
%         title('Vb vs I');
%         
%         title([sprintf('Vb vs I, macro:%s date:%s',diag_info{1},diag_info{1,2}(end-26:end-12))])
%         
%         legend('I','I-(ions+electrons)','Location','Northwest')
% 
%     end
%     
    
    % Redetermine s/c potential, without ions and plasma electron /photoelectron cloud currents
    %[vPlasma, Vsg_sigma, Vsc] = an_Vplasma(V,Itemp,vPlasma,Vsg_sigma);
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
        %     phind = find(V < (vPlasma-Vsc) + 6 & V>=(vPlasma-Vsc));
        %     [phpol,S] = polyfit(V(phind),log(abs(Iph(phind))),1);
        %     S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df);
        %
        %     Tph = -1/phpol(1);
        %     Iftmp = -exp(phpol(2));
        %
        %     % Find Vsc as intersection of ion and photoemission current:
        %     % Iterative solution:
        %     vs = vPlasma-Vsc;
        %     for(i=1:10)
        %         vs = -(log(-polyval([ia(1),ion.b(1)],-vs)) - phpol(2))/phpol(1);
        %     end
        %     % Calculate Iph0:
        %     Iph0 = Iftmp * exp(vs/Tph);
        
        Vdagger = V + Vknee;
        
        %Vdagger = V + Vsc - Vplasma;
        
        
        phind = find(Vdagger < 6 & Vdagger>0);

        
        
        phind = find(Vdagger < 6 & Vdagger>0);
        
        [phpol,S]=polyfit(Vdagger(phind),log(abs(Iph(phind))),1);
        S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df);
        
        Tph = -1/phpol(1);
        Iftmp = -exp(phpol(2));
        
        %get V intersection:
        
        %diph = abs(  ion current(tempV)  - photelectron log current(Vdagger) )
        diph = abs(ion.a(1)*V + ion.b(1) -Iftmp*exp(-(Vdagger)/Tph));
        %find minimum
        idx1 = find(diph==min(diph),1);
        
        
        
        
        %     V(idx)
        %     V(idx+1)
        %     V(idx-1)
        %     y3(idx)
        %     y3(idx+1)
        %     y3(idx-1)
        % add 1E5 accuracy on min, and try it again
        tempV = V(idx1)-1:1E-5:(V(idx1)+1);
        diph = abs(ion.a(1)*tempV + ion.b(1) -Iftmp*exp(-(tempV+Vknee)/Tph));
        eps = abs(Iftmp)/1000;  %good order estimate of minimum accuracy
        idx = find(diph==min(diph) & diph < eps,1);
        
        
        if(isempty(idx))
            DP.Vsi = NaN;
            Q(4) = 1;
            DP.Iph0 = NaN;
        else
            DP.Vsi = tempV(idx);
            DP.Iph0 = Iftmp * exp(-(tempV(idx)+Vknee)/Tph);
            
            ion.b(1) = ion.b(1)-DP.Iph0;  % now that we know Iph0, we can calculate the actual y-intersect of the ion current.
            ion.Vpb(1) = ion.Vpb(1)-DP.Iph0;
        end
        
        DP.Tph     = Tph;
        
        
        Iph(:) = 0;  %set everything to zero
        
        %idx is the at point where Iion and Iph converges
        %Iph(idx1:end)=Iftmp*exp(-(V(idx1:end)+Vsc-Vplasma)/Tph);
        Iph(idx1:end)=Iftmp*exp(-Vdagger(idx1:end)/Tph);

        %Iph0 and ion.I is both an approximation of that part of the sweep, so we
        %remove that region of the Iph current (and maybe add it later)
        
    end
    
    
        
    %---------------------------------------------------------- 
    % Rsquare value calculation of fit
    
    Itot_linear=Iph+elec.I+ion.I;
    Itot_exp=Itot_linear-elec.I+expfit.I;
    Izero_linear = Is-Itot_linear;
    Izero_exp = Is - Itot_exp;
    
    Rsq_linear = 1 - sum((Izero_linear.^2))/sum(((Is-mean(Is)).^2));
    Rsq_exp = 1 -  sum(Izero_exp.^2)/sum((Is-mean(Is)).^2);
    

    
    
    
    %DP.Iph0     = NaN;
    %DP.Tph     = NaN;%defined elsewhere...
    
    DP.Te      = elec.Te;
    DP.ne      = elec.ne;
    DP.Vsg     = [Vsc Vsc_sigma];
    DP.Vph_knee = [Vplasma Vknee_sigma];

    
    DP.ion_Vb_slope      = ion.a;
    DP.ion_Vb_intersect  = ion.b;
    DP.ion_slope      = ion.Vpa;
    DP.ion_intersect  = ion.Vpb;
    
    DP.e_Vb_slope        = elec.a;  
    DP.e_Vb_intersect    = elec.b;
    DP.e_slope        = elec.Vpa;
    DP.e_intersect    = elec.Vpb;
    DP.Quality = sum(Q); 
    
    DP.Rsq.linear       = Rsq_linear;
    DP.Rsq.exp          = Rsq_exp;
    
    
    if (an_debug>1)
        figure(33);

        if(illuminated)

            
            Iph(1:idx1)=ion.b(1)+DP.Iph0; %add photosaturation current
            %            Itot(idx:end)=Iph(idx:end)
            
        end
    

        
        subplot(3,2,2)
        plot(V+Vsc,Izero_linear,'og',V+Vsc,Izero_exp,'or');
        grid on;
        %  title('V vs I - ions - electrons-photoelectrons');
        title([sprintf('Vp vs I-Itot, fully auto,lum=%d, %s',illuminated,diag_info{1})])
        legend('residual(I-Itot linear)','residual(I-Itot exp)','Location','Northwest')
        
        
        axis([-30 30 -5E-9 5E-9])
        axis 'auto x'
        subplot(3,2,4)
        plot(V+Vsc,Is,'b',V+Vsc,Itot_linear,'g',V+Vsc,Itot_exp,'r');
        
        %        title('Vp vs I & Itot ions ');
        title([sprintf('Vp vs I, macro: %s',diag_info{1})])
        legend('I','Itot linear','Itot exp','Location','NorthWest')
        
        grid on;
        
            
        subplot(3,2,5)
        plot(V+Vsc,I,'b',V+Vsc,(ion.I+elec.I)+ion.mean(1),'g',V+Vsc,ion.I+expfit.I+ion.mean(1),'r',V+Vsc,Iph,'black')
        axis([min(V)+Vsc max(V)+Vsc min(I) max(I)])
        title([sprintf('Vp vs I-Itot, fully auto,lum=%d, %s',illuminated,diag_info{1})])
        legend('I','ions+electrons(linear)','Ions+electrons(exp)','photoelectrons','Location','Northwest')
        
        
        grid on;

        %
        %
        %     x = V(1):0.2:V(end);
        %     y = gaussmf(x,[sigma Vsc]);
        % 	subplot(3,2,1),plot(V,Ie,'g',x,y*abs(max(I))/4,'b');grid on;
        % 	title('V & I and Vsc Guess');
        %
        %     Vsc2 = LP_Find_SCpot(V,Ie,dv);
        %     x = V(1):0.2:V(end);
        %     y = gaussmf(x,[1, Vsc2]);
        % 	subplot(3,2,2),plot(V,Ie,'g',x,y*max(I),'b');grid on;
        % 	title('V & I and Vsc Guess number 2');
    end
    
    % Having removed the ion current, we use the electron current to determine
    % the electron temperature and density
    % [Te1,Te2,n1,n2,Ie1,Ie2,f,e,Vsc,Q] = LP_Electron_curr(V,Ie_s,Vsc,dv,Q);
    
catch err
    
    
    fprintf(1,'\nlapdog:Analysis Error for %s, \nVguess= %f , illum=%2.1f\n error message:%s\n',diag_info{2},Vguess,illuminated,err.message);
    
    
    
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


