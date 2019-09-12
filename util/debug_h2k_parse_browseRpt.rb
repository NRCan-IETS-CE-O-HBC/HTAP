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

$program = "debug_h2k_parseBrowseRpt.rb"

HTAPInit()

stream_out(drawRuler("A useless script that tests function H2KOutput.parse_BrowseRpt "))

data = H2KOutput.parse_BrowseRpt("sim-output/Browse.Rpt")


pp data
