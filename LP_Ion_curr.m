%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                                    
% Name:  LP_Ion_curr.m
% Author: Clas Weyde, RG modified not to use hardcoded constants
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
function [out,Q] = LP_Ion_curr(V,I,Vsc,Q)




Ii = I;
Ii(1:end)=0;
out = [];
out.I = Ii;
out.a = NaN;
out.b = NaN;



a = NaN;
b = NaN;

%global ALG;
SM_Below_Vs =0.6;

global an_debug VSC_TO_VPLASMA VSC_TO_VKNEE; 


% Find the number of data points in the sweep
len = length(V);  % the function length returns the length of the vector V

Vp = V+Vsc; % Setting the probe potential

% Find the data points below the spacecraft potential
ind = find(Vp < 0); % Saving indices of all potential values below the knee potential.

if isempty(ind)
    Q(1) = 2;
    return
end

                 
% Use the lowest ALG.SM_Below_Vs*100% of the bias voltage, below the spacecraft potential
% The data is sorted from lowest bias voltage to highest bias voltage so 
% the first ALG.SM_Below_Vs*100% is OK to use
l_ind = length(ind); % Need the number of data points of the vector ind
                     % the function length returns the length of vector ind

                     
                     
top = floor(l_ind*SM_Below_Vs +0.5);
%top = floor(l_ind*ALG.SM_Below_Vs); % The point closest to, but below, ALG.SM_Below_Vs*100% of the
                         % spacecraft potential. The function floor rounds 
                         % the calling parameter to the nearest integer 
                         % towards minus infinity.

ind = ind(1:top); % Only the first ALG.SM_Below_Vs*100% below the spacecraft potential is now
Vr  = V(ind);     % kept of the vector ind    
Ir  = I(ind);     % The "ion-voltage" and "ion-current" are set. Note that this
                  % is not the ion-voltage or ion-current in the physical sense
		          % as there may be contamination from other sources
                  % but the notation is used for convenience in the coding 
                  % Also note that the current vector and the potential vector
                  % have a one-to-one dependence on their elements, so they
                  % can, and must, be changed identically

clear ind l_ind; % Clearing the previous data, the function clear clears the 
                 % function specified

% Now we make sure that we do not go closer than ALG.SM_Bias_Limit V to -Vsc and that no
% positive current values are included in our data set vector
% ind = find(Vi < -Vsc-ALG.SM_Bias_Limit); % Finding the data points of our "ion-data" that are
% Vi = Vi(ind);            % farther from -Vsc than ALG.SM_Bias_Limit V. These are kept, the rest
% Ii = Ii(ind);            % of the data points are discarded

ind = find(Ir < 0); % There may be no positive current values and thus all 
if(isempty(ind) || length(ind) < 2 )
    return
end

Vpr = Vp(ind);
Vr = Vr(ind);       % negative current values in our vector are kept, the
Ir = Ir(ind);       % rest of the data points are, again, discarded


if (size(Vr) ~= size(Ir)) 
  Vr = Vr';
end

% 'This part of our data is now linearly fitted, in a least square sense
[P,S] = polyfit(Vr,Ir,1); % The function polyfit finds the coefficients of a
                      % polynomial P(Vi) of degree 1 that fits the data Ii best
                      % in a least-squares sense. P is a row vector of length
                      % 2 containing the polynomial coefficients in descending
                      % powers, P(1)*Vi+P(2)
a(1) = P(1); % This is accordingly the slope of the line...
b(1) = P(2); % ...and this is the crossing on the y-axis of the line 

S.sigma = sqrt(diag(inv(S.R)*inv(S.R')).*S.normr.^2./S.df); % the std errors in the slope and y-crossing

a(2) = abs(S.sigma(1)/P(1)); %Fractional error 
b(2) = abs(S.sigma(2)/P(2)); %Fractional error


[P2,junk] = polyfit(Vpr,Ir,1);



if a(2) > 1 % if error is large (!)
    
    a = [0 0]; % no slope
    b = [mean(Ir) std(Ir)]; % offset    
    Q(1) = 1;
    
    P2(1) = a(1); % no slope
    P2(2) = b(1);   
end





%P(2) = 0;
% The negative part of this line (since having a positive ion current
% contribution would not be sensible), extended to the full range of the
% potential sweep, is a good approximation to the ion current, and that is
% what is returned from this function

Ii(1:len) = a(1)*V+b(1);%let's try removing it everywhere




%Ii(1:len) = 0;

%Ii(1:length(Vi)) = a*Vi;

%Ii2(1:length(Vi)) = polyval(P,Vi);    % The current is calculated across the entire potential
                      % sweep. The function polyval returns the value of the
                      % polynomial P evaluated at all the points of the vector V.

Ii = (Ii-abs(Ii))./2; % The positive part is removed, leaving only a negative
                      % current contribution. This is the return current
                      % The function abs returns the absolute value of the
                      % elements of the calling parameter.
                      
                      

                      
if (an_debug>1)    
	subplot(2,2,3),plot(Vp,I,'b',Vp,Ii,'g');grid on;
    title([sprintf('Ion current vs Vp, Q(1)=%d',Q(1))])
    legend('I','I_i_o_n')

end


out.I = Ii;
out.a = a;
out.b = b;
out.Vpa = [P2(1) a(2)];
out.Vpb = [P2(2) b(2)];




end

