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
                           "Alert"        =>  1.38   }




module Costing

  def Costing.parseUnitCosts(unitCostFileName)

    unitCostDataHash = Hash.new

    unitCostFile = File.read(unitCostFileName)

    unitCostDataHash = JSON.parse(unitCostFile)

    return unitCostDataHash

  end

  def Costing.getCosts(myUnitCosts,myOptions,attrib,choice,useTheseSources)

    stream_out(" [>] Costing.getCosts: searching cost data for #{attrib} = #{choice}\n")

    myCosts = Hash.new
    found = false
    customDone = false
    done = false

    source = ""

     # Return zero cost for choice = NA (assume we don't know what that is)
    if ( choice.eql? "NA" ) then

      myCosts["NA"] = Hash.new
      myCosts["NA"] = { "found"    => true,
                        "data"     => Hash.new ,
                        "inherited"=> false       }
      myCosts["NA"]["data"] = { "source" => "default",
                                "catagory" => "NA",
                                "units"  => "ea",
                                "UnitCostsMaterials" => 0.0 ,
                                "UnitCostsLabour" =>    0.0  }

      return myCosts
    end

    # USE done as loop control -
    sourceIndex = 0
    # First - start with custom costs
    stream_out ( "  .  Searching for custom cost data\n")
    while ( ! customDone ) do
      # Get next valid cost source
      validSource = useTheseSources[sourceIndex]
      stream_out ("  .  Looking for custom cost scenarios matching #{validSource}... \n")
      # If custom costs didn't match, use component-by-component costs

      sourceIndex = sourceIndex + 1
      if ( sourceIndex == useTheseSources.length ) then
         customDone = true
      end

      # If we find a custom match, set componentDone to true and skip that section.

    end # while ( ! customDone ) do

    # Now get costs from components.

    if ( ! done ) then

      stream_out ( " [x] No custom costs matched. Searching for component-by-component costs.\n")

      # loop through the cost-components that are associated with
      # this option (in myOptions), and attempt to match myUnitCosts data
      # with requested data source (in useTheseSources )
      myOptions[attrib]["options"][choice]["costComponents"].each do | component |
        stream_out " [#] working with #{component}\n"

        # Cost data sets can inherit data from prior dbs.
        # Set default inheratence flag to zero.
        inherited = false


        # Define myCosts as a hash with cost component as key; initialize 'found'
        # attribut to false.
        myCosts[component] = Hash.new
        myCosts[component]["found"] = false

        useTheseSources.each do | specdSource |

          stream_out "  .  Source #{specdSource} was requested, does it exist in db?"
          nomatch = false
          if ( ! myUnitCosts["sources"].keys.include? specdSource ) &&
             ( ! specdSource.eql? "*" ) then
            stream_out " no. (moving on) \n"
            nomatch = true
          end

          next if nomatch

          # Either there is a match, or
          if ( specdSource.eql? "*" ) then
            # case 1: wild car.
            stream_out " It's a wild card - use any record! \n"
            # Wildcard - find any matching record
            if ( ! myUnitCosts["data"].keys.include? component ) then
              fatalerror "Could not find #{component} in unit cost data!"
            end
            source = myUnitCosts["data"][component].keys.sort[0]

          else

            stream_out " yes! \n"

            souce = specdSource
            stream_out "  .  checking for inheratence:\n"
            # Loop through all of the acestors
            myUnitCosts["sources"][specdSource]["inherits"].keys.each do | ancestor |

              stream_out "  .   ?  was component inherited from #{ancestor}?"

              # Check to see if the comonent cost was inherited from this ancestor.
              if ( ! myUnitCosts["sources"][specdSource]["inherits"][ancestor].include? component ) then
                stream_out " no.\n"
              else
                stream_out " YES!\n"
                stream_out ("  .  [!] Inheritance detected! validSource data originates from #{ancestor}\n")
                source = ancestor
                inherited = true
              end

              break if inherited

            end # myUnitCosts["sources"][specdSource]["inherits"].keys.each do | ancestor |

          end

          # find the component in myUnitCosts, and determine if it has cost
          # data that matches our source (specd || ancestor if inherited = true || arbitrary source for wildcard. )
          stream_out ("  .  proceeding to process component cost using data from #{source} \n")

          myUnitCosts["data"][component].keys.each do | costset |
            stream_out "  .   .  found unit cost data from `#{costset}`"
            if ( ! source.eql? costset) && ( ! source.eql? "*".str ) then
              stream_out " but that's not the one we need.\n"
            else
              stream_out " AND that's not the one we need!\n"
              stream_out " [+] Setting myCost data using data from #{costset}.\n"
              myCosts[component]["found"] = true
              myCosts[component]["data"] = Hash.new
              myCosts[component]["data"] = myUnitCosts["data"][component][source]
              myCosts[component]["inherited"] = inherited
              if (inherited) then
                myCosts[component]["specified_source"] = specdSource
                myCosts[component]["inherited_from"] = source
              end
            end

          end # myUnitCosts["data"][component].keys.each do | costset |

          break if myCosts[component]["found"]

        end # useTheseSources.each do | specdSource |

      end # myOptions[attrib]["options"][choice]["costComponents"].each do | component |

    end

    stream_out(" [<] Costing.getCosts: returning \n")
    return myCosts

  end

  def Costing.computeCosts()

  end

end
