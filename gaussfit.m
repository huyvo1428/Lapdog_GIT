function [sigma, mu] = gaussfit( x, y, sigma0, mu0 )
% [sigma, mu] = gaussfit( x, y, sigma0, mu0 )
% Fits a guassian probability density function into (x,y) points using iterative 
% LMS method. Gaussian p.d.f is given by: 
% y = 1/(sqrt(2*pi)*sigma)*exp( -(x - mu)^2 / (2*sigma^2))
% The results are much better than minimazing logarithmic residuals
%
% INPUT:
% sigma0 - initial value of sigma (optional)
% mu0 - initial value of mean (optional)
%
% OUTPUT:
% sigma - optimal value of standard deviation
% mu - optimal value of mean
%
% REMARKS:
% The function does not always converge in which case try to use initial
% values sigma0, mu0. Check also if the data is properly scaled, i.e. p.d.f
% should approx. sum up to 1
% 
% VERSION: 23.02.2012
% 
%some edits by Fredrik Johansson 2014-05-12
% EXAMPLE USAGE:
% x = -10:1:10;
% s = 2;
% m = 3;
% y = 1/(sqrt(2*pi)* s ) * exp( - (x-m).^2 / (2*s^2)) + 0.02*randn( 1, 21 );
% [sigma,mu] = gaussfit( x, y )
% xp = -10:0.1:10;
% yp = 1/(sqrt(2*pi)* sigma ) * exp( - (xp-mu).^2 / (2*sigma^2));
% plot( x, y, 'o', xp, yp, '-' );

            diag = 0;

% Maximum number of iterations
Nmax = 50;

if( length( x ) ~= length( y ))
    fprintf( 'x and y should be of equal length\n\r' );
    exit;
end

n = length( x );
x = reshape( x, n, 1 );
y = reshape( y, n, 1 );

%sort according to x
X = [x,y];
X = sortrows( X );
x = X(:,1);
y = X(:,2);

%Checking if the data is normalized
dx = diff( x );
dy = 0.5*(y(1:length(y)-1) + y(2:length(y)));
s = sum( dx .* dy );
if( s > 1.3 || s < 0.7 )
%    fprintf( 'Data is not normalized! The pdf sums to: %f. Normalizing...\n\r', s );
    y = y ./ s;
end

% X = zeros( n, 3 );
% X(:,1) = 1;
% X(:,2) = x;
% X(:,3) = (x.*x);


% try to estimate mean mu from the location of the maximum
[ymax,index]=max(y);
mu = x(index);

estmu=mu;

% estimate sigma
sigma = 1/(sqrt(2*pi)*ymax);
%estsigma = sigma;

if( nargin == 3 )
    sigma = sigma0;
end

if( nargin == 4 ) &&~isnan(mu0)
    mu = mu0;
end

%xp = linspace( min(x), max(x) );

% iterations


h=0.25; %added euler stepsize FJ 26/6 2014


for i=1:Nmax
%    yp = 1/(sqrt(2*pi)*sigma) * exp( -(xp - mu).^2 / (2*sigma^2));
%    plot( x, y, 'o', xp, yp, '-' );

    dfdsigma = -1/(sqrt(2*pi)*sigma^2)*exp(-((x-mu).^2) / (2*sigma^2));
    dfdsigma = dfdsigma + 1/(sqrt(2*pi)*sigma).*exp(-((x-mu).^2) / (2*sigma^2)).*((x-mu).^2/sigma^3);

    dfdmu = 1/(sqrt(2*pi)*sigma)*exp(-((x-mu).^2)/(2*sigma^2)).*(x-mu)/(sigma^2);

    F = [ dfdsigma dfdmu ];
    a0 = [sigma;mu];
    f0 = 1/(sqrt(2*pi)*sigma).*exp( -(x-mu).^2 /(2*sigma^2));
    da = (F'*F)^(-1)*F'*(y-f0);
   
    a = da*h + a0; %%edited FJ 26/6 2014 ,the stepsize was much too large
    % and will diverge if not careful.
    %ideally, use leapfrog, central difference or Runge-Kutta method
    %instead of this
    sigma = a(1);
    mu = a(2);
%     
%     if mu>10
%         diag = 1;
%     end  
%     if diag
%         figure(3242)
%         plot(x,y,'r',x,(1/(sqrt(2*pi)*sigma^2)*exp(-((x-mu).^2) / (2*sigma^2))),'g');
% 
%         
%     end
    
    
    %%break condition when sufficient accuracy reached FJ
    if (abs(da(1)/a(1)))< 0.001 && i>5 
        %i
        break; 
    end
    
    
    if( sigma < 0 )
        %sigma = abs( sigma );
        sigma = NaN;
        
        fprintf( 'Instability detected! Rerun with initial values sigma0 and mu0! \n\r' );
        fprintf( 'Check if your data is properly scaled! p.d.f should approx. sum up to \n\r' );
        %instead return initial estimates!
        
        if diag
            figure(3241)
            subplot(1,2,1)
            plot(x,y,'r',x,(-1/(sqrt(2*pi)*estsigma^2)*exp(-((x-estmu).^2) / (2*estsigma^2))),'g');
            subplot(1,2,2)
            plot(F);
            
        end
        
        mu=estmu; 
        %sigma=3*estsigma;       
        break;
    end
end

