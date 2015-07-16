#!/usr/bin/env ruby
# fibonacci4.rb

class Integer

  RETURNS_SELF = [0, 1]

  def fib()
    return self if RETURNS_SELF.include?(self)
    return (self-1).fib() + (self-2).fib()
  end 

end
