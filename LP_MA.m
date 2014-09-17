%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                  
% Name: LP_MA.m                                               
% Author: Claes Weyde
% Description:                                                     
%       y_av = LP_MA(y)  
%
%	Given the data points a moving, symmetric average is calculated. This is
%	intended to smooth the data. 
%
%	1. The output vector is defined.
%	2. The first four points are calculated using a forward average of 9 points
%	3. The points that are not the first four or last four points are calculated 
%	   using a symmetric 9-point average.
%	4. The last 4-2 points are calculated using a symmetric 3 point average.
%	5. The very last point is calculated using a backwards two point average.
%	   This will cause the last point to fall somewhat, but should not influence
%	   the data considerably.
%	6. The smoothed data set is returned.                           
%                                                                  
% Input:  
%	  The data points of the set,	y,
% Output: 
%	  The smoothed data set,	y_av                                                    
% Notes:
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function y_av = LP_MA(y)

y_av = [];

ly = length(y);

% For first points a forward average is taken
y_av(1)      = (y(1)+y(2)+y(3)+y(4)+y(5)+y(6)+y(7)+y(8)+y(9))/9;
y_av(2)      = (y(2)+y(3)+y(4)+y(5)+y(6)+y(7)+y(8)+y(9)+y(10))/9;
y_av(3)      = (y(3)+y(4)+y(5)+y(6)+y(7)+y(8)+y(9)+y(10)+y(11))/9;
y_av(4)      = (y(4)+y(5)+y(6)+y(7)+y(8)+y(9)+y(10)+y(11)+y(12))/9;

% For the middle points using a symmetric average
y_av(5:ly-4) = (y(1:ly-8)+y(2:ly-7)+y(3:ly-6)+y(4:ly-5)+y(5:ly-4)+...
                y(6:ly-3)+y(7:ly-2)+y(8:ly-1)+y(9:ly))/9;

% The last 4-2 points are calculated using a 3 point average
y_av(ly-3)   = (y(ly-4)+y(ly-3)+y(ly-2))/3;
y_av(ly-2)   = (y(ly-3)+y(ly-2)+y(ly-1))/3;   
y_av(ly-1)   = (y(ly-2)+y(ly-1)+y(ly))/3; 

% The very last point is taken as a 2 point backward average
y_av(ly)     = (y(ly-1)+y(ly))/2;
end

