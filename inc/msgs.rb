
# =========================================================================================
# msgs.rb: Various output scripts used to handle reporting to files
#
# =========================================================================================
require_relative 'helpMsgs'
class Help
   include HelpTxt
end

def openLogFiles( logFile, summaryFile )
  #debug_off
  begin
    debug_out "Summary file: #{summaryFile}\n"
    fSUMMARY = File.new(summaryFile, "w")
  rescue
    fatalerror("Could not open #{summaryFile}. \n")
  end

  begin
  debug_out "Log file: #{logFile}\n"
  fLOG = File.new(logFile, "w")
  rescue
    fatalerror("Could not open #{logFile}.\n")
  end

  return fLOG, fSUMMARY

end



def monthLong(month)

  match = "error"
  MonthArrList.each do | longMonth |

    if ( longMonth =~ /#{month}/i ) then 
      match = longMonth
      return match 
    end 

  end 

  return match 

end 



def input(prompt="", newline=false)
  require 'readline'
  prompt += "\n" if newline
  Readline.readline(prompt, true).squeeze(" ").strip
end



# =========================================================================================
# Query info about the console, and set terminal width.
#
# =========================================================================================
def setTermSize
   require 'io/console'
   $termWidth = IO.console.winsize[1]

end

def shortenToLen(msg, len, truncStr=" [...] ")

  if ( msg.length > len  )
    truncLen = truncStr.length
    if ( len < truncLen+1 )
      finalLen = len
      truncStr = ""
    else
      finalLen = len - truncLen
    end
    shortmsg = "#{msg[0..finalLen]}#{truncStr}"
  else
    shortmsg = "#{msg}"

  end
  return shortmsg

end

def shortenToTerm(msg,extrashort = 0, truncStr="[...]", newline = TRUE )

  setTermSize if ( $termWidth.nil? )

  if ( newline ) then 
    newline_char = "\n"
  else 
    newline_char = ""
  end 

  if msg.length > $termWidth-extrashort-3 then
    msg.gsub!(/\n/,"")
    shortmsg = "#{msg[0..$termWidth-extrashort-9]} #{truncStr}#{newline_char}"
  else
    msg.gsub!(/\n/,"")
    shortmsg = "#{msg}#{newline_char}"
  end

  return shortmsg

end

def reportSRC(branch, revision)
  stream_out ("\n")
  # Maybe find link to remote reporsitory too?
  stream_out (" GitHub source: \n")
  stream_out ("    - Branch:   #{branch} \n")
  stream_out ("    - Revision: #{revision} \n")
  return
end


def update_run_status (
  batch: nil , 
  action: nil,
  threads_delta: nil ,
  threads_total: nil ,
  frac_done: nil , 
  run_count: nil ,
  err_count: nil ,
  time_left: nil 
)

  if (! batch.nil?  ) then 
    $bufferStatus[:batch] = batch
  end 

  if (!  action.nil?  ) then 
    $bufferStatus[:action] = action 
  end 

  if ( ! threads_delta.nil? ) then 
    $bufferStatus[:current_threads] = $bufferStatus[:current_threads] + threads_delta

  end 

  if ( ! threads_total.nil?) then 
    $bufferStatus[:threads_total] = threads_total
  end 

  if ( ! err_count.nil? ) then 
    $bufferStatus[:err_count] = err_count
  end

  if ( ! run_count.nil? ) then 
    $bufferStatus[:run_count] = run_count.to_i
  end 

  if ( ! time_left.nil? ) then 
    $bufferStatus[:time_left] = time_left
  end

  if (! frac_done.nil? ) then 
    $bufferStatus[:frac_done] = frac_done
  end 

  if ( $bufferStatus[:err_count] == 0 ) then 
    err_txt = colourize("Errors: #{$bufferStatus[:err_count]}", :green)
  else 
    err_txt = colourize("Errors: #{$bufferStatus[:err_count]}", :red)
  end 

  update_txt = shortenToTerm(
    msg = " -> Batch ##{$bufferStatus[:batch]} [Threads Active: #{$bufferStatus[:current_threads]}/#{$bufferStatus[:threads_total]}, Runs done: #{$bufferStatus[:run_count]} (#{$bufferStatus[:frac_done]}%), #{err_txt}, ETA: #{$bufferStatus[:time_left]}] - #{$bufferStatus[:action]}",
    extrashort = 0,
    truncStr = '[...]',
    newline=false
  )

  update_buffer(update_txt)

end 

def update_buffer(new_msg) 
   empty_line = " ".ljust($termWidth-1," ")
   print "\r#{empty_line}"
   buffer = "\r#{new_msg}" 
   print buffer 
end 


def colourize(value, colour)
	case colour
		when :black then "\e[30m" + value.to_s + "\e[0m"
		when :red then "\e[31m" + value.to_s + "\e[0m"
		when :green then "\e[32m" + value.to_s + "\e[0m"
		when :yellow then "\e[33m" + value.to_s + "\e[0m"
		when :blue then "\e[34m" + value.to_s + "\e[0m"
		when :magenta then "\e[35m" + value.to_s + "\e[0m"
		when :cyan then "\e[36m" + value.to_s + "\e[0m"
		when :white then "\e[37m" + value.to_s + "\e[0m"
		when :bright_black then "\e[1m\e[30m" + value.to_s + "\e[0m"
		when :bright_red then "\e[1m\e[31m" + value.to_s + "\e[0m"
		when :bright_green then "\e[1m\e[32m" + value.to_s + "\e[0m"
		when :bright_yellow then "\e[1m\e[33m" + value.to_s + "\e[0m"
		when :bright_blue then "\e[1m\e[34m" + value.to_s + "\e[0m"
		when :bright_magenta then "\e[1m\e[35m" + value.to_s + "\e[0m"
		when :bright_cyan then "\e[1m\e[36m" + value.to_s + "\e[0m"
		when :bright_white then "\e[1m\e[37m" + value.to_s + "\e[0m"
		else value.to_s
	end
end

# =========================================================================================
# Optionally write text to buffer -----------------------------------
# =========================================================================================
def stream_out(msg)
  if ($gTest_params["verbosity"] != "quiet")
    print msg
  end
  #log_out(msg, true)
  if ( msg =~ /\n/ )
    $newLine = true
  else
    $newLine = false
  end
end

def log_out(msg,fromScreen=false)
  $logBufferCount += 1
  logmsg = ""
  if ( ! $fLOG.nil? )
    if ( fromScreen && $newLine ) then
      msg.each_line do |line|
        logmsg = "[to-term]#{line}"
      end
    else
      logmsg = msg
    end

    $fLOG.write("#{logmsg}\n")
    if ( $logBufferCount > 20 )
      $fLOG.flush      
      $logBufferCount = 0
    end
  end
end



# =========================================================================================
# Draw a pretty ruler with optional embedded msg, and custom character 'char',
# formatted to match width of terminal
# =========================================================================================
def drawRuler(msg = nil, char=nil, myLength=nil)

  setTermSize if ( $termWidth.nil?  )

  myLength = $termWidth if myLength.nil?

  c=char
  # set to default ruler character, if none provided.
  if ( char.nil? )
    c = "="
  end

  if ( ! msg.nil? && c == "=" )
    topRule = "_".ljust(myLength-1,"_")
    topRule = "\n#{topRule}\n"
    prefix = "#{$program}: "
  else
    topRule = ""
    prefix  =""
  end

  if (! msg.nil? )
    mainRule = "#{c} #{prefix}#{msg} #{c}".ljust(myLength-1,c)+"\n"
  else
    mainRule = "".ljust(myLength-1,c)+"\n"
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
def debug_pause(seconds=nil)
  return if ( $gNoDebug )
  callerID = caller_info()
  routine = callerID["routine"]
  file =callerID["file"]
  line = callerID["line"]
  $localDebug[routine] = true
  $lastDbgMsg = "\n"
  print "\n"
  debug_out_now(drawRuler(nil,"_ "),callerID)
  if ( seconds.nil? )
    debmsg = "debug_pause(): execution halted at #{file}:#{line.to_s}\n"
    debug_out_now(debmsg,callerID)
    exit
  else
    debmsg = "debug_pause(): execution paused for #{seconds}s at #{file}:#{line.to_s}\n"
    debug_out_now(debmsg,callerID)
    sleep(seconds)
    return
  end
end
# =======



# Hook enabling debugging from within a routine
def debug_on()
  return if ( $gNoDebug )
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
  return if ( $gNoDebug )
  callerID = caller_info()
  $localDebug[callerID["routine"]] = false
  return 0
end


# Routine to test debugging msg formatting

def debug_test_functions()
  debug_on 
  callerID = caller_info()
  # This case causes text to wrap around the console, because sebsequent calls 
  debug_out("{'debug_out' - Test#1: short msg, no return}")
  debug_out("{'debug_out' - Test#2: short msg, with return after '}'}\n")
  debug_out("{'debug_out' - Test#3: a trailing msg}")

  debug_out("{'debug_out' - Test#4: a long message |123456789|123456789|123456789|123456789|123456789}")
  debug_out("{'debug_out' - Test#5: a long message w return |123456789\n                                               |123456789\n                                               |123456789\n                                               |123456789\n                                               |123456789}")

  debug_out("{'debug_out' - Test#6: a message with some interesting content \n#{callerID.pretty_inspect})\n")
  debug_out("{'debug_out' - Test#7: #6, d#{callerID.pretty_inspect})\n")
  
  debug_out_long("{'debug_out_long' - Test#1: short msg, no return}")
  debug_out_long("{'debug_out_long' - Test#2: short msg, with return after '}'}\n")
  debug_out_long("{'debug_out_long' - Test#3: a trailing msg}")

  debug_out_long("{'debug_out_long' - Test#4: a long message |123456789|123456789|123456789|123456789|123456789}")
  debug_out_long("{'debug_out_long' - Test#5: a long message w return |123456789\n                                               |123456789\n                                               |123456789\n                                               |123456789\n                                               |123456789}")

  debug_out_long("{'debug_out_long' - Test#6: a message with some interesting content #{callerID.pretty_inspect})\n")
  debug_out_long("{'debug_out_long' - Test#7: #6, d#{callerID.pretty_inspect})\n")

  debug_off 
  debug_pause 

end 


# check if debug is active 

def debug_status()
  return false if ( $gNoDebug )
  callerID = caller_info() 
  if( $localDebug[callerID["routine"]].nil? ) then
    lDebug = false
  else
    lDebug = $localDebug[callerID["routine"]]
  end
  return lDebug 
end 

# Check of debugging is active, and if so, call debug_out_now
# to write out debugging messages.

def debug_out(debmsg)
  return if ( $gNoDebug )
  callerID = caller_info()
  debug_msg_handler(debmsg, callerID, longmsg=false)

end

def debug_out_long(debmsg)
  return if ( $gNoDebug )
  callerID = caller_info()
  debug_msg_handler(debmsg, callerID, longmsg=true)

end

def debug_msg_handler(debmsg, callerID, longmsg=false)
  return if ( $gNoDebug )

  if( $localDebug[callerID["routine"]].nil? ) then
    lDebug = false
  else
    lDebug = $localDebug[callerID["routine"]]
  end

  if (lDebug || $gDebug ) then
     #debugCaller = Array.new
     debug_out_now( debmsg, callerID, longmsg)
     log_out(debmsg)
  end
end

# =========================================================================================
# Write out formatted debugging messages to the screen. (in almost all cases,
# code should call debug_out and not debug_out_now.
# =========================================================================================
def debug_out_now(debmsg, callerID, longmsg=false)
  return if ( $gNoDebug )
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
 

  prefixLen = 0
  first = true
  debmsg.each_line do |line|
    #print ">#{line}"
    if first then
      first = false
      prefix = "[#{calldots}d#{level}:#{callindent}#{routine}:#{linestring} ".ljust(30)
      prefix = "#{prefix}]"
      prefixLen = prefix.length-1

    else
      prefix = "[ ".ljust(prefixLen)+"]"
    end

    if (  debmsg =~ /^[^\s]/ ) then
      prefix = "#{prefix} "
    end
    if longmsg then 
      fullmsg = "#{fullmsg}"+"#{prefix}#{line}"
    else 
      fullmsg = "#{fullmsg}"+shortenToTerm("#{prefix}#{line}")
    end 

  end

  if longmsg then 
    fullmsg = "#{fullmsg}\n"
  end 
  #debmsg.gsub!(/\n/,"\n#{blank}")
  #debmsg.gsub!(/\n#{blank}\s*\Z/, '')

  print colourize(fullmsg,:bright_black)

  if ($gTest_params["logfile"] )
    $fLOG.write(fullmsg)
  end
  $lastDbgMsg = fullmsg

end


# =========================================================================================
# Log Informational message  for latter reporting reporting
# =========================================================================================
def info_out(msg)

  callerID = Hash.new
  callerID = caller_info()
  line     = callerID["line"]
  file     = callerID["file"]
  routine  = callerID["routine"]
  msg.gsub(/^\n+/, "")
  msg.gsub(/\n+$/, "")
  #msg += " (message reported by #{routine} - #{file}:#{line})"

  if ($gTest_params["logfile"])
    $fLOG.write("Info: #{msg}\n")
  end

  $gInfoMsgs << msg

end


# =========================================================================================
# Write warning message to screen, and log for reporting
# =========================================================================================
def warn_out(msg)

  callerID = Hash.new
  callerID = caller_info()
  line     = callerID["line"]
  file     = callerID["file"]
  routine  = callerID["routine"]
  msg.gsub(/^\n+/, "")
  msg.gsub(/\n+$/, "")
  msg += " (warning reported by #{routine} - #{file}:#{line})"

  if ($gTest_params["logfile"])
    $fLOG.write(msg)
  end

  $gWarnings << msg
  stream_out "\n"
  stream_out prettyList(" (?) WARNING:",msg,:yellow)
  stream_out "\n"
end

def help_out(catagory,topic)
  #require_relative 'helpMsgs'
  return if (emptyOrNil(catagory))
  return if (emptyOrNil(topic))
  if ( ! emptyOrNil( $gHelpMsgsSent[catagory] ) ) then 
    return if ( ! emptyOrNil($gHelpMsgsSent[catagory][topic]) )
  end 
  $gHelpMsgsSent[catagory] = { topic => true }


  if (! $gHelp ) then 
    if ( ! $gHelpAvailableFlagged )
      info_out (" Additional help messages are available. Run with --hints to see them.")
      $gHelpAvailableFlagged = true 
    end 
    return
  end 

  
  
  


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
  shortMsg = ""
  myHelpMsg.gsub!(/^/,'    ')
  maxlen = 0
  myHelpMsg.each_line do | helpline |
    maxlen = helpline.length if ( helpline.length > maxlen)
  end
  boxlen = [$termWidth - 5, maxlen + 5 ].min
  myHelpMsg.each_line do | helpline |
    helpline.gsub!(/\n/,"")
    shortMsg += shortenToTerm(helpline,30,"").ljust(boxlen)+"\n"
  end
  stream_out "\n\n" 
  stream_out shortenToTerm(drawRuler("Hint - #{topic}",'   ?'),$termWidth-boxlen-9,"")
  stream_out shortMsg
  stream_out "\n"
  stream_out shortenToTerm(drawRuler(nil,'   ?'),$termWidth-boxlen-9,"")
  stream_out "\n\n"


end


# =========================================================================================
# Write error message to screen, log for reporting, and set global error flag.
# =========================================================================================
def err_out(msg, reportnow=true)

  callerID = Hash.new
  callerID = caller_info()
  line     = callerID["line"]
  file     = callerID["file"]
  routine  = callerID["routine"]
  msg.gsub(/^\n+/, "")
  msg.gsub(/\n+$/, "")
  msg += " (error reported by #{routine} - #{file}:#{line})"

  
  stream_out ("\n")
  stream_out prettyList(" (!) ERROR:",msg,:red)
  stream_out ("\n")

  if ($fLOG != nil )
    $fLOG.write("\n\n ERROR: #{msg}\n\n")
  end
  $gErrors << msg.gsub(/\n/,'')
  $allok = false
end



# =========================================================================================
# Write error message to screen, log for reporting, and set global error flag.
# =========================================================================================
def fatalerror( err_msg=nil )
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
  if ($program == "substitute-h2k.rb")
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
  end

  $fSUMMARY.close
  $fLOG.close

  exit() # Run stopped
end

def writeHeader()
 stream_out drawRuler($program)
 stream_out $info
 stream_out drawRuler(nil)
end


# print a pretty line

def prettyList(prefix,msg,colour=nil)

  tgtWrapLen = $termWidth - prefix.length - 10

  if ( colour.nil? ) then 
    prefix_colourized = prefix 
  else 
    prefix_colourized = colourize(prefix,colour)
  end 

  wrappedMsg = msg.gsub(/\n/, ' ').gsub(/(.{1,#{tgtWrapLen}})(\s+|$)/, "\\1\n").strip
  prettyMsg = ""

  blankPrefix = " ".ljust(prefix.length)
  first = true
  wrappedMsg.each_line do |line|
    if first then
      prettyMsg += "#{prefix_colourized} #{line}"
      first = false
    else
      prettyMsg += "#{blankPrefix} #{line}"
    end
  end

  return prettyMsg +"\n\n"

end


# =========================================================================================
# Report info about the status of the run,
# =========================================================================================
def ReportMsgs()

  $InfoBuffer = ""
  $ErrorBuffer = ""
  $WarningBuffer = ""



  $gInfoMsgs.each do |msg|

    $fSUMMARY.write "status.info   = \"#{msg}\" \n"

    $InfoBuffer += prettyList("   (-) Info -",msg,:blue)
    #$WarningBuffer += "   + WARNING: #{msg} \n\n"

  end
  if ($InfoBuffer.to_s.gsub(/\s*/, "" ).empty?)
      $InfoBuffer = "   (nil)\n"
  end


  $gWarnings.each do |msg|

    $fSUMMARY.write "status.warning   = \"#{msg}\" \n"

    $WarningBuffer += prettyList("   (?) WARNING -",msg, :yellow)
    #$WarningBuffer += "   + WARNING: #{msg} \n\n"

  end
  if ($WarningBuffer.to_s.gsub(/\s*/, "" ).empty?)
      $WarningBuffer = "   (nil)\n"
  end


  $gErrors.each  do |msg|

    $fSUMMARY.write "status.error    = \"#{msg}\" \n"
    $ErrorBuffer += prettyList("   (!) ERROR -",msg,:red)



  end
  if ($ErrorBuffer.to_s.gsub(/\s*/, "" ).empty?)
    $ErrorBuffer = colourize("   (nil)",:green)+"\n"
  end


  if $allok then
    status = colourize("Task completed successfully",:green)
    $fSUMMARY.write "status.success    = true\n"
  else
    status = colourize("Task failed",:red)
    $fSUMMARY.write "status.success    = false\n"
  end



  endProcessTime = Time.now
  $totalDiff = endProcessTime - $startProcessTime
  $fSUMMARY.write "status.processingtime  = #{$totalDiff}\n"

  stream_out drawRuler("Run Summary")
  stream_out "\n"
  stream_out( " Total processing time: #{$totalDiff.to_f.round(2)} seconds\n" )
  if $program =~ /substitute-h2k\.rb/ then
    stream_out( " Total H2K execution time : #{$runH2KTime.to_f.round(2)} seconds\n" )
    stream_out( " H2K evaluation attempts: #{$gStatus["H2KExecutionAttempts"]} \n" )
  end

  stream_out "\n"
  stream_out " -> Informational messages:\n\n"
  stream_out "#{$InfoBuffer}\n"

  stream_out " -> Warning messages:\n\n"
  stream_out "#{$WarningBuffer}\n"
  stream_out ""
  stream_out " -> Error messages:\n\n"
  stream_out "#{$ErrorBuffer}\n"
  stream_out " STATUS: #{status} \n"
  stream_out drawRuler

  $fLOG.flush

  #if ($fLOG != nil )
  #  $fLOG.write("\n\n ERROR: #{msg}\n\n")
  #end
  #$gErrors << msg.gsub(/\n/,'')
  #$allok = false

end

def formatTimeInterval(timearg)

  time = timearg.to_f
  if ( time > 86400 )
    timeMsg = "#{(time / 86400).round(1)} days"

  elsif ( time> 3600 )
    timeMsg = "#{(time / 3600).round(1)} hours"

  elsif ( time > 60 )
    timeMsg = "#{(time / 60).round(0)} minutes"

  else
    timeMsg = "#{(time ).round(0)} seconds"

  end

  return timeMsg

end
