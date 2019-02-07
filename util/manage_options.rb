

require 'rexml/document'
require 'optparse'
require 'timeout'
require 'fileutils'
require 'digest'
require 'json'
require 'set'
require 'pp'
require 'csv'
require_relative '../include/constants'
require_relative '../include/msgs'
require_relative '../include/H2KUtils'
require_relative '../include/HTAPUtils'

require_relative '../include/costing'
require_relative '../include/legacy-code'
include REXML   # This allows for no "REXML::" prefix to REXML methods
CWCdefsName = "wall-defs.txt"
def parseWallDefs()

  wallAlias = Hash.new
  wallAlias = {
    "cavity" => {
      "R14GlassFibreBatt" => "insulation:r14_batt",
      "R19GlassFibreBatt" => "insulation:r20_batt",
      "R22GlassFibreBatt" => "insulation:r22_batt",
      "R24GlassFibreBatt" => "insulation:r24_batt",
      "R28GlassFibreBatt" => "insulation:r28_batt",
      "2lb.ClosedCellSprayFoam" => { "2x6" => "insulation:spray_foam_2pd_urethane:5.5in_thickness",
        "2x8" => "insulation:spray_foam_2pd_urethane:7.5in_thickness",
        "1.5inApplied" => "insulation:spray_foam:38mm:r6/inch"  },
        "None" => "nil"
      },
      "framing" => {
        "2x4-16inOC" => "framing:conventional:38x89mm_o.c.",
        "2x6-16inOC" => "framing:conventional:38x140mm_o.c.",
        "2x6-24inOC" => "framing:advanced:38x140mm_o.c.",
        "2x6DoubledStud" => "framing:double_stud_wall:305mm"
      },
      "extIns" => {
        "1inUnfacedEPS" => "insulation:eps_type_1:rigid:25mm",
        "None" =>  "nil",
        "1inXPS" => "insulation:xps_type_4:rigid:25mm",
        "1.5inXPS" => "insulation:xps_type_4:rigid:38mm",
        "2inXPS" => "insulation:xps_type_4:rigid:51mm",
        "1inFoilFacedPolyiso" => "insulation:polyisocyanurate:foil-faced:25mm",
        "2inMineralWool" => "insulation_mineral_wool_board_8_lb._51mm_vertical_pt_strapping_&_screws",
        "3inMineralWool" => "insulation_mineral_wool_board_8_lb._76mm_vertical_pt_strapping_&_screws",
        "4inMineralWool" => "insulation_mineral_wool_board_8_lb._89mm_vertical_pt_strapping_&_screws"
      },
      "vapourBarrier" => {
        "Polyethylene" => "vapour_barrier:6_mil",
        #"SmartVapourRetarder"=>"selective_vapour_membrain",
        #"None" => "nil"
      }
    }

    wallRSIMin = {
                    "NBC_Wall_zone4"        => 2.78    ,
                    "NBC_Wall_zone5_noHRV"  => 3.08    ,
                    "NBC_Wall_zone5_HRV"    => 2.97    ,
                    "NBC_Wall_zone6_noHRV"  => 3.08    ,
                    "NBC_Wall_zone6_HRV"    => 2.97    ,
                    "NBC_Wall_zone7A_noHRV" => 3.08    ,
                    "NBC_Wall_zone7A_HRV"   => 2.97    ,
                    "NBC_Wall_zone7B_noHRV" => 3.85    ,
                    "NBC_Wall_zone7B_HRV"   => 3.08    ,
                    "NBC_Wall_zone8_noHRV"  => 3.85    ,
                    "NBC_Wall_zone8_HRV"    => 3.08    ,
    }

    # ?



    cwcDefs = File.open(CWCdefsName,'r')

    lineCount = 0
    lineCols = Array.new
    wallDefs = Hash.new

    wallDefsList = Hash.new

    cavityDefs  = Hash.new
    framingDefs = Hash.new
    extInsDefs  = Hash.new
    spacingDefs = Hash.new
    barrierDefs = Hash.new


    totalDefs = 0

    while !cwcDefs.eof? do

      lineCount += 1

      line = cwcDefs.readline
      #print "======================================================================\n"
      #print "lineCount #{lineCount} \n"
      #print "...............................................\n"

      #print "a| #{line}\n"
      #print "...............................................\n"
      line.gsub!(/\t/, ",")
      line.gsub!(/o.c./, "OC")
      line.gsub!(/\"/, "in")
      line.gsub!(/in\./, "in")
      line.gsub!(/\s/,"")

      lineCols = CSV.parse(line)

      rEff = lineCols[0][1]
      rNom = lineCols[0][2]
      framing = lineCols[0][3]
      spacing = lineCols[0][4]
      cavity  = lineCols[0][5]
      sheathing = lineCols[0][6]
      extIns = lineCols[0][7]
      cladding = lineCols[0][8]
      sheatingMembrane = lineCols[0][9]
      intVapBarrier = lineCols[0][10]




      #print "rEff       (lineCols[0][1]) = #{rEff}\n"
      #print "rNom       (lineCols[0][2]) = #{rNom       }\n"
      #print "framing    (lineCols[0][3]) = #{framing    }\n"
      #print "spacing    (lineCols[0][4]) = #{spacing    }\n"
      #print "cavity     (lineCols[0][5]) = #{cavity     }\n"
      #print "sheathing  (lineCols[0][6]) = #{sheathing  }\n"
      #print "extIns     (lineCols[0][7]) = #{extIns     }\n"


      #print "b| #{line}\n"
      #print "...............................................\n"



      next if ( wallAlias["cavity"][cavity].nil?  )

      next if ( cavity == "2lb.ClosedCellSprayFoam" &&
        wallAlias["cavity"][cavity][framing].nil? )

        next if ( wallAlias["framing"]["#{framing}-#{spacing}"].nil? )

        next if ( wallAlias["extIns"][extIns].nil? )

        next if ( wallAlias["vapourBarrier"][intVapBarrier].nil? )

        totalDefs += 1

        if (barrierDefs[intVapBarrier].nil?) then
          barrierDefs[intVapBarrier] = 0
        end

        if ( cavityDefs[cavity].nil? ) then
          cavityDefs[cavity]    = 0
        end

        if ( framingDefs[framing].nil? ) then
          framingDefs[framing]  = 0
        end

        if ( extInsDefs[extIns].nil? ) then
          extInsDefs[extIns]    = 0
        end

        if ( spacingDefs[spacing].nil? ) then
          spacingDefs[spacing]  = 0
        end

        cavityDefs[cavity]    += 1
        framingDefs[framing]  += 1
        extInsDefs[extIns]    += 1
        spacingDefs[spacing]  += 1
        barrierDefs[intVapBarrier] += 1

        if ( ! extIns.eql?("None") )
          extInsTxt = "+#{extIns}"
        else
          extInsTxt = ""
        end
        thisCode = "#{framing}-#{spacing}_#{cavity}#{extInsTxt}_#{intVapBarrier}_vb"
        thisCode.gsub!(/Polyethylene/,"poly")
        thisCode.gsub!(/GlassFibreBatt/,"-batt")
        if ( wallDefsList[thisCode].nil? )
          wallDefsList[thisCode] = Hash.new
          wallDefsList[thisCode] = {  "Count" => 1,
            "MaxReff" =>rEff.to_f,
            "MinReff" => rEff.to_f,
            "cavity"  => cavity,
            "framing" => framing,
            "vapourBarrier" => intVapBarrier,
            "spacing" => spacing,
            "extIns"  => extIns,
            "rRom"    => rNom
          }

        else
          wallDefsList[thisCode]["Count"] += 1

          if ( rEff.to_f.round(2) > wallDefsList[thisCode]["MaxReff"]) then
            wallDefsList[thisCode]["MaxReff"] = rEff.to_f
          end
          if ( rEff.to_f.round(2) < wallDefsList[thisCode]["MinReff"]  ) then
            wallDefsList[thisCode]["MinReff"]  = rEff.to_f
          end
        end
      end

      #pp wallDefs
      wallDefsList.keys.each do | code |

        thisCount    = wallDefsList[code]["Count"]
        thisRMax     = wallDefsList[code]["MaxReff"]
        thisRMin     = wallDefsList[code]["MinReff"]
        thisCavity   = wallDefsList[code]["cavity" ]
        thisFraming  = wallDefsList[code]["framing"]
        thisSpacing  = wallDefsList[code]["spacing"]
        thisExtIns   = wallDefsList[code]["extIns" ]
        thisVB       = wallDefsList[code]["vapourBarrier" ]
        thisrNom     = wallDefsList[code]["rNom" ]

        thisREffAvg = (thisRMax + thisRMin) / 2

        wall = "NC_R-#{thisREffAvg.to_f.round(0)}(eff)_#{code}"

        wallDefs[wall] = Hash.new
        wallDefs[wall] = {
          "h2kMap" => { "base" => {"Opt-H2K-EffRValue" => thisREffAvg.to_f.round(2) } },
          "costs"  => { "components"=> Array.new },
          "custom-costs" => Hash.new
        }
        if (! thisExtIns.eql?("None") ) then
          wallDefs[wall]["costs"]["components"].push wallAlias["extIns"][thisExtIns]
        end
        wallDefs[wall]["costs"]["components"].push("air_barrier_membrane")
        wallDefs[wall]["costs"]["components"].push("osb:12mm")
        if (! thisCavity.eql?("None") )then
          if ( !thisCavity.eql?("2lb.ClosedCellSprayFoam")) then
            wallDefs[wall]["costs"]["components"].push wallAlias["cavity"][thisCavity]
          else
            wallDefs[wall]["costs"]["components"].push wallAlias["cavity"][thisCavity][thisFraming]
          end
        end
        wallDefs[wall]["costs"]["components"].push wallAlias["framing"]["#{thisFraming}-#{thisSpacing}"]
        wallDefs[wall]["costs"]["components"].push wallAlias["vapourBarrier"][thisVB]
        wallDefs[wall]["costs"]["components"].push "1/2in_gypsum_board"

      end




      print "\n\n Cavity fill =======================\n"

      pp cavityDefs

      print "\n\n Framing definitions =======================\n"

      pp framingDefs

      print "\n\n Exterior insulation =======================\n"

      pp extInsDefs
      print "\n\n Framing spacing =======================\n"
      pp spacingDefs



      print "\n\n vapourBarriers =======================\n"
      pp barrierDefs

      return wallDefs



end




setTermSize

filename = "C:\\HTAP\\HTAP-options.json"
h2kCodeFile = "C:\\HTAP\\Archetypes\\codeLib.cod"

$program = "manage_options.rb"
$info    = "
  This script opens up the htap-options.json file and
  perfroms a set of tasks with it:

    - Reads through the options file to find Windows
      with the performance data defined via
      the characteristic data field, and creates similar
      records in the code library (at location
       #{h2kCodeFile}  )

  With these modifications, it creates a new version of
  the options file (HTAP-options-draft.json), and
  saves it to the working directory.


"

writeHeader()




fDefs = File.new(filename, "r")
parsedDefs = Hash.new

if fDefs == nil then
   fatalerror(" Could not read #{filename}.\n")
end
defsContent = fDefs.read
fDefs.close
parsedDefs = JSON.parse(defsContent)


wallDefs = Hash.new
wallDefs = parseWallDefs()



windowDefs = Hash.new
windowDefs = parsedDefs["Opt-CasementWindows"]["options"]

debug_off

debug_out drawRuler("parse code file", ". ")
debug_out " Parsing code xml from #{h2kCodeFile}..."
h2kCodeElements = Document.new
h2kCodeElements = H2KFile.get_elements_from_filename(h2kCodeFile)
debug_out "done.\n"

stream_out drawRuler("processing window definitions", "=")

windowDefs.keys.each do | window |

   thisWindowData = Hash.new
   thisWindowData = parsedDefs["Opt-CasementWindows"]["options"][window]
   # Does window have characteristics defined?
   if ( ! thisWindowData["characteristics"].nil? ) then
     stream_out "Syncing window definitions for #{window}\n"
     debug_out ".........\n"
     debug_out "#{window} Has characteristic data. Syncing with #{h2kCodeFile}!!!\n"

     str = ""
     h2kCodeElements = H2KLibs.AddWinToCodeLib(window,thisWindowData["characteristics"],h2kCodeElements)

   end


end

stream_out "\n\n"
stream_out drawRuler("Opt-H2KFoundation: definitions")
debug_on
parsedDefs["Opt-H2KFoundation"]["options"].each do | name, data |


  code1 = data["h2kMap"]["base"]["OPT-H2K-IntWallCode"]
  intR = data["h2kMap"]["base"]["OPT-H2K-IntWall-RValue"]
  extR = data["h2kMap"]["base"]["OPT-H2K-ExtWall-RVal"]
  undR = data["h2kMap"]["base"]["OPT-H2K-BelowSlab-RVal"]

  stream_out(" Foundation #{name}\n")
  stream_out("  - code: #{code1}\n")
  stream_out("  - intR: #{intR}\n")
  stream_out("  - extR: #{extR}\n")
  stream_out("  - undR: #{undR}\n")

  if ( code1.eql? "NA" ) then
    stream_out(" Foundation #{name}\n")
    stream_out("  - code: #{code1}\n")
    stream_out("  - intR: #{intR}\n")
    stream_out("  - extR: #{extR}\n")
    stream_out("  - undR: #{undR}\n")

    if ( intR.to_f > 0.1 ) then
      stream_out "    >searching for interior framing components\n"
      wallDefs.each do |wall, data|
       next if wall =~ /att\+/ 
       debug_out (" #{wall} -\n#{data.pretty_inspect}\n")
      end
    end

  end



end


# maybe create a copy for comparison?
# h2kCodeFile.gsub!(/\.cod/, "-ed.cod")
stream_out drawRuler("Outputting code file")
newXMLFile = File.open(h2kCodeFile, "w")
$formatter.write($XMLCodedoc,newXMLFile)
newXMLFile.close
