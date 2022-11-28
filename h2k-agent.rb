require 'rexml/document'
require 'optparse'
require 'timeout'
require 'fileutils'
require 'digest'
require 'json'
require 'set'
require 'pp'

include REXML

require_relative 'inc/msgs'
require_relative 'inc/H2KUtilities'
require_relative 'inc/HTAPUtilities'
require_relative 'inc/constants'
require_relative 'inc/rulesets'

$program = "h2k-agent.rb"
prm_call = true 
HTAPInit()

choice_file = ""
option_file = ""
base_h2k_file = ""

$locale = {
  "location" => "",
  "hdds"     => 0, 
  "climate_zone" => ""
}


# Initialize weather directory data

$cmdlineopts = Hash.new 


bLookForArchetype = FALSE 


h2k_src_path = "C:\\H2K-CLI-Min"


# Get the hot2000 weather library. (fi)
h2k_locations = H2KWth.read_weather_dir(h2k_src_path+"\\Dat\\Wth2020.dir")

$gTest_params["verbosity"] = "quiet"


#=======================================================================================
# h2k-user agent: main flow.

help_msg = "
This script searches through a suite of model input files
and substitutes values from a specified input file.

use: ruby h2k-agent.rb --options Filename.options
--choices Filename.choices
--base_file 'Base model path & file name'

example use for optimization work:

ruby h2k-agent.rb -c HOT2000.choices -o HOT2000.options -b C:\\H2K-CLI-Min\\MyModel.h2k -v

Command line options:
"



if ARGV.empty? then
  stream_out drawRuler("A wrapper for HOT2000")
  puts help_msg
  exit()
end

$cmdlineopts = {  
  "verbose" => false,
  "debug"   => false 
}

optparse = OptionParser.new do |opts|

  opts.banner = help_msg

  opts.on("-h", "--help", "Show help message") do
    puts opts
    exit()
  end

  opts.on("-c", "--choices FILE", "Specified choice file (mandatory)") do |c|
    $cmdlineopts["choices"] = c
    choice_file = c
    if ( !File.exist?(choice_file) )
      fatalerror("Valid path to choice file must be specified with --choices (or -c) option!")
    end
  end

  opts.on("-o", "--options FILE", "Specified options file (mandatory)") do |o|
    $cmdlineopts["options"] = o
    option_file = o
    if ( !File.exist?(option_file) )
      fatalerror("Valid path to option file must be specified with --options (or -o) option!")
    end
  end            

  opts.on("-b", "--base_model FILE", "Specified base file (mandatory)") do |b|
    $cmdlineopts["base_model"] = b
    base_h2k_file = b
    if !base_h2k_file
      fatalerror("Base folder file name missing after --base_folder (or -b) option!")
    end
    if (! File.exist?(base_h2k_file) )
      fatalerror("Base file '#{base_h2k_file}' does not exist in location specified!")
    end
    bLookForArchetype = FALSE
  end

  #opts.on("--unit-cost-db FILE", "Specified path to unit cost database (e.g. HTAPUnitCosts.json)") do |c|
  #  $cmdlineopts["unitCosts"] = c
  #  $unitCostFileName = c
  #  if ( !File.exist?($unitCostFileName) )
  #    err_out ("Could not find #{$unitCostFileName}")
  #    fatalerror("Valid path to unit costs file must be specified with --unit-cost-db option!")
  #  end
  #  $UnitCostFileSet = true
  #end 

  #opts.on("--rulesets FILE", "Specified path to rulesets file (e.g. HTAP-rulesets.json)") do |c|
  #  $cmdlineopts["rulesets"] = c
  #  $rulesetsFileName  = c
  #  if ( !File.exist?($rulesetsFileName) )
  #    err_out ("Could not find #{$rulesetsFileName}")
  #    fatalerror("Valid path to the rulesets file must be specified with the --rulesets option!")
  #  end
  #  $RulesetFileSet = true 
  #end 


  opts.on("-v", "--verbose", "Run verbosely") do
    $cmdlineopts["verbose"] = true
    $gTest_params["verbosity"] = "verbose"
  end

  opts.on("--hints", "Provide helpful hints for intrepreting output") do
    $gHelp = true
  end


  opts.on("-d", "--no-debug", "Disable all debugging") do
  #  #$cmdlineopts["verbose"] = true
  #  #{$gTest_params["verbosity"] = "debug"}
    $gNoDebug = true
  end

  opts.on("-p", "--prm", "Run as a slave to htap-prm") do
    $cmdlineopts["prm"] = true
    $PRMcall = true
  end

  #opts.on("-w", "--warnings", "Report warning messages") do
  #  $cmdlineopts["warnings"] = true
  #  $gWarn = true
  #end


  opts.on("--list_locations", "Produce a list of valid weather locations") do 
    $cmdlineopts["list_locations"] = true 
    $cmdlineopts["verbose"] = true
    $gTest_params["verbosity"] = "verbose"
  end 


  opts.on("-e", "--extra_output", "Produce and save extended output (v1)") do
    $cmdlineopts["extra_output"] = true
  end

  #opts.on("-k", "--keep_H2K_folder", "Keep the H2K sub-folder generated during last run.") do
  #  $cmdlineopts["keep_H2K_folder"] = true
  #  keepH2KFolder = true
  #end

  #opts.on("-a", "--auto-cost-options", "Automatically cost the option(s) set for this run.") do
  #  $cmdlineopts["auto_cost_options"] = true
  #  $autoEstimateCosts = true
  #end

  #opts.on("-g", "--hourly-output", "Extrapolate hourly output from HOT2000's binned data.") do
  #  $cmdlineopts["hourly_output"] = true
  #  $hourlyCalcs = true
  #end


  #opts.on("-j", "--export-options-to-json", "Export the .options file into JSON format and quit.") do

  #  $gJasonExport = true

  #end

  #opts.on("-t", "--test-json-export", "(debugging) Export the .options file as .json, and then re-import it (debugging)") do
  #  $gJasonTest = true
  #end




end

# Note: .parse! strips all arguments from ARGV and .parse does not
#       The parsing code above effects only those options that occur on the command line!
optparse.parse!


debug_on()

stream_out drawRuler("A wrapper for HOT2000")

# Get hot2000 model names
(h2k_file_path, h2k_file_name) = File.split( base_h2k_file )
h2k_file_path.sub!(/\\User/i, '')

# Debug out: print out options

if debug_status() then 
  debug_out " Environment: "
  debug_out "    script location: #{$scriptLocation}\n"
  debug_out "    master path: #{$gMasterPath}\n"
  debug_out " Command line options:"
  $cmdlineopts.keys.each do | option |
    value = $cmdlineopts[option]
    debug_out "    #{option} -> #{value}"
  end 
    
  debug_out("Passed H2K model:\n")
  debug_out("    h2k file path: #{h2k_file_path}\n")
  debug_out("    h2k file name: #{h2k_file_name}\n")
end 
debug_on 
debug_out "Dieing here?"
stream_out ("\n Input files:  \n")
stream_out ("         path: #{$gMasterPath} \n")
stream_out ("         choice_file: #{choice_file} \n")
stream_out ("         option_file: #{option_file} \n")
stream_out ("         Base model: #{base_h2k_file} \n")
stream_out ("         HOT2000 source folder: #{h2k_src_path} \n")



if ($cmdlineopts["list_locations"]) then 
  stream_out drawRuler("Printing a list of valid location keywords")
  stream_out ("\n Locations:\n")
  h2k_locations["options"].keys.each do | location |
    stream_out "  - Key: #{location}  (Region: #{h2k_locations["options"][location]["h2kMap"]["base"]["region_name"]})\n"
  end 

  stream_out ("\n  -> To use these locations, specify `Opt-Location = KEYWORD `\n\n" )
  #pp h2k_locations
  exit
end 



# =====================================================================
# Read inputs
stream_out drawRuler("Parsing input data")
stream_out "\n"
# 1) Options file
stream_out(" -> Parsing options data from #{option_file} ...")
options = HTAPData.getOptionsData(option_file)
options["Opt-Location"] = h2k_locations

stream_out(" (done) \n") if ($allok)

#2) Choices file
stream_out(" -> Reading user-defined choices from #{choice_file} ...")
user_choices, user_choice_order = HTAPData.parse_choice_file(choice_file)
stream_out(" (done) \n") if ($allok)
stream_out("\n")

stream_out ( " Specified choices: \n")
user_choices.each do | attribute, value |
  stream_out ("       - #{attribute.ljust(35)} = #{value} \n")
end

#=======================================================================
# Confirm options, choices make sense 
stream_out(drawRuler("Validating choices and options"))

parseOK,  valid_choices = HTAPData.valdate(options,user_choices)

if (not parseOK) then 
  fatalerror("Options, Choices could not be validated")
end 

stream_out(drawRuler("Verifying Upgrade packages"))


stream_out(drawRuler("Verifying rulesets"))

processed_choices = valid_choices
#===============================================================================
# Configure h2k run folders
stream_out(drawRuler("Setting up HOT2000 environment"))
stream_out("\n")

# Create a working h2k file, or if one exists, check to make sure it is
# identical to the one whe use.
# Variables for doing a md5 test on the integrety of the run.
dir_verified = false
copy_tries   = 0
run_path = $gMasterPath + "\\H2K"
while ( ! dir_verified && copy_tries < 3  )
  log_out("Attempt ##{copy_tries} to verify h2k directory")
  copy_tries = copy_tries + 1 
  stream_out (" -> Creating local H2K install to run files (attempt ##{copy_tries}) \n")
  dir_verified = H2KUtils.create_run_environment(h2k_src_path,run_path)
end 

if ( ! dir_verified ) then 
  fatalerror ("\nFatal Error! Integrity of H2K folder at #{run_path} is compromised!\n Return error code #{$?}\n")
else
  stream_out (" -> H2K environment successfully created.")
end 

# Create a copy of the HOT2000 file into the master folder for manipulation.
# (when called by PRM, the run manager will already do this - if we don't test for it, it will delete the file)
working_h2k_file = $gMasterPath + "\\"+ h2k_file_name
if ( ! $PRMcall )
 # warn_out ("Need to restore PRM call feature")
  stream_out("\n -> Creating a copy of HOT2000 model (#{base_h2k_file} for optimization work... \n")

  

  # Remove any existing file first!

  if ( File.exist?(working_h2k_file) )
    if ( ! FileUtils.rm(working_h2k_file) )
      fatalerror ("Fatal Error! Could not delete #{working_h2k_file}!\n Del return error code #{$?}\n")
    end
  end
  debug_out "copy arguements: #{base_h2k_file} -> #{working_h2k_file}\n "
  FileUtils.cp(base_h2k_file,working_h2k_file)
  stream_out("\n    (File #{working_h2k_file} created.)\n\n")
end 
#===============================================================================
# Parse HOT2000 file and manipulate as necessary 
stream_out(drawRuler("Reading HOT2000 file"))
stream_out("\n -> Parsing a copy of HOT2000 model (#{working_h2k_file}) for optimization work...")
h2k_file_contents = H2KFile.open_xml_as_elements(working_h2k_file)
stream_out("done.")

err_options = false 

#==========================================================
stream_out(drawRuler("Manipulating HOT2000 file "))
H2KFile.write_elements_as_xml("presub.h2k")

mods_ok = H2KEdit.modify_contents(h2k_file_contents,options, valid_choices)
H2KEdit.delete_results(h2k_file_contents)


#===============================================================================
# Write out new xml file 
stream_out(drawRuler("Writing HOT2000 file"))
stream_out("\n -> Writing modified file (#{working_h2k_file}) for optimization work...")
H2KFile.write_elements_as_xml(working_h2k_file)




stream_out(" -> Choices that will be used in the simulation:\n")
valid_choices.each do | attribute, value |
  stream_out ("     - #{attribute.ljust(35)} = #{value} \n")
end

if ( err_options ) then
  $allok = false
end

if (! $allok )
  fatalerror ("Could not parse options & choices")
end

stream_out (" Performing substitutions on H2K file...")

# Process file flow to go here. 


#==========================================================
stream_out(drawRuler("Invoking HOT2000  "))
run_ok = TRUE 
run_ok, lapsed_time = H2Kexec.run_a_hot2000_simulation(working_h2k_file)

debug_out ("Lapsed time: #{lapsed_time} s")

agent_data = {
  "h2k_run_time" => lapsed_time ,
  "agent_processing_time" => Time.now - $startProcessTime -lapsed_time,
  "approx_lapsed_time"=> Time.now - $startProcessTime,
  "copy_tries"  => copy_tries
}


if (! run_ok ) then 
  fatal_error("Could not execute HOT2000 calculations")
end 

#==========================================================
stream_out(drawRuler("Reading simulation results"))


results = H2Kpost.handle_sim_results(working_h2k_file,processed_choices,agent_data)

# Should probably comment this line out in production. 
if (debug_status()) 
  debug_out(results.pretty_inspect)
end 




#==========================================================
stream_out(drawRuler("Writing simulation results"))
HTAPout.write_h2k_eval_results(results)




#===============================================================================
# Closeout 

if ( ! $PRMcall )
  if !$keepH2KFolder
    FileUtils.rm_r ( "#{$gMasterPath}\\H2K" )
  end
end


ReportMsgs()

log_out ("h2k-agent.rb run complete.")
log_out ("Closing log files")
$fSUMMARY.close()
$fLOG.close()