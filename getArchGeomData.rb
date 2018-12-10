#!/usr/bin/env ruby
require 'optparse'
require 'rexml/document'
require 'pp'

include REXML   # This allows for no "REXML::" prefix to REXML methods

=begin
# Global variables
=end
$A_WIN_DIR_KEYS = ['South','SouthEast','East','NorthEast','North','NorthWest','West','SouthWest'] # Global constant of H2K facing direction keys
$A_CEILING_KEYS = ['NA','NA','gable','hip','cathedral','flat','scissor'] # Global constant array mapping ceiling type string to code
$resarray = [] # Global array to hold all output data

=begin
# Definitions (functions) declaration and definition
=end
def getTypeHouseString(iVal)
  sout = ''
  case iVal
    when 1 then sout = 'Single-detached'
    when 2 then sout = 'Double/semi-detached'
    when 3 then sout = 'Duplex'
    when 4 then sout = 'Triplex'
    when 5,13,14 then sout = 'Apartment'
    when 6 then sout = 'Rowhouse end'
    when 7 then sout = 'Mobile'
    when 8 then sout = 'Rowhouse mid'
    when 9 then sout = 'Detached duplex'
    when 10 then sout = 'Detached triplex'
    when 11 then sout = 'Attached duplex'
    when 12 then sout = 'Attached triplex'
    else sout = 'NA'
  end
  return sout
end

def getNumStoreysString(iVal)
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

def getPlanShapeString(iVal)
  sout = ''
  case iVal
    when 1 then sout = 'Rectangular'
    when 2 then sout = 'T-shape'
    when 3 then sout = 'L-shape'
    when 4 then sout = '5-6 corners'
    when 5 then sout = '7-8 corners'
    when 6 then sout = '9-10 corners'
    when 7 then sout = '11 or more corners'
    else sout = 'NA'
  end
  return sout
end

=begin
# Read in command line options
=end

# Load command line options
options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: getArchGeomData.rb -f|--folder NAME -o|--output FILENAME"

  opts.on('-f', '--folder FOLDER', 'Folder to search for *.h2k files')  do |s|
    options[:folder] = s
  end
  opts.on('-o', '--output OUTPUT', 'Name of the output XML file')  do |s|
    options[:output] = s
  end
  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Show help message' ) do
    puts opts
    exit
  end
end.parse!
# Check that the mandatory options were provided
begin
  optparse.parse!
  mandatory = [:folder, :output]                                   # Enforce the presence of
  missing = mandatory.select{ |param| options[param].nil? }        # the -f and -o switches
  unless missing.empty?                                            #
    raise OptionParser::MissingArgument.new(missing.join(', '))    #
  end                                                              #
rescue OptionParser::InvalidOption, OptionParser::MissingArgument  #
  puts $!.to_s                                                     # Friendly output when parsing fails
  puts optparse                                                    #
  exit                                                             #
end
####
# Format the input path and output file path to something Dir.glob understands
options[:folder].gsub!('\\', '/') # Convert all backslashes to forward
options[:folder].gsub!(/^\./, '') # Remove leading period
options[:folder].gsub!(/^\//, '') # Remove leading forward slash
options[:folder].gsub!(/\/$/, '') # Remove trailing forward slash

options[:output].gsub!('\\', '/') # Convert all backslashes to forward
options[:output].gsub!(/^\./, '') # Remove leading period
options[:output].gsub!(/^\//, '') # Remove leading forward slash

=begin
# Begin processing files in user designated folder
=end
# Get all files in the user-provided
files = Dir.glob(options[:folder]+'/*.h2k')
if files.empty?
  puts "No h2k files in #{options[:folder]}"
  exit
end

# Loop through all the files and gather the data
files.each do |file|
  # Open file...
  fFileHANDLE = File.new(file, "r")
  h2kElementsIn = Document.new(fFileHANDLE)
  h2kElements = h2kElementsIn.elements()

  # Initialize results hash
  reshash = {}
  
  # Get a name for this record
  reshash["filename"] = File.basename(file, ".*") 

  # Get the building type
  locationText = "HouseFile/House/Specifications/HouseType"
  reshash["buildingType"] = getTypeHouseString(h2kElements[locationText].attributes["code"].to_i)

  # Get number of storeys
  locationText = "HouseFile/House/Specifications/Storeys"
  reshash["storeys"] = getNumStoreysString(h2kElements[locationText].attributes["code"].to_i)

  # Get the plan shape
  locationText = "HouseFile/House/Specifications/PlanShape"
  reshash["planShape"] = getPlanShapeString(h2kElements[locationText].attributes["code"].to_i)

  # Heated floor areas as reported by the user
  locationText = "HouseFile/House/Specifications"
  reshash["aboveGradeHeatedFloorArea"] = h2kElements[locationText].attributes["aboveGradeHeatedFloorArea"]
  reshash["belowGradeHeatedFloorArea"] = h2kElements[locationText].attributes["belowGradeHeatedFloorArea"]

  # Heated volume
  locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/House"
  reshash["heatedVolume"] = h2kElements[locationText].attributes["volume"]
  
  # Get the gross areas from results
  locationText = "HouseFile/AllResults/Results"
  h2kElements.each(locationText) do |element|
    # puts element.attributes["houseCode"]
    if element.attributes["houseCode"] != nil
      next
    end
    # Gather data from this results set (User defined)
    pointer = "./Other/GrossArea"
    reshash["aboveGradeWallArea"] = element.elements[pointer + "/MainFloors"].attributes["mainWalls"].to_f
    reshash["aboveGradeWallArea"] = sprintf("%0.4f",reshash["aboveGradeWallArea"] + element.elements[pointer + "/Basement"].attributes["aboveGrade"].to_f)
    
    reshash["belowGradeWallArea"] = sprintf("%0.4f",element.elements[pointer + "/Basement"].attributes["belowGrade"].to_f)
    reshash["ponyWallArea"] = sprintf("%0.4f",element.elements[pointer].attributes["ponyWall"].to_f)
    reshash["doorsArea"] = sprintf("%0.4f",element.elements[pointer].attributes["doors"].to_f)
    reshash["exposedFloorsArea"] = sprintf("%0.4f",element.elements[pointer].attributes["exposedFloors"].to_f)
    reshash["slabArea"] = sprintf("%0.4f",element.elements[pointer].attributes["slab"].to_f)
    reshash["bsmtFloorHeaderArea"] = sprintf("%0.4f",element.elements[pointer + "/Basement"].attributes["floorHeader"].to_f)
    reshash["bsmtFloorSlabArea"] = sprintf("%0.4f",element.elements[pointer + "/Basement"].attributes["floorSlab"].to_f)
    reshash["crawlFloorArea"] = sprintf("%0.4f",element.elements[pointer + "/Crawlspace"].attributes["floor"].to_f)
    reshash["crawlWallArea"] = sprintf("%0.4f",element.elements[pointer + "/Crawlspace"].attributes["wall"].to_f)
    if (element.elements[pointer + "/Crawlspace"].attributes["floorHeader"] != nil)
      reshash["crawlFloorHeaderArea"] = sprintf("%0.4f",element.elements[pointer + "/Crawlspace"].attributes["floorHeader"].to_f)
    else
      reshash["crawlFloorHeaderArea"] = "0.000"
    end
    
    # Get the window area data
    $A_WIN_DIR_KEYS.each do |dir|
      reshash["windowArea" + dir] = element.elements[pointer + "/MainFloors/Windows/#{dir}"].attributes["grossArea"].to_f
      reshash["windowArea" + dir] = sprintf("%0.4f",reshash["windowArea" + dir] + element.elements[pointer + "/Basement/Windows/#{dir}"].attributes["grossArea"].to_f)
    end
    
    break # We're done here, don't keep looping
  end

  # Initialize the gross ceiling areas
  (2..6).each do |i|
    reshash[$A_CEILING_KEYS[i] + "CeilingArea"] = 0.0
  end
  locationText = "HouseFile/House/Components/Ceiling"
  h2kElements.each(locationText) do |element|
    itypecode = element.elements["./Construction/Type"].attributes["code"].to_i
    reshash[$A_CEILING_KEYS[itypecode] + "CeilingArea"] += element.elements["./Measurements"].attributes["area"].to_f
  end
  (2..6).each do |i|
    reshash[$A_CEILING_KEYS[i] + "CeilingArea"] = sprintf("%0.4f",reshash[$A_CEILING_KEYS[i] + "CeilingArea"])
  end
  
  # Add results hash to array
  $resarray.push(reshash)
end

=begin
# Output to XML. Note: The formatting allows for import into Excel
=end
resXML = Document.new "<MODELS></MODELS>"
$resarray.each do |reshash|
  resElement = Element.new('ARCH')

  # Loop through the hash to gather the data
  reshash.each do |key, value|
    resElement.add_element "#{key}"
    resElement.elements["#{key}"].add_text("#{value}")
  end
  
  # Add this element to the xml doc
  resXML.elements["MODELS"] << resElement
end
formatter = REXML::Formatters::Pretty.new
formatter.compact = true
File.open("#{options[:output]}","w"){|file| file.puts formatter.write(resXML.root,"")}
