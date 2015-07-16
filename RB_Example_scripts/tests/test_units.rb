#!/usr/bin/env ruby
# test_units.rb

require 'units_converter'
require 'test/unit'

class Tester < Test::Unit::TestCase

  def setup
    @converter = Units_Converter.new()
  end
  
  def test_temps()
    
    tests = {
      '100.0 C = 212.00 F' => {
        :factor    => 'temp',
        :have_num  => 100.0,
        :have_unit => 'C',
        :want_unit => 'F',
      },
      '212.0 F = 100.00 C' => {
        :factor => 'temp',
        :have_num => 212.0, 
        :have_unit => 'F',  
        :want_unit => 'C',
      }
    }
    general_tester( tests )

  end
  
  def test_length()
    
    tests = {
      '1.0 in = 2.54 cm' => {
        :factor => 'length', 
        :have_num => 1.0,   
        :have_unit => 'in', 
        :want_unit => 'cm',
      },
      '1.0 in = 0.03 m' => {
        :factor => 'length', 
        :have_num => 1.0,   
        :have_unit => 'in', 
        :want_unit => 'm' 
      },
      '0.025 m = 2.50 cm' => {
        :factor => 'length', 
        :have_num => 0.025, 
        :have_unit => 'm',  
        :want_unit => 'cm',
      }
    }
    general_tester( tests )

  end
  
  def test_mass()
    
    tests = {
      '1.0 kg = 2.20 lb' => {
        :factor => 'mass', 
        :have_num => 1.0, 
        :have_unit => 'kg', 
        :want_unit => 'lb' 
      },
      '2.2 lb = 1.00 kg' => {
        :factor => 'mass', 
        :have_num => 2.2, 
        :have_unit => 'lb', 
        :want_unit => 'kg' 
      }
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
