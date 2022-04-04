#!/usr/bin/env ruby

def HTAPInit()
  
  #debug_on
  $startProcessTime = Time.now
  $gMasterPath = Dir.getwd()

  $gHelp = false
  $gHelpAvailableFlagged = false 
  $gHelpMsgsSent = Hash.new 

  progShort = $program
  progShort.gsub!(/\.rb/,"")
  debug_out "Opening log files for #{progShort}"
  begin
  $fLOG, $fSUMMARY = openLogFiles("#{progShort}_log.txt","#{progShort}_summary.out")
  log_out drawRuler("LOG FILE.",nil,80)
  log_out("Run started at #{$startProcessTime}\n")
  debug_out ("done.\n")
  rescue
    fatalerror ("Could not open log files.")
  end
  $allok = true

  $scriptLocation = File.expand_path(File.dirname(__FILE__)+"\\..\\.")


  log_out ("#{$program} location: #{$scriptLocation}")

  debug_out ("Parsing configuration file...")
  log_out ("Parsing HTAP configuration file")
  HTAPConfig.parseConfigData()
  debug_out ("done.\n")
end



# Function that can reduce a nested hash into a 'flat' verison
def flattenHash(thisHash,breadCrumbs="")
  debug_off

  flatData = Hash.new 

  thisHash.keys.sort.each do | key |
    
    currHeader = "#{breadCrumbs}:#{key}"
    debug_out ("> #{breadCrumbs} > + #{key} = ")
    if ( thisHash[key].is_a?(Hash) ) then 
      debug_out ("( #{breadCrumbs} > + #{key} ) = ")
      flatData.merge!( flattenHash(thisHash[key], currHeader ) )
    else 
      debug_out ("= #{currHeader} \n")
      flatData.merge!( { "#{currHeader.gsub(/^:/,"")}" => thisHash[key] } ) 
    end 
  end 
  debug_out ("<<returning\n#{flatData.pretty_inspect}\n<<end\n")
  return flatData

end 


# Simple routine to test if variables contain null members

def emptyOrNilRecursive(var)
  return true if emptyOrNil(var)
  return false if (var.is_a?(String) )
  if ( var.is_a?(Array) ) then
    var.each do | member | 
      return true if (emptyOrNilRecursive(member) )
    end 
  end 

  if ( var.is_a?(Hash) ) then
    var.each do | key, val | 
      return true if (emptyOrNilRecursive(val) )
    end 
  end   

  return false 
       
end 




def emptyOrNil(var)
  return true if (var.nil?)
  return true if (var.is_a?(String) && var.empty? )
  return false
  
end 


def convertToCSV(arrToFlatten,printHeader=true,headerArray=[])
  log_out ("Exporting data in csv format")
  #debug_off
  #debug_out ("Export csv - header status #{printHeader}\n ")
  require 'csv'
  flatOutput =""
  # Generate header
 
  return "" if (arrToFlatten.length == 0 )

  #debug_on
  if ( headerArray.empty? ) then 
    #debug_out "Building headerRow:"
    arrToFlatten[0].keys.sort_by{ |word| word.downcase }.each do | key |
      #debug_out "> #{key}"
      headerArray.push(key)
    end 
    #debug_out ("\n")
  
  else 
    #debug_out ("using supplied header row. \n")
  
  end 
  
  
  flatOutput << headerArray.to_csv if (printHeader )
  
  # add rows 
  firstLine = true 
  arrToFlatten.each do | line |
    rowsArray = Array.new
    value = ""
  
    headerArray.each do | key |
      if ( ! emptyOrNil(line[key]) ) 
        value = line[key]
        if ( key =~ /^listOf/ )
          value = "[#{value.gsub(/;$/,"")}]"
        end 
      else
        #warn_out ("Null data encontered!")
      end 

      rowsArray.push(value)
 
    end 

    flatOutput << rowsArray.to_csv 
      
  end

  return flatOutput

  
end



module HTAPData

  # Returns a hash containing the HTAP options data structure. Pareses the file and creates 
  # the hash on first call. 
  def HTAPData.getOptionsData()

    if ( ! $gHTAPOptionsParsed ) then 


      log_out ("Parsing options file - #{$gHTAPOptionsFile}")
      if ( ! File.exist? ($gHTAPOptionsFile) )
        err_out "Options file '#{$gHTAPOptionsFile}' does not exist.  "
        err_out "Options file must be specified with the -o option, or via the .run file."
        fatalerror("Could not find options file")

      end 

      $gHTAPOptions = HTAPData.parse_json_options_file($gHTAPOptionsFile)

      #fHTAPOptions = File.new($gHTAPOptionsFile, "r")
      #if (fHTAPOptions == nil ) then 
      #  fatalerror(" Could not read #{$gHTAPOptionsFile}.\n")
      #end

      #rawOptions = fHTAPOptions.read
      #fHTAPOptions.close

      #$gHTAPOptions = JSON.parse(rawOptions )
      #rawOptions  = nil

      info_out ("Parsed options file #{$gHTAPOptionsFile}")
      $gHTAPOptionsParsed = true

    end 
  
    return $gHTAPOptions.clone 
    
  end 

  def HTAPData.returnProxyIfExists(attribute, choice)
    options = HTAPData.getOptionsData()
    return choice if ( emptyOrNil(options[attribute] ) ) 
    return choice if ( emptyOrNil(options[attribute]["options"] ) ) 
    return choice if ( emptyOrNil(options[attribute]["options"][choice]["costs"] ) ) 
    return choice if ( emptyOrNil(options[attribute]["options"][choice]["costs"]["proxy"]))
    return options[attribute]["options"][choice]["costs"]["proxy"]
  end 



  def HTAPData.simpleConditional( modelValue, conditionalOperator, queryValue)
    result = nil

    #debug_on
    #debug_out "ModelValue : #{modelValue.pretty_inspect}\n"
    #debug_out "CONDITIONAL : #{conditionalOperator}\n"
    #debug_out "queryValue : #{queryValue}\n"
    case conditionalOperator
    
    when "per"
      return true
    
    
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
      warn_out ("Unknown conditional operator #{conditionalOperator}")
      result = false

    end
    debug_out "RESULT: #{result}\n"

    return result

  end

  def HTAPData.parse_results(filename)
    return JSON.parse(File.read(filename))
  end



  def HTAPData.parse_json_options_file(filename)
    # New parsing method for json format
    log_out("Reading available options (#{filename})")

    debug_off
    debug_out("Parsing JSON Options file #{filename}\n")


    fOPTIONS = File.new(filename, "r")

    parsedOptions = Hash.new

    if fOPTIONS == nil then
       fatalerror(" Could not read #{filename}.\n")
    end


    optionsContents = fOPTIONS.read
    fOPTIONS.close

    begin 
      jsonRawOptions = JSON.parse(optionsContents)
    rescue 
      fatalerror("Options file (#{filename}) is incorrectly formmatted, can not be interpreted as json")
    end 


    optionsContents.clear
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
            begin 
              tagindex = jsonRawOptions[attribute]["h2kSchema"].index(tagname) + 1
            rescue 
              fatalerror("Could not locate tag \"#{tagname}\" in h2k schema for option \"#{attribute}\". Check definition of #{attribute} = #{optionEntry} ")
            end 
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




    #stream_out("done.\n\n")
    jsonRawOptions.clear
    return parsedOptions

  end

  def HTAPData.parse_upgrade_file(filename)
    # Simple funciton to parse HTAP-upgrade-packages file in json format. 
    begin 
      rulesetContents = File.read(filename)
    rescue 
      fatalerror("Could not read ruleset  #{filename}.")
    end 

    begin 
      rulesetHash =  JSON.parse(rulesetContents) 
    rescue 
      fatalerror("Ruleset file (#{filename}) is incorrectly formmatted, can not be interpreted as json.")
    end 

    rulesetContents = "" 

    return rulesetHash

  end 


  # Simple function that returns the tags/values as a token-value
  # list. Should be able to directly access this through options,
  # but legacy data map obscures it.
  def HTAPData.getResultsForChoice(options,attribute,choice)

    #debug_on

    result = Hash.new
    #debug_out ("Att: #{attribute}\n")
    #debug_out ("Choice: #{choice}\n")
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
    #debug_out ("returning: \n#{result.pretty_inspect}\n")
    return result

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
           if ( attribute =~ /Opt-Ceilings/ ) then 

            choices["Opt-AtticCeilings"] = value 
            choices["Opt-CathCeilings"] = value 
            choices["Opt-FlatCeilings"] = value 


           end 

           # debug_out ("  parsed: #{attribute} -> #{value} \n")


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

  # Checks to see if an attribute matches entries in the options file
  def HTAPData.isAttribValid(options, attrib)
    debug_off

    if $DoNotValidateOptions.include?(attrib) then 
      return true
    end 

    if ( options[attrib].nil? || options[attrib]["options"].empty? ) then 
      return false
    else 
      return true 
    end 

  end 

  # Checks to see if an attribute should be ignored 
  def HTAPData.isAttribIgnored( attrib)
    debug_off
    if ($LegacyOptionsToIgnore.include?(attrib)) then 
      return true 
    else 
      return false
    end 

  end 


  # checks attribute against list of known alises, and returns prefereed name 
  # if a match is found. also issues a warning for the user
  def HTAPData.queryAttribAliases(attrib)
    if (AliasesForAttributes.keys.include?(attrib) )
      newName = AliasesForAttributes[attrib]
      warn_out("Attribute name '#{attrib}' is depreciated; mapped to '#{newName}'.")
      return newName
      
    else  
      return attrib
    end 
    

  end 



  def HTAPData.isChoiceValid(options, attrib, choice)

    #debug_on # if (attrib =~ /DHW/ )
    #debug_out " > options for #{attrib}:\n #{options[attrib].pretty_inspect}\n"
    if $DoNotValidateOptions.include?(attrib) then 
      return true
    end 
    #debug_out "options[#{attrib}] contains #{choice}?"
    if ( options[attrib]["options"][choice].nil? ||
         options[attrib]["options"][choice].empty?  ) then
      return false
    else
           
      return true
    end

  end

  def HTAPData.validate_options(options,choices,order)
    err = false
    validatedChoices = choices

    #debug_on

    #debug_out (" Validating HTAP options\n")
    # log_out ("Ignoring #{$LegacyOptionsToIgnore.pretty_inspect}\n")
    #debug_out ("I will skip: #{$LegacyOptionsToIgnore.pretty_inspect}\n")

    log_out (" supplied choices:")
    choices.each do | choice, value |
    #
      log_out ("  #{choice} = #{value}")
    #
    end

    # Search through options and determine if they are used in Choices file (warn if not).


    options.each do |option, ignore|
      # debug_out drawRuler("Option #{option}","  .")
      if ( $LegacyOptionsToIgnore.include? option ) then
        #debug_out (" skipped legacy option #{option}\n")
        warn_out ("Options file includes legacy option (#{option}), which is no longer supported.")
        next
      end

      if ( $DoNotValidateOptions.include? option )
        debug_out ("No need to validate #{option}\n")
        next
      end 



     if ( !choices.has_key?(option)  )
        #debug_out " #{option} was not defined in the choice file\n"
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

      end

      next if ( $LegacyOptionsToIgnore.include? attrib or $DoNotValidateOptions.include? attrib ) 

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
          warn_out("Choice #{choice} for attribute #{attrib} is not defined in options file. ")
          debug_out ( "   - found $gOptions[\"#{attrib}\"][\"options\"][\"#{choice}\"} \n")

        end

      end

    end

    validatedChoices, order = HTAPData.zeroInvalidFoundaiton(options,validatedChoices,order)

    return err ,validatedChoices, order

  end

  def HTAPData.zeroInvalidFoundaiton(options,choices,order)
    #debug_on

    if ( $foundationConfiguration == "surfBySurf" ) then
      debug_out ("Zeroing legacy\n")
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
      debug_out ("Zeroing surfs \n")
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



  def HTAPData.summarizeArchetype(myH2KHouseInfo,secLevel)
    # debug_on
    padding = 35
    $numPad = 5
    reportTxt = ""

    reportTxt = MDRpts.newSection("General Characteristics",secLevel)

    generalInfo = {
      "Parameter" => ["House type","Number of storeys" ],
      "Values" => [
        "#{myH2KHouseInfo["house-description"]["type"]}",
        "#{myH2KHouseInfo["house-description"]["storeys"]}"
      ]
    }
    reportTxt += MDRpts.newTable(generalInfo)

    reportTxt += MDRpts.newSection("Dimensions",4)

    dimTable = {
      "Measure" => [
        "Heated floor area",
        "Window area",
        "Window to wall ratio",
        "Window to floor ratio",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " "
      ],
      "noName1" => [
        "","","",
        "S ",
        "SE",
        "E ",
        "NE",
        "N ",
        "NW",
        "W ",
        "SW"
      ],
      "Values"  => [
        formatSqFtSqM(myH2KHouseInfo["dimensions"]["heatedFloorArea"]),
        formatSqFtSqM(myH2KHouseInfo["dimensions"]["windows"]["area"]["total"]),
        numOrDash((myH2KHouseInfo["dimensions"]["windows"]["area"]["total"]/myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["net"]*100).round(0)).to_s+"%",
        numOrDash( (myH2KHouseInfo["dimensions"]["windows"]["area"]["byOrientation"]["1"]/myH2KHouseInfo["dimensions"]["heatedFloorArea"]*100).round(0))+" %",
        numOrDash( (myH2KHouseInfo["dimensions"]["windows"]["area"]["byOrientation"]["2"]/myH2KHouseInfo["dimensions"]["heatedFloorArea"]*100).round(0))+" %",
        numOrDash( (myH2KHouseInfo["dimensions"]["windows"]["area"]["byOrientation"]["3"]/myH2KHouseInfo["dimensions"]["heatedFloorArea"]*100).round(0))+" %",
        numOrDash( (myH2KHouseInfo["dimensions"]["windows"]["area"]["byOrientation"]["4"]/myH2KHouseInfo["dimensions"]["heatedFloorArea"]*100).round(0))+" %",
        numOrDash( (myH2KHouseInfo["dimensions"]["windows"]["area"]["byOrientation"]["5"]/myH2KHouseInfo["dimensions"]["heatedFloorArea"]*100).round(0))+" %",
        numOrDash( (myH2KHouseInfo["dimensions"]["windows"]["area"]["byOrientation"]["5"]/myH2KHouseInfo["dimensions"]["heatedFloorArea"]*100).round(0))+" %",
        numOrDash( (myH2KHouseInfo["dimensions"]["windows"]["area"]["byOrientation"]["7"]/myH2KHouseInfo["dimensions"]["heatedFloorArea"]*100).round(0))+" %",
        numOrDash( (myH2KHouseInfo["dimensions"]["windows"]["area"]["byOrientation"]["8"]/myH2KHouseInfo["dimensions"]["heatedFloorArea"]*100).round(0))+" %"
      ]
    }


    dimTable["Measure"].push "Ceiling area"
    dimTable["noName1"].push "total"
    dimTable["Values"].push formatSqFtSqM(myH2KHouseInfo["dimensions"]["ceilings"]["area"]["all"])

    dimTable["Measure"].push "Ceiling area"
    dimTable["noName1"].push "total      "
    dimTable["Values"].push  "#{formatSqFtSqM(myH2KHouseInfo["dimensions"]["ceilings"]["area"]["all"])}"
    dimTable["Measure"].push "            "
    dimTable["noName1"].push "attic      "
    dimTable["Values"].push  "#{formatSqFtSqM(myH2KHouseInfo["dimensions"]["ceilings"]["area"]["attic"])} "
    dimTable["Measure"].push "            "
    dimTable["noName1"].push "flat       "
    dimTable["Values"].push  "#{formatSqFtSqM(myH2KHouseInfo["dimensions"]["ceilings"]["area"]["flat"])} "
    dimTable["Measure"].push "            "
    dimTable["noName1"].push "cathedral  "
    dimTable["Values"].push  "#{formatSqFtSqM(myH2KHouseInfo["dimensions"]["ceilings"]["area"]["cathedral"])}"
    dimTable["Measure"].push "Above grade wall area "
    dimTable["noName1"].push "           "
    dimTable["Values"].push  "#{formatSqFtSqM(myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["net"])} - net of windows, doors, headers"
    dimTable["Measure"].push "Below grade wall area "
    dimTable["noName1"].push "           "
    dimTable["Values"].push  "#{formatSqFtSqM(myH2KHouseInfo["dimensions"]["below-grade"]["walls"]["total-area"]["internal"])} - including above-grade components of foundation walls"
    dimTable["Measure"].push "Slab area             "
    dimTable["noName1"].push "basement   "
    dimTable["Values"].push  "#{formatSqFtSqM(myH2KHouseInfo["dimensions"]["below-grade"]["basement"]["floor-area"])}"
    dimTable["Measure"].push "                      "
    dimTable["noName1"].push "crawl-space"
    dimTable["Values"].push  "#{formatSqFtSqM(myH2KHouseInfo["dimensions"]["below-grade"]["crawlspace"]["floor-area"])}"
    dimTable["Measure"].push "                      "
    dimTable["noName1"].push "on-grade   "
    dimTable["Values"].push  "#{formatSqFtSqM(myH2KHouseInfo["dimensions"]["below-grade"]["slab"]["floor-area"])}"
    dimTable["Measure"].push "Exposed floors        "
    dimTable["noName1"].push "           "
    dimTable["Values"].push  "#{formatSqFtSqM(myH2KHouseInfo["dimensions"]["exposed-floors"]["area"]["total"])}"

    reportTxt += MDRpts.newTable(dimTable)
    reportTxt += MDRpts.newSection("Equipment Sizes",4)
    eqTable = {
      "Measures" => Array.new,
      "noName"  => Array.new,
      "Values"   => Array.new
    }

    eqTable["Measures"].push "Design Loads"
    eqTable["noName"].push "heating"
    eqTable["Values"].push "#{numOrDash((myH2KHouseInfo["HVAC"]["designLoads"]["heating_W"]/1000).round(1))} kW - when constructed to NBC requirements"

    eqTable["Measures"].push " "
    eqTable["noName"].push "cooling"
    eqTable["Values"].push "#{numOrDash((myH2KHouseInfo["HVAC"]["designLoads"]["cooling_W"]/1000).round(1))} kW - when constructed to NBC requirements"

    eqTable["Measures"].push "Ventilation capacity"
    eqTable["noName"].push "cooling"
    eqTable["Values"].push "#{numOrDash((myH2KHouseInfo["HVAC"]["Ventilator"]["capacity_l/s"]).round(0))} l/s"

    reportTxt += MDRpts.newTable(eqTable)

    return reportTxt

  end

  # Recovers version info from git, returns 'unknown' if errors are encountered
  def HTAPData.getGitInfo()

    begin
      # Change to directory where scripts are located.
      Dir.chdir($scriptLocation)
      revision_number=`git log --pretty=format:'%h' -n 1`
	    revision_number.gsub!(/^'/, '')
	    revision_number.gsub!(/'$/, '')
      branch_name=`git rev-parse --abbrev-ref HEAD`
    rescue
      revision_number = "unknown"
      branch_name = "unknown"
    ensure
      Dir.chdir($gMasterPath)
    end

  	return branch_name.strip, revision_number.strip
  end


  def HTAPData.prepareResult4Json()
    results = Hash.new
    results[$aliasLongConfig] = {
      "OptionsFile"         =>  "#{$gOptionFile}",
      "Recovered-results"   =>  "#{$outputHCode}",
      "version" => $gResults["version"]
    }


    case $HDDs.to_i
    when 0..2999
      climateZone = "Zone 4"
    when 3000..3999
      climateZone = "Zone 5"
    when 4000..4999
      climateZone = "Zone 6"
    when 5000..5999
      climateZone = "Zone 7a"
    when 6000..6999
      climateZone = "Zone 7b"
    when 7000..9999999
      climateZone = "Zone 8"
    else
      climateZone = "nil"
      warn_out ("Could not compute climate zone for #{locale} - HDDs:#{$HDDs}")

    end    


    results[$aliasLongArch] = {   
      "h2k-File"            =>  "#{$h2kFileName}",
      "House-Builder"       =>  "#{$BuilderName}",
      "EvaluationDate"      =>  "#{$EvalDate}",
      "Year-Built"          =>  "#{$YearBuilt}",
      "House-Type"          =>  "#{$HouseType}",
      "House-Storeys"       =>  "#{$HouseStoreys}",
			"Front-Orientation"   =>  "#{$HouseFrontOrientation}",
      "Weather-Locale"      =>  "#{$Locale_model}",
      "Base-Region"         =>  "#{$gBaseRegion}",
      "Base-Locale"         =>  "#{$gBaseLocale}",
			"Base-City"           =>  "#{$gBaseCity}",
      "climate-zone"        =>  "#{climateZone}",
      "fuel-heating-presub"  =>  "#{$ArchetypeData["pre-substitution"]["fuelHeating"]}",
      "fuel-DHW-presub"     =>  "#{$ArchetypeData["pre-substitution"]["fuelDHW"]}",
      "Ceiling-Type"        =>  "#{$Ceilingtype}",
      "Area-Slab-m2"        =>  "#{$FoundationArea["Slab"].round(2)}",
      "Area-Basement-m2"    => "#{$FoundationArea["Basement"].round(2)}",
      "Area-Walkout-m2"     =>  "#{$FoundationArea["Walkout"].round(2)}",
      "Area-Crawl-m2"       =>  "#{$FoundationArea["Crawl"].round(2)}",
      "Floor-Area-m2"     => "#{$FloorArea.round(1)}",
      "House-Volume-m3"   => "#{$HouseVolume.round(1)}",
      "Win-SHGC-S"        => "#{$SHGCWin[1].round(3)}",
      # "Win-R-value-S"     => "#{$rValueWin[1].round(3)}",
      "Win-Area-m2-S"     => "#{$AreaWin_sum[1].round(1)}",
      "Win-SHGC-SE"       => "#{$SHGCWin[2].round(3)}",
      #  "Win-R-value-SE"    => "#{$rValueWin[2].round(3)}",
      "Win-Area-m2-SE"    => "#{$AreaWin_sum[2].round(1)}",
      "Win-SHGC-E"        => "#{$SHGCWin[3].round(3)}",
      # "Win-R-value-E"     => "#{$rValueWin[3].round(3)}",
      "Win-Area-m2-E"     => "#{$AreaWin_sum[3].round(1)}",
      "Win-SHGC-NE"       => "#{$SHGCWin[4].round(3)}",
      # "Win-R-value-NE"    => "#{$rValueWin[4].round(3)}",
      "Win-Area-m2-NE"    => "#{$AreaWin_sum[4].round(1)}",
      "Win-SHGC-N"        => "#{$SHGCWin[5].round(3)}",
      # "Win-R-value-N"     => "#{$rValueWin[5].round(3)}",
      "Win-Area-m2-N"     => "#{$AreaWin_sum[5].round(1)}",
      "Win-SHGC-NW"       => "#{$SHGCWin[6].round(3)}",
      # "Win-R-value-NW"    => "#{$rValueWin[6].round(3)}",
      "Win-Area-m2-NW"    => "#{$AreaWin_sum[6].round(1)}",
      "Win-SHGC-W"        => "#{$SHGCWin[7].round(3)}",
      # "Win-R-value-W"     => "#{$rValueWin[7].round(3)}",
      "Win-Area-m2-W"     => "#{$AreaWin_sum[7].round(1)}",
      "Win-SHGC-SW"       => "#{$SHGCWin[8].round(3)}",
      #  "Win-R-value-SW"    => "#{$rValueWin[8].round(3)}",
      "Win-Area-m2-SW"    => "#{$AreaWin_sum[8].round(1)}",


      "Wall-UAValue"      => "#{$UAValue["wall"].round(2)}" ,
      "Window-UAValue"    => "#{$UAValue['win'].round(2)}", 
      "ExposedFloor-UAValue"      => "#{$UAValue['floor'].round(2)}" ,
      "Ceiling-UAValue"      => "#{$UAValue['ceiling'].round(2)}" ,
		  "Wall-RSI"          => "#{$RSI['wall'].round(2)}" ,
      "Ceiling-RSI"       => "#{$RSI['ceiling'].round(2)}" ,
      "ExposedFloor-RSI"          => "#{$RSI["floor"].round(2)}" ,
      "Archetype-ACH"   => "#{$ACHRate.round(1)}",


      "Area-Door-m2"      => "#{$AreaComp['door'].round(3)}",
      "Area-DoorWin-m2"   => "#{$AreaComp['doorwin'].round(3)}",
      "Area-Windows-m2"   => "#{$AreaComp['win'].round(3)}",
      "Area-Wall-m2"      => "#{$AreaComp['wall'].round(3)}",
      "Area-Header-m2"    => "#{$AreaComp['header'].round(3)}",
      "Area-Ceiling-m2"   => "#{$AreaComp['ceiling'].round(3)}",
      "Area-ExposedFloor-m2"     => "#{$AreaComp['floor'].round(3)}",
      "Area-House-m2"     => "#{$AreaComp['house'].round(3)}",
	  
	  # Data for embodied carbon calculation START
	  "Footing-Length-m"        => $FootingLength,
	  "Foundation-Wall-Area-m2" => $FoundationWallArea,
	  "Foundation-Slab-BelowGrade-Area-m2" => $FoundationSlabArea_BelowGrade,
	  "Foundation-Slab-OnGrade-Area-m2" => $FoundationSlabArea_OnGrade,
	  "Framed-Floor-Area-m2"    => $FramedFloorArea,
	  "Roofing-Area-m2"         => $RoofingArea,
	  # Data for embodied carbon calculation END

    }

    if $gReportChoices then
      results[$aliasLongInput] = Hash.new
      results[$aliasLongInput] = { "Run-Region" =>  "#{$gRunRegion}",
      "Run-Locale" =>  "#{$gRunLocale}",
      "House-Upgraded"   =>  "#{$houseUpgraded}",
      "House-ListOfUpgrades" => "#{$houseUpgradeList}",
      "Ruleset-Fuel-Source" => "#{$gRulesetSpecs["fuel"]}",
      "Ruleset-Ventilation" => "#{$gRulesetSpecs["vent"]}"
    }
    $gChoices.sort.to_h
    for attribute in $gChoices.keys()
      choice = $gChoices[attribute]
      results[$aliasLongInput][attribute] = "#{choice}"
    end
    end

    # duplicate? "Area-ExposedFloor-m2"=>  "#{$FoundationArea["Floor"].round(2)}",

    results["analysis_BCStepCode"] = {
      "TEDI_compliance" =>  BCStepCode.getStepByTEDI(climateZone,$TEDI_kWh_m2)
    }

    results[$aliasLongOutput] = {
      "HDDs"              => $HDDs,
      "Energy-Total-GJ"   => $gResults[$outputHCode]['avgEnergyTotalGJ'].round(1),
      "ERSRefHouse_Energy-Total-GJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyTotalGJ"].round(1),
      #"Ref-En-Total-GJ"   => $RefEnergy.round(1),
      "Util-Bill-gross"   => $gResults[$outputHCode]['avgFuelCostsTotal$'].round(2),
      "Util-PV-revenue"   => $gResults[$outputHCode]['avgPVRevenue'].round(2),
      "Util-Bill-Net"     => $gResults[$outputHCode]['avgFuelCostsTotal$'].round(2) - $gResults[$outputHCode]['avgPVRevenue'].round(2),
      "Util-Bill-Elec"    => $gResults[$outputHCode]['avgFuelCostsElec$'].round(2),
      "Util-Bill-Gas"     => $gResults[$outputHCode]['avgFuelCostsNatGas$'].round(2),
      "Util-Bill-Prop"    => $gResults[$outputHCode]['avgFuelCostsPropane$'].round(2),
      "Util-Bill-Oil"     => $gResults[$outputHCode]['avgFuelCostsOil$'].round(2),
      "Util-Bill-Wood"    => $gResults[$outputHCode]['avgFuelCostsWood$'].round(2),
      "Energy-PV-kWh"     => $gResults[$outputHCode]['avgElecPVGenkWh'].round(0),
      "Gross-HeatLoss-GJ" => $gResults[$outputHCode]['avgGrossHeatLossGJ'].round(1),
      "Infil-VentHeatLoss-GJ" => $gResults[$outputHCode]["avgVentAndInfilGJ"].round(1),
      "Useful-Solar-Gain-GJ" => $gResults[$outputHCode]['avgSolarGainsUtilized'].round(1),
      "Energy-HeatingGJ"  => $gResults[$outputHCode]['avgEnergyHeatingGJ'].round(1),
      "ERSRefHouse_Energy-HeatingGJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyHeatingGJ"].round(1),
      "AuxEnergyReq-HeatingGJ" => $gAuxEnergyHeatingGJ.round(1),
      "TotalAirConditioning-LoadGJ" => $TotalAirConditioningLoad.round(1) ,
      "AvgAirConditioning-COP" => $AvgACCOP.round(1) ,
      "Energy-CoolingGJ"  => $gResults[$outputHCode]['avgEnergyCoolingGJ'].round(1) ,
      "ERSRefHouse_Energy-CoolingGJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyCoolingGJ"].round(1),
      "Energy-VentGJ"     => $gResults[$outputHCode]['avgEnergyVentilationGJ'].round(1) ,
      "ERSRefHouse_Energy-VentGJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyVentilationGJ"].round(1),
      "Energy-DHWGJ"      => $gResults[$outputHCode]['avgEnergyWaterHeatingGJ'].round(1) ,
      "ERSRefHouse_Energy-DHWGJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyWaterHeatingGJ"].round(1),
      "Energy-PlugGJ"     => $gResults[$outputHCode]['avgEnergyEquipmentGJ'].round(1) ,
      "ESRefHouse_Energy-PlugGJ"   => $gResults[$outputHCode]["ERS_Ref_EnergyEquipmentGJ"].round(1),
      "EnergyEleckWh"     => $gResults[$outputHCode]['avgFueluseEleckWh'].round(1) ,
      "EnergyGasM3"       => $gResults[$outputHCode]['avgFueluseNatGasM3'].round(1) ,
      "EnergyOil_l"       => $gResults[$outputHCode]['avgFueluseOilL'].round(1) ,
      "EnergyProp_L"      => $gResults[$outputHCode]['avgFuelusePropaneL'].round(1) ,
      "EnergyWood_cord"   => $gResults[$outputHCode]['avgFueluseWoodcord'].round(1) ,
      # includes pellets
      "TEDI_kWh_m2"       => $TEDI_kWh_m2.round(1) ,
      "MEUI_kWh_m2"       => $MEUI_kWh_m2.round(1) ,
      "ERS-Value"         => $gERSNum.round(1) ,
      "NumTries"          => $NumTries.round(1) ,
      "LapsedTime"        => $runH2KTime.round(2) ,
      "PEAK-Heating-W"    => $gResults[$outputHCode]['avgOthPeakHeatingLoadW'].round(1) ,
      "PEAK-Cooling-W"    => $gResults[$outputHCode]['avgOthPeakCoolingLoadW'].round(1) ,
      "DesignTemp-Heating-oC" => $gResults[$outputHCode]["annual"]["design_Temp"]["heating_C"].round(1)
#      "House-R-Value(SI)" => $RSI['house'].round(3)
    }

    if $ExtraOutput1 then
      results[$aliasLongOutput]["EnvTotalHL-GJ"]     =  $gResults[$outputHCode]['EnvHLTotalGJ'].round(1)
      results[$aliasLongOutput]["EnvCeilHL-GJ"]      =  $gResults[$outputHCode]['EnvHLCeilingGJ'].round(1)
      results[$aliasLongOutput]["EnvWallHL-GJ"]      =  $gResults[$outputHCode]['EnvHLMainWallsGJ'].round(1)
      results[$aliasLongOutput]["EnvWinHL-GJ"]       =  $gResults[$outputHCode]['EnvHLWindowsGJ'].round(1)
      results[$aliasLongOutput]["EnvDoorHL-GJ"]      =  $gResults[$outputHCode]['EnvHLDoorsGJ'].round(1)
      results[$aliasLongOutput]["EnvFloorHL-GJ"]     =  $gResults[$outputHCode]['EnvHLExpFloorsGJ'].round(1)
      results[$aliasLongOutput]["EnvCrawlHL-GJ"]     =  $gResults[$outputHCode]['EnvHLCrawlspaceGJ'].round(1)
      results[$aliasLongOutput]["EnvSlabHL-GJ"]      =  $gResults[$outputHCode]['EnvHLSlabGJ'].round(1)
      results[$aliasLongOutput]["EnvBGBsemntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLBasementBGWallGJ'].round(1)
      results[$aliasLongOutput]["EnvAGBsemntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLBasementAGWallGJ'].round(1)
      results[$aliasLongOutput]["EnvBsemntFHHL-GJ"]  =  $gResults[$outputHCode]['EnvHLBasementFlrHdrsGJ'].round(1)
      results[$aliasLongOutput]["EnvPonyWallHL-GJ"]  =  $gResults[$outputHCode]['EnvHLPonyWallGJ'].round(1)
      results[$aliasLongOutput]["EnvFABsemntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLFlrsAbvBasementGJ'].round(1)
      results[$aliasLongOutput]["EnvAirLkVntHL-GJ"]  =  $gResults[$outputHCode]['EnvHLAirLkVentGJ'].round(1)
      results[$aliasLongOutput]["AnnDHWLoad-GJ"]     =  $gResults[$outputHCode]['AnnHotWaterLoadGJ'].round(1)

      results[$aliasLongOutput]["SpcHeatElec-GJ"]    = $gResults[$outputHCode]['AnnSpcHeatElecGJ'].round(1)
      results[$aliasLongOutput]["SpcHeatHP-GJ"]    = $gResults[$outputHCode]['AnnSpcHeatHPGJ'].round(1)
      results[$aliasLongOutput]["SpcHeatGas-GJ"]     = $gResults[$outputHCode]['AnnSpcHeatGasGJ'].round(1)
      results[$aliasLongOutput]["SpcHeatOil-GJ"]     = $gResults[$outputHCode]['AnnSpcHeatOilGJ'].round(1)
      results[$aliasLongOutput]["SpcHeatProp-GJ"]    = $gResults[$outputHCode]['AnnSpcHeatPropGJ'].round(1)
      results[$aliasLongOutput]["SpcHeatWood-GJ"]    = $gResults[$outputHCode]['AnnSpcHeatWoodGJ'].round(1)
      results[$aliasLongOutput]["HotWaterElec-GJ"]   = $gResults[$outputHCode]['AnnHotWaterElecGJ'].round(1)
      results[$aliasLongOutput]["HotWaterGas-GJ"]    = $gResults[$outputHCode]['AnnHotWaterGasGJ'].round(1)
      results[$aliasLongOutput]["HotWaterOil-GJ"]    = $gResults[$outputHCode]['AnnHotWaterOilGJ'].round(1)
      results[$aliasLongOutput]["HotWaterProp-GJ"]   = $gResults[$outputHCode]['AnnHotWaterPropGJ'].round(1)
      results[$aliasLongOutput]["HotWaterWood-GJ"]   = $gResults[$outputHCode]['AnnHotWaterWoodGJ'].round(1)

      # Extra data for embodied carbon calculation START
      results[$aliasLongArch]["House-HasBasement"]                   = $House_HasBasement
      results[$aliasLongArch]["House-HasBasement-Door"]              = $House_HasBasementDoor
      results[$aliasLongArch]["House-HasBasement-Window"]            = $House_HasBasementWindow
      results[$aliasLongArch]["House-HasCrawlspace"]                 = $House_HasCrawlspace
      results[$aliasLongArch]["House-HasCrawlspace-Door"]            = $House_HasCrawlspaceDoor
      results[$aliasLongArch]["House-HasCrawlspace-Window"]          = $House_HasCrawlspaceWindow
      results[$aliasLongArch]["House-HasWalkout"]                    = $House_HasWalkout
      results[$aliasLongArch]["House-HasWalkout-Door"]               = $House_HasWalkoutDoor
      results[$aliasLongArch]["House-HasWalkout-Window"]             = $House_HasWalkoutWindow
      results[$aliasLongArch]["House-HasSlab"]                       = $House_HasSlab
      results[$aliasLongArch]["House-HasSlab-Door"]                  = $House_HasSlabDoor
      results[$aliasLongArch]["House-HasSlab-Window"]                = $House_HasSlabWindow
      results[$aliasLongArch]["Foundation-Slab-Type-BelowGrade"]     = $FoundationSlabType_BelowGrade
      results[$aliasLongArch]["Foundation-Slab-Type-OnGrade"]        = $FoundationSlabType_OnGrade
      # Extra data for embodied carbon calculation END

    end


    results[$aliasLongStatus] = Hash.new
    $gStatus.keys.each do | status_type |
      results[$aliasLongStatus][status_type] = "#{$gStatus[status_type]}"
    end

    results[$aliasLongStatus]["errors"] = Array.new
    results[$aliasLongStatus]["errors"] = $gErrors
    results[$aliasLongStatus]["warnings"] = Array.new
    results[$aliasLongStatus]["warnings"] = $gWarnings
    results[$aliasLongStatus]["infoMsgs"] = Array.new
    results[$aliasLongStatus]["infoMsgs"] = $gInfoMsgs
    results[$aliasLongStatus]["success"] = $allok

    myEndProcessTime = Time.now
    totalDiff = myEndProcessTime - $startProcessTime
    results[$aliasLongStatus]["processingtime"]  = $totalDiff
    if ( $autoEstimateCosts ) then
      results[$aliasLongCosts] = $costEstimates
    end

    return results

  end 




  def self.formatSqFtSqM(area)
    return "--".rjust($numPad) if numOrDash(area) == "--"
    return ("#{(area*SF_PER_SM).round(0).to_s.rjust($numPad)} ft^2 (#{(area).round(0)} m^2)")
  end

  def self.numOrDash(number)

    if (number.to_f < 0.01 )
      string = "--"
    else
      string = "#{number.to_s}"
    end
    return string

  end

end

module HTAPConfig

  def HTAPConfig.parseConfigData()
    begin
      configContent = File.read("#{$scriptLocation}/#{ConfigDataFile}")
      $gConfigData = JSON.parse(configContent)
    rescue
      log_out("could not parse configuration file:  #{$scriptLocation}/#{ConfigDataFile}")
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

  def HTAPConfig.getCreationDate()
      dateSet, date = self.getData(["createTime"])
      if ( ! dateSet )
        dateStr = "?"
      else
        dateStr = date.split(/ /)[0]
      end
      return dateStr
  end


  def HTAPConfig.setCreationDate()
      dateSet, date = self.getData(["createTime"])
      if ( ! dateSet )
        self.setData(["createTime"],Time.now)
      end
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
