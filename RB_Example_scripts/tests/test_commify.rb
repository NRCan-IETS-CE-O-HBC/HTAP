#!/usr/bin/env ruby
# test_commify.rb

require 'commify'

puts ARGV[0].to_f.commify()
alt_args = {
	:delim => 'delim', 
	:breakpoint => 2, 
	:decimal_pt => 'dp', 
	:show_hundredths => false
} 
puts ARGV[0].to_f.commify(alt_args)

#0.upto(10000) do |i|
#  [i, i.to_f/23.0].each do |k|
#    puts k.commify()
#    puts k.commify('x', 2, 'dec')
#  end
#end
