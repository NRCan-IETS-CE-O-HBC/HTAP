
```\testing\SampleRun```
========================

## Overview:
Simple test suite used to verify HTAP sampling method runs. 
Selects a random sample from all possible combinations. 


## Contents:

  - `Sampling.run` - Test case containing the sample test-case.
  
## Example Usage:

     C:\HTAP\htap-prm.rb -r Sampling.run -o C:\htap\HTAP-options.json -v -t 15 -j

## Configuration
The sampling method is configured by the `run-mode` parameter inside the run file: 
```
    run-mode  = sample{n:15; seed:436} 
```     
     
## Typical output:


     - HTAP-prm: Run complete -----------------------
     
        + 369 files were evaluated successfully.
     
        + 7 files failed to run
     
     ** The following files failed to run: **
         + sim-5.choices (dir: HTAP-sim-5) - substitute-h2k.rb reports errors
         + sim-7.choices (dir: HTAP-sim-7) - substitute-h2k.rb reports errors
         + sim-8.choices (dir: HTAP-sim-8) - substitute-h2k.rb reports errors
         + sim-9.choices (dir: HTAP-sim-9) - substitute-h2k.rb reports errors
         + sim-38.choices (dir: HTAP-sim-38) - substitute-h2k.rb reports errors
         + sim-350.choices (dir: HTAP-sim-350) - substitute-h2k.rb reports errors
         + sim-361.choices (dir: HTAP-sim-361) - substitute-h2k.rb reports errors

## Results 
 
- Detailed results are available in file HTAP-prm-output.json. 
- `.choice` files, log files and `.h2k` input files for failed runs are saved in folders `HTAP-sim-X`.