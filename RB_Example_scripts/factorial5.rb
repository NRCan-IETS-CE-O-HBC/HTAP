#!/usr/bin/env ruby
# factorial5.rb

class Integer
  
  @@factorial_results = [1, 1] # Both 0 and 1 have a value of 1

  def fact()
    @@factorial_results[self] ||= self * (self-1).fact
  end

  def show_mems()
    @@factorial_results.inspect
  end

end
