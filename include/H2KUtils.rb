# ==========================================
# H2KUtils.rb: functions used 
# to query, manipulate hot2000 files and 
# the h2k environment. 
# ==========================================


module H2KUtils

  def H2KUtils.getBuilderName(elements)

    $MyBuilderName = elements["HouseFile/ProgramInformation/File/BuilderName"].text
    if $MyBuilderName !=nil
      $MyBuilderName.gsub!(/\s*/, '')    # Removes mid-line white space
      $MyBuilderName.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end

    return $MyBuilderName
  end 
  
  def H2KUtils.getHouseType(elements)
  
    $MyHouseType = elements["HouseFile/House/Specifications/HouseType/English"].text
    if $MyHouseType !=nil
      $MyHouseType.gsub!(/\s*/, '')    # Removes mid-line white space
      $MyHouseType.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end
    
    return $MyHouseType 
  
  end 
  
  def H2KUtils.getStories(elements)
    $MyHouseStoreys = elements["HouseFile/House/Specifications/Storeys/English"].text
    if $MyHouseStoreys!= nil
      $MyHouseStoreys.gsub!(/\s*/, '')    # Removes mid-line white space
      $MyHouseStoreys.gsub!(',', '-')    # Replace ',' with '-'. Necessary for CSV reporting
    end
    
    return $MyHouseStories
    
  end 

  
end 