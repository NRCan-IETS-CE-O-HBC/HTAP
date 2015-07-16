#!/usr/bin/env ruby
# test_palindrome.rb
puts "Band\tPal?\tpal?"
bands = %w[abba Abba asia Asia]
bands.each do |band| 
  puts "#{band}\t#{band.palindrome?}\t#{band.palindrome?(false)}"
end
