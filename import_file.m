%% Convenient import of lap archive file
% Imports given lap archive file into struct with new, more accessible
% fields.
%%% Syntax
% s = |import_file(filename, macro)| returns a struct that contains, in
% addition to the "usual" fields produced by |MATLAB|'s |importdata|
% function, additional fields:
% For timeseries data, |sample_times|, |timeseries| (currents in column 1
% and potentials in column 2) and |macro|.
% For sweeps, |start_times|, |stop_times|, |sweeps| and |macro|.
% For spectra, |start_times|, |stop_times|, |spectra| and |macro|.
% Files such as |B1S| and |V1H_FRQ| that are not struct variables are
% unaffected and imports normally, as by MATLAB's |importdata| function.
function [out] = import_file(filename, varargin)
%%

%is this necessary? I thought
% [hello,delim,headerline] = importdata(filename)
% would find header lines and delim automatically (and store it in delim &
% headerline
if (~isempty(strfind(filename, 'A1S')) || ~isempty(strfind(filename, 'A2S')))
    temp = importdata(filename, ',', 1);
    a_flag = 1;
else
    a_flag = 0;
    
    temp = importdata(filename, ',', 0);
end
%%%
% Add new fields for struct variables:
if (isstruct(temp))
    
        
    
    
    if (size(temp.textdata, 2) == 2)
        temp.('start_times') = temp.textdata(:,1);
        temp.('stop_times') = temp.textdata(:,2);
        if (strfind(filename, 'PSD'))
            temp.('spectra') = temp.data(:,end-64:end);
        elseif (~isempty(strfind(filename, 'I1S')) || ...
                ~isempty(strfind(filename, 'I2S')))
            temp.('sweeps') = temp.data(:,4:end);
        end
    elseif (size(temp.textdata, 2) == 1)
        temp.('sample_times') = temp.textdata;
        if (size(temp.data, 2) == 4)
            temp.('timeseries') = temp.data(:,2:3);
        elseif (size(temp.data, 2) == 6 || size(temp.data, 2) == 5)
            temp.('timeseries') = temp.data(:,[2,4]);
        end
    end
%     if (~isempty(strfind(filename, 'A1S')) || ~isempty(strfind(filename, 'A2S')))
%         temp.('V_intersect') = temp.data(:,4);
%         temp.('V_inflect') = temp.data(:,16);
%         temp.('SAA') = temp.data(:,2);
%     end
    if (nargin > 1)
        macro = varargin{1};
        temp.macro = macro;
    end
    
    
    if a_flag
       % rows=length(temp.textdata(:,1))-1;
        
        temp2= [];
        
        for i=1:length(temp.textdata(1,:)) %for all columns on row 1
            str = cell2mat(strrep(temp.textdata(1,i),'.','_'));
            str = strrep(str,'(','_');
            str = strrep(str,')','');
            str = strrep(str,'=','');
            str = strrep(str,' ',''); %this will be the substruct name
            
            
            if i < 3 %first two columns should be textdata, input into new substruct
            %    temp2.(sprintf('%s',str))= {};
                temp2(:).(sprintf('%s',str))= temp.textdata(2:end,i);
        
            else %enter corresponding data into new substruct
             %   temp2.(sprintf('%s',str))= [];
                temp2(:).(sprintf('%s',str))= temp.data(:,i-2);
            end
            
            
        end
        
    clear temp
    temp = temp2;
        
    end
    
    out = temp;
elseif (~isempty(strfind(filename, 'B1S')) || ~isempty(strfind(filename, 'B2S')))
    out = struct('data', temp);
    out.('sample_times') = temp(:,1);
    out.('bias_potentials') = temp(:,2);
elseif (~isempty(strfind(filename, 'FRQ')))
    out = struct('data', temp);
    out.('sample_frequencies') = temp;
end

end

