#


# Data from Hanscom b 2011 NBC analysis
$RegionalCostFactors = Hash.new
$RegionalCostFactors  = {  "Halifax"      =>  0.95 ,
  "Edmonton"     =>  1.12 ,
  "Calgary"      =>  1.12 ,  # Assume same as Edmonton?
  "Ottawa"       =>  1.00 ,
  "Toronto"      =>  1.00 ,
  "Quebec"       =>  1.00 ,  # Assume same as Montreal?
  "Montreal"     =>  1.00 ,
  "Vancouver"    =>  1.10 ,
  "PrinceGeorge" =>  1.10 ,
  "Kamloops"     =>  1.10 ,
  "Regina"       =>  1.08 ,  # Same as Winnipeg?
  "Winnipeg"     =>  1.08 ,
  "Fredricton"   =>  1.00 ,  # Same as Quebec?
  "Whitehorse"   =>  1.00 ,
  "Yellowknife"  =>  1.38 ,
  "Inuvik"       =>  1.38 ,
  "Alert"        =>  1.38
}




module Costing


  def Costing.parseUnitCosts(unitCostFileName)

    debug_off

    unitCostDataHash = Hash.new

    unitCostFile = File.read(unitCostFileName)

    unitCostDataHash = JSON.parse(unitCostFile)

    return unitCostDataHash

  end




  def Costing.getCostComponentList(myOptions,myChoices,attribute,choice)

    debug_off if CostingSupport.include? attribute
    #debug_on if ( attribute =~ /DHW/ )
    componentList = Array.new

    debug_out " recovering cost component list for  #{attribute} = #{choice} \n"
    debug_out " contents of options at #{attribute}/#{choice}:#{myOptions[attribute]["options"][choice].pretty_inspect}\n"
    if ( ! myOptions[attribute]["options"][choice]["costProxy"].nil? ) then

      proxyChoice = myOptions[attribute]["options"][choice]["costProxy"]

      debug_out " following proxy reference #{choice}->#{proxyChoice}"
      # Should test to see if a component exists!

      if ( ! HTAPData.isChoiceValid(myOptions, attribute, proxyChoice) ) then
        warn_out ("Cannot cost #{attribute}->#{choice}; specified proxy '#{proxyChoice} doesn't exist.")

      end

      componentList = getCostComponentList(myOptions,myChoices,attribute,proxyChoice)

    elsif ( ! myOptions[attribute]["options"][choice]["costComponents"].nil? )

      componentList = myOptions[attribute]["options"][choice]["costComponents"]

    end

    return componentList

  end

  def Costing.solveComponentConditionals(myOptions,myChoices,attribute,component)
    debug_off
    if ( component.is_a?(String) ) then
      debug_out "retuning string  #{component}"
      return component
    elsif ( component.is_a?(Hash) ) then

      # Conditionals are defined as hashes
      #              { "if[Opt-HVAC.inc?]": {
      #                  "ducting:central_forced_air": "ducting:connect_ventilator_to_central_forced_air",
      #                  "else": "ducting:direct-duct_hrv"
      #                }
      #             }
      #Attempt to process conditional
      if ( component.keys[0] =~/if\[/ )
        testVar = "#{component.keys[0]}"
        testVar.gsub!(/if\[(.+)\]/, "\\1")
          myVar = testVar.split(/\./)[0]
          myTest = testVar.split(/\./)[1]

          # Types of conditionals we support:
          #    VAR.inc? - does VAR's current costing elements include a given component?
          #  ...

          case myTest
          when "inc?"
            debug_out "          Processing include conditional on #{myVar}\n"

            remoteChoice = myChoices[myVar]

            debug_out "          Processing include conditional on #{myVar}->#{remoteChoice}\n"
            remoteCostList = Costing.getCostComponentList(myOptions,myChoices,myVar,remoteChoice)

            # Get the components associated with myVar's final value

            countConditionals = 0
            component.each do | testType, map |
              countConditionals +=1
              if ( countConditionals > 1 )
                choice = myChoices[attribute]
                warn_out " #{attribute}/#{choice}: only one conditional statement permitted"
              else
                found = false
                map.each do | search, result |
                  debug_out "     ? does #{myVar} include unit cost #{search} ?\n"

                  if ( search == "else" || search == "ELSE"  )
                    return result
                    found = true
                  else
                    remoteCostList.each do | remoteComponent |
                       resolvedComponent = Costing.solveComponentConditionals(myOptions,myChoices,myVar,remoteComponent)
                       return result if ( search == resolvedComponent )
                    end
                  end

                  break if found

                end
              end
            end

          when "some other conditional syntax"

          else
            warn_out " #{attrib}/#{choice}: unknown conditional syntax for cost component"
          end

        end

      end

  end

  # THE options file may contain nested cost references
  # with conditionals and proxy cost statements.
  # This function untangles these references and returns
  # a cleaner Optiona array specifiying component costs.
  def Costing.resolveCostingLogic(myOptions,myChoices)

    debug_off

    mySimplerCostTree = Hash.new


    myOptions.each do | attribute, contents |
      debug_off
      #debug_on if CostingSupport.include? attribute
      debug_out drawRuler("Resolving costing logic for #{attribute}", ". ")



      mySimplerCostTree[attribute] = { "options" => Hash.new }

      contents["options"].each do | option, optionContents |
        debug_out " Option = #{option}\n"

        mySimplerCostTree[attribute]["options"][option] = Hash.new

        rawCostList = Array.new
        rawCostList = Costing.getCostComponentList(myOptions,myChoices,attribute,option)

        componentCostList = Array.new
        # elements inside component Cost list can be a hash, indicating embedded comditional logic
        rawCostList.each do | component |

          resolvedComponent = Costing.solveComponentConditionals(myOptions,myChoices,attribute,component)
          componentCostList.push resolvedComponent

        end
        mySimplerCostTree[attribute]["options"][option]["costComponents"]= componentCostList
      end



    end

    return mySimplerCostTree
  end

  def Costing.getCosts(myUnitCosts,myOptions,attrib,choice,useTheseSources)

    debug_off
    debug_off if ( choice != "NA" )

    debug_out(" [>] Costing.getCosts: searching cost data for #{attrib} = #{choice}\n")

    myCosts = Hash.new
    found = false
    customDone = false
    done = false

    source = ""

    # Return zero cost for choice = NA (assume we don't know what that is)
    if ( choice.eql? "NA" ) then

      myCosts["NA"] = Hash.new
      myCosts["NA"] = {
        "found"    => true,
        "data"     => Hash.new ,
        "inherited"=> false
      }
      myCosts["NA"]["data"] = {
        "source" => "default",
        "catagory" => "NA",
        "units"  => "ea",
        "UnitCostsMaterials" => 0.0 ,
        "UnitCostsLabour" =>    0.0
      }
      return myCosts
    end

    # USE done as loop control -
    sourceIndex = 0
    # - CUSTOM COSTS>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # First - start with custom costs - THis doesn't actually work at present
    debug_out ( "  .  Searching for custom cost data\n")
    while ( ! customDone ) do
      # Get next valid cost source
      validSource = useTheseSources[sourceIndex]
      debug_out ("  .  Looking for custom cost scenarios matching #{validSource}... \n")
      # If custom costs didn't match, use component-by-component costs

      sourceIndex = sourceIndex + 1
      if ( sourceIndex == useTheseSources.length ) then
        customDone = true
      end
      # If we find a custom match, set componentDone to true and skip that section.
    end # while ( ! customDone ) do

    # - COMPONENT COSTS>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # Now get costs from components.

    # First, determine if a proxy unit has been specified.


    if ( ! done ) then

      debug_out ( " [x] No custom costs matched. Searching for component-by-component costs.\n")

      # loop through the cost-components that are associated with
      # this option (in myOptions), and attempt to match myUnitCosts data
      # with requested data source (in useTheseSources )
      proxy_cost = false
      if ( ! myOptions[attrib]["options"][choice]["costProxy"].nil? )

        proxy_cost = true
        proxy_choice = myOptions[attrib]["options"][choice]["costProxy"]

        debug_out "   Proxy cost specified. Will attempt to use cost data for #{proxy_choice} ...\n"
        myCosts = Costing.getCosts(myUnitCosts,myOptions,attrib,proxy_choice,useTheseSources)
        return myCosts
      end

      myOptions[attrib]["options"][choice]["costComponents"].each do | component |

        debug_out " . . . . . . . . . . . . . . . . . . . . . . . .  . . . . . . . . . . . .  \n"
        debug_out " [#] working with #{component}\n"

        # Cost data sets can inherit data from prior dbs.
        # Set default inheratence flag to zero.
        inherited = false

        # Define myCosts as a hash with cost component as key; initialize 'found'
        # attribut to false.
        myCosts[component] = Hash.new
        myCosts[component]["found"] = false

        useTheseSources.each do | specdSource |

          debug_out "  .  Source #{specdSource} was requested, does it exist in db?"
          nomatch = false
          if ( ! myUnitCosts["sources"].keys.include? specdSource ) &&
            ( ! specdSource.eql? "*" ) then
            debug_out " no. (moving on) \n"
            nomatch = true
          end

          next if nomatch

          # Either there is a match, or
          if ( specdSource.eql? "*" ) then
            # case 1: wild car.
            debug_out " It's a wild card - use any record! \n"
            # Wildcard - find any matching record
            if ( ! myUnitCosts["data"].keys.include? component ) then
              fatalerror "Could not find #{component} in unit cost data!"
            end
            source = myUnitCosts["data"][component].keys.sort[0]

          else

            debug_out " yes! \n"

            source = specdSource
            debug_out "  .  checking for inheratence:\n"
            # Loop through all of the acestors
            myUnitCosts["sources"][specdSource]["inherits"].keys.each do | ancestor |

              debug_out "  .   ?  was component inherited from #{ancestor}?"

              # Check to see if the comonent cost was inherited from this ancestor.
              if ( ! myUnitCosts["sources"][specdSource]["inherits"][ancestor].include? component ) then
                debug_out " no.\n"
              else
                debug_out " YES!\n"
                debug_out ("  .  [!] Inheritance detected! validSource data originates from #{ancestor}\n")
                source = ancestor
                inherited = true
              end

              break if inherited

            end # myUnitCosts["sources"][specdSource]["inherits"].keys.each do | ancestor |

          end

          # find the component in myUnitCosts, and determine if it has cost
          # data that matches our source (specd || ancestor if inherited = true || arbitrary source for wildcard. )
          debug_out ("  .  proceeding to process component cost using data from #{source}  \n")
          debug_out ("    >#{component}<\n")

          myUnitCosts["data"][component].keys.each do | costset |
            debug_out "  .   .  found unit cost data from `#{costset}`"
            if ( ! source.eql? costset) && ( ! source.eql? "*" ) then
              debug_out " but that's not the one we need.\n"
            else
              debug_out " AND that's the one we need!\n"
              debug_out " [+] Setting myCost data using data from #{costset}.\n"
              myCosts[component]["found"] = true
              myCosts[component]["data"] = Hash.new
              myCosts[component]["data"] = myUnitCosts["data"][component][source]
              myCosts[component]["inherited"] = inherited
              if (inherited) then
                myCosts[component]["specified_source"] = specdSource
                myCosts[component]["inherited_from"] = source
              end
            end
            #
          end # myUnitCosts["data"][component].keys.each do | costset |

          break if myCosts[component]["found"]

        end # useTheseSources.each do | specdSource |

      end # myOptions[attrib]["options"][choice]["costComponents"].each do | component |

    end

    debug_out(" [<] Costing.getCosts: returning \n")
    return myCosts
  end




  def Costing.computeCosts(mySpecdSrc,myUnitCosts,myOptions,myChoices,myH2KHouseInfo)
    debug_off
    costSourcesDBs = Array.new
    costSourcesCustom = Array.new

    costSourcesCustom    = mySpecdSrc["custom"]
    costSourcesDBs       = mySpecdSrc["components"]

    myCosts = Hash.new
    myCosts["total"] = 0
    myCosts["byAttribute"] = Hash.new
    myCosts["bySource"] = Hash.new
    debug_out drawRuler(" Costing calculations ",'.')
    debug_out ("Choices to be costed:\n#{myChoices.pretty_inspect}\n")


    debug_out "  Untangling costing logic via  Costing.resolveCostingLogic(myOptions,myChoices)\n"

    simpleCostTree = Costing.resolveCostingLogic(myOptions,myChoices)


    myChoices.each do | attrib, choice |
      debug_off()
      if ( CostingSupport.include? attrib )  then
        #debug_off()  if (choice != "NA" )
      end

      debug_out " #{attrib} = #{choice}\n"
      debug_out (" + Does cost data exist for #{attrib}? ")
      myCosts["byAttribute"][attrib] = 0
      componentCostsSummary = Hash.new
      # Check to see if costing is supported for this attribute

      if ( ! CostingSupport.include? attrib )  then
        debug_out (" no.\n")

      elsif ( choice == "NA" )
        debug_out ("yes, but choice is 'NA'.\n")
        myCosts["byAttribute"][attrib] += 0.0
      else
        debug_out (" Yes!\n")
        debug_out (" Calling Costing.GetCosts to recover unit costs for #{attrib} = #{choice}\n")

        choiceCosts = Hash.new
        choiceCosts = Costing.getCosts(myUnitCosts,simpleCostTree,attrib,choice,costSourcesDBs)
        #debug_out(" Costs recovered from Costing.GetCosts:\n#{choiceCosts.pretty_inspect}\n")

        costsOK = true
        choiceCosts.keys.each do | costingElement |

          debug_out " Computing costs for #{attrib}=#{choice}, \n+-> component [#{costingElement}]\n"

          catagory = choiceCosts[costingElement]["data"]["category"]
          debug_out "       from catagory: #{catagory} \n"

          units = choiceCosts[costingElement]["data"]["units"]
          materials = choiceCosts[costingElement]["data"]["UnitCostMaterials"].to_f
          labour  = choiceCosts[costingElement]["data"]["UnitCostLabour"].to_f
          source = choiceCosts[costingElement]["data"]["source"]

          measure = 0.0

          debug_out "  Recovering measure for #{attrib}/#{choice}/#{costingElement}\n"
          case attrib
          # .....................................................................
          when "Opt-ACH"
            if ( units == "sf wall" || units == "sf wall (net)" )
              measure =  ( myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["net"] ) * SF_PER_SM
            elsif ( units == "sf wall area (gross)" )
              measure =  ( myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["gross"] ) * SF_PER_SM
            elsif ( units == "sf attic" )
              measure = myH2KHouseInfo["dimensions"]["ceilings"]["area"]["attic"] * SF_PER_SM
            else
              costsOK = false
            end
          # ........................................................................
          when "Opt-AtticCeilings"

            if ( units == "sf attic" )
              measure = myH2KHouseInfo["dimensions"]["ceilings"]["area"]["attic"] * SF_PER_SM
            else
              costsOK = false
            end

          # ........................................................................
          when "Opt-GenericWall_1Layer_definitions"

            if ( units == "sf wall" || units == "sf wall (net)" || units == "sf applied" )
              measure =  ( myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["net"] ) * SF_PER_SM

            elsif ( units == "sf wall area (gross)" )
              measure =  ( myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["gross"] ) * SF_PER_SM

            elsif ( units == "sf attic" )
              measure = myH2KHouseInfo["dimensions"]["ceilings"]["area"]["attic"] * SF_PER_SM

            else
              costsOK = false
            end

          # ........................................................................
          when "Opt-CasementWindows"

            if ( units == "sf applied" &&  catagory == "WINDOWS" )

               measure = myH2KHouseInfo["dimensions"]["windows"]["area"]["total"] * SF_PER_SM

            else

               costsOK = false

            end

          # ........................................................................

          when "Opt-FoundationWallExtIns"

              if ( units == "sf applied" || units == "sf wall")

                 measure = myH2KHouseInfo["dimensions"]["below-grade"]["walls"]["total-area"]["external"] * SF_PER_SM


              else

                 costsOK = false

              end
            # ..................................................................
            when "Opt-FoundationWallIntIns"

                if ( units == "sf applied" || units == "sf wall")

                   measure = myH2KHouseInfo["dimensions"]["below-grade"]["walls"]["total-area"]["internal"] * SF_PER_SM


                else

                   costsOK = false

                end


            # ..................................................................
            when "Opt-FoundationSlabBelowGrade"

                if ( units == "sf applied" )

                   measure = ( myH2KHouseInfo["dimensions"]["below-grade"]["basement"]["floor-area"]  +
                               myH2KHouseInfo["dimensions"]["below-grade"]["crawlspace"]["floor-area"] ) * SF_PER_SM

                else

                   costsOK = false

                end

                # ..................................................................
              when "Opt-FoundationSlabOnGrade"

                    if ( units == "sf applied" )

                       measure = ( myH2KHouseInfo["dimensions"]["below-grade"]["crawlspace"]["floor-area"] ) * SF_PER_SM

                    else

                       costsOK = false

                    end
            # ..................................................................
            when "Opt-DHWSystem"

                  if ( units == "ea" )

                     measure = 1.0

                  else

                     costsOK = false

                  end

           # ..................................................................
           when "Opt-HVACSystem"

                if ( units == "ea" )

                   measure = 1.0

                elsif ( units == "sf heated floor area")
                   measure =  ( myH2KHouseInfo["dimensions"]["heatedFloorArea"] ) * SF_PER_SM

                 elsif ( units == "kW capacity" )

                     if ( catagory == "ELECTRIC RESISTANCE BASEBOARDS" ) then
                       if ( myH2KHouseInfo["HVAC"]["Baseboards"]["count"].to_i == 0  ) then
                         warn_out "H2K file doesn't contain any baseboards. Can't cost #{costingElement}\n"
                       end
                       measure = myH2KHouseInfo["HVAC"]["Baseboards"]["capacity_kW"].to_f * 1.1

                     elsif ( catagory == "AIR CONDITIONING" ) then
                       if ( myH2KHouseInfo["HVAC"]["AirConditioner"]["count"].to_i == 0  ) then
                         warn_out "H2K file doesn't contain any air conditioners. Can't cost #{costingElement}\n"
                       end

                       measure = myH2KHouseInfo["HVAC"]["AirConditioner"]["capacity_kW"].to_f * 1.1

                     else
                        warn_out "Unknown Catagory #{catagory} for #{costingElement}"
                     end

                else

                   costsOK = false

                end
          # ..................................................................
          when "Opt-HRVonly"

            if ( units == "ea" )

               measure = 1.0

             elsif ( units == "l/s capacity")
               if ( catagory == "HRV" ) then
                 measure = myH2KHouseInfo["HVAC"]["Ventilator"]["capacity_l/s"].to_f
               end

             else

                costsOK = false

             end

          else
            debug_out( "Attribute #{attrib} - no costing rules a\n")
            measure = 1.0
            costsOK = false
          end




          debug_out ("   Source    :   #{source}\n")
          debug_out ("   Units     :   #{units}\n")
          debug_out ("   Measure   :   #{measure} (#{units})\n")
          debug_out ("   Materials : $ #{materials.round(2)} / #{units}\n")
          debug_out ("   Labour    : $ #{labour.round(2)} / #{units}\n")

          # ===============================================================
          # Compute costs :
          myCostsComponent = measure * ( materials + labour )

          myCosts["total"] += myCostsComponent.round(2)

          myCosts["byAttribute"][attrib] += myCostsComponent.round(2)

          if ( myCosts["bySource"][source].nil?  ) then
            myCosts["bySource"][source] = 0.0
          end
          myCosts["bySource"][source] +=  myCostsComponent.round(2)


          debug_out ("   Cost      : $ #{myCostsComponent.round(2)}\n")
          componentCostsSummary[costingElement] = myCostsComponent.round(2)

          if ( ! costsOK )
            warn_out ("Can't cost #{attrib}/#{choice}/#{costingElement}")
            debug_out( "Unknown unit of measure for #{attrib}/#{choice}/#{costingElement}!\n")
            warn_out ("Unknown units: \"#{units}\" for #{costingElement}")
            debug_out("available measures\n#{myH2KHouseInfo.pretty_inspect}\n")
            exit
          end

        end

        debug_out "   ...............................................................\n"
        debug_out "   EST COST IMPACT:\n"
        debug_out "     #{attrib} => #{choice} ?   \n"
        debug_out "\n"
        componentCostsSummary.keys.each do |thiscomponent|
          thiscost = '%.2f' % componentCostsSummary[thiscomponent].to_f.round(2)
          debug_out "      $ #{thiscost.rjust(10)} : #{thiscomponent}\n"
        end
        debug_out "      _____________\n"
        total = '%.2f' % myCosts["byAttribute"][attrib].round(2)
        debug_out "      $ #{total.rjust(10)} : TOTAL \n"

      end

    end
    #debug_out "Compute-Costs: Returning \n#{myCosts.pretty_inspect}\n"
    return myCosts

  end # def compute costs

  # Draw a table summarizing the costs
  def Costing.summarizeCosts(myChoices,myCosts)

    myCosts["byAttribute"].each do | attribute , cost |
      #attList = " #{attribute.ljust(30)} = #{myChoices["attribute"].ljust(30)}"
      next if ( cost.to_f < 0.1 )
      costtxt = '%.2f' % cost.to_f
      stream_out " #{attribute.ljust(40)} = #{myChoices[attribute].ljust(40)} --> $ #{costtxt.rjust(9)}\n"
    end
    myTotal = '%.2f' % myCosts["total"].to_f
    stream_out " ...................................................................................................\n"
    stream_out " #{"TOTAL".ljust(40)}   #{" ".ljust(40)}     $ #{myTotal.rjust(9)}\n"

  end


end
