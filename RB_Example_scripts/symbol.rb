#!/usr/bin/env ruby
# symbol.rb

=begin rdoc
This is taken directly from the Ruby Extensions Project at 
http://extensions.rubyforge.org/rdoc/index.html and is licensed 
under the same terms as Ruby itself.
=end
class Symbol

  def to_proc
    Proc.new { |obj, *args| obj.send(self, *args) }
  end

end # class Symbol

# sample usage and resulting values:
# a = (0..9).to_a
# a.map(&:inspect) => ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
# a.inject(&:+) => 45
# a.map(&:inspect).inject('', &:+) => "0123456789"
# etc.
