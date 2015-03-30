
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
%   1. The sweep is sorted upwards and smoothed
%
%   2. find the spacecraft potential (Vsc) and Vph_knee by calling an_Vsc and
%   an_Vplasma. if sunlit: Vph_knee = Vplasma is the plasma at the probe 
% potential from finding the knee of the photoelectron current
%
%   3. evaluate if the sweep is truly sunlit or not, in the case of
%   ambiguous illumination input. 
%   
%   4. Generate photoelectron current (if sunlit) from assumed parameters 
%   and remove from sweep
%
%   5. Fitting an ion current to the part of the sweep below the knee (and
%   below Vsc). And then subtracting the current contribution from the ions
%   from the sweep.
%   
%   6. Fitting an electron current by a linear fit (LP_electron_curr.m) 
%   above Vsc or an exponential fit (LP_expfit_Te.m) below Vknee. removing
%   the linear fit electron current contribution from the sweep.
%   %
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

global diag_info %contains information of current sweep 


warning off; % For unnecessary warnings (often when taking log of zero, these values are not used anyways)
Q    = [0 0 0 0];   % Quality vector

% Initialize DP to ensure a return value:
DP = [];

DP.Iph0             = assmpt.Iph0;
DP.Tph              = assmpt.Tph;
DP.Vsi              = NaN;
DP.Te               = nan(1,2);
DP.ne               = nan(1,2);

DP.Vsg              = nan(1,2);
DP.Vph_knee         = nan(1,2);
DP.Vbar             = nan(1,2);

DP.ion_Vb_slope     = nan(1,2);
DP.ion_Vb_intersect = nan(1,2);
DP.ion_slope        = nan(1,2);
DP.ion_intersect    = nan(1,2);
DP.ion_Up_slope     = nan(1,2);
DP.ion_Up_intersect = nan(1,2);



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
DP.Rsq.linear       = NaN;
DP.Rsq.exp          = NaN;

Iph= 0;


try
    
 
    % Sort the data
    [V,I] = LP_Sort_Sweep(V',I');
    

    %FILTERING
    %---------------------------------------------------
    % I've given up on analysing unfiltered data, it's just too nosiy.
    %Let's do a classic LP moving average, that doesn't move the knee
    
    % Is = LP_MA(I); %Terrible for knees in end-4:end
    
    %dv = S.step_height*IN.VpTM_DAC; % Step height in volt.
    dv = V(2)-V(1);
    
    Is = sweepFilterChooser(I,dv);
    
% 
%     
%     % we have three or four cases:
%     % dv = 0.25 --> e.g. 604, 807 (probably burst mode)
%     % dv = 0.5  --> e.g. 506
%     % dv = 0.75 --> e.g. 505
%     % dv = 1    --> e.g  212 (rare)
%     % dv << 0.25 --> fine sweeps, (not implemented yet)
%     if dv < 0.27 %i.e. if dv ~ 0.25
%         sSpan = 0.1;
%         sMethod = 'rloess';   % loose rloess filter
%     elseif dv > 0.72
%         
%         sSpan = 0.2;     %pretty heavy sgolay filter.
%         sMethod = 'sgolay';
%     else  %i.e. if dv ~ 0.5
%         sSpan = 0.1;       %pretty heavy sgolay filter.
%         sMethod = 'sgolay';
%     end
%     
    
 %   Is = smooth(I,sSpan,sMethod,1).'; %filter sweep NB transpose

     
   % Is = smooth(I,0.2,'sgolay',1).'; %pretty heavy sgolay filter. NB transpose
    

    
    
    % Now the actual fitting starts
    %---------------------------------------------------
    
    % First determine the spacecraft potential
    %Vsc = LP_Find_SCpot(V,I,dv);  % The spacecraft potential is denoted Vsc
%    [Vknee, Vknee_sigma]    = an_Vplasma(V,Is);
%    [Vsc, Vsc_sigma]        = an_Vsc(V,Is);

    twinpeaks = an_Vplasma_v2(V,Is);
    
%    [Vknee Vknee_sigma] =[twinpeaks.Vph_knee];
    Vknee = twinpeaks.Vph_knee(1);
    Vknee_sigma =twinpeaks.Vph_knee(2);
 %   [Vsc, Vsc_sigma] =twinpeaks.Vsc;
    Vsc = twinpeaks.Vsc(1);
    Vsc_sigma =twinpeaks.Vsc(2);

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
        if isnan(Vsc)
            Vsc= Vknee/VSC_TO_VKNEE;
            Vsc_sigma =Vknee_sigma/VSC_TO_VKNEE;           
        end       
        Vplasma=(Vknee/VSC_TO_VKNEE)/VSC_TO_VPLASMA;        
     
    else
        %Vsc=Vknee; %no photoelectrons, so current only function of Vp (absolute)
        Vplasma=NaN;
    end
    
    
    
    
    

    Itemp = Is;
            

    
    if illuminated
        Iph = gen_ph_current(V,-Vplasma,assmpt.Iph0,assmpt.Tph,2); %model two works better for massive electron bullshit.
        
        Itemp = Itemp - Iph;
        
        %[Vsc, Vsigma2] = an_Vsc(V,Itemp);
                
        
        
        if (an_debug>1)
            figure(34);
            
            subplot(3,2,4),plot(V,I,'b',V,Itemp,'g');grid on;
            
            title('I & I - Iph current');
            legend('I','I-Iph','Location','Northwest')
        end
        
    end
    
    
    
    
    

    % Next we determine the ion current, Vsc need to be included in order
    % to determine the probe potential. However Vsc do not need to be that
    % accurate here.In addition to the ion current, the coefficients from
    % the linear fit  are also returned
    % [Ii,ia,ib] = LP_Ion_curr(V,LP_MA(I),Vsc);
    [ion] = LP_Ion_curr(V,Itemp,Vsc,Vknee); % The ion current is denoted Ii,
    Q(2) = ion.Q;
    
    if (an_debug>1)
        figure(34);
        
        subplot(3,2,3),plot(V+Vsc,I,'b',V+Vsc,ion.I,'g');grid on;
        title([sprintf('Ion current vs Vp, out.Q(1)=%d',ion.Q(1))])
        legend('I','I_i_o_n')
        
    end
    
    

    % Now, removing the linearly fitted ion-current from the
    % current will leave the collected plasma electron current 

    Itemp = Itemp - ion.I; 
    
    
    if (an_debug>1)
        
        subplot(3,2,6),plot(V,Is,'b',V,Itemp,'g');grid on;
        % title('I & I - ion current -ph');
        %      title([sprintf('I & I - ion&ph. illumination=%d',illuminated)])
        
        title([sprintf('Vb vs I %s %s',diag_info{1},strrep(diag_info{1,2}(end-26:end-12),'_',''))])
        
        legend('I','I-(ph+ion)','Location','NorthWest')
    end
    

    
    
        
    %Determine the electron current (above Vsc and positive), use a moving average
    %[Te,ne,Ie,ea,eb]=LP_Electron_curr(V,Itemp,Vsc,illuminated);
    %this time, we have already removed Iph component, so we can assume no
    %sunlight effect

    [elec]=LP_Electron_curr(V,Itemp,Vsc,Vknee,0);

    if illuminated
        % find region 1 V below knee and 4V above knee
        %track positions to be filtered which is in this this region
        filter_ind = find(ge(V+Vplasma+1,0) &le(V+Vplasma-4,0));        
    else
        filter_ind = [];
    end
        
        
    
    %obtain exponential fit of plasma electron current.
    expfit= LP_expfit_Te(V,Itemp,Vsc, filter_ind); 
 
   
    DP.Te_exp           = expfit.Te; %contains both value and sigma frac.
    DP.Ie0_exp          = expfit.Ie0;
    DP.ne_exp           = expfit.ne;
    
    %if the plasma electron current fail, try the spacecraft photoelectron
    %cloud current analyser
    if isnan(elec.Te(1))
        
        cloudflag = 1;
        
        [Ts,ns,elec.I,sa,sb]=LP_S_curr(V,Itemp,Vplasma,illuminated);
        
        DP.Tphc             = Ts;
        DP.nphc             = ns;
        DP.phc_slope        = sa;
        DP.phc_intersect    = sb;
        
        %note that Ie is now current from photo electron cloud
        
    end
    

    
%     
    if (an_debug>1)
                        figure(34);

       % title('I & I - ion current -ph');
       
       %      title([sprintf('I & I - ion&ph. illumination=%d',illuminated)])
       

        subplot(3,2,1),plot(V,Is,'b',V,Itemp - elec.I,'g',V,Itemp -expfit.I,'r');grid on;
        
        title([sprintf('I, I-all_linear, I-all_exp %s %s',diag_info{1},strrep(diag_info{1,2}(end-26:end-12),'_',''))])
       
       legend('I','I-I\_linear','I-I\_exp','Location','NorthWest')
    end
%     
    Itemp = Itemp - elec.I; %the resultant current should only be photoelectron current (or zero)
    
    
           
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
    
    %---------------------------------------------------------- 
    % Rsquare value calculation of fit
    
    Itot_linear=Iph+elec.I+ion.I;
    Itot_exp=Itot_linear-elec.I+expfit.I;
%     Izero_linear = Is-Itot_linear;
%     Izero_exp = Is - Itot_exp;
%     
%     Rsq_linear = 1 - sum((Izero_linear.^2))/sum(((Is-mean(Is)).^2));
%     Rsq_exp = 1 -  sum(Izero_exp.^2)/sum((Is-mean(Is)).^2);
%     

    Izero_linear = I-Itot_linear;
    Izero_exp = I - Itot_exp;
    
    Rsq_linear = 1 - nansum((Izero_linear.^2))/nansum(((I-nanmean(I)).^2));
    Rsq_exp = 1 -  nansum(Izero_exp.^2)/nansum((I-nanmean(I)).^2);
    


    
    DP.Te      = elec.Te;
    DP.ne      = elec.ne;
    DP.Vsg     = [Vsc Vsc_sigma];
    DP.Vph_knee = [Vplasma Vknee_sigma];
    DP.Vbar     = twinpeaks.Vbar; 

    DP.ion_Vb_slope     = ion.a;
    DP.ion_Vb_intersect = ion.b;
    DP.ion_slope        = ion.Vpa;
    DP.ion_intersect    = ion.Vpb;
    DP.ion_Up_slope     = ion.Upa;
    DP.ion_Up_intersect = ion.Upb;

    DP.e_Vb_slope        = elec.a;
    DP.e_Vb_intersect    = elec.b;
    DP.e_slope        = elec.Vpa;
    DP.e_intersect    = elec.Vpb;
    DP.Quality = sum(Q);
    
    DP.Rsq.linear       = Rsq_linear;
    DP.Rsq.exp          = Rsq_exp;
    
    
    
    
    
    if (an_debug>1)
        figure(34);

            


        
 
        
        subplot(3,2,2)
        plot(V+Vsc,Izero_linear,'og',V+Vsc,Izero_exp,'or');
        grid on;
        %  title('V vs I - ions - electrons-photoelectrons');
        title([sprintf('WITH ASSUMPTIONS lum=%d, %s',illuminated,diag_info{1})])
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
        plot(V+Vsc,I-Iph,'b',V+Vsc,(ion.I+elec.I)+ion.mean(1),'g',V+Vsc,ion.I+expfit.I+ion.mean(1),'r',V+Vsc,Iph,'black')
        axis([min(V)+Vsc max(V)+Vsc min(I) max(I)])
        title([sprintf('Vp vs I, fully auto,lum=%d, %s',illuminated,diag_info{1})])
        legend('I','ion+e(linear)','Ions+e(exp)','pe','Location','Northwest')

        grid on;
        

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

