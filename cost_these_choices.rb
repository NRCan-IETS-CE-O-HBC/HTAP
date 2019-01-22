#!/usr/bin/env ruby
#
# Script estimates the upgrade costs for a given HTAP file and associated .chocies

#


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
require_relative 'include/costing'

require_relative 'include/constants'

include REXML

$program = "cost_these_choices.rb"

debug_on()
debug_out("[!] Debugging output requested for #{$program}\n")

$allok = true
$startProcessTime = Time.now

$gTest_params = Hash.new
$gTest_params["verbosity"] = "quiet"
$gTest_params["logfile"] = "cost_these_choices.log"

myOptions = Hash.new
myChoices = Hash.new
myChoicesOrder = Array.new

# Path where this script was started and considered master
$gMasterPath = Dir.getwd()
$gMasterPath.gsub!(/\//, '\\')


sumFileSpec = $gMasterPath + "/cost_these_choices_summary.txt"
$fSUMMARY = File.new(sumFileSpec, "w")


$fLOG = File.new($gTest_params["logfile"], "w")
if $fLOG == nil then
   fatalerror("Could not open #{$gTest_params["logfile"]}.\n")
end


specdCostSources = Hash.new
specdCostSources = {"custom" => [],
                      "components" => ["LEEP-BC-Vancouver", "*"]
                   }

#-------------------------------------------------------------------
# Help text. Dumped if help requested, or if no arguments supplied.
#-------------------------------------------------------------------
myHelp_msg = "

 cost_these_choices.rb:

 This script estimates the upgrade costs for a given HTAP file and
 associated .chocies

 use: cost_these_choices.rb --options     options.json
                            --choices     these.choices
                            --unitcosts   unitcosts.json
                            --h2k         h2k.filename


 Command line options:

"



# Dump help text, if no argument given
if ARGV.empty? then
  puts myHelp_msg
  exit()
end

myChoiceFile    = ""
myOptionFile    = ""
myCostsFile     = ""
myBaseModelFile = ""
myChoiceOrder = Array.new

optparse = OptionParser.new do |opts|

   opts.banner = myHelp_msg

   opts.on("-h", "--help", "Show help message") do
      puts opts
      exit()
   end

   opts.on("-v", "--verbose", "Run verbosely") do
      $gVerbose = true
      $gTest_params["verbosity"] = "verbose"
   end

   opts.on("-d", "--debug", "Run in debug mode") do
      $gVerbose = true
      $gTest_params["verbosity"] = "verbose"
      $gDebug = true
   end


   opts.on("-c", "--choices FILE", "Specified choice file (mandatory)") do |c|
      myChoiceFile = c
      if ( !File.exist?(myChoiceFile) )
         fatalerror("Valid path to choice file must be specified with --choices (or -c) option!")
      end
   end

   opts.on("-o", "--options FILE", "Specified options file (mandatory)") do |o|
      myOptionFile = o
      if ( !File.exist?(myOptionFile) )
         fatalerror("Valid path to option file must be specified with --options (or -o) option!")
      end
   end

   opts.on("-u", "--unitcosts FILE", "unit costs file ") do |o|
      myCostsFile = o
      if ( !File.exist?(myCostsFile) )
         fatalerror("Valid path to option file must be specified with --options (or -o) option!")
      end
   end


   opts.on("--h2k FILE", "Specified base file (mandatory)") do |b|
      myBaseModelFile = b
      if !myBaseModelFile
         fatalerror("Base folder file name missing after --base_folder (or -b) option!")
      end
      if (! File.exist?(myBaseModelFile) )
         fatalerror("Base file does not exist in location specified!")
      end
    end


end

optparse.parse!



stream_out ("cost_these_choices.rb: \n")
stream_out ("         ChoiceFile: #{myChoiceFile} \n")
stream_out ("         OptionFile: #{myOptionFile} \n")
stream_out ("         Base model: #{myBaseModelFile} \n")
stream_out ("         Costs     : #{myCostsFile} \n")

#-------------------------------------------------------------------
# COLLECT INPUT
#-------------------------------------------------------------------

# Parse options file
myOptions   = HTAPData.parse_json_options_file(myOptionFile)

# Parse unit costs
myUnitCosts = Costing.parseUnitCosts(myCostsFile)

# Parse choices
#myChoices, myChoiceOrder = HTAPData.parse_choice_file(myChoiceFile)


myChoices, myChoicesOrder = HTAPData.parse_choice_file(myChoiceFile)
# ( not yet supported - read archetype out of choice file)

# Parse h2k file
h2kElements = H2KFile.get_elements_from_filename(myBaseModelFile)

#-------------------------------------------------------------------
# APPLY RULESETS - Not supported right now
#-------------------------------------------------------------------


#-------------------------------------------------------------------
#  Verify options and choices make sense !
#-------------------------------------------------------------------

    myOptionsErr,myChoices,myChoiceOrder = HTAPData.validate_options(myOptions, myChoices, myChoiceOrder )
    if ( myOptionsErr ) then
      fatalerror ("Could not parse options")
      $allok = false
    end

    #-------------------------------------------------------------------
    # Collect dimension data about house
    #-------------------------------------------------------------------
    myH2KHouseInfo = Hash.new
    myH2KHouseInfo = H2KFile.getAllInfo(h2kElements)
    debug_on
    debug_out (" Contents of myH2KHouseInfo:\n#{myH2KHouseInfo.pretty_inspect}")

    myCosts = Hash.new

    # Compute costs
    myCosts = Costing.computeCosts(specdCostSources,myUnitCosts,myOptions,myChoices,myH2KHouseInfo)

    stream_out ( drawRuler("Cost Impacts"))
    myCosts = Costing.computeCosts(specdCostSources,myUnitCosts,myOptions,myChoices,myH2KHouseInfo)
    Costing.summarizeCosts(myChoices, myCosts)













#-------------------------------------------------------------------
# Perform a calculation for sizing impact  ?
# (X) Not required; assume that the HOT2000 file as been processed
#     and systems are sized; locations are updated; future
#     htap functions for geometry habe been processed.
#-------------------------------------------------------------------



#-------------------------------------------------------------------
# Loop through choices; compute costs
#-------------------------------------------------------------------





ReportMsgs()


#pp myH2KHouseInfo
