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
 recover-results.rb - parses OutputListingAll.txt files and combines them.
 
 usage: recover-results.rb [options] 
 
      -h, --help     Displays help
      -l, --local    Search for OutputListingAll.txt in current (local) dirctory
"
# JTB: Remote use not yet implemented for HOT2000 use with Remote Desktop Connection:  
#  (e.g. recover-results.rb 54.204.133.55 ) 


if ARGV.empty? then 
    puts $help_msg
    exit()
end

$local = false 

optparse = OptionParser.new do |opts|

  opts.banner = $help_msg

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

recoveredLines = 0

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
	     recoveredLines += 1
         index += 1
         data << index.to_s << ", " <<batch.to_s << ", " << line.to_s << "\n"
      end
   end
   contents.close
   
end

puts "Recovered "<< recoveredLines.to_s << " lines from " << batch.to_s << " files.\n"

output = File.open('CloudResultsAllData.csv', 'a') 
output.write(header)
output.write(data)
output.close

#puts header
#my @AllFiles = split /\s/, `ls CloudResultsBatch*.txt TempResultsBatch*.txt`; 

exit()

FileUtils.rm Dir.glob('TempResultsBatch*.txt')
exit()

