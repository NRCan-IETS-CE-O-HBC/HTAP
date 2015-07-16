#!/usr/bin/env ruby
# factorial4.rb

class Integer

  RETURNS_1_FOR_FACTORIAL = [0, 1]

  def fact()
    return 1 if RETURNS_1_FOR_FACTORIAL.include?(self)
    return self * (self-1).fact
  end 

end
