
Hourly
========================

## Overview:
Simple test suite used to develop hourly load shape analysis for htap

## Contents:

  - `hourly.run`: First test case 
  - Other files to be added as needed.
  
## Example Usage:

     C:\HTAP\htap-prm.rb -o C:\HTAP\HTAP-options.json -r hourly.run -v -t 5 -j -k 

## Typical output:

      __________________________________________________________________________________________________
      = htap-prm: A simple parallel run manager for HTAP ===============================================
      
       GitHub source:
          - Branch:   hourly-load-shapes
          - Revision: 833dc3d
      
       Initialization:
          - Reading HTAP run definition from .\hourly.run...  done.
          - Evaluating combinations for mesh run
      
                * 1          (options for Location)
                * 1          (options for Archetypes)
                * 1          (options for Rulesets)
                ----------------------------------------------------------
                 1               Total combinations
      
          - Creating mesh run for 1 combinations --- 1 combos created.
          - Guesstimated time requirements ~ 30 seconds (including pre- & post-processing)
          - Deleting prior HTAP-work directories...  done.
          - Deleting prior HTAP-sim directories...  done.
          - Preparing to process 1 generated combinations using 5 threads
      
      
      __________________________________________________________________________________________________
      = htap-prm: Begin Runs ===========================================================================
      
         + Batch 1 ( 0.0% done, 0/1 files processed so far ...)
           - Starting thread 1/1 for sim #1 (PID 14308)... done.
           - Waiting on PID: 14308 (1/1)... done.
           - Reading results files from PID: 14308 (1/1)... done.
           - Post-processing results:
              -> Writing csv output output to HTAP-prm-output.csv ... done.
              -> Writing JSON output to HTAP-prm-output.json... done.
           - Batch processing time: 14 seconds.
      
       - HTAP-prm: runs finished -------------------------
      
       - Deleting working directories... done.
      
       - HTAP-prm: Run complete -----------------------
      
          + 1 files were evaluated successfully.
      
          + 0 files failed to run
      
      __________________________________________________________________________________________________
      = htap-prm: Run Summary ==========================================================================
      
       Total processing time: 16.18 seconds
       -> Informational messages:
      
         (nil)
      
       -> Warning messages:
      
         (nil)
      
       -> Error messages:
      
         (nil)
      
       STATUS: Task completed successfully
      ==================================================================================================

      
## Results 
 
- Detailed results are available in file HTAP-prm-output.json. 
- `.choice` files, log files and `.h2k` input files for failed runs are saved in folders `HTAP-sim-X`.