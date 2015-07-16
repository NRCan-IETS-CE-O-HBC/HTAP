=begin rdoc
This is intended for use with to_lang.rb
=end

module Representable_In_English

=begin rdoc
Return a <b>Hash</b> whose keys are <b>Integer</b>s and whose values 
are the word representing the same value written out as a word.
=end
  def create_english()
    need_ones_in_english.merge(dont_need_ones_in_english)

  end
  
  def special_replacements_in_english(num_as_string)
    add_hyphens_to_tens(num_as_string).strip
  end

# syntactic sugar
  def to_english()
    to_lang('english')
  end

  alias :to_en :to_english

  private

  def add_hyphens_to_tens(num_as_string)
    num_as_string.sub(/ty/, 'ty-').sub(/-?- ?/, '-')
  end

  def need_ones_in_english()
    return {
    10 ** 9 => 'billion',
    10 ** 6 => 'million',
    10 ** 3 => 'thousand',
    100     => 'hundred',
    }
  end

  def dont_need_ones_in_english()
    return {
      90 => 'ninety',
      80 => 'eighty',
      70 => 'seventy',
      60 => 'sixty',
      50 => 'fifty',
      40 => 'forty',
      30 => 'thirty',
      20 => 'twenty',
      19 => 'nineteen',
      18 => 'eighteen',
      17 => 'seventeen',
      16 => 'sixteen',
      15 => 'fifteen',
      14 => 'fourteen',
      13 => 'thirteen',
      12 => 'twelve',
      11 => 'eleven',
      10 => 'ten',
       9 => 'nine',
       8 => 'eight',
       7 => 'seven',
       6 => 'six',
       5 => 'five',
       4 => 'four',
       3 => 'three',
       2 => 'two',
       1 => 'one',
       0 => '',
    }
  end

end
