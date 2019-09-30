
def LegacyProcessConditions()
     debug_off

     $gChoices.each do |attrib1, choice|
       
       next if ( $DoNotValidateOptions.include? attrib1 )
       debug_out " = Processing conditions for #{attrib1}-> #{choice} ...\n"

       $gOptions[attrib1]["options"][choice]["result"] = Hash.new



       if ( $gOptions[attrib1]["options"][choice].empty? ) then
         debug_out "Skipped! "
         next
       end




       if ( $gOptions[attrib1]["options"][choice]["values"].nil? )then
        debug_out "Skipped! "
         next
       end

       valHash = $gOptions[attrib1]["options"][choice]["values"]
       if ( !valHash.empty?  )

          for valueIndex in valHash.keys()
             condHash = $gOptions[attrib1]["options"][choice]["values"][valueIndex]["conditions"]

             # Check for 'all' conditions
             $ValidConditionFound = 0

             if ( condHash.has_key?("all") )
                debug_out ("   - VALINDEX: #{valueIndex} : found valid condition: \"all\" !\n")
                $gOptions[attrib1]["options"][choice]["result"][valueIndex] = Hash.new
                $gOptions[attrib1]["options"][choice]["result"][valueIndex] = condHash["all"]
                $ValidConditionFound = 1
             else
                # Loop through hash
                for conditions in condHash.keys()
                   if (conditions !~ /else/ )
                      debug_out ( " >>>>> Testing |#{conditions}| <<<\n" )
                      valid_condition = 1
                      conditionArray = conditions.split(';')
                      conditionArray.each do |condition|
                         debug_out ("      #{condition} \n")
                         testArray = condition.split('=')
                         testAttribute = testArray[0]
                         testValueList = testArray[1]
                         if ( testValueList == "" )
                            testValueList = "XXXX"
                         end
                         testValueArray = testValueList.split('|')
                         thesevalsmatch = 0
                         testValueArray.each do |testValue|
                            if ( testValue.match($gChoices[testAttribute]) )
                               thesevalsmatch = 1
                            end
                            debug_out ("       \##{$gChoices[testAttribute]} = #{$gChoices[testAttribute]} / #{testValue} / -> #{thesevalsmatch} \n");
                         end
                         if ( thesevalsmatch == 0 )
                            valid_condition = 0
                         end
                      end
                      if ( valid_condition == 1 )
                         $gOptions[attrib1]["options"][choice]["result"][valueIndex]  = condHash[conditions]
                         $ValidConditionFound = 1
                         debug_out ("   - VALINDEX: #{valueIndex} : found valid condition: \"#{conditions}\" !\n")
                      end
                   end
                end
             end
             # Check if else condition exists.
             if ( $ValidConditionFound == 0 )
                debug_out ("Looking for else!: #{condHash["else"]}<\n" )
                if ( condHash.has_key?("else") )
                   $gOptions[attrib1]["options"][choice]["result"][valueIndex] = condHash["else"]
                   $ValidConditionFound = 1
                   debug_out ("   - VALINDEX: #{valueIndex} : found valid condition: \"else\" !\n")
                end
             end

             if ( $ValidConditionFound == 0 )
                $ThisMsg = "No valid conditions were defined for #{attrib1} in options file (#{$gOptionFile}). Choices must match one of the following: "
                for conditions in condHash.keys()
                   $ThisMsg +=   "#{conditions} ; "
                end
                err_out($ThisMsg)

             end
          end
       end

       # This block can probably be removed.
       # Check conditions on external entities that are not 'value' or 'cost' ...
       extHash = $gOptions[attrib1]["options"][choice]

       for externalParam in extHash.keys()

          if ( externalParam =~ /production/ )

             condHash = $gOptions[attrib1]["options"][choice][externalParam]["conditions"]

             # Check for 'all' conditions
             $ValidConditionFound = 0

             if ( condHash.has_key?("all") )
                debug_out ("   - EXTPARAM: #{externalParam} : found valid condition: \"all\" ! (#{condHash["all"]})\n")
                $gOptions[attrib1]["options"][choice]["ext-result"][externalParam] = $CondHash["all"]
                $ValidConditionFound = 1
             else
                # Loop through hash
                for conditions in condHash.keys()
                   valid_condition = 1
                   conditionArray = conditions.split(':')
                   conditionArray.each do |condition|
                      testArray = condition.split('=')
                      testAttribute = testArray[0]
                      testValueList = testArray[1]
                      if ( testValueList == "" )
                         testValueList = "XXXX"
                      end
                      testValueArray = testValueList.split('|')
                      thesevalsmatch = 0
                      testValueArray.each do |testValue|
                         if ( testValue.match($gChoices[testAttribute]) )
                            thesevalsmatch = 1
                            debug_out ("       \##{$gChoices[testAttribute]} = #{$gChoices[testAttribute]} / #{testValue} / -> #{thesevalsmatch} \n")
                         end
                         if ( thesevalsmatch == 0 )
                            valid_condition = 0
                         end
                      end
                   end
                   if ( valid_condition == 1 )
                      $gOptions[attrib1]["options"][choice]["ext-result"][externalParam] = condHash[conditions]
                      $ValidConditionFound = 1
                      debug_out ("   - EXTPARAM: #{externalParam} : found valid condition: \"#{conditions}\" (#{condHash[$conditions]})\n")
                   end
                end
             end

             # Check if else condition exists.
             if ( $ValidConditionFound == 0 )
                if ( condHash.has_key?("else") )
                   $gOptions[attrib1]["options"][choice]["ext-result"][externalParam] = condHash["else"]
                   $ValidConditionFound = 1
                   debug_out ("   - EXTPARAM: #{externalParam} : found valid condition: \"else\" ! (#{condHash["else"]})\n")
                end
             end

             if ( $ValidConditionFound == 0 )
                $ThisMsg = "No valid conditions were defined for #{attrib1} in options file (#{$gOptionFile}). Choices must match one of the following: "
                for conditions in condHash.keys()
                   $ThisMsg +=  "#{conditions};"
                end
                err_out($ThisMsg)
             end
          end
       end

       #debug_out (" >>>>> #{$gOptions[attrib1]["options"][choice]["result"]["production-elec-perKW"]}\n");

       # This section implements the multiply-cost

       if ( $allok )
          cost = $gOptions[attrib1]["options"][choice]["cost"]
          cost_type = $gOptions[attrib1]["options"][choice]["cost-type"]
          if ( defined?(cost) )
             repcost = cost
          else
             repcost = "?"
          end
          if ( !defined?(cost_type) )
             $cost_type = ""
          end
          if ( !defined?(cost) )
             cost = ""
          end
          debug_out ("   - found cost: \$#{cost} (#{cost_type}) \n")

          scaleCost = 0

          # Scale cost by some other parameter.
          if ( repcost =~ /\<MULTIPLY-COST:.+/ )

             multiplier = cost

             multiplier.gsub!(/\</, '')
             multiplier.gsub!(/\>/, '')
             multiplier.gsub!(/MULTIPLY-COST:/, '')

             multArray = multiplier.split('*')
             baseOption = multArray[0]
             scaleFactor = multArray[1]

             baseChoice = $gChoices[baseOption]
             baseCost = $gOptions[baseOption]["options"][baseChoice]["cost"]

             compCost = baseCost.to_f * scaleFactor.to_f

             scaleCost = 1
             $gOptions[attrib1]["options"][choice]["cost"] = compCost.to_s

             cost = compCost.to_s
             if ( !defined?(cost) )
                cost = "0"
             end
             if ( !defined?(cost_type) )
                $cost_type = ""
             end
          end

          #cost should be rounded in debug statement
          debug_out ( "\nMAPPING for #{attrib1} = #{choice} (@ \$#{cost} inc. cost [#{cost_type}] ): \n\n")

          if ( scaleCost == 1 )
             #baseCost should be rounded in debug statement
             debug_out (     "  (cost computed as $ScaleFactor *  #{baseCost} [cost of #{baseChoice}])\n\n")
          end

       end

       # Check on value of error flag before continuing with while loop
       # (the flag may be reset in the next iteration!)
       if ( !$allok )
          break    # exit the loop - don't process rest of choices against options
       end
    end   #end of do each gChoices loop

end



def parse_legacy_options_file(filename)

  $currentAttributeName =""
  $AttributeOpen = 0
  $ExternalAttributeOpen = 0
  $ParametersOpen = 0


  # Parse the option file.
  stream_out("\n\n Reading available options (#{filename})...")
  fOPTIONS = File.new(filename, "r")
  if fOPTIONS == nil then
    fatalerror(" Could not read #{filename}.\n")
  end

  while !fOPTIONS.eof? do

    $line = fOPTIONS.readline
    $line.strip!
    # Removes leading and trailing whitespace
    $line.gsub!(/\!.*$/, '')
    # Removes comments
    $line.gsub!(/\s*/, '')
    # Removes mid-line white space
    $line.gsub!(/\^/, ' ')
    # JTB Added Jun 30/16: Replace '^' with space (used in some option tags to indicate space between words)
    $linecount += 1

    if ( $line !~ /^\s*$/ )
      # Not an empty line!
      lineTokenValue = $line.split('=')
      $token = lineTokenValue[0]
      $value = lineTokenValue[1]

      # Allow value to contain spaces when "~" character used in options file
      #(e.g. *option:retro_GSHP:value:2 = *gshp~../hvac/heatx_v1.gshp)
      if ($value)
        $value.gsub!(/~/, ' ')
      end

      # The file contains 'attributes that are either internal (evaluated by HOT2000)
      # or external (computed elsewhere and post-processed).

      # Open up a new attribute
      if ( $token =~ /^\*attribute:start/ )
        $AttributeOpen = 1
      end

      # Open up a new external attribute
      if ( $token =~ /^\*ext-attribute:start/ )
        $ExternalAttributeOpen = 1
      end

      # Open up parameter block
      if ( $token =~ /^\*ext-parameters:start/ )
        $ParametersOpen = 1
      end

      # Parse parameters.
      if ( $ParametersOpen == 1 )
        # Read parameters. Format:
        #  *param:NAME = VALUE
        if ( $token =~ /^\*param/ )
          $token.gsub!(/\*param:/, '')
          $gParameters[$token] = $value
        end
      end

      # Parse attribute contents Name/Tag/Option(s)
      if ( $AttributeOpen || $ExternalAttributeOpen )

        if ( $token =~ /^\*attribute:name/ )

          $currentAttributeName = $value
          if ( $ExternalAttributeOpen == 1 ) then
            $gOptions[$currentAttributeName]["type"] = "external"
          else
            $gOptions[$currentAttributeName]["type"] = "internal"
          end

          $gOptions[$currentAttributeName]["default"]["defined"] = 0

          $gOptions[$currentAttributeName]["stop-on-error"] = 1

          if ( $currentAttributeName =~ /Opt-Archetype/ && $gLookForArchetype == 0 )
            $gOptions[$currentAttributeName]["stop-on-error"] = 0
          end

        elsif ( $token =~ /^\*attribute:on-error/ )

          if ($value =~ /ignore/ )
            $gOptions[$currentAttributeName]["stop-on-error"] = 0
          end

        elsif ( $token =~ /^\*attribute:tag/ )

          arrResult = $token.split(':')
          $TagIndex = arrResult[2]
          $gOptions[$currentAttributeName]["tags"][$TagIndex] = $value

        elsif ( $token =~ /^\*attribute:default/ )
          # Possibly define default value.

          $gOptions[$currentAttributeName]["default"]["defined"] = 1
          $gOptions[$currentAttributeName]["default"]["value"] = $value

        elsif ( $token =~ /^\*option/ )
          # Format:
          #  *Option:NAME:MetaType:Index or
          #  *Option[CONDITIONS]:NAME:MetaType:Index or
          # MetaType is:
          #  - cost
          #  - value
          #  - alias (for Dakota)
          #  - production-elec
          #  - production-sh
          #  - production-dhw
          #  - WindowParams

          $breakToken = $token.split(':')
          $condition_string = ""

          # Check option keyword to see if it has specific conditions
          # format is *option[condition1>value1;condition2>value2 ...]

          if ( $breakToken[0] =~ /\[.+\]/ )
            $condition_string = $breakToken[0]
            $condition_string.gsub!(/\*option\[/, '')
              $condition_string.gsub!(/\]/, '')
              $condition_string.gsub!(/>/, '=')
            else
              $condition_string = "all"
            end

            $OptionName = $breakToken[1]
            $DataType   = $breakToken[2]

            $ValueIndex = ""
            $CostType = ""

            # Assign values

            if ( $DataType =~ /value/ )
              $ValueIndex = $breakToken[3]
              $gOptions[$currentAttributeName]["options"][$OptionName]["values"][$ValueIndex]["conditions"][$condition_string] = $value
            end

            if ( $DataType =~ /cost/ )
              $CostType = $breakToken[3]
              $gOptions[$currentAttributeName]["options"][$OptionName]["cost-type"] = $CostType
              $gOptions[$currentAttributeName]["options"][$OptionName]["cost"] = $value
            end

            # Window data processing for generic window definitions:
            if ( $DataType =~ /WindowParams/ )
              debug_out ("\nProcessing window data for #{$currentAttributeName} / #{$OptionName}  \n")
              $Param = $breakToken[3]
              $GenericWindowParams[$OptionName][$Param] = $value
              $GenericWindowParamsDefined = 1
            end

            # External entities...
            if ( $DataType =~ /production/ )
              if ( $DataType =~ /cost/ )
                $CostType = $breakToken[3]
              end
              $gOptions[$currentAttributeName]["options"][$OptionName][$DataType]["conditions"][$condition_string] = $value
            end

          end

        end


        # Close attribute and append contents to global options array
        if ( $token =~ /^\*attribute:end/ || $token =~ /^\*ext-attribute:end/)

          $AttributeOpen = 0

        end

        if ( $token =~ /\*ext-parameters:end/ )
          $ParametersOpen = 0
        end

      end

    end

    fOPTIONS.close
    stream_out ("  done.\n")

  end
