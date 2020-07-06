
require 'digest'
require 'rexml/document'
require 'csv'
require 'json'
require 'fileutils'
require 'optparse'
require 'pp'
require 'date'
require 'set'

require_relative '../inc/msgs'
require_relative '../inc/constants'
require_relative '../inc/HTAPUtils'

$program = "coax-cost-data.rb"

HTAPInit()

 
$convertedDates = Hash.new

$gDebugOutput = String.new

current_time = DateTime.now

$gTest_params["verbosity"] 

encoding_alias = {  "\u{00F6}" => "in."  ,
                     # "\u{00AA}" => "",
                      "\u{2551}" => "o",
                      #"\u{00F2}" => "o",
                     # "\u{00E6}" => "o"
                   }


class Float
  def approx(other, relative_epsilon=Float::EPSILON, epsilon=Float::EPSILON)
    diff = other.to_f - self
    return true if diff.abs <= epsilon
    relative_error = ( diff / (self > other ? self : other )).abs
    return relative_error <= relative_epsilon
  end
end


def get_unicode(char)
  begin unicode_search
    (0..109_976).each do |pos|
      chr = ''
      chr << pos
      return pos.to_s(16) if chr == char
    end
  rescue 
    #debug_on 
    debug_out "Could not locate unicode equivlent for >#{char}<\n"
    return ""
  end 
end

# Function that attempts to intrepret dates from a sting.
# TODO: Normalize the date into a standard format
def FindDateInString(string)
    #debug_on
    debug_out " searching for date in #{string}\n"
    $FoundDate = "#{string}"
    $Convertable = true
    if ( string =~ /(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[^ ]*( |-)+2[0-9][0-9][0-9]/i ) then

      $FoundDate.gsub!(/^.*((jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[^ ]*( |-)+2[0-9][0-9][0-9]).*$/i, "\\1")

    elsif ( string =~ /(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[^ ]*( |-)+[0-3]*[0-9](th)*( |-)+2[0-9][0-9][0-9]/i ) then

      $FoundDate.gsub!(/^.*((jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec))[^ ]*( |-)+([0-3]*[0-9])(th)*( |-)+(2[0-9][0-9][0-9]).*$/i, "\\1 \\4 \\7")

    elsif ( string =~ /2[0-9][0-9][0-9].[0-1][0-9].[0-3][0-9]/i ) then

      $FoundDate.gsub!(/^.*(2[0-9][0-9][0-9].[0-1][0-9].[0-3][0-9]).*$/i, "\\1")

    elsif ( string =~ /[0-3][0-9].[0-3][0-9].2[0-9][0-9][0-9]/i ) then


      $FoundDate.gsub!(/^.*([0-3][0-9].[0-3][0-9].2[0-9][0-9][0-9]).*$/i, "\\1")

    elsif ( string =~ /2[0-9][0-9][0-9]/i ) then

      $FoundDate.gsub!(/^.*(2[0-9][0-9][0-9]).*$/i, "\\1")

    else

      $Convertable = false
      $FoundDate =  "n.d."

    end

    if ( $Convertable ) then

      if ( $convertedDates[$FoundDate].nil? || $convertedDates[$FoundDate].empty? ) then
        $convertedDates[$FoundDate] = Array.new
      end

      $convertedDates[$FoundDate].push string

    end

    return $FoundDate

end


# removes problematic spaces, standardizes degrees C/F 
def cleanString(string)
   
   return string if (! string.is_a?(String))
   return string if (emptyOrNil(string))
   string.gsub!(/ +$/,"")
   #string.gsub!(/\(.*\)/,"")
   string.gsub!(/^\s+/,"")
   string.gsub!(/\s+$/,"")
   string.gsub!(/\"/,"in")
   string.gsub!(/([0-9]+o)c/,"\1C")
   string.gsub!(/([0-9]+o)f/,"\1F")
   string.gsub!(/o\.c$/, "o.c.")
   return string 
end 

# copes with common mispellings in leep sheets
def fixMisspellings(string)
  return string if (! string.is_a?(String))
  return string if (emptyOrNil(string))
  string.gsub!(/agregated/i,"aggregated")
  string.gsub!(/maintain/i,"maintain")
  string.gsub!(/drillin /i,"drilling ")
  string.gsub!(/fmineral/i,"mineral")
  return string
end 

# renames various unit alises with standard equivlents
def standardizeUnits(string)
  return string if (! string.is_a?(String))
  return string if (emptyOrNil(string))
  string.gsub!(/\s+$/,"")
  string.gsub!(/^ea /,"ea")
  string.gsub!(/sq\.ft\. floor/, "sf heated floor area")
  return string 
end 

# Replaces spaces with another character (default: '-')
def replaceSpaces(string, replacement="-")
   return string if (! string.is_a?(String))
   return string if (emptyOrNil(string))
   string.gsub!(/ +/,replacement)
   return string 
end 

# Converts string to lower case and deletes whitespace
def lowerCaseNoWhitespace(string ) 
   # version for comparison
   return "#{string}".downcase.gsub(/\s/,"")
end 

# Placeholder for operations on comments / notes 
def fixNotes(string)
  return string   
end 

# Parse according to new HTAP format.
def parseHTAPSchemaLine(line)

  unitCostRecord = {"parsedOK" => false, "data" => Hash.new }
  debug_out "passed line: #{line}\n"
  cols = CSV.parse(line)
  debug_out "Columns: #{cols.pretty_inspect}\n"

  
  unitCostRecord["data"] = { "category"           => cleanString((cols[0][1])), 
                             "description"        => fixMisspellings( cleanString((cols[0][2])) ),
                             "units"              => standardizeUnits( cleanString((cols[0][3])) ),
                             "UnitCostMaterials"  => cleanString("#{(cols[0][4])}").delete(",").to_f,
                             "UnitCostLabour"     => cleanString("#{(cols[0][5])}").delete(",").to_f,
  }

  if ( emptyOrNilRecursive(unitCostRecord["data"] ) ) then 
    unitCostRecord["parsedOK"]= false
    # (actally defaulted to this value above...)
  else 
    unitCostRecord["data"]["note"] = fixNotes( fixMisspellings( cleanString("#{cols[0][6]}") ) )
    unitCostRecord["parsedOK"]= true
  end

  debug_out ("Unit cost record: #{unitCostRecord.pretty_inspect}\n")
  return unitCostRecord
end 

# Parse according to old LEEP sheet format 
def parseOldLEEPSchemaLine(line,category)


  debug_out ("Passed Category: #{category}")
  debug_out ("passed line: #{line}\n" )


  unitCostRecord = {"parsedOK" => false, "data" => Hash.new }

  cols = CSV.parse(line)
  debug_out "Columns: #{cols.pretty_inspect}\n"


  
  unitCostRecord["data"] = { "category"           => cleanString( category.gsub(/\(.*\)/,"") ), 
                             "description"        => fixMisspellings( cleanString("#{(cols[0][0])}") ),
                             "units"              => standardizeUnits( cleanString((cols[0][2])) ),
                             "UnitCostMaterials"  => cleanString("#{(cols[0][3])}").delete(",").to_f,
                             "UnitCostLabour"     => cleanString("#{(cols[0][6])}").delete(",").to_f,
  }

  if ( emptyOrNilRecursive(unitCostRecord["data"] ) ) then 
    unitCostRecord["parsedOK"]= false
    # (actally defaulted to this value above...)
  else 
    unitCostRecord["data"]["note"] = fixNotes( fixMisspellings( cleanString("#{cols[0][10]}") ) )
    unitCostRecord["parsedOK"]= true
  end

  debug_out ("Unit cost record: #{unitCostRecord.pretty_inspect}\n")
  return unitCostRecord                             

end 

# Converts description into concise (but still readable) keyword
def createKeyword(description)

  return description if ( ! description.is_a?(String) )
  return description if (emptyOrNil(description) ) 
  keyword = "#{description}".downcase
  
  keyword.gsub!(/\(.+\)/,"")
  keyword.gsub!(/ *$/, "")
  keyword.gsub!(/ /,"_")

  keyword.gsub!(/_-_/,":")
  keyword.gsub!(/,/,":")
  keyword.gsub!(/:_/,":")
  keyword.gsub!(/_:/,":")
  keyword.gsub!(/__/,"_")
  keyword.gsub!(/_:/,":")
  keyword.gsub!(/:_/,":")  
  keyword.gsub!(/_$/,"")
  #keyword.gsub!(/a/,"@")
  return keyword
  
end 

def minimalCat(string)
  return string if (! string.is_a?(String))
  return string if (emptyOrNil(string))
  stest = "#{string}"
  stest.downcase!
  stest.gsub!(/\(.*\)/,"")
  stest.gsub!(/\s*/,"")
  return stest

end 

stream_out(drawRuler("A script for importing unit-cost-data into HTAP-friendly formats."))


$DBFileName = "HTAPUnitCosts.json"
validCatagories = Array.new

$costFiles = Array.new

rawCatagories = Array.new [   "AIR TIGHTNESS",
                               "FRAMING",
                               "DRYWALL",
                               "SHEATHING",
                               "INSULATION",
                               "CEILING INSULATION",
                               "ICF WALLS",
                               "STRUCTURAL INSULATED PANELS",
                               "WINDOWS",
                               "FOUNDATION WALLS",
                               "BASEMENT FLOOR",
                               "ADDITIVE COMPONENTS FOR THICKER WALL SYSTEMS",
                               "MECHANICAL & ELECTRICAL",
                               "FURNACES",
                               "Furnace",
                               "Furnace",
                               "DUCTING",
                               "Ducting",
                               "HRV",
                               "DHW",
                               "AIRCONDITIONING",
                               "GROUND SOURCE HEAT PUMP",
                               "GSHP",
                               "COLD CLIMATE AIR SOURCE HEAT PUMP",
                               "CCASHP",
                               "COMBINED SPACE AND WATER HEATING SYSTEMS ",
                               "MICRO-COMBINED HEAT AND POWER TECHNOLOGY",
                               "INTEGRATED MECHANICAL SYSTEMS",
                               "CENTRALIZED ZONED FORCED AIR SYSTEMS",
                               "LIGHTING",
                               "SWITCHING",
                               "OTHER",
                               "WIRING",
                               "DRAIN WATER HEAT RECOVERY",
                               "RENEWABLE ENERGY AND COMMUNITY SYSTEMS",
                               "PASSIVE SOLAR DESIGN",
                               "PHOTOVOLTAIC SYSTEMS",
                               "SOLAR DOMESTIC HOT WATER  ",
                               "SOLAR READY",
                               "CEILING",
                               "ENERGY PRICING",
                               "ENVELOPE & CONSTRUCTION",
                               "PANELIZED WALLS",
                               "ROOF",
                               "AC",
                               "GROUND SOURCE HEAT PUMP (ME12)",
                               "COLD CLIMATE AIR SOURCE HEAT PUMP (ME04)",
                               "DUCTLESS MINISPLIT",
                               "COMBINED SPACE AND WATER HEATING SYSTEMS (ME05)",
                               "MICRO-COMBINED HEAT AND POWER TECHNOLOGY (ME06)",
                               "INTEGRATED MECHANICAL SYSTEMS (ME16)",
                               "CENTRALIZED ZONED FORCED AIR SYSTEMS (ME27)",
                               "AIR SOURCE HEAT PUMP",
                               "ELECTRIC RESISTANCE BASEBOARDS",
                              ]

rawCatagories.each do |category|
  #catagory.downcase!.gsub!(/\(.*\)/,"").gsub!(/\s*/,"")
  validCatagories.push( minimalCat(category) )
end 


# text that can be safely ignored.
knownBadCatagories = ["UNIT COSTS",
                      "GENERAL",
                      "Base case house with sub-optimal orientation",
                      "Upgraded house with optimal orientation",
                      "LAST ROW",
                      "CHANGE LOG AREA",
                      "Last edited by"
]

## Handle all functional keywords in lower case
#validCatagories.keys.each do |src|
#  validCatagories[src].each do |cat|
#    cat.downcase!.gsub!(/\s*/,"").gsub!(/\(.*\)/,"")
#  end
#end
#
#$KnownBadCatagories.keys.each do |src|
#  $KnownBadCatagories[src].each do |cat|
#    cat.downcase!.gsub!(/\s*/,"").gsub!(/\(.*\)/,"")
#  end
#end


$thinruler = " . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .\n"
$ruler     = " .......................................................................\n"
$header = " coax-cost-data.rb: A tool for managing HTAP cost data.  It attempts
                    to cope with the highly unstructured nature of cost
                    data sheets, and coaxes it into an HTAP-friendly
                    format.
\n"




optparse = OptionParser.new do |opts|

   opts.banner = "#{$header}\n\n Options:"

   opts.on("-h", "--help", "Show help message") do
      print $ruler
      print opts
      print $ruler
      exit()
   end

   opts.on("--import FILE.csv", "File that should be used to begin CSV import. ") do |file|

     $file = file

   end

   opts.on("--database FILENAME.json", "Path to cost database in json format.",
                                       "If this file exists, new data will be ",
                                       "appended to it. Otherwise it will be ",
                                       "created.") do |b|

     $DBFileName = b

   end

   opts.on("--export_to_csv",
           "Export the cost database in flattened .csv",
           "format. Script will create or overwrite file",
           "HTAPUnitCostsFlattened.csv") do

     $flatten_to_csv = true

   end

   opts.on("--hints", "Provide helpful hints for intrepreting output, if available") do
     $gHelp = true
   end


   opts.on("-d", "--debug [FILE.txt] ",
           "Print debugging messages to screen, or if ",
           "[FILE.txt] is given, to specified text file.") do |logfile|



     $gDebug = true
     if ( !  logfile.nil? && ! logfile.empty? ) then
       $gDebugOutput = logfile
       $gDebugHandle = File.new($gDebugOutput, 'w')
     end

   end


end

optparse.parse!


$linecount = 0

$MyCatagory = "";
$MyCategoryComp = "";
loggedCatagories = Hash.new
$LoggedUnits = Array.new
ignoredCatagories = Hash.new


##

# Check if DB file exists.

parsedDBCostData = Hash.new


stream_out(" -> Preparing to parse cost database - #{$DBFileName}...")
begin
  fDB = File.new($DBFileName, "r")
rescue
  
end

if fDB == nil then
   stream_out(" (File not found. Will be created.)\n")
   parsedDBCostData = { "sources" => Hash.new,
                        "data"    => Hash.new }
   info_out("Costing database #{$DBFileName} was not found; new file created. ")
else

   dbcontents = fDB.read
   parsedDBCostData = JSON.parse(dbcontents)
   fDB.close
   info_out("Costing database #{$DBFileName} opened successfully; data will be appended.")
   stream_out("done.\n")
end


stream_out(" -> Parsing unit cost input file #{$file}: line # 0\r")
begin
fInput = File.new($file, "r")
rescue
  if fInput== nil then
    fatalerror("\n\nFatal error: Could not read #{$file}.\n")
  end
end 

info_out("Cost data sheet #{$file} successfully opened.")


encodings = Hash.new

importedCostData = { "sources" => Hash.new,
                     "data"    => Hash.new }

encodeErrors = Hash.new



linecount = 0
parsedlines = 0 

metadata = { "name"    => "unknown",
             "schema"   => "oldLeep",
             "origin"   => "unknown",
             "collated" => "unknown"
           }
tempCatagory = ""
while !fInput.eof? do

  

  $parsedOK = true
  lineHasData = false 
  line = fInput.readline
  orig_encoding = line.encoding

  linecount += 1
  
  debug_out " . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .\n"
  stream_out(" -> Parsing unit cost input file #{$file}: line #{linecount} \r")
  line.strip! 
  line.gsub!(/""/,"in")

  debug_out " LINE (unrecoded) #{linecount}: #{line} \n"

   begin :parse
     #orig_encoding = "CP850"

     recodeLine = "#{line.encode("UTF-8", orig_encoding)}"
     searchLine = "#{line}".encode(orig_encoding)

     #stop=false

     encode_fixed = false
     encoding_alias.each do |search, replace|
     #
       recodeLine.gsub!(/#{search}/, replace)

     #$searchNative=search.encode!($orig_encoding,"UTF-8")
     #  $recodeLine.gsub!(/$searchNative/, replace.encode!($orig_encoding,"UTF-8"))
     #  $recodeLine.encode("UTF-8")
     #
     end

     if ( searchLine.encode("UTF-8", orig_encoding) =~ /[^\p{ASCII}]/   ) then

       searchLine.encode!("UTF-8").gsub!(/[\p{ASCII}]/, "".encode!("UTF-8"))

       cars = get_unicode($searchLine)

       encodeErrors["Line:#{$linecount}"] =  { "encoding"       =>   orig_encoding,
                                                "Text"           =>  recodeLine,
                                                "bad_char"       =>  searchLine.encode("UTF-8") ,
                                                "unicode_cars"   =>  cars,
                                               # "fixed?"         =>  $fixed
                                               }

     end



     

     codeKey = "#{orig_encoding}|-to->|#{recodeLine.encoding}"

     if (! encodings.keys.include? codeKey ) then

       encodings[codeKey] = 0

     end

     encodings[codeKey] = encodings[codeKey] + 1
     debug_out " LINE ( recoded ) #{linecount}: #{recodeLine} \n"

   rescue
     debug_out "\n recoding failed \n"
     $parsedOK = false
     next
   end
     

   if (recodeLine =~ /^meta,/ ) then 
    #debug_on
    metaCols = Array.new
    metaCols = CSV.parse(recodeLine)
    debug_out "Parsing meta tag:   #{metaCols[0][1]} = #{metaCols[0][2]} \n"
    metadata[cleanString(metaCols[0][1])] = cleanString(metaCols[0][2])
    debug_off
   else 
    # line is data. 

    if ( metadata["schema"] == "htap" )
      next if ( recodeLine !~ /^data/ ) 
      #debug_on
      debug_out ("Parsing htap schema!\n")      
      costData = parseHTAPSchemaLine(recodeLine)
      debug_out ("Cost data returned: #{costData.pretty_inspect}\n")
      debug_out (" is category |#{costData["data"]["category"]}| valid ?\n")
      if ( validCatagories.include?( minimalCat(costData["data"]["category"] ) ) &&  costData["parsedOK"] ) 
        lineHasData = true 
      else 
        tempCategory = "#{costData["data"]["category"]}".gsub(/Last edited by.*$/,"Last edited by ...")
        if ( emptyOrNil(ignoredCatagories[tempCategory] ) ) then
          ignoredCatagories[tempCategory] = { "count"=>0, "lines" =>""}
        end 
        ignoredCatagories[tempCategory]["count"] += 1
        ignoredCatagories[tempCategory]["lines"] += "#{linecount}, "

      end 
      debug_off

    elsif  ( metadata["schema"].downcase == "oldleep" )
      #debug_on
      debug_out ("Parsing old leep schema!\n")
      tempCols = CSV.parse(recodeLine)
      firstCol = tempCols[0][0]
      thirdCol = tempCols[0][2]
      debug_out (" ... 1: #{firstCol}\n ... 3: #{thirdCol}\n")

      if ( ! emptyOrNil(firstCol) && emptyOrNil(thirdCol)  ) then 
        tempCategory = firstCol 
        #debug_on 

        if ( validCatagories.include?( minimalCat(tempCategory) ) ) then 
           #debug_on 
           debug_out ("Line: #{linecount}: #{recodeLine}\n")
           debug_out "    parsing old leep catagory... 1: #{firstCol}\n ... 3: #{thirdCol}\n"
           debug_off 
        else
           
          tempCategory.gsub!(/Last edited by.*$/,"Last edited by ...")
          if ( emptyOrNil(ignoredCatagories[tempCategory] ) ) then
            ignoredCatagories[tempCategory] = { "count"=>0, "lines" =>""}
          end 
          ignoredCatagories[tempCategory]["count"] += 1
          ignoredCatagories[tempCategory]["lines"] += "#{linecount}, "
          
          #debug_on 
          debug_out ("Line: #{linecount}: #{recodeLine}\n")
          debug_out ("CATAGORY - Line: #{linecount}: #{recodeLine}\n")
          debug_out ("     Ignoring catagory #{minimalCat(tempCategory)} \n ")
          debug_off
        end 
        

      elsif (validCatagories.include?(minimalCat(tempCategory) ) &&
            ! knownBadCatagories.include?(minimalCat(tempCategory) ) ) then 
          
          costData = costData = parseOldLEEPSchemaLine(recodeLine,tempCategory)

          if ( costData["parsedOK"] ) then 
            lineHasData = true
            #debug_on 
            debug_out ("Line: #{linecount}: #{recodeLine}\n")
            debug_out ("Cost data returned: #{costData.pretty_inspect}\n")
            debug_off
          end 

      end 

    else 
      fatalerror ("Unknown cost schema: #{metadata["schema"]}")

    end 

  end 
 
   # Save good data to importedCostData arrauy
   if ( $parsedOK && lineHasData && costData["parsedOK"] )
     #Saving data 

     keyword = createKeyword(costData["data"]["description"])
     
     citation = replaceSpaces(metadata["name"])
     debug_out ">keyword: #{keyword} \n>citation: #{citation}\n"

     if ( emptyOrNil(importedCostData["data"][keyword]) ) then 
       importedCostData["data"][keyword] = Hash.new
     end

     importedCostData["data"][keyword][citation] = costData["data"]
     importedCostData["data"][keyword][citation]["date"] = FindDateInString(costData["data"]["note"])
     importedCostData["data"][keyword][citation]["source"] = citation

     #debug_on
     debug_out ("Saved data - KEYWORD /#{keyword}/:\n")
     debug_out ("  #{importedCostData["data"][keyword].pretty_inspect}\n")
     debug_off
     parsedlines += 1
     


   end 

    # lineCols = CSV.parse(recodeLine)
  

end 
stream_out(" -> Parsed unit cost input file #{$file}: #{linecount} total lines.     \n")

ignoredCatagories.keys.each do | badCat |
  badCount = ignoredCatagories[badCat]["count"]
  badLines = ignoredCatagories[badCat]["lines"]
  warn_out("Ignored unrecognized catagory: \"#{badCat}\" (#{badCount} instances, at line #'s #{badLines}) \n")
  help_out("byMsg","importing costs:categories")
end 


info_out ("Imported #{linecount} lines.")
info_out ("Parsed #{parsedlines} cost records.")

citation = replaceSpaces(metadata["name"])

importedCostData["sources"][citation] = { "filename"      => "#{$file}",
                                          "date_collated"   => "#{metadata["collated"]}" ,
                                          "date_imported"   => current_time.strftime("%Y-%m-%d %H:%M:%S"),
                                          "schema_used"     => "#{metadata["schema"]}",
                                          "origin"          => "#{metadata["origin"]}",
                                          "inherits"        => Hash.new
                                        }



#debug_on
debug_out "Cost data: #{importedCostData["sources"].pretty_inspect}\n\n"
debug_out "metadata: #{metadata.pretty_inspect}\n\n"
debug_off



#debug_on
debug_out $ruler
debug_out "    MERGING DATA..."
debug_out $ruler
debug_off 

stream_out (" -> Merging imported data with contents of #{$file}...")



newKeys = 0
mergedKeys =0
inheretedKeys = 0
newRecords = Array.new
mergedRecords = Array.new
inheretedRecords = Array.new

#Create merged set of data.
debug_out "\n"
mergeDiag = ""

importedCitation = metadata["name"]

importedCostData["data"].keys.each do |keyword|

  debug_out $thinruler
  debug_out " KEYWORD: #{keyword} \n"
  
  impCostMat = importedCostData["data"][keyword][importedCitation]["UnitCostMaterials"].to_f
  impCostLab = importedCostData["data"][keyword][importedCitation]["UnitCostLabour"].to_f
  impUnits   = importedCostData["data"][keyword][importedCitation]["units"].to_s

  if ( parsedDBCostData["data"].keys.include? keyword ) then
    debug_out "  -> exists in existing DB! "
    # Key appears in both sets. Let's determine if it is substantially different.
    #  ( Different if a - units are different; b - material costs or labour costs are different; )
    unique = true

    inheretedSRC = ""

    parsedDBCostData["data"][keyword].keys.each do | source |

      parsedDBCostMat = parsedDBCostData["data"][keyword][source]["UnitCostMaterials"].to_f
      parsedDBCostLab = parsedDBCostData["data"][keyword][source]["UnitCostLabour"].to_f
      parsedDBUnits   = parsedDBCostData["data"][keyword][source]["units"].to_s

      matCostSame =  impCostMat.to_f.approx( parsedDBCostMat.to_f )
      labCostSame =  impCostLab.to_f.approx( parsedDBCostLab.to_f )

      debug_out "    ? UNI .... ex:(#{parsedDBUnits }) | im:(#{impUnits })\n"
      debug_out "    ? MAT .... ex:(#{parsedDBCostMat.to_s}) | im:( #{impCostMat})       -> pr:(#{matCostSame}) \n"
      debug_out "    ? LAB .... ex:(#{parsedDBCostLab.to_s}) | im:( #{parsedDBCostLab.to_s})  -> pr:(#{labCostSame}) \n"



      if ( (  impUnits =~ /#{parsedDBUnits}/ ) && matCostSame && labCostSame ) then

        inheretedSRC = source
        inheretedRecords.push "#{source}:#{keyword}"
        unique = false
        inheretedKeys = inheretedKeys + 1

        if ( importedCostData["sources"][citation]["inherits"][source].nil? ||
             importedCostData["sources"][citation]["inherits"][source].empty? ) then

          importedCostData["sources"][citation]["inherits"][source] = Array.new

        end

        debug_out ("    = data is the same; must be inhereted. \n")

        importedCostData["sources"][citation]["inherits"][source].push keyword

      end

      mergeDiag << [citation, source, keyword, unique, impUnits, parsedDBUnits, parsedDBCostMat.to_f, impCostMat.to_f, parsedDBCostLab.to_f,impCostLab.to_f].to_csv

    end

    if ( unique ) then


      importedCostData["data"][keyword].keys.each do | source |

        parsedDBCostData["data"][keyword][source] = importedCostData["data"][keyword][source]
      end

      mergedKeys = mergedKeys + 1

      mergedRecords.push "keyword"


    end





  else

    parsedDBCostData["data"][keyword] = importedCostData["data"][keyword]
    newKeys = newKeys + 1
    newRecords.push keyword

  end
end



# Create merged set of sources
importedCostData["sources"].keys.each do |source|
  # Check to see if it exists.
  if ( parsedDBCostData["sources"].keys.include? source ) then
    print "\n"
    print $ruler
    print " Fatal error: set #{source} already exists in #{$DBFileName} !!!\n"
    print " (previously imported on #{parsedDBCostData["sources"][source]["date_imported"].to_s}.)\n"
    print $ruler
    exit
  else
    parsedDBCostData["sources"][source] = importedCostData["sources"][source]
  end
end


if $gDebug && ! emptyOrNil( $mergeDiag ) then
   if ( ! File.file?('./mergeDiag.csv') ) then
      diagfile = File.open('./mergeDiag.csv', 'w' )
      diagfile.puts "IMSRC, EXSRC, Keyword, unique, impUnits, parsedDBUnits, parsedDBCostMat, impCostMat, parsedDBCostLab,impCostLab\n"
   else
      diagfile = File.open('./mergeDiag.csv', 'a')
   end
   diagfile.puts $mergeDiag
   diagfile.close

end


parsedDBportCostData = Hash.new
parsedDBportCostData = {"sources" => Hash.new,
                   "data" =>Hash.new }


# Append keys to sorted hash
parsedDBCostData["sources"].keys.sort.each do |source|

  parsedDBportCostData["sources"][source] = parsedDBCostData["sources"][source]

end


# Append to export hash, and optionally, flatten to csv.

$flat_output = ""
flat_header = " keyword, source, units, UnitCostMaterials($), UnitCostLabour($), date, category, description, note \n"




parsedDBCostData["data"].keys.sort.each do |keyword|

  parsedDBportCostData["data"][keyword] = parsedDBCostData["data"][keyword]

  if ( $flatten_to_csv ) then

    parsedDBCostData["data"][keyword].keys.sort.each do |source|

        $flat_output << [ keyword,
                          source,
                          parsedDBCostData["data"][keyword][source]["units"],
                          parsedDBCostData["data"][keyword][source]["UnitCostMaterials"],
                          parsedDBCostData["data"][keyword][source]["UnitCostLabour"],
                          parsedDBCostData["data"][keyword][source]["date"],
                          parsedDBCostData["data"][keyword][source]["category"],
                          parsedDBCostData["data"][keyword][source]["description"],
                          parsedDBCostData["data"][keyword][source]["note"]
                        ].to_csv

    end

  end

end


if ( $flatten_to_csv ) then

  csv_outfile = File.open('./HTAPUnitCostsFlattened.csv', 'w')
  csv_outfile.puts flat_header
  csv_outfile.puts $flat_output
  csv_outfile.close

end




stream_out "done. \n"

#if ( ! ignoredCatagories.keys.empty? ) then
#
#  stream_out (" -> WARNING: The following #{ignoredCatagories.length.to_s} categories were ignored:\n")
#  ignoredCatagories.keys.sort.each do |cat|
#    stream_out( "     - \"#{cat}\"\n")
#    stream_out( "         (lines: ")
#    ignoredCatagories[cat].sort.each do | line |
#      stream_out( "#{line}, ")
#    end
#    stream_out(")\n")
#  end
#
#
#end


info_out( "Created #{newKeys.to_s} new records in #{$DBFileName}.")
info_out( "Appended additional cost data to #{mergedKeys.to_s} existing records in #{$DBFileName}")
info_out( "Logged #{inheretedKeys.to_s} records that were inherited from other sources already in #{$DBFileName}.\n")


File.open("./#{$DBFileName}", 'w') do |file|
  file.puts JSON.pretty_generate(parsedDBportCostData)
  file.close
end
info_out("HTAP cost database #{$DBFileName} successfully saved with updated cost data.")

#File.open('./HTAPUnitCostsLite.json', 'w') do |file|
#  file.puts JSON.pretty_generate(parsedDBCostData["data"])
#  file.close
#end



debug_out "............DatesConv.................."
debug_out "\n"
debug_out ( "#{$convertedDates.pretty_inspect}" )

debug_out ("............Categories Encountered....")
debug_out ("\n")
debug_out ( loggedCatagories.pretty_inspect )

debug_out ("............Categories Ignored....")
debug_out ("\n")
debug_out ( ignoredCatagories.pretty_inspect )


debug_out ("............records merged.................")
debug_out ("\n")
debug_out ( mergedRecords.pretty_inspect )

debug_out ("............records inhereted.................")
debug_out ("\n")
debug_out ( inheretedRecords.pretty_inspect )


debug_out ("............records created.................")
debug_out ("\n")
debug_out ( "#{newRecords.pretty_inspect} \n" )

debug_out ("............Line Encoding...................")
debug_out ("\n")
debug_out ( encodings.pretty_inspect)

debug_out ("............Encoding Changes ...................")
debug_out ("\n")
debug_out ( encodeErrors.pretty_inspect)
debug_off


 ReportMsgs()