


module Hourly

  # Master function to manage creation of hourly load shapes from hot2000 results
  def Hourly.analyze(h2kBinResults)



      	
  	debug_on 
    debug_out("Tell Alex what data you need, and he will pass it in.\n")
    
    debug_out("Content currently parsed:\n")
    debug_out(h2kBinResults.pretty_inspect)


    climate_data=readClimateData()
    generateLoadShapes(h2kBinResults,climate_data)
    modelHourlyComponent()



    debug_off()

    return

  end 

  # Function to locate, parse CWEC data? 
  def self.readClimateData()

    debug_on

    #this requires csv class
    require 'csv'

    db_temperature=Array.new
    month=Array.new
    rh=Array.new
    global_solar_hor=Array.new
    time=Array.new
    day=Array.new

    #reads epw to epq_array and removes the first 8 rows (drop(8))
    epw_array = CSV.read("CAN_AB_EDMONTON-INTL-A_3012216_CWEC.epw").drop(8)

    for i in 0..8759
      month[i]=epw_array[i][1].to_i
      db_temperature[i]=epw_array[i][6].to_f
      rh[i]=epw_array[i][8].to_f
      global_solar_hor[i]=epw_array[i][13].to_f #horizontal global solar Wh/m^2
      time[i]=epw_array[i][3].to_i
      day[i]=epw_array[i][2].to_i
    end




    return [month,db_temperature,rh,global_solar_hor,time,day]

  end 


  # Fuction to 

  def self.generateLoadShapes(h2kBinResults,climate_data)



    debug_on
    month=climate_data[0]
    db_temperature=climate_data[1]
    rh=climate_data[2]
    global_solar_hor=climate_data[3]
    time=climate_data[4]
    day=climate_data[5]



    #Ask Alex to send over setpoint, setback, and hours of setback.
    #cooling setpoint (it's constant).
    #HDD, deep ground temperature, design heating temp, design cooling db temp, design cooling wb temp

    #schedule is hardcoded for now.
    time_unoccupied=5.0
    time_unoccupied_end=7.0
    time_unoccupied_start=(time_unoccupied_end-time_unoccupied<0 ? time_unoccupied_end-time_unoccupied+24:time_unoccupied_end-time_unoccupied)
    schedule={occ_temp_heating: 22,unocc_temp_heating: 18,occ_time_start: time_unoccupied_end,occ_time_end: time_unoccupied_start ,temp_cooling: 24}
    indoor_temp=temp_schedule(schedule,time)


    months_number={1=>"january",2=>"february",3=>"march",4=>"april",5=>"may",6=>"june",7=>"july",8=>"august",9=>"september",10=>"october",11=>"november",12=>"december"}
    norm_int_gains=Array[0.84214286,0.59142857,0.58821429,0.56035714,0.55821429,0.58607143,0.67928571,0.77785714,0.9075,0.94285714,0.97071429,1.05642857,1.06285714,1.00071429,0.96214286,0.97607143,0.99,1.16678571,1.51071429,1.70142857,1.68,1.58892857,1.27928571,1.02]#24 hour normalized int gains
    norm_dhw=Array[0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.533333,2.133333,3.2,5.866667,2.933333,0.8,0.266667,0.533333,1.333333,2.4,1.6,1.6,0.533333,0.266667,0.00,0.00,0.00]#24 hour normalized DHW draws
    months=%w[january february march april may june july august september october november december]


    average_temp_month={}
    average_solar={}
    average_indoor_temp_month={}

    start_of_month_hour={"january"=>0,"february"=>744,"march"=>1416,"april"=>2160,"may"=>2880,"june"=>3624,"july"=>4344,"august"=>5088,"september"=>5832,"october"=>6552,"november"=>7296,"december"=>8016}
    hours_per_month={"january"=>744,"february"=>672,"march"=>744,"april"=>720,"may"=>744,"june"=>720,"july"=>744,"august"=>744,"september"=>720,"october"=>744,"november"=>720,"december"=>744}

    for i in months
      average_temp_month.merge!({i=>db_temperature.slice(start_of_month_hour[i],hours_per_month[i]).average})
      average_solar.merge!({i=>global_solar_hor.slice(start_of_month_hour[i],hours_per_month[i]).average})
      average_indoor_temp_month.merge!({i=>indoor_temp.slice(start_of_month_hour[i],hours_per_month[i]).average})
    end

    #calculate mains temp at each hour
    hourly_mains_temp=mains_temp(average_temp_month)

    htap_conduction_losses=Array.new
    htap_solar_gains=Array.new
    htap_internal_gains=Array.new
    htap_elec=Array.new
    htap_dhw=Array.new
    for i in months
      htap_conduction_losses[months_number.key(i)-1]=h2kBinResults["monthly"]["energy_profile"]["energy_loadGJ"][i].to_f*1000000000.0/(hours_per_month[i]*3600.0)
      htap_solar_gains[months_number.key(i)-1]=h2kBinResults["monthly"]["energy_profile"]["solar_gainsGJ"][i].to_f*1000000000.0/(hours_per_month[i]*3600.0)
      htap_internal_gains[months_number.key(i)-1]=h2kBinResults["monthly"]["energy_profile"]["internal_gainsGJ"][i].to_f*1000000000.0/(hours_per_month[i]*3600.0)
     # htap_elec[months_number.key(i)-1]=(h2kBinResults["monthly"]["energy_profile"]["lights_appliancesGJ"][i].to_f*1000000000.0+h2kBinResults["monthly"]["energy_profile"]["hrv_fansGJ"][i].to_f*1000000000.0+h2kBinResults["monthly"]["energy_profile"]["acGJ"][i].to_f*1000000000.0/(hours_per_month[i]*3600.0)
     # htap_dhw[months_number.key(i)-1]=h2kBinResults["monthly"]["energy_profile"]["dhwGJ"][i].to_f*1000000000.0/(hours_per_month[i]*3600.0)
    end

    return

  end


  def self.modelHourlyComponent()

    debug_on

    return

  end



end

class Array
  def sum
    map(&:to_f).reduce(&:+)
  end
end

class Array
  def average
    sum/size
  end
end

class Numeric
  def to_radians
    self * Math::PI / 180
  end
end
#{occ_temp_heating: 22,unocc_temp_heating: 18,occ_time_start: time_unoccupied_end,occ_time_end: time_unoccupied_start ,temp_cooling: 25}
def temp_schedule(schedule,time)
  #this function takes parameters and outputs hourly indoor temperatures. It includes nightime setbacks.
  indoor_temp=Array.new

  time.map!(&:to_f)

  for i in 0..8759
    if schedule[:occ_time_start]<=schedule[:occ_time_end]
      if time[i]>schedule[:occ_time_start] && time[i]<=schedule[:occ_time_end]
          indoor_temp[i]=schedule[:occ_temp_heating]
      else
          indoor_temp[i]=schedule[:unocc_temp_heating]
      end
    else
      if time[i]>schedule[:occ_time_start] || time[i]<=schedule[:occ_time_end]
        indoor_temp[i]=schedule[:occ_temp_heating]
      else
        indoor_temp[i]=schedule[:unocc_temp_heating]
      end
    end
  end

  return indoor_temp

end

def mains_temp(average_temp_month)
  dt=(average_temp_month.values.max-average_temp_month.values.min)*(9.0/5.0)
  average_year_temp=(average_temp_month.values.average)*(9.0/5.0)+32.0
  hourly_mains_temp=Array.new
  for i in 0..8759

    day_of_year=(i+1)/24.0

    hourly_mains_temp[i]=((average_year_temp+6)+(0.4+0.01*(average_year_temp-44))*(dt/2)*Math.sin((0.986*((day_of_year)-15-(35-1*(average_year_temp-44)))-90).to_radians)-32.0)*5.0/9.0
  end
  return hourly_mains_temp
end