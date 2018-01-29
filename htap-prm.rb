

#!/usr/bin/env ruby
# ************************************************************************************
# This is a really rudamentary run-manager developed as a ...
# ************************************************************************************

require 'optparse'
require 'ostruct'
require 'timeout'
require 'fileutils'
require 'pp'

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



$gGenChoiceFileBaseName = "sim-X.choices"
$gGenChoiceFileDir = "./gen-choice-files/"
$gGenChoiceFileNum = 0
$gGenChoiceFileList = Array.new

#default (and only supported mode)
$gRunDefMode   = "mesh"

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

# =========================================================================================
# Optionally write text to buffer -----------------------------------
# =========================================================================================
def stream_out(msg)
   if ($gTest_params["verbosity"] != "quiet")
      print msg
   end
   if ($gTest_params["logfile"])
      $fLOG.write(msg)
   end
end

# =========================================================================================
# Write debug output ------------------------------------------------
# =========================================================================================
def debug_out(debmsg)
   if $gDebug 
      puts debmsg
   end
   if ($gTest_params["logfile"])
      $fLOG.write(debmsg)
   end
end

# =========================================================================================
# Write warning output ------------------------------------------------
# =========================================================================================
def warn_out(debmsg)
   if $gWarn 
      puts debmsg
   end
   if ($gTest_params["logfile"])
      $fLOG.write(debmsg)
   end
end


# =========================================================================================
# Does this do anything? ------------------------------------------------
# =========================================================================================
def parse_output_data(filepath)
   
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
            $gRunDefMode = "mesh"
             
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
             
            # archetypes -  
            $gLocations = $token_values[1].to_s.split(",")
          
          end           
          
          if ( $UpgradesOpen ) 
          
            option  = $token_values[0]
            choices = $token_values[1].to_s.split(",")
            $gRunUpgrades[option] = choices 
            $gOptionList.push option             
            
            
          end 
    

      end  #Case 
      
    end # if ( $defline !~ /^\s*$/ ) 
    
  end # rundefs.each do | line |

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
    $gArchetypeHash[generated_file] = $gChoiceFileSet["Opt-Archetype"] 
    $gLocationHash[generated_file]  = $gChoiceFileSet["Opt-Location"] 
    $gRulesetHash[generated_file]   = $gChoiceFileSet["Opt-Ruleset"] 
    
  else    
    
    case optIndex
    when -3 
    
      $gLocations.each do |location|
        
        $gChoiceFileSet["Opt-Location"] = location 
        
        create_mesh_cartisian_combos(optIndex+1) 
        
      end 
    
    when -2 
    
      $gArchetypes.each do |archetype|
      
        $gChoiceFileSet["Opt-Archetype"] = archetype 
        
        create_mesh_cartisian_combos(optIndex+1) 
        
      end      
    
    
    when -1 
    
      $gRulesets.each do |ruleset|
      
        $gChoiceFileSet["Opt-Ruleset"] = ruleset 
          
        create_mesh_cartisian_combos(optIndex+1) 
         
        
      end # $gRulesets.each do |ruleset|
          
 
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

=begin rdoc
# ----------------------------------------------------------------------------
# Gen Choice File 
# This function generates a choice file from a supplied attirbute:choice hash.
# ----------------------------------------------------------------------------
=end 

def gen_choice_file(choices) 

  # create empty directory to hold choice files 
  if ( ! Dir.exist?($gGenChoiceFileDir) )
    if ( ! Dir.mkdir($gGenChoiceFileDir) )
      fatalerror( " Fatal Error! Could not create #{$gGenChoiceFileDir} below #{$gMasterPath}!\n MKDir Return code: #{$?}\n" )
    end 
     
  end 
  
  $gGenChoiceFileNum = $gGenChoiceFileNum + 1
  
  choicefilename = $gGenChoiceFileBaseName.gsub(/X/,"#{$gGenChoiceFileNum}") 
  choicefilepath = "#{$gGenChoiceFileDir}#{choicefilename}"
 
  
  
  choicefile = File.open(choicefilepath, 'w')
  
  choices.each do | attribute, choice | 
  
    choicefile.write(" #{attribute} : #{choice} \n")   
  
  end 
  
  choicefile.close 

  return choicefilepath

end 



=begin rdoc
#======================================================================================================
# This code will process a supplied list of .choice files using the specified number of threads.  
#======================================================================================================
=end 

def run_these_cases(current_task_files)


         
  $choicefiles        = Array.new
  $PIDS               = Array.new
  $FinishedTheseFiles = Hash.new 
  $RunNumbers         = Array.new
  
  $CompletedRunCount = 0 
  $FailedRunCount = 0 
  
  ## Create working directories 
  
  
  $outputHeaderPrinted = false 
  
  
  current_task_files.each do |choicefile|
    $FinishedTheseFiles[choicefile] = false 
  end 
  
  $choicefileIndex = 0 
  numberOfFiles = $FinishedTheseFiles.count {|k| k.include?(false)}
  
  
  stream_out (" - HTAP-prm: begin runs ----------------------------\n\n")
  
  $choicefileIndex = 0 
  $RunsDone = false 
  
  
  
  # Loop until all files have been processed. 
  while  ! $RunsDone 

      $batchCount = $batchCount + 1 

      stream_out ("   + Batch #{$batchCount} ( #{$choicefileIndex}/#{numberOfFiles} files processed so far...) \n" )

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
        stream_out ("     - Starting thread : #{count}/#{$ThreadsNeeded} for file #{$choicefiles[thread]} ")
        
        
        # For this thread: Get the next choice file in the batch. 
        #$choicefiles[thread] = $RunTheseFiles[$choicefileIndex] 
        
      
        # Make sure that's a real choice file ( this just duplicates a test above )
        if ( $choicefiles[thread] =~ /.*choices$/ )
        
          # Increment run number and create name for unique simulation directory
          $RunNumber = $RunNumber + 1     
          $RunDirectory  = $RunDirs[thread]
          
          
          $SaveDirectory = "#{$SaveDirectoryRoot}-#{$RunNumber}"
          
          # Store run number and directory fro this thread        
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
          FileUtils.cp($choicefiles[thread],$RunDirectory)
          FileUtils.cp($gOptionFile,$RunDirectory)      
          FileUtils.cp("#{$gArchetypeDir}\\#{$H2kFile}",$RunDirectory)
          
          # ... And get base file names for insertion into the substitute-h2k.rb command.
          $LocalChoiceFile  = File.basename $choicefiles[thread]    
          $LocalOptionsFile = File.basename $gOptionFile
         
            
          
            
          # CD to run directory, spawn substitute-h2k thread and save PID 
          Dir.chdir($RunDirectory)


          # Possibly call another script to modify the .h2k and .choice files 
         
          case $Ruleset
          when /936_2015_AW_HRV/
            subcall = "perl C:\\HTAP\\NRC-scripts\\apply936-AW.pl #{$H2kFile} #{$LocalChoiceFile}  #{$LocalOptionsFile} #{$Location} 1 "
            system (subcall)      
          when /936_2015_AW_noHRV/
            subcall = "perl C:\\HTAP\\NRC-scripts\\apply936-AW.pl #{$H2kFile} #{$LocalChoiceFile}  #{$LocalOptionsFile} #{$Location} 0 "
            system (subcall)      
          end 


          
          cmdscript =  "ruby #{$gSubstitutePath} -o #{$LocalOptionsFile} -c #{$LocalChoiceFile} -b #{$H2kFile} --report-choices --prm "

          # Save command for invoking substitute [ useful in debugging ]         
          $cmdtxt = File.open("cmd.txt", 'w') 
          $cmdtxt.write cmdscript
          $cmdtxt.close
          
          debug_out(" ( cmd: #{cmdscript} |  \n")  
             
          pid = Process.spawn( cmdscript, :out => File::NULL, :err => File::NULL ) 

          $PIDS[thread] = pid 
          
          stream_out("(PID #{$PIDS[thread]})...")
                 
          # Cd to root, move to next choice file. 
          Dir.chdir($gMasterPath)
          
        end 

        stream_out (" done. \n")
        $choicefileIndex = $choicefileIndex + 1
        
      end 
      
      
      # Multi-threaded runs - Step 2: Monitor thread progress
      
      #=====================================================================================
      # Wait for threads to complete 
      
      for thread2 in 0..$ThreadsNeeded-1 
          
         count = thread2 + 1  
         
         stream_out ("     - Waiting on PID: #{$PIDS[thread2]} (#{count}/#{$ThreadsNeeded})...")
          
          Process.wait $PIDS[thread2], 0
          status = $?.exitstatus   
          
          if ( status == 0 ) 
          
            stream_out (" done.\n")
            
          else 
          
            stream_out (" FAILED!.\n")
          
          end 
          
      end 
        
      #=====================================================================================
      # Multi-threaded runs - Step 3: Post-process and clean up. 
        
      for thread3 in 0..$ThreadsNeeded-1 
        count = thread3 + 1 
        stream_out ("     - Post-processing results from PID: #{$PIDS[thread3]} (#{count}/#{$ThreadsNeeded} #{$choicefiles[thread3]} )...")
        
        Dir.chdir($RunDirs[thread3])
        
        $runFailed = false 
        
        if ( File.exist?($RunResultFilename) ) 
        
           contents = File.open($RunResultFilename, 'r') 
           
           $RunResults["RunNumber"] << $RunNumbers[thread3]
           $RunResults["RunDir"] << $RunDirs[thread3]
           $RunResults["iiiiiiinput.ChoiceFile"]<< $choicefiles[thread3]
           
           lineCount = 0
           contents.each do |line|
             lineCount = lineCount + 1
             line_clean = line.gsub(/ /, '')
             line_clean = line.gsub(/\n/, '')
             token, value = line_clean.split('=')
             
             $RunResults[token] <<  value
           
           end
           contents.close
           $CompletedRunCount = $CompletedRunCount + 1 
           stream_out (" done.\n")
           

           
        else 
        
            stream_out (" RUN FAILED! (see dir: #{$SaveDirs[thread3]}) \n")
            $failures.write "#{$choicefiles[thread3]} (dir: #{$SaveDirs[thread3]})\n"
            $FailedRuns.push "#{$choicefiles[thread3]} (dir: #{$SaveDirs[thread3]})"
            $FailedRunCount = $FailedRunCount + 1
            

            
            $LocalChoiceFile = File.basename $gOptionFile
            if ( ! FileUtils.rm_rf("#{$RunDirs[thread3]}/#{$LocalChoiceFile}") )
              warn_out(" Warning! Could delete #{$RunDirs[thread3]}  rm_fr Return code: #{$?}\n" )
            end           
            
            $runFailed = true       
            
        end 
        
        Dir.chdir($gMasterPath)  
        
        # Save files from runs that failed, or possibly all runs. 
        if ( $gSaveAllRuns || $runFailed ) 
        
          if ( ! Dir.exist?($SaveDirs[thread3]) ) 
            
            Dir.mkdir($SaveDirs[thread3]) 
            
          else 
          
            FileUtils.rm_rf Dir.glob("#{$SaveDirs[thread3]}/*.*") 
            
          end 
          
          FileUtils.cp( Dir.glob("#{$RunDirs[thread3]}/*.*")  , "#{$SaveDirs[thread3]}" ) 
        
        end 

        #Update status of this thread. 
        $FinishedTheseFiles[$choicefiles[thread3]] = true        
     
      end 
      
      stream_out ("     - Writing results to disk... ") 

      $outputlines = ""
      
      row = 1 
      
      while row <= $RunResults["RunNumber"].length

        
        $RunResults.each do |column, data| 
      
         
      
          if ( ! $outputHeaderPrinted ) 
            
            $outputlines.concat(column.to_s)
      
          else 
        
            $outputlines.concat(data[row-1].to_s)

          end 
        
          $outputlines.concat( ", " )
        
        end

        if ( ! $outputHeaderPrinted ) 
          $outputHeaderPrinted = true 
        else 
          row = row + 1
        end 
      
        $outputlines.concat( "\n " )
      
         

      end 
      
      $output.write($outputlines) 
      $output.flush
      $failures.flush 
      
      $RunResults.clear
      
      stream_out (" done.\n\n")
      
      # Set Flag for file loop 
        
      if ( ! $FinishedTheseFiles.has_value?(false) ) 
      
        $RunsDone = true 
          
      end 
        

  end 
  
  
  
  
  stream_out (" - HTAP-prm: runs finished -------------------------\n\n")
  stream_out (" - Deleting working directories\n\n")
  
  FileUtils.rm_rf Dir.glob("HTAP-work-*") 
  FileUtils.rm_rf Dir.glob("HTAP-work-*") 

end 


=begin rdoc
=========================================================================================
  END OF ALL METHODS 
=========================================================================================
=end

                   
#-------------------------------------------------------------------
# Help text. Dumped if help requested, or if no arguments supplied.
#-------------------------------------------------------------------
$help_msg = "
 ======================================================
 HTAP-prm.rb ( a simple parallel run manager for HTAP )
 ======================================================\n\n"

$gMasterPath = Dir.getwd()


$cmdlineopts = Hash.new
$gTest_params = Hash.new        # test parameters
$gTest_params["verbosity"] = "Lquiet"
$gOptionFile = ""
$gSubstitutePath = "C:\/HTAP\/substitute-h2k.rb"
$gWarn = "1"
$gOutputFile = "HTAP-prm-output.csv"
$gFailFile = "HTAP-prm-failures.txt"
$gSaveAllRuns = false 

$gRunDefinitionsProvided = false 
$gRunDefinitionsFile = ""

$gNumberOfThreads = 3 


#=====================================================================================
# Parse command-line switches.
#=====================================================================================
optparse = OptionParser.new do |opts|
  
   opts.banner = $help_msg

   opts.on("-h", "--help", "Show help message") do
      puts opts
      exit()
   end
  
   opts.on("-v", "--verbose", "Run verbosely") do 
      $cmdlineopts["verbose"] = true
      $gTest_params["verbosity"] = "verbose"
   end

   #opts.on("-d", "--debug", "Run in debug mode") do
   #   $cmdlineopts["verbose"] = true
   #   $gTest_params["verbosity"] = "debug"
   #   $gDebug = true
   #end

   
   #opts.on("-w", "--warnings", "Report warning messages") do 
   #   $gWarn = true
   #end
   
   opts.on("-k", "--keep-all-files", "Keep all .h2k files and output") do 
      $gSaveAllRuns = true
   end
   

   opts.on("-s", "--substitute-h2k-path FILE", "Specified path to substitute RB ") do |o|
      $cmdlineopts["substitute"] = o
      $gSubstitutePath = o
      if ( !File.exist?($gOptionFile) )
         fatalerror("Valid path to substitute-h2k,rb script must be specified with --substitute-h2k-path (or -s) option!")
      end
   end

   opts.on("-t", "--threads X", "Number of threads to use") do |o|
      $gNumberOfThreads = o.to_i
      if ( $gNumberOfThreads < 1 ) 
        $gNumberOfThreads = 1 
      end 
   end
   
   
   
   opts.on("-o", "--options FILE", "Specified options file (mandatory)") do |o|
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
  
   
 
end

optparse.parse!    # Note: parse! strips all arguments from ARGV and parse does not


$RunNumber = 0
$processed_file_count = 0  
$RunDirs  = Array.new
$SaveDirs = Array.new
$FailedRuns  = Array.new
$RunDirectoryRoot  = "HTAP-work"
$SaveDirectoryRoot = "HTAP-sim"
$RunResultFilename = "SubstitutePL-output.txt"
$RunResults = Hash.new {|h,k| h[k] = Array.new }
              #Hash.new{ |h,k| h[k] = Hash.new{|h,k| h[k] = Array.new}}
              

$RunTheseFiles = Array.new
$FinishedTheseFiles = Hash.new


stream_out("\n")
stream_out(" ======================================================\n")
stream_out(" HTAP-prm.rb ( a simple parallel run manager for HTAP ) \n")
stream_out(" ======================================================\n\n")


# Generate working directories 
stream_out(" - Creating working directories (HTAP_work-0 ... HTAP_work-#{$gNumberOfThreads-1}) \n\n")
FileUtils.rm_rf Dir.glob("HTAP-work-*") 

for prethread in 0..$gNumberOfThreads-1 

    $RunDirName = "#{$RunDirectoryRoot}-#{prethread}"
    $RunDirs[prethread] = $RunDirName

end 
stream_out(" - Deleting prior HTAP-sim directories  \n\n")
FileUtils.rm_rf Dir.glob("HTAP-sim-*") 

$output = File.open($gOutputFile, 'w')
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
      stream_out " ! Skipping: #{choicefile} ( not a '.choice' file? ) \n"
    end
  end               
 
  fileorgin = "supplied"
  
else 

  # Smarter mode - embark on run according to definitions in the .run file (mesh supported for now) 
  #  - First parse the *.run file 
  
  stream_out (" - Reading HTAP run definition from #{$gRunDefinitionsFile}... ")
  
  parse_def_file($gRunDefinitionsFile) 
    
  stream_out (" done.\n\n")

  
  if ( $gRunDefMode == "mesh" ) 
  
    stream_out (" - Creating mesh run combinations from run definitions... ") 
      
    create_mesh_cartisian_combos(-3) 

    $RunTheseFiles = $gGenChoiceFileList

    stream_out (" done. (created #{$gGenChoiceFileNum} .choice files)\n\n") 
  end 
  
  fileorgin = "generated"
  
end 




$batchCount = 0 



stream_out(" - Preparing to process #{$RunTheseFiles.count} #{fileorgin} '.choice' files using #{$gNumberOfThreads} threads \n\n")

run_these_cases($RunTheseFiles) 


stream_out (" - HTAP-prm: Run complete -----------------------\n")
stream_out ("   + #{$CompletedRunCount} files were evaluated successfully.\n\n")
stream_out ("   + #{$FailedRunCount} files failed to run \n")

if ( $FailedRunCount > 0 ) 
  stream_out ("   ! The following files failed to run ! \n")

  $FailedRuns.each do |errorfile|
    stream_out ("     + #{errorfile} \n")
  end
  
end 
  
# Close output files
$output.close 
$failures.close   
  
  
stream_out ("\n\n")
  
exit  