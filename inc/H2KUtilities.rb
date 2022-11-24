
# ==========================================
# H2KUtilities.rb: functions used
# to query, manipulate hot2000 files and
# the h2k environment.
# ==========================================


# Parses a HOT2000 weather library and develops a hash with the right location / region codes. 

module H2KWth

  def H2KWth.read_weather_dir(wfile)

    debug_off
    debug_out "Parsing weather data from #{wfile}"

    prov_names = Array.new 
    prov_links = Array.new
    loc_names = Array.new 

    # Default array for HOT2000 locations
    h2k_locations = {
      "structure" => "tree",
      "costed" => FALSE,
      "options" => {
        "NA" => { 
          "h2kMap" => {
            "base" => {
              "OPT-H2K-WTH-FILE" => "NA",
              "OPT-H2K-Region"   => "NA",
              "OPT-H2K-Location" => "NA",
              "region_name"      => "NA"
            }
          }
        }
      },
      "default" => "NA",
      "stop-on-error" => TRUE,
      "h2kSchema" => [
        "OPT-H2K-WTH-FILE",
        "OPT-H2K-Region",
        "OPT-H2K-Location"
      ]
    }

    firstLine = TRUE
    read_prov_names = FALSE 
    read_prov_links = FALSE
    read_loc_names  = FALSE
    loc_count = 0 
    prov_count = 0 
    loc_count = 0 
    num = 0 
    text = File.open(wfile,"rb:ISO-8859-1"){ |file| file.readlines }
    text.each do | line |
      num = num + 1 

      line.gsub!(/\r/,"")
      line.gsub!(/\n/,"")
      line.gsub!(/^\s+/,"")

      if firstLine
        debug_out "[index] #{line}"
       # re = Regexp.new("/\s/".encode("ISO-8859-1"))
       # re = Regexp.new('/s/')
        loc_count, prov_count, junkb = line.split(/ {2,}/)

        debug_out "# regions: #{prov_count}\n"
        debug_out "# locations: #{loc_count}\n"
        firstLine = FALSE
        read_prov_names = TRUE 
        next 
        
      end 

      if read_prov_names
        debug_out "[prov-name] #{line}"
        line.split(/ {2,}/).each do | name |
          prov_names.push(name)
        end 
        debug_out ("LEN: #{prov_names.length} / #{ prov_count.to_i} ")
        if ( prov_names.length == prov_count.to_i ) then 
          read_prov_names = FALSE 
          read_prov_links = TRUE
          next  
        end 

      end 

      if read_prov_links
        debug_out "[prov-link] #{line}"
        line.split(/ {2,}/).each do | link |
          prov_links.push(link)
        end 
        debug_out ("LEN: #{prov_links.length} / #{ loc_count.to_i} ")
        if ( prov_links.length == loc_count.to_i ) then 
          read_prov_links = FALSE 
          read_loc_names = TRUE
          next  
        end 
      end 

      if read_loc_names
        debug_out "[prov-name] #{line}"
        line.split(/ {2,}/).each do | name |
          loc_names.push(name)
        end 
        debug_out ("LEN: #{loc_names.length} / #{ loc_count.to_i} ")
        if ( loc_names.length == loc_count.to_i ) then  
          read_loc_names = FALSE
          next  
        end 
      end 

    end 


    # deal with comma-separated names 
    loc_names.each do | name | 
      name.gsub!(/,\s+(.+)/, " (\\1)")
      name.gsub!(/ +/,"-")
    end 

    # Create hash
    loc_index = 0
    loc_names.each do | name | 
      loc_index = loc_index + 1 
      h2k_locations["options"][name] = { 
        "h2kMap" => {
          "base" => {
            "OPT-H2K-WTH-FILE" => "Wth2020.dir",
            "OPT-H2K-Region"   => prov_links[loc_index-1],
            "OPT-H2K-Location" => loc_index,
            "region_name"      => prov_names[prov_links[loc_index-1].to_i-1]
          }
        }
      }

    end 


    return h2k_locations

  end



end 

# =========================================================================================
# Functions that Get data from h2k file 
# =========================================================================================
module H2KFile

  # =========================================================================================
  # Returns XML elements of HOT2000 file.
  # =========================================================================================
  def H2KFile.open_xml_as_elements(fileSpec)
    debug_on 
    debug_out ("FILE: #{fileSpec}")
    # Split fileSpec into path and filename
    var = Array.new()
    (var[1], var[2]) = File.split( fileSpec )
    # Determine file extension
    tempExt = File.extname(var[2])
    debug_out "Extention is #{tempExt}.\n"
    
    # Open file...
    begin
      fFileHANDLE = File.new(fileSpec, "r")
      debug_out ("a")
      if fFileHANDLE == nil then
        fatalerror("Could not read #{fileSpec}.\n")
      end

      # Global variable $XMDoc is used elsewhere for access to
      # HOT2000 model file elements access using Path.
      if ( tempExt.downcase == ".h2k" )
        $XMLdoc = Document.new(fFileHANDLE)
      elsif ( tempExt.downcase == ".flc" )
        $XMLFueldoc = Document.new(fFileHANDLE)
      elsif ( tempExt.downcase == ".cod" )
        $XMLCodedoc = Document.new(fFileHANDLE)
      else
        $XMLOtherdoc = Document.new(fFileHANDLE)
      end
    rescue
      warn_out ("Errors encountered when reading #{fileSpec}")
    ensure

      fFileHANDLE.close() # Close the since content read
    end

    if ( tempExt.downcase == ".h2k" )
      return $XMLdoc.elements()
    elsif ( tempExt.downcase == ".flc" )
      return $XMLFueldoc.elements()
    elsif ( tempExt.downcase == ".cod" )
      return $XMLCodedoc.elements()
    else
      return $XMLOtherdoc.elements()
    end
  end
  
    def H2KFile.write_elements_as_xml(filespec)
  
    debug_on 
    #$XMLdoc.elements["HouseFile"].delete_element("AllResults")

    # Save changes to the XML doc in existing working H2K file (overwrite original)
    begin
      debug_out (" Overwriting: #{filespec} \n")
      log_out ("saving processed h2k file  version (#{$gWorkingModelFile})")
      newXMLFile = File.open(filespec, "w")
      $XMLdoc.write(newXMLFile)

    rescue
      fatalerror("Could not overwrite #{filespec}\n ")
    ensure
      newXMLFile.close
    end



    begin
      log_out ("saving copy of the pre-h2k version (file-post-sub.h2k)")
      debug_out ("saving a copy of the pre-h2k version (file-post-sub.h2k)\n")
      newXMLFile = File.open("file-postsub.h2k", "w")
      $XMLdoc.write(:output=>newXMLFile, :ie_hack => TRUE)
      newXMLFile.close
    rescue
      warn_out ("Could not create debugging file - file-postsub.h2k")
    ensure
      newXMLFile.close
    end

  end 


  # =========================================================================================
  # Returns Year home was built
  # =========================================================================================
  def H2KFile.getYearBuilt(elements)

    myYearBuilt = elements["HouseFile/House/Specifications/YearBuilt"].attributes["value"].to_i
    #if myYearBuilt !=nil
    #  myBuilderName.gsub!(/\s*/, '')    # Removes mid-line white space
    # myBuilderName.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    # end

    return myYearBuilt
  end


  
  # =========================================================================================
  # Returns Year home was built
  # =========================================================================================
  def H2KFile.getEvalDate(elements)

    myEvalDate = elements["HouseFile/ProgramInformation/File"].attributes["evaluationDate"].to_s

    return myEvalDate
  end  

  def H2KFile.getLocation(elements)
    myLocation = elements["Housefile/ProgramInformation/Weather/Location"]
  end 
  # =========================================================================================
  # Returns Name of a builder
  # =========================================================================================
  def H2KFile.getBuilderName(elements)

    myBuilderName = elements["HouseFile/ProgramInformation/File/BuilderName"].text
    if myBuilderName !=nil
      myBuilderName.gsub!(/\s*/, '')    # Removes mid-line white space
      myBuilderName.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end

    return myBuilderName
  end

  # =========================================================================================
  # Returns Type of house
  # =========================================================================================

  def H2KFile.getHouseType(elements)

    myHouseType = elements["HouseFile/House/Specifications/HouseType/English"].text
    if myHouseType !=nil
      myHouseType.gsub!(/\s*/, '')    # Removes mid-line white space
      myHouseType.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end



    return myHouseType

  end

  # =========================================================================================
  # Returns type of building (how is this different from housetype?)
  # =========================================================================================

  def H2KFile.getBuildingType(elements)

    myBuildingType = elements["HouseFile/House/Specifications"].attributes["buildingType"]
    if myBuildingType !=nil
      myBuildingType.gsub!(/\s*/, '')    # Removes mid-line white space
      myBuildingType.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end



    return myBuildingType

  end

  def H2KFile.getStoreys(elements)

    myHouseStoreysInt = elements["HouseFile/House/Specifications/Storeys"].attributes["code"].to_i
    myHouseStoreysString = self.getNumStoreysString(myHouseStoreysInt)
    return myHouseStoreysString
  end

  # Small function that intreprets h2k story codes and returns readable strings
  def self.getNumStoreysString(iVal)
    sout = ''
    case iVal
      when 1 then sout = 'One'
      when 2 then sout = 'One and half'
      when 3 then sout = 'Two'
      when 4 then sout = 'Two and half'
      when 5 then sout = 'Three'
      when 6 then sout = 'Split level'
      when 7 then sout = 'Split entry'
      else sout = 'NA'
    end
    return sout
  end  

  def H2KFile.getFrontOrientation(elements)
    frontFacingH2KVal = { 1 => "S" , 2 => "SE", 3 => "E", 4 => "NE", 5 => "N", 6 => "NW", 7 => "W", 8 => "SW"}
    myHouseFrontOrientCode = elements["HouseFile/House/Specifications/FacingDirection"].attributes["code"].to_i
    myHouseFrontOrientString = frontFacingH2KVal[myHouseFrontOrientCode]

    return myHouseFrontOrientString
  end

  # AAAA


  # ======================================================================================
  # Get general geometry characteristics
  #
  # This is a common funciton that draws upon Rasoul's functions "GetHouseInfo",
  # getEnvelopeSpecs
  # ======================================================================================
  def H2KFile.getAllInfo(elements)
    debug_off
    myH2KHouseInfo = Hash.new

    # we don't know the filename - create a placeholder that can set elsewhere
    myH2KHouseInfo["h2kFile"] = "unknown"

    myH2KHouseInfo["house-description"]
    # Location/region
    myH2KHouseInfo["locale"] = Hash.new
    myH2KHouseInfo["locale"]["weatherLoc"] = H2KFile.getWeatherCity( elements )
    myH2KHouseInfo["locale"]["region"]     = H2KFile.getRegion( elements )
	  myH2KHouseInfo["locale"]["city"]     = H2KFile.getAddress( elements )

    myH2KHouseInfo["house-description"] = Hash.new
    myH2KHouseInfo["house-description"]["stories"] = H2KFile.getStoreys(elements)
    myH2KHouseInfo["house-description"]["buildingType"] = H2KFile.getBuildingType(elements)
    myH2KHouseInfo["house-description"]["type"] = H2KFile.getHouseType(elements)
	  myH2KHouseInfo["house-description"]["frontOrient"] = H2KFile.getFrontOrientation(elements)
    myH2KHouseInfo["house-description"]["MURBUnits"] = H2KFile.getMURBUnits(elements)

    # Dimensions
    myH2KHouseInfo["dimensions"] = Hash.new
    myH2KHouseInfo["dimensions"]["ceilings"] = Hash.new
    myH2KHouseInfo["dimensions"]["ceilings"]["area"] = Hash.new

    myH2KHouseInfo["dimensions"]["heatedFloorArea"] = H2KFile.getHeatedFloorArea( elements )

    myH2KHouseInfo["dimensions"]["ceilings"]["area"]["all"]       = H2KFile.getCeilingArea( elements, "all", "NA" )
    myH2KHouseInfo["dimensions"]["ceilings"]["area"]["flat"]      = H2KFile.getCeilingArea( elements, "flat", "NA" )
    myH2KHouseInfo["dimensions"]["ceilings"]["area"]["attic"]     = H2KFile.getCeilingArea( elements, "attic", "NA" )
    myH2KHouseInfo["dimensions"]["ceilings"]["area"]["cathedral"] = H2KFile.getCeilingArea( elements, "cathedral", "NA" )

    myH2KHouseInfo["dimensions"]["windows"] = Hash.new
    myH2KHouseInfo["dimensions"]["windows"]["area"] = Hash.new
    myH2KHouseInfo["dimensions"]["windows"]["area"] = H2KFile.getWindowArea( elements )

    myH2KHouseInfo["dimensions"]["walls"] = Hash.new
    myH2KHouseInfo["dimensions"]["walls"]["above-grade"] = Hash.new
    myH2KHouseInfo["dimensions"]["walls"]["above-grade"] = H2KFile.getAGWallDimensions( elements )
    myH2KHouseInfo["dimensions"]["headers"] =  H2KFile.getFlrHeaderDimensions( elements )
    myH2KHouseInfo["dimensions"]["exposed-floors"] = H2KFile.getExpFloorDimensions(elements)
    myH2KHouseInfo["dimensions"]["below-grade"] = H2KFile.getBGDimensions( elements )

    myH2KHouseInfo["HVAC"] = Hash.new
    myH2KHouseInfo["HVAC"]= H2KFile.getSystemInfo(elements)

    debug_out ("House info:\n#{myH2KHouseInfo.pretty_inspect}\n")



    return myH2KHouseInfo

  end




  # =========================================================================================
  # Get the average characteristics of building facade by orientation
  # Maybe this belongs in h2kutils? 
  # =========================================================================================
  def H2KFile.getEnvelopeSpecs(elements)

    # ====================================================================================
    # Parameter      Location
    # ====================================================================================
    # Orientation        HouseFile/House/Components/*/Components/Window/FacingDirection[code]
    # SHGC               HouseFile/House/Components/*/Components/Window[SHGC]
    # r-value            HouseFile/House/Components/*/Components/Window/Construction/Type/[rValue]
    # Height             HouseFile/House/Components/*/Components/Window/Measurements/[height]
    # Width              HouseFile/House/Components/*/Components/Window/Measurements/[width]


    env_info = {
      "windows" => {
        "average_SHGC"  => nil,
        "average_Uvalue" => nil, 
        "total_area" => nil,
        "by_orientation" => {
          "SHGC" => {},
          "Uvalue" => {},
          "area"   => {}
        }
      },
      "ag_walls"    => {
        "average_RSI" => nil,
        "total_area"  => nil
      },
      "ceilings" => {}
    }

    

    window_shgc_sum = Hash.new
    window_U_sum = Hash.new 
    window_area_sum = Hash.new 

    wall_RSI_sum = Hash.new 
    wall_area_sum = Hash.new 

    for i in 1..8
      window_shgc_sum[i] = 0
      window_U_sum[i]    = 0
      window_area_sum[i] = 0 
      env_info["windows"]["by_orientation"]["SHGC"][i] = nil
      env_info["windows"]["by_orientation"]["Uvalue"][i] = nil
      env_info["windows"]["by_orientation"]["area"][i] = 0
    end 



    locationText = "HouseFile/House/Components/*/Components/Window"


    elements.each(locationText) do |window|
      areaWin_temp = 0.0
      # store the area of each windows
      winOrient = window.elements["FacingDirection"].attributes["code"].to_i
  
      # Windows orientation:  "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8
      areaWin_temp = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f)*window.attributes["number"].to_i / 1000000
      # [Height (mm) * Width (mm)] * No of Windows
      window_shgc_sum[winOrient] += window.attributes["shgc"].to_f * areaWin_temp
      # Adds the (SHGC * area) of each windows to summation for individual orientations
      window_U_sum[winOrient]   += 1.0 / (window.elements["Construction"].elements["Type"].attributes["rValue"].to_f)
      # Adds the (area/RSI) of each windows to summation for individual orientations
      window_area_sum[winOrient] += areaWin_temp
      # Adds area of each windows to summation for individual orientations
    end

    locationText = "HouseFile/House/Components/*/Components/Door/Components/Window"
    # Adds door-window

    elements.each(locationText) do |window|
      areaWin_temp = 0.0
      # store the area of each windows
      winOrient = window.elements["FacingDirection"].attributes["code"].to_i
      # Windows orientation:  "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8
      areaWin_temp = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f)*window.attributes["number"].to_i / 1000000
      # [Height (mm) * Width (mm)] * No of Windows
      window_shgc_sum[winOrient] += window.attributes["shgc"].to_f * areaWin_temp
      # Adds the (SHGC * area) of each windows to summation for individual orientations
      window_U_sum[winOrient]   += 1.0 / (window.elements["Construction"].elements["Type"].attributes["rValue"].to_f)
      # Adds the (area/RSI) of each windows to summation for individual orientations
      window_area_sum[winOrient] += areaWin_temp
      # Adds area of each windows to summation for individual orientations
    end


    shgc_sum = 0 
    uvalue_sum = 0 
    area_sum = 0 

    (1..8).each do |winOrient|
      # Calculate the average weighted values for each orientation
      if window_area_sum[winOrient] != 0
        # No windows exist if the total area is zero for an orientation
        # $rValueWin[winOrient] = ($AreaWin_sum[winOrient] / $uAValueWin_sum[winOrient]).round(3)
        # Overall R-value is [A_tot/(U_tot*A_tot)]
        env_info["windows"]["by_orientation"]["SHGC"][winOrient] = (window_shgc_sum[winOrient] / window_area_sum[winOrient]).round(3)

        # Divide the summation of (area* SHGC) by total area
        env_info["windows"]["by_orientation"]["Uvalue"][winOrient] = ( window_U_sum[winOrient] / window_area_sum[winOrient]).round(3)
        # overall UA value is the summation of individual UA values
        env_info["windows"]["by_orientation"]["area"][winOrient] += window_area_sum[winOrient]
        # overall window area of the buildings

        shgc_sum   += window_shgc_sum[winOrient] 
        uvalue_sum += window_U_sum[winOrient]  
        area_sum   += window_area_sum[winOrient]
      end
    end
    env_info["windows"]["average_SHGC"]  = shgc_sum / area_sum
    env_info["windows"]["average_Uvalue"]= uvalue_sum / area_sum
    env_info["windows"]["total_area"]    = area_sum

    return env_info 


    ### Support for door sto be added.
    ##locationText = "HouseFile/House/Components/*/Components/Door"

    ##elements.each(locationText) do |door|
    ##  areaDoor_temp = 0.0
    ##  # store area of each Door
    ##  idDoor = door.attributes["id"].to_i
    ##  areaDoor_temp = (door.elements["Measurements"].attributes["height"].to_f * door.elements["Measurements"].attributes["width"].to_f)
    ##  # [Height (m) * Width (m)]

    ##  locationWindows = "HouseFile/House/Components/*/Components/Door/Components/Window"
    ##  areaWin_sum = 0.0
    ##  elements.each(locationWindows) do |openings|
    ##    if (openings.parent.parent.attributes["id"].to_i == idDoor)
    ##      areaWin_temp = (openings.elements["Measurements"].attributes["height"].to_f * openings.elements["Measurements"].attributes["width"].to_f)*openings.attributes["number"].to_i / 1000000
    ##      areaWin_sum += areaWin_temp
    ##    end
    ##  end

    ##  areaDoor_temp -= areaWin_sum

    ##  $UAValue["door"] += areaDoor_temp / (door.attributes["rValue"].to_f)
    ##  # Adds the (area/RSI) of each door to summation
    ##  $AreaComp["door"] += areaDoor_temp
    ##  # Adds area of each door to summation
    ##  $AreaComp["doorwin"] += areaWin_sum
    ##end

    #areaWall_sum = 0.0
    #
    #locationText = "HouseFile/House/Components/Wall"
    #elements.each(locationText) do |wall|
    #  areaWall_temp = 0.0
    #  idWall = wall.attributes["id"].to_i
    #  areaWall_temp = wall.elements["Measurements"].attributes["height"].to_f * wall.elements["Measurements"].attributes["perimeter"].to_f

    #  locationWindows = "HouseFile/House/Components/Wall/Components/Window"
    #  areaWin_sum = 0.0
    #  elements.each(locationWindows) do |openings|
    #    if (openings.parent.parent.attributes["id"].to_i == idWall)
    #      areaWin_temp = (openings.elements["Measurements"].attributes["height"].to_f * openings.elements["Measurements"].attributes["width"].to_f)*openings.attributes["number"].to_i / 1000000
    #      areaWin_sum += areaWin_temp
    #    end
    #  end

    #  locationDoors = "HouseFile/House/Components/Wall/Components/Door"
    #  areaDoor_sum = 0.0
    #  elements.each(locationDoors) do |openings|
    #    if (openings.parent.parent.attributes["id"].to_i == idWall)
    #      areaDoor_temp = (openings.elements["Measurements"].attributes["height"].to_f * openings.elements["Measurements"].attributes["width"].to_f)
    #      areaDoor_sum += areaDoor_temp
    #    end
    #  end

    #  locationDoors = "HouseFile/House/Components/Wall/Components/FloorHeader"
    #  areaHeader_sum = 0.0
    #  uAValueHeader = 0.0
    #  elements.each(locationDoors) do |head|
    #    if (head.parent.parent.attributes["id"].to_i == idWall)
    #      areaHeader_temp = (head.elements["Measurements"].attributes["height"].to_f * head.elements["Measurements"].attributes["perimeter"].to_f)
    #      uAValueHeader_temp = areaHeader_temp / head.elements["Construction"].elements["Type"].attributes["rValue"].to_f
    #      areaHeader_sum += areaHeader_temp
    #      uAValueHeader += uAValueHeader_temp
    #    end
    #  end

    #  areaWall_temp -= (areaWin_sum + areaDoor_sum)
    #  uAValueWall = areaWall_temp / wall.elements["Construction"].elements["Type"].attributes["rValue"].to_f
    #  $UAValue["wall"] += uAValueWall
    #  $AreaComp["wall"] += areaWall_temp
    #end

    #locationText = "HouseFile/House/Components/*/Components/FloorHeader"
    #elements.each(locationText) do |head|
    #  areaHeader_temp = 0.0
    #  areaHeader_temp = head.elements["Measurements"].attributes["height"].to_f * head.elements["Measurements"].attributes["perimeter"].to_f
    #  $UAValue["header"] += areaHeader_temp / head.elements["Construction"].elements["Type"].attributes["rValue"].to_f
    #  $AreaComp["header"] += areaHeader_temp
    #end

    #locationText = "HouseFile/House/Components/Ceiling"
    #elements.each(locationText) do |ceiling|
    #  areaCeiling_temp = 0.0
    #  areaCeiling_temp = ceiling.elements["Measurements"].attributes["area"].to_f
    #  $UAValue["ceiling"] += areaCeiling_temp / ceiling.elements["Construction"].elements["CeilingType"].attributes["rValue"].to_f
    #  $AreaComp["ceiling"] += areaCeiling_temp
    #end

    #locationText = "HouseFile/House/Components/Floor"
    #elements.each(locationText) do |floor|
    #  areaFloor_temp = 0.0
    #  areaFloor_temp = floor.elements["Measurements"].attributes["area"].to_f
    #  $UAValue["floor"] += areaFloor_temp / floor.elements["Construction"].elements["Type"].attributes["rValue"].to_f
    #  $AreaComp["floor"] += areaFloor_temp
    #end



  end
  # End of getEnvelopeSpecs

  # =========================================================================================
  # Return blower door test value 
  # =========================================================================================
  def H2KFile.getACHRate(elements)
    locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
    ach_result = elements[locationText].attributes["airChangeRate"].to_f
    return ach_result
  end 




  def H2KFile.getMURBUnits(elements)


    if (! elements["HouseFile/House/Specifications/NumberOf"].nil?)
      myMURBUnits = elements["HouseFile/House/Specifications/NumberOf"].attributes["dwellingUnits"].to_i
    end



    return myMURBUnits

  end



  def H2KFile.getHeatedFloorArea(elements)

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
    begin 
      if  ( elements["HouseFile/AllResults/Results/Other/GrossArea"].attributes["ceiling"]!= nil ) then
        ceilingAreaOut = elements["HouseFile/AllResults/Results/Other/GrossArea"].attributes["ceiling"].to_i
      else
        ceilingAreaOut = 0
      end
    rescue 
      ceilingAreaOut = 0 
    end 

    begin
      if  ( elements["HouseFile/AllResults/Results/Other/GrossArea"].attributes["slab"]!= nil ) then
        slabAreaOut = elements["HouseFile/AllResults/Results/Other/GrossArea"].attributes["slab"].to_f
      else
        slabAreaOut = 0
      end
    rescue
      slabAreaOut = 0
    end 

    begin 
      if  ( elements["HouseFile/AllResults/Results/Other/GrossArea/Basement"].attributes["floorSlab"] != nil ) then
        basementSlabAreaOut = elements["HouseFile/AllResults/Results/Other/GrossArea/Basement"].attributes["floorSlab"].to_f
      else
        basementSlabAreaOut  = 0
      end
    rescue 
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
    elsif (areaRatio > 0.50 && areaRatio < 2.0) || areaEstimateTotal == 0 then
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


  # ======================================================================================
  # Get wall characteristics (above-grade, headers....)
  # ======================================================================================
  def H2KFile.getAGWallDimensions(elements)

    #debug_off

    debug_out ("[>] H2KFile.getAGWallDimensions \n")
    wallDimsAG = Hash.new
    wallDimsAG["perimeter"] = 0.0
    wallDimsAG["count"] = 0
    wallDimsAG["area"] = Hash.new
    wallDimsAG["area"]["gross"]   = 0.0
    wallDimsAG["area"]["net"]     = 0.0
    wallDimsAG["area"]["headers"] = 0.0
    wallDimsAG["area"]["windows"] = 0.0
    wallDimsAG["area"]["doors"] = 0.0

    locationWallText = "HouseFile/House/Components/Wall"
    locationWindowText = "HouseFile/House/Components/Wall/Components/Window"
    locationDoorText = "HouseFile/House/Components/Wall/Components/Door"
    locationHeaderText = "HouseFile/House/Components/Wall/Components/FloorHeader"
    wallCounter = 0

    elements.each(locationWallText) do |wall|
      debug_out(drawRuler("Wall"," , "))
      debug_out("\n")
      areaWall_temp = wall.elements["Measurements"].attributes["height"].to_f * wall.elements["Measurements"].attributes["perimeter"].to_f

      # Id for this wall, to match to windows/doors
      idWall = wall.attributes["id"].to_i

      debug_out (" > #{idWall} AREA: #{areaWall_temp} \n")
      # Loop through windows, sum areas of windows attched to this wall.
      areaWindows = 0.0
      elements.each(locationWindowText) do |window|

        if (window.parent.parent.attributes["id"].to_i == idWall)

          thisWinArea  = ( window.elements["Measurements"].attributes["height"].to_f *   window.elements["Measurements"].attributes["width"].to_f ) * window.attributes["number"].to_i / 1000000

          areaWindows += thisWinArea
          debug_out "     WINDOW: parent id #{window.parent.parent.attributes["id"].to_i} - area: #{thisWinArea}\n"
        end
        # if (window.parent.parent.attributes["id"].to_i == idWall)
      end
      debug_out ("TOTAL window area so far #{areaWindows}\n")
      #   elements.each(locationWindowTest) do |window|

      # Loop through doors, sum areas of doors attched to this wall.
      areaDoors= 0.0
      elements.each(locationDoorText) do |door|


        if (door.parent.parent.attributes["id"].to_i == idWall)

          thisDoorArea  = ( door.elements["Measurements"].attributes["height"].to_f * door.elements["Measurements"].attributes["width"].to_f  )
          areaDoors += thisDoorArea

        end
        # if (door.parent.parent.attributes["id"].to_i == idWall)

      end
      debug_out ("TOTAL door area so far #{areaDoors}\n")
      #   elements.each(locationWindowTest) do |door|

      # Loop through floor headers.
      areaHeaders = 0
      elements.each(locationHeaderText) do |header|
        debug_out "Found header  #{header.attributes["id"].to_i} \n"
        if (header.parent.parent.attributes["id"].to_i == idWall)

          thisHeaderArea  = ( header.elements["Measurements"].attributes["height"].to_f *  header.elements["Measurements"].attributes["perimeter"].to_f  )
          areaHeaders += thisHeaderArea
          debug_out "     HEADER: parent id #{header.parent.parent.attributes["id"].to_i} - area: #{thisHeaderArea}\n"

        end
        # if (header.parent.parent.attributes["id"].to_i == idWall)

      end
      debug_out ("TOTAL header so far #{areaHeaders}\n")
      #   elements.each(locationHeaderText) do |header|

      # Permiter for linear foot calcs.
      wallDimsAG["perimeter"] += wall.elements["Measurements"].attributes["perimeter"].to_f

      # Gross wall area, including windows/doors
      wallDimsAG["area"]["gross"] += areaWall_temp + areaHeaders

      # Net wall area, excluding windows, doors.
      wallDimsAG["area"]["net"] += areaWall_temp - areaWindows - areaDoors
      wallDimsAG["area"]["headers"] += areaHeaders
      wallDimsAG["area"]["windows"] += areaWindows
      wallDimsAG["area"]["doors"]   += areaDoors
      wallDimsAG["count"] += 1.to_i

    end
    # elements.each(locationWallText) do |wall|

    debug_out ("Output follows:\n#{wallDimsAG.pretty_inspect}\n")

    debug_out ("[<] H2KFile.getAGWallDimensions \n")
    return wallDimsAG

  end

  def H2KFile.getExpFloorDimensions(elements)
    #debug_on
    locationText = "HouseFile/House/Components/Floor"
    areaFloors = 0
    elements.each(locationText) do |floor|

      thisFloorArea  = ( floor.elements["Measurements"].attributes["area"].to_f   )
      areaFloors += thisFloorArea

    end

    floorDims = {
      "area" => {
        "total" => areaFloors
      }
    }

    return floorDims

  end


  def H2KFile.getFlrHeaderDimensions(elements)
    #debug_on
    locationText = "HouseFile/House/Components/*/Components/FloorHeader"
    areaHeaders = 0
    areaHeadersAG = 0
    areaHeadersBG = 0
    elements.each(locationText) do |header|

      thisHeaderArea  = ( header.elements["Measurements"].attributes["height"].to_f *  header.elements["Measurements"].attributes["perimeter"].to_f  )
      areaHeaders += thisHeaderArea
      parent = header.parent.parent.name

      areaHeadersAG += thisHeaderArea if ( parent =~ /wall/i )
      areaHeadersBG += thisHeaderArea if ( parent =~ /basement/i || parent =~ /crawlspace/i)


    end

    headerDims = {
      "area" => {
        "total" => areaHeaders,
        "above-grade" => areaHeadersAG,
        "below-grade" => areaHeadersBG
      }
    }

    return headerDims

  end


  def H2KFile.getBGDimensions(elements)

    #debug_off
    bgDims = Hash.new
    [ "basement", "crawlspace", "slab" ].each do | type |
      bgDims[type] = Hash.new
      bgDims[type] = {
        "exposed-perimeter" => 0.0,
        "total-perimeter" => 0.0,
        "floor-area" => 0.0,
        "configuration" => nil
      }
    end

    wallCornerCount = 0
    wallDims = Array.new

    bgDims["walls"] = { "total-area" => Hash.new, "below-grade-area" =>Hash.new }
    bgDims["walls"]["total-area"]["internal"] = 0.0
    bgDims["walls"]["total-area"]["external"] = 0.0
    bgDims["walls"]["below-grade-area"]["internal"] = 0.0
    bgDims["walls"]["below-grade-area"]["external"] = 0.0


    #debug_on()
    debug_out ("Parsing below-grade dimensions\n")

    loc = "HouseFile/House/Components"
    count = 0
    elements[loc].elements.each do | component |
      debug_out drawRuler("> component #{component.name}?\n", " + ")

      next if ( component.name == "Crawlspace" && component.attributes["heated"] !~ /true/ )
      next if (
        component.name != "Basement" &&
        component.name != "Crawlspace" &&
        component.name != "Slab"
      )


      count += 1
      debug_out(drawRuler(nil, "  *"))
      debug_out " Processing #{component.name} #{count} /#{component.pretty_inspect} \n"
      thisExposedPerimeter = component.attributes["exposedSurfacePerimeter"].to_f

      thisIsRectangle = component.elements[".//Floor/Measurements"].attributes["isRectangular"].to_s

      if ( thisIsRectangle.eql?("true") )
        debug_out (" + SHAPE #{thisIsRectangle}\n")
        thisWidth = component.elements[".//Floor/Measurements"].attributes["width"].to_f
        thisLength = component.elements[".//Floor/Measurements"].attributes["length"].to_f
        thisFloorArea = thisWidth * thisLength
        thisTotalPerimeter = (thisWidth + thisLength) *2
      else
        debug_out ("non-rectangular!!!\n")
        thisFloorArea = component.elements[".//Floor/Measurements"].attributes["area"].to_f
        thisTotalPerimeter = component.elements[".//Floor/Measurements"].attributes["perimeter"].to_f
      end
      debug_out " >>>>> floor area? : #{thisFloorArea}\n"
      if (component.name == "Basement" || component.name == "Crawlspace") then

        thisHeight = component.elements[".//Wall/Measurements"].attributes["height"].to_f
        thisDepth = component.elements[".//Wall/Measurements"].attributes["depth"].to_f
        thisCorners = component.elements[".//Wall/Construction"].attributes["corners"].to_f
        thisTotalExposedWallArea = thisHeight * thisExposedPerimeter
        thisTotalExposedWallAreaBG = thisDepth * thisExposedPerimeter


        # Total corners
        wallCornerCount += thisCorners

        wallDims.push( {
          "type"       => component.name,
          "corners"    => thisCorners,
          "thisHeight" => thisHeight,
          "thisDepth"  => thisDepth,
          "thisExpPerimeter" => thisExposedPerimeter }
        )


      end

      if ( bgDims[component.name.downcase]["configuration"].nil? )
        bgDims[component.name.downcase]["configuration"] = component.elements[".//Configuration"].text
      else (bgDims[component.name.downcase]["configuration"] !=  component.elements[".//Configuration"].text )
        #warn_out(" HTAP doesn't support foundations with mutilple configurations for #{component.name}\n")
      end


      bgDims[component.name.downcase]["exposed-perimeter"] += thisExposedPerimeter
      bgDims[component.name.downcase]["total-perimeter"] += thisTotalPerimeter
      bgDims[component.name.downcase]["floor-area"] += thisFloorArea


    end


    # Estimate number of internal corners

    cornersExt = [4, (4+(wallCornerCount-4)/2).round(0)].max
    cornersInt = [wallCornerCount-cornersExt,0].max




    debug_out ("Estimate- exterior corners - #{cornersExt} \n")
    debug_out ("Estimate- interior corners - #{cornersInt} \n")


    wallExtTotal = 0.0
    wallExtBG    = 0.0
    wallIntTOtal = 0.0
    wallIntBG    = 0.0
    
    debug_out("wallCornerCount: #{wallCornerCount}\n")
    wallDims.each do |wall|

      #how many corners belong to this wall?
      #fracOfCorners = wall["corners"]/wallCornerCount
      if ( wallCornerCount < 1 )

        fracOfCorners = 0 
        wallCornerCount = 1 
      
      else 
        fracOfCorners = wall["corners"]/wallCornerCount
      end 
	  
      # assume 8" wall
      fdnWallWidth = 8.0 * 2.54 / 100.0
      # exposed perimiter,
      bgDims["walls"]["total-area"]["internal"] += wall["thisHeight"] * ( wall["thisExpPerimeter"] )
      bgDims["walls"]["total-area"]["external"] += wall["thisHeight"] * ( wall["thisExpPerimeter"] + fracOfCorners * ( cornersExt - cornersInt ) * fdnWallWidth * 2.0 )
      bgDims["walls"]["below-grade-area"]["internal"] += wall["thisDepth"] * ( wall["thisExpPerimeter"]  )
      bgDims["walls"]["below-grade-area"]["external"] += wall["thisDepth"] * ( wall["thisExpPerimeter"] + fracOfCorners * ( cornersExt - cornersInt ) * fdnWallWidth * 2.0 )

    end

    #debug_out ("Below-grade dimensions:\n#{bgDims.pretty_inspect}\n")

    return bgDims

  end 


  # ======================================================================================
  # Get window dimensions
  # ======================================================================================
  def H2KFile.getWindowArea(elements)

    windowArea = Hash.new
    windowArea["total"] = 0
    windowArea["byOrientation"] = Hash.new
    windowArea["byOrientation"] = {1=>0,
      2=>0,
      3=>0,
      4=>0,
      5=>0,
      6=>0,
      7=>0,
      8=>0
    }


    locationText = "HouseFile/House/Components/*/Components/Window"
    elements.each(locationText) do |window|

      # Windows orientation:  "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8
      thisWindowOrient = window.elements["FacingDirection"].attributes["code"].to_i
      thisWindowArea   = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f)*window.attributes["number"].to_i / 1000000 # [Height (mm) * Width (mm)] * No of Windows

      windowArea["total"] += thisWindowArea
      windowArea["byOrientation"][thisWindowOrient] += thisWindowArea
      debug_out "> window - #{thisWindowArea.to_s.ljust(30)} m2\n"
    end
    debug_out " TOTAL WINDOW AREA: #{windowArea["total"].to_s.ljust(30)} m2 (#{windowArea["total"]*3.28*3.28} ft2)\n"
    return windowArea

  end # function getWindowArea



  # ========================================================================================
  # Function to return ceiling area:
  #
  # Get the total ceiling area, in square meters, for the type specified and ceiling code name
  # from the passed elements. The ceiling type is one of:
  #   All = All ceilings regardless of type
  #   Attics = Ceilings of type Attic/Gable (2), Attic/Hip (3) or Scissor (6)
  #   Flat = Ceilings of type Flat (5)
  #   Cathedral = Ceilings of type Cathedral (4)
  # The ceiling code name is "NA" for user specified code options
  # =========================================================================================
  def H2KFile.getCeilingArea( elements, ceilingType, ceilingCodeName )
    area = 0.0
    locationText = "HouseFile/House/Components/Ceiling"
    elements.each(locationText) do |element|
      if ceilingType =~ /attic/i
        # Check if construction type (element 3) is Attic/gable (2), Attic/hip (3) or Scissor (6)
        if element[3][1].attributes["code"] == "2" || element[3][1].attributes["code"] == "3" || element[3][1].attributes["code"] == "6"
          if ceilingCodeName == "NA"
            area += element[5].attributes["area"].to_f
          else
            if element[3][3].text == ceilingCodeName
              area += element[5].attributes["area"].to_f
            end
          end
        end
      elsif ceilingType =~ /flat/i
        # Check if construction type (element 3) is Flat (5)
        if element[3][1].attributes["code"] == "5"
          if ceilingCodeName == "NA"
            area += element[5].attributes["area"].to_f
          else
            if element[3][3].text == ceilingCodeName
              area += element[5].attributes["area"].to_f
            end
          end
        end
      elsif ceilingType =~ /cathedral/i
        # Check if construction type (element 3) is Cathedral (4)
        if element[3][1].attributes["code"] == "4"
          if ceilingCodeName == "NA"
            area += element[5].attributes["area"].to_f
          else
            if element[3][3].text == ceilingCodeName
              area += element[5].attributes["area"].to_f
            end
          end
        end
      elsif ceilingType =~ /all/i
        if ceilingCodeName == "NA"
          area += element[5].attributes["area"].to_f
        else
          if element[3][3].text == ceilingCodeName
            area += element[5].attributes["area"].to_f
          end
        end
      end
    end
    return area
  end  # function get Ceiling area.


  def H2KFile.getHouseVolume(elements)

    myHouseVolume= elements["HouseFile/House/NaturalAirInfiltration/Specifications/House"].attributes["volume"].to_f

    return myHouseVolume

  end


  # ==========================================================================================
  # Parses results section and returns peak heating/cooling loads. Need to think about whether
  # we need to spec the result section ...
  # ==========================================================================================
  def H2KFile.getDesignLoads( elements )

    designHeatingLoad = 0
    designCoolingLoad = 0
    elements["HouseFile/AllResults"].elements.each do |element|

      houseCode =  element.attributes["houseCode"]

      if (houseCode == nil && element.attributes["sha256"] != nil)
        houseCode = "General"
      end

      designHeatingLoad = element.elements[".//Other"].attributes["designHeatLossRate"].to_f
      designCoolingLoad = element.elements[".//Other"].attributes["designCoolLossRate"].to_f
    end

    loads = Hash.new
    loads = { "heating_W" => designHeatingLoad.to_f,
      "cooling_W" => designCoolingLoad.to_f }

      return loads

  end



  # ==========================================================================================
  # Parses systems section and returns capacity.
  # ==========================================================================================
  def H2KFile.getSystemInfo( elements )
    debug_off
    systemInfo = Hash.new
    systemInfo = { 
      "fansAndPump"   => { "count" => 0.0 },
      "Furnace"       => { "count" => 0.0, "capacity_kW" => 0.0, },
      "Boiler"        => { "count" => 0.0, "capacity_kW" => 0.0, },
      "Baseboards"    => { "count" => 0.0, "capacity_kW" => 0.0, },
      "ASHP"          => { "count" => 0.0, "capacity_kW" => 0.0, },
      "GSHP"          => { "count" => 0.0, "capacity_kW" => 0.0, },
      "AirConditioner"=> { "count" => 0.0, "capacity_kW" => 0.0, },
      "Ventilator"    => { "count" => 0.0, "capacity_l/s" => 0.0 }
    }

    elements["HouseFile/House/HeatingCooling/Type1/"].elements.each do |t1_system|

      debug_out "Recovering system info for T1 : #{t1_system.name}\n"
      case t1_system.name
      when "FansAndPump"
        systemInfo["fansAndPump"]["count"] += 1
        systemInfo["fansAndPump"]["powerLowW"] = t1_system.elements[".//Power/"].attributes["low"].to_f
        systemInfo["fansAndPump"]["powerHighW"] = t1_system.elements[".//Power/"].attributes["high"].to_f
      when "Baseboards"
        systemInfo["Baseboards"]["count"] += 1
        systemInfo["Baseboards"]["capacity_kW"] = t1_system.elements[".//Specifications/OutputCapacity"].attributes["value"].to_f
      when "Furnace"
        systemInfo["Furnace"]["count"] += 1
        systemInfo["Furnace"]["capacity_kW"] = t1_system.elements[".//Specifications/OutputCapacity"].attributes["value"].to_f
        systemInfo[""]
      else
        warn_out "Unknown system type #{t1_system.name}\n"
      end

    end
    #
    elements["HouseFile/House/HeatingCooling/Type2/"].elements.each do |t2_system|

      debug_out "Recovering system info for T2: #{t2_system.name}\n"
      case t2_system.name
      when "GroundHeatPump"
        systemInfo["GSHP"]["count"] += 1
        systemInfo["GSHP"]["capacity_kW"] = t2_system.elements[".//Specifications/OutputCapacity"].attributes["value"].to_f
      when "AirHeatPump"
        systemInfo["ASHP"]["count"] += 1
        systemInfo["ASHP"]["capacity_kW"] = t2_system.elements[".//Specifications/OutputCapacity"].attributes["value"].to_f
      when "AirConditioning"
        systemInfo["AirConditioner"]["count"] += 1
        systemInfo["AirConditioner"]["capacity_kW"] = t2_system.elements[".//Specifications/RatedCapacity"].attributes["value"].to_f
      else
        warn_out "Unknown system type #{t2_system.name}  \n"
      end

    end

    elements["HouseFile/House/Ventilation/WholeHouseVentilatorList"].elements.each do | ventsys |


      debug_out "Recoveirng system info for vent #{ventsys.name}\n"
      case ventsys.name
      when "Hrv"
        systemInfo["Ventilator"]["count"] += 1
        systemInfo["Ventilator"]["capacity_l/s"] += ventsys.attributes["supplyFlowrate"].to_f
      else
        warn_out "Unknown whole house ventilation type #{ventsys.name}\n"
      end
    end
    systemInfo["designLoads"] = H2KFile.getDesignLoads( elements )

    return systemInfo

  end



  # =========================================================================================
  # Get the name of the base file address city
  # =========================================================================================
  def H2KFile.getAddress(elements)

    myCityAddress = elements["HouseFile/ProgramInformation/Client/StreetAddress/City"].text
	 
	 if myCityAddress != nil
		myCityAddress.gsub!(/\s*/, '')
	 end

    return myCityAddress

  end



  # =========================================================================================
  # Get the name of the base file weather city
  # =========================================================================================
  def H2KFile.getRegion(elements)

    myRegionCode = elements["HouseFile/ProgramInformation/Weather/Region"].attributes["code"].to_i

    myRegionName = $ProvArr[myRegionCode-1]

    return myRegionName

  end
  


  # =========================================================================================
  # Get the name of the base file weather city
  # =========================================================================================
  def H2KFile.getWeatherCity(elements)
    myWth_cityName = elements["HouseFile/ProgramInformation/Weather/Location/English"].text
    myWth_cityName.gsub!(/\s*/, '')    # Removes mid-line white space

    return myWth_cityName
  end

  # =========================================================================================
  # Get program name
  # =========================================================================================

  def H2KFile.getProgramName(elements)
    if( elements["HouseFile/Program"] == nil ) then 
      return "General"
    else 
      loc = "HouseFile/Program"
      name = elements[loc].attributes["class"].to_s 

      case (name)
      when "ca.nrcan.gc.OEE.ERS2020NBC.ErsProgram"
        return "NBC"
      when "ca.nrcan.gc.OEE.ERS.ErsProgram"
        return "ERS"
      when "ca.nrcan.gc.OEE.ONrh.OnProgram"
        return "ON"
      else 
        warn_out("unknown program #{name}")
        return name 
      end 
    end 
  
  end 

end 

# =========================================================================================
# Functions that manipulate the content of an H2k File
# =========================================================================================

module H2KEdit
  #.....................................................
  def H2KEdit.modify_contents(h2k_contents,options,choices)
    #debug_on 
    # Parse code library
    code_lib_name = "codelib.cod"
    code_lib_file =  "#{$gMasterPath}\\H2K\\StdLibs\\#{code_lib_name}"
    
    if ( !File.exist?(code_lib_file) )
      fatalerror("Code library file #{code_lib_name } not found in #{$gMasterPath}\\H2K\\StdLibs\\!")
    else
      h2k_codes = H2KFile.open_xml_as_elements(code_lib_file)
    end
  

    warn_out ("Need to add ruleset support, SOC/General codes")
    choices.each do | attribute, choice |
      
      debug_out(" processing: #{attribute} = #{choice}")
      
      
      next if (attribute =~ /Opt-Ruleset/ ) 

      # Legacy options
      next if (attribute =~ /GOconfig_rotate/)
      next if (attribute =~ /Opt-Archetype/)
      next if (attribute =~ /Opt-DBFiles/)
      next if (attribute =~ /Opt-Archetype/ )
      

      if (options[attribute]["structure"] == "flat" )
        map = nil
      else 
        begin
          map = options[attribute]["options"][choice]["h2kMap"]["base"]
        rescue 
          err_out("Attribute #{attribute} = #{choice} not found in options / H2Kmap / base")
        end 
      end 
      # Extra error handling needed? 

      case attribute

      when "Opt-Program"
        debug_on 
        debug_out("Setting  program... / #{map.pretty_inspect} / #{choice}")
        H2KEdit.set_program(h2k_contents,map,choice)

      when "Opt-Location"
      
        
        
        H2KEdit.set_location(h2k_contents,map,choice)

      when "Opt-ACH"

        H2KEdit.set_ach(h2k_contents,map,choice)


      when "Opt-VentSystem"

        H2KEdit.set_ventsystem(h2k_contents,map,choice)

      
      when "Opt-Windows"

        H2KEdit.set_windows(h2k_contents,h2k_codes,map,choice)

      else
        if (choice == "NA" )
          info_out "Unsupported attribute #{attribute}, Choice = #{choice} "
        else 
          warn_out "Unsupported attribute #{attribute}, Choice = #{choice} "
        end 
      end 

    end 



  end 



  #.....................................................
  def H2KEdit.set_location(h2k_contents,map,choice)
    debug_off 
    debug_out("Setting Location to : #{choice} ")
    #debug_out("Spec: #{map.pretty_inspect}")
    if ( choice == "NA" ) then 
      debug_out ("NA choice specified; leaving location alone")
      return 
    end 

    weather_file = map["OPT-H2K-WTH-FILE"]
    region = map["OPT-H2K-Region"]
    location = map["OPT-H2K-Location"]
    region_name = map["region_name"]


    warn_out("Don't forget to fix depth of frost:")
    # set_permafrost_by_location(h2k_contents,$Locale)


    debug_out(" READ: #{weather_file} #{region} #{location} #{region_name}")

    locationText = "HouseFile/ProgramInformation/Weather"
    h2k_contents[locationText].attributes["library"] = weather_file

    locationText = "HouseFile/ProgramInformation/Weather/Region"
    h2k_contents[locationText].attributes["code"] = region

    locationText = "HouseFile/ProgramInformation/Weather/Region/English"
    h2k_contents[locationText].text = region_name

    locationText = "HouseFile/ProgramInformation/Weather/Region/French"
    h2k_contents[locationText].text = region_name

    locationText = "HouseFile/ProgramInformation/Client/StreetAddress/Province"
    h2k_contents[locationText].text = region_name
    
    locationText = "HouseFile/ProgramInformation/Weather/Location"
    h2k_contents[locationText].attributes["code"] = location    

    locationText = "HouseFile/ProgramInformation/Weather/Location/English"
    h2k_contents[locationText].text = choice

    locationText = "HouseFile/ProgramInformation/Weather/Location/French"
    h2k_contents[locationText].text = choice



    # Check on existence of H2K weather file
    #if ( !File.exist?($run_path + "\\Dat" + "\\" + value) )
    #  fatalerror("Weather file #{value} not found in Dat folder !")
    #else

    #end    



  end 
  #.....................................................
  def H2KEdit.set_ach(h2k_contents,map,choice)

    #debug_on 
    debug_out("Setting ACH to : #{choice} ")
    debug_out("Spec: #{map.pretty_inspect}")

    return if ( choice == "NA" )

    ach = map["<Opt-ACH>"]
    site = map["Opt-BuildingSite"]
    wall_shield = map["Opt-WallShield"]
    flue_shield = map["Opt-FlueShield"]

    if ( ach != "NA" ) then 

      locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/House/AirTightnessTest"
      h2k_contents[locationText].attributes["code"] = "x"
    
      # Need to set the House/AirTightnessTest code attribute to "Blower door test values" (x)
      locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/House/AirTightnessTest"
      h2k_contents[locationText].attributes["code"] = "x"

      # Must also remove "Air Leakage Test Data" section, if present, since it will over-ride user-specified ACH value
      locationText = "HouseFile/House/NaturalAirInfiltration/AirLeakageTestData"
      if (  h2k_contents[locationText] != nil )
        # Need to remove this section!
        locationText = "HouseFile/House/NaturalAirInfiltration"
        h2k_contents[locationText].delete_element("AirLeakageTestData")
        # Change CGSB attribute to true (was set to "As Operated" by AirLeakageTestData section
        locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
        h2k_contents[locationText].attributes["isCgsbTest"] = "true"
      end
      # Set the blower door test value in airChangeRate field
      locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
      h2k_contents[locationText].attributes["airChangeRate"] = ach
  
      h2k_contents[locationText].attributes["isCgsbTest"] = "true"
      h2k_contents[locationText].attributes["isCalculated"] = "true"      


    end 


    if ( site != "NA" ) then 
      if(site.to_f < 1 || site.to_f > 8)
        fatalerror("In Opt-ACH = #{choice}, invalid building site input #{site}")
      end
      locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BuildingSite/Terrain"
      h2k_contents[locationText].attributes["code"] = site
    end 

    if ( wall_shield != "NA" ) then 
      if(wall_shield.to_f < 1 || wall_shield.to_f > 5)
        fatalerror("In Opt-ACH = #{choice}, invalid wall shield input #{wall_shield}")
      end
      locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/LocalShielding/Walls"
      h2k_contents[locationText].attributes["code"] = wall_shield
    end 

    if ( flue_shield != "NA" ) then 
      if(flue_shield.to_f < 1 || flue_shield.to_f > 5)
        fatalerror("In Opt-ACH = #{choice}, invalid flue shield input #{wall_shield}")
      end
      locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/LocalShielding/Flue"
      h2k_contents[locationText].attributes["code"] = flue_shield
    end 

  end 
  #.....................................................
  def H2KEdit.set_ventsystem(h2k_contents,map,choice)

    #debug_on 
    debug_out ("Setting ventilation system to #{choice}")
    debug_out ("Spec: #{map.pretty_inspect}")

    return if ( choice == "NA" )

    # Delete existing ventilation list.
    locationText = "HouseFile/House/Ventilation/"
    h2k_contents[locationText].delete_element("WholeHouseVentilatorList")        


    # What does this do?
    #if ( $outputHCode =~ /General/ )
    #  h2k_contents[locationText].add_element("SupplementalVentilatorList")
    #  h2k_contents[locationText].delete_element("SupplementalVentilatorList")
    #end 


    # Make fresh element
    h2k_contents[locationText].add_element("WholeHouseVentilatorList")    


    # Create HRV from template. 
    H2KTemplates.hrv(h2k_contents)

    # Set the ventilation code requirement to 4 (Not applicable)
    h2k_contents[locationText + "Requirements/Use"].attributes["code"] = "4"

    # Set the air distribution type
    h2k_contents[locationText + "WholeHouse/AirDistributionType"].attributes["code"] = map["OPT-H2K-AirDistType"]

    # Set the operation schedule
    h2k_contents[locationText + "WholeHouse/OperationSchedule"].attributes["code"] = 0
    # User Specified
    h2k_contents[locationText + "WholeHouse/OperationSchedule"].attributes["value"] = map["OPT-H2K-OpSched"]


    flow_rate = 0 
    case map["OPT-FlowCalc"].to_i
    when 2
      begin 
      flow_rate = map["OPT-H2K-HRVSupply"].to_f
      rescue
        err_out ("Could not intrepret HRV flow rate as number. Did you mean to set `Opt-FlowCalc = 1` ?")
      end 
    when 1
      flow_rate = H2KMisc.getF326FlowRates(h2k_contents)
    else 
      err_out("ERROR: For Opt-VentSystem, invalid flow calculation input #{map["OPT-FlowCalc"]}")
    end 

    # L/s supply, exhaust
    h2k_contents[locationText + "WholeHouseVentilatorList/Hrv"].attributes["supplyFlowrate"] = flow_rate.to_s

    h2k_contents[locationText + "WholeHouseVentilatorList/Hrv"].attributes["exhaustFlowrate"] = flow_rate.to_s




    # Update the HRV efficiency
    h2k_contents[locationText  + "WholeHouseVentilatorList/Hrv"].attributes["efficiency1"] = map["OPT-H2K-Rating1"]
    # Rating 1 Efficiency
    h2k_contents[locationText  + "WholeHouseVentilatorList/Hrv"].attributes["efficiency2"] = map["OPT-H2K-Rating2"]
    # Rating 2 Efficiency
    h2k_contents[locationText  + "WholeHouseVentilatorList/Hrv"].attributes["coolingEfficiency"] = map["OPT-H2K-Rating3"]
    # Rating 3 Efficiency


    # Fan power calculation
    case map["OPT-H2K-FanPowerCalc"]

    when "NBC"
      # Determine fan power from flow rate as stated in 9.36.5.11(14a)
      fan_power = flow_rate * 2.32
      fan_power = sprintf("%0.2f", flow_rate )
      h2k_contents[locationText + "WholeHouseVentilatorList/Hrv"].attributes["fanPower1"] =  fan_power
      # Supply the fan power at operating point 1 [W]
      h2k_contents[locationText + "WholeHouseVentilatorList/Hrv"].attributes["fanPower2"] =  fan_power
      # Supply the fan power at operating point 2 [W]
    when "specified"
      h2k_contents[locationText + "WholeHouseVentilatorList/Hrv"].attributes["isDefaultFanpower"] = "false"
      # Specify the fan power
      h2k_contents[locationText + "WholeHouseVentilatorList/Hrv"].attributes["fanPower1"] =  map["OPT-H2K-FanPower1"]
      # Supply the fan power at operating point 1 [W]
      h2k_contents[locationText + "WholeHouseVentilatorList/Hrv"].attributes["fanPower2"] =  map["OPT-H2K-FanPower2"]
      # Supply the fan power at operating point 2 [W]

    when "default"
      h2k_contents[locationText + "WholeHouseVentilatorList/Hrv"].attributes["isDefaultFanpower"] = "true"
    else 
      err_out("ERROR: For Opt-VentSystem, unknown fan power calculation input  #{map["OPT-H2K-FanPowerCalc"]}!")
    end 



  end 
  #.....................................................
  def H2KEdit.set_windows(h2k_contents,h2k_codes,map,choice)

    #debug_on 
    debug_out ("Setting windows to #{choice}")
    debug_out ("Spec: #{map.pretty_inspect}")

    return if ( choice == "NA" )


    map.keys.each do | key, value |

      orientation = key.gsub(/\<Opt-win-/,"").gsub(/-CON\>/,"")
      debug_out ("Orientation: #{orientation}")

      H2KEdit.set_windows_by_orientation(h2k_contents,h2k_codes,orientation,choice)
        
        
    end 
    warn_out("Development stopped here")
    #debug_pause
  end  

  def H2KEdit.set_resultcode(h2k_contents,map,choice)
    warn_out("This function doesn't do anything!!!")
  end 
  
  #.................................................. 
  def H2KEdit.set_program(h2k_contents,map,choice)
    #debug_on 

    debug_out(" setting program to #{choice}")

    return if (choice == "NA")

    if (h2k_contents["HouseFile/Program"] != nil) 
      debug_out ("Deleting existing program section")
      h2k_contents["HouseFile"].delete_element("Program")
    end 
    
    
    if ( choice == "General" )
      debug_out(" Nothing more needed for general, returning ")
      return 
    end 
      
    debug_out(" adding program section")
    loc = "HouseFile"
    h2k_contents[loc].add_element("AllResults")
    h2k_contents[loc].add_element("Program")

    loc = "HouseFile/Program" 
    h2k_contents[loc].add_element("Labels")
    
    loc = "HouseFile/Program/Labels"
    h2k_contents[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
    h2k_contents[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
    h2k_contents[loc].add_element("English")
    loc = "HouseFile/Program/Labels/English"
    h2k_contents[loc].add_text("EnerGuide Rating System")
    loc = "HouseFile/Program/Labels"
    h2k_contents[loc].add_element("French")
    loc = "HouseFile/Program/Labels/French"
    h2k_contents[loc].add_text("Système de cote ÉnerGuide")

    loc = "HouseFile/Program"
    h2k_contents[loc].add_element("Version")
    loc = "HouseFile/Program/Version"
    h2k_contents[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
    h2k_contents[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
    h2k_contents[loc].attributes["major"] = "15"
    h2k_contents[loc].attributes["minor"] = "6"
    h2k_contents[loc].attributes["build"] = "18345"
    h2k_contents[loc].add_element("Labels")
    loc = "HouseFile/Program/Version/Labels"
    h2k_contents[loc].add_element("English")
    loc = "HouseFile/Program/Version/Labels/English"
    h2k_contents[loc].add_text("v15.6b18345")
    loc = "HouseFile/Program/Version/Labels"
    h2k_contents[loc].add_element("French")
    loc = "HouseFile/Program/Version/Labels/French"
    h2k_contents[loc].add_text("v15.6b18345")

    loc = "HouseFile/Program"
    h2k_contents[loc].add_element("SdkVersion")
    loc = "HouseFile/Program/SdkVersion"
    h2k_contents[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
    h2k_contents[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
    h2k_contents[loc].attributes["major"] = "1"
    h2k_contents[loc].attributes["minor"] = "16"
    h2k_contents[loc].attributes["build"] = "18345"
    h2k_contents[loc].add_element("Labels")
    loc = "HouseFile/Program/SdkVersion/Labels"
    h2k_contents[loc].add_element("English")
    loc = "HouseFile/Program/SdkVersion/Labels/English"
    h2k_contents[loc].add_text("v1.16b18345")
    loc = "HouseFile/Program/SdkVersion/Labels"
    h2k_contents[loc].add_element("French")
    loc = "HouseFile/Program/SdkVersion/Labels/French"
    h2k_contents[loc].add_text("v1.16b18345")

    loc = "HouseFile/Program"
    h2k_contents[loc].add_element("Options")
    loc = "HouseFile/Program/Options"
    h2k_contents[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
    h2k_contents[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
    h2k_contents[loc].add_element("Main")
    loc = "HouseFile/Program/Options/Main"
    h2k_contents[loc].attributes["applyHouseholdOperatingConditions"] = "false"
    h2k_contents[loc].attributes["applyReducedOperatingConditions"] = "false"
    h2k_contents[loc].attributes["atypicalElectricalLoads"] = "false"
    h2k_contents[loc].attributes["waterConservation"] = "false"
    h2k_contents[loc].attributes["referenceHouse"] = "false"
    h2k_contents[loc].add_element("Vermiculite")
    loc = "HouseFile/Program/Options/Main/Vermiculite"
    h2k_contents[loc].attributes["code"] = "1"
    h2k_contents[loc].add_element("English")
    loc = "HouseFile/Program/Options/Main/Vermiculite/English"
    h2k_contents[loc].add_text("Unknown")
    loc = "HouseFile/Program/Options/Main/Vermiculite"
    h2k_contents[loc].add_element("French")
    loc = "HouseFile/Program/Options/Main/Vermiculite/French"
    h2k_contents[loc].add_text("Inconnu")
    loc = "HouseFile/Program/Options"
    h2k_contents[loc].add_element("RURComments")
    loc = "HouseFile/Program/Options/RURComments"
    h2k_contents[loc].attributes["xml:space"] = "preserve"

    loc = "HouseFile/Program"
    h2k_contents[loc].add_element("Results")
    loc = "HouseFile/Program/Results"
    h2k_contents[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
    h2k_contents[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
    h2k_contents[loc].add_element("Tsv")
    h2k_contents[loc].add_element("Ers")
    h2k_contents[loc].add_element("RefHse")


    debug_out(" Setting program specific attributes")
    case (choice)
    
    when "ERS"
      loc = "HouseFile/Program" 
      h2k_contents[loc].attributes["class"] = "ca.nrcan.gc.OEE.ERS.ErsProgram"
      loc = "HouseFile/Program/Labels/English"
      h2k_contents[loc].add_text("EnerGuide Rating System")
      loc = "HouseFile/Program/Labels/French"
      h2k_contents[loc].add_text("Système de cote ÉnerGuide")
    when "NBC"
      loc = "HouseFile/Program" 
      h2k_contents[loc].attributes["class"] = "ca.nrcan.gc.OEE.ERS2020NBC.ErsProgram"
      loc = "HouseFile/Program/Labels/English"
      h2k_contents[loc].add_text("EnerGuide Rating System")
      loc = "HouseFile/Program/Labels/French"
      h2k_contents[loc].add_text("Système de cote ÉnerGuide")    
    when "ON"
      loc = "HouseFile/Program" 
      h2k_contents[loc].attributes["class"] = "ca.nrcan.gc.OEE.ONrh.OnProgram"
      loc = "HouseFile/Program/Labels/English"
      h2k_contents[loc].add_text("Ontario Reference House")
      loc = "HouseFile/Program/Labels/French"
      h2k_contents[loc].add_text("Maison de référence de l'Ontario")
    else 
      # Shouldn't happen - choice verified above

    end 

  end 
  #..................................................
  def H2KEdit.delete_results(h2k_contents)
    h2k_contents["HouseFile"].delete_element("AllResults")
    return
  end 

  #..................................................
  # =========================================================================================
  #  Function to change window codes by orientation
  # =========================================================================================
  def H2KEdit.set_windows_by_orientation( h2kFileElements,  h2k_codes, winOrient, newValue)
    # Change ALL existing windows for this orientation (winOrient) to the library code name
    # specified in newValue. If this code name exists in the code library elements (h2k_codes),
    # use the code (either Fav or UsrDef) for all entries facing in this direction. Code names in the code
    # library are unique.
    # Note: Not using "Standard", non-library codes (e.g., 202002)

    # Look for this code name in code library (Favorite and UserDefined)
    windowFacingH2KVal = { 
      "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8 
    }

    # Think about a way to move useThisCodeID out of global. 
    $useThisCodeID  = {  
      "S"  =>  191 ,    
      "SE" =>  192 ,    
      "E"  =>  193 ,    
      "NE" =>  194 ,   
      "N"  =>  195 ,    
      "NW" =>  196 ,    
      "W"  =>  197 ,    
      "SW" =>  198   
    }


    debug_on 
    debug_out "Setting windows to #{newValue} for orientation: #{winOrient}"

    thisCodeInHouse = false
    foundFavLibCode = false
    foundUsrDefLibCode = false
    foundCodeLibElement = ""
    locationCodeFavText = "Codes/Window/Favorite/Code"
    h2k_codes.each(locationCodeFavText) do |codeElement|


      if ( codeElement.get_text("Label") == newValue )
        foundFavLibCode = true
        foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
        break
      end
    end
    # Code library names are also unique across Favorite and User Defined codes
    if ( ! foundFavLibCode )
      locationCodeUsrDefText = "Codes/Window/UserDefined/Code"
      h2k_codes.each(locationCodeUsrDefText) do |codeElement|
        if ( codeElement.get_text("Label") == newValue )
          foundUsrDefLibCode = true
          foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
          break
        end
      end
    end
    if ( foundFavLibCode || foundUsrDefLibCode )
      # Check to see if this code is already used in H2K file and add, if not.
      # Code references are in the <Codes> section. Avoid duplicates!
      if ( foundFavLibCode )
        locationText = "HouseFile/Codes/Window/Favorite"
      else
        locationText = "HouseFile/Codes/Window/UserDefined"
      end
      h2kFileElements.each(locationText + "/Code") do |element|
        if ( element.get_text("Label") == newValue )
          thisCodeInHouse = true
          $useThisCodeID[winOrient] = element.attributes["id"]
          break
        end
      end
      if ( ! thisCodeInHouse )
        if ( h2kFileElements["HouseFile/Codes/Window"] == nil )
          # No section of this type in house file Codes section -- add it!
          h2kFileElements["HouseFile/Codes"].add_element("Window")
        end
        if ( h2kFileElements[locationText] == nil )
          # No Favorite or UserDefined section in house file Codes section -- add it!
          if ( foundFavLibCode )
            h2kFileElements["HouseFile/Codes/Window"].add_element("Favorite")
          else
            h2kFileElements["HouseFile/Codes/Window"].add_element("UserDefined")
          end
        end
        foundCodeLibElement.attributes["id"] = $useThisCodeID[winOrient]
        h2kFileElements[locationText].add(foundCodeLibElement)
      end

      # Windows in walls elements
      locationText = "HouseFile/House/Components/Wall/Components/Window"
      h2kFileElements.each(locationText) do |element|
        if ( element.elements["FacingDirection"].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
          # Check if each house entry has an "idref" attribute and add if it doesn't.
          # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
          if element.elements["Construction/Type"].attributes["idref"] != nil
            # ../Construction/Type
            element.elements["Construction/Type"].attributes["idref"] = $useThisCodeID[winOrient]
          else
            element.elements["Construction/Type"].add_attribute("idref", $useThisCodeID[winOrient])
          end
          element.elements["Construction/Type"].text = newValue
        end
      end
      # Windows in basement
      locationText = "HouseFile/House/Components/Basement/Components/Window"
      h2kFileElements.each(locationText) do |element|
        # 9=FacingDirection
        if ( element.elements["FacingDirection"].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
          # Check if each house entry has an "idref" attribute and add if it doesn't.
          # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
          if element.elements["Construction/Type"].attributes["idref"] != nil
            # ../Construction/Type
            element.elements["Construction/Type"].attributes["idref"] = $useThisCodeID[winOrient]
          else
            element.elements["Construction/Type"].add_attribute("idref", $useThisCodeID[winOrient])
          end
          element.elements["Construction/Type"].text = newValue
        end
      end
      # Windows in walkout
      locationText = "HouseFile/House/Components/Walkout/Components/Window"
      h2kFileElements.each(locationText) do |element|
        # 9=FacingDirection
        if ( element.elements["FacingDirection"].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
          # Check if each house entry has an "idref" attribute and add if it doesn't.
          # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
          if element.elements["Construction/Type"].attributes["idref"] != nil
            # ../Construction/Type
            element.elements["Construction/Type"].attributes["idref"] = $useThisCodeID[winOrient]
          else
            element.elements["Construction/Type"].add_attribute("idref", $useThisCodeID[winOrient])
          end
          element.elements["Construction/Type"].text = newValue
        end
      end
      # Windows in crawlspace (closed or vented)
      locationText = "HouseFile/House/Components/Crawlspace/Components/Window"
      h2kFileElements.each(locationText) do |element|
        # 9=FacingDirection
        if ( element.elements["FacingDirection"].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
          # Check if each house entry has an "idref" attribute and add if it doesn't.
          # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
          if element.elements["Construction/Type"].attributes["idref"] != nil
            # ../Construction/Type
            element.elements["Construction/Type"].attributes["idref"] = $useThisCodeID[winOrient]
          else
            element.elements["Construction/Type"].add_attribute("idref", $useThisCodeID[winOrient])
          end
          element.elements["Construction/Type"].text = newValue
        end
      end

    else
      # Code name not found in the code library
      # Since no User Specified option for windows this must be an error!
      fatalerror("Missing code name: #{newValue} in code library for orientation:#{winOrient}\n")
    end

  end

end 


module H2KTemplates

  # =========================================================================================
  # Add an HRV section (check done external to this method)
  # =========================================================================================

  def H2KTemplates.hrv(elements)
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList"
    elements[locationText].add_element("Hrv")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"
    elements[locationText].attributes["supplyFlowrate"] = "60"
    elements[locationText].attributes["exhaustFlowrate"] = "60"
    elements[locationText].attributes["fanPower1"] = "123.7"
    elements[locationText].attributes["isDefaultFanpower"] = "true"
    elements[locationText].attributes["isEnergyStar"] = "false"
    elements[locationText].attributes["isHomeVentilatingInstituteCertified"] = "false"
    elements[locationText].attributes["isSupplemental"] = "false"
    elements[locationText].attributes["temperatureCondition1"] = "0"
    elements[locationText].attributes["temperatureCondition2"] = "-25"
    elements[locationText].attributes["fanPower2"] = "145.6"
    elements[locationText].attributes["efficiency1"] = "64"
    elements[locationText].attributes["efficiency2"] = "64"
    elements[locationText].attributes["preheaterCapacity"] = "0"
    elements[locationText].attributes["lowTempVentReduction"] = "0"
    elements[locationText].attributes["coolingEfficiency"] = "25"
    elements[locationText].add_element("EquipmentInformation")
    elements[locationText].add_element("VentilatorType")

    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/VentilatorType"
    elements[locationText].attributes["code"] = "1"
    # HRV
    elements[locationText].add_element("English")
    elements[locationText].add_element("French")

    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"
    elements[locationText].add_element("ColdAirDucts")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts"
    elements[locationText].add_element("Supply")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply"
    elements[locationText].attributes["length"] = "1.5"
    elements[locationText].attributes["diameter"] = "152.4"
    elements[locationText].attributes["insulation"] = "0.7"
    elements[locationText].add_element("Location")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply/Location"
    elements[locationText].attributes["code"] = "4"
    # Main Floor
    elements[locationText].add_element("English")
    elements[locationText].add_element("French")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply"
    elements[locationText].add_element("Type")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply/Type"
    elements[locationText].attributes["code"] = "1"
    # Flexible
    elements[locationText].add_element("English")
    elements[locationText].add_element("French")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply"
    elements[locationText].add_element("Sealing")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply/Sealing"
    elements[locationText].attributes["code"] = "2"
    # Sealed
    elements[locationText].add_element("English")
    elements[locationText].add_element("French")

    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts"
    elements[locationText].add_element("Exhaust")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust"
    elements[locationText].attributes["length"] = "1.5"
    elements[locationText].attributes["diameter"] = "152.4"
    elements[locationText].attributes["insulation"] = "0.7"
    elements[locationText].add_element("Location")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust/Location"
    elements[locationText].attributes["code"] = "4"
    # Main Floor
    elements[locationText].add_element("English")
    elements[locationText].add_element("French")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust"
    elements[locationText].add_element("Type")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust/Type"
    elements[locationText].attributes["code"] = "1"
    # Flexible
    elements[locationText].add_element("English")
    elements[locationText].add_element("French")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust"
    elements[locationText].add_element("Sealing")
    locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust/Sealing"
    elements[locationText].attributes["code"] = "2"
    # Sealed
    elements[locationText].add_element("English")
    elements[locationText].add_element("French")
  end 

end 



# Functions related to h2k data model, but that might one day be abstracted elsewhere
module H2KMisc
  def H2KMisc.getF326FlowRates( elements )
    locationText = "HouseFile/House/Ventilation/Rooms"
    roomLabels = [ "living", "bedrooms", "bathrooms", "utility", "otherHabitable" ]
    ventRequired = 0
    roomLabels.each do |roommName|
      if(roommName == "living" || roommName == "bathrooms" || roommName == "utility" || roommName == "otherHabitable")
        numRooms = elements[locationText].attributes[roommName].to_i
        ventRequired += (numRooms*5)
        #print "Room is ",roommName, " and number is ",numRooms, ". Total vent required is ", ventRequired, "\n"
      elsif(roommName == "bedrooms")
        numRooms = elements[locationText].attributes[roommName].to_i
        if(numRooms >= 1)
          ventRequired += 10
          if(numRooms > 1)
            ventRequired += ((numRooms-1)*5)
          end
        end
        #print "Room is ",roommName, " and number is ",numRooms, ". Total vent required is ", ventRequired, "\n"
      end
    end

    # If there is a basement, add another 10 L/s
    if(elements["HouseFile/House/Components/Basement"] != nil)
      ventRequired += 10
      #print "Room is basement. Total vent required is ", ventRequired, "\n"
    end
    #print "Final total vent required is ", ventRequired, "\n"
    return ventRequired
  end

end 



# =========================================================================================
# H2Kexec: routines that execute h2k calculations
# =========================================================================================
module H2Kexec
  def H2Kexec.run_a_hot2000_simulation(h2k_file_name)

    debug_on
    keep_trying = true
    tries = 0
    max_tries = 3 
    maxRunTime = 60
    pid = 0 
    run_ok = FALSE 
    

    run_path = $gMasterPath + "\\H2K"
  

    while keep_trying do 
      tries = tries + 1 
      
      start_time = Time.now

      if ( keep_trying && tries <= max_tries ) then 

        debug_out ("Try # #{tries}")

        run_file_name = "agent_run_file_#{tries}.h2k"
        FileUtils.cp(h2k_file_name, run_file_name)
        run_cmd = "HOT2000.exe -inp ..\\#{run_file_name}"    
        debug_out "HOT2000 run command: `#{run_cmd}`\n"


        begin
          Dir.chdir( run_path )
          pid = Process.spawn(run_cmd, :new_pgroup => true)
          stream_out ("\n Attempt ##{tries}:\n   -> Invoking HOT2000 (PID #{pid}) ...\n")
          run_status = Timeout::timeout($maxRunTime){
            Process.waitpid(pid, 0)
          }
          status = $?.exitstatus

        rescue SystemCallError => errmsg 
          debug_out ("system call error")
          stream_out ("HOT2000 CLI could not be invoked. Trying again.\n")
          log_out("HOT2000 CLI runtime error: #{errmsg}")
          status = -1
          sleep(2)

        rescue Timeout::Error

          debug_out ("Timeout error! ")

          begin
            Process.kill('KILL', pid)
          rescue
            # do nothing - process may have died on its own?
          end
          status = -1

          sleep(2)
        end

        end_time = Time.now 
        lapsed_time = end_time - start_time 


        stream_out("   -> Hot2000 (PID: #{pid}) finished with exit status #{status} \n")

        if status == 0 
          # Successful run!
          stream_out "   -> The run was successful (#{lapsed_time.round(2).to_s} seconds)"
          keep_trying = FALSE
          run_ok = TRUE 

        elsif status == -1 
          warn_out("\n\n Attempt ##{tries}: Timeout on H2K call after #{maxRunTime} seconds." )

        elsif status == 3 || status == nil 
          warn_out( " The run completed but had pre-check messages! (#{lapsed_time.round(2).to_s} seconds)")

        end 
      
      else 

        warn_out("Max number of execution attempts (#{max_tries}) reached. Giving up.")
        #fatalerror("Hot2000 evaluation could not be completed successfully")
        keep_trying = false
        # Give up.

      end 
    end 

    Dir.chdir($gMasterPath)
    if (run_ok) then 
          
      FileUtils.cp(run_file_name,h2k_file_name)

    end 
  
    return run_ok 

  end 
end



# =========================================================================================
# H2Kpost: routines that extract hot2000 tesults
# =========================================================================================

module H2Kpost

  # This function does nothing! 
  def H2Kpost.handle_sim_results(h2k_file_name,choices)
    stream_out("  -> Loading XML elements from #{h2k_file_name}\n")
    results = H2Kpost.prep_results(h2k_file_name,choices)
    return results

  end 

  
  def H2Kpost.prep_results(h2k_file_name,choices)
    debug_on
    
    code = "SOC"
    res_e = H2KFile.open_xml_as_elements(h2k_file_name)

    
    program = H2KFile.getProgramName(res_e)



    debug_out ("PROGRAM: #{program}")

    dim_info = H2KFile.getAllInfo(res_e)
    env_info = H2KFile.getEnvelopeSpecs(res_e)
    res_data = H2Kpost.get_results_from_elements(res_e,program)

    results =  Hash.new 

    results["configuration"] = {
      "OptionsFile"         =>  "#{$gOptionFile}",
      "Recovered-results"   =>  "#{code}",
      "version" => {
        "h2kHouseFile" => "#{res_e["HouseFile/Version"].attributes["major"]}.#{res_e["HouseFile/Version"].attributes["minor"]}",
        "HOT2000" =>  "v#{res_e["HouseFile/Application/Version"].attributes["major"]}"+
                      ".#{res_e["HouseFile/Application/Version"].attributes["minor"]}"+
                      "b#{res_e["HouseFile/Application/Version"].attributes["build"]}"
      },
    }

    # return results 
    results["archetype"] = {
      "h2k-File"  => h2k_file_name, 
      "House-Builder"       =>  H2KFile.getBuilderName(res_e), 
      "EvaluationDate"      =>  H2KFile.getEvalDate(res_e),
      "Year-Built"          =>  H2KFile.getYearBuilt(res_e),
      "House-Type"          =>  H2KFile.getHouseType(res_e),
      "House-Storeys"       =>  H2KFile.getStoreys(res_e), 
      "Front-Orientation"   =>  H2KFile.getFrontOrientation(res_e),
      "Weather-Locale"      =>  H2KFile.getWeatherCity( res_e ),

    #      

    #      "Base-Region"         =>  "#{$gBaseRegion}",
    #      "Base-Locale"         =>  "#{$gBaseLocale}",
    #			"Base-City"           =>  "#{$gBaseCity}",
    #      "climate-zone"        =>  "#{climateZone}",
    #      "fuel-heating-presub"  =>  "#{$ArchetypeData["pre-substitution"]["fuelHeating"]}",
    #      "fuel-DHW-presub"     =>  "#{$ArchetypeData["pre-substitution"]["fuelDHW"]}",
      "Ceiling-Type"        =>  "not-supported",
      "Area-Slab-m2"        =>  dim_info["dimensions"]["below-grade"]["slab"]["floor-area"],
      "Area-Basement-m2"    =>  dim_info["dimensions"]["below-grade"]["basement"]["floor-area"],
      "Area-Walkout-m2"     =>  "not-supported",
      "Area-Crawl-m2"       =>  dim_info["dimensions"]["below-grade"]["crawlspace"]["floor-area"],
      "Floor-Area-m2"       =>  dim_info["dimensions"]["heatedFloorArea"],
      "House-Volume-m3"     => H2KFile.getHouseVolume(res_e),
      "Archetype-ACH"       => H2KFile.getACHRate(res_e),
      "Win-SHGC-average"    =>  env_info["windows"]["average_SHGC"],
      "Win-UValue-average"    =>  env_info["windows"]["average_Uvalue"],
      "Win-Area-Total-m2"   =>  env_info["windows"]["total_area"],

    }


    if ($cmdlineopts["extra_output"]) then 
      results["archetype"]["Win-SHGC-S"     ]  = env_info["windows"]["by_orientation"]["SHGC"][1]
      results["archetype"]["Win-SHGC-SE"    ]  = env_info["windows"]["by_orientation"]["SHGC"][2]
      results["archetype"]["Win-SHGC-E"     ]  = env_info["windows"]["by_orientation"]["SHGC"][3]
      results["archetype"]["Win-SHGC-NE"    ]  = env_info["windows"]["by_orientation"]["SHGC"][4]
      results["archetype"]["Win-SHGC-N"     ]  = env_info["windows"]["by_orientation"]["SHGC"][5]
      results["archetype"]["Win-SHGC-NW"    ]  = env_info["windows"]["by_orientation"]["SHGC"][6]
      results["archetype"]["Win-SHGC-W"     ]  = env_info["windows"]["by_orientation"]["SHGC"][7]
      results["archetype"]["Win-SHGC-SW"    ]  = env_info["windows"]["by_orientation"]["SHGC"][8]
      results["archetype"]["Win-UValue-S"   ]  =   env_info["windows"]["by_orientation"]["Uvalue"][1]
      results["archetype"]["Win-UValue-SE"  ]  =   env_info["windows"]["by_orientation"]["Uvalue"][2]
      results["archetype"]["Win-UValue-E"   ]  =   env_info["windows"]["by_orientation"]["Uvalue"][3]
      results["archetype"]["Win-UValue-NE"  ]  =   env_info["windows"]["by_orientation"]["Uvalue"][4]
      results["archetype"]["Win-UValue-N"   ]  =   env_info["windows"]["by_orientation"]["Uvalue"][5]
      results["archetype"]["Win-UValue-NW"  ]  =   env_info["windows"]["by_orientation"]["Uvalue"][6]
      results["archetype"]["Win-UValue-W"   ]  =   env_info["windows"]["by_orientation"]["Uvalue"][7]
      results["archetype"]["Win-UValue-SW"  ]  =   env_info["windows"]["by_orientation"]["Uvalue"][8]
      results["archetype"]["Win-Area-S"     ]  = env_info["windows"]["by_orientation"]["area"][1]
      results["archetype"]["Win-Area-SE"    ]  = env_info["windows"]["by_orientation"]["area"][2]
      results["archetype"]["Win-Area-E"     ]  = env_info["windows"]["by_orientation"]["area"][3]
      results["archetype"]["Win-Area-NE"    ]  = env_info["windows"]["by_orientation"]["area"][4]
      results["archetype"]["Win-Area-N"     ]  = env_info["windows"]["by_orientation"]["area"][5]
      results["archetype"]["Win-Area-NW"    ]  = env_info["windows"]["by_orientation"]["area"][6]
      results["archetype"]["Win-Area-W"     ]  = env_info["windows"]["by_orientation"]["area"][7]
      results["archetype"]["Win-Area-SW"    ]  = env_info["windows"]["by_orientation"]["area"][8]
    end 


    # TO BE ADDED! 
    #		  "Wall-RSI"            => "#{$RSI['wall'].round(2)}" ,
    #      "Ceiling-RSI"         => "#{$RSI['ceiling'].round(2)}" ,
    #      "ExposedFloor-RSI"          => "#{$RSI["floor"].round(2)}" ,
    #      "Area-Door-m2"        => "#{$AreaComp['door'].round(3)}",
    #      "Area-DoorWin-m2"     => "#{$AreaComp['doorwin'].round(3)}",
    #      "Area-Windows-m2"     => "#{$AreaComp['win'].round(3)}",
    #      "Area-Wall-m2"        => "#{$AreaComp['wall'].round(3)}",
    #      "Area-Header-m2"      => "#{$AreaComp['header'].round(3)}",
    #      "Area-Ceiling-m2"     => "#{$AreaComp['ceiling'].round(3)}",
    #      "Area-ExposedFloor-m2"     => "#{$AreaComp['floor'].round(3)}",
    #      "Area-House-m2"       => "#{$AreaComp['house'].round(3)}"


    

 
    
    results["input"] = { 
    #  "Run-Region" =>  "#{$gRunRegion}",
    #  "Run-Locale" =>  "#{$gRunLocale}",
    #  "House-Upgraded"   =>  "#{$houseUpgraded}",
    #  "House-ListOfUpgrades" => "#{$houseUpgradeList}",
    #  "Ruleset-Fuel-Source" => "#{$gRulesetSpecs["fuel"]}",
    #  "Ruleset-Ventilation" => "#{$gRulesetSpecs["vent"]}"
    }
    
    choices.sort.to_h
    for attribute in choices.keys()
      choice = choices[attribute]
      results["input"][attribute] = "#{choice}"
    end





    results["output"] = { }

    res_data["std_output"].each do | column, value  |
      results["output"][column] = value 
    end

    if ( $cmdlineopts["extra_output"] ) 
      res_data["extra_output"].each do | column, value  |
        results["output"][column] = value 
      end
    end 

    results["status"] = {}
    $gStatus.keys.each do | status_type |
      results["status"][status_type] = "#{$gStatus[status_type]}"
    end

    results["status"]["errors"] = Array.new
    results["status"]["errors"] = $gErrors
    results["status"]["warnings"] = Array.new
    results["status"]["warnings"] = $gWarnings
    results["status"]["infoMsgs"] = Array.new
    results["status"]["infoMsgs"] = $gInfoMsgs
    results["status"]["success"] = $allok
    
    #    myEndProcessTime = Time.now
    #    totalDiff = myEndProcessTime - $startProcessTime
    #    results["status"]["processingtime"]  = $totalDiff
    #    if ( $autoEstimateCosts ) then
    #      results["costs"] = $costEstimates
    #    end



    #    }
    #
    #
    #    results["input"] = Hash.new
    #    results["input"] = { "Run-Region" =>  "#{$gRunRegion}",
    #    "Run-Locale" =>  "#{$gRunLocale}",
    #    "House-Upgraded"   =>  "#{$houseUpgraded}",
    #    "House-ListOfUpgrades" => "#{$houseUpgradeList}",
    #    "Ruleset-Fuel-Source" => "#{$gRulesetSpecs["fuel"]}",
    #    "Ruleset-Ventilation" => "#{$gRulesetSpecs["vent"]}"
    #    $gChoices.sort.to_h
    #    for attribute in $gChoices.keys()
    #      choice = $gChoices[attribute]
    #      results["input"][attribute] = "#{choice}"
    #    end
    #
    #    results["analysis_BCStepCode"] = {
    #      "TEDI_compliance" =>  "-"
    #    }
    #
    #
    #    results["output"] = {
    #      "HDDs"              => $HDDs,
    #      "Energy-Total-GJ"   => $gResults[$outputHCode]['avgEnergyTotalGJ'].round(1),
    #      "ERSRefHouse_Energy-Total-GJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyTotalGJ"].round(1),
    #      #"Ref-En-Total-GJ"   => $RefEnergy.round(1),
    #      "Util-Bill-gross"   => $gResults[$outputHCode]['avgFuelCostsTotal$'].round(2),
    #      "Util-PV-revenue"   => $gResults[$outputHCode]['avgPVRevenue'].round(2),
    #      "Util-Bill-Net"     => $gResults[$outputHCode]['avgFuelCostsTotal$'].round(2) - $gResults[$outputHCode]['avgPVRevenue'].round(2),
    #      "Util-Bill-Elec"    => $gResults[$outputHCode]['avgFuelCostsElec$'].round(2),
    #      "Util-Bill-Gas"     => $gResults[$outputHCode]['avgFuelCostsNatGas$'].round(2),
    #      "Util-Bill-Prop"    => $gResults[$outputHCode]['avgFuelCostsPropane$'].round(2),
    #      "Util-Bill-Oil"     => $gResults[$outputHCode]['avgFuelCostsOil$'].round(2),
    #      "Util-Bill-Wood"    => $gResults[$outputHCode]['avgFuelCostsWood$'].round(2),
    #      "Energy-PV-kWh"     => $gResults[$outputHCode]['avgElecPVGenkWh'].round(0),
    #      "Gross-HeatLoss-GJ" => $gResults[$outputHCode]['avgGrossHeatLossGJ'].round(1),
    #      "Infil-VentHeatLoss-GJ" => $gResults[$outputHCode]["avgVentAndInfilGJ"].round(1),
    #      "Useful-Solar-Gain-GJ" => $gResults[$outputHCode]['avgSolarGainsUtilized'].round(1),
    #      "Energy-HeatingGJ"  => $gResults[$outputHCode]['avgEnergyHeatingGJ'].round(1),
    #      "ERSRefHouse_Energy-HeatingGJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyHeatingGJ"].round(1),
    #      "AuxEnergyReq-HeatingGJ" => $gAuxEnergyHeatingGJ.round(1),
    #      "TotalAirConditioning-LoadGJ" => $TotalAirConditioningLoad.round(1) ,
    #      "AvgAirConditioning-COP" => $AvgACCOP.round(1) ,
    #      "Energy-CoolingGJ"  => $gResults[$outputHCode]['avgEnergyCoolingGJ'].round(1) ,
    #      "ERSRefHouse_Energy-CoolingGJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyCoolingGJ"].round(1),
    #      "Energy-VentGJ"     => $gResults[$outputHCode]['avgEnergyVentilationGJ'].round(1) ,
    #      "ERSRefHouse_Energy-VentGJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyVentilationGJ"].round(1),
    #      "Energy-DHWGJ"      => $gResults[$outputHCode]['avgEnergyWaterHeatingGJ'].round(1) ,
    #      "ERSRefHouse_Energy-DHWGJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyWaterHeatingGJ"].round(1),
    #      "Energy-PlugGJ"     => $gResults[$outputHCode]['avgEnergyEquipmentGJ'].round(1) ,
    #      "ESRefHouse_Energy-PlugGJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyEquipmentGJ"].round(1),
    #      "EnergyEleckWh"     => $gResults[$outputHCode]['avgFueluseEleckWh'].round(1) ,
    #      "EnergyGasM3"       => $gResults[$outputHCode]['avgFueluseNatGasM3'].round(1) ,
    #      "EnergyOil_l"       => $gResults[$outputHCode]['avgFueluseOilL'].round(1) ,
    #      "EnergyProp_L"      => $gResults[$outputHCode]['avgFuelusePropaneL'].round(1) ,
    #      "EnergyWood_cord"   => $gResults[$outputHCode]['avgFueluseWoodcord'].round(1) ,
    #      # includes pellets
    #      "TEDI_kWh_m2"       => $TEDI_kWh_m2.round(1) ,
    #      "MEUI_kWh_m2"       => $MEUI_kWh_m2.round(1) ,
    #      "ERS-Value"         => $gERSNum.round(1) ,
    #      "NumTries"          => $NumTries.round(1) ,
    #      "LapsedTime"        => $runH2KTime.round(2) ,
    #      "PEAK-Heating-W"    => $gResults[$outputHCode]['avgOthPeakHeatingLoadW'].round(1) ,
    #      "PEAK-Cooling-W"    => $gResults[$outputHCode]['avgOthPeakCoolingLoadW'].round(1) ,
    #      "DesignTemp-Heating-oC" => $gResults[$outputHCode]["annual"]["design_Temp"]["heating_C"].round(1)
    ##      "House-R-Value(SI)" => $RSI['house'].round(3)
    #    }
    #
    #    if $ExtraOutput1 then
    #      results["output"]["EnvTotalHL-GJ"]     =  $gResults[$outputHCode]['EnvHLTotalGJ'].round(1)
    #      results["output"]["EnvCeilHL-GJ"]      =  $gResults[$outputHCode]['EnvHLCeilingGJ'].round(1)
    #      results["output"]["EnvWallHL-GJ"]      =  $gResults[$outputHCode]['EnvHLMainWallsGJ'].round(1)
    #      results["output"]["EnvWinHL-GJ"]       =  $gResults[$outputHCode]['EnvHLWindowsGJ'].round(1)
    #      results["output"]["EnvDoorHL-GJ"]      =  $gResults[$outputHCode]['EnvHLDoorsGJ'].round(1)
    #      results["output"]["EnvFloorHL-GJ"]     =  $gResults[$outputHCode]['EnvHLExpFloorsGJ'].round(1)
    #      results["output"]["EnvCrawlHL-GJ"]     =  $gResults[$outputHCode]['EnvHLCrawlspaceGJ'].round(1)
    #      results["output"]["EnvSlabHL-GJ"]      =  $gResults[$outputHCode]['EnvHLSlabGJ'].round(1)
    #      results["output"]["EnvBGBsemntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLBasementBGWallGJ'].round(1)
    #      results["output"]["EnvAGBsemntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLBasementAGWallGJ'].round(1)
    #      results["output"]["EnvBsemntFHHL-GJ"]  =  $gResults[$outputHCode]['EnvHLBasementFlrHdrsGJ'].round(1)
    #      results["output"]["EnvPonyWallHL-GJ"]  =  $gResults[$outputHCode]['EnvHLPonyWallGJ'].round(1)
    #      results["output"]["EnvFABsemntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLFlrsAbvBasementGJ'].round(1)
    #      results["output"]["EnvAirLkVntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLAirLkVentGJ'].round(1)
    #      results["output"]["SpcHeatElec-GJ"]    = $gResults[$outputHCode]['AnnSpcHeatElecGJ'].round(1)
    #      results["output"]["SpcHeatHP-GJ"]      = $gResults[$outputHCode]['AnnSpcHeatHPGJ'].round(1)
    #      results["output"]["SpcHeatGas-GJ"]     = $gResults[$outputHCode]['AnnSpcHeatGasGJ'].round(1)
    #      results["output"]["SpcHeatOil-GJ"]     = $gResults[$outputHCode]['AnnSpcHeatOilGJ'].round(1)
    #      results["output"]["SpcHeatProp-GJ"]    = $gResults[$outputHCode]['AnnSpcHeatPropGJ'].round(1)
    #      results["output"]["SpcHeatWood-GJ"]    = $gResults[$outputHCode]['AnnSpcHeatWoodGJ'].round(1)
    #      results["output"]["HotWaterElec-GJ"]   = $gResults[$outputHCode]['AnnHotWaterElecGJ'].round(1)
    #      results["output"]["HotWaterGas-GJ"]    = $gResults[$outputHCode]['AnnHotWaterGasGJ'].round(1)
    #      results["output"]["HotWaterOil-GJ"]    = $gResults[$outputHCode]['AnnHotWaterOilGJ'].round(1)
    #      results["output"]["HotWaterProp-GJ"]   = $gResults[$outputHCode]['AnnHotWaterPropGJ'].round(1)
    #      results["output"]["HotWaterWood-GJ"]   = $gResults[$outputHCode]['AnnHotWaterWoodGJ'].round(1)
    #    end
    #
    #
    #    results["status"] = Hash.new
    #    $gStatus.keys.each do | status_type |
    #      results["status"][status_type] = "#{$gStatus[status_type]}"
    #    end
    #
    #    results["status"]["errors"] = Array.new
    #    results["status"]["errors"] = $gErrors
    #    results["status"]["warnings"] = Array.new
    #    results["status"]["warnings"] = $gWarnings
    #    results["status"]["infoMsgs"] = Array.new
    #    results["status"]["infoMsgs"] = $gInfoMsgs
    #    results["status"]["success"] = $allok
    #
    #    myEndProcessTime = Time.now
    #    totalDiff = myEndProcessTime - $startProcessTime
    #    results["status"]["processingtime"]  = $totalDiff
    #    if ( $autoEstimateCosts ) then
    #      results["costs"] = $costEstimates
    #    end
    #

    return results

  end 

  def H2Kpost.get_results_from_elements(res_e,program)
    xmlpath = "HouseFile/AllResults"

    myResults = {
      "std_output" => Hash.new,
      "extra_output" => Hash.new,
      "ref_house" => Hash.new 
    } 

    found_the_set = FALSE

    if ( program == "ERS" or  program == "NBC" or program == "ON" )
      code = "SOC"
    else 
      code = "General"
    end 

    debug_on
    debug_out ("Paring results for code: #{program} / #{code}")
    
    res_e["HouseFile/AllResults"].elements.each do |element|




      this_set_code = element.attributes["houseCode"]
      if (this_set_code == nil && element.attributes["sha256"] != nil)
        this_set_code = "General"
      end

      debug_out "Result-set: #{this_set_code}"
      



      if ( this_set_code != code ) then 
        next 
      end 

      found_the_set = TRUE 
      debug_out ("Parsing code #{this_set_code}")

      myResults["std_output"]["avgEnergyTotalGJ"]        = element.elements[".//Annual/Consumption"].attributes["total"].to_f  
      myResults["std_output"]["avgEnergyHeatingGJ"]      = element.elements[".//Annual/Consumption/SpaceHeating"].attributes["total"].to_f  
      myResults["std_output"]["avgGrossHeatLossGJ"]      = element.elements[".//Annual/HeatLoss"].attributes["total"].to_f  
      myResults["std_output"]["avgVentAndInfilGJ"]       = element.elements[".//Annual/HeatLoss"].attributes["airLeakageAndNaturalVentilation"].to_f  
      myResults["std_output"]["avgEnergyCoolingGJ"]      = element.elements[".//Annual/Consumption/Electrical"].attributes["airConditioning"].to_f  
      myResults["std_output"]["avgEnergyVentilationGJ"]  = element.elements[".//Annual/Consumption/Electrical"].attributes["ventilation"].to_f  
      myResults["std_output"]["avgEnergyEquipmentGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["baseload"].to_f  
      myResults["std_output"]["avgEnergyWaterHeatingGJ"] = element.elements[".//Annual/Consumption/HotWater"].attributes["total"].to_f  
      myResults["extra_output"]["EnvHLTotalGJ"] = element.elements[".//Annual/HeatLoss"].attributes["total"].to_f  
      myResults["extra_output"]["EnvHLCeilingGJ"] = element.elements[".//Annual/HeatLoss"].attributes["ceiling"].to_f  
      myResults["extra_output"]["EnvHLMainWallsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["mainWalls"].to_f  
      myResults["extra_output"]["EnvHLWindowsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["windows"].to_f  
      myResults["extra_output"]["EnvHLDoorsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["doors"].to_f  
      myResults["extra_output"]["EnvHLExpFloorsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["exposedFloors"].to_f  
      myResults["extra_output"]["EnvHLCrawlspaceGJ"] = element.elements[".//Annual/HeatLoss"].attributes["crawlspace"].to_f  
      myResults["extra_output"]["EnvHLSlabGJ"] = element.elements[".//Annual/HeatLoss"].attributes["slab"].to_f  
      myResults["extra_output"]["EnvHLBasementBGWallGJ"] = element.elements[".//Annual/HeatLoss"].attributes["basementBelowGradeWall"].to_f  
      myResults["extra_output"]["EnvHLBasementAGWallGJ"] = element.elements[".//Annual/HeatLoss"].attributes["basementAboveGradeWall"].to_f  
      myResults["extra_output"]["EnvHLBasementFlrHdrsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["basementFloorHeaders"].to_f  
      myResults["extra_output"]["EnvHLPonyWallGJ"] = element.elements[".//Annual/HeatLoss"].attributes["ponyWall"].to_f  
      myResults["extra_output"]["EnvHLFlrsAbvBasementGJ"] = element.elements[".//Annual/HeatLoss"].attributes["floorsAboveBasement"].to_f  
      myResults["extra_output"]["EnvHLAirLkVentGJ"] = element.elements[".//Annual/HeatLoss"].attributes["airLeakageAndNaturalVentilation"].to_f  
      myResults["std_output"]["AnnHotWaterLoadGJ"] = element.elements[".//Annual/HotWaterDemand"].attributes["base"].to_f  
      
      myResults["std_output"]["Design_Heating_Load_W"] = element.elements[".//Other"].attributes["designHeatLossRate"].to_f  
      myResults["std_output"]["Design_Cooling_Load_W"] = element.elements[".//Other"].attributes["designCoolLossRate"].to_f  

      myResults["std_output"]["avgOthSeasonalHeatEff"] = element.elements[".//Other"].attributes["seasonalHeatEfficiency"].to_f  
      myResults["extra_output"]["avgVntAirChangeRateNatural"] = element.elements[".//Annual/AirChangeRate"].attributes["natural"].to_f  
      myResults["extra_output"]["avgVntAirChangeRateTotal"] = element.elements[".//Annual/AirChangeRate"].attributes["total"].to_f  
      myResults["extra_output"]["avgSolarGainsUtilized"] = element.elements[".//Annual/UtilizedSolarGains"].attributes["value"].to_f  
      myResults["extra_output"]["avgVntMinAirChangeRate"] = element.elements[".//Other/Ventilation"].attributes["minimumAirChangeRate"].to_f  

      myResults["std_output"]["AnnSpcHeatElecGJ"] = element.elements[".//Annual/Consumption/Electrical"].attributes["spaceHeating"].to_f  
      myResults["std_output"]["AnnSpcHeatHPGJ"] = element.elements[".//Annual/Consumption/Electrical"].attributes["heatPump"].to_f  
      myResults["std_output"]["AnnSpcHeatGasGJ"] = element.elements[".//Annual/Consumption/NaturalGas"].attributes["spaceHeating"].to_f  
      myResults["std_output"]["AnnSpcHeatOilGJ"] = element.elements[".//Annual/Consumption/Oil"].attributes["spaceHeating"].to_f  
      myResults["std_output"]["AnnSpcHeatPropGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["spaceHeating"].to_f  
      myResults["std_output"]["AnnSpcHeatWoodGJ"] = element.elements[".//Annual/Consumption/Wood"].attributes["spaceHeating"].to_f  
      myResults["std_output"]["AnnHotWaterElecGJ"] = element.elements[".//Annual/Consumption/Electrical/HotWater"].attributes["dhw"].to_f  
      myResults["std_output"]["AnnHotWaterGasGJ"] = element.elements[".//Annual/Consumption/NaturalGas"].attributes["hotWater"].to_f  
      myResults["std_output"]["AnnHotWaterOilGJ"] = element.elements[".//Annual/Consumption/Oil"].attributes["hotWater"].to_f  
      myResults["std_output"]["AnnHotWaterPropGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["hotWater"].to_f  
      myResults["std_output"]["AnnHotWaterWoodGJ"] = element.elements[".//Annual/Consumption/Wood"].attributes["hotWater"].to_f  

      
      myResults["std_output"]["avgFueluseElecGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["total"].to_f  
      myResults["std_output"]["avgFueluseNatGasGJ"]  = element.elements[".//Annual/Consumption/NaturalGas"].attributes["total"].to_f  
      myResults["std_output"]["avgFueluseOilGJ"]     = element.elements[".//Annual/Consumption/Oil"].attributes["total"].to_f  
      myResults["std_output"]["avgFuelusePropaneGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["total"].to_f  
      myResults["std_output"]["avgFueluseWoodGJ"]    = element.elements[".//Annual/Consumption/Wood"].attributes["total"].to_f  

      myResults["std_output"]["avgFueluseEleckWh"]  = myResults["std_output"]["avgFueluseElecGJ"] * 277.77777778
      myResults["std_output"]["avgFueluseNatGasM3"] = myResults["std_output"]["avgFueluseNatGasGJ"] * 26.853
      myResults["std_output"]["avgFueluseOilL"]     = myResults["std_output"]["avgFueluseOilGJ"]  * 25.9576
      myResults["std_output"]["avgFuelusePropaneL"] = myResults["std_output"]["avgFuelusePropaneGJ"] / 25.23 * 1000
      myResults["std_output"]["avgFueluseWoodcord"] = myResults["std_output"]["avgFueluseWoodGJ"] / 18.30

      monthArr = [ "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december" ]
      debug_out (" Picking up  AUX energy requirement from each result set. \n")

      myResults["std_output"]["auxEnergyHeatingGJ"] = 0
      $MonthlyAuxHeatingMJ = 0
      monthArr.each do |mth|
        myResults["std_output"]["auxEnergyHeatingGJ"] += element.elements[".//Monthly/UtilizedAuxiliaryHeatRequired"].attributes[mth].to_f / 1000
      end

    end

    # do these belong here? ???
    # Open output file here so we can log errors too!
    #myResults[houseCode]["monthly"]["GrossThermalLoad"] = Hash.new 
    #myResults[houseCode]["monthly"]["UtilizedInternalGains"] = Hash.new 
    #myResults[houseCode]["monthly"]["UtilizedSolarGains"] = Hash.new 
    #myResults[houseCode]["monthly"]["FractionOfTimeHeatingSystemNotOperating"]= Hash.new 
    #myResults[houseCode]["monthly"]["UtilizedAuxiliaryHeatRequired"] = Hash.new 
    #myResults[houseCode]["monthly"][""] = Hash.new 
    # myResults[houseCode]["monthly"][""] = Hash.new 
    
    #monthArr.each do |mth|
    #  myResults[houseCode]["monthly"]["UtilizedAuxiliaryHeatRequired"][mth] = h2kPostElements[".//Monthly/UtilizedAuxiliaryHeatRequired"].attributes[mth].to_f
    #  myResults[houseCode]["monthly"]["GrossThermalLoad"][mth] = h2kPostElements[".//Monthly/FractionOfTimeHeatingSystemNotOperating"].attributes[mth].to_f
    #  myResults[houseCode]["monthly"]["GrossThermalLoad"][mth] = h2kPostElements[".//Monthly/Load/GrossThermal"].attributes[mth].to_f
    #  myResults[houseCode]["monthly"]["UtilizedInternalGains"][mth] = h2kPostElements[".//Monthly/Gains/UtilizedInternal"].attributes[mth].to_f
    #  myResults[houseCode]["monthly"]["UtilizedSolarGains"][mth] = h2kPostElements[".//Monthly/Gains/UtilizedSolar"].attributes[mth].to_f
    #end 



    if ( ! found_the_set ) then 
      err_out("Could not parse result set #{code}")
      
    end 
    
    return myResults

    debug_pause
  end 

  def H2Kpost.read_routstr

  end 

  def H2Kpost.write_results(results)

  end 


end 


# =========================================================================================
# H2Kutilis : module containing functions that manage h2k environment
# =========================================================================================
module H2KUtils

  def H2KUtils.create_run_environment(src_path,run_path)
    env_ok = true  
    dest_path = "#{run_path}"
    if ( ! Dir.exist?( dest_path ) )
      if ( ! FileUtils.mkdir(dest_path) )
        warn_out (" Could not create H2K folder at #{run_path}. Return error code #{$?}.")
      end 
      stream_out ("    Copying H2K program folder to #{dest_path} ...")
      FileUtils.cp_r("#{src_path}/.", "#{dest_path}")
      stream_out (" (done)\n")
    end

    stream_out ("    Checking integrity of H2K installation:\n")
    
    masterMD5  = checksum("#{src_path}").to_s
    workingMD5 = checksum("#{dest_path}").to_s

    stream_out ("    - master:        #{masterMD5}\n")
    stream_out ("    - working copy:  #{workingMD5}")


    if (masterMD5.eql? workingMD5) then
      stream_out(" (checksum match)\n")

      $gStatus["MD5master"] = $masterMD5.to_s
      $gStatus["MD5workingcopy"] = $workingMD5.to_s
      $gStatus["H2KDirCopyAttempts"] = $CopyTries.to_s
      $gStatus["H2KDirCheckSumMatch"] = $DirVerified

    else
      FileUtils.rm_r ( dest_path )
      stream_out(" (CHECKSUM MISMATCH!!!)\n")
      warn_out("Working H2K installation dir (#{dest_path}) differs from source #{$src_path}.")
      env_ok = false 
    end

    return env_ok 

  end 

end 

# =========================================================================================
# General purpose functions 
# =========================================================================================
# Compute a checksum for directory, ignoring files that HOT2000 commonly alters during ar run
# Can this be put inside the module?
def checksum(dir)
  begin
    md5 = Digest::MD5.new
    searchLoc = dir.gsub(/\\/, "/")

    files = Dir["#{searchLoc}/**/*"].reject{|f|  File.directory?(f) ||
      f =~ /Browse\.Rpt/i ||
      f =~ /WINMB\.H2k/i  ||
      f =~ /ROutStr\.H2k/i ||
      f =~ /ROutStr\.Txt/i ||
      f =~ /WMB_.*\.Txt/i ||
      f =~ /HOT2000\.ini/i ||
      f =~ /wizdefs.h2k/i
    }
    content = files.map{|f| File.read(f)}.join
    md5result = md5.update content
    files.clear
    content.clear
    return md5.update content
  rescue 
    warn_out ("Could not checksum h2k directory")
    return nil 
  end
end
