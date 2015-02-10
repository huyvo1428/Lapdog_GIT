function [varargout] = plotCorrelationSunDistance(target, time, parameter, linearFit)

% plotCorrelationSunDistance
%	
%   Plots the supplied parameter values as a function of the distance to 
%   the Sun. Can also plot the linear least square fit for a
%   polynom of degree one and return the correlation coefficient.
%   
%   
%   SYNTAX:
%       
%                   plotCorrelationSunDistance(target)
%       
%                   plotCorrelationSunDistance(target, time, parameter)
%       
%                   plotCorrelationSunDistance(target, time, parameter, linearFit)
%       
%       corrCoeff = plotCorrelationSunDistance(target, time, parameter, linearFit)
%       
%       
%   DESCRIPTION:
%       
%       plotCorrelationSunDistance(target) displays the time spans
%       available for the data used in the calculations. It also displays 
%       the times for when the spacetime related source files were 
%       retrieved.
%       
%       plotCorrelationSunDistance(target, time, parameter) plots the
%       parameter values as a function of the to the Sun.
%       
%       plotCorrelationSunDistance(target, time, parameter, linearFit)
%       plots the parameter values as a function of the distance to the
%       Sun. It also plots the linear least square fit for the data, 
%       using a polynom of degree one.
%       
%       corrCoeff = plotCorrelationSunDistance(target, time, parameter, linearFit)
%       plots the parameter values as a function of the distance to the
%       Sun. It also plots the linear least square fit for the data, 
%       using a polynom of degree one. Returns the correlation coefficient.
%   
%   
%   PARAMETERS:
%       
%       target:     Is a string with one of the following valid target 
%                   names:
%                       
%                       * Earth
%                       * Jupiter
%                       * Mars
%                       * Mercury
%                       * Neptune
%                       * Saturn
%                       * Uranus
%                       * Venus
%                       
%                       * ChuryumovGerasimenko
%                       * Steins
%                       
%                       * Cassini
%                       * Rosetta
%                       
%      time:        Is a vector containing the times associated with the 
%                   respective paramater values.
%                   
%                   Times should be in datenum converted UCT time.
%                   
%      parameter:	Is a vector containing the parameter values associated 
%                   with the respective times.
%
%      linearFit:   Is the boolean expression of true or false,
%                   determining if the linear least square fit should be 
%                   done.
%
%      corrCoeff:   Is the correlation coefficient.
%               
%               
%   REMARKS:
%      
%      Each space coordinate is calculated from a linear interpolation
%      between two spacetime coordinates from Horizons data. The Horizons
%      data used has a six hour step size.
%      
%      Horizons can be found at:
%
%           http://ssd.jpl.nasa.gov/horizons.cgi
%


%   Author: Martin Ulfvik
%   Usage: However the Swedish Institute of Space Physics sees fit.
%   $Revision: 1.02 $  $Date: 2009/04/01 10:45 $
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Checks that the correct number of arguments has been supplied.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    error(nargchk(3, 4, nargin));
    error(nargoutchk(0, 1, nargout));
    
    if (nargin == 3 && nargout == 1) || (nargin == 1 && nargout == 1)
        
        error('Incorrect combination of the number of input and output arguments.');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * If the function call was an info request, then the info is given
    %     and the function ended.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin == 1
        
        if ~strcmp(target, 'Earth')
            
            time2space(target);
        end
        
        spacetime2flux();
        
        return;
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Checks that the parameter argument has the correct form.
    %   * Makes sure the parameter argument gets a one column vector form.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~(isvector(parameter) && isnumeric(parameter) && isreal(parameter))
        
        error('The parameter argument needs to be a vector containing  real numeric entries.');
    
    else
        
        parameterDimensions = size(parameter);
        
        if parameterDimensions(1) == 1
            
            parameter = parameter';
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Checks that the length of the time and parameter arguments are 
    %     equal.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if length(parameter) ~= length(time)
        
        error('The length of the time and parameter arguments need to be equal.');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Checks that the linearFit argument has the correct form if one is
    %     supplied, if none is supplied it sets it to the default.
    %   * Checks that no output argument is requested if it has
    %     specifically been called for no linear fit.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin == 4
        
        if ~(linearFit == 0 || linearFit == 1)
            
            error('The linearFit argument needs to be either false or true');
        end
        
    else
        
        linearFit = false;
        
    end
    
    if ~linearFit && nargout == 1
        
        error('Incorrect number of output arguments.');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Calculates the distance between the Sun and the target at the 
    %     times supplied.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    space = time2space(target, time);
    
    distance = sqrt(sum(space.^2,2));
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Plots the parameter values as a function of the distance.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    plot(distance, parameter, 'b.');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * If a linear fit was requested, then it plots a linear least 
    %     square fit to the data points.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if linearFit == true
        
        hold on;
        
        polyCoeffs = polyfit(distance, parameter, 1);
        
        plot([min(distance) max(distance)], polyCoeffs(1)*[min(distance) max(distance)]+ polyCoeffs(2), 'r-', 'LineWidth', 2);
        
        hold off;
        
        legendHandle = legend('Data Points', 'Linear Square Fit');
        
    else
        
        legendHandle = legend('Data Points');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Visual aspects of the plot.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(legendHandle, 'Location', 'NorthEastOutside');
    set(legendHandle, 'FontName', 'Calibri');
    set(legendHandle, 'FontSize', 8);
    
    set(gca, 'Box'     , 'off');
    set(gca, 'TickDir' , 'in');
    set(gca, 'FontName', 'Calibri');
    set(gca, 'FontSize', 8);
    
    title({'','Parameter value as a function of the distance to the Sun',''});
    xlabel('Distance / AU');
    ylabel('Units of the parameter');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * If the correlation coefficient of the linear least square fit was
    %     requested, then it is calculated.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargout == 1
        
        n = length(parameter);
        
        corrCoeff = ( n*sum(distance.*parameter) - sum(distance)*sum(parameter) ) / ( sqrt(n*sum(distance.^2)-(sum(distance))^2) * sqrt(n*sum(parameter.^2)-(sum(parameter))^2) );
        
        varargout(1) = {corrCoeff};
    end
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%