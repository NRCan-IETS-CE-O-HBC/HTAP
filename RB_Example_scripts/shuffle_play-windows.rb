#!/usr/bin/env ruby
# shuffle_play-windows.rb

class Array

  PLAYER_NAME="C:\\Program Files\\Winamp\\winamp.exe"

=begin rdoc
Non-destructive; returns a copy of self, re-ordered randomly.
=end
  def shuffle()
    sort_by { rand }
  end

=begin rdoc
Destructive; re-orders self randomly.
=end
  def shuffle!()
    replace(shuffle)
  end

=begin rdoc
While we're here, we might as well offer a method 
for pulling out a random member of the <b>Array</b>.
=end
  def random_element()
    shuffle[0]
  end

end # Array

###

class ShufflePlayer

  def initialize(files)
    @files = files.map { |filename| "\"#{filename}\"" }
  end

=begin rdoc
Plays a shuffled version of self
=end
  def play()
    system( "\"#{PLAYER_NAME}\" #{@files.join(' ')}")
  end

end # ShufflePlayer

###

sp = ShufflePlayer.new(ARGV)
sp.play()
