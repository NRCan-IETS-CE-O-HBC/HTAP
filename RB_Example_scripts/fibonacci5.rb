#!/usr/bin/env ruby
# fibonacci5.rb

class Integer
  
  @@fibonacci_results = [0, 1]
  
  def fib()
    @@fibonacci_results[self] ||= (self-1).fib + (self-2).fib
  end

end
