


module Hourly

  # Master function to manage creation of hourly load shapes from hot2000 results
  def Hourly.analyze(h2kBinResults)
    require 'pp'
    debug_on
    debug_out "input\n #{h2kBinResults.pretty_inspect}"
    climate_data=readClimateData()
    generateLoadShapes(h2kBinResults,climate_data)
    modelHourlyComponent()

    return

  end 

  # Function to locate, parse CWEC data? 
  def self.readClimateData()

    #debug_on
    require 'csv'
    require 'open-uri'
    require_relative 'constants'
    db_temperature=Array.new
    month=Array.new
    rh=Array.new
    global_solar_hor=Array.new
    time=Array.new
    day=Array.new
    wind_speed=Array.new
    
    
    
    epwFile = $epwLocaleHash["#{$gRunLocale}"].split('/')[2]
    
    if (File.file?("C:\/HTAP\/weatherfiles\/#{epwFile}"))
      epwFilePath = "C:\/HTAP\/weatherfiles\/#{epwFile}"
    else
      dataURI = $epwRemoteServer+$epwLocaleHash["#{$gRunLocale}"]
      begin
        epwFilePath = open($epwRemoteServer+$epwLocaleHash["#{$gRunLocale}"])
      rescue 
        fatal_error ("Could not open climate data at #{dataURI}\n")
      end 
    end
    
      #epwFilePath="C:\/HTAP\/testing\/hourly\/HTAP-sim-3\/CAN_AB_EDMONTON-INTL-A_3012216_CWEC.epw" #temporary for testing. REMOVE
    
    
    #reads epw to epq_array and removes the first 8 rows (drop(8))
    epw_array = CSV.read(epwFilePath).drop(8)
    
    
    for i in 0..8759
      month[i]=epw_array[i][1].to_i
      db_temperature[i]=epw_array[i][6].to_f
      rh[i]=epw_array[i][8].to_f
      global_solar_hor[i]=epw_array[i][13].to_f #direct global solar Wh/m^2
      time[i]=epw_array[i][3].to_i
      day[i]=epw_array[i][2].to_i
      wind_speed[i]=epw_array[i][21].to_f #m/s
    
    end
    
    file=File.open(epwFilePath,"r")
    
    
    4.times {file.gets} # get to the fourth line on CWEC file
    ground_array=$_.chomp
    ground_array=ground_array.split(",").reject(&:empty?)
    amount_depths=ground_array[1].to_i
    ground_hours=[372,1080,1788,2520,3252,3984,4716,5460,6192,6924,7656,8388]
    ground_temperatures=Array.new(amount_depths){Array.new(12)}
    ground_parameters=Array.new(amount_depths){Array.new(3)}
    ground_temp=Array.new(amount_depths){Array.new(8760)}
    depth=Array.new
    
    for i in 0..amount_depths-1
      depth[i]=ground_array[i*13+2]
    
      for ii in 0..11
        ground_temperatures[i][ii]=ground_array[3+(13*i)+(ii)].to_f
      end
      ground_parameters[i][0]=ground_temperatures[i].average
      ground_parameters[i][1]=(ground_temperatures[i].max-ground_temperatures[i].min)/2.0
    
      y1=ground_hours[ground_temperatures[i].bsearch_index{|x| x>=ground_parameters[i][0]}-1]
      y2=ground_hours[ground_temperatures[i].bsearch_index{|x| x>=ground_parameters[i][0]}]
      x2=ground_temperatures[i].bsearch{|x| x>=ground_parameters[i][0]}
      x1=ground_temperatures[i][ground_temperatures[i].bsearch_index{|x| x>=ground_parameters[i][0]}-1]
      x=ground_parameters[i][0]
      ground_parameters[i][2]=y1+(y2-y1)*(x-x1)/(x2-x1)
    
      for iii in 0..8759
        ground_temp[i][iii]=ground_parameters[i][0]+ground_parameters[i][1]*Math.sin((iii.to_f-ground_parameters[i][2])*2*Math::PI/8760)
      end
    
    end
    
    file.close
    return [month,db_temperature,rh,global_solar_hor,time,day,wind_speed,ground_temp,depth]
    

  end 


  # Fuction to 

  def self.generateLoadShapes(h2kBinResults,climate_data)
      
    require 'pp' 
    #debug_on
    month=climate_data[0]
    db_temperature=climate_data[1]
    rh=climate_data[2]
    global_solar_hor=climate_data[3]
    time=climate_data[4]
    day=climate_data[5]
    wind_speed=climate_data[6]
    ground=climate_data[7]
    depth=climate_data[8]
    
    
    #schedule is hardcoded for now.

   
    time_unoccupied=h2kBinResults["daily"]["setpoint_temperature"]["Nightime_Setback_Duration_hr"]
   
    pp time_unoccupied 
    time_unoccupied_end=7.0
    time_unoccupied_start=(time_unoccupied_end-time_unoccupied<0 ? time_unoccupied_end-time_unoccupied+24 : time_unoccupied_end-time_unoccupied)
    schedule={occ_temp_heating: h2kBinResults["daily"]["setpoint_temperature"]["Daytime_Setpoint_degC"] ,unocc_temp_heating: h2kBinResults["daily"]["setpoint_temperature"]["Nightime_Setpoint_degC"] ,occ_time_start: time_unoccupied_end,occ_time_end: time_unoccupied_start ,temp_cooling: h2kBinResults["daily"]["setpoint_temperature"]["Cooling_Setpoint_degC"] }
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
    
    
    indoor_design_temp=h2kBinResults["daily"]["setpoint_temperature"]["Indoor_Design_Temp_Heat_degC"]
    ua_val=h2kBinResults["avgOthPeakHeatingLoadW"]/(indoor_design_temp-h2kBinResults["annual"]["design_Temp"]["heating_C"])
    
    for i in months
      average_temp_month.merge!({i=>db_temperature.slice(start_of_month_hour[i],hours_per_month[i]).average})
      average_solar.merge!({i=>global_solar_hor.slice(start_of_month_hour[i],hours_per_month[i]).average})
      average_indoor_temp_month.merge!({i=>indoor_temp.slice(start_of_month_hour[i],hours_per_month[i]).average})
    end
    
    
    
    debug_on
    debug_out ("#{h2kBinResults["monthly"]["cooling"].pretty_inspect}")

    htap_conduction_losses=Array.new
    htap_solar_gains=Array.new
    htap_internal_gains=Array.new
    htap_cooling=Array.new
    htap_heating=Array.new
    htap_elec_plug=Array.new
    htap_dhw=Array.new
    for i in months
      htap_conduction_losses[months_number.key(i)-1]=h2kBinResults["monthly"]["energy_profile"]["energy_loadGJ"][i].to_f*1000000000.0/(hours_per_month[i]*3600.0)
      htap_solar_gains[months_number.key(i)-1]=h2kBinResults["monthly"]["energy_profile"]["solar_gainsGJ"][i].to_f*1000000000.0/(hours_per_month[i]*3600.0)
      htap_internal_gains[months_number.key(i)-1]=h2kBinResults["monthly"]["energy_profile"]["internal_gainsGJ"][i].to_f*1000000000.0/(hours_per_month[i]*3600.0)
      htap_heating[months_number.key(i)-1]=h2kBinResults["monthly"]["energy_profile"]["aux_energy_GJ"][i].to_f*1000000000.0/(hours_per_month[i]*3600.0)
    
      
      htap_elec_plug[months_number.key(i)-1]=(h2kBinResults["monthly"]["energy"]["lights_appliances_GJ"][i].to_f*1000000000.0)/(hours_per_month[i]*3600.0)
     htap_dhw[months_number.key(i)-1]=h2kBinResults["monthly"]["energy"]["DHW_heating_primary_GJ"][i].to_f
     if ($hourlyFoundACData) then 
       htap_cooling[months_number.key(i)-1] = h2kBinResults["monthly"]["cooling"]["total_loadGJ"][i].to_f*1000000000.0/(hours_per_month[i]*3600.0)
     else 
       htap_cooling[months_number.key(i)-1] = 0.0 
     end 
    end
    
    
    #calculate mains temp at each hour
    hourly_mains_temp=mains_temp(average_temp_month,h2kBinResults["annual"]["weather"]["Annual_HDD_18C"],h2kBinResults["annual"]["weather"]["Avg_Deep_Ground_Temp_C"],months,months_number)
    daily_DHW_consumption=h2kBinResults["annual"]["DHW_heating"]["Daily_DHW_Consumption_L/day"]
    seasonal_efficiency_dhw=h2kBinResults["annual"]["DHW_heating"]["Primary_DHW_Efficiency"]/100.0
    calc_hourly_DHW_heat_water=Array.new
    hourly_DHW_consumption=Array.new
    for i in 0..8759
      hourly_DHW_consumption[i]=daily_DHW_consumption*norm_dhw[time[i]-1]/24.0
      calc_hourly_DHW_heat_water[i]=hourly_DHW_consumption[i]*4187*(55.0-hourly_mains_temp[i])/(3600.0)
      calc_hourly_DHW_heat_water[i]=(3.0*(60.0-hourly_mains_temp[i])/(55.0-hourly_mains_temp[i])+1.0)*0.25*calc_hourly_DHW_heat_water[i] #weird H2K thing to account that seasonal efficiency is calculated at 60C and there are primary and secondary systems with 3:1 split of heat.
    end
    
    monthly_dhw_water_heat=Array.new
    monthly_dhw_losses=Array.new
    monthly_dhw_losses_W=Array.new
    monthly_dhw_ratio=Array.new
    for i in months
      monthly_dhw_water_heat[months_number.key(i)-1]=calc_hourly_DHW_heat_water.slice(start_of_month_hour[i],hours_per_month[i]).sum*3600.0/(1.0E9) #in GJ, heat going to water, no losses
      monthly_dhw_losses[months_number.key(i)-1]=htap_dhw[months_number.key(i)-1]*seasonal_efficiency_dhw-monthly_dhw_water_heat[months_number.key(i)-1] #in GJ, dhw losses, monthly
      monthly_dhw_losses_W[months_number.key(i)-1]=monthly_dhw_losses[months_number.key(i)-1]*(1.0E9)/(hours_per_month[i]*3600.0)
      #monthly_dhw_ratio[months_number.key(i)-1]=monthly_dhw_losses[months_number.key(i)-1]/monthly_dhw_water_heat[months_number.key(i)-1]
    end
    
    #cooling internal gains
    internal_gains_cooling_htap=Array.new
    for i in 0..11
      internal_gains_cooling_htap[i]=[1000.0*h2kBinResults["daily"]["baseloads"]["interior_lighting_kWh/day"]/24.0+1000.0*h2kBinResults["daily"]["baseloads"]["interior_appliances_kWh/day"]/24.0+1000.0*h2kBinResults["daily"]["baseloads"]["interior_other_kWh/day"]/24.0+1000.0*h2kBinResults["daily"]["gains_from_occupants_kWh/day"]/24.0-htap_internal_gains[i],0].max
    end
    
    #cooling envelope gains
    envelope_gains_cooling_htap=Array.new
    for i in 1..12
      if ($hourlyFoundACData) then 
        envelope_gains_cooling_htap[i-1]=-ua_val*(schedule[:temp_cooling]-average_temp_month[months_number[i]])
      else 
        envelope_gains_cooling_htap[i-1]=0
      end  
    end
    
    #cooling solar gains
    # = Total cooling load - internal gain - Envelope gains
    solar_load_cooling_htap=Array.new
    for i in 0..11
      if ($hourlyFoundACData) then 

        solar_load_cooling_htap[i]=htap_cooling[i]-internal_gains_cooling_htap[i]-envelope_gains_cooling_htap[i]

      else 
        solar_load_cooling_htap[i]= 0

      end 
    end
    
    hourly_conduction_losses=Array.new
    hourly_solar_gains=Array.new
    hourly_internal_gains=Array.new
    hourly_total_heating=Array.new
    hourly_electrical_demand_plug=Array.new
    hourly_dhw_demand=Array.new
    hourly_solar_gains_cooling=Array.new
    hourly_conduction_losses_cooling=Array.new
    hourly_internal_gains_cooling=Array.new
    hourly_total_cooling=Array.new
    hourly_ventilation=Array.new
    timestep=Array.new
    indoor_temp_cooling=Array.new
    #calculate hourly load profiles
    for i in 0..8759
      indoor_temp_cooling[i]=schedule[:temp_cooling]
      hourly_conduction_losses[i]=htap_conduction_losses[month[i]-1].to_f*(indoor_temp[i]-db_temperature[i])/(average_indoor_temp_month[months_number[month[i]]]-average_temp_month[months_number[month[i]]])
      hourly_solar_gains[i]=htap_solar_gains[month[i]-1].to_f*(global_solar_hor[i])/(average_solar[months_number[month[i]]]+0.0000000001)
      hourly_internal_gains[i]=htap_internal_gains[month[i]-1].to_f*norm_int_gains[time[i]-1].to_f
      hourly_total_heating[i]=hourly_conduction_losses[i]-hourly_solar_gains[i]-hourly_internal_gains[i]
      hourly_electrical_demand_plug[i]=htap_elec_plug[month[i]-1].to_f*norm_int_gains[time[i]-1].to_f
      #hourly_dhw_demand[i]=htap_dhw[month[i]-1].to_f*norm_dhw[time[i]-1].to_f
      if ( $hourlyFoundACData) then 
      hourly_solar_gains_cooling[i]=solar_load_cooling_htap[month[i]-1].to_f*(global_solar_hor[i])/(average_solar[months_number[month[i]]]+0.0000000001)
      hourly_conduction_losses_cooling[i]=envelope_gains_cooling_htap[month[i]-1].to_f*(indoor_temp_cooling[i]-db_temperature[i])/(schedule[:temp_cooling]-average_temp_month[months_number[month[i]]])
      hourly_internal_gains_cooling[i]=internal_gains_cooling_htap[month[i]-1].to_f*norm_int_gains[time[i]-1].to_f
      hourly_total_cooling[i]=hourly_solar_gains_cooling[i]+hourly_conduction_losses_cooling[i]+hourly_internal_gains_cooling[i]
      else 
        hourly_solar_gains_cooling[i]       = 0.0
        hourly_conduction_losses_cooling[i] = 0.0
        hourly_internal_gains_cooling[i]    = 0.0  
        hourly_total_cooling[i]             = 0.0
      end 
      hourly_ventilation[i]=h2kBinResults["daily"]["ventilation"]["F326_Required_Flow_Rate_L/s"]/3.0 #divided by three to provide 8 hours of ventilation per day
      timestep[i]=i
    
    end
    
    floor_area=(h2kBinResults["annual"]["volume"]["house_volume_m^3"]-h2kBinResults["annual"]["volume"]["basement_volume_m^3"])/2.5
    eff_mass_f=h2kBinResults["annual"]["mass"]["effective_mass_fraction"]
    
    if  h2kBinResults["annual"]["mass"]["thermal_mass_level"] =~ /A/i
      mcp_per_area=0.06 #MJ/K/m^2
    elsif  h2kBinResults["annual"]["mass"]["thermal_mass_level"] =~ /B/i
      mcp_per_area=0.153 #MJ/K/m^2
    elsif h2kBinResults["annual"]["mass"]["thermal_mass_level"] =~ /C/i
      mcp_per_area=0.415 #MJ/K/m^2
    elsif h2kBinResults["annual"]["mass"]["thermal_mass_level"] =~ /D/i
      mcp_per_area=0.810 #MJ/K/m^2
    else
      mcp_per_area=0.0 #MJ/K/m^2
    end
    
    debug_on
    
    # Model with Mass - heating (lumped capacitance)
    t_bld=Array.new
    t_bld_cooling=Array.new
    mcp=mcp_per_area*1000000.0*floor_area #220.0 is estimate of floor area. 0.06 is value found in H2K manual
    dt=3600.0
    htc=2.0 #convective heat transfer coefficient for lump capacitance model. 2 W/(m^2 K) seems reasonable average for buildings. It generally ranges between ~ 1.5 - 4.5 depending on air flow regime.
    lump_capacitance_area= floor_area+h2kBinResults["annual"]["area"]["ceiling_m^2"]+h2kBinResults["annual"]["area"]["walls_net_m^2"]# this is total surface area
    hourly_heating_mass=Array.new
    hourly_cooling_mass=Array.new
    #thermal mass calculations
    for i in 0..8759
    
      if i==0
        t_bld[i]=5.85
        t_bld_cooling[i]=22.0
        hourly_heating_mass[i]=hourly_total_heating[i]
        hourly_cooling_mass[i]= ($hourlyFoundACData ? hourly_total_cooling[i] : 0 )
      else
        t_air=indoor_temp[i]
        t_bld[i]=(t_air*lump_capacitance_area*htc-hourly_total_heating[i]+(mcp/(dt))*t_bld[i-1])/(mcp/(dt)+lump_capacitance_area*htc)
        hourly_heating_mass[i]=lump_capacitance_area*htc*(t_air-t_bld[i])
        if ($hourlyFoundACData) then 
          t_air_cooling=indoor_temp_cooling[i]
          t_bld_cooling[i]=(t_air_cooling*lump_capacitance_area*htc+hourly_total_cooling[i]+(mcp/(dt))*t_bld_cooling[i-1])/(mcp/(dt)+lump_capacitance_area*htc)
          hourly_cooling_mass[i]=lump_capacitance_area*htc*(t_bld_cooling[i]-t_air_cooling)
        else 
           t_air_cooling= 0.0
           t_bld_cooling[i]= 0.0 
           hourly_cooling_mass[i]= 0.0 
        end 
      end
    
    
    end
    
    
    
    
    
    hourly_monthly_tot_heat=Hash.new
    hourly_monthly_pos_heat=Hash.new
    hourly_heat_ratio=Hash.new
    
    hourly_monthly_tot_cool=Hash.new
    hourly_monthly_pos_cool=Hash.new
    hourly_cool_ratio=Hash.new
    
    for i in months
      hourly_monthly_tot_heat[i]=hourly_heating_mass.slice(start_of_month_hour[i],hours_per_month[i]).sum
      hourly_monthly_pos_heat[i]=hourly_heating_mass.slice(start_of_month_hour[i],hours_per_month[i]).select(&:positive?).sum
      hourly_heat_ratio[i]=hourly_monthly_tot_heat[i].to_f/(hourly_monthly_pos_heat[i].to_f+0.00000000001)
      #if ($hourlyFoundACData) then 
        hourly_monthly_tot_cool[i]=hourly_cooling_mass.slice(start_of_month_hour[i],hours_per_month[i]).sum
        hourly_monthly_pos_cool[i]=hourly_cooling_mass.slice(start_of_month_hour[i],hours_per_month[i]).select(&:positive?).sum
        hourly_cool_ratio[i]=hourly_monthly_tot_cool[i]/(hourly_monthly_pos_cool[i].to_f+0.000000001)
      #else 
      #  hourly_monthly_tot_cool[i] = 0.0
      #  hourly_monthly_pos_cool[i] = 0.0
      #  hourly_cool_ratio[i]       = 0.0
      #end
    end
    
    hourly_total_heating_hash=Hash.new
    hourly_total_cooling_hash=Hash.new
    hourly_heat_ratio_2=Hash.new
    hourly_cool_ratio_2=Hash.new
    for i in months
      hourly_total_heating_hash[i]=hourly_heating_mass.slice(start_of_month_hour[i],hours_per_month[i]).map{|n| [n*hourly_heat_ratio[i],0].max}
      hourly_heat_ratio_2[i]=htap_heating[months_number.key(i)-1]*hours_per_month[i]/(hourly_total_heating_hash[i].sum+0.00000000001) #additional adjustment ratio to get same monthly loads as HOT2000
      hourly_total_heating_hash[i]=hourly_total_heating_hash[i].slice(0,hours_per_month[i]).map{|n| [n*hourly_heat_ratio_2[i],0].max}
      #if ($hourlyFoundACData) then 
        hourly_total_cooling_hash[i]=hourly_cooling_mass.slice(start_of_month_hour[i],hours_per_month[i]).map{|n| [n*hourly_cool_ratio[i],0].max} #apply first ratio to only have positive cooling value
        hourly_cool_ratio_2[i]=htap_cooling[months_number.key(i)-1]*hours_per_month[i]/(hourly_total_cooling_hash[i].sum+0.00000000001) #additional adjustment ratio to get same monthly loads as HOT2000
        hourly_total_cooling_hash[i]=hourly_total_cooling_hash[i].slice(0,hours_per_month[i]).map{|n| [n*hourly_cool_ratio_2[i],0].max}
      #else
      #   hourly_total_cooling_hash[i] = 0.0
      #   hourly_cool_ratio_2[i]       = 0.0
      #   hourly_total_cooling_hash[i] = 0.0
      #end
    end
    hourly_total_heating_mod=Array.new
    hourly_total_cooling_mod=Array.new
    for i in months
      hourly_total_heating_mod=[hourly_total_heating_mod,hourly_total_heating_hash[i]].reduce([], :concat)
      hourly_total_cooling_mod=[hourly_total_cooling_mod,hourly_total_cooling_hash[i]].reduce([], :concat)
    end
    peakHeating=Array.new
    peakCooling=Array.new
    peakHeating[0]=h2kBinResults["avgOthPeakHeatingLoadW"]
    peakCooling[0]=h2kBinResults["avgOthPeakCoolingLoadW"]
    time=time.map { |i| i - 1 } #remove 1 from all elements of array
    #output to csv
    #Add headers to arrays
    timestep.unshift("timestep (hour)")
    time.unshift("hour")
    day.unshift("day")
    month.unshift("month")
    indoor_temp.unshift("Indoor Temperature - heating mode (degC)")
    indoor_temp_cooling.unshift("Indoor Temperature - cooling mode (degC)")
    hourly_conduction_losses.unshift("Envelope Losses (W)")
    hourly_solar_gains.unshift("Solar Gains (W)")
    hourly_internal_gains.unshift("Internal Gains (W)")
    hourly_total_heating_mod.unshift("Total Heating Load (W)")
    
    hourly_DHW_consumption.unshift("DHW Consumption (L)")
    hourly_mains_temp.unshift("Mains Water Temperature (degC)")
    
    hourly_solar_gains_cooling.unshift("Cooling Solar (W)")
    hourly_conduction_losses_cooling.unshift("Cooling Envelope (W)")
    hourly_internal_gains_cooling.unshift("Cooling Gains (W)")
    hourly_total_cooling_mod.unshift("Total Cooling Load (W)")
  
    hourly_electrical_demand_plug.unshift("Plug Load (W)")
    hourly_ventilation.unshift("Ventilation Rate (L/s)")
    
    db_temperature.unshift("Ambient Temperature (degC)")
    rh.unshift("Ambient RH (%)")
    global_solar_hor.unshift("Global Horizontal Radiation (W/m^2)")
    peakHeating.unshift("Design Heating Load (W)")
    peakCooling.unshift("Design Cooling Load (W)")
    wind_speed.unshift("Wind Speed (m/s)")
    
    
    #hourly_dhw_demand.unshift("DHW demand (W)")
    #hourly_electrical_demand.unshift("Electrical Demand (W)")
    
    #monthly_mains_temp.each {|temp| print temp,"\n"}
    
    
    for i in 0..depth.length-1
      ground[i]=ground[i].unshift("Ground Temperature at #{'%.2f' % depth[i]} m depth (degC)")
    end
    printarray3=ground
    printarray=[timestep,month,day,time,hourly_electrical_demand_plug,hourly_total_heating_mod,hourly_total_cooling_mod,hourly_ventilation,hourly_DHW_consumption,hourly_mains_temp,indoor_temp,indoor_temp_cooling,db_temperature,rh,global_solar_hor,wind_speed].concat(printarray3).transpose
    
    printarray2=[peakHeating,peakCooling].transpose
    
    h2kfilename="#{$h2kFileName}"#.delete_suffix('.h2k')
    CSV.open("#{$gMasterPath}\\"+"#{$gRunLocale}"+"_"+h2kfilename+".csv", "w") do |f|
      printarray.each do |x|
        f << x
      end
    
      f << ["\n"]
      printarray2.each do |x|
        f << x
      end
    end
     
         return

  end


  def self.modelHourlyComponent()

    #debug_on

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



class ::Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    self.merge(second.to_h, &merger)
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

def mains_temp(average_temp_month,annual_hdd,deep_ground_temp,months,months_number)


  #Method in HOT2000 as per Patrice Pinel email (he looked in code)
  if deep_ground_temp < 5.0
    iofs = 6.0
  elsif deep_ground_temp < 15.0
    iofs = 7.0
  else
    iofs = 8.0
  end


  hourly_mains_temp=Array.new



  ca1=0.0
  ca2=0.0
  for i in months
    x0=average_temp_month[i]
    ca1=ca1+x0*Math.sin((months_number.key(i)-0.5)*Math::PI/6.0)
    ca2=ca2+x0*Math.cos((months_number.key(i)-0.5)*Math::PI/6.0)
  end
  dt=-Math.sqrt(ca1**2.0+ca2**2.0)/6.0 #ambient air annual amplitude - Not sure how this works, but that's what is done in H2K - so.. consistency
  amplitude=dt+0.00197*annual_hdd-7.8747
  mod_amplitude=(0.2+[0,[0.6,0.04*(deep_ground_temp-5.0)].min].max)*(amplitude.abs)
  for i in 0..8759
    hourly_mains_temp[i]=[4.3,deep_ground_temp+3+mod_amplitude*(Math.sin(Math::PI/6*((i/(24.0*365.0))*12.0+0.5+iofs)))].max
    #(i/(24*365))*12+0.5 converts hours of year i to months, where month 1 is roughly day 15, month 2 is roughly day 45
  end


  return hourly_mains_temp
end