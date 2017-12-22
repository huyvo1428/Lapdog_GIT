%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Name:  LP_Sort_Sweep.m
% Author: Claes Weyde
% Description: 
%	[Vs,Is,Q] = LP_Sort_Sweep(V,I)
%
%   	The data is adjusted the vectors (matrices) containing the data are sorted with 
%       respect to higher bias potential.Note that sorting is only needed if we have both 
%       down and up sweeps.
%
%	1. Now the data is sorted in ascending bias potential order. Here the MATLAB function "sort" is used, 
%	   which sorts the potential in ascending order and saves the indices order. Thus, those indices can 
%	   then be used on the current to sort it in the same way as the potential. The easiest way to do it in 
%	   for example C++ would be to construct a "search for the least and swap"-algorithm using a nested for 
%	   loop.
%	2. The adjusted data vectors are now returned from the function. 
%
% Input:
%      V      Bias potential           [V]
%      I      Probe current            [A]
%
% Output:
%      Vsorted     Sorted bias potential    [V]
%      Isorted     Sorted probe current     [I]
%                                                         
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Vsorted,Isorted] = LP_Sort_Sweep(V,I)


[Vsorted,ind] = sort(V); % The function sort, sorts the elements of V
	                     % in ascending order
Isorted = I(ind);        % The elements of the current-vector Isorted changed 
      	                 % accordingly, so that
      	                 % the correspondance in (V,I)-pairs remain the same after sorting
end
