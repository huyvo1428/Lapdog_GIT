LAPDOG -- LAP Dataset Overview and Geometry
===========================================

Matlab code to grind a LAP PDS Calibrated archive, generating a full Derived archive. 

two modes of executions: main.m or lapdog.m (for script execution)


Outdated info:
Matlab code to grind a LAP PDS archive, creating a daily geometry file and an overview of all operational blocks (period of continuous operation of a certain macro, breaks at day boundary)

Output:
- Geometry TAB and LBL files in directory geofiles 
- Index files (.mat format) in directory index
- Tabindex files in directory tabindex
- Temporary files, in temp/, can be deleted after execution, but only if index/ & tabindex /files are also deleted

- Derived archive, same folder as calibrated archive path



To add geometry files to an archive, you need:
 (1) a user on vroom.umea.irf.se
 (2) write permission on the archive to which you wish to add geometry files

To run:

1. Edit control.m to define which archive to use by uncommenting/adding the appropriate lines in control.m, and provide some other information.

2. Run main. You will be asked if you wish to export the resulting geometry files to archive, in which case they will be placed in the appropriate directories. This works only if you have write permission in the archive.

3. If your ssh is not properly set up (ssh-add not run) you may have to supply your password on vrooom.umea.irf.se twice for each day in the archive.

4. Run PVV on the archive! Otherwise the files created by LAPDOG are not included in the PSA INDEX files.

Routines used by main:

control.m -- input settings by the user

preamble.m -- define PDS keywords etc

indexgen.m -- generates index file if not already existing (remove old index files from index directory if you wish to force index generation)

indexcorr.m — separates data points that cross midnight, fixes index

geometry.m -- uses Spice on vroom.umea.irf.se to generate daily geometry files

opsblocks.m -- makes a list macro_index.txt of operation blocks (continuous macro runs, breaking at midnight)

process.m —- loops each block, generates resampled data ( step 4 in PDS archive)

createTAB.m — daughter process of process.m, writes files.

analysis.m —executes sweep, spectra and downsampling generation and/or analysis (step 5 “DERIVED” in PDS archive)

an_swp2.m —generates sweep analysis files, many subroutines

an_hf —- generates PDS spectra of wave snapshots

an_downsample —-  generates downsampled low frequency file 

createLBL.m —- generates LBL files for each TAB file created





