#!/usr/bin/env ruby
# factorial3.rb

class Integer

  def fact(returns1 = [0, 1])
    return 1 if returns1.include?(self)
    return self * (self-1).fact(returns1)
  end 

end
