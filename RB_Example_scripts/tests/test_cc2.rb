#!/usr/bin/env ruby -w
# test_cc2.rb

require 'currency_converter2.rb'

['USD', 'CAD', 'INR'].each do |abbr|
  cc = CurrencyConverter.new(abbr)
  puts cc.output_rates(1, true)
  puts cc.output_rates(1, false)
  puts cc.output_rates(42, true)
  puts cc.output_rates(42, false)
end
