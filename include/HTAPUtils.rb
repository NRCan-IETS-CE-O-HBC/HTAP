#!/usr/bin/env ruby

def HTAPInit()
  $startProcessTime = Time.now
  progShort = $program
  progShort.gsub!(/\.rb/,"")
  debug_out "Opening log files for #{progShort}"
  begin
  $fLOG, $fSUMMARY = openLogFiles("#{progShort}_log.txt","#{progShort}_summary.out")
  log_out drawRuler("LOG FILE.",nil,80)
  log_out("Run started at #{$startProcessTime}\n")

  rescue
    fatalerror ("Could not open log files.")
  end
  $allok = true

  $scriptLocation = File.expand_path(File.dirname(__FILE__)+"\\..\\.")
  log_out ("#{$program} location: #{$scriptLocation}\n")

  log_out ("Parsing configuration file")
  HTAPConfig.parseConfigData()
end

module HTAPData

  def HTAPData.simpleConditional( modelValue, conditionalOperator, queryValue)
    result = nil

    #debug_on
    debug_out "ModelValue : #{modelValue.pretty_inspect}\n"
    debug_out "CONDITIONAL : #{conditionalOperator}\n"
    debug_out "queryValue : #{queryValue}\n"
    case conditionalOperator
    when "<"
      if (modelValue.to_f < queryValue.to_f )
        result = true
      else
        result = false
      end

    when "<"
      if (modelValue.to_f = queryValue.to_f )
        result = true
      else
        result = false
      end

    when "="
      # Do i need to think more carefully about casts here?
      if (modelValue == queryValue )
        result = true
      else
        result = false
      end

    when "inc"
      result = false
      modelValue.each do | value |
        if ( value == queryValue ) then
          result = true
        end
      end

    when /else/i
      result = true
    else
      warn_out ("Unknown conditional operator #{condition}")
      result = false

    end
    debug_out "RESULT: #{result}\n"

    return result

  end

  def HTAPData.parse_json_options_file(filename)
    # New parsing method for json format
    stream_out("\n\n Reading available options (#{filename})...")

    debug_off
    debug_out("Parsing JSON Options file #{filename}\n")


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

      debug_out drawRuler(nil, ". ")
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

          debug_out "          #{tagindex} - #{schemaEntry}   \n"

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
        debug_off
        #debug_on if (attribute =~ /DHW/ && optionEntry =~ /NBC-HotWater_gas/ )
        debug_out " \n"
        debug_out " ........... OPTION: #{optionEntry} ............ \n"

        parsedOptions[attribute]["options"][optionEntry] = Hash.new
        parsedOptions[attribute]["options"][optionEntry] = {"values"        => Hash.new,
                                                            "costComponents" => Array.new,
                                                            "costCustom"     => Hash.new }

        # Import legacy costs (to be replaced.)
        costsComponents = Array.new
        costsCustom = Hash.new
        if (   jsonRawOptions[attribute]["costed"]  &&
             ! jsonRawOptions[attribute]["options"][optionEntry]["costs"].nil?  ) then

          proxy_cost = false
          debug_out " parsing cost data for #{attribute} / #{optionEntry}:\n#{jsonRawOptions[attribute]["options"][optionEntry]["costs"].pretty_inspect} \n"

          if ( ! jsonRawOptions[attribute]["options"][optionEntry]["costs"]["proxy"].nil? ) then

             debug_out " Proxy costs detetected for #{attribute} = #{optionEntry} \n"
             parsedOptions[attribute]["options"][optionEntry]["costProxy"] = jsonRawOptions[attribute]["options"][optionEntry]["costs"]["proxy"]
             proxy_cost = true

          end

          if ( ! jsonRawOptions[attribute]["options"][optionEntry]["costs"]["components"].nil? && ! proxy_cost ) then
            parsedOptions[attribute]["options"][optionEntry]["costComponents"] = jsonRawOptions[attribute]["options"][optionEntry]["costs"]["components"]
          end

          if ( ! jsonRawOptions[attribute]["options"][optionEntry]["costs"]["custom-costs"].nil? )
            parsedOptions[attribute]["options"][optionEntry]["costCustom"] = jsonRawOptions[attribute]["options"][optionEntry]["costs"]["custom-costs"]
          end
          #costType = jsonRawOptions[attribute]["options"][optionEntry]["costs"]["legacy"]["cost-type"]
          #costVal  = jsonRawOptions[attribute]["options"][optionEntry]["costs"]["legacy"]["cost"]



        else

          # do nothing - no cost data

        end


        # Currently only base supported.
        if ( structure.to_s =~ /tree/) then
          $values = jsonRawOptions[attribute]["options"][optionEntry]["h2kMap"]
          debug_out" has h2kMap entries - \n#{$values["base"].pretty_inspect}\n\n"


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

  # Simple function that returns the tags/values as a token-value
  # list. Should be able to directly access this through options,
  # but legacy data map obscures it.
  def HTAPData.getResultsForChoice(options,attribute,choice)
    #debug_on
    result = Hash.new
    debug_out ("Att: #{attribute}\n")
    debug_out ("Choice: #{choice}\n")
    debug_out( "contents of options[#{attribute}][`options`][#{choice}][`values`] ") #{}"=\n#{options[attribute]["options"][choice]["values"].pretty_inspect}")

    options[attribute]["tags"].each do |tagIndex, tagName|
     debug_out "Querying tag #{tagIndex}\n"
     if ( ! options[attribute]["options"][choice]["values"][tagIndex.to_s].nil? ) then
       tagValue = options[attribute]["options"][choice]["values"][tagIndex.to_s]["conditions"]["all"]
       result[tagName] = tagValue
     else
       result[tagName] = nil
     end
    end
    debug_out ("returning: \n#{result.pretty_inspect}\n")
    return result

  end

  # Parse configuration / choice file
  def HTAPData.parse_choice_file(filename)
    #debug_on

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

      debug_out ("  Line: #{$linecount} >#{$line}<\n")

      if ( line !~ /^\s*$/ )
        debug_out ("----------------------------------------------------------\n")
        debug_out ("LINE: #{line}\n")
        lineTokenValue = line.split(':')
        attribute = lineTokenValue[0]
        value = lineTokenValue[1]

        if ( $LegacyOptionsToIgnore.include? attribute ) then
          info_out ("Choice file includes legacy choice (#{attribute}), which is no longer supported. Input ignored.")
          help_out("byOptions",attribute)

          next
        end

        # Parse config commands
        if ( attribute =~ /^GOconfig_/ )
           attribute.gsub!( /^GOconfig_/, '')
           if ( attribute =~ /rotate/ )
              $gRotate = value
              choices["GOconfig_rotate"] = value
              debug_out ("  parsed: #{attribute} -> #{value} \n")
              order.push("GOconfig_rotate")
           end

        elsif ( attribute =~ /^Opt-Ruleset/)

          $ruleSetArgs = value.clone
          ruleSet = value.clone

          $ruleSetArgs.gsub!(/^.+\[(.+)\].*$/,"\\1")
          $ruleSetArgs.split(/;/).each do |arg|
            condition = arg.split(/>/)[0]
            set = arg.split(/>/)[1]
            debug_out (" #{condition} = #{set}\n")
            $ruleSetSpecs[condition] = set
          end
          ruleSet.gsub!(/\[.*$/,"")

          choices[attribute] = ruleSet
          debug_out( "parsed #{attribute} = #{value} -> #{ruleSet}\n")
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
    debug_out ("Parsed choices:\n#{choices.pretty_inspect}\n")

    return choices,order

  end

  def HTAPData.isChoiceValid(options, attrib, choice)
    debug_off # if (attrib =~ /DHW/ )
    debug_out " > options for #{attrib}:\n #{options[attrib].pretty_inspect}\n"
    debug_out "options[#{attrib}] contains #{choice}?"
    if ( options[attrib]["options"][choice].nil? ||
         options[attrib]["options"][choice].empty?  ) then
      debug_out " FALSE\n "
      return false
    else
      debug_out "true\n"
      return true
    end

  end

  def HTAPData.validate_options(options,choices,order)
    err = false
    validatedChoices = choices

    #debug_on

    debug_out (" Validating HTAP options\n")

     debug_out ("I will skip: #{$LegacyOptionsToIgnore.pretty_inspect}\n")

    debug_out (" These choices were supplied:\n")
    choices.each do | choice, value |

      debug_out ("  #{choice} = #{value}\n")

    end

    # Search through options and determine if they are used in Choices file (warn if not).


    options.each do |option, ignore|
      debug_out drawRuler("Option #{option}","  .")
      if ( $LegacyOptionsToIgnore.include? option ) then
        debug_out (" skipped legacy option #{option}\n")
        warn_out ("Options file includes legacy option (#{option}), which is no longer supported.")
        next
      end



     if ( !choices.has_key?(option)  )
        debug_out " #{option} was not defined in the choice file\n"
        thisMsg = "Option #{option} was not specified in Choices file OR rule set; "


        if ( ! options[option]["default"]["defined"]  )
           thisMsg += "No default value defined in options file."
           err_out (thisMsg)
           err = true

        elsif ( option =~ /Opt-Archetype/ )

           if ( ! $gBaseModelFile )
             validatedChoices["Opt-Archetype"] = $gBaseModelFile
           end

        else

           # Add default value.
           validatedChoices[option] = options[option]["default"]["value"]

           # Apply them at the end.
           order.push(option)

           thisMsg +=  " Using default value (#{validatedChoices[option]})"
           info_out ( thisMsg )

        end
      end
      thisMsg = ""
    end


    # Search through choices and determine if they match options in the Options file (error if not).

    validatedChoices.each do |attrib, choice|

      if ( $LegacyOptionsToIgnore.include? attrib ) then

        warn_out ("Choice file includes legacy option (#{attrib}), which is no longer supported.")
        next

      end

      next if ( $LegacyOptionsToIgnore.include? attrib )


      debug_out ( "\n =CHOOSING=> #{attrib}-> #{choice} \n")


      # Is attribute used in choices file defined in options ?
      if ( !options.has_key?(attrib) )
        thisMsg = "Attribute #{attrib} in choice file OR rule set can't be found in options file."
        err_out( thisMsg )
        err = true
      else
        debug_out ( "   - found $gOptions[\"#{attrib}\"] \n")
      end

      # Is choice in options?
      if ( ! options[attrib]["options"].has_key?(choice) )
        if (  options[attrib]["stop-on-error"] == 1 )
          err = true
          thisMsg = "Choice #{choice} for attribute #{attrib} is not defined in options file."
          err_out( thisMsg )
        else
          # Do nothing
          debug_out ( "   - found $gOptions[\"#{attrib}\"][\"options\"][\"#{choice}\"} \n")

        end

      end

    end

    validatedChoices, order = HTAPData.zeroInvalidFoundaiton(options,validatedChoices,order)

    return err ,validatedChoices, order

  end

  def HTAPData.zeroInvalidFoundaiton(options,choices,order)

    if ( $foundationConfiguration == "surfBySurf" ) then

      choices.delete("Opt-H2KFoundation")
      choices.delete("Opt-H2KFoundationSlabCrawl")
      order.delete("Opt-H2KFoundation")
      order.delete("Opt-H2KFoundationSlabCrawl")

      # Check to see if unsupported configuration ahs resutled -
      #debug_on
      choices.each do | option, choice |
        debug_out ("OPTION: #{option}, #{choice}\n")
      end

      wallExtRValue = HTAPData.getResultsForChoice(options,"Opt-FoundationWallExtIns",choices["Opt-FoundationWallExtIns"])["H2K-Fdn-ExtWallReff"].to_f
      wallIntRValue = HTAPData.getResultsForChoice(options,"Opt-FoundationWallIntIns",choices["Opt-FoundationWallIntIns"])["H2K-Fdn-IntWallReff"].to_f
      wallSlbRValue = HTAPData.getResultsForChoice(options,"Opt-FoundationSlabBelowGrade",choices["Opt-FoundationSlabBelowGrade"])["H2K-Fdn-SlabBelowGradeReff"].to_f

      if ( wallSlbRValue > 0.01 && wallIntRValue  < 0.01 && wallExtRValue < 0.01 ) then
        choices["Opt-FoundationSlabBelowGrade"] = "NBC_936_uninsulated_EffR0"
        warn_out("HOT2000 does not support modelling insulated below-grade slabs with uninsualted foundation walls. Changing Opt-FoundationSlabBelowGrade to 'NBC_936_uninsulated_EffR0' (was #{choices["Opt-FoundationSlabBelowGrade"]}).")
        $gChoicesChangedbyProgram = true
        help_out("byOptions", "Opt-FoundationSlabBelowGrade")

      end
    end



    if ( $foundationConfiguration == "wholeFdn" ) then

      choices.delete("Opt-FoundationSlabBelowGrade")
      choices.delete("Opt-FoundationSlabOnGrade")
      choices.delete("Opt-FoundationWallIntIns")
      choices.delete("Opt-FoundationWallExtIns")

      order.delete("Opt-FoundationSlabBelowGrade")
      order.delete("Opt-FoundationSlabOnGrade")
      order.delete("Opt-FoundationWallIntIns")
      order.delete("Opt-FoundationWallExtIns")


    end

    return choices, order

  end




  def HTAPData.whichFdnConfig(myChoices)
    #debug_on

    # Use a copy, bc these tests cause new keys to be creaed?
    choiceClone = myChoices.clone

    config = ""
    fdnConfigs = Hash.new

    fdnConfigs["wholeFdn"] = HTAPData.valOrNaOrNil([choiceClone["Opt-H2KFoundation"],
                                                   choiceClone["Opt-H2KFoundationSlabCrawl"]
                                                   ])

    fdnConfigs["surfBySurf"] = HTAPData.valOrNaOrNil([choiceClone["Opt-FoundationSlabBelowGrade"] ,
                                                      choiceClone["Opt-FoundationSlabOnGrade"]    ,
                                                      choiceClone["Opt-FoundationWallIntIns"]     ,
                                                      choiceClone["Opt-FoundationWallExtIns"]
                                                    ])

    if ( fdnConfigs["wholeFdn"]   == "nonNA" ||
         fdnConfigs["surfBySurf"] == "nil" ||
         ( fdnConfigs["wholeFdn"]   == "NA" &&  fdnConfigs["surfBySurf"] == "NA" ) ) then
         config = "wholeFdn"
    else
         config = "surfBySurf"
    end

    if ( fdnConfigs["wholeFdn"]   != "nil" &&  fdnConfigs["surfBySurf"] != "nil" ) then

      # Can't have both!

      warn_out ("HTAP cannot use whole foundation and surf-by-surf definitions. Either use Opt-H2KFoundation... or Opt-Foundaiton... defintions")
      warn_out ("Ignoring Options Opt-FoundationSlabBelowGrade,Opt-FoundationSlabOnGrade,Opt-FoundationWallIntIns and  Opt-FoundationWallExtIns")
      $gChoicesChangedbyProgram = true
      help_out(catagory,topic)

    end

    debug_out ("Intrepreted #{fdnConfigs.pretty_inspect}\n Result: #{config}\n")

    return config

  end



  def HTAPData.valOrNaOrNil(values)

    debug_off
    result = nil

    valNonNa        = false
    valDefined      = false

    values.each do | value |
      debug_out "value: ?#{value}?"
      if ( ! value.nil? && ! value.empty?  ) then
          valDefined=true
          if ( value != "NA" ) then
              valNonNa = true
              #break
          end
      end

    end

    if ( valNonNa ) then
      result = "nonNA"
    elsif ( valDefined )
      result = "NA"
    else
      result = "nil"
    end
    debug_out ("result? #{result}\n")
    return result
  end

end

module HTAPConfig

  def HTAPConfig.parseConfigData()
    begin
      configContent = File.read("#{$scriptLocation}/#{ConfigDataFile}")
      $gConfigData = JSON.parse(configContent)
    rescue
      log_out("could not parse configuration file:  #{$scriptLocation}/#{ConfigDataFile} \n")
    end
  end

  def self.setData(keys,content)
    #debug_on
    #debug_out ("Setting data for: #{keys.length} keys\n")
    #debug_out ("passed Keypath #{keys.pretty_inspect}\n")

    exists =  self.checkKeys($gConfigData,keys,"create")
    if ( keys.length > 1)
      $gConfigData.dig(*keys[0..-2])[keys.last] = content
    else
      $gConfigData[keys[0]] = content
    end
  end

  def self.checkKeys(object, keys, action="report")
    #debug_on
    #debug_out("checking for KEYPATH:\n #{keys.pretty_inspect}\n")
    #debug_out("object @ 1:\n#{object.pretty_inspect}\n")
    if ( action != "report" && action != "create")
      fatalerror("#{self.checkKeys}: developer error Known action (#{action})")
    end
    found = false

    if( ! object[keys[0]].nil? )
      found = true
    end
    debug_out ("Query - #{keys[0]} ? #{found}\n")

    if ( ! found && action == "create" )
      if ( keys.length > 1)
        object[keys[0]] = Hash.new
      else
        object[keys[0]] = ""
      end
    end
    #debug_out("object @ 2:\n#{object.pretty_inspect}\n")
    if ( keys.length > 1 && ( found || action == "create" ) )
      found = self.checkKeys(object[keys[0]], keys[1..-1], action )
    end

    debug_out("object @ 3:\n#{object.pretty_inspect}\n")
    return found
  end

  def self.getData(keys)
    #debug_on
    #debug_out ("keys len: #{keys.length}\n")

    found = self.checkKeys($gConfigData,keys)

    if ( ! found )
      contents = nil
    else

      if ( keys.length < 2 )
        #debug_out "Using key: #{keys[0]} = #{$gConfigData["updateTime"]}|\n"
        contents = $gConfigData[keys[0]]
      else
        contents = $gConfigData.dig(*keys[0..-2])[keys.last]
      end
    end

    return found, contents
  end

  def HTAPConfig.setPrmSpeed(timePerEval)

    speedsSet, speeds = self.getData(["prm","timePerEval"])

    if( ! speedsSet )
      speeds = Array.new
    else
      speeds.shift if (speeds.length > 9)
    end

    speeds.push timePerEval.round(1)
    self.setData(["prm","timePerEval"],speeds)

  end

  def HTAPConfig.getPrmSpeed()
    goodEstimate = true
    avgSpeed = 0
    speedsSet, speeds = self.getData(["prm","timePerEval"])

    if( ! speedsSet )
      goodEstimate = false
    else


      if ( speeds.length < 1 )
        goodEstimate = false

      else

        speeds.each do | speed |
          avgSpeed += speed / speeds.length
        end

      end

    end


    return goodEstimate, avgSpeed
  end

  def HTAPConfig.countSuccessfulEvals(evals)

    evalSet, evalCount = self.getData(["prm","successfulH2Kevals"])

    evalCount = 0 if (! evalSet)

    evalCount += evals

    self.setData(["prm","successfulH2Kevals"],evalCount)

  end

  def HTAPConfig.reportSuccessfulEvals()

    evalSet, evalCount = self.getData(["prm","successfulH2Kevals"])

    evalCount = 0 if (! evalSet)

    return evalCount

  end

  def HTAPConfig.checkOddities()

    oddSet, oddOut = self.getData(["oddities"])

    return false if (! oddSet )
    return oddOut

  end



  def HTAPConfig.writeConfigData()

    self.setData( ["updateTime"], Time.now  )

    begin
      configFileOutput  = File.open("#{$scriptLocation}/#{ConfigDataFile}", 'w')
      configFileOutput.write(JSON.pretty_generate($gConfigData))
    rescue
      log_out("could not write configuration file:  #{$scriptLocation}/#{ConfigDataFile} \n")
    ensure
      configFileOutput.close
    end
  end
end
