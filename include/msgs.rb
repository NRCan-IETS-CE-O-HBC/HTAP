
# =========================================================================================
# msgs.rb: Various output scripts used to handle reporting to files
#
# =========================================================================================


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
def warn_out(msg)
  if $gWarn
    puts "\n\n WARNING: #{msg}\n\n"
  end
  if ($gTest_params["logfile"])
    $fLOG.write("\n\n WARNING: #{msg}\n\n")
  end

  $gWarnings << msg.gsub(/\n/,'')

end

def err_out(msg)

  puts "\n\n ERROR: #{msg}\n\n"

  if ($fLOG != nil )
    $fLOG.write("\n\n ERROR: #{msg}\n\n")
  end
  $gErrors << msg.gsub(/\n/,'')
  $allok = false
end




def fatalerror( err_msg )
# Display a fatal error and quit. -----------------------------------

# See if error string is not empty: if not, call err-out to log it
  if ( err_msg.gsub(/\s*/,'') != "") then
    err_out(err_msg)
  end

  ReportMsgs()

  # On error - attempt to save inputs .
  $gChoices.sort.to_h
  $fSUMMARY.write "\n"
  for attribute in $gChoices.keys()
    choice = $gChoices[attribute]
    $fSUMMARY.write("#{$AliasInput}.#{attribute} = #{choice}\n")
  end

  for status_type in $gStatus.keys()
    $fSUMMARY.write( "s.#{status_type} = #{$gStatus[status_type]}\n" )
  end
  $fSUMMARY.write( "s.success = false\n")


  $fSUMMARY.close
  $fLOG.close

  exit() # Run stopped
end

def ReportMsgs()

  $ErrorBuffer = ""
  $WarningBuffer = ""
  $gErrors.each  do |msg|

    $fSUMMARY.write "s.error    = \"#{msg}\" \n"
    $ErrorBuffer += "   + ERROR: #{msg} \n\n"

  end

  $gWarnings.each do |msg|

    $fSUMMARY.write "s.warning   = \"#{msg}\" \n"
    $WarningBuffer += "   + WARNING: #{msg} \n\n"

  end

  if $allok then
    status = "Run completed successfully"
    $fSUMMARY.write "s.success    = true\n"
  else
    status = "Run failed."
    $fSUMMARY.write "s.success    = false\n"
  end

  if ($ErrorBuffer.to_s.gsub(/\s*/, "" ).empty?)
    $ErrorBuffer = "   (nil)\n"
  end

  endProcessTime = Time.now
  $totalDiff = endProcessTime - $startProcessTime
  $fSUMMARY.write "s.processingtime  = #{$totalDiff}\n"

  stream_out " =========================================================\n"
  stream_out " #{$program} run summary : \n"
  stream_out " =========================================================\n"
  stream_out "\n"
  stream_out( " Total processing time: #{$totalDiff.to_f.round(2)} seconds\n" )
  if $program =~ /substiture-h2k.rb/ then 
    stream_out( " Total H2K execution time : #{$runH2KTime.to_f.round(2)} seconds\n" )
    stream_out( " H2K evaluation attempts: #{$gStatus["H2KExecutionAttempts"]} \n\n" )
  end 
  stream_out " #{$program} -> Warning messages:\n\n"
  stream_out "#{$WarningBuffer}\n"
  stream_out ""
  stream_out " #{$program} -> Error messages:\n\n"
  stream_out "#{$ErrorBuffer}\n"
  stream_out " #{$program} STATUS: #{status} \n"
  stream_out " =========================================================\n"


  #
  #if ($fLOG != nil )
  #  $fLOG.write("\n\n ERROR: #{msg}\n\n")
  #end
  #$gErrors << msg.gsub(/\n/,'')
  #$allok = false
end


