#!/usr/bin/env ruby
# ************************************************************************************
# substitute-h2k.rb
# Developed by Jeff Blake, CanmetENERGY-Ottawa, Natural Resources Canada
# Created Nov 2015
# Master maintained in Get Hub
#
# This is a Ruby version of the substitute-h2k.rb script customized for HOT2000 runs.
# Can be used stand-alone or with GenOpt for parametric runs or optimizations of 
# HOT2000 inputs.
# ************************************************************************************

require 'rexml/document'
require 'optparse'
require 'timeout'

include REXML   # This allows for no "REXML::" prefix to REXML methods 

# Constants in Ruby start with upper case letters and, by convention, all upper case
R_PER_RSI = 5.678263
KWH_PER_GJ = 277.778
W_PER_KW = 1000.0



# Desired ERS mode: 
# (USE Data from SOC for now. We'll think of something to do with the other modes later)
$outputHCode = "SOC" 


# Global variable names  (i.e., variables that maintain their content and use (scope) 
# throughout this file). 
# Note loose convention to start global variables with a 'g'. 
# Ruby *requires* globals to start with '$'.
startProcessTime = Time.now
$gDebug = false
$gSkipSims = false
$gTest_params = Hash.new        # test parameters
$gChoiceFile  = ""
$gOptionFile  = ""

$gTotalCost          = 0 
$gIncBaseCosts       = 12000     # Note: This is dependent on model!
$cost_type           = 0

$gRotate             = "S"

$gGOStep             = 0
$gArchGOChoiceFile   = 0

# Use lambda function to avoid the extra lines of creating each hash nesting
$blk = lambda { |h,k| h[k] = Hash.new(&$blk) }
$gOptions = Hash.new(&$blk)
$gChoices = Hash.new(&$blk)
$gResults = Hash.new(&$blk)

$gExtraDataSpecd  = Hash.new

$ThisError   = ""
$ErrorBuffer = "" 

$SaveVPOutput = 0 

$gEnergyPV = 0
$gEnergySDHW = 0
$gEnergyHeating = 0
$gEnergyCooling = 0
$gEnergyVentilation = 0 
$gEnergyWaterHeating = 0
$gEnergyEquipment = 0
$gERSNum = 0  # ERS number

$gRegionalCostAdj = 0

$gRotationAngle = 0

$gEnergyElec = 0
$gEnergyGas = 0
$gEnergyOil = 0 
$gEnergyWood = 0 
$gEnergyPellet = 0 
$gEnergyHardWood = 0
$gEnergyMixedWood = 0
$gEnergySoftWood = 0
$gEnergyTotalWood = 0

$LapsedTime     = 0 
$NumTries       = 0 

$gTotalBaseCost = 0
$gUtilityBaseCost = 0 
$PVTarrifDollarsPerkWh = 0.10

$gPeakCoolingLoadW    = 0 
$gPeakHeatingLoadW    = 0 
$gPeakElecLoadW    = 0 

# Path where this script was started and considered master
# When running GenOpt, it will be a Tmp folder!
$gMasterPath = Dir.getwd()
$gMasterPath.gsub!(/\//, '\\')

#Variables that store the average utility costs, energy amounts.  
$gAvgCost_NatGas    = 0 
$gAvgCost_Electr    = 0 
$gAvgEnergy_Total   = 0  
$gAvgCost_Propane   = 0 
$gAvgCost_Oil       = 0 
$gAvgCost_Wood      = 0 
$gAvgCost_Pellet    = 0 
$gAvgPVRevenue      = 0 
$gAvgElecCons_KWh    = 0 
$gAvgPVOutput_kWh    = 0 
$gAvgCost_Total      = 0 
$gAvgEnergyHeatingGJ = 0 
$gAvgEnergyCoolingGJ = 0 
$gAvgEnergyVentilationGJ  = 0 
$gAvgEnergyWaterHeatingGJ = 0  
$gAvgEnergyEquipmentGJ    = 0 
$gAvgNGasCons_m3     = 0 
$gAvgOilCons_l       = 0 
$gAvgPropCons_l      = 0 
$gAvgPelletCons_tonne = 0 
$gDirection = ""

$GenericWindowParams = Hash.new(&$blk)
$GenericWindowParamsDefined = 0 

$gEnergyHeatingElec = 0
$gEnergyVentElec = 0
$gEnergyHeatingFossil = 0
$gEnergyWaterHeatingElec = 0
$gEnergyWaterHeatingFossil = 0
$gAvgEnergyHeatingElec = 0
$gAvgEnergyVentElec = 0
$gAvgEnergyHeatingFossil = 0
$gAvgEnergyWaterHeatingElec = 0
$gAvgEnergyWaterHeatingFossil = 0
$gAmtOil = 0
$Locale = ""      # Weather location for current run

# Data from Hanscomb 2011 NBC analysis
$RegionalCostFactors = Hash.new
$RegionalCostFactors  = {  "Halifax"      =>  0.95 ,
                           "Edmonton"     =>  1.12 ,
                           "Calgary"      =>  1.12 ,  # Assume same as Edmonton?
                           "Ottawa"       =>  1.00 ,
                           "Toronto"      =>  1.00 ,
                           "Quebec"       =>  1.00 ,  # Assume same as Montreal?
                           "Montreal"     =>  1.00 ,
                           "Vancouver"    =>  1.10 ,
                           "PrinceGeorge" =>  1.10 ,
                           "Kamloops"     =>  1.10 ,
                           "Regina"       =>  1.08 ,  # Same as Winnipeg?
                           "Winnipeg"     =>  1.08 ,
                           "Fredricton"   =>  1.00 ,  # Same as Quebec?
                           "Whitehorse"   =>  1.00 ,
                           "Yellowknife"  =>  1.38 ,
                           "Inuvik"       =>  1.38 , 
                           "Alert"        =>  1.38   }

=begin rdoc
=========================================================================================
 METHODS: Routines called in this file must be defined before use in Ruby
          (can't put at bottom of listing).
=========================================================================================
=end
def fatalerror( err_msg )
# Display a fatal error and quit. -----------------------------------
   if ($gTest_params["logfile"])
      $fLOG.write("\nsubstitute-h2k.rb -> Fatal error: \n")
      $fLOG.write("#{err_msg}\n")
   end
   print "\n=========================================================\n"
   print "substitute-h2k.rb -> Fatal error: \n\n"
   print "     #{err_msg}\n"
   print "\n\n"
   print "substitute-h2k.rb -> Other Error or warning messages:\n\n"
   print "#{$ErrorBuffer}\n"
   exit() # Run stopped
end

# =========================================================================================
# Optionally write text to buffer -----------------------------------
# =========================================================================================
def stream_out(msg)
   if ($gTest_params["verbosity"] != "quiet")
      print msg
   end
   if ($gTest_params["logfile"])
      $fLOG.write(msg)
   end
end

# =========================================================================================
# Write debug output ------------------------------------------------
# =========================================================================================
def debug_out(debmsg)
   if $gDebug 
      puts debmsg
   end
   if ($gTest_params["logfile"])
      $fLOG.write(debmsg)
   end
end

# =========================================================================================
# Returns XML elements of HOT2000 file.
# =========================================================================================
def get_elements_from_filename(fileSpec)
   # Split fileSpec into path and filename
   (tempPath, tempFileName) = File.split( fileSpec )
   # Determine file extension
   tempExt = File.extname(tempFileName)
   
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
   fFileHANDLE.close()  # Close the since content read
  
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
# Search through the HOT2000 working file (copy of input file specified on command line) 
# and change values for settings defined in choice/options files. 
# =========================================================================================
def processFile(filespec)

   # Load all XML elements from HOT2000 file
   h2kElements = get_elements_from_filename(filespec)
   
   # Load all XML elements from HOT2000 code library file. This file is specified
   # in option Opt-DBFiles 
   codeLibName = $gOptions["Opt-DBFiles"]["options"][ $gChoices["Opt-DBFiles"] ]["values"]["1"]["conditions"]["all"]
   h2kCodeFile = $run_path + "\\StdLibs" + "\\" + codeLibName
   if ( !File.exist?(h2kCodeFile) )
      fatalerror("Code library file #{codeLibName} not found in #{$run_path + "\\StdLibs" + "\\"}!")
   else
      h2kCodeElements = get_elements_from_filename(h2kCodeFile)
   end

   # Will contain XML elements for fuel cost file, if Opt-Location is processed! 
   # Initialized here outside of Opt-Locations check to make scope broader
   h2kFuelElements = nil

   # H2K version numbers can be used to determine availability of data in the H2K file.
   # Made global so available outide of this subroutine definition
   locationText = "HouseFile/Application/Version"
   $versionMajor_H2K = h2kElements[locationText].attributes["major"]
   $versionMinor_H2K = h2kElements[locationText].attributes["minor"]
   $versionBuild_H2K = h2kElements[locationText].attributes["build"]

   # Refer to tag value for OPT-H2K-ConfigType to determine which foundations to change (further down)!
   config = $gOptions["Opt-H2KFoundation"]["options"][ $gChoices["Opt-H2KFoundation"] ]["values"]["1"]["conditions"]["all"]
   (configType, configSubType, fndTypes) = config.split('_')
   
   optDHWTankSize = "1"  # DHW variable defined here so scope includes all DHW tags
   
   $gChoiceOrder.each do |choiceEntry|
      if ( $gOptions[choiceEntry]["type"] == "internal" )
         choiceVal =  $gChoices[choiceEntry]
         tagHash = $gOptions[choiceEntry]["tags"]
         valHash = $gOptions[choiceEntry]["options"][choiceVal]["result"]
         
         for tagIndex in tagHash.keys()
            tag = tagHash[tagIndex]
            value = valHash[tagIndex]
            if ( value == "" )
               debug_out (">>>ERR on #{tag}\n")
               value = ""
            end
            
            # Replace existing values in H2K file ....................................
            
            # Weather Location
            #--------------------------------------------------------------------------
            if ( choiceEntry =~ /Opt-Location/ )
               $Locale = $gChoices["Opt-Location"] 
               if ( tag =~ /OPT-H2K-WTH-FILE/ && value != "NA" )
                  # Weather file to use for HOT2000 run
                  locationText = "HouseFile/ProgramInformation/Weather"
                  # Check on existence of H2K weather file
                  if ( !File.exist?($run_path + "\\Dat" + "\\" + value) )
                     fatalerror("Weather file #{value} not found in Dat folder !")
                  else
                     h2kElements[locationText].attributes["library"] = value
                  end
               elsif ( tag =~ /OPT-H2K-Region/ && value != "NA" )
                  # Weather region to use for HOT2000 run
                  locationText = "HouseFile/ProgramInformation/Weather/Region"
                  h2kElements[locationText].attributes["code"] = value
                  # Match Client Information Region with this Region to avoid H2K PreCheck dialog!
                  locationText = "HouseFile/ProgramInformation/Client/StreetAddress/Province"
                  provArr = [ "BRITISH COLUMBIA", "ALBERTA", "SASKATCHEWAN", "MANITOBA", "ONTARIO", "QUEBEC", "NEW BRUNSWICK", "NOVA SCOTIA", "PRINCE EDWARD ISLAND", "NEWFOUNDLAND AND LABRADOR", "YUKON TERRITORY", "NORTHWEST TERRITORY", "NUNAVUT", "OTHER" ]
                  h2kElements[locationText].text = provArr[value.to_i - 1]
               elsif ( tag =~ /OPT-H2K-Location/ && value != "NA" )
                  # Weather location to use for HOT2000 run
                  locationText = "HouseFile/ProgramInformation/Weather/Location"
                  h2kElements[locationText].attributes["code"] = value
               elsif ( tag =~ /OPT-WEATHER-FILE/ ) # Do nothing
               elsif ( tag =~ /OPT-Latitude/ ) # Do nothing
               elsif ( tag =~ /OPT-Longitude/ ) # Do nothing
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
            
            
            # Fuel Costs
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-FuelCost/ )

               # HOT2000 Fuel costing data selections (library file and fuel rates).
               #print "- TAG: #{tag} / #{value} \n"
            
               if ( tag =~ /OPT-LibraryFile/ && value != "NA" )
                  # Fuel Cost file to use for HOT2000 run
                  locationText = "HouseFile/FuelCosts"
                  # Check on existence of H2K weather file
                  h2kFuelFile = $run_path + "\\StdLibs" + "\\" + value
                  if ( !File.exist?(h2kFuelFile) )
                     fatalerror("Fuel cost file #{value} not found in #{$run_path + "\\StdLibs" + "\\"}!")
                  else
                     h2kElements[locationText].attributes["library"] = value
                     #print "> FILE: "+ value + "\n"

                     # Open fuel file and read elements to use below. This assumes that this tag
                     # always comes before the remainder of the weather location tags below!!
                     h2kFuelElements = get_elements_from_filename(h2kFuelFile)
                  end

               elsif ( tag =~ /OPT-ElecName/ && value != "NA" )
                  SetFuelCostRates( "Electricity", h2kElements, h2kFuelElements, value )
                  
               elsif ( tag =~ /OPT-GasName/ && value != "NA" )
                  SetFuelCostRates( "NaturalGas", h2kElements, h2kFuelElements, value )
                  
               elsif ( tag =~ /OPT-OilName/ && value != "NA" )
                  SetFuelCostRates( "Oil", h2kElements, h2kFuelElements, value )
                  
               elsif ( tag =~ /OPT-PropaneName/ && value != "NA" )
                  SetFuelCostRates( "Propane", h2kElements, h2kFuelElements, value )
                  
               elsif ( tag =~ /OPT-WoodName/ && value != "NA" )
                  SetFuelCostRates( "Wood", h2kElements, h2kFuelElements, value )
                  
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
            
            
            # Air Infiltration Rate
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-ACH/ )
               if ( tag =~ /Opt-ACH/ && value != "NA" )
                  # Need to set the House/AirTightnessTest code attribute to "Blower door test values" (x)
                  locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/House/AirTightnessTest"
                  h2kElements[locationText].attributes["code"] = "x"
                  # Must also remove "Air Leakage Test Data" section, if present since it will negate ACH option
                  locationText = "HouseFile/House/NaturalAirInfiltration/AirLeakageTestData"
                  if ( h2kElements[locationText] != nil )
                        # Need to remove this section!
                        locationText = "HouseFile/House/NaturalAirInfiltration"
                        h2kElements[locationText].delete_element("AirLeakageTestData")
                  end
                  # Set the blower door test value in airChangeRate field
                  locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
                  h2kElements[locationText].attributes["airChangeRate"] = value
                  h2kElements[locationText].attributes["isCalculated"] = "true"
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
            
            
            # Ceilings
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-Ceilings/ )
               if ( tag =~ /Opt-Ceiling/ && value != "NA" )
                  # If this surface code name exists in the code library, use the code 
                  # (either Fav or UsrDef) for ceiling and ceiling_flat surfaces. 
                  # Code names in library are unique.
                  # Note: Not using "Standard", non-library codes (e.g., 2221292000)
                  
                  # Look for this code name in code library (Favorite and UserDefined)
                  thisCodeInHouse = false
                  useThisCodeID = "Code 99"
                  foundFavLibCode = false
                  foundUsrDefLibCode = false
                  foundAtticCeil = false
                  foundCathCeil = false
                  ceilngType = ""
                  foundCodeLibElement = ""
                  # Check in Ceiling Codes used for: Attic/Gable, Attic/Hip, Scissor
                  locationCodeFavText = "Codes/Ceiling/Favorite/Code"
                  h2kCodeElements.each(locationCodeFavText) do |codeElement| 
                     if ( codeElement.get_text("Label") == value )
                        foundFavLibCode = true
                        foundAtticCeil = true
                        foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                        break
                     end
                  end
                  if ( ! foundFavLibCode )
                     # Also check in CeilingFlat Codes used for: Cathedral and Flat
                     locationCodeFavText = "Codes/CeilingFlat/Favorite/Code"
                     h2kCodeElements.each(locationCodeFavText) do |codeElement| 
                        if ( codeElement.get_text("Label") == value )
                           foundFavLibCode = true
                           foundCathCeil = true
                           foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                           break
                        end
                     end
                  end
                  # Code library names are also unique across Favorite and User Defined codes
                  if ( ! foundFavLibCode )
                     # Check in Ceiling Codes used for: Attic/Gable, Attic/Hip, Scissor
                     locationCodeUsrDefText = "Codes/Ceiling/UserDefined/Code"
                     h2kCodeElements.each(locationCodeUsrDefText) do |codeElement| 
                        if ( codeElement.get_text("Label") == value )
                           foundUsrDefLibCode = true
                           foundAtticCeil = true
                           foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                           break
                        end
                     end
                  end
                  if ( ! foundFavLibCode && ! foundUsrDefLibCode )
                     # Also check in CeilingFlat Codes used for: Cathedral and Flat
                     locationCodeUsrDefText = "Codes/CeilingFlat/UserDefined/Code"
                     h2kCodeElements.each(locationCodeUsrDefText) do |codeElement| 
                        if ( codeElement.get_text("Label") == value )
                           foundUsrDefLibCode = true
                           foundCathCeil = true
                           foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                           break
                        end
                     end
                  end
                  if ( foundAtticCeil )
                     ceilngType = "Ceiling"
                  else
                     ceilngType = "CeilingFlat"
                  end
                  
                  if ( foundFavLibCode || foundUsrDefLibCode )
                     # Check to see if this code is already used in H2K file and add, if not.
                     # Code references are in the <Codes> section. Can't have duplicates!
                     if ( foundFavLibCode )
                        locationText = "HouseFile/Codes/#{ceilngType}/Favorite"
                     else
                        locationText = "HouseFile/Codes/#{ceilngType}/UserDefined"
                     end
                     h2kElements.each(locationText + "/Code") do |element| 
                        if ( element.get_text("Label") == value )
                           thisCodeInHouse = true
                           useThisCodeID = element.attributes["id"]
                           break
                        end
                     end
                     if ( ! thisCodeInHouse )
                        if ( h2kElements["HouseFile/Codes/#{ceilngType}"] == nil )
                           # No section ofthis type in house file Codes section -- add it!
                           h2kElements["HouseFile/Codes"].add_element(ceilngType)
                        end
                        if ( h2kElements[locationText] == nil )
                           # No Favorite or UserDefined section in house file Codes section -- add it!
                           if ( foundFavLibCode )
                              h2kElements["HouseFile/Codes/#{ceilngType}"].add_element("Favorite")
                           else
                              h2kElements["HouseFile/Codes/#{ceilngType}"].add_element("UserDefined")
                           end
                        end
                        foundCodeLibElement.attributes["id"] = useThisCodeID
                        h2kElements[locationText].add(foundCodeLibElement)
                     end
                     
                     # Change all existing surface references of this type to useThisCodeID
                     # NOTE: House ceiling components all under "Ceiling" tag - only <Codes> 
                     # section distinguishes between "Ceiling" and "CeilingFlat"
                     locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
                     h2kElements.each(locationText) do |element| 
                        # Check if each house entry has an "idref" attribute and add if it doesn't.
                        if element.attributes["idref"] != nil
                           element.attributes["idref"] = useThisCodeID
                        else
                           element.add_attribute("idref", useThisCodeID)
                        end
                        element.text = value
                        element.attributes["nominalInsulation"] = foundCodeLibElement.attributes["nominalRValue"]
                     end
                  else
                     # Code name not found in the code library
                     # Do nothing! Must be either a User Specified R-value in OPT-H2K-EffRValue
                     # or NA in OPT-H2K-EffRValue
                     debug_out(" INFO: Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}\n")
                  end
                  
               elsif ( tag =~ /OPT-H2K-EffRValue/ && value != "NA" )
                  # Change ALL existing ceiling codes to User Specified R-value
                  locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
                  h2kElements.each(locationText) do |element| 
                     element.text = "User specified"
                     element.attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                     if element.attributes["idref"] != nil then
                        # Must delete attribute for User Specified!
                        element.delete_attribute("idref")
                     end
                  end
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
               
            
            # Main Walls
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-MainWall/ )
               if ( tag =~ /OPT-H2K-CodeName/ && value != "NA" )
                  # If this surface type code name exists in the code library, use the code 
                  # (either Fav or UsrDef) for all surfaces. Code names in library are unique.
                  # Note: Not using "Standard", non-library codes (e.g., 2221292000)
                  
                  # Look for this code name in code library (Favorite and UserDefined)
                  thisCodeInHouse = false
                  useThisCodeID = "Code 89"
                  foundFavLibCode = false
                  foundUsrDefLibCode = false
                  foundCodeLibElement = ""
                  locationCodeFavText = "Codes/Wall/Favorite/Code"
                  h2kCodeElements.each(locationCodeFavText) do |codeElement| 
                     if ( codeElement.get_text("Label") == value )
                        foundFavLibCode = true
                        foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                        break
                     end
                  end
                  # Code library names are also unique across Favorite and User Defined codes
                  if ( ! foundFavLibCode )
                     locationCodeUsrDefText = "Codes/Wall/UserDefined/Code"
                     h2kCodeElements.each(locationCodeUsrDefText) do |codeElement| 
                        if ( codeElement.get_text("Label") == value )
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
                        locationText = "HouseFile/Codes/Wall/Favorite"
                     else
                        locationText = "HouseFile/Codes/Wall/UserDefined"
                     end
                     h2kElements.each(locationText + "/Code") do |element| 
                        if ( element.get_text("Label") == value )
                           thisCodeInHouse = true
                           useThisCodeID = element.attributes["id"]
                           break
                        end
                     end
                     if ( ! thisCodeInHouse )
                        if ( h2kElements["HouseFile/Codes/Wall"] == nil )
                           # No section ofthis type in house file Codes section -- add it!
                           h2kElements["HouseFile/Codes"].add_element("Wall")
                        end
                        if ( h2kElements[locationText] == nil )
                           # No Favorite or UserDefined section in house file Codes section -- add it!
                           if ( foundFavLibCode )
                              h2kElements["HouseFile/Codes/Wall"].add_element("Favorite")
                           else
                              h2kElements["HouseFile/Codes/Wall"].add_element("UserDefined")
                           end
                        end
                        foundCodeLibElement.attributes["id"] = useThisCodeID
                        h2kElements[locationText].add(foundCodeLibElement)
                     end
                     # Change all existing surface references of this type to useThisCodeID
                     locationText = "HouseFile/House/Components/Wall/Construction/Type"
                     h2kElements.each(locationText) do |element| 
                        # Check if each house entry has an "idref" attribute and add if it doesn't.
                        if element.attributes["idref"] != nil
                           element.attributes["idref"] = useThisCodeID
                        else
                           element.add_attribute("idref", useThisCodeID)
                        end
                        element.text = value
                        element.attributes["nominalInsulation"] = foundCodeLibElement.attributes["nominalRValue"]
                     end
                  else
                     # Code name not found in the code library
                     # Do nothing! Must be either a User Specified R-value in OPT-H2K-EffRValue
                     # or NA in OPT-H2K-EffRValue
                     debug_out(" INFO: Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}\n")
                  end
                  
               elsif ( tag =~ /OPT-H2K-EffRValue/ && value != "NA" )
                  # Change ALL existing wall codes to User Specified R-value
                  locationText = "HouseFile/House/Components/Wall/Construction/Type"
                  h2kElements.each(locationText) do |element| 
                     element.text = "User specified"
                     element.attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                     if element.attributes["idref"] != nil then
                        # Must delete attribute for User Specified!
                        element.delete_attribute("idref")
                     end
                  end
                  
               elsif ( tag =~ /Opt-MainWall-Bri/ )    # Do nothing
               elsif ( tag =~ /Opt-MainWall-Vin/ )    # Do nothing
               elsif ( tag =~ /Opt-MainWall-Dry/ )    # Do nothing
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
               
               
            # Generic wall insulation thickness settings: - one layer
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-GenericWall_1Layer_definitions/ )
               if ( tag =~ /Opt-H2K-EffRValue/ && value != "NA" )
                  # Change ALL existing wall codes to User Specified R-value
                  locationText = "HouseFile/House/Components/Wall/Construction/Type"
                  h2kElements.each(locationText) do |element| 
                     element.text = "User specified"
                     element.attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                     if element.attributes["idref"] != nil then
                        # Must delete attribute for User Specified!
                        element.delete_attribute("idref")
                     end
                  end
               end
            
               
            # Exposed Floor User-Specified R-Values
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-ExposedFloor/ )
               if ( tag =~ /OPT-H2K-CodeName/ &&  value != "NA" )
                  # If this code name exists in the code library, use the code 
                  # (either Fav or UsrDef) for all entries. Code names in library are unique.
                  # Note: Not using "Standard", non-library codes (e.g., 2221292000)
                  
                  # Look for this code name in code library (Favorite and UserDefined)
                  thisCodeInHouse = false
                  useThisCodeID = "Code 79"
                  foundFavLibCode = false
                  foundUsrDefLibCode = false
                  foundCodeLibElement = ""
                  locationCodeFavText = "Codes/Floor/Favorite/Code"
                  h2kCodeElements.each(locationCodeFavText) do |codeElement| 
                     if ( codeElement.get_text("Label") == value )
                        foundFavLibCode = true
                        foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                        break
                     end
                  end
                  # Code library names are also unique across Favorite and User Defined codes
                  if ( ! foundFavLibCode )
                     locationCodeUsrDefText = "Codes/Floor/UserDefined/Code"
                     h2kCodeElements.each(locationCodeUsrDefText) do |codeElement| 
                        if ( codeElement.get_text("Label") == value )
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
                        locationText = "HouseFile/Codes/Floor/Favorite"
                     else
                        locationText = "HouseFile/Codes/Floor/UserDefined"
                     end
                     h2kElements.each(locationText + "/Code") do |element| 
                        if ( element.get_text("Label") == value )
                           thisCodeInHouse = true
                           useThisCodeID = element.attributes["id"]
                           break
                        end
                     end
                     if ( ! thisCodeInHouse )
                        if ( h2kElements["HouseFile/Codes/Floor"] == nil )
                           # No section ofthis type in house file Codes section -- add it!
                           h2kElements["HouseFile/Codes"].add_element("Floor")
                        end
                        if ( h2kElements[locationText] == nil )
                           # No Favorite or UserDefined section in house file Codes section -- add it!
                           if ( foundFavLibCode )
                              h2kElements["HouseFile/Codes/Floor"].add_element("Favorite")
                           else
                              h2kElements["HouseFile/Codes/Floor"].add_element("UserDefined")
                           end
                        end
                        foundCodeLibElement.attributes["id"] = useThisCodeID
                        h2kElements[locationText].add(foundCodeLibElement)
                     end
                     # Change all existing surface references of this type to useThisCodeID
                     locationText = "HouseFile/House/Components/Floor/Construction/Type"
                     h2kElements.each(locationText) do |element| 
                        # Check if each house entry has an "idref" attribute and add if it doesn't.
                        if element.attributes["idref"] != nil
                           element.attributes["idref"] = useThisCodeID
                        else
                           element.add_attribute("idref", useThisCodeID)
                        end
                        element.text = value
                        element.attributes["nominalInsulation"] = foundCodeLibElement.attributes["nominalRValue"]
                     end
                  else
                     # Code name not found in the code library
                     # Do nothing! Must be either a User Specified R-value in OPT-H2K-EffRValue
                     # or NA in OPT-H2K-EffRValue
                     debug_out(" INFO: Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}\n")
                  end
                  
               elsif ( tag =~ /OPT-H2K-EffRValue/ &&  value != "NA" )
                  # Change ALL existing floor codes to User Specified R-value
                  locationText = "HouseFile/House/Components/Floor/Construction/Type"
                  h2kElements.each(locationText) do |element| 
                     element.text = "User specified"
                     element.attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                     if element.attributes["idref"] != nil then
                        # Must delete attribute for User Specified!
                        element.delete_attribute("idref")
                     end
                  end
               elsif ( tag =~ /Opt-ExposedFloor/ )   # Do nothing
               elsif ( tag =~ /Opt-ExposedFloor-r/ )   # Do nothing
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
               
               
            # Windows (by facing direction)
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-CasementWindows/ )
               if ( tag =~ /Opt-win-S-CON/ &&  value != "NA" )
                  ChangeWinCodeByOrient( "S", value, h2kCodeElements, h2kElements, choiceEntry, tag )
               
               elsif ( tag =~ /Opt-win-E-CON/ &&  value != "NA" )
                  ChangeWinCodeByOrient( "E", value, h2kCodeElements, h2kElements, choiceEntry, tag )

               elsif ( tag =~ /Opt-win-N-CON/ &&  value != "NA" )
                  ChangeWinCodeByOrient( "N", value, h2kCodeElements, h2kElements, choiceEntry, tag )
               
               elsif ( tag =~ /Opt-win-W-CON/ &&  value != "NA" )
                  ChangeWinCodeByOrient( "W", value, h2kCodeElements, h2kElements, choiceEntry, tag )

               elsif ( tag =~ /Opt-win-SE-CON/ &&  value != "NA" )
                  ChangeWinCodeByOrient( "SE", value, h2kCodeElements, h2kElements, choiceEntry, tag )
                  
               elsif ( tag =~ /Opt-win-SW-CON/ &&  value != "NA" )
                  ChangeWinCodeByOrient( "SW", value, h2kCodeElements, h2kElements, choiceEntry, tag )
                  
               elsif ( tag =~ /Opt-win-NE-CON/ &&  value != "NA" )
                  ChangeWinCodeByOrient( "NE", value, h2kCodeElements, h2kElements, choiceEntry, tag )
                  
               elsif ( tag =~ /Opt-win-NW-CON/ &&  value != "NA" )
                  ChangeWinCodeByOrient( "NW", value, h2kCodeElements, h2kElements, choiceEntry, tag )
                  
               elsif ( tag =~ /Opt-win-S-OPT/ )    # Do nothing
               elsif ( tag =~ /Opt-win-E-OPT/ )    # Do nothing
               elsif ( tag =~ /Opt-win-N-OPT/ )    # Do nothing
               elsif ( tag =~ /Opt-win-W-OPT/ )    # Do nothing
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
            
               
            # Foundations
            #  - All types: Basement, Walkout, Crawlspace, Slab-On-Grade
            #  - Interior & Exterior wall insulation, below slab insulation
            #    based on insulaion configuration type
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-H2KFoundation/ )
               locHouseStr = [ "", "" ]
               
               if ( tag =~ /OPT-H2K-ConfigType/ &&  value != "NA" )
                  # Set the configuration type for the fnd types specified in choice file
                  if ( fndTypes == "B" )
                     locHouseStr[0] = "HouseFile/House/Components/Basement/Configuration"
                  elsif ( fndTypes == "W" )
                     locHouseStr[0] = "HouseFile/House/Components/Walkout/Configuration"
                  elsif ( fndTypes == "C" )
                     locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Configuration"
                  elsif ( fndTypes == "S" )
                     locHouseStr[0] = "HouseFile/House/Components/Slab/Configuration"
                  elsif ( fndTypes == "ALL" )
                     # Check to avoid configs starting with "S" used in B or W and
                     # configs starting with "B" used in C or S!
                     if ( configType =~ /^B/ )
                        locHouseStr[0] = "HouseFile/House/Components/Basement/Configuration"
                        locHouseStr[1] = "HouseFile/House/Components/Walkout/Configuration"
                     elsif ( configType =~ /^S/ )
                        locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Configuration"
                        locHouseStr[1] = "HouseFile/House/Components/Slab/Configuration"
                     end
                  end
                  locHouseStr.each do |locStr|
                     if ( locStr != "" )
                        h2kElements.each(locStr) do |element| 
                           # Use the existing configuration type to determine if a new XML section req'd
                           existConfigType = element.attributes["type"]
                           if ( existConfigType.match('N', 3) && !configType.match('N', 3) )
                              # Add missing XML section to Floor for "AddedToSlab"
                              addMissingAddedToSlab(element)
                           end
                           if ( existConfigType.match('E', 2) && !configType.match('E', 2) )
                              # Add missing XML section to Wall for "InteriorAddedInsulation"
                              addMissingInteriorAddedInsulation(element)
                           end
                           if ( existConfigType.match('I', 2) && !configType.match('I', 2) )
                              # Add missing XML section to Wall for "ExteriorAddedInsulation"
                              addMissingExteriorAddedInsulation(element)
                           end
                           # Change existing configutaion values to match choice
                           element.attributes["type"] = configType
                           element.attributes["subtype"] = configSubType
                           element.text = configType + "_" + configSubType
                        end
                     end
                  end
                  
               elsif ( tag =~ /OPT-H2K-IntWallCode/ &&  value != "NA" )
                  # If this code name exists in the code library, use the code 
                  # (either Fav or UsrDef) for all entries. Code names in library are unique.
                  # Note: Not using "Standard", non-library codes (e.g., 2221292000)
                  
                  # Look for this code name in code library (Favorite and UserDefined)
                  thisCodeInHouse = false
                  useThisCodeID = "Code 110"
                  foundFavLibCode = false
                  foundUsrDefLibCode = false
                  foundCodeLibElement = ""
                  # Note: Both Basement and Walkout interior wall codes saved under "BasementWall"
                  locTextArr1 = [ "BasementWall", "CrawlspaceWall" ]
                  fndWallNum = 0
                  locTextArr1.each do |txt|
                     locationCodeFavText = "Codes/#{txt}/Favorite/Code"
                     h2kCodeElements.each(locationCodeFavText) do |codeElement| 
                        if ( codeElement.get_text("Label") == value )
                           foundFavLibCode = true
                           foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                           break
                        end
                     end
                  end
                  # Code library names are unique so also check User Defined codes
                  if ( ! foundFavLibCode )
                     locTextArr1.each do |txt|
                        locationCodeUsrDefText = "Codes/#{txt}/UserDefined/Code"
                        h2kCodeElements.each(locationCodeUsrDefText) do |codeElement| 
                           if ( codeElement.get_text("Label") == value )
                              foundUsrDefLibCode = true
                              foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                              break
                           end
                        end
                     end
                  end
                  locStr = ""
                  locTextArr2 = [ "Favorite", "UserDefined" ]
                  if ( foundFavLibCode || foundUsrDefLibCode )
                     # Check to see if this code is already used in H2K file and add, if not.
                     # Code references are in the <Codes> section. Avoid duplicates!
                     locTextArr1.each do |fndTypeTxt|
                        locTextArr2.each do |favOrUsrDefTxt|
                           locStr = "HouseFile/Codes/#{fndTypeTxt}/#{favOrUsrDefTxt}/Code"
                           h2kElements.each(locStr) do |element| 
                              if ( element.get_text("Label") == value )
                                 thisCodeInHouse = true
                                 useThisCodeID = element.attributes["id"]
                                 break
                              end
                           end
                           break if thisCodeInHouse   # break Fav/UsrDef loop if found
                        end
                        break if thisCodeInHouse      # break fnd type loop if found
                     end
                     if ( ! thisCodeInHouse )
                        if ( fndTypes == "B" || fndTypes == "W" || (fndTypes == "ALL" && configType =~ /^B/) )
                           fndWallNum = 0
                        elsif ( fndTypes == "C" || (fndTypes == "ALL" && configType =~ /^S/) )
                           fndWallNum = 1
                        end
                        locStr = "HouseFile/Codes/#{locTextArr1[fndWallNum]}"
                        if ( h2kElements[locStr] == nil )
                           # No section of this type in house file Codes section -- add it!
                           h2kElements["HouseFile/Codes"].add_element(locTextArr1[fndWallNum])
                        end
                        if ( foundFavLibCode )
                           locationText = locStr + "/Favorite"
                        else
                           locationText = locStr + "/UserDefined"
                        end
                        if ( h2kElements[locationText] == nil )
                           # No Favorite or UserDefined section in house file Codes section -- add it!
                           if ( foundFavLibCode )
                              h2kElements[locStr].add_element("Favorite")
                           else
                              h2kElements[locStr].add_element("UserDefined")
                           end
                        end
                        foundCodeLibElement.attributes["id"] = useThisCodeID
                        h2kElements[locationText].add(foundCodeLibElement)
                     end
                     # Change all interior insulated surface references of this type to useThisCodeID
                     locHouseStr = [ "", "" ]
                     if ( fndTypes == "B" )
                        locHouseStr[0] = "HouseFile/House/Components/Basement/Wall/Construction/InteriorAddedInsulation"
                     elsif ( fndTypes == "W" )
                        locHouseStr[0] = "HouseFile/House/Components/Walkout/Wall/Construction/InteriorAddedInsulation"
                     elsif ( fndTypes == "C" || ( fndTypes == "ALL" && configType =~ /^S/ ) )
                        locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Wall/Construction/Type"
                     elsif ( fndTypes == "ALL" && configType =~ /^B/ )
                        locHouseStr[0] = "HouseFile/House/Components/Basement/Wall/Construction/InteriorAddedInsulation"
                        locHouseStr[1] = "HouseFile/House/Components/Walkout/Wall/Construction/InteriorAddedInsulation"
                     end
                     locHouseStr.each do |locationString|
                        if ( locationString != "" )
                           h2kElements.each(locationString) do |element| 
                              # Check if each house entry has an "idref" attribute and add if it doesn't.
                              if element.attributes["idref"] != nil
                                 element.attributes["idref"] = useThisCodeID
                              else
                                 element.add_attribute("idref", useThisCodeID)
                              end
                              element[1].text = value    # Description tag
                              element.attributes["nominalInsulation"] = foundCodeLibElement.attributes["nominalRValue"]
                           end
                        end
                     end
                  else
                     # Code name not found in the code library
                     # Do nothing! Must be either a User Specified R-value in OPT-H2K-EffRValue
                     # or NA in OPT-H2K-EffRValue
                     debug_out(" INFO: Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}\n")
                  end
                  
               elsif ( tag =~ /OPT-H2K-IntWall-RValue/ &&  value != "NA" )
                  # Change ALL existing interior wall codes to User Specified R-value
                  locHouseStr = [ "", "" ]
                  if ( fndTypes == "B" )
                     locHouseStr[0] = "HouseFile/House/Components/Basement/Wall/Construction/InteriorAddedInsulation"
                  elsif ( fndTypes == "W" )
                     locHouseStr[0] = "HouseFile/House/Components/Walkout/Wall/Construction/InteriorAddedInsulation"
                  elsif ( fndTypes == "C" || ( fndTypes == "ALL" && configType =~ /^S/ ) )
                     locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Wall/Construction/Type"
                  elsif ( fndTypes == "ALL" && configType =~ /^B/ )
                     locHouseStr[0] = "HouseFile/House/Components/Basement/Wall/Construction/InteriorAddedInsulation"
                     locHouseStr[1] = "HouseFile/House/Components/Walkout/Wall/Construction/InteriorAddedInsulation"
                  end
                  locHouseStr.each do |locationString|
                     if ( locationString != "" )
                        h2kElements.each(locationString) do |element| 
                           if element.attributes["idref"] != nil then
                              # Must delete attribute for User Specified!
                              element.delete_attribute("idref")
                           end
                        end
                        h2kElements.each(locationString+"/Description") do |element| 
                           element.text = "User specified"     # Description tag
                        end
                        h2kElements.each(locationString+"/Composite/Section") do |element| 
                           element.attributes["rsi"] = (value.to_f / R_PER_RSI).to_s
                           element.attributes["rank"] = "1"
                           element.attributes["percentage"] = "100"
                        end
                     end
                  end
                  
               elsif ( tag =~ /OPT-H2K-ExtWall-RVal/ &&  value != "NA" ) 
                  # Change ALL existing exterior wall codes to User Specified R-value
                  locHouseStr = [ "", "" ]
                  if ( fndTypes == "B" )
                     locHouseStr[0] = "HouseFile/House/Components/Basement/Wall/Construction/ExteriorAddedInsulation"
                  elsif ( fndTypes == "W" )
                     locHouseStr[0] = "HouseFile/House/Components/Walkout/Wall/Construction/ExteriorAddedInsulation"
                  elsif ( fndTypes == "ALL" && configType =~ /^B/ )
                     locHouseStr[0] = "HouseFile/House/Components/Basement/Wall/Construction/ExteriorAddedInsulation"
                     locHouseStr[1] = "HouseFile/House/Components/Walkout/Wall/Construction/ExteriorAddedInsulation"
                  end
                  locHouseStr.each do |locationString|
                     if ( locationString != "" )
                        h2kElements.each(locationString) do |element| 
                           if element.attributes["idref"] != nil then
                              # Must delete attribute for User Specified!
                              element.delete_attribute("idref")
                           end
                        end
                        h2kElements.each(locationString+"/Description") do |element| 
                           element.text = "User specified"     # Description tag
                        end
                        h2kElements.each(locationString+"/Composite/Section") do |element| 
                           element.attributes["rsi"] = (value.to_f / R_PER_RSI).to_s
                           element.attributes["rank"] = "1"
                           element.attributes["percentage"] = "100"
                        end
                     end
                  end
                  
               elsif ( tag =~ /OPT-H2K-BelowSlab-RVal/ &&  value != "NA" )
                  locHouseStr = [ "", "", "", "" ]
                  if ( fndTypes == "B" )
                     locHouseStr[0] = "HouseFile/House/Components/Basement/Floor/Construction/AddedToSlab"
                  elsif ( fndTypes == "W" )
                     locHouseStr[0] = "HouseFile/House/Components/Walkout/Floor/Construction/AddedToSlab"
                  elsif ( fndTypes == "C" )
                     locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Floor/Construction/AddedToSlab"
                  elsif ( fndTypes == "S" )
                     locHouseStr[0] = "HouseFile/House/Components/Slab/Floor/Construction/AddedToSlab"
                  elsif ( fndTypes == "ALL")
                     locHouseStr[0] = "HouseFile/House/Components/Basement/Floor/Construction/AddedToSlab"
                     locHouseStr[1] = "HouseFile/House/Components/Walkout/Floor/Construction/AddedToSlab"
                     locHouseStr[2] = "HouseFile/House/Components/Crawlspace/Floor/Construction/AddedToSlab"
                     locHouseStr[3] = "HouseFile/House/Components/Slab/Floor/Construction/AddedToSlab"
                  end
                  locHouseStr.each do |locationString|
                     if ( locationString != "" )
                        h2kElements.each(locationString) do |element| 
                           element.text = "User specified"     # Description tag
                           element.attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                           if element.attributes["code"] != nil then
                              # Must delete attribute for User Specified!
                              element.delete_attribute("code")
                           end
                        end
                     end
                  end
                  
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
               
               
            # DWHR (+SDHW) - uses explicit values in options file (not internal models)!
            #---------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-DWHRandSDHW / )
               if ( tag =~ /Opt-DHWDailyDrawLperDay/ &&  value != "NA" )
                  # Turn off DWHR model flag in DHW system
                  locationText = "HouseFile/House/Components/HotWater/Primary"
                  h2kElements[locationText].attributes["hasDrainWaterHeatRecovery"] = "false"
                  # Set draw based on options file settings for Opt-DHWLoadScale, location & plate options
                  locationText = "HouseFile/House/BaseLoads/Summary"
                  h2kElements[locationText].attributes["hotWaterLoad"] = value
               end
            
               
            # Electrical Loads
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-ElecLoadScale/ )
               if ( tag =~ /Opt-ElecLoadScale/ &&  value != "NA" )
                  # Do nothing until determine how to handle!
               end
            
               
            # DHW System (includies DWHR options for internal H2K model. Don't use
            #              both external (explicit) method AND this one!)
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-DHWSystem/ )
               if ( tag =~ /Opt-H2K-Fuel/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary"
                  if ( h2kElements[locationText].attributes["pilotEnergy"] == nil )
                     if ( value != 1 ) # Not electricity
                        h2kElements[locationText].add_attribute("pilotEnergy", "0")
                     end
                  else
                     if ( value == 1 ) # Electricity
                        h2kElements[locationText].delete_attribute("pilotEnergy")
                     end
                  end
				  
				  locationText = "HouseFile/House/Components/HotWater/Primary/EnergySource"
                  h2kElements[locationText].attributes["code"] = value
                  
               elsif ( tag =~ /Opt-H2K-TankType/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/TankType"
                  if ( value.to_i == 4 || value.to_i == 5 || value.to_i == 6 || value.to_i == 12 )
                     optDHWTankSize = "7" # Set to "Not Applicable" for 4:Tankless, 5:Instantaneous, 12:Instantaneous (condensing), 6:Instantaneous (pilot) or get core message
                  else
                     optDHWTankSize = "1" # User Specified
                  end
                  h2kElements[locationText].attributes["code"] = value
                  
               elsif ( tag =~ /Opt-H2K-TankSize/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/TankVolume"
                  h2kElements[locationText].attributes["code"] = optDHWTankSize # See above for tank type!
                  h2kElements[locationText].attributes["value"] = value # Volume in Lites
                  
               elsif ( tag =~ /Opt-H2K-EF/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/EnergyFactor"
                  h2kElements[locationText].attributes["code"] = 2      # User Specified option
                  h2kElements[locationText].attributes["value"] = value # EF value (fraction)

               elsif ( tag =~ /Opt-H2K-FlueDiameter/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary"
			      h2kElements[locationText].attributes["flueDiameter"] = value 
           


                  
               elsif ( tag =~ /Opt-H2K-IntHeatPumpCOP/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary"
                  # This attribute only exists for an *Integrated* Heat Pump
                  h2kElements[locationText].attributes["heatPumpCoefficient"] = value  # COP of integrated HP
               
               # DWHR inputs in the DHW section are available for change ONLY if the Base Loads input 
               # "User Specified Electrical and Water Usage" input is checked. If this is not checked, then
               # changes made here will be overwritten by the Base Loads user inputs for Water Usage.
               
			   
			   
			   
               elsif ( tag =~ /Opt-H2K-HasDWHR/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary"
                  if ( value == "true" )
                     if ( h2kElements[locationText].attributes["hasDrainWaterHeatRecovery"] == "false" )
                        # Need to add DWHR XML section!
                        addMissingDWHR( h2kElements )
                     end
                  else
                     if ( h2kElements[locationText].attributes["hasDrainWaterHeatRecovery"] == "true" )
                        # Need to remove DWHR section!
                        h2kElements[locationText].delete_element("DrainWaterHeatRecovery")
                     end
                  end
                  h2kElements[locationText].attributes["hasDrainWaterHeatRecovery"] = value  # Flag for DWHR
               
               elsif ( tag =~ /Opt-H2K-DHWR-showerLength/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery"
                  h2kElements[locationText].attributes["showerLength"] = value # Shower length in minutes (float)
               
               elsif ( tag =~ /Opt-H2K-DHWR-dailyShowers/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery"
                  h2kElements[locationText].attributes["dailyShowers"] = value  # Number of daily showers (float)
               
               elsif ( tag =~ /Opt-H2K-DHWR-preheatShowerTank/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery"
                  h2kElements[locationText].attributes["preheatShowerTank"] = value  # true or false
               
               # Can't modify DWHR Effectiveness rating at 9.5 l/min directly. It is precalculated based on
               # manufacturer name and model (core overrides this value with a calculation)! See Effectiveness6.xls
               elsif ( tag =~ /Opt-H2K-DHWR-Manufacturer/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/EquipmentInformation/Manufacturer"
                  h2kElements[locationText].text = value  # DWHR Manufacturer
               
               elsif ( tag =~ /Opt-H2K-DHWR-Model/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/EquipmentInformation/Model"
                  h2kElements[locationText].text = value  # DWHR Model
               
               # THIS DOESN"T APPEAR TO DO ANYTHING! *********************************
               elsif ( tag =~ /Opt-H2K-DHWR-Efficiency_code/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/Efficiency"
                  h2kElements[locationText].attributes["code"] = value  # DWHR Efficiency code (1, 2 or 3)
               
               elsif ( tag =~ /Opt-H2K-DHWR-ShowerTemperature_code/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/ShowerTemperature"
                  h2kElements[locationText].attributes["code"] = value  # DWHR Shower temperature code (1:Cool, 2:Warm or 3:Hot)
               
               elsif ( tag =~ /Opt-H2K-DHWR-ShowerHead_code/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/ShowerHead"
                  h2kElements[locationText].attributes["code"] = value  # DWHR Showerhead code (0, 1, 2, 3 or 4)
                 
               end
            
               
            # Heating & Cooling Systems (Type 1 & 2)
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-HVACSystem/ )
               sysType1 = [ "Baseboards", "Furnace", "Boiler", "ComboHeatDhw", "P9" ]
               sysType2 = [ "AirHeatPump", "WaterHeatPump", "GroundHeatPump", "AirConditioning" ]
               
               if ( tag =~ /Opt-H2K-SysType1/ &&  value != "NA" )
                  locationText = "HouseFile/House/HeatingCooling/Type1"
                  if ( h2kElements[locationText + "/#{value}"] == nil )
                     # Create a new system type 1 element with default values for all of its sub-elements
                     createH2KSysType1(h2kElements,value)
                     # Delete the HVAC element that was there (and all of its sub-elements)!
                     sysType1.each do |sysType1Name|
                        if ( h2kElements[locationText + "/#{sysType1Name}"] != nil && sysType1Name != value )
                           h2kElements[locationText].delete_element(sysType1Name)
                        end
                     end
                  else
                     # System type 1 is already set to this value -- do nothing!
                  end
                  
               elsif ( tag =~ /Opt-H2K-SysType2/ &&  value != "NA" )
                  locationText = "HouseFile/House/HeatingCooling/Type2"
                  if ( h2kElements[locationText + "/#{value}"] == nil )
                     # Create a new system type 2 element with default values for all of its sub-elements
                     # unless "None" is specified
                     if ( value != "None" )
                        createH2KSysType2(h2kElements,value)
                     end
                     # Delete the HVAC element that was there (and all of its sub-elements)!
                     sysType2.each do |sysType2Name|
                        if ( h2kElements[locationText + "/#{sysType2Name}"] != nil && sysType2Name != value )
                           h2kElements[locationText].delete_element(sysType2Name)
                        end
                     end
                  else
                     # System type 2 is already set to this value -- do nothing!
                  end
                  
               elsif ( tag =~ /Opt-H2K-Type1Fuel/ &&  value != "NA" )
                  # Apply to all Type 1 systems except Baseboards, which are electric by definition!
                  sysType1.each do |sysType1Name|
                     if ( sysType1Name != "Baseboards" )
                        if ( sysType1Name == "P9" )
                           locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData/EnergySource"
                        else
                           locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Equipment/EnergySource"
                        end
                        if ( h2kElements[locationText] != nil )
                           h2kElements[locationText].attributes["code"] = value
                        end
                     end
                  end
                  
               elsif ( tag =~ /Opt-H2K-Type1EqpType/ &&  value != "NA" )
                  sysType1.each do |sysType1Name|
                     if ( sysType1Name != "Baseboards" && sysType1Name != "P9" )
                        locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Equipment/EquipmentType"
                     else
                        locationText = ""
                     end
                     if ( h2kElements[locationText] != nil )
                        h2kElements[locationText].attributes["code"] = value
                     end
                  end
                  
               elsif ( tag =~ /Opt-H2K-Type1CapOpt/ &&  value != "NA" )
                  sysType1.each do |sysType1Name|
                     if ( sysType1Name != "P9" )
                        locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Specifications/OutputCapacity"
                     else
                        locationText = ""
                     end
                     if ( h2kElements[locationText] != nil )
                        h2kElements[locationText].attributes["code"] = value
                     end
                  end
                  
               elsif ( tag =~ /Opt-H2K-Type1CapVal/ &&  value != "NA" && "#{value}" != "" )
                  sysType1.each do |sysType1Name|
                     if ( sysType1Name != "P9" )
                        locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Specifications/OutputCapacity"
                     else
                        locationText = ""
                     end
                     if ( h2kElements[locationText] != nil )
                        h2kElements[locationText].attributes["value"] = value
                     end
                  end
                  
               elsif ( tag =~ /Opt-H2K-Type1EffType/ &&  value != "NA" )
                  sysType1.each do |sysType1Name|
                     if ( sysType1Name != "P9" && sysType1Name != "Baseboards" )
                        locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Specifications"
                     else
                        locationText = ""
                     end
                     if ( h2kElements[locationText] != nil )
                        h2kElements[locationText].attributes["isSteadyState"] = value
                     end
                  end
                  
               elsif ( tag =~ /Opt-H2K-Type1EffVal/ &&  value != "NA" )
                  sysType1.each do |sysType1Name|
                     if ( sysType1Name != "P9" && sysType1Name != "Baseboards" )
                        locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Specifications"
                     else
                        locationText = ""
                     end
                     if ( h2kElements[locationText] != nil )
                        h2kElements[locationText].attributes["efficiency"] = value
                     end
                  end

               elsif ( tag =~ /Opt-H2K-Type1FanCtl/ &&  value != "NA" )
                  locationText = "HouseFile/House/HeatingCooling/Type1/FansAndPump/Mode"
                  h2kElements[locationText].attributes["code"] = value
                  
               elsif ( tag =~ /Opt-H2K-Type1EEMotor/ &&  value != "NA" )
                  locationText = "HouseFile/House/HeatingCooling/Type1/FansAndPump"
                  h2kElements[locationText].attributes["hasEnergyEfficientMotor"] = value
               
               elsif ( tag =~ /Opt-H2K-Type2CCaseH/ && value != "NA" )
                  sysType2.each do |sysType2Name| 
                     if ( sysType2Name == "AirHeatPump" )
                        locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                        if ( h2kElements[locationText] != nil )
                           locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Equipment"
                           h2kElements[locationText].attributes["crankcaseHeater"] = value 
                        end 
                     end 
                  end 
                  
               elsif ( tag =~ /Opt-H2K-Type2Func/ && value != "NA" )
                  sysType2.each do |sysType2Name| 
                     if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump")
                        locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                        if ( h2kElements[locationText] != nil )
                           locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Equipment/Function"
                           h2kElements[locationText].attributes["code"] = value 
                        end 
                     end 
                  end 

               elsif ( tag =~ /Opt-H2K-Type2Type/ && value != "NA" )
                  sysType2.each do |sysType2Name| 
                     if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump")
                        locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                        if ( h2kElements[locationText] != nil )
                           locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Equipment/Type"
                           h2kElements[locationText].attributes["code"] = value 
                        end 
                     end 
                  end 

               elsif ( tag =~ /Opt-H2K-Type2CapOpt/ && value != "NA" )
                  sysType2.each do |sysType2Name| 
                     if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump")
                        locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                        if ( h2kElements[locationText] != nil )
                           locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Specifications/OutputCapacity"
                           h2kElements[locationText].attributes["code"] = value 
                           h2kElements[locationText].attributes["value"] = "5.6"
                           h2kElements[locationText].attributes["uiUnits"] = "kW"
                        end 
                     end 
                  end 
                 
               elsif ( tag =~ /Opt-H2K-Type2CapVal/ && value != "NA"  && "#{value}" != "" )
                  sysType2.each do |sysType2Name| 
                     if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump")
                        locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                        if ( h2kElements[locationText] != nil )
                           locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Specifications/OutputCapacity"
                           h2kElements[locationText].attributes["value"] = value 
                           h2kElements[locationText].attributes["uiUnits"] = "kW"
                        end 
                     end 
                  end                  
                  
               elsif ( tag =~ /Opt-H2K-Type2HeatCOP/ && value != "NA"  && "#{value}" != "" )
                  sysType2.each do |sysType2Name| 
                     if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump")
                        locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                        if ( h2kElements[locationText] != nil )
                           locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Specifications/HeatingEfficiency"
                           h2kElements[locationText].attributes["isCOP"] = "true" 
                           h2kElements[locationText].attributes["value"] = value
                        end 
                     end 
                  end                               
                  
               elsif ( tag =~ /Opt-H2K-Type2CoolCOP/ && value != "NA"  && "#{value}" != "" )
                  sysType2.each do |sysType2Name| 
                     if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump")
                        locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                        if ( h2kElements[locationText] != nil )
                           locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Specifications/CoolingEfficiency"
                           h2kElements[locationText].attributes["isCOP"] = "true" 
                           h2kElements[locationText].attributes["value"] = value
                        end 
                     end 
                  end                     
                  
               elsif ( tag =~ /Opt-H2K-Type2CutoffType/ && value != "NA"  && "#{value}" != "" )
                  sysType2.each do |sysType2Name| 
                     if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump")
                        locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                        if ( h2kElements[locationText] != nil )
                           locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Temperature/CutoffType"
                           h2kElements[locationText].attributes["code"] = value
                        end 
                     end 
                  end 
                  
               elsif ( tag =~ /Opt-H2K-Type2CutoffTemp/ && value != "NA"  && "#{value}" != "" )
                  sysType2.each do |sysType2Name| 
                     if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump")
                        locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                        if ( h2kElements[locationText] != nil )
                           locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Temperature/CutoffType"
                           h2kElements[locationText].attributes["value"] = value
                        end 
                     end 
                  end    
               end     
            
              
            # HRV System
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-HRVspec/ )
               if ( tag =~ /OPT-H2K-FlowReq/ &&  value != "NA" )
                  locationText = "HouseFile/House/Ventilation/Requirements/Use"
                  h2kElements[locationText].attributes["code"] = value
                  
                  roomLabels = [ "living", "bedrooms", "bathrooms", "utility", "otherHabitable" ]
                  numRooms = 0
                  locationText = "HouseFile/House/Ventilation/Rooms"
                  roomLabels.each do |roommName|
                     numRooms += h2kElements[locationText].attributes[roommName].to_i
                  end
                  if ( value == 1 && numRooms == 0 )
                     debug_out("Choice: #{choiceEntry} Tag: #{tag} \n  No rooms entered for F326 Ventilation requirement!")
                  end
                  
               elsif ( tag =~ /OPT-H2K-AirDistType/ &&  value != "NA" )
                  locationText = "HouseFile/House/Ventilation/WholeHouse/AirDistributionType"
                  h2kElements[locationText].attributes["code"] = value
                  
               elsif ( tag =~ /OPT-H2K-OpSched/ &&  value != "NA" )
                  locationText = "HouseFile/House/Ventilation/WholeHouse/OperationSchedule"
                  h2kElements[locationText].attributes["code"] = "0"    # User Specified
                  h2kElements[locationText].attributes["value"] = value
                  
               elsif ( tag =~ /OPT-H2K-HRVSupply/ &&  value != "NA" )
                  locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"
                  if ( h2kElements[locationText] == nil )
                     createHRV(h2kElements)
                  end
                  h2kElements[locationText].attributes["supplyFlowrate"] = value    # L/s supply
                  h2kElements[locationText].attributes["exhaustFlowrate"] = value   # Exhaust = Supply 
                  
               elsif ( tag =~ /OPT-H2K-Rating1/ &&  value != "NA" )
                  locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"
                  if ( h2kElements[locationText] == nil )
                     createHRV(h2kElements)
                  end
                  h2kElements[locationText].attributes["efficiency1"] = value    # Rating 1 Efficiency
                  
               elsif ( tag =~ /OPT-H2K-Rating2/ &&  value != "NA" )
                  locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"
                  if ( h2kElements[locationText] == nil )
                     createHRV(h2kElements)
                  end
                  h2kElements[locationText].attributes["efficiency2"] = value    # Rating 1 Efficiency
                  
               end
            
               
            # Roof Pitch - change slope of all ext. ceilings (i.e., roofs)
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-RoofPitch/ )
               if ( tag =~ /Opt-H2K-RoofSlope/ &&  value != "NA" )
                  locationText = "HouseFile/House/Components/Ceiling/Measurements/Slope"
                  h2kElements.each(locationText) do |element| 
                     element.attributes["code"] = "0"    # User Specified slope
                     element.attributes["value"] = value
                  end
               end
            
                  
            # PV - external (does not use H2K model but choice file option for sizing)
            # Available for 16 Opt-Locations and 3 roof pitches
            #-----------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-StandoffPV/ )
               if ( tag =~ /Opt-StandoffPV/ &&  value != "NA" && value != "NoPV" )
                  # All processing done after the run in post-process()
                  # Turn off H2K internal model, if it is on!
                  locationText = "HouseFile/House/Generation/Systems"
                  if ( h2kElements[locationText].attributes["photovoltaic"] == "true" )
                     h2kElements[locationText].attributes["photovoltaic"] = false
                     locationText = "HouseFile/House/Generation"
                     h2kElements[locationText].delete_element("Photovoltaic")
                  end
               end
            
               
            # PV - internal. Uses H2K PV Generation model
            # Limited number of parameters available in options file.
            #-----------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-H2K-PV/ )
               if ( tag =~ /Opt-H2K-Area/ &&  value != "NA" )
                  # Check if specified area is possible for this house file
                  totalCeilArea = 0.0
                  locationText = "HouseFile/House/Components/Ceiling/Measurements"
                  h2kElements.each(locationText) do |element| 
                     totalCeilArea += element.attributes["area"].to_f
                  end
                  if ( value.to_f > totalCeilArea )
                     debug_out("WARNING: Specified PV area (#{value} sq.m.) is greater than available roof area (#{totalCeilArea.round().to_s} sq.m.)")
                  end
                  checkCreatePV( h2kElements )
                  locationText = "HouseFile/House/Generation/Photovoltaic/Array"
                  h2kElements[locationText].attributes["area"] = value
                  
               elsif ( tag =~ /Opt-H2K-Slope/ &&  value != "NA" )
                  checkCreatePV( h2kElements )
                  locationText = "HouseFile/House/Generation/Photovoltaic/Array"
                  h2kElements[locationText].attributes["slope"] = value
                  
               elsif ( tag =~ /Opt-H2K-Azimuth/ &&  value != "NA" )
                  checkCreatePV( h2kElements )
                  locationText = "HouseFile/House/Generation/Photovoltaic/Array"
                  h2kElements[locationText].attributes["azimuth"] = value
                  
               elsif ( tag =~ /Opt-H2K-PVModuleType/ &&  value != "NA" )
                  checkCreatePV( h2kElements )
                  locationText = "HouseFile/House/Generation/Photovoltaic/Module/Type"
                  h2kElements[locationText].attributes["code"] = value
                  
               elsif ( tag =~ /Opt-H2K-GridAbsRate/ &&  value != "NA" )
                  checkCreatePV( h2kElements )
                  locationText = "HouseFile/House/Generation/Photovoltaic/Efficiency"
                  h2kElements[locationText].attributes["gridAbsorptionRate"] = value
                  
               elsif ( tag =~ /Opt-H2K-InvEff/ &&  value != "NA" )
                  checkCreatePV( h2kElements )
                  locationText = "HouseFile/House/Generation/Photovoltaic/Efficiency"
                  h2kElements[locationText].attributes["inverterEfficiency"] = value
                  
               end
               
            else
               # Do nothing -- we're ignoring all other tags!
               #debug_out("Tag #{tag} ignored!\n")
            end
         end
      end
   end
   
   # Save changes to the XML doc in existing working H2K file (overwrite original)
   newXMLFile = File.open(filespec, "w")
   $XMLdoc.write(newXMLFile)
   newXMLFile.close
   
end

# =========================================================================================
#  Function to set fuel cost rates
# =========================================================================================
def SetFuelCostRates( fuelName, houseElements, fuelElements, theValue )
   
   locationFuelText = "FuelCosts/#{fuelName}/Fuel"
   
   fuelElements.each(locationFuelText) do |element| 
      
      # This code allows for the "auto" case that matches the fuel lib name with the
      # location name AS WELL AS the case when the fuel name matches some other name in 
      # the fuel lib. The unmatched case could be used to evaluate different fuel rate 
      # structures in one weather location. Note that Opt-Location must be set in the choice
      # file for "auto" to work (it is assigned to $Locale above, so order also matters)!
      if ( (theValue == "auto" && element.get_text("Label") == $Locale) || element.get_text("Label") == theValue)

         # Get fuel ID# from fuel library to save in house
         fuelId = element.attributes["id"]
         houseElements["HouseFile/FuelCosts/#{fuelName}/Fuel"].attributes["id"] = fuelId

         locationText = "HouseFile/FuelCosts/#{fuelName}/Fuel/Label"
         houseElements[locationText].text = element.get_text("Label")
         
         locationText = "HouseFile/FuelCosts/#{fuelName}/Fuel/Units"
         houseElements[locationText].attributes["code"] = element[5].attributes["code"]
         
         locationText = "HouseFile/FuelCosts/#{fuelName}/Fuel/Minimum"
         houseElements[locationText].attributes["units"] =  element[7].attributes["units"]
         houseElements[locationText].attributes["charge"] = element[7].attributes["charge"]
         locationText = "HouseFile/FuelCosts/#{fuelName}/Fuel/RateBlocks/Block1"
         houseElements[locationText].attributes["units"] =  element[9][1].attributes["units"]
         houseElements[locationText].attributes["costPerUnit"] = element[9][1].attributes["costPerUnit"]
         locationText = "HouseFile/FuelCosts/#{fuelName}/Fuel/RateBlocks/Block2"
         houseElements[locationText].attributes["units"] = element[9][3].attributes["units"]
         houseElements[locationText].attributes["costPerUnit"] = element[9][3].attributes["costPerUnit"]
         locationText = "HouseFile/FuelCosts/#{fuelName}/Fuel/RateBlocks/Block3"
         houseElements[locationText].attributes["units"] = element[9][5].attributes["units"]
         houseElements[locationText].attributes["costPerUnit"] = element[9][5].attributes["costPerUnit"]
         locationText = "HouseFile/FuelCosts/#{fuelName}/Fuel/RateBlocks/Block4"
         houseElements[locationText].attributes["units"] = element[9][7].attributes["units"]
         houseElements[locationText].attributes["costPerUnit"] = element[9][7].attributes["costPerUnit"]                      
      
      end   # Matches wth locale OR simple name match

   end   # End of fuel element loop
   
end

# =========================================================================================
#  Function to change window codes by orientation
# =========================================================================================
def ChangeWinCodeByOrient( winOrient, newValue, h2kCodeLibElements, h2kFileElements, choiceEntryValue, tagValue )
   # Change ALL existing windows for this orientation (winOrient) to the library code name
   # specified in newValue. If this code name exists in the code library, use the code 
   # (either Fav or UsrDef) for all entries facing in this direction. Code names in library are unique.
   # Note: Not using "Standard", non-library codes (e.g., 2221292000)

   # Look for this code name in code library (Favorite and UserDefined)
   windowFacingH2KVal = { "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8 }

   $useThisCodeID  = {  "S"  =>  191 ,
                        "SE" =>  192 ,
                        "E"  =>  193 ,
                        "NE" =>  194 ,
                        "N"  =>  195 ,
                        "NW" =>  196 ,  
                        "W"  =>  197 ,
                        "SW" =>  198   }
   
   thisCodeInHouse = false
   foundFavLibCode = false
   foundUsrDefLibCode = false
   foundCodeLibElement = ""
   locationCodeFavText = "Codes/Window/Favorite/Code"
   h2kCodeLibElements.each(locationCodeFavText) do |codeElement| 
      if ( codeElement.get_text("Label") == newValue )
         foundFavLibCode = true
         foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
         break
      end
   end
   # Code library names are also unique across Favorite and User Defined codes
   if ( ! foundFavLibCode )
      locationCodeUsrDefText = "Codes/Window/UserDefined/Code"
      h2kCodeLibElements.each(locationCodeUsrDefText) do |codeElement| 
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
            # No section ofthis type in house file Codes section -- add it!
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
         # 9=FacingDirection
         if ( element[9].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
            # Check if each house entry has an "idref" attribute and add if it doesn't.
            # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
            if element[3][1].attributes["idref"] != nil            # ../Construction/Type
               element[3][1].attributes["idref"] = $useThisCodeID[winOrient]
            else
               element[3][1].add_attribute("idref", $useThisCodeID[winOrient])
            end
            element[3][1].text = newValue
         end
      end
      # Windows in basement wall elements
      locationText = "HouseFile/House/Components/Basement/Components/Window"
      h2kFileElements.each(locationText) do |element| 
         # 9=FacingDirection
         if ( element[9].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
            # Check if each house entry has an "idref" attribute and add if it doesn't.
            # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
            if element[3][1].attributes["idref"] != nil            # ../Construction/Type
               element[3][1].attributes["idref"] = $useThisCodeID[winOrient]
            else
               element[3][1].add_attribute("idref", $useThisCodeID[winOrient])
            end
            element[3][1].text = newValue
         end
      end
      # Windows in walkout wall elements
      locationText = "HouseFile/House/Components/Walkout/Components/Window"
      h2kFileElements.each(locationText) do |element| 
         # 9=FacingDirection
         if ( element[9].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
            # Check if each house entry has an "idref" attribute and add if it doesn't.
            # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
            if element[3][1].attributes["idref"] != nil            # ../Construction/Type
               element[3][1].attributes["idref"] = $useThisCodeID[winOrient]
            else
               element[3][1].add_attribute("idref", $useThisCodeID[winOrient])
            end
            element[3][1].text = newValue
         end
      end
      # Windows in crawlspace elements             [******** Skip for now ********]
      # Windows in ceiling elements (skylights)    [******** Skip for now ********]
      # Windows in door elements                   [******** Skip for now ********]
   else
      # Code name not found in the code library
      # Since no User Specified option for windows this must be an error!
      fatalerror(" INFO: Missing code name: #{newValue} in code library for H2K #{choiceEntryValue} tag:#{tagValue}\n")
   end

end

# =========================================================================================
#  Add missing "AddedToSlab" section to Floor Construction of appropriate fnd
# =========================================================================================
def addMissingAddedToSlab(theElement)
   # locationStr contains "HouseFile/House/Components/X/", where X is "Basement", 
   # "Walkout", "Crawlspace" or "Slab"
   # The Floor element is always three elements from the basement Configuration element
   theFloorElement = theElement.next_element.next_element.next_element
   theFloorConstElement = theFloorElement[1] # First child element is always "Construction"
   theSlabElement = theFloorConstElement.add_element("AddedToSlab", {"rValue"=>"0", "nominalInsulation"=>"0"})
   theSlabElement.add_text("User specified")
end

# =========================================================================================
#  Add missing "InteriorAddedInsulation" section to Wall Construction of appropriate fnd
# =========================================================================================
def addMissingInteriorAddedInsulation(theElement)
   # locationStr contains "HouseFile/House/Components/X/", where X is "Basement", 
   # "Walkout", "Crawlspace" or "Slab"
   # The Wall element is always four elements from the basement Configuration element
   theWallElement = theElement.next_element.next_element.next_element.next_element
   theWallConstElement = theWallElement[1] # First child element is always "Construction"
   theIntWallElement = theWallConstElement.add_element("InteriorAddedInsulation", {"nominalInsulation"=>"0"})
   theIntWallElement.add_element("Description")
   theIntWallCompElement = theIntWallElement.add_element("Composite")
   theIntWallCompElement.add_element("Section", {"rank"=>"1", "percentage"=>"100", "rsi"=>"0", "nominalRsi"=>"0"} )
end

# =========================================================================================
#  Add missing "ExteriorAddedInsulation" section to Wall Construction of appropriate fnd
# =========================================================================================
def addMissingExteriorAddedInsulation(theElement)
   # locationStr contains "HouseFile/House/Components/X/", where X is "Basement", 
   # "Walkout", "Crawlspace" or "Slab"
   # The Wall element is always four elements from the basement Configuration element
   theWallElement = theElement.next_element.next_element.next_element.next_element
   theWallConstElement = theWallElement[1] # First child element is always "Construction"
   theExtWallElement = theWallConstElement.add_element("ExteriorAddedInsulation", {"nominalInsulation"=>"0"})
   theExtWallElement.add_element("Description")
   theExtWallCompElement = theExtWallElement.add_element("Composite")
   theExtWallCompElement.add_element("Section", {"rank"=>"1", "percentage"=>"100", "rsi"=>"0", "nominalRsi"=>"0"} )
end

# =========================================================================================
#  Check if there is a PV section and add, if not.
# =========================================================================================
def checkCreatePV( elements )
   if ( elements["HouseFile/House/Generation/Photovoltaic"] == nil )
      locationText = "HouseFile/House/Generation/Systems"
      elements[locationText].attributes["photovoltaic"] = "true"
      locationText = "HouseFile/House/Generation"
      elements[locationText].add_element("Photovoltaic")
      locationText = "HouseFile/House/Generation/Photovoltaic"
      elements[locationText].add_element("EquipmentInformation")
      elements[locationText].add_element("Array")
      locationText = "HouseFile/House/Generation/Photovoltaic/Array"
      elements[locationText].attributes["area"] = "50"
      elements[locationText].attributes["slope"] = "42"
      elements[locationText].attributes["azimuth"] = "0"
      
      locationText = "HouseFile/House/Generation/Photovoltaic"
      elements[locationText].add_element("Efficiency")
      locationText = "HouseFile/House/Generation/Photovoltaic/Efficiency"
      elements[locationText].attributes["miscellaneousLosses"] = "3"
      elements[locationText].attributes["otherPowerLosses"] = "1"
      elements[locationText].attributes["inverterEfficiency"] = "90"
      elements[locationText].attributes["gridAbsorptionRate"] = "90"
      
      locationText = "HouseFile/House/Generation/Photovoltaic"
      elements[locationText].add_element("Module")
      locationText = "HouseFile/House/Generation/Photovoltaic/Module"
      elements[locationText].attributes["efficiency"] = "13"
      elements[locationText].attributes["cellTemperature"] = "45"
      elements[locationText].attributes["coefficientOfEfficiency"] = "0.4"
      elements[locationText].add_element("Type")
      locationText = "HouseFile/House/Generation/Photovoltaic/Module/Type"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
   end
end

# =========================================================================================
# Add an HRV section (check done external to this method)
# =========================================================================================
def createHRV( elements )
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
   elements[locationText].attributes["code"] = "1"    # HRV
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
   elements[locationText].attributes["code"] = "4" # Main Floor
   elements[locationText].add_element("English")
   elements[locationText].add_element("French")
   locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply"
   elements[locationText].add_element("Type")
   locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply/Type"
   elements[locationText].attributes["code"] = "1" # Flexible
   elements[locationText].add_element("English")
   elements[locationText].add_element("French")
   locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply"
   elements[locationText].add_element("Sealing")
   locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Supply/Sealing"
   elements[locationText].attributes["code"] = "2" # Sealed
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
   elements[locationText].attributes["code"] = "4" # Main Floor
   elements[locationText].add_element("English")
   elements[locationText].add_element("French")
   locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust"
   elements[locationText].add_element("Type")
   locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust/Type"
   elements[locationText].attributes["code"] = "1" # Flexible
   elements[locationText].add_element("English")
   elements[locationText].add_element("French")
   locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust"
   elements[locationText].add_element("Sealing")
   locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv/ColdAirDucts/Exhaust/Sealing"
   elements[locationText].attributes["code"] = "2" # Sealed
   elements[locationText].add_element("English")
   elements[locationText].add_element("French")
end

# Procedure to create a new H2K system Type 1 in the XML house file
# =========================================================================================
# Add a System Type 1 section (check for existence done external to this method)
# =========================================================================================
def createH2KSysType1( elements, sysType1Name )
   locationText = "HouseFile/House/HeatingCooling/Type1"
   
   elements[locationText].add_element(sysType1Name)
   if ( sysType1Name == "Baseboards" )
      locationText = "HouseFile/House/HeatingCooling/Type1/Baseboards"
      elements[locationText].add_element("EquipmentInformation")
      locationText = "HouseFile/House/HeatingCooling/Type1/Baseboards/EquipmentInformation"
      elements[locationText].attributes["numberOfElectronicThermostats"] = "0"
      
      locationText = "HouseFile/House/HeatingCooling/Type1/Baseboards"
      elements[locationText].add_element("Specifications")
      locationText = "HouseFile/House/HeatingCooling/Type1/Baseboards/Specifications"
      elements[locationText].attributes["sizingFactor"] = "1.1"
      elements[locationText].attributes["efficiency"] = "100"
      elements[locationText].add_element("OutputCapacity")
      locationText = "HouseFile/House/HeatingCooling/Type1/Baseboards/Specifications/OutputCapacity"
      elements[locationText].attributes["code"] = "2"    # Calculated
      elements[locationText].attributes["value"] = "0"   # Calculated value - will be replaced!
      elements[locationText].attributes["uiUnits"] = "kW"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
   elsif ( sysType1Name == "Furnace" )
      locationText = "HouseFile/House/HeatingCooling/Type1/Furnace"
      elements[locationText].add_element("EquipmentInformation")
      locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/EquipmentInformation"
      elements[locationText].attributes["energystar"] = "false"
      elements[locationText].add_element("Manufacturer")

      locationText = "HouseFile/House/HeatingCooling/Type1/Furnace"
      elements[locationText].add_element("Equipment")
      locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment"
      elements[locationText].attributes["isBiEnergy"] = "false"
      elements[locationText].attributes["switchoverTemperature"] = "0"
      elements[locationText].add_element("EnergySource")
      locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EnergySource"
      elements[locationText].attributes["code"] = "2"    # Gas
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment"
      elements[locationText].add_element("EquipmentType")
      locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EquipmentType"
      elements[locationText].attributes["code"] = "1"    # Furnace with cont. pilot
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type1/Furnace"
      elements[locationText].add_element("Specifications")
      locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Specifications"
      elements[locationText].attributes["sizingFactor"] = "1.1"
      elements[locationText].attributes["efficiency"] = "78"
      elements[locationText].attributes["isSteadyState"] = "true"
      elements[locationText].attributes["pilotLight"] = "0"
      elements[locationText].attributes["flueDiameter"] = "127"
      elements[locationText].add_element("OutputCapacity")
      locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Specifications/OutputCapacity"
      elements[locationText].attributes["code"] = "2"    # Calculated
      elements[locationText].attributes["value"] = "0"   # Calculated value - will be replaced!
      elements[locationText].attributes["uiUnits"] = "kW"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
   elsif ( sysType1Name == "Boiler" )
      locationText = "HouseFile/House/HeatingCooling/Type1/Boiler"
      elements[locationText].add_element("EquipmentInformation")
      locationText = "HouseFile/House/HeatingCooling/Type1/Boiler/EquipmentInformation"
      elements[locationText].attributes["energystar"] = "false"
      elements[locationText].add_element("Manufacturer")

      locationText = "HouseFile/House/HeatingCooling/Type1/Boiler"
      elements[locationText].add_element("Equipment")
      locationText = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment"
      elements[locationText].attributes["isBiEnergy"] = "false"
      elements[locationText].attributes["switchoverTemperature"] = "0"
      elements[locationText].add_element("EnergySource")
      locationText = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment/EnergySource"
      elements[locationText].attributes["code"] = "2"    # Gas
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment"
      elements[locationText].add_element("EquipmentType")
      locationText = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment/EquipmentType"
      elements[locationText].attributes["code"] = "1"    # Boiler with cont. pilot
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type1/Boiler"
      elements[locationText].add_element("Specifications")
      locationText = "HouseFile/House/HeatingCooling/Type1/Boiler/Specifications"
      elements[locationText].attributes["sizingFactor"] = "1.1"
      elements[locationText].attributes["efficiency"] = "78"
      elements[locationText].attributes["isSteadyState"] = "true"
      elements[locationText].attributes["pilotLight"] = "0"
      elements[locationText].attributes["flueDiameter"] = "127"
      elements[locationText].add_element("OutputCapacity")
      locationText = "HouseFile/House/HeatingCooling/Type1/Boiler/Specifications/OutputCapacity"
      elements[locationText].attributes["code"] = "2"    # Calculated
      elements[locationText].attributes["value"] = "0"   # Calculated value - will be replaced!
      elements[locationText].attributes["uiUnits"] = "kW"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
   elsif ( sysType1Name == "ComboHeatDhw" )
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[locationText].add_element("EquipmentInformation")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/EquipmentInformation"
      elements[locationText].attributes["energystar"] = "false"
      elements[locationText].add_element("Manufacturer")

      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[locationText].add_element("Equipment")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment"
      elements[locationText].add_element("EnergySource")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment/EnergySource"
      elements[locationText].attributes["code"] = "2"    # Gas
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment"
      elements[locationText].add_element("EquipmentType")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment/EquipmentType"
      elements[locationText].attributes["code"] = "1"    # ComboHeatDhw with cont. pilot
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[locationText].add_element("Specifications")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Specifications"
      elements[locationText].attributes["sizingFactor"] = "1.1"
      elements[locationText].attributes["efficiency"] = "78"
      elements[locationText].attributes["isSteadyState"] = "true"
      elements[locationText].attributes["pilotLight"] = "25.3"
      elements[locationText].attributes["flueDiameter"] = "152.4"
      elements[locationText].add_element("OutputCapacity")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Specifications/OutputCapacity"
      elements[locationText].attributes["code"] = "2"    # Calculated
      elements[locationText].attributes["value"] = "0"   # Calculated value - will be replaced!
      elements[locationText].attributes["uiUnits"] = "kW"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")

      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw"
      elements[locationText].add_element("ComboTankAndPump")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[locationText].add_element("TankCapacity")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump/TankCapacity"
      elements[locationText].attributes["code"] = "3"
      elements[locationText].attributes["value"] = "151.4"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[locationText].add_element("EnergyFactor")
      elements[locationText].attributes["useDefaults"] = "true"
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[locationText].add_element("TankLocation")
      elements[locationText].attributes["code"] = "2"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/ComboTankAndPump"
      elements[locationText].add_element("CirculationPump")
      elements[locationText].attributes["isCalculated"] = "true"
      elements[locationText].attributes["value"] = "0"
      elements[locationText].attributes["hasEnergyEfficientMotor"] = "false"
      
   elsif ( sysType1Name == "P9" )
      locationText = "HouseFile/House/HeatingCooling/Type1/P9"
      elements[locationText].attributes["id"] = "0"
      elements[locationText].attributes["numberOfSystems"] = "1"
      elements[locationText].attributes["thermalPerformanceFactor"] = "0"
      elements[locationText].attributes["annualElectricity"] = "0"
      elements[locationText].attributes["spaceHeatingCapacity"] = "0"
      elements[locationText].attributes["spaceHeatingEfficiency"] = "0"
      elements[locationText].attributes["waterHeatingPerformanceFactor"] = "0"
      elements[locationText].attributes["burnerInput"] = "0"
      elements[locationText].attributes["recoveryEfficiency"] = "0"
      elements[locationText].attributes["isUserSpecified"] = "false"
      elements[locationText].add_element("EquipmentInformation")

      locationText = "HouseFile/House/HeatingCooling/Type1/P9"
      elements[locationText].add_element("TestData")
      locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[locationText].attributes["controlsPower"] = "0"
      elements[locationText].attributes["circulationPower"] = "0"
      elements[locationText].attributes["dailyUse"] = "0"
      elements[locationText].attributes["standbyLossWithFan"] = "0"
      elements[locationText].attributes["standbyLossWithoutFan"] = "0"
      elements[locationText].attributes["oneHourRatingHotWater"] = "0"
      elements[locationText].attributes["oneHourRatingConcurrent"] = "0"
      elements[locationText].add_element("EnergySource")
      locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData/EnergySource"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[locationText].add_element("NetEfficiency")
      locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData/NetEfficiency"
      elements[locationText].attributes["loadPerformance15"] = "0"
      elements[locationText].attributes["loadPerformance40"] = "0"
      elements[locationText].attributes["loadPerformance100"] = "0"
      locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[locationText].add_element("ElectricalUse")
      locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData/ElectricalUse"
      elements[locationText].attributes["loadPerformance15"] = "0"
      elements[locationText].attributes["loadPerformance40"] = "0"
      elements[locationText].attributes["loadPerformance100"] = "0"
      locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
      elements[locationText].add_element("BlowerPower")
      locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData/BlowerPower"
      elements[locationText].attributes["loadPerformance15"] = "0"
      elements[locationText].attributes["loadPerformance40"] = "0"
      elements[locationText].attributes["loadPerformance100"] = "0"
   end
end   # createH2KSysType1

# =========================================================================================
# Procedure to create a new H2K system Type 2 in the XML house file. Check done external.
# =========================================================================================
def createH2KSysType2( elements, sysType2Name )

   locationText = "HouseFile/House/HeatingCooling/Type2"
   elements[locationText].add_element(sysType2Name)
   elements[locationText].attributes["shadingInF280Cooling"] = "AccountedFor"

   if ( sysType2Name == "AirHeatPump" )
   
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[locationText].add_element("EquipmentInformation")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/EquipmentInformation"
      elements[locationText].attributes["energystar"] = "false"
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[locationText].add_element("Equipment")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment"
      elements[locationText].attributes["crankcaseHeater"] = "60"
      elements[locationText].add_element("Type")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment/Type"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment"
      elements[locationText].add_element("Function")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Equipment/Function"
      elements[locationText].attributes["code"] = "2"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[locationText].add_element("Specifications")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications"
      elements[locationText].add_element("OutputCapacity")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications/OutputCapacity"
      elements[locationText].attributes["code"] = "2"
      # I think these can be commented out if we default to 'calculated'
      #elements[locationText].attributes["value"] = ""
      #elements[locationText].attributes["uiUnits"] = "kW"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications"
      elements[locationText].add_element("HeatingEfficiency")
      elements[locationText].add_element("CoolingEfficiency")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications/HeatingEfficiency"
      elements[locationText].attributes["isCop"] = "true"
      elements[locationText].attributes["value"] = "2"

      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Specifications/CoolingEfficiency"
      elements[locationText].attributes["isCop"] = "true"
      elements[locationText].attributes["value"] = "2"      
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[locationText].add_element("Temperature")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature"
      elements[locationText].add_element("CutoffType")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature/CutoffType"
      elements[locationText].attributes["code"] = "2"
      elements[locationText].attributes["value"] = "0"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature"
      elements[locationText].add_element("RatingType")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature/RatingType"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].attributes["value"] = "-5.0"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump"
      elements[locationText].add_element("CoolingParameters")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters"
      elements[locationText].attributes["sensibleHeatRatio"] = "0.76"
      elements[locationText].attributes["openableWindowArea"] = "20"
      
      elements[locationText].add_element("FansAndPump")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters/FansAndPump"
      # Do we need to set this? what should we set it to? 
      elements[locationText].attributes["flowRate"] = "700"
      
      elements[locationText].add_element("Mode")
      elements[locationText].add_element("Power")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters/FansAndPump/Mode"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/CoolingParameters/FansAndPump/Power"
      elements[locationText].attributes["isCalculated"] = "true"
      
   elsif ( sysType2Name == "WaterHeatPump" )
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[locationText].add_element("EquipmentInformation")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/EquipmentInformation"
      elements[locationText].attributes["canCsaC448"] = "false"
      
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[locationText].add_element("Equipment")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Equipment"
      elements[locationText].attributes["crankcaseHeater"] = "0"
      elements[locationText].add_element("Function")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Equipment/Function"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[locationText].add_element("Specifications")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications"
      elements[locationText].add_element("OutputCapacity")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications/OutputCapacity"
      elements[locationText].attributes["code"] = "2"
      elements[locationText].attributes["value"] = "21.5"
      elements[locationText].attributes["uiUnits"] = "kW"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications"
      elements[locationText].add_element("HeatingEfficiency")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Specifications/HeatingEfficiency"
      elements[locationText].attributes["isCop"] = "true"
      elements[locationText].attributes["value"] = "3"

      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[locationText].add_element("Temperature")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature"
      elements[locationText].add_element("CutOffType")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature/CutOffType"
      elements[locationText].attributes["code"] = "3"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature"
      elements[locationText].add_element("RatingType")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/Temperature/RatingType"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].attributes["value"] = "8.3"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump"
      elements[locationText].add_element("SourceTemperature")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/SourceTemperature"
      elements[locationText].attributes["depth"] = "1.5"
      elements[locationText].add_element("Use")
      locationText = "HouseFile/House/HeatingCooling/Type2/WaterHeatPump/SourceTemperature/Use"
      elements[locationText].attributes["code"] = "2"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
   elsif ( sysType2Name == "GroundHeatPump" )
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[locationText].add_element("EquipmentInformation")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/EquipmentInformation"
      elements[locationText].attributes["canCsaC448"] = "false"
      
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[locationText].add_element("Equipment")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Equipment"
      elements[locationText].attributes["crankcaseHeater"] = "0"
      elements[locationText].add_element("Function")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Equipment/Function"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[locationText].add_element("Specifications")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications"
      elements[locationText].add_element("OutputCapacity")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications/OutputCapacity"
      elements[locationText].attributes["code"] = "2"
      elements[locationText].attributes["value"] = "21.5"
      elements[locationText].attributes["uiUnits"] = "kW"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications"
      elements[locationText].add_element("HeatingEfficiency")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications/HeatingEfficiency"
      elements[locationText].attributes["isCop"] = "true"
      elements[locationText].attributes["value"] = "3"

      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[locationText].add_element("Temperature")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature"
      elements[locationText].add_element("CutOffType")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature/CutOffType"
      elements[locationText].attributes["code"] = "3"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature"
      elements[locationText].add_element("RatingType")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature/RatingType"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].attributes["value"] = "8.3"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
      elements[locationText].add_element("SourceTemperature")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/SourceTemperature"
      elements[locationText].attributes["depth"] = "1.5"
      elements[locationText].add_element("Use")
      locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/SourceTemperature/Use"
      elements[locationText].attributes["code"] = "2"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
   elsif ( sysType2Name == "AirConditioning" )
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[locationText].add_element("EquipmentInformation")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/EquipmentInformation"
      elements[locationText].attributes["energystar"] = "false"
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[locationText].add_element("Equipment")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Equipment"
      elements[locationText].attributes["crankcaseHeater"] = "60"
      elements[locationText].add_element("CentralType")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Equipment/CentralType"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[locationText].add_element("Specifications")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications"
      elements[locationText].attributes["sizingFactor"] = "1"
      elements[locationText].add_element("RatedCapacity")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications/RatedCapacity"
      elements[locationText].attributes["code"] = "2"
      elements[locationText].attributes["value"] = "0"
      elements[locationText].attributes["uiUnits"] = "kW"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications"
      elements[locationText].add_element("Efficiency")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/Specifications/Efficiency"
      elements[locationText].attributes["isCop"] = "true"
      elements[locationText].attributes["value"] = "3"

      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning"
      elements[locationText].add_element("CoolingParameters")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters"
      elements[locationText].attributes["sensibleHeatRatio"] = "0.76"
      elements[locationText].attributes["openableWindowArea"] = "0"
      elements[locationText].add_element("FansAndPump")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump"
      elements[locationText].attributes["flowRate"] = "0"
      elements[locationText].add_element("Mode")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump/Mode"
      elements[locationText].attributes["code"] = "1"
      elements[locationText].add_element("English")
      elements[locationText].add_element("French")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump"
      elements[locationText].add_element("Power")
      locationText = "HouseFile/House/HeatingCooling/Type2/AirConditioning/CoolingParameters/FansAndPump/Power"
      elements[locationText].attributes["isCalculated"] = "true"
   end
end   # createH2KSysType2

# =========================================================================================
#  Add missing DWHR section to DHW 
# =========================================================================================
def addMissingDWHR(elements)
   locationText = "HouseFile/House/Components/HotWater/Primary"
   elements[locationText].add_element("DrainWaterHeatRecovery")
   locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery"
   elements[locationText].attributes["showerLength"] = "5.0"
   elements[locationText].attributes["dailyShowers"] = "2.0"
   elements[locationText].attributes["preheatShowerTank"] = "false"
   elements[locationText].attributes["effectivenessAt9.5"] = "50.0"
   elements[locationText].add_element("Efficiency", {"code"=>"2"})
   elements[locationText].add_element("EquipmentInformation")
   elements[locationText].add_element("ShowerTemperature", {"code"=>"1"})
   elements[locationText].add_element("ShowerHead", {"code"=>"0"})
   locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/EquipmentInformation"
   elements[locationText].add_element("Manufacturer")
   elements[locationText].add_element("Model")
   locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/ShowerTemperature"
   elements[locationText].add_element("English")
   elements[locationText].add_element("French")
   locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/ShowerHead"
   elements[locationText].add_element("English")
   elements[locationText].add_element("French")
end

# =========================================================================================
# Procedure to run HOT2000
# =========================================================================================
def runsims( direction )

   $RotationAngle = $angles[direction]

   # Save rotation angle for reporting
   $gRotationAngle = $RotationAngle
  
   Dir.chdir( $run_path )
   debug_out ("\n Changed path to path: #{Dir.getwd()} for simulation.\n") 
   
   # Rotate the model, if necessary:
   #   Need to determine how to do this in HOT2000. The OnRotate() function in HOT2000 *interface*
   #   is not accessible from the CLI version of HOT2000 and hasn't been well tested.
   
   runThis = "HOT2000.exe"
   optionSwitch = "-inp"
   fileToLoad = "..\\" + $h2kFileName
   
   # maxRunTime in seconds (decimal value accepted) set to nil or 0 means no timeout checking!
   # JTB: Typical H2K run on my desktop takes under 4 seconds but timeout values in the range
   #      of 4-10 don't seem to work (something to do with timing of GenOpt's timing on 
   #      re-trying a run)! 
   maxRunTime = 30
   startRun = Time.now
   endRun = 0 
   # AF: Extra counters to count how many times we've tried HOT2000.
   keepTrying = true 
   tries = 0
   # This loop actually calls hot2000!
   pid = 0 
   begin      
      Timeout.timeout(maxRunTime) do        # time out after maxRunTime seconds!
         
         while keepTrying do                # within that loop, keep trying for up to 10 times
   
           # Run HOT2000! 
           pid = Process.spawn( runThis,optionSwitch, fileToLoad) 
           stream_out ("\n Invoking HOT2000 (PID #{pid})...")
           Process.wait pid
           status= $?.exitstatus      
           stream_out("\n Hot2000 (PID: #{pid}) finished with exit status #{status} \n")
           
           if status == 0 
              endRun = Time.now
              $runH2KTime = endRun - startRun  
              stream_out( "\n The run was successful (#{$runH2KTime.round(2).to_s} seconds)!\n" )
              keepTrying = false           # Successful run - don't try agian 
           elsif  tries < 0               # Unsuccessful run - try again for up to 10 times     
              tries = tries + 1      
           else
              # GenOpt picks up "Fatal Error!" via an entry in the *.GO-config file.
              fatalerror( " Fatal Error! HOT2000 return code: #{$?}\n" )
              keepTrying = false   # Give up.
           end
           
           # Forceably kill process if needed
           begin 
             Process.kill('KILL', pid)
           rescue 
           end 
           sleep(1)
           
         end 
      end
   rescue
      endRun = Time.now
      $runH2KTime = endRun - startRun  
      stream_out( "\n\n Timeout on H2K call after #{maxRunTime} seconds.\n" )
      sleep(1)
   end

   $NumTries = tries + 1 
   
   Dir.chdir( $gMasterPath )
   debug_out ("\n Moved to path: #{Dir.getwd()}\n") 
   
   # Save output files
   $OutputFolder = "sim-output"
   if ( ! Dir.exist?($OutputFolder) )
      if ( ! system("mkdir #{$OutputFolder}") )
         fatalerror( " Fatal Error! Could not create #{$OutputFolder} below #{$gMasterPath}!\n MKDir Return code: #{$?}\n" )
      end
   else
      if ( File.exist?("#{$OutputFolder}\\Browse.rpt") )
         if ( ! system("del #{$OutputFolder}\\Browse.rpt") )    # Delete existing Browse.Rpt
            fatalerror(" Fatal Error! Could not delete existing Browse.rpt file in #{$OutputFolder}!\n Del Return code: #{$?}\n" )
         end
      end
   end
   
   # Copy simulation results to sim-output folder in master (for ERS number)
   # Note that most of the output is contained in the HOT2000 file in XML!
   if ( Dir.exist?("sim-output") )
      if ( ! system("copy /Y #{$run_path}\\Browse.rpt .\\sim-output\\") )
         fatalerror(" Fatal Error! Could not copy Browse.rpt to #{$OutputFolder}!\n Copy return code: #{$?}\n" )
      else
         stream_out( "\n\n Copied output file Browse.rpt to #{$gMasterPath}\\sim-output.\n" )
      end
   end

end   # runsims

# =========================================================================================
# Post-process results
# =========================================================================================
def postprocess( scaleData )
  
   # Load all XML elements from HOT2000 file (post-run results now available)
   h2kPostElements = get_elements_from_filename( $gWorkingModelFile )

   if ( $gCustomCostAdjustment ) 
      $gRegionalCostAdj = $gCostAdjustmentFactor
   else
      $gRegionalCostAdj = $RegionalCostFactors[$Locale]
   end
   
   # Some data needs to be extracted from Browse.rpt ASCII file because it's not in H2K XML file!
   fBrowseRpt = File.new("#{$OutputFolder}\\Browse.Rpt", "r") 
   if fBrowseRpt == nil then
      fatalerror("Could not read Browse.Rpt.\n")
   end

   bReadFuelCosts = false
   if ( $versionMajor_H2K.to_i >= 11 && $versionMinor_H2K.to_i >= 1 && $versionBuild_H2K.to_i >= 82 )
      bReadFuelCosts = true
   else
      # H2K V11.1 b82 contains "ActualFuelCosts" (previous version did not)!
      locationText = "HouseFile/AllResults/Results/Annual/ActualFuelCosts"
      $gAvgCost_Electr += h2kPostElements[locationText].attributes["electrical"].to_f * scaleData
      $gAvgCost_NatGas += h2kPostElements[locationText].attributes["naturalGas"].to_f * scaleData
      $gAvgCost_Propane += h2kPostElements[locationText].attributes["propane"].to_f * scaleData
      $gAvgCost_Oil += h2kPostElements[locationText].attributes["oil"].to_f * scaleData
      $gAvgCost_Wood += h2kPostElements[locationText].attributes["wood"].to_f * scaleData
      $gAvgCost_Total += ($gAvgCost_Electr + $gAvgCost_NatGas + $gAvgCost_Propane + $gAvgCost_Oil + $gAvgCost_Wood) * scaleData
   end
   
   if ( $gChoices["Opt-H2K-PV"] != "NA" )
      bReadPV = true
      bUseNextPVLine = false
      bMonthlyPVData = false
      mthlyPVPower = [ 0,0,0,0,0,0,0,0,0,0,0,0 ]
      mthlyPVEnergy = [ 0,0,0,0,0,0,0,0,0,0,0,0 ]
      iMonth = 0
   end
   
   while !fBrowseRpt.eof? do
      lineIn = fBrowseRpt.readline
      lineIn.strip!                 # Remove leading and trailing whitespace
      if ( lineIn !~ /^\s*$/ )   # Not an empty line!
         if ( lineIn =~ /^Energuide Rating \(not rounded\) =/ )
            lineIn.sub!(/Energuide Rating \(not rounded\) =/, '')
            lineIn.strip!
            $gERSNum = lineIn.to_f     # Use * scaleData?
         elsif ( bReadFuelCosts && lineIn =~ /^\$/ )
            valuesArr = lineIn.split()   # Uses spaces by default to split-up line
            $gAvgCost_Electr += valuesArr[1].to_f * scaleData
            $gAvgCost_NatGas += valuesArr[2].to_f * scaleData
            $gAvgCost_Oil += valuesArr[3].to_f * scaleData
            $gAvgCost_Propane += valuesArr[4].to_f * scaleData
            $gAvgCost_Wood += valuesArr[5].to_f * scaleData    # Includes pellets until separated out
            $gAvgCost_Total += valuesArr[6].to_f * scaleData
         elsif ( ( bReadPV && lineIn =~ /PHOTOVOLTAIC SYSTEM MONTHLY PERFORMANCE/ ) || ( bReadPV && bUseNextPVLine ) )
            bUseNextPVLine = true
            if ( bMonthlyPVData || lineIn =~ /^Jan/ )
               valuesArr = lineIn.split()   # Uses spaces by default to split-up line
               mthlyPVPower[iMonth] = valuesArr[4].to_f   # Watts
               mthlyPVEnergy[iMonth] = valuesArr[5].to_f  # kWh
               iMonth += 1
               lineIn =~ /^Dec/ ? break : bMonthlyPVData = true
            else
               bMonthlyPVData = false
            end
         end
      end
   end
   fBrowseRpt.close()

   # ==================== New parsing : Get results from all h2k calcs. 
   
   parseDebug = false
   
   h2kPostElements["HouseFile/AllResults"].elements.each do |element|
   
      houseCode =  element.attributes["houseCode"]
   
      if (houseCode == nil) 
	  
	    houseCode = "General"
	  
	  end 
   
      #puts "Code:" << houseCode.to_s
	
	  # ENERGY CONSUMPTION (Annual)
      $gResults[houseCode]["avgEnergyTotalGJ"]        = element.elements[".//Annual/Consumption"].attributes["total"].to_f * scaleData
	  $gResults[houseCode]["avgEnergyHeatingGJ"]      = element.elements[".//Annual/Consumption/SpaceHeating"].attributes["total"].to_f * scaleData
	  $gResults[houseCode]["avgEnergyCoolingGJ"]      = element.elements[".//Annual/Consumption/Electrical"].attributes["spaceCooling"].to_f * scaleData
	  $gResults[houseCode]["avgEnergyVentilationGJ"]  = element.elements[".//Annual/Consumption/Electrical"].attributes["ventilation"].to_f * scaleData
	  $gResults[houseCode]["avgEnergyEquipmentGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["baseload"].to_f * scaleData
	  $gResults[houseCode]["avgEnergyWaterHeatingGJ"] = element.elements[".//Annual/Consumption/HotWater"].attributes["total"].to_f * scaleData
	  
	  # Design loads, other data 
	  $gResults[houseCode]["avgOthPeakHeatingLoadW"] = element.elements[".//Other"].attributes["designHeatLossRate"].to_f * scaleData
	  
	      
	  $gResults[houseCode]["avgOthPeakCoolingLoadW"] = element.elements[".//Other"].attributes["designCoolLossRate"].to_f * scaleData
	     # ( what the heck is a 'cool loss rate' ?!? should be heat gain rate...)
		
      $gResults[houseCode]["avgOthSeasonalHeatEff"] = element.elements[".//Other"].attributes["seasonalHeatEfficiency"].to_f * scaleData
	  $gResults[houseCode]["avgVntAirChangeRateNatural"] = element.elements[".//Annual/AirChangeRate"].attributes["natural"].to_f * scaleData
	  $gResults[houseCode]["avgVntAirChangeRateTotal"] = element.elements[".//Annual/AirChangeRate"].attributes["total"].to_f * scaleData
	  $gResults[houseCode]["avgSolarGainsUtilized"] = element.elements[".//Annual/UtilizedSolarGains"].attributes["value"].to_f * scaleData
	  $gResults[houseCode]["avgVntMinAirChangeRate"] = element.elements[".//Other/Ventilation"].attributes["minimumAirChangeRate"].to_f * scaleData
	  $gResults[houseCode]["avgFuelCostsElec$"]    = element.elements[".//Annual/ActualFuelCosts"].attributes["electrical"].to_f * scaleData
	  $gResults[houseCode]["avgFuelCostsNatGas$"]  = element.elements[".//Annual/ActualFuelCosts"].attributes["naturalGas"].to_f * scaleData
	  $gResults[houseCode]["avgFuelCostsOil$"]     = element.elements[".//Annual/ActualFuelCosts"].attributes["oil"].to_f * scaleData
      $gResults[houseCode]["avgFuelCostsPropane$"] = element.elements[".//Annual/ActualFuelCosts"].attributes["propane"].to_f * scaleData
      $gResults[houseCode]["avgFuelCostsWood$"]    = element.elements[".//Annual/ActualFuelCosts"].attributes["wood"].to_f * scaleData

	  $gResults[houseCode]["avgFueluseElecGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["total"].to_f * scaleData
	  $gResults[houseCode]["avgFueluseNatGasGJ"]  = element.elements[".//Annual/Consumption/NaturalGas"].attributes["total"].to_f * scaleData
	  $gResults[houseCode]["avgFueluseOilGJ"]     = element.elements[".//Annual/Consumption/Oil"].attributes["total"].to_f * scaleData
      $gResults[houseCode]["avgFuelusePropaneGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["total"].to_f * scaleData
      $gResults[houseCode]["avgFueluseWoodGJ"]    = element.elements[".//Annual/Consumption/Wood"].attributes["total"].to_f * scaleData	  
	  
	  
	   $gResults[houseCode]["avgFueluseEleckWh"]   = $gResults[houseCode]["avgFueluseElecGJ"] * 277.77777778
	  
	   $gResults[houseCode]["avgFueluseNatGasM3"]  = $gResults[houseCode]["avgFueluseNatGasGJ"] * 26.853 
	   
	   $gResults[houseCode]["avgFueluseOilL"]      = $gResults[houseCode]["avgFueluseOilGJ"]  * 1000
	   
	   
       $gResults[houseCode]["avgFuelusePropaneL"]  = $gResults[houseCode]["avgFuelusePropaneGJ"] / 25.23 * 1000 
	   
       #$gResults[houseCode]["avgFueluseWoodGJ"]    = "nil" #$gResults[houseCode]["avgFueluseWoodGJ"]   
	   
	   
	   
	   $gResults[houseCode]["avgFuelCostsTotal$"] =  $gResults[houseCode]["avgFuelCostsElec$"]    +
	                                                 $gResults[houseCode]["avgFuelCostsNatGas$"]   +
	                                                 $gResults[houseCode]["avgFuelCostsOil$"]     +
	                                                 $gResults[houseCode]["avgFuelCostsPropane$"]  +
	                                                 $gResults[houseCode]["avgFuelCostsWood$"] 
	   
	   
	  
	  diff =  $gResults[houseCode]["avgFueluseElecGJ"].to_f + $gResults[houseCode]["avgFueluseNatGasGJ"].to_f  -  $gResults[houseCode]["avgEnergyTotalGJ"].to_f
	  $gResults[houseCode]["zH2K-debug-Energy"] = diff.to_f * scaleData	  
	  
	  
	  
	  #  $gResults[houseCode]["<var>"] = element.elements[".//Annual/Consumption/<name>"].attributes["<TAG>"]
	  
	  
	  #puts ">>> Tot " << $gOptions[houseCode]["avgEnergyTotal"].to_s << " GJ"
	  #puts ">>> SH  " << $gOptions[houseCode]["avgEnergyHeatingGJ"].to_s << " GJ"
	  
   end 
   
   if  ( parseDebug ) 
     $gResults.each do |houseCode, data|
       puts ">Results for " << houseCode.to_s
	   data.each do | var, value |
         puts "  - " << var.to_s << " : " << value.to_s 
       end
      end 
	end 

   # Maybe the desired mode wasn't found? if not, reset it to "General"	
	 
   #====================================
   
   if ( ! defined? $gResults[$outputHCode] ) 
		$outputHCode = "General"
   end 
      

   
   
   #$gAvgCost_Pellet = 0    # H2K doesn't identify pellets in output (only inputs)!

   
   # PV Data...
   $PVArrayCost = 0.0
   $PVArraySized = 0.0
   $PVsize = $gChoices["Opt-StandoffPV"]  # Input examples: "SizedPV", "SizedPV|3kW", or "NoPV"
   $PVInt = $gChoices["Opt-H2K-PV"]   # Input examples: "MonoSi-50m2", "NA"
   $PVcapacity = $PVsize
   $PVcapacity.gsub(/[a-zA-Z:\s'\|]/, '')
   if ( $PVcapacity == "" || $PVcapacity == "NoPV" && $PVInt == "NA" ) 
      $PVcapacity = 0.0
   end
   if ( $PVInt != "NA" )
      $PVUnitCost = $gOptions["Opt-H2K-PV"]["options"][ $gChoices["Opt-H2K-PV"] ]["cost"].to_f
      $PVUnitOutput = 0.0  # Calculated in H2K
   elsif ( $PVsize != "NoPV" )
      $PVUnitCost = $gOptions["Opt-StandoffPV"]["options"]["SizedPV"]["cost"].to_f
      $PVUnitOutput = $gOptions["Opt-StandoffPV"]["options"]["SizedPV"]["ext-result"]["production-elec-perKW"].to_f
   end
   
   if ( $PVsize !~ /SizedPV/ )
      # NoPV
      $gPVProduction = 0.0
      $PVArrayCost = 0.0
   else
      # Size PV according to user specification, to max, or to size required to reach Net-Zero. 
      # User-specified PV size (format is 'SizedPV|XkW', PV will be sized to X kW'.
      if ( $gExtraDataSpecd["Opt-StandoffPV"] =~ /kW/ )
         $PVArraySized = $gExtraDataSpecd["Opt-StandoffPV"].to_f  # ignores "kW" in string
         $PVArrayCost = $PVUnitCost * $PVArraySized 
         $gPVProduction = -1.0 * $PVUnitOutput * $PVArraySized
         $PVsize = "spec'd SizedPV | $PVArraySized kW"
      else
         # USER Hasn't specified PV size, Size PV to attempt to get to net-zero. 
         # First, get the home's total energy requirement. 
         $prePVEnergy = $gAvgEnergy_Total
         if ( $prePVEnergy > 0 )
            # This should always be the case!
            $PVArraySized = $prePVEnergy / $PVUnitOutput    # KW Capacity
            $PVmultiplier = 1.0 
            if ( $PVArraySized > 14.0 ) 
               $PVmultiplier = 2.0
            end
            $PVArrayCost  = $PVArraySized * $PVUnitCost * $PVmultiplier
            $PVsize = " scaled: " + "#{$PVArraySized.round(1)} kW"
            $gPVProduction = -1.0 * $PVUnitOutput * $PVArraySized
         else
            # House is already energy positive, no PV needed. Shouldn't happen!
            $PVsize = "0.0 kW"
            $PVArrayCost  = 0.0
         end
         # Degbug: How big is the sized array?
         debug_out ("\n PV array is #{$PVsize}  ...\n")
      end
   end
   $gChoices["Opt-StandoffPV"] = $PVsize
   $gOptions["Opt-StandoffPV"]["options"][$PVsize]["cost"] = $PVArrayCost

   
   
   # THIS ISN"T WORKING YET  
   # PV energy from HOT2000 model run (GJ) or estimate from option file PV data
   if ( $PVInt != "NA" )
      locationText = "HouseFile/AllResults/Results/Monthly/Load/PhotoVoltaicUtilized"
      monthArr = [ "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december" ]
      monthArr.each do |mth|
         $gEnergyPV += h2kPostElements[locationText].attributes[mth].to_f  # GJ
      end
      totalGJperkW = 0.0
      mthlyPVPower.each_index do |iMth|
         if ( mthlyPVPower[iMth] > 0 )
            totalGJperkW += mthlyPVEnergy[iMth] * W_PER_KW / ( mthlyPVPower[iMth] * KWH_PER_GJ )
         else
            wthCity = h2kPostElements["HouseFile/ProgramInformation/Weather/Location/English"].text
            debug_out("\n H2K PV power for #{monthArr[iMth].capitalize} is 0!(Weather for #{wthCity})\n")
         end
      end
      $PVUnitOutput = totalGJperkW / 12
      $PVArraySized = $gEnergyPV / $PVUnitOutput   # kW 
      $PVcapacity = $PVArraySized                  # kW used only in substitutePL-output.txt!
      $PVsize = " H2K: " + "#{$PVArraySized.round(1)} kW"
      $PVmultiplier = 1.0 
      if ( $PVArraySized > 14.0 ) 
         $PVmultiplier = 2.0
      end
      $PVArrayCost  = $PVArraySized * $PVUnitCost * $PVmultiplier
      
      debug_out ("\n PV array is #{$PVsize}  ...\n")
   else
      # PV energy comes from an estimate using Opt-StandoffPV specification. Uses options file
      # number for GJ/kW PV energy production for location and roof pitch.
      $gEnergyPV = $gPVProduction * -1.0 
   end
   
   # PV energy shouldn't be cumulative for orientation runs (GJ * 277.778 -> kWh)!!
   $gAvgPVOutput_kWh   = -1.0 * $gEnergyPV * KWH_PER_GJ * scaleData
   
   $gAvgPVRevenue = $gEnergyPV * KWH_PER_GJ * $PVTarrifDollarsPerkWh

   stream_out  "\n Peak Heating Load (W): #{$gResults[$outputHCode]['avgOthPeakHeatingLoadW'].round(1)}  \n"
   stream_out  " Peak Cooling Load (W): #{$gResults[$outputHCode]['avgOthPeakCoolingLoadW'].round(1)}  \n"

   $check = $gResults[$outputHCode]['avgEnergyHeatingGJ'].to_f + 
            $gResults[$outputHCode]['avgEnergyWaterHeatingGJ'].to_f + 
		    $gResults[$outputHCode]['avgEnergyVentilationGJ'].to_f + 
	 	    $gResults[$outputHCode]['avgEnergyCoolingGJ'].to_f + 
		    $gResults[$outputHCode]['avgEnergyEquipmentGJ'].to_f 
   
   stream_out("\n Energy Consumption: \n\n")
   stream_out ( "  #{$gResults[$outputHCode]['avgEnergyHeatingGJ'].round(1)} ( Space Heating, GJ ) \n")
   stream_out ( "  #{$gResults[$outputHCode]['avgEnergyWaterHeatingGJ'].round(1)} ( Hot Water, GJ ) \n")
   stream_out ( "  #{$gResults[$outputHCode]['avgEnergyVentilationGJ'].round(1)} ( Ventilator Electrical, GJ ) \n")
   stream_out ( "  #{$gResults[$outputHCode]['avgEnergyCoolingGJ'].round(1)} ( Space Cooling, GJ ) \n")
   stream_out ( "  #{$gResults[$outputHCode]['avgEnergyEquipmentGJ'].round(1)} ( Appliances + Lights + Plugs + outdoor, GJ ) \n")
   stream_out ( " --------------------------------------------------------\n")
   stream_out ( "  #{$gResults[$outputHCode]['avgEnergyTotalGJ'].round(1)} ( H2K Total energy use GJ ) \n")
   
    if ( parseDebug )
		stream_out ("       ( check: should = #{$check.round(1)} ?  ) \n ") 
    end 
	
   
   
   stream_out("\n\n Energy Cost (not including credit for PV, direction #{$gRotationAngle} ): \n\n")
   stream_out("  + \$ #{$gResults[$outputHCode]['avgFuelCostsElec$'].round(2)}  (Electricity)\n")
   stream_out("  + \$ #{$gResults[$outputHCode]['avgFuelCostsNatGas$'].round(2)} (Natural Gas)\n")
   stream_out("  + \$ #{$gResults[$outputHCode]['avgFuelCostsOil$'].round(2)}  (Oil)\n")
   stream_out("  + \$ #{$gResults[$outputHCode]['avgFuelCostsPropane$'].round(2)}  (Propane)\n")
   stream_out("  + \$ #{$gResults[$outputHCode]['avgFuelCostsWood$'].round(2)}  (Wood)\n")
   #stream_out("  + \$ #{$gResults[$outputHCode][''].round(2)}  #{$gAvgCost_Pellet.round(2)} (Pellet)\n")
   stream_out ( " --------------------------------------------------------\n")
   stream_out ( "    \$ #{$gResults[$outputHCode]['avgFuelCostsTotal$'].round(2)}  (All utilities).\n")
   stream_out ( "\n")
   stream_out ( "  - \$ #{$gAvgPVRevenue.round(2)} (PV revenue, #{($gAvgPVRevenue * 1e06 / 3600).round} kWh at \$ #{$PVTarrifDollarsPerkWh} / kWh)\n")
   stream_out ( " --------------------------------------------------------\n")
   stream_out ( "    \$ #{$gResults[$outputHCode]['avgFuelCostsTotal$'].round(2) - $gAvgPVRevenue.round(2)} (Net utility costs).\n")
   stream_out ( "\n\n")
   
   stream_out("\n\n Energy Use (not including credit for PV, direction #{$gRotationAngle} ): \n\n")
   stream_out("  - #{$gResults[$outputHCode]['avgFueluseEleckWh'].round(0)} (Electricity, kWh)\n")         
   stream_out("  - #{$gResults[$outputHCode]['avgFueluseNatGasM3'].round(0)} (Natural Gas, m3)\n")                	
   stream_out("  - #{$gResults[$outputHCode]['avgFueluseOilL'].round(0)} (Oil, l)\n")                           	   
   #stream_out("  - #{$gEnergyWood.round(1)} (Wood, cord)\n")                               
   #stream_out("  - #{$gAvgPelletCons_tonne.round(1)} (Pellet, tonnes)\n")                  
   
   # stream_out ("> SCALE #{scaleData} \n"); 
   
   # Estimate total cost of upgrades
   $gTotalCost = 0
   
   stream_out ("\n\n Estimated costs in #{$Locale} (x #{$gRegionalCostAdj} Ottawa costs) : \n\n")

   $gChoices.sort.to_h
   for attribute in $gChoices.keys()
      choice = $gChoices[attribute]
      cost = $gOptions[attribute]["options"][choice]["cost"].to_f
      $gTotalCost += cost
      stream_out( " +  #{cost.round()} ( #{attribute} : #{choice} ) \n")
   end
   stream_out ( " - #{($gIncBaseCosts * $gRegionalCostAdj).round} (Base costs for windows)  \n")
   stream_out ( " --------------------------------------------------------\n")
   stream_out ( " =   #{($gTotalCost-$gIncBaseCosts * $gRegionalCostAdj).round} ( Total incremental cost ) \n\n")
   $gRegionalCostAdj != 0 ? val = $gTotalCost / $gRegionalCostAdj : val = 0
   stream_out ( " ( Unadjusted upgrade costs: \$ #{val} )\n\n")
   
   if ( $gERSNum > 0 )
      $tmpval = $gERSNum.round(1)
      stream_out(" ERS value: #{$tmpval}\n")
   end

end  # End of postprocess

# =========================================================================================
# Fix the paths specified in the HOT2000.ini file
# =========================================================================================
def fix_H2K_INI()
   # Adjust paths in HOT2000.ini file to match copied location
   fH2K_ini_file = File.new("#{$gMasterPath}\\H2K\\HOT2000.ini", "r") 
   if fH2K_ini_file == nil then
      fatalerror("Could not read HOT2000.ini file!\n")
   end
   linecount = 0
   lineout = ""
   while !fH2K_ini_file.eof? do
      linecount += 1
      linein = fH2K_ini_file.readline
      if ( linein =~ /_FILE/ )
         # Using $h2k_src_path to determine what to change in ini file. Regexp.escape is used
         # to properly handle the "\\" characters in the path (i=case insensitive).
         linein.sub!(/#{Regexp.escape($h2k_src_path)}/i, "#{$gMasterPath}\\H2K") 
      end
      lineout += linein
   end
   fH2K_ini_file.close

   fH2K_ini_file_OUT = File.new("#{$gMasterPath}\\H2K\\HOT2000.ini", "w") 
   if fH2K_ini_file_OUT == nil then
      fatalerror("Could not write modified HOT2000.ini file!\n")
   end
   fH2K_ini_file_OUT.write(lineout)
   fH2K_ini_file_OUT.close
end

=begin rdoc
=========================================================================================
  END OF ALL METHODS 
=========================================================================================
=end


$gChoiceOrder = Array.new

$gTest_params["verbosity"] = "quiet"
$gTest_params["logfile"]   = $gMasterPath + "\\SubstitutePL-log.txt"

$fLOG = File.new($gTest_params["logfile"], "w") 
if $fLOG == nil then
   fatalerror("Could not open #{$gTest_params["logfile"]}.\n")
end
                     
#-------------------------------------------------------------------
# Help text. Dumped if help requested, or if no arguments supplied.
#-------------------------------------------------------------------
$help_msg = "

 substitute-h2k.rb: 
 
 This script searches through a suite of model input files 
 and substitutes values from a specified input file. 
 
 use: ruby substitute-h2k.rb --options options.opt
                             --choices choices.options
                             --base_file Base model path & file name
                      
 example use for optimization work:
 
  ruby substitute-h2k.rb -c optimization-choices.choices
                         -o optimization-options.options
                         -b \\HOT2000V11_1_CLI\\MyModel.h2k
      
"

# dump help text, if no argument given
if ARGV.empty? then
  puts $help_msg
  exit()
end

=begin rdoc
Command line argument processing ------------------------------
Using Ruby's "optparse" for command line argument processing (http://ruby-doc.org/stdlib-2.2.0/libdoc/optparse/rdoc/OptionParser.html)!
=end   
$cmdlineopts = {  "verbose" => false,
                  "debug"   => false }

optparse = OptionParser.new do |opts|
  
   opts.banner = $help_msg

   opts.on("-h", "--help", "Show help message") do
      puts opts
      exit()
   end
  
   opts.on("-v", "--verbose", "Run verbosely") do 
      $cmdlineopts["verbose"] = true
      $gTest_params["verbosity"] = "verbose"
   end

   #opts.on("-", "", "") do 
   #   fatalerror("Invalid command line option specified! Do not leave spaces between \"-\" and option letter.")
   #end

   opts.on("-d", "--debug", "Run in debug mode") do
      $cmdlineopts["verbose"] = true
      $gTest_params["verbosity"] = "debug"
      $gDebug = true
   end

   opts.on("-c", "--choices FILE", "Specified choice file (mandatory)") do |c|
      $cmdlineopts["choices"] = c
      $gChoiceFile = c
      if ( !File.exist?($gChoiceFile) )
         fatalerror("Valid path to choice file must be specified with --choices (or -c) option!")
      end
   end
  
   opts.on("-o", "--options FILE", "Specified options file (mandatory)") do |o|
      $cmdlineopts["options"] = o
      $gOptionFile = o
      if ( !File.exist?($gOptionFile) )
         fatalerror("Valid path to option file must be specified with --options (or -o) option!")
      end
   end

   # This may not be required for HOT2000! ***********************************
   opts.on("-b", "--base_model FILE", "Specified base file (mandatory)") do |b|
      $cmdlineopts["base_model"] = b
      $gBaseModelFile = b
      if !$gBaseModelFile
         fatalerror("Base folder file name missing after --base_folder (or -b) option!")
      end
      if (! File.exist?($gBaseModelFile) ) 
         fatalerror("Base file does not exist - create file first!")
      end
   end
 
end

optparse.parse!    # Note: parse! strips all arguments from ARGV and parse does not

if $gDebug 
  debug_out( $cmdlineopts )
end

($h2k_src_path, $h2kFileName) = File.split( $gBaseModelFile )
$h2k_src_path.sub!(/\\User/i, '')     # Strip "User" (any case) from $h2k_src_path
$run_path = $gMasterPath + "\\H2K"

stream_out (" > substitute-h2k.rb path: #{$gMasterPath} \n")
stream_out (" >               ChoiceFile: #{$gChoiceFile} \n")
stream_out (" >               OptionFile: #{$gOptionFile} \n")
stream_out (" >               Base model: #{$gBaseModelFile} \n")
stream_out (" >               HOT2000 source folder: #{$h2k_src_path} \n")
stream_out (" >               HOT2000 run folder: #{$run_path} \n")

=begin rdoc
 Parse option file. This file defines the available choices and costs
 that substitute-h2k.rb can pick from 
=end

stream_out("\n\nReading #{$gOptionFile}...")
fOPTIONS = File.new($gOptionFile, "r") 
if fOPTIONS == nil then
   fatalerror("Could not read #{$gOptionFile}.\n")
end

$linecount = 0
$currentAttributeName =""
$AttributeOpen = 0
$ExternalAttributeOpen = 0
$ParametersOpen = 0 

$gParameters = Hash.new

# Parse the option file. 

while !fOPTIONS.eof? do

   $line = fOPTIONS.readline
   $line.strip!              # Removes leading and trailing whitespace
   $line.gsub!(/\!.*$/, '')  # Removes comments
   $line.gsub!(/\s*/, '')    # Removes mid-line white space
   $line.gsub!(/\^/, ' ')    # JTB Added Jun 30/16: Replace '^' with space (used in some option tags to indicate space between words)
   $linecount += 1

   if ( $line !~ /^\s*$/ )   # Not an empty line!
      lineTokenValue = $line.split('=')
      $token = lineTokenValue[0]
      $value = lineTokenValue[1]

      # Allow value to contain spaces when "~" character used in options file 
      #(e.g. *option:retro_GSHP:value:2 = *gshp~../hvac/heatx_v1.gshp)
      if ($value) 
         $value.gsub!(/~/, ' ')
      end

      # The file contains 'attributes that are either internal (evaluated by HOT2000)
      # or external (computed elsewhere and post-processed). 
      
      # Open up a new attribute    
      if ( $token =~ /^\*attribute:start/ )
         $AttributeOpen = 1
      end

      # Open up a new external attribute    
      if ( $token =~ /^\*ext-attribute:start/ )
         $ExternalAttributeOpen = 1
      end

      # Open up parameter block
      if ( $token =~ /^\*ext-parameters:start/ )
         $ParametersOpen = 1
      end

      # Parse parameters. 
      if ( $ParametersOpen == 1 )
         # Read parameters. Format: 
         #  *param:NAME = VALUE 
         if ( $token =~ /^\*param/ )
            $token.gsub!(/\*param:/, '')
            $gParameters[$token] = $value
         end
      end
    
      # Parse attribute contents Name/Tag/Option(s)
      if ( $AttributeOpen || $ExternalAttributeOpen ) 
         
         if ( $token =~ /^\*attribute:name/ )
         
            $currentAttributeName = $value
            if ( $ExternalAttributeOpen == 1 ) then
               $gOptions[$currentAttributeName]["type"] = "external"
            else
               $gOptions[$currentAttributeName]["type"] = "internal"
            end
         
            $gOptions[$currentAttributeName]["default"]["defined"] = 0
        
         elsif ( $token =~ /^\*attribute:tag/ )
            
            arrResult = $token.split(':')
            $TagIndex = arrResult[2]
            $gOptions[$currentAttributeName]["tags"][$TagIndex] = $value
            
         elsif ( $token =~ /^\*attribute:default/ )   # Possibly define default value. 
         
            $gOptions[$currentAttributeName]["default"]["defined"] = 1
            $gOptions[$currentAttributeName]["default"]["value"] = $value

         elsif ( $token =~ /^\*option/ )
            # Format: 
            #  *Option:NAME:MetaType:Index or 
            #  *Option[CONDITIONS]:NAME:MetaType:Index or    
            # MetaType is:
            #  - cost
            #  - value 
            #  - alias (for Dakota)
            #  - production-elec
            #  - production-sh
            #  - production-dhw
            #  - WindowParams   
            
            $breakToken = $token.split(':')
            $condition_string = ""
            
            # Check option keyword to see if it has specific conditions
            # format is *option[condition1>value1;condition2>value2 ...] 
            
            if ( $breakToken[0] =~ /\[.+\]/ )
               $condition_string = $breakToken[0]
               $condition_string.gsub!(/\*option\[/, '')
               $condition_string.gsub!(/\]/, '') 
               $condition_string.gsub!(/>/, '=') 
            else
               $condition_string = "all"
            end

            $OptionName = $breakToken[1]
            $DataType   = $breakToken[2]
            
            $ValueIndex = ""
            $CostType = ""
            
            # Assign values 
            
            if ( $DataType =~ /value/ )
               $ValueIndex = $breakToken[3]
               $gOptions[$currentAttributeName]["options"][$OptionName]["values"][$ValueIndex]["conditions"][$condition_string] = $value
            end
            
            if ( $DataType =~ /cost/ )
               $CostType = $breakToken[3]
               $gOptions[$currentAttributeName]["options"][$OptionName]["cost-type"] = $CostType
               $gOptions[$currentAttributeName]["options"][$OptionName]["cost"] = $value
            end
            
            # Window data processing for generic window definitions:
            if ( $DataType =~ /WindowParams/ )
               stream_out ("\nProcessing window data for #{$currentAttributeName} / #{$OptionName}  \n")
               $Param = $breakToken[3]
               $GenericWindowParams[$OptionName][$Param] = $value
               $GenericWindowParamsDefined = 1
            end
            
            # External entities...
            if ( $DataType =~ /production/ )
               if ( $DataType =~ /cost/ )
                  $CostType = $breakToken[3]
               end
               $gOptions[$currentAttributeName]["options"][$OptionName][$DataType]["conditions"][$condition_string] = $value
            end
            
         end   # end processing all attribute types (if-elsif block)
      
      end  #end of processing attributes
    
      # Close attribute and append contents to global options array
      if ( $token =~ /^\*attribute:end/ || $token =~ /^\*ext-attribute:end/)
         
         $AttributeOpen = 0
         
         # Store options 
         debug_out ( "========== #{$currentAttributeName} ===========\n");
         debug_out ( "Storing data for #{$currentAttributeName}: \n" );
         
         $OptHash = $gOptions[$currentAttributeName]["options"] 
         
         for $optionIndex in $OptHash.keys()
            debug_out( "    -> #{$optionIndex} \n" )
            $cost_type = $gOptions[$currentAttributeName]["options"][$optionIndex]["cost-type"]
            $cost = $gOptions[$currentAttributeName]["options"][$optionIndex]["cost"]
            $ValHash = $gOptions[$currentAttributeName]["options"][$optionIndex]["values"]
            
            for $valueIndex in $ValHash.keys()
               $CondHash = $gOptions[$currentAttributeName]["options"][$optionIndex]["values"][$valueIndex]["conditions"]
               
               for $conditions in $CondHash.keys()
                  $tag = $gOptions[$currentAttributeName]["tags"][$valueIndex]
                  $value = $gOptions[$currentAttributeName]["options"][$optionIndex]["values"][$valueIndex]["conditions"][$conditions]
                  debug_out( "           - #{$tag} -> #{$value} [valid: #{$conditions} ]   \n")
               end
               
            end

            $ExtEnergyHash = $gOptions[$currentAttributeName]["options"][$optionIndex] 
            for $ExtEnergyType in $ExtEnergyHash.keys()
               if ( $ExtEnergyType =~ /production/ )
                  $CondHash = $gOptions[$currentAttributeName]["options"][$optionIndex][$ExtEnergyType]["conditions"]
                  for $conditions in $CondHash.keys()
                     $ExtEnergyCredit = $gOptions[$currentAttributeName]["options"][$optionIndex][$ExtEnergyType]["conditions"][$conditions] 
                     debug_out ("              - credit:(#{$ExtEnergyType}) #{$ExtEnergyCredit} [valid: #{$conditions} ] \n")
                  end
               end
            end
         end
      end
      
      if ( $token =~ /\*ext-parameters:end/ )
         $ParametersOpen = 0
      end
      
   end   # Empty line check
      
end   #read next line

fOPTIONS.close
stream_out ("...done.\n")


=begin rdoc
 Parse configuration (choice) file. 
=end

stream_out("\n\nReading #{$gChoiceFile}...\n\n")
fCHOICES = File.new($gChoiceFile, "r") 
if fCHOICES == nil then
   fatalerror("Could not read #{$gChoiceFile}.\n")
end

$linecount = 0

while !fCHOICES.eof? do

   $line = fCHOICES.readline
   $line.strip!              # Removes leading and trailing whitespace
   $line.gsub!(/\!.*$/, '')  # Removes comments
   $line.gsub!(/\s*/, '')    # Removes mid-line white space
   $linecount += 1
   
   debug_out ("  Line: #{$linecount} >#{$line}<\n")
   
   if ( $line !~ /^\s*$/ )
      
      lineTokenValue = $line.split(':')
      attribute = lineTokenValue[0]
      value = lineTokenValue[1]
    
      # Parse config commands
      if ( attribute =~ /^GOconfig_/ )
         attribute.gsub!( /^GOconfig_/, '')
         if ( attribute =~ /rotate/ )
            $gRotate = value
            $gChoices["GOconfig_rotate"] = value
            stream_out ("::: #{attribute} -> #{value} \n")
            $gChoiceOrder.push("GOconfig_rotate")
         end 
         if ( attribute =~ /step/ )
            $gGOStep = value
            $gArchGOChoiceFile = 1
         end 
      else
         extradata = value
         if ( value =~ /\|/ )
            value.gsub!(/\|.*$/, '') 
            extradata.gsub!(/^.*\|/, '') 
            extradata.gsub!(/^.*\|/, '') 
         else
            extradata = ""
         end
         
         $gChoices[attribute] = value
         
         stream_out ("::: #{attribute} -> #{value} \n")
         
         # Additional data that may be used to attribute the choices. 
         $gExtraDataSpecd[attribute] = extradata
         
         # Save order of choices to make sure we apply them correctly. 
         $gChoiceOrder.push(attribute)
      end
   end
end

fCHOICES.close
stream_out ("...done.\n\n")

$gExtOptions = Hash.new(&$blk)
# Report 
$allok = true

debug_out("-----------------------------------\n")
debug_out("-----------------------------------\n")
debug_out("Parsing parameters ...\n")

$gCustomCostAdjustment = 0
$gCostAdjustmentFactor = 0

# Possibly overwrite internal parameters with user-specified parameters
$gParameters.each do |parameter, value1|
   if ( parameter =~ /CostAdjustmentFactor/  )
      $gCostAdjustmentFactor = value1
      $gCustomCostAdjustment = 1
   end
  
   if ( parameter =~ /PVTarrifDollarsPerkWh/ )
      $PVTarrifDollarsPerkWh = value1.to_f
   end
  
   if ( parameter =~ /BaseUpgradeCost/ )
      $gIncBaseCosts = value1.to_f
   end
  
   if ( parameter =~ /BaseUtilitiesCost/ )
      $gUtilityBaseCost = value1.to_f
   end
end

=begin rdoc
 Validate choices and options. 
=end
stream_out(" Validating choices and options...\n\n");  

# Search through optons and determine if they are usedin Choices file (warn if not). 
$gOptions.each do |option, ignore|
    stream_out ("> option : #{option} ?\n"); 
    if ( !$gChoices.has_key?(option)  )
      $ThisError = "\nWARNING: Option #{option} found in options file (#{$gOptionFile}) \n"
      $ThisError += "         was not specified in Choices file (#{$gChoiceFile}) \n"
      $ErrorBuffer += $ThisError
      stream_out ( $ThisError )
   
      if ( ! $gOptions[option]["default"]["defined"]  )
         $ThisError = "\nERROR: No default value for option #{option} defined in \n"
         $ThisError += "       Options file (#{$gOptionFile})\n"
         $ErrorBuffer += $ThisError
         fatalerror ( $ThisError )
      else
         # Add default value. 
         $gChoices[option] = $gOptions[option]["default"]["value"]
         # Apply them at the end. 
         $gChoiceOrder.push(option)
         
         $ThisError = "\n         Using default value (#{$gChoices[option]}) \n"
         $ErrorBuffer += $ThisError
         stream_out ( $ThisError )
      end
    end
    $ThisError = ""
end

# Search through choices and determine if they match options in the Options file (error if not). 
$gChoices.each do |attrib, choice|
   debug_out ( "\n ======================== #{attrib} ============================\n")
   debug_out ( "Choosing #{attrib} -> #{choice} \n")
    
   # Is attribute used in choices file defined in options ?
   if ( !$gOptions.has_key?(attrib) )
      $ThisError  = "\nERROR: Attribute #{attrib} appears in choice file (#{$gChoiceFile}), \n"
      $ThisError +=  "       but can't be found in options file (#{$gOptionFile})\n"
      $ErrorBuffer += $ThisError
      stream_out( $ThisError )
      $allok = false
   else
      debug_out ( "   - found $gOptions[\"#{attrib}\"] \n")
   end
  
   # Is choice in options?
   if ( ! $gOptions[attrib]["options"].has_key?(choice) )
      $allok = false
      
      if ( !$allok )
         $ThisError  = "\nERROR: Choice #{choice} (for attribute #{attrib}, defined \n"
         $ThisError +=   "       in choice file #{$gChoiceFile}), is not defined \n"
         $ThisError +=   "       in options file (#{$gOptionFile})\n"
         $ErrorBuffer += $ThisError
         stream_out( $ThisError )
      else
         debug_out ( "   - found $gOptions[\"#{attribute}\"][\"options\"][\"#{choice}\"} \n")
      end
   end
   
   if ( !$allok )
      fatalerror ( "" )
   end
end

=begin rdoc
 Process conditions. 
=end

$gChoices.each do |attrib1, choice|

   valHash = $gOptions[attrib1]["options"][choice]["values"] 
   
   if ( !valHash.empty? )
     
      for valueIndex in valHash.keys()
         condHash = $gOptions[attrib1]["options"][choice]["values"][valueIndex]["conditions"] 
     
         # Check for 'all' conditions
         $ValidConditionFound = 0
        
         if ( condHash.has_key?("all") ) 
            debug_out ("   - VALINDEX: #{valueIndex} : found valid condition: \"all\" !\n")
            $gOptions[attrib1]["options"][choice]["result"][valueIndex] = condHash["all"]
            $ValidConditionFound = 1
         else
            # Loop through hash 
            for conditions in condHash.keys()
               if (conditions !~ /else/ ) 
                  debug_out ( " >>>>> Testing |#{conditions}| <<<\n" )
                  valid_condition = 1
                  conditionArray = conditions.split(';')
                  conditionArray.each do |condition|
                     debug_out ("      #{condition} \n")
                     testArray = condition.split('=')
                     testAttribute = testArray[0]
                     testValueList = testArray[1]
                     if ( testValueList == "" )
                        testValueList = "XXXX"
                     end
                     testValueArray = testValueList.split('|')
                     thesevalsmatch = 0
                     testValueArray.each do |testValue|
                        if ( $gChoices[testAttribute] =~ /testValue/ )
                           thesevalsmatch = 1
                        end
                        debug_out ("       \##{$gChoices[testAttribute]} = #{$gChoices[testAttribute]} / #{testValue} / -> #{thesevalsmatch} \n"); 
                     end
                     if ( thesevalsmatch == 0 )
                        valid_condition = 0
                     end
                  end
                  if ( valid_condition == 1 )
                     $gOptions[attrib1]["options"][choice]["result"][valueIndex]  = condHash[conditions]
                     $ValidConditionFound = 1
                     debug_out ("   - VALINDEX: #{valueIndex} : found valid condition: \"#{conditions}\" !\n")
                  end
               end
            end
         end
         # Check if else condition exists. 
         if ( $ValidConditionFound == 0 )
            debug_out ("Looking for else!: #{condHash["else"]}<\n" )
            if ( condHash.has_key?("else") )
               $gOptions[attrib1]["options"][choice]["result"][valueIndex] = condHash["else"]
               $ValidConditionFound = 1
               debug_out ("   - VALINDEX: #{valueIndex} : found valid condition: \"else\" !\n")
            end
         end
         
         if ( $ValidConditionFound == 0 )
            $ThisError  = "\nERROR: No valid conditions were defined for #{attrib1} \n"
            $ThisError +=   "       in options file (#{$gOptionFile}). Choices must match one \n"
            $ThisError +=   "       of the following:\n"
            for conditions in condHash.keys()
               $ThisError +=   "            -> #{conditions} \n"
            end
            
            $ErrorBuffer += $ThisError
            stream_out( $ThisError )
            
            $allok = false
         else
            $allok = true
         end
      end
   end
   
   # Check conditions on external entities that are not 'value' or 'cost' ...
   extHash = $gOptions[attrib1]["options"][choice]
   
   for externalParam in extHash.keys()
      
      if ( externalParam =~ /production/ )
         
         condHash = $gOptions[attrib1]["options"][choice][externalParam]["conditions"]
         
         # Check for 'all' conditions
         $ValidConditionFound = 0
         
         if ( condHash.has_key?("all") )
            debug_out ("   - EXTPARAM: #{externalParam} : found valid condition: \"all\" ! (#{condHash["all"]})\n")
            $gOptions[attrib1]["options"][choice]["ext-result"][externalParam] = $CondHash["all"]
            $ValidConditionFound = 1
         else
            # Loop through hash 
            for conditions in condHash.keys()
               valid_condition = 1
               conditionArray = conditions.split(':')
               conditionArray.each do |condition|
                  testArray = condition.split('=')
                  testAttribute = testArray[0]
                  testValueList = testArray[1]
                  if ( testValueList == "" )
                     testValueList = "XXXX"
                  end
                  testValueArray = testValueList.split('|')
                  thesevalsmatch = 0
                  testValueArray.each do |testValue|
                     if ( $gChoices[testAttribute] =~ /testValue/ )
                        thesevalsmatch = 1
                        debug_out ("       \##{$gChoices[testAttribute]} = #{$gChoices[testAttribute]} / #{testValue} / -> #{thesevalsmatch} \n")
                     end
                     if ( thesevalsmatch == 0 )
                        valid_condition = 0
                     end
                  end
               end
               if ( valid_condition == 1 )
                  $gOptions[attrib1]["options"][choice]["ext-result"][externalParam] = condHash[conditions]
                  $ValidConditionFound = 1
                  debug_out ("   - EXTPARAM: #{externalParam} : found valid condition: \"#{conditions}\" (#{condHash[$conditions]})\n")
               end
            end
         end
         
         # Check if else condition exists. 
         if ( $ValidConditionFound == 0 )
            if ( condHash.has_key("else") )
               $gOptions[attrib1]["options"][choice]["ext-result"][externalParam] = condHash["else"]
               $ValidConditionFound = 1
               debug_out ("   - EXTPARAM: #{externalParam} : found valid condition: \"else\" ! (#{condHash["else"]})\n")
            end
         end
        
         if ( $ValidConditionFound == 0 )
            $ThisError  = "\nERROR: No valid conditions were defined for #{attrib1} \n"
            $ThisError +=   "       in options file (#{$gOptionFile}). Choices must match one \n"
            $ThisError +=   "       of the following:\n"
            for conditions in condHash.keys()
               $ThisError +=  "            -> #{conditions} \n"
            end
            
            $ErrorBuffer += $ThisError
            stream_out( $ThisError )
            
            $allok = false
         else
            $allok = true
         end
      end
   end
   
   #debug_out (" >>>>> #{$gOptions[attrib1]["options"][choice]["result"]["production-elec-perKW"]}\n"); 
  
   # This section implements the multiply-cost 
   
   if ( $allok )
      cost = $gOptions[attrib1]["options"][choice]["cost"]
      cost_type = $gOptions[attrib1]["options"][choice]["cost-type"]
      if ( defined?(cost) )
         repcost = cost
      else
         repcost = "?"
      end
      if ( !defined?(cost_type) ) 
         $cost_type = "" 
      end
      if ( !defined?(cost) ) 
         cost = "" 
      end
      debug_out ("   - found cost: \$#{cost} (#{cost_type}) \n")
   
      scaleCost = 0
   
      # Scale cost by some other parameter. 
      if ( repcost =~ /\<MULTIPLY-COST:.+/ )
         
         multiplier = cost
         
         multiplier.gsub!(/\</, '')
         multiplier.gsub!(/\>/, '')
         multiplier.gsub!(/MULTIPLY-COST:/, '')
   
         multArray = multiplier.split('*')
         baseOption = multArray[0]
         scaleFactor = multArray[1]
     
         baseChoice = $gChoices[baseOption]
         baseCost = $gOptions[baseOption]["options"][baseChoice]["cost"]
     
         compCost = baseCost.to_f * scaleFactor.to_f
   
         scaleCost = 1
         $gOptions[attrib1]["options"][choice]["cost"] = compCost.to_s
         
         cost = compCost.to_s
         if ( !defined?(cost) )
            cost = "0"
         end
         if ( !defined?(cost_type) )
            $cost_type = ""
         end
      end
   
      #cost should be rounded in debug statement
      debug_out ( "\n\nMAPPING for #{attrib1} = #{choice} (@ \$#{cost} inc. cost [#{cost_type}] ): \n")
      
      if ( scaleCost == 1 )
         #baseCost should be rounded in debug statement
         debug_out (     "  (cost computed as $ScaleFactor *  #{baseCost} [cost of #{baseChoice}])\n")
      end
      
   end
   
   # Check on value of error flag before continuing with while loop
   # (the flag may be reset in the next iteration!)
   if ( !$allok )
      break    # exit the loop - don't process rest of choices against options
   end
end   #end of do each gChoices loop

# Seems like we've found everything!

if ( !$allok )
   stream_out("\n--------------------------------------------------------------\n")
   stream_out("\nSubstitute-h2k.rb encountered the following errors:\n")
   stream_out($ErrorBuffer)
   fatalerror(" Choices in #{$gChoiceFile} do not match options in #{$gOptionFile}!")
else
   stream_out (" done.\n\n")
end

# Create a copy of HOT2000 below master
stream_out (" Creating a copying of HOT2000 executable directory below master... \n")
if ( ! Dir.exist?("#{$gMasterPath}\\H2K") )
   if ( ! system("mkdir #{$gMasterPath}\\H2K") )
      fatalerror ("Fatal Error! Could not create H2K folder below #{$gMasterPath}!\n Return error code #{$?}\n")
   end
end
if ( ! system ("xcopy #{$h2k_src_path} #{$gMasterPath}\\H2K /S /Y /Q") )
   fatalerror ("Fatal Error! Could not copy content to H2K folder below #{$gMasterPath}!\n XCopy return error code #{$?}\n")
end
fix_H2K_INI()  # Fixes the paths in HOT2000.ini file in H2K folder created above

# Create a copy of the HOT2000 file into the master folder for manipulation.
stream_out("\n\n Creating a copy of HOT2000 model file for optimization work...\n")
$gWorkingModelFile = $gMasterPath + "\\"+ $h2kFileName
# Remove any existing file first!  
if ( File.exist?($gWorkingModelFile) )
   if ( ! system ("del #{$gWorkingModelFile}") )
      fatalerror ("Fatal Error! Could not delete #{$gWorkingModelFile}!\n Del return error code #{$?}\n")
   end
end
if ( ! system ("copy #{$gBaseModelFile} #{$gWorkingModelFile}") )
   fatalerror ("Fatal Error! Could not create copy of #{$gBaseModelFile} in #{$gWorkingModelFile}!\n Copy return error code #{$?}\n")
end
stream_out(" File #{$gWorkingModelFile} created.\n\n")

# Process the working file by replacing all existing values with the values 
# specified in the attributes $gChoices and corresponding $gOptions
processFile($gWorkingModelFile)

# Orientation changes. For now, we assume the arrays must always point south.
$angles = Hash.new()
$angles[ "S" => 0 , "E" => 90, "N" => 180, "W" => 270 ]

# Orientations is an array we populate with a single member if the orientation 
# is specified, or with all of the orientations to be run if 'AVG' is spec'd.               
orientations = Array.new()
if ( $gRotate =~ /AVG/ ) 
   orientations = [ 'S', 'N', 'E', 'W' ]
else 
   orientations = [ $gRotate ] 
end

# Compute scale factor for averaging between orientations (=1 if only 
# one orientation is spec'd)
$ScaleResults = 1.0 / orientations.size()    # size returns 1 or 4

# Defined at top and zeroed here because if we are running multiple orientations, 
# we must average them as we go. Averaging is done via the $ScaleResults factor (set
# at 0.25) only when the AVG option is used.
$gAvgCost_NatGas = 0
$gAvgCost_Electr = 0
$gAvgEnergy_Total = 0
$gAvgCost_Propane = 0
$gAvgCost_Oil = 0
$gAvgCost_Wood = 0
$gAvgCost_Pellet = 0
$gAvgPVRevenue = 0
$gAvgElecCons_KWh = 0
$gAvgPVOutput_kWh = 0
$gAvgCost_Total = 0
$gAvgEnergyHeatingGJ = 0
$gAvgEnergyCoolingGJ = 0
$gAvgEnergyVentilationGJ = 0
$gAvgEnergyWaterHeatingGJ = 0
$gAvgEnergyEquipmentGJ = 0
$gAvgNGasCons_m3 = 0
$gAvgOilCons_l = 0
$gAvgPropCons_l = 0
$gAvgPelletCons_tonne = 0
$gAvgEnergyHeatingElec = 0
$gAvgEnergyVentElec = 0
$gAvgEnergyHeatingFossil = 0
$gAvgEnergyWaterHeatingElec = 0
$gAvgEnergyWaterHeatingFossil = 0

$gDirection = ""
$gEnergyHeatingElec = 0
$gEnergyVentElec = 0
$gEnergyHeatingFossil = 0
$gEnergyWaterHeatingElec = 0
$gEnergyWaterHeatingFossil = 0
$gAmtOil = 0

orientations.each do |direction|

   $gDirection = direction

   if ( ! $gSkipSims ) 
      runsims( direction )
   end
   
   # post-process simulation results from a successful run. 
   # The output data are contained in two places:
   # 1) HOT2000 run file in XML -> HouseFile/AllResults
   # 2) Browse.rpt file for the ERS number (ASCII, at "Energuide Rating (not rounded) =")
   postprocess( $ScaleResults )
   
end

$gAvgCost_Total = $gAvgCost_Electr + $gAvgCost_NatGas + $gAvgCost_Propane + $gAvgCost_Oil + $gAvgCost_Wood + $gAvgCost_Pellet

$gAvgPVRevenue = $gAvgPVOutput_kWh * $PVTarrifDollarsPerkWh

$payback = 0
$gAvgUtilCostNet = $gAvgCost_Total - $gAvgPVRevenue

$gUpgCost = $gTotalCost - $gIncBaseCosts
$gUpgSavings = $gUtilityBaseCost - $gAvgUtilCostNet


if ( $gUpgSavings.abs < 1.00 )
   # Savings are practically zero. Set payback to a very large number. 
   $payback = 10000.0
elsif ( $gTotalCost < $gIncBaseCosts )  # Case when upgrade is cheaper than base cost
   if ( $gUpgSavings > 0.0 )            # Does it also save on bills? 
      $payback = 0.0                    # No-brainer. Payback should be zero.
   else
      # It may be cheap, but it costs in the long run.
      # Set payback to a very large #.
      $payback = 100000.0
   end
else
   # Compute payback. 
   $payback = ($gTotalCost-$gIncBaseCosts)/($gUtilityBaseCost-($gAvgCost_Total-$gAvgPVRevenue))
   
   # Paybacks can be less than zero if design costs more in utility bills. Set negative paybacks to very large numbers.
   if ( $payback < 0 ) 
      $payback = 100000.0 
   end
end

# Proxy for cost of ownership 
$payback = $gAvgUtilCostNet + ($gTotalCost-$gIncBaseCosts)/25.0

sumFileSpec = $gMasterPath + "\\SubstitutePL-output.txt"
fSUMMARY = File.new(sumFileSpec, "w")
if fSUMMARY == nil then
   fatalerror("Could not create #{$gMasterPath}\\SubstitutePL-output.txt")
end
## These need to be updated. 
fSUMMARY.write( "Energy-Total-GJ   =  #{$gAvgEnergy_Total.round(1)} \n" )
fSUMMARY.write( "Util-Bill-gross   =  #{$gAvgCost_Total.round(2)}   \n" )
fSUMMARY.write( "Util-PV-revenue   =  #{$gAvgPVRevenue.round(2)}    \n" )
fSUMMARY.write( "Util-Bill-Net     =  #{($gAvgCost_Total-$gAvgPVRevenue).round(2)} \n" )
fSUMMARY.write( "Util-Bill-Elec    =  #{$gAvgCost_Electr.round(2)}  \n" )
fSUMMARY.write( "Util-Bill-Gas     =  #{$gAvgCost_NatGas.round(2)}  \n" )
fSUMMARY.write( "Util-Bill-Prop    =  #{$gAvgCost_Propane.round(2)} \n" )
fSUMMARY.write( "Util-Bill-Oil     =  #{$gAvgCost_Oil.round(2)} \n" )
fSUMMARY.write( "Util-Bill-Wood    =  #{$gAvgCost_Wood.round(2)} \n" )
fSUMMARY.write( "Util-Bill-Pellet  =  #{$gAvgCost_Pellet.round(2)} \n" )

fSUMMARY.write( "Energy-PV-kWh     =  #{$gAvgPVOutput_kWh.round(1)} \n" )
#fSUMMARY.write( "Energy-SDHW      =  #{$gEnergySDHW.round(1)} \n" )
fSUMMARY.write( "Energy-HeatingGJ  =  #{$gAvgEnergyHeatingGJ.round(1)} \n" )
fSUMMARY.write( "Energy-CoolingGJ  =  #{$gAvgEnergyCoolingGJ.round(1)} \n" )
fSUMMARY.write( "Energy-VentGJ     =  #{$gAvgEnergyVentilationGJ.round(1)} \n" )
fSUMMARY.write( "Energy-DHWGJ      =  #{$gAvgEnergyWaterHeatingGJ.round(1)} \n" )
fSUMMARY.write( "Energy-PlugGJ     =  #{$gAvgEnergyEquipmentGJ.round(1)} \n" )
fSUMMARY.write( "EnergyEleckWh     =  #{$gAvgElecCons_KWh.round(1)} \n" )
fSUMMARY.write( "EnergyGasM3       =  #{$gAvgNGasCons_m3.round(1)}  \n" )
fSUMMARY.write( "EnergyOil_l       =  #{$gAvgOilCons_l.round(1)}    \n" )
fSUMMARY.write( "EnergyPellet_t    =  #{$gAvgPelletCons_tonne.round(1)}   \n" )
fSUMMARY.write( "Upgrade-cost      =  #{($gTotalCost-$gIncBaseCosts).round(2)}\n" )
fSUMMARY.write( "SimplePaybackYrs  =  #{$payback.round(1)} \n" )

# These #s are not yet averaged for orientations!
fSUMMARY.write( "PEAK-Heating-W    =  #{$gPeakHeatingLoadW.round(1)}\n" )
fSUMMARY.write( "PEAK-Cooling-W    =  #{$gPeakCoolingLoadW.round(1)}\n" )

fSUMMARY.write( "PV-size-kW      =  #{$PVcapacity.round(1)}\n" )

fSUMMARY.write( "ERS-Value         =  #{$gERSNum.round(1)}\n" )
fSUMMARY.write( "NumTries          =  #{$NumTries.round(1)}\n" )
fSUMMARY.write( "LapsedTime        =  #{$runH2KTime.round(2)}\n" )



fSUMMARY.close() 

endProcessTime = Time.now
totalDiff = endProcessTime - startProcessTime
stream_out( "\n Total processing time: #{totalDiff.round(2)} seconds (H2K run: #{$runH2KTime.round(2)} seconds)\n\n" )

$fLOG.close()
