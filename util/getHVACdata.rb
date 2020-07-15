#!/usr/bin/env ruby

require 'rexml/document'

require_relative '../inc/msgs'
require_relative '../inc/H2KUtils'
require_relative '../inc/constants'

include REXML
# This allows for no "REXML::" prefix to REXML methods

# Declare globals
sFiles = Array.new
bHasHRV = Array.new
sPrimaryHeatFuel = Array.new
sPrimaryHeatType = Array.new
sSecondaryHeatType = Array.new
sPrimaryDHWFuel = Array.new
sPrimaryDHWType = Array.new

# Process the directory input
if ARGV.empty? then
  puts "   Error: No file path provided\n"
  exit
end
spath = ARGV[0].dup
spath.gsub!(/\\$/,'') # Remove trailing slash
spath.gsub!(/\/$/,'') # Remove trailing slash
spath.gsub!(/\\/,'/') # Convert the slashes because Ruby

# Set up regex pattern
# sPattern = spath + '/*.{H2K,h2k}'
sPattern = spath + '/*.h2k'

# Loop through all the H2K files
Dir.glob(sPattern) {|file|
  filename = File.basename(file, ".*")
  sFiles << filename
  elements = H2KFile.get_elements_from_filename(file)
  
  sPrimaryHeatFuel << H2KFile.getPrimaryHeatSys(elements).to_s
  sPrimaryHeatType << H2KFile.getPrimaryHeatSysType(elements).to_s
  sPrimaryDHWFuel << H2KFile.getPrimaryDHWSys(elements).to_s
  sPrimaryDHWType << H2KFile.getPrimaryDHWSysTankType(elements).to_s
  sSecondaryHeatType << H2KFile.getSecondaryHeatSys(elements).to_s

  if elements["HouseFile/House/Ventilation/WholeHouseVentilatorList/Hrv"] != nil
     bHasHRV << "true"
  else
     bHasHRV << "false"
  end
}

# Write the output
File.open("HTAP_HVAC_Summary.csv", "w") { |f| f.write "filename,primary_space_heating_fuel,primary_space_heating_type,secondary_space_heating_type,primary_DHW_fuel,primary_DHW_type,HRV_present\n" }
sFiles.each_with_index do |thisFile, index|
  File.write("HTAP_HVAC_Summary.csv", "#{thisFile},#{sPrimaryHeatFuel[index]},#{sPrimaryHeatType[index]},#{sSecondaryHeatType[index]},#{sPrimaryDHWFuel[index]},#{sPrimaryDHWType[index]},#{bHasHRV[index]}\n", mode: "a")
end