#!/usr/bin/perl
use strict;
use warnings;

use XML::Simple;	# to parse the XML databases
use Data::Dumper;	# to dump info to the terminal for debugging purposes
use Storable  qw(dclone);
use File::Copy;
use File::Copy::Recursive qw(rmove);
use Getopt::Long qw(GetOptions);

# GLOBALS
my $sLocCrossRefFile = "../data/LocationCrossRef.xml"; # Path to location cross-ref (holds what HVAC and DHW system is used for each location, and what archetypes)
my $sArchInfo; # Path to archetype info database
my $sArchDir; # Path to archetypes

# INPUTS (DEFAULTS)
my $iThreads=1; # Must be integer greater than 0
my $iMode; # MUST BE EITHER 1 (use old 11 archetypes), or 2 (use new archetypes)
my $bDispHelp=0;
my @sRuleSets; # NBC9_36_HRV and/or NBC9_36_noHRV
my $sOutputFolder;
my $sInputFile;
my @sLocations;

# OUTPUTS
my $hOutputs;
my $sOutputXML="Summary.xml";

# Parse input
GetOptions(
    'threads=i' => \$iThreads,
	'input=s' => \$sInputFile,
	'output-folder=s' => \$sOutputFolder,
	'help' => \$bDispHelp,
);

if($bDispHelp) {
	displayHelp();
	exit 0;
};

# Check command line input validity
my $iCPUlimit = $ENV{NUMBER_OF_PROCESSORS}-1; # ONLY WORKS FOR WINDOWS
if($iThreads > $iCPUlimit) {die "ERROR: $iThreads is too many threads to run on this machine! Max is $iCPUlimit\n";}
if(not defined $sInputFile) {die "ERROR: --input not provided\n";}
if(not defined $sOutputFolder) {die "ERROR: --output-folder not provided\n";}

# Load the inputs from file
my $hInputs = XMLin($sInputFile, KeyAttr => {}, ForceArray => [ 'location', 'rulesets' ]);

# Gather the data from the file
@sRuleSets=@{$hInputs->{'rulesets'}};
@sLocations=@{$hInputs->{'location'}};
$iMode=$hInputs->{'mode'};
$sOutputFolder =~ s/\\$|\/$//; # Remove a trailing slash
my $hChoices = dclone($hInputs->{'choices'});
undef $hInputs;

# Check input file validity
if(not defined $iMode) {die "ERROR: input 'Mode' not provided. Valid inputs are 1 (use old archs) and 2 (New)\n";}
if($iMode != 1 && $iMode != 2) {die "ERROR: Mode $iMode is not a valid entry. Valid entries are 1 and 2 (see --help for more info)\n";}
if(!@sRuleSets) {die "ERROR: input option --rulesets not provided. Must provide NBC9_36_HRV and/or NBC9_36_noHRV\n";}
if(!@sLocations) {die "ERROR: No location inputs provided\n;"}

# Determine which archetype set is to be simulated
if($iMode == 1) {
	$sArchDir = "C:/HTAP/Archetypes";
	$sArchInfo = "../data/ClassicArchInfo.xml";
} elsif ($iMode == 2) {
	$sArchDir = "C:/HTAP/Archetypes/EGH-ARCH";
	$sArchInfo = "../../../Archetypes/EGH-ARCH/ArchInfo.xml";
} else {
	die "ERROR: Invalid mode number $iMode! Must be 1 (classic 11 archetypes), or 2 (new archetypes)\n";
};

# Load the external databases
my $hCrossRef = XMLin($sLocCrossRefFile);
my $hArchInfo = XMLin($sArchInfo);

# Create the output folder
mkdir($sOutputFolder) or print "Warning: Folder $sOutputFolder already exists\n";
if (-d $sOutputFolder) {sleep 2;}

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
	if($iMode == 1) {$sGroupKey = 'ALL';} # Override if using the old archetypes
	my @sArchs=();
	foreach my $sFile (keys (%{$hArchInfo})) {
		if($hArchInfo->{$sFile}->{"Housing-Market"} =~ m/$sGroupKey/) {push(@sArchs,$sFile);}
	};
	
	# Check the ruleset selection for conflicts
	if($hChoices->{'Opt-HRVonly'} !~ m/^NA/) {
		# Ventilation options are being overridden. This is only valid for the NBC9_36_noHRV ruleset
		foreach my $sSet (@sRuleSets) {
			if($sSet =~ m/NBC9_36_HRV/) {die "Cannot run ruleset $sSet with Opt-HRVonly override\n";}
		};
	};
	
	# Print the RUN file
	setRunFile("../$sLoc.run",$sLoc,\@sRuleSets,$hThisChoice,\@sArchs,$sArchDir);
	
	# Copy the options file in the application (TODO: ANY MANIPULATIONS TO OPTIONS FILE DONE HERE)
	copy("../NBC936.options","../$sLoc.options") or die "Copy failed: $!";

	# Launch HTAP-prm
	chdir("../");
	system("ruby C:\\HTAP\\htap-prm.rb -r .\\$sLoc.run -o C:\\HTAP\\applications\\NBC_Archs\\$sLoc.options -v -k --threads $iThreads");

	# Collect the output
	$hOutputs->{"$sLoc"} = {};
	getOutputData($hOutputs->{"$sLoc"},$sLoc);
	
	# Run clean-up
	my @folders = glob "HTAP-sim-*/";
	mkdir("$sOutputFolder/$sLoc");
	foreach my $folder (@folders) {
		$folder =~ s/\/$//;
		rmove($folder, "$sOutputFolder/$sLoc/$folder");
	};
	unlink "$sLoc.run";
	rmove("HTAP-prm-failures.txt","$sOutputFolder/$sLoc/HTAP-prm-failures.txt");
	rmove("HTAP-prm-output.csv","$sOutputFolder/$sLoc/HTAP-prm-output.csv");
	rmove("$sLoc.options","$sOutputFolder/$sLoc/$sLoc.options");
	
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
	my @sRetrieve = qw( Energy-Total-GJ Energy-DHWGJ Energy-VentGJ EnergyEleckWh EnergyGasM3 EnergyOil_l EnergyProp_L EnergyWood_cord MEUI_kWh_m2 PEAK-Heating-W TEDI_kWh_m2 Opt-ACH );
	
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

sub displayHelp {
	print "\n";
	print " The following input is required:\n\n";
	print "		--input file.txt\n";
	print "	Optional input is: \n";
	print "		--threads 2 (default 1)\n\n";
	print "	Input files are XML with the following format:\n\n";
	print "		<opt>\n";
	print "			<!-- Run mode: Valid inputs are 1 (use old archs) and 2 (New) -->\n";
	print "			<mode>1</mode>\n";
	print "			<!-- Rulesets: Two valid entries:  NBC9_36_HRV and NBC9_36_noHRV -->\n";
	print "			<rulesets>NBC9_36_HRV</rulesets>\n";
	print "			<rulesets>NBC9_36_noHRV</rulesets>\n";
	print "			<!-- Output folder -->\n";
	print "			<output_folder>E:/Default</output_folder>\n";
	print "			<!-- Locations: MUST correpsond to loactions in CrossRefFile-->\n";
	print "			<location>SAINTJOHNS</location>\n";
	print "			<location>YELLOWKNIFE</location>\n";
	print "			<!-- Choices to be possibly overridden -->\n";
	print "			<!-- Opt-DHWSystem and Opt-HVACSystem may be sepcificed here. Else the fuel type is determined by LocationCrossRef.xml -->\n";
	print "			<choices Opt-FuelCost=\"rates2016\" \n";
	print "					 Opt-HRVonly=\"NA\"\n";
	print "					 Opt-ACH=\"NA\"\n";
	print "					 Opt-GenericWall_1Layer_definitions=\"NA\"\n";
	print "			         Opt-H2KFoundation=\"NA\"\n";
	print "					 Opt-ExposedFloor=\"NA\"\n";
	print "					 Opt-CasementWindows=\"NA\"\n";
	print "					 Opt-Doors=\"NA\"\n";
	print "					 Opt-DoorWindows=\"NA\"\n";
	print "					 Opt-H2KFoundationSlabCrawl=\"NA\"\n";
	print "					 Opt-H2K-PV=\"NA\"\n";
	print "					 Opt-AtticCeilings=\"NA\"\n";
	print "					 Opt-CathCeilings=\"NA\"\n";
	print "					 Opt-FlatCeilings=\"NA\"\n";
	print "					 Opt-FloorAboveCrawl=\"NA\"\n";
	print "					 Opt-Baseloads=\"NA\"\n";
	print "					 Opt-ResultHouseCode=\"NA\"\n";
	print "					 Opt-Temperatures=\"NA\"\n";
	print "					 Opt-Specifications=\"NA\"\n";
	print "					 GOconfig_rotate=\"AVG\"\n";
	print "					 Opt-DBFiles=\"H2KCodeLibFile\"\n"; 
	print "			/>\n";
	print "		</opt>\n";

	return 0;
};