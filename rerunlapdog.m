%LAP DERIVED ARCHIVE GENERATION
% anders.eriksson@irfu.se 2012-03-29
% frejon@irfu.se 2014-05-07
%
%For batch mode execution via script, to execute local execution in Matlab, see main.m
%if the calibrated and derived archive is already in /data/LAP_ARCHIVE/
%
%Quick description
%1. The program is designed to be called by a script, and somewhat controlled in batch_control.m, with no other user
% input necessary
%2. preamble defines some variables used everywhere in the script
%3.
%indexgen reads every .LBL file in the CALIB archive (50% of all files) as
%specified from the index.dat file in outputs it into a useful "index"
%variable
%4. some post-processing of the index is needed in indexcorr to split files
%exactly at midnight, OBS some files created in temp/ folder,
%5.generates daily geometry files
%6. Seperates all files into macro operation blocks, each block terminated
%by midnight or new macroid
%7.
%process reads all data, and mills it into new, condensed files
%** information of each new file is stored in "tabindex" variable
%8. an_IV analyses sweeps, wave snapshots (spectra), and downsamples data for
%quick-look plots and stores them in files
%** information of each new file is stored in "an_tabindex" variable
%9. createLBL produces .LBL files for each generated file  (PDS archive
%specific file type)
%

function [] = rerunlapdog(archpath, archID, missioncalendar,redo_resampling)

redo_resampling = str2double(redo_resampling);


fprintf(1,'LAPDOG - LAP Data Overview and Geometry \n');



% fprintf(1,'lapdog: Reading pds.conf\n ')
batch_control;

% Set up PDS keywords etc:

fprintf(1,'lapdog: calling preamble...\n');

preamble;

% Load or, if not defined, generate index:
% fprintf(1,'lapdog: load indices if existing...')
dynampath= mfilename('fullpath'); %find path & remove/lapdog from string
dynampath = dynampath(1:end-12);

fprintf(1,'lapdog: %s\n',dynampath);


if redo_resampling ~= 0
    
    fprintf(1, 'loading index....\n',dynampath);
    indexversion = '2'; %index updated with new variable 17Dec 2014
    indexfile = sprintf('%s/index/index_%s_v%s.mat',dynampath,archiveid,indexversion);
    %indexfile = sprintf('%s/index/index_%s.mat',dynampath,archiveid);
    fp = fopen(indexfile,'r');
    


    if(fp > 0)
        fclose(fp);
        load(indexfile);
        fprintf(1, 'lapdog: succesfully loaded server index\n');
        
        
        substring = '/data/LAP_ARCHIVE/cronworkfolder/';
        newstring= '/data/LAP_ARCHIVE/';
        fprintf(1,'replacing substrings...\n');
        
        index = struct_string_replace(index,substring,newstring); %separate code
        
        
    else
        
        fprintf(1,'lapdog: calling indexgen\n');
        indexgen;
        fprintf(1,'lapdog: splitting files at midnight..\n');
        indexcorr;
        
        
        folder= sprintf('%s/index',dynampath);
        if exist(folder,'dir')~=7
            mkdir(folder);
        end
        
        
        save(indexfile,'index');
    end
    
    
    
    
    % Generate daily geometry files:
    if(do_geom)
        fprintf(1,'lapdog: calling geometry...\n');
        geometry;
    end
    
    % Generate block list file:
    
    fprintf(1,'lapdog: calling opsblocks...\n');
    opsblocks;
    

end


% Resample data
tabindexfile = sprintf('%s/tabindex/tabindex_%s.mat',dynampath,archiveid);
fp = fopen(tabindexfile,'r');
%if(redo_resampling>0)
%    fprintf(1,'lapdog: redoing resampled archive...\n');
%
%    fclose(fp);
%    fp=-1;
%end

if(fp > 0)
    fclose(fp);
    load(tabindexfile);
    fprintf(1,'lapdog: succesfully loaded tabfiles...\n');
    
    
    substring = '/data/LAP_ARCHIVE/cronworkfolder/';
    newstring= '/data/LAP_ARCHIVE/';
    %	substring = strrep(tabindex(1,1),tabindex(1,2),'');
    %	tabindexsubstring= substring{1,1}(1:end-42);
    %	newstring= '/Users/frejon/Documents/RosettaArchive/PDS_Archives/DATASETS/SECOND_DELIVERY_VERSIONS/';
    fprintf(1,'replacing substrings in tabindex...\n');
    tabindex(:,1) = cellfun(@(x) strrep(x,substring,newstring),tabindex(:,1),'un',0);
    
else
    
    fprintf(1,'lapdog: calling process...\n');
    process;
    
    
    folder= sprintf('%s/tabindex',dynampath);
    if exist(folder,'dir')~=7
        mkdir(folder);
    end
    
    save(tabindexfile,'tabindex');
end


%analyse

if(redo_resampling<3) %overload variable for skipping analysis
	analysis;
end


%create all LBL files
fprintf(1,'lapdog: generate LBL files....\n');
createLBL;



fprintf(1,'lapdog: DONE!\n');

end

% End of main.m
