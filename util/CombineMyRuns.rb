require 'fileutils'
require 'pp'
require 'csv'


files = ARGV

AliasesForAttributes = {
  "Opt-GenericWall_1Layer_definitions" => "Opt-AboveGradeWall",
  "Opt-FloorAboveCrawl" => "Opt-ExposedFloor",
  "Opt-HRVonly" => "Opt-VentSystem",
  "Opt-CasementWindows" => "Opt-Windows", 
  "Opt-HVACSystem" => "Opt-Heating-Cooling",
  "Opt-DWHRSystem" => "Opt-DWHR"
}



KeepTheseColumns = 
[#"myID",                                                                      
 # "myBatchname",                                               
 # "analysis_BCStepCode|TEDI_compliance",
 # "archetype|Area-Basement-m2",
 # "archetype|Area-Ceiling-m2",
 # "archetype|Area-Crawl-m2",
 # "archetype|Area-Door-m2",
 # "archetype|Area-DoorWin-m2",
 # "archetype|Area-ExposedFloor-m2",
 # "archetype|Area-Header-m2",
 # "archetype|Area-House-m2",
 # "archetype|Area-Slab-m2",
# "archetype|Area-Walkout-m2",
 "archetype|Area-Wall-m2",
 "archetype|Area-Windows-m2",
 "archetype|Base-Locale",
 "archetype|Base-City",
# "archetype|Base-Region",
# "archetype|Ceiling-Type",
 "archetype|Floor-Area-m2",
# "archetype|Front-Orientation",
# "archetype|House-Builder",
 "archetype|House-Storeys",
 "archetype|House-Type",
 "archetype|House-Volume-m3",
# "archetype|Weather-Locale",
# "archetype|Win-Area-m2-E",
# "archetype|Win-Area-m2-N",
# "archetype|Win-Area-m2-NE",
# "archetype|Win-Area-m2-NW",
# "archetype|Win-Area-m2-S",
# "archetype|Win-Area-m2-SE",
# "archetype|Win-Area-m2-SW",
# "archetype|Win-Area-m2-W",
# "archetype|Win-R-value-E",
# "archetype|Win-R-value-N",
# "archetype|Win-R-value-NE",
# "archetype|Win-R-value-NW",
# "archetype|Win-R-value-S",
# "archetype|Win-R-value-SE",
# "archetype|Win-R-value-SW",
# "archetype|Win-R-value-W",
# "archetype|Win-SHGC-E",
# "archetype|Win-SHGC-N",
# "archetype|Win-SHGC-NE",
# "archetype|Win-SHGC-NW",
# "archetype|Win-SHGC-S",
# "archetype|Win-SHGC-SE",
# "archetype|Win-SHGC-SW",
# "archetype|Win-SHGC-W",
 "archetype|climate-zone",
 "archetype|fuel-DHW-presub",
 "archetype|fuel-heating-presub",
 "archetype|h2k-File",
# "configuration|ChoiceFile",
# "configuration|OptionsFile",
# "configuration|Recovered-results",
# "configuration|RunDirectory",
# "configuration|RunNumber",
# "configuration|SaveDirectory",
# "configuration|version",
# "cost-estimates|audit",
 "cost-estimates|byAttribute|Opt-Ceilings",
 "cost-estimates|byAttribute|Opt-AtticCeilings",
 "cost-estimates|byAttribute|Opt-FlatCeilings",
 "cost-estimates|byAttribute|Opt-CathCeilings",
 "cost-estimates|byAttribute|Opt-ACH",
 "cost-estimates|byAttribute|Opt-CasementWindows",
 "cost-estimates|byAttribute|Opt-DWHRSystem",
 "cost-estimates|byAttribute|Opt-GenericWall_1Layer_definitions",
 "cost-estimates|byAttribute|Opt-HVACSystem",
 "cost-estimates|byAttribute|Opt-HRVonly",
 "cost-estimates|byAttribute|Opt-DHWSystem",
 "cost-estimates|byAttribute|Opt-FoundationWallExtIns",
 "cost-estimates|byAttribute|Opt-FoundationWallIntIns",
 "cost-estimates|byAttribute|Opt-FoundationSlabBelowGrade",
 "cost-estimates|byAttribute|Opt-FoundationSlabOnGrade",
 "cost-estimates|byAttribute|Opt-FloorHeaderIntIns",
 "cost-estimates|byAttribute|Opt-ExposedFloor",
 "cost-estimates|byBuildingComponent|envelope",
 "cost-estimates|byBuildingComponent|mechanical",
 "cost-estimates|byBuildingComponent|renewable",
 "cost-estimates|bySource",
# "cost-estimates|costing-dimensions",
# "cost-estimates|status",
 "cost-estimates|total",
# "input|GOconfig_rotate",
 "input|House-ListOfUpgrades",
 "input|House-Upgraded",
 "input|Opt-ACH",
# "input|Opt-AtticCeilings",
# "input|Opt-Baseloads",
 "input|Opt-CasementWindows",
# "input|Opt-CathCeilings",
 "input|Opt-Ceilings",
# "input|Opt-DBFiles",
 "input|Opt-DHWSystem",
 "input|Opt-DWHRSystem",
# "input|Opt-DoorWindows",
# "input|Opt-Doors",
# "input|Opt-ExposedFloor",
 "input|Opt-FlatCeilings",
 "input|Opt-FloorHeaderIntIns",
 "input|Opt-FoundationSlabBelowGrade",
 "input|Opt-FoundationSlabOnGrade",
 "input|Opt-FoundationWallExtIns",
 "input|Opt-FoundationWallIntIns",
# "input|Opt-FuelCost",
 "input|Opt-GenericWall_1Layer_definitions",
# "input|Opt-H2K-PV",
 "input|Opt-HRVonly",
 "input|Opt-HRVspec",
 "input|Opt-HVACSystem",
 "input|Opt-Location",
# "input|Opt-MainWall",
# "input|Opt-ResultHouseCode",
 "input|Opt-Ruleset",
# "input|Opt-Skylights",
# "input|Opt-Specifications",
# "input|Opt-Temperatures",
 "input|Opt-WindowDistribution",
 "input|Ruleset-Fuel-Source",
 "input|Ruleset-Ventilation",
 "input|Run-Locale",
 "input|Run-Region",
 "input|upgrade-package-list",
 "output|AuxEnergyReq-HeatingGJ",
# "output|AvgAirConditioning-COP",
# "output|ERS-Value",
 "output|Energy-CoolingGJ",
 "output|Energy-DHWGJ",
 "output|Energy-HeatingGJ",
# "output|Energy-PV-kWh",
 "output|Energy-PlugGJ",
 "output|Energy-Total-GJ",
 "output|Energy-VentGJ",
 "output|EnergyEleckWh",
 "output|EnergyGasM3",
 "output|EnergyOil_l",
 "output|EnergyProp_L",
 "output|EnergyWood_cord",
 "output|Gross-HeatLoss-GJ",
 "output|HDDs",
# "output|House-R-Value(SI)",
# "output|LapsedTime",
# "output|MEUI_kWh_m2",
# "output|NumTries",
 "output|PEAK-Cooling-W",
 "output|PEAK-Heating-W",
# "output|Ref-En-Total-GJ",
# "output|SimplePaybackYrs",
# "output|TEDI_kWh_m2",
# "output|TotalAirConditioning-LoadGJ",
 #"output|Useful-Solar-Gain-GJ",
# "output|Util-Bill-Elec",
# "output|Util-Bill-Gas",
# "output|Util-Bill-Net",
# "output|Util-Bill-Oil",
# "output|Util-Bill-Prop",
# "output|Util-Bill-Wood",
# "output|Util-Bill-gross",
# "output|Util-PV-revenue",
# "status|H2KDirCheckSumMatch",
# "status|H2KDirCopyAttempts",
# "status|H2KExecutionAttempts",
 #"status|H2KExecutionTime",
 #"status|MD5master",
 #"status|MD5workingcopy",
 #"status|errors",
 #"status|infoMsgs",
 #"status|processingtime",
 #"status|substitute-h2k-err-msgs",
 "status|success"
 #"status|warnings"
]

def filterGoodCols(line)
  keepCols = Array.new 
  line 
  cols = line.split(",")
  $goodColumns.each do | index | 
  keepCols.push(cols[index])
  end 
  keepLine = keepCols.to_csv
  return keepLine

end 

data = {} 

print "\n\n"

batchCount = 0 

def rebuildCSV(masterfile,files)

  FileUtils.rm_rf(masterfile)
  fOuput = File.new( masterfile,"w")
  masterline = 0
  headerOut = false 


  files.each do | filename |

    colMap = { }


    fInput = File.new( filename, "r")

    linecount = 0 
    firstline = true

    batchCount = 0 

    print " filename > #{filename}\n"

    while !fInput.eof? do

      line = fInput.readline
      
      if firstline then 
        AliasesForAttributes.each_pair do |old,new|
          line.gsub!(/#{new}/,old)
        end 

        colHeaders = line.split(",")
        
        KeepTheseColumns.each do | keepColumn | 
          foundIndex = -1 
          index  = 0 
          colHeaders.each do | foundColumn | 
            if ( keepColumn == foundColumn) then 
              foundIndex = index
            end 
            index = index+ 1 
          end 

          colMap[keepColumn] = foundIndex
   


        end 

        if ( !headerOut ) then 

          lineout = "myID,myBatchname,"
          
          KeepTheseColumns.each do | colName | 
            lineout += "#{colName},"
          end 

          fOuput.puts lineout 
          headerOut = true 
          
        end 

      end 


      if ( ! firstline ) then 
        lineout = "id-#{masterline},#{filename},"
        cols = line.split(",")      
        KeepTheseColumns.each do | colName | 

          colLoc = colMap[colName]
          if ( colLoc == -1 ) 
            colData = 0
          else 
            colData = cols[colLoc]
          end 

          lineout += "#{colData},"

        end 

        fOuput.puts lineout

      end 





      if ( batchCount == 1000 )

        batchCount = 0 
        print " SRC: #{filename} ; LINE # #{linecount}".ljust(80) + "\r"

      end 

      batchCount += 1 
      linecount  += 1 
      masterline += 1 

      firstline = false 
    end 

    print "\n\n"
  end 




  

end 



#rebuildCSV("Draft-DB_merged_prm-output.csv", files_7073) 

rebuildCSV("all-results.csv", files) 


print "\n\n DONE! \n\n"








