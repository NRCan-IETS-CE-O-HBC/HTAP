# ==========================================
# H2KUtils.rb: functions used
# to query, manipulate hot2000 files and
# the h2k environment.
# ==========================================


module HTAP2H2K

  def HTAP2H2K.conf_foundations(myFdnData,myOptions,h2kElements)

    #debug_on

    debug_out "Setting up foundations for this config:\n#{myFdnData.pretty_inspect}\n"

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

      bExtWallInsul = true if ( HTAPData.getResultsForChoice(myOptions,"Opt-FoundationWallExtIns",myFdnData["FoundationWallExtIns"])["H2K-Fdn-ExtWallReff"].to_f > 0.01 )
      bIntWallInsul = true if ( HTAPData.getResultsForChoice(myOptions,"Opt-FoundationWallIntIns",myFdnData["FoundationWallIntIns"])["H2K-Fdn-IntWallReff"].to_f > 0.01 )
      bBGSlabInsul =  true if ( HTAPData.getResultsForChoice(myOptions,"Opt-FoundationSlabBelowGrade",myFdnData["FoundationSlabBelowGrade"])["H2K-Fdn-SlabBelowGradeReff"].to_f > 0.01 )



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
      h2kFdnData["rEffIntWall"] =  myOptions["Opt-FoundationWallIntIns"]["options"][rEff_IntWall]["values"]["1"]["conditions"]["all"].to_f
      h2kFdnData["rEffExtWall"] =  myOptions["Opt-FoundationWallExtIns"]["options"][rEff_ExtWall]["values"]["1"]["conditions"]["all"].to_f
      h2kFdnData["rEff_SlabBG"] =  myOptions["Opt-FoundationSlabBelowGrade"]["options"][rEff_SlabBG]["values"]["1"]["conditions"]["all"].to_f

      debug_out "Processing basements/crawlspaces with following specs:\n#{h2kFdnData.pretty_inspect}"

      H2KFile.updBsmCrawlDef(h2kFdnData,h2kElements)


    end

    debug_out(drawRuler("Slab",". "))
    if ( rEff_SlabOG == "NA" )
      # do nothing!
      debug_out ("'NA' spec'd for on-grade slab. No changes needed\n")

    else
      bOGSlabInsul =  true if ( HTAPData.getResultsForChoice(myOptions,"Opt-FoundationSlabOnGrade",myFdnData["FoundationSlabOnGrade"])["H2K-Fdn-SlabOnGradeReff"].to_f > 0.01 )
      h2kSlabData = Hash.new
      if ( ! bOGSlabInsul  ) then
        slabConfig = "SCN_1"
        h2kSlabData["?ogSlabIns"] = false
      else
        slabConfig = slabConfigInsulated
        h2kSlabData["?ogSlabIns"] = true
      end

      h2kSlabData["rEff_SlabOG"] = myOptions["Opt-FoundationSlabOnGrade"]["options"][rEff_SlabOG]["values"]["1"]["conditions"]["all"].to_f
      h2kSlabData["SlabConfig"] = slabConfig

      H2KFile.updSlabDef(h2kSlabData,h2kElements)


    end

  end

end



module H2KFile

  def H2KFile.heatedCrawlspace(h2kElements)
    isCrawlHeated = false


    if h2kElements["HouseFile/House/Components/Crawlspace"] != nil
      if h2kElements["HouseFile/House/Temperatures/Crawlspace"].attributes["heated"] =~ /true/
        isCrawlHeated = true
      end
    end

    return isCrawlHeated
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
      warn_out ("Errors encounterd when reading #{fileSpec}")
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

  def H2KFile.getStoreys(elements)

    myHouseStoreysInt = elements["HouseFile/House/Specifications/Storeys"].attributes["code"].to_i
    myHouseStoreysString = self.getNumStoreysString(myHouseStoreysInt)

    return myHouseStoreysString

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
    debug_on
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



  # ======================================================================================
  # Get wall characteristics (above-grade, headers....)
  # ======================================================================================
  def H2KFile.getAGWallDimensions(elements)

    #debug_off
    debug_on
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

  # def H2KFile.getAGWallArea(elements)


    def H2KFile.getExpFloorDimensions(elements)
      debug_on
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
    debug_on
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

    wallDims.each do |wall|

      #how many corners belong to this wall?
      fracOfCorners = wall["corners"]/wallCornerCount

      # assume 8" wall
      fdnWallWidth = 8.0 * 2.54 / 100.0
      # exposed perimiter,
      bgDims["walls"]["total-area"]["internal"] += wall["thisHeight"] * ( wall["thisExpPerimeter"] )
      bgDims["walls"]["total-area"]["external"] += wall["thisHeight"] * ( wall["thisExpPerimeter"] + fracOfCorners * ( cornersExt - cornersInt ) * fdnWallWidth * 2.0 )
      bgDims["walls"]["below-grade-area"]["internal"] += wall["thisDepth"] * ( wall["thisExpPerimeter"]  )
      bgDims["walls"]["below-grade-area"]["external"] += wall["thisDepth"] * ( wall["thisExpPerimeter"] + fracOfCorners * ( cornersExt - cornersInt ) * fdnWallWidth * 2.0 )

    end

    debug_out ("Below-grade dimensions:\n#{bgDims.pretty_inspect}\n")

    return bgDims

  end # def H2KFile.getAGWallArea(elements)

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
      systemInfo = { "fansAndPump"   => { "count" => 0.0 },
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

    myH2KHouseInfo["house-description"] = Hash.new
    myH2KHouseInfo["house-description"]["stories"] = H2KFile.getStoreys(elements)
    myH2KHouseInfo["house-description"]["type"] = H2KFile.getHouseType(elements)

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

    debug_off
    result = ""
    debug_out " window #{name} has characteristics:\n #{char.pretty_inspect}"

    exists = H2KLibs.findCodeInLib(name,codeElements)
    debug_out ("> #{exists}\n")
    if ( exists.eql?("not found") ) then
      # check to make sure we haven't matched somewhere else in the tree
      debug_out " Could not find window in lib\n"
    else
      debug_out " Found window at:\n#{exists}. Deleting...\n"
      codeElements[exists].delete_element("./")
      debug_out "And now... #{H2KLibs.findCodeInLib(name,codeElements)}\n"
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

    useLegacy = true

    if ( useLegacy ) then

      rsiVal = 1 / char["u-value"].to_f

      newWindow.elements["Layers"].add_element(
        "WindowLegacy", {"frameHeight"=>10, "shgc"=>char["SHGC"],  "rank" =>1  }
      )

      newWindow.elements["Layers/WindowLegacy"].add_element("Type", { "code"=>1 } )
      newWindow.elements["Layers/WindowLegacy/Type"].add_element("English")
      newWindow.elements["Layers/WindowLegacy/Type"].add_element("French")

      newWindow.elements["Layers/WindowLegacy"].add_element(
        "RsiValues", {"centreOfGlass" => rsiVal.round(4),  "edgeOfGlass" => rsiVal.round(4),  "frame" => rsiVal.round(4) }
      )
    end

    if ( ! useLegacy )then

      newWindow.elements["Layers"].add_element(
        "Window", {"frameHeight"=>0,  "shgc"=>char["SHGC"],  "rank" =>1  }
      )

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
    end

    #$formatter.write(newWindow, $stdout)

    location = "/Codes/Window/UserDefined"
    codeElements[location].add_element(newWindow)
    return codeElements

  end


  def H2KLibs.getNextCodeIndex(codeElements)

    debug_off
    index = 0
    codeElements.each("//Code") do | code |
      thisID = "#{code.attributes['id']}"
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

    # Text in these vaiables are space-sensitive - saved elsewhere.
    require_relative '../include/h2kConfigFiles.rb'

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
      myHandle.write H2K_rout_str
      myHandle.close

      return
    end



  end

  # =========================================================================================
  # Fix the paths specified in the HOT2000.ini file
  # =========================================================================================
  def H2KUtils.fix_H2K_INI(path)

    require_relative '../include/h2kConfigFiles.rb'
    # Rewrite INI file with updated location !
    fH2K_ini_file_OUT = File.new("#{path}\\H2K\\HOT2000.ini", "w")

    debug_off
    myIniOut = H2K_ini_out
    myIniOut.gsub!(/%PATH%/, path )

    debug_out ("writing IniOut - fH2K_ini_file_OUT:\n#{myIniOut}\n")

    fH2K_ini_file_OUT.write(myIniOut)
    fH2K_ini_file_OUT.close

  end

end

# Compute a checksum for directory, ignoring files that HOT2000 commonly alters during ar run
# Can this be put inside the module?
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
