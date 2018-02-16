
Input and Output in HTAP
========================

Contents
------------------
1. [Input/output model](#IOmodel)
2. [Inputs](#inputs)
    1. [`Opt-Location`](#opt-location)
    2. [`Opt-Archetype`](#opt-archetype)
    3. [`Opt-ACH`](#opt-ach)
    4. [`Opt-Mainwall`](#opt-mainwall)
    5. [`Opt-Ceilings`](#opt-ceilings)
    6. [`Opt-H2KFoundation`](#opt-h2kfoundation)
    7. [`Opt-ExposedFloor`](#opt-exposedfloor)
    7. [`Opt-CasementWindows`](#opt-casementwindows)
    8. [`Opt-H2K-PV`](#opt-h2k-pv)
    9. [`Opt-HVAC`](#opt-hvac)
    10. [`Opt-DHWsystem`](#opt-dhwsystem)
    11. [`Opt-DHWRsystem`](#opt-dwhrsystem)
    12. [`Opt-HRV`](#opt-hrv)
3. [Legacy parameters not currently supported](#opt-skipped)    
   
<a name="IOmodel"></a>
Input/Output model 
------------------

To be written

<a name="inputs"></a> 
Inputs 
------

<a name="opt-location"></a>
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

<a name="opt-archetype"></a>         
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
         

<a name="opt-ach"></a>
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
         
         

<a name="opt-mainwall"></a>
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


<a name="opt-ceilings"></a>
### 5) `Opt-Ceilings`

* **Description** : Defines insulation levels in ceilings.
* **Typical values**: Keyword specifying desired celing assembly (e.g. `CeilR40`, `CeilR50`...)
* **HOT2000 bindings**:  Depending on the definitions in the options file, 
    __substitute-h2k.rb__ will do one of two things:
    1. Replace the ceiling construction definition with a specified code from the 
       construction code library
    2. Replace the ceiling construction definition with a user-specified RSI value 
       from the .options file. 
    
>>**Note** that the .options file should provide the construction code **OR** the 
    R-value - not both!

* **Other things you should know**: 
  - __substitute-h2k.rb__ expects US insulation values (R-19, R-22, R-26...), not
    RSI values. __substitute-h2k.rb__ will automatically convert R-values to RSI 
    when creating the .h2k file.   
  - Setting `Opt-Ceilings = NA` will leave the archetype's ceiling definitions to 
    be unchanged.
  - __substitute-h2k.rb__ will apply the same definition to all ceilings, 
    regardless of their size or original construction. 
  - Work to add support for cathedral and scissor ceilings is currently underway
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-Ceilings = CeilR50
         
#### Sample `.options` definition for  `Opt-Location`

         attribute:name = Opt-Ceilings
         *attribute:tag:1  = <Opt-Ceiling>       ! H2K also uses this for library code name
         *attribute:tag:2  = OPT-H2K-EffRValue   ! H2K R-value (Imperial) or "NA" if use code name in tag 1
         *attribute:default = CeilR50
         
         *option:NA:value:1 = NA     ! No change
         *option:NA:value:2 = NA
         *option:NA:cost:total = 0
         
         *option:UsrSpecR40:value:1 =  NA       ! H2K: NA or code name must NOT exist in code library
         *option:UsrSpecR40:value:2 =  40       ! H2K R-value (Imperial)
         *option:UsrSpecR40:cost:total = 0
         
         *option:CeilR40:value:1 =  CeilR40     ! H2K: Code name must exist in code library
         *option:CeilR40:value:2 =  NA          ! H2K: No user-specified R-value (Imperial), code name used!
         *option:CeilR40:cost:total = 0
         
         *option:CeilR50:value:1 = CeilR50                
         *option:CeilR50:value:2 = NA              ! H2K R-value (Imperial)         
         *option:CeilR50:cost:total    =   0       !$0 is assumed cost for LEEP Kelowna optimization


<a name="opt-h2kfoundation"></a>
### 6) `Opt-H2KFoundation`

* **Description** : Defines the below-grade insulation configuration and specification
* **Typical values**: Keyword specifying desired foundation insulation configuration
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will modify all basements in the 
  .h2k file to reflect the corresponding parameters front the options file. For each 
  foundation specification, the options file must define:
    1. The foundation configuration code (.e.g. `BCCB_4`, `BCEB_4_ALL`, `SCB_29_ALL`)
    2. The interior wall construction code, __or__ 
    3. The interior wall specified R-value
    4. The exterior wall specified R-value 
    5. The R-valye of insulation added to the slab.  
* **Other things you should know**: 
  - Below grade heat loss is also sensitive to the _depth of frost_ input. Work is underway 
  to add support to HTAP for this parameter. 
  - Setting `Opt-H2KFoundation = NA ` leaves the archetype basements unchanged.
  
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-H2KFoundation = OBCminR12-Slab0R
         
#### Sample `.options` definition for  `Opt-Location`

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


<a name="opt-exposedfloor"></a>
### 7) `Opt-ExposedFloor`

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

#### Sample `.choice` definition for  `Opt-Location`  
         Opt-ExposedFloor  = BaseExpFloor-R31
         
#### Sample `.options` definition for  `Opt-Location`

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
### 8) `Opt-CasementWindows`

* **Description** : Defines performance characteristics of windows.
* **Typical values**: Keyword specifying the desired window specification 
* **HOT2000 bindings**: When run, __substitute-h2k.rb__ will alter the window 
  definitions according to the corresponding specifications in the .options file. 
  In each case, the script will replace the existing window definition with 
  definition from the code library. The values provided in the .options file 
  must match window definition names in the code library. For instance, 
  in the example below, the codes `DblLeHcAir`, `DblLeHcArg` and `DblLeScArg` 
  must all exist in the code library. 
* **Other things you should know**: 
  - __substitute-h2k__ supports unique window definitions by orientation; each 
    window spec must explicitly name the corresponding code for each of  the S/SE/E/NE/N/NW/W/SW. 
    cardinal points. __substitute-h2k.rb__ will modify the windows for each orientation 
    accordingly. 
  - Within HOT2000's code editor, you may define windows using overall U-value and 
    SHGC inputs, or via HOT2000's legacy window code selector.  
  - This tag will edit all window types, not just casements. 
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-CasementWindows = DoubleLowEHardCoatAirFill
         
#### Sample `.options` definition for  `Opt-Location`

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

<a name="opt-h2k-pv"></a>
### 9) `Opt-H2K-PV`

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
  - PV system sizes are commonly described according to it peak output (e.g. 5kW, 10kW), 
    but HOT2000 describes PV according to collector area and system efficiency. The 
    actual DC output from these systems will vary by location. 

    
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-H2K-PV = MonoSi-10kW
         
#### Sample `.options` definition for  `Opt-Location`

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
           
           *attribute:end
         


         <snip>

<a name="opt-hvac"></a>
### 10) `Opt-HVAC`

>> <mark>**THIS PARAMETER IS LIKELY TO BE REDEFINED IN THE NEAR FUTURE**</mark>

* **Description** : Defines the heating and cooling system performance. 
* **Typical values**: Keyword defining heating and cooling system specification (e.g. `basefurnace`)
* **HOT2000 bindings**:  When run, __substitute-h2k.rb__ will modify the heating
  and cooling system definitions according to the parameters defined in the .options file.
* **Other things you should know**: 
  - Currently this tag includes parameters for Type 1 (+/- AC), Type 2 and combo systems. 
    <mark>The number of inputs needed depends on which system is selected</mark>
  - Contrary to its name, the definition of this system does not include ventilation.
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-Archetype = MediumSFD
         
#### Sample `.options` definition for  `Opt-Location`
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
### 11) `Opt-DHWSystem`

* **Description**: Defines hot water system type and performance 
* **Typical values**: Keyword defining DHW system specifications 
* **HOT2000 bindings**:  When run, __substitute-h2k.rb__ will modify the
  archetype's hot water system type and performance to match the corresponding 
  parameters from from the .options file.
* **Other things you should know**: 
  - if `Opt-HVAC` is set to a combo system, this option will be ignored. 
 
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-DHWSystem = ElecInstantaneous
         
#### Sample `.options` definition for  `Opt-Location`

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
### 12) `DWHRSystem`

* **Description** : Defines drain-water heat recovery 
* **Typical values**: Keyword defining DHW system specifications 
* **HOT2000 bindings**:  When run, __substitute-h2k.rb__ will modify the
  archetype to include the specified drain-water heat recovery system, according to 
  the specifications provided in the .options file.
* **Other things you should know**: 
  - HOT2000's DWHR inputs perimt specification of shower frequency, temperature  and duration
    Running the model in ERS mode may override these inputs.

  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-DWHRSystem = DWHR-eff-30
         
#### Sample `.options` definition for  `Opt-Location`

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

<a name="opt-HRV"></a> 
### 3) `Opt-HRV =`

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


         
<a name="opt-skipped"></a>          
Skipped for now 
---------------
+ Opt-Ruleset 
+ Opt-FuelCost   
+ Opt-DWHRandSDHW       
+ Opt-RoofPitch     
+ Opt-ElecLoadScale
+ Opt-DHWLoadScale 
+ Opt-StandoffPV 