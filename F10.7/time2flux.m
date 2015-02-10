function [varargout] = time2flux(target, time)

% time2flux
%	
%   Returns the estimated flux values for the target and times supplied, 
%   based on the 10.7 cm wavelength flux measured on Earth.
%   
%   
%   SYNTAX:
%       
%              time2flux(target)
%       
%       flux = time2flux(target, time)
%       
%       
%   DESCRIPTION:
%       
%       time2flux(target) displays the time spans available for the data
%       used in the calculations. It also displays the times for when the
%       spacetime related source files were retrieved.
%       
%       flux = time2flux(target, time) returns the estimated flux values 
%       for the specified target at the times supplied.
%   
%   
%   PARAMETERS:
%       
%       target:	Is a string with one of the following valid target names:
%           
%                   * Earth
%               	* Jupiter
%                 	* Mars
%                  	* Mercury
%                 	* Neptune
%                  	* Saturn
%                   * Uranus
%                   * Venus
%                   
%                   * ChuryumovGerasimenko
%                   * Steins
%                   
%                   * Cassini
%                   * Rosetta
%                   
%      flux:	Is the N-by-1 vector containing the estimated flux values.
%                   
%      time: 	Is a vector containing the times for which the space 
%               coordinates should be calculated.
%             	
%            	Times should be in datenum converted UCT time.
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
%      Each flux value is calculated based on the two flux values
%      (before and after) that is measured on Earth, at the 10.7 cm 
%      wavelength, when the Earth sees the same face of the sun as the
%      spacetime in question. The weight the two values carry is based on
%      their proximity (time wise) to the time beeing calculated.
%
%      Assumption for near equatorial (Sun) space is made, in the sence
%      that a rotation of the Sun should be possible to give the space in
%      question the same face of the Sun as seen from Earth.
%
%      Earth flux values can be found at:
%
%           ftp://ftp.ngdc.noaa.gov/STP/SOLAR_DATA/SOLAR_RADIO/FLUX/
%


%   Author: Martin Ulfvik
%   Usage: However the Swedish Institute of Space Physics sees fit.
%   $Revision: 1.01 $  $Date: 2009/03/31 18:48 $
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Checks that the correct number of arguments has been supplied.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    error(nargchk(1, 2, nargin));
    error(nargoutchk(0, 1, nargout));
    
    if nargin == 1 && nargout == 1
        
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
    %   * Checks that the time argument has the correct form.
    %   * Makes sure the time argument gets a one column vector form.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~(isvector(time) && isnumeric(time) && isreal(time))
        
        error('The time argument needs to be a vector containing datenum converted UCT time.');
        
    else
        
        timeDimensions = size(time);
        
        if timeDimensions(1) == 1
            
            time = time';
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Flux values are calculated for the times supplied.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    space = time2space(target, time);
    
    flux = spacetime2flux([space time]);
    
    varargout(1) = {flux};
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%