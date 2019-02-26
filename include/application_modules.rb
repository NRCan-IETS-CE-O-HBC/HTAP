
# file for holding functions related to specific applications - e.g. BC step code


module BCStepCode

# Technical Bulletin B18-08 describes the changes to the BC Energy Step Code effective December 10, 2018
#  / https://www2.gov.bc.ca/assets/gov/farming-natural-resources-and-industry/construction-industry/building-codes-and-standards/bulletins/b18_08_revision1_to_bcbc_stepcode.pdf
#

BC_STEP_TEDI_MAX = {
  "Zone 4" => {
    "Step_1" => nil,
    "Step_2" => 35.0,
    "Step_3" => 30.0,
    "Step_4" => 25.0,
    "Step_5" => 15.0
  },
  "Zone 5" => {
    "Step_1" => nil,
    "Step_2" => 45.0,
    "Step_3" => 40.0,
    "Step_4" => 30.0,
    "Step_5" => 20.0
  },
  "Zone 6" => {
    "Step_1" => nil,
    "Step_2" => 60.0,
    "Step_3" => 50.0,
    "Step_4" => 40.0,
    "Step_5" => 25.0
  },
  "Zone 7a" => {
    "Step_1" => nil,
    "Step_2" => 80.0,
    "Step_3" => 70.0,
    "Step_4" => 55.0,
    "Step_5" => 35.0
  },
  "Zone 7b" => {
    "Step_1" => nil,
    "Step_2" => 100.0,
    "Step_3" => 90.0,
    "Step_4" => 65.0,
    "Step_5" => 50.0
  },
  "Zone 8" => {
    "Step_1" => nil,
    "Step_2" => 120.0,
    "Step_3" => 105.0,
    "Step_4" => 80.0,
    "Step_5" => 60.0
  },
}


  def BCStepCode.getStepByTEDI(climateZone,tedi)

    debug_off
    debug_out "Inputs: `#{climateZone}`, `#{tedi}`\n"
    if ( BC_STEP_TEDI_MAX[climateZone].nil? ) then
      help_out("byTopic","cliamte_Zone names")
      fatalerror ("Unknown climate zone #{climateZone}")
    end

    returnStep = "Step_1"
    BC_STEP_TEDI_MAX[climateZone].each do | stepname, tediReq |
      next if ( tediReq.nil? )
      break if ( tediReq < tedi )
      returnStep = stepname
    end

    debug_out "Returing #{returnStep}"

    return returnStep.gsub(/_/," ")

  end


end
