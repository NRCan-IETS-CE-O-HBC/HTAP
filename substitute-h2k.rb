#!/usr/bin/env ruby
# substitute-h2k.rb

# This is essentially a Ruby version of the substitute.pl script -- customized for HOT2000 runs.

require 'rexml/document'
require 'optparse'

include REXML   # This allows for no "REXML::" prefix to REXML methods 

# Global variable names  (i.e., variables that maintain their content and use (scope) 
# throughout this file). 
# Note loose convention to start global variables with a 'g'. Ruby requires globals to start with '$'.
$gDebug = false
$gSkipSims = false
$gTest_params = Hash.new        # test parameters
$gChoiceFile  = ""
$gOptionFile  = ""

$gTotalCost          = 0 
$gIncBaseCosts       = 11727
$cost_type           = 0

$gRotate             = "S"

$gGOStep             = 0
$gArchGOChoiceFile   = 0

# Use lambda function  to avoid the extra lines of creating each hash nesting
$blk = lambda { |h,k| h[k] = Hash.new(&$blk) }
$gOptions = Hash.new(&$blk)
$gChoices = Hash.new(&$blk)

$gExtraDataSpecd  = Hash.new

$ThisError   = ""
$ErrorBuffer = "" 

$SaveVPOutput = 0 

$gEnergyPV = 0
$gEnergySDHW = 0
$gEnergyHeating = 0
$gEnergyCooling = 0
$gEnergyVentilation = 0 
$gEnergyWaterHeating = 0
$gEnergyEquipment = 0
$gERSNum = 0  # ERS number
$gERSNum_noVent = 0  # ERS number
$gERSCalcMode = 0

$gRegionalCostAdj = 0

$gRotationAngle = 0

$gEnergyElec = 0
$gEnergyGas = 0
$gEnergyOil = 0 
$gEnergyWood = 0 
$gEnergyPellet = 0 
$gEnergyHardWood = 0
$gEnergyMixedWood = 0
$gEnergySoftWood = 0
$gEnergyTotalWood = 0

$gTotalBaseCost = 0
$gUtilityBaseCost = 0 
$PVTarrifDollarsPerkWh = 0.10

$gPeakCoolingLoadW    = 0 
$gPeakHeatingLoadW    = 0 
$gPeakElecLoadW    = 0 

$gMasterPath = Dir.getwd()

#Variables that store the average utility costs, energy amounts.  
$gAvgCost_NatGas    = 0 
$gAvgCost_Electr    = 0 
$gAvgEnergy_Total   = 0  
$gAvgCost_Propane   = 0 
$gAvgCost_Oil       = 0 
$gAvgCost_Wood      = 0 
$gAvgCost_Pellet    = 0 
$gAvgPVRevenue      = 0 
$gAvgElecCons_KWh    = 0 
$gAvgPVOutput_kWh    = 0 
$gAvgCost_Total      = 0 
$gAvgEnergyHeatingGJ = 0 
$gAvgEnergyCoolingGJ = 0 
$gAvgEnergyVentilationGJ  = 0 
$gAvgEnergyWaterHeatingGJ = 0  
$gAvgEnergyEquipmentGJ    = 0 
$gAvgNGasCons_m3     = 0 
$gAvgOilCons_l       = 0 
$gAvgPropCons_l      = 0 
$gAvgPelletCons_tonne = 0 
$gDirection = ""

$GenericWindowParams = Hash.new(&$blk)
$GenericWindowParamsDefined = 0 

$gEnergyHeatingElec = 0
$gEnergyVentElec = 0
$gEnergyHeatingFossil = 0
$gEnergyWaterHeatingElec = 0
$gEnergyWaterHeatingFossil = 0
$gAvgEnergyHeatingElec = 0
$gAvgEnergyVentElec = 0
$gAvgEnergyHeatingFossil = 0
$gAvgEnergyWaterHeatingElec = 0
$gAvgEnergyWaterHeatingFossil = 0
$gAmtOil = 0

# Data from Hanscomb 2011 NBC analysis
$RegionalCostFactors = Hash.new
$RegionalCostFactors  = {  "Halifax"     =>  0.95 ,
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
                            "Inuvik"     =>  1.38 , 
                          "Alert"        =>  1.38   }

# Heating Degree Days (18C base), Source = HOT2000 v10.x (V10WeatherRPT.doc)
$RegionalHDD = Hash.new
$RegionalHDD                = { "Halifax"    =>  4100,
                            "Edmonton"       =>  5400,
                            "Calgary"        =>  5200,
                            "Ottawa"         =>  4600,
                            "Toronto"        =>  3650,
                            "Quebec"         =>  5200,
                            "Montreal"       =>  4250,
                            "Vancouver"      =>  2925,
                            "PrinceGeorge"   =>  5250,
                            "Kamloops"       =>  3650,
                            "Regina"         =>  5750,
                            "Winnipeg"       =>  5900,
                            "Fredricton"     =>  4650,
                            "Whitehorse"     =>  6900,
                            "Yellowknife"    =>  8500,
                            "Inuvik"         =>  10050,
                            "Alert"          =>  12822  }

# Water main temperature (C)
$RegionalWaterMainTemp = Hash.new
$RegionalWaterMainTemp =   { "Halifax"       =>  11.02,
                            "Edmonton"       =>  8.02,
                            "Calgary"        =>  9.02,
                            "Ottawa"         =>  12.03,
                            "Toronto"        =>  14.04,
                            "Quebec"         =>  10.02,
                            "Montreal"       =>  11.03,
                            "Vancouver"      =>  14.02,
                            "PrinceGeorge"   =>  9.02,
                            "Kamloops"       =>  13.03,
                            "Regina"         =>  9.02,
                            "Winnipeg"       =>  9.02,
                            "Fredricton"     =>  11.02,
                            "Whitehorse"     =>  6.01,
                            "Yellowknife"    =>  4.01,
                            "Inuvik"         =>  1.01,
                            "Alert"          =>  1.01 }


=begin rdoc
--------------------------------------------------------------------------
 METHODS: Routines called in this file must be defined before use in Ruby
          (can't put at bottom of listing).
--------------------------------------------------------------------------
=end

# Display a fatal error and quit. -----------------------------------
def fatalerror(err_msg)
  if ( $gTest_params["verbosity"] == "very_verbose" )
    #puts echo_config()
  end
  if ($gTest_params[:logfile])
    $fLOG.write("\nsubstitute.pl -> Fatal error: \n")
    $fLOG.write("#{err_msg}\n")
  end
  print "\n=========================================================\n"
  print "substitute.pl -> Fatal error: \n\n"
  print "     #{err_msg}\n"
  print "\n\n"
  print "substitute.pl -> Error and warning messages:\n\n"
  print "#{$ErrorBuffer}\n"
  exit() # Run stopped
end

# Optionally write text to buffer -----------------------------------
def stream_out(msg)
  if ($gTest_params[:verbosity] != "quiet")
    print msg
  end
  if ($gTest_params[:logfile])
    $fLOG.write(msg)
  end
end

# Write debug output ------------------------------------------------
def debug_out(debmsg)
  if $gDebug 
    print debmsg
  end
  if ($gTest_params[:logfile])
    $fLOG.write(debmsg)
  end
end

# Returns XML elements of HOT2000 file.
def get_elements_from_filename(filename)
   fH2KFile = File.new(filename, "r") 
   if fH2KFile == nil then
      fatalerror("Could not read #{filespec}.\n")
   end
  
   # Need to add error checking on failed open of existing file!
   $XMLdoc = Document.new(fH2KFile)

   # Close the HOT2000 file since content read
   fH2KFile.close()
  
   return $XMLdoc.elements()
end

# Search through the HOT2000 working file (copy of input file specified on command line) 
# and change values for settings defined in choice/options files. 
def processFile(filespec)

   # Load all XML elements from HOT2000 file
   h2kElements = get_elements_from_filename(filespec)
   
   $gChoiceOrder.each do |choiceEntry|
      if ( $gOptions[choiceEntry]["type"] == "internal" )
         choiceVal =  $gChoices[choiceEntry]
         tagHash = $gOptions[choiceEntry]["tags"]
         valHash = $gOptions[choiceEntry]["options"][choiceVal]["result"]
         
         for tagIndex in tagHash.keys()
            tag = tagHash[tagIndex]
            value = valHash[tagIndex]
            if ( value == "" )
               debug_out (">>>ERR on #{tag}\n")
               value = ""
            end
            
            # Replace existing values in H2K file ....................................
            if ( choiceEntry =~ /Opt-Location/ )
               if ( tag =~ /OPT-H2K-WTH-FILE/ )
                  # Weather file to use for HOT2000 run
                  locationText = "HouseFile/ProgramInformation/Weather"
                  # Check on existence of H2K weather file
                  if ( !File.exist?($run_path + "\\Dat" + "\\" + value) )
                     fatalerror("Weather file #{value} not found in folder !")
                  else
                     h2kElements[locationText].attributes["library"] = value
                  end
               elsif ( tag =~ /OPT-H2K-Region/ )
                  # Weather region to use for HOT2000 run
                  locationText = "HouseFile/ProgramInformation/Weather/Region"
                  h2kElements[locationText].attributes["code"] = value
               elsif ( tag =~ /OPT-H2K-Location/ )
                  # Weather location to use for HOT2000 run
                  locationText = "HouseFile/ProgramInformation/Weather/Location"
                  h2kElements[locationText].attributes["code"] = value
               elsif ( tag =~ /OPT-WEATHER-FILE/ ) # Do nothing
               elsif ( tag =~ /OPT-Latitude/ ) # Do nothing
               elsif ( tag =~ /OPT-Longitude/ ) # Do nothing
               else
                  fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
               end
               
            elsif ( choiceEntry =~ /Opt-FuelCost/ )
               # HOT2000 Fuel costing data selections
               
               
               
            elsif ( choiceEntry =~ /Opt-ACH/ )
               if ( tag =~ /Opt-ACH/ )
                  locationText = "HouseFile/House/NaturalAirInfiltration/Specifications/BlowerTest"
                  h2kElements[locationText].attributes["airChangeRate"] = value
               else
                  fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
               end
            
            elsif ( choiceEntry =~ /Opt-Ceilings/ )
               if ( tag =~ /Opt-Ceiling/ )
                  # Set Favourites code from library
                  # Have problems with this method! 
                  # NEEDS MORE WORK! ******************************
               elsif ( tag =~ /OPT-H2K-EffRValue/ )
                  # Change ALL existing ceiling codes to User Specified R-value
                  locationText = "HouseFile/House/Components/Ceiling/Construction/CeilingType"
                  XPath.each( $XMLdoc, locationText) do |element| 
                     element.text = "User specified"
                     element.attributes["rValue"] = value
                     if element.attributes["idref"] then
                        # Must delete attribute for User Specified!
                        element.delete_attribute("idref")
                     end
                  end
               else
                  fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
               end
               
            elsif ( choiceEntry =~ /Opt-MainWall/ )
               if ( tag =~ /Opt-MainWall-Bri/ )
                  # Set Favourites code from library
                  # Have problems with this method! 
                  # NEEDS MORE WORK! ******************************
               elsif ( tag =~ /Opt-MainWall-Vin/ )    # Do nothing
               elsif ( tag =~ /Opt-MainWall-Dry/ )    # Do nothing
               else
                  fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
               end

               elsif ( choiceEntry =~ /Opt-Opt-GenericWall_1Layer_definitions/ )
               if ( tag =~ /OPT-H2K-EffRValue/ )
                  # Change ALL existing wall codes to User Specified R-value
                  locationText = "HouseFile/House/Components/Wall/Construction/Type"
                  XPath.each( $XMLdoc, locationText) do |element| 
                     element.text = "User specified"
                     element.attributes["rValue"] = value
                     if element.attributes["idref"] then
                        # Must delete attribute for User Specified!
                        element.delete_attribute("idref")
                     end
                  end
               elsif ( tag =~ /Opt-GenInsulLayerInboard-a/ )   # Do nothing
               else
                  fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
               end
               
            elsif ( choiceEntry =~ /Opt-ExposedFloor/ )
               if ( tag =~ /Opt-ExposedFloor/ )
                  # Set Favourites code: Not working yet
                  # WORK ON!
               elsif ( tag =~ /OPT-H2K-EffRValue/ )
                  # Change ALL existing floor codes to User Specified R-value
                  locationText = "HouseFile/House/Components/Floor/Construction/Type"
                  XPath.each( $XMLdoc, locationText) do |element| 
                     element.text = "User specified"
                     element.attributes["rValue"] = value
                     if element.attributes["idref"] then
                        # Must delete attribute for User Specified!
                        element.delete_attribute("idref")
                     end
                  end
               elsif ( tag =~ /Opt-ExposedFloor-r/ )   # Do nothing
               else
                  fatalerror("Missing H2K #{choiceEntry} tag:#{tag}")
               end
               
               
            elsif ( choiceEntry =~ /Opt-CasementWindows/ )
               
               
            elsif ( choiceEntry =~ /Opt-BasementSlabInsulation/ )
               
               
            elsif ( choiceEntry =~ /Opt-BasementWallInsulation/ )
               
               
            elsif ( choiceEntry =~ /Opt-DWHRandSDHW / )
               
               
            elsif ( choiceEntry =~ /Opt-ElecLoadScale/ )
               
               
            elsif ( choiceEntry =~ /Opt-DHWLoadScale/ )
               
               
            elsif ( choiceEntry =~ /Opt-DHWSystem/ )
               
               
            elsif ( choiceEntry =~ /Opt-HVACSystem/ )
               
               
            elsif ( choiceEntry =~ /OPT-Furnace-Fan-Ctl/ )
               
               
            elsif ( choiceEntry =~ /Opt-Cooling-Spec/ )
               
               
            elsif ( choiceEntry =~ /Opt-HRVspec/ )
               
               
            elsif ( choiceEntry =~ /Opt-StandoffPV/ )
               
               
            else
               # Do nothing as we're ignoring all other tags!
               debug_out("Tag #{tag} ignored!\n")
            end
         end
      end
   end
   
   # Save changes to the XML doc in existing working H2K file (overwrite original)
   newXMLFile = File.open(filespec, "w")
   $XMLdoc.write(newXMLFile)
   newXMLFile.close
end

# Procedure to run HOT2000
def runsims( direction )

   $RotationAngle = $angles[direction]

   # Save rotation angle for reporting
   $gRotationAngle = $RotationAngle
  
   Dir.chdir( $run_path )
   debug_out ("\n\n Moved to path: #{Dir.getwd()}\n") 
   
   # Rotate the model, if necessary:
   #   Need to determine how to do this in HOT2000. The OnRotate() function in HOT2000 *interface*
   #   is not accessible from the CLI version of HOT2000 and hasn't been well tested.
   
   runThis = "HOT2000.exe"
   optionSwitch = "-inp"
   fileToLoad = "#{$WorkingSimFolderName}\\#{$h2kFileName}"
   
   if ( system(runThis, optionSwitch, fileToLoad) )      # Run HOT2000!
      stream_out( "The run was successful!\n" )
   else
      fatalerror( "Problems with the run! Return code: #{$?}\n" )
   end
   
   Dir.chdir( $master_path )
   
   # Save output files
   if ( ! Dir.exist?("sim-output") )
      if ( ! system("mkdir sim-output") )
         debug_out ("Could not create sim-output below #{$master_path}!\n")
      end
   else
      if ( File.exist?("sim-output\\Browse.rpt") )
         if ( ! system("del sim-output\\Browse.rpt") )    # Delete existing Browse.Rpt
            debug_out ("Could not delete existing Browse.rpt fil in sim-output!\n")
         end
      end
   end
   
   # Copy simulation results to sim-output folder in master (for ERS number)
   # Note that most of the output is contained in the HOT2000 file in XML!
   if ( Dir.exist?("sim-output") )
      system("copy #{$run_path}\\Browse.rpt .\\sim-output\\")
   end
end

# Post-process results
def postprocess( scaleData )
  
   # Load all XML elements from HOT2000 file (post-run results now available)
   h2kPostElements = get_elements_from_filename( $gWorkingModelFile )

   $Locale = $gChoices["Opt-Location"] 
   if ( $Locale =~ /London/ || $Locale =~ /Windsor/ || $Locale =~ /ThunderBay/ )
      $Locale = "Toronto"
   end
  
   if ( $gCustomCostAdjustment ) 
      $gRegionalCostAdj = $gCostAdjustmentFactor
   else
      $gRegionalCostAdj = $RegionalCostFactors[$Locale]
   end
   
   monthArray = [ "january", "february", "march", "april", "may", "june", 
                  "july", "august", "september", "october", "november", "december" ]
   
   locationText = "HouseFile/AllResults/Results/Annual/Consumption"
   $gAvgEnergy_Total += h2kPostElements[locationText].attributes["total"].to_f * scaleData
   
   locationText = "HouseFile/AllResults/Results/Annual/Consumption/Electrical"
   $gAvgElecCons_KWh += h2kPostElements[locationText].attributes["total"].to_f * scaleData
   
   
   
   

=begin  
  if ( $PVsize !~ /SizedPV/ ){
    
    # Use spec'd PV sizes. This only works for NoPV. 
    $gSimResults{"PV production::AnnualTotal"}= 0.0 ; #-1.0*$gExtOptions{"Opt-StandoffPV"}{"options"}{$PVsize}{"ext-result"}{"production-elec-perKW"}; 
    $PVArrayCost = 0.0 ;
	
  } else {
    # Size PV according to user specification, to max, or to size required to reach Net-Zero. 
    
    # User-specified PV size (format is 'SizedPV|XkW', PV will be sized to X kW'.
    if ( $gExtraDataSpecd{"Opt-StandoffPV"} =~ /kW/ ){
      
      $PVArraySized = $gExtraDataSpecd{"Opt-StandoffPV"};     
      $PVArraySized =~ s/kW//g; 
      
      my $PVUnitOutput = $gOptions{"Opt-StandoffPV"}{"options"}{"SizedPV"}{"ext-result"}{"production-elec-perKW"};
      my $PVUnitCost   = $gOptions{"Opt-StandoffPV"}{"options"}{"SizedPV"}{"cost"};
      
      $PVArrayCost = $PVUnitCost * $PVArraySized ; 
      
      $gSimResults{"PV production::AnnualTotal"} = -1.0 * $PVUnitOutput * $PVArraySized; 
            
      # JTB May 12/2015: Removed $PVsize, replaced with "SizedPV" to resolve growing string $PVsize
	  #                  when either seasonal runs or ERS mode used (multiple passes of this code).
	  $PVsize = "spec'd SizedPV | $PVArraySized kW";
    
    } else { 
        
        # USER Hasn't specified PV size, Size PV to attempt to get to net-zero. 
        # First, compute the home's total energy requirement. 
    
        my $prePVEnergy = 0;

        # gSimResults contains all sorts of data. Filter by annual energy consumption (rows containing AnnualTotal).
        foreach my $token ( sort keys %gSimResults ){
          if ( $token =~ /AnnualTotal/  && $token =~ /all_fuels/ ){ 
            my $value = $gSimResults{$token};
            $prePVEnergy += $value; 
          }    
        }

        if ( $prePVEnergy > 0 ){
        
          # This should always be the case!
          
          my $PVUnitOutput = $gOptions{"Opt-StandoffPV"}{"options"}{$PVsize}{"ext-result"}{"production-elec-perKW"};
          my $PVUnitCost   = $gOptions{"Opt-StandoffPV"}{"options"}{$PVsize}{"cost"};
         
         $PVArraySized = $prePVEnergy / $PVUnitOutput ; # KW Capacity
          my $PVmultiplier = 1. ; 
          if ( $PVArraySized > 14. ) { $PVmultiplier = 2. ; }
          
          $PVArrayCost  = $PVArraySized * $PVUnitCost * $PVmultiplier;
                    
          $PVsize = " scaled: ".eval(round1d($PVArraySized))." kW" ;

          $gSimResults{"PV production::AnnualTotal"}=-1.0*$PVUnitOutput*$PVArraySized; 
        
        } else {
          # House is already energy positive, no PV needed. Shouldn't happen!
          $PVsize = "0.0 kW" ;
          $PVArrayCost  = 0. ;
        }
        # Degbug: How big is the sized array?
        debug_out (" PV array is $PVsize  ...\n"); 
        
    }  
  }
  $gChoices{"Opt-StandoffPV"}=$PVsize;
  $gOptions{"Opt-StandoffPV"}{"options"}{$PVsize}{"cost"} = $PVArrayCost;
=end


=begin
  stream_out("\n\n Energy Consumption: \n\n") ; 

  my $gTotalEnergy = 0;

  foreach my $token ( sort keys %gSimResults ){
    if ( $token =~ /AnnualTotal/ && $token =~ /all_fuels/){
        my $value = $gSimResults{$token};
		$gTotalEnergy += $value; 
        stream_out ( "  + $value ( $token, GJ ) \n");
    }
  }
  
  stream_out ( " --------------------------------------------------------\n");
  stream_out ( "    $gTotalEnergy ( Total energy, GJ ) \n");


  # Save Energy consumption for later
   
  $gEnergyPV = defined( $gSimResults{"PV production::AnnualTotal"} ) ? 
                         $gSimResults{"PV production::AnnualTotal"} : 0 ;  

  #$gEnergySDHW = defined( $gSimResults{"SDHW production"} ) ? 
  #                       $gSimResults{"SDHW production"} : 0 ;  

  $gEnergyHeating = defined( $gSimResults{"total_fuel_use/test/all_fuels/space_heating/energy_content::AnnualTotal"} ) ? 
                         $gSimResults{"total_fuel_use/test/all_fuels/space_heating/energy_content::AnnualTotal"} : 0 ;  

  $gEnergyCooling = defined( $gSimResults{"total_fuel_use/test/all_fuels/space_cooling/energy_content::AnnualTotal"} ) ? 
                         $gSimResults{"total_fuel_use/test/all_fuels/space_cooling/energy_content::AnnualTotal"} : 0 ;  

  $gEnergyVentilation = defined( $gSimResults{"total_fuel_use/test/all_fuels/ventilation/energy_content::AnnualTotal"} ) ? 
                         $gSimResults{"total_fuel_use/test/all_fuels/ventilation/energy_content::AnnualTotal"} : 0 ;  

  $gEnergyWaterHeating = defined( $gSimResults{"total_fuel_use/test/all_fuels/water_heating/energy_content::AnnualTotal"} ) ? 
                         $gSimResults{"total_fuel_use/test/all_fuels/water_heating/energy_content::AnnualTotal"} : 0 ;  

  $gEnergyEquipment = defined( $gSimResults{"total_fuel_use/test/all_fuels/equipment/energy_content::AnnualTotal"} ) ? 
                         $gSimResults{"total_fuel_use/test/all_fuels/equipment/energy_content::AnnualTotal"} : 0 ;  

  $gEnergyElec  =  defined($gSimResults{"total_fuel_use/electricity/all_end_uses/quantity::Total_Average"} ) ? 
                         $gSimResults{"total_fuel_use/electricity/all_end_uses/quantity::Total_Average"} * $FracOfYear : 0 ;  
  
  $gEnergyGas   = defined($gSimResults{"total_fuel_use/natural_gas/all_end_uses/quantity::Total_Average"} ) ? 
                         $gSimResults{"total_fuel_use/natural_gas/all_end_uses/quantity::Total_Average"} * $FracOfYear : 0 ;  
  
  $gEnergyOil   = defined($gSimResults{"total_fuel_use/oil/all_end_uses/quantity::Total_Average"} ) ? 
                         $gSimResults{"total_fuel_use/oil/all_end_uses/quantity::Total_Average"}  * $FracOfYear : 0 ;  

  $gEnergyWood  = defined($gSimResults{"total_fuel_use/mixed_wood/all_end_uses/quantity::Total_Average"} ) ? 
                         $gSimResults{"total_fuel_use/mixed_wood/all_end_uses/quantity::Total_Average"} * $FracOfYear : 0 ;  	
  $gEnergyPellet = defined($gSimResults{"total_fuel_use/wood_pellets/all_end_uses/quantity::Total_Average"} ) ? 
                         $gSimResults{"total_fuel_use/wood_pellets/all_end_uses/quantity::Total_Average"} * $FracOfYear : 0 ;  
  $gEnergyHardWood = defined( $gSimResults{"total_fuel_use/hard_wood/all_end_uses/quantity::Total_Average"} ) ? 
                         $gSimResults{"total_fuel_use/hard_wood/all_end_uses/quantity::Total_Average"} * $FracOfYear : 0 ;  
  $gEnergyMixedWood = defined( $gSimResults{"total_fuel_use/mixed_wood/all_end_uses/quantity::Total_Average"} ) ? 
                         $gSimResults{"total_fuel_use/mixed_wood/all_end_uses/quantity::Total_Average"} * $FracOfYear : 0 ;  
  $gEnergySoftWood = defined( $gSimResults{"total_fuel_use/soft_wood/all_end_uses/quantity::Total_Average"} ) ? 
                         $gSimResults{"total_fuel_use/soft_wood/all_end_uses/quantity::Total_Average"} * $FracOfYear : 0 ;  
  
  # New variables required for ERS calculation
  $gEnergyHeatingElec = defined( $gSimResults{"total_fuel_use/test/electricity/space_heating/energy_content::AnnualTotal"} ) ? 
                         $gSimResults{"total_fuel_use/test/electricity/space_heating/energy_content::AnnualTotal"} : 0 ;  
						 
  $gEnergyVentElec = defined( $gSimResults{"total_fuel_use/test/electricity/ventilation/energy_content::AnnualTotal"} ) ? 
                         $gSimResults{"total_fuel_use/test/electricity/ventilation/energy_content::AnnualTotal"} : 0 ;  

  $gEnergyHeatingFossil = defined( $gSimResults{"total_fuel_use/test/fossil_fuels/space_heating/energy_content::AnnualTotal"} ) ? 
                         $gSimResults{"total_fuel_use/test/fossil_fuels/space_heating/energy_content::AnnualTotal"} : 0 ;  
						 
  $gEnergyWaterHeatingElec = defined( $gSimResults{"total_fuel_use/test/electricity/water_heating/energy_content::AnnualTotal"} ) ? 
                         $gSimResults{"total_fuel_use/test/electricity/water_heating/energy_content::AnnualTotal"} : 0 ;  

  $gEnergyWaterHeatingFossil = defined( $gSimResults{"total_fuel_use/test/fossil_fuels/water_heating/energy_content::AnnualTotal"} ) ? 
                         $gSimResults{"total_fuel_use/test/fossil_fuels/water_heating/energy_content::AnnualTotal"} : 0 ;  
  
  $gEnergyTotalWood = $gEnergyHardWood + $gEnergyMixedWood + $gEnergySoftWood + $gEnergyPellet;

  $gAmtOil = defined( $gSimResults{"total_fuel_use/oil/all_end_uses/quantity::Total_Average"} ) ? 
                         $gSimResults{"total_fuel_use/oil/all_end_uses/quantity::Total_Average"} * $FracOfYear : 0 ;  

						 
  my $PVRevenue = $gEnergyPV * 1e06 / 3600. *$PVTarrifDollarsPerkWh; 
  
  my $TotalBill = $TotalElecBill+$TotalGasBill+$TotalOilBill+$TotalPropaneBill+$TotalWoodBill+$TotalPelletBill; 
  my $NetBill   = $TotalBill-$PVRevenue ;
  
  stream_out("\n\n Energy Cost (not including credit for PV, direction $gRotationAngle ): \n\n") ; 
  
  stream_out("  + \$ ".round($TotalElecBill)." (Electricity)\n");
  stream_out("  + \$ ".round($TotalGasBill)." (Natural Gas)\n");
  stream_out("  + \$ ".round($TotalOilBill)." (Oil)\n");
  stream_out("  + \$ ".round($TotalPropaneBill)." (Propane)\n");
  stream_out("  + \$ ".round($TotalWoodBill)." (Wood)\n");
  stream_out("  + \$ ".round($TotalPelletBill)." (Pellet)\n");
  
  stream_out ( " --------------------------------------------------------\n");
  stream_out ( "    \$ ".round($TotalBill) ." (All utilities).\n"); 

  stream_out ( "\n") ;

  stream_out ( "  - \$ ".round($PVRevenue )." (PV revenue, ". eval($gEnergyPV * 1e06 / 3600.). " kWh at \$ $PVTarrifDollarsPerkWh / kWh)\n"); 
  stream_out ( " --------------------------------------------------------\n");
  stream_out ( "    \$ ".round($NetBill) ." (Net utility costs).\n"); 
  
  stream_out ( "\n\n") ; 
  
  # Update global parameters for use in summary. Scalar scaleData averages across orientations
  # when multiple orientations run. When seasonal run in effect these parameters are cumulative. 
  $gAvgCost_NatGas    += $TotalGasBill  * scaleData; 
  $gAvgCost_Electr    += $TotalElecBill * scaleData;  
  $gAvgCost_Propane   += $TotalPropaneBill * scaleData; 
  $gAvgCost_Oil       += $TotalOilBill * scaleData; 
  $gAvgCost_Wood      += $TotalWoodBill * scaleData; 
  $gAvgCost_Pellet    += $TotalPelletBill * scaleData; 
   
  $gAvgEnergy_Total   += $gTotalEnergy  * scaleData; 
  $gAvgNGasCons_m3    += $gEnergyGas * 8760. * 60. * 60.  * scaleData ; 
  $gAvgOilCons_l      += $gEnergyOil * 8760. * 60. * 60.  * scaleData ;  
  $gAvgPelletCons_tonne+= $gEnergyPellet * 8760. * 60. * 60.  * scaleData ;
  
  $gAvgElecCons_KWh   += $gEnergyElec * 8760. * 60. * 60. * scaleData ; 
  
  # Shouldn't be cumulative for seasonal runs or orientation runs!!
  $gAvgPVOutput_kWh   = -1.0 * $gEnergyPV * 1e06 / 3600. * scaleData;  
  
  $gAvgEnergyHeatingGJ      += $gEnergyHeating         * scaleData; 
  $gAvgEnergyCoolingGJ      += $gEnergyCooling         * scaleData; 
  $gAvgEnergyVentilationGJ  += $gEnergyVentilation     * scaleData; 
  $gAvgEnergyWaterHeatingGJ += $gEnergyWaterHeating    * scaleData; 
  $gAvgEnergyEquipmentGJ    += $gEnergyEquipment       * scaleData; 

  # Added for ERS calculation
  $gAvgEnergyHeatingElec        += $gEnergyHeatingElec        * scaleData;		# GJ
  $gAvgEnergyVentElec           += $gEnergyVentElec           * scaleData;		# GJ
  $gAvgEnergyHeatingFossil      += $gEnergyHeatingFossil      * scaleData;		# GJ
  $gAvgEnergyWaterHeatingElec   += $gEnergyWaterHeatingElec   * scaleData;		# GJ
  $gAvgEnergyWaterHeatingFossil += $gEnergyWaterHeatingFossil * scaleData;		# GJ

  stream_out("\n\n Energy Use (not including credit for PV, direction $gRotationAngle ): \n\n") ; 
  
  stream_out("  - ".round($gEnergyElec* 8760. * 60. * 60.)." (Electricity, kWh)\n");
  stream_out("  - ".round($gEnergyGas* 8760. * 60. * 60.)." (Natural Gas, m3)\n");
  stream_out("  - ".round($gEnergyOil* 8760. * 60. * 60.)." (Oil, l)\n");
  stream_out("  - ".round($gEnergyWood* 8760. * 60. * 60.)." (Wood, cord)\n");
  stream_out("  - ".round($gEnergyPellet* 8760. * 60. * 60.)." (Pellet, tonnes)\n");
  
  stream_out ("> SCALE scaleData \n"); 
=end


=begin  
  # Estimate total cost of upgrades

  $gTotalCost = 0;         
  
  stream_out ("\n\n Estimated costs in $Locale (x$gRegionalCostAdj Ottawa costs) : \n\n");

  foreach my  $attribute ( sort keys %gChoices ){
    
    my $choice = $gChoices{$attribute}; 
    my $cost; 
    $cost  = $gOptions{$attribute}{"options"}{$choice}{"cost"} * $gRegionalCostAdj;
    $gTotalCost += $cost ;

    stream_out( " +  ".round($cost)." ( $attribute : $choice ) \n");
    
  }
  stream_out ( " - ".round($gIncBaseCosts * $gRegionalCostAdj)." (Base costs for windows)  \n"); 
  stream_out ( " --------------------------------------------------------\n");
  stream_out ( " =   ".round($gTotalCost-$gIncBaseCosts* $gRegionalCostAdj )." ( Total incremental cost ) \n\n");

  
  stream_out ( " ( Unadjusted upgrade costs: \$".eval( $gTotalCost  /  $gRegionalCostAdj )." )\n\n");
  
  if ( $gERSCalcMode && $gERSNum > 0 ) {
	my $tmpval = round($gERSNum * 10) / 10.;
	stream_out(" ERS value: ".$tmpval."\n");
  
    $tmpval = round($gERSNum_noVent * 10) / 10.;
    stream_out(" ERS value_noVent:   ".$tmpval."\n\n");
  }
  
  chdir($gMasterPath);
  my $fileexists; 
=end

end  # End of postprocess

=begin rdoc
 END OF METHODS
=end

$gChoiceOrder = Array.new

$master_path = Dir.getwd()   #Main path where this script was started and considered master

$gTest_params[:verbosity] = "quiet"
$gTest_params[:logfile]   = $master_path + "\\SubstitutePL-log.txt"

$fLOG = File.new($gTest_params[:logfile], mode="w") 
if $fLOG == nil then
   fatalerror("Could not open #{$gTest_params["logfile"]}.\n")
end

                     
#-------------------------------------------------------------------
# Help text. Dumped if help requested, or if no arguments supplied.
#-------------------------------------------------------------------
$help_msg = "

 substitute.pl: 
 
 This script searches through a suite of model input files 
 and substitutes values from a specified input file. 
 
 use: ./substitute.pl --options options.opt
                      --choices choices.options
                      --base_folder BaseFolderName
                      
 example use for optimization work:
 
  ./substitute.pl -c optimization-choices.opt
                  -o optimization-options.opt
                  -b BaseFolderName
                  -v(v)
      
"

# dump help text, if no argument given
if ARGV.empty? then
  puts $help_msg
  exit()
end

=begin rdoc
Command line argument processing ------------------------------
Using Ruby's "optparse" for command line argument processing (http://ruby-doc.org/stdlib-2.2.0/libdoc/optparse/rdoc/OptionParser.html)!
=end   
$cmdlineopts = Hash.new

optparse = OptionParser.new do |opts|
  
   opts.banner = $help_msg

   opts.on("-h", "--help", "Show help message") do
      puts opts
      exit()
   end
  
   opts.on("-v", "--verbose", "Run verbosely") do 
      $cmdlineopts[:verbose] = true
      $gTest_params[:verbosity] = "verbose"
   end

   opts.on("-vv", "--very_verbose", "Run very verbosely") do
      $cmdlineopts[:v_verbose] = true
      $gTest_params[:verbosity] = "very_verbose"
   end
    
   opts.on("-vvv", "--very_very_verbose", "Run very very verbosely") do
      $cmdlineopts[:vv_verbose] = true
      $gTest_params[:verbosity] = "very_very_verbose"
      $gDebug = true
   end

   opts.on("-c", "--choices FILE", "Specified choice file (mandatory)") do |c|
      $cmdlineopts[:choices] = c
      $gChoiceFile = c
      if ( !File.exist?($gChoiceFile) )
         fatalerror("Valid path to choice file must be specified with --choices (or -c) option!")
      end
   end
  
   opts.on("-o", "--options FILE", "Specified options file (mandatory)") do |o|
      $cmdlineopts[:options] = o
      $gOptionFile = o
      if ( !File.exist?($gOptionFile) )
         fatalerror("Valid path to option file must be specified with --options (or -o) option!")
      end
   end

   # This may not be required for HOT2000! ***********************************
   opts.on("-b", "--base_model FILE", "Specified base file (mandatory)") do |b|
      $cmdlineopts[:base_model] = b
      $gBaseModelFile = b
      if !$gBaseModelFile
         fatalerror("Base folder file name missing after --base_folder (or -b) option!")
      end
      if (! File.exist?($gBaseModelFile) ) 
         fatalerror("Base file does not exist - create file first!")
      end
   end
 
end

optparse.parse!    # Note: parse! strips all arguments from ARGV and parse does not

if $gDebug 
  p $cmdlineopts
end

($run_path, $h2kFileName) = File.split( $gBaseModelFile )
$run_path.sub!(/\\User/i, '')     # Strip "User" (any case) from $run_path

stream_out (" > substitute-h2k.rb path: #{$master_path} \n")
stream_out (" >               ChoiceFile: #{$gChoiceFile} \n")
stream_out (" >               OptionFile: #{$gOptionFile} \n")
stream_out (" >               Base model: #{$gBaseModelFile} \n")
stream_out (" >               HOT2000 run folder: #{$run_path} n")

=begin rdoc
 Parse option file. This file defines the available choices and costs
 that substitute-h2k.rb can pick from 
=end

stream_out("\n\nReading #{$gOptionFile}...")
fOPTIONS = File.new($gOptionFile, mode="r") 
if fOPTIONS == nil then
   fatalerror("Could not read #{$gOptionFile}.\n")
end

$linecount = 0
$currentAttributeName =""
$AttributeOpen = 0
$ExternalAttributeOpen = 0
$ParametersOpen = 0 

$gParameters = Hash.new

# Parse the option file. 

while !fOPTIONS.eof? do

   $line = fOPTIONS.readline
   $line.strip!              # Removes leading and trailing whitespace
   $line.gsub!(/\!.*$/, '')  # Removes comments
   $line.gsub!(/\s*/, '')    # Removes mid-line white space
   $linecount += 1

   if ( $line !~ /^\s*$/ )   # Not an empty line!
      lineTokenValue = $line.split('=')
      $token = lineTokenValue[0]
      $value = lineTokenValue[1]

      # Allow value to contain spaces when "~" character used in options file 
      #(e.g. *option:retro_GSHP:value:2 = *gshp~../hvac/heatx_v1.gshp)
      if ($value) 
         $value.gsub!(/~/, ' ')
      end

      # The file contains 'attributes that are either internal (evaluated by HOT2000)
      # or external (computed elsewhere and post-processed). 
      
      # Open up a new attribute    
      if ( $token =~ /^\*attribute:start/ )
         $AttributeOpen = 1
      end

      # Open up a new external attribute    
      if ( $token =~ /^\*ext-attribute:start/ )
         $ExternalAttributeOpen = 1
      end

      # Open up parameter block
      if ( $token =~ /^\*ext-parameters:start/ )
         $ParametersOpen = 1
      end

      # Parse parameters. 
      if ( $ParametersOpen == 1 )
         # Read parameters. Format: 
         #  *param:NAME = VALUE 
         if ( $token =~ /^\*param/ )
            $token.gsub!(/\*param:/, '')
            $gParameters[$token] = $value
         end
      end
    
      # Parse attribute contents Name/Tag/Option(s)
      if ( $AttributeOpen || $ExternalAttributeOpen ) 
         
         if ( $token =~ /^\*attribute:name/ )
         
            $currentAttributeName = $value
            if ( $ExternalAttributeOpen == 1 ) then
               $gOptions[$currentAttributeName]["type"] = "external"
            else
               $gOptions[$currentAttributeName]["type"] = "internal"
            end
         
            $gOptions[$currentAttributeName]["default"]["defined"] = 0
        
         elsif ( $token =~ /^\*attribute:tag/ )
            
            arrResult = $token.split(':')
            $TagIndex = arrResult[2]
            $gOptions[$currentAttributeName]["tags"][$TagIndex] = $value
            
         elsif ( $token =~ /^\*attribute:default/ )   # Possibly define default value. 
         
            $gOptions[$currentAttributeName]["default"]["defined"] = 1
            $gOptions[$currentAttributeName]["default"]["value"] = $value

         elsif ( $token =~ /^\*option/ )
            # Format: 
            #  *Option:NAME:MetaType:Index or 
            #  *Option[CONDITIONS]:NAME:MetaType:Index or    
            # MetaType is:
            #  - cost
            #  - value 
            #  - alias (for Dakota)
            #  - production-elec
            #  - production-sh
            #  - production-dhw
            #  - WindowParams   
            
            $breakToken = $token.split(':')
            $condition_string = ""
            
            # Check option keyword to see if it has specific conditions
            # format is *option[condition1>value1;condition2>value2 ...] 
            
            if ( $breakToken[0] =~ /\[.+\]/ )
               $condition_string = $breakToken[0]
               $condition_string.gsub!(/\*option\[/, '')
               $condition_string.gsub!(/\]/, '') 
               $condition_string.gsub!(/>/, '=') 
            else
               $condition_string = "all"
            end

            $OptionName = $breakToken[1]
            $DataType   = $breakToken[2]
            
            $ValueIndex = ""
            $CostType = ""
            
            # Assign values 
            
            if ( $DataType =~ /value/ )
               $ValueIndex = $breakToken[3]
               $gOptions[$currentAttributeName]["options"][$OptionName]["values"][$ValueIndex]["conditions"][$condition_string] = $value
            end
            
            if ( $DataType =~ /cost/ )
               $CostType = $breakToken[3]
               $gOptions[$currentAttributeName]["options"][$OptionName]["cost-type"] = $CostType
               $gOptions[$currentAttributeName]["options"][$OptionName]["cost"] = $value
            end
            
            # Window data processing for generic window definitions:
            if ( $DataType =~ /WindowParams/ )
               stream_out ("\nProcessing window data for #{$currentAttributeName} / #{$OptionName}  \n")
               $Param = $breakToken[3]
               $GenericWindowParams[$OptionName][$Param] = $value
               $GenericWindowParamsDefined = 1
            end
            
            # External entities...
            if ( $DataType =~ /production/ )
               if ( $DataType =~ /cost/ )
                  $CostType = $breakToken[3]
               end
               $gOptions[$currentAttributeName]["options"][$OptionName][$DataType]["conditions"][$condition_string] = $value
            end
            
         end   # end processing all attribute types (if-elsif block)
      
      end  #end of processing attributes
    
      # Close attribute and append contents to global options array
      if ( $token =~ /^\*attribute:end/ || $token =~ /^\*ext-attribute:end/)
         
         $AttributeOpen = 0
         
         # Store options 
         debug_out ( "========== #{$currentAttributeName} ===========\n");
         debug_out ( "Storing data for #{$currentAttributeName}: \n" );
         
         $OptHash = $gOptions[$currentAttributeName]["options"] 
         
         for $optionIndex in $OptHash.keys()
            debug_out( "    -> #{$optionIndex} \n" )
            $cost_type = $gOptions[$currentAttributeName]["options"][$optionIndex]["cost-type"]
            $cost = $gOptions[$currentAttributeName]["options"][$optionIndex]["cost"]
            $ValHash = $gOptions[$currentAttributeName]["options"][$optionIndex]["values"]
            
            for $valueIndex in $ValHash.keys()
               $CondHash = $gOptions[$currentAttributeName]["options"][$optionIndex]["values"][$valueIndex]["conditions"]
               
               for $conditions in $CondHash.keys()
                  $tag = $gOptions[$currentAttributeName]["tags"][$valueIndex]
                  $value = $gOptions[$currentAttributeName]["options"][$optionIndex]["values"][$valueIndex]["conditions"][$conditions]
                  debug_out( "           - #{$tag} -> #{$value} [valid: #{$conditions} ]   \n")
               end
               
            end

            $ExtEnergyHash = $gOptions[$currentAttributeName]["options"][$optionIndex] 
            for $ExtEnergyType in $ExtEnergyHash.keys()
               if ( $ExtEnergyType =~ /production/ )
                  $CondHash = $gOptions[$currentAttributeName]["options"][$optionIndex][$ExtEnergyType]["conditions"]
                  for $conditions in $CondHash.keys()
                     $ExtEnergyCredit = $gOptions[$currentAttributeName]["options"][$optionIndex][$ExtEnergyType]["conditions"][$conditions] 
                     debug_out ("              - credit:(#{$ExtEnergyType}) #{$ExtEnergyCredit} [valid: #{$conditions} ] \n")
                  end
               end
            end
         end
      end
      
      if ( $token =~ /\*ext-parameters:end/ )
         $ParametersOpen = 0
      end
      
   end   # Empty line check
      
end   #read next line

fOPTIONS.close
stream_out ("...done.\n")


=begin rdoc
 Parse configuration (choice) file. 
=end

stream_out("\n\nReading #{$gChoiceFile}...\n")
fCHOICES = File.new($gChoiceFile, mode="r") 
if fCHOICES == nil then
   fatalerror("Could not read #{$gChoiceFile}.\n")
end

$linecount = 0

while !fCHOICES.eof? do

   $line = fCHOICES.readline
   $line.strip!              # Removes leading and trailing whitespace
   $line.gsub!(/\!.*$/, '')  # Removes comments
   $line.gsub!(/\s*/, '')    # Removes mid-line white space
   $linecount += 1
   
   debug_out ("  Line: #{$linecount} >#{$line}<\n")
   
   if ( $line !~ /^\s*$/ )
      
      lineTokenValue = $line.split(':')
      attribute = lineTokenValue[0]
      value = lineTokenValue[1]
    
      # Parse config commands
      if ( attribute =~ /^GOconfig_/ )
         attribute.gsub!( /^GOconfig_/, '')
         if ( attribute =~ /rotate/ )
            $gRotate = value
            $gChoices["GOconfig_rotate"] = value
            stream_out ("::: #{attribute} -> #{value} \n")
            $gChoiceOrder.push("GOconfig_rotate")
         end 
         if ( attribute =~ /step/ )
            $gGOStep = value
            $gArchGOChoiceFile = 1
         end 
      else
         extradata = value
         if ( value =~ /\|/ )
            value.gsub!(/\|.*$/, '') 
            extradata.gsub!(/^.*\|/, '') 
            extradata.gsub!(/^.*\|/, '') 
         else
            extradata = ""
         end
         
         $gChoices[attribute] = value
         
         stream_out ("::: #{attribute} -> #{value} \n")
         
         # Additional data that may be used to attribute the choices. 
         $gExtraDataSpecd[attribute] = extradata
         
         # Save order of choices to make sure we apply them correctly. 
         $gChoiceOrder.push(attribute)
      end
   end
end

fCHOICES.close
stream_out ("...done.\n")

$gExtOptions = Hash.new(&$blk)
# Report 
$allok = true

debug_out("-----------------------------------\n")
debug_out("-----------------------------------\n")
debug_out("Parsing parameters ...\n")

$gCustomCostAdjustment = 0
$gCostAdjustmentFactor = 0

# Possibly overwrite internal parameters with user-specified parameters
$gParameters.each do |parameter, value1|
   if ( parameter =~ /CostAdjustmentFactor/  )
      $gCostAdjustmentFactor = value1
      $gCustomCostAdjustment = 1
   end
  
   if ( parameter =~ /PVTarrifDollarsPerkWh/ )
      $PVTarrifDollarsPerkWh = value1.to_f
   end
  
   if ( parameter =~ /BaseUpgradeCost/ )
      $gIncBaseCosts = value1.to_f
   end
  
   if ( parameter =~ /BaseUtilitiesCost/ )
      $gUtilityBaseCost = value1.to_f
   end
end

=begin rdoc
 Validate choices and options. 
=end
stream_out(" Validating choices and options...\n");  

# Search through optons and determine if they are usedin Choices file (warn if not). 
$gOptions.each do |option, ignore|
    stream_out ("> option : #{option} ?\n"); 
    if ( !$gChoices.has_key?(option)  )
      $ThisError = "\nWARNING: Option #{option} found in options file (#{$gOptionFile}) \n"
      $ThisError += "         was not specified in Choices file (#{$gChoiceFile}) \n"
      $ErrorBuffer += $ThisError
      stream_out ( $ThisError )
   
      if ( ! $gOptions[option]["default"]["defined"]  )
         $ThisError = "\nERROR: No default value for option #{option} defined in \n"
         $ThisError += "       Options file (#{$gOptionFile})\n"
         $ErrorBuffer += $ThisError
         fatalerror ( $ThisError )
      else
         # Add default value. 
         $gChoices[option] = $gOptions[option]["default"]["value"]
         # Apply them at the end. 
         $gChoiceOrder.push(option)
         
         $ThisError = "\n         Using default value (#{$gChoices[option]}) \n"
         $ErrorBuffer += $ThisError
         stream_out ( $ThisError )
      end
    end
    $ThisError = ""
end

# Search through choices and determine if they match options in the Options file (error if not). 
$gChoices.each do |attrib, choice|
   debug_out ( "\n ======================== #{attrib} ============================\n")
   debug_out ( "Choosing #{attrib} -> #{choice} \n")
    
   # Is attribute used in choices file defined in options ?
   if ( !$gOptions.has_key?(attrib) )
      $ThisError  = "\nERROR: Attribute #{attrib} appears in choice file (#{$gChoiceFile}), \n"
      $ThisError +=  "       but can't be found in options file (#{$gOptionFile})\n"
      $ErrorBuffer += $ThisError
      stream_out( $ThisError )
      $allok = false
   else
      debug_out ( "   - found $gOptions[\"#{attrib}\"] \n")
   end
  
   # Is choice in options?
   if ( ! $gOptions[attrib]["options"].has_key?(choice) )
      $allok = false
      
      if ( !$allok )
         $ThisError  = "\nERROR: Choice #{choice} (for attribute #{attrib}, defined \n"
         $ThisError +=   "       in choice file #{$gChoiceFile}), is not defined \n"
         $ThisError +=   "       in options file (#{$gOptionFile})\n"
         $ErrorBuffer += $ThisError
         stream_out( $ThisError )
      else
         debug_out ( "   - found $gOptions[\"#{attribute}\"][\"options\"][\"#{choice}\"} \n")
      end
   end
   
   if ( !$allok )
      fatalerror ( "" )
   end
end

=begin rdoc
 Process conditions. 
=end

$gChoices.each do |attrib1, choice|

   valHash = $gOptions[attrib1]["options"][choice]["values"] 
   
   if ( !valHash.empty? )
     
      for valueIndex in valHash.keys()
         condHash = $gOptions[attrib1]["options"][choice]["values"][valueIndex]["conditions"] 
     
         # Check for 'all' conditions
         $ValidConditionFound = 0
        
         if ( condHash.has_key?("all") ) 
            debug_out ("   - VALINDEX: #{valueIndex} : found valid condition: \"all\" !\n")
            $gOptions[attrib1]["options"][choice]["result"][valueIndex] = condHash["all"]
            $ValidConditionFound = 1
         else
            # Loop through hash 
            for conditions in condHash.keys()
               if (conditions !~ /else/ ) 
                  debug_out ( " >>>>> Testing |#{conditions}| <<<\n" )
                  valid_condition = 1
                  conditionArray = conditions.split(';')
                  conditionArray.each do |condition|
                     debug_out ("      #{condition} \n")
                     testArray = condition.split('=')
                     testAttribute = testArray[0]
                     testValueList = testArray[1]
                     if ( testValueList == "" )
                        testValueList = "XXXX"
                     end
                     testValueArray = testValueList.split('|')
                     thesevalsmatch = 0
                     testValueArray.each do |testValue|
                        if ( $gChoices[testAttribute] =~ /testValue/ )
                           thesevalsmatch = 1
                        end
                        debug_out ("       \##{$gChoices[testAttribute]} = #{$gChoices[testAttribute]} / #{testValue} / -> #{thesevalsmatch} \n"); 
                     end
                     if ( thesevalsmatch == 0 )
                        valid_condition = 0
                     end
                  end
                  if ( valid_condition == 1 )
                     $gOptions[attrib1]["options"][choice]["result"][valueIndex]  = condHash[conditions]
                     $ValidConditionFound = 1
                     debug_out ("   - VALINDEX: #{valueIndex} : found valid condition: \"#{conditions}\" !\n")
                  end
               end
            end
         end
         # Check if else condition exists. 
         if ( $ValidConditionFound == 0 )
            debug_out ("Looking for else!: #{condHash["else"]}<\n" )
            if ( condHash.has_key?("else") )
               $gOptions[attrib1]["options"][choice]["result"][valueIndex] = condHash["else"]
               $ValidConditionFound = 1
               debug_out ("   - VALINDEX: #{valueIndex} : found valid condition: \"else\" !\n")
            end
         end
         
         if ( $ValidConditionFound == 0 )
            $ThisError  = "\nERROR: No valid conditions were defined for #{attrib1} \n"
            $ThisError +=   "       in options file (#{$gOptionFile}). Choices must match one \n"
            $ThisError +=   "       of the following:\n"
            for conditions in condHash.keys()
               $ThisError +=   "            -> #{conditions} \n"
            end
            
            $ErrorBuffer += $ThisError
            stream_out( $ThisError )
            
            $allok = false
         else
            $allok = true
         end
      end
   end
   
   # Check conditions on external entities that are not 'value' or 'cost' ...
   extHash = $gOptions[attrib1]["options"][choice]
   
   for externalParam in extHash.keys()
      
      if ( externalParam =~ /production/ )
         
         condHash = $gOptions[attrib1]["options"][choice][externalParam]["conditions"]
         
         # Check for 'all' conditions
         $ValidConditionFound = 0
         
         if ( condHash.has_key?("all") )
            debug_out ("   - EXTPARAM: #{externalParam} : found valid condition: \"all\" ! (#{condHash["all"]})\n")
            $gOptions[attrib1]["options"][choice]["ext-result"][externalParam] = $CondHash["all"]
            $ValidConditionFound = 1
         else
            # Loop through hash 
            for conditions in condHash.keys()
               valid_condition = 1
               conditionArray = conditions.split(':')
               conditionArray.each do |condition|
                  testArray = condition.split('=')
                  testAttribute = testArray[0]
                  testValueList = testArray[1]
                  if ( testValueList == "" )
                     testValueList = "XXXX"
                  end
                  testValueArray = testValueList.split('|')
                  thesevalsmatch = 0
                  testValueArray.each do |testValue|
                     if ( $gChoices[testAttribute] =~ /testValue/ )
                        thesevalsmatch = 1
                        debug_out ("       \##{$gChoices[testAttribute]} = #{$gChoices[testAttribute]} / #{testValue} / -> #{thesevalsmatch} \n")
                     end
                     if ( thesevalsmatch == 0 )
                        valid_condition = 0
                     end
                  end
               end
               if ( valid_condition == 1 )
                  $gOptions[attrib1]["options"][choice]["ext-result"][externalParam] = condHash[conditions]
                  $ValidConditionFound = 1
                  debug_out ("   - EXTPARAM: #{externalParam} : found valid condition: \"#{conditions}\" (#{condHash[$conditions]})\n")
               end
            end
         end
         
         # Check if else condition exists. 
         if ( $ValidConditionFound == 0 )
            if ( condHash.has_key("else") )
               $gOptions[attrib1]["options"][choice]["ext-result"][externalParam] = condHash["else"]
               $ValidConditionFound = 1
               debug_out ("   - EXTPARAM: #{externalParam} : found valid condition: \"else\" ! (#{condHash["else"]})\n")
            end
         end
        
         if ( $ValidConditionFound == 0 )
            $ThisError  = "\nERROR: No valid conditions were defined for #{attrib1} \n"
            $ThisError +=   "       in options file (#{$gOptionFile}). Choices must match one \n"
            $ThisError +=   "       of the following:\n"
            for conditions in condHash.keys()
               $ThisError +=  "            -> #{conditions} \n"
            end
            
            $ErrorBuffer += $ThisError
            stream_out( $ThisError )
            
            $allok = false
         else
            $allok = true
         end
      end
   end
   
   #debug_out (" >>>>> #{$gOptions[attrib1]["options"][choice]["result"]["production-elec-perKW"]}\n"); 
  
   # This section implements the multiply-cost 
   
   if ( $allok )
      cost = $gOptions[attrib1]["options"][choice]["cost"]
      cost_type = $gOptions[attrib1]["options"][choice]["cost-type"]
      if ( defined?(cost) )
         repcost = cost
      else
         repcost = "?"
      end
      if ( !defined?(cost_type) ) 
         $cost_type = "" 
      end
      if ( !defined?(cost) ) 
         cost = "" 
      end
      debug_out ("   - found cost: \$#{cost} (#{cost_type}) \n")
   
      scaleCost = 0
   
      # Scale cost by some other parameter. 
      if ( repcost =~ /\<MULTIPLY-COST:.+/ )
         
         multiplier = cost
         
         multiplier.gsub!(/\</, '')
         multiplier.gsub!(/\>/, '')
         multiplier.gsub!(/MULTIPLY-COST:/, '')
   
         multArray = multiplier.split('*')
         baseOption = multArray[0]
         scaleFactor = multArray[1]
     
         baseChoice = $gChoices[baseOption]
         baseCost = $gOptions[baseOption]["options"][baseChoice]["cost"]
     
         compCost = baseCost.to_f * scaleFactor.to_f
   
         scaleCost = 1
         $gOptions[attrib1]["options"][choice]["cost"] = compCost.to_s
         
         cost = compCost.to_s
         if ( !defined?(cost) )
            cost = "0"
         end
         if ( !defined?(cost_type) )
            $cost_type = ""
         end
      end
   
      #cost should be rounded in debug statement
      debug_out ( "\n\nMAPPING for #{attrib1} = #{choice} (@ \$#{cost} inc. cost [#{cost_type}] ): \n")
      
      if ( scaleCost == 1 )
         #baseCost should be rounded in debug statement
         debug_out (     "  (cost computed as $ScaleFactor *  #{baseCost} [cost of #{baseChoice}])\n")
      end
      
   end
   
   # Check on value of error flag before continuing with while loop
   # (the flag may be reset in the next iteration!)
   if ( !$allok )
      break    # exit the loop - don't process rest of choices against options
   end
end   #end of do each gChoices loop

# Seems like we've found everything!

if ( !$allok )
   stream_out("\n--------------------------------------------------------------\n")
   stream_out("\nSubstitute.pl encountered the following errors:\n")
   stream_out($ErrorBuffer)
   fatalerror(" Choices in #{$gChoiceFile} do not match options in #{$gOptionFile}!")
else
   stream_out (" done.\n")
end

# Now create a copy of our HOT2000 file for manipulation.
stream_out("\n\n Creating a copy of HOT2000 file for optimization work...\n")
$WorkingSimFolderName = "Working-Opt"
$gWorkingModelFile = $gBaseModelFile.sub(/User/, $WorkingSimFolderName)
# Remove any existing file first!
if ( File.exist?($gWorkingModelFile) )
   system ("del #{$gWorkingModelFile}")
end
system ("copy #{$gBaseModelFile} #{$gWorkingModelFile}")
stream_out("File #{$gWorkingModelFile} created.\n")

# Process the working file by replacing all existing values with the values 
# specified in the attributes $gChoices and corresponding $gOptions
processFile($gWorkingModelFile)

# Orientation changes. For now, we assume the arrays must always point south.
$angles = Hash.new()
$angles[ "S" => 0 , "E" => 90, "N" => 180, "W" => 270 ]

# Orientations is an array we populate with a single member if the orientation 
# is specified, or with all of the orientations to be run if 'AVG' is spec'd.               
orientations = Array.new()
if ( $gRotate =~ /AVG/ ) 
   orientations = [ 'S', 'N', 'E', 'W' ]
else 
   orientations = [ $gRotate ] 
end

# Compute scale factor for averaging between orientations (=1 if only 
# one orientation is spec'd)
$ScaleResults = 1.0 / orientations.size()    # size returns 1 or 4

# Defined at top and zeroed here because if we are running multiple orientations, 
# we must average them as we go. Averaging is done via the $ScaleResults factor (set
# at 0.25) only when the AVG option is used.
$gAvgCost_NatGas = 0
$gAvgCost_Electr = 0
$gAvgEnergy_Total = 0
$gAvgCost_Propane = 0
$gAvgCost_Oil = 0
$gAvgCost_Wood = 0
$gAvgCost_Pellet = 0
$gAvgPVRevenue = 0
$gAvgElecCons_KWh = 0
$gAvgPVOutput_kWh = 0
$gAvgCost_Total = 0
$gAvgEnergyHeatingGJ = 0
$gAvgEnergyCoolingGJ = 0
$gAvgEnergyVentilationGJ = 0
$gAvgEnergyWaterHeatingGJ = 0
$gAvgEnergyEquipmentGJ = 0
$gAvgNGasCons_m3 = 0
$gAvgOilCons_l = 0
$gAvgPropCons_l = 0
$gAvgPelletCons_tonne = 0
$gAvgEnergyHeatingElec = 0
$gAvgEnergyVentElec = 0
$gAvgEnergyHeatingFossil = 0
$gAvgEnergyWaterHeatingElec = 0
$gAvgEnergyWaterHeatingFossil = 0

$gDirection = ""
$gEnergyHeatingElec = 0
$gEnergyVentElec = 0
$gEnergyHeatingFossil = 0
$gEnergyWaterHeatingElec = 0
$gEnergyWaterHeatingFossil = 0
$gAmtOil = 0

orientations.each do |direction|

   $gDirection = direction

   if ( ! $gSkipSims ) 
      runsims( direction )
   end
   
   # post-process simulation results from a successful run. 
   # The output data are contained in two places:
   # 1) HOT2000 run file in XML -> HouseFile/AllResults
   # 2) Browse.rpt file for the ERS number (ASCII, at "Energuide Rating (not rounded) =")
   postprocess( $ScaleResults )
   
end

$gAvgCost_Total = $gAvgCost_Electr + $gAvgCost_NatGas + $gAvgCost_Propane + $gAvgCost_Oil + $gAvgCost_Wood + $gAvgCost_Pellet

$gAvgPVRevenue = $gAvgPVOutput_kWh * $PVTarrifDollarsPerkWh

$payback = 0
$gAvgUtilCostNet = $gAvgCost_Total - $gAvgPVRevenue

$gUpgCost = $gTotalCost - $gIncBaseCosts
$gUpgSavings = $gUtilityBaseCost - $gAvgUtilCostNet


if ( $gUpgSavings.abs < 1.00 )
   # Savings are practically zero. Set payback to a very large number. 
   $payback = 10000.0
elsif ( $gTotalCost < $gIncBaseCosts )  # Case when upgrade is cheaper than base cost
   if ( $gUpgSavings > 0.0 )            # Does it also save on bills? 
      $payback = 0.0                    # No-brainer. Payback should be zero.
   else
      # It may be cheap, but it costs in the long run.
      # Set payback to a very large #.
      $payback = 100000.0
   end
else
   # Compute payback. 
   $payback = ($gTotalCost-$gIncBaseCosts)/($gUtilityBaseCost-($gAvgCost_Total-$gAvgPVRevenue))
   
   # Paybacks can be less than zero if design costs more in utility bills. Set negative paybacks to very large numbers.
   if ( $payback < 0 ) 
      $payback = 100000.0 
   end
end

# Proxy for cost of ownership 
$payback = $gAvgUtilCostNet + ($gTotalCost-$gIncBaseCosts)/25.0

sumFileSpec = "#{$gMasterPath}/SubstitutePL-output.txt"
fSUMMARY = File.new(sumFileSpec, mode="w")
if fSUMMARY == nil then
   fatalerror("Could not open #{$gMasterPath}\\SubstitutePL-output.txt")
end

$PVcapacity = $gChoices["Opt-StandoffPV"]

$PVcapacity.gsub(/[a-zA-Z:\s'\|]/, '')

if ( $PVcapacity == "" )
   $PVcapacity = 0.0
end

fSUMMARY.write( "Energy-Total-GJ   =  #{$gAvgEnergy_Total} \n" )
fSUMMARY.write( "Util-Bill-gross   =  #{$gAvgCost_Total}   \n" )
fSUMMARY.write( "Util-PV-revenue   =  #{$gAvgPVRevenue}    \n" )
fSUMMARY.write( "Util-Bill-Net     =  #{$gAvgCost_Total-$gAvgPVRevenue} \n" )
fSUMMARY.write( "Util-Bill-Elec    =  #{$gAvgCost_Electr}  \n" )
fSUMMARY.write( "Util-Bill-Gas     =  #{$gAvgCost_NatGas}  \n" )
fSUMMARY.write( "Util-Bill-Prop    =  #{$gAvgCost_Propane} \n" )
fSUMMARY.write( "Util-Bill-Oil     =  #{$gAvgCost_Oil} \n" )
fSUMMARY.write( "Util-Bill-Wood    =  #{$gAvgCost_Wood} \n" )
fSUMMARY.write( "Util-Bill-Pellet  =  #{$gAvgCost_Pellet} \n" )

fSUMMARY.write( "Energy-PV-kWh     =  #{$gAvgPVOutput_kWh} \n" )
#fSUMMARY.write( "Energy-SDHW      =  #{$gEnergySDHW} \n" )
fSUMMARY.write( "Energy-HeatingGJ  =  #{$gAvgEnergyHeatingGJ} \n" )
fSUMMARY.write( "Energy-CoolingGJ  =  #{$gAvgEnergyCoolingGJ} \n" )
fSUMMARY.write( "Energy-VentGJ     =  #{$gAvgEnergyVentilationGJ} \n" )
fSUMMARY.write( "Energy-DHWGJ      =  #{$gAvgEnergyWaterHeatingGJ} \n" )
fSUMMARY.write( "Energy-PlugGJ     =  #{$gAvgEnergyEquipmentGJ} \n" )
fSUMMARY.write( "EnergyEleckWh     =  #{$gAvgElecCons_KWh} \n" )
fSUMMARY.write( "EnergyGasM3       =  #{$gAvgNGasCons_m3}  \n" )
fSUMMARY.write( "EnergyOil_l       =  #{$gAvgOilCons_l}    \n" )
fSUMMARY.write( "EnergyPellet_t    =  #{$gAvgPelletCons_tonne}   \n" )
fSUMMARY.write( "Upgrade-cost      =  #{$gTotalCost-$gIncBaseCosts}\n" )
fSUMMARY.write( "SimplePaybackYrs  =  #{$payback} \n" )

# These #s are not yet averaged for orientations!
fSUMMARY.write( "PEAK-Heating-W    = #{$gPeakHeatingLoadW}\n" )
fSUMMARY.write( "PEAK-Cooling-W    = #{$gPeakCoolingLoadW}\n" )

fSUMMARY.write( "PV-size-kW      =  #{$PVcapacity}\n" )

fSUMMARY.write( "ERS-Value         =  #{$gERSNum}\n" )
fSUMMARY.write( "ERS-Value_noVent  =  #{$gERSNum_noVent}\n" )

fSUMMARY.close() 

$fLOG.close() 


=begin rdoc
==================================================================================
NOTHING BELOW THIS POINT CONVERTED TO Ruby!
==================================================================================

sub round($){
  my ($var) = @_; 
  my $tmpRounded = int( abs($var) + 0.5);
  my $finalRounded = $var >= 0 ? 0 + $tmpRounded : 0 - $tmpRounded;
  return $finalRounded;
}

sub round1d($){
  my ($var) = @_; 
  my $tmpRounded = int( abs($var*10) + 0.5);
  my $finalRounded = $var >= 0 ? 0 + $tmpRounded : 0 - $tmpRounded;
  return $finalRounded/10;
}

#--------------------------------------------------------------------
# Perform system commands with optional redirection
#--------------------------------------------------------------------
sub execute($){
  my($command) =@_;
  my $result;
  if ($gTest_params{"verbosity"} eq "very_verbose" || $gTest_params{"verbosity"} eq "very_very_verbose" ){    
    debug_out("\n > executing $command \n");
    debug_out(" > from path ".getcwd()."\n");
    system($command);
  }else{
    $result = `$command 2>&1`;
    if ($gTest_params{"logfile"}){
      print fLOG $result."\n\n\n"; 
    }
  }
  return;
}

sub min($$){
  my ($a,$b) = @_; 
  if ($a > $b ) {return $b;}
  else {return $a;}
  
  return 1;
}

=end
