#!/usr/bin/env ruby
# ******************************************************************************
# substitute-h2k.rb
# Developed by Jeff Blake, CanmetENERGY-Ottawa, Natural Resources Canada
# Created Nov 2015
# Master maintained in GitHub
#
# This is a Ruby version of the substitute-h2k.pl script originally written by
# Alex Ferguson. This version is customized for HOT2000 runs. This script can be
# used stand-alone, with GenOpt or HTAP-PRM.rb for parametric runs or optimizations
# of HOT2000 inputs.
# ******************************************************************************


require 'rexml/document'
require 'optparse'
require 'timeout'
require 'fileutils'
#require 'digest'
require 'json'
require 'set'
require 'pp'



require_relative '../include/msgs'
require_relative '../include/markdown-reports.rb'
require_relative '../include/H2KUtils'
require_relative '../include/HTAPUtils'
require_relative '../include/constants'
#require_relative 'include/rulesets'
require_relative '../include/costing'
#require_relative 'include/legacy-code'
#require_relative 'include/application_modules'

include REXML
# This allows for no "REXML::" prefix to REXML methods


$program = "audit-costs.rb"
HTAPInit()

stream_out( drawRuler("A script for examining costs in HTAP output"))
stream_out(" \n \n")

$gTest_params["verbosity"] = "silent"

myHelp_msg = "no help available."

myRunNumbers = Array.new
myRunNumbersProvided = false

optparse = OptionParser.new do |opts|

  opts.banner = $help_msg

  opts.on("-h", "--help", "Show help message") do
    puts opts
    exit()
  end

  opts.on("-v", "--verbose", "Run verbosely") do
    $gTest_params["verbosity"] = "verbose"
  end

  opts.on("-r", "--results FILE", "Specified Results File (mandatory)") do |c|
    $resultsFile = c
      if ( !File.exist?($resultsFile) )
      fatalerror("Valid path to results file must be specified with --results (or -r) option!")
    end
  end

  opts.on("-c", "--costs FILE", "Specified Unit Costs Database (mandatory)") do |c|
    $costsFile = c
      if ( !File.exist?($resultsFile) )
      fatalerror("Valid path to results file must be specified with --results (or -r) option!")
    end
  end

  opts.on("-n", "--run-number #", "Specified Unit Costs Database (mandatory)") do |n|
    myRunNumbersProvided = true
    myRunNumbers.push n.to_i
  end

  opts.on("-w", "--warnings", "Report warning messages") do
    $gWarn = true
  end


end

if ARGV.empty? then
  puts myHelp_msg
  exit()
end

# Note: .parse! strips all arguments from ARGV and .parse does not
#       The parsing code above effects only those options that occur on the command line!
optparse.parse!


stream_out ("audit-costs.rb: \n")
stream_out ("  - ResultsFile: #{$resultsFile} \n \n")

stream_out (drawRuler("Parsing HTAP result file"))
parsedData = HTAPData.parse_results($resultsFile)
results = parsedData["htap-results"]
stream_out (" \n - #{$resultsFile} parsed.\n")

# Loop through each result, find unmodified home, by

baseCases = Array.new
allCases = Array.new

# Catagorize data in easy-to-handle arrays.

results.each do | result |
  debug_out " #{result["result-number"].to_s.ljust(3)} #{result["input"]["Opt-Location"].ljust(20)} #{result["input"]["Opt-Ruleset"].ljust(10)} #{result["archetype"]["h2k-File"][0..15]} #{result["input"]["House-Upgraded"]}\n"
end

results.each do | result |
  #debug_out ("RESULT:\n#{result.pretty_inspect}\n")
  thisCase = { "topology" => Hash.new, "archetype" => Hash.new, "input" => Hash.new, "costs"=> Hash.new }
  thisCase["id"] = result["result-number"]
  thisCase["report"] = if ( myRunNumbersProvided ) ; false else true end

  thisCase["topology"]["location"]  = result["input"]["Opt-Location"]
  thisCase["topology"]["archetype"] = result["archetype"]["h2k-File"]
  thisCase["topology"]["ruleset"] = result["input"]["Opt-Ruleset"]
  # These data are not yet dumped.
  #thisCase["topology"]["heating-fuel"] = result["input"]["ruleset-fuel-spec"]
  #thisCase["topology"]["vent-config"] = result["input"]["ruleset-vent-spec"]
  thisCase["topology"]["climate-zone"] = result["archetype"]["climate-zone"]
  thisCase["input"] = result["input"]
  thisCase["archeype"] = result["archetype"]
  thisCase["costs"] = result["cost-estimates"]
  thisCase["upgraded"] =result["input"]["House-Upgraded"]
  #thisCase["BCStepCodeTEDI"] = result["analysis_BCStepCode"]["TEDI_compliance"]
  allCases.push thisCase

  # Add to base case folder, if this is a base case
  if ( thisCase["input"]["House-Upgraded"] == "false" ) then
    baseCases.push thisCase
    debug_out " flag - BASE CASE: =#{thisCase["id"]} / #{thisCase["input"]["House-Upgraded"]}\n"

  end

end

# for each base case, add a reference to all cases that have same topologyTxt
# find associated base case, and add all_poly_lapped_joints_located_over_solid_backing
baseCases.each do | baseCase |
  debug_out drawRuler(nil,"._.")
  debug_out "Q> #{baseCase["id"]}:\n#{baseCase["topology"].pretty_inspect}\n"
  allCases.select {| someCase |
    someCase["topology"]   == baseCase["topology"]
  }.each do | upgradeCase |
    #debug_out " Setting upgrade case #{upgradeCase["id"]} bc reference to #{baseCase["id"]}\n"
    upgradeCase["baseCaseID"] = baseCase["id"]
    debug_out("-> upg: #{upgradeCase["id"]} - #{upgradeCase["input"]["House-ListOfUpgrades"]} \n")
  end
  debug_out ("#{baseCase["id"]} has BC #{baseCase["baseCaseID"]}?\n")
end




requestedRuns       = Array.new
associatedBaseCases = Array.new
#debug_on
if (myRunNumbersProvided) then
  allCases.select{ |someCase| myRunNumbers.include?(someCase["id"])}.each do | thisCase |
    thisCase["report"] = true
    debug_out "Requested output for ID \n#{thisCase["id"].pretty_inspect}\n"
  end
end


allCases.select{ |someCase| someCase["report"]}.each do | thisCase |
  requestedRuns.push thisCase["id"]
  debug_out ("check this case: #{thisCase["id"]} ->#{thisCase["baseCaseID"]} \n")

    debug_out "ERR: TOPOLOGY: #{thisCase["topology"].pretty_inspect}\n"


  if (! associatedBaseCases.include?(thisCase["baseCaseID"]))
    associatedBaseCases.push thisCase["baseCaseID"]
  end
end

stream_out (" - Total records:    #{allCases.length}\n")
stream_out (" - Total base cases: #{baseCases.length}\n")
stream_out (" - Number of records included in report: #{requestedRuns.length}\n")




stream_out (drawRuler("Compiling Audit Data"))
stream_out " \n"
#debug_on

reportTxt =""
reportTxt = MDRpts.newSection("HTAP batch run - Cost Audit Report", 1)

reportTxt += MDRpts.newParagraph("[TOC]")

reportTxt += MDRpts.newSection("Run Information", 2)
# more information should be added here.

tableData = Array.new
tableData = [
  [ "Total number of HOT2000 runs",
    "Total number of base cases",
    "Number of cases in report",
    "Number of asscoiated cases"
  ],[allCases.length.to_i,
    baseCases.length.to_i,
    requestedRuns.length.to_i,
    associatedBaseCases.length.to_i,
  ]
]

reportTxt += MDRpts.newTable(tableData)

reportTxt += MDRpts.newList([
  "List of reported cases: #{MDRpts.shortenArrList(requestedRuns)}",
  "List of base cases: #{MDRpts.shortenArrList(associatedBaseCases)}"
])

topologyTxt = ""
baseCaseCount = 0






associatedBaseCases.each do | id |
  baseCase = baseCases.select{ | someCase | someCase["id"] == id }[0]
  baseCaseCount += 1
  topologyTxt = ""
  debug_out "BASE CASE #{id}\n"
  debug_out "> this base case:\n#{baseCase.pretty_inspect}\n"

  reportTxt += MDRpts.newSection("Scenario ##{baseCaseCount}",2)

  reportTxt += MDRpts.newSection("Topology",3)

  tableData = {
    "Parameter" => Array.new,
    "Value"    => Array.new,
  }

  baseCase["topology"].each do | parameter, value |
    tableData["Parameter"].push parameter
    tableData["Value"].push value
  end

  reportTxt += MDRpts.newTable(tableData)



  archetypeAlias = baseCase["topology"]["archetype"]
  rulesetAlias = baseCase["topology"]["ruleset"]
  debug_out drawRuler("Base case ##{baseCaseCount}",". ")
  debug_out (" Base Case - #{topologyTxt}\n")

  summaryOfCosts = Costing.summarizeCosts(baseCase["input"],baseCase["costs"],"markdown")

  baseCaseAuditTxt = Costing.auditComponents(baseCase["input"],baseCase["costs"],baseCase["costs"]["costing-dimensions"], "markdown")


  #reportTxt += drawRuler(nil,"_",nil)
  #reportTxt += drawRuler("[#{baseCaseCount}] Base Case","-",nil)
  #reportTxt += " \n\n"

  reportTxt += MDRpts.newSection("House Characteristics",3)

  reportTxt += HTAPData.summarizeArchetype(baseCase["costs"]["costing-dimensions"],4)



  reportTxt += MDRpts.newSection("Base case for scenario ##{baseCaseCount}",3)
  reportTxt += MDRpts.newSection("Benchmark Costs: Summary ##{baseCaseCount}",4)
  reportTxt += MDRpts.newParagraph(
   "Benchmark costs reflect a baseline cost estimate when archetype _#{archetypeAlias}_ " +
   "is constructed to ruleset _#{rulesetAlias.gsub(/_/,"\\_")}_. This estimate does "+
   "not represent the cost to construct the home, or the costs of all energy-related"+
   "components. It merely represents the estimated costs of all measures that are in "+
   "HTAP's unit costs database, for housing components that are also described in the model."
   )
  reportTxt += MDRpts.newParagraph(
     "==NRCan cautions against referencing the benchmark estimates from a single run, as these "+
     "estimates may overlook elements that are assumed to be common to all scenarios (e.g. cladding)=="
  )

  reportTxt += "#{summaryOfCosts}\n"
  reportTxt += " \n\n"

  reportTxt += MDRpts.newSection("Benchmark Costs: detailed audit ##{baseCaseCount}",4)


  reportTxt += MDRpts.newSection("Upgrades for Scenario #{baseCaseCount}",3)
  upgradeIndex = 0
  scenarioCases = Array.new
  scenarioCases = allCases.select {|thisCase|
    thisCase["upgraded"] == "true" &&
    thisCase["topology"]["archetype"]    == baseCase["topology"]["archetype"]    &&
    thisCase["topology"]["location"]     == baseCase["topology"]["location"]     &&
    thisCase["topology"]["archetype"]    == baseCase["topology"]["archetype"]    &&
    thisCase["topology"]["ruleset"]      == baseCase["topology"]["ruleset"]      &&
    thisCase["topology"]["heating-fuel"] == baseCase["topology"]["heating-fuel"] &&
    thisCase["topology"]["vent-config"]  == baseCase["topology"]["vent-config"]  &&
    thisCase["topology"]["climate-zone"] == baseCase["topology"]["climate-zone"]
  }
  debug_out "(Found #{scenarioCases.length} cases)\n"

  #reportTxt += "Total number of upgrades processed:#{scenarioCases.length}\n "

  scenarioCases.each do | thisCase |

    upgradeIndex += 1
    debug_out "Scenario CASE: ? #{upgradeIndex} \n"
    reportTxt +=  MDRpts.newSection("Upgrade ##{upgradeIndex}",4)
    upgrades = thisCase["input"]["House-ListOfUpgrades"].split(/;/)

    reportTxt += MDRpts.newParagraph("Upgrades applied in this run:")

    tableData = {
      "Attribute"      => Array.new,
      "Base Choice"    => Array.new,
      "Upgrade Choice" => Array.new
     }

    scenarioCostImpacts = Hash.new
    upgradeChoices = Hash.new
    costComponentsDiff= Hash.new
    countOfUpgrades = 0
    upgrades.each do | upgrade |
      countOfUpgrades += 1

      debug_out "   case upgrades: ? #{countOfUpgrades}\n"

      attribute, choice = upgrade.split(/=>/)
      baseChoice = baseCase["input"][attribute]
      tableData["Attribute"].push attribute
      tableData["Base Choice"].push baseChoice
      tableData["Upgrade Choice"].push choice

      upgradeChoices[attribute] = choice

      debug_out ("   #{attribute}: #{baseChoice} -> #{choice} \n")

    end
    reportTxt += MDRpts.newTable(tableData)
    rreportTxt = " :()"

    reportTxt += MDRpts.newSection("Comparison to base case",4)

    reportTxt += MDRpts.newParagraph("Comparison between upgrade #{upgradeIndex} and base case #{baseCaseCount}:")

    softwrap = " ".ljust(200," ")
    costComponentsDiff= Hash.new
    upgrades.each do | upgrade |



      debug_out "Crash?\n"

      attribute, choice = upgrade.split(/=>/)


      next if ( baseCase["costs"]["byAttribute"][attribute].nil? || 
                thisCase["costs"]["byAttribute"][attribute].nil? )


      baseChoice = baseCase["input"][attribute]
      debug_out ("   #{attribute}: #{baseChoice} -> #{choice} \n")
      debug_out ("       >base> #{baseCase["costs"]["byAttribute"][attribute]}\n")
      debug_out ("       >upgr> #{thisCase["costs"]["byAttribute"][attribute]}\n")



      scenarioCostImpacts[attribute] = {
         "type" => "specified upgrade",
         "base" => baseCase["costs"]["byAttribute"][attribute] ,
         "upgrade" => thisCase["costs"]["byAttribute"][attribute] ,
         "net" => thisCase["costs"]["byAttribute"][attribute]  - baseCase["costs"]["byAttribute"][attribute]
      }
      reportTxt += MDRpts.newSection("Upgrade: #{attribute} -> #{choice}",6)

      costComponentsDiff["common"] = baseCase["costs"]["audit"][attribute]["elements"].select{ |component, data|
        thisCase["costs"]["audit"][attribute]["elements"].include?(component) &&
        thisCase["costs"]["audit"][attribute]["elements"][component]["component-costs"] == baseCase["costs"]["audit"][attribute]["elements"][component]["component-costs"]
      }


      costComponentsDiff["deleted"] = baseCase["costs"]["audit"][attribute]["elements"].select{ |component, data|
        ! thisCase["costs"]["audit"][attribute]["elements"].include?(component) ||
        thisCase["costs"]["audit"][attribute]["elements"][component]["component-costs"] != baseCase["costs"]["audit"][attribute]["elements"][component]["component-costs"]
      }

      costComponentsDiff["added"] = thisCase["costs"]["audit"][attribute]["elements"].select{ |component, data|
        ! baseCase["costs"]["audit"][attribute]["elements"].include?(component) ||
        thisCase["costs"]["audit"][attribute]["elements"][component]["component-costs"] != baseCase["costs"]["audit"][attribute]["elements"][component]["component-costs"]
      }

      reportTxt += " Change  |   Component    | Cost impact   \n"
      reportTxt += ":-----------|:---------------|----------------:\n"


      netCostChange = 0

      costComponentsDiff["added"].each do | component, data |
        quantity = data["quantity"]
        units =  data["measureDescription"].gsub(/-\.*$/, "")
        cost = data["component-costs"]
        netCostChange += cost
        if cost < 0
          oper = "-"
        else
          oper = "+"
        end
        reportTxt += " ==Added==  | #{component.gsub(/_/," ")} (#{quantity.round(1)} #{units})  |  #{oper}\\ $\\ #{'%.2f' % data["component-costs"].abs} \n"

      end


      costComponentsDiff["deleted"].each do | component, data |

        quantity = baseCase["costs"]["audit"][attribute]["elements"][component]["quantity"]
        units =  baseCase["costs"]["audit"][attribute]["elements"][component]["measureDescription"].gsub(/-\.*$/, "")
        cost = baseCase["costs"]["audit"][attribute]["elements"][component]["component-costs"]
        netCostChange -= cost
        if cost < 0
          oper = "+"
        else
          oper = "-"
        end
        reportTxt += " ==Deleted==  | #{component.gsub(/_/," ")} (#{quantity.round(1)} #{units}) | #{oper}\\ $\\ #{'%.2f' % data["component-costs"].abs} \n"

      end



      costComponentsDiff["common"].each do | component, data |
        quantity = data["quantity"]
        units =  data["measureDescription"].gsub(/-\.*$/, "")
        cost = data["component-costs"]
        if cost < 0
          oper = "+"
        else
          oper = "-"
        end
        rreportTxt += " *No Change* | *#{component.gsub(/_/," ")} #{softwrap} (#{quantity.round(1)} #{units})* | --- \n"

      end
      reportTxt += "   | **TOTAL** | **$\\ #{'%.2f' % netCostChange}** \n"


    end

    # Check if costs have changed for items that are not upgrades.

    thisCase["input"].each do | attribute, choice |
      if (
        thisCase["costs"]["byAttribute"][attribute] != baseCase["costs"]["byAttribute"][attribute] &&
        ! upgradeChoices.keys.include?(attribute)
      )then
        reportTxt += "###### Secondard cost impact: #{attribute} -> #{choice}\n"
        reportTxt += "NOTE: "
        reportTxt += "Specified upgrades have affected the costs of #{attribute} as well \n"

        scenarioCostImpacts[attribute] = {
           "type" => "secondary impact",
           "base" => baseCase["costs"]["byAttribute"][attribute] ,
           "upgrade" => thisCase["costs"]["byAttribute"][attribute] ,
           "net" =>thisCase["costs"]["byAttribute"][attribute]  - baseCase["costs"]["byAttribute"][attribute]
         }


        netCostChange = 0

        costComponentsDiff["common"] = baseCase["costs"]["audit"][attribute]["elements"].select{ |component, data|
          thisCase["costs"]["audit"][attribute]["elements"].include?(component) &&
          thisCase["costs"]["audit"][attribute]["elements"][component]["component-costs"] == baseCase["costs"]["audit"][attribute]["elements"][component]["component-costs"]
        }


        costComponentsDiff["deleted"] = baseCase["costs"]["audit"][attribute]["elements"].select{ |component, data|
          ! thisCase["costs"]["audit"][attribute]["elements"].include?(component) ||
          thisCase["costs"]["audit"][attribute]["elements"][component]["component-costs"] != baseCase["costs"]["audit"][attribute]["elements"][component]["component-costs"]
        }

        costComponentsDiff["added"] = thisCase["costs"]["audit"][attribute]["elements"].select{ |component, data|
          ! baseCase["costs"]["audit"][attribute]["elements"].include?(component) ||
          thisCase["costs"]["audit"][attribute]["elements"][component]["component-costs"] != baseCase["costs"]["audit"][attribute]["elements"][component]["component-costs"]
        }

        reportTxt += " Change  |   Component    | Cost impact   \n"
        reportTxt += ":-----------|:---------------|----------------:\n"

        costComponentsDiff["added"].each do | component, data |
          quantity = data["quantity"]
          units =  data["measureDescription"].gsub(/-\.*$/, "")
          cost = data["component-costs"]
          netCostChange += cost
          if cost < 0
            oper = "-"
          else
            oper = "+"
          end
          reportTxt += " ==Added==  | #{component.gsub(/_/," ")} (#{quantity.round(1)} #{units})  |  #{oper}\ $\\ #{'%.2f' % data["component-costs"].abs} \n"

        end


        costComponentsDiff["deleted"].each do | component, data |

          quantity = baseCase["costs"]["audit"][attribute]["elements"][component]["quantity"]
          units =  baseCase["costs"]["audit"][attribute]["elements"][component]["measureDescription"].gsub(/-\.*$/, "")
          cost = baseCase["costs"]["audit"][attribute]["elements"][component]["component-costs"]
          netCostChange -= cost
          if cost < 0
            oper = "+"
          else
            oper = "-"
          end
          reportTxt += " ==Deleted==  | #{component.gsub(/_/," ")} (#{quantity.round(1)} #{units}) | #{oper}\ $\\ #{'%.2f' % data["component-costs"].abs} \n"

        end



        costComponentsDiff["common"].each do | component, data |
          quantity = data["quantity"]
          units =  data["measureDescription"].gsub(/-\.*$/, "")
          cost = data["component-costs"]
          if cost < 0
            oper = "+"
          else
            oper = "-"
          end
          reportTxt += " *No Change* | *#{component.gsub(/_/," ")} #{softwrap} (#{quantity.round(1)} #{units})* | --- \n"

        end
        reportTxt += "   | **TOTAL** | **$\\ #{'%.2f' % netCostChange}** \n"









      end

    #  pp thisCase["costs"].keys
    #  debug_pause
#
    end

    reportTxt += "###### Summary of cost differences between the base and upgrade cases \n\n"
    reportTxt += " Type | Attribute | Base case  | Upgrade Case  | Net cost impact\n"
    reportTxt += ":-----------|:---------------|---------:|----------:|----------------:\n"
    netImpact = 0
    baseImpact = 0
    upgImpact = 0
    scenarioCostImpacts.select{ |a,b| b["type"] == "specified upgrade"}.each do |attribute, impact|
      netImpact += impact["net"]
      baseImpact += impact["base"]
      upgImpact += impact["upgrade"]
      reportTxt += " #{impact["type"]} | #{attribute}  | $\\ #{impact["base"].round(2)} | $\\ #{impact["upgrade"].round(2)} | $\\ #{impact["net"].round(2)} \n"
    end
    scenarioCostImpacts.select{ |a,b| b["type"] != "specified upgrade"}.each do |attribute, impact|
      netImpact += impact["net"]
      baseImpact += impact["base"]
      upgImpact += impact["upgrade"]
      reportTxt += " #{impact["type"]} | #{attribute}  | $\\ #{impact["base"].round(2)} | $\\ #{impact["upgrade"].round(2)} | $\\ #{impact["net"].round(2)} \n"
    end
    reportTxt += "  | **TOTAL**  | **$\\ #{baseImpact.round(2)}** | **$\\ #{upgImpact.round(2)}** | **$\\ #{netImpact.round(2)}** \n"
    reportTxt += " \n\n"



    reportTxt += "##### Benchmark costs for Upgrade #{upgradeIndex}\n"
    reportTxt += Costing.auditComponents(upgradeChoices,thisCase["costs"],thisCase["costs"]["costing-dimensions"], "markdown")

  end






  debug_out "(done with Base case ##{baseCaseCount})\n\n"
  #reportTxt += baseCaseAuditTxt
end



#debug_out "BASE CASES:\n#{baseCases.pretty_inspect}\n"
reportTxt.gsub!(/\$/,"\$")
reportTxt.gsub!(/ft\^2/,"ft^2^")
reportTxt.gsub!(/m\^2/,"m^2^")
reportTxt.gsub!(/sq\.ft\.?/,"ft^2^")
reportTxt.gsub!(/\\ /,"&nbsp;")
File.write("HTAP-batch-run-cost-audit.md", reportTxt)
ReportMsgs()
