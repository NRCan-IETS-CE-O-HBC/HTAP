
def LegacyProcessConditions()
     debug_off
     
     $gChoices.each do |attrib1, choice|

       debug_out " = Processing conditions for #{attrib1}-> #{choice} ..."

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
