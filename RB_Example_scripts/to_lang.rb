#!/usr/bin/env ruby -w
# to_lang.rb

=begin rdoc
Implement representation of numbers in human languages:
1 => 'one',
2 => 'two',
etc.

This is an generalized extension of ideas shown for the 
specific case of roman numerals in roman_numeral.rb

Note that similar work has already been done at
http://www.deveiate.org/projects/Linguistics/wiki/English
This version focuses only on converting numbers to multiple 
language targets, and pedantically considers "and" to be 
the pronunciation of the decimal point.
=end

class Integer

  require 'representable_in_english'
  require 'representable_in_spanish'
  
  include Representable_In_English
  include Representable_In_Spanish

  EMPTY_STRING = ''
  SPACE        = ' '

  @@lang_of ||= Hash.new()

  def need_ones?(lang)
    send("need_ones_in_#{lang}").keys.include?(self)
  end

  def to_lang(lang)
    return EMPTY_STRING if self.zero?
    
    @@lang_of[lang] ||= send("create_#{lang}")
    
    base      = get_base(lang)
    mult      = (self / base).to_i
    remaining = (self - (mult * base))
   
    raw_output = [
      mult_prefix(base, mult, lang),
      @@lang_of[lang][base],
      remaining.to_lang(lang)
    ].join(SPACE)

    return send(
	"special_replacements_in_#{lang}", 
	raw_output)
  end
 
  private

  def get_base(lang)
    return self if @@lang_of[lang][self]
    @@lang_of[lang].keys.sort.reverse.detect do |k| 
      k <= self
    end
  end

  def mult_prefix(base, mult, lang)
    return mult.to_lang(lang) if mult > 1
    return 1.to_lang(lang)    if base.need_ones?(lang)
    return EMPTY_STRING
  end

end
