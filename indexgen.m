% indexgen.m -- Make useful index 

% anders.eriksson@irfu.se 2012-03-29

% Read PSA index file:
str = sprintf('%s/INDEX/INDEX.TAB',archivepath);
% tmp = importdata(str,'"');
% iname = tmp.textdata(:,2);    % List of label files
ilp = fopen(str);  
tmp=textscan(ilp,'%s %*s %*s %*s %*s %*s','Delimiter',',');
iname = strtrim(char(tmp{1}));  % Clean away leading/trailing blanks
% clear tmp;
if iname(1,1) == '"'
   % Clean away double quotes
   iname(:,1) = '';
end
[r,c] = size(iname);
if iname(1,c) == '"'
   % Clean away double quotes
   iname(:,c) = '';
end
fclose(ilp);

iname = sortrows(iname);  % Special as old index file for ESB1 is not in chronological order

nprel = length(iname);  % Preliminary length

% Remove HK and GEOM files:
blacklist = [];
for(i=1:nprel)
    lname = deblank(sprintf('%s/%s',archivepath,iname(i,:)));
    if(findstr(lname,'H.LBL') | findstr(lname,'GEOM'))
        blacklist = [blacklist; i];
    end
end
if(~isempty(blacklist))
    iname(blacklist,:) = [];
end

n = length(iname);

% Create array to save extended index in:
index(n).lblfile = [];
index(n).tabfile = [];
index(n).t0str = [];
index(n).t1str = [];
index(n).sct0str = [];
index(n).sct1str = [];
index(n).macrostr = [];
index(n).t0 = -1;
index(n).t1 = -1;
index(n).macro = -1;
index(n).lf = -1;
index(n).hf = -1;
index(n).sweep = -1;
index(n).probe = -1;

i = 0;
for ii=1:n  % Loop the label files
    %i % Print to see where we are in the processing
    
    if mod(i,1000) ==0
        fprintf(1,'index generation loop #%i out of%i\n ',i,n)
    end
        
    % Path to label file:
    lname = deblank(sprintf('%s/%s',archivepath,iname(ii,:)));
    % 'deblank' strips off some trailing blanks sometimes turning up and causing problems
    if(isempty(findstr(lname,'H.LBL')) && isempty(findstr(lname,'GEOM')) && ~isempty(lname))  
    % Ignore HK and geometry files as well as spurious blank entries
      % Read label file as variable-value pairs:
      [fp,errmess] = fopen(lname,'r');
      if(isempty(errmess)) %if INDEX.TAB does not correspond to an actual file (quick fix of bug)
            
          i = i+1; % Note that we cannot use ii as index, as we want to get rid of blanks etc.
          tname = strrep(lname,'LBL','TAB');
          lbl = textscan(fp,'%s %s','Delimiter','=');
          fclose(fp);
          var = cellstr(char(lbl{1}));
          val = char(lbl{2});
          % Find macro:
          ind = find(strcmp('INSTRUMENT_MODE_ID',var));
          macrostr = val(ind,:);
          %macro = sscanf(macrostr,'%7*c%f');
          macro = str2num(macrostr(8:10));
          % Find start time:
          ind = find(strcmp('START_TIME',var));
          t0str = val(ind,:);
          t0 = datenum(strrep(t0str,'T',' '));
          % Find end time:
          ind = find(strcmp('STOP_TIME',var));
          t1str = val(ind,:);
          t1 = datenum(strrep(t1str,'T',' '));
          % Find start s/c time:
          % strtrim removes blanks from the end, otherwise a problem
          ind = find(strcmp('SPACECRAFT_CLOCK_START_COUNT',var));
          sct0str = strtrim(val(ind,:));
          % Find end s/c time:
          ind = find(strcmp('SPACECRAFT_CLOCK_STOP_COUNT',var));
          ind22 = strcmp('SPACECRAFT_CLOCK_STOP_COUNT',var);
          sct1str = strtrim(val(ind,:));
          
          % Analyze file name for type of data:
          yymmdd = strcat(t0str(3:4),t0str(6:7),t0str(9:10));;
          str = sprintf('RPCLAP%s',yymmdd);
          base = strfind(lname,str);  % This finds file name start also in case path name contains RPCLAP
          efield = strcmp(lname(base+19),'E');

          probe = str2num(lname(base+21));
          if(lname(base+16) == 'S')
            lf = 0;
            hf = 1;
          elseif(lname(base+16) == 'T')
            lf = 1; 
            hf = 0;
          else
            fprintf(1,'  BAD ADC IDENTIFIER FOUND, %s\n',lname);
          end
          
          sweep = strcmp(lname(base+20),'S'); 
          % if sweep ==1, then the file is NOT a lf or hf file.
          if (sweep)
              lf =  0; %% should be unnecessary, no sweeps are lf...       
              hf = 0;
          end
          
          % % File assumed to contain LF data if covering more than 16 s:
          % lf = (t1-t0 > 16/86400) & ~sweep;  
          % hf = ~(lf | sweep);

          % Collect index:
          
          
          
          index(i).lblfile = lname;
          index(i).tabfile = tname;
          index(i).t0str = t0str;
          index(i).t1str = t1str;
          index(i).sct0str = sct0str;
          index(i).sct1str = sct1str;
          index(i).macrostr = macrostr;
          index(i).t0 = t0;
          index(i).t1 = t1;
          index(i).macro = macro;
          index(i).lf = lf;
          index(i).hf = hf;
          index(i).sweep = sweep;
          index(i).efield = efield;
          index(i).probe = probe;
         
          
          
      end %end of fopen error message constraint
    end % End of if-not-HK
end

% The number of filled index entries are now i, while n was the number
% allocated. Remove the unfilled ones.
if(n > i)
    index((i+1):n) = [];
end


% Clear up and save:
% clear lname t0str t1str macrostr macro t0 t1 lf sweep efield probe;
%save(indexfile,'index'); done after indexcorr

% End of indexgen.m
