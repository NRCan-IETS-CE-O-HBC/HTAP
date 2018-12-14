
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

  #stream_out "\n substitute-h2k.rb: FATAL ERROR: \n\n"
  #stream_out "   + ERROR: #{err_msg}\n"
  #stream_out "\n=========================================================\n"

  $fSUMMARY.close
  $fLOG.close

  exit() # Run stopped
end
