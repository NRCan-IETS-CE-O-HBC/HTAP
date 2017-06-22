#!/usr/bin/env ruby
# Ruby implementation of 'start-substiture.pl'



require 'optparse'
require 'fileutils' 

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



 
$help_msg = "
 start-substitute.rb: 
 
 This script searches through the supplied command line argument file
 and creates one choice file per row in the supplied csv file. 
 
 use: ./start-substitute.rb param1 
 
 where: param1 = GenOpt-picked-these-choices.GO-tmp
		
"

$welcome_msg = "

 start-substitute.rb:

"

if ARGV.empty? then 
    puts $help_msg
    exit()
else

    puts $welcome_msg
end
    


options = {}

optparse = OptionParser.new do |opts|

  opts.banner = $help_msg

  opts.on("-h", "--help", "Displays help") do 
    puts opts
    exit
  end
  
end.parse!


$GenOptChoices = ""

ARGV.each do |f|

  $GenOptChoices = f

end 


  
  


$MasterPath = Dir.getwd() 
$LogFile  = "#{$MasterPath}\\Start-SubstituteRb-log.txt"

$ChoiceFLDir = "C:\\Ruby4HTAP\\GenerateChoiceFiles\\"


 
 # Log file 
fLOG = File.new($LogFile,"w")
if fLOG == nil then 
  fatalerror (" Could not open #{$LogFile}.\n")
end 
fLOG.write(" --- start-substitute.rb log start ---\n")
 

# Choice file - open... 
fGenOptChoices = File.new( $GenOptChoices, "r" ) 
if  fGenOptChoices == nil then 
  fatalerror (" Could not open #{$GenOptChoices} \n")
end
 
$linecount = 0 
 
# ...and parse...
while !fGenOptChoices.eof? do 
  $linecount = $linecount + 1
  
  $line = fGenOptChoices.readline 
  $line.strip!
  $line.gsub!(/\!.*$/, '')  # Removes comments
  $line.gsub!(/\s*/, '')    # Removes mid-line white space

  if ( $linecount < 10 )  then 
    $lineSTR = " #{$linecount}"
  else
    $lineSTR = "#{$linecount}"
  end 
  
  if ( $line !~ /^\s*$/ ) 
  
    puts "|#{$lineSTR}|" << $line 
  
    lineTokenValue = $line.split(':')
    $token = lineTokenValue[0]
    $value = lineTokenValue[1]
    
    if ($token =~ /Opt-ChoiceFileName/ )        
       $choiceFileName = $value 
       fLOG.write (" Choice file is #{$choiceFileName} \n"); 
    end 
    
    if ($token =~ /Location/ )        
       $Location = $value 
       fLOG.write (" Location is #{$Location} \n"); 
    end 
    
    if ($token =~ /HeatCool-Control/ )        
       $HC_ctl = $value
       fLOG.write (" HC-ctl is #{$HC_ctl} \n"); 
    end 
    
     if ($token =~ /HRV_ctl/ )        
       $hrvctl = $value
       fLOG.write (" HRV-ctl is #{$hrvctl} \n"); 
    end


    if ($token =~ /ElecLoadScale/ )        
       $ElecLoad = $value
       fLOG.write (" ElecLoad is #{$ElecLoad} \n"); 
    end     
    
    if ($token =~ /DHWLoadScale/ )        
       $DHWLoad = $value
       fLOG.write (" DHWLoad is #{$DHWLoad} \n"); 
    end        

    if ($token =~ /OptionsFile/ )        
       $OptionsFile = $value
       fLOG.write (" Options are #{$OptionsFile} \n"); 
    end       
    
    if ($token =~ /Archetype/ )        
       $Archetype = $value
       fLOG.write (" Archetype is #{$Archetype} \n"); 
    end   
    
    
  end
  
  
end

fGenOptChoices.close

fLOG.write " The current directory is : #{$MasterPath} \n" 


FileUtils.copy("#{$ChoiceFLDir}\\#{$choiceFileName}",".\\#{$choiceFileName}")

fChoiceFileContent = File.new(".\\#{$choiceFileName}","r")

if  fChoiceFileContent == nil then 
  fatalerror (" Could not open #{$choiceFileName} \n")
end

fLOG.write(" Reading from .\\#{$choiceFileName}\n")

$line_edits = ""

while !fChoiceFileContent.eof? do 

  $line = fChoiceFileContent.readline
  
    $line = $line.gsub(/<LOCATION>/,$Location)
    
    #puts "|| #{$line}\n"
    
    $line_edits << $line 
  
end 

puts "===================== output will look like =============================="
puts $line_edits
puts "--------------------- end output -----------------------------------------"

fChoiceFileContent.close

fChoiceFileContentEdited = File.new(".\\#{$choiceFileName}-edit","w")

if  fChoiceFileContentEdited == nil then 
  fatalerror (" Could not open #{$choiceFileName}-edit \n")
end

fChoiceFileContentEdited.write($line_edits)

fChoiceFileContentEdited.close

$cmd = "ruby C:\\Ruby4HTAP\\substitute-h2k.rb -vv -c #{$choiceFileName}-edit -o #{$OptionsFile} "
fLOG.write("CMD: #{$cmd}\n")
pid = Process.spawn($cmd)
Process.wait pid, 0
status = $?.exitstatus 

#
#
#my $command = $ARGV[1]." ../substitute.pl -e -c $choiceFileName -o ../options-generic-GHG.options -b ./GenericHome-GHG -vv";
#
#print LOG "The command is: ".$command."\n";
#
#system ( $command );
#
#close ( LOG );



fLOG.write(" ---start-substitute.rb log end -----\n\n")

puts "

start-substitute.rb done.

"

