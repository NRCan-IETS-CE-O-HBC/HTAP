#!/usr/bin/env ruby
# test_temp_converter.rb

require 'temperature_converter'
require 'test/unit'

class Tester < Test::Unit::TestCase

  def setup
    @converter = Temperature_Converter.new()
  end
  
  def test_temps()
    
    tests = {
      '100.0 C = 212.00 F' => {
        :have_num  => 100.0,
        :have_unit => 'C',
        :want_unit => 'F',
      },
      '212.0 F = 100.00 C' => {
        :have_num => 212.0, 
        :have_unit => 'F',  
        :want_unit => 'C',
      },
      '70.0 F = 294.26 K' => {
        :have_num => 70.0, 
        :have_unit => 'F',  
        :want_unit => 'K',
      },
      '25.0 C = 298.15 K' => {
        :have_num => 25.0, 
        :have_unit => 'C',  
        :want_unit => 'K',
      },
    }
    general_tester( tests )

  end
  
  private

  def general_tester(tests)
    tests.each_pair do |result,test_args|
      assert_equal( result, @converter.convert( test_args ) )
    end
  end

end
