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
    $resultsFile = c
      if ( !File.exist?($resultsFile) )
      fatalerror("Valid path to results file must be specified with --results (or -r) option!")
    end
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
results = HTAPData.parse_results($resultsFile)
stream_out (" \n - #{$resultsFile} parsed.\n")

# Loop through each result, find unmodified home, by

baseCases = Array.new
allCases = Array.new

# Catagorize data in easy-to-handle arrays.

results.each do | result |

  thisCase = { "topology" => Hash.new, "archetype" => Hash.new, "input" => Hash.new, "costs"=> Hash.new }
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
  if ( result["input"]["House-Upgraded"] == "false" ) then
    baseCases.push thisCase
  end

end

stream_out (" - Total records:    #{allCases.length}\n")
stream_out (" - Total base cases: #{baseCases.length}\n")


stream_out (drawRuler("Compiling Audit Data"))
stream_out " \n"
debug_on
reportTxt = "# HTAP batch run - Cost Audit Report {-}\n"
#reportTxt += "\n[TOC]\n"
topologyTxt = ""
baseCaseCount = 0

baseCases.each do | baseCase |
  baseCaseCount += 1
  topologyTxt = ""

  reportTxt += "## Scenario ##{baseCaseCount}\n"

  topologyTxt += "### Topology: \n"
  #topologyTxt += "|#{"-".ljust(30,"-")}|#{"-".ljust(30,"-")}|\n"
  topologyTxt += "| #{"Parameter".ljust(29)}| #{"Value".ljust(29)}|\n"
  topologyTxt += "|#{"-".ljust(30,"-")}|#{"-".ljust(30,"-")}|\n"
  baseCase["topology"].each do | parameter, value |
    topologyTxt += "| #{parameter.ljust(29)}| #{value.ljust(29)}|\n"
  end

  archetypeAlias = baseCase["topology"]["archetype"]
  rulesetAlias = baseCase["topology"]["ruleset"]
  debug_out drawRuler("Base case ##{baseCaseCount}",". ")
  debug_out (" Base Case - #{topologyTxt}\n")

  summaryOfCosts = Costing.summarizeCosts(baseCase["input"],baseCase["costs"],"markdown")
  baseCaseAuditTxt = Costing.auditComponents(baseCase["input"],baseCase["costs"],baseCase["costs"]["costing-dimensions"], "markdown")
  archetypeSummaryTxt = HTAPData.summarizeArchetype(baseCase["costs"]["costing-dimensions"],false)

  #reportTxt += drawRuler(nil,"_",nil)
  #reportTxt += drawRuler("[#{baseCaseCount}] Base Case","-",nil)
  #reportTxt += " \n\n"
  reportTxt += topologyTxt
  reportTxt += " \n\n"
  reportTxt += " ### House Characteristics:\n\n"
  reportTxt += archetypeSummaryTxt
  #reportTxt += " \n\n"
  reportTxt += "### Base Case for Secenario ##{baseCaseCount} \n\n"
  reportTxt += "#### Benchmark costs - summary:\n\n"
  reportTxt += "Benchmark costs reflect a baseline cost estimate when archetype _#{archetypeAlias}_ "
  reportTxt += "is constructed to ruleset _#{rulesetAlias.gsub(/_/,"\\_")}_. This estimate does "
  reportTxt += "not represent the cost to construct the home, or the costs of all energy-related"
  reportTxt += "components. It merely represents the estimated costs of all measures that are in "
  reportTxt += "HTAP's unit costs database, for housing components that are also described in the model."
  reportTxt += "\n\n"
  reportTxt += "==NRCan cautions against referencing the benchmark estimates from a single run, as these "
  reportTxt += "estimates may overlook elements that are assumed to be common to all scenarios (e.g. cladding)=="
  reportTxt += " \n\n"
  reportTxt += "#{summaryOfCosts}\n"
  reportTxt += " \n\n"
  reportTxt += "#### Benchmark costs - detailed audit:\n\n#{baseCaseAuditTxt}\n\n"


  reportTxt += "### Upgrades for Scenario #{baseCaseCount}\n"
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

  reportTxt += "Total number of upgrades processed:#{scenarioCases.length}\n "

  scenarioCases.each do | thisCase |
    upgradeIndex += 1
    reportTxt += "#### Upgrade ##{upgradeIndex}\n"
    upgrades = thisCase["input"]["House-ListOfUpgrades"].split(/;/)

    reportTxt += "Upgrades applied in this run:\n\n"
    reportTxt += "Attribute   |   Base Choice  | Upgrade Choice    \n"
    reportTxt += ":-----------|:---------------|:-------------\n"
    scenarioCostImpacts = Hash.new
    upgradeChoices = Hash.new
    costComponentsDiff= Hash.new
    upgrades.each do | upgrade |

      attribute, choice = upgrade.split(/=>/)
      baseChoice = baseCase["input"][attribute]
      reportTxt += "#{attribute} | #{baseChoice} | #{choice}  \n"
      upgradeChoices[attribute] = choice
      debug_out "UPGRADE: #{attribute} | #{baseChoice} | #{choice}  \n"

    end
    reportTxt +="\n\n"

    reportTxt += "##### Comparison to base case \n"

    reportTxt += "Comparison between upgrade #{upgradeIndex} and base case #{baseCaseCount}: \n\n"

    softwrap = " ".ljust(200," ")
    costComponentsDiff= Hash.new
    upgrades.each do | upgrade |

      attribute, choice = upgrade.split(/=>/)
      scenarioCostImpacts[attribute] = {
         "type" => "specified upgrade",
         "base" => baseCase["costs"]["byAttribute"][attribute] ,
         "upgrade" => thisCase["costs"]["byAttribute"][attribute] ,
         "net" =>thisCase["costs"]["byAttribute"][attribute]  - baseCase["costs"]["byAttribute"][attribute]
       }
      reportTxt += "###### Upgrade: #{attribute} -> #{choice}\n\n"

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
        reportTxt += " ==Added==  | #{component.gsub(/_/," ")} (#{quantity.round(1)} #{units})  |  #{oper}\ $\ #{'%.2f' % data["component-costs"].abs} \n"

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
        reportTxt += " ==Deleted==  | #{component.gsub(/_/," ")} (#{quantity.round(1)} #{units}) | #{oper}\ $\ #{'%.2f' % data["component-costs"].abs} \n"

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
      reportTxt += "   | **TOTAL** | **$\ #{'%.2f' % netCostChange}** \n"


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
          reportTxt += " ==Added==  | #{component.gsub(/_/," ")} (#{quantity.round(1)} #{units})  |  #{oper}\ $\ #{'%.2f' % data["component-costs"].abs} \n"

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
          reportTxt += " ==Deleted==  | #{component.gsub(/_/," ")} (#{quantity.round(1)} #{units}) | #{oper}\ $\ #{'%.2f' % data["component-costs"].abs} \n"

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
        reportTxt += "   | **TOTAL** | **$\ #{'%.2f' % netCostChange}** \n"









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
      reportTxt += " #{impact["type"]} | #{attribute}  | $\ #{impact["base"].round(2)} | $\ #{impact["upgrade"].round(2)} | $\ #{impact["net"].round(2)} \n"
    end
    scenarioCostImpacts.select{ |a,b| b["type"] != "specified upgrade"}.each do |attribute, impact|
      netImpact += impact["net"]
      baseImpact += impact["base"]
      upgImpact += impact["upgrade"]
      reportTxt += " #{impact["type"]} | #{attribute}  | $\ #{impact["base"].round(2)} | $\ #{impact["upgrade"].round(2)} | $\ #{impact["net"].round(2)} \n"
    end
  reportTxt += "  | **TOTAL**  | **$\ #{baseImpact.round(2)}** | **$\ #{upgImpact.round(2)}** | **$\ #{netImpact.round(2)}** \n"
    reportTxt += " \n\n"



    reportTxt += "##### Benchmark costs for Upgrade #{upgradeIndex}\n"
    reportTxt += Costing.auditComponents(upgradeChoices,thisCase["costs"],thisCase["costs"]["costing-dimensions"], "markdown")

  end






  debug_out "(done with Base case ##{baseCaseCount})\n\n"
  #reportTxt += baseCaseAuditTxt
end



#debug_out "BASE CASES:\n#{baseCases.pretty_inspect}\n"

reportTxt.gsub!(/ft\^2/,"ft^2^")
reportTxt.gsub!(/m\^2/,"m^2^")
reportTxt.gsub!(/sq\.ft\.?/,"ft^2^")
File.write("HTAP-batch-run-cost-audit.md", reportTxt)
ReportMsgs()
