% main -- LAP Dataset Overview and Geometry (lapdog) main file
%
% Create overview of LAP ops and geometry files for a given data set.

% anders.eriksson@irfu.se 2012-03-29
% frejon@irfu.se 2014-04-28



%For local execution via Matlab, to execute in batch mode, see lapdog.m


%Quick description
%1. The program is designed to be controlled in control.m, with no other user
% input necessary
%2. preamble defines some variables used everywhere in the script
%3.(Unless already done)
%indexgen reads every .LBL file in the archive (50% of all files) as 
%specified from the index.dat file in outputs it into a useful "index"
%variable
%4. some post-processing of the index is needed in indexcorr to split files
%exactly at midnight, OBS some files created in temp/ folder, 
%5.generates daily geometry files
%6. Seperates all files into macro operation blocks, each block terminated 
%by midnight or new macroid
%7. (unless already done)
%process reads all data, and mills it into new, condensed files
%** information of each new file is stored in "tabindex" variable
%8. an_IV analyses sweeps, wave snapshots (spectra), and downsamples data for
%quick-look plots and stores them in files
%** information of each new file is stored in "an_tabindex" variable
%9. createLBL produces .LBL files for each generated file  (PDS archive
%specific file type)
%



'LAPDOG - LAP Data Overview and Geometry'
''

% Define the dataset:

'lapdog: calling control...'
control;

% Set up PDS keywords etc:
'lapdog: calling preamble...'
preamble;

% Load or, if not defined, generate index:
'lapdog: load indices if existing...'
indexfile = sprintf('index/index_%s.mat',archiveid);
fp = fopen(indexfile,'r');

 fp = -1;

if(fp > 0)
    fclose(fp);
    load(indexfile);
else

    'lapdog: calling indexgen...'
    indexgen;
    'lapdog: splitting files at midnight..'
    indexcorr;
    save(indexfile,'index');
    
end


% Generate daily geometry files:
if(do_geom)
  'lapdog: calling geometry...'
  geometry;
end

% Generate block list file:
'lapdog: calling opsblocks...'
opsblocks;

if(do_mill)
tabindexfile = sprintf('tabindex/tabindex_%s.mat',archiveid);
fp = fopen(tabindexfile,'r');

 fp = -2;

if(fp > 0)
    fclose(fp);
    load(tabindexfile);
    'lapdog: succesfully loaded tabfiles'
    
else
'lapdog: calling process...'
  process;
  
  
  if exist('tabindex','dir')~=7
      mkdir('tabindex');
  end
 %  save(tabindexfile,'tabindex');
end


analysis;



    
    
'lapdog: generate LBL files....'
createLBL;

end




'lapdog: Parmesan -Done!'
% End of main.m
