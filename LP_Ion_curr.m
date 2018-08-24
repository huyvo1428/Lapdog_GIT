%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Name:  LP_Ion_curr.m
% Author: Fredrik Johansson, original script from Clas Weyde, RG modified not to use hardcoded constants
% Description:
%        Ii = LP_Ion_curr(V,I,Vsc)
%
% 	The ion current is calculated from the low probe potentials. It is important that the photoelectron
%	contribution has been removed before this function is called, otherwise the ion current will in fact be
%	ion current plus a constant contribution from the photo-current.
%
%	1. The length of the data is determined and stored in a variable called "len". This is done using the
%	   MATLAB function "length", but could just as easily be done by for example a counting for-loop.
%	2. The probe potential is calculated as the spacecraft potential added to the bias potential;
%	   Vp = Vb + Vsc.
%	3. The indices for all probe potential values below 0 are stored in the vector called "ind". This is
%	   done using the MATLAB function "find", but could be performed just as easily using a for-structure.
%	4. Now the point closest to, but below, ALG.SM_Below_Vs*100% of the probe potential is stored in the variable called
%	   "top". This way we have, through steps 3 and 4, set the interval [0 - ALG.SM_Below_Vs*100] % of the negative probe
%	   potential. This interval will be used in the fitting below.
%	5. Two new data-vectors (matrices) are set, only keeping probe potential up to the values specified in
%	   the variable "top", i.e. the first ALG.SM_Below_Vs*100% of the negative probe potential. These new vectors are called
%	   Vi and Ii respectively.
%	6. Next we make sure that we do not go closer than ALG.SM_Bias_Limit volt to -Vsc in the bias potential.
%          Translated into probe potentials this means not going higher up than -ALG.SM_Bias_Limit volt. Data values above
%          this are thrown away for both current and potentials. Once again we use the MATLAB function "find", but as mentioned
%	   earlier, one can just as well use for-loops.
%	7. As a final safety check we see so that no current values are above 0, since this would not be
%	   consistent with theory for the ion-saturation region. If any such values are found they are
%	   discarded, the procedure is the same as in step 6 above.
%	8. Finally we have our interval over which we can make a linear fit. A polynomial is determined using
%	   the MATLAB function "polyfit", which given x (potential in our case) and y (current here) values
%	   calculates the polynomial that fits the data best in a least squares sense. This can be performed in
%	   a separate function that does a least squares fit to a linear problem.
%	9. The coefficients are saved in variables, a and b.
%	10.The ion current can now be calculated, assuming only ram ions as this line but extended over the
%	   entire data interval, until the current reaches zero after which it remains zero (since a positive
%	   ion current would not be physical). The MATLAB function polyval is used to calculate the ion current
%	   over the interval, though just setting the current as Ii = b+aVi would work just as well. The ion
%	   current is finally set as Ii = (Ii-abs(Ii))/2, so that it will be zero for positive current values.
%	11.The ion current and the coefficients a and b are returned to the calling function.
%
% Input:
%            Bias potential, V,         [V]
%            Current, I,                [A]
%            Spacecraft potential, Vsc, [V]
%
% Output:
%            Ion current, Ii,           [A]
%            Slope of linear fit, a,    [A/V]
%            Value of y-axis cross, b,  [A]
%
% Notes:
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [out] = LP_Ion_curr(V, I, Vsc, Vknee, SM_Below_Vs)
global CO IN     % Physical & instrumental constants
global assmpt;   % Global assumptions

Ii = I;
Ii(1:end) = 0;
out = [];

a = nan(1,2);
b = nan(1,2);

out.I = Ii;
out.a = nan(1,2);
out.b = nan(1,2);
out.Vpa = nan(1,2);
out.Vpb = nan(1,2);
out.Upa = nan(1,2);
out.Upb = nan(1,2);
out.Q = 0;
out.mean = nan(1,2);


out.ni_1comp = NaN;
out.ni_2comp = NaN;
out.v_ion    = NaN;

out.ni_aion  = NaN;
out.Vsc_aion = NaN;
out.v_aion   = NaN;
%out.P         =nan(1,2);

upper_comparison_bool = true;
%global ALG;

if nargin < 5     % if SM_Below_Vs is not specified, default to 0.3
  SM_Below_Vs = 0.4;
end


if (size(V) ~= size(I))
  V = V';
end

%global an_debug VSC_TO_VPLASMA VSC_TO_VKNEE;


% Find the number of data points in the sweep
len = length(V);  % the function length returns the length of the vector V

Vp = V + Vsc;   % Setting the probe potential.

% Find the data points below the spacecraft potential
ind_all = find(V < -Vknee ); % Saving indices of all potential values below the knee potential.

if isempty(ind_all)
    out.Q = 2;
    return
end
% Remove first point. It could be untrustworthy due to smoothing.
ind =ind_all(2:end); 


% Use the lowest ALG.SM_Below_Vs*100% of the bias voltage, below the spacecraft potential
% The data is sorted from lowest bias voltage to highest bias voltage so
% the first ALG.SM_Below_Vs*100% is OK to use
l_ind = length(ind); % Need the number of data points of the vector ind



top = floor(l_ind*SM_Below_Vs +0.5);



%top = floor(l_ind*ALG.SM_Below_Vs); % The point closest to, but below, ALG.SM_Below_Vs*100% of the
                         % spacecraft potential. The function floor rounds
                         % the calling parameter to the nearest integer
                         % towards minus infinity.

ind = ind(1:top); % Only the first ALG.SM_Below_Vs*100% below the spacecraft potential is now
Vr  = V(ind);     % kept of the vector ind.
Ir  = I(ind);     % The "ion-voltage" and "ion-current" are set. Note that this
                  % is not the ion-voltage or ion-current in the physical sense
		          % as there may be contamination from other sources
                  % but the notation is used for convenience in the coding.
                  % Also note that the current vector and the potential vector
                  % have a one-to-one dependence on their elements, so they
                  % can, and must, be changed identically.


% Now we make sure that we do not go closer than ALG.SM_Bias_Limit V to -Vsc and that no
% positive current values are included in our data set vector
% ind = find(Vi < -Vsc-ALG.SM_Bias_Limit); % Finding the data points of our "ion-data" that are
% Vi = Vi(ind);            % farther from -Vsc than ALG.SM_Bias_Limit V. These are kept, the rest
% Ii = Ii(ind);            % of the data points are discarded

% Exclude positive currents.
ind = find(Ir < 0);
if(isempty(ind) || length(ind) < 2 )
    return
end
%Vpr = Vp(ind);
Vr = Vr(ind);       % Negative current values in our vector are kept, the
Ir = Ir(ind);       % rest of the data points are, again, discarded.





% 'This part of our data is now linearly fitted, in a least square sense
% The function polyfit finds the coefficients of a
% polynomial P(Vi) of degree 1 that fits the data Ii best
% in a least-squares sense. P is a row vector of length
% 2 containing the polynomial coefficients in descending
% powers, P(1)*Vi+P(2)
[P_Vb,S] = polyfit(Vr,Ir,1);

%% upper ion current comparison
% This is basically the same thing, again although a bit higher on the
% sweep. So less comments
% extra comparison after elias findings of spurious slopes
top_upper = floor(l_ind*0.75 +0.5); %

test= floor(l_ind*0.4 +0.5):top_upper; %  from 40% to 75%... 
%this is such a fickle programming language. Need to be test all this very
%carefullly
if(isempty(test) || length(test) < 2 )
    upper_comparison_bool=false;
else
    ind_upper = ind_all(test);  %Doesn't depend on SM_Below_Vs
    %ind_upper = ind(floor(l_ind*0.4 +0.5):top_upper);  %Doesn't depend on SM_Below_Vs
    Vr_upper = V(ind_upper);
    Ir_upper = I(ind_upper);
    
    % Exclude positive currents.
    ind_upper = find(Ir_upper < 0);
    
    % second test
    if(isempty(ind_upper) || length(ind_upper) < 2 )
        upper_comparison_bool=false;
    else
        Vr_upper = Vr_upper(ind_upper);
        Ir_upper = Ir_upper(ind_upper);
    end
end
%%



if upper_comparison_bool
    [P_Vb_upper,S_upper] = polyfit(Vr_upper,Ir_upper,1);
    
    if P_Vb_upper(1) > P_Vb(1)
        % Do comparison Y/N? & is the upper ion current slope more positive than the
        % other?
        %Okay, apparently the ion current in the low part of the sweep is
        %funky, or the "upper ion current" of the sweep is contaminated by
        %electron retarding current. Let's compute R^2 and see which fit was
        %objectively better.
        
        q_ind = 1:floor(l_ind*0.75+0.5);
        I_diff_low   = I(q_ind) - polyval(P_Vb,V(q_ind)); %
        I_diff_upper = I(q_ind) - polyval(P_Vb_upper,V(q_ind));
        
        Rsq_low_temp=  nansum((I_diff_low.^2))  /nansum(((I(q_ind)-nanmean(I(q_ind))).^2));
        Rsq_upper_temp=nansum((I_diff_upper.^2))/nansum(((I(q_ind)-nanmean(I(q_ind))).^2));
        
        Rsq_low   = 1 - Rsq_low_temp;
        Rsq_upper = 1 - Rsq_upper_temp;
        
        
        %this eq makes it so that if both fits are bad, rsq_low_temp is
        %probably preferred, since it's longer and not as affected by 
        %Ie_(exp). If both fits are good, than the Rsq_upper_temp is a very low value, and would not be heavily weighted against.
        if Rsq_low_temp-Rsq_upper_temp/2 > Rsq_upper_temp       
%        if Rsq_low < Rsq_upper  % Upper fit was much better, so let's pretend that's what we did all along.
            fprintf(1,'ion sweep region changed, Rsq_low was =%5.3e,Rsq_upper was =%5.3e ',Rsq_low,Rsq_upper)
            fprintf(1,'V & I = \n');
            fprintf(1,'%e,',V);
            fprintf(1,'\n');
            fprintf(1,'%e,',I);
            fprintf(1,'\n');

            P_Vb= P_Vb_upper;
            S = S_upper;
        end %% Otherwise, this comparison has no impact below this line
        
    end
end
%%


a(1) = P_Vb(1); % This is accordingly the slope of the line...
b(1) = P_Vb(2); % ...and this is the crossing on the y-axis of the line

S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df); % the std errors in the slope and y-crossing

a(2) = abs(S.sigma(1)/P_Vb(1));   % Fractional error
b(2) = abs(S.sigma(2)/P_Vb(2));   % Fractional error


%finding the Ii0 from the exponential, because why not.
%ind2= find(V>-Vsc &~ge(I,0))
%[P_log,S]=polyfit(Vp(ind2),log10(abs(I(ind2))),1)
%a1=10^(P_log(2))
%hah = -(a1-P_Vb(2))/Vsc


%[PVp,junk] = polyfit(Vpr,Ir,1); %this is slow, we need only a simple
%calculation to fit as function of Vsc.
P_Vp = P_Vb;                  %same slope, but we need to change intersect
P_Vp(2) = P_Vb(2) - P_Vb(1)*Vsc; %fit as function of Vp= V-Vsc.

P_Up = P_Vb;
P_Up(2) = P_Vb(2) - P_Vb(1)*Vknee; %same slope, but intersect if ions are function of Up, where Up = V-Vknee)

out.a = a;


if (a(2) > 1) || (a(1) < 0)   % if error is large (!) or slope is in the wrong direction (unphysical)

    a = [0 0];   % no slope
    b = [mean(Ir) std(Ir)];   % offset
    out.Q(1) = 1;

    P_Vp(1) = a(1); % no slope
    P_Vp(2) = b(1);

    P_Up(1) = a(1);
    P_Up(2) = b(1);

    if nargin < 5     % Try it again with a different SM_below_Vs value.
        [out] = LP_Ion_curr(V, I, Vsc, Vknee, 0.6);     % NOTE: RECURSIVE CALL
        return
    end

end





%P(2) = 0;
% The negative part of this line (since having a positive ion current
% contribution would not be sensible), extended to the full range of the
% potential sweep, is a good approximation to the ion current, and that is
% what is returned from this function

    
    Ii(1:len) = a(1)*V+b(1);% overall ion current fit
    % IiVp = V_Vp(1)*(V-Vsc) + b(1);
    % IiUp = V_Up(1)*(V-Vknee) + b(1);
    %
    %

    %Ii(1:len) = 0;

    %Ii(1:length(Vi)) = a*Vi;

    %Ii2(1:length(Vi)) = polyval(P,Vi);    % The current is calculated across the entire potential
    % sweep. The function polyval returns the value of the
    % polynomial P evaluated at all the points of the vector V.

    Ii = (Ii-abs(Ii))/2; % The positive part is removed, leaving only a negative
    % current contribution. This is the return current
    % The function abs returns the absolute value of the
    % elements of the calling parameter.

    %


    % IiVp = (IiVp-abs(IiVp))/2;
    % IiUp = (IiUp-abs(IiUp))/2;

    out.I = Ii;
%    out.a = a;
    out.b = b;
    out.Vpa = [P_Vp(1) a(2)];
    out.Vpb = [P_Vp(2) b(2)];
    out.mean = [mean(Ir) std(Ir)]; % offset
    out.Upa = [P_Up(1) a(2)];
    out.Upb = [P_Up(2) b(2)];
    %out.P   = P_Vb;
    
%     out.Vs(1) = (b(1)-assmpt.Iph0)/a(1);
%     out.Vs(2) = out.Vs(1)-(b(1)-assmpt.Iph0+3e-9)/a(1);
%     


    % Calculate ion densities velocities
    % FKJN edit 6Nov 2015
    % This was terrible, the units are all wrong. What the hell is MQ^-1T^-2L^-1?
    %
    % FKJN edit 25 May 2016 ehmm..  This was actually correct all along.  slightly rephrased below.
    %out.ni_1comp     = max((1e-6 * out.Vpa(1) *assmpt.ionM*CO.mp*assmpt.vram/(2*IN.probe_cA*CO.e^2)),0);

    if (out.Vpa(1)>0)

      % [L-3]           =  [M L T-1 L-2 M-1 L-3 T2 L T-1] = [L-3]
      out.ni_1comp     = 1e-6*(assmpt.ionM*CO.mp*assmpt.vram/(2*IN.probe_cA*(CO.e)^2)) * out.Vpa(1);
      %  out.ni_1comp     = (1e-6 * out.Vpa(1)/(assmpt.vram*2*IN.probe_cA*CO.e));
    else
        out.ni_1comp = 0;
    end
      
    if (out.Vpb(1) < 0) %unphysical if intersection is above zero!

        % [L-3]        = [  L-2 M-0.5 L-1.5 T  sqrt(M T-2 L ) ] = [ L-3]
        out.ni_2comp    = (1e-6/(IN.probe_cA*CO.e))*sqrt((-assmpt.ionM*CO.mp*(out.Vpb(1)) *out.Vpa(1) /(2*CO.e)));
        out.v_ion       =  out.ni_2comp     *assmpt.vram/out.ni_1comp;
    end

    %Accelerated ions calculations

    if (out.Upb(1) < 0) %unphysical if intersection is above zero!
        out.ni_aion     = (1e-6/(IN.probe_cA))*sqrt((-assmpt.ionM*CO.mp*out.Upa(1)*out.Upb(1)/((2*CO.e.^3))));
    end

    if out.Upa(1) ~= 0
        out.Vsc_aion    = Vknee  +out.Upb(1)/out.Upa(1);
        out.v_aion      = sqrt(-2*CO.e*(out.Vsc_aion-Vknee)/(CO.mp*assmpt.ionM));
    end

    % Ii(1:len) = 0;
    %   out.I = Ii; initialised to zero





end
