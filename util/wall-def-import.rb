
require 'rexml/document'
require 'optparse'
require 'timeout'
require 'fileutils'
require 'digest'
require 'json'
require 'set'
require 'pp'

require 'csv'
require_relative '../inc/constants'
require_relative '../inc/msgs'
require_relative '../inc/H2KUtils'
require_relative '../inc/HTAPUtils'

require_relative '../inc/costing'
require_relative '../inc/legacy-code'

$program = "wall-def-import.rb"

stream_out drawRuler("A simple script that parses CWC wall definitions and syncs them with the options file")

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

  CWCdefsName = "wall-defs.txt"

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

  stream_out "Reading #{CWCdefsName}: line #{lineCount}\r"

  while !cwcDefs.eof? do

    lineCount += 1
    stream_out "Reading #{CWCdefsName}: line #{lineCount}\r"
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
          "rNom"    => rNom
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

    stream_out "Reading #{CWCdefsName}: line #{lineCount} done!\n"

    #pp wallDefs

    codeCount = 0
    wallDefsList.keys.each do | code |
      codeCount += 1
      stream_out " Building wall definitions for each code: #{codeCount} \r"
      thisCount    = wallDefsList[code]["Count"]
      thisRMax     = wallDefsList[code]["MaxReff"]
      thisRMin     = wallDefsList[code]["MinReff"]
      thisCavity   = wallDefsList[code]["cavity" ]
      thisFraming  = wallDefsList[code]["framing"]
      thisSpacing  = wallDefsList[code]["spacing"]
      thisExtIns   = wallDefsList[code]["extIns" ]
      thisVB       = wallDefsList[code]["vapourBarrier" ]
      thisRNomInt,  extInsReff   = wallDefsList[code]["rNom" ].split(/\+/)

      extInsReff = "0ci" if ( extInsReff.nil? )
      extInsReff.gsub!(/ci/,"")


      thisREffAvg = (thisRMax + thisRMin) / 2

      wall = "NC_R-#{thisREffAvg.to_f.round(0)}(eff)_#{code}"

      wallDefs[wall] = Hash.new
      wallDefs[wall] = {
        "h2kMap" => { "base" => {"Opt-H2K-EffRValue" => thisREffAvg.to_f.round(2),
                                 "HeaderExtInsRValue" => extInsReff.to_f
                    } },
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





    File.open("./wall-defs.json", 'w') do |file|
      file.puts JSON.pretty_generate(wallDefs)
      file.close
    end


    print "-------------------------------------------------\n"
    print " total definitions: #{totalDefs}\n"
    print "-------------------------------------------------\n"





  optionsFile = File.read("C:\\HTAP\\HTAP-options.json")
  optionsHash = JSON.parse(optionsFile)

  optionsHash["Opt-GenericWall_1Layer_definitions"]["options"].each do | wall,data|
    if ( wall =~ /^NBC/ ) then
      rEffReq = (wallRSIMin[wall]*5.68)
      print "#{wall} needs Reff #{rEffReq.round(2)}\n"

      found = false
      wallDefs.keys.each do |cwcWall|
        rEff = wallDefs[cwcWall]["h2kMap"]["base"]["Opt-H2K-EffRValue"]
        if ( ! found &&
            rEff > rEffReq &&
            cwcWall =~ /2x6-16inOC/ &&
            cwcWall !~ /Polyiso/    &&
            cwcWall !~ /SprayFoam/  ) then
           print "      #{cwcWall} complies (rEFF =#{rEff})\n"
           data["costs"]["proxy"] = cwcWall
           data["costs"].delete("components") if( !data["costs"]["components"].nil? )
           data["h2kMap"]["base"]["HeaderExtInsRValue"] = wallDefs[cwcWall]["h2kMap"]["base"]["HeaderExtInsRValue"]
           found = true

        end
      end

    end
  end


  countExport = 0
  wallDefs.keys.each do |wall|
    countExport += 1
    puts " Reff: #{wallDefs[wall]["h2kMap"]["base"]["Opt-H2K-EffRValue"]}  - #{wall} \n"
    optionsHash["Opt-GenericWall_1Layer_definitions"]["options"][wall] = Hash.new
    optionsHash["Opt-GenericWall_1Layer_definitions"]["options"][wall] = wallDefs[wall]
  end




  print "-------------------------------------------------\n"
  print " exporting  #{countExport} walls \n"
  print "-------------------------------------------------\n"

  wallOutput  = File.open("HTAP-options-draft.json", 'w')
  wallOutput.write(JSON.pretty_generate(optionsHash))
  wallOutput.close
