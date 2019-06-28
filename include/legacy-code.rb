
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





def write_summary_file()
      
      # code to write non-json output from substitute-h2k.rb. 

      if $fSUMMARY == nil then
        fatalerror("Could not create #{$gMasterPath}\\SubstitutePL-output.txt")
      end

      $fSUMMARY.write( "#{$aliasConfig}.OptionsFile       =  #{$gOptionFile}\n")
      $fSUMMARY.write( "#{$aliasConfig}.Recovered-results =  #{$outputHCode}\n")

      if ($FlagHouseInfo)
        $fSUMMARY.write( "#{$aliasArch}.House-Builder     =  #{$BuilderName}\n" )
        $fSUMMARY.write( "#{$aliasArch}.House-Type        =  #{$HouseType}\n" )
        $fSUMMARY.write( "#{$aliasArch}.House-Storeys     =  #{$HouseStoreys}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Front-Orientation =  #{$HouseFrontOrientation}\n")
        $fSUMMARY.write( "#{$aliasArch}.Weather-Locale    =  #{$Locale_model}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Base-Region       =  #{$gBaseRegion}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Base-Locale       =  #{$gBaseLocale}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Ceiling-Type    =  #{$Ceilingtype}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Area-Slab-m2    =  #{$FoundationArea["Slab"].to_f.round(2)}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Area-Basement-m2    =  #{$FoundationArea["Basement"].to_f.round(2)}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Area-ExposedFloor-m2    =  #{$FoundationArea["Floor"].to_f.round(2)}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Area-Walkout-m2    =  #{$FoundationArea["Walkout"].to_f.round(2)}\n" )
        $fSUMMARY.write( "#{$aliasArch}.Area-Crawl-m2    =  #{$FoundationArea["Crawl"].to_f.round(2)}\n" )
      end
      $fSUMMARY.write( "#{$aliasOutput}.HDDs              =  #{$HDDs}\n" )
      $fSUMMARY.write( "#{$aliasOutput}.Energy-Total-GJ   =  #{$gResults[$outputHCode]['avgEnergyTotalGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Ref-En-Total-GJ   =  #{$RefEnergy.round(1)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-gross   =  #{$gResults[$outputHCode]['avgFuelCostsTotal$'].round(2)}   \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-PV-revenue   =  #{$gResults[$outputHCode]['avgPVRevenue'].round(2)}    \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Net     =  #{$gResults[$outputHCode]['avgFuelCostsTotal$'].round(2) - $gResults[$outputHCode]['avgPVRevenue'].round(2)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Elec    =  #{$gResults[$outputHCode]['avgFuelCostsElec$'].round(2)}  \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Gas     =  #{$gResults[$outputHCode]['avgFuelCostsNatGas$'].round(2)}  \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Prop    =  #{$gResults[$outputHCode]['avgFuelCostsPropane$'].round(2)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Oil     =  #{$gResults[$outputHCode]['avgFuelCostsOil$'].round(2)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Wood    =  #{$gResults[$outputHCode]['avgFuelCostsWood$'].round(2)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Util-Bill-Pellet  =  #{$gAvgCost_Pellet.round(2)} \n" )   # Not available separate from wood - set to 0

      $fSUMMARY.write( "#{$aliasOutput}.Energy-PV-kWh     =  #{$gResults[$outputHCode]['avgElecPVGenkWh'].round(0)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Gross-HeatLoss-GJ =  #{$gResults[$outputHCode]['avgGrossHeatLossGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Useful-Solar-Gain-GJ =  #{$gResults[$outputHCode]['avgSolarGainsUtilized'].round(1)} \n" )
      #$fSUMMARY.write( "#{$aliasOutput}.Energy-SDHW      =  #{$gEnergySDHW.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Energy-HeatingGJ  =  #{$gResults[$outputHCode]['avgEnergyHeatingGJ'].round(1)} \n" )

      $fSUMMARY.write( "#{$aliasOutput}.AuxEnergyReq-HeatingGJ = #{$gAuxEnergyHeatingGJ.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.TotalAirConditioning-LoadGJ = #{$TotalAirConditioningLoad.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.AvgAirConditioning-COP = #{$AvgACCOP.round(1)} \n" )

      $fSUMMARY.write( "#{$aliasOutput}.Energy-CoolingGJ  =  #{$gResults[$outputHCode]['avgEnergyCoolingGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Energy-VentGJ     =  #{$gResults[$outputHCode]['avgEnergyVentilationGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Energy-DHWGJ      =  #{$gResults[$outputHCode]['avgEnergyWaterHeatingGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Energy-PlugGJ     =  #{$gResults[$outputHCode]['avgEnergyEquipmentGJ'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.EnergyEleckWh     =  #{$gResults[$outputHCode]['avgFueluseEleckWh'].round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.EnergyGasM3       =  #{$gResults[$outputHCode]['avgFueluseNatGasM3'].round(1)}  \n" )
      $fSUMMARY.write( "#{$aliasOutput}.EnergyOil_l       =  #{$gResults[$outputHCode]['avgFueluseOilL'].round(1)}    \n" )
      $fSUMMARY.write( "#{$aliasOutput}.EnergyProp_L      =  #{$gResults[$outputHCode]['avgFuelusePropaneL'].round(1)}    \n" )
      # includes pellets
      $fSUMMARY.write( "#{$aliasOutput}.EnergyWood_cord   =  #{$gResults[$outputHCode]['avgFueluseWoodcord'].round(1)}    \n" )
      $fSUMMARY.write( "#{$aliasOutput}.Upgrade-cost      =  #{($gTotalCost-$gIncBaseCosts).round(2)}\n" )
      #$fSUMMARY.write( "#{$aliasOutput}.SimplePaybackYrs  =  #{$optCOProxy.round(1)} \n" )

      if ($TsvOutput)
        $fSUMMARY.write( "#{$AliasOutput}.ERS-RatingGJ/a  =  #{$gResults['TSV']['ERSRating']} \n" )
        $fSUMMARY.write( "#{$AliasOutput}.ERS-RefHouseRatingGJ/a  =  #{$gResults['TSV']['ERSRefHouseRating']} \n" )
        $fSUMMARY.write( "#{$AliasOutput}.ERS-GHGt/a  =  #{$gResults['TSV']['ERSGHG']} \n" )
      end


      # These #s are not yet averaged for orientations!
      $fSUMMARY.write( "#{$aliasOutput}.PEAK-Heating-W    =  #{$gResults[$outputHCode]['avgOthPeakHeatingLoadW'].round(1)}\n" )
      $fSUMMARY.write( "#{$aliasOutput}.PEAK-Cooling-W    =  #{$gResults[$outputHCode]['avgOthPeakCoolingLoadW'].round(1)}\n" )

      $fSUMMARY.write( "#{$aliasInput}.PV-size-kW        =  #{$PVcapacity.round(1)}\n" )



      $fSUMMARY.write( "#{$aliasArch}.Floor-Area-m2     =  #{$FloorArea.to_f.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasArch}.House-Volume-m3   =  #{$HouseVolume.to_f.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.TEDI_kWh_m2       =  #{$TEDI_kWh_m2.to_f.round(1)} \n" )
      $fSUMMARY.write( "#{$aliasOutput}.MEUI_kWh_m2       =  #{$MEUI_kWh_m2.to_f.round(1)} \n" )

      $fSUMMARY.write( "#{$aliasOutput}.ERS-Value         =  #{$gERSNum.to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasOutput}.NumTries          =  #{$NumTries.to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasOutput}.LapsedTime        =  #{$runH2KTime.to_f.round(2)}\n" )
      # Windows characteristics
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-S        =  #{$SHGCWin[1].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-S     =  #{$rValueWin[1].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-S     =  #{$AreaWin_sum[1].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-SE       =  #{$SHGCWin[2].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-SE    =  #{$rValueWin[2].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-SE    =  #{$AreaWin_sum[2].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-E        =  #{$SHGCWin[3].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-E     =  #{$rValueWin[3].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-E     =  #{$AreaWin_sum[3].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-NE       =  #{$SHGCWin[4].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-NE    =  #{$rValueWin[4].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-NE    =  #{$AreaWin_sum[4].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-N        =  #{$SHGCWin[5].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-N     =  #{$rValueWin[5].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-N     =  #{$AreaWin_sum[5].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-NW       =  #{$SHGCWin[6].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-NW    =  #{$rValueWin[6].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-NW    =  #{$AreaWin_sum[6].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-W        =  #{$SHGCWin[7].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-W     =  #{$rValueWin[7].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-W     =  #{$AreaWin_sum[7].to_f.round(1)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-SHGC-SW       =  #{$SHGCWin[8].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-R-value-SW    =  #{$rValueWin[8].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Win-Area-m2-SW    =  #{$AreaWin_sum[8].to_f.round(1)}\n" )
      # House components
      $fSUMMARY.write( "#{$aliasArch}.Area-Door-m2      =  #{$AreaComp['door'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-DoorWin-m2   =  #{$AreaComp['doorwin'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-Windows-m2   =  #{$AreaComp['win'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-Wall-m2      =  #{$AreaComp['wall'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-Header-m2    =  #{$AreaComp['header'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-Ceiling-m2   =  #{$AreaComp['ceiling'].to_f.round(3)}\n" )
      #$fSUMMARY.write( "#{$aliasArch}.Area-ExposedFloor-m2     =  #{$AreaComp['floor'].to_f.round(3)}\n" )
      $fSUMMARY.write( "#{$aliasArch}.Area-House-m2     =  #{$AreaComp['house'].to_f.round(3)}\n" )
      # House R-Value
      $fSUMMARY.write( "#{$aliasOutput}.House-R-Value(SI) =  #{$RSI['house'].to_f.round(3)}\n" )

      $fSUMMARY.write( "#{$aliasOutput}.Cost of options using unit costs = #{$optionCost.round(0)}\n")
      for status_type in $gStatus.keys()
        $fSUMMARY.write( "s.#{status_type} = #{$gStatus[status_type]}\n" )
      end

      if $ExtraOutput1 then
        $fSUMMARY.write( "#{$aliasOutput}.EnvTotalHL-GJ     =  #{$gResults[$outputHCode]['EnvHLTotalGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvCeilHL-GJ      =  #{$gResults[$outputHCode]['EnvHLCeilingGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvWallHL-GJ      =  #{$gResults[$outputHCode]['EnvHLMainWallsGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvWinHL-GJ       =  #{$gResults[$outputHCode]['EnvHLWindowsGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvDoorHL-GJ      =  #{$gResults[$outputHCode]['EnvHLDoorsGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvFloorHL-GJ     =  #{$gResults[$outputHCode]['EnvHLExpFloorsGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvCrawlHL-GJ     =  #{$gResults[$outputHCode]['EnvHLCrawlspaceGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvSlabHL-GJ      =  #{$gResults[$outputHCode]['EnvHLSlabGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvBGBsemntHL-GJ  =  #{$gResults[$outputHCode]['EnvHLBasementBGWallGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvAGBsemntHL-GJ  =  #{$gResults[$outputHCode]['EnvHLBasementAGWallGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvBsemntFHHL-GJ  =  #{$gResults[$outputHCode]['EnvHLBasementFlrHdrsGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvPonyWallHL-GJ  =  #{$gResults[$outputHCode]['EnvHLPonyWallGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvFABsemntHL-GJ  =  #{$gResults[$outputHCode]['EnvHLFlrsAbvBasementGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.EnvAirLkVntHL-GJ  =  #{$gResults[$outputHCode]['EnvHLAirLkVentGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.AnnDHWLoad-GJ     =  #{$gResults[$outputHCode]['AnnHotWaterLoadGJ'].round(1)}\n")

        $fSUMMARY.write( "#{$aliasOutput}.SpcHeatElec-GJ    =  #{$gResults[$outputHCode]['AnnSpcHeatElecGJ'].round(1)}\n")
        $fSUMMARY.write( "#{$aliasOutput}.SpcHeatGas-GJ     =  #{$gResults[$outputHCode]['AnnSpcHeatGasGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.SpcHeatOil-GJ     =  #{$gResults[$outputHCode]['AnnSpcHeatOilGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.SpcHeatProp-GJ    =  #{$gResults[$outputHCode]['AnnSpcHeatPropGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.SpcHeatWood-GJ    =  #{$gResults[$outputHCode]['AnnSpcHeatWoodGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.HotWaterElec-GJ c  =  #{$gResults[$outputHCode]['AnnHotWaterElecGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.HotWaterGas-GJ    =  #{$gResults[$outputHCode]['AnnHotWaterGasGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.HotWaterOil-GJ    =  #{$gResults[$outputHCode]['AnnHotWaterOilGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.HotWaterProp-GJ   =  #{$gResults[$outputHCode]['AnnHotWaterPropGJ'].round(1)} \n")
        $fSUMMARY.write( "#{$aliasOutput}.HotWaterWood-GJ   =  #{$gResults[$outputHCode]['AnnHotWaterWoodGJ'].round(1)} \n")
      end


      if ( $gChoices["Opt-Archetype"].nil? || $gChoices["Opt-Archetype"].empty? ) then

        $gChoices["Opt-Archetype"] = $gBaseModelFile

      end

      if $gReportChoices then
        $fSUMMARY.write( "#{$aliasInput}.Run-Region       =  #{$gRunRegion}\n" )
        $fSUMMARY.write( "#{$aliasInput}.Run-Locale       =  #{$gRunLocale}\n" )
        $fSUMMARY.write( "#{$aliasInput}.House-Upgraded   =  #{houseUpgraded}\n" )
        $gChoices.sort.to_h
        for attribute in $gChoices.keys()
          choice = $gChoices[attribute]

          $fSUMMARY.write("#{$aliasInput}.#{attribute} = #{choice}\n")
        end


      end




      # Possibly report Binned data from diagnostics file
      if ($gReadROutStrTxt) then

        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"

          $fSUMMARY.write("#{$aliasOutput}.BIN-data-HRS-#{binstr}   =  #{$binDatHrs[bin].round(4)}\n")

        end


        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"


          $fSUMMARY.write("#{$aliasOutput}.BIN-data-TMP-#{binstr}   =  #{$binDatTmp[bin].round(4)}\n")


        end

        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"


          $fSUMMARY.write("#{$aliasOutput}.BIN-data-HLR-#{binstr}   =  #{$binDatHLR[bin].round(4)}\n")



        end

        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"

          $fSUMMARY.write("#{$aliasOutput}.BIN-data-T2cap-#{binstr} =  #{$binDatT2cap[bin].round(4)}\n")


        end

        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"


          $fSUMMARY.write("#{$aliasOutput}.BIN-data-T2PLR-#{binstr} =  #{$binDatT2PLR[bin].round(4)}\n")



        end


        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"

          #$fSUMMARY.write("BIN-data-T1cap-#{binstr} = #{$binDatT1cap[bin].round(4)}\n")


        end

        32.times do |n|
          bin =n+1
          if (bin<10)  then
            pad = "0"
          else
            pad = ""
          end

          binstr = "#{pad}#{bin.to_i}"

          $fSUMMARY.write("#{$aliasOutput}.BIN-data-T1PLR-#{binstr} =  #{$binDatT1PLR[bin].round(4)}\n")




        end

      end


end 