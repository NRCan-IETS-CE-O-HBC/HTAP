# ==========================================
# H2KUtils.rb: functions used
# to query, manipulate hot2000 files and
# the h2k environment.
# ==========================================

module H2KFile

  # =========================================================================================
  # Returns XML elements of HOT2000 file.
  # =========================================================================================
  def H2KFile.get_elements_from_filename(fileSpec)

    # Split fileSpec into path and filename
    var = Array.new()
    (var[1], var[2]) = File.split( fileSpec )
    # Determine file extension
    tempExt = File.extname(var[2])

    debug_out "Testing file read location, #{fileSpec}... "


    # Open file...
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
    fFileHANDLE.close() # Close the since content read

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

  def H2KFile.getHouseType(elements)

    myHouseType = elements["HouseFile/House/Specifications/HouseType/English"].text
    if myHouseType !=nil
      myHouseType.gsub!(/\s*/, '')    # Removes mid-line white space
      myHouseType.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end



    return myHouseType

  end

  def H2KFile.getStories(elements)
    myHouseStoreys = elements["HouseFile/House/Specifications/Storeys/English"].text
    if myHouseStoreys!= nil
      myHouseStoreys.gsub!(/\s*/, '')    # Removes mid-line white space
      myHouseStoreys.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end

    return myHouseStoreys

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

  def H2KFile.GetHouseVolume(elements)

    myHouseVolume= elements["HouseFile/House/NaturalAirInfiltration/Specifications/House"].attributes["volume"].to_f

    return myHouseVolume

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
  # Get the name of the base file weather city
  # =========================================================================================
  def H2KFile.getRegion(elements)

     myRegionCode = elements["HouseFile/ProgramInformation/Weather/Region"].attributes["code"].to_i

     myRegionName = $ProvArr[myRegionCode-1]

     return myRegionName

  end


  # =========================================================================================
  #  Function to create the Program XML section that contains the ERS program mode data
  # =========================================================================================
  def H2KFile.createProgramXMLSection( elements )
     loc = "HouseFile"
     elements[loc].add_element("Program")

     loc = "HouseFile/Program"
     elements[loc].attributes["class"] = "ca.nrcan.gc.OEE.ERS.ErsProgram"
     elements[loc].add_element("Labels")

     loc = "HouseFile/Program/Labels"
     elements[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
     elements[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
     elements[loc].add_element("English")
     loc = "HouseFile/Program/Labels/English"
     elements[loc].add_text("EnerGuide Rating System")
     loc = "HouseFile/Program/Labels"
     elements[loc].add_element("French")
     loc = "HouseFile/Program/Labels/French"
     elements[loc].add_text("Système de cote ÉnerGuide")

     loc = "HouseFile/Program"
     elements[loc].add_element("Version")
     loc = "HouseFile/Program/Version"
     elements[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
     elements[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
     elements[loc].attributes["major"] = "15"
     elements[loc].attributes["minor"] = "1"
     elements[loc].attributes["build"] = "19"
     elements[loc].add_element("Labels")
     loc = "HouseFile/Program/Version/Labels"
     elements[loc].add_element("English")
     loc = "HouseFile/Program/Labels/English"
     elements[loc].add_text("v15.1b19")
     loc = "HouseFile/Program/Version/Labels"
     elements[loc].add_element("French")
     loc = "HouseFile/Program/Labels/French"
     elements[loc].add_text("v15.1b19")

     loc = "HouseFile/Program"
     elements[loc].add_element("SdkVersion")
     loc = "HouseFile/Program/SdkVersion"
     elements[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
     elements[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
     elements[loc].attributes["major"] = "1"
     elements[loc].attributes["minor"] = "11"
     elements[loc].add_element("Labels")
     loc = "HouseFile/Program/SdkVersion/Labels"
     elements[loc].add_element("English")
     loc = "HouseFile/Program/Labels/English"
     elements[loc].add_text("v1.11")
     loc = "HouseFile/Program/SdkVersion/Labels"
     elements[loc].add_element("French")
     loc = "HouseFile/Program/Labels/French"
     elements[loc].add_text("v1.11")

     loc = "HouseFile/Program"
     elements[loc].add_element("Options")
     loc = "HouseFile/Program/Options"
     elements[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
     elements[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
     elements[loc].add_element("Main")
     loc = "HouseFile/Program/Options/Main"
     elements[loc].attributes["applyHouseholdOperatingConditions"] = "false"
     elements[loc].attributes["applyReducedOperatingConditions"] = "false"
     elements[loc].attributes["atypicalElectricalLoads"] = "false"
     elements[loc].attributes["waterConservation"] = "false"
     elements[loc].attributes["referenceHouse"] = "false"
     elements[loc].add_element("Vermiculite")
     loc = "HouseFile/Program/Options/Main/Vermiculite"
     elements[loc].attributes["code"] = "1"
     elements[loc].add_element("English")
     loc = "HouseFile/Program/Options/Main/Vermiculite/English"
     elements[loc].add_text("Unknown")
     loc = "HouseFile/Program/Options/Main/Vermiculite"
     elements[loc].add_element("French")
     loc = "HouseFile/Program/Options/Main/Vermiculite/French"
     elements[loc].add_text("Inconnu")
     loc = "HouseFile/Program/Options"
     elements[loc].add_element("RURComments")
     loc = "HouseFile/Program/Options/RURComments"
     elements[loc].attributes["xml:space"] = "preserve"

     loc = "HouseFile/Program"
     elements[loc].add_element("Results")
     loc = "HouseFile/Program/Results"
     elements[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
     elements[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
     elements[loc].add_element("Tsv")
     elements[loc].add_element("Ers")
     elements[loc].add_element("RefHse")

  end


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
                                     8=>0 }


      locationText = "HouseFile/House/Components/*/Components/Window"
      elements.each(locationText) do |window|

        thisWindowOrient = window.elements["FacingDirection"].attributes["code"].to_i # Windows orientation:  "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8
        thisWindowArea   = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f)*window.attributes["number"].to_i / 1000000 # [Height (mm) * Width (mm)] * No of Windows

        windowArea["total"] += thisWindowArea
        windowArea["byOrientation"][thisWindowOrient] += thisWindowArea

      end

      return windowArea

    end # function getWindowArea
    # ======================================================================================
    # Get wall characteristics (above-grade, below-grade, headers....)
    # ======================================================================================
    def H2KFile.getAGWallDimensions(elements)

      debug_off()

      debug_out ("[>] H2KFile.getAGWallDimensions \n")
      wallDimsAG = Hash.new
      wallDimsAG["perimeter"] = 0.0
      wallDimsAG["count"] = 0
      wallDimsAG["area"] = Hash.new
      wallDimsAG["area"]["gross"]   = 0.0
      wallDimsAG["area"]["net"]     = 0.0
      wallDimsAG["area"]["headers"] = 0.0

      locationWallText = "HouseFile/House/Components/Wall"
      locationWindowText = "HouseFile/House/Components/Wall/Components/Window"
      locationDoorText = "HouseFile/House/Components/Wall/Components/Door"
      locationHeaderText = "HouseFile/House/Components/Wall/Components/FloorHeader"
      wallCounter = 0

      elements.each(locationWallText) do |wall|

        areaWall_temp = wall.elements["Measurements"].attributes["height"].to_f * wall.elements["Measurements"].attributes["perimeter"].to_f

        # Id for this wall, to match to windows/doors
        idWall = wall.attributes["id"].to_i

        # Loop through windows, sum areas of windows attched to this wall.
        areaWindows = 0.0
        elements.each(locationWindowText) do |window|

          if (window.parent.parent.attributes["id"].to_i == idWall)

            thisWinArea  = ( window.elements["Measurements"].attributes["height"].to_f *
                             window.elements["Measurements"].attributes["width"].to_f   ) * window .attributes["number"].to_i / 1000000
            areaWindows += thisWinArea

          end # if (window.parent.parent.attributes["id"].to_i == idWall)
        end #   elements.each(locationWindowTest) do |window|

        # Loop through doors, sum areas of doors attched to this wall.
        areaDoors= 0.0
        elements.each(locationDoorText) do |door|


          if (door.parent.parent.attributes["id"].to_i == idWall)

            thisDoorArea  = ( door.elements["Measurements"].attributes["height"].to_f *
                              door.elements["Measurements"].attributes["width"].to_f   )
            areaDoors += thisDoorArea


          end # if (door.parent.parent.attributes["id"].to_i == idWall)

        end #   elements.each(locationWindowTest) do |door|

        # Loop through floor headers.
        areaHeaders = 0
        elements.each(locationHeaderText) do |header|

          if (header.parent.parent.attributes["id"].to_i == idWall)

            thisHeaderArea  = ( header.elements["Measurements"].attributes["height"].to_f *
                                header.elements["Measurements"].attributes["perimeter"].to_f   )
            areaHeaders += thisHeaderArea

          end # if (header.parent.parent.attributes["id"].to_i == idWall)

        end #   elements.each(locationHeaderText) do |header|

        # Permiter for linear foot calcs.
        wallDimsAG["perimeter"] += wall.elements["Measurements"].attributes["perimeter"].to_f

        # Gross wall area, including windows/doors
        wallDimsAG["area"]["gross"] += areaWall_temp + areaHeaders

        # Net wall area, excluding windows, doors.
        wallDimsAG["area"]["net"] += areaWall_temp - areaWindows - areaDoors
        wallDimsAG["area"]["headers"] += areaHeaders
        wallDimsAG["area"]["windows"] = areaWindows
        wallDimsAG["area"]["doors"] = areaDoors
        wallDimsAG["count"] += 1.to_i

      end # elements.each(locationWallText) do |wall|

      debug_out ("  Output follows: \n#{wallDimsAG.pretty_inspect}")

      debug_out ("[<] H2KFile.getAGWallDimensions \n")
      return wallDimsAG

    end # def H2KFile.getAGWallArea(elements)

    # ======================================================================================
    # Get general geometry characteristics
    #
    # This is a common funciton that draws upon Rasoul's functions "GetHouseInfo",
    # getEnvelopeSpecs
    # ======================================================================================
    def H2KFile.getAllInfo(elements)

      myH2KHouseInfo = Hash.new

      # Location/region
      myH2KHouseInfo["locale"] = Hash.new
      myH2KHouseInfo["locale"]["weatherLoc"] = H2KFile.getWeatherCity( elements )
      myH2KHouseInfo["locale"]["region"]     = H2KFile.getRegion( elements )


      # Dimensions
      myH2KHouseInfo["dimensions"] = Hash.new
      myH2KHouseInfo["dimensions"]["ceilings"] = Hash.new
      myH2KHouseInfo["dimensions"]["ceilings"]["area"] = Hash.new

      myH2KHouseInfo["heatedFloorArea"] = H2KFile.getHeatedFloorArea( elements )

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

      return myH2KHouseInfo

    end

end




# =========================================================================================
# H2Klibs : module containing that manipulate code libraries
# =========================================================================================
module H2KLibs
  # =========================================================================================
  # Takes a window definition from the options file and creates a similar entry in the code
  # lib. If one already exists, it deletes it and re-creates it.
  # =========================================================================================
  def H2KLibs.AddWinToCodeLib(name,char,codeElements)

     debug_on
     result = ""
     debug_out " window #{name} has characteristics:\n #{char.pretty_inspect}"

     exists = H2KLibs.findCodeInLib(name,codeElements)
     debug_out ("> #{exists}\n")
     if ( exists.eql?("not found") ) then
       # check to make sure we haven't matched somewhere else in the tree
       debug_out " Could not find window in lib\n"
     else
       debug_out " Found window at:\n#{exists}. Deleting...\n"
       exit
     end

     # Now (re)create the window record

     nextID = H2KLibs.getNextCodeIndex(codeElements)



     newWindow = Element.new "Code"
     newWindow.attributes['id'] = "Code #{nextID}"
     newWindow.attributes['nominalRValue'] = 0
     newWindow.elements.add("Label")
     newWindow.elements["Label"].text = "#{name}"

     newWindow.elements.add("Description")
     newWindow.elements["Description"].text = "#{char["panes"]} pane; #{char["coat"]}; #{char["fill"]} fill; U=#{char["u-value"]}"


     newWindow.elements.add("Layers")

     newWindow.elements["Layers"].add_element("Window", {"frameHeight"=>0,
                                                         "shgc"=>char["SHGC"],
                                                         "rank" =>1  } )


     case char["panes"]
     when 2
       code = 2
     when 3
       code = 4
     else
       code = 2
     end

     newWindow.elements["Layers/Window"].add_element("GlazingType", { "code"=>code } )
     newWindow.elements["Layers/Window/GlazingType"].add_element("English")
     newWindow.elements["Layers/Window/GlazingType"].add_element("French")
     newWindow.elements["Layers/Window/"].add_element("OverallThermalResistance", { "code"=> 2, "value" => char["u-value"] })
     newWindow.elements["Layers/Window/OverallThermalResistance"].add_element("English")
     newWindow.elements["Layers/Window/OverallThermalResistance"].add_element("French")
     newWindow.elements["Layers/Window"].add_element("WindowStyle", { "code"=>2 })
     newWindow.elements["Layers/Window/WindowStyle"].add_element("English")
     newWindow.elements["Layers/Window/WindowStyle"].add_element("French")

     code = -99
     case char["fill"]
     when "air"
       code = 1
     when "argon"
       code = 2
     when "krypton"
       code = 6
     else
       code = 2
     end

     newWindow.elements["Layers/Window"].add_element("FillType", { "code"=> code })
     newWindow.elements["Layers/Window/FillType"].add_element("English")
     newWindow.elements["Layers/Window/FillType"].add_element("French")

     newWindow.elements["Layers/Window"].add_element("SpacerType", { "code"=> 2})
     newWindow.elements["Layers/Window/SpacerType"].add_element("English")
     newWindow.elements["Layers/Window/SpacerType"].add_element("French")

     code = -99
     case char["frame"]
     when "vinyl"
       code = 4
     when "wood"
       code = 2
     when "reinforced vinyl"
       code = 5
     else
       code = 2
     end

     newWindow.elements["Layers/Window"].add_element("FrameMaterial", { "code"=> 2})
     newWindow.elements["Layers/Window/FrameMaterial"].add_element("English")
     newWindow.elements["Layers/Window/FrameMaterial"].add_element("French")

     code = -99
     case char["coating"]
     when "clear"
       code = 1
     when "LowE-LowGain"
       code = 2
     when "LowE-HighGain"
       code = 3
     when "tint"
       code = 4
     else
       code = 3
     end

     newWindow.elements["Layers/Window"].add_element("LowECoating", { "code"=> code})
     newWindow.elements["Layers/Window/LowECoating"].add_element("English")
     newWindow.elements["Layers/Window/LowECoating"].add_element("French")


     $formatter.write(newWindow, $stdout)

     location = "/Codes/Window/UserDefined"
     codeElements[location].add_element(newWindow)
     return codeElements

  end


  def H2KLibs.getNextCodeIndex(codeElements)

    debug_on
    index = 0
    codeElements.each("//Code") do | code |
      thisID = code.attributes['id']
      thisID.gsub!(/Code /,"")

      if ( thisID.to_i > index ) then
        index = thisID.to_i
      end

    end

    debug_out "Next code index is #{index+1}\n"
    return index+1

  end

  def H2KLibs.findCodeInLib(name,codeElements)

     debug_off

     debug_out " Looking for #{name}\n"

     result = ""
     path = ""
     location ="not found"
     found = false
     #XPath.each(codeElements, "//Label")
     codeTypes = Array.new
     codeElements["Codes"].elements.each do | attribute |
        if (  attribute.name !~ /Version/ ) then
           path = "Codes/#{attribute.name}"

           codeElements[path].elements.each do | type |
             path = "Codes/#{attribute.name}/#{type.name}"

             codeElements[path].elements.each do | code |
                path = "Codes/#{attribute.name}/#{type.name}/#{code.name}"
                #debug_out ("s: #{path} \n")
                if ( code.attributes["value"].eql?(name) ) then
                  found = true
                  location = "#{path}[@attribute='#{name}']"
                elsif ( code.elements["Label"].text.eql?(name) ) then
                  found = true
                  location = "#{path}/Label[text()='#{name}']/.."
                end
                break if found
             end
             break if found
           end
        end
        break if found
     end


     debug_out " >#{location}<\n"

     return location

  end


end


# =========================================================================================
# H2Kutilis : module containing functions that manage h2k environment
# =========================================================================================

module H2KUtils

  # =========================================================================================
  # Add magic h2k files for diagnostics, if they don't already exist.
  # =========================================================================================
  def H2KUtils.write_h2k_magic_files(path)

    $WinMBFile = "#{path}\\H2K\\WINMB.H2k"
    $ROutFile  = "#{path}\\H2K\\ROutstr.H2k"



    if ( ! File.file?( $WinMBFile ) )

      myHandle = File.open($WinMBFile, 'w')
      myHandle.write "< auto-generated by substitute-h2k.rb >"
      myHandle.close

    end

    if ( ! File.file?( $ROutFile ) )

      myHandle = File.open($ROutFile, 'w')

      # Note that this text below is space-sensitive.
      myHandle.write "<Choose diagnostics>
All,
<End>
     x 'Boot', ! 1 = Startup
     x 'Calculations', ! 2 = Anncal, HseChk, FndChk...
     x 'DHW', ! 3 = All DHW routines
     x 'Space Heat', ! 4 = Space heating system models
     x 'Space Heat Ini', ! 5 = Space heating initialization
     x 'IMS', ! 6 = IMS model
     x 'AIM2', ! 7 = AIM2 model
     x 'HRV', ! 8 = HRV model + Fans No HR
     x 'BHB', ! 9 = Basement Heat balance
     x 'Rooms', ! 10 = Room by room calcs
     x 'C/S', ! 11 = Crawl Space'
     x 'Slab',! 12 = Slab on Grade
     x 'Cooling', ! 13 = Cooling
     x 'P9', !   14 = P9 Combo
     x 'Windows', ! 15 = Window diagnostics (need this even when All specified
     x 'Wizard', ! 16 = HOT2000 Wizard

(This version auto-generated by substitute-h2k.rb)

Put this file in the HOT2000 program directory to turn on diagnostics.
When HOT2000 is started up, a message will appear to state that the
diagnostics will be written to a file named Routstr.Txt.  Other message
boxes will appear on the screen as calculations, ETC occur.  Click OK to
proceed, but note the last message box to appear before the problem
occurs.
JB> Other setting under <Choose diagnostics> is \"Calculations\"
The contents of the diagnostics file were not intended to be of much
use to the general user, but may be useful to the developers in
determining problems with calculations ETC.
This tool should only be used once, I.E. for a single run that causes
the problem to be analysed.
- put the file in the program directory (where HOT2000.exe is located)
- run HOT2000, open the file in question, do the run, quit the program
- e-mail the file Routstr.txt (Winzip/compress it to reduce space) to
  HOT2000 support.
- rename Routstr.h2k to 0Routstr.h2k to suppress the diagnostics
Brian Bradley
bbradley@nrcan.gc.ca
204-984-4920"
      myHandle.close

    return
    end



  end



  # Compute a checksum for directory, ignoring files that HOT2000 commonly alters during



  # =========================================================================================
  # Fix the paths specified in the HOT2000.ini file
  # =========================================================================================
  def H2KUtils.fix_H2K_INI(path)
     # Rewrite INI file with updated location !
     fH2K_ini_file_OUT = File.new("#{path}\\H2K\\HOT2000.ini", "w")

     ini_out=
"[HOT2000]
LANGUAGE=E
ECONOMIC_FILE=#{path}\\H2K\\StdLibs\\econLib.eda
WEATHER_FILE=#{path}\\H2K\\Dat\\Wth110.dir
FUELCOST_FILE=#{path}\\H2K\\StdLibs\\fuelLib.flc
CODELIB_FILE=#{path}\\H2K\\StdLibs\\codeLib.cod
HSEBLD_FILE=#{path}\\H2K\\Dat\\XPstd.slb
UPDATES_URI=http://198.103.48.154/hot2000/LatestVersions.xml
CHECK_FOR_UPDATES=N
UNITS=M
"
     fH2K_ini_file_OUT.write(ini_out)
     fH2K_ini_file_OUT.close

  end

end

def self.checksum(dir)
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
  content.clear
  return md5.update content

end
