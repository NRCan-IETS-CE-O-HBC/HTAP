
# =========================================================================================
# msgs.rb: Various output scripts used to handle reporting to files
#
# =========================================================================================
require_relative 'helpMsgs'
class Help
   include HelpTxt
end

# =========================================================================================
# Query info about the console, and set terminal width.
#
# =========================================================================================
def setTermSize
   require 'io/console'
   $termWidth = IO.console.winsize[1]

end

def shortenToTerm(msg)
  setTermSize if ( $termWidth.nil? )

  if msg.length > $termWidth-3 then
    msg.gsub!(/\n/,"")
    shortmsg = "#{msg[0..$termWidth-9]} [...]\n"
  else
    shortmsg = msg
  end

  return shortmsg

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
# Draw a pretty ruler with optional embedded msg, and custom character 'char',
# formatted to match width of terminal
# =========================================================================================
def drawRuler(msg = nil, char=nil)
  setTermSize if ( $termWidth.nil? )

  c=char
  # set to default ruler character, if none provided.
  if ( char.nil? )
    c = "="
  end

  if ( ! msg.nil? && c == "=" )
    topRule = "".ljust($termWidth-1,"_")
    topRule = "\n#{topRule}\n"
    prefix = "#{$program}: "
  else
    topRule = ""
    prefix  =""
  end

  if (! msg.nil? )
    mainRule = "#{c} #{prefix}#{msg} #{c}".ljust($termWidth-1,c)+"\n"
  else
    mainRule = "".ljust($termWidth-1,c)+"\n"
  end

  return "#{topRule}#{mainRule}"
end

# =========================================================================================
# Return easy-to-read information about the calling routine
# =========================================================================================
def caller_info()

   parent = caller[1].clone

   file = parent.clone
   file.gsub!(/^.+\/HTAP\//,"")
   file.gsub!(/\:[0-9]+\:.+$/,"")

   line = parent.clone
   line.gsub!(/^C:/, "")
   line.gsub!(/^[^:]+:/, "")
   line.gsub!(/:.+$/, "")

   routine = parent.clone
   routine.gsub!(/^.+in /,'')
   routine.gsub!(/\'/, '')
   routine.gsub!(/\`/, '')

   indentLevel = 0
   caller.each do | a |
     if ( a =~ /\`each\'/ ||
          a =~ /\`block in / ||
          a =~ /\`block \(. levels\) in/  ||
          a =~ /\`\<main\>/ ) then
       # Do nothing
     else
       indentLevel += 1
     end
   end

   callerID = Hash.new
   callerID = { "file" => file, "routine" => routine, "line" => line, "level" => indentLevel }
   return callerID

end

# =========================================================================================
# Hook enabling debugging from within a routine
# =========================================================================================
def debug_on()
  callerID = caller_info()
  routine = callerID["routine"]
  file =callerID["file"]
  line = callerID["line"]
  $localDebug[routine] = true
  $lastDbgMsg = "\n"
  print "\n"
  debug_out_now(drawRuler(nil,"_ "),callerID)
  debmsg = "Debugging turned on at #{file}:#{line.to_s}\n"
  debug_out_now(debmsg,callerID)
  return 1
end
# =========================================================================================
# Hook disabling debugging from within a routine
# =========================================================================================
def debug_off()
  callerID = caller_info()
  $localDebug[callerID["routine"]] = false
  return 0
end

# =========================================================================================
# Check of debugging is active, and if so, call debug_out_now
# to write out debugging messages.
# =========================================================================================
def debug_out(debmsg)

  callerID = caller_info()
  if( $localDebug[callerID["routine"]].nil? ) then
    lDebug = false
  else
    lDebug = $localDebug[callerID["routine"]]
  end

  if (lDebug || $gDebug ) then
     debugCaller = Array.new
     debug_out_now( debmsg, callerID)
  end
end

# =========================================================================================
# Write out formatted debugging messages to the screen. (in almost all cases,
# code should call debug_out and not debug_out_now.
# =========================================================================================
def debug_out_now(debmsg, callerID)

  callindent = ""

  level      = callerID["level"]
  lineNumber = callerID["line"]
  routine    = callerID["routine"]

  calldots = ""
  callblks = ""
  (1..level).each do
    calldots ="#{calldots}."
  end


  linestring = lineNumber.to_s
  blankstring = " "

  fullmsg = ""

  if ($lastDbgMsg =~ /\n/ ) then

    first = true
    debmsg.each_line do |line|

      if first then
        first = false
        prefix = "[#{calldots}d#{level}:#{callindent}#{routine}:#{linestring} ".ljust(30)
        prefix = "#{prefix}]"

        if (  debmsg =~ /^[^\s]/ ) then
          prefix = "#{prefix} "
        end
      else
        prefix = "[ ".ljust(30)+"]"
      end

      fullmsg = "#{fullmsg}"+shortenToTerm("#{prefix}#{line}")

    end

    #debmsg.gsub!(/\n/,"\n#{blank}")
    #debmsg.gsub!(/\n#{blank}\s*\Z/, '')
  else
    fullmsg = shortenToTerm(debmsg)
  end
  print fullmsg

  if ($gTest_params["logfile"] )
    $fLOG.write(fullmsg)
  end
  $lastDbgMsg = fullmsg

end

# =========================================================================================
# Write warning message to screen, and log for reporting
# =========================================================================================
def warn_out(msg)
  #puts "\n\n WARNING: #{msg}\n\n"
  if ($gTest_params["logfile"])
    $fLOG.write("\n\n WARNING: #{msg}\n\n")
  end

  $gWarnings << msg.gsub(/\n/,'')

end

def help_out(catagory,topic)
  #require_relative 'helpMsgs'
  return if (! $gHelp )

  myHelp = Help.new
  myHelpMsg = nil
  #pp helpTxt

  begin
    if (catagory == "byMsg") then
      debug_out "by msg (#{topic})...\n"
      myHelpMsg  = myHelp.text[topic]
    else
      debug_out ("by topic - #{catagory}/#{topic}...\n")
      msgIndex = myHelp.index[catagory][topic]
      debug_out ( " ... index #{msgIndex}\n")
      myHelpMsg =  myHelp.text[msgIndex]
    end
  rescue
     myHelpMsg = nil

  end

  if ( myHelpMsg.nil? )
    callerID = Hash.new
    callerID = caller_info()
    line     = callerID["line"]
    file     = callerID["file"]
    routine  = callerID["routine"]
    myHelpMsg = "\n Unfortunately, nobody has provided any help text\n"+
                  " for catagory: #{catagory} / topic: #{topic}\n"+
                  "\n"
    warn_out " Broken call to help_out() in #{routine} (#{file}:#{line}) - some developer should fix this! "
  end

  myHelpMsg.gsub!(/^/,'? ')

  stream_out "\n\n"
  stream_out drawRuler("Hint - #{topic}",'? ')
  stream_out myHelpMsg
  stream_out drawRuler(nil,'? ')
  stream_out "\n\n"


end


# =========================================================================================
# Write error message to screen, log for reporting, and set global error flag.
# =========================================================================================
def err_out(msg)

  puts "\n\n ERROR: #{msg}\n\n"

  if ($fLOG != nil )
    $fLOG.write("\n\n ERROR: #{msg}\n\n")
  end
  $gErrors << msg.gsub(/\n/,'')
  $allok = false
end



# =========================================================================================
# Write error message to screen, log for reporting, and set global error flag.
# =========================================================================================
def fatalerror( err_msg )
# Display a fatal error and quit. -----------------------------------

# See if error string is not empty: if not, call err-out to log it
  if ( err_msg.gsub(/\s*/,'') != "") then
    callerID = caller_info()
    line     = callerID["line"]
    file     = callerID["file"]
    routine  = callerID["routine"]
    err_msg = "#{err_msg} (fatal error called at #{routine} (#{file}:#{line})"
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

def writeHeader()
 stream_out drawRuler($program)
 stream_out $info
 stream_out drawRuler(nil)
end

# =========================================================================================
# Report info about the status of the run,
# =========================================================================================
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

  stream_out drawRuler("#{$program}: Run Summary")
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
  stream_out drawRuler


  #
  #if ($fLOG != nil )
  #  $fLOG.write("\n\n ERROR: #{msg}\n\n")
  #end
  #$gErrors << msg.gsub(/\n/,'')
  #$allok = false
end
