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

    $MyBuilderName = elements["HouseFile/ProgramInformation/File/BuilderName"].text
    if $MyBuilderName !=nil
      $MyBuilderName.gsub!(/\s*/, '')    # Removes mid-line white space
      $MyBuilderName.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end

    return $MyBuilderName
  end 
  
  def H2KFile.getHouseType(elements)
  
    $MyHouseType = elements["HouseFile/House/Specifications/HouseType/English"].text
    if $MyHouseType !=nil
      $MyHouseType.gsub!(/\s*/, '')    # Removes mid-line white space
      $MyHouseType.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end
    
    return $MyHouseType 
  
  end 
  
  def H2KFile.getStories(elements)
    $MyHouseStoreys = elements["HouseFile/House/Specifications/Storeys/English"].text
    if $MyHouseStoreys!= nil
      $MyHouseStoreys.gsub!(/\s*/, '')    # Removes mid-line white space
      $MyHouseStoreys.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end
    
    return $MyHouseStories
    
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
    
    $MyHouseVolume= elements["HouseFile/House/NaturalAirInfiltration/Specifications/House"].attributes["volume"].to_f
    
    return $MyHouseVolume
    
  end 
  
  
  # =========================================================================================
  # Get the name of the base file weather city
  # =========================================================================================
  def H2KFile.getWeatherCity(elements)
     wth_cityName = elements["HouseFile/ProgramInformation/Weather/Location/English"].text
     wth_cityName.gsub!(/\s*/, '')    # Removes mid-line white space
     
     return wth_cityName   
  end
  
  # =========================================================================================
  # Get the name of the base file weather city
  # =========================================================================================
  def H2KFile.getRegion(elements)   
       
     regionCode = elements["HouseFile/ProgramInformation/Weather/Region"].attributes["code"].to_i

     regionName = $ProvArr[regionCode-1] 
        
     return regionName   
  end
  
  
  # =========================================================================================
  #  Function to create the Program XML section that contains the ERS program mode data
  # =========================================================================================
  def H2KFile.createProgramXMLSection( houseElements )
     loc = "HouseFile"
     houseElements[loc].add_element("Program")
  
     loc = "HouseFile/Program"
     houseElements[loc].attributes["class"] = "ca.nrcan.gc.OEE.ERS.ErsProgram"
     houseElements[loc].add_element("Labels")
  
     loc = "HouseFile/Program/Labels"
     houseElements[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
     houseElements[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
     houseElements[loc].add_element("English")
     loc = "HouseFile/Program/Labels/English"
     houseElements[loc].add_text("EnerGuide Rating System")
     loc = "HouseFile/Program/Labels"
     houseElements[loc].add_element("French")
     loc = "HouseFile/Program/Labels/French"
     houseElements[loc].add_text("Système de cote ÉnerGuide")
  
     loc = "HouseFile/Program"
     houseElements[loc].add_element("Version")
     loc = "HouseFile/Program/Version"
     houseElements[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
     houseElements[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
     houseElements[loc].attributes["major"] = "15"
     houseElements[loc].attributes["minor"] = "1"
     houseElements[loc].attributes["build"] = "19"
     houseElements[loc].add_element("Labels")
     loc = "HouseFile/Program/Version/Labels"
     houseElements[loc].add_element("English")
     loc = "HouseFile/Program/Labels/English"
     houseElements[loc].add_text("v15.1b19")
     loc = "HouseFile/Program/Version/Labels"
     houseElements[loc].add_element("French")
     loc = "HouseFile/Program/Labels/French"
     houseElements[loc].add_text("v15.1b19")
  
     loc = "HouseFile/Program"
     houseElements[loc].add_element("SdkVersion")
     loc = "HouseFile/Program/SdkVersion"
     houseElements[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
     houseElements[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
     houseElements[loc].attributes["major"] = "1"
     houseElements[loc].attributes["minor"] = "11"
     houseElements[loc].add_element("Labels")
     loc = "HouseFile/Program/SdkVersion/Labels"
     houseElements[loc].add_element("English")
     loc = "HouseFile/Program/Labels/English"
     houseElements[loc].add_text("v1.11")
     loc = "HouseFile/Program/SdkVersion/Labels"
     houseElements[loc].add_element("French")
     loc = "HouseFile/Program/Labels/French"
     houseElements[loc].add_text("v1.11")
     
     loc = "HouseFile/Program"
     houseElements[loc].add_element("Options")
     loc = "HouseFile/Program/Options"
     houseElements[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
     houseElements[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
     houseElements[loc].add_element("Main")
     loc = "HouseFile/Program/Options/Main"
     houseElements[loc].attributes["applyHouseholdOperatingConditions"] = "false"
     houseElements[loc].attributes["applyReducedOperatingConditions"] = "false"
     houseElements[loc].attributes["atypicalElectricalLoads"] = "false"
     houseElements[loc].attributes["waterConservation"] = "false"
     houseElements[loc].attributes["referenceHouse"] = "false"
     houseElements[loc].add_element("Vermiculite")
     loc = "HouseFile/Program/Options/Main/Vermiculite"
     houseElements[loc].attributes["code"] = "1"
     houseElements[loc].add_element("English")
     loc = "HouseFile/Program/Options/Main/Vermiculite/English"
     houseElements[loc].add_text("Unknown")
     loc = "HouseFile/Program/Options/Main/Vermiculite"
     houseElements[loc].add_element("French")
     loc = "HouseFile/Program/Options/Main/Vermiculite/French"
     houseElements[loc].add_text("Inconnu")
     loc = "HouseFile/Program/Options"
     houseElements[loc].add_element("RURComments")
     loc = "HouseFile/Program/Options/RURComments"
     houseElements[loc].attributes["xml:space"] = "preserve"
     
     loc = "HouseFile/Program"
     houseElements[loc].add_element("Results")
     loc = "HouseFile/Program/Results"
     houseElements[loc].attributes["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance"
     houseElements[loc].attributes["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema"
     houseElements[loc].add_element("Tsv")
     houseElements[loc].add_element("Ers")
     houseElements[loc].add_element("RefHse")
     
  end
  
  
end 

# =========================================================================================
# h2k-utilities.rb : scripts used to manage basic I/O on h2k environment
# =========================================================================================

module H2KUtils

  # =========================================================================================
  # Add magic h2k files for diagnostics, if they don't already exist.
  # =========================================================================================
  def H2KUtils.write_h2k_magic_files(path)
  
    $WinMBFile = "#{path}\\H2K\\WINMB.H2k"
    $ROutFile  = "#{path}\\H2K\\ROutstr.H2k"
  
  

    if ( ! File.file?( $WinMBFile ) )
  
      $Handle = File.open($WinMBFile, 'w')
      $Handle.write "< auto-generated by substitute-h2k.rb >"
      $Handle.close
  
    end

    if ( ! File.file?( $ROutFile ) )
   
      $Handle = File.open($ROutFile, 'w')
      
      # Note that this text below is space-sensitive.
      $Handle.write "<Choose diagnostics>
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
      $Handle.close

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
     
     $ini_out=
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
     fH2K_ini_file_OUT.write($ini_out)
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