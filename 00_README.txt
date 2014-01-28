LAPDOG -- LAP Dataset Overview and Geometry
===========================================

Matlab code to grind a LAP PDS archive, creating a daily geometry file and an overview of all operational blocks (period of continuous operation of a certain macro, breaks at day boundary).

Output:
- Geometry TAB and LBL files in directory geofiles 
- Index files (.mat format) in directory index
- Operation blocks list (ascii file) in directory blocklists

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

geometry.m -- uses Spice on vroom.umea.irf.se to generate daily geometry files

opsblocks.m -- makes a list macro_index.txt of operation blocks (continuous macro runs, breaking at midnight)
