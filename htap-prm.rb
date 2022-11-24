

#!/usr/bin/env ruby
# ************************************************************************************
# This is a rudamentary run-manager developed as a ...
# ************************************************************************************

require 'optparse'
require 'ostruct'
require 'timeout'
require 'fileutils'
require 'pp'
require 'json'
require 'set'
require 'rexml/document' 

require_relative 'inc/msgs'
require_relative 'inc/constants'
require_relative 'inc/HTAPUtils.rb'
require_relative 'inc/application_modules.rb'

include REXML   # This allows for no "REXML::" prefix to REXML methods

$program = "htap-prm.rb"

HTAPInit()

log_out ("Recovering git version info\n")
$branch_name, $revision_number = HTAPData.getGitInfo()

$gRunUpgrades         = Hash.new
$gOptionList          = Array.new
$gOptionListLimit     = Hash.new
$gOptionListIterators = Hash.new

$gMetaValues = Hash.new

$gRulesets   = Array.new
$gArchetypes = Array.new
$gLocations  = Array.new

$gChoiceFileSet = Hash.new

$gArchetypeDir = "C:/HTAP/archetypes"
$gArchetypeHash = Hash.new
$gRulesetHash   = Hash.new
$gLocationHash  = Hash.new
$gExtendedOutputFlag = ""
$gHourlySimulationFlag = ""

$bufferStatus = {:current_threads => 0,
                 :total_threads => 0,
                 :batch =>"",
                 :action => "",
                 :err_count => 0,
                 :processed_count => 0,
                 :frac_done => 0,
                 :time_left => "TBD"
} 

$gGenChoiceFileBaseName = "sim-X.choices"
$gGenChoiceFileDir = "./gen-choice-files/"
$gGenChoiceFileNum = 0
$gGenChoiceFileList = Array.new

#default: mesh, parametric and sample also supported
$gRunDefMode   = "mesh"

#Sample method = default flags
$sample_method    = "random" # Doesn't do anything yet
$sample_size      = 100
$sample_seeded    = false

#Flag for parsing
$RunScopeOpen = false

#Params for JSON output
$gJSONize = false
$gJSONAllData = Array.new
$gHashLoc = 0

$gComputeCosts = false

$snailStart = false
$snailStartWait = 1

$choicesInMemory = true
$ChoiceFileContents = Hash.new
$gDebug = false 

=begin rdoc
=========================================================================================
 METHODS: Routines called in this file must be defined before use in Ruby
          (can't put at bottom of listing).
=========================================================================================
=end 

=begin rdoc
# ----------------------------------------------------------------------------
# parse Def file
# This function parses a prm run definition file (such as HTAP-prm-trialmesh.run)
# and loads the attirbute: options info into a hash.
# ----------------------------------------------------------------------------
=end 


def parse_def_file(filepath)
  bError = false 
  $runParamsOpen = false;
  $runScopeOpen  = false;
  $UpgradesOpen  = false;
  $MetaOpen = false;
  $WildCardsInUse = false;

  rundefs = File.open(filepath, 'r')
  rulesetsHASH = Hash.new
  jsonRawOptions = Hash.new
  rundefs.each do | line |

    $defline = line
    $defline.strip!
    $defline.gsub!(/\!.*$/, '')
    $defline.gsub!(/\s*/, '')
    $defline.gsub!(/\^/,  '')

    if ( $defline !~ /^\s*$/ )
      
      debug_out ("Parsing: #{$defline}\n")

      case
        # Section star/end in the file
        when $defline.match(/RunParameters_START/i)
          $RunParamsOpen = true;

        when $defline.match(/RunParameters_END/i)
          $RunParamsOpen = false;

        when $defline.match(/RunScope_START/i)
          $RunScopeOpen = true;

        when $defline.match(/RunScope_END/i)
          $RunScopeOpen = false;

        when $defline.match(/Upgrades_START/i)
          $UpgradesOpen = true;

        when $defline.match(/Upgrades_END/i)
          $UpgradesOpen = false; 

        when $defline.match(/Meta_START/i)
          $MetaOpen = true; 
          
        when $defline.match(/Meta_END/i)
          $MetaOpen = false; 

        else

          # definitions
          $token_values = Array.new
          $token_values = $defline.split("=")

          debug_out "Token:#{$token_values[0]} = #{$token_values[1]} \n" 

          if ( $RunParamsOpen && $token_values[0] =~ /archetype-dir/i )
            # Where are our .h2k files located?

            $gArchetypeDir = $token_values[1] 
          end  

          if ( $RunParamsOpen && $token_values[0] =~ /options-file/i ) 

            # Where is our options file located?

            $gHTAPOptionsFile = $token_values[1]

            debug_out "$gHTAPOptionsFile? : #{$gHTAPOptionsFile}\n"

            jsonRawOptions = HTAPData.getOptionsData()
          end 

          if ( $RunParamsOpen && $token_values[0] =~ /substitute-file/i )
            # Where is our options file located?

            $gSubstitutePath = $token_values[1]

            debug_out "$gSubstituteFile? : #{$gSubstitutePath}\n" 
          end 

          if ( $RunParamsOpen && $token_values[0] =~ /substitute-file/i )
            # Where is our options file located?

            $gSubstitutePath = $token_values[1]

            debug_out "$gSubstituteFile? : #{$gSubstitutePath}\n" 
          end 

         if ( $RunParamsOpen && $token_values[0] =~ /unit-costs-db/i )
            # Where is our options file located?

            $gCostingFile = $token_values[1]
            $gComputeCosts = true 
          end 

         if ( $RunParamsOpen && $token_values[0] =~ /rulesets-file/i )
            # Where is our options file located?

            $gRulesetsFile = $token_values[1]

            # Test to see if rulesets file can be parsed
            rulesetsHASH = HTAPData.parse_upgrade_file($gRulesetsFile)
            debug_out "Rulesets file #{$gRulesetsFile} parsed ok.\n"
     
          end 

 

          if ( $RunParamsOpen && $token_values[0] =~ /run-mode/i )

            $gRunDefMode = $token_values[1]

            if ( ! ( $gRunDefMode =~ /mesh/ ||
                     $gRunDefMode =~ /parametric/ ||
                     $gRunDefMode =~ /sample/         ) ) then
              fatalerror (" Run mode #{$gRunDefMode} is not supported!")
            end

            # Sample run mode: Additional arguments may be provided.
             if ( $gRunDefMode =~ /sample/ ) then
                # parse parameters `n`, `seed` from `sample{ n=###; seed =###}`
                $sample_args = $gRunDefMode.clone
                $sample_args.gsub!(/.+\{/,'')
                $sample_args.gsub!(/\}/,'')
                $sample_arg_array = $sample_args.split(";")

                 $sample_arg_array.each do |arg|

                   $sample_arg_vals = arg.split(":")

                   case $sample_arg_vals[0]
                  when "n"
                    $sample_size = $sample_arg_vals[1]
                  when "seed"
                    $sample_seed_val = $sample_arg_vals[1]
                    $sample_seeded = true
                  end

                 end

                 $gRunDefMode.gsub!(/\{.*$/,"")

              end 
          end


          if ( $MetaOpen )
            token = $token_values[0]
            value = $token_values[1]
            $gMetaValues[token] = value
          end
          





          if ( $RunScopeOpen && $token_values[0] =~ /rulesets/i )
            # Rulesets that can be applied.
            $gRulesets = $token_values[1].to_s.split(",")
          end

          if ( $RunScopeOpen && $token_values[0] =~ /archetypes/i )

            # archetypes -
            $gArchetypes = $token_values[1].to_s.split(",") 
          end

          if ( $RunScopeOpen && $token_values[0] =~ /locations/i )

            # locations -
            $gLocations = $token_values[1].to_s.split(",")

            $WildCardsInUse = true if ($gLocations.grep(/\*/).length > 0 )
          end

          if ( $UpgradesOpen )
            
            # Check if option has an alias? 
            option  = HTAPData.queryAttribAliases( $token_values[0] ) 
  
            

            # Check if option should be ignored 
            if ( HTAPData.isAttribIgnored(option) )
              warn_out ("Legacy option #{option} will be ignored.")

            elsif (not HTAPData.isAttribValid(jsonRawOptions,option)  ) then 
               err_out("Attribute #{option} does not match any attribute entry in the options file.")
               bError = true 
            else  
              choices = $token_values[1].to_s.split(",")
  
              debug_out " #{option} len = #{choices.grep(/\*/).length} \n"
  
              if ( choices.grep(/\*/).length > 0  ) then
  
                $WildCardsInUse = true
  
              end
  
              $gRunUpgrades[option] = choices
  
              $gOptionList.push option
            end  
          end 
      end  #Case
    end # if ( $defline !~ /^\s*$/ )
 
  end # rundefs.each do | line | 

  # Check to see if run options contians wildcards 

  if ( $WildCardsInUse ) then

    debug_out ("Locations\n")
    locationIndex = 0
    $gLocations.clone.each do | choice |
      next unless  ( choice =~ /\*/ ) 
      pattern = choice.gsub(/\./, "\.")
      pattern.gsub!(/\*/, ".*")
      debug_out( " Wildcard Query /#{pattern}/ \n" )
      superSet = jsonRawOptions["Opt-Location"]["options"].keys
      $gLocations.delete(choice)
      $gLocations.concat superSet.grep(/#{pattern}/)
      locationIndex += 1
    end

    
    $gRunUpgrades.keys.each do |key|
 
      debug_out( " Wildcard search for #{key} => \n" )

      # `upgrade-package-list` does not get tested against the options file.  

      if ( key !~ /upgrade-package-list/ and not HTAPData.isAttribValid(jsonRawOptions,key)  ) then 
        err_out("Attribute #{key} does not match any attribute entry in the options file.")
        bError = true 
      else 
        $gRunUpgrades[key].clone.each do |choice|
  
          debug_out (" ? #{choice} \n")
  
          if ( choice =~ /\*/ ) then
  
            pattern = choice.gsub(/\*/, ".*")
            debug_out "              Wildcard matching on #{key} =~ /#{pattern}/\n"
            # Matching
            if ( key =~ /upgrade-package-list/ ) then 

              superSet = rulesetsHASH["upgrade-packages"].keys
            else 
              superSet = jsonRawOptions[key]["options"].keys
            end 
            $gRunUpgrades[key].delete(choice)
            $gRunUpgrades[key].concat superSet.grep(/#{pattern}/)
  
  
          end
  
        end
      end 
    end
    jsonRawOptions = nil
  end

  if bError 
    fatalerror("Could not parse run file (#{filepath})")
  end 

  return

  #debug_out ("Final locations: #{$gLocations.pretty_inspect}")
  #debug_out ("Final Upgrades: #{$gRunUpgrades.pretty_inspect}")

  
end # def parse_def_file(filepath) 

=begin rdoc
# ----------------------------------------------------------------------------
# cartisian_create_mesh_combinations -
# This function will iterate over all all combinations of choices for all
# attirbutes, and call gen_choice_file to create associated choice files.
# * It calls itself recusrively *
# ----------------------------------------------------------------------------
=end


def create_mesh_cartisian_combos(optIndex)

  if ( optIndex == $gOptionList.count )

    generated_file = gen_choice_file($gChoiceFileSet)

    $gGenChoiceFileList.push generated_file

    # Save the name of the archetype that matches this choice file for invoking
    # with substitute.h2k.

    # "! Opt-Archetype" - choice disabled because prm copies the h2k file into the run directory.
    $gArchetypeHash[generated_file] = $gChoiceFileSet["!Opt-Archetype"]
    $gLocationHash[generated_file]  = $gChoiceFileSet["Opt-Location"]
    $gRulesetHash[generated_file]   = $gChoiceFileSet["Opt-Ruleset"]

    $combosGenerated += 1
    $combosSinceLastUpdate += 1

    if ( $combosSinceLastUpdate == $comboInterval )
      stream_out ("    - Creating #{$gRunDefMode} run for #{$combosRequired} combinations --- #{$combosGenerated} combos created so far...\r")
      $combosSinceLastUpdate = 0 
    end

  else

    case optIndex
    when -3 

      $gLocations.each do |location|

        $gChoiceFileSet["Opt-Location"] = location

        create_mesh_cartisian_combos(optIndex+1)
      end

    when -2

      $archetypeFiles.each do |file|

          debug_out ("test file - #{file}\n")

          $h2kfile = File.basename(file)

          $gChoiceFileSet["!Opt-Archetype"] = $h2kfile

          create_mesh_cartisian_combos(optIndex+1)
      end 

    when -1

      $gRulesets.each do |ruleset|

        $gChoiceFileSet["Opt-Ruleset"] = ruleset

        create_mesh_cartisian_combos(optIndex+1) 
      end #$gOptionList $gRulesets.each do |ruleset| 

    else

       attribute  = $gOptionList[optIndex]
       choices = $gRunUpgrades[attribute]

       choices.each do | choice |

           $gChoiceFileSet[attribute] = choice
           # Recursive call for next step in order.
           create_mesh_cartisian_combos(optIndex+1)
       end
    end
  end
end  


def create_parametric_combos()
  #debug_on
  $Folder = $gArchetypeDir

  startSet = Hash.new

  parameterSpace = Hash.new

  parameterSpace = $gRunUpgrades.clone   

  parameterSpace.keys.each do |attribute|

    startSet[attribute] =  parameterSpace[attribute][0]
  end

  #debug_out " > START SET:\n#{startSet.pretty_inspect}\n" 

  $gArchetypes.each do | archetype |
    debug_out ("> archatype - #{$gArchetypes}\n")
    $archetypeFiles = Dir["#{$Folder}/#{archetype}"]
    $archetypeFiles.each do |h2kpath|
      $gLocations.each do | location |
        $gRulesets.each do | ruleset |

          debug_out (" Setting parametric scope for: \n  1  #{archetype} \n  2  #{h2kpath}    \n  3  #{location}     \n  4  #{ruleset} \n")

          # Base point

          startSet["!Opt-Archetype"] = File.basename(h2kpath)
          startSet["Opt-Location"] = location
          startSet["Opt-Ruleset"] = ruleset

          thisSet=Hash.new
          thisSet = startSet.clone 

          generated_file = gen_choice_file(thisSet)
          $gGenChoiceFileList.push generated_file

          $gArchetypeHash[generated_file] = thisSet["!Opt-Archetype"]
          $gLocationHash[generated_file]  = thisSet["Opt-Location"]
          $gRulesetHash[generated_file]   = thisSet["Opt-Ruleset"]
          $combosGenerated += 1
          $combosSinceLastUpdate += 1
          # Parametric variations....

          parameterSpace.keys.each do |attribute|

            debug_out ("PARAMETRIC: #{attribute} has #{parameterSpace[attribute].length} entries\n")

            if ( parameterSpace[attribute].length < 1  ) then 
              fatalerror " #{attribute} has #{parameterSpace[attribute].length} entries"
            end 

            parameterSpace[attribute][1..-1].each do | choice |

              debug_out ("      + #{choice} \n")

              thisSet = startSet.clone

              thisSet[attribute] = choice

              generated_file = gen_choice_file(thisSet)
              $gGenChoiceFileList.push generated_file

              # Save the name of the archetype that matches this choice file for invoking
              # with substitute.h2k.

              # "! Opt-Archetype" - choice disabled because prm copies the h2k file into the run directory.
              $gArchetypeHash[generated_file] = thisSet["!Opt-Archetype"]
              $gLocationHash[generated_file]  = thisSet["Opt-Location"]
              $gRulesetHash[generated_file]   = thisSet["Opt-Ruleset"]

              $combosGenerated += 1
              $combosSinceLastUpdate += 1
              if ( $combosSinceLastUpdate >= $comboInterval )
                stream_out ("    - Creating mesh run for #{$combosRequired} combinations --- #{$combosGenerated} combos created so far...\r")
                $combosSinceLastUpdate = 0
              end
            end 
          end

          if ( $combosSinceLastUpdate >= $comboInterval )
            stream_out ("    - Creating mesh run for #{$combosRequired} combinations --- #{$combosGenerated} combos created so far...\r")
            $combosSinceLastUpdate = 0
          end 
        end
      end
    end
  end  

  debug_out (" ----- PARAMETRIC RUN: PARAMETER SPACE ----\n#{parameterSpace.pretty_inspect}\n")
  debug_out( " - gArchetype\n#{$gArchetypeHash.pretty_inspect}\n")
  debug_out( " - gLocationH\n#{$gLocationHash.pretty_inspect} \n")
  debug_out( " - gRulesetHa\n#{$gRulesetHash.pretty_inspect}  \n") 
end   

=begin rdoc
# ----------------------------------------------------------------------------
# Gen Choice File
# This function generates a choice file from a supplied attirbute:choice hash.
# ----------------------------------------------------------------------------
=end


def gen_choice_file(choices)

  # create empty directory to hold choice files
  if ( ! Dir.exist?($gGenChoiceFileDir) && ! $choicesInMemory )
    if ( ! Dir.mkdir($gGenChoiceFileDir) )
      fatalerror( " Fatal Error! Could not create #{$gGenChoiceFileDir} below #{$gMasterPath}!\n MKDir Return code: #{$?}\n" )
    end
  end

  $gGenChoiceFileNum = $gGenChoiceFileNum + 1

  choicefilename = $gGenChoiceFileBaseName.gsub(/X/,"#{$gGenChoiceFileNum}")  

  if ( $choicesInMemory ) then

    choicefilepath = "#{choicefilename}"

    $ChoiceFileContents[choicefilepath] = "! Choice file for run $gGenChoiceFileNum\n"

    choices.each do | attribute, choice |

      $ChoiceFileContents[choicefilepath].concat("#{attribute} : #{choice} \n")
    end 

  else 

    choicefilepath = "#{$gGenChoiceFileDir}#{choicefilename}"
    choicefile = File.open(choicefilepath, 'w')

    choices.each do | attribute, choice |

      choicefile.write(" #{attribute} : #{choice} \n")
    end

    choicefile.close
  end

  return choicefilepath
end  

=begin rdoc
#======================================================================================================
# This code will process a supplied list of .choice files using the specified number of threads.
#======================================================================================================
=end


def run_these_cases(current_task_files) 

  $RunResults         = Hash.new
  $choicefiles        = Array.new
  $PIDS               = Array.new
  $FinishedTheseFiles = Hash.new
  $RunNumbers         = Array.new
  lastCount = 0
  $CompletedRunCount = 0
  $FailedRunCount = 0

  ## Create working directories

  $headerline = ""

  if ( $bReadyToResume )
    headerOut = true 
  else 
    headerOut= false
  end  

  current_task_files.each do |choicefile|
    $FinishedTheseFiles[choicefile] = false
  end

  $choicefileIndex = 0
  numberOfFiles = $FinishedTheseFiles.count {|k| k.include?(false)} 

  stream_out drawRuler("Begin Runs")
  stream_out "\n"
  $choicefileIndex = 0
  $RunsDone = false

  $csvColumns = Array.new

  # Loop until all files have been processed.
  $GiveUp = false

  startRunsTime= Time.now

  fJSONout  = File.open("#{$gOutputJSON}", 'w')
  firstJSONLine = true

  batchStatusUpdate = Array.new

  while  ! $RunsDone

      $batchCount = $batchCount + 1

      batchStatusUpdate.clear 

      batchStartTime = Time.now
      fracCompleted = $choicefileIndex.to_f/numberOfFiles.to_f
      
      debug_out ("> BATCH #{$batchCount}, Index: #{$choicefileIndex}, Complete: #{(fracCompleted*100).round(0)}% \n")
      timeMsg = ""
      if ( fracCompleted > 0.0 ) then
        timeNow = Time.now
        timeLapsed = (timeNow - startRunsTime)
        timeRemaining =   timeLapsed / fracCompleted - timeLapsed
        timeMsg = ", ~#{formatTimeInterval(timeRemaining)} remaining"

        debug_out "Time Differential = #{(timeNow -startRunsTime)}\n"
        update_run_status(time_left: "#{formatTimeInterval(timeRemaining)}")
      end

      batchLapsedTime = '0' 

      update_run_status(batch: $batchCount )     
      update_run_status(action: "Initalizing")      
      update_run_status(threads_total: $gNumberOfThreads )
      update_run_status(run_count: $choicefileIndex.to_i)

      update_run_status(frac_done: "#{(fracCompleted*100).round(0)}")

      #stream_out ("   + Batch #{$batchCount} ( #{(fracCompleted*100).round(4)}% done, #{$choicefileIndex}/#{numberOfFiles} files processed so far#{timeMsg} ...) \n" )
      if ( $batchCount == 1 && $snailStart ) then

        #stream_out ("   |\n")
        #stream_out ("   +-> NOTE: \"SnailStart\" is active. Waiting for #{$snailStartWait} seconds between threads (on first batch ONLY!)  \n")
        update_run_status(action: "Pausing for Snail Start")
      end

      # Empty arrays for current batch.
      $choicefiles.clear
      $PIDS.clear
      $SaveDirs.clear  

      # Compute the number of threads we will start: lesser of a) files remaining, or b) threads allowed.

      $ThreadsNeeded = [$FinishedTheseFiles.count {|k| k.include?(false)}, $gNumberOfThreads].min
      debug_out "TOTAL THREADS NEEDED: #{$ThreadsNeeded}"

      #=====================================================================================
      # Multi-threaded runs - Step 1: Spawn threads.
      for thread in 0..$ThreadsNeeded-1

        update_run_status(action: "Spawning threads")
        # For this thread: Get the next choice file in the batch.
        $choicefiles[thread] = current_task_files[$choicefileIndex]

        # Get the name of the .h2k file for this thread.
        $H2kFile = $gArchetypeHash[$choicefiles[thread]]
        $Ruleset = $gRulesetHash[$choicefiles[thread]]
        $Location = $gLocationHash[$choicefiles[thread]]

        count = thread + 1
        #stream_out ("     - Starting thread : #{count}/#{$ThreadsNeeded} for file #{$choicefiles[thread]} ")
        #stream_out ("     - Starting thread #{count}/#{$ThreadsNeeded} for sim ##{$choicefileIndex+1} ") 

        # For this thread: Get the next choice file in the batch.
        #$choicefiles[thread] = $RunTheseFiles[$choicefileIndex] 

        # Make sure that's a real choice file ( this just duplicates a test above )
        if ( $choicefiles[thread] =~ /.*choices$/ )

          # Increment run number and create name for unique simulation directory
          $RunNumber = $RunNumber + 1
          $RunDirectory  = $RunDirs[thread] 

          $SaveDirectory = "#{$SaveDirectoryRoot}-#{$RunNumber}"

          # Store run number and directory for this thread
          $RunNumbers[thread] = $RunNumber
          $SaveDirs[thread]   = $SaveDirectory

          # create empty run directory
          if ( ! Dir.exist?($RunDirectory) )
            if ( ! Dir.mkdir($RunDirectory) )
              fatalerror( " Fatal Error! Could not create #{$RunDirectory} below #{$gMasterPath}!\n MKDir Return code: #{$?}\n" )
            end

          else
            bCPDone = false
            cptries = 0              
                      
            while ! bCPDone
              # Delete contents, but not H2K folder
              begin
                FileUtils.rm_r Dir.glob("#{$RunDirectory}/*.*")
                bCPDone = true 
              rescue
                
                cptries += 1
                 warn_out ("Could not delete files from within #{$RunDirectory} (Try # #{cptries}/3)\n")
                if ( cptries == 3 )
                  bCPDone = true 
                  warn_out ( "Trying to run simulation without deleting files in #{$RunDirectory}")
                else 
                  sleep 5 
                end 
               
              end
            end 
          end   

          # Copy choice and options file into intended run directory...
          if $choicesInMemory
            choicefile = File.open("#{$RunDirectory}/#{$choicefiles[thread]}", 'w')
            choicefile.write ($ChoiceFileContents[$choicefiles[thread]])
            choicefile.close
          else
            FileUtils.cp($choicefiles[thread],$RunDirectory)
          end

          FileUtils.cp($gHTAPOptionsFile,$RunDirectory)

          FileUtils.cp("#{$gArchetypeDir}\\#{$H2kFile}",$RunDirectory)

          if ( $gComputeCosts || $gLEEPPathwayExport ) then
            # Unit cost DB required for cost calcs and LEEP-pathaways export; issue fatal error if not found.
            begin
              FileUtils.cp($gCostingFile,$RunDirectory)
            rescue 
              err_out("Unit cost database ('#{$gCostingFile}') was not copied successfully.")
              fatalerror("Failed to copy unit-cost DB")
            end 
          end
          # ... And get base file names for insertion into the substitute-h2k.rb command.
          $LocalChoiceFile  = File.basename $choicefiles[thread]
          $LocalOptionsFile = File.basename $gHTAPOptionsFile  

          # CD to run directory, spawn substitute-h2k thread and save PID
          Dir.chdir($RunDirectory)

          if ( $gDebug )
            FileUtils.cp("#{$H2kFile}","#{$H2kFile}-p0")
          end  

          # Possibly call another script to modify the .h2k and .choice files
          # Perhaps these are depeciated? 
          case $Ruleset
          when /936_2015_AW_HRV/
            subcall = "perl C:\\HTAP\\NRC-scripts\\apply936-AW.pl #{$H2kFile} #{$LocalChoiceFile}  #{$LocalOptionsFile} #{$Location} 1 "
            system (subcall)
          when /936_2015_AW_noHRV/
            subcall = "perl C:\\HTAP\\NRC-scripts\\apply936-AW.pl #{$H2kFile} #{$LocalChoiceFile}  #{$LocalOptionsFile} #{$Location} 0 "
            system (subcall)
          end

          if ( $gDebug )
            FileUtils.cp("#{$H2kFile}","#{$H2kFile}-p1")
          end

          subCostFlag = ""
          subRulesetsFlag = ""
          if ($gComputeCosts ) then
            subCostFlag = "--auto_cost_options --unit-cost-db #{$gCostingFile}"
          end 

          if ( ! $gRulesetsFile.empty? ) then 
            subRulesetsFlag = "--rulesets #{$gRulesetsFile}"
          end 

          cmdscript =  "ruby #{$gSubstitutePath} "+
                           "-o #{$LocalOptionsFile} "+
                           "-c #{$LocalChoiceFile} "+
                           "-b #{$H2kFile} "+
                           "#{subRulesetsFlag} "+
                           "#{subCostFlag} "+ 
                           "--prm "+
                           "#{$gExtendedOutputFlag} "+ 
                           "#{$gHourlySimulationFlag}"
         # Save command for invoking substitute [ useful in debugging ]
          $cmdtxt = File.open("run-cmd.ps1", 'w')
          $cmdtxt.write "#{cmdscript} -v "

          $cmdtxt.close

          if  ( ! $gLogDebugMsgs ) then

            debugflag = "--no-debug"

          else 

            debug_flag = ""
          
          end 

          # disable debugging in live version for faster runs 
          # (debugging still enabled in run-cmd.ps1)
          pid = Process.spawn( 
            "#{cmdscript} #{debugflag}", 
            :err => "substitute-h2k-errors.txt" 
          )
          
          
          update_run_status(threads_delta: 1) 

          $PIDS[thread] = pid

          #stream_out("(PID #{$PIDS[thread]})...")   

          # Cd to root, move to next choice file.
          Dir.chdir($gMasterPath)
        end

          # Snail-Start:
          # This patch is a workaround for instability observed with highly-thread (20+) runs on machines with slow I/O.
          # On the first batch, the substitute script copies the contents of the h2k folder into the working directories (HTAP-work-X),
          # and these folders are subsequently re-used on the following batches. I suspect that windows struggles when 40+ threads are all
          # trying to copy 80+ MB simultaneously to a slow disk; some folders are not created correctly, some files are missing. The
          # result is a bunch of failed runs.
          #
          # Specifying command line option '--snailStart X' causes prm to pause for X seconds after spawning a thread - * on the first batch only *
          # It seems to give a magnetic disk a fighting chance of keeping up with the copy requests. It doesn't appear to slow the simulation
          # down too much, because it only affects the first batch, the H2K folder copy operation appears to be the most expensive part of that first run.

          # In tests with 40 threads writing to a magnetic disk, `-- snailStart 6` produces stable runs.
          # A future improvement might modify substitute-h2k.rb to take a hash of the h2k directory content, and verify its integrity before proceeding.

          if ( $batchCount == 1 && $snailStart ) then

            #stream_out ("  *SS-Wait")
            for wait in 1..5

              #stream_out (".")

              sleep($snailStartWait/5)
            end

            #stream_out( "*")
          end 

        #stream_out (" done. \n")
        $choicefileIndex = $choicefileIndex + 1

        # Create hash to hold results
        $RunResults["run-#{thread}"] = Hash.new
        $RunResults["run-#{thread}"]["status"] = Hash.new
        $RunResults["run-#{thread}"]["status"]["success"] = nil
        $RunResults["run-#{thread}"]["status"]["errors"] = Array.new
        $RunResults["run-#{thread}"]["status"]["warnings"] = Array.new
        $RunResults["run-#{thread}"]["configuration"] = Hash.new
        $RunResults["run-#{thread}"]["input"] = Hash.new
        $RunResults["run-#{thread}"]["archetype"] = Hash.new
        $RunResults["run-#{thread}"]["output"] = Hash.new
        $RunResults["run-#{thread}"]["cost-estimates"] = Hash.new
        $RunResults["run-#{thread}"]["meta"] = Hash.new
      end 

      # Multi-threaded runs - Step 2: Monitor thread progress
      #=====================================================================================
      # Wait for threads to complete
      update_run_status( action: "Monitoring thread progress" )
      for thread2 in 0..$ThreadsNeeded-1
         update_run_status( action: "Monitoring progress on T#{thread2+1}" )
         count = thread2 + 1

         #stream_out ("     - Waiting on PID: #{$PIDS[thread2]} (#{count}/#{$ThreadsNeeded})...")

          Process.wait($PIDS[thread2], 0)

          status = $?.exitstatus

          if ( status == 0 )

            #stream_out (" done.\n")

          else

            #stream_out (" FAILED! (Exit status: #{status})\n")

            $RunResults["run-#{thread2}"]["status"]["success"] = false
            $RunResults["run-#{thread2}"]["status"]["errors"].push  " Run failed - substitute-h2k.rb returned status #{status}"
          end
          update_run_status( action: "Shutting down T##{thread2+1}")
          update_run_status( threads_delta: -1 )
      end

      #=====================================================================================
      # Multi-threaded runs - Step 3: Post-process and clean up.
      update_run_status(action: "Parsing batch results")
      LEEPPathways.EmptyBuffers() if ($gLEEPPathwayExport )

      for thread3 in 0..$ThreadsNeeded-1  

        count = thread3 + 1
        #stream_out ("     - Reading results files from PID: #{$PIDS[thread3]} (#{count}/#{$ThreadsNeeded})...")
        Dir.chdir($gMasterPath)
        Dir.chdir($RunDirs[thread3])

        # Save HTAP-prm run information
        $RunResults["run-#{thread3}"]["configuration"]["RunNumber"]      = "#{$RunNumbers[thread3].to_s}"
        $RunResults["run-#{thread3}"]["configuration"]["RunDirectory"]   = "#{$RunDirs[thread3].to_s}"
        $RunResults["run-#{thread3}"]["configuration"]["SaveDirectory"]  = "#{$SaveDirs[thread3].to_s}"
        $RunResults["run-#{thread3}"]["configuration"]["ChoiceFile"]     = "#{$choicefiles[thread3].to_s}"


        for token in $gMetaValues.keys() 
          $RunResults["run-#{thread3}"]['meta'][token] = $gMetaValues[token]
        end 
        $runFailed = false

        # Parse contents of substitute-h2k-errors.txt, which may contain ruby errors if substitute-h2k.rb did
        # not execute correctly.
        $RunResults["run-#{thread3}"]["status"]["substitute-h2k-err-msgs"] = "nil"

        if ( File.exist?("substitute-h2k-errors.txt") )
            $errmsgs= File.read("substitute-h2k-errors.txt")
            $errmsgs_chk = $errmsgs
            if ( ! $errmsgs_chk.gsub(/\n*/,"").gsub( / */, "").empty? )
              $RunResults["run-#{thread3}"]["status"]["substitute-h2k-err-msgs"] =  $errmsgs #"Substitute.h2k encountered errors" 
              log_out ("ERROR MESSAGES FROM SUBSTITUTE - START:")
              log_out ($errmsgs)
              log_out ("ERROR MESSAGES FRON SUBSTITUTE - END: ")
            end
        end 

        # if JSON output was generated, default to parsing that. 
        jsonParsed = false
        #debug_out "pp: \n#{$RunResults["run-#{thread3}"].pretty_inspect}\n"
        debug_out "Looking for #{$RunResultFilenameV2} ? \n"
        
        if ( File.exist?($RunResultFilenameV2) ) then
          debug_out "Found it. Parsing JSON output !\n"
          contents = File.read($RunResultFilenameV2)
          thisRunResults = Hash.new
          thisRunResults = JSON.parse(contents)

          # Delete audit data unless it is requested. 
          if ( 
               ! thisRunResults["cost-estimates"].nil? and 
               ! thisRunResults["cost-estimates"]["audit"].nil? and 
               ! $gTest_params["audit-costs"] 
            ) then 

            thisRunResults["cost-estimates"]["audit"] = nil 
          end 

          thisRunResults.keys.each do | section |
            if ( section.eql?("status") || section.eql?("configuration") ) then
              thisRunResults[section].keys.each do | node |
                debug_out ("  ------ #{section}/#{node}\n")
                if ( section == status && node == "success" && $RunResults["run-#{thread3}"][section][node] == false ) then

                else
                  $RunResults["run-#{thread3}"][section][node]  = thisRunResults[section][node]
                end

              end
            else
              debug_out " ...... #{section} \n"
              $RunResults["run-#{thread3}"][section] = thisRunResults[section]
            end
          end
          $runFailed = true if (! $RunResults["run-#{thread3}"]["status"]["success"] )
          jsonParsed = true

          # Extract data for use in pathway tool 
          LEEPPathways.ExtractPathwayData(thisRunResults) if ( $gLEEPPathwayExport )

          #stream_out (" done.\n")
        end

        # if JSON output not found, attempt to parse summary-out file  
        if ( jsonParsed ) then
          # do nothing !
          debug_out "No futher file processing needed\n"
          debug_out drawRuler " . "
          debug_out "results from run-#{thread3}:\n"
          #debug_out ("#{$RunResults["run-#{thread3}"].pretty_inspect}\n")
        elsif (  File.exist?($RunResultFilename)  ) then
          
          debug_out "processing old token/value file \n"

          contents = File.open($RunResultFilename, 'r')

          ec=0
          wc=0

          lineCount = 0

          tokenResults = Hash.new
          
          # handling for old files. 
          begin
          contents.each do |line|
            lineCount = lineCount + 1
            line_clean = line.gsub(/ /, '')
            line_clean = line.gsub(/\n/, '')
            if ( ! line_clean.to_s.empty? )
              $contents = Array.new
              $contents = line_clean.split('=')
              token = $contents[0].gsub(/\s*/,'')
              value = $contents[1].gsub(/^\s*/,'')
              value = $contents[1].gsub(/^ /,'')
              value = $contents[1].gsub(/ +$/,'') 

              # add prefix to
              case token
              when /s.error/
                token.concat("@#{ec}")
                ec = ec + 1
              when /s.warning/
                token.concat("@#{wc}")
                wc=wc+1
              end
              tokenResults[token] = value 
              #$RunResults["run-#{thread3}"][token] = value
            end
          end
          contents.close
          rescue 
            tokenResults["status.success"] = "false"
          end 

          if tokenResults["status.success"] =~ /false/ then
            $runFailed = true
            $RunResults["run-#{thread3}"]["status"]["success"] = false
            #stream_out (" done (with errors).\n")
          else
            #stream_out (" done.\n")
          end

          debug_off
          
        else
            debug_out ("no output anywhere!\n")
            #stream_out (" Output couldn't be found! \n")
            $runFailed = true
        end 

        if ($runFailed)
            #stream_out (" RUN FAILED! (see dir: #{$SaveDirs[thread3]}) \n")
            $failures.write "#{$choicefiles[thread3]} (dir: #{$SaveDirs[thread3]}) - no output from substitute-h2k.rb\n"
            $FailedRuns.push "#{$choicefiles[thread3]} (dir: #{$SaveDirs[thread3]}) - no output from substitute-h2k.rb"
            #$FailedRunCount = $FailedRunCount + 1

            $RunResults["run-#{thread3}"]["status"]["success"] = false
            #if ( $RunResults["run-#{thread3}"]["status"]["errors"].nil? ) then
            #  $RunResults["run-#{thread3}"]["status"]["errors"] = Array.new
            #end
            #$RunResults["run-#{thread3}"]["status"]["errors"].push = " Run failed - no output generated"

            $LocalChoiceFile = File.basename $gHTAPOptionsFile
            if ( ! FileUtils.rm_rf("#{$RunDirs[thread3]}/#{$LocalChoiceFile}") )
              warn_out("Could not delete #{$RunDirs[thread3]}  rm_fr Return code: #{$?}\n" )
            end 
        end

        # Save files from runs that failed, or possibly all runs.
        if ( $gSaveAllRuns || $runFailed || ! $RunResults["run-#{thread3}"]["status"]["success"])
          Dir.chdir($gMasterPath)
          if ( ! Dir.exist?($SaveDirs[thread3]) )

            Dir.mkdir($SaveDirs[thread3])

          else

            FileUtils.rm_rf Dir.glob("#{$SaveDirs[thread3]}/*.*")
          end

          FileUtils.cp( Dir.glob("#{$RunDirs[thread3]}/*.*")  , "#{$SaveDirs[thread3]}" )
          FileUtils.rm_rf ("#{$RunDirs[thread3]}/sim-output")
        end  

        #Update status of this thread.
        $FinishedTheseFiles[$choicefiles[thread3]] = true 
      end

      errs = ""
      currentAction = "Postprocessing results"
      #stream_out ("     - Post-processing results:\n")

      $outputlines = ""

      row = 0 

      # Alternative output in JSON format. Can be memory-intensive 

      $gJSONAllData = Hash.new
      $gJSONAllData = {
        "htap-results"=> Array.new,
        "htap-configuration"=> Array.new
      }

      $gJSONAllData["htap-configuration"] = {
        "git-branch" => $branch_name,
        "git-revision" => $revision_number,
        "runs-by-h2kVersion" => Hash.new
      }  

      Array.new
      $RunResults.keys.each do | run |
        thisRunHash = {
          "result-number"           =>  $gHashLoc+1,
          "status"                 => $RunResults[run]["status"            ],
          "archetype"              => $RunResults[run]["archetype"         ],
          "input"                  => $RunResults[run]["input"             ],
          "output"                 => $RunResults[run]["output"            ],
          "configuration"          => $RunResults[run]["configuration"     ],
          "cost-estimates"         => $RunResults[run]["cost-estimates"    ],
          "meta"                   => $gMetaValues
        }
        
        debug_out (" Result number = #{run} \n")
        debug_out (" ARCH = #{thisRunHash["archetype"]["h2k-File"]} \n")
        
        if ( ! $gTest_params["audit-costs"] ) then 
          thisRunHash["cost-estimates"]["audit"] = nil 
        end 

        # Pick up hot2000 version number for this run, and
        begin 
          h2kVersion = thisRunHash["configuration"]["version"]["HOT2000"]
          if ( ! $gJSONAllData["htap-configuration"]["runs-by-h2kVersion"].key?(h2kVersion) )
            $gJSONAllData["htap-configuration"]["runs-by-h2kVersion"][h2kVersion] = 0
          end

          $gJSONAllData["htap-configuration"]["runs-by-h2kVersion"][h2kVersion] += 1

          if ( ! $RunResults[run]["analysis_BCStepCode"].nil? ) then
            thisRunHash["analysis:BCStepCode"] = $RunResults[run]["analysis_BCStepCode"]
          end
        rescue 
        end  

        $gJSONAllData["htap-results"].push thisRunHash

        if ($RunResults[run]["status"]["success"] == false ) then

          $runFailed = true
          errs=" \n       (!) simulation errors found (!)"
          $msg = "#{$RunResults[run]["configuration"]["ChoiceFile"]} (dir: #{$RunResults[run]["configuration"]["SaveDirectory"]}) - substitute-h2k.rb reports errors"
          $failures.write "#{$msg}\n"
          $FailedRuns.push $msg
          $FailedRunCount = $FailedRunCount + 1
          update_run_status(err_count: $FailedRunCount )
        else
          
          thread = run.gsub(/run-/,"").to_i
          batchStatusUpdate.push $choicefiles[thread]
          $CompletedRunCount = $CompletedRunCount + 1
        end 

        # Increment hash increment too.
        $gHashLoc = $gHashLoc + 1

        if ( $runFailed && $StopOnError ) then
          $RunsDone = true
          $GiveUp = true
        end
        Dir.chdir($gMasterPath)
      end # ends $RunResults.each do 

      # CSV OUTPUT.
      outputlines = ""
      headerLine = ""
      batchSuccessCount = 0

      update_run_status(action: "Writing CSV output" )

      #stream_out("        -> Writing csv output to HTAP-prm-output.csv ... ")

            #-Loop though all instances, and compute 
      $RunResults.each do |run,data|

        debug_out "Run - #{run}\n"
        # Only write out data from successful runs - this helps prevent corrupted database
        next if (  data.nil? || data["status"].nil? || data["status"]["success"] =~ /false/ || data["status"]["success"] == false )
        batchSuccessCount += 1
        debug_out "processing:\n"
        debug_out "  #{data.pretty_inspect} \n"

        data.keys.sort.each do | section |
          data[section].keys.sort.each do |subsection|
            debug_out " . location #{section} : #{subsection} \n"

            contents = data[section][subsection]

            if ( section =~ /cost-estimates/ &&
              ( subsection =~ /byAttribute/ ||
                subsection =~ /byBuildingComponent/
              )
              ) then
              debug_out " . location #{section} : #{subsection} \n"
              contents.each do | colName, colValue |

                headerLine.concat("#{section}|#{subsection}|#{colName},") if ( ! headerOut)

                if ( colValue.is_a?(Hash) || colValue.is_a?(Array) ) then
                  debug_out "> extended output only\n"
                  result = "Details in JSON output"
                else
                  debug_out "> core output \n#{colValue}\n"
                  result = colValue
                end
                outputlines.concat("#{result},")
              end

            else

              headerLine.concat("#{section}|#{subsection},") if ( ! headerOut)

              if ( contents.is_a?(Hash) || contents.is_a?(Array) ) then
                debug_out "> extended output only\n"
                result = "Details in JSON output"
              else
                debug_out "> core output \n#{contents}\n"
                result = contents
              end

              outputlines.concat("#{result},")
            end
          end
        end
        if ( ! headerOut )
          headerLine.concat("\n")
          $fCSVout.write(headerLine)
          headerOut = true
        end
        outputlines.concat("\n") 

      # End of $RunResults.each do
      end

      debug_off 
      $fCSVout.write(outputlines)
      $fCSVout.flush
      #stream_out ("done.\n") 

      if ($gJSONize )
        update_run_status(action: "Writing JSON output" )
        # stream_out("        -> Writing JSON output to HTAP-prm-output.json... ")
        nextBatch = JSON.pretty_generate($gJSONAllData)
        
        configStarted = false 
        # When we append data to the current file on subsequent batches, 
        # we need to overwrite the contents of the "htap-configuraton": {} 
        # hash. To do so, save the contents of hash and compute its 
        # length
        configtxt = "  ],\n"
        nextBatch.each_line  do | line  |
          configStarted = true if ( line =~ /"htap-configuration": \{/ )
          configtxt += line if ( configStarted ) 
        end 
        # add a line ending at the end
        configtxt += "\n"
        # Convert unix line-endings to windows, to match what we write out.
        configtxt.gsub!(/\n/, "\r\n")

        # Compute the length and save for 
        thisCount = configtxt.length
        
        debug_out ("first line? #{firstJSONLine}\n") 

        if ( ! firstJSONLine )

          debug_out ("Rewinding #{lastCount} lines\n")
          
          fJSONout.seek(-lastCount, :CUR)
          
          txtOut = ",\n"
  
          
   
          txtOut += nextBatch.gsub(/^\{\n^\s*\"htap-results\":\s*\[\n/, "")

        else 
          
          txtOut = nextBatch
        end 

        lastCount = thisCount 
        debug_out ("setting rewind flag to #{lastCount}\n")
        debug_off
        firstJSONLine = false
        fJSONout.write txtOut
        fJSONout.flush
        #stream_out("done.\n")
      end

      if ($gLEEPPathwayExport )
        update_run_status(action: "Exporting Pathway file")
        #stream_out("        -> Exporting LEEP Pathway Data ... ")
        LEEPPathways.ExportPathwayData()
        #stream_out("done.\n")
      end 

      update_run_status(action: "Updating HTAP.resume file")
      #stream_out("        -> updating HTAP-prm.resume ... ")
      list = ""
      batchStatusUpdate.each do | run |
        list += "#{run}\n"
      end 
      $fResume.write list 
      batchStatusUpdate.clear 
      #stream_out("done.\n")
      $fResume.flush 

     $failures.flush

     $RunResults.clear

     batchLapsedTime = "#{(Time.now - batchStartTime).round(0)}"

     #stream_out ("     - Batch processing time: #{batchLapsedTime}.#{errs} \n")

     HTAPConfig.countSuccessfulEvals(batchSuccessCount)
     HTAPConfig.writeConfigData()

     update_run_status(action: "Batch complete")

     if ( ! $FinishedTheseFiles.has_value?(false) )

       $RunsDone = true

       update_run_status(action: "Job complete")

     end 
  end

  fJSONout.close
  Dir.chdir($gMasterPath)  

  if ( $GiveUp ) then
    stream_out(" \n - HTAP-prm: runs terminated due to error ---------- \n")
  # else
  #   stream_out(" \n - HTAP-prm: runs finished ------------------------- \n")
  end

  LEEPPathways.CloseOutputFiles() if ($gLEEPPathwayExport)

  if ( ! $gDebug ) then
     # stream_out (" - Deleting working directories... ")
     FileUtils.rm_rf Dir.glob("HTAP-work-*")
     # stream_out("done. \n")
  end
end 

=begin rdoc
=========================================================================================
  END OF ALL METHODS
=========================================================================================
=end 

#-------------------------------------------------------------------
# Help text. Dumped if help requested, or if no arguments supplied.
#-------------------------------------------------------------------

# Dump help text, if no argument given 

$cmdlineopts = Hash.new
$gTest_params = Hash.new        # test parameters
$gTest_params["verbosity"] = "verbose"  

$gHTAPOptionsFile = ""
$gRulesetsFile = ""

$gSubstitutePath = "C:\/HTAP\/substitute-h2k.rb"
$gWarn = "1"
$gOutputFile = ""
$gResumeFile = "HTAP-prm.resume"
$gOutputJSON = "HTAP-prm-output.json"
$gFailFile = "HTAP-prm-failures.txt"
$gSaveAllRuns = false
$bResume = false 
$bReadyToResume = false 
$gRunsAleadyCompleted = Array.new 

$gTest_params["audit-costs"] = false

$gLogDebugMsgs = false 

$gRunDefinitionsProvided = false
$gRunDefinitionsFile = ""

$gNumberOfThreads = 3
$promptBeforeProceeding = false
$StopOnError = false

$gLEEPPathwayExport = false 

#=====================================================================================
# Parse command-line switches.
#=====================================================================================
optparse = OptionParser.new do |opts|

   opts.separator " "
   opts.separator " Example: htap-prm.rb -o path\\to\\htap-options.json -r path\\to\\runfile.run -v "
   opts.separator " "
   opts.separator " Required inputs:"
   opts.separator " "

   #opts.on("-o", "--options FILE", "Specified options file.") do |o|
   #   $cmdlineopts["options"] = o
   #   $gHTAPOptionsFile = o
   #   if ( !File.exist?($gHTAPOptionsFile) )
   #      fatalerror("Valid path to option file must be specified with --options (or -o) option!")
   #   end
   #end

   opts.on("-r", "--run-def FILE", "Specified run definitions file (.run)") do |o|
      $gRunDefinitionsProvided = true
      $gRunDefinitionsFile = o
      if ( !File.exist?($gRunDefinitionsFile) )
         fatalerror("Valid path to run definitions (.run) file must be specified with --run-def (or -r) option!")
      end
   end

   opts.separator "\n Configuration options: "
   opts.separator " "

   opts.on("-t", "--threads X", "Number of threads to use") do |o|
      $gNumberOfThreads = o.to_i
      if ( $gNumberOfThreads < 1 )
        $gNumberOfThreads = 1
      end
   end

   opts.separator " "
   opts.on("--compute-costs", "Estimate costs for assemblies using","costing database.") do |o|
      $gComputeCosts = true
   end

   opts.separator " "
   opts.on(
     "-c", "--confirm", "Prompt before proceeding with run. After ","estimating the size and duration of the run, ","HTAP will ask for conformation before continuing.",
   ) do

     $promptBeforeProceeding = true
   end

   opts.separator " "
   opts.on("-e", "--extra-output", "Report additional data on archetype and part-load","characteristics") do
      $cmdlineopts["extra-output"] = true
      $gExtendedOutputFlag = "-e"
   end

 	 opts.on( "--hourly-output", "Extrapolate hourly output from HOT2000's binned data.") do
       $cmdlineopts["hourly_output"] = true
       $gHourlySimulationFlag = "-g"
       warn_out("Hourly results will saved in HTAP-Sim-X folders. Activating --keep-all-files option to make sure results are preserved.")
       $gSaveAllRuns = true
   end

   opts.separator " "
   opts.on("-k", "--keep-all-files", "Preserve all files (including modified .h2k ","files) in HTAP-sim-X directories. Otherwise, only",
                                     "files that generate errors will be saved.",
                                     ) do
      $gSaveAllRuns = true
   end

  opts.separator " "
   opts.on("-j", "--json", "Provide output in JSON format","(htap-prm-output.json) in additon to .csv output.",
                                            "Slows HTAP down, and make json output from", "large runs unwieldly."
                                         ) do
   
      $gJSONize = true
   end 

 opts.separator " "
   opts.on("-l", "--LEEP-Pathways", "Export tables for use in LEEP pathways tool.") do

      $gLEEPPathwayExport = true 
     
   end
opts.separator " "
   opts.on("-a", "--include_audit_data", "Include detailed audit data for costing ", "calculations in JSON output. Slows HTAP down,",
                                         "and make json output unwieldy on",
                                         "large runs.") do

      $cmdlineopts["audit_data"] = true
      $gTest_params["audit-costs"] = true
   end
opts.separator " "
   opts.on( "--resume", "Attempt to resume prior interrupted run","(experimental feature)") do

      $cmdlineopts["resume"] = true
      $bResume = true 
   end   

   #opts.on("-v", "--verbose", "Output progress to console.") do
   #   $cmdlineopts["verbose"] = true
   #   $gTest_params["verbosity"] = "verbose"
   #end

   opts.separator "\n Debugging options: "
opts.separator " "
   opts.on("--stop-on-error", "Terminate run upon first error encountered.") do

      $StopOnError = true

   end 

   opts.on("--log-debug-msgs", "Log debugging messages from programs. Use with --keep-all-files to see",
                               "substiture-h2k.rb debugging output too.") do

    $gLogDebugMsgs = true

   end   

   #opts.on("-w", "--warnings", "Report warning messages") do
   #   $gWarn = true
   #end

   #opts.on("-s", "--substitute-h2k-path FILE", "Specified path to substitute RB ") do |o|
   #   $cmdlineopts["substitute"] = o
   #   $gSubstitutePath = o
   #   if ( !File.exist?($gSubstitutePath) )
   #      fatalerror("Valid path to substitute-h2k,rb script must be specified with --substitute-h2k-path (or -s) option!")
   #   end
   #end

   #opts.on("-ss", "--snailStart X", "Optional delay (X sec) between spawning threads on the ",
   #                                 "first batch (and ignored on subsequent batches). May improve",
   #                                 "stability on highly parallel machines with slow disk I/O." ) do |o|
   #   $snailStart = true
   #   $snailStartWait = o.to_f
   #end

   opts.separator ""

   opts.on("-h", "--help", "Show help message") do
      puts opts
      exit()
   end 

   opts.separator ""
end  

if ARGV.empty? then
   ARGV.push "-h"
end
optparse.parse!    # Note: parse! strips all arguments from ARGV and parse does not

stream_out(drawRuler("A simple parallel run manager for HTAP"))
# reportSRC($branch_name, $revision_number)

$RunNumber = 0
$processed_file_count = 0
$RunDirs  = Array.new
$SaveDirs = Array.new
$FailedRuns  = Array.new
$RunDirectoryRoot  = "HTAP-work"
$SaveDirectoryRoot = "HTAP-sim"
$RunResultFilenameV2 = "h2k_run_results.json"
$RunResultFilename = "substitute-h2k_summary.out" 

              #Hash.new{ |h,k| h[k] = Hash.new{|h,k| h[k] = Array.new}}

$RunsNeeded = Array.new
$RunTheseFiles = Array.new
$FinishedTheseFiles = Hash.new 

# Generate working directories
#stream_out(" - Creating working directories (HTAP_work-0 ... HTAP_work-#{$gNumberOfThreads-1})  \n")
stream_out("\n Initialization: \n")

#2021djf - output file is based on input run file name
baserun = $gRunDefinitionsFile.gsub(".run", "")
$gOutputFile = baserun + ".csv"
if File.file?($gOutputFile) then
  baserun = baserun + Time.now.strftime("%Y-%m-%d %H%M")
end

#stream_out "base = #{baserun}  and output=#{$gOutputFile}"

if ( $bResume ) then 
  warn_out("Option `--resume` is experimental. Talk to Alex Ferguson before putting to use.")
  info_out("Resuming prior HTAP run")
  log_out("Attempting to resume prior run")
  
  # Read resume file, and then re-open it for appending more data to
  begin   
    $fResume = File.open($gResumeFile, 'r')
    $fResume.each do | line | 
      line.strip!       
      $gRunsAleadyCompleted.push line  
    end 
    $fResume.close 
    $fResume = File.open($gResumeFile, 'a')
  rescue
    fatalerror ("`--resume` option invoked, but could not parse #{$gResumeFile}.")
  end 
  
  # Open CSV file for writing. 
  begin
    $fCSVout= File.open($gOutputFile, 'a') 
  rescue 
    fatalerror( "Could not open CSV output (#{$gOutputFile}) for appending data.\n")
  end 
  
  # If LEEP-pathway data is to be exported, try to parse existing files.
  if ( $gLEEPPathwayExport ) then 
    LEEPPathways.OpenOutputFiles("append")
  end 

  $bReadyToResume = true 
  stream_out("    - Attempting to resume prior run\n")
else 
 
  # Open csv file for writing 
  begin
    $fCSVout = File.open($gOutputFile, 'w') 
  rescue
    fatalerror( "Could not open CSV output file (#{$gOutputFile})\n")
  end 

  # Open resume file for writing 
  begin 
    $fResume = File.open($gResumeFile, 'w')
    $fResume.write ("List of runs previously completed:\n")
  rescue
    warn_out( "Could not open resume file  (#{$gResumeFile}) - runs cannot be resumed.\n")
  end 

  #Open LEEP pathways export files, if needed
  LEEPPathways.OpenOutputFiles("overwrite") if ($gLEEPPathwayExport)

  $bReadyToResume = false
end 

for prethread in 0..$gNumberOfThreads-1

    $RunDirName = "#{$RunDirectoryRoot}-#{prethread}"
    $RunDirs[prethread] = $RunDirName
end 

$failures = File.open($gFailFile, 'w')

$gMeshRunDefs = Hash.new

#==================================================================
# Parse definition file and compute run job
#==================================================================
runLength = 0
if ( ! $gRunDefinitionsProvided )
  # Basic mode: Run a set of .choice files that are provided as arguements to the command line
  #  - load choice files into array for now
  ARGV.each do |choicefile|
    if ( choicefile =~ /.*choices$/ )
      $RunsNeeded.push choicefile
    else
      stream_out "    ! Skipping: #{choicefile} ( not a '.choice' file? ) \n"
    end
  end

  fileorgin = "supplied"

else

  # Smarter mode - embark on run according to definitions in the .run file (mesh supported for now)
  #  - First parse the *.run file

  #stream_out ("    - Reading HTAP run definition from #{$gRunDefinitionsFile}... \n")

  parse_def_file($gRunDefinitionsFile)

  options = HTAPData.getOptionsData()
  bErr = false 
  $gRunUpgrades.keys.each do | attribute |
    next if HTAPData.isAttribIgnored( attribute )
    if ( not HTAPData.isAttribValid(options, attribute) ) then 
      bErr = true 
      err_out ("Unknown attribute '#{attribute}'")
    else 
      choices = $gRunUpgrades[attribute]
      choices.each do | choice | 
        if ( not HTAPData.isChoiceValid(options, attribute, choice) ) 
          err_out( "Unknown choice '#{choice}' for attribute '#{attribute}'")
          bErr = true 
        end
      end 
    end 
  end 

  $gLocations.each do | location | 
     if ( not HTAPData.isChoiceValid(options, "Opt-Location", location) ) 
        err_out( "Unknown location '#{location}' for attribute 'Opt-Location'")
        bErr = true 
     end
  end    

  fatalerror("Attributes and choices do not match those in options file") if bErr
  options.clear 

  debug_out("> Options file #{$gHTAPOptionsFile}")

  $archetypeFiles = Array.new
  $Folder = $gArchetypeDir
  debug_out "> #{$Folder}\n"
  $gArchetypes.each do |arch_entry|
    Dir["#{$Folder}/#{arch_entry}"].each {|file| $archetypeFiles.push file}
  end   

  #debug_out " ARCH: \n#{$archetypeFiles[0].pretty_inspect}\n"

  #stream_out (" done.\n") 

  case $gRunDefMode
  when  "mesh", "sample"

    # estimate the number of combonations
    #debug_out
    runningProduct = 1
    stream_out "    - Evaluating combinations for #{$gRunDefMode} run \n"
    stream_out "          * "+$gLocations.length.to_s.ljust(10)+" (options for Location)\n" #if ($gLocations.length>1 )
    stream_out "          * "+$archetypeFiles.length.to_s.ljust(10)+" (options for Archetypes)\n" #if ($archetypeFiles.length>1 )
    stream_out "          * "+$gRulesets.length.to_s.ljust(10)+" (options for Rulesets)\n" #if ($gRulesets.length>1 )
    $gRunUpgrades.each do | attribute, choices |
       runningProduct *= choices.length
       if ( choices.length > 1 ) then
          stream_out "          * "+choices.length.to_s.ljust(10)+" (options for #{attribute})\n"
       end
    end
    runningProduct *= $gLocations.length
    runningProduct *= $archetypeFiles.length
    runningProduct *= $gRulesets.length
    stream_out "          ----------------------------------------------------------\n"
    stream_out "           #{runningProduct.to_s.ljust(15)} Total combinations \n" 

    if ( runningProduct < 1) then
      fatalerror ( " No combinations to run.")
    end 

    if ($gRunDefMode == "mesh" ) then
      $RunsNeeded = $gGenChoiceFileList
    else

      $pop_size= $gGenChoiceFileList.count

      debug_out "SAMPLE PARAMETERS: \n"
      debug_out " - population       : #{$pop_size} \n"
      debug_out " - requested sample : #{$sample_size} \n"
      debug_out " - Seeded?          : #{$sample_seeded} \n"
      debug_out " - Seedval?         : #{$sample_seed_val} \n"

      if ( $pop_size.to_i < $sample_size.to_i ) then

        warn_out("Sample run method - requested sample size (#{$sample_size}) exceeds size of parameter space (#{$pop_size}).\n")
        warn_out("Run will only return #{$pop_size} results. \n")

        $sample_size = $pop_size
      end

      if ( $sample_seeded ) then

        $RunsNeeded = $gGenChoiceFileList.shuffle(random: Random.new($sample_seed_val.to_i)).first($sample_size.to_i)

      else
        $RunsNeeded = $gGenChoiceFileList.shuffle.first($sample_size.to_i)
      end

      debug_out ($RunsNeeded.pretty_inspect)

      stream_out ("    - Sampled #{$sample_size.to_i} combinations for run\n")
    end

  when "parametric"

    # estimate the number of combonations
    #debug_out
    runningSum = 1
    runningProduct = 1
    stream_out "    - Evaluating combinations for parametric run \n"
    stream_out "          * "+$gLocations.length.to_s.ljust(10)+"  { # of options for Location }\n" #if ($gLocations.length>1 )
    stream_out "          * "+$archetypeFiles.length.to_s.ljust(10)+"  { # of options for Archetypes }\n" #if ($archetypeFiles.length>1 )
    stream_out "          * "+$gRulesets.length.to_s.ljust(10)+"  { # of options for Rulesets }\n" #if ($gRulesets.length>1 )
    stream_out "          *   (    1          { base option for all choices }\n"
    $gRunUpgrades.each do | attribute, choices |
       if ( choices.length > 1 ) then
          runningSum += choices.length - 1
          stream_out "                +  "+(choices.length-1).to_s.ljust(10)+" { additional options for #{attribute} }\n"
       end
    end
    stream_out "               )\n"
    runningProduct *= $gLocations.length
    runningProduct *= $archetypeFiles.length
    runningProduct *= $gRulesets.length
    runningProduct *= runningSum
    stream_out "          ----------------------------------------------------------\n"
    stream_out "           #{runningProduct.to_s.ljust(15)} Total combinations \n"
  end  

  #if ($choicesInMemory )
  #  stream_out (" done. ( created #{$gGenChoiceFileNum} combinations )\n")
  #else
  #  stream_out (" done. (created #{$gGenChoiceFileNum} '.choice' files)\n")
  #end  

  fileorgin = "generated"
end

$batchCount = 0
goodEst, evalSpeed = HTAPConfig.getPrmSpeed()
evalSpeed = 30.0 if ( ! goodEst )
estDuration = runningProduct * evalSpeed / [$gNumberOfThreads, runningProduct].min

stream_out("    - Guesstimated time requirements ~ #{formatTimeInterval(estDuration)} (including pre- & post-processing) using #{$gNumberOfThreads} threads\n")
$waitTime = 0
if ( $promptBeforeProceeding )
  waitstart =Time.now
  stream_out("\n    ? Continue with run ? [yes] \r")
  exitQuery = input "    ? Continue with run ? [yes] "
  stream_out("\n")
  waitend = Time.now

  if ( exitQuery =~ /y[es]*/i ||  exitQuery == "" || exitQuery.nil? )
  else
    log_out ("User terminated run with response #{exitQuery}\n")
    fatalerror("Run terminated by user")
  end
  $waitTime = waitend - waitstart
  log_out ("Waited for #{formatTimeInterval($waitTime)}\n")
end

case $gRunDefMode
when  "mesh", "sample"
  $combosRequired = runningProduct
  $combosGenerated = 0
  $combosSinceLastUpdate = 0
  $comboInterval = 1000

  create_mesh_cartisian_combos(-3) 

  stream_out ("    - Creating #{$gRunDefMode} run for #{$combosRequired} combinations --- #{$combosGenerated} combos created.\n")

when "parametric"

    $combosRequired = runningProduct
    $combosGenerated = 0
    $combosSinceLastUpdate = 0
    $comboInterval = 1000
    if ( runningProduct <  1 ) then
      fatalerror ( " No combinations to run.")
    end

#    stream_out ("    - Creating parametric run for #{$combosRequired} combinations --- #{$combosGenerated} combos created.\r")

    create_parametric_combos()
#    stream_out ("    - Creating parametric run for #{$combosRequired} combinations --- #{$combosGenerated} combos created.\n")
    $RunsNeeded = $gGenChoiceFileList
end 

if ( $bResume )  
  $RunsNeeded.each do | run | 
     $RunTheseFiles.push run unless ( $gRunsAleadyCompleted.include?(run) ) 
  end 
  numOfRunsRequired = $RunTheseFiles.length
  numOfRunsPrevCompleted = $RunsNeeded.length - numOfRunsRequired
  info_out(" Found #{numOfRunsPrevCompleted} runs were already done; #{numOfRunsRequired} remaining")
  stream_out ( "    - [RESUMING] Found #{numOfRunsPrevCompleted} runs were already done; #{numOfRunsRequired} remaining\n")
else 
  $RunTheseFiles = $RunsNeeded
  numOfRunsRequired = $RunTheseFiles.length
end  

if ( numOfRunsRequired <= 0  ) then 
  fatalerror "No runs to be completed!"
end    

# stream_out("    - Deleting prior HTAP-work...")
FileUtils.rm_rf Dir.glob("HTAP-work-*")
# stream_out (" done.\n")
# stream_out(" and HTAP-sim directories... ")
FileUtils.rm_rf Dir.glob("HTAP-sim-*")
# stream_out (" done.\n") 

# if ( $choicesInMemory )
#   stream_out("    - Preparing to process #{$RunTheseFiles.count} #{fileorgin} combinations using #{$gNumberOfThreads} threads  \n")
# else
#   stream_out("    - Preparing to process #{$RunTheseFiles.count} #{fileorgin} '.choice' files using #{$gNumberOfThreads} threads  \n")
# end 

#==================================================================
# Process cases 
#==================================================================
run_these_cases($RunTheseFiles)

#==================================================================
#
#================================================================== 

#==================================================================
# Report on progress
#==================================================================
if ( ! $GiveUp ) then
  stream_out (" - HTAP-prm: Run complete ----------------------- \n")
else
  stream_out (" - HTAP-prm: Error encountered, run terminated -- \n")
end

if $FailedRunCount >0
  stream_out ("    + #{$FailedRunCount} files failed to run \n")
else
  stream_out ("    + All files were evaluated successfully. \n")

end
# if ( $FailedRunCount > 0 )
#   stream_out ("\n ** The following files failed to run: ** \n")
#   $FailedRuns.each do |errorfile|
#     stream_out ("     + #{errorfile} \n")
#   end
#   err_out ("#{$FailedRunCount} files failed to run.")
# end

if ( $CompletedRunCount> 0  &&  $ThreadsNeeded > 0  )
  lapsedTime = Time.now - $startProcessTime - $waitTime
  timePerEvaluation = lapsedTime /  $CompletedRunCount * $ThreadsNeeded
  HTAPConfig.setPrmSpeed(timePerEvaluation)
end 

if ( HTAPConfig.checkOddities() ) then
  info_out(" Fun fact: HTAP has performed #{HTAPConfig.reportSuccessfulEvals()} successful hot2000 simulations for you since #{HTAPConfig.getCreationDate()}.")
end
# Close output files (JSON output dumped in a single write - already closed at this point.
$fCSVout.close
$fResume.close 
$failures.close
HTAPConfig.setCreationDate()
HTAPConfig.writeConfigData()

ReportMsgs()

stream_out ("\n")

exit
