
require 'rexml/document'
require 'optparse'
require 'timeout'
require 'fileutils'
require 'digest'
require 'csv'
require 'json'
require 'set'
require 'pp'

require_relative '../inc/msgs'

require_relative '../inc/markdown-reports.rb'
require_relative '../inc/H2KUtils'
require_relative '../inc/HTAPUtils'
require_relative '../inc/constants'
require_relative '../inc/rulesets'
require_relative '../inc/costing'
require_relative '../inc/legacy-code'
require_relative '../inc/application_modules'
include REXML

$program = "re-cost.rb"
HTAPInit()

$pass_system_size = TRUE 
$system_size = 0.0 

log_out ("Initalizing RECOST-Calculations ")

$results_file = ''
$costs_file = ''
$assembly_file = ''
$options_file  = ''
$costed = {}
$recosted_file = 'HTAP-prm-output-recosted.csv'

stream_out( drawRuler("A script for re-estimating capital costs from HTAP output."))


#debug_on

$help_msg =  " 
 re-cost.rb parses existing HTAP results (e.g. HTAP-prm-output.csv)
 and attempts to recompute the capital costs associated with ECMs. 

 Results are saved in a file named #{$recosted_file}

 To use this script, you must supply it with:
   1. an HTAP output file in .csv format [+]
   2. an HTAP options file (json)
   3. an HTAP assembly list file (json)
   4. an HTAP unit-costs database (json)
   5. the path to the origial HOT2000 files used in this analysis. [+]

 [+ Note: Future versions of this script may elimiate these requirements ]

 re-cost.rb's costing calculations are generally faster and more robust than 
 the full HTAP run, but your mileage may vary as there is currently no 
 support for multi-threading. 

"

optparse = OptionParser.new do |opts|

  opts.banner = $help_msg

  opts.on("-h", "--help", "Show this message") do
    puts opts
    puts " "
    log_out "Help message reported"
    exit()
  end

  opts.on("-o", "--options FILE", "Specified options file (mandatory)") do |c|
    $options_file = c
    if ( !File.exist?($options_file) )
      fatalerror("Valid path to options file must be specified with --options (or -o) option!")
    end
  end

  opts.on("-r", "--results FILE", "Specified results file (mandatory)") do |c|
    $results_file = c
    if ( !File.exist?($results_file) )
      fatalerror("Valid path to results file must be specified with --results (or -r) option!")
    end
  end

  opts.on("-c", "--costs FILE", "Specified unit costs Database (mandatory)") do |c|
    $costs_file = c
    if ( !File.exist?($costs_file) )
      fatalerror("Valid path to costs file must be specified with --results (or -r) option!")
    end
  end

  opts.on("-a", "--assemblies FILE", "Specified assemblies list (mandatory)") do |c|
    $assembly_file = c
    if ( !File.exist?($assembly_file) )
      fatalerror("Valid path to assembly list file must be specified with --results (or -r) option!")
    end
  end

  opts.on("-p", "--path_to_h2k PATH", "Specified path to h2k archetype files") do |c|
    $h2k_path  = c
      #if ( !File.exist?($assembly_file) )
      #fatalerror("Valid path to results file must be specified with --results (or -r) option!")
    #end
  end


end 

if ARGV.empty? then
  puts $help_msg 
  exit()
end

optparse.parse!
stream_out(" Configuration \n")
stream_out("   - Results file:    #{$results_file}\n")
stream_out("   - Unit costs file: #{$costs_file}\n")
stream_out("   - Options file:    #{$options_file}\n")
stream_out("   - Assembly file:   #{$ssembly_file}\n")
stream_out("   - path to h2k files: #{$h2k_path}\n")


stream_out (" Parsing input files [")
stream_out (" options ")
options_data   = HTAPData.parseJson( $options_file, desc = 'Options definitions')
stream_out(" / unit costs ")
unit_cost_data = HTAPData.parseJson( $costs_file , desc='Unit costs file')
stream_out(" / assebmlies ")
assembly_data  = HTAPData.parseJson( $assembly_file , desc='Assembly file')
stream_out(" / results ")
results_data = CSV.parse(File.read($results_file), headers: true)
stream_out ("] done.\n")
list_of_attributes = []

# Shortlist inputs,
debug_out("List of attributes: ")
for header in results_data.headers()
  if (header =~ /^input\|/i  )
    debug_out (" - #{header}\n")
    list_of_attributes.push(header.gsub(/^input\|/,''))
  end 
end 



h2k_file_data = {}

out_csv = CSV.open($recosted_file,'w') 

modified_costs = []
first = true 
irow = 0
ifailures = 0

##debug_on 

for row in results_data.by_row.each()
  
  irow = irow + 1 

  
  #begin 

    if ( row['input|Opt-Heating-Cooling'] != 'ASHP-mini-split' )
      #stream_out "X >#{row['input|Opt-Heating-Cooling']}<\n"
    #  next 
    else   
      #stream_out "o >#{row['input|Opt-Heating-Cooling']}<\n"
    end 



    #next if irow < 20720
    #next if irow > 20760

    stream_out (" [ # #{irow} ")

    #break if irow > 100
    #stream_out(" Parsing row # #{irow}\r")


    h2k_file = row['archetype|h2k-File']
    #debug_on 
    #debug_out "> #{h2k_file}\n"
    #debug_off
    skip = false
    if (h2k_file == 'CFHA-Portfolio-6047.H2K' ||  h2k_file == 'CFHA-Portfolio-1007.H2K' )
      skip = false 
    end 
    
    next if skip 

    pkg_list = row['input|upgrade-package-list']
    #debug_on 
    #debug_out (" ROW # #{irow}: h2k file: #{h2k_file}, pkg: #{pkg_list} \n")
    #debug_off
    #debug_on if (pkg_list == "scenario-1-recap-T3-z4&5")
    


    choices = {}
    debug_out " - CHOICES: start -----------------\n"
    for attribute in list_of_attributes
      choices[attribute] = row["input|#{attribute}"]
      debug_out "   CHOICE: #{attribute}->#{choices[attribute]}\n"
    end   
    debug_out " - CHOICES: end -----------------\n"
    

    system_size_heating = row['output|PEAK-Heating-W']
    system_size_cooling = row['output|PEAK-Cooling-W']



    # Not sure what the logic here is. 
    if ( row['input|Opt-Ruleset'] =~ /NBC9_36/ ) then 
      costed = false 
    else 
      costed = true 
    end 



    debug_out "COSTED FLAG: [#{costed}]\n"


    if ! h2k_file_data.key?(h2k_file)
      
      h2k_file_path = "#{$h2k_path}\\#{h2k_file}".gsub(/\\/,'/')
      
      h2k_file_data[h2k_file] = H2KFile.get_elements_from_filename(h2k_file_path)
      # Need to adapt h2k system size to value computed at run (otherwise the base archetype
      # system size will be used, and won't reflect climate or envelope parameters for the rhn)
      h2k_file_data[h2k_file]["HouseFile/AllResults"].elements.each do |element|
        element.elements[".//Other"].attributes["designHeatLossRate"] = system_size_heating
        element.elements[".//Other"].attributes["designCoolLossRate"] = system_size_cooling
      end
      debug_out (" System size - Heating: #{system_size_heating} W\n")

    end 

    h2kElements = h2k_file_data[h2k_file]
    h2kElements["HouseFile/AllResults"].elements.each do |element|
      element.elements[".//Other"].attributes["designHeatLossRate"] = system_size_heating
      element.elements[".//Other"].attributes["designCoolLossRate"] = system_size_cooling
    end  

    final_size =  H2KFile.getDesignLoads(  h2kElements  )
      
    debug_out ( " size for costing calculations: #{system_size_heating} W (#{final_size['heating_W']}): \n")



    costEstimates = Costing.estimateCosts(options_data,assembly_data,unit_cost_data,choices,list_of_attributes, h2kElements  )
    row['recosted|OK?']   = "#{costed}"
    row['recosted|total_avg'] = costEstimates['total_avg']
    row['recosted|total_max'] = costEstimates['total_max']
    row['recosted|total_min'] = costEstimates['total_min']


    #debug_pause if (pkg_list == "Retrofit-env-pkg_101")

    debug_out (" - Costing result: start -----------\n")
    debug_out (costEstimates.pretty_inspect)
    debug_out (" - Costing result: end -----------\n")

    for attribute in costEstimates['byAttribute'].keys()
      row['recosted|byAttribute|'+attribute] = costEstimates['byAttribute'][attribute]
    end 

    for component in costEstimates['byBuildingComponent'].keys
      row['recosted|byBuildingComponent|'+component] =  costEstimates['byBuildingComponent'][component]
    end 

    
    modified_costs.push(row)

    if first then 
      out_csv << row.headers()
      first = false
    end 
    out_csv << row 
    stream_out (" O ")
  #rescue 
    #ifailures = ifailures + 1 
    #stream_out ( " X " )
    #warn_out (" Could not cost row.\n")

  #end 

  stream_out "]\n"
  

  debug_off 
  #debug_pause if (pkg_list == "scenario-1-recap-T3-z4&5")
end 



stream_out("Measures that were costed successfully:\n")
for key in $costed.keys().sort
  if $costed[key]
    stream_out "[o] #{key}\n"
  end 
end 

stream_out("Measures that could not be costed:\n")
for key in $costed.keys().sort
  if ! $costed[key]
    stream_out "[X] #{key}\n"
  end 
end 

stream_out("[ #{irow} rows, #{ifailures} failures ]")

stream_out (" done!\n")
