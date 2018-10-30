1. removed first 3 tags from Opt-Location
*attribute:tag:1 = <OPT-WEATHER-FILE>
*attribute:tag:2 = <OPT-Latitude>
*attribute:tag:3 = <OPT-Longitude>
2. removed all windows not included in the codeLib.cod:
- Win6_qd_CL
- Wind3SHUTTER
- Wind4SHUTTER
- DblClr
removed *option:___:WindowParams:name  =
        *option:___:WindowParams:panes =  
        *option:___:WindowParams:SHGC  = 
        *option:___:WindowParams:Uval  = 
removed optical property inputs
*attribute:name  = Opt-CasementWindows
*attribute:tag:2 = <Opt-win-S-OPT>
*attribute:tag:4 = <Opt-win-E-OPT>
*attribute:tag:6 = <Opt-win-N-OPT>
*attribute:tag:8 = <Opt-win-W-OPT>

3. removed exposed floor:
*attribute:name   = Opt-ExposedFloor 
*attribute:tag:1  = <Opt-ExposedFloor>
*attribute:tag:2  = <Opt-ExposedFloor-r>

4. removed
*attribute:name   = Opt-FloorSurface
*attribute:tag:1  = <Opt-IntFloor>
*attribute:tag:2  = <Opt-IntFloorInv>
*attribute:default = wood 

5. removed ESP-r HVAC tags
! 1-6 are old ESPr tags, not needed for h2k use 
*attribute:tag:1   = <Opt-HVACSystem>        ! ESP-r: Flag to activate/deactvate IMS file 
*attribute:tag:2   = <Opt-HideGSHPfile>      ! ESP-r: Flag to activate/deactvate GSHP file 
*attribute:tag:3   = <OPT-VENTisIMS>         ! ESP-r: Flag to activate/deactvate IMS file 
*attribute:tag:4   = <OPT-VENTisHRV>         ! ESP-r: Flag to activate/deactvate HRV file 
*attribute:tag:5   = <OPT-WHisIMS>           ! ESP-r: Flag to activate/deactvate WH HRV file 
*attribute:tag:6   = <Opt-HVACCtlFile>       ! ESP-r: Control File 


6. removed cooling spec
*attribute:name  = Opt-Cooling-Spec
*attribute:tag:1 = <OPT-Cooling-Capacity>
*attribute:tag:2 = <OPT-Cooling-COP>
*attribute:tag:3 = <OPT-Cooling-Fan-Power>
*attribute:tag:4 = <OPT-Cooling-Fan-Power-Low>
*attribute:default = NA

7. removed 
*attribute:name    = Opt-HRVspec 
*attribute:tag:1   = <Opt-HRVInputFile>
*attribute:tag:2   = <Opt-CommentOutMVNT>

8. removed
*attribute:name    = Opt-ElecLoadScale
*attribute:tag:1   = <Opt-ElecLoadScale>

*attribute:name    = Opt-DHWLoadScale 
*attribute:tag:1   = <DUMMY-TAG-Not-USED>

9. removed DHW tag 1
*attribute:name  = Opt-DHWSystem
*attribute:tag:1 = <Opt-DHWInputFile>

10. removed Opt-DWHRandSDHW

11. removed main wall ESP-r references
*attribute:name = Opt-MainWall
*attribute:tag:1  = <Opt-MainWall-Bri>
*attribute:tag:2  = <Opt-MainWall-Vin>
*attribute:tag:3  = <Opt-MainWall-Dry>