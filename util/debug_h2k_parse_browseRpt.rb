require 'optparse'
require 'ostruct'
require 'timeout'
require 'fileutils'
require 'pp'
require 'json'
require 'set'
require 'rexml/document'


require_relative '../inc/msgs'
require_relative '../inc/H2KUtils'
require_relative '../inc/HTAPUtils'
require_relative '../inc/constants'
require_relative '../inc/rulesets'
require_relative '../inc/costing'
require_relative '../inc/legacy-code'
require_relative '../inc/application_modules'

include REXML   # This allows for no "REXML::" prefix to REXML methods

$program = "debug_h2k_parseBrowseRpt.rb"

HTAPInit()

stream_out(drawRuler("A useless script that tests function H2KOutput.parse_BrowseRpt "))

data = H2KOutput.parse_BrowseRpt("sim-output/Browse.Rpt")


pp data
