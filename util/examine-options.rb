
#

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
require_relative '../include/constants'

$program = "examine-options.rb"
$info    = 
"  This script opens up the htap-options.json file and
  perfroms a set of tasks with it:

  With these modifications, it creates a new version of
  the options file (HTAP-options-draft.json), and
  saves it to the working directory.


"

hasCostData = Hash.new
setTermSize
writeHeader

optionsFile = File.read("C:\\HTAP\\HTAP-options.json")
optionsHash = JSON.parse(optionsFile)
exit
optionsHash.each do | attribute, definitions |
  # Report cost data

  # =======================================================================
  #
  # =======================================================================

  stream_out drawRuler("attribute #{attribute}")
  if ( ! definitions["costed"] ) then
    stream_out "(no cost data)\n"
    next
  end

  definitions["options"].each do | option, data |

     stream_out drawRuler(" -> #{option}  ? ",". ")
     if ( ! data["costs"]["components"].nil? &&
            data["costs"]["components"].length > 0 ) then

         stream_out "       found component cost data:"
         if ( hasCostData[attribute].nil? )
           hasCostData[attribute] = "#{option}"
         else
           hasCostData[attribute] = "#{hasCostData[attribute]}, #{option}"
         end

     end
    if ( ! data["costs"]["proxy"].nil? )
      proxy = data["costs"]["proxy"]
      stream_out "       found component proxy cost data: (#{proxy})"
      if ( hasCostData[attribute].nil? )
         hasCostData[attribute] = "#{option}"
       else
         hasCostData[attribute] = "#{hasCostData[attribute]}, #{option}"
      end
    end


    stream_out "\n"
  end

end


pp hasCostData

outputCDf = File.new("options_with_cost_data.txt", "w")

hasCostData.each do |attribute,options|
  outputCDf.write "#{attribute} => #{options} \n"
end
outputCDf.close
