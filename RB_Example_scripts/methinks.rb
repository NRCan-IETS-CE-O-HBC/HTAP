#!/usr/bin/env ruby
# methinks.rb

=begin rdoc
Recreate Richard Dawkins' Blind Watchmaker program, in which a 
purely random string is mutated and filtered until it matches 
the target string.
=end

class Children < Array

  def select_fittest(target)
    inject(self[0]) do |fittest,child|
      child.fitter_than?(fittest, target) ? child : fittest
    end
  end

end

class String

  ALPHABET = ('a'..'z').to_a

  LETTER_OFFSET = 'a'[0]

  PARAMS = {
    :generation_size => 20, 
    :mutation_rate   => 10, 
    :display_filter  => 5,
    :mutation_amp    => 6
  }

  TARGET = 'methinksitislikeaweasel'
  
  @mutation_attempts ||= 0

  def deviance_from(target)
    deviance = 0
    split('').each_index do |index|
      deviance += (self[index] - target[index]).abs
    end
    return deviance
  end

  def fitter_than?(other, target)
    deviance_from(target) < other.deviance_from(target)
  end

  def mutate(params)
    split('').map do |char|
      mutate_char(char, params)
    end.join('')
  end

  def mutate_until_matches!(target=TARGET, params=PARAMS)
    return report_success if (self == target)
    report_progress(params)
    @mutation_attempts += 1
    children = propagate(params)
    fittest  = children.select_fittest(target)
    replace(fittest)
    mutate_until_matches!(target, params)
  end

  def propagate(params)
    children = Children.new()
    children << self
    params[:generation_size].times do |generation|
      children << self.mutate(params)
    end
    return children
  end

  def report_progress(params)
    return unless (@mutation_attempts % params[:display_filter] == 0)
    puts "string ##{@mutation_attempts} = #{self}"
  end

  def report_success()
    puts <<END_OF_HERE_DOC
I match after #{@mutation_attempts} mutations
END_OF_HERE_DOC
    return @mutation_attempts
  end

=begin rdoc
Replace self with a <b>String</b> the same length as the 
<i>target</i> argument, consisting entirely of lowercase 
letters.
=end
  def scramble!(target=TARGET)
    @mutation_attempts = 0
    replace( scramble(target) )
  end
  
  def scramble(target=TARGET)
    target.split('').map do |char|
      ALPHABET[rand(ALPHABET.size)]
    end.join('')
  end

  private

=begin rdoc
limit 'out of bounds' indices at end points of the ALPHABET
=end
  def limit_index(alphabet_index)
    alphabet_index = [ALPHABET.size-1,  alphabet_index].min
    alphabet_index = [alphabet_index, 0].max
    return alphabet_index
  end

  def mutate_char(original_char, params)
    return original_char if rand(100) > params[:mutation_rate]
    variance = rand(params[:mutation_amp]) - (params[:mutation_amp] / 2)
    # variance with amp of 6 now ranges from -3 to 2,
    variance += 1 if variance.zero? # therefore move (0..2) up to (1..3)
    alphabet_index = (original_char[0] + variance - LETTER_OFFSET)
    alphabet_index = limit_index(alphabet_index)
    mutated_char = ALPHABET[alphabet_index]
    return mutated_char
  end

end # String

=begin remove '=begin' and '=end' to demo alone
candidate = String.new.scramble!()
candidate.mutate_until_matches!()
=end
