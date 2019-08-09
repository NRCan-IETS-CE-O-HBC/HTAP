


module Hourly

  # Master function to manage creation of hourly load shapes from hot2000 results
  def Hourly.analyze()

    stream_out (" Initializing hourly analysis\n")
  	
  	debug_on 
    debug_out("Tell Alex what data you need, and he will pass it in.")

    readClimateData()
    generateLoadShapes()
    modelHourlyComponent()



    debug_off()

    return

  end 

  # Function to locate, parse CWEC data? 
  def self.readClimateData()

    debug_on

    return

  end 


  # Fuction to 

  def self.generateLoadShapes()

    debug_on

    return

  end


  def self.modelHourlyComponent()

    debug_on

    return

  end



end 