
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

$results_file = ''
$costs_file = ''
$assembly_file = ''
$options_file  = ''

$recosted_file = 'HTAP-prm-output-recosted.csv'

stream_out( drawRuler("A script for re-estimating capital costs from HTAP output."))


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

stream_out (" Parsing input files...")

options_data   = HTAPData.parseJson( $options_file, desc = 'Options definitions')
unit_cost_data = HTAPData.parseJson( $costs_file , desc='Unit costs file')
assembly_data  = HTAPData.parseJson( $assembly_file , desc='Assembly file')
results_data = CSV.parse(File.read($results_file), headers: true)

stream_out (" done.\n")
list_of_attributes = []

# Shortlist inputs,
for header in results_data.headers()
  if (header =~ /^input\|/i  )
    list_of_attributes.push(header.gsub(/^input\|/,''))
  end 
end 

h2k_file_data = {}


out_csv = CSV.open($recosted_file,'w') 

modified_costs = []
first = true 
stream_out(" Parsing rows")
for row in results_data.by_row.each()

  h2k_file = row['archetype|h2k-File']
  
  if ! h2k_file_data.key?(h2k_file)
    h2k_file_path = "#{$h2k_path}\\#{h2k_file}".gsub(/\\/,'/')
    h2k_file_data[h2k_file] = H2KFile.get_elements_from_filename(h2k_file_path)
  end 

  choices = {}

  for attribute in list_of_attributes
     choices[attribute] = row["input|#{attribute}"]
  end 

  costEstimates = Costing.estimateCosts(options_data,assembly_data,unit_cost_data,choices,list_of_attributes, h2k_file_data[h2k_file] )

  row['recosted|total'] = costEstimates['total']

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
  stream_out '.'

end 

stream_out (" done!\n")
