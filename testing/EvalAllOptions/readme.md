
EvalAllOptions
========================

## Overview:
Simple test suite used to verify HTAP inputs/archetypes run. 
Exercises HTAP over a range of possible inputs. 
**Does not examine interactions that may arise with combinations of inputs.**

## Contents:

  - `AllArchetypes.run`: Runs every archetype (.h2k file) in the HTAP/Archetypes directory.
  - `AllLocations.run`:  Runs a base archetype in every weather location, and with every supported ruleset.
  - `AllOptions.run`:  Parametric run for every supported option 
  
## Example Usage:

     C:\HTAP\htap-prm.rb -o C:\HTAP\HTAP-options.json -r AllOptions.run -v  -t 5 -j

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