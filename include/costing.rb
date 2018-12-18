# 


# Data from Hanscom b 2011 NBC analysis
$RegionalCostFactors = Hash.new
$RegionalCostFactors  = {  "Halifax"      =>  0.95 ,
                           "Edmonton"     =>  1.12 ,
                           "Calgary"      =>  1.12 ,  # Assume same as Edmonton?
                           "Ottawa"       =>  1.00 ,
                           "Toronto"      =>  1.00 ,
                           "Quebec"       =>  1.00 ,  # Assume same as Montreal?
                           "Montreal"     =>  1.00 ,
                           "Vancouver"    =>  1.10 ,
                           "PrinceGeorge" =>  1.10 ,
                           "Kamloops"     =>  1.10 ,
                           "Regina"       =>  1.08 ,  # Same as Winnipeg?
                           "Winnipeg"     =>  1.08 ,
                           "Fredricton"   =>  1.00 ,  # Same as Quebec?
                           "Whitehorse"   =>  1.00 ,
                           "Yellowknife"  =>  1.38 ,
                           "Inuvik"       =>  1.38 , 
                           "Alert"        =>  1.38   }
                           
                           
                           
                           
module Costing 

  def Costing.ParseUnitCosts(unitCostFileName)
  
    $unitCostDataHash = Hash.new
  
    $unitCostFile = File.read(unitCostFileName)
    
    $unitCostDataHash = JSON.parse($unitCostFile)                        

    return $unitCostDataHash  
    
  end 
  
end 



