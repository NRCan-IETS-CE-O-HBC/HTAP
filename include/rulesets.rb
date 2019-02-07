


# =========================================================================================
# Rule Set: OEE Equipment Windows Roadmapping modelling
# =========================================================================================
def ArchetypeRoadmapping_RuleSet( ruleType, elements )
   if ruleType =~ /roadmapping_gas/

    if $gChoices["Opt-Archetype"] =~ /pre-1946/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-07-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR20"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-Pre-1946-Gas"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-1-RSI_0.66"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_10"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-1-Gas-AC"#"ghg-hvac-1-Gas"
         $ruleSetChoices["Opt-DHWSystem"]                      = "Pre-1946-Gas-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-exh-fan"
      elsif  $gChoices["Opt-Archetype"] =~ /1946-1983/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-11-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR30"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-1946-1983-Gas"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-4-RSI_0.83"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_6_2"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-4-Gas-AC" #"ghg-hvac-4-Gas"
         $ruleSetChoices["Opt-DHWSystem"]                      = "1946-1983-Gas-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-exh-fan"
      elsif  $gChoices["Opt-Archetype"] =~ /1984-1995/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-14-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR30"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-1984-1995-Gas"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-7-RSI_1.66"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_4_4"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-7-Gas-AC" #"ghg-hvac-7-Gas"
         $ruleSetChoices["Opt-DHWSystem"]                      = "1984-1995-Gas-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-exh-fan"
      elsif  $gChoices["Opt-Archetype"] =~ /1996-2005/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-15-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR40"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-1996-2005-Gas"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-10-RSI_1.72"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_3_2"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-10-Gas-AC" #"ghg-hvac-10-Gas"
         $ruleSetChoices["Opt-DHWSystem"]                      = "1996-2005-Gas-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-exh-fan"
      elsif  $gChoices["Opt-Archetype"] =~ /2006-2011/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-15-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR40"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-2006-2011-Gas"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-13-RSI_1.75"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_2_6"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-13-Gas-AC" #"ghg-hvac-13-Gas"
         $ruleSetChoices["Opt-DHWSystem"]                      = "2006-2011-Gas-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-hrv-55sre"
      elsif  $gChoices["Opt-Archetype"] =~ /2012-2019/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-17-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR50"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-2012-2019-Gas"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-16-RSI_2.95"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_2_4"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-16-Gas-AC" #"ghg-hvac-16-Gas"
         $ruleSetChoices["Opt-DHWSystem"]                      = "2012-2019-Gas-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-hrv-55sre"
      end

   elsif ruleType =~ /roadmapping_elec/
    if $gChoices["Opt-Archetype"] =~ /pre-1946/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-09-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR20"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-Pre-1946-Elect"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-2-RSI_0.68"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_10_3"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-2-Elect-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "Pre-1946-Elect-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-exh-fan"
    elsif  $gChoices["Opt-Archetype"] =~ /1946-1983/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-12-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR30"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-1946-1983-Elect"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-5-RSI_0.86"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_6_1"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-5-Elect-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "1946-1983-Elect-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-exh-fan"
    elsif  $gChoices["Opt-Archetype"] =~ /1984-1995/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-15-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR30"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-1984-1995-Elect"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-8-RSI_1.66"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_4_1"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-8-Elect-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "1984-1995-Elect-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-exh-fan"
      elsif  $gChoices["Opt-Archetype"] =~ /1996-2005/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-16-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR40"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-1996-2005-Elect"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-11-RSI_1.67"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_3_1"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-11-Elect-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "1996-2005-Elect-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-hrv-55sre"
      elsif  $gChoices["Opt-Archetype"] =~ /2006-2011/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-16-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR40"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-2006-2011-Elect"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-14-RSI_1.8"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_2_5"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-14-Elect-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "2006-2011-Elect-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-hrv-55sre"
      elsif  $gChoices["Opt-Archetype"] =~ /2012-2019/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-17-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR50"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-2012-2019-Elect"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-17-RSI_2.95"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_2_4"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-17-Elect-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "2012-2019-Elect-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-hrv-55sre"
      end

   elsif ruleType =~ /roadmapping_oil/
    if $gChoices["Opt-Archetype"] =~ /pre-1946/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-08-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR20"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-Pre-1946-Oil"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-3-RSI_0.58"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_10"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-3-Oil-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "Pre-1946-Oil-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-exh-fan"
     elsif  $gChoices["Opt-Archetype"] =~ /1946-1983/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-11-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR30"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-1946-1983-Oil"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-6-RSI_0.77"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_6_3"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-6-Oil-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "1946-1983-Oil-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-exh-fan"
     elsif  $gChoices["Opt-Archetype"] =~ /1984-1995/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-14-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR30"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-1984-1995-Oil"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-9-RSI_1.53"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_4_9"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-9-Oil-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "1984-1995-Oil-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-exh-fan"
     elsif  $gChoices["Opt-Archetype"] =~ /1996-2005/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-16-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR40"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-1996-2005-Oil"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-12-RSI_1.69"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_3_4"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-12-Oil-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "1996-2005-Oil-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-hrv-55sre"
      elsif  $gChoices["Opt-Archetype"] =~ /2006-2011/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-16-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR40"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-2006-2011-Oil"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-15-RSI_1.98"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_2_4"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-15-Oil-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "2006-2011-Oil-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-hrv-55sre"
      elsif  $gChoices["Opt-Archetype"] =~ /2012-2019/
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-17-eff"
         $ruleSetChoices["Opt-Ceilings"]                       = "CeilR50"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "BaseExpFloor-R31"
         $ruleSetChoices["Opt-CasementWindows"]                = "win-Canada-2012-2019-Oil"
         $ruleSetChoices["Opt-H2KFoundation"]                  = "GHG-bsm-18-RSI_2.95"
         $ruleSetChoices["Opt-ACH"]                            = "ACH_2_4"
         $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-18-Oil-AC"
         $ruleSetChoices["Opt-DHWSystem"]                      = "2012-2019-Oil-dhw"
         $ruleSetChoices["Opt-HRVspec"]                        = "ghg-hrv-55sre"
      end
   end


end

def NorthTesting_RuleSet( ruleType, elements )
      if ruleType =~ /north_testing/

        $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "Generic_Wall_R-30-eff"
        $ruleSetChoices["Opt-Ceilings"]                       = "CeilR80"
        $ruleSetChoices["Opt-CasementWindows"]                = "ghg-ER-34"
        $ruleSetChoices["Opt-H2KFoundation"]                  = "north-test-fnd"
        $ruleSetChoices["Opt-ACH"]                            = "ACH_0_6"
        $ruleSetChoices["Opt-HVACSystem"]                     = "ghg-hvac-5-Elect"
        $ruleSetChoices["Opt-DHWSystem"]                      = "2012-2019-Elect-dhw"
        $ruleSetChoices["Opt-HRVspec"]                        = "HRV_81"
     end
end


# =========================================================================================
# Rule Set: NBC-9.36-2010 Creates global rule set hash $ruleSetChoices
# =========================================================================================
def NBC_936_2010_RuleSet( ruleType, ruleSpecs, elements, locale_HDD, cityName )

   #debug_on
   debug_out "Applying ruleset for HDD #{locale_HDD}\n"
   primHeatFuelName = ""
   secSysType = ""
   primDHWFuelName = ""
   ventSpec = ""

   # Should test for this type somewhere
   if ( ! ruleSpecs["fuel"].nil? )
     debug_out ( " Fuel specfied, overide h2k file contents\n")
     primHeatFuelName = ruleSpecs["fuel"]
     secSysType = "Baseboard"
     primDHWFuelName = ruleSpecs["fuel"]
   else
     debug_out ( " Fuel not specified, obtain from h2k file contnets \n")
     # Use system data
     primHeatFuelName = H2KFile.getPrimaryHeatSys( elements )
     secSysType = H2KFile.getSecondaryHeatSys( elements )
     primDHWFuelName = H2KFile.getPrimaryDHWSys( elements )
   end

   if ( ! ruleSpecs["vent"].nil? )
     ventSpec = ruleSpecs["vent"]
   elsif ( ruleType =~ "NBC_*9_*36_.+")
     ventSpec = ruleType.clone
     ventSpec.gsub!(/NBC_*9_*36_/,"")
   else
     ventSpec = ruleType.clone
     ventSpec = "HRV"
   end
   # Basement, slab, or both in model file?
   # Decide which to use for compliance based on count!
   # ADW May 17 2018: Basements are modified through Opt-H2KFoundation, slabs and crawlspaces through Opt-H2KFoundationSlabCrawl
   # Determine if a crawlspace is present, and if it is, if the crawlspace is heated
   numOfCrawl = 0
   isCrawlHeated = H2KFile.heatedCrawlspace(elements)
   if elements["HouseFile/House/Components/Crawlspace"] != nil
      numOfCrawl += 1
   end

   # Choices that do NOT depend on ruleType!
   applyPermafrostRules = false

   $ruleSetChoices["Opt-ACH"] = "ACH_NBC"
   $ruleSetChoices["Opt-Baseloads"] = "NBC-Baseloads"
   $ruleSetChoices["Opt-ResultHouseCode"] = "General"
   $ruleSetChoices["Opt-Temperatures"] = "NBC_Temps"
   if ($PermafrostHash[cityName] == "continuous")
      $ruleSetChoices["Opt-Specifications"] = "NBC_Specs_Perma"
      applyPermafrostRules = true
   else
      $ruleSetChoices["Opt-Specifications"] = "NBC_Specs_Normal"
   end
   debug_out " >>> primary heating type: #{primHeatFuelName} \n"
   # Heating Equipment performance requirements (Table 9.36.3.10) - No dependency on ruleType!
   if (primHeatFuelName =~ /gas/i ) != nil        # value is "Natural gas"
      $ruleSetChoices["Opt-HVACSystem"] = "NBC-gas-furnace"
   elsif (primHeatFuelName =~ /Oil/i) != nil   # value is Oil
      $ruleSetChoices["Opt-HVACSystem"] = "NBC-oil-heat"
   elsif (primHeatFuelName =~ /Elect/i) != nil   # value is "Electricity
      if secSysType =~ /AirHeatPump/   # TODO: Should we also include WSHP & GSHP in this check?
         $ruleSetChoices["Opt-HVACSystem"] = "NBC-CCASHP"
      else
         $ruleSetChoices["Opt-HVACSystem"] = "NBC-elec-heat"
      end
   end

   # DHW Equipment performance requirements (Table 9.36.4.2)
   if (primDHWFuelName =~ /gas/i) != nil
      $ruleSetChoices["Opt-DHWSystem"] = "NBC-HotWater_gas"
   elsif (primDHWFuelName =~ /Elect/i) != nil
      $ruleSetChoices["Opt-DHWSystem"] = "NBC-HotWater_elec"
   elsif (primDHWFuelName =~ /Oil/i) != nil
      $ruleSetChoices["Opt-DHWSystem"] = "NBC-HotWater_oil"
   end

   # Thermal zones and HDD by rule type
   #-------------------------------------------------------------------------
   if ventSpec == "noHRV"

      # Implement reference ventilation system (HRV with 0% recovery efficiency)
      $ruleSetChoices["Opt-HRVonly"]                        =  "NBC_noHRV"

      # Zone 4 ( HDD < 3000) without an HRV
      if locale_HDD < 3000
      # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone4"
         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone4"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
         $ruleSetChoices["Opt-FloorHeaderIntIns"]               ="NBC_RSI2.78_int"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"

      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"] = "NBC-zone4-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone4-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone4-Doorwindow"

      # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)

      # LEGACY H2K Foundation /

         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone4"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone4"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone4" # If there are any slabs, insulate them
         end

       # NEW-H2K Foundation, no HRV

         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_1.99RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"


      # Zone 5 ( 3000 < HDD < 3999) without an HRV
      elsif locale_HDD >= 3000 && locale_HDD < 3999
         # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"]    = "NBC_Wall_zone5_noHRV"
         $ruleSetChoices["Opt-FloorHeaderIntIns"]                 ="NBC_RSI3.08_int"
         $ruleSetChoices["Opt-AtticCeilings"]                     = "NBC_Ceiling_zone5_noHRV"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"

         $ruleSetChoices["Opt-ExposedFloor"]                      = "NBC_936_4.67RSI"

         # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"] = "NBC-zone5-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone5-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone5-Doorwindow"

         # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone5_noHRV"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone5_noHRV"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone5" # If there are any slabs, insulate them
         end


         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"


      # Zone 6 ( 4000 < HDD < 4999) without an HRV
      elsif locale_HDD >= 4000 && locale_HDD < 4999
         # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone6_noHRV"
         $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone6"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"

         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"

         # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"]                = "NBC-zone6-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone6-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone6-Doorwindow"

         # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone6_noHRV"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone6_noHRV"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone6" # If there are any slabs, insulate them

         end

         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"

      # Zone 7A ( 5000 < HDD < 5999) without an HRV
      elsif locale_HDD >= 5000 && locale_HDD < 5999
         # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone7A_noHRV"
         $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7A_noHRV"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"

         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"

         # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"]                = "NBC-zone7A-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone7A-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone7A-Doorwindow"
         # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone7A_noHRV"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone7A_noHRV"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone7A_noHRV" # If there are any slabs, insulate them

         end


        $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_3.46RSI"
        $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
        $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
        $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_3.72RSI"



      # Zone 7B ( 6000 < HDD < 6999) without an HRV
      elsif locale_HDD >= 6000 && locale_HDD < 6999
         # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone7B_noHRV"
         # Floor header: Table 9.36.2.6 calls for RSI 3.85, but "NBC_Wall_zone7B_noHRV" includes
         # R-5 exterior insulation that is continuous over wall & header assemblies. Therefore
         # adding an additional "NBC_RSI2.97_int"  brings header to code level.
         $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"

         info_out("NBC Ruleset - zone 8 requires RSI 3.85 for header/wall assemblies; "+
                  "header internal insulation set to RSI 2.97 - Wall definition (NBC_Wall_zone8_noHRV) "+
                  "includes R-5 continuous insulation that will be added to header")


         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7B"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"

         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"

         # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"]                = "NBC-zone7B-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone7B-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone7B-Doorwindow"

         # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone7B_noHRV"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone7B_noHRV"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone7B_noHRV" # If there are any slabs, insulate them

         end

         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_3.46RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         if ( applyPermafrostRules ) then
           $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_4.44RSI"
         else
           $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         end
         $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_3.72RSI"



      # Zone 8 (HDD <= 7000) without an HRV
      elsif locale_HDD >= 7000
         # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone8_noHRV"
         # Floor header: Table 9.36.2.6 calls for RSI 3.85, but NBC_Wall_zone8_noHRV includes
         # R-5 exterior insulation that is continuous over wall & header assemblies. Therefore
         # adding an additional "NBC_RSI2.97_int"  brings header to code level.
         $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"

         info_out("NBC Ruleset - zone 8 requires RSI 3.85 for header/wall assemblies; "+
                  "header internal insulation set to RSI 2.97 - Wall definition (NBC_Wall_zone8_noHRV) "+
                  "includes R-5 continuous insulation that will be added to header")

         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone8"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"

         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"

         # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"]                =  "NBC-zone8-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone8-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone8-Doorwindow"

         # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone8_noHRV"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone8_noHRV"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone8_noHRV" # If there are any slabs, insulate them

         end

         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_3.97RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         if ( applyPermafrostRules ) then
           $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_4.44RSI"
         else
           $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         end
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_4.59RSI"

      end

   #-------------------------------------------------------------------------
   elsif ventSpec == "HRV"

      # Performance of Heat/Energy-Recovery Ventilator (Section 9.36.3.9.3)
  		$ruleSetChoices["Opt-HRVonly"]                        =  "NBC_HRV"

     # Zone 4 ( HDD < 3000) without an HRV
      if locale_HDD < 3000
      # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone4"
         $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.78_int"
         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone4"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"

         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"

      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"] = "NBC-zone4-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone4-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone4-Doorwindow"

      # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone4"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone4"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone4" # If there are any slabs, insulate them

         end

         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_1.99RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"



      # Zone 5 ( 3000 < HDD < 3999) with an HRV
      elsif locale_HDD >= 3000 && locale_HDD < 3999
         # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone5_HRV"
         $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone5_HRV"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"

         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"

         # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"]                = "NBC-zone5-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone5-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone5-Doorwindow"

         # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone5_HRV"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone5_HRV"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone5" # If there are any slabs, insulate them

         end

         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"


      # Zone 6 ( 4000 < HDD < 4999) with an HRV
      elsif locale_HDD >= 4000 && locale_HDD < 4999
         # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone6_HRV"
         $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone6"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"

         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"

         # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"]                = "NBC-zone6-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone6-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone6-Doorwindow"

         # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone6_HRV"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone6_HRV"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone6" # If there are any slabs, insulate them

         end


         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"

      # Zone 7A ( 5000 < HDD < 5999) with an HRV
      elsif locale_HDD >= 5000 && locale_HDD < 5999
         # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone7A_HRV"
         $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7A_HRV"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"

         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"

         # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"]                = "NBC-zone7A-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone7A-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone7A-Doorwindow"

         # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone7A_HRV"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone7A_HRV"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone7A_HRV" # If there are any slabs, insulate them

         end

         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_2.84RSI"


      # Zone 7B ( 6000 < HDD < 6999) with an HRV
      elsif locale_HDD >= 6000 && locale_HDD < 6999
         # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone7B_HRV"
         $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7B"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"

         # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"]                =  "NBC-zone7B-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone7B-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone7B-Doorwindow"

         # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone7B_HRV"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone7B_HRV"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone7B_HRV" # If there are any slabs, insulate them

         end

         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         if ( applyPermafrostRules ) then
           $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_4.44RSI"
         else
           $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         end
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_2.84RSI"


      # Zone 8 (HDD <= 7000) with an HRV
      elsif locale_HDD >= 7000
         # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
         $ruleSetChoices["Opt-GenericWall_1Layer_definitions"] = "NBC_Wall_zone8_HRV"
         $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
         $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone8"
         $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
         $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"

         $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"

         # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
         $ruleSetChoices["Opt-CasementWindows"]                =  "NBC-zone8-window"
         $ruleSetChoices["Opt-Doors"] = "NBC-zone8-door"
         $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone8-Doorwindow"

         # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
         $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone8_HRV"
         if isCrawlHeated
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone8_HRV"
         else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
            $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone8_HRV" # If there are any slabs, insulate them

         end

         $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
         $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
         if ( applyPermafrostRules ) then
           $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_4.44RSI"
         else
           $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
         end
         $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_3.72RSI"


      end
   else
     fatalerror ("Unknown ventilaton specification '#{ventSpec}' for NBC 936 ruleset")
   end   # Check on NBC rule set type


   debug_out " ruleset choices:\n#{$ruleSetChoices.pretty_inspect}\n"

end

#===============================================================================
def R2000_NZE_Pilot_RuleSet( ruleType, elements, cityName )

   # R-2000 standard test requirements
   if ruleType =~ /R2000_NZE_Pilot_Env/

      # R-2000 Standard Mechanical Conditions. (Table 2)
      $ruleSetChoices["Opt-HVACSystem"] = "R2000-elec-baseboard"
      $ruleSetChoices["Opt-DHWSystem"] = "R2000-HotWater-elec"
      $ruleSetChoices["Opt-HRVspec"] = "R2000_HRV"

      # No renewable generation for envelope test
      $ruleSetChoices["Opt-H2K-PV"] = "R2000_test"

   elsif ruleType =~ /R2000_NZE_Pilot_Mech/

      # No renewable generation for mechanical systems test
      $ruleSetChoices["Opt-H2K-PV"] = "R2000_test"

   end
end
