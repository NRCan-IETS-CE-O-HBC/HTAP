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

  # Function to read unit cost info - i.e. HTAPUnitCosts.json
  def Costing.parseUnitCosts(unitCostFileName)

    debug_off

    unitCostDataHash = Hash.new

    unitCostFile = File.read(unitCostFileName)

    unitCostDataHash = JSON.parse(unitCostFile)

    return unitCostDataHash

  end



  # For a given attribute->choice: Recover the costs/components list.
  # That may include 'proxy' references, in which a code spec
  # is costed using an actual system with equal or nearly-equal
  # thermal performance. Call this funciton recursively if necessary.
  def Costing.getCostComponentList(myOptions,myChoices,attribute,choice)

    #debug_off
    #debug_on if ( attribute =~ /HVAC/ )
    componentList = Array.new
    finalChoice = ""
    debug_out " recovering cost component list for  #{attribute} = #{choice} \n"
    debug_out " contents of options at #{attribute}/#{choice}:#{myOptions[attribute]["options"][choice].pretty_inspect}\n"

    # Get proxy
    if ( ! myOptions[attribute]["options"][choice]["costProxy"].nil? ) then

      proxyChoice = myOptions[attribute]["options"][choice]["costProxy"]

      debug_out " following proxy reference #{choice}->#{proxyChoice}"
      # Should test to see if a component exists!

      if ( ! HTAPData.isChoiceValid(myOptions, attribute, proxyChoice) ) then
        warn_out ("Cannot cost #{attribute}->#{choice}; specified proxy '#{proxyChoice} doesn't exist.")
      end
      # Recursively call funciton to follow proxy. Tested this on 2x nested
      # references; don't know what happens beyond that.
      componentList, finalChoice = getCostComponentList(myOptions,myChoices,attribute,proxyChoice)

    elsif ( ! myOptions[attribute]["options"][choice]["costComponents"].nil? )

      componentList = myOptions[attribute]["options"][choice]["costComponents"]
      finalChoice = choice
    end

    return componentList, finalChoice

  end

  # Functon that can deal with conditional costing statements -
  # such as hrv ducting costs that change if central forced air is available or not.
  def Costing.solveComponentConditionals(myOptions,myChoices,attribute,component,myH2KHouseInfo)

    if ( component.is_a?(String) ) then
      debug_out "retuning string  #{component}"
      return component
    elsif ( component.is_a?(Hash) ) then
      finalResult = nil
      #debug_off
      #debug_on if (attribute =~ /HVAC/ )
      debug_out " Solving component conditionals for HASH:\n#{component.pretty_inspect}"

      # Conditionals are defined as hashes
      #              { "if[Opt-HVAC.inc?]": {
      #                  "ducting:central_forced_air": "ducting:connect_ventilator_to_central_forced_air",
      #                  "else": "ducting:direct-duct_hrv"
      #                }
      #             }
      #Attempt to process conditional

      #ifThen = false
      #selectBy = false

      #selectBy = true if ( component.keys[0] =~/select\[/ )
      #ifThen = true if ( component.keys[0] =~/if\[/ )
      debug_out "Component - conditional: #{component.keys[0]}\n"
      condVariable = component.keys[0]
      condResults  = component[condVariable]
      dataSource, dataKey    = condVariable.split(/\./)

      debug_out "DataSource: #{dataSource}\n"
      debug_out "DataKey   : #{dataKey}\n"
      keysMap = dataKey.split( /\// )

      # TestVariable
      testVariable = nil
      myChoice = nil
      if ( dataSource =~ /H2KHouseInfo/i )
        myMap = myH2KHouseInfo.clone
      end
      if ( dataSource =~ /HTAPOptions/ )
        myAttribute = dataKey.split(/\//)[0]
        myChoice = myChoices[myAttribute]
        myMap = myOptions.clone
      end
      #debug_out "\n#{myMap.pretty_inspect}\n"

      keysMap.each do | key |
        if ( key == "[choice]" ) then
          thisKey = myChoice
        else
          thisKey = key
        end
        debug_out "Keysmap @ '#{thisKey}':\n"
        myMap = myMap[thisKey]
        debug_out "#{myMap.pretty_inspect}\n"
        testVariable = myMap
      end

      if ( testVariable.is_a?(Hash) ) then
        debug_out "COND: #{condVariable} :A hash was retuned - calling recursively. \n"
        testVariable = Costing.solveComponentConditionals(myOptions,myChoices,attribute,testVariable,myH2KHouseInfo)
      end

      if ( testVariable.is_a?(Array) ) then
        debug_out "COND: #{condVariable} : An array was returned. Examining. \n"
        testVariable.each do | variable |
          if ( variable.is_a?(Hash) ) then
            debug_out "COND: #{condVariable} :A hash was found in that array - calling recursively. \n"
            variable = Costing.solveComponentConditionals(myOptions,myChoices,attribute,variable,myH2KHouseInfo)
          end
        end
      end


      debug_out (" Queried #{dataSource} / #{dataKey} - Returned:\n> #{testVariable.pretty_inspect}\n")

      # Now, compare to conditionals.

      condResults.each do | query, result |

        queryType, queryValue = query.split(/\?/)

        conditionMet = HTAPData.simpleConditional(testVariable, queryType,queryValue)
        debug_out ("Q: is #{dataKey}=#{testVariable} #{queryType} #{queryValue}? #{conditionMet}\n")

        finalResult = result if ( conditionMet )
        break if ( conditionMet )

      end

      debug_out "Returning condtional result - #{finalResult}\n"
      debug_off
      return finalResult
      end

  end

  # THE options file may contain nested cost references
  # with conditionals and proxy cost statements.
  # This function untangles these references and returns
  # a cleaner Option array specifiying the effective
  # component costs.
  def Costing.resolveCostingLogic(myOptions,myChoices,myH2KHouseInfo)

    #debug_off

    mySimplerCostTree = Hash.new
    rawCostLists = Hash.new

    debug_out drawRuler("Step 1: mapping proxies and recovering initial cost lists\n"," .")
    # Step 1: map proxies.
    myChoices.keys.each do | attribute |

      next if ! CostingSupport.include? attribute


      rawCostLists[attribute] = Array.new

      choice = myChoices[attribute]


      debug_out ("Checking for proxy costing for #{attribute}=#{choice}: source = ")
      rawCostLists[attribute], finalChoice = Costing.getCostComponentList(myOptions,myChoices,attribute,choice)

      mySimplerCostTree[attribute] = Hash.new
      mySimplerCostTree[attribute]["options"] = Hash.new
      mySimplerCostTree[attribute]["options"][choice] = Hash.new
      mySimplerCostTree[attribute]["options"][choice]["costComponents"] = rawCostLists[attribute]
      mySimplerCostTree[attribute]["options"][choice]["dataCameFrom"] = finalChoice
      debug_out("#{finalChoice}\n")
    end

    # Step 2: Resolve conditional logic
    debug_out drawRuler("Step 2: solving conditionals in cost lists\n"," .")
    rawCostLists.each do | attribute, list |
      finalCostList = Array.new
      choice = myChoices[attribute]
      # elements inside component Cost list can  be a hash, indicating embedded comditional logic
      list.each do | component |
        resolvedComponent = Costing.solveComponentConditionals(mySimplerCostTree,myChoices,attribute,component,myH2KHouseInfo)
        finalCostList.push resolvedComponent
      end
      mySimplerCostTree[attribute]["options"][choice]["costComponents"] = finalCostList
      debug_out (" > summary for #{attribute} = #{choice} \n")
      debug_out (" > cost Data source #{  mySimplerCostTree[attribute]["options"][choice]["dataCameFrom"]}\n")
      debug_out (" > cost Data array:\n #{  mySimplerCostTree[attribute]["options"][choice]["costComponents"].pretty_inspect}\n")

    end
    return mySimplerCostTree

  end

  # Recovers costs associated with a given attribute, choices.
  def Costing.getCosts(myUnitCosts,myOptions,attrib,choice,useTheseSources)


    #debug_on if ( choice != "NA" )



    debug_out(" [>] Costing.getCosts: searching cost data for #{attrib} = #{choice}\n")

    myCosts = Hash.new
    found = false
    customDone = false
    done = false

    source = ""

    # Return zero cost for choice = NA (assume we don't know what that is)
    if ( choice.eql? "NA" ) then

      myCosts["as_per_h2k_file"] = Hash.new
      myCosts["as_per_h2k_file"] = {
        "found"    => true,
        "data"     => Hash.new ,
        "inherited"=> false
      }
      myCosts["as_per_h2k_file"]["data"] = {
        "source" => "default",
        "catagory" => "NA",
        "units"  => "undefined",
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
              found = true
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

    if ( ! found )

        myCosts["no_costs_defined"] = Hash.new
        myCosts["no_costs_defined"] = {
          "found"    => true,
          "data"     => Hash.new ,
          "inherited"=> false
        }
        myCosts["no_costs_defined"]["data"] = {
          "source" => "default",
          "catagory" => "NA",
          "units"  => "undefined",
          "UnitCostsMaterials" => 0.0 ,
          "UnitCostsLabour" =>    0.0
        }
    end

    debug_out(" [<] Costing.getCosts: returning \n")
    return myCosts
  end



  # Master routine for computing costs
  def Costing.computeCosts(mySpecdSrc,myUnitCosts,myOptions,myChoices,myH2KHouseInfo)

    debug_off

    costSourcesDBs = Array.new
    costSourcesCustom = Array.new

    costSourcesCustom    = mySpecdSrc["custom"]
    costSourcesDBs       = mySpecdSrc["components"]

    myCosts = Hash.new
    myCosts["total"] = 0
    myCosts["byAttribute"] = Hash.new

    CostingSupport.each do | attribute |
      myCosts["byAttribute"][attribute] = 0
    end

    myCosts["bySource"] = Hash.new
    myCosts["byBuildingComponent"] = Hash.new
    myCosts["audit"] = Hash.new
    debug_out drawRuler(" Costing calculations ",'.')
    debug_out ("Choices to be costed:\n#{myChoices.pretty_inspect}\n")


    debug_out "  Untangling costing logic via  Costing.resolveCostingLogic(myOptions,myChoices)\n"

    simpleCostTree = Costing.resolveCostingLogic(myOptions,myChoices,myH2KHouseInfo)
    debug_out " GSHP costing components? \n"
    debug_out (simpleCostTree.pretty_inspect)

    allCostsOK = true
    myChoices.each do | attrib, choice |
      #debug_off()
      if ( CostingSupport.include? attrib )  then
        #debug_on()  if (choice != "NA" )
      end

      debug_out " #{attrib} = #{choice}\n"
      debug_out (" + Does cost data exist for #{attrib}? ")

      componentCostsSummary = Hash.new
      # Check to see if costing is supported for this attribute

      if ( ! CostingSupport.include? attrib )  then
        debug_out (" no.\n")

      else
        debug_out (" Yes!\n")

        myCosts["byAttribute"][attrib] = 0
        myCosts["audit"][attrib] = {
          "elements" => Hash.new,
          "providence" => Hash.new
        }



        debug_out (" Calling Costing.GetCosts to recover unit costs for #{attrib} = #{choice}\n")

        choiceCosts = Hash.new
        choiceCosts = Costing.getCosts(myUnitCosts,simpleCostTree,attrib,choice,costSourcesDBs)

        costsOK = true

        choiceCosts.keys.each do | costingElement |

          debug_out " Computing costs for #{attrib}=#{choice}, \n+-> component [#{costingElement}]\n"

          catagory = choiceCosts[costingElement]["data"]["category"]
          debug_out "       from catagory: #{catagory} \n"

          units = choiceCosts[costingElement]["data"]["units"]
          # Aliases for standard units - perhaps these should be located in the cost-parsing text?
          units = "ea" if ( units =~ /ea\.?ch/i  )
          materials = choiceCosts[costingElement]["data"]["UnitCostMaterials"].to_f
          labour  = choiceCosts[costingElement]["data"]["UnitCostLabour"].to_f
          source = choiceCosts[costingElement]["data"]["source"]
          measureDescription = ""
          measure = 0.0

          debug_out "  Recovering measure for #{attrib}/#{choice}/#{costingElement}\n"
          if ( costingElement == "as_per_h2k_file" ) then
            source    = "NA"
            units     = "NA"
            measure   = 0.0
            materials = 0.0
            labour    = 0.0
            measureDescription = "Spec as defined in H2K file; costs cannot be computed"
          elsif ( costingElement == "no_costs_defined") then
            source    = "nil"
            units     = "nil"
            measure   = 0.0
            materials = 0.0
            labour    = 0.0
            measureDescription = "No costs have been defined; assume zero cost impact."
          else

            case attrib
              # .....................................................................
            when "Opt-ACH"
              if ( units == "sf wall" || units == "sf wall (net)" || units == "sf wall area (gross)" ) then
                measure =
                (
                    myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["gross"] +
                    myH2KHouseInfo["dimensions"]["below-grade"]["walls"]["total-area"]["internal"]
                ) * SF_PER_SM

                measureDescription = "sq.ft - Gross interior wall area including headers, foundation walls, window and door area"

              elsif ( units == "sf attic"  || units == "sf ceilings")
                measure = myH2KHouseInfo["dimensions"]["ceilings"]["area"]["all"] * SF_PER_SM
                measureDescription = "sq.ft - Ceiling area: including attics, flat roofs and scissor ceilings"

              elsif ( units == "sf header area" )
                measure = myH2KHouseInfo["dimensions"]["headers"]["area"]["total"] * SF_PER_SM
                measureDescription = "sq.ft - Floor header area"

              elsif ( units == "ea" || units =="undefined")
                measureDescription = "ea.   - Total component cost, including materials + labour"
                measure = 1.0

              else

                costsOK = false
              end
            when "Opt-FloorHeaderIntIns"
              if ( units == "sf header area" || units == "sf applied" || units =="undefined" )
                  measure = myH2KHouseInfo["dimensions"]["headers"]["area"]["total"] * SF_PER_SM
                measureDescription = "sq.ft - Floor header area"

              else

                costsOK = false
              end

              # ........................................................................
            when "Opt-AtticCeilings"

              if ( units == "sf attic" || units =="undefined" )
                measure = myH2KHouseInfo["dimensions"]["ceilings"]["area"]["attic"] * SF_PER_SM
                measureDescription = "sq.ft - Ceiling area, attics"
              else
                costsOK = false
              end

              # ........................................................................
            when "Opt-GenericWall_1Layer_definitions"

              # Exterior board insulation: goes over header
              if Costing.isExteriorInsulaiton( costingElement) then
                 measure =  (
                   myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["net"] +
                   myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["headers"]
                ) * SF_PER_SM
                measureDescription = "sq.ft - Opaque above-grade wall area - includes headers, excludes windows/doors and a.g. fdn"

              elsif ( units == "sf applied" || units =~ /sf wall/)
                measure = myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["net"]* SF_PER_SM
                measureDescription = "sq.ft - Opaque above-grade wall area - excludes headers, windows/doors and a.g. fdn"

              elsif ( units == "ea"  || units =="undefined")

                  measure = 1.0
                  measureDescription = "ea.   - Total component installation cost (ea)"
              else
                costsOK = false
              end

              # ........................................................................
            when "Opt-CasementWindows"

              if ( (units == "sf applied" &&  catagory == "WINDOWS") || units =="undefined")

                measure = myH2KHouseInfo["dimensions"]["windows"]["area"]["total"] * SF_PER_SM
                measureDescription = "sq.ft - Window area, glass + frame"
              else

                costsOK = false

              end

              # ........................................................................
            when "Opt-FoundationWallExtIns"

              if ( units == "sf applied" || units == "sf wall" || units =="undefined")

                measure = myH2KHouseInfo["dimensions"]["below-grade"]["walls"]["total-area"]["external"] * SF_PER_SM
                measureDescription = "sq.ft - Foundation walls - total external area inc, above and below grade"

              else

                costsOK = false

              end
              # ..................................................................
            when "Opt-FoundationWallIntIns"

              if ( units == "sf applied" || units == "sf wall" || units =="undefined")
                measure = myH2KHouseInfo["dimensions"]["below-grade"]["walls"]["total-area"]["internal"] * SF_PER_SM
                measureDescription = "sq.ft - Foundation walls - total internal area inc. above & below grade"
              else
                costsOK = false
              end


              # ..................................................................
            when "Opt-FoundationSlabBelowGrade"

              if ( units == "sf applied" || units =="undefined") then

                measure = (  myH2KHouseInfo["dimensions"]["below-grade"]["basement"]["floor-area"]  +  myH2KHouseInfo["dimensions"]["below-grade"]["crawlspace"]["floor-area"] )  * SF_PER_SM
                measureDescription = "sq.ft - Below grade floor area: basement + crawlspaces"
              else

                costsOK = false

              end

              # ..................................................................
            when "Opt-FoundationSlabOnGrade"

              if ( units == "sf applied" || units =="undefined")

                measure = ( myH2KHouseInfo["dimensions"]["below-grade"]["slab"]["floor-area"] ) * SF_PER_SM
                measureDescription = "sq.ft - Below grade floor area: slab on grade"
              else

                costsOK = false

              end
              # ..................................................................
            when "Opt-DWHRSystem"

              if ( units == "ea"  || units =="undefined")

                measure = 1.0
                measureDescription = "ea.   - Total component installation cost (ea)"
              else

                costsOK = false

              end

              # ..................................................................
            when "Opt-DHWSystem"

              if ( units == "ea"  || units =="undefined")

                measure = 1.0
                measureDescription = "ea.   - Total component installation cost (ea)"
              else

                costsOK = false

              end


              # ..................................................................
            when "Opt-HVACSystem"

              if ( units == "ea" || units =="undefined"  )

                measure = 1.0
                measureDescription = "ea.   - Total component installation cost"
              elsif ( units == "sf heated floor area")
                measure =  ( myH2KHouseInfo["dimensions"]["heatedFloorArea"] ) * SF_PER_SM
                measureDescription = "sq.ft - Heated floor area from HOT2000 file"
              elsif ( units == "kW capacity" )

                if ( catagory == "ELECTRIC RESISTANCE BASEBOARDS" ) then
                  if ( myH2KHouseInfo["HVAC"]["Baseboards"]["count"].to_i == 0  ) then
                    warn_out "H2K file doesn't contain any baseboards. Can't cost #{costingElement}\n"
                  end
                  measure = myH2KHouseInfo["HVAC"]["Baseboards"]["capacity_kW"].to_f * 1.1
                  measureDescription = "kW    - Total installed baseboard heating capacity"

                elsif ( catagory == "AIR CONDITIONING" ) then
                  if ( myH2KHouseInfo["HVAC"]["AirConditioner"]["count"].to_i == 0  ) then
                    warn_out "H2K file doesn't contain any air conditioners. Can't cost #{costingElement}\n"
                  end

                  measure = myH2KHouseInfo["HVAC"]["AirConditioner"]["capacity_kW"].to_f * 1.1
                  measureDescription = "kW    - Total AC cooling capacity, including central and window units"
                else
                  warn_out "Unknown Catagory #{catagory} for #{costingElement}"
                end

              else

                costsOK = false

              end
              # ..................................................................
            when "Opt-HRVonly"

              if ( units == "ea" || units =="undefined" )

                measure = 1.0
                measureDescription = "ea.   - Total component installation cost"

              elsif ( units == "l/s capacity")
                if ( catagory == "HRV" ) then
                  measure = myH2KHouseInfo["HVAC"]["Ventilator"]["capacity_l/s"].to_f
                  measureDescription ="l/s  - Ventilator supply/exhayst capacity "
                end

              else

                costsOK = false

              end

            else
              warn_out("Costing requested for #{attrib} / #{costingElement} / (units: #{units}), but no rule exists for getting measures for #{attrib} ")
              debug_out( "Attribute #{attrib} - no costing rules a\n")
              measure = 1.0
              costsOK = false
            end
          end




          debug_out ("   Source    :   #{source}\n")
          debug_out ("   Units     :   #{units}\n")
          debug_out ("   Measure   :   #{measure} (#{units})\n")
          debug_out ("   Materials : $ #{materials.round(2)} / #{units}\n")
          debug_out ("   Labour    : $ #{labour.round(2)} / #{units}\n")

          # ===============================================================
          # Compute costs :
          if ( costsOK )
            myCostsComponent = measure * ( materials + labour )

            myCosts["total"] += myCostsComponent.round(2)

            myCosts["byAttribute"][attrib] += myCostsComponent.round(2)

            if ( myCosts["bySource"][source].nil?  ) then
              myCosts["bySource"][source] = 0.0
            end
            myCosts["bySource"][source] +=  myCostsComponent.round(2)

            myCosts["audit"][attrib]["elements"][costingElement] = {
              "source" => source,
              "quantity" => measure,
              "units"  => units,
              "measureDescription"  => measureDescription,
              "unit-cost-materials" => materials.round(2),
              "unit-cost-labour"    => labour.round(2),
              "unit-cost-total"     => labour.round(2)+ materials.round(2),
              "component-costs"     => myCostsComponent.round(2),
            }

            debug_out ("   Cost      : $ #{myCostsComponent.round(2)}\n")
            componentCostsSummary[costingElement] = myCostsComponent.round(2)

          else
            warn_out ("Can't cost #{attrib}/#{choice}/#{costingElement}")
            debug_out("Unknown unit of measure for #{attrib}/#{choice}/#{costingElement}!\n")
            warn_out ("Unknown units: \"#{units}\" for #{costingElement} [#{attrib} = #{choice}]")
            debug_out("available measures\n#{myH2KHouseInfo.pretty_inspect}\n")
            allCostsOK = false

          end


        end

        #debug_on
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
        #debug_off

        if ( choice != simpleCostTree[attrib]["options"][choice]["dataCameFrom"] )
          proxyCosts = true
          proxyChoice = simpleCostTree[attrib]["options"][choice]["dataCameFrom"]
        else
          proxyCosts = false
          proxyChoice = nil
        end
        myCosts["audit"][attrib]["providence"] = {
          "proxyCosts"          => proxyCosts,
          "proxyChoice"         => proxyChoice
        }




      end

    end



    myCosts["byBuildingComponent"]["envelope"] =
      myCosts["byAttribute"]["Opt-ACH"] +
      myCosts["byAttribute"]["Opt-CasementWindows"] +
      myCosts["byAttribute"]["Opt-GenericWall_1Layer_definitions"] +
      myCosts["byAttribute"]["Opt-FloorHeaderIntIns"] +
      myCosts["byAttribute"]["Opt-FoundationWallExtIns"] +
      myCosts["byAttribute"]["Opt-FoundationWallIntIns"] +
      myCosts["byAttribute"]["Opt-FoundationSlabBelowGrade"] +
      myCosts["byAttribute"]["Opt-FoundationSlabOnGrade"] +
      myCosts["byAttribute"]["Opt-Ceilings"] +
      myCosts["byAttribute"]["Opt-AtticCeilings"]

    myCosts["byBuildingComponent"]["mechanical"] =
      myCosts["byAttribute"]["Opt-HRVonly"] +
      myCosts["byAttribute"]["Opt-DHWSystem"] +
      myCosts["byAttribute"]["Opt-HVACSystem"] +
      myCosts["byAttribute"]["Opt-DWHRSystem"]

    # Not supported yet.
    myCosts["byBuildingComponent"]["renewable"] = 0

    myCosts["status"] = allCostsOK
    if (! allCostsOK ) then
      warn_out ("Costing calculations could not be computed correctly")
    end

    debug_out "Compute-Costs: Returning \n#{myCosts.pretty_inspect}\n"

    return myCosts,allCostsOK

  end

  # Create a report auditing all the costing data used in calculaitons,
  # and return as a string.

  def Costing.getAttributeComponents(myChoices,myCosts,myH2KHouseInfo)

    myComponentsDetails = Hash.new
    myChoices.each do |attribute, choice |


    end


  end



  def Costing.auditComponents(myChoices,myCosts,myH2KHouseInfo,format="txt")
    #
    myUnitCostsDB = Costing.parseUnitCosts("C:\\HTAP\\HTAPUnitCosts.json")

    if ( format != "txt") then
      markdown = true
      sep ="|"
    else
      sep = ""
      markdown = false
    end
    debug_out ("Format: #{format}, Markdown: #{markdown}, sep: #{sep} \n")

    lenLongestComponent   = 20
    lenLongestDescription = 20
    lenLongestUnits       = 10

    index = 0
    colWidth = 12
    colPad = 2
    colSep = "   "
    reportTxt = ""
    myChoices.each do | attribute, choice |
      next if ( ! CostingSupport.include? attribute  )
      debug_out drawRuler(nil, "  .  ")
      debug_out "Getting text formats  for #{attribute}\n"




      componentdata = myCosts["audit"][attribute]

      componentdata["elements"].each do | component, data |

        lenLongestComponent = [lenLongestComponent, component.gsub(/_/," ").gsub(/:/,": ").length].max
        lenLongestDescription = [lenLongestDescription, data["measureDescription"].length ].max
        lenLongestUnits = [lenLongestUnits, data["units"].length].max
      end


    end
    lenLongestComponent   = [ lenLongestComponent   , 60  ].min
    lenLongestDescription = [ lenLongestDescription , 100 ].min
    lenLongestUnits       = [ lenLongestUnits       , 50  ].min

    reportLength = lenLongestComponent + lenLongestDescription + 6 * colWidth + 6*colSep.length

    myChoices.each do | attribute, choice |
      next if ( ! CostingSupport.include? attribute  )
      index += 1
      componentdata = myCosts["audit"][attribute]

      reportTxt += "###### #{index}) #{attribute.gsub(/_/,"\\_")} -> #{choice.gsub(/_/,"\\_")}\n"
      reportTxt += "Estimated benchmark cost for this measure: **$ #{'%.2f' % myCosts["byAttribute"][attribute].to_f}**.\n\n"


      if ( componentdata["providence"]["proxyCosts"] == true  ) then
        reportTxt += "Note that costs have not been defined for #{choice.gsub(/_/,"\\_")}."
        reportTxt += " ==Used specification from #{componentdata["providence"]["proxyChoice"].gsub(/_/,"\\_")} to estimate costs.== Details follow.\n"
      end


      # Header row
      reportTxt += "\n"

      reportTxt += "Component: ".ljust(lenLongestComponent+2)
      reportTxt += "#{sep}"
      reportTxt += "  Materials ($/unit)  ".ljust(colWidth)
      reportTxt += "#{sep}"
      reportTxt += "  Labour ($/unit) ".rjust(colWidth)
      reportTxt += "#{sep} "
      reportTxt += " Total unit cost ($/unit) ".rjust(colWidth)
      reportTxt += "#{sep}"
      reportTxt += "  Qty.   ".rjust(colWidth)
      reportTxt += "#{sep}"
      reportTxt += "  Applied costs\ ($)".ljust(colWidth)+"\n"


      reportTxt += ":".ljust(lenLongestComponent+2,"-")
      reportTxt += "#{sep}"
      reportTxt += ":".rjust(colWidth-1,"-")
      reportTxt += "#{sep}"
      reportTxt += ":".rjust(colWidth-1,"-")
      reportTxt += "#{sep}"
      reportTxt += ":".rjust(colWidth-1,"-")
      reportTxt += "#{sep}"
      reportTxt += ":".rjust(colWidth-1,"-")
      #reportTxt += "#{sep}"
      #reportTxt += "-".ljust(colWidth-1,"-")
      reportTxt += "#{sep}"
      reportTxt += "-".ljust(colWidth-1,"-").+":\n"

      componentNotes ="Notes:\n"
      componentIndex = 0
      componentdata["elements"].each do | component, data |
        componentIndex += 1
        unitShort= data["measureDescription"].gsub(/-.*$/,"")
        unitShort = "-" if ( unitShort =~ /No costs have been defined;/ || unitShort =~ /pec as defined in H2K file/ )
        lineTxt = ""
        lineTxt += "#{component.gsub(/_/," ").gsub(/:/,": ")}[^#{componentIndex}]"
        lineTxt += sep
        lineTxt += "$\ #{'%.2f' % data["unit-cost-materials"].to_f}".rjust(colWidth-colPad)+" "*colPad
        lineTxt += sep
        lineTxt += "$\ #{'%.2f' % data["unit-cost-labour"].to_f}".rjust(colWidth-colPad)+" "*colPad
        lineTxt += sep
        lineTxt += "$\ #{'%.2f' % data["unit-cost-total"].to_f}\ /\ #{unitShort}".rjust(colWidth-colPad)+" "*colPad
        lineTxt += sep
        lineTxt += "#{'%.2f' % data["quantity"].to_f}\ #{unitShort}".rjust(colWidth-colPad)+" "*colPad
        lineTxt += sep
        lineTxt += "$\ #{'%.2f' % data["component-costs"].to_f}".rjust(colWidth-colPad)+" "*colPad
        #lineTxt += sep
        #lineTxt += shortenToLen(data["measureDescription"],lenLongestDescription)
        #lineTxt += data["units"].ljust(colWidth+20)
        #lineTxt += " ".ljust(colWidth)
        #lineTxt += shortenToTerm("#{component}",lineTxt.length)
        reportTxt += lineTxt + "\n"

        #pp myUnitCostsDB["data"][component]
        #pp data["source"]


        mySource = data["source"]

        debug_out "> #{data.pretty_inspect}"
        debug_out ": (#{mySource})\n"
        if ( mySource.nil? || mySource.to_s == "nil"  ||mySource.to_s == "NA" )
          componentNotes += "[^#{componentIndex}]: _#{component.gsub(/_/," ")}_: Computed using #{data["measureDescription"]}\n"
        else

          myNotes = myUnitCostsDB["data"][component][mySource]["note"]
          myDate  = myUnitCostsDB["data"][component][mySource]["date"]

          componentNotes += "[^#{componentIndex}]: _#{component.gsub(/_/," ")}_: Source - #{mySource.gsub(/_/,"\\_")} (#{myDate}). #{myNotes} Computed using #{data["measureDescription"]}\n"
        end


      end


      reportTxt += "**TOTAL**".rjust(lenLongestComponent+2)
      reportTxt += sep
      reportTxt += " ".ljust(colWidth)
      reportTxt += sep
      reportTxt += "  ".rjust(colWidth)
      reportTxt += sep
      reportTxt += "   ".rjust(colWidth)
      reportTxt += sep
      reportTxt += "   ".rjust(colWidth)
      reportTxt += sep
      reportTxt += "**$\ #{'%.2f' % myCosts["byAttribute"][attribute].to_f}**".rjust(colWidth-colPad)+" "*colPad
      reportTxt += "\n"
      #sep
      #reportTxt += "( total for measure ) "
      reportTxt += "\n\n"
      reportTxt += componentNotes
      reportTxt += "\n\n"
    end

    return reportTxt

  end

  def Costing.auditCosts(myChoices,myCosts,myH2KHouseInfo,fluff=true)

    audTxt = "\n"

    index = 0
    colWidth = 12
    colPad = 2
    colSep = "   "
    lenLongestComponent   = 20
    lenLongestDescription = 20
    lenLongestUnits       = 10
    myCosts["audit"].each do | attribute , componentdata |
      next if ( ! CostingSupport.include? attribute  )
      componentdata["elements"].each do | component, data |
        lenLongestComponent = [lenLongestComponent, component.gsub(/_/," ").gsub(/:/,": ").length].max
        lenLongestDescription = [lenLongestDescription, data["measureDescription"].length ].max
        lenLongestUnits = [lenLongestUnits, data["units"].length].max
      end
    end

    lenLongestComponent   = [ lenLongestComponent   , 60  ].min
    lenLongestDescription = [ lenLongestDescription , 100 ].min
    lenLongestUnits       = [ lenLongestUnits       , 50  ].min



    reportLength = lenLongestComponent + lenLongestDescription + 6 * colWidth + 6*colSep.length
    if fluff then
      h2kFilename = myH2KHouseInfo["h2kFile"]
      audTxt += drawRuler("HTAP Costing - Audit Report | h2kFile: #{h2kFilename} | #{Time.now}","=",reportLength)
      audTxt += "\nThis report details HTAP's costing calculations.\n"
      audTxt += "\nCost summary:\n"
      audTxt += Costing.summarizeCosts(myChoices, myCosts)
      audTxt += "\n\n"
      audTxt += drawRuler("Choice-by-Choice costing calculations", "=", reportLength)
    end
    myChoices.each do | attribute, choice |

      next if ( ! CostingSupport.include? attribute  )
      next if ( choice.nil? || myCosts["audit"][attribute].nil? )
      componentdata = myCosts["audit"][attribute]

      #myCosts["audit"][attrib][costingElement] = {
      #  "source" => source,
      #  "quantity" => measure,
      #  "units"  => units,
      #  "unit-cost-materials" => materials.round(2),
      #  "unit-cost-labour"    => labour.round(2),
      #  "component-costs"     => myCostsComponent.round(2)
      #}
      #debug_on
      debug_out ("Component data:\n #{componentdata.pretty_inspect}\n")

      proxyRefTxt = ""
      if ( componentdata["providence"]["proxyCosts"] == true  ) then
        proxyRefTxt = " (Note: Used specification from #{componentdata["providence"]["proxyChoice"]} to estimate costs.)"
      end

      index += 1
      audTxt += "\n"
      audTxt += "\##{index}) #{attribute} = #{choice}#{proxyRefTxt}\n"



      audTxt += drawRuler(nil,"=",reportLength)

      audTxt += "Cost Component: ".ljust(lenLongestComponent+2)
      audTxt += "[ ("
      audTxt += " (  Mat.$/ ".ljust(colWidth)
      audTxt += " + "
      audTxt += "  Lab.$/ ".rjust(colWidth)
      audTxt += ") ="
      audTxt += " U. Cost $/ ".rjust(colWidth)
      audTxt += "] *"
      audTxt += "[  Qty.  ] ".rjust(colWidth)
      audTxt += " = "
      audTxt += "[  Cost $  ]".ljust(colWidth)
      audTxt += "  "
      audTxt += "( Quantity represents: ) "

      #audTxt += "|Units of Measure ".ljust(colWidth)
      #audTxt += "|Component Name".ljust(30)
      audTxt +="\n"
      audTxt += "."*reportLength+"\n"
      componentdata["elements"].each do | component, data |

        lineTxt = ""
        lineTxt += shortenToLen( component.gsub(/_/," ").gsub(/:/,": "), lenLongestComponent ).ljust(lenLongestComponent+2)
        lineTxt+= colSep
        lineTxt += "#{'%.2f' % data["unit-cost-materials"].to_f}".rjust(colWidth-colPad)+" "*colPad
        lineTxt+= colSep
        lineTxt += "#{'%.2f' % data["unit-cost-labour"].to_f}".rjust(colWidth-colPad)+" "*colPad
        lineTxt+= colSep
        lineTxt += "#{'%.2f' % data["unit-cost-total"].to_f}".rjust(colWidth-colPad)+" "*colPad
        lineTxt+= colSep
        lineTxt += "#{'%.2f' % data["quantity"].to_f}".rjust(colWidth-colPad)+" "*colPad
        lineTxt+= colSep
        lineTxt += "#{'%.2f' % data["component-costs"].to_f}".rjust(colWidth-colPad)+" "*colPad
        lineTxt += colSep
        lineTxt += shortenToLen(data["measureDescription"],lenLongestDescription)
        #lineTxt += data["units"].ljust(colWidth+20)
        #lineTxt += " ".ljust(colWidth)
        #lineTxt += shortenToTerm("#{component}",lineTxt.length)
        audTxt  += lineTxt + "\n"
      end
      audTxt += "."*reportLength+"\n"
      audTxt += "TOTAL:".rjust(lenLongestComponent+2)
      audTxt += "   "
      audTxt += " ".ljust(colWidth)
      audTxt += "   "
      audTxt += "  ".rjust(colWidth)
      audTxt += "   "
      audTxt += "   ".rjust(colWidth)
      audTxt += "   "
      audTxt += "   ".rjust(colWidth)
      audTxt += "   "
      audTxt += "#{'%.2f' % myCosts["byAttribute"][attribute].to_f}".rjust(colWidth-colPad)+" "*colPad
      audTxt += "  "
      audTxt += "( total for measure ) "
      audTxt += "\n"

    end
    return audTxt
  end

  def Costing.isExteriorInsulaiton(costingElement)

    return true if ( costingElement =~ /fasteners.+exterior_insulation/ )
    return true if ( costingElement =~ /^insulation/ && ( costingElement =~ /rigid/ ||  costingElement =~ /board/ ) )
    return false

  end


  def Costing.summarizeCosts(myChoices,myCosts,format="txt")
    #debug_on

    # TO DO - simplify the markdown inplementaiton of this table

    markdown = false
    m = " "

    if ( format != "txt") then
      markdown = true
      m = "|"

    end
    maxAttLen = 0
    maxChoiceLen = 0
    myCosts["byAttribute"].each do | attribute, cost |
      debug_out ("> #{attribute}: #{cost}\n")
      maxAttLen = [attribute.length, maxAttLen].max
      maxChoiceLen = [myChoices[attribute].length,maxChoiceLen].max
    end
    summaryTxt = ""
    summaryTxt +=  " ....................................................................................................\n" if (! markdown)
    summaryTxt +=  "#{m}#{"Option".ljust(maxAttLen)} #{m}  #{"Choice".ljust(maxChoiceLen)} #{m}    Cost#{m}\n"
    summaryTxt +=  "#{m}---#{m}---#{m}---:#{m}\n" if markdown
    summaryTxt +=  " ....................................................................................................\n" if (! markdown)



    myCosts["byAttribute"].each do | attribute, cost |
      next if (myChoices[attribute].nil? || attribute.nil? )
      #attList = " #{attribute.ljust(30)} = #{myChoices["attribute"].ljust(30)}"
      #next if ( cost.to_f < 0.1 )
      costtxt = '%.2f' % cost.to_f
      if markdown
        summaryTxt += " #{m}#{attribute.gsub(/_/,"\\_").ljust(maxAttLen)} #{m} #{myChoices[attribute].gsub(/_/,"\\_").ljust(maxChoiceLen)} #{m} $ #{costtxt.rjust(9)}#{m}\n"
      else
        summaryTxt += " #{m}#{attribute.ljust(maxAttLen)} #{m} #{myChoices[attribute].ljust(maxChoiceLen)} #{m} $ #{costtxt.rjust(9)}#{m}\n"
      end
    end
    myTotal = '%.2f' % myCosts["total"].to_f
    summaryTxt +=  " ....................................................................................................\n" if (! markdown)
    summaryTxt +=  "#{m}#{"Total ".ljust(maxAttLen)} #{m} #{" ".ljust(maxChoiceLen)} #{m}  $ #{myTotal.rjust(9)}#{m}\n"

    return summaryTxt
  end
end
