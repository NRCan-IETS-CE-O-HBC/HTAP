#!/usr/bin/env ruby
# units_converter.rb
# See also GNU units at http://www.gnu.org/software/units/units.html

# Converts Metric/SI <-> US units.

=begin rdoc
Converts to and from various units of measure. Supplement as desired. 
More information is available at 
http://en.wikipedia.org/wiki/Conversion_of_units
=end
class Units_Converter

  # every factor has some base unit for multi-stage conversion
  BASE_UNIT_OF = {
    'length'      => 'm',
    'volume'      => 'L',
    'mass'        => 'kg',
    'temperature' => 'K',
    'temp'        => 'K',
  }

  # conversion constants within the US system
  INCHES_PER_FT     = 12.0
  QUARTS_PER_GALLON = 4.0
  
  # conversion across the US/Metric divide
  METERS_PER_FT     = 0.3048
  GALLONS_PER_LITER = 0.26417205
  LBS_PER_KILOGRAM  = 2.20462262
  
  # temperature is more complicated
  C_TO_F_ADD        = 32.0
  F_TO_C_RATIO      = 5.0/9.0
  C_TO_K_ADD        = 273.15

  C2K = lambda { |c| c + C_TO_K_ADD }
  F2C = lambda { |f| (f - C_TO_F_ADD ) * F_TO_C_RATIO }
  K2C = lambda { |k| k - C_TO_K_ADD }
  C2F = lambda { |c| (c / F_TO_C_RATIO) + C_TO_F_ADD }
  F2K = lambda { |f| C2K.call( F2C.call(f) ) }
  K2F = lambda { |k| C2F.call( K2C.call(k) ) }

  CONVERSIONS = {
    # most units just need to get to the base unit
    # have => {want => how_many_wants_per_have},
    'ft'  => { 
      'm'  => lambda { |ft| ft * METERS_PER_FT } 
    },
    'in'  => { 
      'm'  => lambda { |inches| inches * (METERS_PER_FT / INCHES_PER_FT) } 
    },
    'gal' => { 
      'L'  => lambda { |gal| gal / GALLONS_PER_LITER } 
    },
    'lb'  => { 
      'kg' => lambda { |lb| lb / LBS_PER_KILOGRAM } 
    },
    'C'   => { 
      'K'  => C2K 
    },
    'F'   => { 
      'K'  => F2K 
    },

    # base units require more conversion targets
    'm'   => {
      'cm'  => lambda { |m| m * 100.0 },
      'km'  => lambda { |m| m / 1000.0 },
      'ft'  => lambda { |m| m / METERS_PER_FT },
      'in'  => lambda { |m| m / METERS_PER_FT * INCHES_PER_FT },
    },
    'L'   => {
      'gal' => lambda { |L| L * GALLONS_PER_LITER },
      'qt'  => lambda { |L| L * GALLONS_PER_LITER * QUARTS_PER_GALLON },
    },
    'kg'  => {
      'g'   => lambda { |kg| kg * 1000.0 },
      'lb'  => lambda { |kg| kg * LBS_PER_KILOGRAM },
    },
    'K'   => {
      'F'   => K2F,
      'C'   => K2C,
    },

  }

  OUTPUT_FORMAT = "%.2f"

  def convert(params)
    conversion_proc = 
      CONVERSIONS[params[:have_unit]][params[:want_unit]] || 
      get_proc_via_base_unit(params)

    return "#{params[:have_num]} #{params[:have_unit]} = " + 
      "#{sprintf( OUTPUT_FORMAT, conversion_proc[params[:have_num]] )} " + 
      "#{params[:want_unit]}"
  end

  private

=begin rdoc
If there is no direct link between the known unit and the desired 
unit, we must do a 2-stage conversion, using the base unit for that 
factor as a "Rosetta Stone".
=end
  def get_proc_via_base_unit(params)
    base_unit         = BASE_UNIT_OF[params[:factor]]
    have_to_base_proc = CONVERSIONS[params[:have_unit]][base_unit]
    base_to_want_proc = CONVERSIONS[base_unit][params[:want_unit]]
    return lambda do |have| 
      base_to_want_proc.call( have_to_base_proc.call( have ) )
    end
  end

end
