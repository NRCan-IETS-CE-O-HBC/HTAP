# ===========================================================================
# HTAPInit: Generic function that sets up HTAP logging and manages the config 
#           file 
# ===========================================================================

def HTAPInit()
  
  
  $startProcessTime = Time.now
  $gMasterPath = Dir.getwd()

  $dev_msgs_on = true 


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


# ===========================================================================
# HTAPData: Functions pretaining to HTAP data structure (options, choices)
# ===========================================================================
module HTAPData 

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



  # Returns a hash containing the HTAP options data structure. Pareses the file and creates 
  # the hash on first call. 
  def HTAPData.getOptionsData( file = "nil" )
    debug_out ("Recovering option data, passed file = #{file}...\n")
    if ( ! $gHTAPOptionsParsed ) then 


      log_out ("Parsing options file - #{file}")
      if ( ! File.exist? (file) )
        err_out "Options file '#{file}' does not exist.  "
        err_out "Options file must be specified with the -o option, or via the .run file."
        fatalerror("Could not find options file")

      end 

      $gHTAPOptions = HTAPData.parse_json_options_file(file)

      #fHTAPOptions = File.new($gHTAPOptionsFile, "r")
      #if (fHTAPOptions == nil ) then 
      #  fatalerror(" Could not read #{$gHTAPOptionsFile}.\n")
      #end

      #rawOptions = fHTAPOptions.read
      #fHTAPOptions.close

      #$gHTAPOptions = JSON.parse(rawOptions )
      #rawOptions  = nil

      info_out ("Parsed options file #{file}")
      $gHTAPOptionsParsed = true

    end 
  
    return $gHTAPOptions.clone 
    
  end 

  # Parses a JSON-formatted option file 
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

    return jsonRawOptions

  end 


  # Parse configuration / choice file
  def HTAPData.parse_choice_file(filename)


    blk = lambda { |h,k| h[k] = Hash.new(&blk) }
    choices = Hash.new(&blk)
    order = Array.new

    # ===============================================
    fCHOICES = File.open(filename, "rb:ISO-8859-1")
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

  # Checks to see if an attribute should be ignored 
  def HTAPData.isAttribIgnored( attrib)
    debug_off
    if ($LegacyOptionsToIgnore.include?(attrib)) then 
      return true 
    else 
      return false
    end 

  end 

  # Checks to see if an attribute matches entries in the options file
  def HTAPData.isAttribValid(options, attrib)

    if $DoNotValidateOptions.include?(attrib) then 
      return true
    end 

    if ( options[attrib].nil? || options[attrib]["options"].empty? ) then 
      return false
    else 
      return true 
    end 

  end 

  def HTAPData.isChoiceValid(options, attrib, choice)
 
    #debug_on # if (attrib =~ /DHW/ )
    debug_out " > options for #{attrib}:\n #{options[attrib].pretty_inspect}\n"
    if $DoNotValidateOptions.include?(attrib) then 
      return true
    end 

    debug_out "CHOICE encoding: #{choice.encoding}"
    debug_out "options[#{attrib}] contains #{choice}?"
    if ( options[attrib]["options"][choice].nil? ||
         options[attrib]["options"][choice].empty?  ) then
      
      return false

    else
           
      return true
    end

  end

  def HTAPData.valdate(options,passed_choices)
    debug_on 
    # A) go through the list of choices, and resolve aliases if any. 
    resolved_choices = Hash.new 
    parseOK = true 
    valid_choices = Hash.new 

    passed_choices.each do | user_attribute, value | 
      # 1) Resolve any aliases, if any 
      attribute = HTAPData.queryAttribAliases( user_attribute ) 
      debug_out " #{attribute} {#{user_attribute}} -> #{value}\n"
      # 2) Check and warn if this is a legacy option that will be ignored. 
      if ( HTAPData.isAttribIgnored(attribute) ) then 
        warn_out("Legacy option #{attribute} will be ignored.")
      else
        resolved_choices[attribute] = value 
      end 
    end 
    # B) Go through the list of options, assign defaults for missing choices

    options.keys.each do | option | 

      if ( option =~ Regexp.union(resolved_choices.keys))
        debug_out("#{option} matches!")
      else 
        debug_out("#{option} does not match!")
        if ( options[option].has_key?("default"))
          resolved_choices[option] = options[option]["default"]
          log_out("No value specified for #{option}, using default (#{resolved_choices[option]})")
        else 
          err_out("No value specified for #{option}, no default defined in options file")
          parseOK = false 
        end 

      end 

    end 

    # B) lets make sure that the choice attributes correspond
    #    to valid options
    #debug_on 
    debug_out "CHOICES: \n"
    resolved_choices.each do | user_attribute, value | 
      bError = false       
      # 1) Resolve any aliases, if any 
      attribute = HTAPData.queryAttribAliases( user_attribute ) 
      debug_out(" #{attribute} {#{user_attribute}} -> #{value}\n")

      # 3) Check that the attribute is defined in the options!
      if (not HTAPData.isAttribValid(options,attribute)  ) then 
        err_out("Attribute #{attribute} does not match any attribute entry in the options file.")
        bError = true 
        parseOK = false
      end   

      # 4) Check if the choice is valid 
      if (not HTAPData.isChoiceValid(options, attribute, value))
        err_out("Choice #{attribute}=#{value} does not match valid entries in the option file")
        bError = true
        parseOK = false
        debug_pause()
      end 

      if (not bError ) then 

        valid_choices[attribute] = value 

      end 


    end

    return  parseOK , valid_choices

  end

  # Simple function that returns the tags/values as a token-value
  # list. Should be able to directly access this through options,
  # but legacy data map obscures it.
  def HTAPData.getResultsForChoice(options,attribute,choice)

    #debug_on
    if (debug_status())
      debug_out("options[#{attribute}] = #{options[attribute].pretty_inspect}")
    end 

    result = Hash.new
    #debug_out ("Att: #{attribute}\n")
    #debug_out ("Choice: #{choice}\n")
    #debug_out( "contents of options[#{attribute}][`options`][#{choice}][`values`] ") #{}"=\n#{options[attribute]["options"][choice]["values"].pretty_inspect}")

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


  # Determines if a house will be upgraded, and returns a list 
  # of parameters describing the upgrades
  def HTAPData.upgrade_status(passed_choices)
    devmsg_out("Need to add support for upgrade status on rulesets")
    isSetbyRuleset = {}
    house_upgraded = false 
    list_of_upgrades = ""

    passed_choices.each do |thisAttrib, thisChoice|
      isSetbyRuleset[thisAttrib] = false
      next if ( AttribThatAreNotUpgrades.include?(thisAttrib) )
      
      if ( isSetbyRuleset[thisAttrib] )
      
        # skip, if upgrade was imposed by ruleset.
      
      elsif ( thisChoice != "NA" )
      
        house_upgraded = true
        list_of_upgrades += "#{thisAttrib}=>#{thisChoice};"
      
      end
    end

    return house_upgraded, list_of_upgrades

  end 


  #
  def HTAPData.get_foundation_config(passed_choices)
    #debug_on

    # Use a copy, bc these tests cause new keys to be created?
    choice_clone = passed_choices.clone 

    config = ""
    fdnConfigs = Hash.new

    if (debug_status()) 
      debug_out("FDN choices #{passed_choices.pretty_inspect}")
      debug_out("FDN CONFIG: #{fdnConfigs.pretty_inspect}")
    end 


    fdnConfigs["wholeFdn"] = HTAPData.valOrNaOrNil([choice_clone["Opt-H2KFoundation"],
                                                    choice_clone["Opt-H2KFoundationSlabCrawl"]
                                                   ])

    

    fdnConfigs["surfBySurf"] = HTAPData.valOrNaOrNil([choice_clone["Opt-FoundationSlabBelowGrade"] ,
                                                      choice_clone["Opt-FoundationSlabOnGrade"]    ,
                                                      choice_clone["Opt-FoundationWallIntIns"]     ,
                                                      choice_clone["Opt-FoundationWallExtIns"]
                                                    ])


    if (debug_status()) 
      debug_out("FDN choices #{passed_choices.pretty_inspect}")
      debug_out("FDN CONFIG: #{fdnConfigs.pretty_inspect}")
    end 

    if ( fdnConfigs["wholeFdn"]   == "nonNA" ||
         fdnConfigs["surfBySurf"] == "nil" ||
         ( fdnConfigs["wholeFdn"]   == "NA" &&  fdnConfigs["surfBySurf"] == "NA" ) ) then
         config = "wholeFdn"
    else
         config = "surfBySurf"
    end

    if ( fdnConfigs["wholeFdn"]   == "nonNA" &&  fdnConfigs["surfBySurf"] != "nonNA" ) then

      # Can't have both!

      warn_out ("HTAP cannot use whole foundation and surf-by-surf definitions. Either use Opt-H2KFoundation... or Opt-Foundaiton... defintions")
      warn_out ("Ignoring Options Opt-FoundationSlabBelowGrade,Opt-FoundationSlabOnGrade,Opt-FoundationWallIntIns and  Opt-FoundationWallExtIns")
      $gChoicesChangedbyProgram = true
      help_out(catagory,topic)

    end

    debug_out ("Intrepreted #{fdnConfigs.pretty_inspect}\n Result: #{config}\n")

    return config

  end

  # Test a list of value to see if it is NA, or Nil, or Non NA>
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






module HTAPout

  def HTAPout.write_h2k_eval_results(results)

    fJsonOut = File.open("#{$gMasterPath}\\h2k_run_results.json", "w")
    if ( fJsonOut.nil? )then
      fatalerror("Could not create #{$gMasterPath}\\h2k_run_results.json.txt")
    end

    fJsonOut.puts JSON.pretty_generate(results)
    fJsonOut.close

  end 
end 

# ===========================================================================
# HTAPConfig: Functions managing the HTAP configurration file  
# ===========================================================================

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


