#!/usr/bin/env ruby
# temperature_converter.rb
# See also GNU units at http://www.gnu.org/software/units/units.html

# Converts Metric/SI <-> US units.

=begin rdoc
Converts to and from various units of temperature. 
=end
class Temperature_Converter

  # every factor has some base unit for multi-stage conversion
  # I allow either full or shortened name as the key
  BASE_UNIT_OF = {
    'temperature' => 'K',
    'temp'        => 'K',
  }

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
    'C'   => { 'K' => C2K },
    'F'   => { 'K' => F2K },

    # The base unit requires more conversion targets
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
    base_unit         = BASE_UNIT_OF['temperature']
    have_to_base_proc = CONVERSIONS[params[:have_unit]][base_unit]
    base_to_want_proc = CONVERSIONS[base_unit][params[:want_unit]]
    return lambda do |have| 
      base_to_want_proc.call( have_to_base_proc.call( have ) )
    end
  end

end
