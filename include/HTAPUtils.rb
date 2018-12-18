


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
   
  # Parse configuration / choice file 
  def HTAPData.parse_choice_file(filename) 
  
    $blk = lambda { |h,k| h[k] = Hash.new(&$blk) }
    $choices = Hash.new(&$blk)
    $order = Array.new
    
    # ===============================================
    fCHOICES = File.new(filename, "r") 
    if fCHOICES == nil then
       err_out("Could not read #{filename}.\n")
       fatalerror(" ")
    end

    $linecount = 0

    while !fCHOICES.eof? do

      $line = fCHOICES.readline
      $line.strip!              # Removes leading and trailing whitespace
      $line.gsub!(/\!.*$/, '')  # Removes comments
      $line.gsub!(/\s*/, '')    # Removes mid-line white space
      $linecount += 1
   
      debug_out ("  Line: #{$linecount} >#{$line}<\n")
   
      if ( $line !~ /^\s*$/ )
      
        lineTokenValue = $line.split(':')
        attribute = lineTokenValue[0]
        value = lineTokenValue[1]
        
        if ( $LegacyOptionsToIgnore.include? attribute ) then 
          warn_out ("Choice file includes legacy choice (#{attribute}), which is no longer supported. Input ignored.")
          next 
        end 
        
        # Parse config commands
        if ( attribute =~ /^GOconfig_/ )
           attribute.gsub!( /^GOconfig_/, '')
           if ( attribute =~ /rotate/ )
              $gRotate = value
              $choices["GOconfig_rotate"] = value
              stream_out ("   - #{attribute} -> #{value} \n")
              $order.push("GOconfig_rotate")
           end 

        else
        
           if ( value =~ /\|/ )
              #value.gsub!(/\|.*$/, '') 
              value = value.gsub(/\|.*$/, '') 
              extradata.gsub!(/^.*\|/, '') 
              extradata.gsub!(/^.*\|/, '') 
           else
              extradata = ""
           end
           
           $choices[attribute] = value
           
           stream_out ("   - #{attribute} -> #{value} \n")
           
                     
           # Save order of choices to make sure we apply them correctly. 
           $order.push(attribute)
        end
      end
    end

    fCHOICES.close
  
    # ------------------------------------------------------
  
  
    return $choices,$order
  
  end 
  
  
  def HTAPData.validate_options(options,choices,order) 
    $err = false 
    $ValidatedChoices = Hash.new
    $ValidatedChoices = choices
    $order = order 
   
   
    # Search through options and determine if they are used in Choices file (warn if not). 
    options.each do |option, ignore|

      if ( $LegacyOptionsToIgnore.include? option ) then 
      
        warn_out ("Options file includes legacy option (#{option}), which is no longer supported.")
        next 
        
      end 
      
      #debug_out ("> option : #{option} ? = #{choices.has_key?(option)}\n"); 
      if ( !choices.has_key?(option)  )
        
        $ThisMsg = "Option #{option} was not specified in Choices file OR rule set; "
        
           
        if ( ! options[option]["default"]["defined"]  )
           $ThisMsg += "No default value defined in options file."
           err_out ($ThisMsg)
           $err = true 
           
        elsif ( option =~ /Opt-Archetype/ ) 
        
           if ( ! $gBaseModelFile ) 
             $ValidatedChoices["Opt-Archetype"] = $gBaseModelFile
           end 
        
        else 
           
           # Add default value. 
          $ValidatedChoices[option] = options[option]["default"]["value"]
           # Apply them at the end. 
           $order.push(option)
           
           $ThisMsg +=  " Using default value (#{$ValidatedChoices[option]})"
           warn_out ( $ThisMsg )
           
        end
      end
      $ThisMsg = ""
    end
    
    
# Search through choices and determine if they match options in the Options file (error if not). 

   $ValidatedChoices.each do |attrib, choice|
      
     if ( $LegacyOptionsToIgnore.include? attrib ) then 
     
       warn_out ("Choice file includes legacy option (#{attrib}), which is no longer supported.")
       next 
       
     end 
     
     
     debug_out ( "\n =CHOOSING=> #{attrib}-> #{choice} \n")
     
      
     # Is attribute used in choices file defined in options ?
     if ( !options.has_key?(attrib) )
        $ThisMsg = "Attribute #{attrib} in choice file OR rule set can't be found in options file."
        err_out( $ThisMsg )
        $err = true 
     else
        debug_out ( "   - found $gOptions[\"#{attrib}\"] \n")
     end
     
       # Is choice in options?
       if ( ! options[attrib]["options"].has_key?(choice) ) 
         if (  options[attrib]["stop-on-error"] == 1 ) 
            $err = true 
            $ThisMsg = "Choice #{choice} for attribute #{attrib} is not defined in options file."
            err_out( $ThisMsg )
         else 
            # Do nothing 
            debug_out ( "   - found $gOptions[\"#{attribute}\"][\"options\"][\"#{choice}\"} \n")
      
         end 

      end 

    end    
    
    return $err, $ValidatedChoices, $order 
  
  end 
  
end 

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    