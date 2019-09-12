


module HelpTxt

attr_accessor :index
attr_accessor :text

def initialize

@index = Hash.new
@index["byOptions"] = Hash.new
@index["byOptions"] = {
  "Opt-Ruleset" => nil,
  "Opt-DBFiles" => nil,
  "Opt-Location" => nil,
  "Opt-FuelCost" => nil,
  "Opt-ResultHouseCode" => nil,
  "Opt-Archetype" => nil,
  "Opt-ACH" => nil,
  "Opt-AtticCeilings" => nil,
  "Opt-CathCeilings" => nil,
  "Opt-FlatCeilings" => nil,
  "Opt-MainWall" => nil,
  "Opt-GenericWall_1Layer_definitions" => nil,
  "Opt-ExposedFloor" => "Opt-ExposedFloor",
  "Opt-CasementWindows" => nil,
  "Opt-Skylights" => nil,
  "Opt-DoorWindows" => nil,
  "Opt-Doors" => nil,
  "Opt-H2KFoundation" => nil,
  "Opt-H2KFoundationSlabCrawl" => nil,
  "Opt-FoundationWallExtIns" => nil,
  "Opt-FoundationWallIntIns" => nil,
  "Opt-FoundationSlabBelowGrade" => nil,
  "Opt-FoundationSlabOnGrade" => nil,
  "Opt-DHWSystem" => nil,
  "Opt-DWHRSystem" => nil,
  "Opt-HVACSystem" => nil,
  "Opt-HRVspec" => nil,
  "Opt-HRVonly" => nil,
  "Opt-H2K-PV" => nil,
  "GOconfig_rotate" => nil,
  "Opt-Ceilings" => nil,
  "Opt-FloorHeaderIntIns" => nil,
  "Opt-FloorHeader" => "Opt-FloorHeader",
  "Opt-FloorAboveCrawl" => "Opt-FloorAboveCrawl",
  "Opt-Baseloads" => nil,
  "Opt-Temperatures" => nil,
  "Opt-Specifications" => nil,
}



@text = Hash.new
@text["fdn-conifguration"] = "
  HTAP supports two approaches to defining the foundation insulation:
    - A whole foundation approach, in which the requirements for slab, interior
      and exterior wall are set by a single variable, or
    - Surface-by-surface approach, in which the requirements are set separately
      for slab, interior and exterior wall insulation.

  You can only use one or the other. Either the options on the left or the right
  must be set to 'NA'
  ...............................................................................................
  Approach         Opt-FoundaitonXYZ vals                   Opt-H2KFoundation vals
  ...............................................................................................
  Whole            Opt-FoundationWallExtIns     = 'value'   Opt-H2KFoundation          = 'NA'
  Foundation       Opt-FoundationWallIntIns     = 'value'   Opt-H2KFoundationSlabCrawl = 'NA'
  Definition       Opt-FoundationSlabBelowGrade = 'value'
                   Opt-FoundationSlabOnGrade    = 'value'
  ...............................................................................................
  Surface-by-      Opt-FoundationWallExtIns     = 'NA'      Opt-H2KFoundation          = 'value'
  Surface          Opt-FoundationWallIntIns     = 'NA'      Opt-H2KFoundationSlabCrawl = 'value'
  Definition       Opt-FoundationSlabBelowGrade = 'NA'
                   Opt-FoundationSlabOnGrade    = 'NA'
  ...............................................................................................

  (You can also set variables in both columns to 'NA', which causes HTAP to leave the
   foundation alone.)

"

@text["Opt-FloorAboveCrawl"] = "
 Prior versions of HTAP supported two variables that could set the thermal
 caracteristics of exposed floors - Opt-ExposedFloors and Opt-FloorAboveCrawl.
 These have been combined into a single varible (Opt-ExposedFloors) that
 will set the exposed floor insulation values for both overhanging floors
 and floors over open/vented crawlspaces.

"

@text["Opt-ExposedFloor"] = "
 Opt-ExposedFloor sets insulation levels for floor surfaces above unheated
 spaces (including floors above garages, open crawl spaces). It supports
 two specific mapping paramaters:

 \"h2kMap\": {
   \"base\": {
     \"OPT-H2K-CodeName\": string,
     \"OPT-H2K-EffRValue\": float
   }

 Each option definition should set one of these parameters to \"NA\"; setting
 both to values other than \"NA\" will create an error.

 OPT-H2K-CodeName will set the construction definition of exposed floors to
 the user defined code. Since HOT2000 does not support using user-defined
 codes for floors above foundation, it cannot also set the R-Value of floors
 above foundations.

 OPT-H2K-EffRValue will set the effective R-value of both exposed floors and
 floors above unheated crawlspaces to the perscribed r-value.

 RECOMMENDATION: USE OPT-H2K-EffRValue, and set OPT-H2K-CodeName to NA.
"

@text["Opt-FloorHeader"] = "
 Option Opt-FloorHeader is no longer supported. Use Opt-FloorHeaderIntIns
 instead.

 Option Opt-FloorHeader would set the header insulation value independently
 of the wall insulation value. This approach makes no sense for walls with
 external insulated sheathing. Opt-FloorHeaderIntIns allows users to specify
 internal insualtion values; substitute-h2k.rb will add these values
 to the external insulaton layer to estimate the effective RSI for the header
 + external insulaton assembly.

"

@text["cliamte_Zone names"] = "
 Climate zone names should be one of:
   - Zone 4
   - Zone 5
   - Zone 6
   - Zone 7a
   - Zone 7b
   - Zone 8
"

@text["importing costs:categories"] = "
 coax-cost-data.rb checks the catagory for each cost record 
 against a hard-coded list, to make sure that the algorims 
 in costing.rb understand how to calculate its associated 
 costs. This list is maintaned as part of the 'rawCatagories' 
 array in coax-coast.data.rb; make sure that your costing 
 sheet entries match a catagory  in this list. 
"

end
end
