#!/usr/bin/env ruby

# This script parses through the files
 
#use warnings;
#use strict;

require 'optparse'
require 'fileutils'

$gMasterPath = Dir.getwd()


$RemoteDir     = "HousingModels/OptFramework"; 
$RemoteFile    = "OutputListingAll.txt"; 
$OutputFile    = "CloudResultsAllData.csv"; 
$Batch         = 0; 
$TotalRows     = 0; 
$help_msg = "
 recover-results.rb 
 usage: recover-results.rb <remote computer address> 
 (e.g. recover-results.rb ubuntu\@ec2-23-23-47-71.compute-1.amazonaws.com ) 
 
 "


if ARGV.empty? then 
    puts $help_msg
    exit()
end

$local = false 

optparse = OptionParser.new do |opts|

  opts.banner = 
  " recover-results.rb - parses OutputListingAll.txt files and combines them.
    
    usage: recover-results.rb [options]
   "

  opts.on("-h", "--help", "Displays help") do 
    puts opts
    exit
  end
  
  opts.on("-l", "--local", "Search for OutputListingAll.txt in current (local) dirctory") do 
     $local = true
     puts ">>> HERE"

  end 
  
  
  
end

optparse.parse!



if ($local)
  FileUtils.rm Dir.glob('TempResultsBatch*.txt')
  FileUtils.rm Dir.glob('CloudResultsAllData.csv')
  
  FileUtils.cp( $RemoteFile, "TempResultsBatch1.txt ")


end 
FileList = Array.new

Dir.glob('TempResultsBatch*.txt').each do |f| 
  FileList.push(f)
end
Dir.glob('CloudResultsBatch*.txt').each do |f| 
  FileList.push(f)
end


puts "---"
puts FileList
puts "---"
#i = 0

batch = 0
index =0
header =""
data = ""

FileList.each do |fileName|
  batch += 1
  lineCount = 0
  puts "Recvering results from "  << fileName
  contents = File.open(fileName, 'r') 
  contents.each do |line|
    lineCount += 1
	#puts "F: " << fileName <<" | " << batch.to_s << " | " << lineCount.to_s
	#	line  = line.gsub!(/\s+/,", ") 
	line  = line.gsub(/([^ ]) ([^ ])/,"\\1\\2") 
	
	line  = line.gsub(/\s+/,", ") 
   # $line  =~ s/\s+/,/g;


	if lineCount < 20 
	  #GenOpt preamble. DO nothing
	elsif batch == 1 and lineCount == 20
	  
	  header = "ID, batch, " << line.to_s << ", status\n"
      
	elsif lineCount > 20 
	  index += 1
	  data << index.to_s << ", " <<batch.to_s << ", " << line.to_s << "\n"
	  
	end
	
	
  end
  contents.close
  puts lineCount.to_s << " lines."
end


output = File.open('CloudResultsAllData.csv', 'a') 
output.write(header)
output.write(data)
output.close

#puts header
#my @AllFiles = split /\s/, `ls CloudResultsBatch*.txt TempResultsBatch*.txt`; 

exit()

FileUtils.rm Dir.glob('TempResultsBatch*.txt')
exit()


#if ($ARGV[0] =~/local/) {



#my @AllFiles = split /\s/, `ls CloudResultsBatch*.txt TempResultsBatch*.txt`; 
#
##push @AllFiles, $LocalFileName; 
#
#open (WRITEOUT, ">$OutputFile") or die ( " Could not open $OutputFile for writing !"); 
#
#
#foreach ( @AllFiles ) {
#	print "Recovering data from $_ ... \n"; 
#	$Batch++; 
#	my $LocalFileName = $_; 
#	open (READIN,$LocalFileName) or die ( " Could not open $LocalFileName for reading !"); 
#
#	my $LineCount = 0; 
#	my $headerLine = ""; 
#	my $lines = ""; 
#	my $row = 1;  
#  
#	while ( my $line =<READIN> ){
#
#		$LineCount++; 
#    
#		if ( $LineCount < 20 ) {
#    
#			# GenOpt preamble. Do nothing. 
#    
#		} elsif ( $LineCount == 20 ) {
#    
#			# Header Row, copied for first batch only. 
#			if ( $Batch == 1) {
#				$line  =~ s/ /_/g; 
#				$line  =~ s/\s+/,/g; 
#				#print " HEADER: $line "; 
#				$lines .= "ID,batch,row,$line"."junk,generation\n" ; 
#			}
#		} else {
#			$row++; 
#			$TotalRows++; 
#			# All other rows
#			$line =~ s/\s+/,/g; 
#			$line =~ s/,$//g; 
#			$lines .= "$TotalRows,$Batch,$row,$line\n" ; 
#		}
#
#		#print $lines; 
#	}
#
#	close READIN; 
#  
#	print WRITEOUT $lines; 
#}
#  
#close WRITEOUT; 
#system ("cp $OutputFile /cygdrive/s/SBC/Housing_\\&_Buildings/HBCS_2012_2016_Initiatives/ecoEII_New_Housing/Optimization_results/");
#print ("  All done! Recovered $TotalRows Rows in $Batch files. \n"); 
#print ("  You may wish to rename local file 'RecoveredFromCloud.txt' to 'CloudResultsBatch*.txt' if that optimization run is complete. \n"); 
#print ("  Have a good day\n"); 
#
#