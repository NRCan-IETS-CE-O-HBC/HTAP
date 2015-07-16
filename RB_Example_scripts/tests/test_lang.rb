#!/usr/bin/env ruby
# test_lang.rb

require 'to_lang'
require 'test/unit'

class Tester < Test::Unit::TestCase

  def test_langs()
    
    tests = {
      'en' => {
        1     => 'one',
        5     => 'five',
        9     => 'nine',
        11    => 'eleven',
        51    => 'fifty one',
        100   => 'one hundred',
        101   => 'one hundred one',
        257   => 'two hundred fifty seven',
        1000  => 'one thousand',
        1001  => 'one thousand one',
        90125 => 'ninety thousand one hundred twenty five',
      },
      'es' => {
        1     => 'uno',
        5     => 'cinco',
        9     => 'nueve',
        11    => 'once',
        51    => 'cincuenta-uno',
        100   => 'uno ciento',
        101   => 'uno ciento uno',
        257   => 'dos ciento cincuenta-siete',
        1000  => 'uno mil',
        1001  => 'uno mil uno',
        90125 => 'noventa-mil uno ciento veinte cinco',
      }
    }
    %w[ en es ].each do |lang|
      general_tester( tests, lang )
    end
  end
  
  private

  def general_tester(tests, lang)
    tests[lang].each_key do |num|
      assert_equal( num.send("to_#{lang}"), tests[lang][num] )
    end
  end

end
