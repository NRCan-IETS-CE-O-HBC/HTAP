#!/usr/bin/env ruby
# test_opts.rb

=begin comment
Run this without warnings to avoid message about method redefinition, 
which we are doing intentionally for this testing script.
=end

require 'benchmark'
include Benchmark

  FUNC_OF_FILE = {
    'factorial' => 'fact',
    'fibonacci' => 'fib',
  }

  UPPER_OF_FILE = {
    'factorial' => 200,
    'fibonacci' => 30,
  }

['factorial', 'fibonacci'].each do |file|
  
  (1..5).to_a.each do |num|
    require "#{file}#{num}"
    upper = UPPER_OF_FILE[file]
    
    bm do |test|
      
      test.report("#{file}#{num}") do
        upper.send(FUNC_OF_FILE[file])
      end
    
    end
  
  end

end
