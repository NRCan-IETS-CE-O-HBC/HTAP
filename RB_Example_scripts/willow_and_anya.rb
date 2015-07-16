#!/usr/bin/env ruby -w
# willow_and_anya.rb

%w[him same_time_same_place].each do |lib_file|
  require "#{lib_file}"
end

[Him, SameTimeSamePlace].each do |episode|
  puts episode.describe()
end
