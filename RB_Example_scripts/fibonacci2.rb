#!/usr/bin/env ruby
# fibonacci2.rb

class Integer

  def fib()
    return self if [0, 1].include?(self)
    return (self-1).fib + (self-2).fib
  end

end
