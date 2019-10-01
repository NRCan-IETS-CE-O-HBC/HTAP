# HTAP: A quick start guide #

Before following this guide, you must first install HTAP using the instructions in `HTAP-installation.md`. All examples in this guide use the files located in `HTAP\doc\examples\`. #

##### Working with HTAP files <a name="contents"></a>

1. [Editing text files](#editingFiles)
2. [Using the command line](#commandLine)

##### Running HTAP

3. [Using `htap-prm.rb` for HOT2000 batch processing](#batchProcessing)
4. [The `.run` file](#runFile)
5. [The `.options` file](#optionsFile)
6. [Changing the house models (.h2k files)](#changingh2k)
7. [Adding other locations](#addingLoc)
8. [Specifying different upgrades](#specUpg)
9. [Analyzing results](#analysingResults)

##### Troubleshooting

10. [Interpreting HTAP PRM output]()
11. [Reading simulation log files]()



<a name="editingFiles"></a>

## 1. Editing HTAP files

HTAP doesn't have a user interface. To work with HTAP, you must use a text editor to change ascii input files. While most windows computers include a free notepad application, we recommend using a program specifically designed to edit ascii files. 

If you don't already have such a program, you can download Notepad++ for free at <https://notepad-plus-plus.org/>

| ![1569895034153](img/notepadapp.png) |
| ------------------------------------ |
| Editing HTAP files in Notepad ++     |

([back to contents](#contents))<a name="batchProcessing"></a>

## 2. Using the command line 

To invoke HTAP,  you will enter commands in the windows command line console. Look for a program called Windows PowerShell. 

Once you have started the shell, navigate to the HTAP directory.

- Type `C:\HTAP`  to navigate to the root HTAP directory
- Type `C:\HTAP\doc\examples` to navigate to the example directory used in this guide.
- Type `C:\HTAP\htap-prm.rb --help` to learn more about invoking HTAP's parallel run manager.

| ![1569894949825](img/cmdLine.png)            |
| -------------------------------------------- |
| Invoking `htap-prm.rb` from the command line |

([back to contents](#contents))<a name="batchProcessing"></a>

## 3. Using  `htap-prm.rb` for batch HOT2000 processing

`HTAP-prm.rb` is a parallel run manager that can configure and dispatch multiple HOT2000 
simulations over parallel threads, and recover their output. For input, you must 
supply `htap-prm.rb` with a `.run` file, which contains pointers to other databases 
that HTAP should use, configuration options for the analysis, and instructions for changing hot2000 files. 

To start an HTAP run, use the following command:

    htap-prm.rb -r [run-file] -c

#### Example:

```
C:\HTAP\doc\examples> C:\htap\htap-prm.rb -r example.run -c -v
```

#### Output: 

```
____________________________________________________________________________________
= htap-prm: A simple parallel run manager for HTAP =================================

 GitHub source:
    - Branch:   Release-prep
    - Revision: 40a74f6

 Initialization:
    - Reading HTAP run definition from example.run...  done.
    - Evaluating combinations for parametric run

          * 2           { # of options for Location }
          * 1           { # of options for Archetypes }
          * 1           { # of options for Rulesets }
          *   (    1          { base option for all choices }
                +  2          { additional options for Opt-Windows }
               )
          ----------------------------------------------------------
           6               Total combinations

    - Creating parametric run for 6 combinations --- 6 combos created.
    - Guesstimated time requirements ~ 21 seconds (including pre- & post-processing)

    ? Continue with run ? [yes]

    - Deleting prior HTAP-work directories...  done.
    - Deleting prior HTAP-sim directories...  done.
    - Preparing to process 6 generated combinations using 3 threads


____________________________________________________________________________________
= htap-prm: Begin Runs =============================================================

   + Batch 1 ( 0.0% done, 0/6 files processed so far ...)
     - Starting thread 1/3 for sim #1 (PID 24288)... done.
     - Starting thread 2/3 for sim #2 (PID 19956)... done.
     - Starting thread 3/3 for sim #3 (PID 21132)... done.
     - Waiting on PID: 24288 (1/3)... done.
     - Waiting on PID: 19956 (2/3)... done.
     - Waiting on PID: 21132 (3/3)... done.
     - Reading results files from PID: 24288 (1/3)... done.
     - Reading results files from PID: 19956 (2/3)... done.
     - Reading results files from PID: 21132 (3/3)... done.
     - Post-processing results:
        -> Writing csv output to HTAP-prm-output.csv ... done.
        -> updating HTAP-prm.resume ... done.
     - Batch processing time: 13 seconds.

   + Batch 2 ( 50.0% done, 3/6 files processed so far, ~13 seconds remaining ...)
     - Starting thread 1/3 for sim #4 (PID 23948)... done.
     - Starting thread 2/3 for sim #5 (PID 9332)... done.
     - Starting thread 3/3 for sim #6 (PID 24344)... done.
     - Waiting on PID: 23948 (1/3)... done.
     - Waiting on PID: 9332 (2/3)... done.
     - Waiting on PID: 24344 (3/3)... done.
     - Reading results files from PID: 23948 (1/3)... done.
     - Reading results files from PID: 9332 (2/3)... done.
     - Reading results files from PID: 24344 (3/3)... done.
     - Post-processing results:
        -> Writing csv output to HTAP-prm-output.csv ... done.
        -> updating HTAP-prm.resume ... done.
     - Batch processing time: 11 seconds.

 - HTAP-prm: runs finished -------------------------

 - Deleting working directories... done.

 - HTAP-prm: Run complete -----------------------

    + 6 files were evaluated successfully.

    + 0 files failed to run

____________________________________________________________________________________
= htap-prm: Run Summary ============================================================

 Total processing time: 29.89 seconds
 -> Informational messages:

   (-) Info - Parsed options file C:/HTAP/HTAP-options.json


 -> Warning messages:

   (nil)

 -> Error messages:

   (nil)

 STATUS: Task completed successfully
====================================================================================
```
([back to contents](#contents))<a name="runFile"></a>

## 4. The `.run` file

The `.run` file defines which HOT2000 files that HTAP should work with, and the changes to be made to those files. The `.run` file has three sections:
- The `RunParameters` section describes where input files and databases are found, as well as the type of run that HTAP will perform
- The `RunScope` section describes which house models (.h2k files), locations and rulesets will be used in the run
- The `RunUpgrades` section describes how each .h2k file will be changed during the run. 

You will frequently change the the `.run` file while working with HTAP. Many projects will require a unique `.run` file, some may require several dedicated `.run` files.

([back to contents](#contents))<a name="optionsFile"></a>

## 5. The options file (`HTAP-options.json`)

The options file is a database. It defines all of the attributes within a HOT2000 model that HTAP can change, and rules for how those attributes can be changed. 

HTAP includes a single options file (`C:\HTAP\HTAP-options.json`). This is the file you will use for most of your HTAP work. You will frequently refer to the options file, but will rarely need to edit it. 

The options file is stored in JSON format. You can inspect its contents using a editor like Notepad++. It may seem overwhelming at first, but is easy to navigate using a code-folding feature (*View; fold-all* in Notepad++)

| ![1569896813694](img/json-folded.png)            |
| ------------------------------------------------ |
| Inspecting `HTAP-options.json` file in Notepad++ |

([back to contents](#contents))<a name="changingh2k"></a>

## 6. Changing the house models (.h2k files)

HTAP will work with most recent HOT2000 models. To change the HOT2000 files used in an HTAP run, you need to make two changes to the `.run` file:

1. Edit the `RunParameters` / `archetype-dir` entry to point to the directory containing the .h2k files you wish to run.
2. Edit the `RunScope` / `archetypes` entry to list the specific .h2k files  

Note that the `RunScope` / `archetypes`  entry can be a single .h2k file name (e.g. `rowhouse_1.h2k` ), a list of .h2k files (e.g. `rowhouse_1.h2k, rowhouse_2.h2k` ), or a wildcard string for searching (e.g. `rowhouse_*.h2k`). If you specify more than one .h2k file, HTAP will run analysis on all of those locations.

#### Example:

```
RunParameters_START

  run-mode          = parametric
  archetype-dir     = C:/my-h2k-file-location
  unit-costs-db     = C:/HTAP/HTAPUnitCosts.json
  options-file      = C:/HTAP/HTAP-options.json
  
RunParameters_END


RunScope_START

  archetypes     = rowhouse_*.h2k
  locations      = VANCOUVER, TORONTO
  rulesets       = as-found

RunScope_END
```



 ([back to contents](#contents))<a name="addingLoc"></a>

## 7. Adding other locations

HTAP supports all of the HOT2000 weather locations.  To change the locations used in the HTAP run, you must change the `RunScope` / `locations` entry. 

#### Example

```
RunScope_START

  archetypes     = rowhouse_*.h2k
  locations      = HALIFAX, TRURO, GREENWOOD, YARMOUTH  
  rulesets       = as-found

RunScope_END
```

You can find a complete list of supported locations by inspecting the `Opt-Locations/options` entry in `HTAP-options.json`. Or you can run HTAP analysis for all locations using a wild card:

```
locations      = *
```

Setting the location to `NA` will cause HTAP to leave the weather location entry in the HOT2000 file unchanged:

```
locations      = NA
```



 ([back to contents](#contents))<a name="specUpg"></a>

##8. Specifying different upgrades

HTAP works by editing attributes within .h2k files. We refer to the .h2k file attributes that HTAP supports as *upgrades.* Most upgrades affect the insulation, air sealing and mechanical systems in the home of the home, but a handful relate to the how the HOT2000 files should be evaluated.[^a]

The following upgrades are frequently used:

| Category         | HTAP `.run` file attribute     | Description                                                  |
| ---------------- | ------------------------------ | ------------------------------------------------------------ |
| Envelope         | `Opt-ACH`                      | Household air-tightness (air changes per hour @ 50 Pa)       |
|                  | `Opt-Windows`                  | U-value & SHGC for windows. (Variants `Opt-Skylights`,`Opt-DoorWindows` and `Opt-Doors` are also supported.) |
|                  | `Opt-Ceilings`                 | R-value of insulation for all ceilings (Supported variants: `Opt-AtticCeilings`, `Opt-CathCeilings`, `Opt-FlatCeilings`) |
|                  | `Opt-AboveGradeWall`           | R-value for all above-grade walls                            |
|                  | `Opt-FoundationWallExtIns`     | R-value for insulation on foundation exterior                |
|                  | `Opt-FoundationWallIntIns`     | R-value for wall assemblies installed on the foundation interior |
|                  | `Opt-FoundationSlabBelowGrade` | R-value for insulation installed underneath below-grade slabs |
|                  | `Opt-FoundationSlabOnGrade`    | R-value for insulation installed underneath on-grade slabs   |
|                  | `Opt-ExposedFloor`             | R-value for exposed floors, including floors above unheated crawlspaces and floors above garages. |
| Mechanicals      | `Opt-Heating-Cooling`          | Defines the heating and cooling systems                      |
|                  | `Opt-DHWsystem`                | Defines the water heating system                             |
|                  | `Opt-DWHR`                     | Defines drain-water heat recovery equipment, if installed    |
|                  | `Opt-VentSystem`               | Sets the ventilation equipment.                              |
| Renewable Energy | `Opt-H2K-PV`                   | Sets the size and efficiency of roof-mounted photovoltaics   |
| Other Parameters | `Opt-ResultHouseCode`          | Specifies which result set should be recovered (e.g. General mode, ERS, Reduced operating conditions) |
|                  | `Opt-Baseloads`                | Defines the appliance, lighting, plug and hot water loads in the building |
|                  | `Opt-Temperatures`             | Defines the set point temperatures the building              |

For each attribute, you can specify a list of choices that will be used.  Entries may be a comma separated list, wild-card string, or `NA`. The following table outlines how HTAP interprets different choices for the `Opt-Ceilings` attribute.

| `.run` File Entry                                 | Effect                                                       |
| ------------------------------------------------- | ------------------------------------------------------------ |
| ` Opt-Ceilings = CeilR40,CeilR50,CeilR60,CeilR70` | HTAP will run four simulations with attic insulation set to R40, R50, R60 and R70 levels. |
| `Opt-Ceilings  = *`                               | HTAP will run separate simulations for every one of the ceiling insulation definitions in the options file |
| `Opt-Ceilings  = NA`                              | HTAP will not change the ceiling insulation in the .h2k file. |

HTAP's input and output [reference](./HTAP-input-and-output.md) describes attributes in detail. 

[^a]: Future work may migrate these upgrades to the `RunScope` section. 

 ([back to contents](#contents))<a name="analysingResults"></a>

##9. Analyzing results

HTAP saves run results in comma-separated variable format. The output file is always called *HTAP-prm-output.csv*, and is saved in the same directory that HTAP was run from. You can analyze the data in this file using spreadsheet or data visualization software. 

Each HOT2000 run is reported on a separate line. The output may contain over 150 different columns. The columns are loosely organized by the scheme `Catagory|Variable`:

| Category     | Interpretation                                               |
| ------------ | ------------------------------------------------------------ |
| `configuration|____` | Variables describing how HTAP was configured          |
| `input|____` | Variables describing upgrades and other attributes specified for each HOT2000 evaluation |
| `output|____` | Variables describing data collected from HOT2000 results |
| `status|____` | Variables describing HTAP's progress |
| `archetype|____` | Variables describing the dimensions and characteristics of the house, form the HOT2000 file. |
| `cost-estimates|____` | Variables containing HTAP's capital cost estimates, if applicable |
| `analysis|____` | Variables containing additional calculations that HTAP performed on HOT2000 data. |

HTAP updates the results continually through a run, after each batch of HOT2000 simulations are completed. You can inspect the data while HTAP continues to process results. If you do so, be sure that your analysis program does not lock the results file (*HTAP-prm-output.csv*). Otherwise, HTAP will not be able to write new results to the file, and will crash.

 ([back to contents](#contents))<a name="errorsHTAP"></a>

##  10.[Interpreting `HTAP-prm.rb` errors]()

HTAP will occasionally encounter errors when attempting to process runs and evaluate HOT2000 files. These errors usually stem from:

-  typos in the `.run` file such as paths to .h2k files, options files or upgrade definitions
-  errors in the .h2k file that prevent hot2000 from evaluating it
-  errors in the options file or unit cost file 
-  programming errors

Some of these errors may be identified and reported by `HTAP-prm.rb`. Some may arise from `substitute-h2k.rb`— a lower-level program that HTAP uses to process .h2k files. Others may arise from HOT2000 itself. Whenever possible, `HTAP-prm.rb` will attempt to report an informative message to help you fix the error.

##### Common HTAP-prm.rb error messages: #####

| `(!) ERROR -  Message`                                       | Probable Causes & Solutions                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| `Valid path to run definitions (.run) file must be specified with --run-def (or -r) option! ` | You have provided the incorrect path to the `.run` file in the command line, or have misspelled its name. |
| `Could not parse run file`                                   | The `.run` file contains formatting errors. Inspect the file and correct the errors, or replace the file with a working `.run` file. |
| `Unknown location 'aaa' for attribute 'Opt-Location'`        | Entries in the location field are misspelled. Confirm spelling in `HTAP-options.json` |
| `Attribute 'ccc' does not match any attribute entry in the options file.` | Attribute name is misspelled. Confirm spelling in `HTAP-options.json` |
| `Unknown choice 'bbb' for attribute 'ccc'`                   | Choice entries for attribute `bbb` is misspelled. Confirm spelling in `HTAP-options.json` |
| `Options file 'C:/HTAP/HTAP-options.json' does not exist.`   | The `RunParameters` / `options-file` entry is incorrect.     |
| `Options file (C:/HTAP/HTAP-options.json) is incorrectly formmatted, cannot be interpreted as json` | The options file contains formatting errors.  Copy the contents of the options file into a json validator such as https://jsonlint.com/ and correct errors. |
| `Could not open CSV output file`                             | HTAP output file (*HTAP-prm-output.csv*) is open in another program (such as a spreadsheet), and HTAP cannot write to it. Close other programs that are reading HTAP-prm-output.csv |
| `No combinations to run.`                                    | The `RunScope`/`Archetypes`,  `Locations` and `rulesets` entries are missing, or misspelled. Also check that the `archetype-dir` entry is correct. |
| `X files failed to run.`                                     | HTAP or HOT2000 encountered errors when evaluating individual simulations. See [Interpreting simulation errors](#errormsgsSub) |

 ([back to contents](#contents))<a name="errormsgsSub"></a>


