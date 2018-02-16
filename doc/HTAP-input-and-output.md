
Input and Output in HTAP
========================

Input/Output model 
------------------

To be written

Inputs - 
------

### 1) `Opt-Location`

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
         
### 2) `Opt-Archetype`

* **Description** : Defines the .h2k file that will be used for the basis of a 
    HTAP run 
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
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-Archetype = MediumSFD
         
#### Sample `.options` definition for  `Opt-Location`

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
         


### 3) `Opt-ACH`

* **Description** : Defines the infiltration characteristics of the building, using 
  inputs similar to those collected to a blower-door test. 
* **Typical values**: Keyword indicating level of airtightness (e.g. `ACH_3`, `ACH_1_5`)
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will map the keyword to values 
  in the .options file, and then edit the .h2k file to reflect the same air leakage 
  performance target. 
* **Other things you should know**: 
  - HTAP can presently only change the blower-door test air change rate; options to 
    adjust the house volume, ELA or site characteristics are not supported.
  - Setting `Opt-ACH = NA` will cause __substitute-h2k.rb__ to leave air infiltration 
    unchanged int he archetype 
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-ACH = ACH_7
         
#### Sample `.options` definition for  `Opt-Location`

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
         
         


### 4) `Opt-MainWall`

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



### X) `Opt-XXX =`

* **Description** : 
* **Typical values**: 
* **HOT2000 bindings**:  
* **Other things you should know**: 
  - Note 1
  - Note 2
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-Archetype = MediumSFD
         
#### Sample `.options` definition for  `Opt-Location`

         *attribute:
         


         <snip>



### X) `Opt-XXX =`

* **Description** : 
* **Typical values**: 
* **HOT2000 bindings**:  
* **Other things you should know**: 
  - Note 1
  - Note 2
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-Archetype = MediumSFD
         
#### Sample `.options` definition for  `Opt-Location`

         *attribute:
         


         <snip>



### X) `Opt-XXX =`

* **Description** : 
* **Typical values**: 
* **HOT2000 bindings**:  
* **Other things you should know**: 
  - Note 1
  - Note 2
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-Archetype = MediumSFD
         
#### Sample `.options` definition for  `Opt-Location`

         *attribute:
         


         <snip>
         

Skipped for now 
---------------
Opt-Ruleset 
Opt-FuelCost         
         
