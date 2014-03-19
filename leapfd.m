%leapfrogd

function [dx,d2x] = leapfd(x,y,varargin)


dx= zeros(length(y),1);
d2x = zeros(length(y),1);

lgolay=varargin{1,1};


if nargin >2
    
    x= smooth(x,lgolay,'sgolay');
end


if length(x) ==length(y)
            
    for j = 2: length(x)-1
        
        %leapfrog derivative method

        dx(j)= (x(j-1)-x(j+1))/(y(j-1)-y(j+1)); %dx/dy

        
    end%for
    
    dx(1)= (x(1)-x(1+1))/(y(1)-y(1+1)); %dx/dy
    dx(j+1)= (x(j)-x(j+1))/(y(j)-y(j+1)); %dx/dy
 
    
if nargin >2
    
    dx= smooth(dx,lgolay,'sgolay');
end
  
    
for j= 2:length(x)-1
        %leapfrog derivative method
        d2x(j)= (dx(j-1)-dx(j+1))/(y(j-1)-y(j+1)); %d2x/dy^2

    end%for
    
    d2x(1)= (dx(1)-dx(1+1))/(y(1)-y(1+1)); %d2x/dy^2  forward differentiation, larger error
    d2x(j+1)= (dx(j)-dx(j+1))/(y(j)-y(j+1)); %d2x/dy^2   %backward differentiation, larger error
    



end



end
