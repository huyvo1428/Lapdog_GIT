% main -- LAP Dataset Overview and Geometry (lapdog) main file
%
% LAP DERIVED ARCHIVE GENERATION
% anders.eriksson at  irfu.se 2012-03-29
% frejon at irfu.se 2014-05-07
%
%For batch mode execution via script, to execute local execution in Matlab, see main.m
%
%
% Quick description
% 1. The program is designed to be called by a script, and somewhat controlled in batch_control.m, with no other user
%    input necessary
% 2. preamble defines some variables used everywhere in the script
% 3. indexgen reads every .LBL file in the archive (50% of all files) as
%    specified from the index.dat file in outputs it into a useful "index"
%    variable
% 4. some post-processing of the index is needed in indexcorr to split files
%    exactly at midnight, OBS some files created in temp/ folder,
% 5. generates daily geometry files
% 6. Seperates all files into macro operation blocks, each block terminated
%    by midnight or new macroid
% 7. process reads all data, and mills it into new, condensed files
% ** information of each new file is stored in "tabindex" variable
% 8. an_IV analyses sweeps, wave snapshots (spectra), and downsamples data for
%    quick-look plots and stores them in files
% ** information of each new file is stored in "an_tabindex" variable
% 9. createLBL produces .LBL files for each generated file  (PDS archive
%    specific file type)
%
function [] = edder_lapdog(archpath, archID, missioncalendar)



fprintf(1,'LAPDOG - LAP Data Overview and Geometry \n')



% fprintf(1,'lapdog: Reading pds.conf\r ')

batch_control;

derivedpath = strrep(archivepath,'RPCLAP-2','RPCLAP-99');
derivedpath = strrep(derivedpath,'EDITED','EDDER');

% Set up PDS keywords etc:

fprintf(1,'lapdog: calling preamble...\n')

preamble;

% Load or, if not defined, generate index:
% fprintf(1,'lapdog: load indices if existing...')
dynampath= mfilename('fullpath'); %find path & remove/lapdog from string
dynampath = dynampath(1:end-13);

fprintf(1,'lapdog: %s\n',dynampath)

indexfile = sprintf('%s/index/index_%s.mat',dynampath,archiveid);
fp = fopen(indexfile,'r');
if(fp > 0)
     fclose(fp);
     load(indexfile);
else
    
    fprintf(1,'lapdog: calling indexgen\n')    
    indexgen;
    fprintf(1,'lapdog: splitting files at midnight..\n')   
    indexcorr;
    
    
    folder= sprintf('%s/index',dynampath);
    if exist(folder,'dir')~=7
        mkdir(folder);
    end
    

    save(indexfile,'index');
end


% Generate daily geometry files:
if(do_geom)
    fprintf(1,'lapdog: calling geometry...\n')
    geometry;
end

% Generate block list file:

fprintf(1,'lapdog: calling opsblocks...\n')
opsblocks;

tabindexfile = sprintf('%s/tabindex/tabindex_%s.mat',dynampath,archiveid);
%     fp = fopen(tabindexfile,'r');
%     if(fp > 0)
%         fclose(fp);
%         load(tabindexfile);
%         fprintf(1,'lapdog: successfully loaded tabfiles...\n')
%     else

fprintf(1,'lapdog: calling process...\n')
edder_process;


folder= sprintf('%s/tabindex',dynampath);
if exist(folder,'dir')~=7
    mkdir(folder);
end

save(tabindexfile,'tabindex');
%end



%edder_analysis; Let's not.



fprintf(1,'lapdog: generate LBL files....\n')
createLBL;


fprintf(1,'lapdog: DONE!\n')

end

% End of main.m
