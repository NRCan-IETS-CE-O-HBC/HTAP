


# =========================================================================================
# Rule Set: OEE Equipment Windows Roadmapping modelling
# =========================================================================================

def ArchetypeRoadmapping_RuleSet( rule, elements )
   
   debug_off
   debug_out "h2k file : #{$h2kFileName} \n"
   debug_out "rule     : #{rule} \n"
   
   if ( rule =~ /auto/ ) then 
      
      primHeatFuelName = H2KFile.getPrimaryHeatSys( elements )
      
      secSysType = H2KFile.getSecondaryHeatSys( elements )
      yearbuilt = H2KFile.getYearBuilt(elements)
      
      debug_out ( "1st heating system: #{primHeatFuelName}\n") 
      debug_out ( "2nd heating system: #{secSysType}\n")
      debug_out ( "Yearbuilt:          #{yearbuilt}\n")
      
      debug_out ("ChecFuel\n")
      if ( primHeatFuelName =~ /electric/i ) then 
         ruleType = "Roadmapping_elec"
      elsif  ( primHeatFuelName =~ /Natural gas/i ) then 
         ruleType = "Roadmapping_gas"
      elsif  ( primHeatFuelName =~ /Oil/i ) then 
         ruleType = "Roadmapping_oil"
      elsif  ( primHeatFuelName =~ /Propane/i ) then 
         ruleType = "Roadmapping_oil"
      elsif  ( primHeatFuelName =~ /wood/i ) then 
         ruleType = "Roadmapping_oil"
      else 
         err_out("unknown fuel type: #{primHeatFuelName} (secondary: #{secSysType})")
         fatalerror("Roadmapping_auto ruleset could not intrepret fuel")
      end 
      
      debug_out ("CheckYear\n")
      if ( yearbuilt < 1946 ) then 
         vintage = "pre-1946"
      elsif ( yearbuilt < 1984) then 
         vintage = "1946-1983"
      elsif ( yearbuilt < 1996) then 
         vintage = "1984-1995"         
      elsif ( yearbuilt < 2006) then 
         vintage = "1996-2005"      
      elsif ( yearbuilt < 2012) then 
         vintage = "2006-2011"      
      else 
         vintage = "2012-2019"   
      end 
      
      
   else 
      vintage = $h2kFileName
      ruleType = rule 
   end 
   
   debug_out ("Vintage / Fuel: #{vintage} / #{ruleType} ")
   
   debug_off 
   if vintage =~ /pre-1946/
      $ruleSetChoices["Opt-ACH"]            = "ACH_10"
      if ruleType =~ /Roadmapping_elec/
         $ruleSetChoices["Opt-Windows"]     = "dbl-clear-u3.33"
      else  
         $ruleSetChoices["Opt-Windows"]     = "dbl-clear-u3.85"
      end 
      $ruleSetChoices["Opt-Ceilings"]             = "CeilR20"
      $ruleSetChoices["Opt-AboveGradeWall"]           = "Generic_Wall_R-07-eff"
      $ruleSetChoices["Opt-FoundationWallIntIns"]     = "VintageR5"
      $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "uninsulated"
      $ruleSetChoices["Opt-ExposedFloor"]             = "VintageR3"
      
      
      if ruleType =~ /Roadmapping_gas/
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageGas74%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageGasEF0.55"
         
      elsif ruleType =~ /Roadmapping_elec/
         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-elec-heat"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageElecEF0.92"
         
      elsif ruleType =~ /Roadmapping_oil/ 
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageOil64%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageOilEF0.52"
         
      end 
      
   elsif  vintage =~ /1946-1983/
      
      if ruleType =~ /Roadmapping_elec/
         $ruleSetChoices["Opt-Windows"]     = "dbl-clear-u2.94"
      else  
         $ruleSetChoices["Opt-Windows"]     = "dbl-clear-u3.33"
      end       
      $ruleSetChoices["Opt-ACH"]            = "ACH_6"
      $ruleSetChoices["Opt-Ceilings"]             = "CeilR25"      
      $ruleSetChoices["Opt-AboveGradeWall"]           = "Generic_Wall_R-10-eff"
      $ruleSetChoices["Opt-FoundationWallIntIns"]     = "VintageR5"
      $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "uninsulated"
      $ruleSetChoices["Opt-ExposedFloor"]             = "VintageR10"      
      
      if ruleType =~ /Roadmapping_gas/
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageGas78%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageGasEF0.55"
         
      elsif ruleType =~ /Roadmapping_elec/
         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-elec-heat"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageElecEF0.92"
         
      elsif ruleType =~ /Roadmapping_oil/ 
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageOil68%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageOilEF0.52"
         
      end 
      
      
   elsif  vintage =~ /1984-1995/
      
      if ruleType =~ /Roadmapping_elec/
         $ruleSetChoices["Opt-Windows"]     = "dbl-clear-u2.94"
      else  
         $ruleSetChoices["Opt-Windows"]     = "dbl-clear-u3.13"
      end     
      $ruleSetChoices["Opt-ACH"]            = "ACH_4_5"
      $ruleSetChoices["Opt-Ceilings"]             = "CeilR30"      
      $ruleSetChoices["Opt-AboveGradeWall"]           = "Generic_Wall_R-15-eff"
      $ruleSetChoices["Opt-FoundationWallIntIns"]     = "VintageR10"
      $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "VintageR5"
      $ruleSetChoices["Opt-ExposedFloor"]             = "VintageR20"
      
      if ruleType =~ /Roadmapping_gas/
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageGas80%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageGasEF0.57"
         
      elsif ruleType =~ /Roadmapping_elec/
         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-elec-heat"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageElecEF0.92"
         
      elsif ruleType =~ /Roadmapping_oil/ 
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageOil74%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageOilEF0.55"
         
      end 
      
   elsif  vintage =~ /1996-2005/
      $ruleSetChoices["Opt-ACH"]            = "ACH_3_5"
      $ruleSetChoices["Opt-Ceilings"]             = "CeilR40"
      $ruleSetChoices["Opt-Windows"]     = "dbl-clear-u2.13"
      $ruleSetChoices["Opt-AboveGradeWall"]           = "Generic_Wall_R-15-eff"
      $ruleSetChoices["Opt-FoundationWallIntIns"]     = "VintageR10"
      $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "VintageR5"
      $ruleSetChoices["Opt-ExposedFloor"]             = "VintageR20"
      
      if ruleType =~ /Roadmapping_gas/
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageGas87%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageGasEF0.57"
         
      elsif ruleType =~ /Roadmapping_elec/
         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-elec-heat"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageElecEF0.92"
         
      elsif ruleType =~ /Roadmapping_oil/ 
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageOil83%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageOilEF0.55"
         
         
      end 
      
   elsif  vintage =~ /2006-2011/
      $ruleSetChoices["Opt-ACH"]            = "ACH_2_5"
      
      $ruleSetChoices["Opt-Windows"]     = "dbl-clear-u2.13"
      $ruleSetChoices["Opt-Ceilings"]             = "CeilR40"
      $ruleSetChoices["Opt-AboveGradeWall"]           = "Generic_Wall_R-15-eff"
      $ruleSetChoices["Opt-FoundationWallIntIns"]     = "VintageR10"
      $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "VintageR5"
      $ruleSetChoices["Opt-ExposedFloor"]             = "VintageR25"
      
      if ruleType =~ /Roadmapping_gas/
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageGas90%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageGasEF0.55"
         
      elsif ruleType =~ /Roadmapping_elec/
         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-elec-heat"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageElecEF0.92"
         
      elsif ruleType =~ /Roadmapping_oil/ 
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageOil83%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageOilEF0.55"
         
      end       
      
   elsif  vintage =~ /2012-2019/
      $ruleSetChoices["Opt-ACH"]            = "ACH_2_5"
      $ruleSetChoices["Opt-Ceilings"]             = "CeilR50"
      $ruleSetChoices["Opt-Windows"]     = "dbl-clear-u1.8"
      $ruleSetChoices["Opt-AboveGradeWall"]           = "Generic_Wall_R-17-eff"
      $ruleSetChoices["Opt-FoundationWallIntIns"]     = "VintageR17"
      $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "VintageR10"
      $ruleSetChoices["Opt-ExposedFloor"]             = "VintageR30"
      
      if ruleType =~ /Roadmapping_gas/
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageGas92%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageGasEF0.67"
         
      elsif ruleType =~ /Roadmapping_elec/
         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-elec-heat"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageElecEF0.92"
      elsif ruleType =~ /Roadmapping_oil/ 
         $ruleSetChoices["Opt-Heating-Cooling"] = "vintageOil87%"
         $ruleSetChoices["Opt-DHWSystem"]       = "vintageOilEF0.57"
         
      end 
      
      
      
   end 
   
   return 
   
   
end

def NorthTesting_RuleSet( ruleType, elements )
   if ruleType =~ /north_testing/
      
      $ruleSetChoices["Opt-AboveGradeWall"] = "Generic_Wall_R-30-eff"
      $ruleSetChoices["Opt-Ceilings"]                       = "CeilR80"
      
      $ruleSetChoices["Opt-Windows"]                = "ghg-ER-34"
      $ruleSetChoices["Opt-H2KFoundation"]                  = "north-test-fnd"
      $ruleSetChoices["Opt-ACH"]                            = "ACH_0_6"
      $ruleSetChoices["Opt-Heating-Cooling"]                     = "ghg-hvac-5-Elect"
      
      $ruleSetChoices["Opt-DHWSystem"]                      = "2012-2019-Elect-dhw"
      $ruleSetChoices["Opt-VentSystem"]                        = "HRV_81"
   end
end


module NBC
   
   def NBC.apply_936p5(year, ruleSpecs, elements, locale_HDD, cityName)
      debug_on
      debug_pause
      
   end 
   
   def NBC.apply_936p6(year, house, ruleSpecs, elements, locale_HDD, cityName)
      
      debug_on
      


      # Recover parameters needed to apply the right rulesets
      params_for_code = get_hse_params_for_code(elements, ruleSpecs, locale_HDD, cityName)
      
      apply_936_operating_conditions(year)
      if ( house == "ref_house")


         # Possibly overwrite SH system type 1/2 if it is a HP
         if ( params_for_code["SH_type_2"] =~ /HeatPump/ ) then 
            params_for_code["SH_type_2"] = ""
         end 

         params_for_code["vent_sys_type"] = "noHRV"


         apply_936_env_requirements(year, params_for_code)
         apply_936_mech_requirements(year,params_for_code)


      end 

      debug_out "CODE CHOICES: \n"
      debug_out ($ruleSetChoices.pretty_inspect())
      
      #debug_pause
      
   end 
   
   #========================================================
   # Get key house parameters from HSE file and format them 
   # in a hash that can be used to apply right code requirements.
   # Also: Call routine 'overide_hse_params...' to determine 
   #       if user has spec'd alternate compliance paths. 
   def self.get_hse_params_for_code(elements,ruleSpecs,locale_HDD, cityName)
      debug_on 
      
      debug_out("Ruleset specifications:\n")
      debug_out(ruleSpecs.pretty_inspect())
      
      params_for_code = {
         "SH_type_1"         => H2KFile.getPrimaryHeatSys( elements ) ,
         "SH_type_2"         => H2KFile.getSecondaryHeatSys( elements ),
         "DHW_type"          => H2KFile.getPrimaryDHWSys( elements ),
         "house_type"        => H2KFile.getHouseType(elements), 
         "heated_crawlspace" => H2KFile.heatedCrawlspace(elements), 
         "vent_sys_type"     => H2KFile.get_vent_sys_type(elements) }
      
      
      
      if ( locale_HDD < 3000 )
         cz = "cz4"
      elsif (locale_HDD >= 3000 && locale_HDD < 3999 )
         cz = "cz5"
      elsif (locale_HDD >= 4000 && locale_HDD < 4999 )
         cz = "cz6"
      elsif (locale_HDD >= 5000 && locale_HDD < 5999 )
         cz = "cz7a"
      elsif (locale_HDD >= 6000 && locale_HDD < 6999 )
         cz = "cz7b"    
      elsif (locale_HDD >= 7000 )
         cz = "cz8"
      end 
      
      params_for_code["climate_zone"] = cz
      
      debug_out("HSE PARAMS:\n")
      debug_out(params_for_code.pretty_inspect())
      
      
      params_for_code = overide_hse_params_for_code(ruleSpecs,params_for_code)
      
      
      debug_out("Final PARAMS:\n")
      debug_out(params_for_code.pretty_inspect())
      
      return params_for_code
      
   end
   
   # ============================================================= 
   # Possibly overwrite code params with items set in input file
   def self.overide_hse_params_for_code(ruleSpecs,params_for_code)
      
      debug_on 
      
      if ( ruleSpecs["fuel"] =~ /elec/i ) then 
         params_for_code["SH_type_1"] = "electricity" 
         params_for_code["SH_type_2"] = "electricity" 
         params_for_code["DHW_type"]  = "electricity" 
      end 
      if ( ruleSpecs["fuel"] =~ /gas/i ) then 
         params_for_code["SH_type_1"] = "gas" 
         params_for_code["SH_type_2"] = "gas" 
         params_for_code["DHW_type"]  = "gas" 
      end 
      
      if ( ruleSpecs["fuel"] =~ /oil/i ) then 
         params_for_code["SH_type_1"] = "oil" 
         params_for_code["SH_type_2"] = "oil" 
         params_for_code["DHW_type"]  = "oil" 
      end 
      
      if ( ruleSpecs["vent"] =~ /HRV/i ) then 
         params_for_code["vent_sys_type"] = "HRV"
      end 
      
      if ( ruleSpecs["vent"] =~ /noHRV/ ) then 
         params_for_code["vent_sys_type"] = "noHRV"
      end 
      
      return params_for_code
      
   end 
   
   # ============================================================
   # Set gains / temperatures / ventilation schedules 
   def self.apply_936_operating_conditions(year)
      
      debug_on 
      if ( year == "2020" )
         
         # Note: code in substutute.h2k-rb probably needs a rewrite
         # to better algin with ERS DHW definitions.
         $ruleSetChoices["Opt-Baseloads"] = "nbc_2020_baseloads"
         $ruleSetChoices["Opt-Temperatures"] = "nbc_2020_temps"
         $ruleSetChoices["Opt-ResultHouseCode"] = "General"
         $ruleSetChoices["Opt-VentSched"]  = "nbc_ventilation_rate"
         
      else 
         $ruleSetChoices["Opt-Baseloads"] = "NBC-Baseloads"
         $ruleSetChoices["Opt-ResultHouseCode"] = "General"
         $ruleSetChoices["Opt-Temperatures"] = "NBC_Temps"
         $ruleSetChoices["Opt-VentSched"]  = "nbc_ventilation_rate"
         
      end 
      
   end 
   
   # ============================================================
   # Apply envelope requirements
   def self.apply_936_env_requirements(year,params_for_code)
      
      debug_on
      debug_out "Applying 9.36 envelope requirements for #{year} NBC\n"
      
      $ruleSetChoices["Opt-WindowDistribution"] = "Reference-9.36"


      # ACH: 
      if (year == "2020") then 
         # This is a work-around; need to detect "guarded/unguarded" H2k Input parameter 
         # And apply right parameter accordingly
         if (params_for_code["house_type"] == "SingleDetached") then
            $ruleSetChoices["Opt-ACH"] = "ACH_NBC_2p5"
         else
            $ruleSetChoices["Opt-ACH"] = "ACH_NBC_3p0"
         end 
      else 
         $ruleSetChoices["Opt-ACH"] = "ACH_NBC"
      end
      
      # Opaque components : 
      
      # Thermal zones and HDD by rule type
      #-------------------------------------------------------------------------
      if params_for_code["vent_sys_type"] == "noHRV"
         
         # Zone 4 ( HDD < 3000) without an HRV
         if params_for_code["climate_zone"] =="cz4" then 
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone4"
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone4"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
            $ruleSetChoices["Opt-FloorHeaderIntIns"]               ="NBC_RSI2.78_int"
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"] = "NBC-zone4-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone4-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone4-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            
            # LEGACY H2K Foundation /
            
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone4"
            if params_for_code["heated_crawlspace"]
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
         elsif params_for_code["climate_zone"] == "cz5" then
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"]    = "NBC_Wall_zone5_noHRV"
            $ruleSetChoices["Opt-FloorHeaderIntIns"]                 ="NBC_RSI3.08_int"
            $ruleSetChoices["Opt-AtticCeilings"]                     = "NBC_Ceiling_zone5_noHRV"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
            
            $ruleSetChoices["Opt-ExposedFloor"]                      = "NBC_936_4.67RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"] = "NBC-zone5-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone5-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone5-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone5_noHRV"
            if params_for_code["heated_crawlspace"]
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone5_noHRV"
            else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone5" # If there are any slabs, insulate them
            end
            
            
            $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
            $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
            
            
            # Zone 6 ( 4000 < HDD < 4999) without an HRV
         elsif params_for_code["climate_zone"] == "cz6" then
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone6_noHRV"
            $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone6"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
            
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"]                = "NBC-zone6-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone6-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone6-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone6_noHRV"
            if params_for_code["heated_crawlspace"]
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone6_noHRV"
            else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone6" # If there are any slabs, insulate them
               
            end
            
            $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
            $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
            
            # Zone 7A ( 5000 < HDD < 5999) without an HRV
         elsif params_for_code["climate_zone"] == "cz7a" then
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone7A_noHRV"
            $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7A_noHRV"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
            
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"]                = "NBC-zone7A-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone7A-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone7A-Doorwindow"
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone7A_noHRV"
            if params_for_code["heated_crawlspace"]
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone7A_noHRV"
            else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone7A_noHRV" # If there are any slabs, insulate them
               
            end
            
            
            $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_3.46RSI"
            $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_3.72RSI"
            
            
            
            # Zone 7B ( 6000 < HDD < 6999) without an HRV
         elsif params_for_code["climate_zone"] == "cz7b" then
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] == "NBC_Wall_zone7B_noHRV"
            # Floor header: Table 9.36.2.6 calls for RSI 3.85, but "NBC_Wall_zone7B_noHRV" includes
            # R-5 exterior insulation that is continuous over wall & header assemblies. Therefore
            # adding an additional "NBC_RSI2.97_int"  brings header to code level.
            $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
            
            info_out("NBC Ruleset - zone 8 requires RSI 3.85 for header/wall assemblies; "+
            "header internal insulation set to RSI 2.97 - Wall definition (NBC_Wall_zone8_noHRV) "+
            "includes R-5 continuous insulation that will be added to header")
            
            
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7B"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
            
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"]                = "NBC-zone7B-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone7B-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone7B-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone7B_noHRV"
            if params_for_code["heated_crawlspace"]
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
         elsif params_for_code["climate_zone"] == "cz8" then 
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone8_noHRV"
            # Floor header: Table 9.36.2.6 calls for RSI 3.85, but NBC_Wall_zone8_noHRV includes
            # R-5 exterior insulation that is continuous over wall & header assemblies. Therefore
            # adding an additional "NBC_RSI2.97_int"  brings header to code level.
            $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
            
            info_out("NBC Ruleset - zone 8 requires RSI 3.85 for header/wall assemblies; "+
            "header internal insulation set to RSI 2.97 - Wall definition (NBC_Wall_zone8_noHRV) "+
            "includes R-5 continuous insulation that will be added to header")
            
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone8"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
            
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"]                =  "NBC-zone8-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone8-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone8-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone8_noHRV"
            if params_for_code["heated_crawlspace"]
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
      elsif params_for_code["vent_sys_type"] == "HRV"
         
         # Zone 4 ( HDD < 3000) without an HRV
         if params_for_code["climate_zone"] =="cz4" then
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone4"
            $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.78_int"
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone4"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
            
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"] = "NBC-zone4-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone4-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone4-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone4"
            if params_for_code["heated_crawlspace"]
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone4"
            else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone4" # If there are any slabs, insulate them
               
            end
            
            $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_1.99RSI"
            $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
            
            
            
            # Zone 5 ( 3000 < HDD < 3999) with an HRV
         elsif params_for_code["climate_zone"] == "cz5" then
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone5_HRV"
            $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone5_HRV"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
            
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"]                = "NBC-zone5-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone5-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone5-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone5_HRV"
            if params_for_code["heated_crawlspace"]
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone5_HRV"
            else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone5" # If there are any slabs, insulate them
               
            end
            
            $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
            $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
            
            
            # Zone 6 ( 4000 < HDD < 4999) with an HRV
         elsif params_for_code["climate_zone"] == "cz6" then
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone6_HRV"
            $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone6"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
            
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"]                = "NBC-zone6-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone6-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone6-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone6_HRV"
            if params_for_code["heated_crawlspace"]
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone6_HRV"
            else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone6" # If there are any slabs, insulate them
               
            end
            
            
            $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
            $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
            
            # Zone 7A ( 5000 < HDD < 5999) with an HRV
         elsif params_for_code["climate_zone"] == "cz7a" then
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone7A_HRV"
            $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7A_HRV"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
            
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"]                = "NBC-zone7A-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone7A-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone7A-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone7A_HRV"
            if params_for_code["heated_crawlspace"]
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone7A_HRV"
            else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
               $ruleSetChoices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone7A_HRV" # If there are any slabs, insulate them
               
            end
            
            $ruleSetChoices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
            $ruleSetChoices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
            $ruleSetChoices["Opt-FoundationSlabOnGrade"] = "NBC_936_2.84RSI"
            
            
            # Zone 7B ( 6000 < HDD < 6999) with an HRV
         elsif params_for_code["climate_zone"] == "cz7b" then
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone7B_HRV"
            $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7B"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"]                =  "NBC-zone7B-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone7B-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone7B-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone7B_HRV"
            if params_for_code["heated_crawlspace"]
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
         elsif params_for_code["climate_zone"] == "cz8" then
            # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
            $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone8_HRV"
            $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
            $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone8"
            $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
            $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
            
            $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
            
            # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
            
            $ruleSetChoices["Opt-Windows"]                =  "NBC-zone8-window"
            
            $ruleSetChoices["Opt-Doors"] = "NBC-zone8-door"
            $ruleSetChoices["Opt-DoorWindows"] = "NBC-zone8-Doorwindow"
            
            # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
            $ruleSetChoices["Opt-H2KFoundation"] = "NBC_BCIN_zone8_HRV"
            if params_for_code["heated_crawlspace"]
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
      
   end 
   
   # ====================================================================================
   def self.apply_936_mech_requirements(year,params_for_code)
      
      debug_on 
      debug_out ("   - year: #{year}\n")
      debug_out ("   - passed params: #{params_for_code.pretty_inspect} \n")

      if ( params_for_code["DHW_type"] =~ /gas/i && year == "2020") 
      
         $ruleSetChoices["Opt-DHWSystem"] = "NBC_2020_DHW_gas_EF0.69"
      
      elsif ( params_for_code["DHW_type"] =~ /gas/i && year == "2015")
      
         $ruleSetChoices["Opt-DHWSystem"] = "NBC-HotWater_gas" 
      
      elsif ( params_for_code["DHW_type"] =~ /elec/i )
      
         $ruleSetChoices["Opt-DHWSystem"] = "NBC-HotWater_elec"
      
      elsif ( params_for_code["DHW_type"] =~ /oil/i ) 
      
         $ruleSetChoices["Opt-DHWSystem"] = "NBC-HotWater_oil"
         
      end 

      

      if (params_for_code["SH_type_1"] =~ /gas/i && year == "2020" )        # value is "Natural gas"
      
         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-gas-furnace-2020" 

      elsif (params_for_code["SH_type_1"] =~ /gas/i && year == "2020 ") 

         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-gas-furnace"

      elsif (params_for_code["SH_type_1"] =~ /Oil/i  )    # value is Oil
         
         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-oil-heat"

      elsif (params_for_code["SH_type_1"] =~ /Elect/i) != nil   # value is "Electricity

         if ( params_for_code["SH_type_2"]=~ /HeatPump/ )  # TODO: Should we also include WSHP & GSHP in this check?
            $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-CCASHP"

         else
            $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-elec-heat"
            
         end

      end
 
      $ruleSetChoices["Opt-VentSystem"] =  "VentFans_sre_0"
      


   end 
end 

# =========================================================================================
# Rule Set: NBC-9.36-2010 [ !actually 2015! ] Creates global rule set hash $ruleSetChoices
# =========================================================================================
def NBC_936_RuleSet( ruleType, ruleSpecs, elements, locale_HDD, cityName, variant  )
   
   debug_on
   debug_out "Applying ruleset #{ruleType}[#{ruleSpecs}] (#{variant}) for HDD #{locale_HDD}\n"
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
   elsif ( ruleType =~ /NBC_?9_?36.\[+/)
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
   $ruleSetChoices["Opt-WindowDistribution"] = "Reference-9.36"
   if ($PermafrostHash[cityName] == "continuous")
      $ruleSetChoices["Opt-Specifications"] = "NBC_Specs_Perma"
      applyPermafrostRules = true
   else
      $ruleSetChoices["Opt-Specifications"] = "NBC_Specs_Normal"
   end
   debug_out " >>> primary heating type: #{primHeatFuelName} \n"
   # Heating Equipment performance requirements (Table 9.36.3.10) - No dependency on ruleType!
   if (primHeatFuelName =~ /gas/i ) != nil        # value is "Natural gas"
      
      $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-gas-furnace"
   elsif (primHeatFuelName =~ /Oil/i) != nil   # value is Oil
      $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-oil-heat"
   elsif (primHeatFuelName =~ /Elect/i) != nil   # value is "Electricity
      if secSysType =~ /AirHeatPump/   # TODO: Should we also include WSHP & GSHP in this check?
         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-CCASHP"
      else
         $ruleSetChoices["Opt-Heating-Cooling"] = "NBC-elec-heat"
         
      end
   end
   
   # DHW Equipment performance requirements (Table 9.36.4.2)
   debug_out ("DHW FUEL #{primDHWFuelName} \n ")
   if (primDHWFuelName =~ /gas/i) != nil
      $ruleSetChoices["Opt-DHWSystem"] = "NBC-HotWater_gas"
   elsif (primDHWFuelName =~ /Elect/i) != nil
      $ruleSetChoices["Opt-DHWSystem"] = "NBC-HotWater_elec"
   elsif (primDHWFuelName =~ /Oil/i) != nil
      $ruleSetChoices["Opt-DHWSystem"] = "NBC-HotWater_oil"
   else 
      warn_out ("NBC 936 ruleset - unknown DHW fuel source. Using Electric ")
      $ruleSetChoices["Opt-DHWSystem"] = "NBC-HotWater_elec"
   end
   

# Thermal zones and HDD by rule type
#-------------------------------------------------------------------------
if ventSpec == "noHRV"
   
   # Implement reference ventilation system (HRV with 0% recovery efficiency)
   
   $ruleSetChoices["Opt-VentSystem"]                        =  "NBC_noHRV"
   
   
   # Zone 4 ( HDD < 3000) without an HRV
   if locale_HDD < 3000
      # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone4"
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone4"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
      $ruleSetChoices["Opt-FloorHeaderIntIns"]               ="NBC_RSI2.78_int"
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"] = "NBC-zone4-window"
      
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
      $ruleSetChoices["Opt-AboveGradeWall"]    = "NBC_Wall_zone5_noHRV"
      $ruleSetChoices["Opt-FloorHeaderIntIns"]                 ="NBC_RSI3.08_int"
      $ruleSetChoices["Opt-AtticCeilings"]                     = "NBC_Ceiling_zone5_noHRV"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
      
      $ruleSetChoices["Opt-ExposedFloor"]                      = "NBC_936_4.67RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"] = "NBC-zone5-window"
      
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
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone6_noHRV"
      $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone6"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
      
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"]                = "NBC-zone6-window"
      
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
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone7A_noHRV"
      $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7A_noHRV"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
      
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"]                = "NBC-zone7A-window"
      
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
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone7B_noHRV"
      # Floor header: Table 9.36.2.6 calls for RSI 3.85, but "NBC_Wall_zone7B_noHRV" includes
      # R-5 exterior insulation that is continuous over wall & header assemblies. Therefore
      # adding an additional "NBC_RSI2.97_int"  brings header to code level.
      $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
      
      info_out("NBC Ruleset - zone 8 requires RSI 3.85 for header/wall assemblies; "+
      "header internal insulation set to RSI 2.97 - Wall definition (NBC_Wall_zone8_noHRV) "+
      "includes R-5 continuous insulation that will be added to header")
      
      
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7B"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
      
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"]                = "NBC-zone7B-window"
      
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
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone8_noHRV"
      # Floor header: Table 9.36.2.6 calls for RSI 3.85, but NBC_Wall_zone8_noHRV includes
      # R-5 exterior insulation that is continuous over wall & header assemblies. Therefore
      # adding an additional "NBC_RSI2.97_int"  brings header to code level.
      $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
      
      info_out("NBC Ruleset - zone 8 requires RSI 3.85 for header/wall assemblies; "+
      "header internal insulation set to RSI 2.97 - Wall definition (NBC_Wall_zone8_noHRV) "+
      "includes R-5 continuous insulation that will be added to header")
      
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone8"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
      
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"]                =  "NBC-zone8-window"
      
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
   
   $ruleSetChoices["Opt-VentSystem"]                        =  "NBC_HRV"
     
   # Zone 4 ( HDD < 3000) without an HRV
   if locale_HDD < 3000
      # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone4"
      $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.78_int"
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone4"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
      
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"] = "NBC-zone4-window"
      
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
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone5_HRV"
      $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone5_HRV"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
      
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"]                = "NBC-zone5-window"
      
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
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone6_HRV"
      $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone6"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
      
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"]                = "NBC-zone6-window"
      
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
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone7A_HRV"
      $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7A_HRV"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
      
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"]                = "NBC-zone7A-window"
      
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
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone7B_HRV"
      $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7B"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"]                =  "NBC-zone7B-window"
      
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
      $ruleSetChoices["Opt-AboveGradeWall"] = "NBC_Wall_zone8_HRV"
      $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
      $ruleSetChoices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone8"
      $ruleSetChoices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
      $ruleSetChoices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
      
      $ruleSetChoices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
      
      # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
      
      $ruleSetChoices["Opt-Windows"]                =  "NBC-zone8-window"
      
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

def NBC_936_2020_RuleSet( ruleType, ruleSpecs, elements, locale_HDD, cityName )
   
   # For starters, call the NBC 2015
   NBC_936_2010_RuleSet( ruleType, ruleSpecs, elements, locale_HDD, cityName )
   
   
   
end 

def LEEP_pathways_ruleset()
   $ruleSetChoices["Opt-AboveGradeWall"] = "NC_R-16(eff)_2x6-16inOC_R19-batt_poly_vb"
   $ruleSetChoices["Opt-FloorHeaderIntIns"]              = "NC_R-15eff_4.5inBatt"
   $ruleSetChoices["Opt-AtticCeilings"]                  = "CeilR40"
   $ruleSetChoices["Opt-CathCeilings"]                   = "CeilR40"
   $ruleSetChoices["Opt-FlatCeilings"]                   = "CeilR40"
   $ruleSetChoices["Opt-ExposedFloor"]                     = "NBC_936_5.02RSI"
   
   $ruleSetChoices["Opt-Heating-Cooling"]                      = "gas-furnace-ecm"
   
   $ruleSetChoices["Opt-FoundationWallIntIns"] = "WoodFrameEffR15"
   $ruleSetChoices["Opt-FoundationWallExtIns"] = "uninsulated"
   $ruleSetChoices["Opt-FoundationSlabBelowGrade"] = "uninsulated"
   $ruleSetChoices["Opt-DHWSystem"]="gas_storagetank_w/powervent_ef0.67"
   
   $ruleSetChoices["Opt-Windows"]="NC-2g-MG-u1.82"
   $ruleSetChoices["Opt-ACH"]="New-Const-air_seal_to_3.50_ach"
   $ruleSetChoices["Opt-VentSystem"]="HRV_sre_60"
   
end
#===============================================================================
def R2000_NZE_Pilot_RuleSet( ruleType, elements, cityName )
   
   # R-2000 standard test requirements
   if ruleType =~ /R2000_NZE_Pilot_Env/
      
      # R-2000 Standard Mechanical Conditions. (Table 2)
      
      $ruleSetChoices["Opt-Heating-Cooling"] = "R2000-elec-baseboard"
      
      $ruleSetChoices["Opt-DHWSystem"] = "R2000-HotWater-elec"
      $ruleSetChoices["Opt-VentSystem"] = "R2000_HRV"
      
      # No renewable generation for envelope test
      $ruleSetChoices["Opt-H2K-PV"] = "R2000_test"
      
   elsif ruleType =~ /R2000_NZE_Pilot_Mech/
      
      # No renewable generation for mechanical systems test
      $ruleSetChoices["Opt-H2K-PV"] = "R2000_test"
      
   end
end
