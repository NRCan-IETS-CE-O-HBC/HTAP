
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

def debug_on()

  parentRoutine = caller[0]

  line = "#{parentRoutine}"
  line.gsub!(/^C:/, "")
  line.gsub!(/^[^:]+:/, "")
  line.gsub!(/:.+$/, "")
  #line.gsub(/^[^:]+:([^:]+:[^:]+$)/, "\\1")
  parentRoutine.gsub!(/^.+in /,'')
  parentRoutine.gsub!(/\'/, '')
  parentRoutine.gsub!(/\`/, '')
  $localDebug[parentRoutine] = true

  debmsg = " Debugging turned on at line \# #{line.to_s}.\n"

  debug_out_now(debmsg,parentRoutine,caller)

  return 1
end

def debug_off()
  parentRoutine = caller[0]

  parentRoutine.gsub!(/^.+in /,'')
  parentRoutine.gsub!(/\'/, '')
  parentRoutine.gsub!(/\`/, '')
  $localDebug[parentRoutine] = false
  return 0
end

# =========================================================================================
# Write debug output ------------------------------------------------
# =========================================================================================
def debug_out(debmsg)
  parentRoutine = caller[0]
  line = caller[0]
  parentRoutine.gsub!(/^.+in /,'')
  parentRoutine.gsub!(/\'/, '')
  parentRoutine.gsub!(/\`/, '')


  if( $localDebug[parentRoutine].nil? ) then
    lDebug = false
  else
    lDebug = $localDebug[parentRoutine]
  end

  if (lDebug || $gDebug ) then
     debugCaller = Array.new
     debugCaller = caller
     debug_out_now( debmsg, parentRoutine, debugCaller)
  end
end



def debug_out_now(debmsg, parentRoutine, debugCaller)
  callindent = ""
  debugCaller.each do | a |
    if ( a =~ /\`each\'/ ||
         a =~ /\`block in / ||
         a =~ /\`block \(. levels\) in/  ||
         a =~ /\`\<main\>/ ) then
      # Do nothing
    else
      callindent = "#{callindent}.."
    end
  end

  line = debugCaller[0]
  line.gsub!(/^C:/, "")
  line.gsub!(/^[^:]+:/, "")
  line.gsub!(/:.+$/, "")
  linestring = line
  blankstring = " "

  fullmsg = ""

  if ($lastDbgMsg =~ /\n/ ) then



    first = true
    debmsg.each_line do |line|

      if line.length > 80 then
        line.gsub!(/\n/,"")
        shortmsg = "#{line[0..80]}"
        shortmsg = "#{shortmsg} ...\n"
      else
        shortmsg = line
      end

      if first then
        first = false
        prefix = "[d:#{callindent}#{parentRoutine}:#{linestring} ".ljust(30)
        prefix = "#{prefix}]"

        if (  shortmsg =~ /^[^\s]/ ) then
          prefix = "#{prefix} "
        end
      else
        prefix = "[ ".ljust(30)
        prefix = prefix = "#{prefix}]   "
      end



      fullmsg = "#{fullmsg}#{prefix}#{shortmsg}"

    end

    #debmsg.gsub!(/\n/,"\n#{blank}")
    #debmsg.gsub!(/\n#{blank}\s*\Z/, '')
  else
    fullmsg = debmsg
  end
  print fullmsg

  if ($gTest_params["logfile"] )
    $fLOG.write(fullmsg)
  end
  $lastDbgMsg = fullmsg

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
