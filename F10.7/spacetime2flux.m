function [varargout] = spacetime2flux(spacetime)

% spacetime2flux
%	
%   Estimates the flux from the Sun at the supplied spacetimes based on the
%   10.7 cm wavelength flux measured on Earth.
%   
%   
%   SYNTAX:
%       
%              spacetime2flux()
%       
%       flux = spacetime2flux(spacetime)
%       
%       
%   DESCRIPTION:
%       
%       spacetime2flux() displays the time spans available for the data
%       used in the calculations. It also displays the times for when the
%       spacetime related source files were retrieved.
%       
%       flux = spacetime2flux(tspacetime) returns the estimated flux values
%       for the specified spacetime coordinates supplied.
%   
%   
%   PARAMETERS:
%       
%      flux:        Is the N-by-1 vector containing the estimated flux
%                   values.
%                   
%      spacetime:	Is the N-by-4 matrix containing the spacetime
%                   coordinates for which the flux values should be
%                   calculated. Each row should has the form:
%                           
%                          [positionX positionY positionZ time]
%            	
%                   Space coordinates should be in astronomical units.
%                   Times should be in datenum converted UCT time.
%                   
%                   The coordinate system used is:
%                       
%                       * Cartesian coordinates
%                       * Sun Mean Equator and Node of Date
%
%                   
%   REMARKS:
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
%   $Revision: 1.02 $  $Date: 2009/05/22 13:57 $
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Checks that the correct number of arguments has been supplied.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    error(nargchk(0, 1, nargin));
    error(nargoutchk(0, 1, nargout));
    
    if nargin == 0 && nargout == 1
        
        error('Incorrect combination of the number of input and output arguments.');
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * If it is not an info request, checks that the spacetime argument
    %     has the correct form.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin == 1
        
        spacetimeDimnsions = size(spacetime);
        
        if ~(spacetimeDimnsions(2) == 4 && isnumeric(spacetime) && isreal(spacetime))
            
            error('The spacetime argument needs to be in the form: [positionX positionY positionZ time]');
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Sets the values for the basic variables.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    filePathDAILYPLT = fullfile('resources', 'DAILYPLT.ADJ');
    
    filePathDataHorizonsEarth = fullfile('resources', 'dataHorizonsEarth.mat');
    
    earthSiderealPeriod = 365.256;
    
    earthSunFaceAlignmentPeriod = 27;
    
    sunFaceRotationPeriod = earthSiderealPeriod*earthSunFaceAlignmentPeriod / (earthSiderealPeriod+earthSunFaceAlignmentPeriod);
    
    C  = 299792458;
    AU = 149597870691;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Reads the DAILYPLT.ADJ file.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fileID = fopen(filePathDAILYPLT, 'r');
        
        scan = textscan(fileID, '%f', 'Delimiter', '+');
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %   scan{1}: Time (number) and Flux - (mixed)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        scanLength = length(scan{1});
        
    fclose(fileID);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Sorts the information read from the DAILYPLT.ADJ file for data 
    %     belonging to year 1980+, so that times are assigned to 
    %     "timeDailyplt" and flux values to "fluxAdjDailyplt".
    %   * Fills in missing flux values by linear interpolation from 
    %     existing flux values.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    timeDailyplt    = zeros(scanLength,1);
    fluxAdjDailyplt = zeros(scanLength,1);
    
    dataCounter = 0;
    gapCounter = 0;
    
    for scanRow = 1:scanLength-1

        if scan{1}(scanRow) > 19800000
            
            if scan{1}(scanRow+1) < 19000000
                
                if gapCounter > 0
                    
                    indexDifference = scan{1}(scanRow+1) - scan{1}(scanRow-1-gapCounter);
                    
                    indexStep = indexDifference / (gapCounter+1);
                    
                    for gapRow = 1:gapCounter
                            
                        dataCounter = dataCounter + 1;
                            
                        timeDailyplt(dataCounter)    = scan{1}(scanRow-1-gapCounter+gapRow);
                        fluxAdjDailyplt(dataCounter) = scan{1}(scanRow-1-gapCounter) + gapRow*indexStep;
                    end
                end
                
                dataCounter = dataCounter + 1;
                
                timeDailyplt(dataCounter)    = scan{1}(scanRow);
                fluxAdjDailyplt(dataCounter) = scan{1}(scanRow+1);
                
                gapCounter = 0;
                
            else
                
                gapCounter = gapCounter + 1;
            end
        end
    end
    
    clear scan;
    
    dataDailypltLength = dataCounter;
    
    timeDailyplt(dataDailypltLength+1:scanLength) = [];
    timeDailyplt = datenum(num2str(timeDailyplt), 'yyyymmdd')+20/24;
    
    fluxAdjDailyplt(dataDailypltLength+1:scanLength) = [];
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Loads the variables from the dataHorizonsEarth.mat file.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    load(filePathDataHorizonsEarth);
    	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   dataHorizonsGeneratedEarth: Time (string)
        %
    	%   dataHorizonsEarth{1}: Times (datenum)
    	%   dataHorizonsEarth{2}: Postions (X)
    	%   dataHorizonsEarth{3}: Postions (Y)
    	%   dataHorizonsEarth{4}: Postions (Z)
    	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    dataHorizonsLength = length(dataHorizonsEarth{1});
    
    spaceHorizons = [dataHorizonsEarth{2} dataHorizonsEarth{3} dataHorizonsEarth{4}];
    timeHorizons  = dataHorizonsEarth{1};
    
    clear dataHorizonsEarth;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * If the function call was an info request, then the info is given
    %     and the function ended.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargin == 0
        
        firstTime = datestr(timeHorizons(1)                 , 'yyyy-mm-dd');
        lastTime  = datestr(timeHorizons(dataHorizonsLength), 'yyyy-mm-dd');
        
        display(' ');
        display('Earth spacetime data is available for the time span:');
        display(' ');
        display(horzcat(firstTime, '  -  ', lastTime))
        display(' ');
        display('The spacetime data was generated from a Horizons file retrieved:');
        display(' ');
        display(strcat(dataHorizonsGeneratedEarth));
        display(' ');
        
        firstTime = datestr(timeDailyplt(1)                 , 'yyyy-mm-dd');
        lastTime  = datestr(timeDailyplt(dataDailypltLength), 'yyyy-mm-dd');
        
        display(' ');
        display('Earth flux data is available for the time span:');
        display(' ');
        display(horzcat(firstTime, '  -  ', lastTime))
        display(' ');
        
        display(' ');
        display('It should be noted that the calculations might need as');
        display('much as a month of buffer time from these extremeties.');
        display(' ');
        
        return;
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Separates space and time and adjusts the time to take into
    %     account for the travel time of light.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    space = spacetime(:,1:3);
    time  = spacetime(:,4) - (sqrt(sum(space.^2,2))-1)*AU/(24*3600*C);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Finds the indices in the horizon data that corresponds to the 
    %     times no later than the times supplied.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    spacetimeLength = spacetimeDimnsions(1);
    
    indices = zeros(spacetimeLength,1);
    
    for timeCounter = 1:spacetimeLength
        
        index = find(timeHorizons <= time(timeCounter), 1, 'last');
        
        if isempty(index) || (index == dataHorizonsLength)
            
            error('The spacetime argument entered requires data beyond of that available.');
        else
            
            indices(timeCounter) = index;
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Earths position at the times supplied.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    spaceEarth = spaceHorizons(indices,:) + (spaceHorizons(indices+1,:) - spaceHorizons(indices,:)) .* (( (time-timeHorizons(indices)) ./ (timeHorizons(indices+1)-timeHorizons(indices)) )*ones(1,3));
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * The angle between the spacetimes supplied and Earth.
    %   * Determination of the sign of the angle.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    angleEarth = atan2(space(:,1).*spaceEarth(:,2)-space(:,2).*spaceEarth(:,1), space(:,1).*spaceEarth(:,1)+space(:,2).*spaceEarth(:,2));
    
    angleEarthSign = sign(angleEarth);
    
    indices = find(angleEarthSign == 0);
    
    if ~isempty(indices)
        
        angleEarthSign(indices) = 1;
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * The two adjacent times when the Earth will see the same face
    %     of the sun as the spacetime does.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    timeClose = time + angleEarth/(2*pi) * sunFaceRotationPeriod*earthSiderealPeriod/(earthSiderealPeriod-sunFaceRotationPeriod);
    timeFar   = timeClose - angleEarthSign * earthSunFaceAlignmentPeriod;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * Finds the indices in the Dailyplt data that corresponds to the
    %     times no later than the times timeClose and timeFar.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    indicesClose = zeros(spacetimeLength,1);
    indicesFar   = zeros(spacetimeLength,1);
    
    for timeCounter = 1:spacetimeLength
        
        indexClose = find(timeDailyplt <= timeClose(timeCounter), 1, 'last');
        indexFar   = find(timeDailyplt <= timeFar(timeCounter)  , 1, 'last');
        
        if isempty(indexClose) || isempty(indexFar) || (indexClose == dataDailypltLength) || (indexFar == dataDailypltLength)
            
            error('The spacetime argument entered requires data beyond of that available.');
        else
            
            indicesClose(timeCounter) = indexClose;
            indicesFar(timeCounter)   = indexFar;
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * The flux values for times timeClose and timeFar.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fluxAdjClose = fluxAdjDailyplt(indicesClose) .* (1-(timeClose-timeDailyplt(indicesClose))./(timeDailyplt(indicesClose+1)-timeDailyplt(indicesClose))) + fluxAdjDailyplt(indicesClose+1) .* (1-(timeDailyplt(indicesClose+1)-timeClose)./(timeDailyplt(indicesClose+1)-timeDailyplt(indicesClose)));
    
    fluxAdjFar   = fluxAdjDailyplt(indicesFar)   .* (1-(timeFar  -timeDailyplt(indicesFar)  )./( timeDailyplt(indicesFar +1)-timeDailyplt(indicesFar)  )) + fluxAdjDailyplt(indicesFar+1)   .* (1-(timeDailyplt(indicesFar  +1)-timeFar  )./(timeDailyplt(indicesFar  +1)-timeDailyplt(indicesFar)  ));
	
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   * The estimated flux values for the supplied spacetimes.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fluxAdj = fluxAdjClose .* (1-abs(timeClose-time)/earthSunFaceAlignmentPeriod) + fluxAdjFar .* (1-abs(timeFar-time)/earthSunFaceAlignmentPeriod);
    
    flux = fluxAdj ./ sum(space.^2,2);
    
    varargout(1) = {flux};
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%