
workingfile = "HTAPUnitCostsDraft.json"

del = system ("rm -f #{workingfile}")

sheetPath = 'C:\\Users\\aferguso\\Google Drive\\NRCan work\\NRCan-Optimization-Results\\Cost-data-sheets\\Unit-Costs'

sheets = {
  "LEEP-ON-Ottawa" => {
    "filename" => "LEEP_COSTING_ottawa_V1.4.csv" ,
    "date_collated" => "2013-09-01",
    "schema_used" => "oldLeep",
    "origin" => "Costs used in Ottawa LEEP 2013"
  },
  "LEEP-MB-Winnipeg" => {
    "filename" => "LEEP_Costing_MB_winnipeg.csv",
    "date_collated" => "2014-09-01",
    "schema_used" => "oldLeep",
    "origin" => "Costs used in MB LEEP 2014"
  },
  "LEEP-BC-Vancouver" => {
    "filename" => "LEEP_COSTING_BC-vancouver_V1.0.csv",
    "date_collated" => "2016-09-01",
    "date_imported" => "2018-10-02 11:32:55",
    "schema_used" => "oldLeep",
    "origin" => "Costs used in Vancouver LEEP 2016"
  },
  "LEEP-BC-KamloopsChesnut" => {
    "filename"=> "LEEP_COSTING_Sept_2016_Chesnut.csv",
    "date_collated"=> "2016-09-01",
    "schema_used"=> "oldLeep",
    "origin"=> "Costs used in Kamloops LEEP 2016"
  },
  "VancouverAirSealData" => {
    "filename" => "E3-air-sealing.csv",
    "orgin" => "Halbig 2015, Air-Barrier details, Report for NRCan. E3 Consulting",
    "date_collated" => "2015-01-15",
    "schema_used" => "oldLeep"
  },
  "MiscNRCanEstimates2019" => {
    "filename" => "misc-cost-data.csv",
    "orgin" => "NRCan - collected cost estimates from in-house research",
    "date_collated" => "2019-01-04",
    "schema_used" => "oldLeep",
    "debug" => false
  }
}




sheets.keys.each do | set |

  file    = sheets[set]["filename"]
  source  = sheets[set]["orgin"]
  date    = sheets[set]["date_collated"]
  schema  = sheets[set]["schema_used"]

  if ( ! sheets[set]["debug"].nil? ) then
    debug = sheets[set]["debug"]
  else
    debug = false
  end

  filepath = "'#{sheetPath}\\#{file}'"

  cmd = "..\\coax-cost-data.rb"
  cmd += " --import #{filepath}"
  cmd += " --source '#{source}'"
  cmd += " --date '#{date}'"
  cmd += " --set '#{set}'"
  cmd += " --schema '#{schema}'"
  cmd += " --database '#{workingfile}' "
  if (debug) then
    cmd += " -d"
  end
  cmd += " 2>&1"

  print "\n\n{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{import}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}\n\n"
  print "> Processing data for #{set} \n"

  print "-CMD--------------------------------------------------------------\n"
  print " > #{cmd}\n"
  print "-----------------------------------------------------------------\n"

  ok = system (cmd)


  #results = `#{cmd}`

  break if ( ! ok )

end


#.\coax-cost-data.rb --date 2015-01-15 --import "E3-air-sealing
#.csv" --schema oldLeep --source "Halbig 2015, Air-Barrier details, Report for NRCan. E3 Consulting" --database .\HTAPUnitCos
#ts.json  --set VancouverAirSealData  -d
