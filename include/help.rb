
a = "test?"

help = Hash.new
help["byOptions"] = Hash.new
help["byOptions"] = { "Opt-Ruleset" => nil,
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
                      "Opt-ExposedFloor" => nil,
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
                      "Opt-FloorHeader" => nil,
                      "Opt-FloorAboveCrawl" => nil,
                      "Opt-Baseloads" => nil,
                      "Opt-Temperatures" => nil,
                      "Opt-Specifications" => nil,
}



helpTxt = Hash.new

helpTxt["FdnConifguration"] = "
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
