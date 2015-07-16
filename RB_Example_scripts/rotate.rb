#!/usr/bin/env ruby
# rotate.rb

class String

  def rotate(char)
    return nil unless self.match(char)
    return self if (self[0] == char[0])
    chars = self.split(//)
    return ([chars.pop] + chars).join('').rotate(char)
  end

  def rotate!(char)
    replace(rotate(char))
  end

end
