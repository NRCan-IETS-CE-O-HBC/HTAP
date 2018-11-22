#!/usr/bin/perl
use strict;
use warnings;

use XML::Simple;	# to parse the XML databases
use Data::Dumper;	# to dump info to the terminal for debugging purposes
use Storable  qw(dclone);
use File::Copy::Recursive qw(rmove);

# GLOBALS
my $sArchDir = "C:/HTAP/Archetypes/EGH-ARCH"; # Path to archetypes
my $sLocCrossRefFile = "../data/LocationCrossRef.xml"; # Path to location cross-ref (holds what HVAC and DHW system is used for each location, and what archetypes)
my $sArchInfo = "../../../Archetypes/EGH-ARCH/ArchInfo.xml"; # Path to database holding archetype info

# INPUTS
my $iThreads=2; # Must be integer greater than 0
my @sLocations = qw( SAINTJOHNS CHARLOTTETOWN  HALIFAX MONCTON MONTREAL TORONTO WINNIPEG SASKATOON CALGARY VANCOUVER WHITEHORSE YELLOWKNIFE IQALUIT); # MUST correpsond to loactions in $sLocCrossRefFile
my @sRuleSets = qw( NBC9_36_HRV NBC9_36_noHRV);
my $sOutputFolder = "E:/EGH_ARCH_ACH_0_6";
# Intialize all relevant choices to "NA" OR choose changes to building envelope
my $hChoices = { 
				 # "Opt-FuelCost" => 'rates2016', # COMMENT OUT IF DEFAULTS ARE TO BE USED
				 # "Opt-DHWSystem" => 'NBC-HotWater_gas', # COMMENT OUT IF DEFAULTS ARE TO BE USED
				 "Opt-HVACSystem" => 'NBC-elec-heat',
				 "Opt-ACH" => 'ACH_0_6',                      
				 "Opt-GenericWall_1Layer_definitions" => 'NA',
				 "Opt-H2KFoundation" => 'NA',
				 "Opt-ExposedFloor" => 'NA',
				 "Opt-CasementWindows" => 'NA',
				 "Opt-Doors" => 'NA',
				 "Opt-DoorWindows" => 'NA',
				 "Opt-H2KFoundationSlabCrawl " => 'NA',
				 "Opt-H2K-PV " => 'NA',
				 "Opt-AtticCeilings" => 'NA',
				 "Opt-CathCeilings" => 'NA',
				 "Opt-FlatCeilings" => 'NA',
				 "Opt-FloorAboveCrawl" => 'NA',
				 "Opt-HRVonly" => 'NA',
				 "Opt-Baseloads" => 'NA',
				 "Opt-ResultHouseCode" => 'General',
				 "Opt-Temperatures" => 'NA',
				 "Opt-Specifications" => 'NA',
				 "GOconfig_rotate" => 'AVG',
				 "Opt-DBFiles" => 'H2KCodeLibFile'
				};

# OUTPUTS
my $hOutputs;
my $sOutputXML="Summary.xml";

# Load the external databases
my $hCrossRef = XMLin($sLocCrossRefFile);
my $hArchInfo = XMLin($sArchInfo);

foreach my $sLoc (@sLocations) { # This loop represents one call to htap parallel run manager
	my $hThisChoice = dclone($hChoices); # Clone the Hash

	# Add location-specific data (if not manually over-ridden)
	if(not exists $hThisChoice->{"Opt-DHWSystem"}) {
		$hThisChoice->{"Opt-DHWSystem"} = $hCrossRef->{"$sLoc"}->{"Opt-DHWSystem"};
	};
	if(not exists $hThisChoice->{"Opt-HVACSystem"}) {
		$hThisChoice->{"Opt-HVACSystem"} = $hCrossRef->{"$sLoc"}->{"Opt-HVACSystem"};
	};

	# Determine the archetypes to be run for this location
	my $sGroupKey = $hCrossRef->{"$sLoc"}->{"Arch-Set"}; # Identify what housing market to use for this location
	my @sArchs=();
	foreach my $sFile (keys (%{$hArchInfo})) {
		if($hArchInfo->{$sFile}->{"Housing-Market"} =~ m/$sGroupKey/) {push(@sArchs,$sFile);}
	};
	
	# Print the RUN file
	setRunFile("../$sLoc.run",$sLoc,\@sRuleSets,$hThisChoice,\@sArchs,$sArchDir);
	
	# Launch HTAP-prm
	chdir("../");
	system("ruby C:\\HTAP\\htap-prm.rb -r .\\$sLoc.run -o C:\\HTAP\\HOT2000.options -v -k --threads $iThreads");
	
	# Collect the output
	$hOutputs->{"$sLoc"} = {};
	getOutputData($hOutputs->{"$sLoc"},$sLoc);
	
	# Run clean-up
	my @folders = glob "HTAP-sim-*/";
	mkdir("E:/EGH_ARCH_SIM1/$sLoc");
	foreach my $folder (@folders) {
		$folder =~ s/\/$//;
		rmove($folder, "E:/EGH_ARCH_SIM1/$sLoc/$folder");
	};
	unlink "$sLoc.run";
	rmove("HTAP-prm-failures.txt","$sOutputFolder/$sLoc/HTAP-prm-failures.txt");
	rmove("HTAP-prm-output.csv","$sOutputFolder/$sLoc/HTAP-prm-output.csv");
	
	# Back to where we started from
	chdir("scripts");
};

# Store the output in an XML (for now)
open (my $fh, '>', "$sOutputFolder/$sOutputXML") or die ("Can't open datafile: $sOutputXML");	# open writeable file
print $fh XMLout($hOutputs, KeyAttr => [  ]);	# printout the XML data
close $fh;

##########################################################################################
# SUBROUTINES
##########################################################################################

# setRunFile prints out the HTAP run file
sub setRunFile {
	# INPUTS
	my $sFile = shift;
	my $sLocate = shift;
	my $ref_Rulesets = shift;
	my $hChosen = shift;
	my $ref_ArchList = shift;
	my $sArchDir = shift;
	
	# INTERMEDIATES
	my @sRules = @$ref_Rulesets;
	my @sAr = @$ref_ArchList;
	
	# Open the file for writing
	open (my $fh, '>', $sFile) or die ("Can't open datafile: $sFile");	# open writeable file
	# Print the top matter
	print $fh "! Definitions file for HTAP-PRM RUN \n\n";
	print $fh "! Run-Mode: Parameters that affect how htap-prm is configured. \n";
	print $fh "RunParameters_START\n";
	print $fh "  run-mode                           = mesh \n";
	print $fh "  archetype-dir                      = $sArchDir\n";
	print $fh "RunParameters_END\n\n\n";
	print $fh "! Parameters controlling archetypes, locations, reference rulests. (these will always be\n";
	print $fh "! run in mesh, even if anoptimization mode is added in the future.\n";
	print $fh "RunScope_START\n\n";
	my $sArchLine = "  archetypes = $sAr[0]";
	for(my $i=1;$i<=$#sAr;$i++) {$sArchLine = $sArchLine. ",$sAr[$i]";}
	print $fh "$sArchLine\n";
	print $fh "  locations  = $sLocate\n";
	my $sRuleLines = "  rulesets   = $sRules[0]";
	for(my $i=1;$i<=$#sRules;$i++) {$sRuleLines = $sRuleLines. ",$sRules[$i]";}
	print $fh "$sRuleLines\n\n";
	print $fh "RunScope_END\n\n";
	print $fh "! Parameters controlling the design of the building \n";
	print $fh "Upgrades_START\n\n";
	
	foreach my $choice (keys (%{$hChosen})) {
		my $val = $hChosen->{$choice};
		printf $fh "   %-34s = %s\n",$choice,$val;
	};
	print $fh "\nUpgrades_END\n";
	close $fh;
	
	return 0;
};

# retrieve data from an HTAP run
sub getOutputData {
	my $hRef = shift;
	my $sLocation = shift;
	my @sRetrieve = qw( Energy-DHWGJ Energy-VentGJ EnergyEleckWh EnergyGasM3 EnergyOil_l EnergyProp_L EnergyWood_cord MEUI_kWh_m2 PEAK-Heating-W TEDI_kWh_m2 Opt-ACH );
	
	# INTERMEDIATES
	my $sOutputFile = "HTAP-prm-output.csv";
	open(my $fid, "<", $sOutputFile) or die "Can't open < $sOutputFile: $!";
	my @sAllData = <$fid>;
	close $fid;
	my @iIndex=(-1) x scalar @sRetrieve;
	my $iArchName;
	my $iRuleSet;
	
	# Get the headers
	my @sHeaders = split /,/,shift @sAllData;
	$sHeaders[$#sHeaders] =~ s/^\s+|\s+$//g; # Remove leading and trailing whitespace
	
	# Index the headers
	LOOP_1: for(my $i=0;$i<=$#sHeaders;$i++) {
		if($sHeaders[$i] =~ m/Opt-Archetype/) {
			$iArchName=$i;
			next LOOP_1;
		} elsif($sHeaders[$i] =~ m/Opt-Ruleset/) {
			$iRuleSet=$i;
			next LOOP_1;
		};
		LOOP_2: for(my $j=0;$j<=$#sRetrieve;$j++) {
			if($sHeaders[$i] =~ m/$sRetrieve[$j]/) {
				$iIndex[$j] = $i;
				last LOOP_2;
			};
		};
	};
	for(my $i=0;$i<=$#iIndex;$i++) {
		if($iIndex[$i]<0) {print "Unable to index result $sRetrieve[$i] for location $sLocation. Will be set to NA\n";}
	};
	
	# Parse the data in this file
	foreach my $sLine (@sAllData) {
		my @sData = split /,/,$sLine;
		$sData[$#sData] =~ s/^\s+|\s+$//g; # Remove leading and trailing whitespace
		for(my $i=0;$i<=$#iIndex;$i++) {
			if($iIndex[$i]>-1) {
				$sData[$iIndex[$i]] =~ s/^\s+|\s+$//g; # Remove leading and trailing whitespace
				$sData[$iRuleSet] =~ s/^\s+|\s+$//g; # Remove leading and trailing whitespace
				$sData[$iArchName] =~ s/^\s+|\s+$//g; # Remove leading and trailing whitespace
				$hRef->{$sData[$iRuleSet]}->{$sData[$iArchName]}->{$sRetrieve[$i]} = $sData[$iIndex[$i]];
			} else {
				$hRef->{$sData[$iRuleSet]}->{$sData[$iArchName]}->{$sRetrieve[$i]} = "NA";
			};
		};
	};
	return 0;
};