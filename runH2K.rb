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
  $XMLdoc = Document.new($h2kFile)
  return $XMLdoc.elements()
end

if ARGV.empty? then
  puts("Need a command line argument with full path to the h2k file!")
  exit()
end

# Load a HOT2000 file using command line parameter and assign contents to a Hash
$h2kElements = get_elements_from_filename(ARGV[0])

puts("Application Name:")
$h2kElements.each("HouseFile/Application/Name") { |element| puts element.to_a }	

puts("IDs and Labels of main house components:")
$h2kElements.each("HouseFile/House/Components/*") { |element1| 
  puts element1.attributes["id"]
}	  

puts("rValue of Ceilings:")
locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
$h2kElements.each(locationText) { |element| 
  puts element.attributes["rValue"] 
}

puts("Change all wall codes to User Specified: ")
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
puts("Change all ceiling standard codes: ")
locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
XPath.each( $XMLdoc, locationText) do |element| 
  puts " - Existing ceiling code is: #{element.text}"
  if !element.attributes["idref"] then
    # Need to add attribute with *unique* code reference **TODO**
	element.add_attribute("idref", "Code 1") 
  end
  element.text = "22113A3000"
  puts " - New ceiling code is: #{element.text}"
  # **TODO**
  # Must add code with all layer data in <Codes> section!
  # Copy-and-paste from code library entries -- this works!
  # use next_element() in loop
  
end
(path, h2kFileName) = File.split(ARGV[0])
newFileName = "#{path}\\WizardHouseChanged.h2k"
puts("Writing out to a new file named #{newFileName}.")
newXMLFile = File.open(newFileName, "w")
$XMLdoc.write(newXMLFile)
newXMLFile.close
# Need to close XML source file before trying to load it into H2K below!
$h2kFile.close

puts("\n---------------------------------------------------------------\n")

# Start H2K using specified file. This returns control to the calling program (this)
# without waiting for H2K to close.
#`C:\\HOT2000_v11_75\\hot2000.exe C:\\HOT2000_v11_75\\User\\WizardHouse.h2k`

# Another way to do the same thing as above
#%x[C:\\HOT2000_v11_75\\hot2000.exe C:\\HOT2000_v11_75\\User\\WizardHouse.h2k]

# To run H2K but pass a command line argument for the file to open in H2K
path = File.dirname(path)	        # Removes outermost path portion (\\user)
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

# Try running the H2K file provided
# H2K command line option to run loaded file is "-inp" (first argument)
# Must specify folder BELOW main HOT2000 installed folder!  Example:
#    > C:\HOT2000_v11_75\hot2000.exe -inp User\WizardHouse.h2k
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

exit(0)	#Don't really need this!