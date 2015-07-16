#!/usr/bin/env ruby
# factorial2.rb

class Integer

  def fact()
    return 1 if [0, 1].include?(self)
    return self * (self-1).fact
  end

end
