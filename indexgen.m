% indexgen.m -- Make useful index
%
% anders.eriksson@irfu.se 2012-03-29
% edited by frejon@irfu.se 2014-05-01
%
%Make sure an old index doesn't interfere with the new one
if exist('index','var')==1
    clear index
end


% Read PSA index file:
str = sprintf('%s/INDEX/INDEX.TAB',archivepath);
% tmp = importdata(str,'"');
% iname = tmp.textdata(:,2);    % List of label files
ilp = fopen(str);


if ilp < 0
    fprintf(1,'Error, cannot open file %s\n', str);
    return;%break
end % if I/O error


tmp=textscan(ilp,'%s %*s %*s %*s %*s %*s','Delimiter',',');

if isempty(tmp{1})
	fprintf(1,'Error- Empty file  %s\n', str);
    return;%break
end


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
    preldate=str2double(lname(end-22:end-17));


    if preldate < 040101
        blacklist = [blacklist; i];
        fprintf(1,'index generation found file: %s \n before 2004-01-01(!) ignoring...\n',lname);
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
index(n).macro = -1; % (temporary invalid value). Correct value is defined as the macro number interpreted as a hexadecimal number (not decimal number).
index(n).lf = -1;
index(n).hf = -1;
index(n).sweep = -1;
index(n).probe = -1;
index(n).pre_sweep_samples =-1;

macrotemp= '41000';


i = 0;

for ii=1:n  % Loop the label files
    %i % Print to see where we are in the processing

    if mod(i,5000) ==0
        fprintf(1,'Index generation loop #%i out of %i\r',i,n)
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
          macro = hex2dec(macrostr(8:10));
          if isnan(macro)
              warning('Can not interpret macro number from macro string (INSTRUMENT_MODE_ID).')
          end



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
%          ind22 = strcmp('SPACECRAFT_CLOCK_STOP_COUNT',var);
          sct1str = strtrim(val(ind,:));

          % Analyze file name for type of data:
          yymmdd = strcat(t0str(3:4),t0str(6:7),t0str(9:10));
          str = sprintf('RPCLAP%s',yymmdd);
          base = strfind(lname,str);  % This finds file name start also in case path name contains RPCLAP
          efield = strcmp(lname(base+19),'E');

          probe = str2double(lname(base+21));
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
              lf = 0; %% should be unnecessary, no sweeps are lf...
              hf = 0;

              %update: sweep files have "initial sweep smpls" which is a
              %very useful variable.


              %update 2. erik changed keyword to be probe specific...
              % ind = find(strcmp('ROSETTA:LAP_INITIAL_SWEEP_SMPLS',var));


              cstr= sprintf('ROSETTA:LAP_P%1d_INITIAL_SWEEP_SMPLS',probe);
              ind = find(strcmp(cstr,var));
              %          ind22 = strcmp('SPACECRAFT_CLOCK_STOP_COUNT',var);
              if(~isempty(ind))

                  str = strrep(strtrim(val(ind,:)),'"',''); %trim and strip from ""
                  if(~isempty(str))
                      in_smpls = hex2dec(str(end-3:end)); %only need maximum last three, convert from hex to dec.
                  else
                      %str
                      in_smpls=0;
                  end
              else
                  %Edit FKJN 8/8 2016. follow up bug due to INITIAL_SWEEP_SMPLS problem. 
                  in_smpls=0;     
                  i = i -1 ; % revert counter
                 fprintf(1,'strangeness in sweep file, _INITIAL_SWEEP_SMPLS = not found, skipping file %s.\r',lname)
                 continue %back to next iteration of nearest for loop (line 95), ignore everythin below
              end

              %FKJN edit 28/6 2016
              if in_smpls >  400 % I hope this is enough of a ridiculous number
                i = i -1 ; % revert counter
                fprintf(1,'Error in Index generation, _INITIAL_SWEEP_SMPLS = %i skipping file %s.\r',in_smpls,lname)
                continue %back to next iteration of nearest for loop (line 95), ignore everythin below
              end

              index(i).pre_sweep_samples =in_smpls; % start collecting index


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



      end %if I/O error
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
