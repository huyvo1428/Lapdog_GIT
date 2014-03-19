%d2 Approximate second derivative
% [d2y] = d2(x,y) returns the second derivative of y with respect to x.
% d2y is a vector of the same length as y. The vectors should be sorted
% in ascending order. If the length of the data is less than 5 gradient
% will be used.
%
% The differentiation is:
% y_0''=(2*y_4-27*y_3+270*y_2-490*y_0+270*y_-1-27*y_-2+2*y_-3)/(180*h^2)
%
% [d2y,d3y] = d2(x,y) provides both the second and the third derivative
% where the third is evaluated using a similar scheme but only 6 points
function [d2y,d3y] = d2(x,y)
d2y = [];
d3y = [];
lx = length(x); %checking sizes
ly = length(y);
lgolay = max([(2*floor(lx/12)+1) 5]);
y = smooth(y,lgolay,'sgolay');
% if (lx == ly && lx >= 5)
% h = x(2)-x(1); %the steplength is the same throughout
% %%%%%%%%%%%%%%%%%%%%%%%
% %The second derivative%
% %%%%%%%%%%%%%%%%%%%%%%%
% %Use forward differentiation for left boundary
% d2y(1) = (11*y(5)-56*y(4)+114*y(3)-104*y(2)+35*y(1))/(12*h^2);
% d2y(2) = (11*y(6)-56*y(5)+114*y(4)-104*y(3)+35*y(2))/(12*h^2);
% d2y(3) = (11*y(7)-56*y(6)+114*y(5)-104*y(4)+35*y(3))/(12*h^2);
% %Now use the 7-point symmetric formula
% d2y(4:lx-3) = (2*y(7:lx)-27*y(6:lx-1)+270*y(5:lx-2)-490*y(4:lx-3)+...
% 270*y(3:lx-4)-27*y(2:lx-5)+2*y(1:lx-6))/(180*h^2);
% %Use backward differentiation for right boundary
% d2y(lx-2) = (35*y(lx-2)-104*y(lx-3)+114*y(lx-4)-...
% 56*y(lx-5)+11*y(lx-6))/(12*h^2);
% d2y(lx-1) = (35*y(lx-1)-104*y(lx-2)+114*y(lx-3)-...
% 56*y(lx-4)+11*y(lx-5))/(12*h^2);
% d2y(lx) = (35*y(lx)-104*y(lx-1)+114*y(lx-2)-...
% 56*y(lx-3)+11*y(lx-4))/(12*h^2);
% %%%%%%%%%%%%%%%%%%%%%%
% %The third derivative%
% %%%%%%%%%%%%%%%%%%%%%%
% %Use forward differentiation for left boundary
% d3y(1) = (-3*y(5)+14*y(4)-24*y(3)+18*y(2)-5*y(1))/(2*h^3);
% d3y(2) = (-3*y(6)+14*y(5)-24*y(4)+18*y(3)-5*y(2))/(2*h^3);
% d3y(3) = (-3*y(7)+14*y(6)-24*y(5)+18*y(4)-5*y(3))/(2*h^3);
% %Now use the 6-point symmetric formula
% d3y(4:lx-3) = (-y(7:lx)+8*y(6:lx-1)-13*y(5:lx-2)+13*y(3:lx-4)-...
% 8*y(2:lx-5)+y(1:lx-6))/(8*h^3);
% %Use backward differentiation for the right boundary
% d3y(lx-2) = (5*y(lx-2)-18*y(lx-3)+24*y(lx-4)-14*y(lx-5)+...
% 3*y(lx-6))/(2*h^3);
% d3y(lx-1) = (5*y(lx-1)-18*y(lx-2)+24*y(lx-3)-14*y(lx-4)+...
% 3*y(lx-5))/(2*h^3);
% d3y(lx) = (5*y(lx)-18*y(lx-1)+24*y(lx-2)-14*y(lx-3)+...
% 3*y(lx-4))/(2*h^3);
% else
%using simple gradient
d2y = gradient(smooth(gradient(y),lgolay,'sgolay'),x);
d3y = gradient(smooth(d2y,lgolay,'sgolay'),x);
%end
