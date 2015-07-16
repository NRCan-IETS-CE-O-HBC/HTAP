#!/usr/bin/env ruby
# currency_converter2.rb

### RSS feeds for rates at 
# http://www.currencysource.com/rss_currencyexchangerates.html

=begin rdoc
open-uri allows Kernel.open to read data using a URI, not just from 
a local file.
=end
require 'open-uri'
=begin rdoc
YAML[http://www.yaml.org/] stands for "YAML Ain't Markup Language" 
and is a simple human-readable data markup format.
=end
require 'yaml'

=begin rdoc
I also want to add a method to all <b>Hash</b>es.
=end
class Hash

=begin rdoc
Allow <b>Hash</b>es to be subtracted from each other.
=end
  def -(hash_with_pairs_to_remove_from_self)
    output = self.dup
    hash_with_pairs_to_remove_from_self.each_key do |k|
      output.delete(k)
    end
    output
  end

end

class CurrencyConverter

  BASE_URL = 'http://currencysource.com/RSS'
  CURRENCY_CODES = {
    'EUR' => 'Euro',
    'CAD' => 'Canadian Dollar',
    'CNY' => 'Chinese Yuan',
    'INR' => 'Indian Rupee',
    'MXN' => 'Mexican Peso',
    'USD' => 'US Dollar',
  }
  RATES_DIRECTORY = 'extras/currency_exchange_rates'

  def initialize(code='USD')
    unless CURRENCY_CODES.has_key?(code)
      fail "I know nothing about #{code}" 
    end
    @base_currency = code
    @name          = CURRENCY_CODES[code]
  end

  def output_rates(mult=1, try_new_rates=true)
    rates = get_rates(try_new_rates)
    save_rates_in_local_file!(rates)
    return get_value(mult, rates) + "\n"
  end

  private

  def download_new_rates()
    puts 'Downloading new exchange rates...'
    begin
      raw_rate_lines = get_xml_lines()
    rescue
      puts 'Download failed. Falling back to local file.'
      return nil
    end
    rates = Hash.new('')
    comparison_codes = CURRENCY_CODES - { @base_currency => @name }
    comparison_codes.each_key do |abbr|
      rates[abbr] = get_rate_for_abbr_from_raw_rate_lines(
        abbr, 
        raw_rate_lines
      )
    end
    return rates
  end

  def get_rates(try_new_rates)
    return load_old_rates unless try_new_rates
    return download_new_rates || load_old_rates
  end

  def get_rate_for_abbr_from_raw_rate_lines(abbr, raw_rate_lines)
    regex = {
      :open => 
        /^\<title\>1 #{@base_currency} = #{abbr} \(/,
      :close =>
        /\)\<\/title\>\r\n$/
    }
    line = raw_rate_lines.detect { |line| line =~ /#{abbr}/ }
    line.gsub(regex[:open], '').gsub(regex[:close], '').to_f
  end

  def get_value(mult, rates)
    return "#{pluralize(mult, @name)} (#{@base_currency}) = \n" + 
      rates.keys.map do |abbr| 
        "\t#{pluralize(mult * rates[abbr], CURRENCY_CODES[abbr])} (#{abbr})"
      end.join("\n")
  end

=begin rdoc
get_xml_lines is able to read from a URI with the open-uri library.
This also could have been implemented with the RSS library written by 
Kouhei Sutou <kou@cozmixng.org> and detailed at
http://www.cozmixng.org/~rwiki/?cmd=view;name=RSS+Parser%3A%3ATutorial.en
=end
  def get_xml_lines()
    open("#{BASE_URL}/#{@base_currency}.xml").readlines.find_all do |line| 
      line =~ /1 #{@base_currency} =/
    end
  end

  def load_old_rates()
    puts "Reading stored exchange rates from local file #{rates_filename()}"
    rates = YAML.load(File.open(rates_filename))
    fail 'no old rates' unless rates
    return rates
  end

  def pluralize(num, term)
    (num == 1) ? "#{num} #{term}" : "#{num} #{term}s"
  end

  def rates_filename()
    "#{RATES_DIRECTORY}/#{@base_currency}.yaml"
  end

=begin rdoc
Store new rates in an external YAML file. 
This is a side-effect akin to memoization, hence the bang.
=end
  def save_rates_in_local_file!(rates)
    return unless rates
    File.open(rates_filename, 'w') { |rf| YAML.dump(rates, rf) }
  end

end
