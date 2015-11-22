#!/usr/bin/env ruby
# runH2K.rb

=begin rdoc
This script uses the Rexml parser, which is written in Ruby itself.
More information at http://www.germane-software.com/software/rexml
=end
require 'rexml/document'
include REXML		# This allows for no "REXML::" prefix to REXML methods

=begin rdoc
Returns DOM elements of a given filename. DOM: Document Object Model -- a programming interface for HTML, XML and SVG documents.
=end
def get_elements_from_filename(filename)
  $h2kFile = File.open(filename)
  # Need to add error checking on failed open of existing file!
  $XMLdoc = Document.new($h2kFile)
  return $XMLdoc.elements()
end

def get_elements_from_codelib(filename)
  $h2kCodeFile = File.open(filename)
  $XMLCodedoc = Document.new($h2kCodeFile)
  return $XMLCodedoc.elements()
end


if ARGV.empty? then
  puts("Need a command line argument with full path to the h2k file!")
  exit()
end

# Load a HOT2000 file using command line parameter and assign contents to a Hash
$h2kElements = get_elements_from_filename(ARGV[0])

# Load a HOT2000 code library file and assign contents to a Hash
$h2kCodeLibElements = get_elements_from_codelib("c:\\HOT2000_v11_76\\StdLibs\\codeLib.cod")

print("Application Name: ")
$h2kElements.each("HouseFile/Application/Name") { |element| print "#{element.text}\n" }

puts("\nIDs and Labels of main house components:")
$h2kElements.each("HouseFile/House/Components/*") { |element1| 
   print "#{element1.attributes["id"]}: #{element1.get_text("Label")}\n" 
}

print("\nWeather file name: ")
XPath.each( $XMLdoc, "HouseFile/ProgramInformation/Weather") { |element| 
  print "#{element.attributes["library"]} "
}
# XPath.first(..) DOESN'T WORK
print "  or other method: #{$h2kElements["HouseFile/ProgramInformation/Weather"].attributes["library"]}\n"

puts("\nrValue of all ceilings:")
locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
$h2kElements.each(locationText) { |element| 
  puts element.attributes["rValue"] 
}
# Alternate method 1
puts("rValue of all ceilings (using XPath):")
XPath.each( $XMLdoc, locationText) { |element| 
  puts element.attributes["rValue"] 
}
# Alternate method 2
puts("rValue of first ceiling (more direct method):")
puts $h2kElements[locationText].attributes["rValue"]

=begin rdoc
Changing all envelope codes (i.e., walls, ceilings, exposed floors, basement walls and floors, windows, doors) to User Specified is the simplest change since we don't need to reference the <Codes> section. However, we need "system" effective R-values pre-determined.
=end
puts("\nChange all existing wall codes to User Specified: ")
locationText = "HouseFile/House/Components/Wall/Construction/Type"
XPath.each( $XMLdoc, locationText) do |element| 
  puts " - Existing wall code is: #{element.text} and R-Value is #{element.attributes["rValue"]}."
  element.text = "User specified"
  element.attributes["rValue"] = 3.99
  if element.attributes["idref"] then
    element.delete_attribute("idref")	# Must delete attribute for User Specified!
  end
  puts " - New wall code is: #{element.text} and R-Value is #{element.attributes["rValue"]}."
end

=begin rdoc
Changing all codes to a Standard, Favourite or UserDefined code involves setting a reference in the <House><Components> section to an entry reference that must be created in the <Codes> section of the house file.  This can be done by referencing an existing code name (e.g., "Attic28") in the Codes Library file and copy-and-paste the contents of either <Favorite><Code>... or <UserDefined><Code>... from the codes library file (.cod) file into the <Codes> section of the house file (.h2k).
=end
codeNameToUse = "Attic28"
puts("Change all ceiling standard codes to #{codeNameToUse}... ")
locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
XPath.each( $XMLdoc, locationText) do |element| 
  puts " - Existing ceiling code is: #{element.text}"
  if !element.attributes["idref"] then
    # Need to add attribute code to use in <Codes> section Since doing all ceilings
	# with same code, no need to be concerned with existing ceiling codes in <Codes>
	element.add_attribute("idref", "Code 99") 
  else
    element.attributes["idref"] = "Code 99"
  end
  element.text = codeNameToUse    # "Attic28"
end
# Copy-and-paste from code library entry to <Codes> section of house file for 
# the desired code name
codeLibLocation = "Codes/Ceiling/Favorite/Code" 
XPath.each( $XMLCodedoc, codeLibLocation) do |codeLibElement|
  if codeLibElement[1].text == codeNameToUse then
    # This is the code we want to use
	codeLibElement.attributes["id"] = "Code 99"
    
    #elementToReplace = $XMLdoc.elements["HouseFile/Codes/Ceiling/Standard/Code"]
	#Replace this element with codeLibElement - Can't seem to do this! ***************************
    #Or insert a new element before or after it - Can't seem to do this! *************************
    
	# Hardcoded loaction works but indices (always odd) depend on codes present in file!
	# [9] = Codes (Always 9)
	# [3] = Ceilings if there are Wall codes present, otherwise [1]!
	# Need t check other combinations of existing data for other surfaces: floors, windows, etc.
	$XMLdoc.root[9][3][1][1] = codeLibElement  
  end
end
# Alternate method for locating code library element to copy
#$h2kCodeLibElements.each(codeLibLocation) { |codeLibElement|
#   ...same code as above (doesn't seem to be any advantage)
#}

=begin rdoc
Test air infiltration changes
=end
puts "\n---------------------------------------------------------------"
puts("Current ACH: ")
locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
$h2kElements.each(locationText) { |element| 
  puts element.attributes["airChangeRate"] 
  puts("Changing ACH to 4.50")
  element.attributes["airChangeRate"] = 4.50
}

=begin rdoc
Test HVAC changes : Code below only works for Furnaces! Need to check on existance of each Type 1 system (Baseboards, Furnace, Boiler, Combo or P9) to know which XML tag to inspect and change.
=end
puts "\n---------------------------------------------------------------\n"
puts("Current heating system is: ")
locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EquipmentType"
$h2kElements.each(locationText) { |element| 
  print "Type #{element.attributes["code"]} : "
}
locationText = "HouseFile/House/HeatingCooling/Type1/Furnace/Equipment/EquipmentType/English"
$h2kElements.each(locationText) { |element| 
  print "#{element.text}\n\n"
}


=begin rdoc
Save changes to the XML doc in a new file so don't overwrite original
=end
(path, h2kFileName) = File.split(ARGV[0])
puts "\nH2K file path is: #{path}" 
puts "H2K file input name is: #{h2kFileName}" 
newFileName = "#{path}\\WizardHouseChanged.h2k"
puts("Writing out to a new file named #{newFileName}.")
newXMLFile = File.open(newFileName, "w")
$XMLdoc.write(newXMLFile)
newXMLFile.close
# Need to close XML source file before trying to load it into H2K below!
$h2kFile.close
$h2kCodeFile.close

puts("\n---------------------------------------------------------------\n")

# Start H2K using specified file. This returns control to the calling program (this)
# without waiting for H2K to close. Works but not what we want!
#`C:\\HOT2000_v11_75\\hot2000.exe C:\\HOT2000_v11_75\\User\\WizardHouse.h2k`

# Another way to do the same thing as above. Works but not what we want!
#%x[C:\\HOT2000_v11_75\\hot2000.exe C:\\HOT2000_v11_75\\User\\WizardHouse.h2k]

# To run H2K and wait until exited. Pass H2K a command line argument for the file to open.
path = File.dirname(path)	        # Removes outermost path portion (\\user)
if ( path !~ /V11_1_CLI/ )
   runThis = path + "\\HOT2000.exe"	# NOTE: Doesn't work if space in path!
   puts "\nStart #{runThis} with file #{newFileName} (y/n)?"
   answer = STDIN.gets.chomp           # Specify STDIN or gets text from ARGV!
   if answer.capitalize == 'Y' then
     if system(runThis, newFileName) then
       puts "The program ran as expected!"
     else
       puts "It didn't work! Return code follows:"
       puts $?
     end
   end
end

# Run H2K with XML file provided (.h2k), run the analysis and close the file.
# H2K command line option to run loaded file is "-inp" (first argument)
# Must specify folder BELOW main HOT2000 installed folder!  Example:
#    > C:\HOT2000_v11_76\hot2000.exe -inp User\WizardHouse.h2k
fileToLoad = "user\\WizardHouseChanged.h2k"
optionSwitch = "-inp"
Dir.chdir(path) do 
  puts "The current path is: #{Dir.pwd}"
  puts "\nRun #{runThis} with switch #{optionSwitch} and file #{fileToLoad} (y/n)?"
  answer = STDIN.gets.chomp           # Need STDIN or gets text from ARGV!
  if answer.capitalize == 'Y' then
    if system(runThis, optionSwitch, fileToLoad) then
      puts "The run worked!"
    else
      puts "The run did NOT work"
      puts $?
    end
  end
end #returns to original working folder

# The ERS number is in Browse.rpt in a separate line that reads:
#    EnerGuide Rating (not rounded) =   ##.####

puts "Back in main program (Folder: #{Dir.pwd})."

exit(0)	# Don't really need this but can control the app return code this way!
