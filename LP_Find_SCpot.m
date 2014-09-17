%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                  
% Name: LP_Find_SCpot.m
% Author: Claes Weyde, Reine Gill
% Description:                    
%	Vsc = LP_Find_SCpot(V,I,dv,)
%                                 
%	The spacecraft potential is determined by looking at the maximum in the second derivative. Below is a
%	step-by-step description of the algorithm.
%
%	1. First the length of the data is determined and stored in a variable called "len".
%
%	2. Next the differentiation is performed. This is done by calling the MATLAB function gradient.m. What 
%	   this function does is basically to take the centered differences between the elements in the vector 
%	   and divide by the step length (that is given in the calling of the function). On the left and right 
%	   edges of the vector, forward differences are taken. Now a smoothing is performed using
%	   Savitsky-Golay filtering (see Press et al., Numerical Recipes in C). This procedure
%	   is performed twice, first with the current data and the step height as input, and then with the
%	   obtained derivative of the current data and the step height as input.
%
%	3. Having obtained the first and second derivative the maximum in the second derivative is sought. 
%	   First the indices of all points above 94% of the maximum value in the second derivative is found.
%	   Having found this set of values the right most index of these are choosen as the index for the
%	   negative of the spacecraft potential. The right most index is
%	   choosen since there is a tendency to go to the left.
%
%	4. The spacecraft potential is now set as the negative of the potential value having the index 
%	   determined above.
%
%	5. Vsc is returned from the function.
%                                                                  
% Input:
%      V       Bias potential           [V]
%      I       Probe current            [A]
%      dv      Potential step height    [V]
%
% Output:
%      Vsc     Spacecraft potential     [V]
%
% Notes:                                                           
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Vsc = LP_Find_SCpot(V,I,dv)

global efi_f_io_lp_l1bp;
%global ALG;  % Algorithm parameters
SM_Sav_Gol = 5;


% Find the number of data points in the sweep
len=length(V); % the function length returns the length of the vector V

% Normal derivatives:
d1s = gradient(sgolayfilt(I,2,SM_Sav_Gol),dv);
d2s = gradient(sgolayfilt(d1s,2,SM_Sav_Gol),dv);

if (efi_f_io_lp_l1bp>1)
	subplot(2,2,4)
    plot(V,I,'g',V,d2s,'red',V,d1s,'blue');
	legend('Data','2nd der','1st der','location','northwest')
	title('The determination of V_s_c');
	grid on;
    drawnow;
end

% Use linearly calculated derivatives to find Vs:
vmax = find(d2s >= 0.94*max(d2s));
vsind=vmax(length(vmax)); % Choose right most index

Vsc=-V(vsind);

