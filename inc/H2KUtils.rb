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

  def H2KFile.getBuildingType(elements)

    myBuildingType = elements["HouseFile/House/Specifications"].attributes["buildingType"]
    if myBuildingType !=nil
      myBuildingType.gsub!(/\s*/, '')    # Removes mid-line white space
      myBuildingType.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end



    return myBuildingType

  end

  def H2KFile.getMURBUnits(elements)


    if (! elements["HouseFile/House/Specifications/NumberOf"].nil?)
      myMURBUnits = elements["HouseFile/House/Specifications/NumberOf"].attributes["dwellingUnits"].to_i
    end



    return myMURBUnits

  end

  def H2KFile.getStoreys(elements)

    myHouseStoreysInt = elements["HouseFile/House/Specifications/Storeys"].attributes["code"].to_i
    myHouseStoreysString = self.getNumStoreysString(myHouseStoreysInt)

    return myHouseStoreysString

  end

  def H2KFile.getFrontOrientation(elements)
    frontFacingH2KVal = { 1 => "S" , 2 => "SE", 3 => "E", 4 => "NE", 5 => "N", 6 => "NW", 7 => "W", 8 => "SW"}
    myHouseFrontOrientCode = elements["HouseFile/House/Specifications/FacingDirection"].attributes["code"].to_i
    myHouseFrontOrientString = frontFacingH2KVal[myHouseFrontOrientCode]

    return myHouseFrontOrientString
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

  # ====================================================================================
  # The below method is for the calculation of framed floor area required for the embodied carbon estimation using MCE2
  def H2KFile.getFramedFloorArea(elements)
    # Get XML file version that "elements" came from. The version can be from the original file (pre-processed inputs)
    # or from the post-processed outputs (which will match the version of the H2K CLI used), depending on the "elements"
    # passed to this function.
    versionMajor = elements["HouseFile/Application/Version"].attributes["major"].to_i
    versionMinor = elements["HouseFile/Application/Version"].attributes["minor"].to_i
    versionBuild = elements["HouseFile/Application/Version"].attributes["build"].to_i
    if (versionMajor == 11 && versionMinor >= 5 && versionBuild >= 8) || versionMajor > 11 then
        framedFloorArea = elements["HouseFile/House/Specifications/HeatedFloorArea"].attributes["aboveGrade"].to_f
    else
        framedFloorArea = elements["HouseFile/House/Specifications"].attributes["aboveGradeHeatedFloorArea"].to_f
    end
#         debug_on
    debug_out "framedFloorArea: >#{framedFloorArea}<\n"
    debug_off
    return framedFloorArea
  end # End getFramedFloorArea

  # ====================================================================================
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
  # The below method is for the calculation of roof area required for the embodied carbon estimation using MCE2
  def H2KFile.getRoofingArea(elements)
    roofingArea = 0.0
    locationText = "HouseFile/House/Components/Ceiling"
    elements.each(locationText) do |ceiling|
        if ceiling.nil? == false
            if ceiling.elements["Construction/Type/English"].include?("Flat") ||
            ceiling.elements["Construction/Type/English"].include?("Cathedral") ||
            ceiling.elements["Construction/Type/English"].include?("Scissor")
                roofingArea += ceiling.elements["Measurements"].attributes["area"].to_f
            elsif ceiling.elements["Construction/Type/English"].include?("Attic/gable") ||
            ceiling.elements["Construction/Type/English"].include?("Attic/hip")
                slope = ceiling.elements["Measurements/Slope"].attributes["value"].to_f
                roofingArea += ceiling.elements["Measurements"].attributes["area"].to_f * Math.sqrt(1 + slope**2)
            end
        end
    end
#         debug_on
    debug_out "roofingArea: >#{roofingArea}<\n"
    debug_off
    return roofingArea
  end # END getRoofingArea

  # ====================================================================================
  # The below method is for the calculation of roof insulation area required for the embodied carbon estimation using MCE2
  def H2KFile.getRoofInsulationArea(elements)
    roofInsulationArea = 0.0
    locationText = "HouseFile/House/Components/Ceiling"
    elements.each(locationText) do |ceiling|
        if ceiling.nil? == false
            roofInsulationArea += ceiling.elements["Measurements"].attributes["area"].to_f
        end
    end
#         debug_on
    debug_out "roofInsulationArea: >#{roofInsulationArea}<\n"
    debug_off
    return roofInsulationArea
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

  # def H2KFile.getAGWallArea(elements)


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
#      fracOfCorners = wall["corners"]/wallCornerCount
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

  def H2KFile.deleteAllWin(elements)
    # Delete all existing windows - exclude door-windows
    locationText = "HouseFile/House/Components/*/Components/Window"
    elements.each(locationText) do |window|
      window.parent.delete_element("Window")
    end

  end

  def H2KFile.addWin(elements, facingDirection, height, width, overhangW, overhangH, winCode)
    # Facing direction codes for HOT2000
    windowFacingH2KVal = { "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8 }
    useThisCodeID  = {  "S"  =>  291 ,    "SE" =>  292 ,    "E"  =>  293 ,    "NE" =>  294 ,    "N"  =>  295 ,    "NW" =>  296 ,    "W"  =>  297 ,    "SW" =>  298   }
    locationText = "HouseFile/House/Components/Wall"
    largestWallArea = 0.0
    idWall = "0"
    # Determine the largest wall in a house
    elements.each(locationText) do |wall|
      areaWall_temp = wall.elements["Measurements"].attributes["height"].to_f * wall.elements["Measurements"].attributes["perimeter"].to_f
      if (areaWall_temp > largestWallArea && wall.attributes["adjacentEnclosedSpace"] == "false")
        idWall = wall.attributes["id"]
        largestWallArea = areaWall_temp
      end
    end

    elements.each(locationText) do |wall|
      # Search for the largest wall and add windows
      if (wall.attributes["id"] == idWall && wall.attributes["adjacentEnclosedSpace"] == "false")
        wall.elements["Components"].add_element("Window")
        locationTextWin = "HouseFile/House/Components/Wall/Components/Window"
        elements.each(locationTextWin) do |window|
          # Add window information to the newly added element
          if (window.attributes["id"].nil?)
            window.attributes["number"] = "1"
            window.attributes["er"] = "12.7173"
            window.attributes["shgc"] = "0.432"
            window.attributes["frameHeight"] = "10"
            window.attributes["frameAreaFraction"] = "0.0189"
            window.attributes["edgeOfGlassFraction"] = "0.1157"
            window.attributes["centreOfGlassFraction"] = "0.8654"
            window.attributes["adjacentEnclosedSpace"] = "false"
            window.attributes["id"] = useThisCodeID[facingDirection]
            # Window label
            window.add_element("Label")
            window.elements["Label"].add_text("refHse+#{facingDirection}")
            # Window construction
            window.add_element("Construction")
            window.elements["Construction"].attributes["energyStar"] = "true"
            window.elements["Construction"].add_element("Type")
            window.elements["Construction"].elements["Type"].attributes["idref"] = winCode
            window.elements["Construction"].elements["Type"].attributes["rValue"] = "0.9259"
            window.elements["Construction"].elements["Type"].add_text("NC-3g-HG-u1.08")
            # Window measurements
            window.add_element("Measurements")
            window.elements["Measurements"].attributes["height"] = height
            window.elements["Measurements"].attributes["width"] = width
            window.elements["Measurements"].attributes["headerHeight"] = overhangH
            window.elements["Measurements"].attributes["overhangWidth"] = overhangW
            window.elements["Measurements"].add_element("Tilt")
            window.elements["Measurements"].elements["Tilt"].attributes["code"] = "1"
            window.elements["Measurements"].elements["Tilt"].attributes["value"] = "90"
            window.elements["Measurements"].elements["Tilt"].add_element("English")
            window.elements["Measurements"].elements["Tilt"].elements["English"].add_text("Vertical")
            window.elements["Measurements"].elements["Tilt"].add_element("French")
            window.elements["Measurements"].elements["Tilt"].elements["French"].add_text("Verticale")
            # Window shading
            window.add_element("Shading")
            window.elements["Shading"].attributes["curtain"] = "1"
            window.elements["Shading"].attributes["shutterRValue"] = "0"
            # Facing direction
            window.add_element("FacingDirection")
            window.elements["FacingDirection"].attributes["code"] = windowFacingH2KVal[facingDirection]
            window.elements["FacingDirection"].add_element("English")
            window.elements["FacingDirection"].elements["English"].add_text("#{facingDirection}")
            window.elements["FacingDirection"].add_element("French")
            window.elements["FacingDirection"].elements["French"].add_text("#{facingDirection}")
          end
        end
      end
    end
  end


  def H2KFile.add_win_to_any_wall(passed_elements, facingDirection, height, width, overhangW, overhangH, winCode)
  
    windowFacingH2KVal = { "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8 }
    useThisCodeID  = {  "S"  =>  291 ,    "SE" =>  292 ,    "E"  =>  293 ,    "NE" =>  294 ,    "N"  =>  295 ,    "NW" =>  296 ,    "W"  =>  297 ,    "SW" =>  298   }
    locationText = "HouseFile/House/Components/Wall"
    
    debug_out ("Placing window (w = #{width} / h = #{height}; faces #{facingDirection}) \n")
    
    window_placed = false

    window_area = ( height / 1000.0 ) * ( width / 1000.0 )
    wall_num = 0 
    locationText = "HouseFile/House/Components/Wall"



    passed_elements.each(locationText) do |wall|

      next if window_placed
      wall_num = wall_num + 1 
      
      wall_area = wall.elements["Measurements"].attributes["height"].to_f * wall.elements["Measurements"].attributes["perimeter"].to_f
      debug_out " >#{wall_num} -  Wall area: #{wall_area}\n"
    

      comp_area_total = 0.0

      debug_out ( " >#{wall_num} - # components: #{wall.elements['components'].nil?}\n" )

    
      if ( ! wall.elements['Components'].nil? )
        debug_out(" >#{wall_num} - wall name: #{wall.name}\n")
        wall.elements["Components"].elements.each do |comp|
          debug_out (" >#{wall_num} - Wall has comonent - #{comp.name}\n")
          
        #  #debug_out "comp> #{component.pretty_inspect}\n"
          comp_width = comp.elements["Measurements"].attributes["width"].to_f 
          comp_height = comp.elements["Measurements"].attributes["height"].to_f 
          if ( comp.name == 'Window' )
            comp_width = comp_width / 1000.0
            comp_height = comp_height / 1000.0 
          end 
          comp_area = comp_width * comp_height 
          debug_out (" >#{wall_num} - > Component: #{comp.name} w #{comp_width} x h #{comp_height} = a #{comp_area} \n")
          comp_area_total = comp_area_total + comp_area
        end 
      end 

      free_area = wall_area - comp_area_total
      debug_out (" >#{wall_num} - Net wall area #{free_area} > window area #{window_area}  ? \n")

      if ( free_area < window_area )
        debug_out (" >#{wall_num} -    No  (wall too small, going to next one )\n ")

      else 
        # Place window in this wall

        debug_out (" >#{wall_num} -    YES (wall is big enough, placing window here. )\n")
        
        if ( wall.elements['Components'].nil? ) then 
          wall.add_element('Components')
        end 
        wall.elements["Components"].add_element("Window")
        #pp wall.elements["Components"]
        #locationTextWin = "HouseFile/House/Components/Wall/Components/Window"
        #elements.each(locationTextWin) do |window|
        debug_out (' >#{wall_num} - Looping through comonents to find a window with nil ID ?')
        wall.elements["Components"].elements.each do | window |
          debug_out(" >#{wall_num} -wall has a #{window.name}, needs and ID ? #{ window.attributes["id"].nil? }\n")
          next if ( window.name != 'Window' )
          next if ( ! window.attributes["id"].nil? )

          #debug_out(" wall has a #{window.name}, needs and ID ? #{ window.attributes["id"].nil? }\n")
         
          window.attributes["number"] = "1"
          window.attributes["er"] = "12.7173"
          window.attributes["shgc"] = "0.432"
          window.attributes["frameHeight"] = "10"
          window.attributes["frameAreaFraction"] = "0.0189"
          window.attributes["edgeOfGlassFraction"] = "0.1157"
          window.attributes["centreOfGlassFraction"] = "0.8654"
          window.attributes["adjacentEnclosedSpace"] = "false"
          window.attributes["id"] = useThisCodeID[facingDirection]
          # Window label
          window.add_element("Label")
          window.elements["Label"].add_text("refHse+#{facingDirection}")
          # Window construction
          window.add_element("Construction")
          window.elements["Construction"].attributes["energyStar"] = "true"
          window.elements["Construction"].add_element("Type")
          window.elements["Construction"].elements["Type"].attributes["idref"] = winCode
          window.elements["Construction"].elements["Type"].attributes["rValue"] = "0.9259"
          window.elements["Construction"].elements["Type"].add_text("NC-3g-HG-u1.08")
          # Window measurements
          window.add_element("Measurements")
          window.elements["Measurements"].attributes["height"] = height
          window.elements["Measurements"].attributes["width"] = width
          window.elements["Measurements"].attributes["headerHeight"] = overhangH
          window.elements["Measurements"].attributes["overhangWidth"] = overhangW
          window.elements["Measurements"].add_element("Tilt")
          window.elements["Measurements"].elements["Tilt"].attributes["code"] = "1"
          window.elements["Measurements"].elements["Tilt"].attributes["value"] = "90"
          window.elements["Measurements"].elements["Tilt"].add_element("English")
          window.elements["Measurements"].elements["Tilt"].elements["English"].add_text("Vertical")
          window.elements["Measurements"].elements["Tilt"].add_element("French")
          window.elements["Measurements"].elements["Tilt"].elements["French"].add_text("Verticale")
          # Window shading
          window.add_element("Shading")
          window.elements["Shading"].attributes["curtain"] = "1"
          window.elements["Shading"].attributes["shutterRValue"] = "0"
          # Facing direction
          window.add_element("FacingDirection")
          window.elements["FacingDirection"].attributes["code"] = windowFacingH2KVal[facingDirection]
          window.elements["FacingDirection"].add_element("English")
          window.elements["FacingDirection"].elements["English"].add_text("#{facingDirection}")
          window.elements["FacingDirection"].add_element("French")
          window.elements["FacingDirection"].elements["French"].add_text("#{facingDirection}")
          

        end
        
        window_placed = true 
      end 
    end 


    if ( ! window_placed )
      warn_out ("Could not find a location for window facing #{facingDirection}\n")
    end



    debug_out " Did I find a home in this window ? #{window_placed}\n"

  end   
  #debug_off()

  # ====================================================================================
  # The below method is for the calculation of footing length required for the embodied carbon estimation using MCE2
  def H2KFile.getFootingLength(elements) # (1) basement, (2) crawlspace, (3) walkout, (4) slab
    footingLength = 0.0
    locationText = "HouseFile/House/Components/Basement"
    elements.each(locationText) do |basement|
        if basement.nil? == false
            if basement.elements["Floor/Measurements"].attributes["isRectangular"] == 'true'
                footingLength += 2 * basement.elements["Floor/Measurements"].attributes["length"].to_f +
                2 * basement.elements["Floor/Measurements"].attributes["width"].to_f
            else
                footingLength += basement.elements["Floor/Measurements"].attributes["perimeter"].to_f
            end
        end
    end
    locationText = "HouseFile/House/Components/Crawlspace"
    elements.each(locationText) do |crawlspace|
        if crawlspace.nil? == false
            if crawlspace.elements["Floor/Measurements"].attributes["isRectangular"] == 'true'
                footingLength += 2 * crawlspace.elements["Floor/Measurements"].attributes["length"].to_f +
                2 * crawlspace.elements["Floor/Measurements"].attributes["width"].to_f
            else
                footingLength += crawlspace.elements["Floor/Measurements"].attributes["perimeter"].to_f
            end
        end
    end
    locationText = "HouseFile/House/Components/Walkout"
    elements.each(locationText) do |walkout|
        if walkout.nil? == false
            footingLength += 2 * walkout.elements["Measurements"].attributes["l1"].to_f +
            2 * walkout.elements["Measurements"].attributes["l2"].to_f
        end
    end
    locationText = "HouseFile/House/Components/Slab"
    elements.each(locationText) do |slab|
        if slab.nil? == false
            if slab.elements["Floor/Measurements"].attributes["isRectangular"] == 'true'
                footingLength += 2 * slab.elements["Floor/Measurements"].attributes["length"].to_f +
                2 * slab.elements["Floor/Measurements"].attributes["width"].to_f
            else
                footingLength += slab.elements["Floor/Measurements"].attributes["perimeter"].to_f
            end
        end
    end
#         debug_on
    debug_out "footingLength: >#{footingLength}<\n"
    debug_off
    return footingLength
  end  # END getFootingLength
    # ====================================================================================
    # Gather info on whether a house has basement/crawlspace/walkout/slab and if they have any door/window
  def H2KFile.getHouseBelowGradeInfo(elements)
    house_has_basement = false
    house_has_basement_door = false
    house_has_basement_window = false
    house_has_crawlspace = false
    house_has_crawlspace_door = false
    house_has_crawlspace_window = false
    house_has_walkout = false
    house_has_walkout_door = false
    house_has_walkout_window = false
    house_has_slab = false
    house_has_slab_door = false
    house_has_slab_window = false

    ##### gather info of basements and their doors and windows
    locationText = "HouseFile/House/Components/Basement"
    elements.each(locationText) do |basement|
        if basement.nil? == false
            house_has_basement = true
            ##### calculate door and window areas of the basement
            if basement.elements["Components"].nil? == false
                basement.elements["Components"].elements.each do |comp|
                    if comp.nil? == false
                        comp_name = comp.name
                        if comp_name.include?("Door")
                            house_has_basement_door = true
                        elsif comp_name.include?("Window")
                            house_has_basement_window = true
                        end
                    end
                end
            end
        end
    end

    ##### gather info of crawlspaces and their doors and windows
    locationText = "HouseFile/House/Components/Crawlspace"
    elements.each(locationText) do |crawlspace|
        if crawlspace.nil? == false
            house_has_crawlspace = true
            ##### calculate door and window areas of the crawlspace
            if crawlspace.elements["Components"].nil? == false
                crawlspace.elements["Components"].elements.each do |comp|
                    if comp.nil? == false
                        comp_name = comp.name
                        if comp_name.include?("Door")
                            house_has_crawlspace_door = true
                        elsif comp_name.include?("Window")
                            house_has_crawlspace_window = true
                        end
                    end
                end
            end
        end
    end

    ##### gather info of walkouts and their doors and windows
    locationText = "HouseFile/House/Components/Walkout"
    elements.each(locationText) do |walkout|
        if walkout.nil? == false
            house_has_walkout = true
            ##### calculate door and window areas of the walkout
            if walkout.elements["Components"].nil? == false
                walkout.elements["Components"].elements.each do |comp|
                    if comp.nil? == false
                        comp_name = comp.name
                        if comp_name.include?("Door")
                            house_has_walkout_door = true
                        elsif comp_name.include?("Window")
                            house_has_walkout_window = true
                        end
                    end
                end
            end
        end
    end

    ##### gather info of slabs and their doors and windows
    locationText = "HouseFile/House/Components/Slab"
    elements.each(locationText) do |slab|
        if slab.nil? == false
            house_has_slab = true
            ##### calculate door and window areas of the slab
            if slab.elements["Components"].nil? == false
                slab.elements["Components"].elements.each do |comp|
                    if comp.nil? == false
                        comp_name = comp.name
                        if comp_name.include?("Door")
                            house_has_slab_door = true
                        elsif comp_name.include?("Window")
                            house_has_slab_window = true
                        end
                    end
                end
            end
        end
    end

    return house_has_basement, house_has_basement_door, house_has_basement_window,
    house_has_crawlspace, house_has_crawlspace_door, house_has_crawlspace_window,
    house_has_walkout, house_has_walkout_door, house_has_walkout_window,
    house_has_slab, house_has_slab_door, house_has_slab_window

  end
  # ====================================================================================
  # The below method is for the calculation of foundation wall area required for the embodied carbon estimation using MCE2
  def H2KFile.getFoundationWallArea(elements)  # (1) basement, (2) crawlspace, (3) walkout, (4) slab
    foundationWallArea = 0.0
    opening_area = 0.0

    #=================== (1) basement: calculate foundation wall area of basement(s) ===================
    locationText = "HouseFile/House/Components/Basement"
    elements.each(locationText) do |basement|
        if basement.nil? == false

            ##### calculate foundation wall area of the basement
            basement_footingLength = basement.attributes["exposedSurfacePerimeter"].to_f
            basement_foundationWallHeight = basement.elements["Wall/Measurements"].attributes["height"].to_f
            foundationWallArea += basement_footingLength * basement_foundationWallHeight

            if basement.elements["Components"].nil? == false

                ##### calculate door and window areas of the basement
                basement.elements["Components"].elements.each do |comp|
                    comp_name = comp.name
                    if comp_name.include?("Door")
                        door_height = comp.elements["Measurements"].attributes["height"].to_f
                        door_width = comp.elements["Measurements"].attributes["width"].to_f
                        opening_area += door_height * door_width
    #                             debug_on
                        debug_out "door_height: >#{door_height}<\n"
                        debug_out "door_width: >#{door_width}<\n"
                        debug_out "opening_area: >#{opening_area}<\n"
                        debug_off
                    elsif comp_name.include?("Window")
                        window_number = comp.attributes["number"].to_f
                        window_height = comp.elements["Measurements"].attributes["height"].to_f
                        window_width = comp.elements["Measurements"].attributes["width"].to_f
                        opening_area += window_height * window_width * window_number / 1000000
    #                             debug_on
                        debug_out "window_number: >#{window_number}<\n"
                        debug_out "window_height: >#{window_height}<\n"
                        debug_out "window_width: >#{window_width}<\n"
                        debug_out "opening_area: >#{opening_area}<\n"
                        debug_off
                    end
                end # END basement.elements["Components"].elements.each do |comp|
            end # END basement.elements["Components"].nil? == false
        end # END if basement.nil? == false
    end # END elements.each(locationText) do |basement|
    #=================== (2) crawlspace: calculate foundation wall area of crawlspace(s) ====================
    locationText = "HouseFile/House/Components/Crawlspace"
    elements.each(locationText) do |crawlspace|
        if crawlspace.nil? == false

            ##### calculate foundation wall area of the crawlspace
            crawlspace_footingLength = crawlspace.attributes["exposedSurfacePerimeter"].to_f
            crawlspace_foundationWallHeight = crawlspace.elements["Wall/Measurements"].attributes["height"].to_f
            foundationWallArea += crawlspace_footingLength * crawlspace_foundationWallHeight

            if crawlspace.elements["Components"].nil? == false
                ##### calculate door and window areas of the crawlspace
                crawlspace.elements["Components"].elements.each do |comp|
                    comp_name = comp.name
                    if comp_name.include?("Door")
                        door_height = comp.elements["Measurements"].attributes["height"].to_f
                        door_width = comp.elements["Measurements"].attributes["width"].to_f
                        opening_area += door_height * door_width
    #                             debug_on
                        debug_out "door_height: >#{door_height}<\n"
                        debug_out "door_width: >#{door_width}<\n"
                        debug_out "opening_area: >#{opening_area}<\n"
                        debug_off
                    elsif comp_name.include?("Window")
                        window_number = comp.attributes["number"].to_f
                        window_height = comp.elements["Measurements"].attributes["height"].to_f
                        window_width = comp.elements["Measurements"].attributes["width"].to_f
                        opening_area += window_height * window_width * window_number / 1000000
    #                             debug_on
                        debug_out "window_height: >#{window_height}<\n"
                        debug_out "window_width: >#{window_width}<\n"
                        debug_out "opening_area: >#{opening_area}<\n"
                        debug_off
                    end
                end # END crawlspace.elements["Components"].elements.each do |comp|
            end # END crawlspace.elements["Components"].nil? == false
        end # END if crawlspace.nil? == false
    end # END elements.each(locationText) do |crawlspace|
    #=================== (3) walkout: calculate foundation wall area of walkout(s) ====================
    # calculate exterior surfaces area excluding door and window area
    locationText = "HouseFile/House/Components/Walkout"
    elements.each(locationText) do |walkout|
    #             debug_on
    #             debug_out_long "walkout: >#{walkout.pretty_inspect}<\n"
    #             debug_off
        if walkout.nil? == false

            ##### calculate foundation wall area of the walkout
            if walkout.elements["ExteriorSurfaces"].nil? == false
                foundationWallArea += walkout.elements["ExteriorSurfaces"].attributes["aboveGradeArea"].to_f +
                walkout.elements["ExteriorSurfaces"].attributes["belowGradeArea"].to_f
            else  # Added this as the ERS-4386 and ERS-4540 archetypes did not have walkout.elements["ExteriorSurfaces"]
                foundationWallArea += elements["HouseFile/AllResults/Results/Other/GrossArea/Basement"].attributes["aboveGrade"].to_f +
                elements["HouseFile/AllResults/Results/Other/GrossArea/Basement"].attributes["belowGrade"].to_f +
                elements["HouseFile/AllResults/Results/Other/GrossArea/Crawlspace"].attributes["wall"].to_f
            end

            if walkout.elements["Components"].nil? == false
                ##### calculate door and window areas of the walkout
                walkout.elements["Components"].elements.each do |comp|
                    comp_name = comp.name
                    if comp_name.include?("Door")
                        door_height = comp.elements["Measurements"].attributes["height"].to_f
                        door_width = comp.elements["Measurements"].attributes["width"].to_f
                        opening_area += door_height * door_width
    #                             debug_on
                        debug_out "door_height: >#{door_height}<\n"
                        debug_out "door_width: >#{door_width}<\n"
                        debug_out "opening_area: >#{opening_area}<\n"
                        debug_off
                    elsif comp_name.include?("Window")
                        window_number = comp.attributes["number"].to_f
                        window_height = comp.elements["Measurements"].attributes["height"].to_f
                        window_width = comp.elements["Measurements"].attributes["width"].to_f
                        opening_area += window_height * window_width * window_number / 1000000
    #                             debug_on
                        debug_out "window_height: >#{window_height}<\n"
                        debug_out "window_width: >#{window_width}<\n"
                        debug_out "opening_area: >#{opening_area}<\n"
                        debug_off
                    end
                end
            end #if walkout.elements["Components"].nil? == false
        end # if walkout.nil? == false
    end # elements.each(locationText) do |walkout|
    #=================== (4) slab: calculate foundation wall area of slab(s) ====================
    # no foundation wall and no window/door for slabs
    # ============================================================================================
    foundationWallArea = foundationWallArea - opening_area
    #         debug_on
    debug_out "foundationWallArea: >#{foundationWallArea}<\n"
    debug_off
    return foundationWallArea
  end # END getFoundationWallArea
  # ====================================================================================
  # The below method is for the calculation of foundation slab area required for the embodied carbon estimation using MCE2
  def H2KFile.getFoundationSlabArea(elements) # (1) basement, (2) crawlspace, (3) walkout, (4) slab
    foundationSlabArea = 0.0
    locationText = "HouseFile/House/Components/Basement"
    elements.each(locationText) do |basement|
        if basement.nil? == false
            if basement.elements["Floor/Measurements"].attributes["isRectangular"] == 'true'
                foundationSlabArea += basement.elements["Floor/Measurements"].attributes["length"].to_f *
                basement.elements["Floor/Measurements"].attributes["width"].to_f
            else
                foundationSlabArea += basement.elements["Floor/Measurements"].attributes["area"].to_f
            end
        end
    end
    locationText = "HouseFile/House/Components/Crawlspace"
    elements.each(locationText) do |crawlspace|
        if crawlspace.nil? == false
            if crawlspace.elements["Floor/Measurements"].attributes["isRectangular"] == 'true'
                foundationSlabArea += crawlspace.elements["Floor/Measurements"].attributes["length"].to_f *
                crawlspace.elements["Floor/Measurements"].attributes["width"].to_f
            else
                foundationSlabArea += crawlspace.elements["Floor/Measurements"].attributes["area"].to_f
            end
        end
    end
    locationText = "HouseFile/House/Components/Walkout"
    elements.each(locationText) do |walkout|
        if walkout.nil? == false
            foundationSlabArea += walkout.elements["Measurements"].attributes["l1"].to_f * walkout.elements["Measurements"].attributes["l2"].to_f
        end
    end
    locationText = "HouseFile/House/Components/Slab"
    elements.each(locationText) do |slab|
        if slab.nil? == false
            if slab.elements["Floor/Measurements"].attributes["isRectangular"] == 'true'
                foundationSlabArea += slab.elements["Floor/Measurements"].attributes["length"].to_f *
                slab.elements["Floor/Measurements"].attributes["width"].to_f
            else
                foundationSlabArea += slab.elements["Floor/Measurements"].attributes["area"].to_f
            end
        end
    end
#         debug_on
    debug_out "foundationSlabArea: >#{foundationSlabArea}<\n"
    debug_off
    return foundationSlabArea
  end

  # ====================================================================================

end # END module H2KFile




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
    require_relative '../inc/h2kConfigFiles.rb'

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

    require_relative '../inc/h2kConfigFiles.rb'
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

# =========================================================================================
# H2Kutilis : Parse H2k File 
# =========================================================================================
module H2KOutput 

  def H2KOutput.parse_BrowseRpt(myBrowseRptFile)
    
    #debug_on

    myBrowseData = {"monthly"=>Hash.new, "daily" => Hash.new, "annual" => Hash.new }
    fBrowseRpt = File.new(myBrowseRptFile, "r")
    # fBrowseRpt = File.new(myBrowseRptFile, "r", :encoding => 'UTF-8', :invalid=>:replace, :replace=>"?" )
    # fBrowseRpt = File.new(myBrowseRptFile, "r", :encoding => 'UTF-16BE', :invalid=>:replace, :replace=>"?" )
   
    flagACPerf = false 
    flagSHPerf = false 
    flagSRPerf = false 
    flagBLPerf = false 
    flagEPPerf = false
    flagWTPref = false
    flagENPref = false

    $hourlyFoundACData = false 
    lineNo = 0
    while !fBrowseRpt.eof? do

      lineNo = lineNo+ 1
      line = fBrowseRpt.readline.encode("UTF-8",  :invalid=>:replace, :replace=>"?" )      

      # Sequentially read file lines
      line.strip!
      # Remove leading and trailing whitespace


      # ==============================================================
      # Heating section 

      if ( line =~ /\*\*\* SPACE HEATING SYSTEM PERFORMANCE \*\*\*/ )
        myBrowseData["monthly"]["heating"] = {"loadGJ" => Hash.new, 
                                              "input_energyGJ" => Hash.new,
                                              "COP" => Hash.new
                                             }        
        flagSHPerf = true 
      end 

      if ( flagSHPerf )

        if ( line =~ /^Ann/i ) 
          flagSHPerf = false 
        else 



          debug_out ("#{line}\n")

          words = line.split(/\s+/)
          
          if (MonthArrListAbbr.include?("#{words[0]}".downcase) )        
            
            month = monthLong(words[0].downcase)
            myBrowseData["monthly"]["heating"]["loadGJ"][month] = words[1].to_f/1000
            myBrowseData["monthly"]["heating"]["input_energyGJ"][month] = words[6].to_f/1000
            myBrowseData["monthly"]["heating"]["COP"][month] = words[7].to_f

          end 
   
        end 

      end 

      # ==============================================================
      # Cooling section 


      if ( line =~ /\*\*\* AIR CONDITIONING SYSTEM PERFORMANCE \*\*\*/ )
        $hourlyFoundACData = true 
        myBrowseData["monthly"]["cooling"] = {"sensible_loadGJ" => Hash.new, 
                                                "latent_loadGJ" => Hash.new,
                                                "total_loadGJ" => Hash.new
                                                }        
        flagACPerf = true 
      end 

      if ( flagACPerf )

        if ( line =~ /^Ann/i ) 
          flagACPerf = false 
        else 



          debug_out ("#{line}\n")

          words = line.split(/\s+/)
          
          if (MonthArrListAbbr.include?("#{words[0]}".downcase) )        

            month = monthLong(words[0].downcase)

            myBrowseData["monthly"]["cooling"]["sensible_loadGJ"][month] = words[1].to_f/1000
            myBrowseData["monthly"]["cooling"]["latent_loadGJ"][month] = words[2].to_f/1000
            myBrowseData["monthly"]["cooling"]["total_loadGJ"][month] = (words[1].to_f + words[2].to_f)/1000

          end 
   
        end 

      end


      # ==============================================================
      # HVAC/DHW/Appliance energy consumption section
      if ( line =~ /\*\*\* MONTHLY ESTIMATED ENERGY CONSUMPTION BY DEVICE \( MJ \) \*\*\*/)
        myBrowseData["monthly"]["energy"] = {"space_heating_primary_GJ" => Hash.new,
                                             "space_heating_secondary_GJ" => Hash.new,
                                             "DHW_heating_primary_GJ" => Hash.new,
                                             "DHW_heating_secondary_GJ" => Hash.new,
                                             "lights_appliances_GJ" => Hash.new,
                                             "HRV_fans_GJ" => Hash.new,
                                             "air_conditioner_GJ" => Hash.new
        }

        flagENPerf = true
      end

      if ( flagENPerf )

        if ( line =~ /^Total/i )
          flagENPerf = false
        else



          debug_out ("#{line}\n")

          words = line.split(/\s+/)

          if (MonthArrListAbbr.include?("#{words[0]}".downcase) )

            month = monthLong(words[0].downcase)
            myBrowseData["monthly"]["energy"]["space_heating_primary_GJ"][month] = words[1].to_f/1000
            myBrowseData["monthly"]["energy"]["space_heating_secondary_GJ"][month] = words[2].to_f/1000
            myBrowseData["monthly"]["energy"]["DHW_heating_primary_GJ"][month] = words[3].to_f/1000
            myBrowseData["monthly"]["energy"]["DHW_heating_secondary_GJ"][month] = words[4].to_f/1000
            myBrowseData["monthly"]["energy"]["lights_appliances_GJ"][month] = words[5].to_f/1000
            myBrowseData["monthly"]["energy"]["HRV_fans_GJ"][month] = words[6].to_f/1000
            myBrowseData["monthly"]["energy"]["air_conditioner_GJ"][month] = words[7].to_f/1000

          end

        end

      end

      # ==============================================================
      # Weather file section
      if ( line =~ /s\*\*\* Weather File Listing \*\*\*/)
        myBrowseData["annual"]["weather"] = {"Annual_HDD_18C"   => nil,
                                             "Avg_Deep_Ground_Temp_C" => nil
        }

        myBrowseData["annual"]["design_Temp"] = {"heating_C"   => nil,
                                                 "cooling_dry_bulb_C" => nil,
                                                 "cooling_wet_bulb_C" => nil

        }

        myBrowseData["monthly"]["weather"] = {"dry_bulb_C" => Hash.new,
                                              "wet_bulb_C" => Hash.new,
                                              "amplitude_C" => Hash.new,
                                              "st_dev_C" => Hash.new,
                                              "wind_speed_km/hr" => Hash.new
        }


        flagWTPerf = true
      end

      if ( flagWTPerf )

        words = line.split(/\s+/)

        if ( words[0] == "Annual" && words[1] != "Heating" )
          flagWTPerf = false
        else

          words = line.split(/\s+/)


           if ( line =~ /^Annual Heating Degree Days \(18 C\)/i ) then
            myBrowseData["annual"]["weather"]["Annual_HDD_18C"] = words[7].to_f
            flagWTPerf = true
           end

           if ( line =~ /Average Deep Ground Temperature \(C\)/i ) then
             myBrowseData["annual"]["weather"]["Avg_Deep_Ground_Temp_C"] = words[6].to_f
           end

          if ( line =~ /Design Heating Temperature \(C\)/i ) then
            myBrowseData["annual"]["design_Temp"]["heating_C"] = words[5].to_f
          end

          if ( line =~ /Design Cooling Dry Bulb Temp. \(C\)/i ) then
            myBrowseData["annual"]["design_Temp"]["cooling_dry_bulb_C"] = words[7].to_f
          end

          if ( line =~ /Design Cooling Wet Bulb Temp. \(C\)/i ) then
            myBrowseData["annual"]["design_Temp"]["cooling_wet_bulb_C"] = words[7].to_f
          end


          if (MonthArrListAbbr.include?("#{words[0]}".downcase) )
            month = monthLong(words[0].downcase)
            myBrowseData["monthly"]["weather"]["dry_bulb_C"][month] = words[1].to_f
            myBrowseData["monthly"]["weather"]["wet_bulb_C"][month] = words[2].to_f
            myBrowseData["monthly"]["weather"]["amplitude_C"][month] = words[3].to_f
            myBrowseData["monthly"]["weather"]["st_dev_C"][month] = words[4].to_f
            myBrowseData["monthly"]["weather"]["wind_speed_km/hr"][month] = words[5].to_f
          end
        end
      end



      # ==============================================================
      # Domestic Hot Water Heating Summary
		if ( line =~ /\*\*\* ANNUAL DOMESTIC WATER HEATING SUMMARY \*\*\*/ )
			myBrowseData["annual"]["DHW_heating"] = {"Daily_DHW_Consumption_L/day"   => nil,
                                                 "DHW_Temperature_C" => nil,
                                                 "DHW_Heating_Load_MJ" => nil,
																 "Primary_DHW_Energy_Use_MJ" => nil,
																 "Primary_DHW_Efficiency" => nil

        }
		  
		  flagDHWPref = true
		 end
		 
		 if (flagDHWPref)
		 
			if ( line =~ /\*\*\* BASE LOADS SUMMARY \*\*\*/ )
				flagDHWPref = false
			else
				
				words = line.split(/\s+/)
			
				if ( line =~ /Daily Hot Water Consumption/i ) then
					myBrowseData["annual"]["DHW_heating"]["Daily_DHW_Consumption_L/day"] = words[5].to_f
				end

				if ( line =~ /Hot Water Temperature/i ) then
					myBrowseData["annual"]["DHW_heating"]["DHW_Temperature_C"] = words[4].to_f
				end
				
				if ( line =~ /Estimated Domestic Water Heating Load/i ) then
					myBrowseData["annual"]["DHW_heating"]["DHW_Heating_Load_MJ"] = words[6].to_f
				end
				
				if ( line =~ /PRIMARY Domestic Water Heating Energy Consumption/i ) then
					myBrowseData["annual"]["DHW_heating"]["Primary_DHW_Energy_Use_MJ"] = words[7].to_f
				end
				
				if ( line =~ /PRIMARY System Seasonal Efficiency/i ) then
					myBrowseData["annual"]["DHW_heating"]["Primary_DHW_Efficiency"] = words[5].to_f
				end
				
			end
		end
      # ==============================================================
      # Ventilation Summary Section
      if ( line =~ /\*\*\* AIR LEAKAGE AND VENTILATION SUMMARY \*\*\*/ )
        myBrowseData["daily"]["ventilation"] = {"F326_Required_Flow_Rate_L/s"   => nil

        }

        flagVENTPref = true
      end

      if (flagVENTPref)

        if ( line =~ /\*\*\* SPACE HEATING SYSTEM \*\*\*/ )
          flagVENTPref = false
        else

          words = line.split(/\s+/)

          if ( line =~ /F326 Required continuous ventilation rate/i ) then
            myBrowseData["daily"]["ventilation"]["F326_Required_Flow_Rate_L/s"] = words[6].to_f
          end

        end
      end
	  # ==============================================================
      # Setpoint Temperatures Section
      if ( line =~ /\*\*\* HOUSE TEMPERATURES \*\*\*/ )
        myBrowseData["daily"]["setpoint_temperature"] = {"Daytime_Setpoint_degC"   => nil,
                                                 "Nightime_Setpoint_degC" => nil,
                                                 "Nightime_Setback_Duration_hr" => nil,
																 "Cooling_Setpoint_degC" => nil,
																 "Indoor_Design_Temp_Heat_degC" => nil,
																 "Indoor_Design_Temp_Cool_degC" => nil
																 }

        flagSETPOINTPref = true
      end

      if (flagSETPOINTPref)

        if ( line =~ /\*\*\* WINDOW CHARACTERISTICS \*\*\*/ )
          flagSETPOINTPref = false
        else

          words = line.split(/\s+/)

          if ( line =~ /Daytime Setpoint/i ) then
            myBrowseData["daily"]["setpoint_temperature"]["Daytime_Setpoint_degC"] = words[5].to_f
          end
		  if ( line =~ /Nightime Setpoint/i ) then
            myBrowseData["daily"]["setpoint_temperature"]["Nightime_Setpoint_degC"] = words[3].to_f
          end
		  if ( line =~ /Nightime Setback Duration/i ) then
            myBrowseData["daily"]["setpoint_temperature"]["Nightime_Setback_Duration_hr"] = words[4].to_f
          end
		  if ( line =~ /Cooling Temperature/i ) then
            myBrowseData["daily"]["setpoint_temperature"]["Cooling_Setpoint_degC"] = words[words.length-2].to_f #second from last
          end
		  if ( line =~ /Heating/i ) then
            myBrowseData["daily"]["setpoint_temperature"]["Indoor_Design_Temp_Heat_degC"] = words[2].to_f
          end
		  if ( line =~ /Cooling/i ) then
            myBrowseData["daily"]["setpoint_temperature"]["Indoor_Design_Temp_Cool_degC"] = words[2].to_f
          end
		  
        end
      end
      # ==============================================================
      # Building Parameters Section
      if ( line =~ /\*\*\* BUILDING PARAMETERS SUMMARY \*\*\*/ )
        myBrowseData["annual"]["volume"]={"house_volume_m^3"=> 0.0}
        myBrowseData["annual"]["area"]={"walls_net_m^2"=> nil,
                                        "ceiling_m^2" => nil
        }



        flagBLDPARPref = true
      end

      if (flagBLDPARPref)

        if ( line =~ /\*\*\* AIR LEAKAGE AND VENTILATION \*\*\*/ )
          flagBLDPARPref = false
        else

          words = line.split(/\s+/)

          if ( line =~ /m3/i ) then
            debug_out ("Volume: #{words[0]}\n")
            myBrowseData["annual"]["volume"]["house_volume_m^3"] = words[0].to_f
          end
          if ( line =~ /Main Walls/i ) then
            myBrowseData["annual"]["area"]["walls_net_m^2"] = words[3].to_f
          end
          if ( line =~ /Ceiling/i ) then
            myBrowseData["annual"]["area"]["ceiling_m^2"] = words[2].to_f
          end

        end
      end
      # ==============================================================
      # Foundation Section
      if ( line =~ /\*\*\* FOUNDATIONS \*\*\*/ )
        myBrowseData["annual"]["volume"]={"basement_volume_m^3" => 0.0}



        flagFOUNDPARPref = true
      end

      if (flagFOUNDPARPref)

        if ( line =~ /\*\*\* Foundation Floor Header Code Schedule \*\*\*/ )
          flagFOUNDPARPref = false
        else

          words = line.split(/\s+/)

          if ( line =~ /Foundation type/i ) then
            myBrowseData["annual"]["volume"]["basement_volume_m^3"] = words[6].to_f
          end

        end
      end
      # ==============================================================
      # General House Characteristics
      if ( line =~ /\*\*\* GENERAL HOUSE CHARACTERISTICS \*\*\*/ )
        myBrowseData["annual"]["mass"] = {"thermal_mass_level"   => nil,
                                          "effective_mass_fraction"   => nil
        }

        flagHOUSECHARref = true
      end

      if (flagHOUSECHARref)

        if ( line =~ /\*\*\* HOUSE TEMPERATURES \*\*\*/ )
          flagHOUSECHARref = false
        else

          words = line.split(/\s+/)

          if ( line =~ /House Thermal Mass Level/i ) then
            myBrowseData["annual"]["mass"]["thermal_mass_level"] = words[4]
          end
          if ( line =~ /Effective mass fraction/i ) then
            myBrowseData["annual"]["mass"]["effective_mass_fraction"] = words[3].to_f
          end

        end
      end
		# ==============================================================
      # Solar Radiation section
      if ( line =~ /\*\*\* Solar Radiation \(MJ\/m2\/day\) \*\*\*/ )
        myBrowseData["monthly"]["solar_radiation"] = {"global_horizontal_MJ/M2/day" => Hash.new, 
                                                      "diffuse_horizontal_MJ/M2/day" => Hash.new,
                                                      "vertical_surface_South_MJ/M2/day" => Hash.new,
                                                      "vertical_surface_SE/SW_MJ/M2/day" => Hash.new,
                                                      "vertical_surface_East/West_MJ/M2/day" => Hash.new,
                                                      "vertical_surface_NE/NW_MJ/M2/day" => Hash.new,
                                                      "vertical_surface_North_MJ/M2/day" => Hash.new
                                                       }        
        flagSRPerf = true 
      end 

      if ( flagSRPerf )

        if ( line =~ /^Ann/i ) 
          flagSRPerf = false 
        else 



          debug_out ("#{line}\n")

          words = line.split(/\s+/)
          
          if (MonthArrListAbbr.include?("#{words[0]}".downcase) )        
            
            month = monthLong(words[0].downcase)
            myBrowseData["monthly"]["solar_radiation"]["global_horizontal_MJ/M2/day"][month] = words[1].to_f
            myBrowseData["monthly"]["solar_radiation"]["diffuse_horizontal_MJ/M2/day"][month] = words[2].to_f
            myBrowseData["monthly"]["solar_radiation"]["vertical_surface_South_MJ/M2/day"][month] = words[3].to_f
            myBrowseData["monthly"]["solar_radiation"]["vertical_surface_SE/SW_MJ/M2/day"][month] = words[4].to_f
            myBrowseData["monthly"]["solar_radiation"]["vertical_surface_East/West_MJ/M2/day"][month] = words[5].to_f
            myBrowseData["monthly"]["solar_radiation"]["vertical_surface_NE/NW_MJ/M2/day"][month] = words[6].to_f
            myBrowseData["monthly"]["solar_radiation"]["vertical_surface_North_MJ/M2/day"][month] = words[7].to_f

          end 
   
        end 

      end 




      # ==============================================================
      # EnergyProfile
      if ( line =~ /\*\*\* MONTHLY ENERGY PROFILE \*\*\*/ )
        myBrowseData["monthly"]["energy_profile"] = {"energy_loadGJ"     => Hash.new, 
                                                     "internal_gainsGJ"  => Hash.new,
                                                     "solar_gainsGJ"     => Hash.new,
                                                     "aux_energy_GJ"     => Hash.new
                                                       }        
        flagEPPerf = true 
      end 

      if ( flagEPPerf )

        if ( line =~ /^Annual/i ) 
          flagEPPerf = false 
        else 

          debug_out ("#{line}\n")
          words = line.split(/\s+/)

          if (MonthArrListAbbr.include?("#{words[0]}".downcase) )        
            
            month = monthLong(words[0].downcase)
            myBrowseData["monthly"]["energy_profile"]["energy_loadGJ"   ][month] = words[1].to_f/1000
            myBrowseData["monthly"]["energy_profile"]["internal_gainsGJ"][month] = words[2].to_f/1000
            myBrowseData["monthly"]["energy_profile"]["solar_gainsGJ"   ][month] = words[3].to_f/1000
            myBrowseData["monthly"]["energy_profile"]["aux_energy_GJ"   ][month] = words[4].to_f/1000

          end 
   


   
        end 

      end 



      # ==============================================================
      # Baseloads section
      if ( line =~ /\*\*\* BASE LOADS SUMMARY \*\*\*/ )
        myBrowseData["daily"]["baseloads"] = {"interior_lighting_kWh/day"   => nil, 
                                              "interior_appliances_kWh/day" => nil,
                                              "interior_other_kWh/day"      => nil,
                                              "exterior_other_kWh/day"      => nil,
                                                       }        
        flagBLPerf = true 
      end 

      if ( flagBLPerf )

        if ( line =~ /^Total Average Electrical Load/i ) 
          flagBLPerf = false 
        else 

          debug_out ("#{line}\n")
          words = line.split(/\s+/)

          if ( line =~ /Interior Lighting/i ) then 
            myBrowseData["daily"]["baseloads"]["interior_lighting_kWh/day"] = words[2].to_f
          end 

          if (line =~ /Appliances/i ) then 
            myBrowseData["daily"]["baseloads"]["interior_appliances_kWh/day"] = words[1].to_f
          end 

          if (line =~ /Other/i ) then 
            myBrowseData["daily"]["baseloads"]["interior_other_kWh/day"] = words[1].to_f
          end           

          if (line =~ /Exterior use/i ) then 
            myBrowseData["daily"]["baseloads"]["exterior_other_kWh/day"] = words[2].to_f
          end 


   
        end 

      end 


      if ( line =~ /Sensible Internal Heat Gain From Occupants/ ) then 
        gain = line.split('=')[1].gsub(/kWh\/day/,"").gsub(/\s*/,"")
        myBrowseData["daily"]["gains_from_occupants_kWh/day"] = gain.to_f
      end 



    end 

    return myBrowseData

  end 

  def H2KOutput.parse_results(myResultCode,myElements)
    
    myResults = Hash.new(&$blk)
    myResults[myResultCode] = Hash.new 
    myResults[myResultCode]["found"] = false  
    debug_out("Results: #{myResultCode}\n")
    log_out("Querying HOT2000 file for result set #{myResultCode}.\n")

    # Make sure that the code we want is available

    if ( myElements["HouseFile/AllResults"].nil? ) then 
      err_out ("<AllResults> section is missing from h2k file.")
      fatalerror("HOT2000 did not produce any results.")
    end 

    myElements["HouseFile/AllResults"].elements.each do |element|

      houseCode =  element.attributes["houseCode"]

      

      # 05-Feb-2018 JTB: Note that in Non-Program (ERS) mode there is no "houseCode" attribute in the single element results set!
      # When in Program mode there are multiple element results sets (7). The first set has no houseCode attribute, the next six (6)
      # do have a value for the houseCode attribute. The last set has the houseCode attribute of "UserHouse", which almost exactly
      # matches the first results set (General mode results).
      if (houseCode == nil && element.attributes["sha256"] != nil)
        houseCode = "General"
      end

      if (houseCode == "#{myResultCode}" )
        $HCRequestedfoundfound = true
        myResults[myResultCode]["found"] = true        
      end

    end

    if ( ! myResults["myResultCode"]["found"]  ) then 
      log_out("Could not find result set #{myResultCode}.\n")
      return myResults[myResultCode] 
    end 
    
    myElements["HouseFile/AllResults"].elements.each do |element|
      debug_out ("Set ...\n")
      houseCode =  element.attributes["houseCode"]

      if (houseCode == nil && element.attributes["sha256"] != nil)
        houseCode = "General"
      end

      # JTB 31-Jan-2018: Limiting results parsing to 1 set specified by user in choice file and saved in myResultCode
      if (houseCode =~ /#{myResultCode}/)

        stream_out( "\n Parsing results from set: #{myResultCode} ...")
        # Energy Consumption (Annual GJ)
        myResults[houseCode]["avgEnergyTotalGJ"]        = element.elements[".//Annual/Consumption"].attributes["total"].to_f  
        myResults[houseCode]["avgEnergyHeatingGJ"]      = element.elements[".//Annual/Consumption/SpaceHeating"].attributes["total"].to_f  
        myResults[houseCode]["avgGrossHeatLossGJ"]      = element.elements[".//Annual/HeatLoss"].attributes["total"].to_f  
        myResults[houseCode]["avgVentAndInfilGJ"]       = element.elements[".//Annual/HeatLoss"].attributes["airLeakageAndNaturalVentilation"].to_f  
        myResults[houseCode]["avgEnergyCoolingGJ"]      = element.elements[".//Annual/Consumption/Electrical"].attributes["airConditioning"].to_f  
        myResults[houseCode]["avgEnergyVentilationGJ"]  = element.elements[".//Annual/Consumption/Electrical"].attributes["ventilation"].to_f  
        myResults[houseCode]["avgEnergyEquipmentGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["baseload"].to_f  
        myResults[houseCode]["avgEnergyWaterHeatingGJ"] = element.elements[".//Annual/Consumption/HotWater"].attributes["total"].to_f  

        if $ExtraOutput1 then
          # Total Heat Loss of all zones by component (GJ)
          myResults[houseCode]["EnvHLTotalGJ"] = element.elements[".//Annual/HeatLoss"].attributes["total"].to_f  
          myResults[houseCode]["EnvHLCeilingGJ"] = element.elements[".//Annual/HeatLoss"].attributes["ceiling"].to_f  
          myResults[houseCode]["EnvHLMainWallsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["mainWalls"].to_f  
          myResults[houseCode]["EnvHLWindowsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["windows"].to_f  
          myResults[houseCode]["EnvHLDoorsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["doors"].to_f  
          myResults[houseCode]["EnvHLExpFloorsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["exposedFloors"].to_f  
          myResults[houseCode]["EnvHLCrawlspaceGJ"] = element.elements[".//Annual/HeatLoss"].attributes["crawlspace"].to_f  
          myResults[houseCode]["EnvHLSlabGJ"] = element.elements[".//Annual/HeatLoss"].attributes["slab"].to_f  
          myResults[houseCode]["EnvHLBasementBGWallGJ"] = element.elements[".//Annual/HeatLoss"].attributes["basementBelowGradeWall"].to_f  
          myResults[houseCode]["EnvHLBasementAGWallGJ"] = element.elements[".//Annual/HeatLoss"].attributes["basementAboveGradeWall"].to_f  
          myResults[houseCode]["EnvHLBasementFlrHdrsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["basementFloorHeaders"].to_f  
          myResults[houseCode]["EnvHLPonyWallGJ"] = element.elements[".//Annual/HeatLoss"].attributes["ponyWall"].to_f  
          myResults[houseCode]["EnvHLFlrsAbvBasementGJ"] = element.elements[".//Annual/HeatLoss"].attributes["floorsAboveBasement"].to_f  
          myResults[houseCode]["EnvHLAirLkVentGJ"] = element.elements[".//Annual/HeatLoss"].attributes["airLeakageAndNaturalVentilation"].to_f  

          # Annual DHW heating load [GJ] -- heating load (or demand) on DHW system (before efficiency applied)
          myResults[houseCode]["AnnHotWaterLoadGJ"] = element.elements[".//Annual/HotWaterDemand"].attributes["base"].to_f  
        end
        debug_out ("Parsing design loads\n")
        # Design loads, other data
        myResults[houseCode]["avgOthPeakHeatingLoadW"] = element.elements[".//Other"].attributes["designHeatLossRate"].to_f  
        myResults[houseCode]["avgOthPeakCoolingLoadW"] = element.elements[".//Other"].attributes["designCoolLossRate"].to_f  

        myResults[houseCode]["avgOthSeasonalHeatEff"] = element.elements[".//Other"].attributes["seasonalHeatEfficiency"].to_f  
        myResults[houseCode]["avgVntAirChangeRateNatural"] = element.elements[".//Annual/AirChangeRate"].attributes["natural"].to_f  
        myResults[houseCode]["avgVntAirChangeRateTotal"] = element.elements[".//Annual/AirChangeRate"].attributes["total"].to_f  
        myResults[houseCode]["avgSolarGainsUtilized"] = element.elements[".//Annual/UtilizedSolarGains"].attributes["value"].to_f  
        myResults[houseCode]["avgVntMinAirChangeRate"] = element.elements[".//Other/Ventilation"].attributes["minimumAirChangeRate"].to_f  

        myResults[houseCode]["avgFuelCostsElec$"]    = element.elements[".//Annual/ActualFuelCosts"].attributes["electrical"].to_f  
        myResults[houseCode]["avgFuelCostsNatGas$"]  = element.elements[".//Annual/ActualFuelCosts"].attributes["naturalGas"].to_f  
        myResults[houseCode]["avgFuelCostsOil$"]     = element.elements[".//Annual/ActualFuelCosts"].attributes["oil"].to_f  
        myResults[houseCode]["avgFuelCostsPropane$"] = element.elements[".//Annual/ActualFuelCosts"].attributes["propane"].to_f  
        myResults[houseCode]["avgFuelCostsWood$"]    = element.elements[".//Annual/ActualFuelCosts"].attributes["wood"].to_f  

        if $ExtraOutput1 then
          # Annual SpaceHeating and HotWater energy by fuel type [GJ]
          myResults[houseCode]["AnnSpcHeatElecGJ"] = element.elements[".//Annual/Consumption/Electrical"].attributes["spaceHeating"].to_f  
          myResults[houseCode]["AnnSpcHeatHPGJ"] = element.elements[".//Annual/Consumption/Electrical"].attributes["heatPump"].to_f  
          myResults[houseCode]["AnnSpcHeatGasGJ"] = element.elements[".//Annual/Consumption/NaturalGas"].attributes["spaceHeating"].to_f  
          myResults[houseCode]["AnnSpcHeatOilGJ"] = element.elements[".//Annual/Consumption/Oil"].attributes["spaceHeating"].to_f  
          myResults[houseCode]["AnnSpcHeatPropGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["spaceHeating"].to_f  
          myResults[houseCode]["AnnSpcHeatWoodGJ"] = element.elements[".//Annual/Consumption/Wood"].attributes["spaceHeating"].to_f  
          myResults[houseCode]["AnnHotWaterElecGJ"] = element.elements[".//Annual/Consumption/Electrical/HotWater"].attributes["dhw"].to_f  
          myResults[houseCode]["AnnHotWaterGasGJ"] = element.elements[".//Annual/Consumption/NaturalGas"].attributes["hotWater"].to_f  
          myResults[houseCode]["AnnHotWaterOilGJ"] = element.elements[".//Annual/Consumption/Oil"].attributes["hotWater"].to_f  
          myResults[houseCode]["AnnHotWaterPropGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["hotWater"].to_f  
          myResults[houseCode]["AnnHotWaterWoodGJ"] = element.elements[".//Annual/Consumption/Wood"].attributes["hotWater"].to_f  
        end

        myResults[houseCode]["avgFueluseElecGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["total"].to_f  

        # Bug in v11.3b90: The annual electrical energy total is 0 even though its components are not. Workaround below.
        # 07-APR-2018 JTB: This should only be checked when there is NO internal PV model in use!
        if !$PVIntModel && myResults[houseCode]["avgFueluseElecGJ"] == 0 then
          myResults[houseCode]["avgFueluseElecGJ"] = element.elements[".//Annual/Consumption/Electrical"].attributes["baseload"].to_f   +
          element.elements[".//Annual/Consumption/Electrical"].attributes["airConditioning"].to_f   +
          element.elements[".//Annual/Consumption/Electrical"].attributes["appliance"].to_f   +
          element.elements[".//Annual/Consumption/Electrical"].attributes["lighting"].to_f   +
          element.elements[".//Annual/Consumption/Electrical"].attributes["heatPump"].to_f   +
          element.elements[".//Annual/Consumption/Electrical"].attributes["spaceHeating"].to_f   +
          element.elements[".//Annual/Consumption/Electrical"].attributes["spaceCooling"].to_f   +
          element.elements[".//Annual/Consumption/Electrical"].attributes["ventilation"].to_f   +
          element.elements[".//Annual/Consumption/Electrical/HotWater"].attributes["dhw"].to_f  
        end
        myResults[houseCode]["avgFueluseNatGasGJ"]  = element.elements[".//Annual/Consumption/NaturalGas"].attributes["total"].to_f  
        myResults[houseCode]["avgFueluseOilGJ"]     = element.elements[".//Annual/Consumption/Oil"].attributes["total"].to_f  
        myResults[houseCode]["avgFuelusePropaneGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["total"].to_f  
        myResults[houseCode]["avgFueluseWoodGJ"]    = element.elements[".//Annual/Consumption/Wood"].attributes["total"].to_f  

        myResults[houseCode]["avgFueluseEleckWh"]  = myResults[houseCode]["avgFueluseElecGJ"] * 277.77777778
        myResults[houseCode]["avgFueluseNatGasM3"] = myResults[houseCode]["avgFueluseNatGasGJ"] * 26.853
        myResults[houseCode]["avgFueluseOilL"]     = myResults[houseCode]["avgFueluseOilGJ"]  * 25.9576
        myResults[houseCode]["avgFuelusePropaneL"] = myResults[houseCode]["avgFuelusePropaneGJ"] / 25.23 * 1000
        myResults[houseCode]["avgFueluseWoodcord"] = myResults[houseCode]["avgFueluseWoodGJ"] / 18.30
        # estimated GJ/cord for wood/pellet burning from YHC Fuel Cost Comparison.xls

        myResults[houseCode]["avgFuelCostsTotal$"] = myResults[houseCode]["avgFuelCostsElec$"] +
        myResults[houseCode]["avgFuelCostsNatGas$"] +
        myResults[houseCode]["avgFuelCostsOil$"] +
        myResults[houseCode]["avgFuelCostsPropane$"] +
        myResults[houseCode]["avgFuelCostsWood$"]

        # JTB 10-Nov-2016: Changed variable name from avgEnergyTotalGJ to "..Gross.." and uncommented
        # the reading of avgEnergyTotalGJ above. This value does NOT include utilized PV energy and
        # avgEnergyTotalGJ does when there is an internal H2K PV model.
        myResults[houseCode]["avgEnergyGrossGJ"]  = myResults[houseCode]['avgEnergyHeatingGJ'].to_f +
        myResults[houseCode]['avgEnergyWaterHeatingGJ'].to_f +
        myResults[houseCode]['avgEnergyVentilationGJ'].to_f +
        myResults[houseCode]['avgEnergyCoolingGJ'].to_f +
        myResults[houseCode]['avgEnergyEquipmentGJ'].to_f

      

        monthArr = [ "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december" ]
        debug_out (" Picking up  AUX energy requirement from each result set. \n")

        $gAuxEnergyHeatingGJ = 0
        $MonthlyAuxHeatingMJ = 0
        monthArr.each do |mth|
          $gAuxEnergyHeatingGJ += element.elements[".//Monthly/UtilizedAuxiliaryHeatRequired"].attributes[mth].to_f / 1000
        end

        # ASF 03-Oct-2016 - picking up PV generation from each individual result set.
        if ( $PVIntModel )
          pvAvailable = 0
          pvUtilized  = 0
          #monthArr = [ "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december" ]
          monthArr.each do |mth|
            # ASF: 03-Oct-2016: Note inner caps on PhotoVoltaic likely an error (and inconsistent with convention used
            #                   elsewhere in the h2k file. Watch out for future .h2k file format changes here!)
            # ASF: 05-Oct-2016: I suspect this loop is really expensive.
            pvAvailable += h2kPostElements[".//Monthly/Load/PhotoVoltaicAvailable"].attributes[mth].to_f
            # GJ
            pvUtilized  += h2kPostElements[".//Monthly/Load/PhotoVoltaicUtilized"].attributes[mth].to_f
            # GJ
          end
          # 10-Nov-2016 JTB: Use annual PV values only! HOT2000 redistributes the monthly excesses, if available!
          myResults[houseCode]["avgEnergyPVAvailableGJ"] = pvAvailable
          # GJ
          myResults[houseCode]["avgEnergyPVUtilizedGJ"]  = pvUtilized
          # GJ
          myResults[houseCode]["avgElecPVGenkWh"] = myResults[houseCode]["avgEnergyPVAvailableGJ"] * 277.777778
          # kWh
          myResults[houseCode]["avgElecPVUsedkWh"] = myResults[houseCode]["avgEnergyPVUtilizedGJ"] * 277.777778
          # kWh

          # ***** Calculation of NET PV Revenue using HOT2000 model *****
          # 10-Nov-2016 JTB: Assumes that all annual PV energy available is used to reduce house electricity
          # to zero first, the balance is sold to utility at the rate PVTarrifDollarsPerkWh,
          # which is specified in the options file (defaulted at top if not in Options file!).
          netAnnualPV = myResults[houseCode]["avgElecPVGenkWh"] - myResults[houseCode]["avgElecPVUsedkWh"]
          if ( netAnnualPV > 0 )
            myResults[houseCode]["avgPVRevenue"] = netAnnualPV  * $PVTarrifDollarsPerkWh
          else
            myResults[houseCode]["avgPVRevenue"] = 0
          end
        else
          # Calculate and reset these values below if external PV model used
          myResults[houseCode]["avgEnergyPVAvailableGJ"] = 0.0
          myResults[houseCode]["avgEnergyPVUtilizedGJ"]  = 0.0
          myResults[houseCode]["avgElecPVGenkWh"] = 0.0
          myResults[houseCode]["avgElecPVUsedkWh"] = 0.0
          myResults[houseCode]["avgPVRevenue"] =  0.0
        end

        # This is used for debugging only.
        diff =  ( myResults[houseCode]["avgFueluseElecGJ"].to_f +
          myResults[houseCode]["avgFueluseNatGasGJ"].to_f -
          myResults[houseCode]["avgEnergyPVUtilizedGJ"]) - myResults[houseCode]["avgEnergyTotalGJ"].to_f
          myResults[houseCode]["zH2K-debug-Energy"] = diff.to_f  

          
        # break out of the element loop to avoid further processing

        #Append monthly result sets             
 

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

      end

    end
    # h2kPostElements |element| loop (and scope of local variable houseCode!)

    return myResults[myResultCode]  
    
  end 
end 


# Compute a checksum for directory, ignoring files that HOT2000 commonly alters during ar run
# Can this be put inside the module?
def self.checksum(dir)
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
