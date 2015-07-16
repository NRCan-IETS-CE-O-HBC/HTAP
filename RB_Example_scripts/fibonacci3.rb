#!/usr/bin/env ruby
# fibonacci3.rb

class Integer

  def fib(returns_self = [0, 1])
    return self if returns_self.include?(self)
    return (self-1).fib(returns_self) + (self-2).fib(returns_self)
  end 

end
