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
  $XMLdoc = Document.new(File.open(filename))
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

puts("Trying changing all ceiling codes and write out to a new file: ")
locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
XPath.each( $XMLdoc, locationText) do |element| 
  puts " - Existing ceiling code is: #{element.text}"
  element.text = "22113A3000"
  puts " - New ceiling code is: #{element.text}"
end
$XMLdoc.write(File.open("WizardHouseChanged.xml", "w"))

puts("\n---------------------------------------------------------------\n")

# Start H2K using specified file. This returns control to the calling program (this)
# without waiting for H2K to close.
#`C:\\HOT2000_v11_75\\hot2000.exe C:\\HOT2000_v11_75\\User\\WizardHouse.h2k`

# Another way to do the same thing as above
#%x[C:\\HOT2000_v11_75\\hot2000.exe C:\\HOT2000_v11_75\\User\\WizardHouse.h2k]

# To run H2K but pass a command line argument for the file to open in H2K
# NOTE: The following cases work in debug mode only!  WHY? *******************
(path, h2kFileName) = File.split(ARGV[0])
path = File.dirname(path)	        # Removes outermost path portion (\\user)
runThis = path + "\\HOT2000.exe"	# NOTE: Doesn't work if space in  path!
puts "\nStart #{runThis} with file #{ARGV[0]} (y/n)?"
answer = STDIN.gets.chomp           # Specify STDIN or gets text from ARGV!
if answer.capitalize == 'Y' then
  if system(runThis, ARGV[0]) then
    puts "The program ran as expected!"
  else
    puts "It didn't work! Return code follows:"
    puts $?
  end
end

# Try running the H2K file provided
# H2K command line option to run loaded file is "-inp" (first argument) --> NOT WORKING!
# Must specify folder BELOW main HOT2000 installed folder!  Example:
#    > C:\HOT2000_v11_75\hot2000.exe -inp User\WizardHouse.h2k
fileToLoad = "user\\" + h2kFileName
optionSwitch = "-inp"
Dir.chdir(path) do 
  puts "The current path is: #{Dir.pwd}"
  puts "\nRun #{runThis} with switch #{optionSwitch} and file #{fileToLoad} (y/n)?"
  answer = STDIN.gets.chomp           # Need STDIN or gets text from ARGV!
  if answer.capitalize == 'Y' then
    #STDIN.ungetc('\n')      # Buffer a CR character - NOT WORKING!
    if system(runThis, optionSwitch, fileToLoad) then
      puts "The run worked!"
    else
      puts "The run did NOT work"
      puts $?
    end
  end
end #returns to original working folder

puts "Back in main program (Folder: #{Dir.pwd})."

puts "\nRun the DOS batch runH2KTest.bat file with parameter #{fileToLoad} (y/n)?"
answer = STDIN.gets.chomp           # Need STDIN or gets text from ARGV!
if answer.capitalize == 'Y' then
  if system("runH2KTest.bat", fileToLoad) then
    puts "The program ran as expected!"
  else
    puts "It didn't work! Return code follows:"
    puts $?
  end
end

exit(0)	#Don't really need this!