module Precision

  # what character should be displayed at each breakpoint?
  COMMIFY_DELIMITER  = ','

  # What should the decimal point character be?
  COMMIFY_DECIMAL = '.'

  # What power of 10 defines each breakpoint?
  COMMIFY_BREAKPOINT = 3

  # Should an explicit '0' be shown in the 100ths place, 
  # such as for currency?
  COMMIFY_PAD_100THS = true

=begin rdoc
This method returns a <b>String</b> representing the numeric value of
self, with delimiters at every digit breakpoint. 4 Optional arguments:

1. delimiter (<b>String</b>): defaults to a comma
2. breakpoint (<b>Integer</b>): defaults to 3, showing every multiple of 1000
3. decimal_pt (<b>String</b>): defaults to '.'
4. show_hundredths (<b>Boolean</b>): whether an explicit '0' should be shown 
in the hundredths place, defaulting to <b>true</b>.
=end
  def commify(args = {})

    args[:delimiter]       ||= COMMIFY_DELIMITER
    args[:breakpoint]      ||= COMMIFY_BREAKPOINT 
    args[:decimal_pt]      ||= COMMIFY_DECIMAL
    args[:show_hundredths] ||= COMMIFY_PAD_100THS

    int_as_string, float_as_string = to_s.split('.')
    
    int_out   = format_int(
      int_as_string, 
      args[:breakpoint], 
      args[:delimiter]
    )
    
    float_out = format_float(
      float_as_string, 
      args[:decimal_pt], 
      args[:show_hundredths]
    )
    
    return int_out + float_out
  end

  private

=begin rdoc
Return a <b>String</b> representing the properly-formatted 
<b>Integer</b> portion of self.
=end
  def format_int(int_as_string, breakpoint, delimiter)
    reversed_groups = int_as_string.reverse.split(/(\d{#{breakpoint}})/)
    reversed_digits = reversed_groups.grep(/\d+/)
    digit_groups    = reversed_digits.reverse.map { |unit| unit.reverse }
    return digit_groups.join(delimiter)
  end

=begin rdoc
Return a <b>String</b> representing the properly-formatted 
floating-point portion of self.
=end
  def format_float(float_as_string, decimal_pt, show_hundredths)
    return ''  unless float_as_string
    output = decimal_pt + float_as_string
    return output unless show_hundredths 
    output += '0' if (float_as_string.size == 1)
    return output
  end 

end
