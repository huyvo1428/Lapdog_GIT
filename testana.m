% 
% 
% 
% Linear Model with Nonpolynomial Terms
% 
% When a polynomial function does not produce a satisfactory model of your
%data, you can try using a linear model with nonpolynomial terms. 
%For example, consider the following function that is linear in the 
%parameters a0, a1, and a2, but nonlinear in the t data:
% 
% y = a0+a1e^t +a2te^-t

%You can compute the unknown coefficients a0, a1, and a2 by constructing and solving a set o
%f simultaneous equations and solving for the parameters. The following 
%syntax accomplishes this by forming a design matrix, where each column represents a
%variable used to predict the response (a term in the model) and each row
% corresponds to one observation of those variables:

% Enter t and y as columnwise vectors


t = [0 0.3 0.8 1.1 1.6 2.3]';
y = [0.6 0.67 1.01 1.35 1.47 1.25]';

t = V.';

y = I.';

A=5;


C= t;
C(:)=10E-9;


% Form the design matrix
%X = [ones(size(t))  exp(-t)  t.*exp(-t)];

%X = [ones(size(t))  exp(t)  t+A];

X = [ones(size(t))  exp(t+A)];

X(t>A,:) = [ones(size(t(t>A)))  (t(t>A)+A)];


% Calculate model coefficients
a = X\y; %NB Backslash

% a =
%     1.3983
%   - 0.8860
%     0.3085

%Therefore, the model of the data is given by



%Now evaluate the model at regularly spaced points and plot the model with the original data, as follows:

len= length(t);
figure(2);


T = (t(1):0.5:t(end)).';
Y = [ones(size(T))  exp(T+A)]*a;
Y(T>A,:) = [ones(size(T(T>A)))  (T(T>A)+A)]*a;

plot(T,Y,'-',t,y,'o'), grid on