

require 'rexml/document'
require 'optparse'
require 'timeout'
require 'fileutils'
require 'digest'
require 'json'
require 'set'
require 'pp'

require_relative '../include/msgs'
require_relative '../include/H2KUtils'
require_relative '../include/HTAPUtils'

require_relative '../include/costing'
require_relative '../include/legacy-code'



include REXML   # This allows for no "REXML::" prefix to REXML methods

require_relative '../include/constants'

$program = "manage_options.rb"

filename = "..\\HTAP-options.json"
h2kCodeFile = "C:\\HTAP\\Archetypes\\codeLib.cod"

fDefs = File.new(filename, "r")
parsedDefs = Hash.new

if fDefs == nil then
   fatalerror(" Could not read #{filename}.\n")
end
defsContent = fDefs.read
fDefs.close
parsedDefs = JSON.parse(defsContent)

windowDefs = Hash.new
windowDefs = parsedDefs["Opt-CasementWindows"]["options"]


debug_on

debug_out " ///////////////////////////////////////////////////////////////\n"
debug_out " Parsing code xml from #{h2kCodeFile}..."
h2kCodeElements = Document.new
h2kCodeElements = H2KFile.get_elements_from_filename(h2kCodeFile)
debug_out "done.\n"

debug_out " ///////////////////////////////////////////////////////////////\n"
debug_out " Processing windows!\n"
windowDefs.keys.each do | window |

   thisWindowData = Hash.new
   thisWindowData = parsedDefs["Opt-CasementWindows"]["options"][window]
   # Does window have characteristics defined?
   if ( ! thisWindowData["characteristics"].nil? ) then

     debug_out ".........\n"
     debug_out "#{window} Has characteristic data. Syncing with #{h2kCodeFile}!!!\n"

     str = ""
     h2kCodeElements = H2KLibs.AddWinToCodeLib(window,thisWindowData["characteristics"],h2kCodeElements)

   end


end

# maybe create a copy for comparison?
# h2kCodeFile.gsub!(/\.cod/, "-ed.cod")

newXMLFile = File.open(h2kCodeFile, "w")

$formatter.write($XMLCodedoc,newXMLFile)

newXMLFile.close
