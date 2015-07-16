#!/usr/bin/env ruby
# demo_els_parser.rb

require 'els_parser.rb' 

moby_dick = ELS_Parser.new('extras/moby_dick.txt')
puts moby_dick.search() # assumes 'ssirhan'
puts moby_dick.reset_params( {
  :start_pt => 93060,
  :end_pt   => nil,
  :min_skip => 13790,
  :max_skip => 13800,
  :term     => 'kennedy'
} ).search()
puts moby_dick.reset_params( {
  :start_pt => 327400,
  :end_pt   => nil,
  :min_skip => 0,
  :max_skip => 5,
  :term     => 'rabin'
} ).search()
puts moby_dick.reset_params( {
  :start_pt => 104620,
  :end_pt   => 200000,
  :min_skip => 26020,
  :max_skip => 26030,
  :term     => 'mlking'
} ).search()
