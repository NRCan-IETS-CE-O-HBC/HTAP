# A Quick start guide for using HTAP #

Before following this guide, you must first install HTAP using the 
instructions in `HTAP-installation.md`. All examples in this guide use the files located in `HTAP\doc\examples\`.

[TOC]

## HOW TO: use `htap-prm.rb` for batch HOT2000 processing

`HTAP-prm.rb` is a parallel run manager that can configure and dispatch multiple HOT2000 
simulations over parallel threads, and recover their output. For input, you must 
supply `htap-prm.rb` with a `.run` file, which contains pointers to other databases 
that HTAP should use, configuration options for the analysis, and instructions for changing hot2000 files. 

To start an HTAP run, use the following command:

    > htap-prm.rb -r [run-file] -v -c

#### Example:

```
C:\HTAP\doc\examples> C:\htap\htap-prm.rb -r example.run -c -v
```

#### Output: 

```
_______________________________________________________________________________________________
= htap-prm: A simple parallel run manager for HTAP ============================================

 GitHub source:
    - Branch:   General-dev
    - Revision: 5d4cca6

 Initialization:
    - Reading HTAP run definition from example.run...  done.
    - Evaluating combinations for parametric run

          * 2           { # of options for Location }
          * 1           { # of options for Archetypes }
          * 1           { # of options for Rulesets }
          *   (    1          { base option for all choices }
                +  4          { additional options for Opt-CasementWindows }
               )
          ----------------------------------------------------------
           10              Total combinations

    - Creating parametric run for 10 combinations --- 10 combos created.
    - Guesstimated time requirements ~ 41 seconds (including pre- & post-processing)

    ? Continue with run ? [yes]

    - Deleting prior HTAP-work directories...  done.
    - Deleting prior HTAP-sim directories...  done.
    - Preparing to process 10 generated combinations using 3 threads


_______________________________________________________________________________________________
= htap-prm: Begin Runs ========================================================================

   + Batch 1 ( 0.0% done, 0/10 files processed so far ...)
     - Starting thread 1/3 for sim #1 (PID 16980)... done.
     - Starting thread 2/3 for sim #2 (PID 15660)... done.
     - Starting thread 3/3 for sim #3 (PID 2972)... done.
     - Waiting on PID: 16980 (1/3)... done.
     - Waiting on PID: 15660 (2/3)... done.
     - Waiting on PID: 2972 (3/3)... done.
     - Reading results files from PID: 16980 (1/3)... done.
     - Reading results files from PID: 15660 (2/3)... done.
     - Reading results files from PID: 2972 (3/3)... done.
     - Post-processing results:
        -> Writing csv output to HTAP-prm-output.csv ... done.
        -> updating HTAP-prm.resume ... done.
     - Batch processing time: 13 seconds.

   + Batch 2 ( 30.0% done, 3/10 files processed so far, ~30 seconds remaining ...)
     - Starting thread 1/3 for sim #4 (PID 19260)... done.
     - Starting thread 2/3 for sim #5 (PID 12608)... done.
     - Starting thread 3/3 for sim #6 (PID 15460)... done.
     - Waiting on PID: 19260 (1/3)... done.
     - Waiting on PID: 12608 (2/3)... done.
     - Waiting on PID: 15460 (3/3)... done.
     - Reading results files from PID: 19260 (1/3)... done.
     - Reading results files from PID: 12608 (2/3)... done.
     - Reading results files from PID: 15460 (3/3)... done.
     - Post-processing results:
        -> Writing csv output to HTAP-prm-output.csv ... done.
        -> updating HTAP-prm.resume ... done.
     - Batch processing time: 10 seconds.

   + Batch 3 ( 60.0% done, 6/10 files processed so far, ~15 seconds remaining ...)
     - Starting thread 1/3 for sim #7 (PID 21360)... done.
     - Starting thread 2/3 for sim #8 (PID 15176)... done.
     - Starting thread 3/3 for sim #9 (PID 15324)... done.
     - Waiting on PID: 21360 (1/3)... done.
     - Waiting on PID: 15176 (2/3)... done.
     - Waiting on PID: 15324 (3/3)... done.
     - Reading results files from PID: 21360 (1/3)... done.
     - Reading results files from PID: 15176 (2/3)... done.
     - Reading results files from PID: 15324 (3/3)... done.
     - Post-processing results:
        -> Writing csv output to HTAP-prm-output.csv ... done.
        -> updating HTAP-prm.resume ... done.
     - Batch processing time: 10 seconds.

   + Batch 4 ( 90.0% done, 9/10 files processed so far, ~4 seconds remaining ...)
     - Starting thread 1/1 for sim #10 (PID 18092)... done.
     - Waiting on PID: 18092 (1/1)... done.
     - Reading results files from PID: 18092 (1/1)... done.
     - Post-processing results:
        -> Writing csv output to HTAP-prm-output.csv ... done.
        -> updating HTAP-prm.resume ... done.
     - Batch processing time: 15 seconds.

 - HTAP-prm: runs finished -------------------------

 - Deleting working directories... done.

 - HTAP-prm: Run complete -----------------------

    + 10 files were evaluated successfully.

    + 0 files failed to run

_______________________________________________________________________________________________
= htap-prm: Run Summary =======================================================================

 Total processing time: 52.7 seconds
 -> Informational messages:

   (-) Info - Parsed options file C:/HTAP/HTAP-options.json


 -> Warning messages:

   (nil)

 -> Error messages:

   (nil)

 STATUS: Task completed successfully
===============================================================================================

```



## HOW TO: change the  ##

