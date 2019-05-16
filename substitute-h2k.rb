#!/usr/bin/env ruby
# ******************************************************************************
# substitute-h2k.rb
# Developed by Jeff Blake, CanmetENERGY-Ottawa, Natural Resources Canada
# Created Nov 2015
# Master maintained in GitHub
#
# This is a Ruby version of the substitute-h2k.pl script originally written by
# Alex Ferguson. This version is customized for HOT2000 runs. This script can be
# used stand-alone, with GenOpt or HTAP-PRM.rb for parametric runs or optimizations
# of HOT2000 inputs.
# ******************************************************************************


require 'rexml/document'
require 'optparse'
require 'timeout'
require 'fileutils'
require 'digest'
require 'json'
require 'set'
require 'pp'



require_relative 'include/msgs'
require_relative 'include/H2KUtils'
require_relative 'include/HTAPUtils'
require_relative 'include/constants'
require_relative 'include/rulesets'
require_relative 'include/costing'
require_relative 'include/legacy-code'
require_relative 'include/application_modules'

include REXML
# This allows for no "REXML::" prefix to REXML methods


$program = "substitute-h2k.rb"
HTAPInit()
# Parameters controlling timeout and re-try limits for HOT2000
# maxRunTime in seconds (decimal value accepted) set to nil or 0 means no timeout checking!
# Typical H2K run < 10 seconds, but may much take longer in ERS mode
$maxRunTime = 50
# JTB 05-10-2016: Also setting maximum retries within timeout period
$maxTries   = 3


$gJasonExport = false
$gJasonTest = false
ScriptName = "substitute.rb"

# HOT2000 output data sets depend on the run mode set in the HOT2000 inputs. In General mode
# just one run is done and one set of outputs is generated, In ERS mode, multiple (7) runs of the
# H2K core are initiated by the interface (either CLI or GUI). The output data sets contain the
# following sections ("houseCode is the XML attribute in each section):
#    houseCode=nil: Runs without any imposed conditions on inputs (i.e., same as "General" mode)
#    houseCode=SOC: ERS mode using "Standard Operating Conditions"
#    houseCode=HOC: ERS mode using "Household Operating Conditions"
#    houseCode=HCV: ERS mode "House with Continuous Scheduled Ventilation"
#    houseCode=ROC: ERS mode "House with Reduced Operating Conditions"
#    houseCode=Reference: ERS "Reference House"
#    houseCode=UserHouse: ERS mode "General Mode"
#
# 01-Feb-2018 JTB: Note that this variable will be overridden by the choice file setting for
#                  Opt-ResultHouseCode. In the case where the user has set an ERS mode output
#                  data set but the input file is set to General mode, this variable will be
#                  changed to "General".
$outputHCode = "SOC"

# Global variable names  (i.e., variables that maintain their content and use (scope)
# throughout this file).
# Note loose convention to start global variables with a 'g'.
# Ruby *requires* globals to start with '$'.

$gDebug = false
$gSkipSims = false
$gTest_params = Hash.new
# test parameters
$gChoiceFile  = ""
$gOptionFile  = ""
$PRMcall      = false
$ExtraOutput1 = false
$TsvOutput = false
$keepH2KFolder = false
$autoCostOptions = false
$autoEstimateCosts = true

$gTotalCost          = 0
$gIncBaseCosts       = 12000
# Note: This is dependent on model!
$cost_type           = 0
$gRotate             = "S"
$gArchGOChoiceFile   = 0
$gReadROutStrTxt = false

$ArchetypeData = Hash.new
$ArchetypeData["pre-substitution"]= Hash.new
$ArchetypeData["post-substitution"] = Hash.new

# Use lambda function to avoid the extra lines of creating each hash nesting
$blk = lambda { |h,k| h[k] = Hash.new(&$blk) }
$gOptions = Hash.new(&$blk)
$gOptions2 = Hash.new
$gOptionsOld = Hash.new
$gChoices = Hash.new(&$blk)
$gResults = Hash.new(&$blk)
$gElecRate = Hash.new(&$blk)
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
$gERSNum = 0
# ERS number
$gRegionalCostAdj = 0
$gRotationAngle = 0
$gEnergyElec = 0
$gEnergyGas = 0
$gEnergyOil = 0
$gEnergyProp = 0
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
# Default value if not set in Options file
$gPeakCoolingLoadW    = 0
$gPeakHeatingLoadW    = 0
$gPeakElecLoadW    = 0

# Variables for saving part-load data from hourly-bins
$binDatHrs    = Array.new
$binDatTmp    = Array.new
$binDatTsfB   = Array.new
$binDatHLR    = Array.new
$binDatT2cap  = Array.new
$binDatT2cap  = Array.new
$binDatT2PLR  = Array.new
$binDatT1PLR = Array.new

#Aliases for input/output short hand & long hand

$aliasShortInput   = "i"
$aliasShortOutput  = "o"
$aliasShortConfig  = "c"
$aliasShortArch    = "a"

$aliasLongInput   = "input"
$aliasLongOutput  = "output"
$aliasLongConfig  = "configuration"
$aliasLongArch    = "archetype"
$aliasLongStatus  = "status"
$aliasLongCosts   = "cost-estimates"

# Default to short
$aliasInput   = $aliasLongInput
$aliasOutput  = $aliasLongOutput
$aliasConfig  = $aliasLongConfig
$aliasArch    = $aliasLongArch



# Path where this script was started and considered master
$gMasterPath = Dir.getwd()
$gMasterPath.gsub!(/\//, '\\')
$unitCostFileName = "C:/HTAP/HTAPUnitCosts.json"

#Variables that store the average utility costs, energy amounts.
$gAvgEnergy_Total   = 0
$gAvgPVRevenue      = 0
$gAvgElecCons_KWh    = 0
$gAvgPVOutput_kWh    = 0
$gAvgCost_Total      = 0
$gAvgEnergyCoolingGJ = 0
$gAvgEnergyVentilationGJ  = 0
$gAvgEnergyWaterHeatingGJ = 0
$gAvgEnergyEquipmentGJ    = 0
$gAvgNGasCons_m3     = 0
$gAvgOilCons_l       = 0
$gAvgPropCons_l      = 0
$gAvgPelletCons_t    = 0
$gDirection = ""

# Flag for reporting general information
$FlagHouseInfo = true

# Flag for reporting choices in inputs
$gReportChoices      = true

$GenericWindowParams = Hash.new(&$blk)
$GenericWindowParamsDefined = 0
$gLookForArchetype = 1
$gAuxEnergyHeatingGJ = 0
# 29-Nov-2016 JTB: Added for use by RC
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
$Locale = ""
# Weather location for current run
$gWarn = false

$gNoDebug = false

$PVInt = "NA"
$PVIntModel = false
$annPVPowerFromBrowseRpt = 0.0

# Flags for AC Performance Data from Browse.rpt file
$annACSensibleLoadFromBrowseRpt = 0.0
$annACLatentLoadFromBrowseRpt = 0.0
$TotalAirConditioningLoad = 0.0
$AvgACCOP = 0.0

costEstimates = Hash.new

$ruleSetChoices = Hash.new
$ruleSetName = ""

$HDDs = ""

$optionCost = 0.00
# Total cost of all options used in this run

##=begin rdoc
#=========================================================================================
#METHODS: Routines called in this file must be defined before use in Ruby
#(can't put at bottom of listing).
#=========================================================================================
#=end


# -----------------------------------------------------------------------------------------------------

def exportOptionsToJson()

  $gExportFormat = Hash.new
  $gOptions.each do |attribute, defs|
    # Ignore legacy tags that aren't supported anymore.
    if ( $LegacyOptionsToIgnore.include? attribute )
      stream_out "    - skipping : #{attribute} (legacy variable no longer supported)\n"

      next
    else
      stream_out "    - exporting > #{attribute}\n"

    end

    # Are relationships 1->1 (flat) or 1->[1,2,3..] (tree)?
    if (  attribute =~ /GOconfig_rotate/      ||
      attribute =~ /Opt-DBFiles/          ||
      attribute =~ /Opt-ResultHouseCode/  ||
      attribute =~ /Opt-Archetype/        ||
      attribute =~ /Ruleset/                  ) then

      treeStructure = false
      structure = "flat"
    else

      treeStructure = true
      structure = "tree"

    end

    # is cost data required?
    if (  ! treeStructure ||
      attribute =~ /GOconfig_rotate/     ||
      attribute =~ /Opt-FuelCost/        ||
      attribute =~ /Opt-Location/        ||
      attribute =~ /Opt-FuelCost/        ||
      attribute =~ /Opt-DBFiles/         ||
      attribute =~ /Opt-ResultHouseCode/ ||
      attribute =~ /Opt-FuelCost/          ) then

      costingincluded = false
      costtext = "not applicable"
    else

      costingincluded = true
      costtext = "included"

    end

    # Create entry
    $gExportFormat[attribute] = Hash.new

    $gExportFormat[attribute] = {
      "structure"  => structure ,
      "costed"  => costingincluded ,
      "options" => Hash.new ,
      "default" => nil ,
      "stop-on-error" => false
    }


    if ( treeStructure ) then
      $gExportFormat[attribute]["h2kSchema"]  = Array.new

    end

    stopOnError = $gOptions[attribute]["stop-on-error"]

    if ( stopOnError == 1 ) then

      $gExportFormat[attribute]["stop-on-error"] = true

    end


    if ($gOptions[attribute].has_key?("default"))then
      $gExportFormat[attribute]["default"] =  $gOptions[attribute]["default"]["value"]
    end


    if ( treeStructure ) then
      $gOptions[attribute]["tags"].each do | index, tagname |

        # Listing of all supported tags
        $gExportFormat[attribute]["h2kSchema"].push(tagname)

      end
    end

    $gOptions[attribute]["options"].each do | option, defs2 |


      $gExportFormat[attribute]["options"][option] = Hash.new
      if ( treeStructure ) then
        $gExportFormat[attribute]["options"][option]["h2kMap"] = Hash.new
        $gExportFormat[attribute]["options"][option]["h2kMap"]["base"] = Hash.new

        # one day consider:
        #$gExportFormat[attribute]["options"][option]["values"]["variant"]
        $gExportFormat[attribute]["options"][option]["costs"] = Hash.new
        if ( costingincluded )

          $gExportFormat[attribute]["options"][option]["costs"]["components"] = Array.new
          # This field doesn't exist in the HOT2000 file. Let's create an empty example
          $gExportFormat[attribute]["options"][option]["costs"]["components"] = [ "Example Key-phrase: Layer1", "Example Key-phrase: Layer2", "Example Key-phrase: Layer3" ]
          # This field doesn't exist in the HOT2000 file. Let's create an empty example
          $gExportFormat[attribute]["options"][option]["costs"]["custom-costs"] = Hash.new
          #$gExportFormat[attribute]["options"][option]["costs"]["custom-costs"] ={ "ExampleScenarioA" =>
          #  { "Units" => "sf floor area",
          #    "TotUnitCost"  => 1.50,
          #    "Comment" => "eg: Alex's original estimate"
          #  },
          #  "ExampleScenarioB" => { "Units" => "sf floor area",
          #               "TotUnitCost"  => 1.70,
          #    "Comment" => "eg: Real numbers from ACME builder."
          #  }
          #}


        end


        # Code for testing purposes : Allows direct comparison between .json and .options generated data maps.
        if ( $gDebug ) then
          $gExportFormat[attribute]["options"][option]["costs"]["legacy"] = Hash.new
          costType = $gOptions[attribute]["options"][option]["cost-type"]
          costVal =  $gOptions[attribute]["options"][option]["cost"]
          $gExportFormat[attribute]["options"][option]["costs"]["legacy"] = { "cost-type" => costType, "cost" => costVal }
        end
      end

      $gOptions[attribute]["options"][option]["values"].each do | valnum, val |
        result = val["conditions"]["all"]
        if ( treeStructure )
          schematag = $gExportFormat[attribute]["h2kSchema"][valnum.to_i - 1]

          $gExportFormat[attribute]["options"][option]["h2kMap"]["base"][schematag] = result
        else
          $gExportFormat[attribute]["options"][option] = result

        end

      end





    end

  end



  stream_out ("Writing out options in json format (HTAP-options.json)...")
  $JSONoutput  = File.open("HTAP-options.json", 'w')
  $JSONoutput.write(JSON.pretty_generate($gExportFormat))
  $JSONoutput.close
  stream_out("done.")


  if ( $gDebug ) then

    $JSONoutput  = File.open("HTAPLegacyOptionsStructure.json", 'w')
    $JSONoutput.write(JSON.pretty_generate($gOptions))
    $JSONoutput.close

    $gOptions2 = HTAPData.parse_json_options_file("HTAP-options.json")

    $JSONoutput  = File.open("HTAPJSONOptionsStructure.json", 'w')
    $JSONoutput.write(JSON.pretty_generate($gOptions2))
    $JSONoutput.close

    debug_out ("Wrote old and new data formats to:\n")
    debug_out ("   - HTAPLegacyOptionsStructure.json \n")
    debug_out ("   - HTAPJSONOptionsStructure.json \n")
    debug_out ("   ( diff these files to compare data models ) \n")

  end



end





# =========================================================================================
# Search through the HOT2000 working file (copy of input file specified on command line)
# and change values for settings defined in choice/options files.
# =========================================================================================
def processFile(h2kElements)
  #debug_off
  # Load all XML elements from HOT2000 code library file. This file is specified
  # in option Opt-DBFiles
  codeLibName = $gOptions["Opt-DBFiles"]["options"][ $gChoices["Opt-DBFiles"] ]["values"]["1"]["conditions"]["all"]

  h2kCodeFile = $run_path + "\\StdLibs" + "\\" + codeLibName

  if ( !File.exist?(h2kCodeFile) )
    fatalerror("Code library file #{codeLibName} not found in #{$run_path + "\\StdLibs" + "\\"}!")
  else
    h2kCodeElements = H2KFile.get_elements_from_filename(h2kCodeFile)
  end
  begin
    debug_out ("saving a copy of the pre-substitute version (filepresub.h2k)\n")
    newXMLFile = File.open("file-presub.h2k", "w")
    $XMLdoc.write(newXMLFile)

  rescue
    warn_out ("Couldn't create debugging file - filepresub.h2k")
  ensure
    newXMLFile.close
  end

  $ArchetypeData["pre-substitution"]["fuelHeating"] = H2KFile.getPrimaryHeatSys( h2kElements )
  $ArchetypeData["pre-substitution"]["fuelDHW"] = H2KFile.getPrimaryDHWSys( h2kElements )


  # Will contain XML elements for fuel cost file, if Opt-Location is processed!
  # Initialized here outside of Opt-Locations check to make scope broader
  h2kFuelElements = nil

  # H2K version numbers can be used to determine availability of data in the H2K input file.
  # Made global so available outide of this subroutine definition. Note that processed output
  # file will have the version number of the H2K CLI version used in the run!
  locationText = "HouseFile/Application/Version"
  $versionMajor_H2K_input = h2kElements[locationText].attributes["major"]
  $versionMinor_H2K_input = h2kElements[locationText].attributes["minor"]
  $versionBuild_H2K_input = h2kElements[locationText].attributes["build"]

  locationText = "HouseFile/House/Generation/PhotovoltaicSystems"
  if ( h2kElements[locationText] != nil )
    $PVIntModel = true
  end

  debug_out "Foundation config: #{$foundationConfiguration}\n"

  # Legacy - set global foundaton type.
  if ( $foundationConfiguration == "wholeFdn")
    # Refer to tag value for OPT-H2K-ConfigType in choice Opt-H2KFoundation to determine which foundations to change (further down)!
    config = $gOptions["Opt-H2KFoundation"]["options"][ $gChoices["Opt-H2KFoundation"] ]["values"]["1"]["conditions"]["all"]
    (configType, configSubType, fndTypes) = config.split('_')
    # Refer to tag value for OPT-H2K-ConfigType in choice Opt-H2KFoundationSlabCrawl to determine which foundations to change (further down)!
    config2 = $gOptions["Opt-H2KFoundationSlabCrawl"]["options"][ $gChoices["Opt-H2KFoundationSlabCrawl"] ]["values"]["1"]["conditions"]["all"]
    (configType2, configSubType2, fndTypes2) = config2.split('_')
  end





  optDHWTankSize = "1"
  # DHW variable defined here so scope includes all DHW tags

  sysType1 = [ "Baseboards", "Furnace", "Boiler", "ComboHeatDhw", "P9" ]
  sysType2 = [ "AirHeatPump", "WaterHeatPump", "GroundHeatPump", "AirConditioning" ]

  # 06-Feb-2017 JTB: Save the base house system heating capacity (Watts) before this XML section is deleted.
  # For use when setting the P9 heating capacity and burner input when "Calculated" option specified
  # in options file even though it's not available in H2K GUI!
  baseHeatSysCap = getBaseSystemCapacity(h2kElements, sysType1)

  # Open the unit cost file for reading below
  if ( $autoCostOptions )
    $unitCostFile = File.read($unitCostFileName)
    unitCostDataHash = JSON.parse($unitCostFile)
  end




  baseOptionCost = 0
  #debug_on
  $gChoiceOrder.each do |choiceEntry|

    debug_out drawRuler("By ChoiceOrder : #{choiceEntry}",".  ")
    debug_out("Processing: #{choiceEntry} | #{$gOptions[choiceEntry]["type"]} = #{$gChoices[choiceEntry]}\n")


    if ( $gOptions[choiceEntry]["type"] == "internal" )
      choiceVal =  $gChoices[choiceEntry]

      tagHash = $gOptions[choiceEntry]["tags"]
      valHash = $gOptions[choiceEntry]["options"][choiceVal]["result"]
      debug_out "choice val = #{choiceVal}\n"
      debug_out "contents of tagHash:\n#{tagHash.pretty_inspect}\n"
      debug_out "contents of valHash:\n#{valHash.pretty_inspect}\n"
      for tagIndex in tagHash.keys()
        debug_out "tagIndex: #{tagIndex}\n"
        tag = tagHash[tagIndex]
        value = valHash[tagIndex.to_s]

        if ( value == "" || value.nil? )
          debug_out (">>ERR #{choiceEntry} / #{choiceVal} / #{tag} - empty value \n")
          value = ""
        end
        # Replace existing values in H2K file ....................................

        # Weather Location
        #--------------------------------------------------------------------------
        if ( choiceEntry =~ /Opt-Location/ )
          $Locale = $gChoices["Opt-Location"]
          $gRunLocale = $Locale
          # changing the soil condition to permafrost if the location is within
          # continuous permafrost zone
          set_permafrost_by_location(h2kElements,$Locale)

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

            h2kElements[locationText].text = $ProvArr[value.to_i - 1]
            $gRunRegion = $ProvArr[value.to_i - 1]
          elsif ( tag =~ /OPT-H2K-Location/ && value != "NA" )
            # Weather location to use for HOT2000 run
            locationText = "HouseFile/ProgramInformation/Weather/Location"
            h2kElements[locationText].attributes["code"] = value

          elsif ( tag =~ /OPT-WEATHER-FILE/ )
            # Do nothing
          elsif ( tag =~ /OPT-Latitude/ )
            # Do nothing
          elsif ( tag =~ /OPT-Longitude/ )
            # Do nothing
          else
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
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


              # Open fuel file and read elements to use below. This assumes that this tag
              # always comes before the remainder of the weather location tags below!!

              h2kFuelElements = H2KFile.get_elements_from_filename(h2kFuelFile)
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
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end


          # Air Infiltration Rate
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-ACH/ )
          if ( tag =~ /Opt-ACH/ && value != "NA" )

            # Need to set the House/AirTightnessTest code attribute to "Blower door test values" (x)
            locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/House/AirTightnessTest"
            h2kElements[locationText].attributes["code"] = "x"
            # Must also remove "Air Leakage Test Data" section, if present, since it will over-ride user-specified ACH value
            locationText = "HouseFile/House/NaturalAirInfiltration/AirLeakageTestData"
            if ( h2kElements[locationText] != nil )
              # Need to remove this section!
              locationText = "HouseFile/House/NaturalAirInfiltration"
              h2kElements[locationText].delete_element("AirLeakageTestData")
              # Change CGSB attribute to true (was set to "As Operated" by AirLeakageTestData section
              locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
              h2kElements[locationText].attributes["isCgsbTest"] = "true"
            end
            # Set the blower door test value in airChangeRate field
            locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
            h2kElements[locationText].attributes["airChangeRate"] = value

            h2kElements[locationText].attributes["isCgsbTest"] = "true"
            h2kElements[locationText].attributes["isCalculated"] = "true"
          elsif( tag =~ /Opt-BuildingSite/ && value != "NA" )
            if(value.to_f < 1 || value.to_f > 8)
              fatalerror("In #{choiceEntry}, invalid building site input #{value}")
            end
            locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BuildingSite/Terrain"
            h2kElements[locationText].attributes["code"] = value
          elsif( tag =~ /Opt-WallShield/ && value != "NA" )
            if(value.to_f < 1 || value.to_f > 5)
              fatalerror("In #{choiceEntry}, invalid wall shielding input #{value}")
            end
            locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/LocalShielding/Walls"
            h2kElements[locationText].attributes["code"] = value
          elsif( tag =~ /Opt-FlueShield/ && value != "NA" )
            if(value.to_f < 1 || value.to_f > 5)
              fatalerror("In #{choiceEntry}, invalid wall shielding input #{value}")
            end
            locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/LocalShielding/Flue"
            h2kElements[locationText].attributes["code"] = value
            #else
            #   if ( value == "NA" ) # Don't change anything
            #   else fatalerror("Missing H2K #{choiceEntry} tag:#{tag}") end
          end


          # Ceilings - All ceiling constructions
          # Note: UsrSpec R-values will change all ceilings regardless of construction type but code library
          # entries must match the code names that appear in code lib "Ceiling Codes" group or the
          #       "Flat or Cathedral Ceiling Codes" group.
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-Ceilings/ )
          if ( tag =~ /Opt-Ceiling/ && value != "NA" )
            # If this surface code name exists in the code library, use the code
            # (either Favourite or UsrDef) for ceiling and ceiling_flat groupings.
            # Code names in library are unique and split into two groups: "Ceiling Codes"
            # and "Flat or Cathedral Ceiling Codes" so the code name specified CAN ONLY EXIST
            # in one of these groups!
            # Note: Not using "Standard", non-library codes (e.g., 2221292000)

            foundCodeLibElement = nil
            useThisCodeID = "Code 99"

            foundCodeLibElement, useThisCodeID = findCeilingCodeInLibrary( h2kElements, h2kCodeElements, value )

            if foundCodeLibElement != nil
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
              # Code name not found in the code library!
              # Code missing or a User Specified R-value in OPT-H2K-EffRValue
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
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end


          # Attic Ceilings - All Attic/gable, Attic/Hip or Scissor ceiling constructions
          #-----------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-AtticCeilings/ )
          if ( tag =~ /Opt-Ceiling/ && value != "NA" )
            # If this surface code name exists in the code library, use the code
            # (either Favourite or UsrDef) for "Ceiling Codes" grouping.
            # Code names in library are unique.
            # Note: Not using "Standard", non-library codes (e.g., 2221292000)

            foundCodeLibElement = nil
            useThisCodeID = "Code 99"

            foundCodeLibElement, useThisCodeID = findCeilingCodeInLibrary( h2kElements, h2kCodeElements, value )

            if foundCodeLibElement != nil
              # Change all existing surface references of this type to useThisCodeID
              # NOTE: House ceiling components all under "Ceiling" tag - only <Codes>
              # section distinguishes between "Ceiling" and "CeilingFlat"
              locationText = "HouseFile/House/Components/Ceiling/Construction"
              h2kElements.each(locationText) do |element|
                # Check if construction type (element 1) is Attic/gable (2), Attic/hip (3) or Scissor (6)
                if element[1].attributes["code"] == "2" || element[1].attributes["code"] == "3" || element[1].attributes["code"] == "6"
                  # Check if each house entry has an "idref" attribute for CeilingType (element 3) and add if it doesn't.
                  if element[3].attributes["idref"] != nil
                    element[3].attributes["idref"] = useThisCodeID
                  else
                    element[3].add_attribute("idref", useThisCodeID)
                  end
                  element[3].text = value
                  element[3].attributes["nominalInsulation"] = foundCodeLibElement.attributes["nominalRValue"]
                end
              end
            else
              # Code name not found in the code library!
              # Code missing or a User Specified R-value in OPT-H2K-EffRValue
              # or NA in OPT-H2K-EffRValue
              debug_out(" INFO: Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}\n")
            end

          elsif ( tag =~ /OPT-H2K-EffRValue/ && value != "NA" )
            locationText = "HouseFile/House/Components/Ceiling/Construction"
            h2kElements.each(locationText) do |element|
              # Check if construction type (element 1) is Attic/gable (2), Attic/hip (3) or Scissor (6)
              if element[1].attributes["code"] == "2" || element[1].attributes["code"] == "3" || element[1].attributes["code"] == "6"
                element[3].text = "User specified"
                element[3].attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                if element[3].attributes["idref"] != nil then
                  # Must delete attribute for User Specified!
                  element[3].delete_attribute("idref")
                end
              end
            end
          elsif (tag =~ /OPT-H2K-HeelHeight/ && value != "NA")
            locationText = "HouseFile/House/Components/Ceiling/Measurements"
            h2kElements[locationText].attributes["heelHeight"] = value
          else
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end


          # Cathedral Ceilings - All Cathedral ceiling constructions
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-CathCeilings/ )
          if ( tag =~ /Opt-Ceiling/ && value != "NA" )
            # If this surface code name exists in the code library, use the code
            # (either Favourite or UsrDef) for "Flat or Cathedral Ceiling Codes" grouping.
            # Code names in library are unique.
            # Note: Not using "Standard", non-library codes (e.g., 2221292000)

            foundCodeLibElement = nil
            useThisCodeID = "Code 99"

            foundCodeLibElement, useThisCodeID = findCeilingCodeInLibrary( h2kElements, h2kCodeElements, value )

            if foundCodeLibElement != nil
              # Change all existing surface references of this type to useThisCodeID
              # NOTE: House ceiling components all under "Ceiling" tag - only <Codes>
              # section distinguishes between "Ceiling" and "CeilingFlat"
              locationText = "HouseFile/House/Components/Ceiling/Construction"
              h2kElements.each(locationText) do |element|
                # Check if construction type (element 1) is Cathedral (4)
                if element[1].attributes["code"] == "4"
                  # Check if each house entry has an "idref" attribute for CeilingType (element 3) and add if it doesn't.
                  if element[3].attributes["idref"] != nil
                    element[3].attributes["idref"] = useThisCodeID
                  else
                    element[3].add_attribute("idref", useThisCodeID)
                  end
                  element[3].text = value
                  element[3].attributes["nominalInsulation"] = foundCodeLibElement.attributes["nominalRValue"]
                end
              end
            else
              # Code name not found in the code library!
              # Code missing or a User Specified R-value in OPT-H2K-EffRValue
              # or NA in OPT-H2K-EffRValue
              debug_out(" INFO: Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}\n")
            end

          elsif ( tag =~ /OPT-H2K-EffRValue/ && value != "NA" )
            locationText = "HouseFile/House/Components/Ceiling/Construction"
            h2kElements.each(locationText) do |element|
              # Check if construction type (element 1) is Cathedral (4)
              if element[1].attributes["code"] == "4"
                element[3].text = "User specified"
                element[3].attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                if element[3].attributes["idref"] != nil then
                  # Must delete attribute for User Specified!
                  element[3].delete_attribute("idref")
                end
              end
            end
          else
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end


          # Flat Ceilings - All Flat ceiling constructions
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-FlatCeilings/ )
          if ( tag =~ /Opt-Ceiling/ && value != "NA" )
            # If this surface code name exists in the code library, use the code
            # (either Favourite or UsrDef) from the "Flat or Cathedral Ceiling Codes" grouping.
            # Code names in library are unique.
            # Note: Not using "Standard", non-library codes (e.g., 2221292000)

            foundCodeLibElement = nil
            useThisCodeID = "Code 99"

            foundCodeLibElement, useThisCodeID = findCeilingCodeInLibrary( h2kElements, h2kCodeElements, value )

            if foundCodeLibElement != nil
              # Change all existing surface references of this type to useThisCodeID
              # NOTE: House ceiling components all under "Ceiling" tag - only <Codes>
              # section distinguishes between "Ceiling" and "CeilingFlat"
              locationText = "HouseFile/House/Components/Ceiling/Construction"
              h2kElements.each(locationText) do |element|
                # Check if construction type (element 1) is Flat (5)
                if element[1].attributes["code"] == "5"
                  # Check if each house entry has an "idref" attribute for CeilingType (element 3) and add if it doesn't.
                  if element[3].attributes["idref"] != nil
                    element[3].attributes["idref"] = useThisCodeID
                  else
                    element[3].add_attribute("idref", useThisCodeID)
                  end
                  element[3].text = value
                  element[3].attributes["nominalInsulation"] = foundCodeLibElement.attributes["nominalRValue"]
                end
              end
            else
              # Code name not found in the code library!
              # Code missing or a User Specified R-value in OPT-H2K-EffRValue
              # or NA in OPT-H2K-EffRValue
              debug_out(" INFO: Code name: #{value} NOT in code library for H2K #{choiceEntry} tag:#{tag}\n")
            end

          elsif ( tag =~ /OPT-H2K-EffRValue/ && value != "NA" )
            locationText = "HouseFile/House/Components/Ceiling/Construction"
            h2kElements.each(locationText) do |element|
              # Check if construction type (element 1) is Flat (5)
              if element[1].attributes["code"] == "5"
                element[3].text = "User specified"
                element[3].attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                if element[3].attributes["idref"] != nil then
                  # Must delete attribute for User Specified!
                  element[3].delete_attribute("idref")
                end
              end
            end
          else
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
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

          elsif ( tag =~ /Opt-MainWall-Bri/ )
            # Do nothing
          elsif ( tag =~ /Opt-MainWall-Vin/ )
            # Do nothing
          elsif ( tag =~ /Opt-MainWall-Dry/ )
            # Do nothing
          else
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end


          # Generic wall insulation thickness settings: - one layer
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-GenericWall_1Layer_definitions/ )
          if ( tag =~ /OPT-H2K-EffRValue/i && value != "NA" )
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

          # Floor header User-Specified R-values
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-FloorHeaderIntIns/ )

          debug_out ("Opt-FloorHeaderIntIns: Header insulation - internal only  = #{value} \n")
          if ( tag =~ /FloorHeaderIntIns_Eff_RValue/ && value != "NA" )
            debug_out ("interior cavity R value specified\n")
            headerIntInsReff = value.to_f

            # Check to see if wall insulation definitions include R value for exterior sheathing
            wallChoice = $gChoices["Opt-GenericWall_1Layer_definitions"]
            debug_out "Checking to see if wall def #{wallChoice} sets header R value\n"

            wallResults =  HTAPData.getResultsForChoice($gOptions,"Opt-GenericWall_1Layer_definitions",wallChoice)

            headerExtInsReff = 0.0
            if ( ! wallResults["HeaderExtInsRValue"].nil? &&  wallResults["HeaderExtInsRValue"].to_f > 0.01 )
              headerExtInsReff = wallResults["HeaderExtInsRValue"].to_f
              info_out ("Floor Header: Wall spec #{wallChoice} includes exterior insulation. Adding R-#{headerExtInsReff.round(1)} to floor header.")
            end

            # ------------------------------------------------------------------------------
            # Also check to see if air-tightness requirements include option to sprayfoam rim joists, and
            # add insulaiton accordingly.

            achChoice = $gChoices["Opt-ACH"]

            debug_out "Checking to see if ACH spec #{achChoice} includes sprayfoaming rim joists"

            # query costing components
            achCostComponents = Hash.new
            achCostComponents = Costing.getCostComponentList($gOptions,$gChoices,"Opt-ACH",achChoice)

            debug_out ("Cost components for OPT-ACH = #{achChoice}:\n #{achCostComponents.pretty_inspect}")



            incSprayFoam = false
            sprayfoamcomponent = ""
            achCostComponents.each do | component |
              debug_out ("? sprayfoam in #{component}\n")
              if (component =~ /sprayfoam/i && ( component =~ /rim[_| ]?joist/i || component =~ /floorm[_| ]?header/i ) ) then
                debug_out "  Yes - add 1.5in spray foam to header R-value"
                sprayfoamcomponent = component
                incSprayFoam = true
              end
              break if incSprayFoam
            end

            if ( incSprayFoam )
              headerSprayfoamREff = 1.5 * 6.0
              info_out ("Floor Header: airsealing spec #{achChoice} includes spray foam of floor headers [#{sprayfoamcomponent}]. Adding R-#{headerSprayfoamREff.round(1)} to floor header.")
            else
              headerSprayfoamREff = 0
            end


            headerREff = headerExtInsReff + headerIntInsReff + headerSprayfoamREff


            # Change ALL existing floor headers codes to User Specified R-value
            # Should it be different for the main floors and basement??
            locationText = "HouseFile/House/Components/*/Components/FloorHeader/Construction/Type"
            h2kElements.each(locationText) do |element|
              debug_out "Setting R-value to #{headerREff } (#{(headerREff  / R_PER_RSI).round(2).to_s} RSI)\n"
              element.text = "User specified"
              element.attributes["rValue"] = (headerREff / R_PER_RSI).to_s
              if element.attributes["idref"] != nil then
                # Must delete attribute for User Specified!
                element.delete_attribute("idref")
              end
            end
          end

          # Floor header User-Specified R-values
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-ExposedFloor/ )
          if ( tag =~ /OPT-H2K-CodeName/ &&  value != "NA" && value != "")

            if ( h2kElements["HouseFile/House/Components/Crawlspace"] != nil &&
              ! H2KFile.heatedCrawlspace(h2kElements) ) then
              warn_out ("Opt-ExposedFloor definition uses codes (`OPT-H2K-CodeName`==`#{value}`) & house also " +
              "includes unheated crawlspaces. Floors above unheated crawlspaces cannot be set using code "+
              "defintions. Use OPT-H2K-EffRValue instead. (run with --hints for more info).")

              help_out("byOptions", "Opt-ExposedFloor")

            end
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

            # 1) Exposed floors - Overhangs, floors above garages, ect...
            locationText = "HouseFile/House/Components/Floor/Construction/Type"
            h2kElements.each(locationText) do |element|
              element.text = "User specified"
              element.attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
              if element.attributes["idref"] != nil then
                # Must delete attribute for User Specified!
                element.delete_attribute("idref")
              end
            end

            # 2) Floors above unheated / vented / open crawlspaces
            if ( h2kElements["HouseFile/House/Components/Crawlspace"] != nil &&
              ! H2KFile.heatedCrawlspace(h2kElements) )

              locationText = "HouseFile/House/Components/Crawlspace/Floor/Construction/FloorsAbove"
              h2kElements.each(locationText) do |element|
                element.text = "User specified"
                # Description tag
                element.attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                if element.attributes["idref"] != nil then
                  # Must delete attribute for User Specified!
                  element.delete_attribute("idref")
                end
              end
              #
              #
            end



          elsif ( choiceEntry =~ /Opt-FloorAboveCrawl/ )
            # If there is a crawlspace and an R-value has been specified for the floor above the crawlspace, update
            if ( tag =~ /OPT-H2K-EffRValue/ &&  value != "NA" && h2kElements["HouseFile/House/Components/Crawlspace"] != nil)

            end



          else
            if ( value == "NA" or value == "" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end


          # Windows (by facing direction)
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-CasementWindows/ )
          if ( tag =~ /Opt-win-\*-CON/ &&  value != "NA" )
            ChangeWinCodeByOrient( "S", value, h2kCodeElements, h2kElements, choiceEntry, tag )
            ChangeWinCodeByOrient( "E", value, h2kCodeElements, h2kElements, choiceEntry, tag )
            ChangeWinCodeByOrient( "N", value, h2kCodeElements, h2kElements, choiceEntry, tag )
            ChangeWinCodeByOrient( "W", value, h2kCodeElements, h2kElements, choiceEntry, tag )
            ChangeWinCodeByOrient( "SE", value, h2kCodeElements, h2kElements, choiceEntry, tag )
            ChangeWinCodeByOrient( "SW", value, h2kCodeElements, h2kElements, choiceEntry, tag )
            ChangeWinCodeByOrient( "NE", value, h2kCodeElements, h2kElements, choiceEntry, tag )
            ChangeWinCodeByOrient( "NW", value, h2kCodeElements, h2kElements, choiceEntry, tag )
          elsif ( tag =~ /Opt-win-S-CON/ &&  value != "NA" )
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

          else
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end


          # Skylights - windows in ceilings
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-Skylights/ )
          if ( tag =~ /Opt-win-S-CON/ &&  value != "NA" )
            ChangeSkylightCodeByOrient( "S", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-E-CON/ &&  value != "NA" )
            ChangeSkylightCodeByOrient( "E", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-N-CON/ &&  value != "NA" )
            ChangeSkylightCodeByOrient( "N", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-W-CON/ &&  value != "NA" )
            ChangeSkylightCodeByOrient( "W", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-SE-CON/ &&  value != "NA" )
            ChangeSkylightCodeByOrient( "SE", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-SW-CON/ &&  value != "NA" )
            ChangeSkylightCodeByOrient( "SW", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-NE-CON/ &&  value != "NA" )
            ChangeSkylightCodeByOrient( "NE", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-NW-CON/ &&  value != "NA" )
            ChangeSkylightCodeByOrient( "NW", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          else
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end


          # Windows in doors
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-DoorWindows/ )
          if ( tag =~ /Opt-win-S-CON/ &&  value != "NA" )
            ChangeDoorWinCodeByOrient( "S", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-E-CON/ &&  value != "NA" )
            ChangeDoorWinCodeByOrient( "E", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-N-CON/ &&  value != "NA" )
            ChangeDoorWinCodeByOrient( "N", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-W-CON/ &&  value != "NA" )
            ChangeDoorWinCodeByOrient( "W", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-SE-CON/ &&  value != "NA" )
            ChangeDoorWinCodeByOrient( "SE", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-SW-CON/ &&  value != "NA" )
            ChangeDoorWinCodeByOrient( "SW", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-NE-CON/ &&  value != "NA" )
            ChangeDoorWinCodeByOrient( "NE", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          elsif ( tag =~ /Opt-win-NW-CON/ &&  value != "NA" )
            ChangeDoorWinCodeByOrient( "NW", value, h2kCodeElements, h2kElements, choiceEntry, tag )

          else
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end


          # Doors - set all doors to User Specified
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-Doors/ )
          if ( tag =~ /Opt-R-value/ && value != "NA" )
            locationText = "HouseFile/House/Components/*/Components/Door/Construction/Type"
            h2kElements.each(locationText) do |element|
              element.attributes["code"] = 8
              element.attributes["value"] = (value.to_f / R_PER_RSI).to_s
            end
          end


          # Foundations
          #  - All types: Basement, Walkout, Crawlspace, Slab-On-Grade
          #  - Interior & Exterior wall insulation, below slab insulation
          #    based on insulation configuration type
          #--------------------------------------------------------------------------

        elsif ( choiceEntry == "Opt-H2KFoundation" )
          locHouseStr = [ "", "" ]

          if ( tag =~ /OPT-H2K-ConfigType/ &&  value != "NA" )
            # Set the configuration type for the foundation types specified in choice file
            if ( fndTypes == "B" )
              locHouseStr[0] = "HouseFile/House/Components/Basement/Configuration"
            elsif ( fndTypes == "W" )
              locHouseStr[0] = "HouseFile/House/Components/Walkout/Configuration"
            elsif ( fndTypes == "C" )
              locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Configuration"
            elsif ( fndTypes == "S" )
              locHouseStr[0] = "HouseFile/House/Components/Slab/Configuration"
            elsif ( fndTypes == "ALL" )
              # Check to AVOID:
              # - configurations that start with "B" cannot modify configurations starting with C or S!
              # - configurations that start with "S" cannot modify configurations starting with B or W AND
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
                  # Use the existing configuration type to determine if a new XML section is required
                  existConfigType = element.attributes["type"]
                  if ( existConfigType.match('N', 3) && !configType.match('N', 3) )
                    # Add missing XML section to Floor for "AddedToSlab"
                    addMissingAddedToSlab(locStr[27], element)
                  end
                  if ( existConfigType.match('E', 2) && !configType.match('E', 2) )
                    # Add missing XML section to Wall for "InteriorAddedInsulation"
                    addMissingInteriorAddedInsulation(element)
                  end
                  if ( existConfigType.match('I', 2) && !configType.match('I', 2) )
                    # Add missing XML section to Wall for "ExteriorAddedInsulation"
                    addMissingExteriorAddedInsulation(element)
                  end
                  # Change existing configuration values to match choice
                  element.attributes["type"] = configType
                  element.attributes["subtype"] = configSubType
                  element.text = configType + "_" + configSubType
                end
              end
            end

          elsif ( tag =~ /OPT-H2K-IntWallCode/ &&  value != "NA" )
            # If this code name exists in the code library, use the code
            # (either Favorite or UsrDef) for all entries. Code names in library are unique.
            # Note: *Not* using "Standard", non-library codes (e.g., 2221292000)

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
                  break if thisCodeInHouse
                  # break Fav/UsrDef loop if found
                end
                break if thisCodeInHouse
                # break fnd type loop if found
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
                    element[1].text = value
                    # Description tag
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
                  element.text = "User specified"
                  # Description tag
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
                  element.text = "User specified"
                  # Description tag
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
                  element.text = "User specified"
                  # Description tag
                  element.attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                  if element.attributes["code"] != nil then
                    # Must delete attribute for User Specified!
                    element.delete_attribute("code")
                  end
                end
              end
            end

          else
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end


          # Slab or Crawl Foundations
          #  - Types: Slab-On-Grade or Crawlspace only
          #  - Interior & Exterior wall insulation, below slab insulation
          #    based on insulation configuration type
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-H2KFoundationSlabCrawl/ )
          locHouseStr = [ "", "" ]

          if ( tag =~ /OPT-H2K-ConfigType/ &&  value != "NA" )
            # Set the configuration type for the foundation types specified in choice file
            if ( fndTypes2 == "C" )
              locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Configuration"
            elsif ( fndTypes2 == "S" )
              locHouseStr[0] = "HouseFile/House/Components/Slab/Configuration"
            elsif ( fndTypes2 == "ALL" )
              locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Configuration"
              locHouseStr[1] = "HouseFile/House/Components/Slab/Configuration"
            end
            locHouseStr.each do |locStr|
              if ( locStr != "" )
                h2kElements.each(locStr) do |element|
                  # Use the existing configuration type to determine if a new XML section is required
                  existConfigType = element.attributes["type"]
                  if ( existConfigType.match('N', 2) && !configType2.match('N', 2) )
                    # Add missing XML section to Floor for "AddedToSlab"
                    addMissingAddedToSlab(locStr[27], element)
                  end
                  # Change existing configuration values to match choice
                  element.attributes["type"] = configType2
                  element.attributes["subtype"] = configSubType2
                  element.text = configType + "_" + configSubType2
                end
              end
            end

          elsif ( tag =~ /OPT-H2K-CrawlWallCode/ &&  value != "NA" )
            # If this code name exists in the code library, use the code
            # (either Favorite or UsrDef) for all entries. Code names in library are unique.
            # Note: *Not* using "Standard", non-library codes (e.g., 2221292000)

            # Look for this code name in code library (Favorite and UserDefined)
            thisCodeInHouse = false
            useThisCodeID = "Code 210"
            foundFavLibCode = false
            foundUsrDefLibCode = false
            foundCodeLibElement = ""
            # Note: Both Basement and Walkout interior wall codes saved under "BasementWall"
            fndWallNum = 0
            locationCodeFavText = "Codes/CrawlspaceWall/Favorite/Code"
            h2kCodeElements.each(locationCodeFavText) do |codeElement|
              if ( codeElement.get_text("Label") == value )
                foundFavLibCode = true
                foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                break
              end
            end
            # Code library names are unique so also check User Defined codes
            if ( ! foundFavLibCode )
              locationCodeUsrDefText = "Codes/CrawlspaceWall/UserDefined/Code"
              h2kCodeElements.each(locationCodeUsrDefText) do |codeElement|
                if ( codeElement.get_text("Label") == value )
                  foundUsrDefLibCode = true
                  foundCodeLibElement = Marshal.load(Marshal.dump(codeElement))
                  break
                end
              end
            end
            locStr = ""
            locTextArr2 = [ "Favorite", "UserDefined" ]
            if ( foundFavLibCode || foundUsrDefLibCode )
              # Check to see if this code is already used in H2K file and add, if not.
              # Code references are in the <Codes> section. Avoid duplicates!
              locTextArr2.each do |favOrUsrDefTxt|
                locStr = "HouseFile/Codes/CrawlspaceWall/#{favOrUsrDefTxt}/Code"
                h2kElements.each(locStr) do |element|
                  if ( element.get_text("Label") == value )
                    thisCodeInHouse = true
                    useThisCodeID = element.attributes["id"]
                    break
                  end
                end
                break if thisCodeInHouse
                # break Fav/UsrDef loop if found
              end
              if ( ! thisCodeInHouse )
                locStr = "HouseFile/Codes/CrawlspaceWall"
                if ( h2kElements[locStr] == nil )
                  # No section of this type in house file Codes section -- add it!
                  h2kElements["HouseFile/Codes"].add_element("CrawlspaceWall")
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
              if ( fndTypes2 == "C" || ( fndTypes2 == "ALL" && configType2 =~ /^S/ ) )
                locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Wall/Construction/Type"
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
                    element[1].text = value
                    # Description tag
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

          elsif ( tag =~ /OPT-H2K-CrawlWall-RValue/ &&  value != "NA" )
            # Change ALL existing interior wall codes to User Specified R-value
            locHouseStr = [ "", "" ]
            if ( fndTypes2 == "C" || ( fndTypes2 == "ALL" && configType2 =~ /^S/ ) )
              locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Wall/Construction/Type"
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
                  element.text = "User specified"
                  # Description tag
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
            if ( fndTypes2 == "C" )
              locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Floor/Construction/AddedToSlab"
            elsif ( fndTypes2 == "S" )
              locHouseStr[0] = "HouseFile/House/Components/Slab/Floor/Construction/AddedToSlab"
            elsif ( fndTypes2 == "ALL")
              locHouseStr[0] = "HouseFile/House/Components/Crawlspace/Floor/Construction/AddedToSlab"
              locHouseStr[1] = "HouseFile/House/Components/Slab/Floor/Construction/AddedToSlab"
            end
            locHouseStr.each do |locationString|
              if ( locationString != "" )
                h2kElements.each(locationString) do |element|
                  element.text = "User specified"
                  # Description tag
                  element.attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
                  if element.attributes["code"] != nil then
                    # Must delete attribute for User Specified!
                    element.delete_attribute("code")
                  end
                end
              end
            end

          else
            if ( value == "NA" )
              # Don't change anything
            else
              fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
            end
          end

          # Floor above crawlspace
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-FloorAboveCrawl/ )
          # If there is a crawlspace and an R-value has been specified for the floor above the crawlspace, update
          if ( tag =~ /OPT-H2K-EffRValue/ &&  value != "NA" && h2kElements["HouseFile/House/Components/Crawlspace"] != nil)
            locationText = "HouseFile/House/Components/Crawlspace/Floor/Construction/FloorsAbove"
            h2kElements.each(locationText) do |element|
              element.text = "User specified"
              # Description tag
              element.attributes["rValue"] = (value.to_f / R_PER_RSI).to_s
              if element.attributes["idref"] != nil then
                # Must delete attribute for User Specified!
                element.delete_attribute("idref")
              end
            end
          end

          # DHW System
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-DHWSystem/ )
          if ( tag =~ /Opt-H2K-Fuel/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary"
            if ( h2kElements[locationText].attributes["pilotEnergy"] == nil )
              if ( value != 1 )
                # Not electricity
                h2kElements[locationText].add_attribute("pilotEnergy", "0")
              end
            else
              if ( value == 1 )
                # Electricity
                h2kElements[locationText].delete_attribute("pilotEnergy")
              end
            end

            locationText = "HouseFile/House/Components/HotWater/Primary/EnergySource"
            h2kElements[locationText].attributes["code"] = value

          elsif ( tag =~ /Opt-H2K-TankType/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/TankType"
            if ( value.to_i == 4 || value.to_i == 5 || value.to_i == 6 || value.to_i == 12 )
              optDHWTankSize = "7"
              # Set to "Not Applicable" for 4:Tankless, 5:Instantaneous, 12:Instantaneous (condensing), 6:Instantaneous (pilot) or get core message
            else
              optDHWTankSize = "1"
              # User Specified
            end
            h2kElements[locationText].attributes["code"] = value

          elsif ( tag =~ /Opt-H2K-TankSize/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/TankVolume"
            h2kElements[locationText].attributes["code"] = optDHWTankSize
            # See above for tank type!
            h2kElements[locationText].attributes["value"] = value
            # Volume in Lites

          elsif ( tag =~ /Opt-H2K-EF/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/EnergyFactor"
            h2kElements[locationText].attributes["code"] = 2
            # User Specified option
            h2kElements[locationText].attributes["value"] = value
            # EF value (fraction)

          elsif ( tag =~ /Opt-H2K-FlueDiameter/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary"
            h2kElements[locationText].attributes["flueDiameter"] = value

          elsif ( tag =~ /Opt-H2K-IntHeatPumpCOP/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary"
            # This attribute only exists for an *Integrated* Heat Pump
            h2kElements[locationText].attributes["heatPumpCoefficient"] = value
            # COP of integrated HP
          end

          # DWHR System (includes DWHR options for internal H2K model. Don't use
          #              both external (explicit) method AND this one!)
          # DWHR inputs in the DHW section are available for change ONLY if the Base Loads input
          # "User Specified Electrical and Water Usage" input is checked. If this is not checked, then
          # changes made here will be overwritten by the Base Loads user inputs for Water Usage.
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-DWHRSystem/ )
          if ( tag =~ /Opt-H2K-HasDWHR/ &&  value != "NA" )
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
            h2kElements[locationText].attributes["hasDrainWaterHeatRecovery"] = value
            # Flag for DWHR

          elsif ( tag =~ /Opt-H2K-DWHR-showerLength/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery"
            h2kElements[locationText].attributes["showerLength"] = value
            # Shower length in minutes (float)

          elsif ( tag =~ /Opt-H2K-DWHR-dailyShowers/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery"
            h2kElements[locationText].attributes["dailyShowers"] = value
            # Number of daily showers (float)

          elsif ( tag =~ /Opt-H2K-DWHR-preheatShowerTank/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery"
            h2kElements[locationText].attributes["preheatShowerTank"] = value
            # true or false

            # Can't modify DWHR Effectiveness rating at 9.5 l/min directly. It is precalculated based on
            # manufacturer name and model (core overrides this value with a calculation)! See Effectiveness6.xls
          elsif ( tag =~ /Opt-H2K-DWHR-Manufacturer/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/EquipmentInformation/Manufacturer"
            h2kElements[locationText].text = value
            # DWHR Manufacturer

          elsif ( tag =~ /Opt-H2K-DWHR-Model/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/EquipmentInformation/Model"
            h2kElements[locationText].text = value
            # DWHR Model

            # THIS DOESN"T APPEAR TO DO ANYTHING! *********************************
          elsif ( tag =~ /Opt-H2K-DWHR-Efficiency_code/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/Efficiency"
            h2kElements[locationText].attributes["code"] = value
            # DWHR Efficiency code (1, 2 or 3)

            # ASF 05-10-2016- this tag controls effectiveness
          elsif ( tag =~ /Opt-H2K-DWHR-Effectiveness9p5/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery"
            h2kElements[locationText].attributes["effectivenessAt9.5"] = value
            # P.55 test result (0->100)

          elsif ( tag =~ /Opt-H2K-DWHR-ShowerTemperature_code/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/ShowerTemperature"
            h2kElements[locationText].attributes["code"] = value
            # DWHR Shower temperature code (1:Cool, 2:Warm or 3:Hot)

          elsif ( tag =~ /Opt-H2K-DWHR-ShowerHead_code/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/ShowerHead"
            h2kElements[locationText].attributes["code"] = value
            # DWHR Showerhead code (0, 1, 2, 3 or 4)

          end


          # Heating & Cooling Systems (Type 1 & 2)
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-HVACSystem/ )

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
              # System type 1 is already set to this value -- do nothing (here)!
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

                  # If fuel is NG/Propane/Oil/wood, make sure there is a non-zero flue size.
                  # This can happen when switching fuel from electricity. Skip check for P9.
                  if value != "1" && sysType1Name != "P9"
                    locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Specifications"
                    if h2kElements[locationText].attributes["flueDiameter"].to_i == 0
                      h2kElements[locationText].attributes["flueDiameter"] = "127"
                      #mm
                    end
                  end
                end
              end
            end

          elsif ( tag =~ /Opt-H2K-Type1EqpType/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name != "Baseboards" && sysType1Name != "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Equipment/EquipmentType"
              else
                locationText = "SkipThis"
              end
              if ( h2kElements[locationText] != nil )
                h2kElements[locationText].attributes["code"] = value
                # 28-Dec-2016 JTB: If the energy source is one of the 4 woods and the equipment type is
                # NOT a conventional fireplace, add the "EPA/CSA" attribute field in the
                # EquipmentInformation section to avoid a crash!
                locationText2 = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Equipment/EnergySource"
                if ( h2kElements[locationText2].attributes["code"].to_i > 4 && value != "8" )
                  locationText2 = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/EquipmentInformation"
                  h2kElements[locationText2].attributes["epaCsa"] = "false"
                end
              end
            end

          elsif ( tag =~ /Opt-H2K-Type1CapOpt/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name != "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Specifications/OutputCapacity"
              else
                # JTB 05-Feb-2017 - There is no capacity sizing option for P9 systems in GUI.
                # but we've provided this option in the HTAP options file for this parameter!
                # Handle this in Opt-H2K-Type1CapVal (next code block).
                locationText = "SkipThis"
              end
              if ( h2kElements[locationText] != nil )
                h2kElements[locationText].attributes["code"] = value
              end
            end

          elsif ( tag =~ /Opt-H2K-Type1CapVal/ && "#{value}" != "" )
            # Allowing "NA" value here for P9 autosize option!
            sysType1.each do |sysType1Name|
              if ( sysType1Name != "P9" && value != "NA" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Specifications/OutputCapacity"
                h2kElements[locationText].attributes["value"] = value if ( h2kElements[locationText] != nil )
              else
                # JTB 06-Feb-2017 - P9 capacity: Allowing option 2 (Calculated) even though not available in H2K GUI!
                # When this case is specified in the options file, use base system heating capacity. Also set burner
                # input parameter further down in this code.
                locationText = "HouseFile/House/HeatingCooling/Type1/P9"
                if ( value == "NA" )
                  # Happens when options file user specifies "Calculated" for sizing option!
                  h2kElements[locationText].attributes["spaceHeatingCapacity"] = baseHeatSysCap.to_s if ( h2kElements[locationText] != nil )
                else
                  h2kElements[locationText].attributes["spaceHeatingCapacity"] = value if ( h2kElements[locationText] != nil )
                end
              end

            end

          elsif ( tag =~ /Opt-H2K-Type1EffType/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name != "P9" && sysType1Name != "Baseboards" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/Specifications"
              else
                # ASF 07-Oct-2016  Not needed for P9 ?
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
                h2kElements[locationText].attributes["efficiency"] = value if ( h2kElements[locationText] != nil )
              elsif (sysType1Name == "P9")
                # ASF 07-Oct-2016  Mapped to P9 spaceHeatingEfficiency attribute
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}"
                h2kElements[locationText].attributes["spaceHeatingEfficiency"] = value if ( h2kElements[locationText] != nil )
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
                  if ( sysType2Name == "AirHeatPump" )
                    locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Equipment/Type"
                  else
                    locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Equipment/Function"
                  end
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

              elsif ( sysType2Name == "AirConditioning" )
                locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                if ( h2kElements[locationText] != nil )
                  locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Specifications/RatedCapacity"
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

              elsif  ( sysType2Name == "AirConditioning")
                locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                if ( h2kElements[locationText] != nil )
                  locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Specifications/RatedCapacity"
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
                  h2kElements[locationText].attributes["isCop"] = "true"
                  h2kElements[locationText].attributes["value"] = value
                end
              end
            end

            # Possibly set the rating temperature
          elsif ( tag =~ /Opt-H2K-Type2RatingTemp/ && value != "NA"  && "#{value}" != "" )
            sysType2.each do |sysType2Name|
              if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump")
                locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                if ( h2kElements[locationText] != nil )
                  locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Temperature/RatingType"
                  h2kElements[locationText].attributes["code"] = "3"
                  h2kElements[locationText].attributes["value"] = value
                end
              end
            end


          elsif ( tag =~ /Opt-H2K-Type2CoolCOP/ && value != "NA"  && "#{value}" != "" )
            sysType2.each do |sysType2Name|
              if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump" )
                locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                if ( h2kElements[locationText] != nil )
                  locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Specifications/CoolingEfficiency"
                  h2kElements[locationText].attributes["isCop"] = "true"
                  h2kElements[locationText].attributes["value"] = value
                end

              elsif ( sysType2Name == "AirConditioning" )
                locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}"
                if ( h2kElements[locationText] != nil )
                  locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Specifications/Efficiency"
                  h2kElements[locationText].attributes["isCop"] = "true"
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


            # Possibly set window characteristics / cooling types

          elsif ( tag =~ /Opt-H2K-CoolOperWindow/ && value != "NA"  && "#{value}" != "" )
            sysType2.each do |sysType2Name|
              if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "AirConditioning"  )
                locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/CoolingParameters"
                if ( h2kElements[locationText] != nil )
                  h2kElements[locationText].attributes["openableWindowArea"] = value
                end
              end
            end

          elsif ( tag =~ /Opt-H2K-CoolSpecType/ && value != "NA"  && "#{value}" != "" )
            sysType2.each do |sysType2Name|
              if ( sysType2Name == "AirHeatPump" || sysType2Name == "WaterHeatPump" || sysType2Name == "GroundHeatPump")
                if ( "#{value}" != "COP" ) then

                  result = "false"

                else

                  result = "true"

                end

                locationText = "HouseFile/House/HeatingCooling/Type2/#{sysType2Name}/Specifications/CoolingEfficiency"

                if ( h2kElements[locationText] != nil )
                  h2kElements[locationText].attributes["isCop"] = result
                end
              end
            end


            # ASF 06-Oct-2016 - Tags for P.9 performance start here.

          elsif ( tag =~ /Opt-H2K-P9-manufacturer/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/EquipmentInformation/Manufacturer"
                h2kElements[locationText].text = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-model/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/EquipmentInformation/Model"
                h2kElements[locationText].text = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-TPF/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}"
                h2kElements[locationText].attributes["thermalPerformanceFactor"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-AnnualElec/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}"
                h2kElements[locationText].attributes["annualElectricity"] = value if ( h2kElements[locationText] != nil )
              end
            end


          elsif ( tag =~ /Opt-H2K-P9-WHPF/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}"
                h2kElements[locationText].attributes["waterHeatingPerformanceFactor"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-burnerInput/ )
            # 06-Feb-2017 JTB: Removed "NA" check to allow for "Calculated" option
            sysType1.each do |sysType1Name|
              locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}"
              if ( sysType1Name == "P9" )
                if ( value == "NA" )
                  # 06-Feb-2017 JTB: Rough estimation of burner input as 2.5 x baseHeatSysCap. Note that the actual burner input depends on
                  # both the space heating capacity and the size of the DHW tank and can vary from a factor of about 2.x to 5.x!
                  # This is part of the option of allowing P9 system capacities to be set to "Calculated" in the options file
                  # even though the H2K GUI does not have this option!
                  h2kElements[locationText].attributes["burnerInput"] = (2.5 * baseHeatSysCap).to_s if ( h2kElements[locationText] != nil )
                else
                  h2kElements[locationText].attributes["burnerInput"] = value if ( h2kElements[locationText] != nil )
                end
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-recEff/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}"
                h2kElements[locationText].attributes["recoveryEfficiency"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-ctlsPower/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData"
                h2kElements[locationText].attributes["controlsPower"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-circPower/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData"
                h2kElements[locationText].attributes["circulationPower"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-dailyUse/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData"
                h2kElements[locationText].attributes["dailyUse"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-stbyLossNoFan/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData"
                h2kElements[locationText].attributes["standbyLossWithoutFan"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-stbyLossWFan/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData"
                h2kElements[locationText].attributes["standbyLossWithFan"] = value if ( h2kElements[locationText] != nil )
              end
            end


          elsif ( tag =~ /Opt-H2K-P9-oneHrHotWater/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData"
                h2kElements[locationText].attributes["oneHourRatingHotWater"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-oneHourConc/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData"
                h2kElements[locationText].attributes["oneHourConc"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-netEff15/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData/NetEfficiency"
                h2kElements[locationText].attributes["loadPerformance15"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-netEff40/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData/NetEfficiency"
                h2kElements[locationText].attributes["loadPerformance40"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-netEff100/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData/NetEfficiency"
                h2kElements[locationText].attributes["loadPerformance100"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-elecUse15/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData/ElectricalUse"
                h2kElements[locationText].attributes["loadPerformance15"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-elecUse40/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData/ElectricalUse"
                h2kElements[locationText].attributes["loadPerformance40"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-elecUse100/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData/ElectricalUse"
                h2kElements[locationText].attributes["loadPerformance100"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-blowPower15/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData/BlowerPower"
                h2kElements[locationText].attributes["loadPerformance15"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-blowPower40/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData/BlowerPower"
                h2kElements[locationText].attributes["loadPerformance40"] = value if ( h2kElements[locationText] != nil )
              end
            end

          elsif ( tag =~ /Opt-H2K-P9-blowPower100/ &&  value != "NA" )
            sysType1.each do |sysType1Name|
              if ( sysType1Name == "P9" )
                locationText = "HouseFile/House/HeatingCooling/Type1/#{sysType1Name}/TestData/BlowerPower"
                h2kElements[locationText].attributes["loadPerformance100"] = value if ( h2kElements[locationText] != nil )
              end
            end

          end
          # END of elsif under HVACSystem section

          # HRV Ventilation System
          # Note: This option will remove all other ventilation systems
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-HRVonly/ )
          if(valHash["1"] == "false")
            # Option not active, skip
            break
          elsif(valHash["1"] == "true")
            # Option is active
            # Delete all existing systems
            locationText = "HouseFile/House/Ventilation/"
            h2kElements[locationText].delete_element("WholeHouseVentilatorList")
            h2kElements[locationText].delete_element("SupplementalVentilatorList")

            # Make fresh elements
            h2kElements[locationText].add_element("WholeHouseVentilatorList")
            h2kElements[locationText].add_element("SupplementalVentilatorList")

            # Construct the HRV input framework
            createHRV(h2kElements)

            # Set the ventilation code requirement to 4 (Not applicable)
            h2kElements[locationText + "Requirements/Use"].attributes["code"] = "4"

            # Set the air distribution type
            h2kElements[locationText + "WholeHouse/AirDistributionType"].attributes["code"] = valHash["2"]

            # Set the operation schedule
            h2kElements[locationText + "WholeHouse/OperationSchedule"].attributes["code"] = "0"
            # User Specified
            h2kElements[locationText + "WholeHouse/OperationSchedule"].attributes["value"] = valHash["3"]

            # Determine flow calculation
            calcFlow = 0
            if(valHash["4"] == "2")
              # The flow rate is supplied
              h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["supplyFlowrate"] = valHash["5"]
              # L/s supply
              h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["exhaustFlowrate"] = valHash["5"]
              # Exhaust = Supply
              calcFlow = valHash["5"].to_f
            elsif(valHash["4"] == "1")
              # The flow rate is calculated using F326
              calcFlow = getF326FlowRates(h2kElements)
              if(calcFlow < 1)
                fatalerror("ERROR: For Opt-HRVonly, could not calculate F326 flow rates!\n")
              else
                h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["supplyFlowrate"] = calcFlow.to_s
                # L/s supply
                h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["exhaustFlowrate"] = calcFlow.to_s
                # Exhaust = Supply
              end
            else
              fatalerror("ERROR: For Opt-HRVonly, invalid flow calculation input  #{valHash["4"]}!\n")
            end

            # Update the HRV efficiency
            h2kElements[locationText  + "WholeHouseVentilatorList/Hrv"].attributes["efficiency1"] = valHash["6"]
            # Rating 1 Efficiency
            h2kElements[locationText  + "WholeHouseVentilatorList/Hrv"].attributes["efficiency2"] = valHash["7"]
            # Rating 2 Efficiency
            h2kElements[locationText  + "WholeHouseVentilatorList/Hrv"].attributes["coolingEfficiency"] = valHash["8"]
            # Rating 3 Efficiency

            # Determine fan power calculation
            if(valHash["9"] == "default")
              h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["isDefaultFanpower"] = "true"
              # Let HOT2000 calculate the fan power
            elsif(valHash["9"] == "specified")
              h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["isDefaultFanpower"] = "false"
              # Specify the fan power
              h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["fanPower1"] =  valHash["10"]
              # Supply the fan power at operating point 1 [W]
              h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["fanPower2"] =  valHash["11"]
              # Supply the fan power at operating point 2 [W]
            elsif(valHash["9"] == "NBC")
              h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["isDefaultFanpower"] = "false"
              # Specify the fan power
              # Determine fan power from flow rate as stated in 9.36.5.11(14a)
              fanPower = calcFlow*2.32
              fanPower = sprintf("%0.2f", fanPower)
              # Format to two decimal places

              # Assume same fan power for all temperatures
              h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["fanPower1"] =  fanPower
              # Supply the fan power at operating point 1 [W]
              h2kElements[locationText + "WholeHouseVentilatorList/Hrv"].attributes["fanPower2"] =  fanPower
              # Supply the fan power at operating point 2 [W]
            else
              fatalerror("ERROR: For Opt-HRVonly, unknown fan power calculation input  #{valHash["9"]}!\n")
            end
          else
            fatalerror("ERROR: For Opt-HRVonly, unknown active input  #{valHash["1"]}!\n")
          end

          break

          # HRV System
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-HRVspec/ )
          if ( tag =~ /OPT-H2K-FlowReq/ &&  value != "NA" )
            locationText = "HouseFile/House/Ventilation/Requirements/Use"
            h2kElements[locationText].attributes["code"] = value

            roomLabels = [ "living", "bedrooms", "bathrooms", "utility", "otherHabitable" ]
            numRooms = 0
            $FanFlow = 0
            locationText = "HouseFile/House/Ventilation/Rooms"
            roomLabels.each do |roommName|
              numRooms += h2kElements[locationText].attributes[roommName].to_i
              $FanFlow += h2kElements[locationText].attributes[roommName].to_i
              if roommName =~ /bedrooms/
                $FanFlow += h2kElements[locationText].attributes[roommName].to_i
              end
            end
            if ( value == "1" && numRooms == 0 )
              debug_out("Choice: #{choiceEntry} Tag: #{tag} \n  No rooms entered for F326 Ventilation requirement!")
            end

            if (value == "1" && h2kElements[locationText].attributes["living"].to_i < 3)
              h2kElements[locationText].attributes["living"] = 3
            end
            if (value == "1" && h2kElements[locationText].attributes["bedrooms"].to_i < 1)
              h2kElements[locationText].attributes["bedrooms"] = 1
            end
            if (value == "1" && h2kElements[locationText].attributes["bathrooms"].to_i < 1)
              h2kElements[locationText].attributes["bathrooms"] = 1
            end

            # If F326 specified && basement exists, set vent-rate for other basement areas to 10/Ls. Otherwise, 0.
            # This code is needed b/c setting F326 in homes with slab foundations can cause hot2000 to produce an errror.
            if ( value == 1 )
              $basementFound = false
              locationComponents = "HouseFile/House/Components"
              h2kCodeElements.each(locationComponents) do |component|
                # TODO: Should this also include crawlspace?
                if ( component =~ /Basement/ || component =~ /Walkout/ )
                  $basementFound = true
                end
              end
            end

            locationVentRate = "HouseFile/House/Ventilation/Rooms/VentilationRate"
            if ( $basementFound )
              # 10L/s vent rate in basement
              h2kElements[locationVentRate].attributes["code"] = 3
            else
              # "Non-applicable" - there is no basement
              h2kElements[locationVentRate].attributes["code"] = 1
            end

          elsif ( tag =~ /OPT-H2K-AirDistType/ &&  value != "NA" )
            locationText = "HouseFile/House/Ventilation/WholeHouse/AirDistributionType"
            h2kElements[locationText].attributes["code"] = value

          elsif ( tag =~ /OPT-H2K-OpSched/ &&  value != "NA" )
            locationText = "HouseFile/House/Ventilation/WholeHouse/OperationSchedule"
            h2kElements[locationText].attributes["code"] = "0"
            # User Specified
            h2kElements[locationText].attributes["value"] = value

          elsif ( tag =~ /OPT-H2K-HRVSupply/ &&  value != "NA" )
            locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"
            if ( h2kElements[locationText] == nil )
              createHRV(h2kElements)
            end
            h2kElements[locationText].attributes["supplyFlowrate"] = "#{[($FanFlow * 10.6 / 1.5).round(0),value.to_f].max}"
            # L/s supply
            h2kElements[locationText].attributes["exhaustFlowrate"] = "#{[($FanFlow * 10.6 / 1.5).round(0),value.to_f].max}"
            # Exhaust = Supply
            h2kElements[locationText].attributes["isDefaultFanpower"] = "true"

          elsif ( tag =~ /OPT-H2K-Rating1/ &&  value != "NA" )
            locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"
            if ( h2kElements[locationText] == nil )
              createHRV(h2kElements)
            end
            h2kElements[locationText].attributes["efficiency1"] = value
            # Rating 1 Efficiency

          elsif ( tag =~ /OPT-H2K-Rating2/ &&  value != "NA" )
            locationText = "HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"
            if ( h2kElements[locationText] == nil )
              createHRV(h2kElements)
            end
            h2kElements[locationText].attributes["efficiency2"] = value
            # Rating 1 Efficiency

          end

          # Boundary Conditions
          # ADW 07-May-2018: Original development of option
          # Notes: If this option is active, baseloads are switched to user-defined
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-Baseloads/ )
          # Baseload option has been defined in choice file, update
          if(choiceVal == "NA")
            # Don't change the baseload entries
            break
          end

          # Instead of looping through tags, update all values in this pass
          locationText = "HouseFile/House/BaseLoads/"

          # Set to specified
          h2kElements[locationText + "Summary"].attributes["isSpecified"] = "true"

          # Update occupancy
          h2kElements[locationText + "Occupancy"].attributes["isOccupied"] = "true"
          h2kElements[locationText + "Occupancy/Adults"].attributes["occupants"] = valHash["1"]
          h2kElements[locationText + "Occupancy/Adults"].attributes["atHome"] = valHash["2"]
          h2kElements[locationText + "Occupancy/Children"].attributes["occupants"] = valHash["3"]
          h2kElements[locationText + "Occupancy/Children"].attributes["atHome"] = valHash["4"]
          h2kElements[locationText + "Occupancy/Infants"].attributes["occupants"] = valHash["5"]
          h2kElements[locationText + "Occupancy/Infants"].attributes["atHome"] = valHash["6"]
          h2kElements[locationText].attributes["basementFractionOfInternalGains"] = valHash["7"]

          # Remove any defined user gains if they exist
          h2kElements[locationText + "Summary"].delete_element("WaterUsage")
          h2kElements[locationText + "Summary"].delete_element("ElectricalUsage")
          h2kElements[locationText + "Summary"].delete_element("AdvancedUserSpecified")

          # Define user gains
          h2kElements[locationText + "Summary"].add_attribute("isSpecified", "true")
          h2kElements[locationText + "Summary"].attributes["electricalAppliances"] = valHash["8"]
          h2kElements[locationText + "Summary"].attributes["lighting"] = valHash["9"]
          h2kElements[locationText + "Summary"].attributes["otherElectric"] = valHash["10"]
          h2kElements[locationText + "Summary"].attributes["exteriorUse"] = valHash["11"]
          h2kElements[locationText + "Summary"].attributes["hotWaterLoad"] = valHash["12"]
          h2kElements[locationText].add_element("AdvancedUserSpecified")
          h2kElements[locationText + "AdvancedUserSpecified"].add_attribute("hotWaterTemperature", valHash["13"])

          # Determine if a gas stove has been defined
          if ((valHash["14"] == "2" || valHash["14"] == "4") && valHash["15"] != "NA") #
            if(valHash["14"] == "2")
              # Natural Gas Stove
              h2kElements[locationText + "AdvancedUserSpecified"].add_element("GasStove")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove"].add_attribute("code","2")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove"].add_element("English")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove/English"].add_text("Natural Gas")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove"].add_element("French")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove/French"].add_text("Gaz naturel")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove"].add_attribute("value",valHash["15"])
            elsif(valHash["14"] == "4")
              # Propane Stove
              h2kElements[locationText + "AdvancedUserSpecified"].add_element("GasStove")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove"].add_attribute("code","4")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove"].add_element("English")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove/English"].add_text("Propane")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove"].add_element("French")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove/French"].add_text("Propane")
              h2kElements[locationText + "AdvancedUserSpecified/GasStove"].add_attribute("value",valHash["15"])
            else
              fatalerror("For Opt-Baseloads, unknown stove fuel type #{valHash["14"]}!\n")
            end
          end

          # Determine house foundation type


          $basementFound = false
          if !h2kElements["HouseFile/House/Components/Basement"].nil? || !h2kElements["HouseFile/House/Components/Walkout"].nil?
            $basementFound = true
          end

          # Determine Dryer inputs
          h2kElements[locationText + "AdvancedUserSpecified"].add_element("DryerLocation")
          h2kElements[locationText + "AdvancedUserSpecified/DryerLocation"].add_element("English")
          h2kElements[locationText + "AdvancedUserSpecified/DryerLocation"].add_element("French")

          if ((valHash["16"] == "2" || valHash["16"] == "4") && valHash["17"] != "NA")
            # Gas dryer fuel and consumption has been specified
            if(valHash["16"] == "2")
              # Natural Gas Dryer
              # Add Gas Dryer element
              h2kElements[locationText + "AdvancedUserSpecified"].add_element("GasDryer")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer"].add_attribute("code", "2")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer"].add_element("English")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer/English"].add_text("Natural Gas")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer"].add_element("French")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer/French"].add_text("Gaz naturel")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer"].add_attribute("value",valHash["17"])
            elsif(valHash["16"] == "4")
              # Propane Dryer
              # Add Gas Dryer element
              h2kElements[locationText + "AdvancedUserSpecified"].add_element("GasDryer")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer"].add_attribute("code", "4")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer"].add_element("English")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer/English"].add_text("Propane")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer"].add_element("French")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer/French"].add_text("Propane")
              h2kElements[locationText + "AdvancedUserSpecified/GasDryer"].add_attribute("value",valHash["17"])
            else
              # Fuel type is not valid
              fatalerror("In Opt-Baseloads: Unknown dryer fuel type #{valHash["16"]}!\n")
            end

            # Set up location of dryer
            if(valHash["18"] == "1" || (valHash["18"] == "2" && !$basementFound))
              # On the main floor, or foundation requested but there is no full basement
              h2kElements[locationText + "AdvancedUserSpecified/DryerLocation"].add_attribute("code", "1")
              h2kElements[locationText + "AdvancedUserSpecified/DryerLocation/English"].add_text("Main Floor")
              h2kElements[locationText + "AdvancedUserSpecified/DryerLocation/French"].add_text("Plancher Principal")
            elsif(valHash["18"] == "2")
              # In the foundation zone, and full basement is present
              h2kElements[locationText + "AdvancedUserSpecified/DryerLocation"].add_attribute("code", "6")
              h2kElements[locationText + "AdvancedUserSpecified/DryerLocation"].add_text("Foundation - 1")
            elsif (valHash["18"] == "NA")
              # There is a dryer, but the user has not specified a location. Assume main floor
              warn_out("In Opt-Baseloads: Unknown dryer location #{valHash["18"]}! Setting to main floor.")
              h2kElements[locationText + "AdvancedUserSpecified/DryerLocation"].add_attribute("code", "1")
              h2kElements[locationText + "AdvancedUserSpecified/DryerLocation/English"].add_text("Main Floor")
              h2kElements[locationText + "AdvancedUserSpecified/DryerLocation/French"].add_text("Plancher Principal")
            else
              fatalerror("In Opt-Baseloads: Invalid dryer location input #{valHash["18"]}! Must be NA, 1, or 2 \n")
            end

          else
            # Either no dryer fuel type and/or daily consumption has not been provided
            h2kElements[locationText + "AdvancedUserSpecified/DryerLocation"].add_attribute("code", "0")
            h2kElements[locationText + "AdvancedUserSpecified/DryerLocation/English"].add_text("No Laundry Equipment")
            h2kElements[locationText + "AdvancedUserSpecified/DryerLocation/French"].add_text("Aucun Ã‰qu. de Buandrie")
          end

          # Move to the next choiceEntry with a break
          break

          # Temperature inputs
          # ADW 23-May-2018: Original development of option
          # Notes:
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-Temperatures/ )
          locationText = "HouseFile/House/Temperatures/"
          if ( tag =~ /Opt-H2K-DayHeatSet/ &&  value != "NA" )
            h2kElements[locationText + "MainFloors"].attributes["daytimeHeatingSetPoint"] = value
          elsif ( tag =~ /Opt-H2K-NightHeatSet/ &&  value != "NA" )
            h2kElements[locationText + "MainFloors"].attributes["nighttimeHeatingSetPoint"] = value
          elsif ( tag =~ /Opt-H2K-SetbackDur/ &&  value != "NA" )
            h2kElements[locationText + "MainFloors"].attributes["nighttimeSetbackDuration"] = value
          elsif ( tag =~ /Opt-H2K-CoolSet/ &&  value != "NA" )
            h2kElements[locationText + "MainFloors"].attributes["coolingSetPoint"] = value
          elsif ( tag =~ /Opt-H2K-AllowRise/ &&  value != "NA" )
            if(value != "1" && value != "2" && value != "3")
              fatalerror("In Opt-Temperatures: Invalid allowable rise option #{value}! Must be NA, 1, 2, or 3 \n")
            end
            h2kElements[locationText + "MainFloors/AllowableRise"].attributes["code"] = value
          elsif ( tag =~ /Opt-H2K-BsmtIsHeat/ &&  value != "NA" )
            if(value != "true" && value != "false")
              fatalerror("In Opt-Temperatures: Is basement heated must be true or false, not #{value}\n")
            end
            h2kElements[locationText + "Basement"].attributes["heated"] = value
          elsif ( tag =~ /Opt-H2K-BsmtIsCool/ &&  value != "NA" )
            if(value != "true" && value != "false")
              fatalerror("In Opt-Temperatures: Is basement cooled must be true or false, not #{value}\n")
            end
            h2kElements[locationText + "Basement"].attributes["cooled"] = value
          elsif ( tag =~ /Opt-H2K-BsmtSepTherm/ &&  value != "NA" )
            if(value != "true" && value != "false")
              fatalerror("In Opt-Temperatures: Is basement separate thermostat must be true or false, not #{value}\n")
            end
            h2kElements[locationText + "Basement"].attributes["separateThermostat"] = value
          elsif ( tag =~ /Opt-H2K-BsmtHeatSet/ &&  value != "NA" )
            h2kElements[locationText + "Basement"].attributes["heatingSetPoint"] = value
          elsif ( tag =~ /Opt-H2K-EqipHeat/ &&  value != "NA" )
            h2kElements[locationText + "Equipment"].attributes["heatingSetPoint"] = value
          elsif ( tag =~ /Opt-H2K-EqipCool/ &&  value != "NA" )
            h2kElements[locationText + "Equipment"].attributes["coolingSetPoint"] = value
          elsif ( tag =~ /Opt-H2K-CrawlIsHeat/ &&  value != "NA" )
            if(value != "true" && value != "false")
              fatalerror("In Opt-Temperatures: Is crawlspace must be true or false, not #{value}\n")
            end
            h2kElements[locationText + "Crawlspace"].attributes["heated"] = value
          elsif ( tag =~ /Opt-H2K-CrawlHeatSet/ &&  value != "NA" )
            h2kElements[locationText + "Crawlspace"].attributes["heatingSetPoint"] = value
          elsif ( tag =~ /Opt-H2K-CoolSeasStart/ &&  value != "NA" )
            if(value.to_i < 1 || value.to_i > 12)
              fatalerror("In #{choiceEntry}: Invalid cooling season start #{value}")
            end
            locationText = "HouseFile/House/HeatingCooling/CoolingSeason/"
            h2kElements[locationText + "Start"].attributes["code"] = value
          elsif ( tag =~ /Opt-H2K-CoolSeasEnd/ &&  value != "NA" )
            if(value.to_i < 1 || value.to_i > 12)
              fatalerror("In #{choiceEntry}: Invalid cooling season end #{value}")
            end
            locationText = "HouseFile/House/HeatingCooling/CoolingSeason/"
            h2kElements[locationText + "End"].attributes["code"] = value
          elsif ( tag =~ /Opt-H2K-CoolSeasDes/ &&  value != "NA" )
            if(value.to_i < 1 || value.to_i > 12)
              fatalerror("In #{choiceEntry}: Invalid cooling season design month #{value}")
            end
            locationText = "HouseFile/House/HeatingCooling/CoolingSeason/"
            h2kElements[locationText + "Design"].attributes["code"] = value
          end

          # House specifications inputs
          # ADW 24-May-2018: Original development of option
          # Notes:
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-Specifications/ )
          locationText = "HouseFile/House/Specifications/"
          if ( tag =~ /Opt-H2K-ThermalMass/ &&  value != "NA" )
            if(value != "1" && value != "2" && value != "3" && value != "4")
              fatalerror("In Opt-Specifications: Invalid thermal mass input #{value}\n")
            end
            h2kElements[locationText + "ThermalMass"].attributes["code"] = value
          elsif ( tag =~ /Opt-H2K-WallColour/ &&  value != "NA" )
            if((value.to_f > 1) || (value.to_f < 0))
              fatalerror("In Opt-Specifications: Invalid wall colour input #{value}\n")
            end
            h2kElements[locationText + "WallColour"].attributes["code"] = "1"
            h2kElements[locationText + "WallColour"].attributes["value"] = value
          elsif ( tag =~ /Opt-H2K-SoilCondition/ &&  value != "NA" )
            if(value != "1" && value != "2" && value != "3")
              fatalerror("In Opt-Specifications: Invalid soil conductivity input #{value}\n")
            end
            h2kElements[locationText + "SoilCondition"].attributes["code"] = value
          elsif ( tag =~ /Opt-H2K-RoofColour/ &&  value != "NA" )
            if((value.to_f > 1) || (value.to_f < 0))
              fatalerror("In Opt-Specifications: Invalid roof colour input #{value}\n")
            end
            h2kElements[locationText + "RoofColour"].attributes["code"] = "1"
            h2kElements[locationText + "RoofColour"].attributes["value"] = value
          elsif ( tag =~ /Opt-H2K-WaterLevel/ &&  value != "NA" )
            if(value != "1" && value != "2" && value != "3")
              fatalerror("In Opt-Specifications: Invalid water level input #{value}\n")
            end
            h2kElements[locationText + "WaterLevel"].attributes["code"] = value
          end

          # Roof Pitch - change slope of all ext. ceilings (i.e., roofs)
          #--------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-RoofPitch/ )
          if ( tag =~ /Opt-H2K-RoofSlope/ &&  value != "NA" )
            locationText = "HouseFile/House/Components/Ceiling/Measurements/Slope"
            h2kElements.each(locationText) do |element|
              element.attributes["code"] = "0"
              # User Specified slope
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
            locationText = "HouseFile/House/Generation/PhotovoltaicSystems"
            if ( h2kElements[locationText] != nil )
              locationText = "HouseFile/House/Generation"
              h2kElements[locationText].delete_element("PhotovoltaicSystems")
              $PVIntModel = false
            end
          end


          # PV - internal. Uses H2K PV Generation model
          # Limited number of parameters available in options file.
          #
          # ASF 03-Oct-2016: Updated to reflect new file structure in v11.3.90b
          # JTB 03-Nov-2016: Note that available PV annual energy is allocated to reduce
          #                  annual electrical energy to zero (regardless of monthly values).
          #                  The excess energy is ignored in H2K (i.e., no util credit calc'd)
          #----------------------------------------------------------------------------

        elsif ( choiceEntry =~ /Opt-H2K-PV/ )
          if ( tag =~ /Opt-H2K-Area/ &&  value != "NA" )
            # Check if specified area is possible for this house file
            totalCeilArea = 0.0
            locationText = "HouseFile/House/Components/Ceiling/Measurements"
            h2kElements.each(locationText) do |element|
              totalCeilArea += element.attributes["area"].to_f
            end
            if ( value.to_f > totalCeilArea )
              warn_out("WARNING: Specified PV area (#{value} sq.m.) is greater than available roof area (#{totalCeilArea.round().to_s} sq.m.)")
            end
            checkCreatePV( h2kElements )
            locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System/Array"
            h2kElements[locationText].attributes["area"] = value

          elsif ( tag =~ /Opt-H2K-Slope/ &&  value != "NA" )
            checkCreatePV( h2kElements )
            locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System/Array"
            h2kElements[locationText].attributes["slope"] = value

          elsif ( tag =~ /Opt-H2K-Azimuth/ &&  value != "NA" )
            checkCreatePV( h2kElements )
            locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System/Array"
            h2kElements[locationText].attributes["azimuth"] = value

          elsif ( tag =~ /Opt-H2K-PVModuleType/ &&  value != "NA" )
            checkCreatePV( h2kElements )
            locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System/Module/Type"
            h2kElements[locationText].attributes["code"] = value

          elsif ( tag =~ /Opt-H2K-GridAbsRate/ &&  value != "NA" )
            checkCreatePV( h2kElements )
            locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System/Efficiency"
            h2kElements[locationText].attributes["gridAbsorptionRate"] = value

          elsif ( tag =~ /Opt-H2K-InvEff/ &&  value != "NA" )
            checkCreatePV( h2kElements )
            locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System/Efficiency"
            h2kElements[locationText].attributes["inverterEfficiency"] = value

          end

          # Results and Program Mode - change program mode so correct result sets produced
          # Note: The XML file does not contain a "mode" parameter. It uses the presence or
          #       absence of the <Program> section to indicate the mode.
          #--------------------------------------------------------------------------------
        elsif ( choiceEntry =~ /Opt-ResultHouseCode/ )
          if value == "NA"
            # Don't change the run mode but use the "General" output section!
            $outputHCode = "General"

          elsif value == "General"
            # Change run mode and set output section
            $outputHCode = "General"
            if h2kElements["HouseFile/Program"] != nil
              h2kElements["HouseFile"].delete_element("Program")
            end

          else
            # Change run mode to ERS and set output section
            $outputHCode = value
            if h2kElements["HouseFile/Program"] == nil
              createProgramXMLSection( h2kElements )
            end
          end

        # Change window distribution
        # Delete all windows and redistribute according to the choices
        #-----------------------------------------------------------------------------------
        elsif (choiceEntry =~ /Opt-WindowDistribution/)
          #winArea = H2KFile.getWindowArea(h2kElements)
          wallAreaAG = H2KFile.getAGWallDimensions(h2kElements)
          winArea = wallAreaAG["area"]["windows"].to_f
          doorArea = wallAreaAG["area"]["doors"].to_f
          grossWallArea = wallAreaAG["area"]["gross"].to_f
          fDWR = (winArea+doorArea) / grossWallArea

          frontOrientation = H2KFile.getFrontOrientation(h2kElements)
          winCode = h2kElements["HouseFile/House/Components/Wall/Components/Window/Construction/Type"].attributes["idref"]
          if value == "NA"
            # Do nothing -- window distribution remain unchanged
          elsif value == "equal-on-all-sides"
            # TBA
            if (fDWR < 0.17)
              fDWR = 0.17
            elsif (fDWR > 0.22)
              fDWR = 0.22
            end
            equalWinArea = (fDWR * grossWallArea - doorArea)/4
            newWinHeight = Math.sqrt(equalWinArea) * 1000.0
            newWinWidth = Math.sqrt(equalWinArea) * 1000.0
            H2KFile.deleteAllWin(h2kElements)
            if (frontOrientation =~ /S/ || frontOrientation =~ /N/ || frontOrientation =~ /W/ || frontOrientation =~ /E/)
              H2KFile.addWin(h2kElements, "S", newWinHeight, newWinWidth, winCode)
              H2KFile.addWin(h2kElements, "N", newWinHeight, newWinWidth, winCode)
              H2KFile.addWin(h2kElements, "E", newWinHeight, newWinWidth, winCode)
              H2KFile.addWin(h2kElements, "W", newWinHeight, newWinWidth, winCode)
            else
              H2KFile.addWin(h2kElements, "SE", newWinHeight, newWinWidth, winCode)
              H2KFile.addWin(h2kElements, "NE", newWinHeight, newWinWidth, winCode)
              H2KFile.addWin(h2kElements, "SW", newWinHeight, newWinWidth, winCode)
              H2KFile.addWin(h2kElements, "NW", newWinHeight, newWinWidth, winCode)
            end


          end

        #------------------------------------------------------------------------------------
        else
          # Do nothing -- we're ignoring all other tags!
          debug_out("Tag #{tag} ignored!\n")

        end
        # of if block for this option choice (choiceEntry)


      end
      # end of tag loop
    end
  end

  # Delete energy upgrades --- it messes everything up!
  h2kElements["HouseFile"].delete_element("EnergyUpgrades")


  # Now we have processed all sequential choices - we need to preform
  # operations tha depend on multiple choices. Start with Foundations...
  myFdnData = Hash.new


  debug_out ( ">>> $foundation config? #{$foundationConfiguration}\n")

  if ( $foundationConfiguration == "surfBySurf")
    myFdnData["FoundationWallExtIns"     ] =  $gChoices["Opt-FoundationWallExtIns"     ]
    myFdnData["FoundationWallIntIns"     ] =  $gChoices["Opt-FoundationWallIntIns"     ]
    myFdnData["FoundationSlabBelowGrade" ] =  $gChoices["Opt-FoundationSlabBelowGrade" ]
    myFdnData["FoundationSlabOnGrade"    ] =  $gChoices["Opt-FoundationSlabOnGrade"    ]
    HTAP2H2K.conf_foundations(myFdnData,$gOptions.clone,h2kElements)
  end


  #Delete results section
  h2kElements["HouseFile"].delete_element("AllResults")

  # Save changes to the XML doc in existing working H2K file (overwrite original)
  begin
    debug_out (" Overwriting: #{$gWorkingModelFile} \n")
    newXMLFile = File.open($gWorkingModelFile, "w")
    $XMLdoc.write(newXMLFile)

  rescue
    fatalerror("Could not overwrite #{$gWorkingModelFile}\n ")
  ensure
    newXMLFile.close
  end

  begin
    debug_out ("saving a copy of the pre-h2k version (file-post-sub.h2k)\n")
    newXMLFile = File.open("file-postsub.h2k", "w")
    $XMLdoc.write(newXMLFile)
    newXMLFile.close
  rescue
    warn_out ("Could not create debugging file - file-postsub.h2k")
  ensure
    newXMLFile.close
  end

  debug_out ("Returning from process...")
  #debug_pause

end

# =========================================================================================
#  Function to find a ceiling code name in the Code Library (Favourite or User Defined).
#  This function will return the entire code library XML element for the found code or nil,
#  if not found. It also returns the code ID to use. Note that since code library names are
#  unique across all groups, a code name can occur in only one code group element. That
#  means a ceiling code cannot appear in both "Ceiling Codes" and
#  "Flat or Cathedral Ceiling Codes".
# =========================================================================================
def findCeilingCodeInLibrary( h2kElements, h2kCodeElements, value )
  # Look for this code name in code library (Favourite and UserDefined)
  thisCodeInHouse = false
  useThisCodeID = "Code 99"
  foundFavLibCode = false
  foundUsrDefLibCode = false
  foundAtticCeil = false
  foundCathCeil = false
  ceilngType = ""
  foundCodeLibElement = nil

  # Check in Favourite Ceiling Codes used for: Attic/Gable, Attic/Hip, Scissor
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
    # Also check in Favourite CeilingFlat Codes used for: Cathedral and Flat
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
    # Check in User Defined Ceiling Codes used for: Attic/Gable, Attic/Hip, Scissor
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
    # Also check in User Defined CeilingFlat Codes used for: Cathedral and Flat
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
  end

  return foundCodeLibElement, useThisCodeID
end

# =========================================================================================
#  Function to create the Program XML section that contains the ERS program mode data
# =========================================================================================
def createProgramXMLSection( houseElements )
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

    end
    # Matches wth locale OR simple name match

  end
  # End of fuel element loop

end

# =========================================================================================
#  Function to change window codes by orientation
# =========================================================================================
def ChangeWinCodeByOrient( winOrient, newValue, h2kCodeLibElements, h2kFileElements, choiceEntryValue, tagValue )
  # Change ALL existing windows for this orientation (winOrient) to the library code name
  # specified in newValue. If this code name exists in the code library elements (h2kCodeLibElements),
  # use the code (either Fav or UsrDef) for all entries facing in this direction. Code names in the code
  # library are unique.
  # Note: Not using "Standard", non-library codes (e.g., 202002)

  # Look for this code name in code library (Favorite and UserDefined)
  windowFacingH2KVal = { "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8 }

  $useThisCodeID  = {  "S"  =>  191 ,    "SE" =>  192 ,    "E"  =>  193 ,    "NE" =>  194 ,    "N"  =>  195 ,    "NW" =>  196 ,    "W"  =>  197 ,    "SW" =>  198   }

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
        # 9=FacingDirection
        if ( element[9].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
          # Check if each house entry has an "idref" attribute and add if it doesn't.
          # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
          if element[3][1].attributes["idref"] != nil
            # ../Construction/Type
            element[3][1].attributes["idref"] = $useThisCodeID[winOrient]
          else
            element[3][1].add_attribute("idref", $useThisCodeID[winOrient])
          end
          element[3][1].text = newValue
        end
      end
      # Windows in basement
      locationText = "HouseFile/House/Components/Basement/Components/Window"
      h2kFileElements.each(locationText) do |element|
        # 9=FacingDirection
        if ( element[9].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
          # Check if each house entry has an "idref" attribute and add if it doesn't.
          # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
          if element[3][1].attributes["idref"] != nil
            # ../Construction/Type
            element[3][1].attributes["idref"] = $useThisCodeID[winOrient]
          else
            element[3][1].add_attribute("idref", $useThisCodeID[winOrient])
          end
          element[3][1].text = newValue
        end
      end
      # Windows in walkout
      locationText = "HouseFile/House/Components/Walkout/Components/Window"
      h2kFileElements.each(locationText) do |element|
        # 9=FacingDirection
        if ( element[9].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
          # Check if each house entry has an "idref" attribute and add if it doesn't.
          # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
          if element[3][1].attributes["idref"] != nil
            # ../Construction/Type
            element[3][1].attributes["idref"] = $useThisCodeID[winOrient]
          else
            element[3][1].add_attribute("idref", $useThisCodeID[winOrient])
          end
          element[3][1].text = newValue
        end
      end
      # Windows in crawlspace (closed or vented)
      locationText = "HouseFile/House/Components/Crawlspace/Components/Window"
      h2kFileElements.each(locationText) do |element|
        # 9=FacingDirection
        if ( element[9].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
          # Check if each house entry has an "idref" attribute and add if it doesn't.
          # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
          if element[3][1].attributes["idref"] != nil
            # ../Construction/Type
            element[3][1].attributes["idref"] = $useThisCodeID[winOrient]
          else
            element[3][1].add_attribute("idref", $useThisCodeID[winOrient])
          end
          element[3][1].text = newValue
        end
      end

    else
      # Code name not found in the code library
      # Since no User Specified option for windows this must be an error!
      fatalerror("Missing code name: #{newValue} in code library for H2K #{choiceEntryValue} tag:#{tagValue}\n")
    end

  end

  # =========================================================================================
  #  Function to change skylight window codes by orientation
  # =========================================================================================
  def ChangeSkylightCodeByOrient( winOrient, newValue, h2kCodeLibElements, h2kFileElements, choiceEntryValue, tagValue )
    # Change ALL existing windows in ceilings for this orientation (winOrient) to the library code name
    # specified in newValue. If this code name exists in the code library elements (h2kCodeLibElements),
    # use the code (either Fav or UsrDef) for all entries facing in this direction. Code names in the code
    # library are unique.
    # Note: Not using "Standard", non-library codes (e.g., 202002)

    # Look for this code name in code library (Favorite and UserDefined)
    windowFacingH2KVal = { "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8 }

    $useThisCodeID  = { "S"  =>  201 , "SE" =>  202 , "E"  =>  203 , "NE" =>  204 , "N"  =>  205 , "NW" =>  206 , "W"  =>  207 , "SW" =>  208   }

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

        # Windows in ceiling elements (skylights)
        locationText = "HouseFile/House/Components/Ceiling/Components/Window"
        h2kFileElements.each(locationText) do |element|
          # 9=FacingDirection
          if ( element[9].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
            # Check if each entry has an "idref" attribute and add if it doesn't.
            # Change each entry to reference a new <Codes> section $useThisCodeID[winOrient]
            if element[3][1].attributes["idref"] != nil
              # ../Construction/Type
              element[3][1].attributes["idref"] = $useThisCodeID[winOrient]
            else
              element[3][1].add_attribute("idref", $useThisCodeID[winOrient])
            end
            element[3][1].text = newValue
          end
        end
      else
        # Code name not found in the code library
        # Since no User Specified option for windows this must be an error!
        fatalerror("Missing code name: #{newValue} in code library for H2K #{choiceEntryValue} tag:#{tagValue}\n")
      end

    end

    # =========================================================================================
    #  Function to change door window codes by orientation
    # =========================================================================================
    def ChangeDoorWinCodeByOrient( winOrient, newValue, h2kCodeLibElements, h2kFileElements, choiceEntryValue, tagValue )
      # Change ALL existing windows in doors for this orientation (winOrient) to the library code name
      # specified in newValue. If this code name exists in the code library elements (h2kCodeLibElements),
      # use the code (either Fav or UsrDef) for all entries facing in this direction. Code names in the code
      # library are unique.
      # Note: Not using "Standard", non-library codes (e.g., 202002)

      # Look for this code name in code library (Favorite and UserDefined)
      windowFacingH2KVal = { "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8 }

      $useThisCodeID = { "S"  =>  211 ,"SE" =>  212 ,"E"  =>  213 ,"NE" =>  214 ,"N"  =>  215 ,"NW" =>  216 ,"W"  =>  217 ,"SW" =>  218 }

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

          # Windows in door elements
          locationText = "HouseFile/House/Components/*/Components/Door/Components/Window"
          h2kFileElements.each(locationText) do |element|
            # 9=FacingDirection
            if ( element[9].attributes["code"] == windowFacingH2KVal[winOrient].to_s )
              # Check if each house entry has an "idref" attribute and add if it doesn't.
              # Change each house entry to reference a new <Codes> section $useThisCodeID[winOrient]
              if element[3][1].attributes["idref"] != nil
                # ../Construction/Type
                element[3][1].attributes["idref"] = $useThisCodeID[winOrient]
              else
                element[3][1].add_attribute("idref", $useThisCodeID[winOrient])
              end
              element[3][1].text = newValue
            end
          end
        else
          # Code name not found in the code library
          # Since no User Specified option for windows this must be an error!
          fatalerror(" INFO: Missing code name: #{newValue} in code library for H2K #{choiceEntryValue} tag:#{tagValue}\n")
        end

      end

      # =========================================================================================
      #  Add missing "AddedToSlab" section to Floor Construction of appropriate fnd
      # =========================================================================================
      def addMissingAddedToSlab(type, theElement)
        # locationStr contains "HouseFile/House/Components/X/", where X is "Basement",
        # "Walkout", "Crawlspace" or "Slab"
        # The Floor element is always three elements from the basement Configuration element,
        # two elements from the Crawlspace config and one from the slab config.
        if type == "B"
          theFloorElement = theElement.next_element.next_element.next_element
        elsif type == "C"
          theFloorElement = theElement.next_element.next_element
        elsif type == "S"
          theFloorElement = theElement.next_element
        end
        theFloorConstElement = theFloorElement[1]
        # First child element is always "Construction"
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
        theWallConstElement = theWallElement[1]
        # First child element is always "Construction"
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
        theWallConstElement = theWallElement[1]
        # First child element is always "Construction"
        theExtWallElement = theWallConstElement.add_element("ExteriorAddedInsulation", {"nominalInsulation"=>"0"})
        theExtWallElement.add_element("Description")
        theExtWallCompElement = theExtWallElement.add_element("Composite")
        theExtWallCompElement.add_element("Section", {"rank"=>"1", "percentage"=>"100", "rsi"=>"0", "nominalRsi"=>"0"} )
      end

      # =========================================================================================
      #  Check if there is a PV section and add, if not.
      #  ASF 03-Oct-2016: Updated to reflect new file structure in v11.3.90b
      # =========================================================================================
      def checkCreatePV( elements )
        if ( elements["HouseFile/House/Generation/PhotovoltaicSystems"] == nil )
          locationText = "HouseFile/House/Generation"
          elements[locationText].add_element("PhotovoltaicSystems")
          locationText = "HouseFile/House/Generation/PhotovoltaicSystems"
          elements[locationText].add_element("System")
          locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System"
          elements[locationText].attributes["rank"] = "1"
          elements[locationText].add_element("EquipmentInformation")
          elements[locationText].add_element("Array")
          locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System/Array"
          elements[locationText].attributes["area"] = "50"
          elements[locationText].attributes["slope"] = "42"
          elements[locationText].attributes["azimuth"] = "0"

          locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System"
          elements[locationText].add_element("Efficiency")
          locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System/Efficiency"
          elements[locationText].attributes["miscellaneousLosses"] = "3"
          elements[locationText].attributes["otherPowerLosses"] = "1"
          elements[locationText].attributes["inverterEfficiency"] = "90"
          elements[locationText].attributes["gridAbsorptionRate"] = "90"

          locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System"
          elements[locationText].add_element("Module")
          locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System/Module"
          elements[locationText].attributes["efficiency"] = "13"
          elements[locationText].attributes["cellTemperature"] = "45"
          elements[locationText].attributes["coefficientOfEfficiency"] = "0.4"
          elements[locationText].add_element("Type")
          locationText = "HouseFile/House/Generation/PhotovoltaicSystems/System/Module/Type"
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

      # =========================================================================================
      # Determine the F326 flow rate for a house
      # =========================================================================================
      def getF326FlowRates( elements )
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

      # =========================================================================================
      # Get and return primary (type 1) system space heating capacity in Watts
      # =========================================================================================
      def getBaseSystemCapacity( elements, sysType1Arr )
        capValue = 0
        locationText = "HouseFile/House/HeatingCooling/Type1"

        sysType1Arr.each do |sysType1Name|
          if ( elements[locationText + "/#{sysType1Name}"] != nil )
            if ( sysType1Name != "P9" )
              capValue = elements[locationText + "/#{sysType1Name}" + "/Specifications/OutputCapacity"].attributes["value"]
            else
              capValue = elements[locationText + "/#{sysType1Name}"].attributes["spaceHeatingCapacity"]
            end
          end
        end

        return capValue.to_f * 1000
        # Always returns Watts!
      end

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
          elements[locationText].attributes["code"] = "2"
          # Calculated
          elements[locationText].attributes["value"] = "0"
          # Calculated value - will be replaced!
          elements[locationText].attributes["uiUnits"] = "kW"
          elements[locationText].add_element("English")
          elements[locationText].add_element("French")

        elsif ( sysType1Name == "Furnace" )


          debug_out ("ADDING FURNACE ....\n")

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
          elements[locationText].attributes["code"] = "2"
          # Gas
          elements[locationText].add_element("English")
          elements[locationText].add_element("French")
          locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment"
          elements[locationText].add_element("EquipmentType")
          locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EquipmentType"
          elements[locationText].attributes["code"] = "1"
          # Furnace with cont. pilot
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
          elements[locationText].attributes["code"] = "2"
          # Calculated
          elements[locationText].attributes["value"] = "0"
          # Calculated value - will be replaced!
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
          elements[locationText].attributes["code"] = "2"
          # Gas
          elements[locationText].add_element("English")
          elements[locationText].add_element("French")
          locationText = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment"
          elements[locationText].add_element("EquipmentType")
          locationText = "HouseFile/House/HeatingCooling/Type1/Boiler/Equipment/EquipmentType"
          elements[locationText].attributes["code"] = "1"
          # Boiler with cont. pilot
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
          elements[locationText].attributes["code"] = "2"
          # Calculated
          elements[locationText].attributes["value"] = "0"
          # Calculated value - will be replaced!
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
          elements[locationText].attributes["code"] = "2"
          # Gas
          elements[locationText].add_element("English")
          elements[locationText].add_element("French")
          locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment"
          elements[locationText].add_element("EquipmentType")
          locationText = "HouseFile/House/HeatingCooling/Type1/ComboHeatDhw/Equipment/EquipmentType"
          elements[locationText].attributes["code"] = "1"
          # ComboHeatDhw with cont. pilot
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
          elements[locationText].attributes["code"] = "2"
          # Calculated
          elements[locationText].attributes["value"] = "0"
          # Calculated value - will be replaced!
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
          elements[locationText].attributes["thermalPerformanceFactor"] = "0.9"
          elements[locationText].attributes["annualElectricity"] = "1800"
          elements[locationText].attributes["spaceHeatingCapacity"] = "23900"
          elements[locationText].attributes["spaceHeatingEfficiency"] = "90"
          elements[locationText].attributes["waterHeatingPerformanceFactor"] = "0.9"
          elements[locationText].attributes["burnerInput"] = "0"
          elements[locationText].attributes["recoveryEfficiency"] = "0"
          elements[locationText].attributes["isUserSpecified"] = "true"
          elements[locationText].add_element("EquipmentInformation")
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/EquipmentInformation"
          elements[locationText].add_element("Manufacturer")
          elements[locationText].add_element("Model")
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/EquipmentInformation/Manufacturer"
          elements[locationText].text = "Generic"
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/EquipmentInformation/Model"
          elements[locationText].text = "Generic"

          locationText = "HouseFile/House/HeatingCooling/Type1/P9"
          elements[locationText].add_element("TestData")
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
          elements[locationText].attributes["controlsPower"] = "10"
          elements[locationText].attributes["circulationPower"] = "130"
          elements[locationText].attributes["dailyUse"] = "0.2"
          elements[locationText].attributes["standbyLossWithFan"] = "0"
          elements[locationText].attributes["standbyLossWithoutFan"] = "0"
          elements[locationText].attributes["oneHourRatingHotWater"] = "1000"
          elements[locationText].attributes["oneHourRatingConcurrent"] = "1000"
          elements[locationText].add_element("EnergySource")
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData/EnergySource"
          elements[locationText].attributes["code"] = "2"
          elements[locationText].add_element("English")
          elements[locationText].add_element("French")
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
          elements[locationText].add_element("NetEfficiency")
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData/NetEfficiency"
          elements[locationText].attributes["loadPerformance15"] = "80"
          elements[locationText].attributes["loadPerformance40"] = "80"
          elements[locationText].attributes["loadPerformance100"] = "80"
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
          elements[locationText].add_element("ElectricalUse")
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData/ElectricalUse"
          elements[locationText].attributes["loadPerformance15"] = "100"
          elements[locationText].attributes["loadPerformance40"] = "200"
          elements[locationText].attributes["loadPerformance100"] = "300"
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData"
          elements[locationText].add_element("BlowerPower")
          locationText = "HouseFile/House/HeatingCooling/Type1/P9/TestData/BlowerPower"
          elements[locationText].attributes["loadPerformance15"] = "300"
          elements[locationText].attributes["loadPerformance40"] = "500"
          elements[locationText].attributes["loadPerformance100"] = "800"
        end
      end
      # createH2KSysType1

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

          # CHECK this - should be 8.3 ?

          locationText = "HouseFile/House/HeatingCooling/Type2/AirHeatPump/Temperature/RatingType"
          elements[locationText].attributes["code"] = "3"
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
          locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications"
          elements[locationText].add_element("CoolingEfficiency")
          locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Specifications/CoolingEfficiency"
          elements[locationText].attributes["isCop"] = "true"
          elements[locationText].attributes["value"] = "3"

          locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
          elements[locationText].add_element("Temperature")
          locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature"
          elements[locationText].add_element("CutoffType")
          locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/Temperature/CutoffType"
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

          locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump"
          elements[locationText].add_element("CoolingParameters")

          locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters"
          elements[locationText].attributes["sensibleHeatRatio"] = "0.76"
          elements[locationText].attributes["openableWindowArea"] = "20"

          elements[locationText].add_element("FansAndPump")

          locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters/FansAndPump"
          # Do we need to set this? what should we set it to?
          elements[locationText].attributes["flowRate"] = "360"

          elements[locationText].add_element("Mode")
          elements[locationText].add_element("Power")

          locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters/FansAndPump/Mode"
          elements[locationText].attributes["code"] = "1"
          elements[locationText].add_element("English")
          elements[locationText].add_element("French")

          locationText = "HouseFile/House/HeatingCooling/Type2/GroundHeatPump/CoolingParameters/FansAndPump/Power"
          elements[locationText].attributes["isCalculated"] = "true"

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
          elements[locationText].attributes["openableWindowArea"] = "20"
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
      end
      # createH2KSysType2

      # =========================================================================================
      #  Add missing DWHR section to DHW
      # =========================================================================================
      def addMissingDWHR(elements)
        locationText = "HouseFile/House/Components/HotWater/Primary"
        elements[locationText].add_element("DrainWaterHeatRecovery")
        locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery"
        elements[locationText].attributes["showerLength"] = "5.0"
        elements[locationText].attributes["dailyShowers"] = "2"
        elements[locationText].attributes["preheatShowerTank"] = "false"
        elements[locationText].attributes["effectivenessAt9.5"] = "50.0"
        elements[locationText].add_element("Efficiency", {"code"=>"2"})
        elements[locationText].add_element("EquipmentInformation")
        elements[locationText].add_element("ShowerTemperature", {"code"=>"1"})
        elements[locationText].add_element("ShowerHead", {"code"=>"0"})
        locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/EquipmentInformation"
        elements[locationText].add_element("Manufacturer")
        elements[locationText].add_element("Model")

        # ASF 05-10-2016: Added default values for manufacturer, model so hthat user can spec "NA" in choice file.
        locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/EquipmentInformation/Manufacturer"
        elements[locationText].text = "Generic"
        locationText = "HouseFile/House/Components/HotWater/Primary/DrainWaterHeatRecovery/EquipmentInformation/Model"
        elements[locationText].text = "2-Medium Efficiency"
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


        # make a back-up copy, in case HOT2000 crashses mid-run and empties the runfille


        # Command to execute H2k.
        runThis = "HOT2000.exe -inp ..\\#{$h2kFileName}"




        # JB TODO: What does this comment mean? --> AF: Extra counters to count ls tmpval how many times we've tried HOT2000.
        keepTrying = true
        tries = 1
        # This loop actually calls hot2000!
        pid = 0

        $runH2KTime = Time.now - Time.now


        while keepTrying do

          startH2Krun = Time.now

          $gStatus["H2KExecutionAttempts"] = tries

          FileUtils.cp("..\\#{$h2kFileName}", "..\\run_file_file_#{tries}.h2k")

          runThis = "HOT2000.exe -inp ..\\run_file_file_#{tries}.h2k"

          begin

            pid = Process.spawn( runThis, :new_pgroup => true )
            stream_out ("\n Attempt ##{tries}:  Invoking HOT2000 (PID #{pid}) ...")
            runStatus = Timeout::timeout($maxRunTime){
              Process.waitpid(pid, 0)
            }
            status = $?.exitstatus
          rescue Timeout::Error

            begin
              Process.kill('KILL', pid)
            rescue
              # do nothing - process may have died on its own?
            end


            status = -1

            sleep(2)
          end


          endH2Krun = Time.now

          $runH2KTime = $runH2KTime + ( endH2Krun - startH2Krun )

          stream_out(" Hot2000 (PID: #{pid}) finished with exit status #{status} \n")

          if status == -1
            warn_out("\n\n Attempt ##{tries}: Timeout on H2K call after #{$maxRunTime} seconds." )
            keepTrying = true
            # Successful run - don't try agian

          elsif status == 0


            stream_out( " The run was successful (#{$runH2KTime.round(2).to_s} seconds)!\n" )
            keepTrying = false
            # Successful run - don't try agian

            FileUtils.cp("..\\run_file_file_#{tries}.h2k", "..\\#{$h2kFileName}")

          elsif status == 3 ||  status == nil
            # Pre-check message(s)


            warn_out( " The run completed but had pre-check messages (#{$runH2KTime.round(2).to_s} seconds)!" )
            keepTrying = false
            # Successful run - don't try agian

            FileUtils.cp("..\\run_file_file_#{tries}.h2k", "..\\#{$h2kFileName}")

            #elsif status == nil
            #   # Get nil status when can't load an h2k file.
            #
            #   fatalerror( "When spawning H2K, process returned nil return code after #{$runH2KTime.round(2).to_s} seconds; HOT2000 message box or couldn't load file!\n" )
            #   keepTrying = false   # Give up.

          end


          if ( keepTrying && tries < $maxTries )
            # Unsuccessful run - try again for up to maxTries
            tries = tries + 1
            keepTrying = true

            # if run failed, overwrite the h2k file with the backup. Needed because if H2k times out, or crashes mid-run,
            # the h2k file may be corrupted.


            # Try to kill the process again to make sure there are no zombies holding write access to h2k files.

          elsif ( keepTrying && tries == $maxTries )

            warn_out("Max number of execution attempts (#{$maxTries}) reached. Giving up.")
            fatalerror("Hot2000 evaluation could not be completed successfully")
            keepTrying = false
            # Give up.

          end

          begin
            Process.kill('KILL', pid)
            sleep(2)
          rescue
            # do nothing - process may have died on its own?
          end





        end

        $gStatus["H2KExecutionTime"] = $runH2KTime

        $NumTries = tries



        Dir.chdir( $gMasterPath )
        debug_out ("\n Moved to path: #{Dir.getwd()}\n")

        # Save output files
        $OutputFolder = "sim-output"
        if ( ! Dir.exist?($OutputFolder) )
          if ( ! system("mkdir #{$OutputFolder}") )
            fatalerror( "Could not create #{$OutputFolder} below #{$gMasterPath}! MKDir Return code: #{$?}\n" )
          end
        else
          if ( File.exist?("#{$OutputFolder}\\Browse.rpt") )
            if ( ! system("del #{$OutputFolder}\\Browse.rpt") )
              # Delete existing Browse.Rpt
              fatalerror("Could not delete existing Browse.rpt file in #{$OutputFolder}! Del Return code: #{$?}\n" )
            end
          end
        end

        # Copy simulation results to sim-output folder in master (for ERS number)
        # Note that most of the output is contained in the HOT2000 file in XML!
        if ( Dir.exist?("sim-output") )
          stream_out ("\n Copying results.")
          FileUtils.cp("#{$run_path}\\Browse.rpt", ".\\sim-output\\")

          if ( $gReadROutStrTxt )
            if ( File.file?("#{$run_path}\\ROutStr.txt")  )
              FileUtils.cp("#{$run_path}\\ROutStr.txt", ".\\sim-output\\")
              debug_out( "\n\n Copied output file Routstr.txt to #{$gMasterPath}\\sim-output.\n" )
            else
              fatalerror("Could not copy Routstr.txt to #{$OutputFolder}! Copy return code: #{$?}\n" )
            end
          end

          #if ( ! system("copy /Y #{$run_path}\\Browse.rpt .\\sim-output\\") )
          #if ( ! FileUtils.cp("#{$run_path}\\Browse.rpt", ".\\sim-output\\") )
          #   fatalerror("\n Fatal Error! Could not copy Browse.rpt to #{$OutputFolder}!\n Copy return code: #{$?}\n" )
          #else
          #   debug_out( "\n\n Copied output file Browse.rpt to #{$gMasterPath}\\sim-output.\n" )
          #end
        end

      end
      # runsims

      # =========================================================================================
      # Post-process results
      # =========================================================================================
      def postprocess( scaleData )

        stream_out( "\n Loading XML elements from #{$gWorkingModelFile} ...")

        # Load all XML elements from HOT2000 file (post-run results now available)
        h2kPostElements = H2KFile.get_elements_from_filename( $gWorkingModelFile )

        if ( $gCustomCostAdjustment )
          $gRegionalCostAdj = $gCostAdjustmentFactor
        else
          $gRegionalCostAdj = $RegionalCostFactors[$Locale]
        end

        # PVSise Depreciated. To be removed in later versions.
        # $PVsize = $gChoices["Opt-StandoffPV"]  # Input examples: "SizedPV", "SizedPV|3kW", or "NoPV"
        $PVInt = $gChoices["Opt-H2K-PV"]
        # Input examples: "MonoSi-50m2", "NA"
        if ( $PVInt != "NA" )
          $PVIntModel = true
          if ( $PVsize != "NoPV" )
            # Internal PV model supercedes external!
            $PVsize = "NoPV"
          end
        end

        # Set flags for reading from Browse.rpt file
        bReadOldERSValue = false
        bUseNextPVLine = false
        bUseNextACLine = false
        bReadAirConditioningLoad = true
        # Always get Air Conditioning Load (not available in XML)

        #Open diagnostics file and possibly read in interesting info  !?!
        $lineNo = 0
        if ( $gReadROutStrTxt  )
          #begin
          stream_out("\nParsing diagnostics from #{$OutputFolder}\\Routstr.txt ...")
          fRoutStr = File.new("#{$OutputFolder}\\Routstr.txt", "r")

          $SOCparse     = false
          $SHTiniparse  = false
          $FFBCparse    = false
          $EFBCparse    = false
          $HPparse      = false
          $bHeatingDone = false
          $EBakparse    = false
          $GOPparse     = false
          # Zero arrays
          32.times do |n|

            $binDatHrs[n+1]=0
            $binDatTmp[n+1]=0
            $binDatTsfB[n+1]=0
            $binDatHLR[n+1]=0
            $binDatT2cap[n+1]=0
            #$binDatT1cap[n+1]=0
            $binDatT2PLR[n+1]=0
            $binDatT1PLR[n+1]=0

          end



          while !fRoutStr.eof? do

            $lineNo = $lineNo + 1

            $lineIn = fRoutStr.readline
            $lineIn.strip!

            if ( $lineIn =~ /^\s*$/ ||  $bHeatingDone ) then
              next
              # Skip empty line.
            end


            #Report binned data in general or SOC modes.
            # (This still calls for a more robust approach that can set the evaluation
            #  type from the choice file or cmd line.)
            if ($lineIn =~ /Starting Run: House with standard operating conditions/ ||
              $lineIn =~ /Starting Run: House\s*$/ )
              debug_out("ROUTSTR ? SOC open #{$lineNo} | #{$lineIn} \n")
              $SOCparse = true
            elsif ($lineIn =~ /Starting Run: / &&  $SOCparse)
              debug_out("ROUTSTR ? SOC close  #{$lineNo} |  #{$lineIn} \n")
              $SOCparse = false
            end

            if ( ! $SOCparse ) then
              next
              # Skip if we're not within standard OCs.
            end

            # Test if cooling sectins have been reached.
            if ( $lineIn =~ /Cooling calculations ../ )
              debug_out("ROUTSTR ? COOLING SECTION : #{$lineIn} \n")
              $bHeatingDone = true
              next
            end



            # Set flags for sections in the file
            if ($lineIn =~ /SpaceHTini/ )
              debug_out("ROUTSTR ? SpaceHTini open #{$lineNo} | #{$lineIn} \n")
              $SHTiniparse = true
            elsif ($lineIn =~ /Space00/ && $SHTiniparse )
              debug_out("ROUTSTR ? SpaceHTini close  #{$lineNo} | #{$lineIn}  \n")
              $SHTiniparse = false
            end

            if ($lineIn =~ /FossilFurnaceBC/ )
              debug_out("ROUTSTR ? FossilFurnaceBC open #{$lineNo} | #{$lineIn} \n")
              $FFBCparse = true
            elsif ($FFBCparse &&
              ( $lineIn =~ /HPBPLocated/ || $lineIn =~ /ElectricFurnaceBC/ || $lineIn =~ /oSpaceHT/ ) )
              debug_out("ROUTSTR ? FossilFurnaceBC close  #{$lineNo} | #{$lineIn}  \n")
              $FFBCparse = false
            end


            if ($lineIn =~ /GOPBackup: Gas\/Oil\/Propane backup../ )
              debug_out("ROUTSTR ? Gas/Oil/Propoane backup open #{$lineNo} | #{$lineIn} \n")
              $GOPparse = true
            elsif ( $GOPparse &&
              ( $lineIn =~ /HPBPLocated/ || $lineIn =~ /ElectricFurnaceBC/ || $lineIn =~ /oSpaceHT/ ) )
              debug_out("ROUTSTR ? Gas/Oil/Propoane backup close  #{$lineNo} | #{$lineIn}  \n")
              $GOPparse = false
            end


            if ($lineIn =~ /ElectricFurnaceBC/  )
              debug_out("ROUTSTR ? ElectricFurnaceBC open #{$lineNo} | #{$lineIn} \n")
              $EFBCparse = true
            elsif ($EFBCparse  &&
              ( $lineIn =~ /HPBPLocated/ || $lineIn =~ /oSpaceHT/ ) )
              debug_out("ROUTSTR ? ElectricFurnaceBC close  #{$lineNo} | #{$lineIn}  \n")
              $EFBCparse = false
            end

            if ($lineIn =~ /ElectricBackup: ELECTRIC BACK-UP/  )
              debug_out("ROUTSTR ? ElectricBack open #{$lineNo} | #{$lineIn} \n")
              $EBakparse = true
            elsif ( $EBakparse &&
              ( $lineIn =~ /ElectricFurnaceBC: ELECTRIC HEAT BELOW CUT-OFF../ ) )
              debug_out("ROUTSTR ? ElectricBack close  #{$lineNo} | #{$lineIn}  \n")
              $EBakparse = false
            end


            if ($lineIn =~ /AboveHPBP @160/ )
              debug_out("ROUTSTR ? HP open #{$lineNo} | #{$lineIn} \n")
              $HPparse = true
            elsif ( $HPparse &&
              ( $lineIn =~ /FALLS THU OPS/ || $lineIn =~ /Exit AboveHPBP @ 180/ || $lineIn =~/HPBPLocated 180   T/) )
              debug_out("ROUTSTR ? HP close  #{$lineNo} | #{$lineIn}  \n")
              $HPparse = false
            end


            # ==== Parse Data =====

            # Read fan power
            if ($lineIn =~ /QFFAN/ )
              debug_out("ROUTSTR ? QFFAN : #{$lineNo} | #{$lineIn}  \n")
              valuesArr = $lineIn.split()
              $FurnFanPower = valuesArr[3]
              $HPFanPower = valuesArr[4]
              debug_out("ROUTSTR ? #{$lineNo} | QFFAN = #{$FurnFanPower} , QHPFAN = #{$HPFanPower} \n ")
            end

            # Read T1 capacity
            if ($lineIn =~ /oSpaceHT FURNPW/ )
              valuesArr = $lineIn.split()
              debug_out("ROUTSTR ? oCpaceHTFURN : #{$lineIn} \n")
              $T1Capacity = valuesArr[2]
            end

            # Get SH bin definitions
            if ($SHTiniparse)
              debug_out("ROUTSTR ? SHITI : #{$lineIn} \n")
              # Headerline  - ignore
              if ($lineIn =~ /Bin  BinHours   TbinC    HLcvs    HLAir    TsfB    CShtr     HLR0     HLR1     HLR2/ )

              else
                valuesArr = $lineIn.split()
                binNo = valuesArr[0].to_i
                $binDatHrs[binNo]  = valuesArr[1].to_f
                $binDatTmp[binNo]  = valuesArr[2].to_f
                $binDatTsfB[binNo] = valuesArr[5].to_f
              end

            end





            # Get furnace performace data
            if ( $FFBCparse )
              debug_out("ROUTSTR ? FossilFurnace : #{$lineIn} \n")
              if ($lineIn =~ /FossilFurnaceBC:/ || $lineIn !~ /^\s*[0-9]/)
                # Header - ignore
              else

                debug_out(">>>FOSIL Furnace  Parsing #{$lineIn} \n")
                valuesArr = $lineIn.split()
                binNo = valuesArr[0].to_i
                $binDatHLR[binNo]  = valuesArr[3].to_f
                $binDatT1PLR[binNo]  = valuesArr[6].to_f


              end
            end

            # Get Heat pump w/ electric back-up data
            if ( $EBakparse )
              debug_out("ROUTSTR ? E-Backup: #{$lineIn} \n")
              if ($lineIn =~ /ElectricFurnaceBC:/ || $lineIn !~ /^\s*[0-9]/)
                # Header - ignore
              else

                valuesArr = $lineIn.split()
                binNo = valuesArr[0].to_i
                $binDatHLR[binNo]  = valuesArr[1].to_f
                $binDatT2cap[binNo]  = valuesArr[3].to_f
                $binDatT2PLR[binNo]  = 1.0
                $binDatT1PLR[binNo]  = valuesArr[5].to_f


              end
            end


            #Get heat pump w/gas back up data.
            if ( $GOPparse )

              if ( $lineIn !~ /^@290/ )
                # Header - ignore
              else
                debug_out("ROUTSTR ? GOP parse: #{$lineIn} \n")
                valuesArr = $lineIn.split()
                binNo = valuesArr[1].to_i
                $binDatHLR[binNo]  = valuesArr[2].to_f
                $binDatT2cap[binNo]  = valuesArr[3].to_f
                $binDatT2PLR[binNo]  = 1.0
                $binDatT1PLR[binNo]  = valuesArr[6].to_f


              end



            end



            # Get Electric furnace data
            if ( $EFBCparse )
              debug_out("ROUTSTR ? Electric Furnace :  #{$lineIn} \n")
              if ($lineIn =~ /ElectricFurnaceBC:/ || $lineIn !~ /^\s*[0-9]/)
                # Header - ignore
              else

                valuesArr = $lineIn.split()
                binNo = valuesArr[0].to_i
                $binDatHLR[binNo]  = valuesArr[1].to_f
                $binDatT1PLR[binNo]  = valuesArr[3].to_f


              end
            end


            # Get heat pump data
            if ( $HPparse )
              debug_out("ROUTSTR ? Heat pump : #{$lineIn} \n")
              if ($lineIn =~ /AboveHPBP/ || $lineIn !~ /^\s*[0-9]/ )
                # Header - ignore
              else
                valuesArr = $lineIn.split()
                binNo = valuesArr[0].to_i
                $binDatHLR[binNo]    = valuesArr[2].to_f
                $binDatT2cap[binNo]  = valuesArr[4].to_f
                $binDatT2PLR[binNo]  = valuesArr[5].to_f


              end
            end

          end
          # end of while loop


          stream_out("done.\n")
          fRoutStr.close()
          #rescue
          #  fatalerror("Could not read ROutStr.txt\n")

          #end
        end
        #of reading ROUTSTR file





        debug_out(" bin data: #{'%4s' "bin"} #{'%12s' % "$binDatHrs"} #{'%12s' % "$binDatTmp"}  #{'%12s' % "$binDatTsfB"} #{'%12s' % "$binDatHLR"} #{'%12s' % "$binDatT1PLR"} #{'%12s' % "$binDatT2PLR"} #{'%12s' % "$binDatT2cap"}\n" )
        32.times do |n|

          bin = n + 1
          debug_out(" bin data: #{'%4s' % bin} #{'%12s' % $binDatHrs[bin]} #{'%12s' % $binDatTmp[bin]}  #{'%12s' % $binDatTsfB[bin]} #{'%12s' % $binDatHLR[bin]} #{'%12s' % $binDatT1PLR[bin]} #{'%12s' % $binDatT2PLR[bin]}  #{'%12s' % $binDatT2cap[bin]}\n" )

        end










        # Determine if need to read old ERS number based on existence of file Set_EGH.h2k in H2K folder
        if File.exist?("#{$run_path}\\Set_EGH.h2k") then
          bReadOldERSValue = true
        end


        # Read from Browse.rpt ASCII file *if* data not available in XML (.h2k file)!
        if bReadOldERSValue || bReadAirConditioningLoad || $PVIntModel
          begin
            fBrowseRpt = File.new("#{$OutputFolder}\\Browse.Rpt", "r")
            while !fBrowseRpt.eof? do
              lineIn = fBrowseRpt.readline
              # Sequentially read file lines
              lineIn.strip!
              # Remove leading and trailing whitespace
              if ( lineIn !~ /^\s*$/ )
                # Not an empty line!
                if ( bReadOldERSValue && lineIn =~ /^Energuide Rating \(not rounded\) =/ )
                  lineIn.sub!(/Energuide Rating \(not rounded\) =/, '')
                  lineIn.strip!
                  $gERSNum = lineIn.to_f
                  # Use * scaleData?
                  bReadOldERSValue = false
                  break if !$PVIntModel
                  # Stop parsing Browse.rpt when ERS number found!
                elsif ( ( $PVIntModel && lineIn =~ /PHOTOVOLTAIC SYSTEM MONTHLY PERFORMANCE/ ) || ( $PVIntModel && bUseNextPVLine ) )
                  bUseNextPVLine = true
                  if ( lineIn =~ /^Annual/ )
                    valuesArr = lineIn.split()
                    # Uses spaces by default to split-up line
                    $annPVPowerFromBrowseRpt = valuesArr[4].to_f * 12.0 / 1000.0
                    # kW (approx PV power)
                    break
                    # PV power near bottom and last value to read!
                  end
                elsif ( (bReadAirConditioningLoad && lineIn =~ /AIR CONDITIONING SYSTEM PERFORMANCE/) || bUseNextACLine)
                  bUseNextACLine = true
                  if ( lineIn =~ /^Ann/ )
                    # Look for the annual results
                    valuesArr = lineIn.split()
                    # Uses spaces by default to split-up line
                    $annACSensibleLoadFromBrowseRpt = valuesArr[1].to_f
                    #Annual AirConditioning Sensible Load (MJ)
                    $annACLatentLoadFromBrowseRpt = valuesArr[2].to_f
                    #Annual AirConditioning Latent Load (MJ)
                    $AvgACCOP = valuesArr[8].to_f
                    #Average COP of AirConditioning
                    $TotalAirConditioningLoad = ($annACSensibleLoadFromBrowseRpt + $annACLatentLoadFromBrowseRpt) / 1000.0
                    # Divided by 1000 to convert unit to GJ
                    bUseNextACLine = false
                    break if !$PVIntModel
                    # Stop parsing Browse.rpt if noting else required!
                  end
                end
              end
            end
            fBrowseRpt.close()
          rescue
            fatalerror("Could not read Browse.Rpt.\n")
          end
        end

        # ===================== Get house information from the XML file
        if ($FlagHouseInfo)
          getHouseInfo(h2kPostElements)
        end

        # ===================== Get envelope characteristics from the XML file
        getEnvelopeSpecs(h2kPostElements)

        # ==================== Get electricity rate structure for external PV model use
        if ($PVsize !~ /NoPV/ )
          locationText = "HouseFile/FuelCosts/Electricity/Fuel/Minimum"
          $gElecRate["ElecMthMinCharge$"] = h2kPostElements[locationText].attributes["charge"].to_f
          locationText = "HouseFile/FuelCosts/Electricity/Fuel/RateBlocks/Block1"
          $gElecRate["ElecBlck1Units"] = h2kPostElements[locationText].attributes["units"].to_f
          $gElecRate["ElecBlck1CostPerUnit"] = h2kPostElements[locationText].attributes["costPerUnit"].to_f
          if ( h2kPostElements[locationText].attributes["units"] != "99999" )
            locationText = "HouseFile/FuelCosts/Electricity/Fuel/RateBlocks/Block2"
            $gElecRate["ElecBlck2Units"] = h2kPostElements[locationText].attributes["units"].to_f
            $gElecRate["ElecBlck2CostPerUnit"] = h2kPostElements[locationText].attributes["costPerUnit"].to_f
            if ( h2kPostElements[locationText].attributes["units"] != "99999" )
              locationText = "HouseFile/FuelCosts/Electricity/Fuel/RateBlocks/Block3"
              $gElecRate["ElecBlck3Units"] = h2kPostElements[locationText].attributes["units"].to_f
              $gElecRate["ElecBlck3CostPerUnit"] = h2kPostElements[locationText].attributes["costPerUnit"].to_f
              if ( h2kPostElements[locationText].attributes["units"] != "99999" )
                locationText = "HouseFile/FuelCosts/Electricity/Fuel/RateBlocks/Block4"
                $gElecRate["ElecBlck4Units"] = h2kPostElements[locationText].attributes["units"].to_f
                $gElecRate["ElecBlck4CostPerUnit"] = h2kPostElements[locationText].attributes["costPerUnit"].to_f
              end
            end
          end
        end

        # Get house heated floor area
        $FloorArea = H2KFile.getHeatedFloorArea( h2kPostElements )
        $HouseVolume= h2kPostElements["HouseFile/House/NaturalAirInfiltration/Specifications/House"].attributes["volume"].to_f
        # ==================== Get results for all h2k calcs from XML file (except above case)

        parseDebug = true
        $HCRequestedfound = false
        $HCGeneralFound = false
        $HCSOCFound = false

        # Make sure that the code we want is available
        h2kPostElements["HouseFile/AllResults"].elements.each do |element|

          houseCode =  element.attributes["houseCode"]

          # 05-Feb-2018 JTB: Note that in Non-Program (ERS) mode there is no "houseCode" attribute in the single element results set!
          # When in Program mode there are multiple element results sets (7). The first set has no houseCode attribute, the next six (6)
          # do have a value for the houseCode attribute. The last set has the houseCode attribute of "UserHouse", which almost exactly
          # matches the first results set (General mode results).
          if (houseCode == nil && element.attributes["sha256"] != nil)
            houseCode = "General"
          end

          if (houseCode == "#{$outputHCode}" )
            $HCRequestedfoundfound = true
          end

          if ( houseCode == "SOC" )
            $HCSOCFound = true
          end

          if ( houseCode == "General" )
            $HCGeneralFound = true
          end

        end

        if ( ! $HCRequestedfound && $outputHCode != "General" )
          $ThisMsg = "HOT2000 didn't generate \"#{$outputHCode}\" result set. "

          if ( $HCSOCFound )
            $outputHCode = "SOC"
          elsif ( $HCGeneralFound )
            $outputHCode = "General"
          end

          $ThisMsg +=" Reporting result set \"#{$outputHCode}\" result instead. \n"
          warn_out($ThisMsg)
        end

        h2kPostElements["HouseFile/AllResults"].elements.each do |element|

          houseCode =  element.attributes["houseCode"]

          if (houseCode == nil && element.attributes["sha256"] != nil)
            houseCode = "General"
          end

          # JTB 31-Jan-2018: Limiting results parsing to 1 set specified by user in choice file and saved in $outputHCode
          if (houseCode =~ /#{$outputHCode}/)

            stream_out( "\n Parsing results from set: #{$outputHCode} ...")

            # Energy Consumption (Annual GJ)
            $gResults[houseCode]["avgEnergyTotalGJ"]        = element.elements[".//Annual/Consumption"].attributes["total"].to_f * scaleData
            $gResults[houseCode]["avgEnergyHeatingGJ"]      = element.elements[".//Annual/Consumption/SpaceHeating"].attributes["total"].to_f * scaleData
            $gResults[houseCode]["avgGrossHeatLossGJ"]      = element.elements[".//Annual/HeatLoss"].attributes["total"].to_f * scaleData
            $gResults[houseCode]["avgEnergyCoolingGJ"]      = element.elements[".//Annual/Consumption/Electrical"].attributes["airConditioning"].to_f * scaleData
            $gResults[houseCode]["avgEnergyVentilationGJ"]  = element.elements[".//Annual/Consumption/Electrical"].attributes["ventilation"].to_f * scaleData
            $gResults[houseCode]["avgEnergyEquipmentGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["baseload"].to_f * scaleData
            $gResults[houseCode]["avgEnergyWaterHeatingGJ"] = element.elements[".//Annual/Consumption/HotWater"].attributes["total"].to_f * scaleData

            if $ExtraOutput1 then
              # Total Heat Loss of all zones by component (GJ)
              $gResults[houseCode]["EnvHLTotalGJ"] = element.elements[".//Annual/HeatLoss"].attributes["total"].to_f * scaleData
              $gResults[houseCode]["EnvHLCeilingGJ"] = element.elements[".//Annual/HeatLoss"].attributes["ceiling"].to_f * scaleData
              $gResults[houseCode]["EnvHLMainWallsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["mainWalls"].to_f * scaleData
              $gResults[houseCode]["EnvHLWindowsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["windows"].to_f * scaleData
              $gResults[houseCode]["EnvHLDoorsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["doors"].to_f * scaleData
              $gResults[houseCode]["EnvHLExpFloorsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["exposedFloors"].to_f * scaleData
              $gResults[houseCode]["EnvHLCrawlspaceGJ"] = element.elements[".//Annual/HeatLoss"].attributes["crawlspace"].to_f * scaleData
              $gResults[houseCode]["EnvHLSlabGJ"] = element.elements[".//Annual/HeatLoss"].attributes["slab"].to_f * scaleData
              $gResults[houseCode]["EnvHLBasementBGWallGJ"] = element.elements[".//Annual/HeatLoss"].attributes["basementBelowGradeWall"].to_f * scaleData
              $gResults[houseCode]["EnvHLBasementAGWallGJ"] = element.elements[".//Annual/HeatLoss"].attributes["basementAboveGradeWall"].to_f * scaleData
              $gResults[houseCode]["EnvHLBasementFlrHdrsGJ"] = element.elements[".//Annual/HeatLoss"].attributes["basementFloorHeaders"].to_f * scaleData
              $gResults[houseCode]["EnvHLPonyWallGJ"] = element.elements[".//Annual/HeatLoss"].attributes["ponyWall"].to_f * scaleData
              $gResults[houseCode]["EnvHLFlrsAbvBasementGJ"] = element.elements[".//Annual/HeatLoss"].attributes["floorsAboveBasement"].to_f * scaleData
              $gResults[houseCode]["EnvHLAirLkVentGJ"] = element.elements[".//Annual/HeatLoss"].attributes["airLeakageAndNaturalVentilation"].to_f * scaleData

              # Annual DHW heating load [GJ] -- heating load (or demand) on DHW system (before efficiency applied)
              $gResults[houseCode]["AnnHotWaterLoadGJ"] = element.elements[".//Annual/HotWaterDemand"].attributes["base"].to_f * scaleData
            end

            # Design loads, other data
            $gResults[houseCode]["avgOthPeakHeatingLoadW"] = element.elements[".//Other"].attributes["designHeatLossRate"].to_f * scaleData
            $gResults[houseCode]["avgOthPeakCoolingLoadW"] = element.elements[".//Other"].attributes["designCoolLossRate"].to_f * scaleData

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

            if $ExtraOutput1 then
              # Annual SpaceHeating and HotWater energy by fuel type [GJ]
              $gResults[houseCode]["AnnSpcHeatElecGJ"] = element.elements[".//Annual/Consumption/Electrical"].attributes["spaceHeating"].to_f * scaleData
              $gResults[houseCode]["AnnSpcHeatGasGJ"] = element.elements[".//Annual/Consumption/NaturalGas"].attributes["spaceHeating"].to_f * scaleData
              $gResults[houseCode]["AnnSpcHeatOilGJ"] = element.elements[".//Annual/Consumption/Oil"].attributes["spaceHeating"].to_f * scaleData
              $gResults[houseCode]["AnnSpcHeatPropGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["spaceHeating"].to_f * scaleData
              $gResults[houseCode]["AnnSpcHeatWoodGJ"] = element.elements[".//Annual/Consumption/Wood"].attributes["spaceHeating"].to_f * scaleData
              $gResults[houseCode]["AnnHotWaterElecGJ"] = element.elements[".//Annual/Consumption/Electrical/HotWater"].attributes["dhw"].to_f * scaleData
              $gResults[houseCode]["AnnHotWaterGasGJ"] = element.elements[".//Annual/Consumption/NaturalGas"].attributes["hotWater"].to_f * scaleData
              $gResults[houseCode]["AnnHotWaterOilGJ"] = element.elements[".//Annual/Consumption/Oil"].attributes["hotWater"].to_f * scaleData
              $gResults[houseCode]["AnnHotWaterPropGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["hotWater"].to_f * scaleData
              $gResults[houseCode]["AnnHotWaterWoodGJ"] = element.elements[".//Annual/Consumption/Wood"].attributes["hotWater"].to_f * scaleData
            end

            $gResults[houseCode]["avgFueluseElecGJ"]    = element.elements[".//Annual/Consumption/Electrical"].attributes["total"].to_f * scaleData

            # Bug in v11.3b90: The annual electrical energy total is 0 even though its components are not. Workaround below.
            # 07-APR-2018 JTB: This should only be checked when there is NO internal PV model in use!
            if !$PVIntModel && $gResults[houseCode]["avgFueluseElecGJ"] == 0 then
              $gResults[houseCode]["avgFueluseElecGJ"] = element.elements[".//Annual/Consumption/Electrical"].attributes["baseload"].to_f * scaleData +
              element.elements[".//Annual/Consumption/Electrical"].attributes["airConditioning"].to_f * scaleData +
              element.elements[".//Annual/Consumption/Electrical"].attributes["appliance"].to_f * scaleData +
              element.elements[".//Annual/Consumption/Electrical"].attributes["lighting"].to_f * scaleData +
              element.elements[".//Annual/Consumption/Electrical"].attributes["heatPump"].to_f * scaleData +
              element.elements[".//Annual/Consumption/Electrical"].attributes["spaceHeating"].to_f * scaleData +
              element.elements[".//Annual/Consumption/Electrical"].attributes["spaceCooling"].to_f * scaleData +
              element.elements[".//Annual/Consumption/Electrical"].attributes["ventilation"].to_f * scaleData +
              element.elements[".//Annual/Consumption/Electrical/HotWater"].attributes["dhw"].to_f * scaleData
            end
            $gResults[houseCode]["avgFueluseNatGasGJ"]  = element.elements[".//Annual/Consumption/NaturalGas"].attributes["total"].to_f * scaleData
            $gResults[houseCode]["avgFueluseOilGJ"]     = element.elements[".//Annual/Consumption/Oil"].attributes["total"].to_f * scaleData
            $gResults[houseCode]["avgFuelusePropaneGJ"] = element.elements[".//Annual/Consumption/Propane"].attributes["total"].to_f * scaleData
            $gResults[houseCode]["avgFueluseWoodGJ"]    = element.elements[".//Annual/Consumption/Wood"].attributes["total"].to_f * scaleData

            $gResults[houseCode]["avgFueluseEleckWh"]  = $gResults[houseCode]["avgFueluseElecGJ"] * 277.77777778
            $gResults[houseCode]["avgFueluseNatGasM3"] = $gResults[houseCode]["avgFueluseNatGasGJ"] * 26.853
            $gResults[houseCode]["avgFueluseOilL"]     = $gResults[houseCode]["avgFueluseOilGJ"]  * 25.9576
            $gResults[houseCode]["avgFuelusePropaneL"] = $gResults[houseCode]["avgFuelusePropaneGJ"] / 25.23 * 1000
            $gResults[houseCode]["avgFueluseWoodcord"] = $gResults[houseCode]["avgFueluseWoodGJ"] / 18.30
            # estimated GJ/cord for wood/pellet burning from YHC Fuel Cost Comparison.xls

            $gResults[houseCode]["avgFuelCostsTotal$"] = $gResults[houseCode]["avgFuelCostsElec$"] +
            $gResults[houseCode]["avgFuelCostsNatGas$"] +
            $gResults[houseCode]["avgFuelCostsOil$"] +
            $gResults[houseCode]["avgFuelCostsPropane$"] +
            $gResults[houseCode]["avgFuelCostsWood$"]

            # JTB 10-Nov-2016: Changed variable name from avgEnergyTotalGJ to "..Gross.." and uncommented
            # the reading of avgEnergyTotalGJ above. This value does NOT include utilized PV energy and
            # avgEnergyTotalGJ does when there is an internal H2K PV model.
            $gResults[houseCode]["avgEnergyGrossGJ"]  = $gResults[houseCode]['avgEnergyHeatingGJ'].to_f +
            $gResults[houseCode]['avgEnergyWaterHeatingGJ'].to_f +
            $gResults[houseCode]['avgEnergyVentilationGJ'].to_f +
            $gResults[houseCode]['avgEnergyCoolingGJ'].to_f +
            $gResults[houseCode]['avgEnergyEquipmentGJ'].to_f



            monthArr = [ "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december" ]
            # Picking up  AUX energy requirement from each result set.

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
              $gResults[houseCode]["avgEnergyPVAvailableGJ"] = pvAvailable
              # GJ
              $gResults[houseCode]["avgEnergyPVUtilizedGJ"]  = pvUtilized
              # GJ
              $gResults[houseCode]["avgElecPVGenkWh"] = $gResults[houseCode]["avgEnergyPVAvailableGJ"] * 277.777778
              # kWh
              $gResults[houseCode]["avgElecPVUsedkWh"] = $gResults[houseCode]["avgEnergyPVUtilizedGJ"] * 277.777778
              # kWh

              # ***** Calculation of NET PV Revenue using HOT2000 model *****
              # 10-Nov-2016 JTB: Assumes that all annual PV energy available is used to reduce house electricity
              # to zero first, the balance is sold to utility at the rate PVTarrifDollarsPerkWh,
              # which is specified in the options file (defaulted at top if not in Options file!).
              netAnnualPV = $gResults[houseCode]["avgElecPVGenkWh"] - $gResults[houseCode]["avgElecPVUsedkWh"]
              if ( netAnnualPV > 0 )
                $gResults[houseCode]["avgPVRevenue"] = netAnnualPV  * $PVTarrifDollarsPerkWh
              else
                $gResults[houseCode]["avgPVRevenue"] = 0
              end
            else
              # Calculate and reset these values below if external PV model used
              $gResults[houseCode]["avgEnergyPVAvailableGJ"] = 0.0
              $gResults[houseCode]["avgEnergyPVUtilizedGJ"]  = 0.0
              $gResults[houseCode]["avgElecPVGenkWh"] = 0.0
              $gResults[houseCode]["avgElecPVUsedkWh"] = 0.0
              $gResults[houseCode]["avgPVRevenue"] =  0.0
            end

            # This is used for debugging only.
            diff =  ( $gResults[houseCode]["avgFueluseElecGJ"].to_f +
              $gResults[houseCode]["avgFueluseNatGasGJ"].to_f -
              $gResults[houseCode]["avgEnergyPVUtilizedGJ"]) - $gResults[houseCode]["avgEnergyTotalGJ"].to_f
              $gResults[houseCode]["zH2K-debug-Energy"] = diff.to_f * scaleData

              break
              # break out of the element loop to avoid further processing

            end

          end
          # h2kPostElements |element| loop (and scope of local variable houseCode!)

          # TSV output
        	locationText = "HouseFile/Program/Results/Tsv"
        	if h2kPostElements["HouseFile/Program"] != nil
        		$TsvOutput = true
        		$gResults["TSV"]["ERSRating"] = h2kPostElements[locationText].elements["ERSRating"].attributes["value"].to_f
        		$gResults["TSV"]["ERSRefHouseRating"] = h2kPostElements[locationText].elements["ERSRefHouseRating"].attributes["value"].to_f
        		$gResults["TSV"]["ERSGHG"] = h2kPostElements[locationText].elements["ERSGHG"].attributes["value"].to_f
        	end



          if ( $gDebug )
            $gResults.each do |houseCode, data|
              debug_out (">Results for " << houseCode.to_s)
              data.each do | var, value |
                debug_out ("  - " << var.to_s << " : " << value.to_s )
              end
            end
          end

          $gAvgCost_Pellet = 0
          # H2K doesn't identify pellets in output (only inputs)!

          # Total of all fuels in GJ
          $gAvgEnergy_Total = $gResults[$outputHCode]["avgFueluseElecGJ"] + $gResults[$outputHCode]["avgFueluseNatGasGJ"] +
          $gResults[$outputHCode]["avgFueluseOilGJ"] + $gResults[$outputHCode]["avgFuelusePropaneGJ"] +
          $gResults[$outputHCode]["avgFueluseWoodGJ"]

          # JTB 12-Nov-2016 : Updated and still valid. Sets cost of PV based on model type
          #                   and estimates PV kW size.
          # PV Data cost...
          $PVArrayCost = 0.0
          $PVArraySized = 0.0
          # Stand-off PV code depriciated. Need to figure out how to get PV size from H2k results.
          $PVsize = "NoPV"
          $PVcapacity = $PVsize
          $PVcapacity.gsub(/[a-zA-Z:\s'\|]/, '')
          if ( !$PVIntModel && ( $PVcapacity == "" || $PVcapacity == "NoPV" ) )
            $PVcapacity = 0.0
          end
          if ( $PVIntModel )
            if ( $PVInt != "NA" )
              # JTB 03-Nov-2016: The Cost field for Opt-H2K-PV is total cost NOT unit cost!!
              $PVUnitCost = $gOptions["Opt-H2K-PV"]["options"][ $gChoices["Opt-H2K-PV"] ]["cost"].to_f
              $PVUnitOutput = 0.0
              # GJ/kW not used or estimated for internal H2K PV model
            else
              # No PV option specified in choice file (PV internal model part of base file)
              $PVUnitCost = 0.0
              $PVUnitOutput = 0.0
            end
          elsif ( $PVsize != "NoPV" )

            # Depreciated - to be removed.
            #$PVUnitCost = $gOptions["Opt-StandoffPV"]["options"]["SizedPV"]["cost"].to_f
            #$PVUnitOutput = $gOptions["Opt-StandoffPV"]["options"]["SizedPV"]["ext-result"]["production-elec-perKW"].to_f  # GJ/kW
          end

          if ( $PVsize =~ /NoPV/ )
            # NoPV
            $gPVProduction = 0.0
            $PVArrayCost = 0.0
          elsif ( $PVsize =~ /SizedPV/ )
            # Size PV according to user specification, to max, or to size required to reach Net-Zero.
            # User-specified PV size (format is 'SizedPV|XkW', PV will be sized to X kW'.
            if ( $gExtraDataSpecd["Opt-StandoffPV"] =~ /kW/ )
              $PVArraySized = $gExtraDataSpecd["Opt-StandoffPV"].to_f
              # ignores "kW" in string
              $PVArrayCost = $PVUnitCost * $PVArraySized
              $gPVProduction = -1.0 * $PVUnitOutput * $PVArraySized
              $PVsize = "spec'd SizedPV | #{$PVArraySized} kW"
            else
              # USER Hasn't specified PV size, Size PV to attempt to get to net-zero.
              # First, get the home's total energy requirement.
              $prePVEnergy = $gAvgEnergy_Total
              if ( $prePVEnergy > 0 )
                # This should always be the case!
                $PVArraySized = $prePVEnergy / $PVUnitOutput
                # KW Capacity
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
              # Debug: How big is the sized array?
              debug_out ("\n PV array is #{$PVsize}  ...\n")
            end
          end

          # Depreciated. To be deleted.
          #$gChoices["Opt-StandoffPV"] = $PVsize
          #$gOptions["Opt-StandoffPV"]["options"][$PVsize]["cost"] = $PVArrayCost


          # PV energy from HOT2000 model run (GJ) or estimate from option file PV data
          if ( $PVIntModel )
            $PVcapacity = $annPVPowerFromBrowseRpt
            # kW
            $PVsize = " H2K: " + "#{$PVcapacity.round(1)} kW"
            $gEnergyPV = $gResults[$outputHCode]["avgEnergyPVUtilizedGJ"]

            debug_out ("\n PV array is #{$PVsize}  ...\n")
          elsif ( $PVsize !~ /NoPV/ )
            # PV energy comes from an estimate using Opt-StandoffPV specification. Uses options file
            # number for GJ/kW PV energy production for location and roof pitch.
            $PVcapacity = $PVArraySized
            # kW
            $gEnergyPV = $gPVProduction * -1.0
            # GJ

            # Set values for external PV model (initialized to zero above)...
            $gResults[$outputHCode]["avgEnergyPVAvailableGJ"] = $gEnergyPV
            if ( $gResults[$outputHCode]["avgFueluseElecGJ"] > $gEnergyPV )
              # Decrease house electricity use by PV energy productions
              $gResults[$outputHCode]["avgEnergyPVUtilizedGJ"] = $gEnergyPV
              $gResults[$outputHCode]["avgFueluseElecGJ"] -= $gEnergyPV
              $gResults[$outputHCode]["avgFueluseEleckWh"] = $gResults[$outputHCode]["avgFueluseElecGJ"] * 277.77777778
              # Calculate new electricity cost and also update total fuel costs!
              calcElectCost( "annual" )
            else
              # PV production at least enough to cover house electrical needs!
              $gResults[$outputHCode]["avgEnergyPVUtilizedGJ"]  = $gResults[$outputHCode]["avgFueluseElecGJ"]
              $gResults[$outputHCode]["avgFueluseElecGJ"] = 0.0
              $gResults[$outputHCode]["avgFueluseEleckWh"] = 0.0
              # New electricity cost is just the monthly minimum (also update total fuel cost)!
              calcElectCost( "annualMin" )
            end
            $gResults[$outputHCode]["avgElecPVGenkWh"] = $gResults[$outputHCode]["avgEnergyPVAvailableGJ"] * 277.777778
            # kWh
            $gResults[$outputHCode]["avgElecPVUsedkWh"] = $gResults[$outputHCode]["avgEnergyPVUtilizedGJ"] * 277.777778
            # kWh

            netAnnualPV = $gResults[$outputHCode]["avgElecPVGenkWh"] - $gResults[$outputHCode]["avgElecPVUsedkWh"]
            if ( netAnnualPV > 0 )
              $gResults[$outputHCode]["avgPVRevenue"] = netAnnualPV  * $PVTarrifDollarsPerkWh
            else
              $gResults[$outputHCode]["avgPVRevenue"] = 0
            end
          end

          stream_out( " done \n")

          stream_out drawRuler("Simulation Results")

          stream_out  "\n Peak Heating Load (W): #{$gResults[$outputHCode]['avgOthPeakHeatingLoadW'].round(1)}  \n"
          stream_out  " Peak Cooling Load (W): #{$gResults[$outputHCode]['avgOthPeakCoolingLoadW'].round(1)}  \n"

          stream_out("\n Energy Consumption: \n\n")
          stream_out ( "  #{$gResults[$outputHCode]['avgEnergyHeatingGJ'].round(1)} ( Space Heating, GJ ) \n")
          stream_out ( "  #{$gResults[$outputHCode]['avgEnergyWaterHeatingGJ'].round(1)} ( Hot Water, GJ ) \n")
          stream_out ( "  #{$gResults[$outputHCode]['avgEnergyVentilationGJ'].round(1)} ( Ventilator Electrical, GJ ) \n")
          stream_out ( "  #{$gResults[$outputHCode]['avgEnergyCoolingGJ'].round(1)} ( Space Cooling, GJ ) \n")
          stream_out ( "  #{$gResults[$outputHCode]['avgEnergyEquipmentGJ'].round(1)} ( Appliances + Lights + Plugs + outdoor, GJ ) \n")
          stream_out ( " --------------------------------------------------------\n")
          stream_out ( "  #{$gResults[$outputHCode]['avgEnergyGrossGJ'].round(1)} ( H2K Gross energy use GJ ) \n")

          if ( parseDebug )
            $check = $gResults[$outputHCode]['avgEnergyHeatingGJ'].to_f +
            $gResults[$outputHCode]['avgEnergyWaterHeatingGJ'].to_f +
            $gResults[$outputHCode]['avgEnergyVentilationGJ'].to_f +
            $gResults[$outputHCode]['avgEnergyCoolingGJ'].to_f +
            $gResults[$outputHCode]['avgEnergyEquipmentGJ'].to_f
            stream_out ("       ( Check1: should = #{$check.round(1)}, ")
            stream_out ("Check2: avgEnergyTotalGJ = #{$gResults[$outputHCode]['avgEnergyTotalGJ'].round(1)} ) \n ")
          end

          if $ExtraOutput1 then
            stream_out("\n Components of envelope heat loss: \n\n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLCeilingGJ'].round(1)} ( Envelope Ceiling Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLMainWallsGJ'].round(1)} ( Envelope Main Wall Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLWindowsGJ'].round(1)} ( Envelope Window Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLDoorsGJ'].round(1)} ( Envelope Door Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLExpFloorsGJ'].round(1)} ( Envelope Exp Floor Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLCrawlspaceGJ'].round(1)} ( Envelope Crawlspace Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLSlabGJ'].round(1)} ( Envelope Slab Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLBasementBGWallGJ'].round(1)} ( Envelope BG Basement Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLBasementAGWallGJ'].round(1)} ( Envelope AG Basement Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLBasementFlrHdrsGJ'].round(1)} ( Envelope Basement Floor Hdr Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLPonyWallGJ'].round(1)} ( Envelope Pony Wall Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLFlrsAbvBasementGJ'].round(1)} ( Envelope Floors Above Basement Heat Loss (all zones), GJ ) \n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLAirLkVentGJ'].round(1)} ( Envelope Air Leakage & Ventilation Heat Loss (all zones), GJ ) \n")
            stream_out ( " --------------------------------------------------------\n")
            stream_out ( "  #{$gResults[$outputHCode]['EnvHLTotalGJ'].round(1)} ( Envelope Total Heat Loss (as reported in file), GJ ) \n")

            if ( parseDebug )
              $check = $gResults[$outputHCode]['EnvHLCeilingGJ'].to_f +
              $gResults[$outputHCode]['EnvHLMainWallsGJ'].to_f +
              $gResults[$outputHCode]['EnvHLWindowsGJ'].to_f +
              $gResults[$outputHCode]['EnvHLDoorsGJ'].to_f +
              $gResults[$outputHCode]['EnvHLExpFloorsGJ'].to_f +
              $gResults[$outputHCode]['EnvHLCrawlspaceGJ'].to_f +
              $gResults[$outputHCode]['EnvHLSlabGJ'].to_f +
              $gResults[$outputHCode]['EnvHLBasementBGWallGJ'].to_f +
              $gResults[$outputHCode]['EnvHLBasementAGWallGJ'].to_f +
              $gResults[$outputHCode]['EnvHLBasementFlrHdrsGJ'].to_f +
              $gResults[$outputHCode]['EnvHLPonyWallGJ'].to_f +
              $gResults[$outputHCode]['EnvHLAirLkVentGJ'].to_f
              stream_out ("       ( Note: sum above without basement floor above HL = #{$check.round(1)} )")
            end

            stream_out ( "\n\n  #{$gResults[$outputHCode]["AnnHotWaterLoadGJ"].round(1)} ( Annual DHW heating load, GJ ) \n")
          end

          stream_out("\n\n Energy Cost (not including credit for PV, direction #{$gRotationAngle} ): \n\n")
          stream_out("  + \$ #{$gResults[$outputHCode]['avgFuelCostsElec$'].round(2)}  (Electricity)\n")
          stream_out("  + \$ #{$gResults[$outputHCode]['avgFuelCostsNatGas$'].round(2)} (Natural Gas)\n")
          stream_out("  + \$ #{$gResults[$outputHCode]['avgFuelCostsOil$'].round(2)}  (Oil)\n")
          stream_out("  + \$ #{$gResults[$outputHCode]['avgFuelCostsPropane$'].round(2)}  (Propane)\n")
          stream_out("  + \$ #{$gResults[$outputHCode]['avgFuelCostsWood$'].round(2)}  (Wood) \n")
          #   stream_out("  + \$ #{$gResults[$outputHCode][''].round(2)}  #{$gAvgCost_Pellet.round(2)} (Pellet)\n")
          stream_out ( " --------------------------------------------------------\n")
          stream_out ( "    \$ #{$gResults[$outputHCode]['avgFuelCostsTotal$'].round(2)}  (All utilities).\n")
          stream_out ( "\n")

          netAnnualPV = $gResults[$outputHCode]['avgElecPVGenkWh'] - $gResults[$outputHCode]['avgElecPVUsedkWh']

          stream_out ( "  - \$ #{$gResults[$outputHCode]['avgPVRevenue'].round(2)} (**Net PV revenue for #{$PVcapacity.round(0)} kW unit: #{netAnnualPV.round(0)} kWh at \$ #{$PVTarrifDollarsPerkWh} / kWh)\n")
          stream_out ( " --------------------------------------------------------\n")

          netUtilityCost = $gResults[$outputHCode]['avgFuelCostsTotal$'] - $gResults[$outputHCode]['avgPVRevenue']

          stream_out ( "    \$ #{netUtilityCost.round(2)} (Net utility costs).\n")
          stream_out ( "\n")

          if $ExtraOutput1 then
            stream_out("\n Space Heating Energy Use by Fuel (GJ): \n\n")
            stream_out("  - #{$gResults[$outputHCode]["AnnSpcHeatElecGJ"].round(1)} (Space Heating Electricity, GJ)\n")
            stream_out("  - #{$gResults[$outputHCode]["AnnSpcHeatGasGJ"].round(1)} (Space Heating Natural Gas, GJ)\n")
            stream_out("  - #{$gResults[$outputHCode]["AnnSpcHeatOilGJ"].round(1)} (Space Heating Oil, GJ)\n")
            stream_out("  - #{$gResults[$outputHCode]["AnnSpcHeatPropGJ"].round(1)} (Space Heating Propane, GJ)\n")
            stream_out("  - #{$gResults[$outputHCode]["AnnSpcHeatWoodGJ"].round(1)} (Space Heating Wood, GJ)\n")
            stream_out("  - #{$gResults[$outputHCode]["AnnHotWaterElecGJ"].round(1)} (Hot Water Heating Electricity, GJ)\n")
            stream_out("  - #{$gResults[$outputHCode]["AnnHotWaterGasGJ"].round(1)} (Hot Water Heating Natural Gas, GJ)\n")
            stream_out("  - #{$gResults[$outputHCode]["AnnHotWaterOilGJ"].round(1)} (Hot Water Heating Oil, GJ)\n")
            stream_out("  - #{$gResults[$outputHCode]["AnnHotWaterPropGJ"].round(1)} (Hot Water Heating Propane, GJ)\n")
            stream_out("  - #{$gResults[$outputHCode]["AnnHotWaterWoodGJ"].round(1)} (Hot Water Heating Wood, GJ)\n")
          end

          stream_out("\n\n Total Energy Use by Fuel (in fuel units, not including credit for PV, direction #{$gRotationAngle} ): \n\n")
          stream_out("  - #{$gResults[$outputHCode]['avgFueluseEleckWh'].round(0)} (Total Electricity, kWh)\n")
          stream_out("  - #{$gResults[$outputHCode]['avgFueluseNatGasM3'].round(0)} (Total Natural Gas, m3)\n")
          stream_out("  - #{$gResults[$outputHCode]['avgFueluseOilL'].round(0)} (Total Oil, l)\n")
          stream_out("  - #{$gResults[$outputHCode]['avgFuelusePropaneL'].round(0)} (Total Propane, l)\n")

          # ASF 03-Oct-2016:
          # Wood/Pellets
          stream_out("  - #{$gResults[$outputHCode]['avgFueluseWoodcord'].round(0)} (Total Wood, cord)\n")
          # stream_out("  - #{$gAvgPelletCons_t.round(1)} (Pellet, tonnes)\n")
          # stream_out ("> SCALE #{scaleData} \n");
          # Estimate total cost of upgrades


          if ( $gERSNum > 0 )
            $tmpval = $gERSNum.round(1)
            stream_out(" ERS value: #{$tmpval}\n")
          end

        end
        # End of postprocess

        # =========================================================================================
        # Get the general information about the house
        # =========================================================================================
        def getHouseInfo (elements)


          $BuilderName  = H2KFile.getBuilderName(elements)
          $HouseType    = H2KFile.getHouseType(elements)
          $HouseStoreys = H2KFile.getStoreys(elements)

          locationText = "HouseFile/House/Components/Ceiling"
          areaCeiling_temp = 0.0
          elements.each(locationText) do |ceiling|
            if ceiling.elements["Measurements"].attributes["area"].to_f > areaCeiling_temp
              $Ceilingtype = ceiling.elements["Construction"].elements["Type"].elements["English"].text
              $Ceilingtype.gsub!(/\s*/, '')
              # Removes mid-line white space
              $Ceilingtype.gsub!(',', '-')
              # Replace ',' with '-'. Necessary for CSV reporting

              areaCeiling_temp = ceiling.elements["Measurements"].attributes["area"].to_f
            end
          end

          $FoundationArea = Hash.new(0)
          locationText = "HouseFile/House/Components/Floor"
          areaFloor_temp = 0.0
          elements.each(locationText) do |floor|
            areaFloor_temp = floor.elements["Measurements"].attributes["area"].to_f
            $FoundationArea["Floor"] += areaFloor_temp
          end

          locationText = "HouseFile/House/Components/Basement"
          areaBasement_temp = 0.0
          elements.each(locationText) do |basement|
            if basement.elements["Floor"].elements["Measurements"].attributes["isRectangular"] == "true"
              areaBasement_temp = basement.elements["Floor"].elements["Measurements"].attributes["width"].to_f*basement.elements["Floor"].elements["Measurements"].attributes["length"].to_f
            else
              areaBasement_temp = basement.elements["Floor"].elements["Measurements"].attributes["area"].to_f
            end
            $FoundationArea["Basement"] += areaBasement_temp
          end

          locationText = "HouseFile/House/Components/Crawlspace"
          areaCrawl_temp = 0.0
          elements.each(locationText) do |crawl|
            if crawl.attributes["isRectangular"] == "true"
              areaCrawl_temp = crawl.elements["Floor"].elements["Measurements"].attributes["width"].to_f*crawl.elements["Floor"].elements["Measurements"].attributes["length"].to_f
            else
              areaCrawl_temp = crawl.elements["Floor"].elements["Measurements"].attributes["area"].to_f
            end
            $FoundationArea["Crawl"] += areaCrawl_temp
          end

          locationText = "HouseFile/House/Components/Slab"
          areaSlab_temp = 0.0
          elements.each(locationText) do |slab|
            if slab.attributes["isRectangular"] == "true"
              areaSlab_temp = slab.elements["Floor"].elements["Measurements"].attributes["width"].to_f*slab.elements["Floor"].elements["Measurements"].attributes["length"].to_f
            else
              areaSlab_temp = slab.elements["Floor"].elements["Measurements"].attributes["area"].to_f
            end
            $FoundationArea["Slab"] += areaSlab_temp
          end

          locationText = "HouseFile/House/Components/Walkout"
          areaWalkout_temp = 0.0
          elements.each(locationText) do |walkout|
            areaWalkout_temp = walkout.elements["Measurements"].attributes["l1"].to_f*walkout.elements["Measurements"].attributes["l2"].to_f
            $FoundationArea["Walkout"] += areaWalkout_temp
          end


        end
        # End of getHouseInfo

        # =========================================================================================
        # Get the average characteristics of building facade by orientation
        # =========================================================================================
        def getEnvelopeSpecs(elements)
          # ====================================================================================
          # Parameter      Location
          # ====================================================================================
          # Orientation        HouseFile/House/Components/*/Components/Window/FacingDirection[code]
          # SHGC               HouseFile/House/Components/*/Components/Window[SHGC]
          # r-value            HouseFile/House/Components/*/Components/Window/Construction/Type/[rValue]
          # Height             HouseFile/House/Components/*/Components/Window/Measurements/[height]
          # Width              HouseFile/House/Components/*/Components/Window/Measurements/[width]

          $SHGCWin_sum = Hash.new(0)
          $uAValueWin_sum = Hash.new(0)
          $AreaWin_sum = Hash.new(0)
          $rValueWin = Hash.new(0)
          $SHGCWin = Hash.new(0)
          $UAValue = Hash.new(0)
          $RSI = Hash.new(0)
          $AreaComp = Hash.new(0)

          locationText = "HouseFile/House/Components/*/Components/Window"

          elements.each(locationText) do |window|
            areaWin_temp = 0.0
            # store the area of each windows
            winOrient = window.elements["FacingDirection"].attributes["code"].to_i
            # Windows orientation:  "S" => 1, "SE" => 2, "E" => 3, "NE" => 4, "N" => 5, "NW" => 6, "W" => 7, "SW" => 8
            areaWin_temp = (window.elements["Measurements"].attributes["height"].to_f * window.elements["Measurements"].attributes["width"].to_f)*window.attributes["number"].to_i / 1000000
            # [Height (mm) * Width (mm)] * No of Windows
            $SHGCWin_sum[winOrient] += window.attributes["shgc"].to_f * areaWin_temp
            # Adds the (SHGC * area) of each windows to summation for individual orientations
            $uAValueWin_sum[winOrient] += areaWin_temp / (window.elements["Construction"].elements["Type"].attributes["rValue"].to_f)
            # Adds the (area/RSI) of each windows to summation for individual orientations
            $AreaWin_sum[winOrient] += areaWin_temp
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
            $SHGCWin_sum[winOrient] += window.attributes["shgc"].to_f * areaWin_temp
            # Adds the (SHGC * area) of each windows to summation for individual orientations
            $uAValueWin_sum[winOrient] += areaWin_temp / (window.elements["Construction"].elements["Type"].attributes["rValue"].to_f)
            # Adds the (area/RSI) of each windows to summation for individual orientations
            $AreaWin_sum[winOrient] += areaWin_temp
            # Adds area of each windows to summation for individual orientations
          end

          (1..8).each do |winOrient|
            # Calculate the average weighted values for each orientation
            if $AreaWin_sum[winOrient] != 0
              # No windows exist if the total area is zero for an orientation
              $rValueWin[winOrient] = ($AreaWin_sum[winOrient] / $uAValueWin_sum[winOrient]).round(3)
              # Overall R-value is [A_tot/(U_tot*A_tot)]
              $SHGCWin[winOrient] = ($SHGCWin_sum[winOrient] / $AreaWin_sum[winOrient]).round(3)
              # Divide the summation of (area* SHGC) by total area
              $UAValue["win"] += $uAValueWin_sum[winOrient]
              # overall UA value is the summation of individual UA values
              $AreaComp["win"] += $AreaWin_sum[winOrient]
              # overall window area of the buildings
            end
          end

          locationText = "HouseFile/House/Components/*/Components/Door"

          elements.each(locationText) do |door|
            areaDoor_temp = 0.0
            # store area of each Door
            idDoor = door.attributes["id"].to_i
            areaDoor_temp = (door.elements["Measurements"].attributes["height"].to_f * door.elements["Measurements"].attributes["width"].to_f)
            # [Height (m) * Width (m)]

            locationWindows = "HouseFile/House/Components/*/Components/Door/Components/Window"
            areaWin_sum = 0.0
            elements.each(locationWindows) do |openings|
              if (openings.parent.parent.attributes["id"].to_i == idDoor)
                areaWin_temp = (openings.elements["Measurements"].attributes["height"].to_f * openings.elements["Measurements"].attributes["width"].to_f)*openings.attributes["number"].to_i / 1000000
                areaWin_sum += areaWin_temp
              end
            end

            areaDoor_temp -= areaWin_sum

            $UAValue["door"] += areaDoor_temp / (door.attributes["rValue"].to_f)
            # Adds the (area/RSI) of each door to summation
            $AreaComp["door"] += areaDoor_temp
            # Adds area of each door to summation
            $AreaComp["doorwin"] += areaWin_sum
          end

          $AreaWall_sum = 0.0
          $uAValueWall_sum = 0.0
          locationText = "HouseFile/House/Components/Wall"
          elements.each(locationText) do |wall|
            areaWall_temp = 0.0
            idWall = wall.attributes["id"].to_i
            areaWall_temp = wall.elements["Measurements"].attributes["height"].to_f * wall.elements["Measurements"].attributes["perimeter"].to_f

            locationWindows = "HouseFile/House/Components/Wall/Components/Window"
            areaWin_sum = 0.0
            elements.each(locationWindows) do |openings|
              if (openings.parent.parent.attributes["id"].to_i == idWall)
                areaWin_temp = (openings.elements["Measurements"].attributes["height"].to_f * openings.elements["Measurements"].attributes["width"].to_f)*openings.attributes["number"].to_i / 1000000
                areaWin_sum += areaWin_temp
              end
            end

            locationDoors = "HouseFile/House/Components/Wall/Components/Door"
            areaDoor_sum = 0.0
            elements.each(locationDoors) do |openings|
              if (openings.parent.parent.attributes["id"].to_i == idWall)
                areaDoor_temp = (openings.elements["Measurements"].attributes["height"].to_f * openings.elements["Measurements"].attributes["width"].to_f)
                areaDoor_sum += areaDoor_temp
              end
            end

            locationDoors = "HouseFile/House/Components/Wall/Components/FloorHeader"
            areaHeader_sum = 0.0
            uAValueHeader = 0.0
            elements.each(locationDoors) do |head|
              if (head.parent.parent.attributes["id"].to_i == idWall)
                areaHeader_temp = (head.elements["Measurements"].attributes["height"].to_f * head.elements["Measurements"].attributes["perimeter"].to_f)
                uAValueHeader_temp = areaHeader_temp / head.elements["Construction"].elements["Type"].attributes["rValue"].to_f
                areaHeader_sum += areaHeader_temp
                uAValueHeader += uAValueHeader_temp
              end
            end

            areaWall_temp -= (areaWin_sum + areaDoor_sum)
            uAValueWall = areaWall_temp / wall.elements["Construction"].elements["Type"].attributes["rValue"].to_f
            $UAValue["wall"] += uAValueWall
            $AreaComp["wall"] += areaWall_temp
          end

          locationText = "HouseFile/House/Components/*/Components/FloorHeader"
          elements.each(locationText) do |head|
            areaHeader_temp = 0.0
            areaHeader_temp = head.elements["Measurements"].attributes["height"].to_f * head.elements["Measurements"].attributes["perimeter"].to_f
            $UAValue["header"] += areaHeader_temp / head.elements["Construction"].elements["Type"].attributes["rValue"].to_f
            $AreaComp["header"] += areaHeader_temp
          end

          locationText = "HouseFile/House/Components/Ceiling"
          elements.each(locationText) do |ceiling|
            areaCeiling_temp = 0.0
            areaCeiling_temp = ceiling.elements["Measurements"].attributes["area"].to_f
            $UAValue["ceiling"] += areaCeiling_temp / ceiling.elements["Construction"].elements["CeilingType"].attributes["rValue"].to_f
            $AreaComp["ceiling"] += areaCeiling_temp
          end

          locationText = "HouseFile/House/Components/Floor"
          elements.each(locationText) do |floor|
            areaFloor_temp = 0.0
            areaFloor_temp = floor.elements["Measurements"].attributes["area"].to_f
            $UAValue["floor"] += areaFloor_temp / floor.elements["Construction"].elements["Type"].attributes["rValue"].to_f
            $AreaComp["floor"] += areaFloor_temp
          end

          $UAValue["house"] = 0.0
          $AreaComp["house"] = 0.0
          $UAValue.each_key do |component|
            if ($UAValue[component]!= 0.0 && component !="house")
              $RSI[component] = $AreaComp[component] / $UAValue[component]
              $UAValue["house"] += $UAValue[component]
              $AreaComp["house"] += $AreaComp[component]
            end
          end
          $RSI["house"] = $AreaComp["house"] / $UAValue["house"]
          $R_ValueHouse = ($RSI["house"] * R_PER_RSI).round(1)

        end
        # End of getEnvelopeSpecs

        # =========================================================================================
        # Calculate electricity cost using global results array and electricity cost rate structure
        # This routine is only called when the PV external model is used!
        # =========================================================================================
        def calcElectCost( calcType )
          balancekWh = 0
          # Subtract old electricity cost from total before recalculating electricity cost
          $gResults[$outputHCode]["avgFuelCostsTotal$"] -= $gResults[$outputHCode]["avgFuelCostsElec$"]
          if ( calcType == "annualMin" )
            $gElecRate["avgFuelCostsElec$"] = $gElecRate["ElecMthMinCharge$"] * 12
          else
            if ( $gResults[$outputHCode]["avgFueluseEleckWh"] > $gElecRate["ElecBlck1Units"] )
              $gResults[$outputHCode]["avgFuelCostsElec$"] = $gElecRate["ElecBlck1Units"] * $gElecRate["ElecBlck1CostPerUnit"]
              balancekWh = $gResults[$outputHCode]["avgFueluseEleckWh"] - $gElecRate["ElecBlck1Units"]
              if ( balancekWh > $gElecRate["ElecBlck2Units"] )
                $gResults[$outputHCode]["avgFuelCostsElec$"] += $gElecRate["ElecBlck2Units"] * $gElecRate["ElecBlck2CostPerUnit"]
                balancekWh -= $gElecRate["ElecBlck2Units"]
                if ( balancekWh > $gElecRate["ElecBlck3Units"] )
                  $gResults[$outputHCode]["avgFuelCostsElec$"] += $gElecRate["ElecBlck3Units"] * $gElecRate["ElecBlck3CostPerUnit"]
                  balancekWh -= $gElecRate["ElecBlck3Units"]
                  $gResults[$outputHCode]["avgFuelCostsElec$"] += balancekWh * $gElecRate["ElecBlck4CostPerUnit"]
                else
                  $gResults[$outputHCode]["avgFuelCostsElec$"] += balancekWh * $gElecRate["ElecBlck3CostPerUnit"]
                end
              else
                $gResults[$outputHCode]["avgFuelCostsElec$"] += balancekWh * $gElecRate["ElecBlck2CostPerUnit"]
              end
            else
              $gResults[$outputHCode]["avgFuelCostsElec$"] = $gResults[$outputHCode]["avgFueluseEleckWh"] * $gElecRate["ElecBlck1CostPerUnit"]
            end
          end
          # Update total fuel cost variable
          $gResults[$outputHCode]["avgFuelCostsTotal$"] += $gResults[$outputHCode]["avgFuelCostsElec$"]
        end

        # =========================================================================================
        # Permafrost  ------------------------------------------------
        # =========================================================================================
        def set_permafrost_by_location(elements,cityName)

          if $PermafrostHash[cityName] == "continuous"

            soilCondition = elements["HouseFile/House/Specifications/SoilCondition"].attributes["code"]
            soilCondition = "3"
            elements["HouseFile/House/Specifications/SoilCondition"].attributes["code"] = soilCondition

          end
        end

        #===============================================================================
        # Get the unit cost value for the specified option and apply to the unit value
        # (e.g., ft2, linear ft, each, etc.) to calculate the extended cost.
        #
        # Search unit cost(s) from unitCostData hash already read from JSON file. This
        # may involve multiple materials that need to be summed. TotUnCost is the sum of
        # material and labour modified unit costs (i.e., includes multiplier).
        # Get appropriate multiplication factors from H2K file (e.g., floor area,
        # wall area, each, etc.). Calculate the total cost for the option passed.
        #
        # Note: This function called for base costs as well as upgrade cost. The
        #       difference is calculated and reported in SubstitutePL-output.txt
        #===============================================================================
        def getOptionCost( unitCostData, optName, optTag, optValue, elements )
          unitCost = 0
          cost = 0
          # Switch on Option type
          case optName
          when "Opt-ACH"
            #.................................................................................
            # Don't care about value of optTag since not used for air sealing
            unitCostData.select do |theOne|
              if theOne["MatCat1"]=="Envelope" && theOne["MatCat2"]=="AirTightness" &&
                theOne["Description"]=~/Upgrading/ && theOne["Description"]=~/#{optValue}/
                unitCost = theOne["TotUnCost"]
              end
            end
            if unitCost == 0
              # All other cases of air selaing upgrades: Use logarithmic fit equation from
              # data points in cost dB (Cost = -0.988 * ln(ACH) + 1.3216, R-squared = 0.9987).
              # This assumes that all air sealing upgrades start from an average house
              # air sealing rate of 3.57 ACH!
              if optValue.to_f < 3.5 && optValue.to_f > 0
                unitCost = -0.988 * Math.log(optValue.to_f, Math::E) + 1.3216
              end
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)  * SF_PER_SM
          when "Opt-Ceilings"
            #.................................................................................
            if ( optTag =~ /Opt-Ceiling/ )
              nominalR = 0
              ceilingArea = H2KFile.getCeilingArea( elements, "All", optValue) * SF_PER_SM
              # User-defined ceiling code name from code library!
              locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
              elements.each(locationText) do |element|
                unitCost = 0
                next if element.text != optValue
                nominalR = element.attributes["nominalInsulation"].to_f * R_PER_RSI
                unitCostData.select do |theOne|
                  if theOne["MatCat1"]=="Envelope" && theOne["MatCat2"]=="CeilingInsulation" &&
                    theOne["Description"]=~/R#{nominalR.round(0)}/
                    unitCost = theOne["TotUnCost"]
                  end
                end
                if unitCost == 0
                  # The nominal R-value for this ceiling code doesn't have an associated unit cost data item.
                  # Use regression fit (R-squared = 0.9987) to estimate cost.
                  unitCost = 0.038 * nominalR + 0.0253
                end
                cost += unitCost * ceilingArea
              end
            elsif ( optTag =~ /OPT-H2K-EffRValue/ )
              ceilingArea = H2KFile.getCeilingArea( elements, "All", "NA") * SF_PER_SM
              locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
              elements.each(locationText) do |element|
                unitCost = 0
                unitCostData.select do |theOne|
                  if theOne["MatCat1"]=="Envelope" && theOne["MatCat2"]=="CeilingInsulation" &&
                    theOne["Description"]=~/R#{optValue}/
                    unitCost = theOne["TotUnCost"]
                  end
                end
                if unitCost == 0
                  # The R-value used in options file doesn't have an associated unit cost data item. Use
                  # regression fit (R-squared = 0.9987)
                  unitCost = 0.038 * optValue.to_f + 0.0253
                end
                cost += unitCost * ceilingArea
              end
            end
          when "Opt-AtticCeilings"
            #.................................................................................
            if ( optTag =~ /Opt-Ceiling/ )
              # User-defined ceiling code name from code library!
              nominalR = 0
              # Get house ceiling area for attics only (Attic/Gable, Attic/Hip, Scissor)
              ceilingArea = H2KFile.getCeilingArea( elements,"Attics", optValue ) * SF_PER_SM
              locationText = "HouseFile/House/Components/Ceiling/Construction"
              elements.each(locationText) do |element|
                unitCost = 0
                next if element[1].attributes["code"] != "2" && element[1].attributes["code"] != "3" &&
                element[1].attributes["code"] != "6"
                next if element[3].text != optValue
                nominalR = element[3].attributes["nominalInsulation"].to_f * R_PER_RSI
                unitCostData.select do |theOne|
                  if theOne["MatCat1"]=="Envelope" && theOne["MatCat2"]=="CeilingInsulation" &&
                    theOne["Description"]=~/R#{nominalR.round(0)}/
                    unitCost = theOne["TotUnCost"]
                  end
                end
                if unitCost == 0
                  # The nominal R-value for this ceiling code doesn't have an associated unit cost data item.
                  # Use regression fit (R-squared = 0.9987) to estimate cost.
                  unitCost = 0.038 * nominalR + 0.0253
                end
                cost += unitCost * ceilingArea
              end
            elsif ( optTag =~ /OPT-H2K-EffRValue/ )
              # Get house ceiling area for attics only (Attic/Gable, Attic/Hip, Scissor)
              ceilingArea = H2KFile.getCeilingArea( elements,"Attics", "NA" ) * SF_PER_SM
              locationText = "HouseFile/House/Components/Ceiling/Construction"
              elements.each(locationText) do |element|
                unitCost = 0
                next if element[1].attributes["code"] != "2" && element[1].attributes["code"] != "3" &&
                element[1].attributes["code"] != "6"
                unitCostData.select do |theOne|
                  if theOne["MatCat1"]=="Envelope" && theOne["MatCat2"]=="CeilingInsulation" &&
                    theOne["Description"]=~/R#{optValue}/
                    unitCost = theOne["TotUnCost"]
                  end
                end
                if unitCost == 0
                  # The R-value used in options file doesn't have an associated unit cost data item. Use
                  # regression fit (R-squared = 0.9987)
                  unitCost = 0.038 * optValue.to_f + 0.0253
                end
                cost += unitCost * ceilingArea
              end
            elsif ( optTag =~ /OPT-H2K-HeelHeight/)
              # Do nothing -- raised-heel truss included in ceiling unit cost above
            end
          when "Opt-CathCeilings"
            #.................................................................................
            if ( optTag =~ /Opt-Ceiling/ )
              # User-defined ceiling code name from code library!
              nominalR = 0
              # Get house ceiling area for cathedral ceilings only
              ceilingArea = H2KFile.getCeilingArea( elements,"Cathedral", optValue ) * SF_PER_SM
              locationText = "HouseFile/House/Components/Ceiling/Construction"
              elements.each(locationText) do |element|
                unitCost = 0
                next if element[1].attributes["code"] != "4"
                next if element[3].text != optValue
                nominalR = element[3].attributes["nominalInsulation"].to_f * R_PER_RSI
                unitCostData.select do |theOne|
                  if theOne["MatCat1"]=="Envelope" && theOne["MatCat2"]=="CeilingInsulation" &&
                    theOne["Description"]=~/R#{nominalR.round(0)}/
                    unitCost = theOne["TotUnCost"]
                  end
                end
                if unitCost == 0
                  # The nominal R-value for this ceiling code doesn't have an associated unit cost data item.
                  # Use regression fit (R-squared = 0.9987) to estimate cost.
                  unitCost = 0.038 * nominalR + 0.0253
                end
                cost += unitCost * ceilingArea
              end
            elsif ( optTag =~ /OPT-H2K-EffRValue/ )
              # Get house ceiling area for cathedral ceilings only
              ceilingArea = H2KFile.getCeilingArea( elements,"Cathedral", "NA" ) * SF_PER_SM
              locationText = "HouseFile/House/Components/Ceiling/Construction"
              elements.each(locationText) do |element|
                unitCost = 0
                next if element[1].attributes["code"] != "4"
                unitCostData.select do |theOne|
                  if theOne["MatCat1"]=="Envelope" && theOne["MatCat2"]=="CeilingInsulation" &&
                    theOne["Description"]=~/R#{optValue}/
                    unitCost = theOne["TotUnCost"]
                  end
                end
                if unitCost == 0
                  # The R-value used in options file doesn't have an associated unit cost data item. Use
                  # regression fit (R-squared = 0.9987)
                  unitCost = 0.038 * optValue.to_f + 0.0253
                end
                cost += unitCost * ceilingArea
              end
            end
          when "Opt-FlatCeilings"
            #.................................................................................
            if ( optTag =~ /Opt-Ceiling/ )
              # User-defined ceiling code name from code library!
              nominalR = 0
              # Get house ceiling area for flat ceilings only
              ceilingArea = H2KFile.getCeilingArea( elements,"Flat", optValue ) * SF_PER_SM
              locationText = "HouseFile/House/Components/Ceiling/Construction"
              elements.each(locationText) do |element|
                unitCost = 0
                next if element[1].attributes["code"] != "5"
                next if element[3].text != optValue
                nominalR = element[3].attributes["nominalInsulation"].to_f * R_PER_RSI
                unitCostData.select do |theOne|
                  if theOne["MatCat1"]=="Envelope" && theOne["MatCat2"]=="CeilingInsulation" &&
                    theOne["Description"]=~/R#{nominalR.round(0)}/
                    unitCost = theOne["TotUnCost"]
                  end
                end
                if unitCost == 0
                  # The nominal R-value for this ceiling code doesn't have an associated unit cost data item.
                  # Use regression fit (R-squared = 0.9987) to estimate cost.
                  unitCost = 0.038 * nominalR + 0.0253
                end
                cost += unitCost * ceilingArea
              end
            elsif ( optTag =~ /OPT-H2K-EffRValue/ )
              # Get house ceiling area for cathedral ceilings only
              ceilingArea = H2KFile.getCeilingArea( elements,"Flat", "NA" ) * SF_PER_SM
              locationText = "HouseFile/House/Components/Ceiling/Construction"
              elements.each(locationText) do |element|
                unitCost = 0
                next if element[1].attributes["code"] != "5"
                unitCostData.select do |theOne|
                  if theOne["MatCat1"]=="Envelope" && theOne["MatCat2"]=="CeilingInsulation" &&
                    theOne["Description"]=~/R#{optValue}/
                    unitCost = theOne["TotUnCost"]
                  end
                end
                if unitCost == 0
                  # The R-value used in options file doesn't have an associated unit cost data item. Use
                  # regression fit (R-squared = 0.9987)
                  unitCost = 0.038 * optValue.to_f + 0.0253
                end
                cost += unitCost * ceilingArea
              end
            end
          when "Opt-Mainwall"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            # Get house main wall area from the first XML <results> section - these are totals of multiple surfaces
            wallAreaOut = elements["HouseFile/AllResults/Results/Other/GrossArea/MainFloors"].attributes["mainWalls"].to_f
            cost = unitCost * wallAreaOut
          when "Opt-GenericWall_1Layer_definitions"
            #.................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            # Get house main wall area from the first XML <results> section - these are totals of multiple surfaces
            wallAreaOut = elements["HouseFile/AllResults/Results/Other/GrossArea/MainFloors"].attributes["mainWalls"].to_f
            cost = unitCost * wallAreaOut
          when "Opt-FloorHeader"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            # Get house floor header area from the first XML <results> section - these are totals of multiple surfaces
            locationText = "HouseFile/AllResults/Results/Other/GrossArea/*"
            # Basement, Crawl space
            headerAreaout = 0
            elements.each(locationText) do |element|
              headerAreaout +=  element.attributes["floorHeader"].to_f
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-ExposedFloor"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-CasementWindows"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-Skylights"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            # Get house skylight area from the house components - skylight is the only allowable component for the ceiling
            locationText = "HouseFile/House/Components/Ceiling/Components/*/Measurements"
            skylightAreaout = 0
            elements.each(locationText) do |element|
              skylightAreaout += (element.attributes["height"].to_f * element.attributes["width"].to_f)/1000000.0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-DoorWindows"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            # Get door  area from the house components - skylight is the only allowable component for the ceiling
            locationText = "HouseFile/House/Components/*/Components/Door/Components/Window/Measurements"
            doorwindowAreaout = 0
            elements.each(locationText) do |element|
              doorwindowAreaout += (element.attributes["height"].to_f * element.attributes["width"].to_f)/1000000.0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-Doors"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            locationText = "HouseFile/House/Components/*/Components/Door/Measurements"
            doorAreaout = 0
            elements.each(locationText) do |element|
              doorAreaout += (element.attributes["height"].to_f * element.attributes["width"].to_f)
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-H2KFoundation"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-H2KFoundationSlabCrawl"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-DHWSystem"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-DWHRSystem"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-HVACSystem"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-HRVspec"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-Baseloads"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-RoofPitch"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-StandoffPV"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          when "Opt-H2K-PV"
            #.................................................................................
            if optValue == "NA"
              unitCost = 0
            elsif optValue == ""
              unitCost = 0
            end
            cost = unitCost * H2KFile.getHeatedFloorArea(elements)
          end
          return cost
        end

        #===============================================================================
        # Costing module

        #===============================================================================

        def estimateCosts(myOptions,myUnitCosts,myChoices, myChoiceOrder )
          debug_off

          h2kCostElements = H2KFile.get_elements_from_filename( $gWorkingModelFile )
          myCosts = Hash.new
          myH2KHouseInfo = Hash.new
          myH2KHouseInfo = H2KFile.getAllInfo(h2kCostElements)
          myH2KHouseInfo["h2kFile"] = $gWorkingModelFile
          debug_out ( "Data from #{$gWorkingModelFile}\n")
          debug_out ( "Dimensions for costing:\n#{myH2KHouseInfo.pretty_inspect}\n")

          specdCostSources = Hash.new
          specdCostSources = {
            "custom" => [],
            "components" => ["MiscNRCanEstimates2019","VancouverAirSealData","LEEP-BC-Vancouver","*"]
          }

          # Compute costs
          costsOK = false

          myCosts, costsOK = Costing.computeCosts(specdCostSources,myUnitCosts,myOptions,myChoices,myH2KHouseInfo)

          if ( ! costsOK )
            stream_out " - Costs could not be calculated correctly. See warning messages\n"
          else
            debug_out "\n\n"
            debug_out drawRuler(" cost calculations complete; reporting "," / ")
            debug_out "\n\n"
            stream_out ( drawRuler("Cost Impacts"))
            stream_out( Costing.summarizeCosts(myChoices, myCosts))
            File.write(CostingAuditReportName, Costing.auditCosts(myChoices,myCosts,myH2KHouseInfo))
            info_out("Comprehensive costing calculation report written to #{CostingAuditReportName}")

            myCosts["costing-dimensions"] = myH2KHouseInfo

          end

          #debug_on
          debug_out ( "Dimensions for costing:\n#{myH2KHouseInfo.pretty_inspect}\n")
          debug_off

          return myCosts

        end

        $allok = true

        $gChoiceOrder = Array.new

        $gTest_params["verbosity"] = "quiet"
        $gTest_params["logfile"]   = $gMasterPath + "\\SubstitutePL-log.txt"

        # Open output file here so we can log errors too!



        #-------------------------------------------------------------------
        # Help text. Dumped if help requested, or if no arguments supplied.
        #-------------------------------------------------------------------
        $help_msg = "

        This script searches through a suite of model input files
        and substitutes values from a specified input file.

        use: ruby substitute-h2k.rb --options Filename.options
        --choices Filename.choices
        --base_file 'Base model path & file name'

        example use for optimization work:

        ruby substitute-h2k.rb -c HOT2000.choices -o HOT2000.options -b C:\\H2K-CLI-Min\\MyModel.h2k -v

        Command line options:

        "

        # Dump help text, if no argument given
        if ARGV.empty? then
          stream_out drawRuler("A wrapper for HOT2000")
          puts $help_msg
          exit()
        end

        #=begin rdoc
        #Command line argument processing ------------------------------
        #Using Ruby's "optparse" for command line argument processing (http://ruby-doc.org/stdlib-2.2.0/libdoc/optparse/rdoc/OptionParser.html)!
        #=end
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

            opts.on("--hints", "Provide helpful hints for intrepreting output") do
              $gHelp = true

            end


            opts.on("-d", "--no-debug", "Disable all debugging") do
              #$cmdlineopts["verbose"] = true
              #{$gTest_params["verbosity"] = "debug"}
              $gNoDebug = true
            end

            opts.on("-r", "--report-choices", "Report .choice file input as part of output") do
              $cmdlineopts["report-choices"] = true
              $gReportChoices = true
            end

            opts.on("-c", "--choices FILE", "Specified choice file (mandatory)") do |c|
              $cmdlineopts["choices"] = c
              $gChoiceFile = c
              if ( !File.exist?($gChoiceFile) )
                fatalerror("Valid path to choice file must be specified with --choices (or -c) option!")
              end
            end

            opts.on("-p", "--prm", "Run as a slave to htap-prm") do
              $cmdlineopts["prm"] = true
              $PRMcall = true
            end

            opts.on("-w", "--warnings", "Report warning messages") do
              $cmdlineopts["warnings"] = true
              $gWarn = true
            end

            opts.on("-o", "--options FILE", "Specified options file (mandatory)") do |o|
              $cmdlineopts["options"] = o
              $gOptionFile = o
              if ( !File.exist?($gOptionFile) )
                fatalerror("Valid path to option file must be specified with --options (or -o) option!")
              end
            end

            opts.on("-b", "--base_model FILE", "Specified base file (mandatory)") do |b|
              $cmdlineopts["base_model"] = b
              $gBaseModelFile = b
              if !$gBaseModelFile
                fatalerror("Base folder file name missing after --base_folder (or -b) option!")
              end
              if (! File.exist?($gBaseModelFile) )
                fatalerror("Base file '#{$gBaseModelFile}' does not exist in location specified!")
              end
              $gLookForArchetype = 0;
            end

            opts.on("-e", "--extra_output1", "Produce and save extended output (v1)") do
              $cmdlineopts["extra_output1"] = true
              $gReadROutStrTxt = true
              $ExtraOutput1 = true
            end

            opts.on("-k", "--keep_H2K_folder", "Keep the H2K sub-folder generated during last run.") do
              $cmdlineopts["keep_H2K_folder"] = true
              $keepH2KFolder = true
            end

            opts.on("-l", "--long-prefix", "Use long-prefixes in output .") do

              $aliasInput   = $aliasLongInput
              $aliasOutput  = $aliasLongOutput
              $aliasConfig  = $aliasLongConfig
              $aliasArch    = $aliasLongArch

            end

            opts.on("-a", "--auto-cost-options", "Automatically cost the option(s) set for this run.") do
              $cmdlineopts["auto_cost_options"] = true
              $autoEstimateCosts = true
            end

            opts.on("-j", "--export-options-to-json", "Export the .options file into JSON format and quit.") do

              $gJasonExport = true

            end

            opts.on("-t", "--test-json-export", "(debugging) Export the .options file as .json, and then re-import it (debugging)") do

              $gJasonTest = true

            end



          end

          # Note: .parse! strips all arguments from ARGV and .parse does not
          #       The parsing code above effects only those options that occur on the command line!
          optparse.parse!

          stream_out drawRuler("A wrapper for HOT2000")

          if $gDebug
            debug_out( $cmdlineopts )
          end

          if !$gBaseModelFile then
            $gBaseModelFile = "Not specified. Using archetype specified in .choice file"
            $gLookForArchetype = 1
          else
            # Note: !! This code is over-written below by a hard-coded path for the $h2k_src_path (executable path)
            # The two lines below ASSUME that all model files are located below the H2K CLI program!
            ($h2k_src_path, $h2kFileName) = File.split( $gBaseModelFile )
            $h2k_src_path.sub!(/\\User/i, '')
            # Strip "User" (any case) from $h2k_src_path
          end

          $h2k_src_path = "C:\\H2K-CLI-Min"
          $run_path = $gMasterPath + "\\H2K"

          stream_out ("\n Input files:  \n")
          stream_out ("         path: #{$gMasterPath} \n")
          stream_out ("         ChoiceFile: #{$gChoiceFile} \n")
          stream_out ("         OptionFile: #{$gOptionFile} \n")
          stream_out ("         Base model: #{$gBaseModelFile} \n")
          stream_out ("         HOT2000 source folder: #{$h2k_src_path} \n")
          stream_out ("         HOT2000 run folder: #{$run_path} \n")

          #=begin rdoc
          #Parse option file. This file defines the available choices and costs
          #that substitute-h2k.rb can pick from
          #=end

          $linecount = 0
          $gParameters = Hash.new

          stream_out drawRuler("Parsing input data")

          if ( $gOptionFile =~ /\.json/ ) then

            $gOptions = HTAPData.parse_json_options_file($gOptionFile)


          else

            parse_legacy_options_file($gOptionFile)

            # Code used to test round-tripping
            if ( $gJasonTest )
              stream_out (" Debugging option --test-json-export specified. \n")
              stream_out (" Writing options to json format (HTAP-options.json) and re-importing... \n")
              exportOptionsToJson()
              $gOptionsOld = $gOptions
              $gOptions = nil
              $gOptions= HTAPdata.parse_json_options_file("HTAP-options.json")

            end

            if ( $gJasonExport ) then

              stream_out (" \n\n")
              stream_out drawRuler("JSON export")
              stream_out (" Option --export-options-to-json specified. \n")
              stream_out (" Writing HTAP-options.json and quitting...")
              exportOptionsToJson()
              stream_out ("  Complete.  \n\n")
              exit

            end

          end



          for $currentAttributeName in $gOptions.keys()

            # Store options - what does this do?

            debug_out drawRuler( "Storing data for #{$currentAttributeName}", "> " );

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

          #=begin rdoc
          #Parse configuration (choice) file.
          #=end

          stream_out("\n\n Reading user-defined choices (#{$gChoiceFile})...\n")
          $gChoices, $gChoiceOrder = HTAPData.parse_choice_file($gChoiceFile)
          stream_out (" ...done.\n\n")

          stream_out ( " Specified choices: \n")
          $gChoices.each do | attribute, value |
            stream_out (" - #{attribute.ljust(35)} = #{value} \n ")
          end

          stream_out(drawRuler("Setting up HOT2000 environment"))
          if $gLookForArchetype == 1 && !$gChoices["Opt-Archetype"].empty?
            $Archetype_value = $gChoices["Opt-Archetype"]

            # IF NA is set, and nothing is given at the command line, default to SmallSFD.
            if ( $Archetype_value =~ /NA/ )
              $Archetype_value = "SmallSFD"
            end

            debug_out "Archetype ? #{$Archetype_value}\n"
            $gBaseModelFile = $gOptions["Opt-Archetype"]["options"][$Archetype_value]["values"]['1']['conditions']['all']
            ($h2k_src_path, $h2kFileName) = File.split( $gBaseModelFile )
            $h2k_src_path.sub!(/\\User/i, '')
            # Strip "User" (any case) from $h2k_src_path
            $run_path = $gMasterPath + "\\H2K"

            stream_out ("\n   UPDATED: Base model: #{$gBaseModelFile} \n")
            stream_out ("            HOT2000 model file: #{$h2kFileName} \n")
            stream_out ("            HOT2000 source folder: #{$h2k_src_path} \n")
            stream_out ("            HOT2000 run folder: #{$run_path} \n")
          end

          # Create a working h2k file, or if one exists, check to make sure it is
          # identical to the one whe use.
          # Variables for doing a md5 test on the integrety of the run.
          $DirVerified = false
          $CopyTries = 0

          while ( ! $DirVerified && $CopyTries < 3 ) do

            if ( ! Dir.exist?("#{$gMasterPath}\\H2K") )
              if ( ! system("mkdir #{$gMasterPath}\\H2K") )
                warn_out (" Could not create H2K folder below #{$gMasterPath} on attempt #{$CopyTries+1}. Return error code #{$?}.")
              end
              stream_out (" Copying H2K folder to source\n")
              FileUtils.cp_r("#{$h2k_src_path}/.", "#{$gMasterPath}\\H2K")
            end

            stream_out (" Checking integrity of H2K installation\n")
            stream_out (" + Attempt ##{$CopyTries+1}:\n")
            $masterMD5  = self.checksum("#{$h2k_src_path}").to_s
            $workingMD5 = self.checksum("#{$gMasterPath}\\H2K").to_s

            stream_out ("   - master:        #{$masterMD5}\n")
            stream_out ("   - working copy:  #{$workingMD5}")


            if ($masterMD5.eql? $workingMD5) then
              $DirVerified = true
              stream_out(" (checksum match)\n")
            else

              FileUtils.rm_r ( "#{$gMasterPath}\\H2K" )
              stream_out(" (CHECKSUM MISMATCH!!!)\n")
              warn_out ("Working H2K installation dir (#{$gMasterPath}) differs from source #{$gMasterPath}. Attempting to re-create (#{$CopyTries+1}). Return error code #{$?}.")
            end

            $CopyTries  = $CopyTries  + 1

          end

          $gStatus["MD5master"] = $masterMD5.to_s
          $gStatus["MD5workingcopy"] = $workingMD5.to_s
          $gStatus["H2KDirCopyAttempts"] = $CopyTries.to_s
          $gStatus["H2KDirCheckSumMatch"] = $DirVerified

          if ( ! $DirVerified )
            fatalerror ("\nFatal Error! Integrity of H2K folder at #{$gMasterPath} is compromised!\n Return error code #{$?}\n")
          else
            H2KUtils.fix_H2K_INI($gMasterPath)
            H2KUtils.write_h2k_magic_files($gMasterPath)
            # Remove existing RoutStr file! It can grow very large, if present.
            rOut_file  = "#{$gMasterPath}\\H2K\\ROutstr.txt"
            if File.exist?(rOut_file)
              system ("del #{rOut_file}")
            end
          end

          # Create a copy of the HOT2000 file into the master folder for manipulation.
          # (when called by PRM, the run manager will already do this - if we don't test for it, it will delete the file)

          $gWorkingModelFile = $gMasterPath + "\\"+ $h2kFileName

          if ( ! $PRMcall )
            stream_out("\n Creating a copy of HOT2000 model (#{$gBaseModelFile} for optimization work... \n")
            # Remove any existing file first!
            if ( File.exist?($gWorkingModelFile) )
              if ( ! system ("del #{$gWorkingModelFile}") )
                fatalerror ("Fatal Error! Could not delete #{$gWorkingModelFile}!\n Del return error code #{$?}\n")
              end
            end

            debug_out "copy arguements: #{$gBaseModelFile} -> #{$gWorkingModelFile}\n "
            FileUtils.cp($gBaseModelFile,$gWorkingModelFile)
            stream_out("\n  (File #{$gWorkingModelFile} created.)\n\n")
          end

          # Load all XML elements from HOT2000 file

          stream_out(drawRuler("Reading HOT2000 file"))
          stream_out("\n Parsing a copy of HOT2000 model (#{$gWorkingModelFile}) for optimization work...")
          h2kElements = H2KFile.get_elements_from_filename($gWorkingModelFile)
          stream_out("done.")

          # Which fdn set?
          $foundationConfiguration =  HTAPData.whichFdnConfig($gChoices)

          # Get rule set choices hash values in $ruleSetChoices for the
          # rule set name specified in the choice file
          $ruleSetName = $gChoices["Opt-Ruleset"]

          # Get some data from the base house model file...

          $Locale = $gChoices["Opt-Location"]

          # Weather city name

          # Base location from original H2K file.
          $gBaseLocale = H2KFile.getWeatherCity( h2kElements )
          $gBaseRegion = H2KFile.getRegion( h2kElements )

          if $Locale.empty? || $Locale == "NA"
            # from base model file
            locale = $gBaseLocale
            $gRunLocale = $gBaseLocale
            $gRunRegion = $gBaseRegion
          else
            # from Opt-Location
            locale = $Locale
          end
          locale.gsub!(/\./, '')
          $HDDs = $HDDHash[ locale.upcase ]

          case $HDDs.to_i
          when 0..2999
            climateZone = "Zone 4"
          when 3000..3999
            climateZone = "Zone 5"
          when 4000..4999
            climateZone = "Zone 6"
          when 5000..5999
            climateZone = "Zone 7a"
          when 6000..6999
            climateZone = "Zone 7b"
          when 7000..9999999
            climateZone = "Zone 8"
          else
            climateZone = "nil"
            warn_out ("Could not compute climate zone for #{locale} - HDDs:#{$HDDs}")

          end

          $Locale_model = locale

          isSetbyRuleset = Hash.new
          $gChoices.each do |thisChoice|
            isSetbyRuleset[thisChoice]=false
          end



          if !$ruleSetName.empty? && $ruleSetName != "NA"
            stream_out(drawRuler("Processing Rulesets"))

            ruleSet = $ruleSetName

            debug_out "Pre-ruleset choices:\n #{$gChoices.pretty_inspect}\n"
            debug_out ("RULESET #{ruleSet} with conditions:#{$ruleSetSpecs.pretty_inspect}\n")

            conditionString = ""
            $ruleSetSpecs.each do | cond, value |
              conditionString = "; #{cond}=#{value}"
            end

            stream_out("\n\n Applying Ruleset #{ruleSet}#{conditionString}:\n")

            if ( ruleSet =~ /as-found/ )
              # Do nothing!
              stream_out ("  (a) AS FOUND: no changes made to model\n")

            elsif ( ruleSet =~ /^NBC_*9_*36$/ || ruleSet =~ /^NBC_*9_*36_noHRV$/ ||  ruleSet =~ /^NBC_*9_*36_noHRV$/ )
              stream_out ("  (b) NBC 936 pathway \n")
              NBC_936_2010_RuleSet( ruleSet, $ruleSetSpecs, h2kElements, $HDDs,locale )

            elsif ( ruleSet =~ /936_2015_AW_HRV/ ||  ruleSet =~ /936_2015_AW_noHRV / )
              stream_out ("  (c) Protorype NBC Ruleset by Adam Wills.\n")
              # Do nothing - this is the AW rule set.

            elsif ( ruleSet =~ /R2000_NZE_Pilot_Env/ ||  ruleSet =~ /R2000_NZE_Pilot_Mech/ )
              stream_out ("  (d) R2000 NZE Pilot envelope set\n")
              R2000_NZE_Pilot_RuleSet( ruleSet, h2kElements, locale )

            elsif ( ruleSet =~ /R2000_NZE_Pilot_Base/)
              stream_out ("  (e) Base case from R2000 NZE pilot \n")
              NBC_936_2010_RuleSet( "NBC9_36_HRV", h2kElements, $HDDs,locale )
              R2000_NZE_Pilot_RuleSet( "R2000_NZE_Pilot_Env", h2kElements, locale )


            elsif ( ruleSet =~ /ArchetypeRoadmapping/)
              stream_out ("  (f) Vintage archetypes based on EGH database analysis ")
              ArchetypeRoadmapping_RuleSet( ruleSet, h2kElements )

            else
              fatalerror "Unknown ruleset #{ruleSet}"

            end

            # Replace choices in $gChoices with rule set choices in $ruleSetChoices
            stream_out("\n Replacing user-defined choices with rule set choices where appropriate...\n")
            $ruleSetChoices.each do |attrib, choice|
              if choice.empty?
                warn_out("WARNING:  Attribute #{attrib} is blank in the rule set.")
                next
                # skip setting this empty choice!
              elsif ( $gChoices[attrib].empty? || $gChoices[attrib] =~ /NA/ )
                # Change choice to rule set value for all choices that are "NA"
                isSetbyRuleset[attrib] = true
                $gChoices[attrib] = choice
                stream_out ("   - #{attrib} -> #{choice} \n")
              else
                next
                # skip changing this choice because it has a non-NA value!
              end
            end


          end

          houseUpgraded = false
          houseSetByRuleset = false
          houseUpgradeList = ""
          $gChoices.each do |thisAttrib,thisChoice|

            next if ( AttribThatAreNotUpgrades.include?(thisAttrib) )
            if ( isSetbyRuleset[thisAttrib] )
              houseSetByRuleset = true
            elsif ( thisChoice != "NA" )
              houseUpgraded = true
              houseUpgradeList += "#{thisAttrib}=>#{thisChoice};"
            end

          end





          debug_out("Parsing parameters ...\n")

          $gCustomCostAdjustment = 0
          $gCostAdjustmentFactor = 0

          # Possibly overwrite internal parameters with user-specified parameters
          # This can probably be deleted !
          #$gParameters.each do |parameter, value1|
          #   if ( parameter =~ /CostAdjustmentFactor/  )
          #      $gCostAdjustmentFactor = value1
          #      $gCustomCostAdjustment = 1
          #   end
          #
          #   if ( parameter =~ /PVTarrifDollarsPerkWh/ )
          #      $PVTarrifDollarsPerkWh = value1.to_f
          #   end
          #
          #   if ( parameter =~ /BaseUpgradeCost/ )
          #      $gIncBaseCosts = value1.to_f
          #   end
          #
          #   if ( parameter =~ /BaseUtilitiesCost/ )
          #      $gUtilityBaseCost = value1.to_f
          #   end
          #end

          #=begin rdoc
          #Validate choices and options.
          #=end
          stream_out(drawRuler("Validating choices and options"))


          $OptionsERR,$gChoices, $gChoiceOrder = HTAPData.validate_options($gOptions, $gChoices, $gChoiceOrder )



          if ( $gChoicesChangedbyProgram ) then

            warn_out ("#{$program} made changes to specified choices to ensure combinations are compatable with HTAP data model.")

          end

          stream_out(" Choices that will be used in the simulation:\n")
          $gChoices.each do | attribute, value |
            stream_out (" - #{attribute.ljust(35)} = #{value} \n ")
          end



          if ( $OptionsERR ) then
            $allok = false
          end

          if (! $allok )
            fatalerror ("Could not parse options & choices")
          end



          #================
          # Older code associated with processing 'conditions' for various
          # options. no longer needed (?)

          #=begin rdoc
          #Process conditions.
          #=end


          # Can this be removed? NO!
          LegacyProcessConditions()

          # Seems like we've found everything!

          if ( !$allok )
            fatalerror(" Choices in #{$gChoiceFile} do not match options in #{$gOptionFile}!")
          else

          end

          # Process the working file by replacing all existing values with the values
          # specified in the attributes $gChoices and corresponding $gOptions

          stream_out drawRuler(' Manipulating HOT2000 file ')
          stream_out (" Performing substitutions on H2K file...")

          processFile( h2kElements )

          stream_out( "done.")




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
          $ScaleResults = 1.0 / orientations.size()
          # size returns 1 or 4

          # Defined at top and zeroed here because if we are running multiple orientations,
          # we must average them as we go. Averaging is done via the $ScaleResults factor (set
          # at 0.25) only when the AVG option is used.
          $gAvgEnergy_Total = 0
          $gAvgPVRevenue = 0
          $gAvgElecCons_KWh = 0
          $gAvgPVOutput_kWh = 0
          $gAvgCost_Total = 0
          $gAvgEnergyCoolingGJ = 0
          $gAvgEnergyVentilationGJ = 0
          $gAvgEnergyWaterHeatingGJ = 0
          $gAvgEnergyEquipmentGJ = 0
          $gAvgNGasCons_m3 = 0
          $gAvgOilCons_l = 0
          $gAvgPropCons_l = 0
          $gAvgPelletCons_t = 0
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
          $FloorArea = 0


          stream_out drawRuler('Running HOT2000 simulations')


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



          # if autocosts were estimatd, compute costs
          if ( $autoEstimateCosts ) then

            myUnitCosts = Costing.parseUnitCosts($unitCostFileName)
            costEstimates = estimateCosts($gOptions,myUnitCosts,$gChoices,$gChoiceOrder)

          end


          $gAvgCost_Total = $gResults[$outputHCode]['avgFuelCostsTotal$']

          if ( $PVIntModel )
            $gAvgPVRevenue = ( $gResults[$outputHCode]['avgElecPVGenkWh'] - $gResults[$outputHCode]['avgElecPVUsedkWh'] ) * $PVTarrifDollarsPerkWh
          else
            $gAvgPVRevenue = ( $gResults[$outputHCode]['avgElecPVGenkWh'] - $gResults[$outputHCode]['avgFueluseEleckWh'] ) * $PVTarrifDollarsPerkWh
          end

          $gAvgPVRevenue = 0.0 if $gAvgPVRevenue < 0.0

          $optCOProxy = 0
          $gAvgUtilCostNet = $gAvgCost_Total - $gAvgPVRevenue

          # Proxy for cost of ownership (JTB 05-10-2016: Vriable used to be "$payback")
          $optCOProxy = $gAvgUtilCostNet + ($gTotalCost-$gIncBaseCosts)/25.0

          $TEDI_kWh_m2 = ( $gAuxEnergyHeatingGJ * 277.78 / $FloorArea )

          $MEUI_kWh_m2 =  ( $gResults[$outputHCode]['avgEnergyHeatingGJ'] +
            $gResults[$outputHCode]['avgEnergyCoolingGJ'] +
            $gResults[$outputHCode]['avgEnergyVentilationGJ'] +
            $gResults[$outputHCode]['avgEnergyWaterHeatingGJ']  ) * 277.78 / $FloorArea

            if ( $gResults['Reference'].empty? ) then
              $RefEnergy = 0.0
            else
              $RefEnergy = $gResults['Reference']['avgEnergyTotalGJ']
            end

            json_output = true
            if ( json_output ) then

              results = Hash.new
              results[$aliasLongConfig] = { "OptionsFile"         =>  "#{$gOptionFile}",
              "Recovered-results"   =>  "#{$outputHCode}"
            }
            results[$aliasLongArch] = {   "h2k-File"            =>  "#{$h2kFileName}",
            "House-Builder"       =>  "#{$BuilderName}",
            "House-Type"          =>  "#{$HouseType}",
            "House-Storeys"       =>  "#{$HouseStoreys}",
            "Weather-Locale"      =>  "#{$Locale_model}",
            "Base-Region"         =>  "#{$gBaseRegion}",
            "Base-Locale"         =>  "#{$gBaseLocale}",
            "climate-zone"        =>  "#{climateZone}",
            "fuel-heating-presub"  =>  "#{$ArchetypeData["pre-substitution"]["fuelHeating"]}",
            "fuel-DHW-presub"     =>  "#{$ArchetypeData["pre-substitution"]["fuelHDHW"]}",
            "Ceiling-Type"        =>  "#{$Ceilingtype}",
            "Area-Slab-m2"        =>  "#{$FoundationArea["Slab"].round(2)}",
            "Area-Basement-m2"    => "#{$FoundationArea["Basement"].round(2)}",
            "Area-Walkout-m2"     =>  "#{$FoundationArea["Walkout"].round(2)}",
            "Area-Crawl-m2"       =>  "#{$FoundationArea["Crawl"].round(2)}",
            "Floor-Area-m2"     => "#{$FloorArea.round(1)}",
            "House-Volume-m3"   => "#{$HouseVolume.round(1)}",
            "Win-SHGC-S"        => "#{$SHGCWin[1].round(3)}",
            "Win-R-value-S"     => "#{$rValueWin[1].round(3)}",
            "Win-Area-m2-S"     => "#{$AreaWin_sum[1].round(1)}",
            "Win-SHGC-SE"       => "#{$SHGCWin[2].round(3)}",
            "Win-R-value-SE"    => "#{$rValueWin[2].round(3)}",
            "Win-Area-m2-SE"    => "#{$AreaWin_sum[2].round(1)}",
            "Win-SHGC-E"        => "#{$SHGCWin[3].round(3)}",
            "Win-R-value-E"     => "#{$rValueWin[3].round(3)}",
            "Win-Area-m2-E"     => "#{$AreaWin_sum[3].round(1)}",
            "Win-SHGC-NE"       => "#{$SHGCWin[4].round(3)}",
            "Win-R-value-NE"    => "#{$rValueWin[4].round(3)}",
            "Win-Area-m2-NE"    => "#{$AreaWin_sum[4].round(1)}",
            "Win-SHGC-N"        => "#{$SHGCWin[5].round(3)}",
            "Win-R-value-N"     => "#{$rValueWin[5].round(3)}",
            "Win-Area-m2-N"     => "#{$AreaWin_sum[5].round(1)}",
            "Win-SHGC-NW"       => "#{$SHGCWin[6].round(3)}",
            "Win-R-value-NW"    => "#{$rValueWin[6].round(3)}",
            "Win-Area-m2-NW"    => "#{$AreaWin_sum[6].round(1)}",
            "Win-SHGC-W"        => "#{$SHGCWin[7].round(3)}",
            "Win-R-value-W"     => "#{$rValueWin[7].round(3)}",
            "Win-Area-m2-W"     => "#{$AreaWin_sum[7].round(1)}",
            "Win-SHGC-SW"       => "#{$SHGCWin[8].round(3)}",
            "Win-R-value-SW"    => "#{$rValueWin[8].round(3)}",
            "Win-Area-m2-SW"    => "#{$AreaWin_sum[8].round(1)}",
            "Area-Door-m2"      => "#{$AreaComp['door'].round(3)}",
            "Area-DoorWin-m2"   => "#{$AreaComp['doorwin'].round(3)}",
            "Area-Windows-m2"   => "#{$AreaComp['win'].round(3)}",
            "Area-Wall-m2"      => "#{$AreaComp['wall'].round(3)}",
            "Area-Header-m2"    => "#{$AreaComp['header'].round(3)}",
            "Area-Ceiling-m2"   => "#{$AreaComp['ceiling'].round(3)}",
            "Area-ExposedFloor-m2"     => "#{$AreaComp['floor'].round(3)}",
            "Area-House-m2"     => "#{$AreaComp['house'].round(3)}"
          }

          if $gReportChoices then
            results[$aliasLongInput] = Hash.new
            results[$aliasLongInput] = { "Run-Region" =>  "#{$gRunRegion}",
            "Run-Locale" =>  "#{$gRunLocale}",
            "House-Upgraded"   =>  "#{houseUpgraded}",
            "House-ListOfUpgrades" => "#{houseUpgradeList}"
          }
          $gChoices.sort.to_h
          for attribute in $gChoices.keys()
            choice = $gChoices[attribute]
            results[$aliasLongInput][attribute] = "#{choice}"
          end
        end

        # duplicate? "Area-ExposedFloor-m2"=>  "#{$FoundationArea["Floor"].round(2)}",

        results["analysis_BCStepCode"] = {
          "TEDI_compliance" =>  BCStepCode.getStepByTEDI(climateZone,$TEDI_kWh_m2)
        }

        results[$aliasLongOutput] = {   "HDDs"              => $HDDs,
          "Energy-Total-GJ"   => $gResults[$outputHCode]['avgEnergyTotalGJ'].round(1),
          "Ref-En-Total-GJ"   => $RefEnergy.round(1),
          "Util-Bill-gross"   => $gResults[$outputHCode]['avgFuelCostsTotal$'].round(2),
          "Util-PV-revenue"   => $gResults[$outputHCode]['avgPVRevenue'].round(2),
          "Util-Bill-Net"     => $gResults[$outputHCode]['avgFuelCostsTotal$'].round(2) - $gResults[$outputHCode]['avgPVRevenue'].round(2),
          "Util-Bill-Elec"    => $gResults[$outputHCode]['avgFuelCostsElec$'].round(2),
          "Util-Bill-Gas"     => $gResults[$outputHCode]['avgFuelCostsNatGas$'].round(2),
          "Util-Bill-Prop"    => $gResults[$outputHCode]['avgFuelCostsPropane$'].round(2),
          "Util-Bill-Oil"     => $gResults[$outputHCode]['avgFuelCostsOil$'].round(2),
          "Util-Bill-Wood"    => $gResults[$outputHCode]['avgFuelCostsWood$'].round(2),
          "Energy-PV-kWh"     => $gResults[$outputHCode]['avgElecPVGenkWh'].round(0),
          "Gross-HeatLoss-GJ" => $gResults[$outputHCode]['avgGrossHeatLossGJ'].round(0),
          "Energy-HeatingGJ"  => $gResults[$outputHCode]['avgEnergyHeatingGJ'].round(1),
          "AuxEnergyReq-HeatingGJ" => $gAuxEnergyHeatingGJ.round(1),
          "TotalAirConditioning-LoadGJ" => $TotalAirConditioningLoad.round(1) ,
          "AvgAirConditioning-COP" => $AvgACCOP.round(1) ,
          "Energy-CoolingGJ"  => $gResults[$outputHCode]['avgEnergyCoolingGJ'].round(1) ,
          "Energy-VentGJ"     => $gResults[$outputHCode]['avgEnergyVentilationGJ'].round(1) ,
          "Energy-DHWGJ"      => $gResults[$outputHCode]['avgEnergyWaterHeatingGJ'].round(1) ,
          "Energy-PlugGJ"     => $gResults[$outputHCode]['avgEnergyEquipmentGJ'].round(1) ,
          "EnergyEleckWh"     => $gResults[$outputHCode]['avgFueluseEleckWh'].round(1) ,
          "EnergyGasM3"       => $gResults[$outputHCode]['avgFueluseNatGasM3'].round(1) ,
          "EnergyOil_l"       => $gResults[$outputHCode]['avgFueluseOilL'].round(1) ,
          "EnergyProp_L"      => $gResults[$outputHCode]['avgFuelusePropaneL'].round(1) ,
          "EnergyWood_cord"   => $gResults[$outputHCode]['avgFueluseWoodcord'].round(1) ,
          # includes pellets
          "SimplePaybackYrs"  => $optCOProxy.round(1) ,
          "TEDI_kWh_m2"       => $TEDI_kWh_m2.round(1) ,
          "MEUI_kWh_m2"       => $MEUI_kWh_m2.round(1) ,
          "ERS-Value"         => $gERSNum.round(1) ,
          "NumTries"          => $NumTries.round(1) ,
          "LapsedTime"        => $runH2KTime.round(2) ,
          "PEAK-Heating-W"    => $gResults[$outputHCode]['avgOthPeakHeatingLoadW'].round(1) ,
          "PEAK-Cooling-W"    => $gResults[$outputHCode]['avgOthPeakCoolingLoadW'].round(1) ,
          "House-R-Value(SI)" => $RSI['house'].round(3)
        }

        if $ExtraOutput1 then
          results[$aliasLongOutput]["EnvTotalHL-GJ"]     =  $gResults[$outputHCode]['EnvHLTotalGJ'].round(1)
          results[$aliasLongOutput]["EnvCeilHL-GJ"]      =  $gResults[$outputHCode]['EnvHLCeilingGJ'].round(1)
          results[$aliasLongOutput]["EnvWallHL-GJ"]      =  $gResults[$outputHCode]['EnvHLMainWallsGJ'].round(1)
          results[$aliasLongOutput]["EnvWinHL-GJ"]       =  $gResults[$outputHCode]['EnvHLWindowsGJ'].round(1)
          results[$aliasLongOutput]["EnvDoorHL-GJ"]      =  $gResults[$outputHCode]['EnvHLDoorsGJ'].round(1)
          results[$aliasLongOutput]["EnvFloorHL-GJ"]     =  $gResults[$outputHCode]['EnvHLExpFloorsGJ'].round(1)
          results[$aliasLongOutput]["EnvCrawlHL-GJ"]     =  $gResults[$outputHCode]['EnvHLCrawlspaceGJ'].round(1)
          results[$aliasLongOutput]["EnvSlabHL-GJ"]      =  $gResults[$outputHCode]['EnvHLSlabGJ'].round(1)
          results[$aliasLongOutput]["EnvBGBsemntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLBasementBGWallGJ'].round(1)
          results[$aliasLongOutput]["EnvAGBsemntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLBasementAGWallGJ'].round(1)
          results[$aliasLongOutput]["EnvBsemntFHHL-GJ"]  =  $gResults[$outputHCode]['EnvHLBasementFlrHdrsGJ'].round(1)
          results[$aliasLongOutput]["EnvPonyWallHL-GJ"]  =  $gResults[$outputHCode]['EnvHLPonyWallGJ'].round(1)
          results[$aliasLongOutput]["EnvFABsemntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLFlrsAbvBasementGJ'].round(1)
          results[$aliasLongOutput]["EnvAirLkVntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLAirLkVentGJ'].round(1)
          results[$aliasLongOutput]["AnnDHWLoad-GJ"]     =  $gResults[$outputHCode]['AnnHotWaterLoadGJ'].round(1)

          results[$aliasLongOutput]["SpcHeatElec-GJ"]    = $gResults[$outputHCode]['AnnSpcHeatElecGJ'].round(1)
          results[$aliasLongOutput]["SpcHeatGas-GJ"]     = $gResults[$outputHCode]['AnnSpcHeatGasGJ'].round(1)
          results[$aliasLongOutput]["SpcHeatOil-GJ"]     = $gResults[$outputHCode]['AnnSpcHeatOilGJ'].round(1)
          results[$aliasLongOutput]["SpcHeatProp-GJ"]    = $gResults[$outputHCode]['AnnSpcHeatPropGJ'].round(1)
          results[$aliasLongOutput]["SpcHeatWood-GJ"]    = $gResults[$outputHCode]['AnnSpcHeatWoodGJ'].round(1)
          results[$aliasLongOutput]["HotWaterElec-GJ"]   = $gResults[$outputHCode]['AnnHotWaterElecGJ'].round(1)
          results[$aliasLongOutput]["HotWaterGas-GJ"]    = $gResults[$outputHCode]['AnnHotWaterGasGJ'].round(1)
          results[$aliasLongOutput]["HotWaterOil-GJ"]    = $gResults[$outputHCode]['AnnHotWaterOilGJ'].round(1)
          results[$aliasLongOutput]["HotWaterProp-GJ"]   = $gResults[$outputHCode]['AnnHotWaterPropGJ'].round(1)
          results[$aliasLongOutput]["HotWaterWood-GJ"]   = $gResults[$outputHCode]['AnnHotWaterWoodGJ'].round(1)
        end


        results[$aliasLongStatus] = Hash.new
        $gStatus.keys.each do | status_type |
          results[$aliasLongStatus][status_type] = "#{$gStatus[status_type]}"
        end

        results[$aliasLongStatus]["errors"] = Array.new
        results[$aliasLongStatus]["errors"] = $gErrors
        results[$aliasLongStatus]["warnings"] = Array.new
        results[$aliasLongStatus]["warnings"] = $gWarnings
        results[$aliasLongStatus]["infoMsgs"] = Array.new
        results[$aliasLongStatus]["infoMsgs"] = $gInfoMsgs
        results[$aliasLongStatus]["success"] = $allok

        myEndProcessTime = Time.now
        totalDiff = myEndProcessTime - $startProcessTime
        results[$aliasLongStatus]["processingtime"]  = $totalDiff
        if ( $autoEstimateCosts ) then
          results[$aliasLongCosts] = costEstimates
        end

        fJsonOut = File.open("#{$gMasterPath}\\h2k_run_results.json", "w")
        if ( fJsonOut.nil? )then
          fatalerror("Could not create #{$gMasterPath}\\SubstitutePL-output.txt")
        end
        fJsonOut.puts JSON.pretty_generate(results)
        fJsonOut.close
      end


      if $fSUMMARY == nil then
        fatalerror("Could not create #{$gMasterPath}\\SubstitutePL-output.txt")
      end

      $fSUMMARY.write( "#{$aliasConfig}.OptionsFile       =  #{$gOptionFile}\n")
      $fSUMMARY.write( "#{$aliasConfig}.Recovered-results =  #{$outputHCode}\n")

      if ($FlagHouseInfo)
        $fSUMMARY.write( "#{$aliasArch}.House-Builder     =  #{$BuilderName}\n" )
        $fSUMMARY.write( "#{$aliasArch}.House-Type        =  #{$HouseType}\n" )
        $fSUMMARY.write( "#{$aliasArch}.House-Storeys     =  #{$HouseStoreys}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Weather-Locale    =  #{$Locale_model}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Base-Region       =  #{$gBaseRegion}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Base-Locale       =  #{$gBaseLocale}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Ceiling-Type    =  #{$Ceilingtype}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Area-Slab-m2    =  #{$FoundationArea["Slab"].to_f.round(2)}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Area-Basement-m2    =  #{$FoundationArea["Basement"].to_f.round(2)}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Area-ExposedFloor-m2    =  #{$FoundationArea["Floor"].to_f.round(2)}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Area-Walkout-m2    =  #{$FoundationArea["Walkout"].to_f.round(2)}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Area-Crawl-m2    =  #{$FoundationArea["Crawl"].to_f.round(2)}\n" )
      end
      $fSUMMARY.write( "#{$aliasOutput}.HDDs              =  #{$HDDs}\n" )
      $fSUMMARY.write( "#{$aliasOutput}.Energy-Total-GJ   =  #{$gResults[$outputHCode]['avgEnergyTotalGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Ref-En-Total-GJ   =  #{$RefEnergy.round(1)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-gross   =  #{$gResults[$outputHCode]['avgFuelCostsTotal$'].round(2)}   \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-PV-revenue   =  #{$gResults[$outputHCode]['avgPVRevenue'].round(2)}    \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Net     =  #{$gResults[$outputHCode]['avgFuelCostsTotal$'].round(2) - $gResults[$outputHCode]['avgPVRevenue'].round(2)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Elec    =  #{$gResults[$outputHCode]['avgFuelCostsElec$'].round(2)}  \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Gas     =  #{$gResults[$outputHCode]['avgFuelCostsNatGas$'].round(2)}  \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Prop    =  #{$gResults[$outputHCode]['avgFuelCostsPropane$'].round(2)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Oil     =  #{$gResults[$outputHCode]['avgFuelCostsOil$'].round(2)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Wood    =  #{$gResults[$outputHCode]['avgFuelCostsWood$'].round(2)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Pellet  =  #{$gAvgCost_Pellet.round(2)} \n" )   # Not available separate from wood - set to 0

      $fSUMMARY.write( "#{$aliasOutput}.Energy-PV-kWh     =  #{$gResults[$outputHCode]['avgElecPVGenkWh'].round(0)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Gross-HeatLoss-GJ =  #{$gResults[$outputHCode]['avgGrossHeatLossGJ'].round(0)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Energy-SDHW      =  #{$gEnergySDHW.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Energy-HeatingGJ  =  #{$gResults[$outputHCode]['avgEnergyHeatingGJ'].round(1)} \n" )

      $fSUMMARY.write( "#{$aliasOutput}.AuxEnergyReq-HeatingGJ = #{$gAuxEnergyHeatingGJ.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.TotalAirConditioning-LoadGJ = #{$TotalAirConditioningLoad.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.AvgAirConditioning-COP = #{$AvgACCOP.round(1)} \n" )

      $fSUMMARY.write( "#{$aliasOutput}.Energy-CoolingGJ  =  #{$gResults[$outputHCode]['avgEnergyCoolingGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Energy-VentGJ     =  #{$gResults[$outputHCode]['avgEnergyVentilationGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Energy-DHWGJ      =  #{$gResults[$outputHCode]['avgEnergyWaterHeatingGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Energy-PlugGJ     =  #{$gResults[$outputHCode]['avgEnergyEquipmentGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.EnergyEleckWh     =  #{$gResults[$outputHCode]['avgFueluseEleckWh'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.EnergyGasM3       =  #{$gResults[$outputHCode]['avgFueluseNatGasM3'].round(1)}  \n" )
      $fSUMMARY.write( "#{$aliasOutput}.EnergyOil_l       =  #{$gResults[$outputHCode]['avgFueluseOilL'].round(1)}    \n" )
      $fSUMMARY.write( "#{$aliasOutput}.EnergyProp_L      =  #{$gResults[$outputHCode]['avgFuelusePropaneL'].round(1)}    \n" )
      # includes pellets
      $fSUMMARY.write( "#{$aliasOutput}.EnergyWood_cord   =  #{$gResults[$outputHCode]['avgFueluseWoodcord'].round(1)}    \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Upgrade-cost      =  #{($gTotalCost-$gIncBaseCosts).round(2)}\n" )
      #$fSUMMARY.write( "#{$aliasOutput}.SimplePaybackYrs  =  #{$optCOProxy.round(1)} \n" )

      if ($TsvOutput)
      	$fSUMMARY.write( "#{$AliasOutput}.ERS-RatingGJ/a  =  #{$gResults['TSV']['ERSRating']} \n" )
      	$fSUMMARY.write( "#{$AliasOutput}.ERS-RefHouseRatingGJ/a  =  #{$gResults['TSV']['ERSRefHouseRating']} \n" )
      	$fSUMMARY.write( "#{$AliasOutput}.ERS-GHGt/a  =  #{$gResults['TSV']['ERSGHG']} \n" )
      end


      # These #s are not yet averaged for orientations!
      $fSUMMARY.write( "#{$aliasOutput}.PEAK-Heating-W    =  #{$gResults[$outputHCode]['avgOthPeakHeatingLoadW'].round(1)}\n" )
      $fSUMMARY.write( "#{$aliasOutput}.PEAK-Cooling-W    =  #{$gResults[$outputHCode]['avgOthPeakCoolingLoadW'].round(1)}\n" )

      $fSUMMARY.write( "#{$aliasInput}.PV-size-kW        =  #{$PVcapacity.round(1)}\n" )



      $fSUMMARY.write( "#{$aliasArch}.Floor-Area-m2     =  #{$FloorArea.to_f.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasArch}.House-Volume-m3   =  #{$HouseVolume.to_f.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.TEDI_kWh_m2       =  #{$TEDI_kWh_m2.to_f.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.MEUI_kWh_m2       =  #{$MEUI_kWh_m2.to_f.round(1)} \n" )

      $fSUMMARY.write( "#{$aliasOutput}.ERS-Value         =  #{$gERSNum.to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasOutput}.NumTries          =  #{$NumTries.to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasOutput}.LapsedTime        =  #{$runH2KTime.to_f.round(2)}\n" )
      # Windows characteristics
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-S        =  #{$SHGCWin[1].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-S     =  #{$rValueWin[1].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-S     =  #{$AreaWin_sum[1].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-SE       =  #{$SHGCWin[2].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-SE    =  #{$rValueWin[2].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-SE    =  #{$AreaWin_sum[2].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-E        =  #{$SHGCWin[3].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-E     =  #{$rValueWin[3].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-E     =  #{$AreaWin_sum[3].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-NE       =  #{$SHGCWin[4].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-NE    =  #{$rValueWin[4].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-NE    =  #{$AreaWin_sum[4].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-N        =  #{$SHGCWin[5].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-N     =  #{$rValueWin[5].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-N     =  #{$AreaWin_sum[5].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-NW       =  #{$SHGCWin[6].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-NW    =  #{$rValueWin[6].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-NW    =  #{$AreaWin_sum[6].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-W        =  #{$SHGCWin[7].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-W     =  #{$rValueWin[7].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-W     =  #{$AreaWin_sum[7].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-SW       =  #{$SHGCWin[8].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-SW    =  #{$rValueWin[8].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-SW    =  #{$AreaWin_sum[8].to_f.round(1)}\n" )
      # House components
      $fSUMMARY.write( "#{$aliasArch}.Area-Door-m2      =  #{$AreaComp['door'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-DoorWin-m2   =  #{$AreaComp['doorwin'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-Windows-m2   =  #{$AreaComp['win'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-Wall-m2      =  #{$AreaComp['wall'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-Header-m2    =  #{$AreaComp['header'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-Ceiling-m2   =  #{$AreaComp['ceiling'].to_f.round(3)}\n" )
      #$fSUMMARY.write( "#{$aliasArch}.Area-ExposedFloor-m2     =  #{$AreaComp['floor'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-House-m2     =  #{$AreaComp['house'].to_f.round(3)}\n" )
      # House R-Value
      $fSUMMARY.write( "#{$aliasOutput}.House-R-Value(SI) =  #{$RSI['house'].to_f.round(3)}\n" )

      $fSUMMARY.write( "#{$aliasOutput}.Cost of options using unit costs = #{$optionCost.round(0)}\n")
      for status_type in $gStatus.keys()
        $fSUMMARY.write( "s.#{status_type} = #{$gStatus[status_type]}\n" )
      end

      if $ExtraOutput1 then
        $fSUMMARY.write( "#{$aliasOutput}.EnvTotalHL-GJ     =  #{$gResults[$outputHCode]['EnvHLTotalGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvCeilHL-GJ      =  #{$gResults[$outputHCode]['EnvHLCeilingGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvWallHL-GJ      =  #{$gResults[$outputHCode]['EnvHLMainWallsGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvWinHL-GJ       =  #{$gResults[$outputHCode]['EnvHLWindowsGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvDoorHL-GJ      =  #{$gResults[$outputHCode]['EnvHLDoorsGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvFloorHL-GJ     =  #{$gResults[$outputHCode]['EnvHLExpFloorsGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvCrawlHL-GJ     =  #{$gResults[$outputHCode]['EnvHLCrawlspaceGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvSlabHL-GJ      =  #{$gResults[$outputHCode]['EnvHLSlabGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvBGBsemntHL-GJ  =  #{$gResults[$outputHCode]['EnvHLBasementBGWallGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvAGBsemntHL-GJ  =  #{$gResults[$outputHCode]['EnvHLBasementAGWallGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvBsemntFHHL-GJ  =  #{$gResults[$outputHCode]['EnvHLBasementFlrHdrsGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvPonyWallHL-GJ  =  #{$gResults[$outputHCode]['EnvHLPonyWallGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvFABsemntHL-GJ  =  #{$gResults[$outputHCode]['EnvHLFlrsAbvBasementGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvAirLkVntHL-GJ  =  #{$gResults[$outputHCode]['EnvHLAirLkVentGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.AnnDHWLoad-GJ     =  #{$gResults[$outputHCode]['AnnHotWaterLoadGJ'].round(1)}\n")

        $fSUMMARY.write( "#{$aliasOutput}.SpcHeatElec-GJ    =  #{$gResults[$outputHCode]['AnnSpcHeatElecGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.SpcHeatGas-GJ     =  #{$gResults[$outputHCode]['AnnSpcHeatGasGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.SpcHeatOil-GJ     =  #{$gResults[$outputHCode]['AnnSpcHeatOilGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.SpcHeatProp-GJ    =  #{$gResults[$outputHCode]['AnnSpcHeatPropGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.SpcHeatWood-GJ    =  #{$gResults[$outputHCode]['AnnSpcHeatWoodGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.HotWaterElec-GJ c  =  #{$gResults[$outputHCode]['AnnHotWaterElecGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.HotWaterGas-GJ    =  #{$gResults[$outputHCode]['AnnHotWaterGasGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.HotWaterOil-GJ    =  #{$gResults[$outputHCode]['AnnHotWaterOilGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.HotWaterProp-GJ   =  #{$gResults[$outputHCode]['AnnHotWaterPropGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.HotWaterWood-GJ   =  #{$gResults[$outputHCode]['AnnHotWaterWoodGJ'].round(1)} \n")
      end


      if ( $gChoices["Opt-Archetype"].nil? || $gChoices["Opt-Archetype"].empty? ) then

        $gChoices["Opt-Archetype"] = $gBaseModelFile

      end

      if $gReportChoices then
        $fSUMMARY.write( "#{$aliasInput}.Run-Region       =  #{$gRunRegion}\n" )
        $fSUMMARY.write( "#{$aliasInput}.Run-Locale       =  #{$gRunLocale}\n" )
        $fSUMMARY.write( "#{$aliasInput}.House-Upgraded   =  #{houseUpgraded}\n" )
        $gChoices.sort.to_h
        for attribute in $gChoices.keys()
          choice = $gChoices[attribute]

          $fSUMMARY.write("#{$aliasInput}.#{attribute} = #{choice}\n")
        end


      end




      # Possibly report Binned data from diagnostics file
      if ($gReadROutStrTxt) then

        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"

          $fSUMMARY.write("#{$aliasOutput}.BIN-data-HRS-#{binstr}   =  #{$binDatHrs[bin].round(4)}\n")

        end


        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"


          $fSUMMARY.write("#{$aliasOutput}.BIN-data-TMP-#{binstr}   =  #{$binDatTmp[bin].round(4)}\n")


        end

        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"


          $fSUMMARY.write("#{$aliasOutput}.BIN-data-HLR-#{binstr}   =  #{$binDatHLR[bin].round(4)}\n")



        end

        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"

          $fSUMMARY.write("#{$aliasOutput}.BIN-data-T2cap-#{binstr} =  #{$binDatT2cap[bin].round(4)}\n")


        end

        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"


          $fSUMMARY.write("#{$aliasOutput}.BIN-data-T2PLR-#{binstr} =  #{$binDatT2PLR[bin].round(4)}\n")



        end


        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"

          #$fSUMMARY.write("BIN-data-T1cap-#{binstr} = #{$binDatT1cap[bin].round(4)}\n")


        end

        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"

          $fSUMMARY.write("#{$aliasOutput}.BIN-data-T1PLR-#{binstr} =  #{$binDatT1PLR[bin].round(4)}\n")




        end

      end





      if ( ! $PRMcall )
        if !$keepH2KFolder
          FileUtils.rm_r ( "#{$gMasterPath}\\H2K" )
        end
      end



      ReportMsgs()

      $fSUMMARY.close()
      $fLOG.close()
