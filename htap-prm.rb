

#!/usr/bin/env ruby
# ************************************************************************************
# This is a really rudamentary run-manager developed as a ...
# ************************************************************************************

require 'optparse'
require 'ostruct'
require 'timeout'
require 'fileutils'
require 'pp'


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
# Write warning output ------------------------------------------------
# =========================================================================================
def parse_output_data(filepath)
   if $gWarn 
      puts debmsg
   end
   if ($gTest_params["logfile"])
      $fLOG.write(debmsg)
   end
end


# =========================================================================================
# Parse Substitute-H2k Resutls  -----------------------------------------------------------
# =========================================================================================


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

$gNumberOfThreads = 3 

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

   opts.on("-d", "--debug", "Run in debug mode") do
      $cmdlineopts["verbose"] = true
      $gTest_params["verbosity"] = "debug"
      $gDebug = true
   end

   
   opts.on("-w", "--warnings", "Report warning messages") do 
      $gWarn = true
   end

   opts.on("-s", "--substitute-h2k-path FILE", "Specified path to substitute RB ") do |o|
      $cmdlineopts["substitute"] = o
      $gSubstitutePath = o
      if ( !File.exist?($gOptionFile) )
         fatalerror("Valid path to option file must be specified with --options (or -o) option!")
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


 
end

optparse.parse!    # Note: parse! strips all arguments from ARGV and parse does not


# ARGV contains 

$RunNumber = 0

$RunDirectoryRoot = "HTAP-Sim"
$RunResultFilename = "SubstitutePL-output.txt"
$RunResults = Hash.new {|h,k| h[k] = Array.new }
              #Hash.new{ |h,k| h[k] = Hash.new{|h,k| h[k] = Array.new}}
              

$RunTheseFiles = Array.new
$FinishedTheseFiles = Hash.new
stream_out("\n")
stream_out(" ======================================================\n")
stream_out(" HTAP-prm.rb ( a simple parallel run manager for HTAP ) \n")
stream_out(" ======================================================\n\n")
ARGV.each do |choicefile|
  if ( choicefile =~ /.*choices$/ )
    $RunTheseFiles.push choicefile
    $FinishedTheseFiles[choicefile] = false 
  else 
    stream_out " ! Skipping: #{choicefile} ( not a '.choice' file? ) \n"
  end
end               

stream_out(" - Preparing to process #{$FinishedTheseFiles.count} '.choice' files using #{$gNumberOfThreads} threads \n\n")


$batchCount = 0 
$choicefileIndex = 0 
$numberOfFiles = $FinishedTheseFiles.count {|k| k.include?(false)}
$processed_file_count = 0
       
$choicefiles = Array.new
$PIDS        = Array.new
$RunDirs     = Array.new 
$RunNumbers  = Array.new

$FailedRuns  = Array.new
$CompletedRunCount = 0 
$FailedRunCount = 0 



output = File.open($gOutputFile, 'w') 

$outputHeaderPrinted = false 


stream_out (" - HTAP-prm: begin runs ----------------------------\n\n")


# Loop until all files have been processed. 
while $FinishedTheseFiles.has_value?(false) 

  $batchCount = $batchCount + 1 

  stream_out ("   + Batch #{$batchCount} ( #{$choicefileIndex}/#{$numberOfFiles} files processed so far...) \n" )

  # Empty arrays for current batch. 
  $choicefiles.clear
  $PIDS.clear       
  $RunDirs.clear    
  
  
  # Compute the number of threads we will start: lesser of a) files remaining, or b) threads allowed.
  $ThreadsNeeded = [$FinishedTheseFiles.count {|k| k.include?(false)}, $gNumberOfThreads].min 
  
  
  # Multi-threaded runs - Step 1: Spawn threads. 
  for thread in 0..$ThreadsNeeded-1  
  
    # For this thread: Get the next choice file in the batch. 
    $choicefiles[thread] = $RunTheseFiles[$choicefileIndex] 
  
  
    count = thread + 1 
    stream_out ("     - Starting thread : #{count}/#{$ThreadsNeeded} for file #{$choicefiles[thread]} ")
    
    
    # For this thread: Get the next choice file in the batch. 
    $choicefiles[thread] = $RunTheseFiles[$choicefileIndex]
  
    # Make sure that's a real choice file ( this just duplicates a test above )
    if ( $choicefiles[thread] =~ /.*choices$/ )
    
      # Increment run number and create name for unique simulation directory
      $RunNumber = $RunNumber + 1     
      $RunDirectory = "#{$RunDirectoryRoot}-#{$RunNumber}"
      
      # Store run number and directory fro this thread        
      $RunNumbers[thread] = $RunNumber
      $RunDirs[thread] = $RunDirectory
        
        
      # Delete prior run directory if it exists
      if ( Dir.exist?($RunDirectory) )
        if ( ! FileUtils.rm_rf("#{$RunDirectory}") )
          fatalerror( " Fatal Error! Could not create #{$RunDirectory} below #{$gMasterPath}!\n MKDir Return code: #{$?}\n" )
        end
      end
      
      # Re-create empty run directory
      if ( ! Dir.exist?($RunDirectory) )
        if ( ! Dir.mkdir($RunDirectory) )
          fatalerror( " Fatal Error! Could not create #{$RunDirectory} below #{$gMasterPath}!\n MKDir Return code: #{$?}\n" )
        end
      end 
      
      # Copy choice and options file into intended run directory...
      FileUtils.cp($choicefiles[thread],$RunDirectory)
      FileUtils.cp($gOptionFile,$RunDirectory)      
           
      # ... And get base file names for insertion into the substitute-h2k.rb command.
      $LocalChoiceFile = File.basename $choicefiles[thread]    
      $LocalOptionsFile = File.basename $gOptionFile
        
      # CD to run directory, spawn substitute-h2k thread and save PID 
      Dir.chdir($RunDirectory)
          
      
      cmdscript =  "ruby #{$gSubstitutePath} -o #{$LocalOptionsFile} -c #{$LocalChoiceFile} --report-choices "
      
      
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
    
    
  # Multi-threaded runs - Step 3: Post-process and clean up. 
    
  for thread3 in 0..$ThreadsNeeded-1 
    count = thread3 + 1 
    stream_out ("     - Post-processing results from PID: #{$PIDS[thread3]} (#{count}/#{$ThreadsNeeded})...")
    
    Dir.chdir($RunDirs[thread3])
    
    if ( ! FileUtils.rm_rf("H2K") )
        warn_out(" Warning! Could delete #{$RunDirs[thread3]}/H2K  rm_fr Return code: #{$?}\n" )
    end
    
    if ( File.exist?($RunResultFilename) ) 
    
       contents = File.open($RunResultFilename, 'r') 
       
       $RunResults["RunNumber"] << $RunNumbers[thread3]
       $RunResults["RunDir"] << $RunDirs[thread3]
       $RunResults["input.ChoiceFile"]<< $choicefiles[thread3]
       
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
    
        stream_out (" RUN FAILED! \n")
        $FailedRuns.push "#{$choicefiles[thread]} (dir: #{$RunDirs[thread3]})"
        $FailedRunCount = $FailedRunCount + 1 
    end 
    
    Dir.chdir($gMasterPath)
    
    #Update status of this thread. 
    $FinishedTheseFiles[$choicefiles[thread3]] = true        
 
  end 
  
  stream_out ("     - Writing results to disk... ") 
  # Write out results intermittantly. 
  outputlines = ""
  
  row = 1 
  
  while row <= $RunResults["RunNumber"].length

    #stream_out ( "\n           > Data for #{row} ? #{$outputHeaderPrinted}    \n")
    $RunResults.each do |column, data| 
  
      #stream_out "                     - #{column} | #{data[row-1]} \n"
  
      if ( ! $outputHeaderPrinted ) 
        
        outputlines.concat(column.to_s)
  
      else 
    
        outputlines.concat(data[row-1].to_s)

      end 
    
      outputlines.concat( ", " )
    
    end

    if ( ! $outputHeaderPrinted ) 
      $outputHeaderPrinted = true 
    else 
      row = row + 1
    end 
  
    outputlines.concat( "\n " )
  
     

  end 
  
  output.write(outputlines) 
  output.flush 

  $RunResults.clear
  
  stream_out (" done.\n\n")
  
end 


output.close 

stream_out (" - HTAP-prm: runs finished -------------------------\n\n")



stream_out (" - HTAP-prm: Run complete -----------------------\n")
stream_out ("   + #{$CompletedRunCount} files were evaluated successfully.\n\n")
stream_out ("   + #{$FailedRunCount} files failed to run \n")

if ( $FailedRunCount > 0 ) 
  stream_out ("   ! The following files failed to run ! \n")

  $FailedRuns.each do |errorfile|
    stream_out ("     + #{errorfile} \n")
  end
  
end 
  
  
stream_out ("\n\n")
  
exit  