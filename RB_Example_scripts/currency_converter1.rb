#!/usr/bin/env ruby
# currency_converter1.rb
# Using fixed exchange rates

class CurrencyConverter

  BASE_ABBR_AND_NAME = { 'USD' => 'US Dollar' }
  
  FULLNAME_OF = {
    'EUR' => 'Euro',
    'CAD' => 'Canadian Dollar',
    'CNY' => 'Chinese Yuan',
    'INR' => 'Indian Rupee',
    'MXN' => 'Mexican Peso',
  }
  
  EXCHANGE_RATES = {
    'EUR' => 0.781738,
    'INR' => 46.540136,
    'CNY' => 7.977233,
    'MXN' => 10.890852,
    'CAD' => 1.127004,
  }
  
  def initialize()
    @base_currency = BASE_ABBR_AND_NAME.keys[0]
    @name          = BASE_ABBR_AND_NAME[@base_currency]
  end

  def output_rates(mult=1)
    get_value(mult, get_rates) + "\n"
  end

  private

  def get_rates()
    return EXCHANGE_RATES
  end

  def get_value(mult, rates)
    return pluralize(mult, @name) + 
    	" (#{@base_currency}) = \n" + 
    	rates.keys.map do |abbr| 
      	"\t" + 
      	pluralize(mult * rates[abbr], FULLNAME_OF[abbr]) + 
      	"(#{abbr})"
    	end.join("\n")
  end

=begin rdoc
This assumes that all plurals will be formed by adding an 's'. 
It could be made more flexible with a Hash of plural suffixes (which 
could be the empty string) or explicit plural forms that are simple 
replacements for the singular. 

For convenience, this outputs a string with the number of items, a 
space, and then the pluralized form of the currency unit. That suited 
the needs of this particular script.
=end
  def pluralize(num, term)
    (num == 1) ? "#{num} #{term}" : "#{num} #{term}s"
  end

end
