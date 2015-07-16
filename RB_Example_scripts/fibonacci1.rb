#!/usr/bin/env ruby
# fibonacci1.rb

class Integer

  def fib()
    return 0 if self.zero?
    return 1 if self == 1
    return (self-1).fib + (self-2).fib
  end

end
