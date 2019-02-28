# Code used to test some functions

#!/usr/bin/env ruby
# ************************************************************************************
# This is a really rudamentary run-manager developed as a ...
# ************************************************************************************

require 'optparse'
require 'ostruct'
require 'timeout'
require 'fileutils'
require 'pp'
require 'json'
require 'set'
require 'rexml/document'


require_relative '../include/msgs'
require_relative '../include/H2KUtils'
require_relative '../include/HTAPUtils'
require_relative '../include/constants'
require_relative '../include/rulesets'
require_relative '../include/costing'
require_relative '../include/legacy-code'
require_relative '../include/application_modules'

include REXML   # This allows for no "REXML::" prefix to REXML methods

$program = "misc-dev-tests.rb"

HTAPInit()

stream_out(drawRuler("A useless script that tests how some functions within HTAP work."))

# Did log files get created?
stream_out(drawRuler("HTAP intialization","_"))

stream_out("\n\n")

stream_out(" + Check : misc-dev-tests_log.txt exists".ljust(80) + " ? ")
if (  ! File.file?("misc-dev-tests_log.txt")) then
  stream_out(" No. \n")
  warn_out ("Log file #{"misc-dev-tests_log.txt"} could not be created\n")
else
  stream_out(*" yes.\n")
end

stream_out("\n\n")
stream_out(drawRuler("BC STEP CODE DATA","_"))
zones = ["Zone 4","Zone 5","Zone 6", "Zone 7a", "Zone 7b", "Zone 8"]
steps = ["Step 1","Step 2", "Step 3", "Step 4"]

zones.each do |zone|
  stream_out(drawRuler("Searching for step TEDI mins in #{zone}","."))
  tedi = 200
  steps.each do |step|
    thisStep = BCStepCode.getStepByTEDI(zone,tedi)
    while ( thisStep == step )
      tedi = tedi - 1
      thisStep = BCStepCode.getStepByTEDI(zone,tedi)
    end
    stream_out(" + Check : #{zone} , #{thisStep}  TEDI ".ljust(80) +" <= "+"#{tedi}\n")
  end

end





ReportMsgs()
