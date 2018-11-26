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
tic

% Define the dataset:
'lapdog: calling control...'
control;

% Set up PDS keywords, constants etc:
'lapdog: calling preamble...'
preamble;



% Load or, if not defined, generate index:
'lapdog: load indices if existing...'

indexversion = '2'; %index updated with a new variable 17Dec 2014
indexfile = sprintf('index/index_%s_v%s.mat',archiveid,indexversion);

if index_cache_enabled & (exist(indexfile) == 2) & exist(derivedpath, 'dir')
    load(indexfile);
else
    'lapdog: calling indexgen...'
    indexgen;
    'lapdog: splitting files at midnight..'
    indexcorr;
    save(indexfile,'index');
end



%--------------------------------------------------
% Debugging code for only keeping a specific date?
%--------------------------------------------------
% i_keep = [];
% for i = 1:length(index)    
%     if ~isempty(strfind(index(i).lblfile, '/2014/AUG/D17/'))
%         i_keep(end+1) = i;
%     end
%     if isempty(strfind(index(i).lblfile, '/home/erjo/LAP_ARCHIVE_test/RO-C-RPCLAP-3-1408-CALIB-V0.3/'))
%         ''
%     end
%     
%end
%index = index(i_keep);
%-------------------------------------------------


scResetCount=str2double(index(1).sct0str(2));

% Generate daily geometry files:
if(do_geom)
  'lapdog: calling geometry...'
  geometry;
end

% Generate block list file:
'lapdog: calling opsblocks...'
opsblocks;

tabindexfile = sprintf('tabindex/tabindex_%s.mat',archiveid);

if tabindex_cache_enabled & (exist(tabindexfile) == 2)
    load(tabindexfile);
    'lapdog: successfully loaded tabfiles'
else
    'lapdog: calling process...'
    process;  
  
    if exist('tabindex','dir')~=7
        mkdir('tabindex');
    end
    save(tabindexfile,'tabindex');
end



analysis;



'lapdog: generate LBL files....'
createLBL(1,1)



'lapdog: Parmesan -Done!'
toc
% End of main.m

