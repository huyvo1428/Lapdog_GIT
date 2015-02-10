function [varargout] = time2space(target, time)

% time2space
%	
%   Returns the space coordinates for the target and times supplied.
%   
%   
%   SYNTAX:
%       
%               time2space(target)
%       
%       space = time2space(target, time)
%       
%       
%   DESCRIPTION:
%       
%       time2space(target) displays the time span that is available for
%       calculations for the specified target. It also displays the time
%       when the Horizon file, which is the source of the data, was 
%       retrieved.
%       
%       space = time2space(target, time) returns the space coordinates for
%       the specified target at the times given.
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
%      space:	Is the N-by-3 matrix containing the space coordinates. Each 
%               row has the form:
%                   
%               	[positionX positionY positionZ]
%            	
%            	Space coordinates are in astronomical units.
%               
%           	The coordinate system used is:
%           	
%                   * Cartesian coordinates
%                   * Sun Mean Equator and Node of Date
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
    %   * Checks that the target name supplied is a valid one and if so,
    %     loads the appropriate variables.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch target
    
        case 'Earth'
            
            load(fullfile('resources', 'dataHorizonsEarth.mat'));
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %   dataHorizonsGeneratedEarth: Time (string)
                %
                %   dataHorizonsEarth{1}: Times (datenum)
                %   dataHorizonsEarth{2}: Postions (X)
                %   dataHorizonsEarth{3}: Postions (Y)
                %   dataHorizonsEarth{4}: Postions (Z)
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            dataHorizonsGenerated = dataHorizonsGeneratedEarth;
            clear dataHorizonsGeneratedEarth;
            
            dataHorizonsSpace = [dataHorizonsEarth{2} dataHorizonsEarth{3} dataHorizonsEarth{4}];
            dataHorizonsTime  = dataHorizonsEarth{1};
            clear dataHorizonsEarth;
            
        case 'Jupiter'
            
            load(fullfile('resources', 'dataHorizonsJupiter.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedJupiter;
            clear dataHorizonsGeneratedJupiter;
            
            dataHorizonsSpace = [dataHorizonsJupiter{2} dataHorizonsJupiter{3} dataHorizonsJupiter{4}];
            dataHorizonsTime  = dataHorizonsJupiter{1};
            clear dataHorizonsJupiter;
            
        case 'Mars'
            
            load(fullfile('resources', 'dataHorizonsMars.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedMars;
            clear dataHorizonsGeneratedMars;
            
            dataHorizonsSpace = [dataHorizonsMars{2} dataHorizonsMars{3} dataHorizonsMars{4}];
            dataHorizonsTime  = dataHorizonsMars{1};
            clear dataHorizonsMars;
            
        case 'Mercury'
            
            load(fullfile('resources', 'dataHorizonsMercury.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedMercury;
            clear dataHorizonsGeneratedMercury;
            
            dataHorizonsSpace = [dataHorizonsMercury{2} dataHorizonsMercury{3} dataHorizonsMercury{4}];
            dataHorizonsTime  = dataHorizonsMercury{1};
            clear dataHorizonsMercury;
            
        case 'Neptune'
            
            load(fullfile('resources', 'dataHorizonsNeptune.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedNeptune;
            clear dataHorizonsGeneratedNeptune;
            
            dataHorizonsSpace = [dataHorizonsNeptune{2} dataHorizonsNeptune{3} dataHorizonsNeptune{4}];
            dataHorizonsTime  = dataHorizonsNeptune{1};
            clear dataHorizonsNeptune;
            
        case 'Saturn'
            
            load(fullfile('resources', 'dataHorizonsSaturn.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedSaturn;
            clear dataHorizonsGeneratedSaturn;
            
            dataHorizonsSpace = [dataHorizonsSaturn{2} dataHorizonsSaturn{3} dataHorizonsSaturn{4}];
            dataHorizonsTime  = dataHorizonsSaturn{1};
            clear dataHorizonsSaturn;
            
        case 'Uranus'
            
            load(fullfile('resources', 'dataHorizonsUranus.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedUranus;
            clear dataHorizonsGeneratedUranus;
            
            dataHorizonsSpace = [dataHorizonsUranus{2} dataHorizonsUranus{3} dataHorizonsUranus{4}];
            dataHorizonsTime  = dataHorizonsUranus{1};
            clear dataHorizonsUranus;
            
        case 'Venus'
            
            load(fullfile('resources', 'dataHorizonsVenus.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedVenus;
            clear dataHorizonsGeneratedVenus;
            
            dataHorizonsSpace = [dataHorizonsVenus{2} dataHorizonsVenus{3} dataHorizonsVenus{4}];
            dataHorizonsTime  = dataHorizonsVenus{1};
            clear dataHorizonsVenus;
            
        case 'ChuryumovGerasimenko'
            
            load(fullfile('resources', 'dataHorizonsChuryumovGerasimenko.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedChuryumovGerasimenko;
            clear dataHorizonsGeneratedChuryumovGerasimenko;
            
            dataHorizonsSpace = [dataHorizonsChuryumovGerasimenko{2} dataHorizonsChuryumovGerasimenko{3} dataHorizonsChuryumovGerasimenko{4}];
            dataHorizonsTime  = dataHorizonsChuryumovGerasimenko{1};
            clear dataHorizonsChuryumovGerasimenko;
            
        case 'Steins'
            
            load(fullfile('resources', 'dataHorizonsSteins.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedSteins;
            clear dataHorizonsGeneratedSteins;
            
            dataHorizonsSpace = [dataHorizonsSteins{2} dataHorizonsSteins{3} dataHorizonsSteins{4}];
            dataHorizonsTime  = dataHorizonsSteins{1};
            clear dataHorizonsSteins;
            
        case 'Cassini'
            
            load(fullfile('resources', 'dataHorizonsCassini.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedCassini;
            clear dataHorizonsGeneratedCassini;
            
            dataHorizonsSpace = [dataHorizonsCassini{2} dataHorizonsCassini{3} dataHorizonsCassini{4}];
            dataHorizonsTime  = dataHorizonsCassini{1};
            clear dataHorizonsCassini;
            
        case 'Rosetta'
            
            load(fullfile('resources', 'dataHorizonsRosetta.mat'));
            
            dataHorizonsGenerated = dataHorizonsGeneratedRosetta;
            clear dataHorizonsGeneratedRosetta;
            
            dataHorizonsSpace = [dataHorizonsRosetta{2} dataHorizonsRosetta{3} dataHorizonsRosetta{4}];
            dataHorizonsTime  = dataHorizonsRosetta{1};
            clear dataHorizonsRosetta;
            
        otherwise
            
            error('Invalid target name supplied.');
    end
    
    dataHorizonsLength = length(dataHorizonsTime);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * If the function call was an info request, then the info is given
    %     and the function ended.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin == 1
        
        firstTime = datestr(dataHorizonsTime(1)                 , 'yyyy-mm-dd');
        lastTime  = datestr(dataHorizonsTime(dataHorizonsLength), 'yyyy-mm-dd');
        
        display(' ');
        display(horzcat(target, ' spacetime data is available for the time span:'));
        display(' ');
        display(horzcat(firstTime, '  -  ', lastTime))
        display(' ');
        display('The spacetime data was generated from a Horizons file retrieved:');
        display(' ');
        display(strcat(dataHorizonsGenerated));
        display(' ');
        
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
    %   * Checks that the time argument are within the time span that is
    %     available for calculations.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if dataHorizonsTime(1) > min(time) || dataHorizonsTime(dataHorizonsLength) < max(time)
        
        error('The time argument entered requires data beyond of that available.');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Finds the indices in the horizon data that corresponds to the 
    %     times no later than the times supplied.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    timeLength = length(time);
    
    indices = zeros(timeLength,1);
    
    for timeCounter = 1:timeLength
        
        indices(timeCounter) = find(dataHorizonsTime <= time(timeCounter), 1, 'last');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Calculates the position for the target at the times supplied.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    space = dataHorizonsSpace(indices,:) + (dataHorizonsSpace(indices+1,:) - dataHorizonsSpace(indices,:)) .* (( (time-dataHorizonsTime(indices)) ./ (dataHorizonsTime(indices+1) - dataHorizonsTime(indices)) )*ones(1,3));
    
    varargout(1) = {space};
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%