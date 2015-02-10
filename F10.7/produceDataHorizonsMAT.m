function produceDataHorizonsMAT(targetBody, filePathHorizons)

% produceDataHorizonsEarthMAT()
%   
%   Where X is the targetBody string supplied:   
%
%   Produces a dataHorizonsX.mat file from a horizon file.
%
%   The mat file contains the variables "dataHorizonsGeneratedX" and
%   "dataHorizonsX". They have the following forms:
%
%   dataHorizonsGeneratedEarth = 'yyyy-mm-ddTHH:MM:SS'
%
%   dataHorizonsEarth = cell(1,4)
%       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%       %   dataHorizonsEarth{1}: Times (datenum)
%       %   dataHorizonsEarth{2}: Postions (X)
%       %   dataHorizonsEarth{3}: Postions (Y)
%       %   dataHorizonsEarth{4}: Postions (Z)
%       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%   Author: Martin Ulfvik
%   Usage: However the Swedish Institute of Space Physics sees fit.
%   $Revision: 1.00 $  $Date: 2009/03/27 12:42 $


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %   * Reads the horizon file.
   %   * Extracts relevant data.
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %Opens the file filePathHorizons with read permission only, calls the
   %open file fileID
   fileID = fopen(filePathHorizons, 'r');

       allheaderRowsFound = false;
       headerRows = 0;

       endDataFound = false;

       dataLength = 0;

       while ~allheaderRowsFound

           headerRows = headerRows +1;
           readLine = fgetl(fileID);

           if strncmp(readLine, 'Ephemeris / WWW_USER', 20)

               dataHorizonsGenerated = datestr(datenum(readLine(26:45), 'mmm dd HH:MM:SS yyyy'), 'yyyy-mm-ddTHH:MM:SS');
           end

           if strcmp(readLine, '$$SOE')

               allheaderRowsFound = true;
           end
       end

       while ~endDataFound

           readLine = fgetl(fileID);

           if strcmp(readLine, '$$EOE')

               endDataFound = true;

           else

               dataLength = dataLength + 1;
           end
       end

       frewind(fileID);

       dataHorizons = textscan(fileID, '%*s %s %f %f %f', dataLength, 'Delimiter', ',', 'HeaderLines', headerRows);
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           %   1: Time (string) - later converted to datenum
           %   2: Postion (X)
           %   3: Postion (Y)
           %   4: Postion (Z)
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fclose(fileID);


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %   * Converts the time in strings to time in datenum
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   temp = char(dataHorizons{1});
   temp = temp(:,6:29);

   dataHorizons{1} = datenum(temp, 'yyyy-mmm-dd HH:MM:SS.FFF');
   clear temp;


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %   * Generates the mat file based on the target body input.
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   switch targetBody

       case 'Earth'

           dataHorizonsGeneratedEarth = dataHorizonsGenerated;
           dataHorizonsEarth = dataHorizons;
           save('dataHorizonsEarth.mat', 'dataHorizonsEarth', 'dataHorizonsGeneratedEarth');

       case 'Jupiter'

           dataHorizonsGeneratedJupiter = dataHorizonsGenerated;
           dataHorizonsJupiter = dataHorizons;
           save('dataHorizonsJupiter.mat', 'dataHorizonsJupiter', 'dataHorizonsGeneratedJupiter');

       case 'Mars'

           dataHorizonsGeneratedMars = dataHorizonsGenerated;
           dataHorizonsMars = dataHorizons;
           save('dataHorizonsMars.mat', 'dataHorizonsMars', 'dataHorizonsGeneratedMars');

       case 'Mercury'

           dataHorizonsGeneratedMercury = dataHorizonsGenerated;
           dataHorizonsMercury = dataHorizons;
           save('dataHorizonsMercury.mat', 'dataHorizonsMercury', 'dataHorizonsGeneratedMercury');

       case 'Neptune'

           dataHorizonsGeneratedNeptune = dataHorizonsGenerated;
           dataHorizonsNeptune = dataHorizons;
           save('dataHorizonsNeptune.mat', 'dataHorizonsNeptune', 'dataHorizonsGeneratedNeptune');

       case 'Saturn'

           dataHorizonsGeneratedSaturn = dataHorizonsGenerated;
           dataHorizonsSaturn = dataHorizons;
           save('dataHorizonsSaturn.mat', 'dataHorizonsSaturn', 'dataHorizonsGeneratedSaturn');

       case 'Uranus'

           dataHorizonsGeneratedUranus = dataHorizonsGenerated;
           dataHorizonsUranus = dataHorizons;
           save('dataHorizonsUranus.mat', 'dataHorizonsUranus', 'dataHorizonsGeneratedUranus');

       case 'Venus'

           dataHorizonsGeneratedVenus = dataHorizonsGenerated;
           dataHorizonsVenus = dataHorizons;
           save('dataHorizonsVenus.mat', 'dataHorizonsVenus', 'dataHorizonsGeneratedVenus');

       case 'ChuryumovGerasimenko'

           dataHorizonsGeneratedChuryumovGerasimenko = dataHorizonsGenerated;
           dataHorizonsChuryumovGerasimenko = dataHorizons;
           save('dataHorizonsChuryumovGerasimenko.mat', 'dataHorizonsChuryumovGerasimenko', 'dataHorizonsGeneratedChuryumovGerasimenko');

       case 'Steins'

           dataHorizonsGeneratedSteins = dataHorizonsGenerated;
           dataHorizonsSteins = dataHorizons;
           save('dataHorizonsSteins.mat', 'dataHorizonsSteins', 'dataHorizonsGeneratedSteins');

       case 'Cassini'

           dataHorizonsGeneratedCassini = dataHorizonsGenerated;
           dataHorizonsCassini = dataHorizons;
           save('dataHorizonsCassini.mat', 'dataHorizonsCassini', 'dataHorizonsGeneratedCassini');

       case 'Rosetta'

           dataHorizonsGeneratedRosetta = dataHorizonsGenerated;
           dataHorizonsRosetta = dataHorizons;
           save('dataHorizonsRosetta.mat', 'dataHorizonsRosetta', 'dataHorizonsGeneratedRosetta');

       otherwise

           error('Invalid target body name supplied.');
   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%