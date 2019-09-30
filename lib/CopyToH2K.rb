
#!/usr/bin/env ruby

require 'fileutils'

$gTargetArchDir = "C:\\H2K-CLI-Min\\User\\"
$gTargetLibDir = "C:\\H2K-CLI-Min\\StdLibs\\"
$gTargetCodDir = "C:\\H2K-CLI-Min\\StdLibs\\"

$gMasterPath = Dir.getwd()



print ">#{$gMasterPath} \n"

gFilesH2k = Dir["./*.h2k"] 

gFilesH2k.each do |filename|

  print ">> Copying #{filename} to #{$gTargetArchDir}..."
 
  FileUtils.cp( filename, $gTargetArchDir + File.basename(filename,".h2k")+".h2k")
  
  print " done.\n"
  
end


gFilesCod = Dir["./*.cod"] 

gFilesCod.each do |filename|

  print ">> Copying #{filename} to #{$gTargetCodDir}..."
 
  FileUtils.cp( filename, $gTargetCodDir + File.basename(filename, ".cod")+".cod")
  
  print " done.\n"
  
end

gFilesFlc = Dir["./*.flc"] 

gFilesFlc.each do |filename|

  print ">> Copying #{filename} to #{$gTargetLibDir}..."
  
  FileUtils.cp( filename, $gTargetLibDir + File.basename(filename, ".flc")+".flc")
  
  print " done.\n"
  
end

#print ">> \n #{$gFilesH2k} \n"



