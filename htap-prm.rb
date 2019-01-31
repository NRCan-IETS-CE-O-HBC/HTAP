

#!/usr/bin/env ruby
# ************************************************************************************
# This is a really rudamentary run-manager developed as a ...
# ************************************************************************************

require 'optparse'
require 'ostruct'
require 'timeout'
require 'fileutils'
require 'pp'
require 'json'
require 'set'
require 'rexml/document'

require_relative 'include/msgs'
require_relative 'include/constants'

include REXML   # This allows for no "REXML::" prefix to REXML methods

$gRunUpgrades         = Hash.new
$gOptionList          = Array.new
$gOptionListLimit     = Hash.new
$gOptionListIterators = Hash.new

$gRulesets   = Array.new
$gArchetypes = Array.new
$gLocations  = Array.new

$gChoiceFileSet = Hash.new

$gArchetypeDir = "C:/HTAP/archetypes"
$gArchetypeHash = Hash.new
$gRulesetHash   = Hash.new
$gLocationHash  = Hash.new
$gExtendedOutputFlag = ""

$gGenChoiceFileBaseName = "sim-X.choices"
$gGenChoiceFileDir = "./gen-choice-files/"
$gGenChoiceFileNum = 0
$gGenChoiceFileList = Array.new

#default
$gRunDefMode   = "mesh"
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

$program = "htap-prm.rb"

=begin rdoc
=========================================================================================
 METHODS: Routines called in this file must be defined before use in Ruby
          (can't put at bottom of listing).
=========================================================================================
=end
def fatalerror( err_msg )
# Display a fatal error and quit. -----------------------------------
   if ($gTest_params["logfile"])
      $fLOG.write("\nsubstitute-h2k.rb -> Fatal error: \n")
      $fLOG.write("#{err_msg}\n")
   end
   print "\n=========================================================\n"
   print "substitute-h2k.rb -> Fatal error: \n\n"
   print "     #{err_msg}\n"
   print "\n\n"
   print "substitute-h2k.rb -> Other Error or warning messages:\n\n"
   print "#{$ErrorBuffer}\n"
   exit() # Run stopped
end


=begin rdoc
# ----------------------------------------------------------------------------
# parse Def file
# This function parses a prm run definition file (such as HTAP-prm-trialmesh.run)
# and loads the attirbute: options info into a hash.
# ----------------------------------------------------------------------------
=end


def parse_def_file(filepath)

  $runParamsOpen = false;
  $runScopeOpen  = false;
  $UpgradesOpen  = false;

  $WildCardsInUse = false;

  rundefs = File.open(filepath, 'r')

  rundefs.each do | line |

    $defline = line
    $defline.strip!
    $defline.gsub!(/\!.*$/, '')
    $defline.gsub!(/\s*/, '')
    $defline.gsub!(/\^/,  '')

    if ( $defline !~ /^\s*$/ )

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

        else

          # definitions
          $token_values = Array.new
          $token_values = $defline.split("=")



          if ( $RunParamsOpen && $token_values[0] =~ /archetype-dir/i )
            # Where are our .h2k files located?

            $gArchetypeDir = $token_values[1]


          end


          if ( $RunParamsOpen && $token_values[0] =~ /run-mode/i )
            # This does nothing only 'mesh' supported for now!!!
            $gRunDefMode = $token_values[1]

            if ( ! ( $gRunDefMode =~ /mesh/ ||
                     $gRunDefMode =~ /parametric/ ||
                     $gRunDefMode =~ /parmetric-by-scope/     ) ) then
              fatalerror (" Run mode #{$gRunDefMode} is not supported!")
            end

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

          end

          if ( $UpgradesOpen )

            option  = $token_values[0]
            choices = $token_values[1].to_s.split(",")

            debug_out " #{option} len = #{choices.grep(/\*/).length} \n"

            if ( choices.grep(/\*/).length > 0  ) then

              $WildCardsInUse = true

            end

            $gRunUpgrades[option] = choices

            $gOptionList.push option


          end


      end  #Case

    end # if ( $defline !~ /^\s*$/ )

  end # rundefs.each do | line |


  # Check to see if run options contians wildcards


  if ( $WildCardsInUse ) then

    if ( ! $gOptionFile =~ /\.json/i ) then
      fatalerror ("Wildcard matching is only supported with .json option files")
    end

    fOPTIONS = File.new($gOptionFile, "r")
    if fOPTIONS == nil then
       fatalerror(" Could not read #{filename}.\n")
    end

    $OptionsContents = fOPTIONS.read
    fOPTIONS.close

    $JSONRawOptions = JSON.parse($OptionsContents)
    $OptionsContents = nil

    $gRunUpgrades.keys.each do |key|
      debug_out( " Wildcard search for #{key} => \n" )




      $gRunUpgrades[key].clone.each do |choice|

        debug_out (" ? #{choice} \n")

        if ( choice =~ /\*/ ) then

          $pattern = choice.gsub(/\*/, ".*")

          debug_out "              Wildcard matching on #{key}=#{$pattern}\n"

          # Matching

          $SuperSet = $JSONRawOptions[key]["options"].keys

          $gRunUpgrades[key].delete(choice)

          $gRunUpgrades[key].concat $SuperSet.grep(/#{$pattern}/)


        end

      end


    end

      $JSONRawOptions = nil

  end




  # What if archetypes are defined using a wildcard?






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
      stream_out ("    - Creating mesh run for #{$combosRequired} combinations --- #{$combosGenerated} combos created so far...\r")
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

  $Folder = $gArchetypeDir

  startSet = Hash.new

  parameterSpace = Hash.new

  parameterSpace = $gRunUpgrades.clone




  parameterSpace.keys.each do |attribute|

    startSet[attribute] =  parameterSpace[attribute][0]

  end

  debug_out " > START SET:\n#{startSet.pretty_inspect}\n"


  $gArchetypes.each do | archetype |

    $ArchetypeFiles = Dir["#{$Folder}/#{archetype}"]
    $ArchetypeFiles.each do |h2kpath|

      $gLocations.each do | location |
        $gRulesets.each do | ruleset |

          debug_out (" Setting parametric scope for #{archetype} / #{location} /#{ruleset} \n")

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
          # Parametric variations....

          parameterSpace.keys.each do |attribute|

            debug_out ("PARAMETRIC: #{attribute} has #{parameterSpace[attribute].length} entries\n")

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

              if ( $combosSinceLastUpdate == $comboInterval )
                stream_out ("    - Creating mesh run for #{$combosRequired} combinations --- #{$combosGenerated} combos created so far...\r")
                $combosSinceLastUpdate = 0


              end

            end


          end

        end

      end
    end
  end



  debug_out (" ----- PARAMETRIC RUN: PARAMETER SPACE ----\n#{parameterSpace.pretty_inspect}\n")

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

  $CompletedRunCount = 0
  $FailedRunCount = 0

  ## Create working directories

  $headerline = ""
  $outputHeaderPrinted = false


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

  startProcessTime = Time.now

  while  ! $RunsDone

      $batchCount = $batchCount + 1

      batchStartTime = Time.now
      fracCompleted = $choicefileIndex.to_f/numberOfFiles.to_f
      debug_out ("> BATCH #{$batchCount}, Index: #{$choicefileIndex}, Complete: #{fracCompleted*100}% \n")
      timeMsg = ""
      if ( fracCompleted > 0.0 ) then
        timeNow = Time.now
        timeLapsed = (timeNow - startProcessTime)
        timeRemaining =   timeLapsed / fracCompleted - timeLapsed


        debug_out "Time Differential = #{(timeNow - startProcessTime)}\n"
        if ( timeRemaining > 86400 )
          timeMsg = ", ~#{(timeRemaining / 86400).round(2)} days remaining"

        elsif ( timeRemaining > 3600 )
          timeMsg = ", ~#{(timeRemaining / 3600).round(1)} hours remaining"

        elsif ( timeRemaining > 60 )
          timeMsg = ", ~#{(timeRemaining / 60).round(0)} minutes remaining"

        elsif ( timeRemaining > 60 )
          timeMsg = ", ~#{(timeRemaining).round(0)} seconds remaining"


        end
      end

      stream_out ("   + Batch #{$batchCount} ( #{(fracCompleted*100).round(4)}% done, #{$choicefileIndex}/#{numberOfFiles} files processed so far#{timeMsg} ...) \n" )
      if ( $batchCount == 1 && $snailStart ) then

        stream_out ("   |\n")
        stream_out ("   +-> NOTE: \"SnailStart\" is active. Waiting for #{$snailStartWait} seconds between threads (on first batch ONLY!) \n\n")

      end

      # Empty arrays for current batch.
      $choicefiles.clear
      $PIDS.clear
      $SaveDirs.clear



      # Compute the number of threads we will start: lesser of a) files remaining, or b) threads allowed.
      $ThreadsNeeded = [$FinishedTheseFiles.count {|k| k.include?(false)}, $gNumberOfThreads].min

      #=====================================================================================
      # Multi-threaded runs - Step 1: Spawn threads.
      for thread in 0..$ThreadsNeeded-1

        # For this thread: Get the next choice file in the batch.
        $choicefiles[thread] = current_task_files[$choicefileIndex]

        # Get the name of the .h2k file for this thread.
        $H2kFile = $gArchetypeHash[$choicefiles[thread]]
        $Ruleset = $gRulesetHash[$choicefiles[thread]]
        $Location = $gLocationHash[$choicefiles[thread]]

        count = thread + 1
        #stream_out ("     - Starting thread : #{count}/#{$ThreadsNeeded} for file #{$choicefiles[thread]} ")
        stream_out ("     - Starting thread #{count}/#{$ThreadsNeeded} for sim ##{$choicefileIndex+1} ")


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
              # Delete contents, but not H2K folder
              FileUtils.rm_r Dir.glob("#{$RunDirectory}/*.*")
          end




          # Copy choice and options file into intended run directory...
          if $choicesInMemory
            choicefile = File.open("#{$RunDirectory}/#{$choicefiles[thread]}", 'w')
            choicefile.write ($ChoiceFileContents[$choicefiles[thread]])
            choicefile.close
          else
            FileUtils.cp($choicefiles[thread],$RunDirectory)
          end


          FileUtils.cp($gOptionFile,$RunDirectory)
          FileUtils.cp("#{$gArchetypeDir}\\#{$H2kFile}",$RunDirectory)

          if ( $gComputeCosts ) then
            # Think about error handling.
            FileUtils.cp($gCostingFile,$RunDirectory)
          end
          # ... And get base file names for insertion into the substitute-h2k.rb command.
          $LocalChoiceFile  = File.basename $choicefiles[thread]
          $LocalOptionsFile = File.basename $gOptionFile



          # CD to run directory, spawn substitute-h2k thread and save PID
          Dir.chdir($RunDirectory)

          if ( $gDebug )
            FileUtils.cp("#{$H2kFile}","#{$H2kFile}-p0")
          end



          # Possibly call another script to modify the .h2k and .choice files

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

          $SubCostFlag = ""
          if ($gComputeCosts ) then
            $SubCostFlag = "--auto_cost_options"
          end
          cmdscript =  "ruby #{$gSubstitutePath} -o #{$LocalOptionsFile} -c #{$LocalChoiceFile} -b #{$H2kFile} --report-choices --prm #{$gExtendedOutputFlag} #{$SubCostFlag} 2>&1"

          # Save command for invoking substitute [ useful in debugging ]
          $cmdtxt = File.open("cmd.txt", 'w')
          $cmdtxt.write cmdscript
          $cmdtxt.close

          #debug_out(" ( cmd: #{cmdscript} |  \n")


          pid = Process.spawn( cmdscript, :out => File::NULL, :err => "substitute-h2k-errors.txt" )




          $PIDS[thread] = pid

          stream_out("(PID #{$PIDS[thread]})...")




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

            stream_out ("  *SS-Wait")
            for wait in 1..5

              stream_out (".")

              sleep($snailStartWait/5)

            end

            stream_out( "*")

          end


        stream_out (" done. \n")
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

      end


      # Multi-threaded runs - Step 2: Monitor thread progress

      #=====================================================================================
      # Wait for threads to complete

      for thread2 in 0..$ThreadsNeeded-1

         count = thread2 + 1

         stream_out ("     - Waiting on PID: #{$PIDS[thread2]} (#{count}/#{$ThreadsNeeded})...")

          Process.wait($PIDS[thread2], 0)

          status = $?.exitstatus

          if ( status == 0 )

            stream_out (" done.\n")

          else

            stream_out (" FAILED! (Exit status: #{status})\n")

            $RunResults["run-#{thread2}"]["status"]["success"] = false
            $RunResults["run-#{thread2}"]["status"]["errors"].push  " Run failed - substitute-h2k.rb returned status #{status}"

          end

      end

      #=====================================================================================
      # Multi-threaded runs - Step 3: Post-process and clean up.



      for thread3 in 0..$ThreadsNeeded-1
        #debug_on
        count = thread3 + 1
        stream_out ("     - Reading results files from PID: #{$PIDS[thread3]} (#{count}/#{$ThreadsNeeded})...")

        Dir.chdir($RunDirs[thread3])


        $RunResults["run-#{thread3}"]["configuration"]["RunNumber"]      = "#{$RunNumbers[thread3].to_s}"
        $RunResults["run-#{thread3}"]["configuration"]["RunDirectory"]   = "#{$RunDirs[thread3].to_s}"
        $RunResults["run-#{thread3}"]["configuration"]["SaveDirectory"]  = "#{$SaveDirs[thread3].to_s}"
        $RunResults["run-#{thread3}"]["configuration"]["ChoiceFile"]     = "#{$choicefiles[thread3].to_s}"

        $runFailed = false

        # Parse contents of substitute-h2k-errors.txt, which may contain ruby errors if substitute-h2k.rb did
        # not execute correctly.
        $RunResults["run-#{thread3}"]["status"]["substitute-h2k-err-msgs"] = "nil"

        if ( File.exist?("substitute-h2k-errors.txt") )
            $errmsgs= File.read("substitute-h2k-errors.txt")
            $errmsgs_chk = $errmsgs
            if ( ! $errmsgs_chk.gsub(/\n*/,"").gsub( / */, "").empty? )
              $RunResults["run-#{thread3}"]["status"]["substitute-h2k-err-msgs"] = $errmsgs
            end

        end

       jsonParsed = false

       debug_out "Looking for #{$RunResultFilenameV2} ? \n"
       if ( File.exist?($RunResultFilenameV2) ) then
         debug_out "Found it. Parsing JSON output !\n"
         contents = File.read($RunResultFilenameV2)
         thisRunResults = Hash.new
         thisRunResults = JSON.parse(contents)


         #$RunResults["run-#{thread3}"]["output"] = thisRunResults["output"]
         #$RunResults["run-#{thread3}"]["cost-estimates"] = thisRunResults["costEstimates"]
         #$RunResults["run-#{thread3}"]["input"] = thisRunResults["input"]
         #$RunResults["run-#{thread3}"]["archetype"] = thisRunResults["archetype"]

         thisRunResults.keys.each do | section |
            if ( section.eql?("status") || section.eql?("configuration") ) then
              thisRunResults[section].keys.each do | node |
                debug_out ("  ------ #{section}/#{node}\n")
                if ( section == status && node == "success" && $RunResults["run-#{thread3}"][section][node] == "false" ) then

                else
                  $RunResults["run-#{thread3}"][section][node]  = thisRunResults[section][node]
                end

              end
            else
              debug_out " ...... #{section} \n"
              $RunResults["run-#{thread3}"][section] = thisRunResults[section]
            end
          end
         $runFailed = true if (! $RunResults["run-#{thread3}"]["status"]["success"] == "true")
         jsonParsed = true
         stream_out (" done.\n")
       end

       if ( jsonParsed ) then
         # do nothing !
         debug_out "No futher file processing needed\n"
         debug_out drawRuler " . "
         debug_out "results from run-#{thread3}:\n"
         debug_out ("#{$RunResults["run-#{thread3}"].pretty_inspect}\n")
       elsif (  File.exist?($RunResultFilename)  ) then
         debug_out "processing old token/value file \n"
           contents = File.open($RunResultFilename, 'r')

           ec=0
           wc=0

           lineCount = 0
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
               $RunResults["run-#{thread3}"][token] = value
             end

           end
           contents.close

           if $RunResults["run-#{thread3}"]["s.success"] =~ /false/ then
             $runFailed = true
             stream_out (" done (with errors).\n")
           else
             stream_out (" done.\n")
           end

        else
            debug_out ("no output anywhere!\n")
            stream_out (" Output couldn't be found! \n")
            $runFailed = true
        end

        if ($runFailed)
            #stream_out (" RUN FAILED! (see dir: #{$SaveDirs[thread3]}) \n")
            $failures.write "#{$choicefiles[thread3]} (dir: #{$SaveDirs[thread3]}) - no output from substitute-h2k.rb\n"
            $FailedRuns.push "#{$choicefiles[thread3]} (dir: #{$SaveDirs[thread3]}) - no output from substitute-h2k.rb"
            $FailedRunCount = $FailedRunCount + 1

            $RunResults["run-#{thread3}"]["status"]["success"] = "false"
            #if ( $RunResults["run-#{thread3}"]["status"]["errors"].nil? ) then
            #  $RunResults["run-#{thread3}"]["status"]["errors"] = Array.new
            #end
            #$RunResults["run-#{thread3}"]["status"]["errors"].push = " Run failed - no output generated"

            $LocalChoiceFile = File.basename $gOptionFile
            if ( ! FileUtils.rm_rf("#{$RunDirs[thread3]}/#{$LocalChoiceFile}") )
              warn_out(" Warning! Could delete #{$RunDirs[thread3]}  rm_fr Return code: #{$?}\n" )
            end


        end

        Dir.chdir($gMasterPath)

        # Save files from runs that failed, or possibly all runs.
        if ( $gSaveAllRuns || $runFailed )

          if ( ! Dir.exist?($SaveDirs[thread3]) )

            Dir.mkdir($SaveDirs[thread3])

          else

            FileUtils.rm_rf Dir.glob("#{$SaveDirs[thread3]}/*.*")

          end

          FileUtils.mv( Dir.glob("#{$RunDirs[thread3]}/*.*")  , "#{$SaveDirs[thread3]}" )
          FileUtils.rm_rf ("#{$RunDirs[thread3]}/sim-output")
        end

        #Update status of this thread.
        $FinishedTheseFiles[$choicefiles[thread3]] = true


      end

      errs = ""
      stream_out ("     - Post-processing results... ")

      $outputlines = ""

      row = 0


      # Alternative output in JSON format. Can be memory-intensive



        $RunResults.keys.each do | run |

          $gJSONAllData[$gHashLoc] = Hash.new
          $gJSONAllData[$gHashLoc] = { "result-number"           =>  $gHashLoc+1,
                                        "status"                 => $RunResults[run]["status"            ],
                                        "archetype"              => $RunResults[run]["archetype"         ],
                                        "input"                  => $RunResults[run]["input"             ],
                                        "output"                 => $RunResults[run]["output"            ],
                                        "configuration"          => $RunResults[run]["configuration"     ],
                                        "miscellaneous_info"     => $RunResults[run]["miscellaneous_info"],
                                        "cost-estimates"     => $RunResults[run]["cost-estimates"]  }


          if ( $gJSONAllData[$gHashLoc]["status"]["success"] == "false" ) then

            $runFailed = true
            errs=" *** simulation errors found ***"
            $msg = "#{$gJSONAllData[$gHashLoc]["configuration"]["ChoiceFile"]} (dir: #{$gJSONAllData[$gHashLoc]["configuration"]["SaveDirectory"]}) - substitute-h2k.rb reports errors"
            $failures.write "$msg\n"
            $FailedRuns.push $msg
            $FailedRunCount = $FailedRunCount + 1

          else

            $CompletedRunCount = $CompletedRunCount + 1

          end


          # Increment hash increment too.
          $gHashLoc = $gHashLoc + 1

          if ( $runFailed && $StopOnError ) then
            $RunsDone = true
            $GiveUp = true
          end




         end # ends $RunResults.each do




     $failures.flush

     $RunResults.clear

     batchLapsedTime = "#{(Time.now - batchStartTime).round(0)} seconds"

     stream_out ("done. Duration: #{batchLapsedTime}.#{errs}\n\n")

     if ( ! $FinishedTheseFiles.has_value?(false) )

       $RunsDone = true

     end


  end


  if ( $GiveUp ) then
    stream_out(" - HTAP-prm: runs terminated due to error ----------\n\n")
  else
    stream_out(" - HTAP-prm: runs finished -------------------------\n\n")
  end

  if ($gJSONize )
    stream_out(" - Writing JSON output to HTAP-prm-output.json... ")
    $JSONoutput  = File.open($gOutputJSON, 'w')
    $JSONoutput.write(JSON.pretty_generate($gJSONAllData))
    $JSONoutput.close
    stream_out("done.\n\n")
  end


  if ( ! $gDebug ) then
     stream_out (" - Deleting working directories... ")
     FileUtils.rm_rf Dir.glob("HTAP-work-*")
     stream_out("done.\n\n")
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

$gMasterPath = Dir.getwd()


$cmdlineopts = Hash.new
$gTest_params = Hash.new        # test parameters
$gTest_params["verbosity"] = "Lquiet"
$gOptionFile = ""
$gSubstitutePath = "C:\/HTAP\/substitute-h2k.rb"
$gWarn = "1"
$gOutputFile = "HTAP-prm-output.csv"
$gOutputJSON = "HTAP-prm-output.json"
$gFailFile = "HTAP-prm-failures.txt"
$gSaveAllRuns = false

$gRunDefinitionsProvided = false
$gRunDefinitionsFile = ""

$gNumberOfThreads = 3

$StopOnError = false

#=====================================================================================
# Parse command-line switches.
#=====================================================================================
optparse = OptionParser.new do |opts|


   opts.separator " USAGE: htap-prm.rb -o path\\to\\htap-options.json -r path\\to\\runfile.run -v "
   opts.separator " "
   opts.separator " Required inputs:"

   opts.on("-o", "--options FILE", "Specified options file (mandatory).") do |o|
      $cmdlineopts["options"] = o
      $gOptionFile = o
      if ( !File.exist?($gOptionFile) )
         fatalerror("Valid path to option file must be specified with --options (or -o) option!")
      end
   end

   opts.on("-r", "--run-def FILE", "Specified run definitions file (.run)") do |o|
      $gRunDefinitionsProvided = true
      $gRunDefinitionsFile = o
      if ( !File.exist?($gRunDefinitionsFile) )
         fatalerror("Valid path to run definitions (.run) file must be specified with --run-def (or -r) option!")
      end
   end

   opts.separator "\n Configuration options: "

   opts.on("-t", "--threads X", "Number of threads to use") do |o|
      $gNumberOfThreads = o.to_i
      if ( $gNumberOfThreads < 1 )
        $gNumberOfThreads = 1
      end
   end

   opts.on("-a", "--cost-assemblies FILE", "Estimate costs for assemblies using costing database.") do |o|
      $gComputeCosts = true
      $gCostingFile = o
      if ( ! File.exist?($gRunDefinitionsFile) ) then
        fatalerror("Costing file #{$gCostingFile} could not be found!")
      end

   end



   opts.on("-e", "--extra-output", "Report additional data on archetype and part-load characteristics") do
      $cmdlineopts["extra-output"] = true
      $gExtendedOutputFlag = "-e"
   end

   opts.on("-k", "--keep-all-files", "Preserve all files, including modified .h2k files, in HTAP-sim-X",
                                     "directories. (otherwise, only files that generate errors will be
                                      saved).") do
      $gSaveAllRuns = true
   end

   opts.on("-j", "--json", "Provide output in JSON format (htap-prm-output.json),","in additon to .csv.") do
      $gJSONize = true
   end


   opts.on("-v", "--verbose", "Output progress to console.") do
      $cmdlineopts["verbose"] = true
      $gTest_params["verbosity"] = "verbose"
   end

   opts.separator "\n Debugging options: "

   opts.on("--debug", "Run in debug mode. Prints extra output to screen.") do
      $cmdlineopts["verbose"] = true
      $gTest_params["verbosity"] = "verbose"
      $gDebug = true
   end

   opts.on("--stop-on-error", "Terminate run upon first error encountered.") do

      $StopOnError = true

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

stream_out(drawRuler("A simple parallel run manager for HTAP"))

optparse.parse!    # Note: parse! strips all arguments from ARGV and parse does not


$RunNumber = 0
$processed_file_count = 0
$RunDirs  = Array.new
$SaveDirs = Array.new
$FailedRuns  = Array.new
$RunDirectoryRoot  = "HTAP-work"
$SaveDirectoryRoot = "HTAP-sim"
$RunResultFilenameV2 = "h2k_run_results.json"
$RunResultFilename = "SubstitutePL-output.txt"


              #Hash.new{ |h,k| h[k] = Hash.new{|h,k| h[k] = Array.new}}


$RunTheseFiles = Array.new
$FinishedTheseFiles = Hash.new


# Generate working directories
#stream_out(" - Creating working directories (HTAP_work-0 ... HTAP_work-#{$gNumberOfThreads-1}) \n\n")
stream_out(" Initialization: \n")

stream_out("    - Deleting prior HTAP-work directories... ")
FileUtils.rm_rf Dir.glob("HTAP-work-*")
stream_out (" done.\n")
stream_out("    - Deleting prior HTAP-sim directories... ")
FileUtils.rm_rf Dir.glob("HTAP-sim-*")
stream_out (" done.\n")



for prethread in 0..$gNumberOfThreads-1

    $RunDirName = "#{$RunDirectoryRoot}-#{prethread}"
    $RunDirs[prethread] = $RunDirName

end

$outputCSV = File.open($gOutputFile, 'w')

$failures = File.open($gFailFile, 'w')

$gMeshRunDefs = Hash.new

#==================================================================
#
#==================================================================

if ( ! $gRunDefinitionsProvided )
  # Basic mode: Run a set of .choice files that are provided as arguements to the command line
  #  - load choice files into array for now
  ARGV.each do |choicefile|
    if ( choicefile =~ /.*choices$/ )
      $RunTheseFiles.push choicefile
    else
      stream_out "    ! Skipping: #{choicefile} ( not a '.choice' file? ) \n"
    end
  end

  fileorgin = "supplied"

else

  # Smarter mode - embark on run according to definitions in the .run file (mesh supported for now)
  #  - First parse the *.run file

  stream_out ("    - Reading HTAP run definition from #{$gRunDefinitionsFile}... ")

  parse_def_file($gRunDefinitionsFile)
  $archetypeFiles = Array.new
  $Folder = $gArchetypeDir
  $gArchetypes.each do |arch_entry|
    $archetypeFiles = Dir["#{$Folder}/#{arch_entry}"]
  end



  stream_out (" done.\n")

  case $gRunDefMode
  when  "mesh"

    # estimate the number of combonations
    #debug_out
    runningProduct = 1
    stream_out "    - Evaluating combinations for mesh run\n\n"
    stream_out "          * "+$gLocations.length.to_s.ljust(10)+" (options for Location)\n" if ($gLocations.length>1 )
    stream_out "          * "+$archetypeFiles.length.to_s.ljust(10)+" (options for Archetypes)\n" if ($archetypeFiles.length>1 )
    stream_out "          * "+$gRulesets.length.to_s.ljust(10)+" (options for Rulesets)\n" if ($gRulesets.length>1 )
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
    stream_out "           #{runningProduct.to_s.ljust(15)} Total combinations\n\n"




    $combosRequired = runningProduct
    $combosGenerated = 0
    $combosSinceLastUpdate = 0
    $comboInterval = 1000

    create_mesh_cartisian_combos(-3)


    stream_out ("    - Setting up mesh run for #{$combosRequired} combinations --- #{$combosGenerated} combos created.\n")

  when "parametric"

    # estimate the number of combonations
    #debug_out
    runningSum = 1
    runningProduct = 1
    stream_out "    - Evaluating combinations for parametric run\n\n"
    stream_out "          * "+$gLocations.length.to_s.ljust(10)+"  { # of options for Location }\n" if ($gLocations.length>1 )
    stream_out "          * "+$archetypeFiles.length.to_s.ljust(10)+"  { # of options for Archetypes }\n" if ($archetypeFiles.length>1 )
    stream_out "          * "+$gRulesets.length.to_s.ljust(10)+"  { # of options for Rulesets }\n" if ($gRulesets.length>1 )
    stream_out "          *    (   1          { base option for all choices }\n"
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
    stream_out "           #{runningProduct.to_s.ljust(15)} Total combinations\n\n"

    $combosRequired = runningProduct
    $combosGenerated = 0
    $combosSinceLastUpdate = 0
    $comboInterval = 1000

    stream_out ("    - Setting up parametric run for #{$combosRequired} combinations --- #{$combosGenerated} combos created.\r")

    create_parametric_combos()
    stream_out ("    - Setting up parametric run for #{$combosRequired} combinations --- #{$combosGenerated} combos created.\n")
  end

  $RunTheseFiles = $gGenChoiceFileList

  #if ($choicesInMemory )
  #  stream_out (" done. ( created #{$gGenChoiceFileNum} combinations )\n")
  #else
  #  stream_out (" done. (created #{$gGenChoiceFileNum} '.choice' files)\n")
  #end



  fileorgin = "generated"

end




$batchCount = 0


if ( $choicesInMemory )
  stream_out("    - Preparing to process #{$RunTheseFiles.count} #{fileorgin} combinations using #{$gNumberOfThreads} threads \n\n")
else
  stream_out("    - Preparing to process #{$RunTheseFiles.count} #{fileorgin} '.choice' files using #{$gNumberOfThreads} threads \n\n")
end

run_these_cases($RunTheseFiles)


if ( ! $GiveUp ) then
  stream_out (" - HTAP-prm: Run complete -----------------------\n\n")
else
  stream_out (" - HTAP-prm: Error encountered, run terminated --\n\n")
end
stream_out ("    + #{$CompletedRunCount} files were evaluated successfully.\n\n")
stream_out ("    + #{$FailedRunCount} files failed to run \n")

if ( $FailedRunCount > 0 )
  stream_out ("\n ** The following files failed to run: ** \n")

  $FailedRuns.each do |errorfile|
    stream_out ("     + #{errorfile} \n")
  end

end

# Close output files (JSON output dumped in a single write - already closed at this point.
$outputCSV.close
$failures.close


stream_out ("\n\n")

exit
