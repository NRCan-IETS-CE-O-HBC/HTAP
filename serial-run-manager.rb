

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
 ==========================================================================
 serial-run-manger.rb: 
 
 This is a rudimentary run manager developed to test JP's 9.36 rule set.
 It's a prototype for an eventual multi-threaded genopt replacement.

 --------------------------------------------------------------------------
      
"

$gMasterPath = Dir.getwd()


$cmdlineopts = Hash.new
$gTest_params = Hash.new        # test parameters
$gTest_params["verbosity"] = "Lquiet"
$gOptionFile = ""
$gSubstitutePath = "C:\/HTAP\/substitute-h2k.rb"
$gWarn = ""
$gOutputFile = "HTAP-output.csv"



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
RunResults = Hash.new {|h,k| h[k] = Array.new }
              #Hash.new{ |h,k| h[k] = Hash.new{|h,k| h[k] = Array.new}}
ARGV.each do |choicefile|


    if ( choicefile =~ /.*choices$/ )
    
        
        $RunNumber = $RunNumber + 1     
        $RunDirectory = "#{$RunDirectoryRoot}-#{$RunNumber}"
        
        if ( Dir.exist?($RunDirectory) )
          if ( ! FileUtils.rm_rf("#{$RunDirectory}") )
            fatalerror( " Fatal Error! Could not create #{$RunDirectory} below #{$gMasterPath}!\n MKDir Return code: #{$?}\n" )
          end
        end


        if ( ! Dir.exist?($RunDirectory) )
          if ( ! Dir.mkdir($RunDirectory) )
            fatalerror( " Fatal Error! Could not create #{$RunDirectory} below #{$gMasterPath}!\n MKDir Return code: #{$?}\n" )
          end
        end 
        
        # Copy choice and options file into intended directory 
        FileUtils.cp(choicefile,$RunDirectory)
        FileUtils.cp($gOptionFile,$RunDirectory)
        
        $LocalChoiceFile = choicefile.gsub(/^.*\\/, '')
        $LocalOptionsFile = $gOptionFile.gsub(/^.*\\/, '')
        
                
        
        Dir.chdir($RunDirectory)
        
        cmdscript =  "ruby #{$gSubstitutePath} -o .\\#{$LocalOptionsFile} -c .\\#{$LocalChoiceFile} --report-choices  "
        
        stream_out("Running  simulation # #{$RunNumber} ...")
        debug_out(" ( cmd: #{cmdscript} |  \n")
        
        pid = Process.spawn( cmdscript ) 

        debug_out("  PID #{pid} ")
               
        Process.wait pid, 0
        status = $?.exitstatus      

        if ( ! FileUtils.rm_rf("H2K") )
           warn_out(" Warning! Could delete #{$RunDirectory}/H2K  rm_fr Return code: #{$?}\n" )
        end
        
        
        debug_out(" finished with exit status #{status} | ")
       
        debug_out(" parsing results from #{$RunDirectory}/#{$RunResultFilename}") 

        contents = File.open($RunResultFilename, 'r') 
      
        
        RunResults["RunNumber"] << $RunNumber
        RunResults["input.ChoiceFile"]<< $LocalChoiceFile
      
        lineCount = 0
        contents.each do |line|
          lineCount = lineCount + 1
          line_clean = line.gsub(/ /, '')
          line_clean = line.gsub(/\n/, '')
          token, value = line_clean.split('=')
          
          RunResults[token] <<  value
         
        end
        contents.close
   
  
        Dir.chdir($gMasterPath)
        stream_out(" done\n")
        
    else 
    
        stream_out ("Warning: #{choicefile} does not appear to be a choice file. Skipping.\n")
        
    end

end 

#Runs Done - export to output 




RowsToWrite =  RunResults["RunNumber"].length

puts "Writing #{RowsToWrite} lines....\n"

outputlines = ""
row = 0

while row <= RunResults["RunNumber"].length

  puts "> #{row} "
      
  
  RunResults.each do |column, data| 
  
    if ( row == 0 ) 
        
      outputlines.concat(column.to_s)
  
    else 
    
      outputlines.concat(data[row-1].to_s)

    end 
    
    outputlines.concat( ", " )
    
  end

  row = row + 1
  outputlines.concat( "\n " )

end 

output = File.open($gOutputFile, 'w') 
output.write(outputlines) 
output.close 






