


module HTAPData

  def HTAPData.parse_json_options_file(filename)
    # New parsing method for json format

    debug_on
    stream_out("\n\n Reading available options (#{filename})...")
    debug_out(" --------------JSON options parsing ------------ ")
    fOPTIONS = File.new(filename, "r")

    parsedOptions = Hash.new

    if fOPTIONS == nil then
       fatalerror(" Could not read #{filename}.\n")
    end


    optionsContents = fOPTIONS.read
    fOPTIONS.close
    jsonRawOptions = JSON.parse(optionsContents)

    for attribute in jsonRawOptions.keys()



      structure = jsonRawOptions[attribute]["structure"]
      schema = jsonRawOptions[attribute]["schema"].to_s

      debug_out "\n ====================================="
      debug_out " Attribute: #{attribute} "
      debug_out " structure: #{structure} "

      stopOnError = jsonRawOptions[attribute]["stop-on-error"]
      if ( stopOnError ) then
        errFlag = 1
      else
        errFlag = 0
      end


      #puts "> #{attribute} (#{structure}) \n"
      parsedOptions[attribute] = Hash.new
      parsedOptions[attribute] = { "type" => "internal" ,
                                "default" => Hash.new ,
                                "stop-on-error" => errFlag  ,
                                "tags" => Hash.new   ,
                                "options" => Hash.new      }




      if ( structure.to_s =~ /tree/)
        tagindex = 0
        debug_out " SCHEMA : "
        for schemaEntry in jsonRawOptions[attribute]["h2kSchema"]
          tagindex = tagindex + 1
          parsedOptions[attribute]["tags"][tagindex] = schemaEntry

          debug_out "          #{tagindex} - #{schemaEntry}   "

        end

      else
        parsedOptions[attribute]["tags"][1] = "<NotARealTag>"
      end

      if ( ! jsonRawOptions[attribute]["default"].nil? ) then
         default = jsonRawOptions[attribute]["default"]

        parsedOptions[attribute]["default"] = { "defined" => 1,
                                             "value"   => default }

      end

      for optionEntry in jsonRawOptions[attribute]["options"].keys
        debug_out " "
        debug_out " ........... OPTION: #{optionEntry} ............ "

        parsedOptions[attribute]["options"][optionEntry] = Hash.new
        parsedOptions[attribute]["options"][optionEntry] = { "values"        => Hash.new,
                                                         "costComponents" => Array.new,
                                                         "costCustom"     => Hash.new }

        # Import legacy costs (to be replaced.)
        costsComponents = Array.new
        costsCustom = Hash.new
        if (   jsonRawOptions[attribute]["costed"]  &&
             ! jsonRawOptions[attribute]["options"][optionEntry]["costs"].nil?  ) then


          parsedOptions[attribute]["options"][optionEntry]["costComponents"] = jsonRawOptions[attribute]["options"][optionEntry]["costs"]["components"]
          parsedOptions[attribute]["options"][optionEntry]["costCustom"] = jsonRawOptions[attribute]["options"][optionEntry]["costs"]["custom-costs"]
          #costType = jsonRawOptions[attribute]["options"][optionEntry]["costs"]["legacy"]["cost-type"]
          #costVal  = jsonRawOptions[attribute]["options"][optionEntry]["costs"]["legacy"]["cost"]

          costType = "total"
          costVal  = 0

        else
          costType = "total"
          costVal  = 0
        end


        # Currently only base supported.
        if ( structure.to_s =~ /tree/) then
          $values = jsonRawOptions[attribute]["options"][optionEntry]["h2kMap"]
          debug_out" has h2kMap entries - "
          debug_out"      #{$values["base"]} \n\n"


          valuesWithConditions = Hash.new

          for tagname,value in $values["base"]

            tagindex = jsonRawOptions[attribute]["h2kSchema"].index(tagname) + 1
            if ( ! tagindex.nil? )
              valuesWithConditions[tagindex.to_s] = Hash.new
              valuesWithConditions[tagindex.to_s] = { "conditions" => Hash.new }
              valuesWithConditions[tagindex.to_s]["conditions"] = { "all" => value }
            else
              fatalerror("For #{attribute}: tag #{tagname} does not match schema.\n")
            end
          end

          parsedOptions[attribute]["options"][optionEntry]["values"] = valuesWithConditions

        else
          $values = jsonRawOptions[attribute]["options"][optionEntry]
          debug_out " has value - #{$values}"
          parsedOptions[attribute]["options"][optionEntry]["values"][1.to_s] = { "conditions" =>
                                                                                 { "all" => $values }
                                                                            }

        end

      end


    end




    stream_out("done.\n\n")

    return parsedOptions

  end

  # Parse configuration / choice file
  def HTAPData.parse_choice_file(filename)

    blk = lambda { |h,k| h[k] = Hash.new(&blk) }
    choices = Hash.new(&blk)
    order = Array.new

    # ===============================================
    fCHOICES = File.new(filename, "r")
    if fCHOICES == nil then
       err_out("Could not read #{filename}.\n")
       fatalerror(" ")
    end

    linecount = 0

    while !fCHOICES.eof? do

      line = fCHOICES.readline
      line.strip!              # Removes leading and trailing whitespace
      line.gsub!(/\!.*$/, '')  # Removes comments
      line.gsub!(/\s*/, '')    # Removes mid-line white space
      linecount += 1

      #debug_out ("  Line: #{$linecount} >#{$line}<\n")

      if ( line !~ /^\s*$/ )

        lineTokenValue = line.split(':')
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
              choices["GOconfig_rotate"] = value
              stream_out ("  parsed: #{attribute} -> #{value} \n")
              order.push("GOconfig_rotate")
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

           choices[attribute] = value

           debug_out ("  parsed: #{attribute} -> #{value} \n")


           # Save order of choices to make sure we apply them correctly.
           order.push(attribute)
        end
      end
    end

    fCHOICES.close

    # ------------------------------------------------------

    choices.each do | attrib, choice|

      stream_out (" - #{attrib} = #{choice} \n")

    end

    return choices,order

  end


  def HTAPData.validate_options(options,choices,order)
    $err = false
    $ValidatedChoices = Hash.new
    $ValidatedChoices = choices
    $order = order

    debug_out ("\n  CODE: HTAPData.validate_options(options,choices,order)  \n")
    debug_out (" choices\n")
    choices.each do | choice, value|

      debug_out (" >>> #{choice} = #{value}")

    end

    # Search through options and determine if they are used in Choices file (warn if not).
    options.each do |option, ignore|


      if ( $LegacyOptionsToIgnore.include? option ) then

        warn_out ("Options file includes legacy option (#{option}), which is no longer supported.")
        next

      end

      debug_out ("> option : #{option} ? = #{choices.has_key?(option)}\n");

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