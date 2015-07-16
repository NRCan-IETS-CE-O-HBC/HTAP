#!/usr/bin/env ruby
# shuffle_play

class Array

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
    @files = files
  end

=begin rdoc
Plays a shuffled version of self with the play_file method.
=end
  def play()
    @files.shuffle.each do |file|
      play_file(file)
    end
  end

  private

=begin rdoc
Uses ogg123, assumes presence and appropriateness.
=end
  def play_file(file)
    system("ogg123 #{file}")
  end

end # ShufflePlayer

###

sp = ShufflePlayer.new(ARGV)
sp.play()
