#!/usr/bin/env ruby
# boolean_golf.rb

=begin rdoc
This is intended merely to add handy true? and false? methods to every
object. The most succinct way seemed to be declaring these particular
methods in this order. Note that to_b ("to Boolean") is an alias to
the true?() method.
=end
class Object

  def false?()
    not self
  end

  def true?()
    not false?
  end
  
  alias :to_b :true?

end
