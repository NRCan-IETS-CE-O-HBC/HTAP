


module NBC

  def NBC.apply_936p7(year,params_for_ruleset)
    
    
    debug_on 
    debug_out("Applying NBC 9.36.7 rulesets, #{year} edition.")

    params_for_ruleset["vent_sys_type"] = "noHRV"

    ruleset_choices = Hash.new 
    ruleset_choices = apply_936_operating_conditions(year,ruleset_choices)
    ruleset_choices = apply_936_env_requirements(year, params_for_ruleset,ruleset_choices)
    ruleset_choices = apply_936_mech_requirements(year,params_for_ruleset,ruleset_choices)

    return ruleset_choices

  end 

   # ============================================================
   # Set gains / temperatures / ventilation schedules 
   def self.apply_936_operating_conditions(year, choices)
    

    debug_on 
    if ( year == "2020" )
       
       # Note: code in substutute.h2k-rb probably needs a rewrite
       # to better algin with ERS DHW definitions.
       choices["Opt-Baseloads"] = "nbc_2020_baseloads"
       choices["Opt-Temperatures"] = "nbc_2020_temps"
       choices["Opt-VentSched"]  = "nbc_ventilation_rate"
       
    else 
       choices["Opt-Baseloads"] = "NBC-Baseloads"
       choices["Opt-Temperatures"] = "NBC_Temps"
       choices["Opt-VentSched"]  = "nbc_ventilation_rate"
       
    end 
    return choices
    
 end 

   
  # ============================================================
  # Apply envelope requirements
  def self.apply_936_env_requirements(year,params_for_ruleset,choices)
      
    debug_on
    debug_out "Applying 9.36 envelope requirements for #{year} NBC\n"
    
    choices["Opt-WindowDistribution"] = "Reference-9.36"
    cityName = params_for_ruleset['cityName']
    if ($PermafrostHash[cityName] == "continuous")
      choices["Opt-Specifications"] = "NBC_Specs_Perma"
      applyPermafrostRules = true
    else
        choices["Opt-Specifications"] = "NBC_Specs_Normal"
    end


    # ACH: 
    if (year == "2020") then 
        # This is a work-around; need to detect "guarded/unguarded" H2k Input parameter 
        # And apply right parameter accordingly
        if (params_for_ruleset["house_type"] == "SingleDetached") then
          choices["Opt-ACH"] = "ACH_NBC_2p5"
        else
          choices["Opt-ACH"] = "ACH_NBC_3p0"
        end 
    else 
        choices["Opt-ACH"] = "ACH_NBC"
    end
    
    # Opaque components : 
    
    # Thermal zones and HDD by rule type
    #-------------------------------------------------------------------------
    if params_for_ruleset["vent_sys_type"] == "noHRV"
        
        # Zone 4 ( HDD < 3000) without an HRV
        if params_for_ruleset["climate_zone"] =="cz4" then 
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] = "NBC_Wall_zone4"
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone4"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
          choices["Opt-FloorHeaderIntIns"]               ="NBC_RSI2.78_int"
          choices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"] = "NBC-zone4-window"
          
          choices["Opt-Doors"] = "NBC-zone4-door"
          choices["Opt-DoorWindows"] = "NBC-zone4-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          
          # LEGACY H2K Foundation /
          
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone4"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone4"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone4" # If there are any slabs, insulate them
          end
          
          # NEW-H2K Foundation, no HRV
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_1.99RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
          
          
          # Zone 5 ( 3000 < HDD < 3999) without an HRV
        elsif params_for_ruleset["climate_zone"] == "cz5" then
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"]    = "NBC_Wall_zone5_noHRV"
          choices["Opt-FloorHeaderIntIns"]                 ="NBC_RSI3.08_int"
          choices["Opt-AtticCeilings"]                     = "NBC_Ceiling_zone5_noHRV"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
          
          choices["Opt-ExposedFloor"]                      = "NBC_936_4.67RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"] = "NBC-zone5-window"
          
          choices["Opt-Doors"] = "NBC-zone5-door"
          choices["Opt-DoorWindows"] = "NBC-zone5-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone5_noHRV"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone5_noHRV"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone5" # If there are any slabs, insulate them
          end
          
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
          
          
          # Zone 6 ( 4000 < HDD < 4999) without an HRV
        elsif params_for_ruleset["climate_zone"] == "cz6" then
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] = "NBC_Wall_zone6_noHRV"
          choices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone6"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
          
          choices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"]                = "NBC-zone6-window"
          
          choices["Opt-Doors"] = "NBC-zone6-door"
          choices["Opt-DoorWindows"] = "NBC-zone6-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone6_noHRV"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone6_noHRV"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone6" # If there are any slabs, insulate them
              
          end
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
          
          # Zone 7A ( 5000 < HDD < 5999) without an HRV
        elsif params_for_ruleset["climate_zone"] == "cz7a" then
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] = "NBC_Wall_zone7A_noHRV"
          choices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7A_noHRV"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
          
          choices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"]                = "NBC-zone7A-window"
          
          choices["Opt-Doors"] = "NBC-zone7A-door"
          choices["Opt-DoorWindows"] = "NBC-zone7A-Doorwindow"
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone7A_noHRV"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone7A_noHRV"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone7A_noHRV" # If there are any slabs, insulate them
              
          end
          
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_3.46RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_3.72RSI"
          
          
          
          # Zone 7B ( 6000 < HDD < 6999) without an HRV
        elsif params_for_ruleset["climate_zone"] == "cz7b" then
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] == "NBC_Wall_zone7B_noHRV"
          # Floor header: Table 9.36.2.6 calls for RSI 3.85, but "NBC_Wall_zone7B_noHRV" includes
          # R-5 exterior insulation that is continuous over wall & header assemblies. Therefore
          # adding an additional "NBC_RSI2.97_int"  brings header to code level.
          choices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
          
          info_out("NBC Ruleset - zone 8 requires RSI 3.85 for header/wall assemblies; "+
          "header internal insulation set to RSI 2.97 - Wall definition (NBC_Wall_zone8_noHRV) "+
          "includes R-5 continuous insulation that will be added to header")
          
          
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7B"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
          
          choices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"]                = "NBC-zone7B-window"
          
          choices["Opt-Doors"] = "NBC-zone7B-door"
          choices["Opt-DoorWindows"] = "NBC-zone7B-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone7B_noHRV"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone7B_noHRV"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone7B_noHRV" # If there are any slabs, insulate them
              
          end
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_3.46RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          if ( applyPermafrostRules ) then
              choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_4.44RSI"
          else
              choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          end
          choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_3.72RSI"
          
          
          
          # Zone 8 (HDD <= 7000) without an HRV
        elsif params_for_ruleset["climate_zone"] == "cz8" then 
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] = "NBC_Wall_zone8_noHRV"
          # Floor header: Table 9.36.2.6 calls for RSI 3.85, but NBC_Wall_zone8_noHRV includes
          # R-5 exterior insulation that is continuous over wall & header assemblies. Therefore
          # adding an additional "NBC_RSI2.97_int"  brings header to code level.
          choices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
          
          info_out("NBC Ruleset - zone 8 requires RSI 3.85 for header/wall assemblies; "+
          "header internal insulation set to RSI 2.97 - Wall definition (NBC_Wall_zone8_noHRV) "+
          "includes R-5 continuous insulation that will be added to header")
          
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone8"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
          
          choices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"]                =  "NBC-zone8-window"
          
          choices["Opt-Doors"] = "NBC-zone8-door"
          choices["Opt-DoorWindows"] = "NBC-zone8-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone8_noHRV"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone8_noHRV"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone8_noHRV" # If there are any slabs, insulate them
              
          end
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_3.97RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          if ( applyPermafrostRules ) then
              choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_4.44RSI"
          else
              choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          end
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_4.59RSI"
          
        end
        
        #-------------------------------------------------------------------------
    elsif params_for_ruleset["vent_sys_type"] == "HRV"
        
        # Zone 4 ( HDD < 3000) without an HRV
        if params_for_ruleset["climate_zone"] =="cz4" then
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] = "NBC_Wall_zone4"
          choices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.78_int"
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone4"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
          
          choices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"] = "NBC-zone4-window"
          
          choices["Opt-Doors"] = "NBC-zone4-door"
          choices["Opt-DoorWindows"] = "NBC-zone4-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone4"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone4"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone4" # If there are any slabs, insulate them
              
          end
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_1.99RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
          
          
          
          # Zone 5 ( 3000 < HDD < 3999) with an HRV
        elsif params_for_ruleset["climate_zone"] == "cz5" then
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] = "NBC_Wall_zone5_HRV"
          choices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone5_HRV"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
          
          choices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"]                = "NBC-zone5-window"
          
          choices["Opt-Doors"] = "NBC-zone5-door"
          choices["Opt-DoorWindows"] = "NBC-zone5-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone5_HRV"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone5_HRV"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone5" # If there are any slabs, insulate them
              
          end
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
          
          
          # Zone 6 ( 4000 < HDD < 4999) with an HRV
        elsif params_for_ruleset["climate_zone"] == "cz6" then
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] = "NBC_Wall_zone6_HRV"
          choices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone6"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI4.67"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI4.67"
          
          choices["Opt-ExposedFloor"]                   = "NBC_936_4.67RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"]                = "NBC-zone6-window"
          
          choices["Opt-Doors"] = "NBC-zone6-door"
          choices["Opt-DoorWindows"] = "NBC-zone6-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone6_HRV"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone6_HRV"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone6" # If there are any slabs, insulate them
              
          end
          
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_1.96RSI"
          
          # Zone 7A ( 5000 < HDD < 5999) with an HRV
        elsif params_for_ruleset["climate_zone"] == "cz7a" then
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] = "NBC_Wall_zone7A_HRV"
          choices["Opt-FloorHeaderIntIns"]              = "NBC_RSI2.97_int"
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7A_HRV"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
          
          choices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"]                = "NBC-zone7A-window"
          
          choices["Opt-Doors"] = "NBC-zone7A-door"
          choices["Opt-DoorWindows"] = "NBC-zone7A-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone7A_HRV"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone7A_HRV"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone7A_HRV" # If there are any slabs, insulate them
              
          end
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_2.84RSI"
          
          
          # Zone 7B ( 6000 < HDD < 6999) with an HRV
        elsif params_for_ruleset["climate_zone"] == "cz7b" then
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] = "NBC_Wall_zone7B_HRV"
          choices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone7B"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
          choices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"]                =  "NBC-zone7B-window"
          
          choices["Opt-Doors"] = "NBC-zone7B-door"
          choices["Opt-DoorWindows"] = "NBC-zone7B-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone7B_HRV"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone7B_HRV"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone7B_HRV" # If there are any slabs, insulate them
              
          end
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          if ( applyPermafrostRules ) then
              choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_4.44RSI"
          else
              choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          end
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_2.84RSI"
          
          
          # Zone 8 (HDD <= 7000) with an HRV
        elsif params_for_ruleset["climate_zone"] == "cz8" then
          # Effective thermal resistance of above-ground opaque assemblies (Table 9.36.2.6 A&B)
          choices["Opt-AboveGradeWall"] = "NBC_Wall_zone8_HRV"
          choices["Opt-FloorHeaderIntIns"]              = "NBC_RSI3.08_int"
          choices["Opt-AtticCeilings"]                  = "NBC_Ceiling_zone8"
          choices["Opt-CathCeilings"]                   = "NBC_CathCeiling_RSI5.02"
          choices["Opt-FlatCeilings"]                   = "NBC_FlatCeiling_RSI5.02"
          
          choices["Opt-ExposedFloor"]                   = "NBC_936_5.02RSI"
          
          # Effective thermal resistance of fenestration (Table 9.36.2.7.(1))
          
          choices["Opt-Windows"]                =  "NBC-zone8-window"
          
          choices["Opt-Doors"] = "NBC-zone8-door"
          choices["Opt-DoorWindows"] = "NBC-zone8-Doorwindow"
          
          # Effective thermal resistance of assemblies below-grade or in contact with the ground (Table 9.36.2.8.A&B)
          choices["Opt-H2KFoundation"] = "NBC_BCIN_zone8_HRV"
          if params_for_ruleset["heated_crawlspace"]
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SCB_zone8_HRV"
          else # There is a crawlspace, but it isn't heated. Treat floor above crawlspace as exposed floor
              choices["Opt-H2KFoundationSlabCrawl"] = "NBC_SOnly_zone8_HRV" # If there are any slabs, insulate them
              
          end
          
          choices["Opt-FoundationWallIntIns"] = "NBC_936_2.98RSI"
          choices["Opt-FoundationWallExtIns"] = "NBC_936_uninsulated_EffR0"
          if ( applyPermafrostRules ) then
              choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_4.44RSI"
          else
              choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
          end
          choices["Opt-FoundationSlabOnGrade"] = "NBC_936_3.72RSI"
        end 
    else
        fatalerror ("Unknown ventilaton specification '#{ventSpec}' for NBC 936 ruleset")
    end   # Check on NBC rule set type
    
    return choices

  end 
 
  # ====================================================================================
  def self.apply_936_mech_requirements(year,params_for_ruleset,choices)
    
    if (debug_status)
      debug_out ("   - year: #{year}\n")
      debug_out ("   - passed params: #{params_for_ruleset.pretty_inspect} \n")
      debug_out ("status of choices: #{choices}")
    end 
    if ( params_for_ruleset["DHW_type"] =~ /gas/i && year == "2020") 
    
       choices["Opt-DHWSystem"] = "NBC_2020_DHW_gas_EF0.69"
    
    elsif ( params_for_ruleset["DHW_type"] =~ /gas/i && year == "2015")
    
       choices["Opt-DHWSystem"] = "NBC-HotWater_gas" 
    
    elsif ( params_for_ruleset["DHW_type"] =~ /elec/i )
    
       choices["Opt-DHWSystem"] = "NBC-HotWater_elec"
    
    elsif ( params_for_ruleset["DHW_type"] =~ /oil/i ) 
    
       choices["Opt-DHWSystem"] = "NBC-HotWater_oil"
       
    end 

    

    if (params_for_ruleset["SH_type_1"] =~ /gas/i && year == "2020" )        # value is "Natural gas"
    
       choices["Opt-Heating-Cooling"] = "NBC-gas-furnace-2020" 

    elsif (params_for_ruleset["SH_type_1"] =~ /gas/i && year == "2020 ") 

       choices["Opt-Heating-Cooling"] = "NBC-gas-furnace"

    elsif (params_for_ruleset["SH_type_1"] =~ /Oil/i  )    # value is Oil
       
       choices["Opt-Heating-Cooling"] = "NBC-oil-heat"

    elsif (params_for_ruleset["SH_type_1"] =~ /Elect/i) != nil   # value is "Electricity

       if ( params_for_ruleset["SH_type_2"]=~ /HeatPump/ )  # TODO: Should we also include WSHP & GSHP in this check?
          choices["Opt-Heating-Cooling"] = "NBC-CCASHP"

       else
          choices["Opt-Heating-Cooling"] = "NBC-elec-heat"
          
       end

    end

    choices["Opt-VentSystem"] =  "VentFans_sre_0"
    return choices

  end 
end 