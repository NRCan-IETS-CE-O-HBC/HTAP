# ==========================================
# H2KUtils.rb: functions used 
# to query, manipulate hot2000 files and 
# the h2k environment. 
# ==========================================


module H2KUtils

  def H2KUtils.getBuilderName(elements)

    $MyBuilderName = elements["HouseFile/ProgramInformation/File/BuilderName"].text
    if $MyBuilderName !=nil
      $MyBuilderName.gsub!(/\s*/, '')    # Removes mid-line white space
      $MyBuilderName.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end

    return $MyBuilderName
  end 
  
  def H2KUtils.getHouseType(elements)
  
    $MyHouseType = elements["HouseFile/House/Specifications/HouseType/English"].text
    if $MyHouseType !=nil
      $MyHouseType.gsub!(/\s*/, '')    # Removes mid-line white space
      $MyHouseType.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end
    
    return $MyHouseType 
  
  end 
  
  def H2KUtils.getStories(elements)
    $MyHouseStoreys = elements["HouseFile/House/Specifications/Storeys/English"].text
    if $MyHouseStoreys!= nil
      $MyHouseStoreys.gsub!(/\s*/, '')    # Removes mid-line white space
      $MyHouseStoreys.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end
    
    return $MyHouseStories
    
  end 

  def H2KUtils.getHeatedFloorArea(elements) 

   # Initialize vars
   areaRatio = 0
   heatedFloorArea = 0
   
   # Get XML file version that "elements" came from. The version can be from the original file (pre-processed inputs)
   # or from the post-processed outputs (which will match the version of the H2K CLI used), depending on the "elements"
   # passed to this function.
   versionMajor = elements["HouseFile/Application/Version"].attributes["major"].to_i
   versionMinor = elements["HouseFile/Application/Version"].attributes["minor"].to_i
   versionBuild = elements["HouseFile/Application/Version"].attributes["build"].to_i

   if (versionMajor == 11 && versionMinor >= 5 && versionBuild >= 8) || versionMajor > 11 then
      # "House", "Multi-unit: one unit", or "Multi-unit: whole building"
      buildingType =  elements["HouseFile/House/Specifications"].attributes["buildingType"]
      areaAboveGradeInput = elements["HouseFile/House/Specifications/HeatedFloorArea"].attributes["aboveGrade"].to_f
      areaBelowGradeInput = elements["HouseFile/House/Specifications/HeatedFloorArea"].attributes["belowGrade"].to_f
   else
      buildingType = "House"
      areaAboveGradeInput = elements["HouseFile/House/Specifications"].attributes["aboveGradeHeatedFloorArea"].to_f
      areaBelowGradeInput = elements["HouseFile/House/Specifications"].attributes["belowGradeHeatedFloorArea"].to_f
   end

   areaUserInputTotal = areaAboveGradeInput + areaBelowGradeInput

   case elements["HouseFile/House/Specifications/Storeys"].attributes["code"].to_f
   when 1
      numStoreysInput = 1
   when 2
      numStoreysInput = 1.5  # 1.5 storeys
   when 3
      numStoreysInput = 2
   when 4
      numStoreysInput = 2.5  # 2.5 storeys
   when 5
      numStoreysInput = 3
   when 6..7
      numStoreysInput = 2    # Split level or Spli entry/raised basement
   end

   # Get house area estimates from the first XML <results> section - these are totals of multiple surfaces
   if  ( elements["HouseFile/AllResults/Results/Other/GrossArea"].attributes["ceiling"]!= nil ) then 
     ceilingAreaOut = elements["HouseFile/AllResults/Results/Other/GrossArea"].attributes["ceiling"].to_i
   else 
     ceilingAreaOut = 0 
   end 
   
   if  ( elements["HouseFile/AllResults/Results/Other/GrossArea"].attributes["slab"]!= nil ) then 
     slabAreaOut = elements["HouseFile/AllResults/Results/Other/GrossArea"].attributes["slab"].to_f
   else
     slabAreaOut = 0
   end 

   if  ( elements["HouseFile/AllResults/Results/Other/GrossArea/Basement"].attributes["floorSlab"] != nil ) then 
      basementSlabAreaOut = elements["HouseFile/AllResults/Results/Other/GrossArea/Basement"].attributes["floorSlab"].to_f
   else 
     basementSlabAreaOut  = 0 
   end 
   
   if numStoreysInput == 1 then 
      # Single storey house -- avoid counting a basement heated area 
      areaEstimateTotal = ceilingAreaOut
   else
      # Multi-storey houses add area of "heated" basement & crawlspace (check if heated!)
      loc = "HouseFile/House/Temperatures/Basement"
      loc2 = "HouseFile/House/Temperatures/Crawlspace"
      if elements[loc].attributes["heated"] == "true" || elements[loc].attributes["heatingSetPoint"] == "true" || elements[loc2].attributes["heated"] == "true"
         areaEstimateTotal = ceilingAreaOut * numStoreysInput + basementSlabAreaOut
      else
         areaEstimateTotal = ceilingAreaOut * numStoreysInput
      end
   end
   
   if areaEstimateTotal > 0
      areaRatio = areaUserInputTotal / areaEstimateTotal
   else
      stream_out("\nNote: House area estimate from results section is zero.\n")
   end
   
   if buildingType.include? "Multi-unit" then
      # For multis using the "new" MURB method assume that heated area comes from a valid user input (not an estimate form ceiling/basement areas)
      heatedFloorArea = areaUserInputTotal
   elsif areaRatio > 0.50 && areaRatio < 2.0 then
      # Accept user input area if it's between 50% and 200% of the estimated area!
      heatedFloorArea = areaUserInputTotal
   else
      # Use user input area for Triplexes (type 4), Apartments (type 5), or
      # row house (end:6 or middle:8) regardless of area ratio (but non-zero)
      houseType = elements["HouseFile/House/Specifications/HouseType"].attributes["code"].to_i
      if (houseType == 4 || houseType == 5 || houseType == 6 || houseType == 8) && areaUserInputTotal > 0
         heatedFloorArea = areaUserInputTotal
      else
         heatedFloorArea = areaEstimateTotal
      end
   end
   
   return heatedFloorArea
 
  end # End GetHeatedFloorArea
  
  
end 