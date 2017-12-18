%Computes a central difference derivative and second derivative, with some
%smoothing if asked to(i.e. if a spread for the smooth is one of the inputs).
%the first and last derivative points is calculated by a forward and backward differentiaion
%
% NOTE: Suspiciously similar to leapfd.m
% 
function [dx,d2x] = centralDD(x,y,varargin)


dx= zeros(length(y),1);
d2x = zeros(length(y),1);



if nargin >2
    spread=varargin{1,1};
    %x= smooth(x,spread,'sgolay'); % no need to needless smooth an already
    %smoothened curve
end


len=length(x);

if len ==length(y)
    

    
    dx(1)= (x(1)-x(1+1))/(y(1)-y(1+1)); %dx/dy forward differentiation, larger error    
    dx(len)= (x(len-1)-x(len))/(y(len-1)-y(len)); %dx/dy backward differentiation, larger error
    
    
    
        for j = 2: length(x)-1
    
            %central difference derivative method
    
            dx(j)= (x(j-1)-x(j+1))/(y(j-1)-y(j+1)); %dx/dy
    
    
        end%for
    
    
    
    
    if nargin >2
        
    %    dx(2:end-1)= smooth(dx(2:end-1),spread,'sgolay'); %maybe smooth the di curve, why not
    end
    
    
    
    d2x(1)= (dx(1)-dx(1+1))/(y(1)-y(1+1)); %d2x/dy^2  forward differentiation, larger error, so let's reduce it by 10%
    d2x(len)= (dx(len-1)-dx(len))/(y(len-1)-y(len)); %d2x/dy^2   %backward differentiation, larger error, so let's reduce it by 10%
    
    
    for j= 2:length(x)-1
            %central difference derivative method
            d2x(j)= (dx(j-1)-dx(j+1))/(y(j-1)-y(j+1)); %d2x/dy^2 
    
    end%for
    
    
    
    
end



end
