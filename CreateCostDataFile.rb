#!/usr/bin/env ruby
# ******************************************************************************
# CreateCostDataFile.rb
# Developed by Jeff Blake, CanmetENERGY-Ottawa, Natural Resources Canada
# Created September 2018
# Master maintained in GitHub
#
# This script creates a JSON cost data file by converting a costing spreadsheet
# that has been cleaned up from the original LEEP costing spreadsheet.
#
# This script could be modified to read directly from the large, multi-sheet
# LEEP Excel files and extract/reformat to suit with a little more effort.
# ******************************************************************************

require 'csv'
require 'json'
require 'fileutils'

extracted_data   = CSV.table('./UnitCosts_Edited.csv', header_converters: nil )
transformed_data = extracted_data.map { |row| row.to_hash }

File.open('./HTAPUnitCosts.json', 'w') do |file|
  file.puts JSON.pretty_generate(transformed_data)
end

puts("HTAPUnitCosts.json successfully created with #{transformed_data.count} entries.")



