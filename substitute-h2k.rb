#!/usr/bin/env ruby
# substitute-h2k.rb

# This is essentially a Ruby version of the substitute-h2k.pl script -- customized for HOT2000 runs.

require 'rexml/document'
require 'optparse'

include REXML   # This allows for no "REXML::" prefix to REXML methods 

# Constants in Ruby start with upper case letters and, by convention, all upper case
CONV_R_2_RSI = 5.678263

# Global variable names  (i.e., variables that maintain their content and use (scope) 
# throughout this file). 
# Note loose convention to start global variables with a 'g'. 
# Ruby *requires* globals to start with '$'.
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

# Use lambda function  to avoid the extra lines of creating each hash nesting
$blk = lambda { |h,k| h[k] = Hash.new(&$blk) }
$gOptions = Hash.new(&$blk)
$gChoices = Hash.new(&$blk)

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

# Data from Hanscomb 2011 NBC analysis
$RegionalCostFactors = Hash.new
$RegionalCostFactors  = {  "Halifax"     =>  0.95 ,
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
                            "Inuvik"     =>  1.38 , 
                          "Alert"        =>  1.38   }

=begin rdoc
 ---------------------------------------------------------------------------
 METHODS: Routines called in this file must be defined before use in Ruby
          (can't put at bottom of listing).
 ---------------------------------------------------------------------------
=end
def fatalerror( err_msg )
# Display a fatal error and quit. -----------------------------------
  if ($gTest_params["logfile"])
    $fLOG.write("\nsubstitute-h2k.pl -> Fatal error: \n")
    $fLOG.write("#{err_msg}\n")
  end
  print "\n=========================================================\n"
  print "substitute-h2k.pl -> Fatal error: \n\n"
  print "     #{err_msg}\n"
  print "\n\n"
  print "substitute-h2k.pl -> Other Error or warning messages:\n\n"
  print "#{$ErrorBuffer}\n"
  exit() # Run stopped
end

# Optionally write text to buffer -----------------------------------
def stream_out(msg)
  if ($gTest_params["verbosity"] != "quiet")
    print msg
  end
  if ($gTest_params["logfile"])
    $fLOG.write(msg)
  end
end

# Write debug output ------------------------------------------------
def debug_out(debmsg)
  if $gDebug 
    puts debmsg
  end
  if ($gTest_params["logfile"])
    $fLOG.write(debmsg)
  end
end

# Returns XML elements of HOT2000 file.
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

# Search through the HOT2000 working file (copy of input file specified on command line) 
# and change values for settings defined in choice/options files. 
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

   # Will contain XML elements for fuel cost file, if pt-Location is processed! 
   # Initialized here outside of Opt-Locations check to make scope broader
   h2kFuelElements = nil

   # H2K version numbers can be used to determine availability of data in the H2K file.
   # Made global so available outide of this subroutine definition
   locationText = "HouseFile/Application/Version"
   $versionMajor_H2K = h2kElements[locationText].attributes["major"]
   $versionMinor_H2K = h2kElements[locationText].attributes["minor"]
   $versionBuild_H2K = h2kElements[locationText].attributes["build"]

   windowFacingH2K = { "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8 }
   
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
                  # Match Client Street address province ID to avoid H2K dialog!
                  locationText = "HouseFile/ProgramInformation/Client/StreetAddress/Province"
                  provArr = [ "BC", "AB", "SK", "MB", "ON", "QC", "NB", "NS", "PE", "NL", "YT", "NT", "NU" ]
                  h2kElements[locationText].attributes["code"] = provArr[value.to_i - 1]
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
               # HOT2000 Fuel costing data selections
               if ( tag =~ /OPT-LibraryFile/ && value != "NA" )
                  # Fuel Cost file to use for HOT2000 run
                  locationText = "HouseFile/FuelCosts"
                  # Check on existence of H2K weather file
                  h2kWthFile = $run_path + "\\StdLibs" + "\\" + value
                  if ( !File.exist?(h2kWthFile) )
                     fatalerror("Fuel cost file #{value} not found in #{$run_path + "\\StdLibs" + "\\"}!")
                  else
                     h2kElements[locationText].attributes["library"] = value
                     # Open weather file and read elements to use below. This assumes that this tag
                     # always comes before the remainderof the weather location tags below!!
                     h2kFuelElements = get_elements_from_filename(h2kWthFile)
                  end
               elsif ( tag =~ /OPT-ElecName/ && value != "NA" )
                  locationText = "HouseFile/FuelCosts/Electricity/Fuel/Label"
                  h2kElements[locationText].text = value
               elsif ( tag =~ /OPT-ElecID/ && value != "NA" )
                  locationText = "HouseFile/FuelCosts/Electricity/Fuel"
                  h2kElements[locationText].attributes["id"] = value
                  # Set using rate blocks for this id from library file!
                  locationFuelText = "FuelCosts/Electricity/Fuel"
                  h2kFuelElements.each(locationFuelText) do |element| 
                     if h2kFuelElements[locationFuelText].attributes["id"] == value
                        locationText = "HouseFile/FuelCosts/Electricity/Fuel/Units"
                        h2kElements[locationText].attributes["code"] = h2kFuelElements[locationFuelText][5].attributes["code"]
                        locationText = "HouseFile/FuelCosts/Electricity/Fuel/Minimum"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][7].attributes["units"]
                        h2kElements[locationText].attributes["charge"] = h2kFuelElements[locationFuelText][7].attributes["charge"]
                        locationText = "HouseFile/FuelCosts/Electricity/Fuel/RateBlocks/Block1"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][1].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][1].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Electricity/Fuel/RateBlocks/Block2"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][3].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][3].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Electricity/Fuel/RateBlocks/Block3"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][5].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][5].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Electricity/Fuel/RateBlocks/Block4"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][7].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][7].attributes["costPerUnit"]
                     end
                  end
               elsif ( tag =~ /OPT-GasName/ && value != "NA" )
                  locationText = "HouseFile/FuelCosts/NaturalGas/Fuel/Label"
                  h2kElements[locationText].text = value
               elsif ( tag =~ /OPT-GasID/ && value != "NA" )
                  locationText = "HouseFile/FuelCosts/NaturalGas/Fuel"
                  h2kElements[locationText].attributes["id"] = value
                  # Set using rate blocks for this id from library file!
                  locationFuelText = "FuelCosts/NaturalGas/Fuel"
                  h2kFuelElements.each(locationFuelText) do |element| 
                     if h2kFuelElements[locationFuelText].attributes["id"] == value
                        locationText = "HouseFile/FuelCosts/NaturalGas/Fuel/Units"
                        h2kElements[locationText].attributes["code"] = h2kFuelElements[locationFuelText][5].attributes["code"]
                        locationText = "HouseFile/FuelCosts/NaturalGas/Fuel/Minimum"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][7].attributes["units"]
                        h2kElements[locationText].attributes["charge"] = h2kFuelElements[locationFuelText][7].attributes["charge"]
                        locationText = "HouseFile/FuelCosts/NaturalGas/Fuel/RateBlocks/Block1"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][1].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][1].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/NaturalGas/Fuel/RateBlocks/Block2"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][3].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][3].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/NaturalGas/Fuel/RateBlocks/Block3"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][5].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][5].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/NaturalGas/Fuel/RateBlocks/Block4"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][7].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][7].attributes["costPerUnit"]
                     end
                  end
               elsif ( tag =~ /OPT-OilName/ && value != "NA" )
                  locationText = "HouseFile/FuelCosts/Oil/Fuel/Label"
                  h2kElements[locationText].text = value
               elsif ( tag =~ /OPT-OilID/ && value != "NA" )
                  locationText = "HouseFile/FuelCosts/Oil/Fuel"
                  h2kElements[locationText].attributes["id"] = value
                  # Set using rate blocks for this id from library file!
                  locationFuelText = "FuelCosts/Oil/Fuel"
                  h2kFuelElements.each(locationFuelText) do |element| 
                     if h2kFuelElements[locationFuelText].attributes["id"] == value
                        locationText = "HouseFile/FuelCosts/Oil/Fuel/Units"
                        h2kElements[locationText].attributes["code"] = h2kFuelElements[locationFuelText][5].attributes["code"]
                        locationText = "HouseFile/FuelCosts/Oil/Fuel/Minimum"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][7].attributes["units"]
                        h2kElements[locationText].attributes["charge"] = h2kFuelElements[locationFuelText][7].attributes["charge"]
                        locationText = "HouseFile/FuelCosts/Oil/Fuel/RateBlocks/Block1"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][1].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][1].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Oil/Fuel/RateBlocks/Block2"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][3].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][3].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Oil/Fuel/RateBlocks/Block3"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][5].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][5].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Oil/Fuel/RateBlocks/Block4"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][7].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][7].attributes["costPerUnit"]
                     end
                  end
               elsif ( tag =~ /OPT-PropaneName/ && value != "NA" )
                  locationText = "HouseFile/FuelCosts/Propane/Fuel/Label"
                  h2kElements[locationText].text = value
               elsif ( tag =~ /OPT-PropaneID/ && value != "NA" )
                  locationText = "HouseFile/FuelCosts/Propane/Fuel"
                  h2kElements[locationText].attributes["id"] = value
                  # Set using rate blocks for this id from library file!
                  locationFuelText = "FuelCosts/Propane/Fuel"
                  h2kFuelElements.each(locationFuelText) do |element| 
                     if h2kFuelElements[locationFuelText].attributes["id"] == value
                        locationText = "HouseFile/FuelCosts/Propane/Fuel/Units"
                        h2kElements[locationText].attributes["code"] = h2kFuelElements[locationFuelText][5].attributes["code"]
                        locationText = "HouseFile/FuelCosts/Propane/Fuel/Minimum"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][7].attributes["units"]
                        h2kElements[locationText].attributes["charge"] = h2kFuelElements[locationFuelText][7].attributes["charge"]
                        locationText = "HouseFile/FuelCosts/Propane/Fuel/RateBlocks/Block1"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][1].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][1].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Propane/Fuel/RateBlocks/Block2"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][3].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][3].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Propane/Fuel/RateBlocks/Block3"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][5].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][5].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Propane/Fuel/RateBlocks/Block4"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][7].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][7].attributes["costPerUnit"]
                     end
                  end
               elsif ( tag =~ /OPT-WoodName/ && value != "NA" )
                  locationText = "HouseFile/FuelCosts/Wood/Fuel/Label"
                  h2kElements[locationText].text = value
               elsif ( tag =~ /OPT-WoodID/ && value != "NA" )
                  locationText = "HouseFile/FuelCosts/Wood/Fuel"
                  h2kElements[locationText].attributes["id"] = value
                  # Set using rate blocks for this id from library file!
                  locationFuelText = "FuelCosts/Wood/Fuel"
                  h2kFuelElements.each(locationFuelText) do |element| 
                     if h2kFuelElements[locationFuelText].attributes["id"] == value
                        locationText = "HouseFile/FuelCosts/Wood/Fuel/Units"
                        h2kElements[locationText].attributes["code"] = h2kFuelElements[locationFuelText][5].attributes["code"]
                        locationText = "HouseFile/FuelCosts/Wood/Fuel/Minimum"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][7].attributes["units"]
                        h2kElements[locationText].attributes["charge"] = h2kFuelElements[locationFuelText][7].attributes["charge"]
                        locationText = "HouseFile/FuelCosts/Wood/Fuel/RateBlocks/Block1"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][1].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][1].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Wood/Fuel/RateBlocks/Block2"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][3].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][3].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Wood/Fuel/RateBlocks/Block3"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][5].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][5].attributes["costPerUnit"]
                        locationText = "HouseFile/FuelCosts/Wood/Fuel/RateBlocks/Block4"
                        h2kElements[locationText].attributes["units"] = h2kFuelElements[locationFuelText][9][7].attributes["units"]
                        h2kElements[locationText].attributes["costPerUnit"] = h2kFuelElements[locationFuelText][9][7].attributes["costPerUnit"]
                     end
                  end
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
            
            
            # Air Infiltration Rate
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-ACH/ )
               if ( tag =~ /Opt-ACH/ && value != "NA" )
                  locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
                  h2kElements[locationText].attributes["airChangeRate"] = value
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
            
            
            # Ceilings
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-Ceilings/ )
               if ( tag =~ /Opt-Ceiling/ && value != "NA" )
                  # If this surface code name exists in the code library, use the code 
                  # (either Fav or UsrDef) for all surfaces of this type. Code names in library are unique.
                  # Note: Not using "Standard", non-library codes (e.g., 2221292000)
                  
                  # Look for this code name in code library (Favorite and UserDefined)
                  thisCodeInHouse = false
                  useThisCodeID = "Code 99"
                  foundFavLibCode = false
                  foundUsrDefLibCode = false
                  foundCodeLibElement = ""
                  locationCodeFavText = "Codes/Ceiling/Favorite/Code"
                  h2kCodeElements.each(locationCodeFavText) do |codeElement| 
                     if ( codeElement.get_text("Label") == value )
                        foundFavLibCode = true
                        foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                        break
                     end
                  end
                  # Code library names are also unique across Favorite and User Defined codes
                  if ( ! foundFavLibCode )
                     locationCodeUsrDefText = "Codes/Ceiling/UserDefined/Code"
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
                        locationText = "HouseFile/Codes/Ceiling/Favorite"
                     else
                        locationText = "HouseFile/Codes/Ceiling/UserDefined"
                     end
                     h2kElements.each(locationText + "/Code") do |element| 
                        if ( element.get_text("Label") == value )
                           thisCodeInHouse = true
                           useThisCodeID = element.attributes["id"]
                           break
                        end
                     end
                     if ( ! thisCodeInHouse )
                        if ( h2kElements["HouseFile/Codes/Ceiling"] == nil )
                           # No section ofthis type in house file Codes section -- add it!
                           h2kElements["HouseFile/Codes"].add_element("Ceiling")
                        end
                        if ( h2kElements[locationText] == nil )
                           # No Favorite or UserDefined section in house file Codes section -- add it!
                           if ( foundFavLibCode )
                              h2kElements["HouseFile/Codes/Ceiling"].add_element("Favorite")
                           else
                              h2kElements["HouseFile/Codes/Ceiling"].add_element("UserDefined")
                           end
                        end
                        h2kElements[locationText].add(foundCodeLibElement)
                        h2kElements[locationText + "/Code"].attributes["id"] = useThisCodeID
                     end
                     # Change all existing surface references of this type to useThisCodeID
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
                     debug_out("Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}")
                  end
                  
               elsif ( tag =~ /OPT-H2K-EffRValue/ && value != "NA" )
                  # Change ALL existing ceiling codes to User Specified R-value
                  locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
                  h2kElements.each(locationText) do |element| 
                     element.text = "User specified"
                     element.attributes["rValue"] = (value.to_f / CONV_R_2_RSI).to_s
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
                        h2kElements[locationText].add(foundCodeLibElement)
                        h2kElements[locationText + "/Code"].attributes["id"] = useThisCodeID
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
                     debug_out("Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}")
                  end
                  
               elsif ( tag =~ /OPT-H2K-EffRValue/ && value != "NA" )
                  # Change ALL existing wall codes to User Specified R-value
                  locationText = "HouseFile/House/Components/Wall/Construction/Type"
                  h2kElements.each(locationText) do |element| 
                     element.text = "User specified"
                     element.attributes["rValue"] = (value.to_f / CONV_R_2_RSI).to_s
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
                        h2kElements[locationText].add(foundCodeLibElement)
                        h2kElements[locationText + "/Code"].attributes["id"] = useThisCodeID
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
                     debug_out("Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}")
                  end
                  
               elsif ( tag =~ /OPT-H2K-EffRValue/ &&  value != "NA" )
                  # Change ALL existing floor codes to User Specified R-value
                  locationText = "HouseFile/House/Components/Floor/Construction/Type"
                  h2kElements.each(locationText) do |element| 
                     element.text = "User specified"
                     element.attributes["rValue"] = (value.to_f / CONV_R_2_RSI).to_s
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
                  # Change ALL existing S-facing windows to this library code name.
                  # If this code name exists in the code library, use the code 
                  # (either Fav or UsrDef) for all entries facing S. Code names in library are unique.
                  # Note: Not using "Standard", non-library codes (e.g., 2221292000)
                  
                  # Look for this code name in code library (Favorite and UserDefined)
                  thisCodeInHouse = false
                  useThisCodeID = "Code 199"
                  foundFavLibCode = false
                  foundUsrDefLibCode = false
                  foundCodeLibElement = ""
                  locationCodeFavText = "Codes/Window/Favorite/Code"
                  h2kCodeElements.each(locationCodeFavText) do |codeElement| 
                     if ( codeElement.get_text("Label") == value )
                        foundFavLibCode = true
                        foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                        break
                     end
                  end
                  # Code library names are also unique across Favorite and User Defined codes
                  if ( ! foundFavLibCode )
                     locationCodeUsrDefText = "Codes/Window/UserDefined/Code"
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
                        locationText = "HouseFile/Codes/Window/Favorite"
                     else
                        locationText = "HouseFile/Codes/Window/UserDefined"
                     end
                     h2kElements.each(locationText + "/Code") do |element| 
                        if ( element.get_text("Label") == value )
                           thisCodeInHouse = true
                           useThisCodeID = element.attributes["id"]
                           break
                        end
                     end
                     if ( ! thisCodeInHouse )
                        if ( h2kElements["HouseFile/Codes/Window"] == nil )
                           # No section ofthis type in house file Codes section -- add it!
                           h2kElements["HouseFile/Codes"].add_element("Window")
                        end
                        if ( h2kElements[locationText] == nil )
                           # No Favorite or UserDefined section in house file Codes section -- add it!
                           if ( foundFavLibCode )
                              h2kElements["HouseFile/Codes/Window"].add_element("Favorite")
                           else
                              h2kElements["HouseFile/Codes/Window"].add_element("UserDefined")
                           end
                        end
                        h2kElements[locationText].add(foundCodeLibElement)
                        h2kElements[locationText + "/Code"].attributes["id"] = useThisCodeID
                     end
                     
                     # Windows in walls elements
                     locationText = "HouseFile/House/Components/Wall/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["S"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in basement wall elements
                     locationText = "HouseFile/House/Components/Basement/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["S"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in walkout wall elements
                     locationText = "HouseFile/House/Components/Walkout/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["S"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in crawlspace elements             [******** Skip for now ********]
                     # Windows in ceiling elements (skylights)    [******** Skip for now ********]
                     # Windows in door elements                   [******** Skip for now ********]
                  else
                     # Code name not found in the code library
                     # Since no User Specified option for windows this must be an error!
                     fatalerror("Missing code name: #{value} in code library for H2K #{choiceEntry} tag:#{tag}")
                  end
               
               elsif ( tag =~ /Opt-win-E-CON/ &&  value != "NA" )
                  # Change ALL existing E-facing windows to this library code name.
                  # If this code name exists in the code library, use the code 
                  # (either Fav or UsrDef) for all entries facing E. Code names in library are unique.
                  # Note: Not using "Standard", non-library codes (e.g., 2221292000)
                  
                  # Look for this code name in code library (Favorite and UserDefined)
                  thisCodeInHouse = false
                  useThisCodeID = "Code 189"
                  foundFavLibCode = false
                  foundUsrDefLibCode = false
                  foundCodeLibElement = ""
                  locationCodeFavText = "Codes/Window/Favorite/Code"
                  h2kCodeElements.each(locationCodeFavText) do |codeElement| 
                     if ( codeElement.get_text("Label") == value )
                        foundFavLibCode = true
                        foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                        break
                     end
                  end
                  # Code library names are also unique across Favorite and User Defined codes
                  if ( ! foundFavLibCode )
                     locationCodeUsrDefText = "Codes/Window/UserDefined/Code"
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
                        locationText = "HouseFile/Codes/Window/Favorite"
                     else
                        locationText = "HouseFile/Codes/Window/UserDefined"
                     end
                     h2kElements.each(locationText + "/Code") do |element| 
                        if ( element.get_text("Label") == value )
                           thisCodeInHouse = true
                           useThisCodeID = element.attributes["id"]
                           break
                        end
                     end
                     if ( ! thisCodeInHouse )
                        if ( h2kElements["HouseFile/Codes/Window"] == nil )
                           # No section ofthis type in house file Codes section -- add it!
                           h2kElements["HouseFile/Codes"].add_element("Window")
                        end
                        if ( h2kElements[locationText] == nil )
                           # No Favorite or UserDefined section in house file Codes section -- add it!
                           if ( foundFavLibCode )
                              h2kElements["HouseFile/Codes/Window"].add_element("Favorite")
                           else
                              h2kElements["HouseFile/Codes/Window"].add_element("UserDefined")
                           end
                        end
                        h2kElements[locationText].add(foundCodeLibElement)
                        h2kElements[locationText + "/Code"].attributes["id"] = useThisCodeID
                     end
                     
                     # Windows in walls elements
                     locationText = "HouseFile/House/Components/Wall/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["E"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in basement wall elements
                     locationText = "HouseFile/House/Components/Basement/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["E"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in walkout wall elements
                     locationText = "HouseFile/House/Components/Walkout/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["E"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in crawlspace elements             [******** Skip for now ********]
                     # Windows in ceiling elements (skylights)    [******** Skip for now ********]
                     # Windows in door elements                   [******** Skip for now ********]
                  else
                     # Code name not found in the code library
                     # Since no User Specified option for windows this must be an error!
                     fatalerror("Missing code name: #{value} in code library for H2K #{choiceEntry} tag:#{tag}")
                  end

               elsif ( tag =~ /Opt-win-N-CON/ &&  value != "NA" )    # Do nothing
                  # Change ALL existing N-facing windows to this library code name.
                  # If this code name exists in the code library, use the code 
                  # (either Fav or UsrDef) for all entries facing N. Code names in library are unique.
                  # Note: Not using "Standard", non-library codes (e.g., 2221292000)
                  
                  # Look for this code name in code library (Favorite and UserDefined)
                  thisCodeInHouse = false
                  useThisCodeID = "Code 179"
                  foundFavLibCode = false
                  foundUsrDefLibCode = false
                  foundCodeLibElement = ""
                  locationCodeFavText = "Codes/Window/Favorite/Code"
                  h2kCodeElements.each(locationCodeFavText) do |codeElement| 
                     if ( codeElement.get_text("Label") == value )
                        foundFavLibCode = true
                        foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                        break
                     end
                  end
                  # Code library names are also unique across Favorite and User Defined codes
                  if ( ! foundFavLibCode )
                     locationCodeUsrDefText = "Codes/Window/UserDefined/Code"
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
                        locationText = "HouseFile/Codes/Window/Favorite"
                     else
                        locationText = "HouseFile/Codes/Window/UserDefined"
                     end
                     h2kElements.each(locationText + "/Code") do |element| 
                        if ( element.get_text("Label") == value )
                           thisCodeInHouse = true
                           useThisCodeID = element.attributes["id"]
                           break
                        end
                     end
                     if ( ! thisCodeInHouse )
                        if ( h2kElements["HouseFile/Codes/Window"] == nil )
                           # No section ofthis type in house file Codes section -- add it!
                           h2kElements["HouseFile/Codes"].add_element("Window")
                        end
                        if ( h2kElements[locationText] == nil )
                           # No Favorite or UserDefined section in house file Codes section -- add it!
                           if ( foundFavLibCode )
                              h2kElements["HouseFile/Codes/Window"].add_element("Favorite")
                           else
                              h2kElements["HouseFile/Codes/Window"].add_element("UserDefined")
                           end
                        end
                        h2kElements[locationText].add(foundCodeLibElement)
                        h2kElements[locationText + "/Code"].attributes["id"] = useThisCodeID
                     end
                     
                     # Windows in walls elements
                     locationText = "HouseFile/House/Components/Wall/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["N"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in basement wall elements
                     locationText = "HouseFile/House/Components/Basement/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["N"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in walkout wall elements
                     locationText = "HouseFile/House/Components/Walkout/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["N"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in crawlspace elements             [******** Skip for now ********]
                     # Windows in ceiling elements (skylights)    [******** Skip for now ********]
                     # Windows in door elements                   [******** Skip for now ********]
                  else
                     # Code name not found in the code library
                     # Since no User Specified option for windows this must be an error!
                     fatalerror("Missing code name: #{value} in code library for H2K #{choiceEntry} tag:#{tag}")
                  end
               
               elsif ( tag =~ /Opt-win-W-CON/ &&  value != "NA" )    # Do nothing
                  # Change ALL existing W-facing windows to this library code name.
                  # If this code name exists in the code library, use the code 
                  # (either Fav or UsrDef) for all entries facing W. Code names in library are unique.
                  # Note: Not using "Standard", non-library codes (e.g., 2221292000)
                  
                  # Look for this code name in code library (Favorite and UserDefined)
                  thisCodeInHouse = false
                  useThisCodeID = "Code 169"
                  foundFavLibCode = false
                  foundUsrDefLibCode = false
                  foundCodeLibElement = ""
                  locationCodeFavText = "Codes/Window/Favorite/Code"
                  h2kCodeElements.each(locationCodeFavText) do |codeElement| 
                     if ( codeElement.get_text("Label") == value )
                        foundFavLibCode = true
                        foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                        break
                     end
                  end
                  # Code library names are also unique across Favorite and User Defined codes
                  if ( ! foundFavLibCode )
                     locationCodeUsrDefText = "Codes/Window/UserDefined/Code"
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
                        locationText = "HouseFile/Codes/Window/Favorite"
                     else
                        locationText = "HouseFile/Codes/Window/UserDefined"
                     end
                     h2kElements.each(locationText + "/Code") do |element| 
                        if ( element.get_text("Label") == value )
                           thisCodeInHouse = true
                           useThisCodeID = element.attributes["id"]
                           break
                        end
                     end
                     if ( ! thisCodeInHouse )
                        if ( h2kElements["HouseFile/Codes/Window"] == nil )
                           # No section ofthis type in house file Codes section -- add it!
                           h2kElements["HouseFile/Codes"].add_element("Window")
                        end
                        if ( h2kElements[locationText] == nil )
                           # No Favorite or UserDefined section in house file Codes section -- add it!
                           if ( foundFavLibCode )
                              h2kElements["HouseFile/Codes/Window"].add_element("Favorite")
                           else
                              h2kElements["HouseFile/Codes/Window"].add_element("UserDefined")
                           end
                        end
                        h2kElements[locationText].add(foundCodeLibElement)
                        h2kElements[locationText + "/Code"].attributes["id"] = useThisCodeID
                     end
                     
                     # Windows in walls elements
                     locationText = "HouseFile/House/Components/Wall/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["W"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in basement wall elements
                     locationText = "HouseFile/House/Components/Basement/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["W"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in walkout wall elements
                     locationText = "HouseFile/House/Components/Walkout/Components/Window"
                     h2kElements.each(locationText) do |element| 
                        # 9=FacingDirection
                        if ( element[9].attributes["code"] == windowFacingH2K["W"].to_s )
                           # Check if each house entry has an "idref" attribute and add if it doesn't.
                           # Change each house entry to reference a new <Codes> section useThisCodeID
                           if element[3][1].attributes["idref"] != nil            # ../Construction/Type
                              element[3][1].attributes["idref"] = useThisCodeID
                           else
                              element[3][1].add_attribute("idref", useThisCodeID)
                           end
                           element[3][1].text = value
                        end
                     end
                     # Windows in crawlspace elements             [******** Skip for now ********]
                     # Windows in ceiling elements (skylights)    [******** Skip for now ********]
                     # Windows in door elements                   [******** Skip for now ********]
                  else
                     # Code name not found in the code library
                     # Since no User Specified option for windows this must be an error!
                     fatalerror("Missing code name: #{value} in code library for H2K #{choiceEntry} tag:#{tag}")
                  end
               
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
               # Refer to tag value for OPT-H2K-ConfigType to determine which foundations to change!
               config = $gOptions["Opt-H2KFoundation"]["options"][ $gChoices["Opt-H2KFoundation"] ]["values"]["1"]["conditions"]["all"]
               (configType, configSubType, fndTypes) = config.split('_')
                  
               if ( tag =~ /OPT-H2K-ConfigType/ &&  value != "NA" )
                  # Set the configuration type for the fnd types specified (A=All)
                  if ( fndTypes == "B" || fndTypes == "A" )
                     locationText = "HouseFile/House/Components/Basement/Configuration"
                     h2kElements.each(locationText) do |element| 
                        element.attributes["type"] = configType
                        element.attributes["subtype"] = configSubType
                        element.attributes["overlap"] = "0"
                        element.text = configType + "_" + configSubType
                     end
                  elsif ( fndTypes == "W" || fndTypes == "A" )
                     locationText = "HouseFile/House/Components/Walkout/Configuration"
                     h2kElements.each(locationText) do |element| 
                        element.attributes["type"] = configType
                        element.attributes["subtype"] = configSubType
                        element.text = configType + "_" + configSubType
                     end
                  elsif ( fndTypes == "C" || fndTypes == "A" )
                     locationText = "HouseFile/House/Components/Crawlspace/Configuration"
                     h2kElements.each(locationText) do |element| 
                        element.attributes["type"] = configType
                        element.attributes["subtype"] = configSubType
                        element.text = configType + "_" + configSubType
                     end
                  elsif ( fndTypes == "S" || fndTypes == "A" )
                     locationText = "HouseFile/House/Components/Slab/Configuration"
                     h2kElements.each(locationText) do |element| 
                        element.attributes["type"] = configType
                        element.attributes["subtype"] = configSubType
                        element.text = configType + "_" + configSubType
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
                        locationCodeUsrDefText = "Codes/" + txt + "/Favorite/Code"
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
                        if ( fndTypes == "B" || fndTypes == "W" || (fndTypes == "A" && configType =~ /^B/) )
                           locStr = "HouseFile/Codes/BasementWall"
                        elsif ( fndTypes == "C" || (fndTypes == "A" && configType =~ /^S/) )
                           locStr = "HouseFile/Codes/CrawlspaceWall"
                        end
                        if ( h2kElements[locStr] == nil )
                           # No section of this type in house file Codes section -- add it!
                           h2kElements["HouseFile/Codes"].add_element(FndTypeTxt)
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
                     elsif ( fndTypes == "C" || ( fndTypes == "A" && configType =~ /^S/ ) )
                        locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Wall/Construction/Type"
                     elsif ( fndTypes == "A" && configType =~ /^B/ )
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
                     debug_out("Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}")
                  end
                  
               elsif ( tag =~ /OPT-H2K-IntWall-RValue/ &&  value != "NA" )
                  # Change ALL existing interior wall codes to User Specified R-value
                  locHouseStr = [ "", "" ]
                  if ( fndTypes == "B" )
                     locHouseStr[0] = "HouseFile/House/Components/Basement/Wall/Construction/InteriorAddedInsulation"
                  elsif ( fndTypes == "W" )
                     locHouseStr[0] = "HouseFile/House/Components/Walkout/Wall/Construction/InteriorAddedInsulation"
                  elsif ( fndTypes == "C" || ( fndTypes == "A" && configType =~ /^S/ ) )
                     locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Wall/Construction/Type"
                  elsif ( fndTypes == "A" && configType =~ /^B/ )
                     locHouseStr[0] = "HouseFile/House/Components/Basement/Wall/Construction/InteriorAddedInsulation"
                     locHouseStr[1] = "HouseFile/House/Components/Walkout/Wall/Construction/InteriorAddedInsulation"
                  end
                  locHouseStr.each do |locationString|
                     if ( locationString != "" )
                        h2kElements.each(locationString) do |element| 
                           element[1].text = "User specified"     # Description tag
                           element[3][1].attributes["rsi"] = (value.to_f / CONV_R_2_RSI).to_s
                           element[3][1].attributes["rank"] = "1"
                           element[3][1].attributes["percentage"] = "100"
                           if element.attributes["idref"] != nil then
                              # Must delete attribute for User Specified!
                              element.delete_attribute("idref")
                           end
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
                  elsif ( fndTypes == "A" && configType =~ /^B/ )
                     locHouseStr[0] = "HouseFile/House/Components/Basement/Wall/Construction/ExteriorAddedInsulation"
                     locHouseStr[1] = "HouseFile/House/Components/Walkout/Wall/Construction/ExteriorAddedInsulation"
                  end
                  locHouseStr.each do |locationString|
                     if ( locationString != "" )
                        h2kElements.each(locationString) do |element| 
                           element[1].text = "User specified"     # Description tag
                           element[3][1].attributes["rsi"] = (value.to_f / CONV_R_2_RSI).to_s
                           element[3][1].attributes["rank"] = "1"
                           element[3][1].attributes["percentage"] = "100"
                           if element.attributes["code"] != nil then
                              # Must delete attribute for User Specified!
                              element.delete_attribute("code")
                           end
                        end
                      end
                  end
                  
               elsif ( tag =~ /OPT-H2K-BelowSlab-RVal/ &&  value != "NA" )
                  
               else
                  if ( value == "NA" ) # Don't change anything
                  else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
               
               
            # DWHR (+SDHW)
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-DWHRandSDHW / )
               
               
            # Electrical Loads
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-ElecLoadScale/ )
               
               
            # DHW Loads (Hot Water Use)
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-DHWLoadScale/ )
               
               
            # DHW System
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-DHWSystem/ )
               
               
            # HVAC System (Type 1)
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-HVACSystem/ )
               if ( tag =~ /XXXX/ &&  value != "NA" )
                  locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EquipmentType"
                  h2kElements[locationText].attributes["code"] = value
               else
                  #if ( value == "NA" ) # Don't change anything
                  #else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
               end
               
               
            # Furance Fan Control
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /OPT-Furnace-Fan-Ctl/ )
               
               
            # Cooling System
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-Cooling-Spec/ )
               
               
            # HRV System
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-HRVspec/ )
               
               
            # PV - Use H2K model
            #--------------------------------------------------------------------------
            elsif ( choiceEntry =~ /Opt-StandoffPV/ )
               if ( tag =~ /Opt-StandoffPV/ &&  value != "NA" )
                  #locationText1 = "HouseFile/House/Generation/Photovoltaic/Array"
                  #locationText2 = "HouseFile/House/Generation/Photovoltaic/Module/Type"
                  #h2kElements[locationText1].attributes["area"] = value
                  #h2kElements[locationText1].attributes["slope"] = value
                  #h2kElements[locationText1].attributes["azimuth"] = value
                  #h2kElements[locationText2].attributes["code"] = value
               else
                  #if ( value == "NA" ) # Don't change anything
                  #else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
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

# Procedure to run HOT2000
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
   
   if ( system(runThis, optionSwitch, fileToLoad) )      # Run HOT2000!
      stream_out( "\n The run was successful!\n" )
   else
      # GenOpt picks up "Fatal Error!" via an entry in the *.GO-config file.
      fatalerror( " Fatal Error! HOT2000 return code: #{$?}\n" )
   end
   
   Dir.chdir( $gMasterPath )
   debug_out ("\n Moved to path: #{Dir.getwd()}\n") 
   
   # Save output files
   $OutputFolder = "sim-output"
   if ( ! Dir.exist?($OutputFolder) )
      if ( ! system("mkdir #{$OutputFolder}") )
         debug_out ("Could not create #{$OutputFolder} below #{$gMasterPath}!\n")
      end
   else
      if ( File.exist?("#{$OutputFolder}\\Browse.rpt") )
         if ( ! system("del #{$OutputFolder}\\Browse.rpt") )    # Delete existing Browse.Rpt
            debug_out ("Could not delete existing Browse.rpt file in #{$OutputFolder}!\n")
         end
      end
   end
   
   # Copy simulation results to sim-output folder in master (for ERS number)
   # Note that most of the output is contained in the HOT2000 file in XML!
   if ( Dir.exist?("sim-output") )
      system("copy #{$run_path}\\Browse.rpt .\\sim-output\\")
   end

end   # runsims

# Post-process results
def postprocess( scaleData )
  
   # Load all XML elements from HOT2000 file (post-run results now available)
   h2kPostElements = get_elements_from_filename( $gWorkingModelFile )

   $Locale = $gChoices["Opt-Location"] 
   if ( $Locale =~ /London/ || $Locale =~ /Windsor/ || $Locale =~ /ThunderBay/ )
      $Locale = "Toronto"
   end
  
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
            break    # Got what we want -- exit the while loop because this is last item to find in file!
         end
      end
   end
   fBrowseRpt.close()

   $gAvgCost_Pellet = 0    # H2K doesn't identify pellets in output (only inputs)!
   
   # Total energy: H2K value in GJ
   locationText = "HouseFile/AllResults/Results/Annual/Consumption"
   $gAvgEnergy_Total += h2kPostElements[locationText].attributes["total"].to_f * scaleData
   
   locationText = "HouseFile/AllResults/Results/Annual/Consumption/SpaceHeating"
   $gAvgEnergyHeatingGJ += h2kPostElements[locationText].attributes["total"].to_f * scaleData
   
   locationText = "HouseFile/AllResults/Results/Annual/Consumption/Electrical"
   $gAvgEnergyCoolingGJ += h2kPostElements[locationText].attributes["airConditioning"].to_f * scaleData
   $gAvgEnergyVentilationGJ += h2kPostElements[locationText].attributes["ventilation"].to_f * scaleData
   $gAvgEnergyEquipmentGJ += h2kPostElements[locationText].attributes["appliance"].to_f * scaleData
   
   locationText = "HouseFile/AllResults/Results/Annual/Consumption/HotWater"
   $gAvgEnergyWaterHeatingGJ += h2kPostElements[locationText].attributes["total"].to_f * scaleData
   
   # H2K Electicity value in GJ * 277.778 -> kWh
   locationText = "HouseFile/AllResults/Results/Annual/Consumption/Electrical"
   $gAvgElecCons_KWh += h2kPostElements[locationText].attributes["total"].to_f * 277.778 * scaleData
   
   # H2K Natural Gas value in GJ * 26.839 -> m3 NG
   locationText = "HouseFile/AllResults/Results/Annual/Consumption/NaturalGas"
   $gAvgNGasCons_m3 += h2kPostElements[locationText].attributes["total"].to_f * 26.839 * scaleData
   
   # H2K Oil value in GJ * 25.958 -> Lites oil
   locationText = "HouseFile/AllResults/Results/Annual/Consumption/Oil"
   $gAvgOilCons_l += h2kPostElements[locationText].attributes["total"].to_f * 25.958 * scaleData
   
   # H2K Wood value in GJ * 0.07167 -> 1000 kg wood (Is this correct since HC varies with wood type?)
   locationText = "HouseFile/AllResults/Results/Annual/Consumption/Wood"
   $gEnergyWood = h2kPostElements[locationText].attributes["total"].to_f * 0.07167 * scaleData
   # Note that avgWoodCons_tonne is NOT output. Jeff created here for comparison purposes
   $gAvgPelletCons_tonne = 0  
   
   # Design heat loss (W)
   locationText = "HouseFile/AllResults/Results/Other/"
   $gPeakHeatingLoadW += h2kPostElements[locationText].attributes["designHeatLossRate"].to_f * scaleData
   
   # Design heat loss (W)
   locationText = "HouseFile/AllResults/Results/Other/"
   $gPeakCoolingLoadW += h2kPostElements[locationText].attributes["designCoolLossRate"].to_f * scaleData
   
   # PV Data...
   $PVArrayCost = 0.0
   $PVArraySized = 0.0
   $PVsize = $gChoices["Opt-StandoffPV"]
   $PVcapacity = $PVsize
   $PVcapacity.gsub(/[a-zA-Z:\s'\|]/, '')
   if ( $PVcapacity == "" || $PVcapacity == "NoPV")
      $PVcapacity = 0.0
   end
   
   if ( $PVsize !~ /SizedPV/ )
      # Use spec'd PV sizes. This only works for NoPV. 
      $gPVProduction = 0.0
      $PVArrayCost = 0.0
   else
      # Size PV according to user specification, to max, or to size required to reach Net-Zero. 
      # User-specified PV size (format is 'SizedPV|XkW', PV will be sized to X kW'.
      if ( $gExtraDataSpecd["Opt-StandoffPV"] =~ /kW/ )
         $PVArraySized = $gExtraDataSpecd["Opt-StandoffPV"].to_f  # ignores "kW" in string
         $PVUnitOutput = $gOptions["Opt-StandoffPV"]["options"]["SizedPV"]["ext-result"]["production-elec-perKW"].to_f
         $PVUnitCost = $gOptions["Opt-StandoffPV"]["options"]["SizedPV"]["cost"].to_f
         $PVArrayCost = $PVUnitCost * $PVArraySized 
         $gPVProduction = -1.0 * $PVUnitOutput * $PVArraySized
         $PVsize = "spec'd SizedPV | $PVArraySized kW"
      else
         # USER Hasn't specified PV size, Size PV to attempt to get to net-zero. 
         # First, get the home's total energy requirement. 
         $prePVEnergy = $gAvgEnergy_Total
         if ( $prePVEnergy > 0 )
            # This should always be the case!
            $PVUnitOutput = $gOptions["Opt-StandoffPV"]["options"][$PVsize]["ext-result"]["production-elec-perKW"].to_f
            $PVUnitCost = $gOptions["Opt-StandoffPV"]["options"][$PVsize]["cost"].to_f
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
         debug_out (" PV array is #{$PVsize}  ...\n")
      end
   end
   $gChoices["Opt-StandoffPV"] = $PVsize
   $gOptions["Opt-StandoffPV"]["options"][$PVsize]["cost"] = $PVArrayCost

   # PV energy from HOT2000 model run (GJ) OR Size provided in Choice file!
   # ----------------------------------------------------------------------
   #locationText = "HouseFile/AllResults/Results/Monthly/Load/PhotoVoltaicUtilized"
   #monthArr = [ "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december" ]
   #monthArr.each do |mth|
   #   $gEnergyPV += h2kPostElements[locationText].attributes[mth].to_f
   #end
   
   # PV energy shouldn't be cumulative for orientation runs (GJ * 277.778 -> kWh)!!
   $gAvgPVOutput_kWh   = -1.0 * $gEnergyPV * 277.778 * scaleData

   stream_out  "\n Peak Heating Load (W): #{$gPeakHeatingLoadW.round(1)} \n"
   stream_out  " Peak Cooling Load (W): #{$gPeakCoolingLoadW.round(1)} \n"
   
   stream_out("\n Energy Consumption: \n\n")
   stream_out ( "  #{$gAvgEnergyHeatingGJ.round(1)} ( Space Heating, GJ ) \n")
   stream_out ( "  #{$gAvgEnergyWaterHeatingGJ.round(1)} ( Hot Water, GJ ) \n")
   stream_out ( "  #{$gAvgEnergyVentilationGJ.round(1)} ( Ventilator Electrical, GJ ) \n")
   stream_out ( "  #{$gAvgEnergyCoolingGJ.round(1)} ( Space Cooling, GJ ) \n")
   stream_out ( " --------------------------------------------------------\n")
   stream_out ( "    #{($gAvgEnergyHeatingGJ + $gAvgEnergyWaterHeatingGJ + $gAvgEnergyVentilationGJ).round(1)} ( H2K Annual Space+DHW, GJ ) \n")
   
   stream_out("\n\n Energy Cost (not including credit for PV, direction #{$gRotationAngle} ): \n\n")
   stream_out("  + \$ #{$gAvgCost_Electr.round(2)} (Electricity)\n")
   stream_out("  + \$ #{$gAvgCost_NatGas.round(2)} (Natural Gas)\n")
   stream_out("  + \$ #{$gAvgCost_Oil.round(2)} (Oil)\n")
   stream_out("  + \$ #{$gAvgCost_Propane.round(2)} (Propane)\n")
   stream_out("  + \$ #{$gAvgCost_Wood.round(2)} (Wood)\n")
   stream_out("  + \$ #{$gAvgCost_Pellet.round(2)} (Pellet)\n")
   stream_out ( " --------------------------------------------------------\n")
   stream_out ( "    \$ #{$gAvgCost_Total.round(2)} (All utilities).\n")
   stream_out ( "\n")
   stream_out ( "  - \$ #{$gAvgPVRevenue.round(2)} (PV revenue, #{($gAvgPVRevenue * 1e06 / 3600).round} kWh at \$ #{$PVTarrifDollarsPerkWh} / kWh)\n")
   stream_out ( " --------------------------------------------------------\n")
   stream_out ( "    \$ #{($gAvgCost_Total - $gAvgPVRevenue).round(2)} (Net utility costs).\n")
   stream_out ( "\n\n")
   
   stream_out("\n\n Energy Use (not including credit for PV, direction #{$gRotationAngle} ): \n\n")
   stream_out("  - #{$gAvgElecCons_KWh.round(1)} (Electricity, kWh)\n")
   stream_out("  - #{$gAvgNGasCons_m3.round(1)} (Natural Gas, m3)\n")
   stream_out("  - #{$gAvgOilCons_l.round(1)} (Oil, l)\n")
   stream_out("  - #{$gEnergyWood.round(1)} (Wood, cord)\n")
   stream_out("  - #{$gAvgPelletCons_tonne.round(1)} (Pellet, tonnes)\n")
   stream_out ("> SCALE #{scaleData} \n"); 
   
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
 ---------------------------------------------------------------------------
 END OF ALL METHODS 
 ---------------------------------------------------------------------------
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

 substitute-h2k.pl: 
 
 This script searches through a suite of model input files 
 and substitutes values from a specified input file. 
 
 use: ruby substitute-h2k.pl --options options.opt
                             --choices choices.options
                             --base_file Base model path & file name
                      
 example use for optimization work:
 
  ruby substitute-h2k.pl -c optimization-choices.choices
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

stream_out("\n\nReading #{$gChoiceFile}...\n")
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
stream_out ("...done.\n")

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
stream_out(" Validating choices and options...\n");  

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
   stream_out("\nSubstitute-h2k.pl encountered the following errors:\n")
   stream_out($ErrorBuffer)
   fatalerror(" Choices in #{$gChoiceFile} do not match options in #{$gOptionFile}!")
else
   stream_out (" done.\n")
end

# Create a copy of HOT2000 below master
if ( ! Dir.exist?("#{$gMasterPath}\\H2K") )
   if ( ! system("mkdir #{$gMasterPath}\\H2K") )
      debug_out ("Could not create H2K folder below #{$gMasterPath}!\n")
   end
end
if ( ! system ("xcopy #{$h2k_src_path} #{$gMasterPath}\\H2K /S /Y /Q") )
   debug_out ("Could not create xcopy of HOT2000 in H2K folder below #{$gMasterPath}!\n")
end
fix_H2K_INI()  # Fixes the paths in HOT2000.ini file in H2K folder created above

# Create a copy of the HOT2000 file into the master folder for manipulation.
stream_out("\n\n Creating a copy of HOT2000 file for optimization work...\n")
$gWorkingModelFile = $gMasterPath + "\\"+ $h2kFileName
# Remove any existing file first!  
if ( File.exist?($gWorkingModelFile) )
   system ("del #{$gWorkingModelFile}")
end
system ("copy #{$gBaseModelFile} #{$gWorkingModelFile}")
stream_out("File #{$gWorkingModelFile} created.\n\n")

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

fSUMMARY.close() 

$fLOG.close() 
