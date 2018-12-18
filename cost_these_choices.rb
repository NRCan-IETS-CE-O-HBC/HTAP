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

$allok = true 
$startProcessTime = Time.now 

$gTest_params = Hash.new  
$gTest_params["verbosity"] = "quiet"
$gTest_params["logfile"] = "cost_these_choices.log" 

$gOptions = Hash.new 
$gChoices = Hash.new 
$gChoicesOrder = Array.new

# Path where this script was started and considered master
$gMasterPath = Dir.getwd()
$gMasterPath.gsub!(/\//, '\\')


sumFileSpec = $gMasterPath + "/cost_these_choices_summary.txt"
$fSUMMARY = File.new(sumFileSpec, "w")


$fLOG = File.new($gTest_params["logfile"], "w") 
if $fLOG == nil then
   fatalerror("Could not open #{$gTest_params["logfile"]}.\n")
end




#-------------------------------------------------------------------
# Help text. Dumped if help requested, or if no arguments supplied.
#-------------------------------------------------------------------
$help_msg = "

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
  puts $help_msg
  exit()
end

optparse = OptionParser.new do |opts|
  
   opts.banner = $help_msg

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
      $gChoiceFile = c
      if ( !File.exist?($gChoiceFile) )
         fatalerror("Valid path to choice file must be specified with --choices (or -c) option!")
      end
   end   
   
   opts.on("-o", "--options FILE", "Specified options file (mandatory)") do |o|
      $gOptionFile = o
      if ( !File.exist?($gOptionFile) )
         fatalerror("Valid path to option file must be specified with --options (or -o) option!")
      end
   end
   
   opts.on("-u", "--unitcosts FILE", "unit costs file ") do |o|
      $gCostsFile = o
      if ( !File.exist?($gCostsFile) )
         fatalerror("Valid path to option file must be specified with --options (or -o) option!")
      end
   end   
   

   opts.on("--h2k FILE", "Specified base file (mandatory)") do |b|
      $gBaseModelFile = b
      if !$gBaseModelFile
         fatalerror("Base folder file name missing after --base_folder (or -b) option!")
      end
      if (! File.exist?($gBaseModelFile) ) 
         fatalerror("Base file does not exist in location specified!")
      end
    end
   
   
end

optparse.parse!

stream_out ("cost_these_choices.rb: \n") 
stream_out ("         ChoiceFile: #{$gChoiceFile} \n")
stream_out ("         OptionFile: #{$gOptionFile} \n")
stream_out ("         Base model: #{$gBaseModelFile} \n")
stream_out ("         Costs     : #{$gCostsFile} \n")

#-------------------------------------------------------------------
# COLLECT INPUT 
#-------------------------------------------------------------------

# Parse options file 
$gOptions   = HTAPData.parse_json_options_file($gOptionFile)

# Parse unit costs
$gUnitCosts = Costing.ParseUnitCosts($gCostsFile)

# Parse choices
$gChoices, $gChoiceOrder = HTAPData.parse_choice_file($gChoiceFile)


# ( not yet supported - read archetype out of choice file) 

# Parse h2k file 
h2kElements = H2KFile.get_elements_from_filename($gBaseModelFile)

#-------------------------------------------------------------------
# APPLY RULESETS - Not supported right now 
#-------------------------------------------------------------------


#-------------------------------------------------------------------
#  Verify options and choices make sense ! 
#-------------------------------------------------------------------
$OptionsErr,$gChoices, $gChoiceOrder = HTAPData.validate_options($gOptions, $gChoices, $gChoiceOrder ) 

if ( $OptionsErr ) then 
  fatalerror ("Could not parse options") 
  $allok = false 
end 


#-------------------------------------------------------------------
# Perform a calculation for sizing impact 
#-------------------------------------------------------------------


#-------------------------------------------------------------------
# Collect dimension data about house 
#-------------------------------------------------------------------

# Base location from original H2K file. 
$gBaseLocale = H2KFile.getWeatherCity( h2kElements )
$gBaseRegion = H2KFile.getRegion( h2kElements )




ReportMsgs()

