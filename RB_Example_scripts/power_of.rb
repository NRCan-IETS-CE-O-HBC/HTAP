#!/usr/bin/env ruby
# power_of.rb

class Integer

=begin rdoc
Add a simple <b>Integer</b>-only method that reports the 
exponent to which the base must be raised to get self.
=end
  def power_of(base)
    # return nil for inapplicable situations
    return nil   unless base.is_a?(Integer)
    return nil   if (base.zero? and not [0, 1].include?(self))
    
    # deal with odd but reasonable 
    # numeric situations
    return 1     if base == self
    return 0     if self == 1
    return false if base == 1
    return false if base.abs > self.abs

    exponent = (self/base).power_of(base)
    return exponent ? exponent + 1 : exponent
  end

end
