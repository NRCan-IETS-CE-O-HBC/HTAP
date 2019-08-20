
require 'optparse'
require 'pp'
require 'json'
require 'set'
require 'rexml/document'

require_relative 'include/msgs'
require_relative 'include/constants'
require_relative 'include/HTAPUtils.rb'

include REXML   # This allows for no "REXML::" prefix to REXML methods

$program = "export-pathways-data.rb"

jsonSourceFile = nil

GoodArchDataFields = [
   "archID",
   "h2k-File",
   "house-description:type", 
   "house-description:stories",
   "house-description:buildingType",
   "house-description:frontOrient",  
   "house-description:MURBUnits",
   "locale:region",
   "locale:weatherLoc",   
   "dimensions:below-grade:basement:configuration",
   "dimensions:below-grade:basement:exposed-perimeter",
   "dimensions:below-grade:basement:floor-area",
   "dimensions:below-grade:basement:total-perimeter",
   "dimensions:below-grade:crawlspace:configuration",
   "dimensions:below-grade:crawlspace:exposed-perimeter",
   "dimensions:below-grade:crawlspace:floor-area",
   "dimensions:below-grade:crawlspace:total-perimeter",
   "dimensions:below-grade:slab:configuration",
   "dimensions:below-grade:slab:exposed-perimeter",
   "dimensions:below-grade:slab:floor-area",
   "dimensions:below-grade:slab:total-perimeter",
   "dimensions:below-grade:walls:below-grade-area:external",
   "dimensions:below-grade:walls:below-grade-area:internal",
   "dimensions:below-grade:walls:total-area:external",
   "dimensions:below-grade:walls:total-area:internal",
   "dimensions:ceilings:area:all",
   "dimensions:ceilings:area:attic",
   "dimensions:ceilings:area:cathedral",
   "dimensions:ceilings:area:flat",
   "dimensions:exposed-floors:area:total",
   "dimensions:headers:area:above-grade",
   "dimensions:headers:area:below-grade",
   "dimensions:headers:area:total",
   "dimensions:heatedFloorArea",
   "dimensions:walls:above-grade:area:doors",
   "dimensions:walls:above-grade:area:gross",
   "dimensions:walls:above-grade:area:headers",
   "dimensions:walls:above-grade:area:net",
   "dimensions:walls:above-grade:area:windows",
   "dimensions:walls:above-grade:count",
   "dimensions:walls:above-grade:perimeter",
   "dimensions:windows:area:byOrientation:1",
   "dimensions:windows:area:byOrientation:2",
   "dimensions:windows:area:byOrientation:3",
   "dimensions:windows:area:byOrientation:4",
   "dimensions:windows:area:byOrientation:5",
   "dimensions:windows:area:byOrientation:6",
   "dimensions:windows:area:byOrientation:7",
   "dimensions:windows:area:byOrientation:8",
   "dimensions:windows:area:total"
]

GoodECMFields = Array.new [
  "ecmID",
  "attribute",
  "measure"
]


GoodECMCatagories = Array.new [ 
  "Opt-ACH",
  "Opt-CasementWindows",
  "Opt-WindowDistribution",
  "Opt-AtticCeilings",
  "Opt-CathCeilings",
  "Opt-FlatCeilings",
  "Opt-GenericWall_1Layer_definitions",
  "Opt-FloorHeaderIntIns",
  "Opt-ExposedFloor",
  "Opt-FoundationSlabBelowGrade", 
  "Opt-FoundationSlabOnGrade", 
  "Opt-FoundationWallExtIns", 
  "Opt-FoundationWallIntIns", 
  "Opt-HRVonly",
  "Opt-HVACSystem",
  "Opt-DHWSystem",
  "Opt-DWHR-System",

]

GoodRunDataFields = Array.new [ 
  "runID",
  "archID",
  "listOfECMs",
  "version:git-branch",
  "version:git-revision",  
  "version:HOT2000",
  "version:h2kHouseFile",
  "Recovered-results",
  "Opt-Location",
  "HDDs",
  "Opt-Ruleset",
  "Ruleset-Ventilation",
  "Ruleset-Fuel-Source",
  "Opt-Baseloads",
  "Opt-Temperatures",  
  "House-Upgraded",
  "upgrade-package-list",
  "Opt-ACH",
  "Opt-CasementWindows",
  "Opt-WindowDistribution",
  "Opt-AtticCeilings",
  "Opt-CathCeilings",
  "Opt-FlatCeilings",
  "Opt-GenericWall_1Layer_definitions",
  "Opt-FloorHeaderIntIns",
  "Opt-ExposedFloor",
  "Opt-FoundationSlabBelowGrade", 
  "Opt-FoundationSlabOnGrade", 
  "Opt-FoundationWallExtIns", 
  "Opt-FoundationWallIntIns", 
  "Opt-HRVonly",
  "Opt-HVACSystem",
  "Opt-DHWSystem",
  "Opt-DWHR-System",
  "House-ListOfUpgrades",
  "Energy-Total-GJ",
  "Energy-HeatingGJ",
  "Energy-CoolingGJ",
  "Energy-VentGJ",
  "Energy-DHWGJ",
  "Energy-PlugGJ",
  "EnergyEleckWh",
  "EnergyGasM3",
  "EnergyOil_l",
  "EnergyProp_L",
  "EnergyWood_cord",
  "Gross-HeatLoss-GJ",
  "PEAK-Cooling-W",
  "PEAK-Heating-W",
  "TEDI_kWh_m2",
  "MEUI_kWh_m2",
   "HVAC:ASHP:capacity_kW",
   "HVAC:ASHP:count",
   "HVAC:AirConditioner:capacity_kW",
   "HVAC:AirConditioner:count",
   "HVAC:Baseboards:capacity_kW",
   "HVAC:Baseboards:count",
   "HVAC:Boiler:capacity_kW",
   "HVAC:Boiler:count",
   "HVAC:Furnace:capacity_kW",
   "HVAC:Furnace:count",
   "HVAC:GSHP:capacity_kW",
   "HVAC:GSHP:count",
   "HVAC:Ventilator:capacity_l/s",
   "HVAC:Ventilator:count",
   "HVAC:designLoads:cooling_W",
   "HVAC:designLoads:heating_W",
   "HVAC:fansAndPump:count",
   "HVAC:fansAndPump:powerHighW",
   "HVAC:fansAndPump:powerLowW"
]




HTAPInit()


def flattenHash(thisHash,breadCrumbs="")
  debug_off

  flatData = Hash.new 



  thisHash.keys.sort.each do | key |
    
    currHeader = "#{breadCrumbs}:#{key}"
    debug_out ("> #{breadCrumbs} > + #{key} = ")
    if ( thisHash[key].is_a?(Hash) ) then 
      debug_out ("( #{breadCrumbs} > + #{key} ) = ")
      flatData.merge!( flattenHash(thisHash[key], currHeader ) )
    else 
      debug_out ("= #{currHeader} \n")
      flatData.merge!( { "#{currHeader.gsub(/^:/,"")}" => thisHash[key] } ) 
    end 
  end 
  debug_out ("<<returning\n#{flatData.pretty_inspect}\n<<end\n")
  return flatData

end 

#=====================================================================================
# Parse command-line switches.
#=====================================================================================
optparse = OptionParser.new do |opts|

   opts.separator " USAGE: #{$program} --json-source HTAP-prm-output.json  "
   opts.separator " "
   opts.separator " Required inputs:"

    opts.on("-j", "--json-source FILE", "Specified json data souce (.json)") do |j|
      jsonSourceFile = j
    end


   opts.on("-h", "--help", "Show help message") do
      puts opts
      exit()
   end

end 

optparse.parse!

# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
# Parse data file 
if emptyOrNil ( jsonSourceFile ) then 
  fatalerror ("Source data file must be specified with the --json-source option!")
end 

if ( !File.exist?(jsonSourceFile) )
  fatalerror ("Source data file #{jsonSourceFile} cannot be found!")
end 

stream_out ("Parsing #{jsonSourceFile}...")

fHTAPResults = File.new(jsonSourceFile, "r")
if fHTAPResults == nil then
  fatalerror(" Could not read #{jsonSourceFile}.\n")
end

dataRaw = fHTAPResults.read
fHTAPResults.close

allData = JSON.parse(dataRaw)
dataRaw = nil
stream_out("done.\n")
info_out ("Parsed #{jsonSourceFile}")






# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
# Loop through results, build simple hashes

$archetypeData = Array.new
$runData = Array.new 
$ecmData = Array.new

# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
# GetArchID - takes a HTAP run result, determines if it already exists in the archetype set, and 
# adds it if not. Returns the archetype ID
def getArchID(result)
  foundArch = false 
  archID = nil
  archCount = 0
  #debug_ 
  
  if (! emptyOrNil($archetypeData) ) then 
    $archetypeData.each do | archetype | 
      archCount += 1
      debug_out (" > # #{archetype["archID"]} - #{archetype["h2k-File"]} == #{result["archetype"]["h2k-File"]} ?")
      if archetype["h2k-File"] == result["archetype"]["h2k-File"] then 
        archID = archetype["archID"]
        foundArch = true 
        
      end 
      debug_out ("#{foundArch}\n")
    end 
  end 
      
  if ( ! foundArch )

    debug_out "Saving archetype !\n"
    archID = archCount + 1
    thisArchetype = Hash.new 
    thisArchetype["archID"] = archID  
    thisArchetype["h2k-File"] = result["archetype"]["h2k-File"]
    dimensionData = flattenHash(result["cost-estimates"]["costing-dimensions"])
    
    debug_out "archID: #{archID}\n"
    dimensionData.each do | member |
      #debug_out (">#{member.pretty_inspect}\n") 
    end 
    #debug_out (">#{dimensionData.pretty_inspect}\n") 


    debug_out ("> saving #{thisArchetype}\n")
    thisArchetype.merge!(dimensionData)
    

    #result["archetype"].keys.each do | key |
    #  if ($archetypeFields.include?(key) )
    #    thisArchetype[key] = result["archetype"][key]
    #  end 
    #end 

    $archetypeData.push(thisArchetype)
    debug_off
  end 

  return archID

end 

# . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
# GetArchID - takes a HTAP run result, determines if the selected options exist in the list of ecms,
# adds them it if not. Returns a ';' delimited string of selected ECMs.

def getECMs(inputHash)
  debug_off

  listOfECMs = ""

  inputHash.each do | key, value |
    ecmCount = 0 
    ecmID = ""
    foundECM = false 

    if (GoodECMCatagories.include?(key) )
    
      searchTextKey = "#{key}:+:#{value}"
      if ( ! emptyOrNil ($ecmData) )
      
        debug_out "Key: #{key} => #{value} ?"

        $ecmData.each do | ecm | 
          ecmCount += 1
          if ( ecm["searchTextKey"] == searchTextKey )
            foundECM = true
            ecmID = ecm["ecmID"]
            debug_out "FOUND @ #{ecmID} !" 
            break
          end 
        end  
      end 
    
      if ( ! foundECM )

        ecmID = ecmCount + 1 
        $ecmData.push( 
          { "ecmID" => ecmID, "searchTextKey" => searchTextKey, "attribute" => key, "measure" => value }
        )
        debug_out "not found. Added new row @ #{ecmID} !"

      end 

      listOfECMs += ";#{ecmID}"
      debug_out ("\n")

    end


  end 
  debug_out "\n LIST OF ECMS: #{listOfECMs}\n"
  debug_off 
  return listOfECMs.gsub(/^;/,"")

end 

badRecords = false 
badRecordNums = Array.new 

gitBranch   = allData["htap-configuration"]["git-branch"]
gitRevision = allData["htap-configuration"]["git-revision"]

result_count = 0
stream_out "\n"
spacer = "|"
stream_line = ""
width = 20

rule = " +" + "-".ljust(width,"-") + 
        "+" + "-".ljust(width,"-") + 
        "+" + "-".ljust(width,"-") + "+\n"
stream_out(rule)
stream_out " "+spacer+"Archetypes".rjust(width)+spacer+"ECMs".rjust(width)+spacer+"Runs".rjust(width)+spacer+"\n"
stream_out(rule)

countArchetypes = 0
countRUns = 0 
countECMs = 0 

allData["htap-results"].each do | result |
  result_count += 1

  #pp result
  if (result["status"]["success"] ) then 

    archID = getArchID(result)


    thisRun = Hash.new 
    thisRun["runID"] = result["result-number"] 
    thisRun["archID"] = archID

    thisRun["version:git-branch"]= gitBranch
    thisRun["version:git-revision"] = gitRevision
    thisRun.merge!( flattenHash( result["input"]   ) ) 
    thisRun.merge!( flattenHash( result["configuration"]) ) 
    thisRun.merge!( flattenHash( result["output"]) ) 
    thisRun.merge!( flattenHash( result["cost-estimates"]["costing-dimensions"]) ) 

    thisRun["listOfECMs"] = "[#{getECMs(result["input"])}]" 

    #stream_out("Reading result # #{result_count}...                     \r" )
  
    $runData.push(thisRun)

  else
    badRecords = true 
    badRecordNums.push(result["result-number"])
  end 
  #if ( emptyOrNil())
  countArchetypes = $archetypeData.length.to_s.rjust(width) 
  countECMs = $ecmData.length.to_s.rjust(width) 
  countRUns = $runData.length.to_s.rjust(width)
  stream_line = " "+spacer+countArchetypes+spacer+countECMs+spacer+countRUns+spacer
  stream_out(stream_line+"\r")
  
  #stream_out(" Run results:     #{result_count},   Archetypes #{$archetypeData.length}, ECMs   \r")
  
  
end 

info_out "HTAP data contained #{countArchetypes} archetypes\n"
info_out "HTAP data contained #{countRUns} results\n"
info_out "HTAP data contained #{countECMs} unique ECMs\n"

stream_out ( stream_line+"\n" )
stream_out rule

listOfKeys = "List of available columns for HTAP pathways ([x] denotes columns to appear in output)\n"
listOfKeys += "ARCHDATA:\n"
$archetypeData[0].keys.each do | key | 
  string = ""
  if ( GoodArchDataFields.include?(key) )
    string = " [x] #{key}\n"
  else 
    string = " [ ] #{key}\n"
  end 
  listOfKeys += string 
end 



listOfKeys += "\n\nRUNDATA:\n"
$runData[0].keys.each do | key | 
  string = ""
  if ( GoodRunDataFields.include?(key) )
    string = " [x] #{key}\n"
  else 
    string = " [ ] #{key}\n"
  end 
  listOfKeys += string 
end 


stream_out ("\n\n")
stream_out listOfKeys



if (badRecords) then 
  badRecordList = badRecordNums.to_csv
  warn_out ("HTAP reports the following records were not evaluated successfully: #{badRecordNums}")
end 




def convertToCSV(arrToFlatten,headerArray=[])
  debug_off
  require 'csv'
  flatOutput =""
  # Generate header

  #debug_on
  if ( headerArray.empty? ) then 
    
    debug_out "Building headerRow:"
    arrToFlatten[0].keys.sort_by{ |word| word.downcase }.each do | key |
      debug_out "> #{key}"
      headerArray.push(key)
    end 
    debug_out ("\n")
  
  else 
    debug_out ("using supplied header row. \n")
  
  end 
  debug_off
  
  flatOutput << headerArray.to_csv
  # add rows 

  arrToFlatten.each do | line |
    rowsArray = Array.new
    value = ""
  
    headerArray.each do | key |
      if ( ! emptyOrNil(line[key]) ) 
        value = line[key]
      else
        #warn_out ("Null data encontered!")
      end 

      rowsArray.push(value)
 
    end 
    flatOutput << rowsArray.to_csv 
  
  end

  return flatOutput 
end

flatOutput = convertToCSV($archetypeData, GoodArchDataFields)
csv_outfile = File.open('./Pathways_HTAPArchetypeData.csv', 'w')
csv_outfile.puts flatOutput
csv_outfile.close

flatOutput = convertToCSV($runData,GoodRunDataFields)
csv_outfile = File.open('./Pathways_HTAPRunData.csv', 'w')
csv_outfile.puts flatOutput
csv_outfile.close

ecmDataSort = $ecmData.sort_by{|ecm| ecm["attribute"]}

flatOutput = convertToCSV(ecmDataSort, GoodECMFields)
csv_outfile = File.open('./Pathways_ListOfECMs.csv', 'w')
csv_outfile.puts flatOutput
csv_outfile.close

availabeData = File.open('./Pathways_available_fields.txt','w')
availabeData.puts listOfKeys
availabeData.close


ReportMsgs()


