
require 'rexml/document'
require 'optparse'
require 'timeout'
require 'fileutils'
require 'digest'
require 'json'
require 'set'
require 'pp'



require_relative '../inc/msgs'
require_relative '../inc/H2KUtils'
require_relative '../inc/HTAPUtils'
require_relative '../inc/constants'
#require_relative '../inc/rulesets'
#require_relative '../inc/costing'
#require_relative '../inc/legacy-code'

include REXML

$gTest_params["verbosity"] = "verbose"

$program = "geth2kinfo.rb"

HTAPInit()



stream_out drawRuler("a simple script that populates and prints the h2k data map.")


#-------------------------------------------------------------------
# Help text. Dumped if help requested, or if no arguments supplied.
#-------------------------------------------------------------------
$help_msg = "

#{$program}:

This script takes a h2k file, parses it, and prints the contents
of the h2kinfo hash.

Use:

geth2kinfo.rb [h2kfile.h2k]


"

# Dump help text, if no argument given
if ARGV.empty? then
  puts $help_msg
  exit()
end

h2kElements = H2KFile.get_elements_from_filename(ARGV[0])

myH2KHouseInfo = Hash.new
myH2KHouseInfo = H2KFile.getAllInfo(h2kElements)

stream_out (" Contents of myH2KHouseInfo:\n\n#{myH2KHouseInfo.pretty_inspect}")

ReportMsgs()
