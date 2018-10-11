
Input and Output in HTAP
========================

Contents
------------------
1. [File formats](#IOmodel)
    1. [The options file (`HTAP-options.json`)](#options-definition)
    1. [The choice file (`my_evaluaton.choices`)](#choice-definition)
    1. [The run file (`my_batch.run`)](#run-definition)
    1. [The unit cost database (`HTAPUnitCosts.json`)] (#cost-definition)
1. [Attributes that can be modified by HTAP](#attributes)
    1. [`Opt-Location`](#opt-location)
    1. [`Opt-Archetype`](#opt-archetype)
    1. [`Opt-ACH`](#opt-ach)
    1. [`Opt-Mainwall`](#opt-mainwall)
    1. [`Opt-Ceilings`](#opt-ceilings)
    1. [`Opt-AtticCeilings`](#opt-attic-ceilings)
    1. [`Opt-CathCeilings`](#opt-cath-ceilings)
    1. [`Opt-FlatCeilings`](#opt-flat-ceilings)
    1. [`Opt-H2KFoundation`](#opt-h2kfoundation)
    1. [`Opt-H2KFoundationSlabCrawl`](#opt-h2kfoundation-slabcrawl)
    1. [`Opt-ExposedFloor`](#opt-exposedfloor)
    1. [`Opt-CasementWindows`](#opt-casementwindows)
    1. [`Opt-Skylights`](#opt-sylights)
    1. [`Opt-DoorWindows`](#opt-door-windows)
    1. [`Opt-Doors`](#opt-doors)
    1. [`Opt-H2K-PV`](#opt-h2k-pv)
    1. [`Opt-HVACSystem`](#opt-hvacsystem)
    1. [`Opt-DHWsystem`](#opt-dhwsystem)
    1. [`Opt-DWHRsystem`](#opt-dwhrsystem)
    1. [`Opt-HRVspec`](#opt-hrvspec)
    1. [`Opt-FuelCost`](#opt-fuelcost)
    1. [`Opt-RoofPitch`](#opt-roofpitch)
    1. [`Opt-Ruleset`](#opt-ruleset)
1. [Legacy parameters not currently supported](#opt-skipped)    
1. [Outputs](#outputs)
    1. [`RunNumber`](#runnumber)
    2. [`H2K-outputs`](#h2k-outputs)
    3. [`input.data`](#input.data)
1. [Legacy files and features]    

   
    
    
<a name="IOmodel"></a>
File formats 
------------
<a name="options-definition"></a>
### The options file (`HTAP-options.json`)
HTAP supports data input via JSON formatted options files.[^1] This file is formatted as a list of hashes - each of which defines attributes that can be set changed within the model, or that affect how the evaluations should be performed. 


[^1]: Available since commit 2b29e5f5539219c1260ddc2fe3dfa7a2947fd373 


The  HTAP-options.json file looks like this: 

    {
       "Attribute_1": {   },
       "Attribute_2": {   },
       "Attribute_3": {   }
       
       <--snip-->

       "Attribute_X": {   }       
    }   

Each attribute can be defined in one of two ways - using the simple, or `flat` structure, or the nested, `tree` structure. 

- The `flat` structure should be used for _one-to-one relationships_  when changing attributes causes HTAP to affect a single part of the HOT2000 data model - such as setting 
a fuel library, or specifying the code library.  
- The `tree` structure should be used for _one-to-many relationships_  when changing attributes causes HTAP to affect a multiple parts of the HOT2000 data model - such as setting 
changing the mechanical system from a furnace a heat pump or combo. 

#### Attribute specification - `tree` structure 

    "Tree-Attribute_X": {
      "structure": "tree",
      "costed": [true|false],
      "options": {
        "keyword_a":{
          "h2kMap": {
            "base": { 
              "<h2k-tag-1>": "Option-A-Value-to-be-set-1",
              "<h2k-tag-2>": "Option-A-Value-to-be-set-2",
              "<h2k-tag-3>": "Option-A-Value-to-be-set-3",
              "<h2k-tag-4>": "Option-A-Value-to-be-set-4",
              "<h2k-tag-5>": "Option-A-Value-to-be-set-5",
              "<h2k-tag-6>": "Option-A-Value-to-be-set-6",
              "<h2k-tag-7>": "Option-A-Value-to-be-set-7",
              "<h2k-tag-8>": "Option-A-Value-to-be-set-8"
            },
            "variants": {
               "scenario_name" : { 
                  "<h2k-tag-4>": "Value-to-be-modified",
               }
            }   
          },
          "costs": {
            "components": [
              "unit-cost-component-1",
              "unit-cost-component-2",
              "unit-cost-component-3"
            ],
            "custom-costs": {
              "ExampleScenarioA": {
                "Units": "unit key word",
                "TotUnitCost": ##.##,
                "Comment": "name of component"
              },
            }
          }
        },
        "keyword_b": { ... }
        
        <--snip-->
        
        "keyword_z": { ... }
      }
      "default": "keyword_a",
      "stop-on-error": true,
      "h2kSchema": [
        "<h2k-tag-1>",
        "<h2k-tag-2>",
        "<h2k-tag-3>",
        "<h2k-tag-4>",
        "<h2k-tag-5>",
        "<h2k-tag-6>",
        "<h2k-tag-7>",
        "<h2k-tag-8>"
      ]
    }

    
#### Attribute specification - `flat` structure
The flat definitions for attributes are relatively simple. They can be used when an objective evaluation requires changing the HOT2000 data model in one place - for instance by setting the .h2k input file. or 

    "Flat_Attribute_Y": {
        "structure": "flat",
        "costed": false,
        "options": {
          "keyword_a": "option-a-value",
          "keyword_b": "option-b-value",
          "keyword_c": "option-c-value",
          
           <-- snip -->    

          "keyword_z": "value_z",      
          
        },
        "default": "keyword_a",
        "stop-on-error": [true|false]
        "
    }
    
#### Members belonging to an attribute:
    
Members common to both `tree` and `flat` structures:
- `"structure": ["flat"|"tree"]`: string keyword describing which structure should be used 
- `"costed": [true|false]`: specifies whether cost data is associated with this attribute. If `"costed": true`, the costs section must be supplied.<mark>Note that </mark>**`"costed": true`**<mark> is currently only supported in the tree structure.</mark>
- `"options": { ... }`: Hash defining the valid options that an attribute can be set to. Contents depend on whether `tree` or `flat` structure is used. 
- `"default": "keyword_X"`: specifies the default value that should be used if the user opts not to provide an option. 
- `"stop-on-error": [true|false]`: Flag indicating if the run should be terminated when an option is not provided, or if HTAP should attempt to continue. 

Members specific to the `tree` structure:
- `"h2kSchema": [ ... ]`: list of keyword tags that HTAP supports for this attribute - each of which refers to a part of the .h2k file that HTAP can modify. Each option must map one or more of these tags to a value. The schema is only defined once per attribute. 
- `"h2kMap": { ... }`: a hash that maps the `"h2kSchema"` tags to the values for a specific option `"h2kMap"` supports a standard base definition that will be used for all applications. <mark>Future versions will include support `"variants"` that users to modify a one or more tags 
for a specific analysis.</mark>
- `"base": { ... }`: a hash that maps the `"h2kSchema"` tags to the values for a specific option. 
- `"variants": { ... }`: a set of hashes that overwrite definitions in the base h2k map for specific scenario requirements. This section is intended to allow users to customize their configurations without duplicating options files or options definitions. <mark>This feature is not yet implemented.</mark>
- `"costs": { ... }`: a hash describing how costs should be evaluated for this option. Required if `"costed": true`. 
- `"components": [ ... ]`: A list of components that a) are required to implement this option, and b) match entries in the unit costs database. 
- `"custom-costs": { ... }`: A hash describing customized costs that can be applied in place of data from the unit cost database. 
- `"Units": "unit key word"`: String describing how custom costs should be applied (e.g. `"Units": "sf floor area"|"sf applied"|"ea"|...`
- `"TotUnitCost": ##.##`: Float data quantifying the unit cost in canadian dollars 
- `"comment": "comment string"`: Optional string that can describe where the data came from.




#### Example `flat` attribute: Mapping archetype to required .h2k file 

    "Opt-Archetype": {
      "structure": "flat",
      "costed": false,
      "options": {
        "NA": "NA",
        "SmallSFD": "C:\\H2K-CLI-Min\\User\\BC-Step-rev-SmallSFD.h2k",
        "MediumSFD": "C:\\H2K-CLI-Min\\User\\BC-Step-rev-MediumSFD.h2k",
        "LargeSFD": "C:\\H2K-CLI-Min\\User\\BC-Step-rev-LargeSFD.h2k",
        "Rowhouse": "C:\\H2K-CLI-Min\\User\\BC-Step-rev-Row.h2k",
        
        <-- snip --> 
        
        "Quadplex": "C:\\H2K-CLI-Min\\User\\BC-Step-rev-Quad.h2k",
        
      },
      "default": "SmallSFD",
      "stop-on-error": true
    },
    

#### Example `tree` attribute: Casement windows definition 

     "Opt-CasementWindows": {
     "structure": "tree",
     "costed": true,
     "options": {
       "NA": {
         "h2kMap": {
           "base": {
             "<Opt-win-S-CON>": "NA",
             "<Opt-win-E-CON>": "NA",
             "<Opt-win-N-CON>": "NA",
             "<Opt-win-W-CON>": "NA",
             "<Opt-win-SE-CON>": "NA",
             "<Opt-win-SW-CON>": "NA",
             "<Opt-win-NE-CON>": "NA",
             "<Opt-win-NW-CON>": "NA"
           }
         },
         "costs": {
           "components": [
             "Example Key-phrase: Layer1",
             "Example Key-phrase: Layer2",
             "Example Key-phrase: Layer3"
           ],
           "custom-costs": {
             "ExampleScenarioA": {
               "Units": "sf floor area",
               "TotUnitCost": 1.5,
               "Comment": "eg: Alex's original estimate"
             },
             "ExampleScenarioB": {
               "Units": "sf floor area",
               "TotUnitCost": 1.7,
               "Comment": "eg: Real numbers from ACME builder."
             }
           }
         }
       },
       "DoubleLowEHardCoatAirFill": {
         "h2kMap": {
           "base": {
             "<Opt-win-S-CON>": "DblLeHcAir",
             "<Opt-win-E-CON>": "DblLeHcAir",
             "<Opt-win-N-CON>": "DblLeHcAir",
             "<Opt-win-W-CON>": "DblLeHcAir",
             "<Opt-win-SE-CON>": "DblLeHcAir",
             "<Opt-win-SW-CON>": "DblLeHcAir",
             "<Opt-win-NE-CON>": "DblLeHcAir",
             "<Opt-win-NW-CON>": "DblLeHcAir"
           }
         },
         "costs": {
           "components": [
             "Example Key-phrase: Layer1",
             "Example Key-phrase: Layer2",
             "Example Key-phrase: Layer3"
           ],
           "custom-costs": {
             "ExampleScenarioA": {
               "Units": "sf floor area",
               "TotUnitCost": 1.5,
               "Comment": "eg: Alex's original estimate"
             },
             "ExampleScenarioB": {
               "Units": "sf floor area",
               "TotUnitCost": 1.7,
               "Comment": "eg: Real numbers from ACME builder."
             }
           }
         }
       }, 
       TripleLowESoftCoatKryFill": { ... }
     }
     "default": "DoubleLowEHardCoatArgFill",
     "stop-on-error": true,
     "h2kSchema": [
       "<Opt-win-S-CON>",
       "<Opt-win-E-CON>",
       "<Opt-win-N-CON>",
       "<Opt-win-W-CON>",
       "<Opt-win-SE-CON>",
       "<Opt-win-SW-CON>",
       "<Opt-win-NE-CON>",
       "<Opt-win-NW-CON>"
     ]      
    
    } 

<a name="choice-definition"></a>
### The HOT2000.choice file 
The .choice file contains a token-value list that defines the option that HTAP should use for each attribute.  The syntax for each is TOKEN : VALUE, and comments are denoted with a exclamation mark (!).  Entries in the choice file must obey the following rules:
- Each token must match one of the attributes in the .options file
- Each value must match on of the options given for that attribute in the .options file
- `NA` values instruct the substiture-h2k.rb script to leave the associated data in the .h2k file alone – that is, whatever inputs were provided when the file was created in HOT2000 will be used in the HTAP simulation.

An example .choice file follows. In this example, the .choice file instructs HTAP to replace the heating system with a cold-climate air source heat pump, the DHW system with a heat pump water heater, and to add a drain-water heat recovery device. All other inputs are left unchanged. 

        !-----------------------------------------------------------------------
        ! Choice file for use in exercising HOT2000
        !
        ! The H2K model file used is a valid model and nothing needs to be 
        ! changed for it to run!  Using "NA" on any of the options below
        ! leaves the model unchanged for that option.
        !-----------------------------------------------------------------------  
        
        ! HOT2000 code library file to be used - MUST ALWAYS BE SPECIFIED HERE
        Opt-DBFiles  : H2KCodeLibFile
        
        ! Weather location
        Opt-Location : NA 
        
        ! Archetype file: 
        Opt-Archetype: NZEH-Arch-1
        
        ! Fuel costs 
        Opt-FuelCost : rates2016
        
        ! Air tightness 
        Opt-ACH : NA
                
        ! Ceiling R-value
        Opt-Ceilings : NA
        
        ! Main wall definitions 
        Opt-GenericWall_1Layer_definitions : NA   
        
        ! Exposed floor
        Opt-ExposedFloor : NA
        
        ! Optical and thermal characteristics of casement windows (all)
        Opt-CasementWindows  : NA   
        
        ! Foundation definitions
        Opt-H2KFoundation : NA  
        
        ! Hot water system.
        Opt-DHWSystem :  HPHotWater
                
        ! Drain-water heat recovery 
        Opt-DWHRsystem:  DWHR-eff-30 
        
        ! HVAC system 
        Opt-HVACSystem  : CCASHP
        
        ! HRV spec 
        Opt-HRVspec : NA
        
        Opt-RoofPitch : NA   !6-12
        
        Opt-H2K-PV : NA 
          <snip>

<a name="run-definition"></a>
### The .run file 
The .run file contains a token-value list that defines the runs for `htap-prm.rb`. The .run file contains 3 sections:
* **RunParameters** : Defines the `run-mode` and the `archetype-dir`. The `run-mode` is set to mesh; the only mode currently available. The `archetype-dir` is the local directory that contains the archetypes used in the HTAP runs.
* **RunScope** : Defines the `archetypes`, `locations`, and `rulesets`. 
  - Multiple `archetypes` can be defined for the HTAP runs, and each `*.h2K` file is separated by a comma (,). Each `archetypes` file must be located in the `archetype-dir`. These archetypes are not the same as `Opt-Archetype` tags, these are the HOT2000 files, `*.h2k`. 
  - The `locations` parameter defines the weather location used for each HTAP run. These `locations` correspond to the municipal location defined in HOT2000 weather file, and are the same values as `Opt-Location`. Multiple locations can be defined, and each is comma-separated in the list.
  - Setting `locations = NA` will cause the archetype to be run with whatever weather location was defined in the original `*.h2k` archetype file. 
  - The `rulesets` parameter `as-found` will cause HTAP to run the `archetypes` for `locations` with no other upgrades. `rulesets` are defined as a set of upgrades to satisfy and a particular performance target: national building code energy requirements, EnergyStar targets, etc. `rulesets` are a functionality that is currently under develepment, and should be used with caution. Multiple rulesets can be defined, and each is comma-separated in the list.
  
* **Upgrades** : Defines options to be investigated in mesh mode during the HTAP run. 
   - If the `rulesets` tag is set to `as-found`, then  __substitute-h2k.rb__ will apply each combination of inputs as defined in the sections below.
   - If the `rulesets` tag is set to a specific ruleset, then  __substitute-h2k.rb__ will apply each combination of inputs using the ruleset as the _new_ base case archetype.

```
! Run-Mode: Parameters that affect how htap-prm is configured. 
RunParameters_START
  run-mode                           = mesh 
  archetype-dir                      = C:/HTAP/Archetypes
RunParameters_END 


! Parameters controlling archetypes, locations, reference rulesets.
RunScope_START

  archetypes                        = NRCan-A9_3000sf_2stry_walkOut.h2k
  locations                         = Vancouver, Toronto, Halifax
  rulesets                          = as-found, 936_2015_AW_noHRV, 936_2015_AW_HRV
  
RunScope_END

! Parameters controlling the design of the building 
Upgrades_START

    Opt-FuelCost                       = rates2016  
    Opt-ACH                            = NA
    Opt-MainWall                       = GenericWall_1Layer
    Opt-GenericWall_1Layer_definitions = NA
    Opt-Ceilings                       = NA
    Opt-H2KFoundation                  = NA
    Opt-ExposedFloor                   = NA
    Opt-CasementWindows                = NA
    Opt-H2K-PV                         = NA
    Opt-DWHRandSDHW                    = NA 
    Opt-RoofPitch                      = NA
    Opt-DHWSystem                      = NA
    Opt-DWHRSystem                     = NA
    Opt-HVACSystem                     = NA 
    Opt-HRVspec                        = NA

Upgrades_END
```


<a name="cost-definition"></a>
### The unit cost database (`HTAPUnitCosts.json`) 
HTAP includes a unit cost database with estimates on the costs of various energy related upgrades. The database is organized in two sets of hashes - `"sources"` and `"data"`:

     {
       "sources": { ... },
       "data": { ... }
     }

#### Source entries 
The source entries within the database describe where cost data was obtained from. They have the following format:

    "sources": { 
       "cost-source-b": {
         "filename": "source-file-b.csv",
         "date_collated": "YYYY-MM-DD",
         "date_imported": "YYYY-MM-DD HH:MM:SS",
         "schema_used": "schema name",
         "origin": "Comment on data source b",
         "inherits": {
           "cost-source-a": [
              "entry-name-a", 
              "entry-name-b", 
              "entry-name-c",
              
              <--snip-->
              
              "entry-name-d"
           ]
         }
       },
       "cost-source-a": {
         "filename": "source-file-a.csv",
         "date_collated": "YYYY-MM-DD",
         "date_imported": "YYYY-MM-DD HH:MM:SS",
         "schema_used": "schema name",
         "origin": "Comment on data source a",
         "inherits": {
         }
       }
    } 
     
Each source entry has the following members:    

- `"filename":  "source-file-b.csv"`: filename used to generate entries within the cost database - typically a LEEP unit-cost sheet exported in csv format. 
- `"date_collated": "YYYY-MM-DD"`: Approximate date when data sheet was compiled.
- `"date_imported": "YYYY-MM-DD HH:MM:SS"`: Exact date/time when data was imported.
- `"schema_used": "schema name"`: Keyword describing which schema was used to intrepret the imported csv data. 
- `"origin": "Comment on data source b"`: Comment on data source
- `"inherits": { ... }` : Hash describing which entries merely duplicate data from other databases.


##### Example source entry 
    "sources":{
        "LEEP-MB-Winnipeg": {
          "filename": "LEEP_Costing_MB_winnipeg.csv",
          "date_collated": "2014-09-01",
          "date_imported": "2018-10-02 11:32:54",
          "schema_used": "oldLeep",
          "origin": "Costs used in MB LEEP 2014",
          "inherits": {
            "LEEP-ON-Ottawa": [
              "upgrading_from_3.57ach_to_1.75",
              "upgrading_from_3.57ach_to_1.25",
              "upgrading_from_3.57_to_1.0",
              "upgrading_from_3.57_to_0.6",

              <--snip--> 
              
              "solar_light_tube_kit:including_roof_unit:flashing:ceiling_fixture_&_3m"
            ]
          }
        },
        "LEEP-ON-Ottawa": {
          "filename": "LEEP_COSTING_ottawa_V1.4.csv",
          "date_collated": "2013-09-01",
          "date_imported": "2018-10-02 11:32:53",
          "schema_used": "oldLeep",
          "origin": "Costs used in Ottawa LEEP 2013",
          "inherits": {
          }
        }
    }
    
#### Data entries  
The data entries within the database contain the actual unit costs. They have the following format:    
    
    "data": {
      "unit-cost-component-1": {
        "cost-source-a": {
          "category": "category-name",
          "description": "cost description",
          "units": "unit keyword",
          "UnitCostMaterials": ##.##,
          "UnitCostLabour": ##.##,
          "note": "information about cost data",
          "date": "YYYY-MM-DD"
        },
        "cost-source-b": { ... }
        "cost-source-c": { ... }
        
        <--snip-->  
        
        "cost-source-d": { ... }
      
      },
      "unit-cost-component-2": { ... },        
      "unit-cost-component-3": { ... },
      
      <--snip--> 
      
      "unit-cost-component-3": { ... },
      
    }
     
Each data entry contains the following: 
- `"category": "category-name"`: Descriptive category for data (could be `"INSULATION"` or `"DRYWALL"`). HTAP presently ignores this data. 
- `"description": "cost description"`: Expanded descriptor for this entry
- `"units": "unit keyword"`:  String describing how custom costs should be applied (e.g. "units": "sf floor area"|"sf applied"|"ea"|...)
- `"UnitCostMaterials": ##.##`: Materials cost estimate ($/unit)
- `"UnitCostLabour": ##.##`: Labour cost estimate ($/unit)
- `"note": "information about cost data"`: Additional info about source of data (e.g. reference)
- `"date": "YYYY-MM-DD"`: Date data collected/reported. 


##### Example data entry 

    "data": {
      "1/2in_gypsum_board": {
        "LEEP-ON-Ottawa": {
          "category": "DRYWALL",
          "description": "1/2in Gypsum board",
          "units": "sf wall",
          "UnitCostMaterials": 0.35,
          "UnitCostLabour": 0.41,
          "note": "Hanscomb - aggregated average of material and labour for base case walls",
          "date": "n.d.",
          "source": "LEEP-ON-Ottawa"
        }
      },
      "1/2in_plywood": {
        "LEEP-BC-Vancouver": {
          "category": "SHEATHING",
          "description": "1/2in plywood",
          "units": "sf applied",
          "UnitCostMaterials": 0.57,
          "UnitCostLabour": 0.0,
          "note": "Griff Building Supplies",
          "date": "n.d.",
          "source": "LEEP-BC-Vancouver"
        }
      },
      "2x12_engineered_i-joists-_hanscomb": {
        "LEEP-MB-Winnipeg": {
          "category": "FRAMING",
          "description": "2x12 engineered i-joists- Hanscomb",
          "units": "LF",
          "UnitCostMaterials": 1.9,
          "UnitCostLabour": 0.0,
          "note": "",
          "date": "n.d.",
          "source": "LEEP-MB-Winnipeg"
        }
      },
    }
     
<a name="attributes"></a> 
Attributes that can be modified by HTAP 
------

<a name="opt-location"></a>
### `Opt-Location` 

* **Description** : Defines weather file location to be used in the HTAP run.
* **Typical values**: Municipal location corresponding to valid HOT2000 weather file 
  (e.g. `Calgary`, `Toronto`, `Vancouver` ...)
* **HOT2000 bindings**:  Based on the specified `Opt-Location`, __substitute-h2k.rb__ will set the 
  weather database (typically `Wth110.dir`, the weather region and the weather file location. 
* **Other things you should know**: 
  - By design, HOT2000 will also attempt to match the weather location to 
    a valid set of fuel cost data in the fuel library. This feature has proven temperamental, 
    and should be used with care. Note that HOT2000 will not generate errors or warnings if 
    the location is not successfully matched to a fuel library. Resulting energy estimates
    will be correct, but fuel cost calculations will be wrong.
  - Setting `Opt-Location = NA` will cause  __substitute-h2k.rb__  to run the h2k file with 
    whatever weather location was defined in the original file. 
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-Location = Toronto 
         
#### Sample `.options` definition for  `Opt-Location`

         *attribute:start 
         *attribute:name  = Opt-Location
         *attribute:tag:1 = OPT-H2K-WTH-FILE
         *attribute:tag:2 = OPT-H2K-Region
         *attribute:tag:3 = OPT-H2K-Location
         *attribute:default = Ottawa 
         
         *option:NA:value:1 = NA
         *option:NA:value:2 = NA
         *option:NA:value:3 = NA
         *option:NA:cost:total    = 0
         
         *option:Whitehorse:value:1 = Wth110.dir
         *option:Whitehorse:value:2 = 11
         *option:Whitehorse:value:3 = 69
         *option:Whitehorse:cost:total    = 0
           
         *option:Toronto:value:1 = Wth110.dir
         *option:Toronto:value:2 = 5
         *option:Toronto:value:3 = 42
         *option:Toronto:cost:total    = 0
         
         <snip>

<a name="opt-archetype"></a>         
### `Opt-Archetype` 

* **Description** : Defines the .h2k file that will be used for the basis of a HTAP run 
* **Typical values**: Keyword that maps to a .h2k file path (e.g. `SmallSFD`) 
* **HOT2000 bindings**:  The __substitute-h2k.rb__ script will make a copy of the 
    specified .h2k file, and will alter it according to your specified choices. __substitute-h2k.rb__
    will then invoke HOT2000 to evaluate the .h2k file, and recover the results from that file
* **Other things you should know**: 
  - __substitute-h2k.rb__ will make a copy of the specified archetype file for its operations --- the original will not 
    be modified. 
  - Earlier versions of HTAP required the archetypes to be located in the `C:\H2K-CLI-Min\User\` directory; more recently, HTAP 
    can work with archetypes in arbitrary locations
  - Alternatively, the archetype file can be passed to __substitute-h2k.rb__ via a command line, as below. In this 
    usage, the `Opt-Archetype` definition should be omitted from the choice file.
  
#### Sample `.choice` definition for  `Opt-Archetype`  
         Opt-Archetype = MediumSFD
         
#### Sample `.options` definition for  `Opt-Archetype`

         *attribute:start 
         *attribute:name = Opt-Archetype
         *attribute:tag:1 = <NotARealTag>
         *attribute:default = NZEH-Arch-1
         
         *option:NA:value:1 = NA
         *option:NA:cost:total = 0
                  
         *option:SmallSFD:value:1 = C:\H2K-CLI-Min\User\BC-Step-rev-SmallSFD.h2k
         *option:SmallSFD:cost:total = 0
         
         *option:MediumSFD:value:1 = C:\H2K-CLI-Min\User\BC-Step-rev-MediumSFD.h2k
         *option:MediumSFD:cost:total = 0
         
         *option:LargeSFD:value:1 = C:\H2K-CLI-Min\User\BC-Step-rev-LargeSFD.h2k
         *option:LargeSFD:cost:total = 0      
         <snip>
         

<a name="opt-ach"></a>
### `Opt-ACH` 

* **Description** : Defines the infiltration characteristics of the building, using 
  inputs similar to those collected from a blower-door test. 
* **Typical values**: Keyword indicating level of airtightness (e.g. `ACH_3`, `ACH_1_5`)
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will map the keyword to values 
  in the .options file, and then edit the .h2k file to reflect the same air leakage 
  performance target. 
* **Other things you should know**: 
  - HTAP can presently only change the blower-door test air change rate; options to 
    adjust the house volume, ELA or site characteristics are not supported.
  - Setting `Opt-ACH = NA` will cause __substitute-h2k.rb__ to leave air infiltration 
    unchanged in the archetype 
  
#### Sample `.choice` definition for  `Opt-ACH`  
         Opt-ACH = ACH_7
         
#### Sample `.options` definition for  `Opt-ACH`

         *attribute:start
         *attribute:name     = Opt-ACH
         *attribute:tag:1    = <Opt-ACH>
         *attribute:default  = NA
         
         *option:NA:value:1  = NA    ! Means "no change" to H2K
         *option:NA:cost:total  =  0
         
         *option:ACH_7:value:1  = 7.0
         *option:ACH_7:cost:total  =  0
         
         *option:ACH_6_5:value:1  = 6.5
         *option:ACH_6_5:cost:total  =  0
         <snip>
         

<a name="opt-mainwall"></a>
### `Opt-MainWall`

* **Description** : Defines insulation levels in above-grade opaque walls. 
* **Typical values**: Keyword specifying desired wall assembly (e.g. `BaseR20`,
    `SIPS-R28-Wall`, `DblStud-R52-Wall`) 
* **HOT2000 bindings**:  Depending on the definitions in the options file, 
    __substitute-h2k.rb__ will do one of two things:
    1. Replace the wall construction definition with a specified code from the 
       construction code library
    2. Replace the wall construction definition with a user-specified RSI value 
       from the .options file. 
    
>>**Note** that the .options file should provide the construction code **OR** the 
    R-value - not both!

* **Other things you should know**: 
  - __substitute-h2k.rb__ expects US insulation values (R-19, R-22, R-26...), not
    RSI values. __substitute-h2k.rb__ will automatically convert R-values to RSI 
    when creating the .h2k file.   
  - Setting `Opt-MainWall = NA` will leave the archetype's main wall definitions to 
    be unchanged.
  - __substitute-h2k.rb__ will apply the same definition to all above-grade walls, 
    regardless of their size, orientation, or original construction. 
  - HTAP also includes support for an alternate main wall construction definition, 
    `Opt-GenericWall_1Layer_definitions`. This definition is depreciated and 
    will be removed from future versions. 
  
#### Sample `.choice` definition for  `Opt-MainWall`  
         Opt-MainWall = BaseR21
         
#### Sample `.options` definition for  `Opt-MainWall`
         *attribute:name = Opt-MainWall
         *attribute:tag:1  = OPT-H2K-CodeName    ! Use "NA" (or non-existent name) for user-Specified case
         *attribute:tag:2  = OPT-H2K-EffRValue   ! User-Specified R-value (Imperial)
         *attribute:default = GenericWall_1Layer
         
         ! GENERIC wall definitions: thickness of insulation layers
         ! is set separately, based on data in options file
         
         ! - Single insulation layer (batts). 
         *option:GenericWall_1Layer:value:1 =   NA          ! NA for H2K
         *option:GenericWall_1Layer:value:2 =   NA          ! NA for H2K
         *option:GenericWall_1Layer:cost:total    =   0     ! Costs defined in Generic Wall definitions 
         
         
         *option:NA:value:1 =   NA
         *option:NA:value:2 =   NA
         *option:NA:cost:total = 0
         
         ! Example: Wall definition from library code 
         
         *option:BaseR20:value:1 =   BaseWallCode  ! Existing H2K code library wall name
         *option:BaseR20:value:2 =   NA           ! OR, User-specified R-value (Imperial), but not both!
         *option:BaseR20:cost:total    =   0
         
         ! Example: Wall definition from library code 
         *option:SIPS-R28-Wall:value:1 =   NA        ! Existing H2K code library wall name
         *option:SIPS-R28-Wall:value:2 =   28        ! OR, User-specified R-value (Imperial), but not both!
         *option:SIPS-R28-Wall:cost:total    =  0
         <snip>


<a name="opt-ceilings"></a>
### `Opt-Ceilings`

* **Description** : Defines insulation levels in ceilings.
* **Typical values**: Keyword specifying desired ceiling assembly (e.g. `CeilR40`, `CeilR50`...)
* **HOT2000 bindings**:  Depending on the definitions in the options file, 
    __substitute-h2k.rb__ will do one of two things:
    1. Replace the ceiling construction definition with a specified code from the 
       construction code library
    2. Replace the ceiling construction definition with a user-specified RSI value 
       from the .options file. 
    
>>**Note** that the .options file should provide the construction code **OR** the 
    R-value - not both!

* **Other things you should know**: 
  - __substitute-h2k.rb__ expects Imperial/US insulation values (R-19, R-22, R-26...), not
    RSI values. __substitute-h2k.rb__ will automatically convert R-values to RSI 
    when creating the .h2k file.   
  - Setting `Opt-Ceilings = NA` will leave the archetype's ceiling definitions 
    unchanged.
  - __substitute-h2k.rb__ will apply the same definition to all ceilings, 
    regardless of their size or original construction. 
  - If the User Specified option is used, then all ceilings, regardless of type will
    be changed (i.e., Attic/Gable, Attic/Hip, Scissor, Flat or Cathedral). 
  - If the code library names option is used, then only one group of code library  
    ceilings will be changed depending on which group the chosen code name
    appears in. There are two code library ceiling groups: "Ceiling Codes" (i.e., 
    Attic/Gable, Attic/Hip and Scissor) and "Flat or Cathedral Ceiling Codes".
  - This option should not be combined with any other ceiling option!
  
#### Sample `.choice` definition for  `Opt-Ceilings`  
         Opt-Ceilings = CeilR50
         
#### Sample `.options` definition for  `Opt-Ceilings`

         attribute:name = Opt-Ceilings
         *attribute:tag:1  = <Opt-Ceiling>       ! H2K uses this for library code name
         *attribute:tag:2  = OPT-H2K-EffRValue   ! H2K R-value (Imperial) or "NA" if use code name in tag 1
         *attribute:default = CeilR50
         
         *option:NA:value:1 = NA     ! No change
         *option:NA:value:2 = NA
         *option:NA:cost:total = 0
         
         *option:UsrSpecR40:value:1 =  NA       ! H2K: NA or code name in code library
         *option:UsrSpecR40:value:2 =  40       ! H2K R-value (Imperial)
         *option:UsrSpecR40:cost:total = 0
         
         *option:CeilR40:value:1 =  CeilR40     ! H2K: Code name must exist in code library
         *option:CeilR40:value:2 =  NA          ! H2K: No user-specified R-value (Imperial), code name used!
         *option:CeilR40:cost:total = 0
         
         *option:CeilR50:value:1 = CeilR50                
         *option:CeilR50:value:2 = NA              ! H2K R-value (Imperial)         
         *option:CeilR50:cost:total    =   0       
         <snip>

         
<a name="opt-attic-ceilings"></a>
### `Opt-AtticCeilings`

* **Description** : Defines insulation levels in attic/gable, attic/hip, and scissor ceilings only.
* **Typical values**: Keyword specifying desired ceiling assembly (e.g. `CeilR40`, `CeilR50`...)
* **HOT2000 bindings**:  Depending on the definitions in the options file, 
    __substitute-h2k.rb__ will do one of two things:
    1. Replace the ceiling construction definition with a specified code from the 
       construction code library
    2. Replace the ceiling construction definition with a user-specified RSI value 
       from the .options file. 
    
>>**Note** that the .options file should provide the construction code **OR** the 
    R-value - not both!

* **Other things you should know**: 
  - __substitute-h2k.rb__ expects Imperial/US insulation values (R-19, R-22, R-26...), not
    RSI values. __substitute-h2k.rb__ will automatically convert R-values to RSI 
    when creating the .h2k file.   
  - Setting `Opt-AtticCeilings = NA` will leave the archetype's ceiling definitions 
    unchanged.
  - Attic ceilings are all ceilings of type Attic/Gable, Attic/Hip or Scissor
  - __substitute-h2k.rb__ will apply the same definition to all attic ceilings, 
    regardless of their size or original construction. 
  - The "Ceiling Codes" code library group must contain an entry for the name specified
    when the ceiling code name option is used.
  - This option should not be combined with the Opt-Ceilings option!
    
#### Sample `.choice` definition for  `Opt-AtticCeilings`  
         Opt-AtticCeilings = CeilR50
         
#### Sample `.options` definition for  `Opt-AtticCeilings`

         attribute:name = Opt-AtticCeilings
         *attribute:tag:1  = <Opt-Ceiling>       ! H2K uses this for library code name
         *attribute:tag:2  = OPT-H2K-EffRValue   ! H2K R-value (Imperial) or "NA" if use code name in tag 1
         *attribute:default = CeilR50
         
         *option:NA:value:1 = NA     ! No change
         *option:NA:value:2 = NA
         *option:NA:cost:total = 0
         
         *option:UsrSpecR40:value:1 =  NA       ! H2K: NA or code name for code library
         *option:UsrSpecR40:value:2 =  40       ! H2K R-value (Imperial)
         *option:UsrSpecR40:cost:total = 0
         
         *option:CeilR40:value:1 =  CeilR40     ! H2K: Code name must exist in code library
         *option:CeilR40:value:2 =  NA          ! H2K: No user-specified R-value (Imperial), code name used!
         *option:CeilR40:cost:total = 0
         
         *option:CeilR50:value:1 = CeilR50                
         *option:CeilR50:value:2 = NA              ! H2K R-value (Imperial)         
         *option:CeilR50:cost:total    =   0       
         <snip>

         
<a name="opt-cath-ceilings"></a>
### `Opt-CathCeilings`

* **Description** : Defines insulation levels in cathedral ceilings only.
* **Typical values**: Keyword specifying desired ceiling assembly (e.g. `CeilR40`, `CeilR50`...)
* **HOT2000 bindings**:  Depending on the definitions in the options file, 
    __substitute-h2k.rb__ will do one of two things:
    1. Replace the ceiling construction definition with a specified code from the 
       construction code library
    2. Replace the ceiling construction definition with a user-specified RSI value 
       from the .options file. 
    
>>**Note** that the .options file should provide the construction code **OR** the 
    R-value - not both!

* **Other things you should know**: 
  - __substitute-h2k.rb__ expects Imperial/US insulation values (R-19, R-22, R-26...), not
    RSI values. __substitute-h2k.rb__ will automatically convert R-values to RSI 
    when creating the .h2k file.   
  - Setting option to `NA` will leave the archetype's ceiling definitions 
    unchanged.
  - __substitute-h2k.rb__ will apply the same definition to all cathedral ceilings, 
    regardless of their size or original construction. 
  - The "Flat or Cathedral Ceiling Codes" code library group must contain an entry for 
    the name specified when the ceiling code name option is used.
  - This option should not be combined with the Opt-Ceilings option!
    
#### Sample `.choice` definition for  `Opt-CathCeilings`  
         Opt-CathCeilings = CeilR50
         
#### Sample `.options` definition for  `Opt-CathCeilings`

         attribute:name = Opt-CathCeilings
         *attribute:tag:1  = <Opt-Ceiling>       ! H2K uses this for library code name
         *attribute:tag:2  = OPT-H2K-EffRValue   ! H2K R-value (Imperial) or "NA" if use code name in tag 1
         *attribute:default = CeilR50
         
         *option:NA:value:1 = NA     ! No change
         *option:NA:value:2 = NA
         *option:NA:cost:total = 0
         
         *option:UsrSpecR40:value:1 =  NA       ! H2K: NA or code name for code library
         *option:UsrSpecR40:value:2 =  40       ! H2K R-value (Imperial)
         *option:UsrSpecR40:cost:total = 0
         
         *option:CeilR40:value:1 =  CeilR40     ! H2K: Code name must exist in code library
         *option:CeilR40:value:2 =  NA          ! H2K: No user-specified R-value (Imperial), code name used!
         *option:CeilR40:cost:total = 0
         
         *option:CeilR50:value:1 = CeilR50                
         *option:CeilR50:value:2 = NA              ! H2K R-value (Imperial)         
         *option:CeilR50:cost:total    =   0       
         <snip>

         
<a name="opt-flat-ceilings"></a>
### `Opt-FlatCeilings`

* **Description** : Defines insulation levels in flat ceilings only.
* **Typical values**: Keyword specifying desired ceiling assembly (e.g. `CeilR40`, `CeilR50`...)
* **HOT2000 bindings**:  Depending on the definitions in the options file, 
    __substitute-h2k.rb__ will do one of two things:
    1. Replace the ceiling construction definition with a specified code from the 
       construction code library
    2. Replace the ceiling construction definition with a user-specified RSI value 
       from the .options file. 
    
>>**Note** that the .options file should provide the construction code **OR** the 
    R-value - not both!

* **Other things you should know**: 
  - __substitute-h2k.rb__ expects Imperial/US insulation values (R-19, R-22, R-26...), not
    RSI values. __substitute-h2k.rb__ will automatically convert R-values to RSI 
    when creating the .h2k file.   
  - Setting option to `NA` will leave the archetype's ceiling definitions 
    unchanged.
  - __substitute-h2k.rb__ will apply the same definition to all flat ceilings, 
    regardless of their size or original construction. 
  - The "Flat or Cathedral Ceiling Codes" code library group must contain an entry for 
    the name specified when the ceiling code name option is used.
  - This option should not be combined with the Opt-Ceilings option!
    
#### Sample `.choice` definition for  `Opt-FlatCeilings`  
         Opt-FlatCeilings = CeilR50
         
#### Sample `.options` definition for  `Opt-FlatCeilings`

         attribute:name = Opt-FlatCeilings
         *attribute:tag:1  = <Opt-Ceiling>       ! H2K uses this for library code name
         *attribute:tag:2  = OPT-H2K-EffRValue   ! H2K R-value (Imperial) or "NA" if use code name in tag 1
         *attribute:default = CeilR50
         
         *option:NA:value:1 = NA     ! No change
         *option:NA:value:2 = NA
         *option:NA:cost:total = 0
         
         *option:UsrSpecR40:value:1 =  NA       ! H2K: NA or code name for code library
         *option:UsrSpecR40:value:2 =  40       ! H2K R-value (Imperial)
         *option:UsrSpecR40:cost:total = 0
         
         *option:CeilR40:value:1 =  CeilR40     ! H2K: Code name must exist in code library
         *option:CeilR40:value:2 =  NA          ! H2K: No user-specified R-value (Imperial), code name used!
         *option:CeilR40:cost:total = 0
         
         *option:CeilR50:value:1 = CeilR50                
         *option:CeilR50:value:2 = NA              ! H2K R-value (Imperial)         
         *option:CeilR50:cost:total    =   0       
         <snip>
         

<a name="opt-h2kfoundation"></a>
### `Opt-H2KFoundation`

* **Description** : Defines the below-grade insulation configuration and specification
* **Typical values**: Keyword specifying desired foundation insulation configuration
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will modify all foundations in the 
  .h2k file to reflect the corresponding parameters from the options file. For each 
  foundation specification, the options file must define:
    1. The foundation configuration code (.e.g. `BCCB_4_B`, `BCEB_4_ALL`, `SCB_29_ALL`). Note that this code is a concatenation of the HOT2000 configuration type (e.g., BCCB_4) and a suffix (ALL, B, W, C, S)
    2. The interior wall construction code, __or__ 
    3. The interior wall specified R-value (Note: One of the two must be NA)
    4. The exterior wall specified R-value or NA
    5. The R-value of insulation added to the slab or NA.  
* **Other things you should know**: 
  - Below grade heat loss is also sensitive to the _depth of frost_ input. Work is underway 
  to add support to HTAP for this parameter. 
  - Setting `Opt-H2KFoundation = NA ` leaves the archetype basements unchanged.
  
  
#### Sample `.choice` definition for  `Opt-H2KFoundation`  
         Opt-H2KFoundation = OBCminR12-Slab0R
         
#### Sample `.options` definition for  `Opt-H2KFoundation`

         *attribute:name   = Opt-H2KFoundation
         *attribute:tag:1  = OPT-H2K-ConfigType     ! Fnd config code (e.g., BCCB_4 + _ALL or _B or _W or _C or _S)
         *attribute:tag:2  = OPT-H2K-IntWallCode    ! Int. wall Fav/UsrDef code for BCCx_x, BCIx_x
         *attribute:tag:3  = OPT-H2K-IntWall-RValue ! Int. wall User-Specified R-value (Imp) for BCCx_x, BCIx_x
         *attribute:tag:4  = OPT-H2K-ExtWall-RVal   ! Ext. wall User-Specified R-value (Imp) for BCCx_x, BCEx_x
         *attribute:tag:5  = OPT-H2K-BelowSlab-RVal ! Below slab User-Specified R-value(Imp) for BCCB_x, BCEB_x
         *attribute:default = NA
         
         *option:NA:value:1 = NA
         *option:NA:value:2 = NA
         *option:NA:value:3 = NA
         *option:NA:value:4 = NA
         *option:NA:value:5 = NA
         *option:NA:cost:total = 0
         
         *option:OBCminR12-Slab0R:value:1 = BCIN_1_B    ! Ref# 1 - change all Basements (ALL/B/W/C/S)
         *option:OBCminR12-Slab0R:value:2 = BsmWllR12
         *option:OBCminR12-Slab0R:value:3 = NA        ! R for userSpec option (set to NA if use int wall code in tag 2)
         *option:OBCminR12-Slab0R:value:4 = NA
         *option:OBCminR12-Slab0R:value:5 = NA
         *option:OBCminR12-Slab0R:cost:total = 0
         
         *option:OBCminR12-Slab24R:value:1 = BCIB_4_ALL  ! Ref# 22 - change ALL foundations in model (that apply)
         *option:OBCminR12-Slab24R:value:2 = BsmWllR12
         *option:OBCminR12-Slab24R:value:3 = NA          ! R for userSpec option (set to NA if use int wall code in tag 2)
         *option:OBCminR12-Slab24R:value:4 = NA          ! External wall added R-value (Imp)
         *option:OBCminR12-Slab24R:value:5 = 24          ! Below slab R-value
         *option:OBCminR12-Slab24R:cost:total = 0
         <snip>


<a name="opt-h2kfoundation-slabcrawl"></a>
### `Opt-FoundationSlabCrawl`

* **Description** : Defines the below-grade insulation configuration and specification for Slab-On-Grade and Crawlspace foundations
* **Typical values**: Keyword specifying desired foundation insulation configuration
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will modify Slab and/or Crawl foundations in the 
  .h2k file to reflect the corresponding parameters from the options file. For each 
  foundation specification, the options file must define:
    1. The foundation configuration code (.e.g. `SCB_29_ALL`, `SCB_29_S`). Note that this code is a concatenation of the HOT2000 configuration type (e.g., BCCB_4) and a suffix (ALL, B, W, C, S)
    2. The interior wall construction code, __or__ 
    3. The interior wall specified R-value (Note: One of the two must be NA)
    4. The exterior wall specified R-value or NA
    5. The R-value of insulation added to the slab or NA.  
* **Other things you should know**: 
  - Below grade heat loss is also sensitive to the _depth of frost_ input. Work is underway 
  to add support to HTAP for this parameter. 
  - Setting `Opt-H2KFoundation = NA ` leaves the archetype basements unchanged.
  
  
#### Sample `.choice` definition for  `Opt-H2KFoundationSlabCrawl`  
         Opt-H2KFoundationSlabCrawl = OBCminR12-Slab0R
         
#### Sample `.options` definition for  `Opt-H2KFoundation`

         *attribute:name   = Opt-H2KFoundationSlabCrawl
         *attribute:tag:1  = OPT-H2K-ConfigType     ! Fnd config code (e.g., BCCB_4 + _ALL or _B or _W or _C or _S)
         *attribute:tag:2  = 
         *attribute:tag:3  = 
         *attribute:tag:4  = 
         *attribute:tag:5  = 
         *attribute:default = NA
         
         <snip>


<a name="opt-exposedfloor"></a>
### `Opt-ExposedFloor`

* **Description**: Defines insulation levels in exposed floors, including spaces 
    above garages, and porches. 
* **Typical values**: Keyword specifying desired floor assembly (e.g. `BaseExpFloor-R31`)
* **HOT2000 bindings**:  Depending on the definitions in the options file, 
    __substitute-h2k.rb__ will do one of two things:
    1. Replace the floor construction definition with a specified code from the 
       construction code library
    2. Replace the floor construction definition with a user-specified RSI value 
       from the .options file. 
    
>>**Note** that the .options file should provide the construction code **OR** the 
    R-value - not both!

* **Other things you should know**: 
  - __substitute-h2k.rb__ expects US insulation values (R-19, R-22, R-26...), not
    RSI values. __substitute-h2k.rb__ will automatically convert R-values to RSI 
    when creating the .h2k file.   
  - Setting `Opt-ExposedFloor = NA` will leave the archetype's floor definitions to 
    be unchanged.

#### Sample `.choice` definition for  `Opt-ExposedFloor`  
         Opt-ExposedFloor  = BaseExpFloor-R31
         
#### Sample `.options` definition for  `Opt-ExposedFloor`

         *attribute:name   = Opt-ExposedFloor 
         *attribute:tag:1  = OPT-H2K-CodeName    ! Use "NA" (or non-existent name) for user-Specified case
         *attribute:tag:2  = OPT-H2K-EffRValue   ! User-Specified R-value (Imperial)
         *attribute:default = NA          
         
         *option:NA:value:1 = NA    ! For H2K - No change
         *option:NA:value:2 = NA    ! For H2K - No change
         *option:NA:cost:total    = 0
         
         *option:BaseExpFloor-R31:value:1 = NA     ! Use "NA" (or non-existent name) for user-Specified case
         *option:BaseExpFloor-R31:value:2 = 31     ! User-Specified R-value (Imperial) / NA for code name
         *option:BaseExpFloor-R31:cost:total    = 0
         
         *option:ExpFloorFlash&Batt-R36:value:1 = NA     ! Use "NA" (or non-existent name) for user-Specified case
         *option:ExpFloorFlash&Batt-R36:value:2 = 36     ! User-Specified R-value (Imperial) / NA for code name
         *option:ExpFloorFlash&Batt-R36:cost:total    = 0
         <snip>
     
         

<a name="opt-casementwindows"></a>
### `Opt-CasementWindows`

* **Description** : Defines performance characteristics of windows.
* **Typical values**: Keyword specifying the desired window specification 
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will alter the window 
  definitions according to the corresponding specifications in the .options file. 
  In each case, the script will replace the existing window definition with 
  a definition from the code library. The values provided in the .options file 
  must match window definition names in the code library. For instance, 
  in the example below, the codes `DblLeHcAir`, `DblLeHcArg` and `DblLeScArg` 
  must all exist in the code library. 
* **Other things you should know**: 
  - __substitute-h2k__ supports unique window definitions by orientation; each 
    window spec must explicitly name the corresponding code for each of the S/SE/E/NE/N/NW/W/SW 
    orientations. __substitute-h2k.rb__ will modify the windows for each orientation 
    accordingly. 
  - Within HOT2000's code editor, you may define windows using overall U-value and 
    SHGC inputs, or via HOT2000's legacy window code selector.  
  - This tag will edit all window types in walls, not just casements. However, it will not change
    windows in doors or ceilings (i.e., skylights).
  - Setting `Opt-CasementWindows = NA ` leaves the archetype windows unchanged.

  
#### Sample `.choice` definition for  `Opt-CasementWindows`  
         Opt-CasementWindows = DoubleLowEHardCoatAirFill
         
#### Sample `.options` definition for  `Opt-CasementWindows`

          *attribute:start 
          *attribute:name  = Opt-CasementWindows
          *attribute:tag:1 = <Opt-win-S-CON>     ! Also H2K S windows lib code name
          *attribute:tag:2 = <Opt-win-E-CON>     ! Also H2K E windows lib code name
          *attribute:tag:3 = <Opt-win-N-CON>     ! Also H2K N windows lib code name
          *attribute:tag:4 = <Opt-win-W-CON>     ! Also H2K W windows lib code name
          *attribute:tag:5 = <Opt-win-SE-CON>     ! H2K SE windows lib code name
          *attribute:tag:6 = <Opt-win-SW-CON>     ! H2K SW windows lib code name
          *attribute:tag:7 = <Opt-win-NE-CON>     ! H2K NE windows lib code name
          *attribute:tag:8 = <Opt-win-NW-CON>     ! H2K NW windows lib code name
          *attribute:default = DoubleLowEHardCoatArgFill
          
          *option:NA:value:1 = NA   
          *option:NA:value:2 = NA
          *option:NA:value:3 = NA   
          *option:NA:value:4 = NA
          *option:NA:value:5 = NA   
          *option:NA:value:6 = NA
          *option:NA:value:7 = NA   
          *option:NA:value:8 = NA
          *option:NA:cost:total = 0.0
          
          *option:DoubleLowEHardCoatAirFill:value:1 = DblLeHcAir   
          *option:DoubleLowEHardCoatAirFill:value:2 = DblLeHcAir
          *option:DoubleLowEHardCoatAirFill:value:3 = DblLeHcAir   
          *option:DoubleLowEHardCoatAirFill:value:4 = DblLeHcAir
          *option:DoubleLowEHardCoatAirFill:value:5 = DblLeHcAir   
          *option:DoubleLowEHardCoatAirFill:value:6 = DblLeHcAir
          *option:DoubleLowEHardCoatAirFill:value:7 = DblLeHcAir   
          *option:DoubleLowEHardCoatAirFill:value:8 = DblLeHcAir
          *option:DoubleLowEHardCoatAirFill:cost:total    = 0.0 
          
          *option:DoubleArgon_HighGainOnSouth:value:1 = DblLeHcArg   
          *option:DoubleArgon_HighGainOnSouth:value:2 = DblLeScArg 
          *option:DoubleArgon_HighGainOnSouth:value:3 = DblLeScArg   
          *option:DoubleArgon_HighGainOnSouth:value:4 = DblLeScArg 
          *option:DoubleArgon_HighGainOnSouth:value:5 = DblLeScArg   
          *option:DoubleArgon_HighGainOnSouth:value:6 = DblLeScArg 
          *option:DoubleArgon_HighGainOnSouth:value:7 = DblLeScArg   
          *option:DoubleArgon_HighGainOnSouth:value:8 = DblLeScArg 
          *option:DoubleArgon_HighGainOnSouth:cost:total    = 0
          <snip>

          
<a name="opt-skylights"></a>
### `Opt-Skylights`

* **Description** : Defines performance characteristics of skylights (i.e., windows in ceilings).
* **Typical values**: Keyword specifying the desired skylight specification 
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will alter the ceiling window 
  definitions according to the corresponding specifications in the .options file. 
  In each case, the script will replace the existing windows (in ceilings) definitions with 
  the definition from the code library. The values provided in the .options file 
  must match window definition names in the code library. For instance, 
  in the example below, the code `SkylightDef` must exist in the code library. 
* **Other things you should know**: 
  - __substitute-h2k__ supports unique window definitions by orientation; each 
    window spec must explicitly name the corresponding code for each of the S/SE/E/NE/N/NW/W/SW 
    directions. __substitute-h2k.rb__ will modify the windows for each orientation 
    accordingly. 
  - Within HOT2000's code editor, you may define windows using overall U-value and 
    SHGC inputs, or via HOT2000's legacy window code selector.  
  - This tag will edit all ceiling window types. It will not effect windows in doors or walls.
  - Setting `Opt-Skylights = NA` leaves the archetype ceiling windows unchanged.

  
#### Sample `.choice` definition for  `Opt-Skylights`  
         Opt-Skylights = SkylightDef
         
#### Sample `.options` definition for  `Opt-Skylights`

          *attribute:start 
          *attribute:name  = Opt-Skylights
          *attribute:tag:1 = <Opt-win-S-CON>     ! Also H2K S windows lib code name
          *attribute:tag:2 = <Opt-win-E-CON>     ! Also H2K E windows lib code name
          *attribute:tag:3 = <Opt-win-N-CON>     ! Also H2K N windows lib code name
          *attribute:tag:4 = <Opt-win-W-CON>     ! Also H2K W windows lib code name
          *attribute:tag:5 = <Opt-win-SE-CON>     ! H2K SE windows lib code name
          *attribute:tag:6 = <Opt-win-SW-CON>     ! H2K SW windows lib code name
          *attribute:tag:7 = <Opt-win-NE-CON>     ! H2K NE windows lib code name
          *attribute:tag:8 = <Opt-win-NW-CON>     ! H2K NW windows lib code name
          *attribute:default = SkylightDef
          
          *option:NA:value:1 = NA   
          *option:NA:value:2 = NA
          *option:NA:value:3 = NA   
          *option:NA:value:4 = NA
          *option:NA:value:5 = NA   
          *option:NA:value:6 = NA
          *option:NA:value:7 = NA   
          *option:NA:value:8 = NA
          *option:NA:cost:total = 0.0
          
          *option:SkylightDef:value:1 = SkylightDef   
          *option:SkylightDef:value:2 = SkylightDef
          *option:SkylightDef:value:3 = SkylightDef   
          *option:SkylightDef:value:4 = SkylightDef
          *option:SkylightDef:value:5 = SkylightDef   
          *option:SkylightDef:value:6 = SkylightDef
          *option:SkylightDef:value:7 = SkylightDef   
          *option:SkylightDef:value:8 = SkylightDef
          *option:SkylightDef:cost:total = 0.0
          <snip>

          
          
<a name="opt-door-windows"></a>
### `Opt-DoorWindows`

* **Description** : Defines performance characteristics of windows in doors.
* **Typical values**: Keyword specifying the desired door window specification 
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will alter the door window 
  definitions according to the corresponding specifications in the .options file. 
  In each case, the script will replace the existing windows (in doors) definitions with 
  the definition from the code library. The values provided in the .options file 
  must match window definition names in the code library. For instance, 
  in the example below, the codes `DoorWinDef` must exist in the code library. 
* **Other things you should know**: 
  - __substitute-h2k__ supports unique door window definitions by orientation; each 
    window spec must explicitly name the corresponding code for each of the S/SE/E/NE/N/NW/W/SW 
    directions. __substitute-h2k.rb__ will modify the door windows for each orientation 
    accordingly. 
  - Within HOT2000's code editor, you may define windows using overall U-value and 
    SHGC inputs, or via HOT2000's legacy window code selector.  
  - This tag will edit all door window types. It will not effect skylights or windows in walls.
  - Setting `Opt-DoorWindows = NA` leaves the archetype ceiling windows unchanged.

  
#### Sample `.choice` definition for  `Opt-DoorWindows`  
         Opt-DoorWindows = DoubleLowEHardCoatAirFill
         
#### Sample `.options` definition for  `Opt-DoorWindows`

          *attribute:start 
          *attribute:name  = Opt-DoorWindows
          *attribute:tag:1 = <Opt-win-S-CON>     ! Also H2K S windows lib code name
          *attribute:tag:2 = <Opt-win-E-CON>     ! Also H2K E windows lib code name
          *attribute:tag:3 = <Opt-win-N-CON>     ! Also H2K N windows lib code name
          *attribute:tag:4 = <Opt-win-W-CON>     ! Also H2K W windows lib code name
          *attribute:tag:5 = <Opt-win-SE-CON>     ! H2K SE windows lib code name
          *attribute:tag:6 = <Opt-win-SW-CON>     ! H2K SW windows lib code name
          *attribute:tag:7 = <Opt-win-NE-CON>     ! H2K NE windows lib code name
          *attribute:tag:8 = <Opt-win-NW-CON>     ! H2K NW windows lib code name
          *attribute:default = DoorWinDef
          
          *option:NA:value:1 = NA   
          *option:NA:value:2 = NA
          *option:NA:value:3 = NA   
          *option:NA:value:4 = NA
          *option:NA:value:5 = NA   
          *option:NA:value:6 = NA
          *option:NA:value:7 = NA   
          *option:NA:value:8 = NA
          *option:NA:cost:total = 0.0
          
          *option:DoorWinDef:value:1 = DoorWinDef   
          *option:DoorWinDef:value:2 = DoorWinDef
          *option:DoorWinDef:value:3 = DoorWinDef   
          *option:DoorWinDef:value:4 = DoorWinDef
          *option:DoorWinDef:value:5 = DoorWinDef   
          *option:DoorWinDef:value:6 = DoorWinDef
          *option:DoorWinDef:value:7 = DoorWinDef   
          *option:DoorWinDef:value:8 = DoorWinDef
          *option:DoorWinDef:cost:total = 0.0
          <snip>


<a name="opt-doors"></a>
### `Opt-Doors`

* **Description** : Defines performance characteristics of doors.
* **Typical values**: Keyword specifying the desired door specification 
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will alter the door  
  definitions according to the corresponding specifications in the .options file. 
  In each case, the script will replace the existing door R-value with 
  the value specified. 
* **Other things you should know**: 
  - This tag will edit all doors in the archetype.
  - Setting `Opt-Doors = NA` leaves the archetype doors unchanged.

  
#### Sample `.choice` definition for  `Opt-Doors`  
         Opt-Doors = SolidWood
         
#### Sample `.options` definition for  `Opt-Doors`

          *attribute:start 
          *attribute:name  = Opt-Doors
          *attribute:tag:1 = <Opt-R-value>     ! User specified R-value (Imperial) of door
          *attribute:default = SolidWood

          *option:NA:value:1 = NA   
          *option:NA:cost:total = 0.0

          *option:SolidWood:value:1 = 2.2
          *option:SolidWood:cost:total = 0.0

          *option:HollowWood:value:1 = 2.1
          *option:HollowWood:cost:total = 0.0

          *option:SteelFG:value:1 = 1.65      ! Steel Fibreglass core
          *option:SteelFG:cost:total = 0.0

          *option:SteelPS:value:1 = 5.57      ! Steel polystyrene core
          *option:SteelPS:cost:total = 0.0

          *option:SteelMDSprayCore:value:1 = 6.47    ! Steel medium density spray foam core
          *option:SteelMDSprayCore:cost:total = 0.0

          *option:FibrePolyCore:value:1 = 4.83    ! Fibreglass polystyrene core
          *option:FibrePolyCore:cost:total = 0.0

          *option:FibreMDSprayCore:value:1 = 5.57    ! Fibreglass medium density spray foam core
          *option:FibreMDSprayCore:cost:total = 0.0
          <snip>

          
          
<a name="opt-h2k-pv"></a>
### `Opt-H2K-PV`

* **Description**: Defines HOT2000's PV module inputs 
* **Typical values**:  Keyword defining PV system specification. 
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will modify 
    the PV system definition using the corresponding parameters from the 
    .options file. 
* **Other things you should know**: 
  - If `Opt-H2K-PV  = NA`, __substitute-h2k.rb__ will leave the PV system unchanged 
    in the archetype. If the provided archetype does not include a PV system, the run will
    also examine cases without PV systems. However, if the base archetype includes 
    a PV system, setting `Opt-H2K-PV  = NA` will leave this system unchanged, and 
    all runs will include a PV system. If you are studing designs with- and without PV,
    make sure PV is removed from the base archetype. 
  - PV system sizes are commonly described according to their peak output (e.g. 5kW, 10kW), 
    but HOT2000 describes PV according to collector area and system efficiency. The 
    actual DC output from these systems will vary by location. 

    
  
#### Sample `.choice` definition for  `Opt-H2K-PV`  
         Opt-H2K-PV = MonoSi-10kW
         
#### Sample `.options` definition for  `Opt-H2K-PV`

           *attribute:start
           *attribute:name  = Opt-H2K-PV
           *attribute:tag:1 = Opt-H2K-Area           ! m2
           *attribute:tag:2 = Opt-H2K-Slope          ! degrees from horizontal
           *attribute:tag:3 = Opt-H2K-Azimuth        ! degrees from S
           *attribute:tag:4 = Opt-H2K-PVModuleType   ! 1:Mono-Si, 2:Poly-Si, 3:a-Si, 4:CdTe, 5:CIS, 6:UsrSpec
           *attribute:tag:5 = Opt-H2K-GridAbsRate    ! %
           *attribute:tag:6 = Opt-H2K-InvEff         ! %
           *attribute:default = NA
           
           *option:NA:value:1 = NA
           *option:NA:value:2 = NA
           *option:NA:value:3 = NA
           *option:NA:value:4 = NA
           *option:NA:value:5 = NA
           *option:NA:value:6 = NA
           *option:NA:cost:total  = 0
           
           *option:MonoSi-5kW:value:1 = 53             !53m2 is required area for 5 kW for Mono-Si
           *option:MonoSi-5kW:value:2 = 18.4           !22.6 for 5-12 roof in Prince George and 18.4 for 4-12 slope in Kelowna
           *option:MonoSi-5kW:value:3 = 0
           *option:MonoSi-5kW:value:4 = 1
           *option:MonoSi-5kW:value:5 = 90
           *option:MonoSi-5kW:value:6 = 90
           *option:MonoSi-5kW:cost:total = 21500      !$21500 assumed cost for 5 kW PV system for Prince George & Kelowna LEEP
           
           *option:MonoSi-10kW:value:1 = 107          !107m2 is required area for 10 kW for Mono-Si
           *option:MonoSi-10kW:value:2 = 18.4         !22.6 for 5-12 roof in Prince George and 18.4 for 4-12 slope in Kelowna
           *option:MonoSi-10kW:value:3 = 0
           *option:MonoSi-10kW:value:4 = 1
           *option:MonoSi-10kW:value:5 = 90
           *option:MonoSi-10kW:value:6 = 90
           *option:MonoSi-10kW:cost:total = 33395     !$33395 assumed cost for 10 kW PV system for Prince George & Kelowna LEEP
           
           *option:MonoSi-200m2:value:1 = 200
           *option:MonoSi-200m2:value:2 = 43
           *option:MonoSi-200m2:value:3 = 0
           *option:MonoSi-200m2:value:4 = 1
           *option:MonoSi-200m2:value:5 = 90
           *option:MonoSi-200m2:value:6 = 90
           *option:MonoSi-200m2:cost:total = 0
           <snip>

<a name="opt-hvacsystem"></a>
### `Opt-HVACSystem`

>> <mark>**THIS PARAMETER IS LIKELY TO BE REDEFINED IN THE NEAR FUTURE**</mark>

* **Description** : Defines the heating and cooling system performance. 
* **Typical values**: Keyword defining heating and cooling system specification (e.g. `basefurnace`)
* **HOT2000 bindings**:  When run, __substitute-h2k.rb__ will modify the heating
  and cooling system definitions according to the parameters defined in the .options file.
* **Other things you should know**: 
  - Currently this tag includes parameters for Type 1 (+/- AC), Type 2 and combo systems (P9). 
    <mark>The number of inputs needed depends on which system is selected</mark>
  - Contrary to its name, the definition of this system does not include ventilation. Mechanical ventilation is defined in `Opt-HRVspec`
  - Setting `Opt-HVACSystem = NA ` leaves the archetype HVAC system unchanged.

  
#### Sample `.choice` definition for  `Opt-HVACSystem`  
         Opt-Archetype = MediumSFD
         
#### Sample `.options` definition for  `Opt-HVACSystem`
         *attribute:start
         *attribute:name    = Opt-HVACSystem          ! System Name. 
         *attribute:tag:1  = Opt-H2K-SysType1        ! H2K: Baseboards, Furnace, Boiler, ComboHeatDhw, P9
         *attribute:tag:2  = Opt-H2K-SysType2        ! H2K: None, AirHeatPump, WaterHeatPump, GroundHeatPump, AirConditioning
         *attribute:tag:3  = Opt-H2K-Type1Fuel       ! H2K: 1:Elect, 2:NGas, 3:Oil, 4:Prop, 5:Mixed Wood, 6:Hardwood, 7:Softwood, 8: Pellets  
         *attribute:tag:4  = Opt-H2K-Type1EqpType    ! H2K: Heating system equipment type --> depends on fuel and SysType1
         *attribute:tag:5  = Opt-H2K-Type1CapOpt     ! H2K: 1:UserSpec, 2:Calculated
         ! 6-8: Type 1 tags - Type 1 equipment only 
         *attribute:tag:6  = Opt-H2K-Type1CapVal     ! H2K: Type 1: Capacity value. 
         *attribute:tag:7  = Opt-H2K-Type1EffType    ! H2K: Type 1: true=SS, false=AFUE
         *attribute:tag:8  = Opt-H2K-Type1EffVal     ! H2K: Type 1: Efficiency value (0->100)
         ! 9-10: Fan tags, needed for all definitions 
         *attribute:tag:9  = Opt-H2K-Type1FanCtl     ! H2K: 1:Auto, 2:Continuous
         *attribute:tag:10 = Opt-H2K-Type1EEMotor    ! H2K: true/false
         ! 11-20: Type 2 /HP definitions 
         *attribute:tag:11  = Opt-H2K-Type2CCaseH     ! H2K: Type2: CrankCaseHeater Value ? 
         *attribute:tag:12  = Opt-H2K-Type2Func       ! H2K: Type2: Function - ASHP :( 1 = Heating, 2 = Heating/Cooling  )
         *attribute:tag:13  = Opt-H2K-Type2Type       ! H2K: Type2: Type - ASHP :( 1 = Central split, 2=Central single pkg, 3= MiniSplit Ductless )
                                                      !                    WSHP : Nil 
                                                      !                    GSHP : Nil                    
         *attribute:tag:14  = Opt-H2K-Type2CapOpt     ! H2K: Type2: Capacity Option (1:UserSpec, 2:Calculated)
         *attribute:tag:15  = Opt-H2K-Type2CapVal     ! H2K: Type2: Capacity value (if specified?)
         *attribute:tag:16  = Opt-H2K-Type2HeatCOP    ! COP Efficiency in heating (0->4ish...)
         *attribute:tag:17  = Opt-H2K-Type2CoolCOP    ! COP Efficiency in cooling (0->4ish...)
         *attribute:tag:18  = Opt-H2K-Type2CutoffType ! Cut off type 1: balance point, 2: Restricted , 3 unrestricted 
         *attribute:tag:19  = Opt-H2K-Type2CutoffTemp ! Cut off temperature (oC)
         *attribute:tag:20  = Opt-H2K-CoolOperWindow  ! Operable window fraction for cooling (%, 0->100)
         ! 21-onwards: P9 data. Used for type1 P9 systems only 
         *attribute:tag:21  = Opt-H2K-P9-manufacturer  ! P9 manufacturer (does nothing outside of GUI!)
         *attribute:tag:22  = Opt-H2K-P9-model         ! P9 model (does nothing outside of GUI!)
         *attribute:tag:23  = Opt-H2K-P9-TPF           ! P9 TPF
         *attribute:tag:24  = Opt-H2K-P9-AnnualElec    ! P9 Annual energy use 
         *attribute:tag:25  = Opt-H2K-P9-WHPF          ! P9 WHPF2*option
         *attribute:tag:26  = Opt-H2K-P9-burnerInput   ! P9 Burner input 
         *attribute:tag:27  = Opt-H2K-P9-recEff        ! P9 Recovery efficiency
         *attribute:tag:28  = Opt-H2K-P9-ctlsPower     ! P9 Ctl power (W)
         *attribute:tag:29  = Opt-H2K-P9-circPower     ! P9 Circ power (W)
         *attribute:tag:30  = Opt-H2K-P9-dailyUse      ! P9 Daily use ???
         *attribute:tag:31  = Opt-H2K-P9-stbyLossWFan  ! P9 Standby loss (fan)
         *attribute:tag:32  = Opt-H2K-P9-stbyLossNoFan ! P9 Standby loss (no fan)
         *attribute:tag:33  = Opt-H2K-P9-oneHrHotWater ! P9 one hour rating (HW)
         *attribute:tag:34  = Opt-H2K-P9-oneHourConc   ! P9 one hour rating concurrent
         *attribute:tag:35  = Opt-H2K-P9-netEff15      ! P9 net efficiency - 15
         *attribute:tag:36  = Opt-H2K-P9-netEff40      ! P9 net efficiency - 40
         *attribute:tag:37  = Opt-H2K-P9-netEff100     ! P9 net efficiency - 100 
         *attribute:tag:38  = Opt-H2K-P9-elecUse15     ! P9 Elec use - 15
         *attribute:tag:39  = Opt-H2K-P9-elecUse40     ! P9 Elec use - 40
         *attribute:tag:40  = Opt-H2K-P9-elecUse100    ! P9 Elec use - 100 
         *attribute:tag:41  = Opt-H2K-P9-blowPower15   ! P9 BlowerPower - 15
         *attribute:tag:42  = Opt-H2K-P9-blowPower40   ! P9 BlowerPower - 40      
         *attribute:tag:43  = Opt-H2K-P9-blowPower100  ! P9 BlowerPower - 100 
     
         
         *option:gas-furnace-ecm:value:1 = Furnace
         *option:gas-furnace-ecm:value:2 = None
         *option:gas-furnace-ecm:value:3 = 2
         *option:gas-furnace-ecm:value:4 = 2       ! Spark ignition
         *option:gas-furnace-ecm:value:5 = 2       ! User specified capacity
         *option:gas-furnace-ecm:value:6 = NA      ! Low capacity furnace 
         *option:gas-furnace-ecm:value:7 = true    ! SS
         *option:gas-furnace-ecm:value:8 = 96      ! Efficiency
         *option:gas-furnace-ecm:value:9 = 1       ! Auto fan control
         *option:gas-furnace-ecm:value:10 = true    ! EE motor
         *option:gas-furnace-ecm:cost:total    = 0
         
         *option:elec-baseboard:value:1 = Baseboards
         *option:elec-baseboard:value:2 = None
         *option:elec-baseboard:value:3 = 1
         *option:elec-baseboard:value:4 = NA
         *option:elec-baseboard:value:5 = 2
         *option:elec-baseboard:value:6 = NA
         *option:elec-baseboard:value:7 = 1
         *option:elec-baseboard:value:8 = 100
         *option:elec-baseboard:value:9 = NA
         *option:elec-baseboard:value:10 = NA
         *option:elec-baseboard:cost:total       = 0
         
         *option:pellet-stove:value:1 = Furnace
         *option:pellet-stove:value:2 = None
         *option:pellet-stove:value:3 = 8        ! pellets  
         *option:pellet-stove:value:4 = 6       ! pellet stove
         *option:pellet-stove:value:5 = 2       ! H2K: 1:UserSpec, 2:Calculated
         *option:pellet-stove:value:6 = NA      ! H2K: Type 1: Capacity value. 
         *option:pellet-stove:value:7 = true    ! H2K: Type 1: true=SS, false=AFUE
         *option:pellet-stove:value:8 = 75      ! H2K: Type 1: Efficiency value (0->100)
         *option:pellet-stove:value:9 = 1       ! H2K: 1:Auto, 2:Continuous
         *option:pellet-stove:value:10 = true    ! H2K: EE motor true/false
         *option:pellet-stove:cost:total       = 0
         
         
         *option:CCASHP:value:1 = Baseboards            ! H2K: Baseboards, Furnace, Boiler, ComboHeatDhw, P9    
         *option:CCASHP:value:2 = AirHeatPump           ! H2K: None, AirHeatPump, WaterHeatPump, GroundHeatPump, AirConditioning    
         *option:CCASHP:value:3 =  NA                   ! H2K: 1:Elect, 2:NGas, 3:Oil, 4:Prop, 5:Mixed Wood, 6:Hardwood, 7:Softwood, 8: Pellets      
         *option:CCASHP:value:4 =  NA                   ! H2K: Heating system equipment type --> depends on fuel and SysType1    
         *option:CCASHP:value:5 =  1                    ! H2K: Type 1 capacity 1:UserSpec, 2:Calculated    
         *option:CCASHP:value:6 =  12                   ! H2K: Capacity value.     
         *option:CCASHP:value:7 =  true                 ! H2K: true=SS, false=AFUE    
         *option:CCASHP:value:8 =  100                  ! H2K: Efficiency value (0->100)    
         *option:CCASHP:value:9 = 1                     ! H2K: 1:Auto, 2:Continuous    
         *option:CCASHP:value:10 = true                  ! H2K: ee-motor true/false   
         *option:CCASHP:value:11 = 60                    ! H2K: Crankcase heater?
         *option:CCASHP:value:12 = 1                     ! Function heating/cooling 
         *option:CCASHP:value:13 = 1                     ! Type: central split 
         *option:CCASHP:value:14 = 2                     ! Capacity: Calculated 
         *option:CCASHP:value:15 = NA                    ! Capacity value (W)
         *option:CCASHP:value:16 = 3                     ! Heating COP 
         *option:CCASHP:value:17 = NA                    ! Cooling COP 
         *option:CCASHP:value:18 = 2                     ! Cut off type : Restricted 
         *option:CCASHP:value:19 = -22                   ! Cut off temp 
         *option:CCASHP:value:20 = 25                    ! Operable window area
         *option:CCASHP:cost:total   = 0                 
         
         *option:GSHP:value:1  = Baseboards            ! H2K: Baseboards, Furnace, Boiler, ComboHeatDhw, P9    
         *option:GSHP:value:2  = GroundHeatPump        ! H2K: None, AirHeatPump, WaterHeatPump, GroundHeatPump, AirConditioning    
         *option:GSHP:value:3  =  NA                   ! H2K: 1:Elect, 2:NGas, 3:Oil, 4:Prop, 5:Mixed Wood, 6:Hardwood, 7:Softwood, 8: Pellets      
         *option:GSHP:value:4 =  NA                   ! H2K: Heating system equipment type --> depends on fuel and SysType1    
         *option:GSHP:value:5 =  2                    ! H2K: Type 1 capacity 1:UserSpec, 2:Calculated    
         *option:GSHP:value:6 =  6                    ! H2K: Capacity value.     
         *option:GSHP:value:7 =  true                 ! H2K: true=SS, false=AFUE    
         *option:GSHP:value:8 =  100                  ! H2K: Efficiency value (0->100)    
         *option:GSHP:value:9 = 1                     ! H2K: 1:Auto, 2:Continuous    
         *option:GSHP:value:10 = false                 ! H2K: ee-motor true/false   
         *option:GSHP:value:11 = 60                    ! H2K: Crankcase heater?
         *option:GSHP:value:12 = 2                     ! Function heating/cooling 
         *option:GSHP:value:13 = NA                    ! Type: central split 
         *option:GSHP:value:14 = 2                     ! Capacity: Calculated 
         *option:GSHP:value:15 = NA                    ! Capacity value (W)
         *option:GSHP:value:16 = 3                     ! Heating COP 
         *option:GSHP:value:17 = 3                     ! Cooling COP 
         *option:GSHP:value:18 = 2                     ! Cut off type : Restricted 
         *option:GSHP:value:19 = -20                   ! Cut off temp 
         *option:GSHP:value:20 = 25                    ! Operable window area
         *option:GSHP:cost:total = 0                 
         
         ! Combo
         *option:ComboHeatA:value:1 = P9                  ! H2K: Baseboards, Furnace, Boiler, ComboHeatDhw, P9    
         *option:ComboHeatA:value:2 = None                ! H2K: None, AirHeatPump, WaterHeatPump, GroundHeatPump, AirConditioning    
         *option:ComboHeatA:value:3 = 2                   ! H2K: 1:Elect, 2:NGas, 3:Oil, 4:Prop, 5:Mixed Wood, 6:Hardwood, 7:Softwood, 8: Pellets  
         *option:ComboHeatA:value:4 = 2                  ! H2K: Heating system equipment type --> depends on fuel and SysType1    
         *option:ComboHeatA:value:5 = 2                  ! H2K: Type 1 capacity 1:UserSpec, 2:Calculated    
         *option:ComboHeatA:value:6 = NA                 ! H2K: Type 1: Capacity value 
         *option:ComboHeatA:value:7 = true               ! H2K: Type 1: true=SS, false=AFUE
         *option:ComboHeatA:value:8 = 95                 ! H2K: Type 1: Efficiency value (0->100)
         *option:ComboHeatA:value:9 = 1                  ! H2K: 1:Auto, 2:Continuous   
         *option:ComboHeatA:value:10 = true               ! H2K: EE motor (true/false) 
         *option:ComboHeatA:value:11  = Navien^America    ! P9 manufacturer (just an identifier - does nothing)
         *option:ComboHeatA:value:12  = 13-06-M0424-2     ! P9 model (just an identifier - does nothing)
         *option:ComboHeatA:value:13  = 0.98              ! P9 TPF
         *option:ComboHeatA:value:14  = 1463              ! P9 Annual energy use 
         *option:ComboHeatA:value:15  = 0.95              ! P9 WHPF2*option
         *option:ComboHeatA:value:16  = NA             	 ! P9 Burner input (NA when tag 11 set to 2 for Calculated)
         *option:ComboHeatA:value:17  = 95                ! P9 Recovery efficiency
         *option:ComboHeatA:value:18  = 7                 ! P9 Ctl power (W)
         *option:ComboHeatA:value:19  = 74                ! P9 Circ power (W)
         *option:ComboHeatA:value:20  = 0.19              ! P9 Daily use ???
         *option:ComboHeatA:value:21  = 0                 ! P9 Standby loss (fan)
         *option:ComboHeatA:value:22  = 0                 ! P9 Standby loss (no fan)
         *option:ComboHeatA:value:23  = 1444              ! P9 one hour rating (HW)
         *option:ComboHeatA:value:24  = 1459              ! P9 one hour rating concurrent
         *option:ComboHeatA:value:25  = 94                ! P9 net efficiency - 15
         *option:ComboHeatA:value:26  = 96                ! P9 net efficiency - 40
         *option:ComboHeatA:value:27  = 91                ! P9 net efficiency - 100 
         *option:ComboHeatA:value:28  = 145               ! P9 Elec use - 15
         *option:ComboHeatA:value:29  = 231               ! P9 Elec use - 40
         *option:ComboHeatA:value:30  = 548               ! P9 Elec use - 100 
         *option:ComboHeatA:value:31  = 107               ! P9 BlowerPower - 15
         *option:ComboHeatA:value:32  = 117               ! P9 BlowerPower - 40
         *option:ComboHeatA:value:33  = 418               ! P9 BlowerPower - 100 
         *option:ComboHeatA:cost:total = 0
         
         <snip>
         
         
<a name="opt-dhwsystem"></a>         
### `Opt-DHWSystem`

* **Description**: Defines hot water system type and performance 
* **Typical values**: Keyword defining DHW system specifications 
* **HOT2000 bindings**:  When run, __substitute-h2k.rb__ will modify the
  archetype's hot water system type and performance to match the corresponding 
  parameters from the .options file.
* **Other things you should know**: 
  - if `Opt-HVAC` is set to a combo system, this option will be ignored. 
  - Setting `Opt-DHWSystem = NA ` leaves the archetype domestic hot water system unchanged.

#### Sample `.choice` definition for  `Opt-DHWSystem`  
         Opt-DHWSystem = ElecInstantaneous
         
#### Sample `.options` definition for  `Opt-DHWSystem`

          *attribute:start
          *attribute:name  = Opt-DHWSystem
          *attribute:tag:1 = Opt-H2K-Fuel                          ! DHW Fuel code (1-7)
          *attribute:tag:2 = Opt-H2K-TankType                      ! DHW tank type code (code depends on fuel!)
          *attribute:tag:3 = Opt-H2K-TankSize                      ! DHW tank size code (volume code)
          *attribute:tag:4 = Opt-H2K-EF                            ! DHW Energy Factor code
          *attribute:tag:5 = Opt-H2K-IntHeatPumpCOP                ! DHW Integrated HP COP
          *attribute:tag:6 = Opt-H2K-FlueDiameter                  ! DHW Flue diameter
          *attribute:default = BaseDHW 
          
          *option:NA:value:1 = NA
          *option:NA:value:2 = NA
          *option:NA:value:3 = NA
          *option:NA:value:4 = NA
          *option:NA:value:5 = NA
          *option:NA:value:6 = NA
          *option:NA:cost:total = 0
          
          *option:BaseDHW:value:1 = 2       ! Gas
          *option:BaseDHW:value:2 = 2       ! Conventional Tank
          *option:BaseDHW:value:3 = 190     ! Litres (50 USGal)
          *option:BaseDHW:value:4 = 0.67    ! EF
          *option:BaseDHW:value:5 = NA        
          *option:BaseDHW:value:6 = 76.2
          *option:BaseDHW:cost:total = 0
          
          *option:ElecInstantaneous:value:1 = 1         ! Elec
          *option:ElecInstantaneous:value:2 = 4         ! Instantaneous
          *option:ElecInstantaneous:value:3 = 0         ! Litres
          *option:ElecInstantaneous:value:4 = 0.936     ! EF
          *option:ElecInstantaneous:value:5 = NA        
          *option:ElecInstantaneous:value:6 = 0
          *option:ElecInstantaneous:cost:total = 0
          
          <snip>

         

<a name="opt-dwhrsystem"></a> 
### `Opt-DWHRSystem`
* **Description** : Indicates presence and performance of drainwater heat recovery systems 
* **Typical values**: Keyword defining DWHR system specifications 
* **HOT2000 bindings**:  When run, __substitute-h2k.rb__ will modify the
  archetype to include the specified drain-water heat recovery system, according to 
  the specifications provided in the .options file.
* **Other things you should know**: 
  - HOT2000's DWHR inputs permit specification of shower frequency, temperature  and duration
    Running the model in ERS mode may override these inputs.
  - setting `Opt-DWHRSystem = NA` leaves the drain water heat recovery system unchanged.


  
#### Sample `.choice` definition for  `Opt-DWHRSystem`  
         Opt-DWHRSystem = DWHR-eff-30
         
#### Sample `.options` definition for  `Opt-DWHRSystem`

         *attribute:start
         *attribute:name  = Opt-DWHRSystem
         *attribute:tag:1 = Opt-H2K-HasDWHR                      ! DWHR "true" or "false"
         *attribute:tag:2 = Opt-H2K-DWHR-preheatShowerTank       ! DWHR Preheat shower only "true" or "false"
         *attribute:tag:3 = Opt-H2K-DWHR-Manufacturer            ! DWHR Manufacturer: Generic, EccoInnovation^Technologies^Inc., Power-Pipe, Watercycles^Energy^Recovery^Inc., Generic
         *attribute:tag:4 = Opt-H2K-DWHR-Model                   ! DWHR Model: See H2K DWHR screen
         *attribute:tag:5 = Opt-H2K-DWHR-Efficiency_code         ! DWHR Efficiency code (1, 2 or 3) -- Always seems to be 2!!
         *attribute:tag:6 = Opt-H2K-DWHR-Effectiveness9p5        ! DWHR effectiveness at 9.5
         *attribute:tag:7 = Opt-H2K-DWHR-ShowerTemperature_code  ! DWHR Shower temperature code (1, 2 or 3)
         *attribute:tag:8 = Opt-H2K-DWHR-ShowerHead_code         ! DWHR Showhead flow rate code (0-4)
         *attribute:tag:9 = Opt-H2K-DWHR-showerLength            ! DWHR Shower length in minutes e.g. 6.5
         *attribute:tag:10 = Opt-H2K-DWHR-dailyShowers             ! DWHR Number of daily showers e.g. 2.45
         
         *attribute:default = none
         
         *option:NA:value:1   = NA
         *option:NA:value:2   = NA
         *option:NA:value:3   = NA
         *option:NA:value:4   = NA
         *option:NA:value:5   = NA
         *option:NA:value:6   = NA
         *option:NA:value:7   = NA
         *option:NA:value:8   = NA
         *option:NA:value:9   = NA
         *option:NA:value:10  = NA
         *option:NA:cost:total = 0
         
         *option:DWHR-eff-30:value:1   = true          ! Has DHWR? true/false
         *option:DWHR-eff-30:value:2   = false         ! DWHR Preheat shower only "true" or "false"
         *option:DWHR-eff-30:value:3   = Power-Pipe    ! DWHR Manufacturer: Generic, EccoInnovation^Technologies^Inc., 
         *option:DWHR-eff-30:value:4   = C3-39         ! DWHR Model: See H2K DWHR screen
         *option:DWHR-eff-30:value:5   = 2             ! DWHR Efficiency code (1, 2 or 3) -- Always seems to be 2!!
         *option:DWHR-eff-30:value:6   = 31.0          ! DWHR effectiveness @ 9.5 l/m  (%)
         *option:DWHR-eff-30:value:7   = 2             ! DWHR Shower temperature code (1, 2 or 3)
         *option:DWHR-eff-30:value:8   = 2             ! DWHR Shower flow  code / head dcode (1-4) 
         *option:DWHR-eff-30:value:9   = 4.53          ! Shower lenght (minutes)
         *option:DWHR-eff-30:value:10  = 3             ! number of daily showers
         *option:DWHR-eff-30:cost:total = 615           !$615 assumed cost for LEEP Prince George & Kelowna
         
         *option:DWHR-eff-42:value:1   = true          ! Has DHWR? true/false
         *option:DWHR-eff-42:value:2   = false         ! DWHR Preheat shower only "true" or "false"
         *option:DWHR-eff-42:value:3   = Power-Pipe    ! DWHR Manufacturer: Generic, EccoInnovation^Technologies^Inc., 
         *option:DWHR-eff-42:value:4   = C4-57         ! DWHR Model: See H2K DWHR screen
         *option:DWHR-eff-42:value:5   = 2             ! DWHR Efficiency code (1, 2 or 3) -- Always seems to be 2!!
         *option:DWHR-eff-42:value:6   = 41.5          ! DWHR effectiveness @ 9.5 l/m  (%)
         *option:DWHR-eff-42:value:7   = 2             ! DWHR Shower temperature code (1, 2 or 3)
         *option:DWHR-eff-42:value:8   = 2             ! DWHR Shower flow  code / head dcode (1-4) 
         *option:DWHR-eff-42:value:9   = 4.53          ! Shower lenght (minutes)
         *option:DWHR-eff-42:value:10  = 3             ! number of daily showers
         *option:DWHR-eff-42:cost:total = 0
         <snip>
         
         

<a name="opt-HRVspec"></a> 
### `Opt-HRVspec` 

* **Description** : Creates/configures a whole-house ventilator item to the provided specification.
* **Typical values**: Keyword specifying the HRV system  (i.e., the mechanical ventilation system)
* **HOT2000 bindings**:   
  - `OPT-H2K-FlowReq`: Integer flag indicating if H2K should warn when insufficient ventilation is provided. 
    Values:  `1:F326, 2:ACH, 3:Flow Rate, 4:Not Applicable`
  - `OPT-H2K-AirDistType`: Integer flag indicating if ventilator is tied to central air or dedicated duct work. 
    Values: `1: Forced air heating ductwork, 2: DedIcated low volume ductwork, 3: 2 with transfer fans`
  - `OPT-H2K-OpSched` : Specified number of minutes/day the unit will operate for. Sets         `HouseFile/House/Ventilation/WholeHouse/OperationSchedule`
  - `OPT-H2K-HRVSupply`: Balanced supply/exhaust rate . Sets 
     `HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv[supplyFlowRate]` and
     `HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv[exhaustFlowRate]`
  - `OPT-H2K-Rating1`:  SRE at 0°C. Sets `HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv[efficiency1]`
  - `OPT-H2K-Rating1`:  SRE at -25°C. Sets `HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv[efficiency2]`
* **Other things you should know**: 
  - Setting `Opt-HRVspec = NA` leaves the archetype ventilation system unchanged. If no mechanical ventilation system is defined in the archetype, then none will be run in HTAP. If the archetype has a mechanical system defined, then no changes will be made to it for the HTAP run.

  
#### Sample `.choice` definition for  `Opt-HRVspec`
         Opt-HRVspec = HRV_60
         
#### Sample `.options` definition for  `Opt-HRVspec`

         *attribute:start 
         *attribute:name    = Opt-HRVspec 
         *attribute:tag:3   = OPT-H2K-FlowReq      ! 1:F326, 2:ACH, 3:Flow Rate, 4:Not Applicable
         *attribute:tag:4   = OPT-H2K-AirDistType  ! 1: Forced air heating ductwork, 2: Dedecated low volume ductwork, 3: 2 with transfer fans
         *attribute:tag:5   = OPT-H2K-OpSched      ! User Specified minutes/day
         *attribute:tag:6   = OPT-H2K-HRVSupply    ! 
         *attribute:tag:7   = OPT-H2K-Rating1
         *attribute:tag:8   = OPT-H2K-Rating2
         *attribute:default = CEF_SPEC
         
         *option:NA:value:3 = NA     ! F326
         *option:NA:value:4 = NA     ! Forced air heating ductwork
         *option:NA:value:5 = NA   ! Min./Day
         *option:NA:value:6 = NA    ! L/s (exhaust = supply)
         *option:NA:value:7 = NA    ! Eff% @ Rating1
         *option:NA:value:8 = NA    ! Eff% @ Rating2
         *option:NA:cost:total = 0
         
         *option:CEF_SPEC:value:3 = 1     ! F326
         *option:CEF_SPEC:value:4 = 1     ! Forced air heating ductwork
         *option:CEF_SPEC:value:5 = 480   ! Min./Day
         *option:CEF_SPEC:value:6 = 60    ! L/s (exhaust = supply)
         *option:CEF_SPEC:value:7 = 64    ! Eff% @ Rating1
         *option:CEF_SPEC:value:8 = 64    ! Eff% @ Rating2
         *option:CEF_SPEC:cost:total = 0
         
         
         *option:HRV_60:value:3 = 1     ! F326
         *option:HRV_60:value:4 = 1     ! Forced air heating ductwork
         *option:HRV_60:value:5 = 1440   ! Min./Day
         *option:HRV_60:value:6 = 60    ! L/s (exhaust = supply)
         *option:HRV_60:value:7 = 60    ! Eff% @ Rating1     Prince George used 70% at 0, 61% at -25C at $1386
         *option:HRV_60:value:8 = 55    ! Eff% @ Rating2
         *option:HRV_60:cost:total = 1496       !$1496 cost assumed for LEEP Kelowna optimization
         <snip>
         


<a name="opt-fuelcost"></a>
### `Opt-FuelCost`   

* **Description** : Defines the fuel costs used to calculate the annual cost of electricity, gas, oil, propane and/or wood required by the specific arcehtype defined by __substitute-h2k.rb__. HOT2000 requires as exact match between the fuel cost selected and an entry in the FuelLib_.flc file
* **Typical values**: Keyword indicating fuel library name
* **HOT2000 bindings**:   
  - `OPT-LibraryFile`: Fuel Library filename, file must be defined in the `StdLibs` directory, FuelLib16.flc (fuel library files are `*.flc`)
  - `OPT-ElecName`: the name of the entry in the fuel library that defines the electricity cost structure, by usage
  - `OPT-GasName`: the name of the entry in the fuel library that defines the gas cost structure, by usage
  - `OPT-OilName`: the name of the entry in the fuel library that defines the oil cost structure, by usage
  - `OPT-PropaneName`: the name of the entry in the fuel library that defines the propane cost structure, by usage
  - `OPT-WoodName`:the name of the entry in the fuel library that defines the wood cost structure, by usage

* **Other things you should know**: 
 - there is a known issue when there is not an exact match between the `Opt-*Name` and an entry in the fuel cost library file. A solution is being developed.
 - setting `Opt-FuelCost = NA` leaves the fuel costs unchanged.
  
#### Sample `.choice` definition for  `Opt-FuelCost`
         Opt-FuelCost = rates2016
         
#### Sample `.options` definition for  `Opt-FuelCost`
        *attribute:start
        *attribute:name     = Opt-FuelCost
        *attribute:tag:1    = <OPT-LibraryFile>
        *attribute:tag:2    = <OPT-ElecName>
        *attribute:tag:3    = <OPT-GasName>
        *attribute:tag:4    = <OPT-OilName>
        *attribute:tag:5    = <OPT-PropaneName>
        *attribute:tag:6    = <OPT-WoodName>
        *attribute:default  = rates2016
        <snip>
        
<a name="opt-roofpitch"></a>
### `Opt-RoofPitch`   

* **Description** : Roof pitch is used by HOT2000 to calcualte the volume of the attic. The air change rate to the attic, its volume and solar gains, combined with the outdoor air temperature are used the heat balance to estimate the average attic temperature. That temperature is then used to estimate the heat loss or gain through the attic ceiling to the house.
* **Typical values**: Keyword indicating slope of the roof line, e.g. 3-12
* **Other things you should know**: 
 - setting `Opt-RoofPitch = NA` leaves the roof pitch unchanged.
  
#### Sample `.choice` definition for  `Opt-RoofPitch`
     Opt-RoofPitch = 3-12
         
#### Sample `.options` definition for  `Opt-RoofPitch`
    *attribute:start
    *attribute:name     = Opt-RoofPitch
    *attribute:tag:1    = Opt-H2K-RoofSlope
    *attribute:default  = 8-12 

    *option:NA:value:1 = NA
    *option:NA:cost:total  = 0

    *option:3-12:value:1 = 0.250
    *option:3-12:cost:total  = 0

    *option:6-12:value:1 = 0.500
    *option:6-12:cost:total  = 0

    *option:8-12:value:1 = 0.667
    *option:8-12:cost:total  = 0

    *option:12-12:value:1 = 1.000
    *option:12-12:cost:total  = 0
    <snip>


<a name="opt-ruleset"></a>
### `Opt-Ruleset`   

* **Description** : The rule set option is used to access a Ruby function that ensures compliance with specific named rule sets such as the NBC 9.36 code or R-2000.
* **Typical values**: Keyword indicating rule set name, e.g., "NBC9_36_noHRV"
* **Other things you should know**: 
  - Any new rule set requires Ruby code to be added to __substitute-h2k.rb__ to enforce the attribute settings required for compliance 
  - This option over-rides other option choices that may appear in the choice file in order to achieve compliance
  
#### Sample `.choice` definition for  `Opt-Ruleset`
     Opt-Ruleset = NBC9_36_noHRV
         
#### Sample `.options` definition for  `Opt-Ruleset`
    *attribute:start
    *attribute:name = Opt-Ruleset 
    *attribute:tag:1 = <NotNOTARealTag>
    *attribute:default = NA
    *attribute:on-error = ignore 

    *option:NA:value:1    = NA
    *option:NA:cost:total = 0

    *option:NBC9_36_noHRV:value:1    = NBC9_36_noHRV
    *option:NBC9_36_noHRV:cost:total = 0

    *option:NBC9_36_HRV:value:1    = NBC9_36_HRV
    *option:NBC9_36_HRV:cost:total = 0
    <snip>


<a name="outputs"></a> 
Outputs 
------
The output file `HTAP-prm-output.csv` contains one line of data for each HTAP run. Each line of output contains **3 main segments** of information: 1. the run number and unique run identifiers, 2. the HOT2000 run output, and 3. the input data as defined above. The input data is repeated in the output to allow for HTAP run identification.

Each of these output segments is defined below.

<a name="#runnumber"></a>
### `RunNumber` 
The first 4 columns of the output for each HTAP run are:`RunNumber`,`RunDir`,`iiiiiiinput.ChoiceFile`, and `Recovered-results`. Only the first column - `RunNumber` - is a unique identifier for each run. The other 3 columns can be ignored.

<a name="#h2k-outputs"></a>
### `H2K-outputs` 
The next 34 columns are pulled from the HOT2000 results, in the _.h2k_ xml file.

  - `Energy-Total-GJ`: the total energy consumption from the HOT2000 run for the archetype and the inputs defined above.
  - `Ref-En-Total-GJ`: the total energy consumption for the HOT2000 reference house run (in ERS mode)
All outputs named `Util-Bill-_` are calculated based on the consumption of each fuel as calculated by HOT2000 (for each applicable use: heating, cooling, hot water, ventilation, and plug loads) using and the `Opt-FuelCost` identified for each HTAP run. 
  - `Util-Bill-gross`: the sum of all the fuel costs, i.e., `Util-Bill-Elec + Util-Bill-Gas + Util-Bill-Prop + Util-Bill-Oil + Util-Bill-Wood`
  - `Util-PV-revenue`: the net annual PV generation (kWh) * PV Tarrif ($/kWh). HTAP Assumes that all annual PV energy available is used to reduce house electricity to zero first, the balance is sold to utility at the rate PV Tarrif. _This is currently set to 0_ 
  - `Util-Bill-Net = Util-Bill-gross - Util-PV-revenue`
  - `Util-Bill-Elec`, `Util-Bill-Gas`, `Util-Bill-Prop`, `Util-Bill-Oil`,`Util-Bill-Wood`: the individual fuel consumptions * fuel cost rates.
  - `Energy-PV-kWh`: the amount of energy generated by any PV system identified (kWh)
  - `Gross-HeatLoss-GJ`: the annual heat loss as calculated in HOT2000
  - `Energy-HeatingGJ`: the total heating energy required
  - `AuxEnergyReq-HeatingGJ`: the furnace output, i.e., the total furnace thermal output
  - `Energy-CoolingGJ`: the amount of cooling energy 	 
  - `Energy-VentGJ`: the mechanical ventilation energy consumption 
  - `Energy-DHWGJ`: the water heating energy consumption
  - `Energy-PlugGJ`: the plug load energy consumption - based on standard operating conditions.
The following 5 output report the consumption of each fuel, in the units used for fuel costs. These output report the consumption for all uses, as applicable: heating, cooling, hot water, ventilation, and plug loads.
  - `EnergyEleckWh`: the total number of kWh of electricity consumed
  - `EnergyGasM3`: the total number of m3 of natural gas consumed
  - `EnergyOil_l`: the total number of L of oil consumed
  - `EnergyProp_L`: the total number of L of propane consumed
  - `EnergyWood_cord`: the number of cords of wood consumed
  - `Upgrade-cost`: if the upgrade costs are defined in the .options file, then the costs for each upgrade considered will be summed.
  _Note: many options do not include costs at this time._
  - `SimplePaybackYrs`: This is a legacy output that should not be used
  - `PEAK-Heating-W` and `PEAK-Cooling-W`: Peak heating and cooling loads.
  - `PV-size-kW`: size of the PV system in kW        	 
  - `Floor-Area-m2`: conditioned floor area in m2
  - `TEDI_kWh_m2`: Thermal Energy Demand Intensity = AuxEnergyReq-HeatingGJ (converted to kWh) / Floor-Area-m2
  - `MEUI_kWh_m2`: Mechanical Energy Utilization Intensity = (Energy-HeatingGJ + Energy-CoolingGJ + Energy-VentGJ + Energy-DHWGJ)(converted to kWh) / Floor-Area-m2
  - `ERS-Value`: the Energy Rating System Value is only available if the file is run in ERS mode.
  - `NumTries` and `LapsedTime`: are for information purposes only.

<a name="#input.data"></a>
### `input.data`
All of the inputs (#inputs) defined above are repeated for each HTAP run to help identify. These inputs are identified by the tag `input.Opt-__`.


<a name="#legacy"></a>
## Legacy files and inputs
### The HOT2000.options file (depreciated) 
<mark>This section refers to a file format that may not be supported in future versions</mark>

Most of HTAP’s data are stored in the .options file.  The option file contains a list of attributes that HTAP can edit within HOT2000 input (.h2k) files. The HOT2000 input files are XML format files. An excerpt from the HOT2000.options file follows:

         !-----------------------------------------------------------------------
         ! Photovoltaics 
         ! Use internal HOT2000 PV Generation model
         ! Choice file used to specify Internal PV OR External PV but not both!
         !-----------------------------------------------------------------------
         *attribute:start
         *attribute:name  = Opt-H2K-PV
         *attribute:tag:1 = Opt-H2K-Area           ! m2
         *attribute:tag:2 = Opt-H2K-Slope          ! degrees from horizontal
         *attribute:tag:3 = Opt-H2K-Azimuth        ! degrees from S
         *attribute:tag:4 = Opt-H2K-PVModuleType   ! 1:Mono-Si, 2:Poly-Si, 3:a-Si, 4:CdTe, 5:CIS, 
                                                   ! 6:UsrSpec
         *attribute:tag:5 = Opt-H2K-GridAbsRate    ! %
         *attribute:tag:6 = Opt-H2K-InvEff         ! %
         *attribute:default = NA
         
         *option:NA:value:1 = NA
         *option:NA:value:2 = NA
         *option:NA:value:3 = NA
         *option:NA:value:4 = NA
         *option:NA:value:5 = NA
         *option:NA:value:6 = NA
         *option:NA:cost:total  = 0
         
         *option:MonoSi-5kW:value:1 = 53             !53m2 is required area for 5 kW for Mono-Si
         *option:MonoSi-5kW:value:2 = 18.4           !22.6 for 5-12 roof in Prince George
         *option:MonoSi-5kW:value:3 = 0
         *option:MonoSi-5kW:value:4 = 1
         *option:MonoSi-5kW:value:5 = 90
         *option:MonoSi-5kW:value:6 = 90
         *option:MonoSi-5kW:cost:total = 21500      !$21500 assumed cost for 5 kW PV system 
         
         *option:MonoSi-10kW:value:1 = 107          !107m2 is required area for 10 kW for Mono-Si
         *option:MonoSi-10kW:value:2 = 18.4         !22.6 for 5-12 roof in Prince George 
         *option:MonoSi-10kW:value:3 = 0
         *option:MonoSi-10kW:value:4 = 1
         *option:MonoSi-10kW:value:5 = 90
         *option:MonoSi-10kW:value:6 = 90
         *option:MonoSi-10kW:cost:total = 33395     !$33395 assumed cost for 10 kW PV system for ! 
                                                    !Prince George & Kelowna LEEP

          *attribute:end
         <snip>
    

This section defines data for the `Opt-H2K-PV` attribute.  Three options are available: `NA`, 
`MonoSi-5kW`, and `MonoSi-10kW`.  __substitute-h2k.rb__ interprets the 
`NA` specification as instructions to leave the existing .h2k file 
unaltered – that is, the values for those inputs that were provided when the file
was saved in HOT2000 will be preserved when the file is run in HTAP. 
The remainder of the data for each attribute describe tags, values, 
and costs. Each tag identifies a key word that substitute-h2k.rb 
associates with part of the HOT2000 data model. For instance, `Opt-H2K-InvEff` 
refers to the inverter efficiency of PV modules. Each value 
provides the alphanumeric input that must be substituted within the 
.h2k file. For example, the inverter efficiency will be set to 
90% for the `MonoSI-10kW` case in the snippet above. 
