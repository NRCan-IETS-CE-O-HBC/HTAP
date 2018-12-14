


module HTAPData

  def HTAPData.parse_json_options_file(filename)
    # New parsing method for json format 
    stream_out("\n\n Reading available options (#{filename})...")
    debug_out(" --------------JSON options parsing ------------ ")
    fOPTIONS = File.new(filename, "r") 
    
    $gOptions2 = Hash.new
    
    if fOPTIONS == nil then
       fatalerror(" Could not read #{filename}.\n")
    end
    
    
    $OptionsContents = fOPTIONS.read
    fOPTIONS.close 
    $JSONRawOptions = JSON.parse($OptionsContents)
      
    for attribute in $JSONRawOptions.keys()
  
  
      
      structure = $JSONRawOptions[attribute]["structure"]
      schema = $JSONRawOptions[attribute]["schema"].to_s
      
      debug_out "\n ====================================="
      debug_out " Attribute: #{attribute} "    
      debug_out " structure: #{structure} " 
      
      $StopOnError = $JSONRawOptions[attribute]["stop-on-error"]
      if ( $StopOnError ) then 
        errFlag = 1
      else 
        errFlag = 0 
      end   
      
      
      #puts "> #{attribute} (#{structure}) \n" 
      $gOptions2[attribute] = Hash.new
      $gOptions2[attribute] = { "type" => "internal" ,
                                "default" => Hash.new , 
                                "stop-on-error" => errFlag  , 
                                "tags" => Hash.new   ,
                                "options" => Hash.new      } 
                                
  
                    
                    
      if ( structure.to_s =~ /tree/) 
        tagindex = 0  
        debug_out " SCHEMA : " 
        for schemaEntry in $JSONRawOptions[attribute]["h2kSchema"]                          
          tagindex = tagindex + 1
          $gOptions2[attribute]["tags"][tagindex] = schemaEntry
          
          debug_out "          #{tagindex} - #{schemaEntry}   "
          
        end 
        
      else 
        $gOptions2[attribute]["tags"][1] = "<NotARealTag>"
      end 
      
      if ( ! $JSONRawOptions[attribute]["default"].nil? ) then 
         default = $JSONRawOptions[attribute]["default"]
  
        $gOptions2[attribute]["default"] = { "defined" => 1, 
                                             "value"   => default } 
      
      end 
      
      for optionEntry in $JSONRawOptions[attribute]["options"].keys
        debug_out " "
        debug_out " ........... OPTION: #{optionEntry} ............ "       
          
        $gOptions2[attribute]["options"][optionEntry] = Hash.new
        
        # Import legacy costs (to be replaced.)
        
  
        
        if ( $JSONRawOptions[attribute]["costed"]  &&
               ! $JSONRawOptions[attribute]["options"][optionEntry]["costs"].nil? &&
               ! $JSONRawOptions[attribute]["options"][optionEntry]["costs"]["legacy"].nil?  &&
               ! $JSONRawOptions[attribute]["options"][optionEntry]["costs"]["legacy"]["cost-type"].nil?    ) 
          
          costType = $JSONRawOptions[attribute]["options"][optionEntry]["costs"]["legacy"]["cost-type"]
          costVal  = $JSONRawOptions[attribute]["options"][optionEntry]["costs"]["legacy"]["cost"]
        else 
          costType = "total"
          costVal  = 0 
        end 
       
        $gOptions2[attribute]["options"][optionEntry] = { "values" => Hash.new,
                                                          "cost-type" => costType, # legacy compatability - to be removed 
                                                          "cost"   => "#{costVal.to_s}"        }   # legacy compatability - to be removed 
          
          
          
        # Currently only base supported. 
        if ( structure.to_s =~ /tree/) 
          $values = $JSONRawOptions[attribute]["options"][optionEntry]["h2kMap"] 
          debug_out" has h2kMap entries - " 
          debug_out"      #{$values["base"]} \n\n"
          
  
          valuesWithConditions = Hash.new
          
          for tagname,value in $values["base"]
            
            tagindex = $JSONRawOptions[attribute]["h2kSchema"].index(tagname) + 1
            if ( ! tagindex.nil? ) 
              valuesWithConditions[tagindex.to_s] = Hash.new
              valuesWithConditions[tagindex.to_s] = { "conditions" => Hash.new } 
              valuesWithConditions[tagindex.to_s]["conditions"] = { "all" => value } 
            else 
              fatalerror("For #{attribute}: tag #{tagname} does not match schema.\n")
            end 
          end 
            
          $gOptions2[attribute]["options"][optionEntry]["values"] = valuesWithConditions
                        
        else  
          $values = $JSONRawOptions[attribute]["options"][optionEntry]
          debug_out " has value - #{$values}" 
          $gOptions2[attribute]["options"][optionEntry]["values"][1.to_s] = { "conditions" => 
                                                                                 { "all" => $values }
                                                                            }
          
        end 
        
      end   
       
  
    end 
    
    stream_out("done.\n\n") 
    
    return $gOptions2
    
  end 
  
end 































  def compare_json(json1, json2)
    
    
    
    # return false if classes mismatch or don't match our allowed types
    unless((json1.class == json2.class) && ( json1.is_a?(String) || 
                                             json1.is_a?(Hash)   || 
                                             json1.is_a?(Array)  || 
                                             json1.is_a?(Float)  || 
                                             json1.is_a?(Integer)   ) 
           ) 
      return false
    end   
    
    # initializing result var in the desired scope
    result = false
    
    debug_out "Comparing JSON \n " 
    
    
    
    # Parse objects to JSON if Strings
    json1,json2 = [json1,json2].map! do |json|
      json.is_a?(String) || json1.is_a?(Float)  ? JSON.parse(json) : json
    end
    
     # If an array, loop through each subarray/hash within the array and recursively call self with these objects for traversal
    if(json1.is_a?(Array))
      json1.each_with_index do |obj, index|
        json1_obj, json2_obj = obj, json2[index]
        result = compare_json(json1_obj, json2_obj)
        # End loop once a false match has been found
        break unless result
      end
    end 
    
    
    
    
    debug_out "comp done?"
    
    
    
    
    
    
  end   
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    