%Computes a central difference derivative and second derivative, with some
%smoothing if asked to.
function [dx,d2x] = leapfd(x,y,varargin)


dx= zeros(length(y),1);
d2x = zeros(length(y),1);

spread=varargin{1,1};


if nargin >2
    
    x= smooth(x,spread,'sgolay');
end


len=length(x);

if len ==length(y)
    

    
    
        for j = 2: length(x)-1
    
            %leapfrog derivative method
    
            dx(j)= (x(j-1)-x(j+1))/(y(j-1)-y(j+1)); %dx/dy
    
    
        end%for
    
    
    dx(1)= (x(1)-x(1+1))/(y(1)-y(1+1)); %dx/dy forward differentiation
    dx(len)= (x(len-1)-x(len))/(y(len-1)-y(len)); %dx/dy backward differentiation
    
    
    
    
    if nargin >2
        
        dx= smooth(dx,spread,'sgolay');
    end
    
    
    
    
    for j= 2:length(x)-1
            %leapfrog derivative method
            d2x(j)= (dx(j-1)-dx(j+1))/(y(j-1)-y(j+1)); %d2x/dy^2
    
        end%for
    
    d2x(1)= (dx(1)-dx(1+1))/(y(1)-y(1+1)); %d2x/dy^2  forward differentiation, larger error
    d2x(len)= (dx(len-1)-dx(len))/(y(len-1)-y(len)); %d2x/dy^2   %backward differentiation
    
    
    
    
end



end
