
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

hasCostData = Hash.new


optionsFile = File.read("C:\\HTAP\\HTAP-options.json")
optionsHash = JSON.parse(optionsFile)

optionsHash.each do | attribute, definitions |
  # Report cost data

  # =======================================================================
  #
  # =======================================================================


  if ( ! definitions["costed"] ) then
    stream_out "> attribute #{attribute} : no cost data\n"
    next

  end

  definitions["options"].each do | option, data |

     if ( ! data["costs"]["components"].nil? &&
            data["costs"]["components"].length > 0 ) then

         stream_out " Cost data for :  #{attribute} \ #{option} \n"
         if ( hasCostData[attribute].nil? )
           hasCostData[attribute] = "#{option}"
         else
           hasCostData[attribute] = "#{hasCostData[attribute]}, #{option}"
         end

     end

  end

end


pp hasCostData

outputCDf = File.new("options_with_cost_data.txt", "w")

hasCostData.each do |attribute,options|
  outputCDf.write "#{attribute} => #{options} \n"
end
outputCDf.close 
