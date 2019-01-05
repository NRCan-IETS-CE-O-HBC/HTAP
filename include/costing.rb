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

  def Costing.getCosts(myUnitCosts,myOptions,attrib,choice,useTheseSources)



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
    if ( ! done ) then

      debug_out ( " [x] No custom costs matched. Searching for component-by-component costs.\n")

      # loop through the cost-components that are associated with
      # this option (in myOptions), and attempt to match myUnitCosts data
      # with requested data source (in useTheseSources )

      debug_out " >>> contents of options:\n#{myOptions[attrib]["options"][choice].pretty_inspect}\n"

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

    myChoices.each do | attrib, choice |

      if ( CostingSupport.include? attrib )  then
        debug_on()
      else
        debug_off()
      end
      debug_out " =================================================================\n"
      debug_out " #{attrib} = #{choice}\n"
      debug_out (" + Does cost data exist for #{attrib}? ")
      myCosts["byAttribute"][attrib] = 0

      # Check to see if costing is supported for this attribute

      if ( ! CostingSupport.include? attrib )  then
        debug_out (" no.\n")
      else
        debug_out (" Yes!\n")
        debug_out (" Calling Costing.GetCosts to recover unit costs for #{attrib} = #{choice}\n")

        choiceCosts = Hash.new
        choiceCosts = Costing.getCosts(myUnitCosts,myOptions,attrib,choice,costSourcesDBs)
        #debug_out (" Costs recovered from Costing.GetCosts:\n#{choiceCosts.pretty_inspect}\n")


        choiceCosts.keys.each do | costingElement |

          debug_out " Computing costs for #{attrib}=#{choice} component [#{costingElement}]\n"

          units = choiceCosts[costingElement]["data"]["units"]
          materials = choiceCosts[costingElement]["data"]["UnitCostMaterials"].to_f
          labour  = choiceCosts[costingElement]["data"]["UnitCostLabour"].to_f
          source = choiceCosts[costingElement]["data"]["source"]

          measure = Float
          case units
          when "default" || "ea"
            measure = 1
          when "sf attic"
            measure = myH2KHouseInfo["dimensions"]["ceilings"]["area"]["attic"] * SF_PER_SM
          when "lf wall"

          when "sf wall" || "sf wall (net)"
            measure =  ( myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["net"] ) * SF_PER_SM
          when  "sf wall area (gross)"
            measure =  ( myH2KHouseInfo["dimensions"]["walls"]["above-grade"]["area"]["gross"] ) * SF_PER_SM

          when "sf applied"
            # read the catagory to figure out what to do
            case choiceCosts[costingElement]["data"]["category"]
            when "WINDOWS"
              measure = myH2KHouseInfo["dimensions"]["windows"]["area"]["total"] * SF_PER_SM

            else
            end


          else
            measure = 1
          end

          # Compute costs :

          myCostsComponent = measure * ( materials + labour )

          myCosts["total"] += myCostsComponent.round(2)

          myCosts["byAttribute"][attrib] += myCostsComponent.round(2)

          if ( myCosts["bySource"][source].nil?  ) then
            myCosts["bySource"][source] = 0
          end
          myCosts["bySource"][source] +=  myCostsComponent.round(2)

          debug_out ("   Source    :   #{source}\n")
          debug_out ("   Units     :   #{units}\n")
          debug_out ("   Measure   :   #{measure.round(2)} (#{units})\n")
          debug_out ("   Materials : $ #{materials.round(2)} / #{units}\n")
          debug_out ("   Labour    : $ #{labour.round(2)} / #{units}\n")
          debug_out ("   Cost      : $ #{myCostsComponent.round(2)}\n")



        end

        debug_out "   ...............................................................\n"
        debug_out "   Est. cost impact for #{attrib} => #{choice} ? $ #{myCosts["byAttribute"][attrib].round(2)} \n"



      end

    end

    return myCosts

  end # def compute costs

end
