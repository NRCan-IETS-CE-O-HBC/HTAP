# ==========================================
# H2KUtilities.rb: functions used
# to query, manipulate hot2000 files and
# the h2k environment.
# ==========================================


# Parses a HOT2000 weather library and develops a hash with the right location / region codes. 

module H2KWth

  def H2KWth.read_weather_dir(wfile)

    debug_off()
    debug_out "Parsing weather data from #{wfile}"
    prov_names = Array.new 
    prov_links = Array.new
    loc_names = Array.new 

    # Default array for HOT2000 locations
    h2k_locations = {
      "structure" => "tree",
      "costed" => false,
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
      "stop-on-error" => true,
      "h2kSchema" => [
        "OPT-H2K-WTH-FILE",
        "OPT-H2K-Region",
        "OPT-H2K-Location"
      ]
    }

    firstLine = true
    read_prov_names = false 
    read_prov_links = false
    read_loc_names  = false
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
        firstLine = false
        read_prov_names = true 
        next 
        
      end 

      if read_prov_names
        debug_out "[prov-name] #{line}"
        line.split(/ {2,}/).each do | name |
          prov_names.push(name)
        end 
        debug_out ("LEN: #{prov_names.length} / #{ prov_count.to_i} ")
        if ( prov_names.length == prov_count.to_i ) then 
          read_prov_names = false 
          read_prov_links = true
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
          read_prov_links = false 
          read_loc_names = true
          next  
        end 
      end 

      if read_loc_names
        debug_out "[prov-name] #{line}"
        line.split(/ {3,}/).each do | name |
          debug_out ("+-> #{name}")
          loc_names.push(name)
        end 
        debug_out ("LEN: #{loc_names.length} / #{ loc_count.to_i} ")
        if ( loc_names.length == loc_count.to_i ) then  
          read_loc_names = false
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
  
    if debug_status() 
      filename = "debug-wthr-map.json"
      debug_out "Creating debugging file - #{filename}"
      fJsonOut = File.open(filename, "w")
      if ( fJsonOut.nil? )then
        fatalerror("Could not create #{filename}")
      end
  
      fJsonOut.puts JSON.pretty_generate(h2k_locations)
      fJsonOut.close

    end 

    return h2k_locations

    

  end

  def H2KWth.list_locations(h2k_locations)
    stream_out drawRuler("Printing a list of valid location keywords")
    stream_out ("\n Locations:\n")
    h2k_locations["options"].keys.each do | location |
      stream_out "  - KEYWORD: #{location}  (Region: #{h2k_locations["options"][location]["h2kMap"]["base"]["region_name"]})\n"
    end 
    stream_out ("\n  -> To use these locations, specify `Opt-Location = KEYWORD `\n\n" )
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
      $XMLdoc.write(:output=>newXMLFile, :ie_hack => true)
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
      "ceilings" => {},
      "envelope" => {
        "envelope_area_m2" => nil,
        "areaWeightedUvalue_excl_Infiltration_W_per_m2K" => nil,
        "areaWeightedUvalue_incl_Infiltration_W_per_m2K" => nil
      }
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



    x_path = "HouseFile/House/Components/*/Components/Window"


    elements.each(x_path) do |window|
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

    x_path = "HouseFile/House/Components/*/Components/Door/Components/Window"
    # Adds door-window

    elements.each(x_path) do |window|
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

    ### Support for door sto be added.
    ##x_path = "HouseFile/House/Components/*/Components/Door"

    ##elements.each(x_path) do |door|
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
    #x_path = "HouseFile/House/Components/Wall"
    #elements.each(x_path) do |wall|
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

    #x_path = "HouseFile/House/Components/*/Components/FloorHeader"
    #elements.each(x_path) do |head|
    #  areaHeader_temp = 0.0
    #  areaHeader_temp = head.elements["Measurements"].attributes["height"].to_f * head.elements["Measurements"].attributes["perimeter"].to_f
    #  $UAValue["header"] += areaHeader_temp / head.elements["Construction"].elements["Type"].attributes["rValue"].to_f
    #  $AreaComp["header"] += areaHeader_temp
    #end

    #x_path = "HouseFile/House/Components/Ceiling"
    #elements.each(x_path) do |ceiling|
    #  areaCeiling_temp = 0.0
    #  areaCeiling_temp = ceiling.elements["Measurements"].attributes["area"].to_f
    #  $UAValue["ceiling"] += areaCeiling_temp / ceiling.elements["Construction"].elements["CeilingType"].attributes["rValue"].to_f
    #  $AreaComp["ceiling"] += areaCeiling_temp
    #end

    #x_path = "HouseFile/House/Components/Floor"
    #elements.each(x_path) do |floor|
    #  areaFloor_temp = 0.0
    #  areaFloor_temp = floor.elements["Measurements"].attributes["area"].to_f
    #  $UAValue["floor"] += areaFloor_temp / floor.elements["Construction"].elements["Type"].attributes["rValue"].to_f
    #  $AreaComp["floor"] += areaFloor_temp
    #end


    # ====================================================================================
    # ====================================================================================
    # ====================================================================================
    # Calculate area-weighted U-value of the envelope START Sara
    #TODO: Add air film to each U-value
    #TODO: IMPORTANT Question: the below calculation gives area-weighted U-value of proposed house?
    # Note: All r-values in HOT2000 have been considered as rsi.
    # Procedure:
    # 1. Ceiling
    # 2. Wall: 2.1. Window, 2.2. Door, 2.3. FloorHeader
    # 3. Basement: 3.1. Floor, 3.2. Wall, 3.3. Door, 3.4. Windows, 3.5. FloorHeader
    # 4. Crawlspace: 4.1. Floor, 4.2. Wall, 4.3. Door, 4.4. Windows, 4.5. FloorHeader
    # 5. Walkout: 4.1. Floor, 4.2. Wall, 4.3. Door, 4.4. Windows, 4.5. FloorHeader
    # 6. Slab: 6.1. Floor, 6.2. Wall

    ##### Set initial values
    envelope_area = 0.0
    envelope_uavalue = 0.0
    # ------------------------------------------------------------------------------------
    ##### 1. Ceiling
    debug_on
    ceiling_path = "HouseFile/House/Components/Ceiling"
    elements.each(ceiling_path) do |ceiling|
        ceiling_area = 0.0
        ceiling_area = ceiling.elements["Measurements"].attributes["area"].to_f
        ceiling_rvalue = ceiling.elements["Construction"].elements["CeilingType"].attributes["rValue"].to_f
        ceiling_uavalue = ceiling_area / ceiling_rvalue
        envelope_area += ceiling_area
        envelope_uavalue += ceiling_uavalue    
        debug_out "ceiling_area is #{ceiling_area}"
        debug_out "ceiling_rvalue is #{ceiling_rvalue}"
        debug_out "ceiling_uavalue is #{ceiling_uavalue}"
        debug_out "envelope_uavalue is #{envelope_uavalue}"
    end
    # ------------------------------------------------------------------------------------
    ##### 2. Wall
    wall_path = "HouseFile/House/Components/Wall"
    elements.each(wall_path) do |wall|
        idWall = wall.attributes["id"].to_i
        debug_out "idWall is #{idWall}"
        wall_area_gross = 0.0
        wall_area_net = 0.0
        wall_height = wall.elements["Measurements"].attributes["height"].to_f
        wall_perimeter = wall.elements["Measurements"].attributes["perimeter"].to_f
        wall_width = wall_perimeter / 2.0 - wall_height
        wall_area_gross = wall_width * wall_height
        wall_area_net = wall_area_gross
        wall_rvalue = wall.elements["Construction"].elements["Type"].attributes["rValue"].to_f
        envelope_area += wall_area_gross
        debug_out "wall_height is #{wall_height}"
        debug_out "wall_width is #{wall_width}"
        debug_out "wall_area_gross is #{wall_area_gross}"
        debug_out "wall_rvalue is #{wall_rvalue}"

        # ------------------------------------------------------------------------------------
        # 2.1. Wall: Window
        # Note: 'headerHeight' (e.g. see ERS-1001) has not been considered in window calculation.
        wall_window_path = wall_path + "/Components/Window"
        elements.each(wall_window_path) do |window|
            debug_out "idWindow is #{window.parent.parent.attributes["id"].to_i}"
            if (window.parent.parent.attributes["id"].to_i == idWall)
                window_area = 0.0
                # [Height (mm) * Width (mm)] * No of Windows
                window_area = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f) * window.attributes["number"].to_i / 1000000
                window_rvalue = window.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                window_uavalue = window_area / window_rvalue
                wall_area_net -= window_area
                envelope_uavalue += window_uavalue
                debug_out "window_area is #{window_area}"
                debug_out "window_rvalue is #{window_rvalue}"
                debug_out "window_uavalue is #{window_uavalue}"
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(wall_window_path) do |window|
        # ------------------------------------------------------------------------------------
        # 2.2. Wall: Door
        wall_door_path = wall_path+"/Components/Door"
        elements.each(wall_door_path) do |door|
            idDoor = door.attributes["id"].to_i
            debug_out "idDoor is #{idDoor}"
            if (door.parent.parent.attributes["id"].to_i == idWall)
                # Door (the whole door)
                door_area_gross = 0.0
                door_area_net = 0.0
                door_area_gross = (door.elements["Measurements"].attributes["height"].to_f * door.elements["Measurements"].attributes["width"].to_f)
                door_area_net = door_area_gross
                door_rvalue = door.attributes["rValue"].to_f
                wall_area_net -= door_area_gross
                debug_out "door_area_gross is #{door_area_gross}"
                debug_out "door_rvalue is #{door_rvalue}"

                # Door: Window  #Note: 'headerHeight' (e.g. see ERS-1001) has not been considered in door's window calculation.
                door_window_path = wall_door_path + "/Components/Window"
                elements.each(door_window_path) do |window|
                    debug_out "idWindow is #{window.parent.parent.attributes["id"].to_i}"
                    if (window.parent.parent.attributes["id"].to_i == idDoor)
                        window_area = 0.0
                        # [Height (mm) * Width (mm)] * No of Windows
                        window_area = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f) * window.attributes["number"].to_i / 1000000
                        window_rvalue = window.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                        window_uavalue = window_area / window_rvalue
                        door_area_net -= window_area
                        envelope_uavalue += window_uavalue
                        debug_out "window_area is #{window_area}"
                        debug_out "window_rvalue is #{window_rvalue}"
                        debug_out "window_uavalue is #{window_uavalue}"
                        debug_out "envelope_uavalue is #{envelope_uavalue}"
                    end
                end #elements.each(door_window_path) do |window|

                # calculate UA-Value of door_area_net (i.e. excluding windows)
                door_uavalue = door_area_net / door_rvalue
                debug_out "door_uavalue is #{door_uavalue}"
                envelope_uavalue += door_uavalue
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(wall_door_path) do |door|
        # ------------------------------------------------------------------------------------
        # 2.3. Wall: FloorHeader (e.g. ERS-1022)
        wall_floorheader_path = wall_path + "/Components/FloorHeader"
        elements.each(wall_floorheader_path) do |floorheader|
            debug_out "idFloorHeader is #{floorheader.parent.parent.attributes["id"].to_i}"
            if (floorheader.parent.parent.attributes["id"].to_i == idWall)
                floorheader_area = 0.0
                floorheader_height = floorheader.elements["Measurements"].attributes["height"].to_f
                floorheader_perimeter = floorheader.elements["Measurements"].attributes["perimeter"].to_f
                floorheader_width = floorheader_perimeter / 2.0 - floorheader_height
                floorheader_area = floorheader_width * floorheader_height
                floorheader_rvalue = floorheader.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                floorheader_uavalue = floorheader_area / floorheader_rvalue
                envelope_area += floorheader_area #Note: HOT2000 considers floorheader as a separate componenet. In other words, its area is not part of walls (gross wall area).
                envelope_uavalue += floorheader_uavalue
                debug_out "floorheader_area is #{floorheader_area}"
                debug_out "floorheader_rvalue is #{floorheader_rvalue}"
                debug_out "floorheader_uavalue is #{floorheader_uavalue}"
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(wall_floorheader_path) do |floorheader|

        # ------------------------------------------------------------------------------------
        # calculate UA-Value of wall_area_net (i.e. excluding doors and windows)
        wall_uavalue = wall_area_net / wall_rvalue
        envelope_uavalue += wall_uavalue
        debug_out "wall_area_gross is #{wall_area_gross}"
        debug_out "wall_area_net is #{wall_area_net}"
        debug_out "wall_uavalue is #{wall_uavalue}"
        debug_out "envelope_uavalue is #{envelope_uavalue}"

    end #elements.each(wall_path) do |wall|

    # ------------------------------------------------------------------------------------
    ##### 3. Basement
    basement_path = "HouseFile/House/Components/Basement"
    elements.each(basement_path) do |basement|
        idBasement = basement.attributes["id"].to_i
        debug_out "idBasement is #{idBasement}"
        # ------------------------------------------------------------------------------------
        # 3.1. Basement: Floor (e.g. ERS-1001)
        # Note: It has been assumed that each basement has only one floor.
        # This assumption is important as basement_floor_perimeter is used for the calculation of basement's wall area.
        basement_floor_perimeter = 0.0
        basement_floor_path = basement_path + "/Floor"
        elements.each(basement_floor_path) do |floor|
            if (floor.parent.attributes["id"].to_i == idBasement)
                basement_floor_perimeter = floor.elements["Measurements"].attributes["perimeter"].to_f
                basement_floor_area = 0.0
                basement_floor_area = floor.elements["Measurements"].attributes["area"].to_f
                if !floor.elements["Construction"].elements["AddedToSlab"].nil?
                    basement_floor_rvalue = floor.elements["Construction"].elements["FloorsAbove"].attributes["rValue"].to_f + floor.elements["Construction"].elements["AddedToSlab"].attributes["rValue"].to_f
                else
                    basement_floor_rvalue = floor.elements["Construction"].elements["FloorsAbove"].attributes["rValue"].to_f
                end
                basement_floor_uavalue = basement_floor_area / basement_floor_rvalue
                envelope_area += basement_floor_area
                envelope_uavalue += basement_floor_uavalue
                debug_out "basement_floor_area is #{basement_floor_area}"
                debug_out "basement_floor_rvalue is #{basement_floor_rvalue}"
                debug_out "basement_floor_uavalue is #{basement_floor_uavalue}"
                debug_out "envelope_area is #{envelope_area}"
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(basement_floor_path) do |floor|
        # ------------------------------------------------------------------------------------
        # 3.2. Basement: Wall (e.g. ERS-1001, ERS-1552)
        # TODO Question Note: 'ponyWallHeight' (e.g. see ERS-1552) has been considered in the basement's wall area calculation
        # Note: It has been assumed that basements have only one wall object in .h2k file.
        # This assumption is important as basement_wall_area_net and basement_wall_rvalue are used for the calculation of basement's ua value of the net wall area.
        debug_out "basement_floor_perimeter is #{basement_floor_perimeter}"
        basement_wall_area_gross = 0.0
        basement_wall_area_net = 0.0
        basement_wall_rvalue = 0.0
        basement_wall_path = basement_path + "/Wall"
        elements.each(basement_wall_path) do |wall|
            idBasementWall = wall.parent.attributes["id"].to_i
            debug_out "idBasement is #{idBasement}"
            debug_out "idBasementWall is #{idBasementWall}"
            if (idBasementWall == idBasement)
                basement_hasPonyWall = wall.attributes["hasPonyWall"]
                debug_out "basement_hasPonyWall is #{basement_hasPonyWall}"
                # Reference for RSI of concrete basement wall: ASHRAE Handbook - Fundamentals (SI Edition) > CHAPTER 27 HEAT, AIR, AND MOISTURE CONTROL IN BUILDING ASSEMBLIES—EXAMPLES
                # As per above reference: 'A U-factor of 5.7 W/(m2·K) is sometimes used for concrete basement floors on the ground.
                # For basement walls below grade, the temperature difference for winter design conditions is greater than for the floor.
                # Test results indicate that, at the mid-height of the below-grade portion of the basement wall, the unit area heat loss is approximately twice that of the floor.'
                if basement_hasPonyWall == 'false' #(e.g. ERS-1001)
                    basement_wall_area_gross = wall.elements["Measurements"].attributes["height"].to_f * basement_floor_perimeter
                    basement_wall_area_net = basement_wall_area_gross
                    basement_wall_rvalue = wall.elements["Construction"].elements["InteriorAddedInsulation"].elements["Composite"].elements["Section"].attributes["rsi"].to_f
                    if basement_wall_rvalue == 0.0
                        basement_wall_rvalue = 1.0/(2.0*5.7) # Reference: See above ASHRAE reference for RSI of concrete basement wall TODO: see updated values
                    end
                    envelope_area += basement_wall_area_gross
                    debug_out "basement_wall_area_gross is #{basement_wall_area_gross}"
                    debug_out "basement_wall_rvalue is #{basement_wall_rvalue}"
                    debug_out "envelope_area is #{envelope_area}"
                else #(i.e. if basement has hasPonyWall) (e.g. ERS-1552)
                    # basement's whole walls
                    basement_wall_area_gross = wall.elements["Measurements"].attributes["height"].to_f * basement_floor_perimeter
                    basement_wall_area_net = basement_wall_area_gross
                    basement_wall_rvalue = wall.elements["Construction"].elements["InteriorAddedInsulation"].elements["Composite"].elements["Section"].attributes["rsi"].to_f
                    if basement_wall_rvalue == 0.0
                        basement_wall_rvalue = 1.0/(2.0*5.7) # Reference: See above ASHRAE reference for RSI of concrete basement wall   TODO: see updated values
                    end
                    envelope_area += basement_wall_area_gross
                    debug_out "basement_wall_area_gross is #{basement_wall_area_gross}"
                    debug_out "basement_wall_area_net is #{basement_wall_area_net}"
                    debug_out "basement_wall_rvalue is #{basement_wall_rvalue}"
                    debug_out "envelope_area is #{envelope_area}"
                    debug_out "envelope_uavalue is #{envelope_uavalue}"

                    # basement's pony walls  #TODO Question: I have assumed pony wall is an extra wall in the interior part of the basement's wall. So, I have not added its area to 'envelope_area' as it has already been considered in 'envelope_area' (see a few lines above)
                    #TODO Question: It has been assumed that ponywall does not have any doors/windows. OK?
                    #TODO Question: ERS-1603 has two ponywall's section in h2k file. what should be done in these cases?
                    basement_ponywall_area = 0.0
                    basement_ponywall_area = wall.elements["Measurements"].attributes["ponyWallHeight"].to_f * basement_floor_perimeter
                    basement_ponywall_rvalue = wall.elements["Construction"].elements["PonyWallType"].elements["Composite"].elements["Section"].attributes["rsi"].to_f
                    basement_ponywall_uavalue = basement_ponywall_area / basement_ponywall_rvalue
                    envelope_uavalue += basement_ponywall_uavalue
                    debug_out "basement_ponywall_area is #{basement_ponywall_area}"
                    debug_out "basement_ponywall_rvalue is #{basement_ponywall_rvalue}"
                    debug_out "basement_ponywall_uavalue is #{basement_ponywall_uavalue}"
                    debug_out "envelope_area is #{envelope_area}"
                    debug_out "envelope_uavalue is #{envelope_uavalue}"
                end
                # ------------------------------------------------------------------------------------
            end #if (wall.parent.parent.attributes["id"].to_i == idBasement)
        end #elements.each(basement_wall_path) do |wall|
        # ------------------------------------------------------------------------------------
        # 3.3. Basement: Door (e.g. ERS-1603)
        basement_door_path = basement_path+"/Components/Door"
        elements.each(basement_door_path) do |door|
            idDoor = door.attributes["id"].to_i
            debug_out "idDoor is #{idDoor}"
            if (door.parent.parent.attributes["id"].to_i == idBasement)
                # Door (the whole door)
                door_area_gross = 0.0
                door_area_net = 0.0
                door_area_gross = (door.elements["Measurements"].attributes["height"].to_f * door.elements["Measurements"].attributes["width"].to_f)
                door_area_net = door_area_gross
                door_rvalue = door.attributes["rValue"].to_f
                basement_wall_area_net -= door_area_gross
                debug_out "door_area_gross is #{door_area_gross}"
                debug_out "door_rvalue is #{door_rvalue}"

                # Door: Window  #Note: 'headerHeight' (e.g. see ERS-1001) has not been considered in door's window calculation.
                door_window_path = basement_door_path + "/Components/Window"
                elements.each(door_window_path) do |window|
                    debug_out "idWindow is #{window.parent.parent.attributes["id"].to_i}"
                    if (window.parent.parent.attributes["id"].to_i == idDoor)
                        window_area = 0.0
                        # [Height (mm) * Width (mm)] * No of Windows
                        window_area = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f) * window.attributes["number"].to_i / 1000000
                        window_rvalue = window.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                        window_uavalue = window_area / window_rvalue
                        door_area_net -= window_area
                        envelope_uavalue += window_uavalue
                        debug_out "window_area is #{window_area}"
                        debug_out "window_rvalue is #{window_rvalue}"
                        debug_out "window_uavalue is #{window_uavalue}"
                        debug_out "envelope_area is #{envelope_area}"
                        debug_out "envelope_uavalue is #{envelope_uavalue}"
                    end
                end #elements.each(door_window_path) do |window|

                # calculate UA-Value of door_area_net (i.e. excluding windows)
                door_uavalue = door_area_net / door_rvalue
                debug_out "door_uavalue is #{door_uavalue}"
                envelope_uavalue += door_uavalue
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(basement_door_path) do |door|
        # ------------------------------------------------------------------------------------
        # 3.4. Basement: Window (e.g. ERS-1603)
        basement_window_path = basement_path + "/Components/Window"
        elements.each(basement_window_path) do |window|
            debug_out "idWindow is #{window.parent.parent.attributes["id"].to_i}"
            if (window.parent.parent.attributes["id"].to_i == idBasement)
                window_area = 0.0
                # [Height (mm) * Width (mm)] * No of Windows
                window_area = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f) * window.attributes["number"].to_i / 1000000
                window_rvalue = window.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                window_uavalue = window_area / window_rvalue
                basement_wall_area_net -= window_area
                envelope_uavalue += window_uavalue
                debug_out "window_area is #{window_area}"
                debug_out "window_rvalue is #{window_rvalue}"
                debug_out "window_uavalue is #{window_uavalue}"
                debug_out "envelope_area is #{envelope_area}"
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(basement_window_path) do |window|
        # ------------------------------------------------------------------------------------
        # Now calculate UA-Value of basement's wall_area_net (i.e. excluding doors and windows)
        basement_wall_uavalue = basement_wall_area_net / basement_wall_rvalue
        envelope_uavalue += basement_wall_uavalue
        debug_out "basement_wall_area_gross is #{basement_wall_area_gross}"
        debug_out "basement_wall_area_net is #{basement_wall_area_net}"
        debug_out "basement_wall_uavalue is #{basement_wall_uavalue}"
        debug_out "envelope_area is #{envelope_area}"
        debug_out "envelope_uavalue is #{envelope_uavalue}"
        # ------------------------------------------------------------------------------------
        # 3.5. Basement: FloorHeader (e.g. ERS-1603)
        basement_floorheader_path = basement_path + "/Components/FloorHeader"
        elements.each(basement_floorheader_path) do |floorheader|
            if (floorheader.parent.parent.attributes["id"].to_i == idBasement)
                basement_floorheader_area = 0.0
                basement_floorheader_height = floorheader.elements["Measurements"].attributes["height"].to_f
                basement_floorheader_perimeter = floorheader.elements["Measurements"].attributes["perimeter"].to_f
                basement_floorheader_width = basement_floorheader_perimeter / 2.0 - basement_floorheader_height
                basement_floorheader_area = basement_floorheader_width * basement_floorheader_height
                basement_floorheader_rvalue = floorheader.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                basement_floorheader_uavalue = basement_floorheader_area / basement_floorheader_rvalue
                envelope_area += basement_floorheader_area #Note: HOT2000 considers floorheader as a separate componenet. In other words, its area is not part of walls (gross wall area).
                envelope_uavalue += basement_floorheader_uavalue
                debug_out "basement_floorheader_area is #{basement_floorheader_area}"
                debug_out "basement_floorheader_rvalue is #{basement_floorheader_rvalue}"
                debug_out "basement_floorheader_uavalue is #{basement_floorheader_uavalue}"
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end
        # ------------------------------------------------------------------------------------
    end #elements.each(basement_path) do |basement|

    # ------------------------------------------------------------------------------------
    # 4. Crawlspace (e.g. ERS-1022, ERS-1658, ERS-8020)
    # Note: It has been assumed that each crawlspace has only one floor.
    # This assumption is important as crawlspace_floor_perimeter is used for the calculation of crawlspace's wall area.
    crawlspace_path = "HouseFile/House/Components/Crawlspace"
    elements.each(crawlspace_path) do |crawlspace|
        idCrawlspace = crawlspace.attributes["id"].to_i
        debug_out "idCrawlspace is #{idCrawlspace}"
        crawlspace_type_code = crawlspace.elements["VentilationType"].attributes["code"]
        if crawlspace_type_code=='2'
            crawlspace_type = 'open'
        elsif crawlspace_type_code=='3'
            crawlspace_type = 'closed'
        end
        debug_out "crawlspace_type_code is #{crawlspace_type_code}"
        debug_out "crawlspace_type is #{crawlspace_type}"
        # ------------------------------------------------------------------------------------
        if crawlspace_type=='closed'
            # ------------------------------------------------------------------------------------
            # 4.1. Crawlspace: Floor (e.g. ERS-1022, ERS-1658, ERS-8020)
            crawlspace_floor_path = crawlspace_path + "/Floor"
            crawlspace_floor_perimeter = 0.0
            elements.each(crawlspace_floor_path) do |floor|
                if (floor.parent.attributes["id"].to_i == idCrawlspace)
                    crawlspace_floor_perimeter = floor.elements["Measurements"].attributes["perimeter"].to_f
                    crawlspace_floor_area = 0.0
                    crawlspace_floor_area = floor.elements["Measurements"].attributes["area"].to_f
                    if !floor.elements["Construction"].elements["AddedToSlab"].nil?
                        crawlspace_floor_rvalue = floor.elements["Construction"].elements["FloorsAbove"].attributes["rValue"].to_f + floor.elements["Construction"].elements["AddedToSlab"].attributes["rValue"].to_f
                    else
                        crawlspace_floor_rvalue = floor.elements["Construction"].elements["FloorsAbove"].attributes["rValue"].to_f
                    end
                    crawlspace_floor_uavalue = crawlspace_floor_area / crawlspace_floor_rvalue
                    envelope_area += crawlspace_floor_area
                    envelope_uavalue += crawlspace_floor_uavalue
                    debug_out "crawlspace_floor_area is #{crawlspace_floor_area}"
                    debug_out "crawlspace_floor_rvalue is #{crawlspace_floor_rvalue}"
                    debug_out "crawlspace_floor_uavalue is #{crawlspace_floor_uavalue}"
                    debug_out "envelope_area is #{envelope_area}"
                    debug_out "envelope_uavalue is #{envelope_uavalue}"
                end
            end
            # ------------------------------------------------------------------------------------
            # 4.2. Crawlspace: Wall
            # Note: It has been assumed that crawlspace's wall does not have any ponyWall.
            crawlspace_wall_area_gross = 0.0
            crawlspace_wall_area_net = 0.0
            crawlspace_wall_rvalue = 0.0
            crawlspace_wall_path = crawlspace_path + "/Wall"
            debug_out "crawlspace_floor_perimeter is #{crawlspace_floor_perimeter}"
            elements.each(crawlspace_wall_path) do |wall|
                if (wall.parent.attributes["id"].to_i == idCrawlspace)
                    crawlspace_wall_area_gross = wall.elements["Measurements"].attributes["height"].to_f * crawlspace_floor_perimeter  #Note: It has been assumed that crawlspace has only one floor.
                    crawlspace_wall_area_net = crawlspace_wall_area_gross
                    crawlspace_wall_rvalue = wall.elements["Construction"].elements["Type"].elements["Composite"].elements["Section"].attributes["rsi"].to_f
                    envelope_area += crawlspace_wall_area_gross
                    debug_out "crawlspace_wall_area_gross is #{crawlspace_wall_area_gross}"
                    debug_out "crawlspace_wall_area_net is #{crawlspace_wall_area_net}"
                    debug_out "crawlspace_wall_rvalue is #{crawlspace_wall_rvalue}"
                    debug_out "envelope_area is #{envelope_area}"
                    debug_out "envelope_uavalue is #{envelope_uavalue}"
                end
            end
            # ------------------------------------------------------------------------------------
            # 4.3. Crawlspace: Door (e.g. no ERS)
            crawlspace_door_path = crawlspace_path+"/Components/Door"
            elements.each(crawlspace_door_path) do |door|
                idDoor = door.attributes["id"].to_i
                debug_out "idDoor is #{idDoor}"
                if (door.parent.parent.attributes["id"].to_i == idCrawlspace)
                    # Door (the whole door)
                    door_area_gross = 0.0
                    door_area_net = 0.0
                    door_area_gross = (door.elements["Measurements"].attributes["height"].to_f * door.elements["Measurements"].attributes["width"].to_f)
                    door_area_net = door_area_gross
                    door_rvalue = door.attributes["rValue"].to_f
                    crawlspace_wall_area_net -= door_area_gross
                    debug_out "door_area_gross is #{door_area_gross}"
                    debug_out "door_rvalue is #{door_rvalue}"

                    # Door: Window  #Note: 'headerHeight' (e.g. see ERS-1001) has not been considered in door's window calculation.
                    door_window_path = crawlspace_door_path + "/Components/Window"
                    elements.each(door_window_path) do |window|
                        debug_out "idWindow is #{window.parent.parent.attributes["id"].to_i}"
                        if (window.parent.parent.attributes["id"].to_i == idDoor)
                            window_area = 0.0
                            # [Height (mm) * Width (mm)] * No of Windows
                            window_area = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f) * window.attributes["number"].to_i / 1000000
                            window_rvalue = window.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                            window_uavalue = window_area / window_rvalue
                            door_area_net -= window_area
                            envelope_uavalue += window_uavalue
                            debug_out "window_area is #{window_area}"
                            debug_out "window_rvalue is #{window_rvalue}"
                            debug_out "window_uavalue is #{window_uavalue}"
                            debug_out "envelope_area is #{envelope_area}"
                            debug_out "envelope_uavalue is #{envelope_uavalue}"
                        end
                    end #elements.each(door_window_path) do |window|

                    # calculate UA-Value of door_area_net (i.e. excluding windows)
                    door_uavalue = door_area_net / door_rvalue
                    debug_out "door_area_net is #{door_area_net}"
                    debug_out "door_uavalue is #{door_uavalue}"
                    envelope_uavalue += door_uavalue
                    debug_out "envelope_uavalue is #{envelope_uavalue}"
                end
            end #elements.each(crawlspace_door_path) do |door|
            # ------------------------------------------------------------------------------------
            # 4.4. Crawlspace: Window (e.g. no ERS)
            crawlspace_window_path = crawlspace_path + "/Components/Window"
            elements.each(crawlspace_window_path) do |window|
                debug_out "idWindow is #{window.parent.parent.attributes["id"].to_i}"
                if (window.parent.parent.attributes["id"].to_i == idCrawlspace)
                    window_area = 0.0
                    # [Height (mm) * Width (mm)] * No of Windows
                    window_area = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f) * window.attributes["number"].to_i / 1000000
                    window_rvalue = window.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                    window_uavalue = window_area / window_rvalue
                    crawlspace_wall_area_net -= window_area
                    envelope_uavalue += window_uavalue
                    debug_out "window_area is #{window_area}"
                    debug_out "window_rvalue is #{window_rvalue}"
                    debug_out "window_uavalue is #{window_uavalue}"
                    debug_out "envelope_area is #{envelope_area}"
                    debug_out "envelope_uavalue is #{envelope_uavalue}"
                end
            end #elements.each(crawlspace_window_path) do |window|

            # ------------------------------------------------------------------------------------
            # Now calculate UA-Value of crawlspace's wall_area_net (i.e. excluding doors and windows)
            crawlspace_wall_uavalue = crawlspace_wall_area_net / crawlspace_wall_rvalue
            envelope_uavalue += crawlspace_wall_uavalue
            debug_out "crawlspace_wall_area_gross is #{crawlspace_wall_area_gross}"
            debug_out "crawlspace_wall_area_net is #{crawlspace_wall_area_net}"
            debug_out "crawlspace_wall_uavalue is #{crawlspace_wall_uavalue}"
            debug_out "envelope_area is #{envelope_area}"
            debug_out "envelope_uavalue is #{envelope_uavalue}"
            # ------------------------------------------------------------------------------------
            # 4.5. Crawlspace: FloorHeader (e.g. ERS-1022)
            crawlspace_floorheader_path = crawlspace_path + "/Components/FloorHeader"
            elements.each(crawlspace_floorheader_path) do |floorheader|
                if (floorheader.parent.parent.attributes["id"].to_i == idCrawlspace)
                    crawlspace_floorheader_area = 0.0
                    crawlspace_floorheader_height = floorheader.elements["Measurements"].attributes["height"].to_f
                    crawlspace_floorheader_perimeter = floorheader.elements["Measurements"].attributes["perimeter"].to_f
                    crawlspace_floorheader_width = crawlspace_floorheader_perimeter / 2.0 - crawlspace_floorheader_height
                    crawlspace_floorheader_area = crawlspace_floorheader_width * crawlspace_floorheader_height
                    crawlspace_floorheader_rvalue = floorheader.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                    crawlspace_floorheader_uavalue = crawlspace_floorheader_area / crawlspace_floorheader_rvalue
                    envelope_area += crawlspace_floorheader_area #Note: HOT2000 considers floorheader as a separate componenet. In other words, its area is not part of walls (gross wall area).
                    envelope_uavalue += crawlspace_floorheader_uavalue
                    debug_out "crawlspace_floorheader_area is #{crawlspace_floorheader_area}"
                    debug_out "crawlspace_floorheader_rvalue is #{crawlspace_floorheader_rvalue}"
                    debug_out "crawlspace_floorheader_uavalue is #{crawlspace_floorheader_uavalue}"
                    debug_out "envelope_uavalue is #{envelope_uavalue}"
                end
            end
        end #if crawlspace_type=='closed'
    end
    # ------------------------------------------------------------------------------------
    # 5. Walkout (e.g. ERS-1727, ERS-4523, ERS-4540)
    walkout_path = "HouseFile/House/Components/Walkout"
    elements.each(walkout_path) do |walkout|
        idWalkout = walkout.attributes["id"].to_i
        debug_out "idWalkout is #{idWalkout}"
        # ------------------------------------------------------------------------------------
        # 5.1. Walkout: Floor
        walkout_floor_path = walkout_path+"/Floor"
        elements.each(walkout_floor_path) do |floor|
            debug_out "walkout_floor_id #{floor.parent.attributes["id"].to_i}"
            if (floor.parent.attributes["id"].to_i == idWalkout)
                walkout_floor_area = 0.0
                walkout_floor_area = walkout.elements["Measurements"].attributes["l1"].to_f * walkout.elements["Measurements"].attributes["l2"].to_f
                debug_out "walkout_floor_area is #{walkout_floor_area}"
                # Reference for RSI of concrete basement floors on the ground: ASHRAE Handbook - Fundamentals (SI Edition) > CHAPTER 27 HEAT, AIR, AND MOISTURE CONTROL IN BUILDING ASSEMBLIES—EXAMPLES
                # As per above reference: 'A U-factor of 5.7 W/(m2·K) is sometimes used for concrete basement floors on the ground.'
                if !floor.elements["Construction"].elements["AddedToSlab"].nil?
                    #TODO Question: Why concrete slab floor is added to the rest here, but not the same calculation method for walkout
                    walkout_floor_rvalue =  1.0/5.7 + floor.elements["Construction"].elements["FloorsAbove"].attributes["rValue"].to_f + floor.elements["Construction"].elements["AddedToSlab"].attributes["rValue"].to_f
                else
                    walkout_floor_rvalue =  1.0/5.7 + floor.elements["Construction"].elements["FloorsAbove"].attributes["rValue"].to_f
                end
                walkout_floor_uavalue = walkout_floor_area / walkout_floor_rvalue
                envelope_area += walkout_floor_area
                envelope_uavalue += walkout_floor_uavalue
#                 debug_out "walkout_floor_area is #{walkout_floor_area}"
                debug_out "walkout_floor_rvalue is #{walkout_floor_rvalue}"
                debug_out "walkout_floor_uavalue is #{walkout_floor_uavalue}"
                debug_out "envelope_area is #{envelope_area}"
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(walkout_floor_path) do |floor|
        # ------------------------------------------------------------------------------------
        # 5.2. Walkout: Wall
        # Note: it has been assumed that walkouts have only one wall object in HOT2000 files.
        # This assumption is important as walkout_wall_area_net and associated UA-value are calculated later on after all other things (doors, windows) are calculated for the walkout.
        walkout_wall_path = walkout_path+"/Wall"
        walkout_wall_area_net = 0.0
        walkout_wall_rvalue = 0.0
        elements.each(walkout_wall_path) do |wall|
            if (wall.parent.attributes["id"].to_i == idWalkout)
                walkout_wall_area_gross = 0.0
                walkout_wall_area_gross = 2 * walkout.elements["Measurements"].attributes["height"].to_f * (walkout.elements["Measurements"].attributes["l1"].to_f + walkout.elements["Measurements"].attributes["l2"].to_f)
                walkout_wall_area_net = walkout_wall_area_gross
                if ( ! wall.elements["Construction"].elements["InteriorAddedInsulation"].nil? )
                    #TODO: Question I added 1.0/(2.0*5.7) into walkout_wall_rvalue_interior here as well
                    walkout_wall_rvalue_interior = 1.0/(2.0*5.7) + wall.elements["Construction"].elements["InteriorAddedInsulation"].elements["Composite"].elements["Section"].attributes["rsi"].to_f
                else
                    # Reference for RSI of concrete basement wall: ASHRAE Handbook - Fundamentals (SI Edition) > CHAPTER 27 HEAT, AIR, AND MOISTURE CONTROL IN BUILDING ASSEMBLIES—EXAMPLES
                    # As per above reference: 'A U-factor of 5.7 W/(m2·K) is sometimes used for concrete basement floors on the ground.
                    # For basement walls below grade, the temperature difference for winter design conditions is greater than for the floor.
                    # Test results indicate that, at the mid-height of the below-grade portion of the basement wall, the unit area heat loss is approximately twice that of the floor.'
                    walkout_wall_rvalue_interior = 1.0/(2.0*5.7) # 0.16 # ASHRAE appoximation
                end 
                if ( ! wall.elements["Construction"].elements["ExteriorAddedInsulation"].nil? )
                    #TODO: Question I added 0.08 into walkout_wall_rvalue_exterior here as well; although shouldn't '0.08' be replaced by 1.0/(2.0*5.7)
                    walkout_wall_rvalue_exterior = 0.08 + wall.elements["Construction"].elements["ExteriorAddedInsulation"].elements["Composite"].elements["Section"].attributes["rsi"].to_f
                else 
                    walkout_wall_rvalue_exterior = 0.08 # ASHRAE appoximation # TODO: Question: shouldn't it be the same as walkout_wall_rvalue_interior when there is no insulation
                end 
                walkout_wall_rvalue = walkout_wall_rvalue_exterior + walkout_wall_rvalue_interior
                debug_out "walkout_wall_area_net is #{walkout_wall_area_net}"
                debug_out "walkout_wall_rvalue is #{walkout_wall_rvalue}"
                debug_out "envelope_area is #{envelope_area}"
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(walkout_wall_path) do |wall|
        # ------------------------------------------------------------------------------------
        # 5.3. Walkout: Door
        walkout_door_path = walkout_path+"/Components/Door"
        elements.each(walkout_door_path) do |door|
            idWalkoutDoor = door.attributes["id"].to_i
            debug_out "idWalkoutDoor is #{idWalkoutDoor}"
            debug_out "#{door.parent.parent.attributes["id"].to_i}"
            if (door.parent.parent.attributes["id"].to_i == idWalkout)

                # Door (the whole door)
                door_area_gross = 0.0
                door_area_net = 0.0
                door_area_gross = door.elements["Measurements"].attributes["height"].to_f * door.elements["Measurements"].attributes["width"].to_f
                door_area_net = door_area_gross
                door_rvalue = door.attributes["rValue"].to_f
                walkout_wall_area_net -= door_area_gross
                debug_out "walkout_wall_area_net is #{walkout_wall_area_net}"
                debug_out "door_area_gross is #{door_area_gross}"
                debug_out "door_rvalue is #{door_rvalue}"

                # Door: Window
                # Note: 'headerHeight' (e.g. see ERS-1001) has not been considered in window calculation.
                walkout_door_window_path = walkout_door_path+"/Components/Window"
                debug_out "walkout_door_window_path is #{walkout_door_window_path}"
                elements.each(walkout_door_window_path) do |window|
                    debug_out "window parent id is #{window.parent.parent.attributes["id"].to_i}"
                    debug_out "idWalkout is #{idWalkout}"
                    debug_out "idWalkoutDoor is #{idWalkoutDoor}"
                    if (window.parent.parent.attributes["id"].to_i == idWalkoutDoor)
                        window_area = 0.0
                        # [Height (mm) * Width (mm)] * No of Windows
                        window_area = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f) * window.attributes["number"].to_i / 1000000
                        window_rvalue = window.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                        window_uavalue = window_area / window_rvalue
                        door_area_net -= window_area
                        envelope_uavalue += window_uavalue
                        debug_out "window_area is #{window_area}"
                        debug_out "window_rvalue is #{window_rvalue}"
                        debug_out "window_uavalue is #{window_uavalue}"
                        debug_out "envelope_uavalue is #{envelope_uavalue}"
                    end
                end #elements.each(door_window_path) do |window|

                # calculate UA-Value of door_area_net (i.e. excluding windows)
                door_uavalue = door_area_net / door_rvalue
                debug_out "door_area_net is #{door_area_net}"
                debug_out "door_uavalue is #{door_uavalue}"
                envelope_area += door_area_gross
                envelope_uavalue += door_uavalue
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(walkout_door_path) do |door|
        # ------------------------------------------------------------------------------------
        # 5.4. Walkout: Window
        walkout_window_path = walkout_path+"/Components/Window"
        elements.each(walkout_window_path) do |window|
            if (window.parent.parent.attributes["id"].to_i == idWalkout)
                window_area = 0.0
                window_area = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f) * window.attributes["number"].to_i / 1000000
                window_rvalue = window.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                window_uavalue = window_area / window_rvalue
                walkout_wall_area_net -= window_area
                envelope_area += window_area
                envelope_uavalue += window_uavalue
                debug_out "window_area is #{window_area}"
                debug_out "window_rvalue is #{window_rvalue}"
                debug_out "window_uavalue is #{window_uavalue}"
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(wall_window_path) do |window|
        # ------------------------------------------------------------------------------------
        # 5.5. Walkout: FloorHeader
        walkout_floorheader_path = walkout_path+"/Components/FloorHeader"
        elements.each(walkout_floorheader_path) do |floorheader|
            if (floorheader.parent.parent.attributes["id"].to_i == idWalkout)
                floorheader_area = 0.0
                floorheader_height = floorheader.elements["Measurements"].attributes["height"].to_f
                floorheader_perimeter = floorheader.elements["Measurements"].attributes["perimeter"].to_f
                floorheader_width = floorheader_perimeter / 2.0 - floorheader_height
                floorheader_area = floorheader_width * floorheader_height
                floorheader_rvalue = floorheader.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                floorheader_uavalue = floorheader_area / floorheader_rvalue
                envelope_area += floorheader_area # Note: floorheader_area is added to 'envelope_area' as floorheader is a separate component
                envelope_uavalue += floorheader_uavalue
                debug_out "floorheader_area is #{floorheader_area}"
                debug_out "floorheader_rvalue is #{floorheader_rvalue}"
                debug_out "floorheader_uavalue is #{floorheader_uavalue}"
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end #elements.each(wall_window_path) do |window|
        # ------------------------------------------------------------------------------------
        # Now that walkout_wall_area_net has been calculated, calculate ua-value of the walkout's wall.
        walkout_wall_uavalue = walkout_wall_area_net / walkout_wall_rvalue
        envelope_area += walkout_wall_area_net
        envelope_uavalue += walkout_wall_uavalue
        debug_out "walkout_wall_area_net is #{walkout_wall_area_net}"
        debug_out "walkout_wall_rvalue is #{walkout_wall_rvalue}"
        debug_out "walkout_wall_uavalue is #{walkout_wall_uavalue}"
        debug_out "envelope_area is #{envelope_area}"
        debug_out "envelope_uavalue is #{envelope_uavalue}"
    end #elements.each(walkout_path) do |walkout|
    # ------------------------------------------------------------------------------------
    # 6. Slab: Floor (e.g. ERS-1690)
    slab_path = "HouseFile/House/Components/Slab"
    elements.each(slab_path) do |slab|
        idSlab = slab.attributes["id"].to_i
        debug_out "idSlab is #{idSlab}"
        # ------------------------------------------------------------------------------------
        # 6.1. Slab: Floor
        slab_floor_path = slab_path+"/Floor"
        elements.each(slab_floor_path) do |floor|
            idSlabFloorParent = floor.parent.attributes["id"].to_i
            debug_out "idSlabFloorParent is #{idSlabFloorParent}"
            if (floor.parent.attributes["id"].to_i == idSlab)
                slab_floor_area = 0.0
                debug_out ("#{floor.elements["Construction"].pretty_inspect}")
                slab_floor_area = floor.elements["Measurements"].attributes["area"].to_f
                if ( slab_floor_rvalue = floor.elements["Construction"].elements["AddedToSlab"].nil? )
                  # Uninsulated
                  # Reference for RSI of concrete basement floors on the ground: ASHRAE Handbook - Fundamentals (SI Edition) > CHAPTER 27 HEAT, AIR, AND MOISTURE CONTROL IN BUILDING ASSEMBLIES—EXAMPLES
                  # As per above reference: 'A U-factor of 5.7 W/(m2·K) is sometimes used for concrete basement floors on the ground.'
                  slab_floor_rvalue = 1.0/5.7 #0.08806 # ASHRAE appoximation (S.Gilani - confirm? TODO: see updated values)
                else 
                 # pp slab_floor_rvalue = floor.elements["Construction"].elements["AddedToSlab"]
                  slab_floor_rvalue = 1.0/5.7 + floor.elements["Construction"].elements["AddedToSlab"].attributes["rValue"].to_f #TODO Question: are there cases with 'FloorsAbove' insulation for slabs?
                end 
                slab_floor_uavalue = slab_floor_area / slab_floor_rvalue
                envelope_area += slab_floor_area
                envelope_uavalue += slab_floor_uavalue
                debug_out "slab_floor_area is #{slab_floor_area}"
                debug_out "slab_floor_rvalue is #{slab_floor_rvalue}"
                debug_out "slab_floor_uavalue is #{slab_floor_uavalue}"
                debug_out "envelope_area is #{envelope_area}"
                debug_out "envelope_uavalue is #{envelope_uavalue}"
            end
        end
        # ------------------------------------------------------------------------------------
        # 6.2. Slab: Wall #TODO Question: .h2k file does not have height of wall (see e.g. ERS-1690)
#         slab_wall_path = slab_path+"/Wall"
#         elements.each(slab_wall_path) do |wall|
#             idSlabWallParent = wall.parent.attributes["id"].to_i
#             debug_out "idSlab is #{idSlab}"
#             debug_out "idSlabWallParent is #{idSlabWallParent}"
#             if (idSlabWallParent == idSlab)
# #                 puts "Sara"
#             end
#         end
        # ------------------------------------------------------------------------------------
    end
    # ------------------------------------------------------------------------------------
    ##### Whole house's area-weighted U-value [W/(m2.K)]
    area_weighted_u = envelope_uavalue / envelope_area #W/(m2.K)
    env_info["envelope"]["envelope_area_m2"] = envelope_area
    env_info["envelope"]["areaWeightedUvalue_excl_Infiltration_W_per_m2K"] = area_weighted_u
    debug_out "envelope_area is #{envelope_area}"
    debug_out "envelope_uavalue is #{envelope_uavalue}"
    debug_out "area_weighted_u is #{area_weighted_u}"

    # ------------------------------------------------------------------------------------
    ##### Whole house's area-weighted U-value including infiltration [W/(m2.K)]
    # envelope metric [W/(m2.K)] = sum(Ui.Ai)/sum(Ai) + (NLR@75Pa) x (density of air at standard conditions) x (specific heat capacity of air at standard conditions)
    # Density of air at standard conditions= 1.204 kg/m3  (REF: https://en.wikipedia.org/wiki/Density_of_air)
    # Specific heat capacity of air at standard conditions = 1003.5 J/(kg.K)  (REF: https://en.wikipedia.org/wiki/Table_of_specific_heat_capacities)

    # 0. Air properties
    rho_air = 1.204
    cp_air = 1003.5

    # 1. Get ACH@50 from .h2k file
    ach_at_50Pa = H2KFile.getACHRate(elements) #TODO: Question: ok to use this for getting ACH?
    debug_out "ach_at_50Pa is #{ach_at_50Pa}"

    # 2. Convert ACH@50 to ACH@75 using Equation ACH@75 = ACH@50 / ((50/75)^0.6)
    # (REF: 'Acceptable Air Tightness of Walls in Passive Houses' @https://www.phius.org/sites/default/files/2022-04/201508-Airtightness-Karagiozis.pdf)
    # Note: flow exponent (n) has been set as 0.6 as per NECB2020 Section 8.4.2.9.
    ach_at_75Pa = ach_at_50Pa / ((50.0/75.0)**0.6)
    debug_out "ach_at_75Pa is #{ach_at_75Pa}"

    # 3. Convert ACH@75 to NLR@75
    # ACH x Volume x 3.6 / EnvelopeArea = NLR (L/s/m2)
    x_path = "HouseFile/House/NaturalAirInfiltration/Specifications/House"
    myHouseVolume = H2KFile.getHouseVolume(elements)
    house_volume = elements[x_path].attributes["volume"].to_f # m3
    debug_out "envelope_area is #{envelope_area}"
    nlr_at_75Pa = (ach_at_75Pa * myHouseVolume * 3.6) / envelope_area  # (L/s/m2)
    debug_out "house_volume is #{myHouseVolume}"
    debug_out "nlr_at_75Pa is #{nlr_at_75Pa}"

    # 4. Convert NLR@75 to NLR@typical operating pressure differential of 5Pa as per NECB2020 (REF: NECB2020 Section 8.4.2.9.)
    wallDimsAG = H2KFile.getAGWallDimensions(elements)
    wall_area_gross_abovegrade = wallDimsAG["area"]["gross"]
    debug_out "wallDimsAG is #{wallDimsAG}"
    debug_out "wall_area_gross_abovegrade is #{wall_area_gross_abovegrade}"
    nlr_at_typ_opr_p_diff = ((5.00 / 75.0) ** 0.60) * nlr_at_75Pa * envelope_area / wall_area_gross_abovegrade  # [L/(s.m2)] #TODO: Question: I have considered wall_area_gross_abovegrade for NECB's Equation (Section 8.4.2.9.)
    debug_out "nlr_at_typ_opr_p_diff is #{nlr_at_typ_opr_p_diff}"

    # 5. Calculate Whole house's area-weighted U-value including infiltration [W/(m2.K)]
    envelope_infiltration_W_per_m2k = nlr_at_typ_opr_p_diff * rho_air * cp_air * 0.001
    envelope_uavalue_incl_infiltration = area_weighted_u + envelope_infiltration_W_per_m2k
    env_info["envelope"]["areaWeightedUvalue_incl_Infiltration_W_per_m2K"] = envelope_uavalue_incl_infiltration
    debug_out "envelope_infiltration_W_per_m2k is #{envelope_infiltration_W_per_m2k}"
    debug_out "envelope_uavalue_incl_infiltration is #{envelope_uavalue_incl_infiltration}"

    debug_off
    # Calculate area-weighted U-value of the envelope END
    # ====================================================================================
    # ====================================================================================
    # ====================================================================================
    return env_info

  end
  # End of getEnvelopeSpecs

  # =========================================================================================
  # Return blower door test value 
  # =========================================================================================
  def H2KFile.getACHRate(elements)
    x_path = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
    ach_result = elements[x_path].attributes["airChangeRate"].to_f
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
    x_path = "HouseFile/House/Components/Floor"
    areaFloors = 0
    elements.each(x_path) do |floor|

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
    x_path = "HouseFile/House/Components/*/Components/FloorHeader"
    areaHeaders = 0
    areaHeadersAG = 0
    areaHeadersBG = 0
    elements.each(x_path) do |header|

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


    x_path = "HouseFile/House/Components/*/Components/Window"
    elements.each(x_path) do |window|

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
    x_path = "HouseFile/House/Components/Ceiling"
    elements.each(x_path) do |element|
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

  def H2KFile.heatedCrawlspace(h2kElements)
    isCrawlHeated = false


    if h2kElements["HouseFile/House/Components/Crawlspace"] != nil
      if h2kElements["HouseFile/House/Temperatures/Crawlspace"].attributes["heated"] =~ /true/
        isCrawlHeated = true
      end
    end

    return isCrawlHeated
  end

  # =========================================================================================
  # Get primary heating system type and fuel
  # =========================================================================================
  def H2KFile.getPrimaryHeatSys(elements)

    if elements["HouseFile/House/HeatingCooling/Type1/Baseboards"] != nil
      #sysType1 = "Baseboards"
      fuelName = "electricity"
    elsif elements["HouseFile/House/HeatingCooling/Type1/Furnace"] != nil
      #sysType1 = "Furnace"
      fuelName = elements["HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EnergySource/English"].text
    elsif elements["HouseFile/House/HeatingCooling/Type1/Boiler"] != nil
      #sysType1 = "Boiler"
      fuelName = elements["HouseFile/House/HeatingCooling/Type1/Boiler/Equipment/EnergySource/English"].text
    elsif elements["HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"] != nil
      #sysType1 = "Combo"
      fuelName = elements["HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment/EnergySource/English"].text
    elsif elements["HouseFile/House/HeatingCooling/Type1/P9"] != nil
      #sysType1 = "P9"
      fuelName = elements["HouseFile/House/HeatingCooling/Type1//TestData/EnergySource/English"].text
    end

    return fuelName
  end

  # =========================================================================================
  # Get secondary heating system type
  # =========================================================================================
  def H2KFile.getSecondaryHeatSys(elements)

    sysType2 = "NA"

    if elements["HouseFile/House/HeatingCooling/Type2/AirHeatPump"] != nil
      sysType2 = "AirHeatPump"
    elsif elements["HouseFile/House/HeatingCooling/Type2/WaterHeatPump"] != nil
      sysType2 = "WaterHeatPump"
    elsif elements["HouseFile/House/HeatingCooling/Type2/GroundHeatPump"] != nil
      sysType2 = "GroundHeatPump"
    elsif elements["HouseFile/House/HeatingCooling/Type2/AirConditioning"] != nil
      sysType2 = "AirConditioning"
    end

    return sysType2
  end

  # =========================================================================================
  # Get primary DHW system type and fuel
  # =========================================================================================
  def H2KFile.getPrimaryDHWSys(elements)

    fuelName = elements["HouseFile/House/Components/HotWater/Primary/EnergySource/English"].text
    #tankType1 = elements["HouseFile/House/Components/HotWater/Primary/TankType"].attributes["code"]

    return fuelName
  end

  # =====================================================================================
  # Get Ventilation system
  # =====================================================================================
  def H2KFile.get_vent_sys_type(elements)

    bHRV_found = false 
    bERV_found = false 

    location_txt = "HouseFile/House/Ventilation/WholeHouseVentilatorList/*"
 
    elements.each(location_txt) do | this_vent_sys |

      if ( this_vent_sys.name =~ /hrv/i )
        bHRV_found = true 
      elsif ( this_vent_sys.name =~ /hrv/i )
        bERV_found = true 
      end 
    end 



    return "ERV" if bERV_found 
    return "HRV" if bHRV_found
    return "fans"

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
  

    devmsg_out ("Need to add ruleset support")
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

      when "Opt-AboveGradeWall"

        H2KEdit.set_above_grade_wall(h2k_contents,map,choice)

      when "Opt-Ceilings"

        H2KEdit.set_ceilings(h2k_contents,map,choice,"all")

      when "Opt-AtticCeilings"
        H2KEdit.set_ceilings(h2k_contents,map,choice,"attic")

      when "Opt-CathCeilings"
        H2KEdit.set_ceilings(h2k_contents,map,choice,"cathedral")

      when "Opt-FlatCeilings"
        H2KEdit.set_ceilings(h2k_contents,map,choice,"flat")

      when "Opt-Heating-Cooling"

        H2KEdit.set_heating_cooling(h2k_contents,map,choice)

      when "Opt-FoundationWallIntIns" , "Opt-FoundationWallExtIns", "Opt-FoundationSlabOnGrade" ,"Opt-FoundationSlabBelowGrade"

        # Do nothing - handled below

      else
        if (choice == "NA" )
          devmsg_out "Unsupported attribute #{attribute}, Choice = #{choice} "
        else 
          devmsg_out "Unsupported attribute #{attribute}, Choice = #{choice} "
        end 
      end 

    end 

    # Test foundation configruations 
    # debug_on 
    fdn_config = HTAPData.get_foundation_config(choices)
    if (debug_status())
      debug_out("Foundation config: #{fdn_config.pretty_inspect}")
    end 

    
    devmsg_out("Need to add support for legacy foundations")
    case fdn_config

    when "wholeFdn"
    
      warn_out("use of H2kFoundations not yet supported")
    
    when "surfBySurf"


      # Now we have processed all sequential choices - we need to preform
      # operations tha depend on multiple choices. Start with Foundations...
      myFdnData = Hash.new


      debug_out ( ">>> $foundation config? #{$foundationConfiguration}\n")
      myFdnData["FoundationWallExtIns"     ] = choices["Opt-FoundationWallExtIns"     ]
      myFdnData["FoundationWallIntIns"     ] = choices["Opt-FoundationWallIntIns"     ]
      myFdnData["FoundationSlabBelowGrade" ] = choices["Opt-FoundationSlabBelowGrade" ]
      myFdnData["FoundationSlabOnGrade"    ] = choices["Opt-FoundationSlabOnGrade"    ]
      H2KEdit.conf_foundations(myFdnData,options.clone,h2k_contents)

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

    x_path = "HouseFile/ProgramInformation/Weather"
    h2k_contents[x_path].attributes["library"] = weather_file

    x_path = "HouseFile/ProgramInformation/Weather/Region"
    h2k_contents[x_path].attributes["code"] = region

    x_path = "HouseFile/ProgramInformation/Weather/Region/English"
    h2k_contents[x_path].text = region_name

    x_path = "HouseFile/ProgramInformation/Weather/Region/French"
    h2k_contents[x_path].text = region_name

    x_path = "HouseFile/ProgramInformation/Client/StreetAddress/Province"
    h2k_contents[x_path].text = region_name
    
    x_path = "HouseFile/ProgramInformation/Weather/Location"
    h2k_contents[x_path].attributes["code"] = location    

    x_path = "HouseFile/ProgramInformation/Weather/Location/English"
    h2k_contents[x_path].text = choice

    x_path = "HouseFile/ProgramInformation/Weather/Location/French"
    h2k_contents[x_path].text = choice



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

    if ( isNonNa(ach) ) then 

      x_path = "HouseFile/House/NaturalAirInfiltration/Specifications/House/AirTightnessTest"
      h2k_contents[x_path].attributes["code"] = "x"
    
      # Need to set the House/AirTightnessTest code attribute to "Blower door test values" (x)
      x_path = "HouseFile/House/NaturalAirInfiltration/Specifications/House/AirTightnessTest"
      h2k_contents[x_path].attributes["code"] = "x"

      # Must also remove "Air Leakage Test Data" section, if present, since it will over-ride user-specified ACH value
      x_path = "HouseFile/House/NaturalAirInfiltration/AirLeakageTestData"
      if (  h2k_contents[x_path] != nil )
        # Need to remove this section!
        x_path = "HouseFile/House/NaturalAirInfiltration"
        h2k_contents[x_path].delete_element("AirLeakageTestData")
        # Change CGSB attribute to true (was set to "As Operated" by AirLeakageTestData section
        x_path = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
        h2k_contents[x_path].attributes["isCgsbTest"] = "true"
      end
      # Set the blower door test value in airChangeRate field
      x_path = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
      h2k_contents[x_path].attributes["airChangeRate"] = ach
  
      h2k_contents[x_path].attributes["isCgsbTest"] = "true"
      h2k_contents[x_path].attributes["isCalculated"] = "true"      


    end 


    if ( isNonNa(site) ) then 
      if(site.to_f < 1 || site.to_f > 8)
        fatalerror("In Opt-ACH = #{choice}, invalid building site input #{site}")
      end
      x_path = "HouseFile/House/NaturalAirInfiltration/Specifications/BuildingSite/Terrain"
      h2k_contents[x_path].attributes["code"] = site
    end 

    if ( isNonNa(wall_shield) ) then 
      if(wall_shield.to_f < 1 || wall_shield.to_f > 5)
        fatalerror("In Opt-ACH = #{choice}, invalid wall shield input #{wall_shield}")
      end
      x_path = "HouseFile/House/NaturalAirInfiltration/Specifications/LocalShielding/Walls"
      h2k_contents[x_path].attributes["code"] = wall_shield
    end 

    if ( isNonNa(flue_shield) ) then 
      if(flue_shield.to_f < 1 || flue_shield.to_f > 5)
        fatalerror("In Opt-ACH = #{choice}, invalid flue shield input #{wall_shield}")
      end
      x_path = "HouseFile/House/NaturalAirInfiltration/Specifications/LocalShielding/Flue"
      h2k_contents[x_path].attributes["code"] = flue_shield
    end 

  end 
  #.....................................................
  def H2KEdit.set_ventsystem(h2k_contents,map,choice)

    #debug_on 
    debug_out ("Setting ventilation system to #{choice}")
    debug_out ("Spec: #{map.pretty_inspect}")

    return if ( choice == "NA" )

    # Delete existing ventilation list.
    x_path = "HouseFile/House/Ventilation/"
    h2k_contents[x_path].delete_element("WholeHouseVentilatorList")        


    # What does this do?
    #if ( $outputHCode =~ /General/ )
    #  h2k_contents[x_path].add_element("SupplementalVentilatorList")
    #  h2k_contents[x_path].delete_element("SupplementalVentilatorList")
    #end 


    # Make fresh element
    h2k_contents[x_path].add_element("WholeHouseVentilatorList")    


    # Create HRV from template. 
    H2KTemplates.hrv(h2k_contents)

    # Set the ventilation code requirement to 4 (Not applicable)
    h2k_contents[x_path + "Requirements/Use"].attributes["code"] = "4"

    # Set the air distribution type
    h2k_contents[x_path + "WholeHouse/AirDistributionType"].attributes["code"] = map["OPT-H2K-AirDistType"]

    # Set the operation schedule
    h2k_contents[x_path + "WholeHouse/OperationSchedule"].attributes["code"] = 0
    # User Specified
    h2k_contents[x_path + "WholeHouse/OperationSchedule"].attributes["value"] = map["OPT-H2K-OpSched"]


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
    h2k_contents[x_path + "WholeHouseVentilatorList/Hrv"].attributes["supplyFlowrate"] = flow_rate.to_s

    h2k_contents[x_path + "WholeHouseVentilatorList/Hrv"].attributes["exhaustFlowrate"] = flow_rate.to_s




    # Update the HRV efficiency
    h2k_contents[x_path  + "WholeHouseVentilatorList/Hrv"].attributes["efficiency1"] = map["OPT-H2K-Rating1"]
    # Rating 1 Efficiency
    h2k_contents[x_path  + "WholeHouseVentilatorList/Hrv"].attributes["efficiency2"] = map["OPT-H2K-Rating2"]
    # Rating 2 Efficiency
    h2k_contents[x_path  + "WholeHouseVentilatorList/Hrv"].attributes["coolingEfficiency"] = map["OPT-H2K-Rating3"]
    # Rating 3 Efficiency


    # Fan power calculation
    case map["OPT-H2K-FanPowerCalc"]

    when "NBC"
      # Determine fan power from flow rate as stated in 9.36.5.11(14a)
      fan_power = flow_rate * 2.32
      fan_power = sprintf("%0.2f", flow_rate )
      h2k_contents[x_path + "WholeHouseVentilatorList/Hrv"].attributes["fanPower1"] =  fan_power
      # Supply the fan power at operating point 1 [W]
      h2k_contents[x_path + "WholeHouseVentilatorList/Hrv"].attributes["fanPower2"] =  fan_power
      # Supply the fan power at operating point 2 [W]
    when "specified"
      h2k_contents[x_path + "WholeHouseVentilatorList/Hrv"].attributes["isDefaultFanpower"] = "false"
      # Specify the fan power
      h2k_contents[x_path + "WholeHouseVentilatorList/Hrv"].attributes["fanPower1"] =  map["OPT-H2K-FanPower1"]
      # Supply the fan power at operating point 1 [W]
      h2k_contents[x_path + "WholeHouseVentilatorList/Hrv"].attributes["fanPower2"] =  map["OPT-H2K-FanPower2"]
      # Supply the fan power at operating point 2 [W]

    when "default"
      h2k_contents[x_path + "WholeHouseVentilatorList/Hrv"].attributes["isDefaultFanpower"] = "true"
    else 
      err_out("ERROR: For Opt-VentSystem, unknown fan power calculation input  #{map["OPT-H2K-FanPowerCalc"]}!")
    end 

  end 
  #.....................................................
  def H2KEdit.set_windows(h2k_contents,h2k_codes,map,choice)

    #debug_on 
    if ( debug_status())
      debug_out ("Setting windows to #{choice}")
      debug_out ("Spec: #{map.pretty_inspect}")
    end 
    return if ( choice == "NA" )


    map.keys.each do | key, value |
      orientation = key.gsub(/\<Opt-win-/,"").gsub(/-CON\>/,"")
      debug_out ("Orientation: #{orientation}")

      H2KEdit.set_windows_by_orientation(h2k_contents,h2k_codes,orientation,choice)
    end 
    
  end  

  def H2KEdit.set_above_grade_wall(h2k_contents,map,choice)
    #debug_on

    if ( debug_status())
      debug_out ("Setting walls to #{choice}")
      debug_out ("Spec: #{map.pretty_inspect}")
    end
    
    return if ( choice == "NA" )

    x_path = "HouseFile/House/Components/Wall/Construction/Type"

    h2k_contents.each(x_path) do |wall_type|

      wall_type.text = "User specified"
      
      wall_type.attributes["rValue"] = map["OPT-H2K-EffRValue"] 
      
      if wall_type.attributes["idref"] != nil then
        # Must delete attribute for User Specified!
        wall_type.delete_attribute("idref")
      end 
    
    end 
    
  end

  def H2KEdit.set_ceilings(h2k_contents,map,choice,type)

    debug_out("Seeting ceiling type #{type} to #{choice}")
    
    return if choice == "NA"
    
    if ( map["OPT-H2K-EffRValue"] == "NA" ) 
      err_out "Ceiling type #{type}, choice #{choice}: OPT-H2K-EffRValue must be numerical value (not NA)"
    end 

    r_value = map["OPT-H2K-EffRValue"].to_f
                  
    debug_out ("TYPE: #{type} Choice: #{choice} / RVALUE: #{r_value}")
    x_path = "HouseFile/House/Components/Ceiling"
    
    h2k_contents.each(x_path) do |ceiling|

      next if ( type == "attic" &&
                ceiling.elements["Construction/Type"].attributes["code"] != "2" && 
                ceiling.elements["Construction/Type"].attributes["code"] != "3" && 
                ceiling.elements["Construction/Type"].attributes["code"] != "6" )

      next if ( type == "flat" &&
                ceiling.elements["Construction/Type"].attributes["code"] != "5" ) 

      next if ( type == "cathedral" &&
                  ceiling.elements["Construction/Type"].attributes["code"] != "4" ) 

      rsi = r_value / R_PER_RSI 
      debug_out("RSI: #{rsi.round(3).to_s}")
      ceiling.elements["Construction/CeilingType"].text = "User specified"
      ceiling.elements["Construction/CeilingType"].attributes["rValue"] = rsi.round(3).to_s
      if ceiling.elements["Construction/CeilingType"].attributes["idref"] != nil then
        # Must delete attribute for User Specified!
        ceiling.elements["Construction/CeilingType"].delete_attribute("idref")
      end
    end
    devmsg_out("Support for code definitions in ceilings currently broken.")
    devmsg_out("Heel-height not currently supported; consider adding function in the future.")

  end 


  def H2KEdit.set_heating_cooling(h2k_contents,map,choice)
    #debug_on 

    if ( debug_status())
      debug_out ("Setting heating/cooling to #{choice}")
      debug_out ("Spec: #{map.pretty_inspect}")
    end
    
    return if ( choice == "NA" )

    sys_1_keyword = map["Opt-H2K-SysType1"]
    sys_2_keyword = map["Opt-H2K-SysType2"]
    
    if ( sys_1_keyword  != "NA" )
      debug_out "SYSTEM 1 - #{sys_1_keyword}"
      
      x_path = "HouseFile/House/HeatingCooling/Type1"
      
      # Make sure template exists (?)
      if ( h2k_contents[x_path + "/#{sys_1_keyword}"] == nil )
        # Create a new system type 1 element with default values for all of its sub-elements
        debug_out ("calling Create System type to add xml entry for #{sys_1_keyword}")
        H2KEdit.createH2KSysType1(h2k_contents,sys_1_keyword)

        # Delete any other systems, if there are any
        $sys_type_1_list.each do |sys_type|
          if ( h2k_contents[x_path + "/#{sys_type}"] != nil && sys_type != sys_1_keyword )
            debug_out ("Deleting redundant system #{sys_type}")
            h2k_contents[x_path].delete_element(sys_type)
          end
        end
        
      end 

      # Now set Type 1 parameters 
      $sys_type_1_list.each do |sys_type|
      end 
      
      sys_type = sys_1_keyword
      base_path = "HouseFile/House/HeatingCooling/Type1/#{sys_type}"
      x_path = base_path + "/Equipment/EnergySource"
      if ( sys_type != "Baseboards" && h2k_contents[x_path] == nil )


        #next if (sys_type == "Baseboards")
        #next if (h2k_contents[x_path] == nil )

        # FUEL TYPE
        fuel_code = map["Opt-H2K-Type1Fuel"]
        if ( isNonNa(fuel_code))
          debug_out "Setting fuel for #{sys_type} to #{fuel_code}"
          h2k_contents[x_path].attributes["code"] = fuel_code
      
          if (fuel_code != "1" )
            # Ensure that combustio appliances have a flue
            x_path = base_path + "/Specifications"
            if h2k_contents[x_path].attributes["flueDiameter"].to_i == 0
              debug_out ("Setting flue diameter to 127 mm by default")
              h2k_contents[x_path].attributes["flueDiameter"] = "127"  #mm
            end
          end 
        end 

        # EQUIPMENT TYPE
        equip_code = map["Opt-H2K-Type1EqpType"]
        x_path = base_path + "/Equipment/EquipmentType"
        if ( h2k_contents[x_path] != nil && isNonNa(equip_code) )
          debug_out ("Setting equipment type to #{equip_code}")
          h2k_contents[x_path].attributes["code"] = equip_code
          # 28-Dec-2016 JTB: If the energy source is one of the 4 woods and the equipment type is
          # NOT a conventional fireplace, add the "EPA/CSA" attribute field in the
          # EquipmentInformation section to avoid a crash!
          if (h2k_contents[base_path+"/Equipment/EnergySource"].attributes["code"].to_i > 4 && equip_code != "8" )
            h2k_contents[base_path+"/EquipmentInformation"].attributes["epaCsa"] = "false"
          end 
        
        end 

        # How is capacity sized ?
        cap_opt = map["Opt-H2K-Type1CapOpt"]
        x_path = base_path + "/Specifications/OutputCapacity"
        if (isNonNa(cap_opt) && h2k_contents[x_path] != nil)
          debug_out("Setting capacity option to #{cap_opt}")
          h2k_contents[x_path].attributes["code"] = cap_opt

        end 

        # how big is the system?
        capacity = map["Opt-H2k-Type1CapVal"]
        if ( isNonNa(capacity) && capacity.to_s != "" && h2k_contents[x_path] != nil )
          debug_out ("TYPE 1 Capacity = |#{capacity}|")
          h2k_contents[x_path].attributes["value"] = capacity
        end 

        # Is efficiency steady-state? 
        eff_type = map["Opt-H2K-Type1EffType"]
        x_path = base_path + "/Specifications"
        if (isNonNa(eff_type) && sys_type != "Baseboards" )
          debug_out ("Type 1 eff type / is steady state ? = #{eff_type}")
          h2k_contents[x_path].attributes["isSteadyState"] = eff_type
        end 

        # Efficiency value
        eff_value= map["Opt-H2K-Type1EffVal"]
        if (isNonNa(eff_type) && sys_type != "Baseboards" )
          debug_out ("Type 1 efficiency value = #{eff_value}")
          h2k_contents[x_path].attributes["efficiency"] = eff_value
        end

        # Fan Control
        fan_ctl = map["Opt-H2K-Type1FanCtl"]
        x_path = "HouseFile/House/HeatingCooling/Type1/FansAndPump/Mode"
        if (isNonNa(fan_ctl) )
          debug_out ("Type 1 fa ctl = #{fan_ctl}")
          h2k_contents[x_path].attributes["code"] = fan_ctl
        end 

        # Fan Control
        ee_motor = map["Opt-H2K-Type1EEMotor"]
        x_path = "HouseFile/House/HeatingCooling/Type1/FansAndPump"
        if (isNonNa(ee_motor) )
          debug_out("Type 1 ee motor: #{ee_motor}")
          h2k_contents[x_path].attributes["hasEnergyEfficientMotor"] = ee_motor
        end  

      end 


    end # if ( sys_1_keyword  != "NA" )

    #------ type 2 
    if( sys_2_keyword == "None" )
      debug_out("System 2 = none, deleting type 2 systems")
      x_path = "HouseFile/House/HeatingCooling/Type2"
      $sys_type_2_list.each do |sys_type|
        if ( h2k_contents[x_path + "/#{sys_type}"] != nil )
          debug_out ("Deleting redundant system #{sys_type}")
          h2k_contents[x_path].delete_element(sys_type)
        end
      end 
    
    elsif ( sys_2_keyword  != "NA" )

      debug_out "SYSTEM 2 - #{sys_2_keyword}"
      x_path = "HouseFile/House/HeatingCooling/Type2"
      if ( h2k_contents[x_path + "/#{sys_2_keyword}"] == nil && sys_2_keyword != "None" )
        debug_out ("calling Create System type to add xml entry for #{sys_2_keyword}")
        H2KEdit.createH2KSysType2(h2k_contents,sys_2_keyword)
      end 
      $sys_type_2_list.each do |sys_type|
        if ( h2k_contents[x_path + "/#{sys_type}"] != nil && sys_type != sys_2_keyword )
          debug_out ("Deleting redundant system #{sys_type}")
          h2k_contents[x_path].delete_element(sys_type)
        end
      end
      
      debug_out ("Setting cooling seasing start / end ")
      h2k_contents["HouseFile/House/HeatingCooling/CoolingSeason/Start"].attributes["code"] = 5
      h2k_contents["HouseFile/House/HeatingCooling/CoolingSeason/End"].attributes["code"] = 10
      
      
      sys_type = sys_2_keyword

      base_path = base_path = "HouseFile/House/HeatingCooling/Type2/#{sys_type}"

      # Type2 function 
      type_2_function = map["Opt-H2K-Type2Func"]
      if ( isNonNa(type_2_function) && sys_type != "AirConditioning"  )
        debug_out("Type 2 function #{type_2_function}")
        x_path = base_path + "/Equipment/Function"
        h2k_contents[x_path].attributes["code"] = type_2_function
      end 
      #return 
      # Type2 type
      type_2_type = map["Opt-H2K-Type2Type"]
      if ( isNonNa(type_2_type) && sys_type != "AirConditioning"  )
        debug_out("Type 2 type #{type_2_type}")
        x_path = base_path + "/Equipment/Type"
        h2k_contents[x_path].attributes["code"] = type_2_type
      end 


      # Crank Case Heater power draw
      crank_case_heater = map["Opt-H2K-Type2CCaseH"]
      x_path = base_path + "/Equipment"
      if (sys_type == "AirHeatPump" && isNonNa(crank_case_heater) )
        debug_out("Setting Crank Case heater to #{crank_case_heater}")
        h2k_contents[x_path].attributes["crankcaseHeater"] = crank_case_heater
      end 

      # How is capacity sized ?
      cap_opt = map["Opt-H2K-Type2CapOpt"]
      if ( sys_type != "AirConditioning" )
        # For ASHP, GSHP, WHP
        x_path = base_path + "/Specifications/OutputCapacity"
      else 
        # FOR AC
        x_path = base_path + "/Specifications/RatedCapacity"
      end 

      if (isNonNa(cap_opt) && h2k_contents[x_path] != nil)
        debug_out("Setting type 2 capacity option to #{cap_opt}")
        h2k_contents[x_path].attributes["code"] = cap_opt
        h2k_contents[x_path].attributes["value"] = "15.6"
        h2k_contents[x_path].attributes["uiUnits"] = "kW"
      end 

      # how big is the system?
      capacity = map["Opt-H2k-Type2CapVal"]
      if ( isNonNa(capacity) && capacity.to_s != "" && h2k_contents[x_path] != nil )
        debug_out ("TYPE 2 Capacity = |#{capacity}|")
        h2k_contents[x_path].attributes["value"] = capacity
        h2k_contents[x_path].attributes["uiUnits"] = "kW"
      end 

      # Heating COP?
      heat_cop = map["Opt-H2K-Type2HeatCOP"]
      x_path = base_path + "/Specifications/HeatingEfficiency"
      if ( isNonNa(heat_cop) && sys_type != "AirConditioning")
        debug_out ("TYPE 2 COP heating= |#{heat_cop}|")
        h2k_contents[x_path].attributes["isCOP"] = "true"
        h2k_contents[x_path].attributes["uiUnits"] = heat_cop
      end 

      rating_temp = map["Opt-H2K-Type2RatingTemp"]
      x_path = base_path + "/Temperature/RatingType"
      if ( isNonNa(rating_temp) && sys_type != "AirConditioning" )
        debug_out ("TYPE 2 rating temp: #{rating_temp}")
        h2k_contents[x_path].attributes["code"] = "3"
        h2k_contents[x_path].attributes["value"] = rating_temp
      end 


      # Type 2 cutoff (balanced/restricted/unrestricted)
      cutoff_control = map["Opt-H2K-Type2CutoffType"]
      x_path = base_path + "/Temperature/CutoffType"
      if ( isNonNa(cutoff_control) && sys_type != "AirConditioning")
        debug_out ("TYPE 2 cutoff control |#{cutoff_control}|")
        h2k_contents[x_path].attributes["code"] = cutoff_control
      end 

      # Type 2 cutoff (balanced/restricted/unrestricted)
      cutoff_temp = map["Opt-H2K-Type2CutoffTemp"]
      x_path = base_path + "/Temperature/CutoffType"
      if ( isNonNa(cutoff_temp) && sys_type != "AirConditioning")
        debug_out ("TYPE 2 cutoff control |#{cutoff_temp}|")
        h2k_contents[x_path].attributes["value"] = cutoff_temp
      end       

      # Cooling COP ?
      cool_cop = map["Opt-H2K-Type2CoolCOP"]
      if ( sys_type != "AirConditioning" )
        # For ASHP, GSHP, WHP
        x_path = base_path + "/Specifications/CoolingEfficiency"
      else 
        # FOR AC
        x_path = base_path + "/Specifications/Efficiency"
      end 

      if ( isNonNa(cool_cop)  && h2k_contents[x_path] != nil)
        debug_out("Setting type 2 cooling COP to #{cool_cop}")
        h2k_contents[x_path].attributes["isCOP"] = "true"
        h2k_contents[x_path].attributes["value"] = cool_cop
      end 

      cool_spec_type = map["Opt-H2K-CoolSpecType"]
      x_path = base_path + "/Specifications/CoolingEfficiency"
      if ( isNonNa(cool_spec_type) && sys_type != "AirConditioning" )
        if (cool_spec_type != "COP" ) then 
          result = "false"
        else 
          result = "true"
        end 
        h2k_contents[x_path].attributes["isCop"] = result
      end 






      # Type 2 cutoff (balanced/restricted/unrestricted)
      operable_window_frac = map["Opt-H2K-CoolOperWindow"]
      x_path = base_path + "/CoolingParameters"
      if ( isNonNa(operable_window_frac))
        debug_out ("TYPE 2 window operable parameter |#{operable_window_frac}|")
        h2k_contents[x_path].attributes["openableWindowArea"] = operable_window_frac
      end 


    end # if ( sys_2_keyword  != "NA" ) 

    warn_out("This routine is is not yet finished")
    #debug_pause()

  end 

  def self.isNonNa(value)
    debug_off
  
    valNonNa   = false

    if ( ! value.nil? && ! value.empty? )
      if (value != "NA" )
        valNonNa = true 
      else 
        valNonNa = false
      end 
    end 

    return valNonNa

  end 

  # =========================================================================================
  # Add a System Type 1 section (check for existence done external to this method)
  # =========================================================================================
  def H2KEdit.createH2KSysType1( elements, sysType1Name )
    #debug_on 
    debug_out("Creating type 1 definition - #{sysType1Name}")
    x_path = "HouseFile/House/HeatingCooling/Type1"

    elements[x_path].add_element(sysType1Name)
    if ( sysType1Name == "Baseboards" )
      x_path = "HouseFile/House/HeatingCooling/Type1/Baseboards"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type1/Baseboards/EquipmentInformation"
      elements[x_path].attributes["numberOfElectronicThermostats"] = "0"

      x_path = "HouseFile/House/HeatingCooling/Type1/Baseboards"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type1/Baseboards/Specifications"
      elements[x_path].attributes["sizingFactor"] = "1.1"
      elements[x_path].attributes["efficiency"] = "100"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type1/Baseboards/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      # Calculated
      elements[x_path].attributes["value"] = "0"
      # Calculated value - will be replaced!
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

    elsif ( sysType1Name == "Furnace" )


      debug_out ("ADDING FURNACE ....\n")

      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/EquipmentInformation"
      elements[x_path].attributes["energystar"] = "false"
      elements[x_path].add_element("Manufacturer")

      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment"
      elements[x_path].attributes["isBiEnergy"] = "false"
      elements[x_path].attributes["switchoverTemperature"] = "0"
      elements[x_path].add_element("EnergySource")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EnergySource"
      elements[x_path].attributes["code"] = "2"
      # Gas
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment"
      elements[x_path].add_element("EquipmentType")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EquipmentType"
      elements[x_path].attributes["code"] = "1"
      # Furnace with cont. pilot
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Specifications"
      elements[x_path].attributes["sizingFactor"] = "1.1"
      elements[x_path].attributes["efficiency"] = "78"
      elements[x_path].attributes["isSteadyState"] = "true"
      elements[x_path].attributes["pilotLight"] = "0"
      elements[x_path].attributes["flueDiameter"] = "127"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      # Calculated
      elements[x_path].attributes["value"] = "0"
      # Calculated value - will be replaced!
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

    elsif ( sysType1Name == "Boiler" )
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/EquipmentInformation"
      elements[x_path].attributes["energystar"] = "false"
      elements[x_path].add_element("Manufacturer")

      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment"
      elements[x_path].attributes["isBiEnergy"] = "false"
      elements[x_path].attributes["switchoverTemperature"] = "0"
      elements[x_path].add_element("EnergySource")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment/EnergySource"
      elements[x_path].attributes["code"] = "2"
      # Gas
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment"
      elements[x_path].add_element("EquipmentType")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment/EquipmentType"
      elements[x_path].attributes["code"] = "1"
      # Boiler with cont. pilot
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Specifications"
      elements[x_path].attributes["sizingFactor"] = "1.1"
      elements[x_path].attributes["efficiency"] = "78"
      elements[x_path].attributes["isSteadyState"] = "true"
      elements[x_path].attributes["pilotLight"] = "0"
      elements[x_path].attributes["flueDiameter"] = "127"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      # Calculated
      elements[x_path].attributes["value"] = "0"
      # Calculated value - will be replaced!
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

    elsif ( sysType1Name == "ComboHeatDhw" )
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/EquipmentInformation"
      elements[x_path].attributes["energystar"] = "false"
      elements[x_path].add_element("Manufacturer")

      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment"
      elements[x_path].add_element("EnergySource")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment/EnergySource"
      elements[x_path].attributes["code"] = "2"
      # Gas
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment"
      elements[x_path].add_element("EquipmentType")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment/EquipmentType"
      elements[x_path].attributes["code"] = "1"
      # ComboHeatDhw with cont. pilot
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Specifications"
      elements[x_path].attributes["sizingFactor"] = "1.1"
      elements[x_path].attributes["efficiency"] = "78"
      elements[x_path].attributes["isSteadyState"] = "true"
      elements[x_path].attributes["pilotLight"] = "25.3"
      elements[x_path].attributes["flueDiameter"] = "152.4"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      # Calculated
      elements[x_path].attributes["value"] = "0"
      # Calculated value - will be replaced!
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[x_path].add_element("ComboTankAndPump")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[x_path].add_element("TankCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump/TankCapacity"
      elements[x_path].attributes["code"] = "3"
      elements[x_path].attributes["value"] = "151.4"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[x_path].add_element("EnergyFactor")
      elements[x_path].attributes["useDefaults"] = "true"
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[x_path].add_element("TankLocation")
      elements[x_path].attributes["code"] = "2"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[x_path].add_element("CirculationPump")
      elements[x_path].attributes["isCalculated"] = "true"
      elements[x_path].attributes["value"] = "0"
      elements[x_path].attributes["hasEnergyEfficientMotor"] = "false"

    elsif ( sysType1Name == "P9" )
      x_path = "HouseFile/House/HeatingCooling/Type1/P9"
      elements[x_path].attributes["id"] = "0"
      elements[x_path].attributes["numberOfSystems"] = "1"
      elements[x_path].attributes["thermalPerformanceFactor"] = "0.9"
      elements[x_path].attributes["annualElectricity"] = "1800"
      elements[x_path].attributes["spaceHeatingCapacity"] = "23900"
      elements[x_path].attributes["spaceHeatingEfficiency"] = "90"
      elements[x_path].attributes["waterHeatingPerformanceFactor"] = "0.9"
      elements[x_path].attributes["burnerInput"] = "0"
      elements[x_path].attributes["recoveryEfficiency"] = "0"
      elements[x_path].attributes["isUserSpecified"] = "true"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/EquipmentInformation"
      elements[x_path].add_element("Manufacturer")
      elements[x_path].add_element("Model")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/EquipmentInformation/Manufacturer"
      elements[x_path].text = "Generic"
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/EquipmentInformation/Model"
      elements[x_path].text = "Generic"

      x_path = "HouseFile/House/HeatingCooling/Type1/P9"
      elements[x_path].add_element("TestData")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[x_path].attributes["controlsPower"] = "10"
      elements[x_path].attributes["circulationPower"] = "130"
      elements[x_path].attributes["dailyUse"] = "0.2"
      elements[x_path].attributes["standbyLossWithFan"] = "0"
      elements[x_path].attributes["standbyLossWithoutFan"] = "0"
      elements[x_path].attributes["oneHourRatingHotWater"] = "1000"
      elements[x_path].attributes["oneHourRatingConcurrent"] = "1000"
      elements[x_path].add_element("EnergySource")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData/EnergySource"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[x_path].add_element("NetEfficiency")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData/NetEfficiency"
      elements[x_path].attributes["loadPerformance15"] = "80"
      elements[x_path].attributes["loadPerformance40"] = "80"
      elements[x_path].attributes["loadPerformance100"] = "80"
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[x_path].add_element("ElectricalUse")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData/ElectricalUse"
      elements[x_path].attributes["loadPerformance15"] = "100"
      elements[x_path].attributes["loadPerformance40"] = "200"
      elements[x_path].attributes["loadPerformance100"] = "300"
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[x_path].add_element("BlowerPower")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData/BlowerPower"
      elements[x_path].attributes["loadPerformance15"] = "300"
      elements[x_path].attributes["loadPerformance40"] = "500"
      elements[x_path].attributes["loadPerformance100"] = "800"
    end
  end
  # createH2KSysType1

  # =========================================================================================
  # Procedure to create a new H2K system Type 2 in the XML house file. Check done external.
  # =========================================================================================
  def H2KEdit.createH2KSysType2( elements, sysType2Name )
    debug_on 
    debug_out("Creating type 2 definition - #{sysType2Name}")
    x_path = "HouseFile/House/HeatingCooling/Type2"
    elements[x_path].add_element(sysType2Name)
    elements[x_path].attributes["shadingInF280Cooling"] = "AccountedFor"

    if ( sysType2Name == "AirHeatPump" )

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[x_path].add_element("EquipmentInformation")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/EquipmentInformation"
      elements[x_path].attributes["energystar"] = "false"

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[x_path].add_element("Equipment")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment"
      elements[x_path].attributes["crankcaseHeater"] = "60"
      elements[x_path].add_element("Type")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment/Type"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment"
      elements[x_path].add_element("Function")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment/Function"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[x_path].add_element("Specifications")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications"
      elements[x_path].add_element("OutputCapacity")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      # I think these can be commented out if we default to 'calculated'
      #elements[x_path].attributes["value"] = ""
      #elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications"
      elements[x_path].add_element("HeatingEfficiency")
      elements[x_path].add_element("CoolingEfficiency")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications/HeatingEfficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "2"

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications/CoolingEfficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "2"

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[x_path].add_element("Temperature")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature"
      elements[x_path].add_element("CutoffType")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature/CutoffType"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].attributes["value"] = "0"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature"
      elements[x_path].add_element("RatingType")

      # CHECK this - should be 8.3 ?

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature/RatingType"
      elements[x_path].attributes["code"] = "3"
      elements[x_path].attributes["value"] = "-5.0"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[x_path].add_element("CoolingParameters")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters"
      elements[x_path].attributes["sensibleHeatRatio"] = "0.76"
      elements[x_path].attributes["openableWindowArea"] = "20"

      elements[x_path].add_element("FansAndPump")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters/FansAndPump"
      # Do we need to set this? what should we set it to?
      elements[x_path].attributes["flowRate"] = "700"

      elements[x_path].add_element("Mode")
      elements[x_path].add_element("Power")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters/FansAndPump/Mode"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters/FansAndPump/Power"
      elements[x_path].attributes["isCalculated"] = "true"

    elsif ( sysType2Name == "WaterHeatPump" )
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/EquipmentInformation"
      elements[x_path].attributes["canCsaC448"] = "false"

      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Equipment"
      elements[x_path].attributes["crankcaseHeater"] = "0"
      elements[x_path].add_element("Function")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Equipment/Function"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].attributes["value"] = "21.5"
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications"
      elements[x_path].add_element("HeatingEfficiency")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications/HeatingEfficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "3"

      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[x_path].add_element("Temperature")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature"
      elements[x_path].add_element("CutOffType")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature/CutOffType"
      elements[x_path].attributes["code"] = "3"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature"
      elements[x_path].add_element("RatingType")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature/RatingType"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].attributes["value"] = "8.3"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[x_path].add_element("SourceTemperature")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/SourceTemperature"
      elements[x_path].attributes["depth"] = "1.5"
      elements[x_path].add_element("Use")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/SourceTemperature/Use"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

    elsif ( sysType2Name == "GroundHeatPump" )
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/EquipmentInformation"
      elements[x_path].attributes["canCsaC448"] = "false"

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Equipment"
      elements[x_path].attributes["crankcaseHeater"] = "0"
      elements[x_path].add_element("Function")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Equipment/Function"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].attributes["value"] = "21.5"
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications"
      elements[x_path].add_element("HeatingEfficiency")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications/HeatingEfficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "3"
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications"
      elements[x_path].add_element("CoolingEfficiency")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications/CoolingEfficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "3"

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("Temperature")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature"
      elements[x_path].add_element("CutoffType")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature/CutoffType"
      elements[x_path].attributes["code"] = "3"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature"
      elements[x_path].add_element("RatingType")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature/RatingType"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].attributes["value"] = "8.3"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("SourceTemperature")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/SourceTemperature"
      elements[x_path].attributes["depth"] = "1.5"
      elements[x_path].add_element("Use")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/SourceTemperature/Use"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("CoolingParameters")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters"
      elements[x_path].attributes["sensibleHeatRatio"] = "0.76"
      elements[x_path].attributes["openableWindowArea"] = "20"

      elements[x_path].add_element("FansAndPump")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters/FansAndPump"
      # Do we need to set this? what should we set it to?
      elements[x_path].attributes["flowRate"] = "360"

      elements[x_path].add_element("Mode")
      elements[x_path].add_element("Power")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters/FansAndPump/Mode"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters/FansAndPump/Power"
      elements[x_path].attributes["isCalculated"] = "true"

    elsif ( sysType2Name == "AirConditioning" )
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/EquipmentInformation"
      elements[x_path].attributes["energystar"] = "false"

      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Equipment"
      elements[x_path].attributes["crankcaseHeater"] = "60"
      elements[x_path].add_element("CentralType")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Equipment/CentralType"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications"
      elements[x_path].attributes["sizingFactor"] = "1"
      elements[x_path].add_element("RatedCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications/RatedCapacity"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].attributes["value"] = "0"
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications"
      elements[x_path].add_element("Efficiency")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications/Efficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "3"

      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[x_path].add_element("CoolingParameters")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters"
      elements[x_path].attributes["sensibleHeatRatio"] = "0.76"
      elements[x_path].attributes["openableWindowArea"] = "20"
      elements[x_path].add_element("FansAndPump")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump"
      elements[x_path].attributes["flowRate"] = "0"
      elements[x_path].add_element("Mode")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump/Mode"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump"
      elements[x_path].add_element("Power")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump/Power"
      elements[x_path].attributes["isCalculated"] = "true"
    end
  end
  # createH2KSysType2






  def H2KEdit.conf_foundations(myFdnData,myOptions,h2k_contents)

    

    if (debug_status())
      debug_out "Setting up foundations for this config:\n#{myFdnData.pretty_inspect}\n"
    end 
    slabConfigInsulated = "SCB_25"
    # Insulation configuration on slabs -
    #  Pretty sure requirements are that 9.25.2.3 (5) requires SBC 25 and 29.
    #
    #         |   |_______________________|   |
    #         |    _______________________    |   SCB 25
    #         |   /***********************\   |
    #         |__/*************************\__|
    #
    #
    #         |   |_______________________|   |
    #       **|    _______________________    |**  SCB 29
    #       **|   /***********************\   |**
    #       **|__/*************************\__|**
    #
    #
    #         |   |_______________________|   |
    #       **|    _______________________    |**  SCB 31
    #       **|   /***********************\   |**
    #       **|__/*************************\__|**
    #       ********                     ********
    #
    slabConfigInsulated = "SCB_25"

    h2kFdnData = Hash.new


    rEff_ExtWall = myFdnData["FoundationWallExtIns"]
    rEff_IntWall = myFdnData["FoundationWallIntIns"]
    rEff_SlabOG  = myFdnData["FoundationSlabOnGrade"]
    rEff_SlabBG  = myFdnData["FoundationSlabBelowGrade"]


    # Basements, crawl-spaces
    if ( rEff_ExtWall == "NA" && rEff_IntWall == "NA" && rEff_SlabBG == "NA" )
      # Do nothing!
      debug_out ("'NA' spec'd for Int/Ext walls and below-grade slabs. No changes needed\n")
    else

      debug_out (">>> FDN CHOICE: #{myFdnData["FoundationSlabBelowGrade"]}\n")

      bExtWallInsul = true if ( myOptions["Opt-FoundationWallExtIns"]["options"][rEff_ExtWall]["h2kMap"]["base"]["H2K-Fdn-ExtWallReff"].to_f > 0.01 )
      bIntWallInsul = true if ( myOptions["Opt-FoundationWallIntIns"]["options"][rEff_IntWall]["h2kMap"]["base"]["H2K-Fdn-IntWallReff"].to_f > 0.01)  
      bBGSlabInsul =  true if ( myOptions["Opt-FoundationSlabBelowGrade"]["options"][rEff_SlabBG]["h2kMap"]["base"]["H2K-Fdn-SlabBelowGradeReff"].to_f > 0.01)
        
      if ( bBGSlabInsul & !bIntWallInsul & ! bExtWallInsul )
        # HOT2000 Can't actually run this scenario. Set slab to uninsulated and warn user
        bBGSlabInsul = false 
        rEff_SlabBG  = "uninsulated"
        warn_out ("Slab below-grade set to 'uninsulated'")
      end 


      rEff_ExtWall = "uninsulated" if ( rEff_ExtWall == "NA")
      rEff_IntWall = "uninsulated" if ( rEff_IntWall == "NA")
      rEff_SlabBG  = "uninsulated" if ( rEff_SlabBG  == "NA")

      debug_out ( "vars:#{rEff_ExtWall}/#{rEff_IntWall}/#{rEff_SlabBG}/#{rEff_SlabOG}\n")

      debug_out(drawRuler("Basements, CrawlSpaces",". "))

      # Where is the insulation ?
      #
      # [  ] exterior     [   ] Interior      [  ] Slab  (None! )
      if  ( ! bExtWallInsul && ! bIntWallInsul && ! bBGSlabInsul ) then
        basementConfig = "BCNN_2"
        crawlSpaceConfig = "SCN_1"
        h2kFdnData["?bgSlabIns"]  = false
        h2kFdnData["?IntWallIns"] = false
        h2kFdnData["?ExtWallIns"] = false


        # [ X ] exterior     [   ] Interior      [  ] Slab  ( full height exterior)
      elsif  ( bExtWallInsul && ! bIntWallInsul && ! bBGSlabInsul ) then
        basementConfig = "BCEN_2"
        crawlSpaceConfig = "SCN_1"
        h2kFdnData["?bgSlabIns"]  = false
        h2kFdnData["?IntWallIns"] = false
        h2kFdnData["?ExtWallIns"] = true

        # [   ] exterior     [  X ] Interior      [  ] Slab   ( full height interior )
      elsif  ( ! bExtWallInsul &&  bIntWallInsul && ! bBGSlabInsul ) then

        basementConfig = "BCIN_1"
        crawlSpaceConfig = "SCN_1"
        h2kFdnData["?bgSlabIns"]  = false
        h2kFdnData["?IntWallIns"] = true
        h2kFdnData["?ExtWallIns"] = false

        # [ X ] exterior     [ X ] Interior      [  ] Slab     ( full height exterior, within 8" of slab on interior )
      elsif  ( bExtWallInsul && bIntWallInsul && ! bBGSlabInsul ) then

        basementConfig = "BCCN_5"
        crawlSpaceConfig = "SCN_1"
        h2kFdnData["?bgSlabIns"]  = false
        h2kFdnData["?IntWallIns"] = true
        h2kFdnData["?ExtWallIns"] = true

        #      [ X ] exterior                  [   ] Interior                   [ X ] Slab     ( full height exterior, underneath slab )
      elsif  (  bExtWallInsul && ! bIntWallInsul &&  bBGSlabInsul ) then

        basementConfig = "BCEB_4"
        crawlSpaceConfig = slabConfigInsulated
        # (SCB_29, SCB_31 would give better thermal separation - not sure which to use... )

        h2kFdnData["?bgSlabIns"]  = true
        h2kFdnData["?IntWallIns"] = false
        h2kFdnData["?ExtWallIns"] = true


        # [   ] exterior     [ x  ] Interior      [ X ] Slab     ( full height exterior, underneath slab )
      elsif  ( ! bExtWallInsul &&  bIntWallInsul &&  bBGSlabInsul ) then

        basementConfig = "BCIB_1"
        crawlSpaceConfig = slabConfigInsulated
        # (SCB_29, SCB_31 would give better thermal separation - not sure which to use... )

        h2kFdnData["?bgSlabIns"]  = true
        h2kFdnData["?IntWallIns"] = true
        h2kFdnData["?ExtWallIns"] = false


        #      [ X ] exterior                  [  X ] Interior                   [ X ] Slab     ( full height exterior, underneath slab )
      elsif  (  bExtWallInsul &&  bIntWallInsul &&  bBGSlabInsul ) then

        basementConfig = "BCCB_9"
        crawlSpaceConfig = slabConfigInsulated
        # (SCB_29, SCB_31 would give better thermal separation - not sure which to use... )

        h2kFdnData["?bgSlabIns"]  = true
        h2kFdnData["?IntWallIns"] = true
        h2kFdnData["?ExtWallIns"] = true

      else
        # Need to make this case more general?
        fatalerror ("Unsupported foundation configuration!!!")
      end

      debug_out " Basement/crawlspace configuration : #{basementConfig}\n"
      h2kFdnData["BasementConfig"] = basementConfig
      h2kFdnData["CrawlConfig"] = crawlSpaceConfig
      h2kFdnData["rEffIntWall"] =  myOptions["Opt-FoundationWallIntIns"]["options"][rEff_IntWall]["h2kMap"]["base"]["H2K-Fdn-IntWallReff"].to_f
      h2kFdnData["rEffExtWall"] =  myOptions["Opt-FoundationWallExtIns"]["options"][rEff_ExtWall]["h2kMap"]["base"]["H2K-Fdn-ExtWallReff"].to_f
      h2kFdnData["rEff_SlabBG"] =  myOptions["Opt-FoundationSlabBelowGrade"]["options"][rEff_SlabBG]["h2kMap"]["base"]["H2K-Fdn-SlabBelowGradeReff"].to_f

      debug_out "Processing basements/crawlspaces with following specs:\n#{h2kFdnData.pretty_inspect}"

      H2KFile.updBsmCrawlDef(h2kFdnData,h2k_contents)


    end

    debug_out(drawRuler("Slab",". "))
    if ( rEff_SlabOG == "NA" )
      # do nothing!
      debug_out ("'NA' spec'd for on-grade slab. No changes needed\n")

    else
      bOGSlabInsul =  true if ( myOptions["Opt-FoundationSlabOnGrade"]["options"][rEff_SlabOG]["h2kMap"]["base"]["H2K-Fdn-SlabOnGradeReff"].to_f > 0.01 )
        
        h2kSlabData = Hash.new
      if ( ! bOGSlabInsul  ) then
        slabConfig = "SCN_1"
        h2kSlabData["?ogSlabIns"] = false
      else
        slabConfig = slabConfigInsulated
        h2kSlabData["?ogSlabIns"] = true
      end
                                   
      h2kSlabData["rEff_SlabOG"] = myOptions["Opt-FoundationSlabOnGrade"]["options"][rEff_SlabOG]["h2kMap"]["base"]["H2K-Fdn-SlabOnGradeReff"].to_f
      h2kSlabData["SlabConfig"] = slabConfig

      H2KFile.updSlabDef(h2kSlabData,h2k_contents)


    end

  end

  def H2KFile.updSlabDef (fdnData,h2kElements)
    debug_off


    debug_out ("FDN data:\n#{fdnData.pretty_inspect}\n")
    looplocation = "HouseFile/House/Components"

    h2kElements[looplocation].elements.each do | node |
      next if ( node.name != "Slab" )
      debug_out ("Processing node: #{node.name} ? \n")

      config_type = fdnData["SlabConfig"].split(/_/)[0]
      config_subtype= fdnData["SlabConfig"].split(/_/)[1]


      loc = ".//Configuration"
      node.elements[loc].attributes["type"] = config_type
      node.elements[loc].attributes["subtype"] = config_subtype
      node.elements[loc].text = fdnData["SlabConfig"]

      loc = ".//Floor"
      debug_out ( "Setting paramaters at #{loc}\n")
      node.elements["#{loc}/Construction"].attributes["heatedFloor"] = 'false'

      node.elements["#{loc}/Construction"].elements.delete("AddedToSlab")
      if ( ! fdnData["?ogSlabIns"] ) then

      else
        node.elements["#{loc}/Construction"].elements.add("AddedToSlab")

        node.elements[loc].elements.add("AddedToSlab")
        node.elements["#{loc}/Construction/AddedToSlab"].text = "User Specified"
        node.elements["#{loc}/Construction/AddedToSlab"].attributes["nominalInsulation"] = "#{((fdnData["rEff_SlabOG"].to_f)/R_PER_RSI).round(4)}"
        #HOT2000 v11.58 expects rValue - but values set to RSI ?!?! - possible h2k bug.
        node.elements["#{loc}/Construction/AddedToSlab"].attributes["rValue"] = "#{((fdnData["rEff_SlabOG"].to_f)/R_PER_RSI).round(4)}"

        debug_out "slab insulation R-value: #{node.elements["#{loc}/Construction/AddedToSlab"].attributes["rValue"] } \n"

      end

      node.elements.delete("Wall")
      node.elements.add("Wall")
      node.elements[".//Wall"].elements.add("RValues")
      node.elements[".//Wall/RValues"].attributes["skirt"] = '0'
      node.elements[".//Wall/RValues"].attributes["thermalBreak"] = '0'
    end

    return
  end

  # Update a basement definition to reflect new data.
  def H2KFile.updBsmCrawlDef(fdnData,h2kElements)

    #debug_on

    looplocation = "HouseFile/House/Components"

    h2kElements[looplocation].elements.each do | node |

      # Only work if basements, heated crawlspaces
      next if ( node.name != "Basement"   && node.name != "Crawlspace"               )
      next if ( node.name == "Crawlspace" && ! H2KFile.heatedCrawlspace(h2kElements) )

      label = node.elements[".//Label"].text

      debug_out "> updating definitions for #{node.name} '#{label}'\n"

      if ( node.name == "Basement" ) then
        debug_out(" ... basement code \n")
        config_type = fdnData["BasementConfig"].split(/_/)[0]
        config_subtype= fdnData["BasementConfig"].split(/_/)[1]

      elsif ( node.name == "Crawlspace" ) then
        debug_out(" ... crawlspace code \n")
        config_type = fdnData["CrawlConfig"].split(/_/)[0]
        config_subtype= fdnData["CrawlConfig"].split(/_/)[1]

      end

      debug_out(" setting configuration to #{config_type}, subtype #{config_subtype}\n")
      loc = ".//Configuration"

      node.elements[loc].attributes["type"] = config_type
      node.elements[loc].attributes["subtype"] = config_subtype

      node.elements[loc].attributes["overlap"] = "0" if ( node.name == "Basement" )

      node.elements[loc].text = fdnData["configuration"]

      loc = ".//Floor/Construction"
      node.elements[loc].attributes["isBelowFrostline"] = "true"
      node.elements[loc].attributes["hasIntegralFooting"] = "false"
      node.elements[loc].attributes["heatedFloor"] = "false"

      loc = ".//Wall/Construction/"
      node.elements[loc].elements.delete("InteriorAddedInsulation")
      if (!  fdnData["?IntWallIns"] ) then

      elsif ( node.name == "Basement") then

        debug_out "Adding definitions for interior wall insulation\n"
        node.elements[loc].elements.add("InteriorAddedInsulation")
        loc = ".//Wall/Construction/InteriorAddedInsulation"

        node.elements[loc].attributes["nominalInsulation"]= "#{((fdnData["rEffIntWall"].to_f)/R_PER_RSI).round(4)}"
        #   <Section nominalRsi='2.11' percentage='100' rank='1' rsi='1.7687'/>

        node.elements[loc].elements.add("Composite")


        node.elements["#{loc}/Composite"].elements.each do | section |
          debug_out " Deleting   node.elements[#{loc}/Composite].elements.delete(Section)\n"
          node.elements["#{loc}/Composite"].elements.delete("Section")
        end

        node.elements["#{loc}/Composite"].elements.add("Section")
        node.elements["#{loc}/Composite/Section"].attributes["nominalRsi"] = "#{((fdnData["rEffIntWall"].to_f)/R_PER_RSI).round(4)}"
        node.elements["#{loc}/Composite/Section"].attributes["percentage"] = "100"
        node.elements["#{loc}/Composite/Section"].attributes["rank"] = "1"
        node.elements["#{loc}/Composite/Section"].attributes["rsi"] = "#{(fdnData["rEffIntWall"].to_f/R_PER_RSI).round(4)}"

      end

      loc = ".//Wall/Construction/"
      node.elements[loc].elements.delete("ExteriorAddedInsulation")
      if ( ! fdnData["?ExtWallIns"] ) then

      elsif ( node.name == "Basement")
        debug_out "Adding definitions for exterior wall insulation\n"
        node.elements[loc].elements.add("ExteriorAddedInsulation")


        loc = ".//Wall/Construction/ExteriorAddedInsulation"

        node.elements[loc].attributes["nominalInsulation"]= "#{((fdnData["rEffExtWall"].to_f + 1.0)/R_PER_RSI).round(4)}"
        #   <Section nominalRsi='2.11' percentage='100' rank='1' rsi='1.7687'/>

        #node.elements["#{loc}/Composite"].elements.each do | section |
        #  debug_out "     deleting section tag (node.elements[#{loc}/Composite].elements.delete(Section))\n"
        #  node.elements["#{loc}/Composite"].elements.delete("Section")
        #end
        node.elements["#{loc}"].elements.add("Composite")
        node.elements["#{loc}/Composite"].elements.add("Section")
        node.elements["#{loc}/Composite/Section"].attributes["nominalRsi"] = "#{((fdnData["rEffExtWall"].to_f + 1.0)/R_PER_RSI).round(4)}"
        node.elements["#{loc}/Composite/Section"].attributes["percentage"] = "100"
        node.elements["#{loc}/Composite/Section"].attributes["rank"] = "1"
        node.elements["#{loc}/Composite/Section"].attributes["rsi"] = "#{(fdnData["rEffExtWall"].to_f/R_PER_RSI).round(4)}"
        debug_out "Ext wall RSI: #{(fdnData["rEffExtWall"].to_f/R_PER_RSI).round(4)}\n"
      end

      if (node.name == "Crawlspace" )
        loc = ".//Wall/Construction/Type"
        node.elements[loc].attributes.delete 'idref'
        node.elements["#{loc}/Description"].text = "User Defined"
        node.elements["#{loc}/Composite"].elements.each do | section |
          debug_out " Deleting   node.elements[#{loc}/Composite].elements.delete(Section)\n"
          node.elements["#{loc}/Composite"].elements.delete("Section")
        end
        node.elements["#{loc}/Composite"].elements.add("Section")
        node.elements["#{loc}/Composite/Section"].attributes["nominalRsi"] = "#{((fdnData["rEffIntWall"].to_f+fdnData["rEffExtWall"].to_f)/R_PER_RSI).round(4)}"
        node.elements["#{loc}/Composite/Section"].attributes["percentage"] = "100"
        node.elements["#{loc}/Composite/Section"].attributes["rank"] = "1"
        node.elements["#{loc}/Composite/Section"].attributes["rsi"] = "#{((fdnData["rEffIntWall"].to_f+fdnData["rEffExtWall"].to_f)/R_PER_RSI).round(4)}"
      end

      loc = ".//Floor/Construction"
      node.elements["#{loc}"].attributes["heatedFloor"] = 'false'
      node.elements[loc].elements.delete("AddedToSlab")
      if ( !  fdnData["?bgSlabIns"] ) then

      else
        debug_out "Adding definitions for under-slab insulation\n"
        #node.elements["#{loc}/Composite"].elements.each do | section |

        node.elements[loc].elements.add("AddedToSlab")
        node.elements["#{loc}/AddedToSlab"].text = "User Specified"
        node.elements["#{loc}/AddedToSlab"].attributes["nominalInsulation"] = "#{((fdnData["rEff_SlabBG"].to_f + 1.0)/R_PER_RSI).round(4)}"
        #HOT2000 v11.58 expects rValue - but values set to RSI ?!?! - possible h2k bug.
        node.elements["#{loc}/AddedToSlab"].attributes["rValue"] = "#{((fdnData["rEff_SlabBG"].to_f)/R_PER_RSI).round(4)}"
      end



    end

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


    #debug_on 
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
        x_path = "HouseFile/Codes/Window/Favorite"
      else
        x_path = "HouseFile/Codes/Window/UserDefined"
      end
      h2kFileElements.each(x_path + "/Code") do |element|
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
        if ( h2kFileElements[x_path] == nil )
          # No Favorite or UserDefined section in house file Codes section -- add it!
          if ( foundFavLibCode )
            h2kFileElements["HouseFile/Codes/Window"].add_element("Favorite")
          else
            h2kFileElements["HouseFile/Codes/Window"].add_element("UserDefined")
          end
        end
        foundCodeLibElement.attributes["id"] = $useThisCodeID[winOrient]
        h2kFileElements[x_path].add(foundCodeLibElement)
      end

      # Windows in walls elements
      x_path = "HouseFile/House/Components/Wall/Components/Window"
      h2kFileElements.each(x_path) do |element|
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
      x_path = "HouseFile/House/Components/Basement/Components/Window"
      h2kFileElements.each(x_path) do |element|
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
      x_path = "HouseFile/House/Components/Walkout/Components/Window"
      h2kFileElements.each(x_path) do |element|
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
      x_path = "HouseFile/House/Components/Crawlspace/Components/Window"
      h2kFileElements.each(x_path) do |element|
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
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList"
    elements[x_path].add_element("Hrv")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"
    elements[x_path].attributes["supplyFlowrate"] = "60"
    elements[x_path].attributes["exhaustFlowrate"] = "60"
    elements[x_path].attributes["fanPower1"] = "123.7"
    elements[x_path].attributes["isDefaultFanpower"] = "true"
    elements[x_path].attributes["isEnergyStar"] = "false"
    elements[x_path].attributes["isHomeVentilatingInstituteCertified"] = "false"
    elements[x_path].attributes["isSupplemental"] = "false"
    elements[x_path].attributes["temperatureCondition1"] = "0"
    elements[x_path].attributes["temperatureCondition2"] = "-25"
    elements[x_path].attributes["fanPower2"] = "145.6"
    elements[x_path].attributes["efficiency1"] = "64"
    elements[x_path].attributes["efficiency2"] = "64"
    elements[x_path].attributes["preheaterCapacity"] = "0"
    elements[x_path].attributes["lowTempVentReduction"] = "0"
    elements[x_path].attributes["coolingEfficiency"] = "25"
    elements[x_path].add_element("EquipmentInformation")
    elements[x_path].add_element("VentilatorType")

    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/VentilatorType"
    elements[x_path].attributes["code"] = "1"
    # HRV
    elements[x_path].add_element("English")
    elements[x_path].add_element("French")

    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"
    elements[x_path].add_element("ColdAirDucts")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts"
    elements[x_path].add_element("Supply")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply"
    elements[x_path].attributes["length"] = "1.5"
    elements[x_path].attributes["diameter"] = "152.4"
    elements[x_path].attributes["insulation"] = "0.7"
    elements[x_path].add_element("Location")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply/Location"
    elements[x_path].attributes["code"] = "4"
    # Main Floor
    elements[x_path].add_element("English")
    elements[x_path].add_element("French")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply"
    elements[x_path].add_element("Type")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply/Type"
    elements[x_path].attributes["code"] = "1"
    # Flexible
    elements[x_path].add_element("English")
    elements[x_path].add_element("French")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply"
    elements[x_path].add_element("Sealing")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply/Sealing"
    elements[x_path].attributes["code"] = "2"
    # Sealed
    elements[x_path].add_element("English")
    elements[x_path].add_element("French")

    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts"
    elements[x_path].add_element("Exhaust")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust"
    elements[x_path].attributes["length"] = "1.5"
    elements[x_path].attributes["diameter"] = "152.4"
    elements[x_path].attributes["insulation"] = "0.7"
    elements[x_path].add_element("Location")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust/Location"
    elements[x_path].attributes["code"] = "4"
    # Main Floor
    elements[x_path].add_element("English")
    elements[x_path].add_element("French")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust"
    elements[x_path].add_element("Type")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust/Type"
    elements[x_path].attributes["code"] = "1"
    # Flexible
    elements[x_path].add_element("English")
    elements[x_path].add_element("French")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust"
    elements[x_path].add_element("Sealing")
    x_path = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust/Sealing"
    elements[x_path].attributes["code"] = "2"
    # Sealed
    elements[x_path].add_element("English")
    elements[x_path].add_element("French")
  end 

  # =========================================================================================
  # Add a System Type 1 section (check for existence done external to this method)
  # =========================================================================================
  def H2KTemplates.createH2KSysType1( elements, sysType1Name )
    debug_on 
    debug_out("Creating type 1 definition - #{sysType1Name}")
    x_path = "HouseFile/House/HeatingCooling/Type1"

    elements[x_path].add_element(sysType1Name)
    if ( sysType1Name == "Baseboards" )
      x_path = "HouseFile/House/HeatingCooling/Type1/Baseboards"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type1/Baseboards/EquipmentInformation"
      elements[x_path].attributes["numberOfElectronicThermostats"] = "0"

      x_path = "HouseFile/House/HeatingCooling/Type1/Baseboards"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type1/Baseboards/Specifications"
      elements[x_path].attributes["sizingFactor"] = "1.1"
      elements[x_path].attributes["efficiency"] = "100"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type1/Baseboards/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      # Calculated
      elements[x_path].attributes["value"] = "0"
      # Calculated value - will be replaced!
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

    elsif ( sysType1Name == "Furnace" )


      debug_out ("ADDING FURNACE ....\n")

      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/EquipmentInformation"
      elements[x_path].attributes["energystar"] = "false"
      elements[x_path].add_element("Manufacturer")

      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment"
      elements[x_path].attributes["isBiEnergy"] = "false"
      elements[x_path].attributes["switchoverTemperature"] = "0"
      elements[x_path].add_element("EnergySource")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EnergySource"
      elements[x_path].attributes["code"] = "2"
      # Gas
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment"
      elements[x_path].add_element("EquipmentType")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EquipmentType"
      elements[x_path].attributes["code"] = "1"
      # Furnace with cont. pilot
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Specifications"
      elements[x_path].attributes["sizingFactor"] = "1.1"
      elements[x_path].attributes["efficiency"] = "78"
      elements[x_path].attributes["isSteadyState"] = "true"
      elements[x_path].attributes["pilotLight"] = "0"
      elements[x_path].attributes["flueDiameter"] = "127"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type1/Furnace/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      # Calculated
      elements[x_path].attributes["value"] = "0"
      # Calculated value - will be replaced!
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

    elsif ( sysType1Name == "Boiler" )
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/EquipmentInformation"
      elements[x_path].attributes["energystar"] = "false"
      elements[x_path].add_element("Manufacturer")

      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment"
      elements[x_path].attributes["isBiEnergy"] = "false"
      elements[x_path].attributes["switchoverTemperature"] = "0"
      elements[x_path].add_element("EnergySource")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment/EnergySource"
      elements[x_path].attributes["code"] = "2"
      # Gas
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment"
      elements[x_path].add_element("EquipmentType")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment/EquipmentType"
      elements[x_path].attributes["code"] = "1"
      # Boiler with cont. pilot
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Specifications"
      elements[x_path].attributes["sizingFactor"] = "1.1"
      elements[x_path].attributes["efficiency"] = "78"
      elements[x_path].attributes["isSteadyState"] = "true"
      elements[x_path].attributes["pilotLight"] = "0"
      elements[x_path].attributes["flueDiameter"] = "127"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type1/Boiler/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      # Calculated
      elements[x_path].attributes["value"] = "0"
      # Calculated value - will be replaced!
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

    elsif ( sysType1Name == "ComboHeatDhw" )
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/EquipmentInformation"
      elements[x_path].attributes["energystar"] = "false"
      elements[x_path].add_element("Manufacturer")

      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment"
      elements[x_path].add_element("EnergySource")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment/EnergySource"
      elements[x_path].attributes["code"] = "2"
      # Gas
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment"
      elements[x_path].add_element("EquipmentType")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment/EquipmentType"
      elements[x_path].attributes["code"] = "1"
      # ComboHeatDhw with cont. pilot
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Specifications"
      elements[x_path].attributes["sizingFactor"] = "1.1"
      elements[x_path].attributes["efficiency"] = "78"
      elements[x_path].attributes["isSteadyState"] = "true"
      elements[x_path].attributes["pilotLight"] = "25.3"
      elements[x_path].attributes["flueDiameter"] = "152.4"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      # Calculated
      elements[x_path].attributes["value"] = "0"
      # Calculated value - will be replaced!
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[x_path].add_element("ComboTankAndPump")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[x_path].add_element("TankCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump/TankCapacity"
      elements[x_path].attributes["code"] = "3"
      elements[x_path].attributes["value"] = "151.4"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[x_path].add_element("EnergyFactor")
      elements[x_path].attributes["useDefaults"] = "true"
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[x_path].add_element("TankLocation")
      elements[x_path].attributes["code"] = "2"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[x_path].add_element("CirculationPump")
      elements[x_path].attributes["isCalculated"] = "true"
      elements[x_path].attributes["value"] = "0"
      elements[x_path].attributes["hasEnergyEfficientMotor"] = "false"

    elsif ( sysType1Name == "P9" )
      x_path = "HouseFile/House/HeatingCooling/Type1/P9"
      elements[x_path].attributes["id"] = "0"
      elements[x_path].attributes["numberOfSystems"] = "1"
      elements[x_path].attributes["thermalPerformanceFactor"] = "0.9"
      elements[x_path].attributes["annualElectricity"] = "1800"
      elements[x_path].attributes["spaceHeatingCapacity"] = "23900"
      elements[x_path].attributes["spaceHeatingEfficiency"] = "90"
      elements[x_path].attributes["waterHeatingPerformanceFactor"] = "0.9"
      elements[x_path].attributes["burnerInput"] = "0"
      elements[x_path].attributes["recoveryEfficiency"] = "0"
      elements[x_path].attributes["isUserSpecified"] = "true"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/EquipmentInformation"
      elements[x_path].add_element("Manufacturer")
      elements[x_path].add_element("Model")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/EquipmentInformation/Manufacturer"
      elements[x_path].text = "Generic"
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/EquipmentInformation/Model"
      elements[x_path].text = "Generic"

      x_path = "HouseFile/House/HeatingCooling/Type1/P9"
      elements[x_path].add_element("TestData")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[x_path].attributes["controlsPower"] = "10"
      elements[x_path].attributes["circulationPower"] = "130"
      elements[x_path].attributes["dailyUse"] = "0.2"
      elements[x_path].attributes["standbyLossWithFan"] = "0"
      elements[x_path].attributes["standbyLossWithoutFan"] = "0"
      elements[x_path].attributes["oneHourRatingHotWater"] = "1000"
      elements[x_path].attributes["oneHourRatingConcurrent"] = "1000"
      elements[x_path].add_element("EnergySource")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData/EnergySource"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[x_path].add_element("NetEfficiency")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData/NetEfficiency"
      elements[x_path].attributes["loadPerformance15"] = "80"
      elements[x_path].attributes["loadPerformance40"] = "80"
      elements[x_path].attributes["loadPerformance100"] = "80"
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[x_path].add_element("ElectricalUse")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData/ElectricalUse"
      elements[x_path].attributes["loadPerformance15"] = "100"
      elements[x_path].attributes["loadPerformance40"] = "200"
      elements[x_path].attributes["loadPerformance100"] = "300"
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[x_path].add_element("BlowerPower")
      x_path = "HouseFile/House/HeatingCooling/Type1/P9/TestData/BlowerPower"
      elements[x_path].attributes["loadPerformance15"] = "300"
      elements[x_path].attributes["loadPerformance40"] = "500"
      elements[x_path].attributes["loadPerformance100"] = "800"
    end
  end
  # createH2KSysType1

  # =========================================================================================
  # Procedure to create a new H2K system Type 2 in the XML house file. Check done external.
  # =========================================================================================
  def H2KTemplates.createH2KSysType2( elements, sysType2Name )
    debug_on 
    debug_out("Creating type 2 definition - #{sysType2Name}")
    x_path = "HouseFile/House/HeatingCooling/Type2"
    elements[x_path].add_element(sysType2Name)
    elements[x_path].attributes["shadingInF280Cooling"] = "AccountedFor"

    if ( sysType2Name == "AirHeatPump" )

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[x_path].add_element("EquipmentInformation")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/EquipmentInformation"
      elements[x_path].attributes["energystar"] = "false"

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[x_path].add_element("Equipment")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment"
      elements[x_path].attributes["crankcaseHeater"] = "60"
      elements[x_path].add_element("Type")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment/Type"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment"
      elements[x_path].add_element("Function")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment/Function"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[x_path].add_element("Specifications")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications"
      elements[x_path].add_element("OutputCapacity")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      # I think these can be commented out if we default to 'calculated'
      #elements[x_path].attributes["value"] = ""
      #elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications"
      elements[x_path].add_element("HeatingEfficiency")
      elements[x_path].add_element("CoolingEfficiency")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications/HeatingEfficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "2"

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications/CoolingEfficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "2"

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[x_path].add_element("Temperature")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature"
      elements[x_path].add_element("CutoffType")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature/CutoffType"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].attributes["value"] = "0"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature"
      elements[x_path].add_element("RatingType")

      # CHECK this - should be 8.3 ?

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature/RatingType"
      elements[x_path].attributes["code"] = "3"
      elements[x_path].attributes["value"] = "-5.0"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[x_path].add_element("CoolingParameters")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters"
      elements[x_path].attributes["sensibleHeatRatio"] = "0.76"
      elements[x_path].attributes["openableWindowArea"] = "20"

      elements[x_path].add_element("FansAndPump")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters/FansAndPump"
      # Do we need to set this? what should we set it to?
      elements[x_path].attributes["flowRate"] = "700"

      elements[x_path].add_element("Mode")
      elements[x_path].add_element("Power")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters/FansAndPump/Mode"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters/FansAndPump/Power"
      elements[x_path].attributes["isCalculated"] = "true"

    elsif ( sysType2Name == "WaterHeatPump" )
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/EquipmentInformation"
      elements[x_path].attributes["canCsaC448"] = "false"

      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Equipment"
      elements[x_path].attributes["crankcaseHeater"] = "0"
      elements[x_path].add_element("Function")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Equipment/Function"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].attributes["value"] = "21.5"
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications"
      elements[x_path].add_element("HeatingEfficiency")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications/HeatingEfficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "3"

      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[x_path].add_element("Temperature")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature"
      elements[x_path].add_element("CutOffType")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature/CutOffType"
      elements[x_path].attributes["code"] = "3"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature"
      elements[x_path].add_element("RatingType")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature/RatingType"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].attributes["value"] = "8.3"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[x_path].add_element("SourceTemperature")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/SourceTemperature"
      elements[x_path].attributes["depth"] = "1.5"
      elements[x_path].add_element("Use")
      x_path = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/SourceTemperature/Use"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

    elsif ( sysType2Name == "GroundHeatPump" )
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/EquipmentInformation"
      elements[x_path].attributes["canCsaC448"] = "false"

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Equipment"
      elements[x_path].attributes["crankcaseHeater"] = "0"
      elements[x_path].add_element("Function")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Equipment/Function"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications"
      elements[x_path].add_element("OutputCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications/OutputCapacity"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].attributes["value"] = "21.5"
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications"
      elements[x_path].add_element("HeatingEfficiency")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications/HeatingEfficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "3"
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications"
      elements[x_path].add_element("CoolingEfficiency")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications/CoolingEfficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "3"

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("Temperature")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature"
      elements[x_path].add_element("CutoffType")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature/CutoffType"
      elements[x_path].attributes["code"] = "3"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature"
      elements[x_path].add_element("RatingType")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature/RatingType"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].attributes["value"] = "8.3"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("SourceTemperature")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/SourceTemperature"
      elements[x_path].attributes["depth"] = "1.5"
      elements[x_path].add_element("Use")
      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/SourceTemperature/Use"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[x_path].add_element("CoolingParameters")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters"
      elements[x_path].attributes["sensibleHeatRatio"] = "0.76"
      elements[x_path].attributes["openableWindowArea"] = "20"

      elements[x_path].add_element("FansAndPump")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters/FansAndPump"
      # Do we need to set this? what should we set it to?
      elements[x_path].attributes["flowRate"] = "360"

      elements[x_path].add_element("Mode")
      elements[x_path].add_element("Power")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters/FansAndPump/Mode"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters/FansAndPump/Power"
      elements[x_path].attributes["isCalculated"] = "true"

    elsif ( sysType2Name == "AirConditioning" )
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[x_path].add_element("EquipmentInformation")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/EquipmentInformation"
      elements[x_path].attributes["energystar"] = "false"

      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[x_path].add_element("Equipment")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Equipment"
      elements[x_path].attributes["crankcaseHeater"] = "60"
      elements[x_path].add_element("CentralType")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Equipment/CentralType"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")

      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[x_path].add_element("Specifications")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications"
      elements[x_path].attributes["sizingFactor"] = "1"
      elements[x_path].add_element("RatedCapacity")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications/RatedCapacity"
      elements[x_path].attributes["code"] = "2"
      elements[x_path].attributes["value"] = "0"
      elements[x_path].attributes["uiUnits"] = "kW"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications"
      elements[x_path].add_element("Efficiency")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications/Efficiency"
      elements[x_path].attributes["isCop"] = "true"
      elements[x_path].attributes["value"] = "3"

      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[x_path].add_element("CoolingParameters")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters"
      elements[x_path].attributes["sensibleHeatRatio"] = "0.76"
      elements[x_path].attributes["openableWindowArea"] = "20"
      elements[x_path].add_element("FansAndPump")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump"
      elements[x_path].attributes["flowRate"] = "0"
      elements[x_path].add_element("Mode")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump/Mode"
      elements[x_path].attributes["code"] = "1"
      elements[x_path].add_element("English")
      elements[x_path].add_element("French")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump"
      elements[x_path].add_element("Power")
      x_path = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump/Power"
      elements[x_path].attributes["isCalculated"] = "true"
    end
  end
  # createH2KSysType2


end 



# Functions related to h2k data model, but that might one day be abstracted elsewhere
module H2KMisc
  def H2KMisc.getF326FlowRates( elements )
    x_path = "HouseFile/House/Ventilation/Rooms"
    roomLabels = [ "living", "bedrooms", "bathrooms", "utility", "otherHabitable" ]
    ventRequired = 0
    roomLabels.each do |roommName|
      if(roommName == "living" || roommName == "bathrooms" || roommName == "utility" || roommName == "otherHabitable")
        numRooms = elements[x_path].attributes[roommName].to_i
        ventRequired += (numRooms*5)
        #print "Room is ",roommName, " and number is ",numRooms, ". Total vent required is ", ventRequired, "\n"
      elsif(roommName == "bedrooms")
        numRooms = elements[x_path].attributes[roommName].to_i
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
    keep_trying = true
    tries = 0
    max_tries = 3 
    maxRunTime = 60
    pid = 0 
    run_ok = false 
    

    run_path = $gMasterPath + "/H2K"
  

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
          keep_trying = false
          run_ok = true 

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
  
    return run_ok, lapsed_time

  end 
end



# =========================================================================================
# H2Kpost: routines that extract hot2000 tesults
# =========================================================================================

module H2Kpost

  # This function collects data fom various parts of the HTA data model and coolates 
  # it into a digestable/outputable hash.
  def H2Kpost.handle_sim_results(h2k_file_name,choices,agent_data)
    stream_out("  -> Loading XML elements from #{h2k_file_name}\n")
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

    # return results / Archetype description
    results["archetype"] = {
      "h2k-File"  => File.split(h2k_file_name)[1], 
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
      "Exterior-Envelope-Area-m2"   =>  env_info["envelope"]["envelope_area_m2"],
      "AreaWeighted-Uvalue-excl-Infiltration-W-per-m2K"   =>  env_info["envelope"]["areaWeightedUvalue_excl_Infiltration_W_per_m2K"],
      "AreaWeighted-Uvalue-incl-Infiltration-W-per-m2K"   =>  env_info["envelope"]["areaWeightedUvalue_incl_Infiltration_W_per_m2K"]
    }

    # Window data 
    if ($cmdlineopts["extra_output"]) then 
      results["archetype"]["Win-SHGC-S"     ]  = env_info["windows"]["by_orientation"]["SHGC"][1]
      results["archetype"]["Win-SHGC-SE"    ]  = env_info["windows"]["by_orientation"]["SHGC"][2]
      results["archetype"]["Win-SHGC-E"     ]  = env_info["windows"]["by_orientation"]["SHGC"][3]
      results["archetype"]["Win-SHGC-NE"    ]  = env_info["windows"]["by_orientation"]["SHGC"][4]
      results["archetype"]["Win-SHGC-N"     ]  = env_info["windows"]["by_orientation"]["SHGC"][5]
      results["archetype"]["Win-SHGC-NW"    ]  = env_info["windows"]["by_orientation"]["SHGC"][6]
      results["archetype"]["Win-SHGC-W"     ]  = env_info["windows"]["by_orientation"]["SHGC"][7]
      results["archetype"]["Win-SHGC-SW"    ]  = env_info["windows"]["by_orientation"]["SHGC"][8]
      results["archetype"]["Win-UValue-S"   ]  = env_info["windows"]["by_orientation"]["Uvalue"][1]
      results["archetype"]["Win-UValue-SE"  ]  = env_info["windows"]["by_orientation"]["Uvalue"][2]
      results["archetype"]["Win-UValue-E"   ]  = env_info["windows"]["by_orientation"]["Uvalue"][3]
      results["archetype"]["Win-UValue-NE"  ]  = env_info["windows"]["by_orientation"]["Uvalue"][4]
      results["archetype"]["Win-UValue-N"   ]  = env_info["windows"]["by_orientation"]["Uvalue"][5]
      results["archetype"]["Win-UValue-NW"  ]  = env_info["windows"]["by_orientation"]["Uvalue"][6]
      results["archetype"]["Win-UValue-W"   ]  = env_info["windows"]["by_orientation"]["Uvalue"][7]
      results["archetype"]["Win-UValue-SW"  ]  = env_info["windows"]["by_orientation"]["Uvalue"][8]
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


    

 
    # INPUT ! 
    results["input"] = { 
    #  "Run-Region" =>  "#{$gRunRegion}",
    #  "Run-Locale" =>  "#{$gRunLocale}",
    #  "House-Upgraded"   =>  "#{$houseUpgraded}",
    #  "House-ListOfUpgrades" => "#{$houseUpgradeList}",
    #  "Ruleset-Fuel-Source" => "#{$gRulesetSpecs["fuel"]}",
    #  "Ruleset-Ventilation" => "#{$gRulesetSpecs["vent"]}"
    }
    
    # Designate house as upgraded or not, and prepare list of upgrades as a string
    
    house_upgraded, list_of_upgrades = HTAPData.upgrade_status(choices)
    #debug_on 
    debug_out "> upgraded >  #{house_upgraded} "
    debug_out "> list >  #{list_of_upgrades} "
    results["input"]["upgraded"] = house_upgraded
    results["input"]["upgrades_applied"] = list_of_upgrades


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

    results["ref_house"] = {}
    res_data["ref_house"].each do | column, value  |
      results["ref_house"][column] = value 
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

    agent_data.keys.each do | agent_var |
      results["status"][agent_var] = agent_data[agent_var]
    end 


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
    #      "Infil-VentHeatLoss-GJ" => $gResults[$outputHCode]["VentAndInfilGJ"].round(1),
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

  # Recover simulation results from the h2k file 
  def H2Kpost.get_results_from_elements(res_e,program)
    debug_on 
    xmlpath = "HouseFile/AllResults"

    monthArr = [ "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december" ]

    myResults = {
      "std_output" => Hash.new,
      "extra_output" => Hash.new,
      "ref_house" => Hash.new 
    } 

    found_the_set = false

    if ( program == "ERS" or  program == "NBC" or program == "ON" )
      code = "SOC"
    else 
      code = "General"
    end 

    #debug_on
    debug_out ("Parsing results for code: #{program} / #{code}")
    

    compute_nbc_compliance = false 

    res_e["HouseFile/AllResults"].elements.each do |element|

      this_set_code = element.attributes["houseCode"]
      if (this_set_code == nil && element.attributes["sha256"] != nil)
        this_set_code = "General"
      end

      debug_out "Result-set: #{this_set_code}"
      
      if ( this_set_code != code ) then 
        next 
      end 

      

      found_the_set = true 
      debug_out ("Parsing code #{this_set_code}")

      myResults["std_output"]["EnergyTotalGJ"]        = element.elements[".//Annual/Consumption"].attributes["total"].to_f  
      myResults["std_output"]["EnergyHeatingGJ"]      = element.elements[".//Annual/Consumption/SpaceHeating"].attributes["total"].to_f  
      myResults["std_output"]["GrossHeatLossGJ"]      = element.elements[".//Annual/HeatLoss"].attributes["total"].to_f  
      myResults["std_output"]["VentAndInfilGJ"]       = element.elements[".//Annual/HeatLoss"].attributes["airLeakageAndNaturalVentilation"].to_f  
      myResults["std_output"]["EnergyCoolingGJ"]      = element.elements[".//Annual/Consumption/Electrical"].attributes["airConditioning"].to_f  
      myResults["std_output"]["EnergyVentilationGJ"]  = element.elements[".//Annual/Consumption/Electrical"].attributes["ventilation"].to_f  
      myResults["std_output"]["EnergyEquipmentGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["baseload"].to_f  
      myResults["std_output"]["EnergyWaterHeatingGJ"] = element.elements[".//Annual/Consumption/HotWater"].attributes["total"].to_f  
      myResults["std_output"]["HeatLossGrossEnvelopeGJ"] = element.elements[".//Annual/HeatLoss"].attributes["total"].to_f  

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

      myResults["std_output"]["OthSeasonalHeatEff"] = element.elements[".//Other"].attributes["seasonalHeatEfficiency"].to_f  
      myResults["extra_output"]["VntAirChangeRateNatural"] = element.elements[".//Annual/AirChangeRate"].attributes["natural"].to_f  
      myResults["extra_output"]["VntAirChangeRateTotal"] = element.elements[".//Annual/AirChangeRate"].attributes["total"].to_f  
      myResults["extra_output"]["SolarGainsUtilized"] = element.elements[".//Annual/UtilizedSolarGains"].attributes["value"].to_f  
      myResults["extra_output"]["VntMinAirChangeRate"] = element.elements[".//Other/Ventilation"].attributes["minimumAirChangeRate"].to_f  

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

      
      myResults["std_output"]["FueluseElecGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["total"].to_f  
      myResults["std_output"]["FueluseNatGasGJ"]  = element.elements[".//Annual/Consumption/NaturalGas"].attributes["total"].to_f  
      myResults["std_output"]["FueluseOilGJ"]     = element.elements[".//Annual/Consumption/Oil"].attributes["total"].to_f  
      myResults["std_output"]["FuelusePropaneGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["total"].to_f  
      myResults["std_output"]["FueluseWoodGJ"]    = element.elements[".//Annual/Consumption/Wood"].attributes["total"].to_f  

      myResults["std_output"]["FueluseEleckWh"]  = myResults["std_output"]["FueluseElecGJ"] * 277.77777778
      myResults["std_output"]["FueluseNatGasM3"] = myResults["std_output"]["FueluseNatGasGJ"] * 26.853
      myResults["std_output"]["FueluseOilL"]     = myResults["std_output"]["FueluseOilGJ"]  * 25.9576
      myResults["std_output"]["FuelusePropaneL"] = myResults["std_output"]["FuelusePropaneGJ"] / 25.23 * 1000
      myResults["std_output"]["FueluseWoodcord"] = myResults["std_output"]["FueluseWoodGJ"] / 18.30
      #debug_out (" Picking up  AUX energy requirement from each result set. \n")

      myResults["std_output"]["auxEnergyHeatingGJ"] = 0
      $MonthlyAuxHeatingMJ = 0
      monthArr.each do |mth|
        myResults["std_output"]["auxEnergyHeatingGJ"] += element.elements[".//Monthly/UtilizedAuxiliaryHeatRequired"].attributes[mth].to_f / 1000
      end

      myResults["std_output"]["regulatedEnergyUseGJ"] =  
        myResults["std_output"]["EnergyWaterHeatingGJ"] + 
        myResults["std_output"]["EnergyHeatingGJ"] + 
        myResults["std_output"]["EnergyCoolingGJ"] + 
        myResults["std_output"]["EnergyVentilationGJ"] 


    end

    # For NBC, parse reference house data too
    if ( program == "NBC" )
      res_e["HouseFile/AllResults"].elements.each do |element|
        this_set_code = element.attributes["houseCode"]
        next if (this_set_code != "Reference")
            
        debug_out "Getting reference house data from result set '#{this_set_code}'"
        myResults["ref_house"]["EnergyTotalGJ"]        = element.elements[".//Annual/Consumption"].attributes["total"].to_f  
        myResults["ref_house"]["EnergyHeatingGJ"]      = element.elements[".//Annual/Consumption/SpaceHeating"].attributes["total"].to_f  
        myResults["ref_house"]["GrossHeatLossGJ"]      = element.elements[".//Annual/HeatLoss"].attributes["total"].to_f  
        myResults["ref_house"]["VentAndInfilGJ"]       = element.elements[".//Annual/HeatLoss"].attributes["airLeakageAndNaturalVentilation"].to_f  
        myResults["ref_house"]["EnergyCoolingGJ"]      = element.elements[".//Annual/Consumption/Electrical"].attributes["airConditioning"].to_f  
        myResults["ref_house"]["EnergyVentilationGJ"]  = element.elements[".//Annual/Consumption/Electrical"].attributes["ventilation"].to_f  
        myResults["ref_house"]["EnergyEquipmentGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["baseload"].to_f  
        myResults["ref_house"]["EnergyWaterHeatingGJ"] = element.elements[".//Annual/Consumption/HotWater"].attributes["total"].to_f  

        myResults["ref_house"]["Design_Heating_Load_W"] = element.elements[".//Other"].attributes["designHeatLossRate"].to_f  
        myResults["ref_house"]["Design_Cooling_Load_W"] = element.elements[".//Other"].attributes["designCoolLossRate"].to_f  
          
        myResults["ref_house"]["auxEnergyHeatingGJ"] = 0
        monthArr.each do |mth|
          myResults["ref_house"]["auxEnergyHeatingGJ"] += element.elements[".//Monthly/UtilizedAuxiliaryHeatRequired"].attributes[mth].to_f / 1000
        end 
        
        myResults["ref_house"]["regulatedEnergyUseGJ"] = 
          myResults["ref_house"]["EnergyWaterHeatingGJ"] +
          myResults["ref_house"]["EnergyHeatingGJ"] +
          myResults["ref_house"]["EnergyCoolingGJ"] +
          myResults["ref_house"]["EnergyVentilationGJ"] 

        myResults["ref_house"]["HeatLossGrossEnvelopeGJ"] = element.elements[".//Annual/HeatLoss"].attributes["total"].to_f  

        compute_nbc_compliance = true 

        myResults["ref_house"]["nbcEnvelopeImprovement"] = 
          (  myResults["ref_house"]["HeatLossGrossEnvelopeGJ"] - myResults["std_output"]["HeatLossGrossEnvelopeGJ"] ) / myResults["ref_house"]["HeatLossGrossEnvelopeGJ"]
        myResults["ref_house"]["nbcOverallImprovement"]  = (  myResults["ref_house"]["regulatedEnergyUseGJ"] -  myResults["std_output"]["regulatedEnergyUseGJ"] ) / myResults["ref_house"]["regulatedEnergyUseGJ"]




      end 

    else 
      
      debug_out "Setting reference house data to nil "
      myResults["ref_house"]["EnergyTotalGJ"]        = " " 
      myResults["ref_house"]["EnergyHeatingGJ"]      = " "
      myResults["ref_house"]["GrossHeatLossGJ"]      = " "
      myResults["ref_house"]["VentAndInfilGJ"]       = " " 
      myResults["ref_house"]["EnergyCoolingGJ"]      = " "
      myResults["ref_house"]["EnergyVentilationGJ"]  = " "
      myResults["ref_house"]["EnergyEquipmentGJ"]    = " "
      myResults["ref_house"]["EnergyWaterHeatingGJ"] = " "
      myResults["ref_house"]["Design_Heating_Load_W"]   = " "
      myResults["ref_house"]["Design_Cooling_Load_W"]   = " "
        

    
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

  # Stub to read diagnostic output (maybe used in the future! )
  def H2Kpost.read_routstr
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
      log_out ("Created a new h2k directory")
      FileUtils.cp_r("#{src_path}/.", "#{dest_path}")
      stream_out (" (done)\n")
    else 
      log_out "h2k directory exists - no need to copy a new one"
    end

    stream_out ("    Checking integrity of H2K installation:\n")
    
    masterMD5  = checksum("#{src_path}").to_s
    workingMD5 = checksum("#{dest_path}").to_s

    stream_out ("    - master:        #{masterMD5}\n")
    stream_out ("    - working copy:  #{workingMD5}")


    if (masterMD5.eql? workingMD5) then
      log_out("H2K file checksum matches master. All OK")
      stream_out(" (checksum match)\n")

      $gStatus["MD5master"] = $masterMD5.to_s
      $gStatus["MD5workingcopy"] = $workingMD5.to_s
      $gStatus["H2KDirCopyAttempts"] = $CopyTries.to_s
      $gStatus["H2KDirCheckSumMatch"] = $DirVerified

    else
      log_out("H2K file checksum does not match master. Deleting copy")
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
