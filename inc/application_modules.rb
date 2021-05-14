 
# file for holding functions related to specific applications - e.g. BC step code


module BCStepCode

# Technical Bulletin B18-08 describes the changes to the BC Energy Step Code effective December 10, 2018
#  / https://www2.gov.bc.ca/assets/gov/farming-natural-resources-and-industry/construction-industry/building-codes-and-standards/bulletins/b18_08_revision1_to_bcbc_stepcode.pdf
#

BC_STEP_TEDI_MAX = {
  "Zone 4" => {
    "Step_1" => nil,
    "Step_2" => 35.0,
    "Step_3" => 30.0,
    "Step_4" => 25.0,
    "Step_5" => 15.0
  },
  "Zone 5" => {
    "Step_1" => nil,
    "Step_2" => 45.0,
    "Step_3" => 40.0,
    "Step_4" => 30.0,
    "Step_5" => 20.0
  },
  "Zone 6" => {
    "Step_1" => nil,
    "Step_2" => 60.0,
    "Step_3" => 50.0,
    "Step_4" => 40.0,
    "Step_5" => 25.0
  },
  "Zone 7a" => {
    "Step_1" => nil,
    "Step_2" => 80.0,
    "Step_3" => 70.0,
    "Step_4" => 55.0,
    "Step_5" => 35.0
  },
  "Zone 7b" => {
    "Step_1" => nil,
    "Step_2" => 100.0,
    "Step_3" => 90.0,
    "Step_4" => 65.0,
    "Step_5" => 50.0
  },
  "Zone 8" => {
    "Step_1" => nil,
    "Step_2" => 120.0,
    "Step_3" => 105.0,
    "Step_4" => 80.0,
    "Step_5" => 60.0
  },
}


  def BCStepCode.getStepByTEDI(climateZone,tedi)

    debug_off
    debug_out "Inputs: `#{climateZone}`, `#{tedi}`\n"
    if ( BC_STEP_TEDI_MAX[climateZone].nil? ) then
      help_out("byTopic","cliamte_Zone names")
      fatalerror ("Unknown climate zone #{climateZone}")
    end

    returnStep = "Step_1"
    BC_STEP_TEDI_MAX[climateZone].each do | stepname, tediReq |
      next if ( tediReq.nil? )
      break if ( tediReq < tedi )
      returnStep = stepname
    end

    debug_out "Returing #{returnStep}"

    return returnStep.gsub(/_/," ")

  end


end


module LEEPPathways 
  


  PathwaysECMs = {
    "Opt-AtticCeilings:+:CeilR40"           => "lpATT_01",
    "Opt-AtticCeilings:+:CeilR50"           => "lpATT_02",  
    "Opt-AtticCeilings:+:CeilR60"           => "lpATT_03",
    "Opt-AtticCeilings:+:CeilR70"           => "lpATT_04",  
    "Opt-AtticCeilings:+:CeilR80"           => "lpATT_05",

    "Opt-ACH:+:New-Const-air_seal_to_3.50_ach"  => "lpACH_01",
    "Opt-ACH:+:New-Const-air_seal_to_2.50_ach"  => "lpACH_02",
    "Opt-ACH:+:New-Const-air_seal_to_1.50_ach"  => "lpACH_03",
    "Opt-ACH:+:New-Const-air_seal_to_0.60_ach"  => "lpACH_04",
    "Opt-ACH:+:New-Const-air_seal_to_1.00_ach"  => "lpACH_05",


    "Opt-Windows:+:NC-2g-MG-u1.82"   => "lpWIN_01",
    "Opt-Windows:+:NC-2g-HG-u1.65"   => "lpWIN_02",
    "Opt-Windows:+:NC-2g-LG-u1.65"   => "lpWIN_03",
    "Opt-Windows:+:NC-3g-HG-u1.08"   => "lpWIN_04",
    "Opt-Windows:+:NC-3g-LG-u1.08"   => "lpWIN_05",  
    "Opt-Windows:+:NC-3g-LG-u0.85"   => "lpWIN_06",  
    "Opt-Windows:+:NC-2g-MG-u1.65"   => "lpWIN_07",
    "Opt-Windows:+:NC-3g-MG-u1.08"   => "lpWIN_08",


    "Opt-FoundationWallExtIns:+:uninsulated"       => "lpFDe_01" ,
    "Opt-FoundationWallExtIns:+:xps1.5inEffR7.5"   => "lpFDe_02" ,        
    "Opt-FoundationWallExtIns:+:xps2.5inEffR12.5"  => "lpFDe_03" ,        
    "Opt-FoundationWallExtIns:+:xps3inEffR15"      => "lpFDe_04" , 
    "Opt-FoundationWallExtIns:+:xps4inEffR20"      => "lpFDe_05" , 


    "Opt-FoundationWallIntIns:+:WoodFrameEffR11"  => "lpFDi_01" ,    
    "Opt-FoundationWallIntIns:+:WoodFrameEffR15"  => "lpFDi_02" ,    
    "Opt-FoundationWallIntIns:+:WoodFrameEffR17"  => "lpFDi_03" ,      

    "Opt-FoundationSlabBelowGrade:+:uninsulated"  => "lpSBG_01" , 
    "Opt-FoundationSlabBelowGrade:+:xps4inEffR20" => "lpSBG_02" , 
    "Opt-FoundationSlabBelowGrade:+:xps2inEffR10" => "lpSBG_03" , 


    "Opt-Heating-Cooling:+:gas-furnace-psc"     => "lpH&C_01", 
    "Opt-Heating-Cooling:+:gas-furnace-ecm"     => "lpH&C_02", 
    "Opt-Heating-Cooling:+:gas-furnace-ecm+AC"  => "lpH&C_03", 
    "Opt-Heating-Cooling:+:CCASHP"              => "lpH&C_04", 
    "Opt-Heating-Cooling:+:ASHP"                => "lpH&C_05", 
    "Opt-Heating-Cooling:+:elec-baseboard"      => "lpH&C_06", 
    "Opt-Heating-Cooling:+:elec-baseboard+AC"   => "lpH&C_07",


    "Opt-AboveGradeWall:+:NC_R-16(eff)_2x6-16inOC_R19-batt_poly_vb" => "lpMWL_01",
    "Opt-AboveGradeWall:+:NC_R-22(eff)_2x6-16inOC_R22-batt+1inXPS_poly_vb" => "lpMWL_02",
    
    "Opt-AboveGradeWall:+:NC_R-26(eff)_2x6-16inOC_R19-batt+2inXPS_poly_vb" => "lpMWL_03",
    "Opt-AboveGradeWall:+:NC_R-30(eff)_2x6-16inOC_R24-batt+3inMineralWool_poly_vb" => "lpMWL_04",
    "Opt-AboveGradeWall:+:NC_R-40(eff)_2x6-16inOC_R24-batt+4.5inXPS_poly_vb" => "lpMWL_05",


    "Opt-DHWSystem:+:gas_storagetank_w/powervent_ef0.67" => "lpDHW_01",
    "Opt-DHWSystem:+:GasInstantaneous" => "lpDHW_02",
    "Opt-DHWSystem:+:HPHotWater" => "lpDHW_03",
    "Opt-DHWSystem:+:elec_storage_ef0.89" => "lpDHW_04",

    "Opt-VentSystem:+:HRV_sre_60"         => "lpHRV_01",  
    "Opt-VentSystem:+:HRV_sre_78"         => "lpHRV_02",
    "Opt-DWHR:+:NA"     => "lpDWHR_00",

    "Opt-DWHR:+:DWHR-eff-55"     => "lpDWHR_01"

  }
  GoodArchFields = [
    "archID",
    "h2k-File",
#    "listOfLocations",
    "house-description:type", 
    "house-description:stories",
    "house-description:buildingType",
  #   "house-description:frontOrient",  
  #   "house-description:MURBUnits",
  #   "locale:region",
  #   "locale:weatherLoc",   
  #   "dimensions:below-grade:basement:configuration",
  #   "dimensions:below-grade:basement:exposed-perimeter",
    "dimensions:below-grade:basement:floor-area",
  #   "dimensions:below-grade:basement:total-perimeter",
    #  "dimensions:below-grade:crawlspace:configuration",
    #  "dimensions:below-grade:crawlspace:exposed-perimeter",
    #  "dimensions:below-grade:crawlspace:floor-area",
    #  "dimensions:below-grade:crawlspace:total-perimeter",
    #  "dimensions:below-grade:slab:configuration",
    #  "dimensions:below-grade:slab:exposed-perimeter",
    #  "dimensions:below-grade:slab:floor-area",
    #  "dimensions:below-grade:slab:total-perimeter",
    "dimensions:below-grade:walls:below-grade-area:external",
    #  "dimensions:below-grade:walls:below-grade-area:internal",
    "dimensions:below-grade:walls:total-area:external",
    #  "dimensions:below-grade:walls:total-area:internal",
    #  "dimensions:ceilings:area:all",
    "dimensions:ceilings:area:attic",
    #  "dimensions:ceilings:area:cathedral",
    #  "dimensions:ceilings:area:flat",
    #  "dimensions:exposed-floors:area:total",
    "dimensions:headers:area:above-grade",
    #  "dimensions:headers:area:below-grade",
    #  "dimensions:headers:area:total",
    "dimensions:heatedFloorArea",
    "dimensions:walls:above-grade:area:doors",
    #  "dimensions:walls:above-grade:area:gross",
    "dimensions:walls:above-grade:area:headers",
    "dimensions:walls:above-grade:area:net",
    "dimensions:walls:above-grade:area:windows",
    #  "dimensions:walls:above-grade:count",
    #  "dimensions:walls:above-grade:perimeter",
    #  "dimensions:windows:area:byOrientation:1",
    #  "dimensions:windows:area:byOrientation:2",
    #  "dimensions:windows:area:byOrientation:3",
    #  "dimensions:windows:area:byOrientation:4",
    #  "dimensions:windows:area:byOrientation:5",
    #  "dimensions:windows:area:byOrientation:6",
    #  "dimensions:windows:area:byOrientation:7",
    #  "dimensions:windows:area:byOrientation:8",
    "dimensions:windows:area:total"
  ]

  GoodECMFields = Array.new [
    "ecmID",
    "attribute",
    "measure",
    "longName"
  ]

  GoodLocFields = Array.new [ 
    "locID",
    "WeatherCityName",
    "Region",
    "HDDs",
    "ClimateZone"
  ]

  GoodECMCatagories = Array.new [ 
    "Opt-ACH",
    "Opt-Windows",
    "Opt-WindowDistribution",
    "Opt-AtticCeilings",
    "Opt-CathCeilings",
    "Opt-FlatCeilings",
    "Opt-AboveGradeWall",
    "Opt-FloorHeaderIntIns",
    "Opt-ExposedFloor",
    "Opt-FoundationSlabBelowGrade", 
    "Opt-FoundationSlabOnGrade", 
    "Opt-FoundationWallExtIns", 
    "Opt-FoundationWallIntIns", 
    "Opt-VentSystem",
    "Opt-Heating-Cooling",
    "Opt-DHWSystem",
    "Opt-DWHR",
    "Opt-H2KFoundation",

  ]

  GoodRunFields = Array.new [ 
    "runID",
    "archID",
    "locID",
    "listOfECMs",
    "version:git-branch",
    "version:git-revision",  
    "version:HOT2000",
    "version:h2kHouseFile",
    "Energy-Total-GJ",
    "Energy-HeatingGJ",
    "Energy-CoolingGJ",
    "Energy-VentGJ",
    "Energy-DHWGJ",
    "Energy-PlugGJ",
    "EnergyEleckWh",
    "EnergyGasM3",
    "EnergyOil_l",
    "EnergyProp_L",
    "EnergyWood_cord",
    "AuxEnergyReq-HeatingGJ",
    "Gross-HeatLoss-GJ",
    "PEAK-Cooling-W",
    "PEAK-Heating-W",
    "TEDI_kWh_m2",
    "MEUI_kWh_m2",
    "House-Upgraded",
    "upgrade-package-list",
    "House-ListOfUpgrades",
    "Recovered-results",
  #  "Opt-Location",
  #  "HDDs", 
  #  "Opt-ACH",

  #  "Opt-Windows",

  #  "Opt-WindowDistribution",
  #  "Opt-AtticCeilings",
  #  "Opt-CathCeilings",
  #  "Opt-FlatCeilings",
  #  "Opt-AboveGradeWall",
  #  "Opt-FloorHeaderIntIns",
  #  "Opt-ExposedFloor",
  #  "Opt-FoundationSlabBelowGrade", 
  #  "Opt-FoundationSlabOnGrade", 
  #  "Opt-FoundationWallExtIns", 
  #  "Opt-FoundationWallIntIns", 
  #  "Opt-VentSystem",
  #  "Opt-Heating-Cooling",
  #  "Opt-DHWSystem",
  #  "Opt-DWHR",
    #  "HVAC:ASHP:capacity_kW",
    #  "HVAC:ASHP:count",
    #  "HVAC:AirConditioner:capacity_kW",
    #  "HVAC:AirConditioner:count",
    #  "HVAC:Baseboards:capacity_kW",
    #  "HVAC:Baseboards:count",
    #  "HVAC:Boiler:capacity_kW",
    #  "HVAC:Boiler:count",
    #  "HVAC:Furnace:capacity_kW",
    #  "HVAC:Furnace:count",
    #  "HVAC:GSHP:capacity_kW",
    #  "HVAC:GSHP:count",
    #  "HVAC:Ventilator:capacity_l/s",
    #  "HVAC:Ventilator:count",
    #  "HVAC:designLoads:cooling_W",
    #  "HVAC:designLoads:heating_W",
    #  "HVAC:fansAndPump:count",
    #  "HVAC:fansAndPump:powerHighW",
    #  "HVAC:fansAndPump:powerLowW"
    "Opt-Ruleset",
    "Ruleset-Ventilation",
    "Ruleset-Fuel-Source",
    "Opt-Baseloads",
    "Opt-Temperatures", 
  ]


  def LEEPPathways.EmptyBuffers()
    $LEEParchetypeDataBuffer = Array.new 
    $LEEPrunData             = Array.new 
    $LEEPecmDataBuffer       = Array.new 
    $LEEPlocDataBuffer       = Array.new 
  end 


  def LEEPPathways.ExtractPathwayData(result)
    log_out ("Extracting Pathway Data")
    
    
    # debug_on

    options = HTAPData.getOptionsData() 

    badRecords = false 
    badRecordNums = Array.new 

    gitBranch   = "nobranch" # allData["htap-configuration"]["git-branch"]
    gitRevision = "noRevision" #allData["htap-configuration"]["git-revision"]
    if (result["status"]["success"] ) then 

      archID = getArchID(result)
      locID = getLocID(result)    
      thisRun = Hash.new 
      $LEEPRunID += 1
      thisRun["runID"] = $LEEPRunID
      thisRun["archID"] = archID
      thisRun["locID"] = locID

      thisRun["version:git-branch"]= gitBranch
      thisRun["version:git-revision"] = gitRevision
      thisRun.merge!( flattenHash( result["input"]   ) ) 
      thisRun.merge!( flattenHash( result["configuration"]) ) 
      thisRun.merge!( flattenHash( result["output"]) ) 
      thisRun.merge!( flattenHash( result["cost-estimates"]["costing-dimensions"]) ) 

      thisRun["listOfECMs"] = getECMs(result["input"]) 

      #stream_out("Reading result # #{result_count}...                     \r" )
    
      $LEEPrunData.push(thisRun)

    else
      badRecords = true 
      badRecordNums.push(result["result-number"])
    end     


  end 


  def self.ReconstituteDataStructure(txt)
    firstRow = true 
    header = Array.new 
    data = Array.new
    dataStructure = Array.new 
    txt.split("\n").each do | line |
      
      if firstRow then 
        header = line.split(",")
        firstRow = false 
      else 
        data = line.split(",")
        record = Hash.new 
        i = 0 
        until i == header.length do 
          record[header[i]] = data[i]
          i+=1       
        end 
        dataStructure.push record    
      end 
 
    end 
    data.clear
    header.clear
    txt.clear 
    return dataStructure
  end 

  def LEEPPathways.OpenOutputFiles(mode="overwrite")

    log_out("Opening LEEP output files [mode=#{mode}\n")
    if (mode == "overwrite")
      $ECM_outfile = File.open('./Pathways_ListOfECMs.csv', 'w')
      $ARC_outfile = File.open('./Pathways_HTAPArchetypeData.csv', 'w')
      $LOC_outfile = File.open('./Pathways_HTAPLocationData.csv', 'w')
      $RUN_outfile = File.open('./Pathways_HTAPRunData.csv', 'w')
      $LEEPprintHeader = true 
      $LEEPRunID = 0 
    elsif ( mode =="append")
      #begin 
        # Parse ECM output file, and reconsititute data hash

        log_out ("Rebuilding LEEP pathways data structures from prior runs")
        previousData = File.read('./Pathways_ListOfECMs.csv')
        $LEEPecmData = self.ReconstituteDataStructure(previousData)
        previousData.clear
        $LEEPecmData.each do | ecmRecord |
          ecmRecord["searchTextKey"] = "#{ecmRecord["attribute"]}:+:#{ecmRecord["measure"]}"
        end 
        previousData = File.read('./Pathways_HTAPLocationData.csv')
        $LEEPlocData = self.ReconstituteDataStructure(previousData)
        previousData.clear 

        previousData = File.read('./Pathways_HTAPArchetypeData.csv')
        $LEEParchetypeData = self.ReconstituteDataStructure(previousData)
        previousData.clear

        $LEEPRunID = File.read('./Pathways_HTAPRunData.csv').split("\n").length

        $ECM_outfile = File.open('./Pathways_ListOfECMs.csv', 'a')
        $ARC_outfile = File.open('./Pathways_HTAPArchetypeData.csv', 'a')
        $LOC_outfile = File.open('./Pathways_HTAPLocationData.csv', 'a')
        $RUN_outfile = File.open('./Pathways_HTAPRunData.csv', 'a')
        $LEEPprintHeader = false 
    else
      fatalerror ("Logic error - unknown mode #{mode}")
    end

  end   

  def LEEPPathways.ExportPathwayData()
    #debug_on 
    #debug_out ("Export - Print headers status: #{$LEEPprintHeader}\n")
    flatOutput = convertToCSV($LEEParchetypeDataBuffer,$LEEPprintHeader, GoodArchFields)
    $ARC_outfile.puts flatOutput if (! emptyOrNil(flatOutput) )
    $ARC_outfile.flush 

    flatOutput = convertToCSV($LEEPlocDataBuffer, $LEEPprintHeader,GoodLocFields)
    $LOC_outfile.puts flatOutput if (! emptyOrNil(flatOutput) )
    $LOC_outfile.flush
    flatOutput = convertToCSV($LEEPrunData, $LEEPprintHeader,GoodRunFields)
    $RUN_outfile.puts flatOutput if (! emptyOrNil(flatOutput) )
    $RUN_outfile.flush 
    ecmDataSort = $LEEPecmDataBuffer.sort_by{|ecm| ecm["ecmID"]}
    flatOutput = convertToCSV(ecmDataSort, $LEEPprintHeader,GoodECMFields)
    $ECM_outfile.puts flatOutput if (! emptyOrNil(flatOutput) )
    $ECM_outfile.flush
    #availabeData = File.open('./Pathways_available_fields.txt','w')
    #availabeData.puts listOfKeys
    #availabeData.close

    $LEEPprintHeader = false 

  end 

  def LEEPPathways.CloseOutputFiles()
    log_out("Closing LEEP output files\n")
    $ECM_outfile.close
    $ARC_outfile.close
    $LOC_outfile.close
    $RUN_outfile.close
  end 

  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  # GetArchID - takes a HTAP run result, determines if it already exists in the archetype set, and 
  # adds it if not. Returns the archetype ID
  def self.getArchID(result)
    foundArch = false 
    archID = nil
    locID = getLocID(result)
    archCount = 0
    #debug_ 
    
    if (! emptyOrNil($LEEParchetypeData) ) then 
      $LEEParchetypeData.each do | archetype | 
        archCount += 1
        debug_out (" > # #{archetype["archID"]} - #{archetype["h2k-File"]} == #{result["archetype"]["h2k-File"]} ?")
        if archetype["h2k-File"] == result["archetype"]["h2k-File"] then 
          archID = archetype["archID"]
          foundArch = true 
          #debug_on

          #debug_out "TEST: - #{locID} [#{archetype["listOfLocations"]}]\n"
          #if (! bListContainsID(locID, archetype["listOfLocations"])) then 
          #  archetype["listOfLocations"] += "#{locID};"
          #end

          break
        end 
        debug_out ("#{foundArch}\n")
      end 
    end 
        
    if ( ! foundArch )

      debug_out "Saving archetype !\n"
      archID = archCount + 1
      thisArchetype = Hash.new 
      thisArchetype["archID"] = archID  
      thisArchetype["h2k-File"] = result["archetype"]["h2k-File"]
      thisArchetype["listOfLocations"] = "#{locID};"
      dimensionData = flattenHash(result["cost-estimates"]["costing-dimensions"])
      
      debug_out "archID: #{archID}\n"
      dimensionData.each do | member |
        #debug_out (">#{member.pretty_inspect}\n") 
      end 
      #debug_out (">#{dimensionData.pretty_inspect}\n") 


      debug_out ("> saving #{thisArchetype}\n")
      thisArchetype.merge!(dimensionData)
      

      #result["archetype"].keys.each do | key |
      #  if ($archetypeFields.include?(key) )
      #    thisArchetype[key] = result["archetype"][key]
      #  end 
      #end 

      $LEEParchetypeData.push(thisArchetype)
      $LEEParchetypeDataBuffer.push(thisArchetype)

      debug_off
    end 

    return archID

  end 


  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  # GetLocID - takes a HTAP run result, determines if it already exists in the location set, and 
  # adds it if not. Returns the location ID
  def self.getLocID(result)
    
    #debug_on
    locFound = false 
    locID = nil
    locCount = 0
    #pp result 
    # possibly search for id
    if ( ! emptyOrNil($LEEPlocData) )
      $LEEPlocData.each do | location |
        locCount += 1
        debug_out ("\n")
        if location["WeatherCityName"] == result["input"]["Run-Locale"]
          locFound = true 
          locID = location["locID"]
          break
        end 
      end 

    end 
    
    if ( ! locFound )
      locID = locCount + 1 
      thisLoc = { "locID" => locID ,
                  "WeatherCityName" => result["input"]["Run-Locale"] ,
                  "Region" => result["input"]["Run-Region"] ,
                  "HDDs" => result["output"]["HDDs"].to_i,
                  "ClimateZone" => result["archetype"]["climate-zone"]
      }
      $LEEPlocData.push(thisLoc)
      $LEEPlocDataBuffer.push(thisLoc)
    end 

    debug_out "Returning loc [#{locID}]\n"
    return locID

  end   

  
  # . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
  # GetECMs - takes a HTAP run result, determines if the selected options exist in the list of ecms,
  # adds them it if not. Returns a ';' delimited string of selected ECMs.

  def self.bListContainsID(thisID, thisList)
    #debug_on
    thisArray = thisList.split(/;/)
    #debug_out ("searching for #{thisID} in #{thisArray.pretty_inspect}\n")
    return thisArray.include?(thisID.to_s)
  end 

  def self.getECMs(inputHash)
    #debug_on

    listOfECMs = ""

    inputHash.each do | key, value |
      ecmCount = 0 
      ecmID = ""
      foundECM = false 

      # is there a proxy ? 
      finalValue = HTAPData.returnProxyIfExists(key, value)

      if (GoodECMCatagories.include?(key) )
      
        searchTextKey = "#{key}:+:#{finalValue}"
        if ( ! emptyOrNil ($LEEPecmData) )
        
          debug_out "Key: #{key} => #{finalValue} ?"

          $LEEPecmData.each do | ecm | 
            ecmCount += 1
            if ( ecm["searchTextKey"] == searchTextKey )
              foundECM = true
              ecmID = ecm["ecmID"]
              debug_out "FOUND @ #{ecmID} !" 
              break
            end 
          end  
        end 
      
        if ( ! foundECM )

          if ( PathwaysECMs.keys.include?(searchTextKey) ) then 
            ecmID = PathwaysECMs[searchTextKey]+"_X" 
          else 
            ecmID = "id-#{ecmCount}_X" 
          end 
          record = { 
              "ecmID" => ecmID, 
              "searchTextKey" => searchTextKey, 
              "attribute"     => key, 
              "measure"       => finalValue,
              "longName"      => searchTextKey
            }
          # . check if this ECM is linked to LEEP reserved set. 
          $LEEPecmData.push( record ) 
          $LEEPecmDataBuffer.push(record)
          debug_out "not found. Added new row @ #{ecmID} !"

        end 

        listOfECMs += ";#{ecmID}"
        debug_out ("\n")

      end


    end 
    debug_out "\n LIST OF ECMS: #{listOfECMs}\n"
    debug_off 
    return listOfECMs.gsub(/^;/,"")

  end 


end 


