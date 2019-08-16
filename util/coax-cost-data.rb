
require 'digest'
require 'rexml/document'
require 'csv'
require 'json'
require 'fileutils'
require 'optparse'
require 'pp'
require 'date'
require 'set'

require_relative '../include/msgs'
require_relative '../include/constants'
require_relative '../include/HTAPUtils'

 
convertedDates = Hash.new

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
    debug_on 
    debug_out "Could not locate unicode equivlent for >#{char}<\n"
    return ""
  end 
end

# Function that attempts to intrepret dates from a sting.
# TODO: Normalize the date into a standard format
def FindDateInString(string)

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

      if ( convertedDates[$FoundDate].nil? || convertedDates[$FoundDate].empty? ) then
        convertedDates[$FoundDate] = Array.new
      end

      convertedDates[$FoundDate].push string

    end

    return $FoundDate

end

def parseHTAPSchemaLine(line)
  debug_on
  unitCostRecord = {"parsedOK" => false, "data" => Hash.new }
  debug_out "passed line: #{line}\n"
  cols = CSV.parse(line)
  debug_out "Columns: #{cols.pretty_inspect}\n"

  
  unitCostRecord["data"] = { "category"           => (cols[0][1]), 
                             "description"        => (cols[0][2]),
                             "units"              => (cols[0][3]),
                             "UnitCostMaterials"  => (cols[0][4]),
                             "UnitCostLabour"     => (cols[0][5])
  }
    

  

  if ( emptyOrNilRecursive(unitCostRecord["data"] ) ) then 
    unitCostRecord["parsedOK"]= false
    # (actally defaulted to this value above...)
  else 
    unitCostRecord["data"].each do | key, value |
      value = cleanString(value)
    end 
    unitCostRecord["data"]["UnitCostNote"] = cleanString(cols[0][6])
    unitCostRecord["parsedOK"]= true
  end

  debug_out ("Unit cost record: #{unitCostRecord.pretty_inspect}\n")
  return unitCostRecord
end 

def createKeyword(description)
  keyword = "#{description}".downcase
  keyword.gsub!(/ /,"_")
  keyword.gsub!(/ /,"_")
  keyword.gsub!(/_-_/,":")
  keyword.gsub!(/,/,":")
  keyword.gsub!(/:_/,":")
  keyword.gsub!(/:_/,":")
  keyword.gsub!(/__/,"_")
  keyword.gsub!(/_$/,"")
  keyword.gsub!(/_:/,":")
  keyword.gsub!(/\(.+\)/,"")
  return keyword
end 


def cleanString(string)
   return string if (! string.is_a?(String))
   return string if (emptyOrNil(string))
   string.gsub!(/\(.*\)/,"")
   string.gsub!(/^\s+/,"")
   string.gsub!(/\s+$/,"")
   return string 
end 


def replaceSpaces(string, replacement="-")
   return string if (! string.is_a?(String))
   return string if (emptyOrNil(string))
   string.gsub!(/ +/,replacement)
   return string 
end 




def lowerCaseNoWhitespace(string ) 
   # version for comparison
   return "#{string}".downcase.gsub(/\s/,"")
end 





$DBFileName = "HTAPUnitCosts.json"


$costFiles = Array.new

validCatagories = Array.new [   "AIR TIGHTNESS",
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

validCatagories.each do |catagory|
  catagory.downcase!.gsub!(/\s*/,"").gsub!(/\(.*\)/,"")
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

stream_out $ruler
stream_out $header
stream_out $ruler





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
else

   dbcontents = fDB.read
   parsedDBCostData = JSON.parse(dbcontents)
   fDB.close
   stream_out("done.\n")
end


stream_out(" -> Parsing unit cost input file #{$file}...")

fInput = File.new($file, "r")
if fInput== nil then
   stream_out("\n\nFatal error: Could not read #{$file}.\n")
   exit
end

encodings = Hash.new

importedCostData = { "sources" => Hash.new,
                     "data"    => Hash.new }

encodeErrors = Hash.new

debug_on

linecount = 0

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

    metaCols = Array.new
    metaCols = CSV.parse(recodeLine)
    debug_out "Parsing meta tag:   #{metaCols[0][1]} = #{metaCols[0][2]} \n"
    metadata[cleanString(metaCols[0][1])] = cleanString(metaCols[0][2])

   else 
    # line is data. 

    if ( metadata["schema"] == "htap" )
      next if ( recodeLine !~ /^data/ ) 

      debug_out ("Parsing with htap schema!\n")      
      costData = parseHTAPSchemaLine(recodeLine)
      debug_out ("Cost data returned: #{costData.pretty_inspect}\n")
      debug_out (" is category |#{costData["data"]["category"]}| valid ?\n")
      if ( validCatagories.include?( lowerCaseNoWhitespace(costData["data"]["category"] ) ) &&  costData["parsedOK"] ) 
        lineHasData = true 
      else 
        $parsedOK = false 
        warn_out "Unsupported catagory: #{costData["data"]["category"]}\n"
        pp costData
      end 
      

    elsif  ( metadata["schema"].downcase == "oldleep" )
      debug_out ("Parsing old leep schema!\n")
      tempCols = CSV.parse(recodeLine.gsub(/\"/,""))
      firstCol = tempCols[0][0]
      thirdCol = tempCols[0][2]
      debug_out (" ... 1: #{firstCol}\n ... 3: #{thirdCol}\n")

      if ( ! emptyOrNil(firstCol) && emptyOrNil(thirdCol)  ) then 

        tempCatagory = firstCol 

      elsif (validCatagories.include?(lowerCaseNoWhitespace(tempCatagory) ) &&
            ! knownBadCatagories.include?(lowerCaseNoWhitespace(tempCatagory) ) ) then 
          debug_out "parsing line\n"
      end 
 

    end 


   end 
 
 
   if ( $parsedOK && lineHasData && costData["parsedOK"] )
     #Saving data 
     pp metadata
     keyword = createKeyword(costData["data"]["description"])
     citation = replaceSpaces(metadata["name"])
     debug_out ">keyword: #{keyword} \n>citation: #{citation}\n"

     if ( emptyOrNil(importedCostData["data"][keyword]) ) then 
       importedCostData["data"][keyword] = Hash.new
     end

     importedCostData["data"][keyword][citation] = costData["data"]
     importedCostData["data"][keyword][citation]["date"] = FindDateInString(costData["data"]["note"])
     
     
#    {
#                                                       "category"          => "#{$MyCatagory}",
#                                                       "description"       => "#{$MyDescription}",
#                                                       "units"             => "#{$MyUnits}",
#                                                       "UnitCostMaterials" => $MyMaterialsUnitCost,
#                                                       "UnitCostLabour"    => $MyLabourUnitCost,
#                                                       "note"              => "#{$MyNote}",
#                                                       "date"              => "#{$MyDate}",
#                                                       "source"            => "#{citation}"
#                                                     }
#
   end 

    # lineCols = CSV.parse(recodeLine)

   exit if linecount > 15

end 


citation = replaceSpaces(metadata["origin"])

importedCostData["sources"][citation] = { "filename"      => "#{$file}",
                                          "date_collated"   => "#{metadata["collated"]}" ,
                                          "date_imported"   => current_time.strftime("%Y-%m-%d %H:%M:%S"),
                                          "schema_used"     => "#{metadata["schema"]}",
                                          "origin"          => "#{metadata["origin"]}",
                                          "inherits"        => Hash.new
                                        }




debug_out "Cost data: #{importedCostData["sources"].pretty_inspect}\n\n"
debug_out "metadata: #{metadata.pretty_inspect}\n\n"





debug_out $ruler
debug_out "    MERGING DATA..."
debug_out $ruler

exit
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


if $gDebug && ! $mergeDiag.empty?  then
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

if ( ! ignoredCatagories.keys.empty? ) then

  stream_out (" -> WARNING: The following #{ignoredCatagories.length.to_s} categories were ignored:\n")
  ignoredCatagories.keys.sort.each do |cat|
    stream_out( "     - \"#{cat}\"\n")
    stream_out( "         (lines: ")
    ignoredCatagories[cat].sort.each do | line |
      stream_out( "#{line}, ")
    end
    stream_out(")\n")
  end


end

stream_out " -> Results: \n"
stream_out "    Created #{newKeys.to_s} new records; \n"
stream_out "    appended data to #{mergedKeys.to_s} records; \n"
stream_out "    ignored #{inheretedKeys.to_s} records that were inherited.)\n"


File.open("./#{$DBFileName}", 'w') do |file|
  file.puts JSON.pretty_generate(parsedDBportCostData)
  file.close
end


#File.open('./HTAPUnitCostsLite.json', 'w') do |file|
#  file.puts JSON.pretty_generate(parsedDBCostData["data"])
#  file.close
#end


if $gDebug then
debug_out "............DatesConv.................."
debug_out ""
debug_out ( convertedDates.pretty_inspect )

debug_out ("............Categories Encountered....")
debug_out ("")
debug_out ( loggedCatagories.pretty_inspect )

debug_out ("............Categories Ignored....")
debug_out ("")
debug_out ( ignoredCatagories.pretty_inspect )


debug_out ("............records merged.................")
debug_out ("")
debug_out ( mergedRecords.pretty_inspect )

debug_out ("............records inhereted.................")
debug_out ("")
debug_out ( inheretedRecords.pretty_inspect )


debug_out ("............records created.................")
debug_out ("")
debug_out ( newRecords.pretty_inspect )

debug_out ("............Line Encoding...................")
debug_out ("")
debug_out ( encodings.pretty_inspect)

debug_out ("............Encoding Changes ...................")
debug_out ("")
debug_out ( encodeErrors.pretty_inspect)


end






exit 

while !fInput.eof? do
  
   $line = fInput.readline
   $line.strip! 
   
   $line.gsub!(/""/,"in")

   $MyDescription = "";
   $MyUnits = "" ;
   $MyMaterialsUnitCost = nil;
   $MyLabourUnitCost = nil;
   $MyNote = "";

   $line = fInput.readline

   $orig_encoding = $line.encoding

   $line.strip!              # Removes leading and trailing whitespace
   $line.gsub!(/""/,"in")
   $LineCols = Array.new


   $parsedOK = true

   $linecount = $linecount + 1

   debug_out " . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .\n"
   debug_out " LINE (unrecoded) #{$linecount}: #{$line} "

   begin :parse
     $orig_encoding = "CP850"

     $recodeLine = "#{$line.encode("UTF-8", $orig_encoding)}"
     $searchLine = "#{$line}".encode($orig_encoding)

     $stop=false

     $encode_fixed = false
     $encoding_alias.each do |search, replace|
     #
       $recodeLine.gsub!(/#{search}/, replace)

       #$searchNative=search.encode!($orig_encoding,"UTF-8")
     #  $recodeLine.gsub!(/$searchNative/, replace.encode!($orig_encoding,"UTF-8"))
     #  $recodeLine.encode("UTF-8")
     #
     end
     

     if ( $searchLine.encode("UTF-8", $orig_encoding) =~ /[^\p{ASCII}]/   ) then


       $searchLine.encode!("UTF-8").gsub!(/[\p{ASCII}]/, "".encode!("UTF-8"))

       $cars = get_unicode($searchLine)

       encodeErrors["Line:#{$linecount}"] =  { "encoding"       =>   $orig_encoding,
                                                "Text"           =>   $recodeLine,
                                                "bad_char"       =>   $searchLine.encode("UTF-8") ,
                                                "unicode_cars"   =>   $cars,
                                               # "fixed?"         =>   $fixed
                                               }


     end




     $LineCols = CSV.parse($recodeLine)

     $codeKey = "#{$orig_encoding}|-to->|#{$recodeLine.encoding}"

     if (! encodings.keys.include? $codeKey ) then

       encodings[$codeKey] = 0

     end

     encodings[$codeKey] = encodings[$codeKey] + 1

   rescue
     $parsedOK = false
     next
   end






   $LineHasData = false

   case $schema

   when "oldLeep"

      $col1temp = "#{$LineCols[0][0]}"
      $col3temp = "#{$LineCols[0][2]}"



      if (  ! $col1temp.gsub(/\s+/,"").empty? ) then

        if (  $col3temp.gsub(/\s+/,"").empty? )  then

          $MyCatagory = "#{$LineCols[0][0]}"
          # version for writing
          $MyCatagory.gsub!(/\(.*\)/,"")
          $MyCatagory.gsub!(/^\s+/,"")
          $MyCatagory.gsub!(/\s+$/,"")

          # version for comparison
          $MyCategoryComp = "#{$MyCatagory}".downcase.gsub(/\s/,"")

          debug_out ( "___________________________________________________________\n")
          debug_out ( " CATAGORY: #{$MyCategory} (#{$MyCategoryComp}) ? #{validCatagories[$schema].include?($MyCategoryComp)} \n" )
          debug_out ( "    - based on [1] #{$col1temp} [3] #{$col3temp} !\n" )

        else

          $LineHasData = true
          $MyDescription = "#{$LineCols[0][0]}"

          $MyDescription.gsub!(/\"/,"in")
          $MyDescription.gsub!(/([0-9]+o)c/,"\1C")
          $MyDescription.gsub!(/([0-9]+o)f/,"\1F")




          # Hard-coded work-rounds for UTF-16 characters  - need to do this in a more robust way
          #$MyDescription.gsub!(/\(16.\)/,"(16in)")
          #$MyDescription.gsub!(/\(24.\)/,"(24in)")
          #$MyDescription.gsub!(/(0|O).F EWT/i,"0F EWT")

          $MyDescription.gsub!(/o\.c$/, "o.c.")

          $MyKeyword   = "#{$MyDescription.downcase}"

          $MyKeyword.gsub!(/ /,"_")
          $MyKeyword.gsub!(/ /,"_")
          $MyKeyword.gsub!(/_-_/,":")
          $MyKeyword.gsub!(/,/,":")
          $MyKeyword.gsub!(/:_/,":")

          $MyKeyword.gsub!(/\(.+\)/,"")
          $MyKeyword.gsub!(/__/,"_")
          $MyKeyword.gsub!(/_$/,"")
          $MyKeyword.gsub!(/_:/,":")
          $MyKeyword.gsub!(/:_/,":")

          $MyUnits             = "#{$LineCols[0][2]}"
          $MyMaterialsUnitCost = "#{$LineCols[0][3]}".delete(",").to_f
          $MyLabourUnitCost    = "#{$LineCols[0][6]}".delete(",").to_f
          $MyNote              = "#{$LineCols[0][10]}"

          $MyUnits.gsub!(/\s+$/,"")
          $MyUnits.gsub!(/^ea /,"ea")
          $MyUnits.gsub!(/sq\.ft\. floor/, "sf heated floor area")

                    # known misspellings
          $MyNote.gsub!(/agregated/i,"aggregated")
          $MyNote.gsub!(/maintain/i,"maintain")
          $MyNote.gsub!(/drillin /i,"drilling ")
          $MyNote.gsub!(/fmineral/i,"mineral")


          # Try to extract date from note
          $MyDate = FindDateInString($MyNote)



        end

      end

   else
     # Other schemas to go here.
   end


   # Create a list of catagories that that were encountered for debugging purposes.
   if ( ! loggedCatagories.include?($MyCatagory) ) then
        include = validCatagories[$schema].include?($MyCategoryComp)
        loggedCatagories[$MyCatagory] = include
   end


   # Check to see if current catagory is valid,
   # and store data in hash

   if ( ! validCatagories[$schema].include?($MyCategoryComp) ) then

     # Check to see if we know that this can be safely ignored.
     $known = false

     $KnownBadCatagories[$schema].each do |badCat|
       if ( $MyCategoryComp =~ /#{badCat}/ ) then
         $known = true
       end
     end

     if $MyCategoryComp =~ ( /^\s*$/ ) then

       $known = true

     end

     if ( !$known ) then
       if ( ! ignoredCatagories.keys.include?($MyCatagory) ) then
         ignoredCatagories[$MyCatagory] = Array.new
       end
       ignoredCatagories[$MyCatagory].push $linecount

     end

   elsif ( $LineHasData && validCatagories[$schema].include?($MyCategoryComp) ) then

      # if so, include it in the list of catagories we encountered.

      if ( ! loggedCatagories.include? $MyCatagory ) then

        loggedCatagories.push $MyCatagory

      end

      # Try to interpret contents.

      importedCostData["data"]["#{$MyKeyword}"] = Hash.new
      importedCostData["data"]["#{$MyKeyword}"][citation] = {
                                                        "category"          => "#{$MyCatagory}",
                                                        "description"       => "#{$MyDescription}",
                                                        "units"             => "#{$MyUnits}",
                                                        "UnitCostMaterials" => $MyMaterialsUnitCost,
                                                        "UnitCostLabour"    => $MyLabourUnitCost,
                                                        "note"              => "#{$MyNote}",
                                                        "date"              => "#{$MyDate}",
                                                        "source"            => "#{citation}"
                                                      }


   end

   if $gDebug then

     debug_out ("col 1>  #{$col1temp}\n")
     debug_out ("col 3>  #{$col3temp}\n")
     debug_out "   --> parsed ? #{$parsedOK} \n"
     if ( $parsedOK ) then

      debug_out "   ---> has data? #{$LineHasData} \n"
      if ( $LineHasData ) then
        debug_out "   ----> valid category? #{validCatagories[$schema].include?($MyCategoryComp)} \n"

        if (validCatagories[$schema].include?($MyCategoryComp)) then
           debug_out "   -----> \"KEYWORD\"           => \"#{$MyKeyword}\"            "
           debug_out "   -----> \"category\"          => \"#{$MyCatagory}\"          "
           debug_out "   -----> \"description\"       => \"#{$MyDescription}\"       "
           debug_out "   -----> \"units\"             => \"#{$MyUnits}\"             "
           debug_out "   -----> \"UnitCostMaterials\" =>  #{$MyMaterialsUnitCost}    "
           debug_out "   -----> \"UnitCostLabour\"    =>  #{$MyLabourUnitCost}       "
           debug_out "   -----> \"note\"              => \"#{$MyNote}\"              "
           debug_out "   -----> \"date\"              => \"#{$MyDate}\"              "
           debug_out "   -----> \"source\"            => \"#{citation}\"            "







        end

      end
     end
   end


end
stream_out ("done.\n")

importedCostData["sources"][citation] = { "filename"      => "#{$file}",
                                        "date_collated" => "#{$date}" ,
                                        "date_imported" => current_time.strftime("%Y-%m-%d %H:%M:%S"),
                                        "schema_used"   => "#{$schema}",
                                        "origin"        => "#{$source_description}",
                                        "inherits"      => Hash.new
                                  }



# Next: Merge Imported data with database.


debug_out $ruler
debug_out "    MERGING DATA..."
debug_out $ruler


stream_out (" -> Merging imported data with contents of #{$file}...")


newKeys = 0
mergedKeys =0
inheretedKeys = 0
newRecords = Array.new
mergedRecords = Array.new
inheretedRecords = Array.new

#Create merged set of data.
debug_out "\n"
$mergeDiag = ""

importedCostData["data"].keys.each do |keyword|
  # Check to see if it exists.

  debug_out $thinruler
  debug_out " KEYWORD: #{keyword} \n"

  impCostMat = importedCostData["data"][keyword][citation]["UnitCostMaterials"].to_f
  impCostLab = importedCostData["data"][keyword][citation]["UnitCostLabour"].to_f
  impUnits   = importedCostData["data"][keyword][citation]["units"].to_s


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

        if (! $gDebug ) then
          break
        end

      end

      $mergeDiag << [citation, source, keyword, unique, impUnits, parsedDBUnits, parsedDBCostMat.to_f, impCostMat.to_f, parsedDBCostLab.to_f,impCostLab.to_f].to_csv

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


if $gDebug && ! $mergeDiag.empty?  then
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

if ( ! ignoredCatagories.keys.empty? ) then

  stream_out (" -> WARNING: The following #{ignoredCatagories.length.to_s} categories were ignored:\n")
  ignoredCatagories.keys.sort.each do |cat|
    stream_out( "     - \"#{cat}\"\n")
    stream_out( "         (lines: ")
    ignoredCatagories[cat].sort.each do | line |
      stream_out( "#{line}, ")
    end
    stream_out(")\n")
  end


end

stream_out " -> Results: \n"
stream_out "    Created #{newKeys.to_s} new records; \n"
stream_out "    appended data to #{mergedKeys.to_s} records; \n"
stream_out "    ignored #{inheretedKeys.to_s} records that were inherited.)\n"


File.open("./#{$DBFileName}", 'w') do |file|
  file.puts JSON.pretty_generate(parsedDBportCostData)
  file.close
end


#File.open('./HTAPUnitCostsLite.json', 'w') do |file|
#  file.puts JSON.pretty_generate(parsedDBCostData["data"])
#  file.close
#end


if $gDebug then
debug_out "............DatesConv.................."
debug_out ""
debug_out ( convertedDates.pretty_inspect )

debug_out ("............Categories Encountered....")
debug_out ("")
debug_out ( loggedCatagories.pretty_inspect )

debug_out ("............Categories Ignored....")
debug_out ("")
debug_out ( ignoredCatagories.pretty_inspect )


debug_out ("............records merged.................")
debug_out ("")
debug_out ( mergedRecords.pretty_inspect )

debug_out ("............records inhereted.................")
debug_out ("")
debug_out ( inheretedRecords.pretty_inspect )


debug_out ("............records created.................")
debug_out ("")
debug_out ( newRecords.pretty_inspect )

debug_out ("............Line Encoding...................")
debug_out ("")
debug_out ( encodings.pretty_inspect)

debug_out ("............Encoding Changes ...................")
debug_out ("")
debug_out ( encodeErrors.pretty_inspect)


end
