%% Ordinary linear least squares fit with outlier removal
function [pp, varargout] = fit_ols_ESD(X, Y, varargin)
%%
% Generalized ESD test for outliers:
% (http://www.itl.nist.gov/div898/handbook/eda/section3/eda35h3.htm)
n = numel(Y);
outliers = false(n, 1);
k = 0;
pp = NaN(1,2);
if nargin > 2
    alpha = varargin{1};
else
    alpha = 0.001;
end
while k < numel(Y)-3
    k = k+1;
    %%%
    % Total least squares:
    [pp, SS ,junk] = polyfit(X(~outliers), Y(~outliers), 1);
    %%%
    % Compute test statistic:
    residuals = abs(Y(~outliers) - polyval(pp, X(~outliers)));
    [R, I] = max(residuals);
    R = R/nanstd(residuals);
    %%%
    % Compute critical value:
    p = 1 - alpha/(2*(n-k+1));
    tp = tinv(p, n-k-1);
    lambda = (n-k)*tp/sqrt((n-k-1+tp^2)*(n-k+1));
    %%%
    % Test for outlier:
    outlier = R > lambda;
    if outlier
        tmp = find(~outliers);
        outliers(tmp(I)) = true;
        n = n-1;
    else
        break;
    end
end

%% Give output:
if nargout == 2
    varargout{1} = outliers;
end

if nargout == 3
    varargout{1} = outliers;
    varargout{2} = SS;
    
end


end
