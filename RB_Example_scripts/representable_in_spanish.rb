=begin rdoc
This is intended for use with to_lang.rb
=end

module Representable_In_Spanish

=begin rdoc
Return a <b>Hash</b> whose keys are <b>Integer</b>s and whose values 
are the word representing the same value written out as a word.
=end
  def create_spanish()
    need_ones_in_spanish.merge(dont_need_ones_in_spanish)

  end
  
  def special_replacements_in_spanish(num_as_string)
    add_hyphens_to_tens(num_as_string).strip
  end

# syntactic sugar
  def to_spanish()
    to_lang('spanish')
  end

  alias :to_es :to_spanish

  private

  def add_hyphens_to_tens(num_as_string)
    num_as_string.sub(/ta/, 'ta-').sub(/-?- ?/, '-')
  end

  def need_ones_in_spanish()
    return {
    10 ** 12 => 'billon',
    10 ** 9  => 'mil millones',
    10 ** 6  => 'millon',
    10 ** 3  => 'mil',
    100      => 'ciento',
    }
  end

  def dont_need_ones_in_spanish()
    return {
      90 => 'noventa',
      80 => 'ochenta',
      70 => 'setenta',
      60 => 'sesenta',
      50 => 'cincuenta',
      40 => 'cuarenta',
      30 => 'treinta',
      20 => 'veinte',
      19 => 'diecinueve',
      18 => 'dieciocho',
      17 => 'diecisiete',
      16 => 'dieciseis',
      15 => 'quince',
      14 => 'catorce',
      13 => 'trece',
      12 => 'doce',
      11 => 'once',
      10 => 'deiz',
       9 => 'nueve',
       8 => 'ocho',
       7 => 'siete',
       6 => 'seis',
       5 => 'cinco',
       4 => 'cuatro',
       3 => 'tres',
       2 => 'dos',
       1 => 'uno',
       0 => '', # 'cero'
    }
  end

end
