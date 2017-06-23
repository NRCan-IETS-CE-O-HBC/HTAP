#!/usr/bin/perl    

# This script creates choices files from a supplied csv file with
# specific choice attributes set. 
 
use warnings;
use strict;

sub UpgradeRuleSet($);
sub WriteChoiceFile($);
sub fatalerror($);

#--------------------------------------------
# Help text. Dumped if no arguments supplied.
#--------------------------------------------
my $Help_msg = "

 MakeOptFiles.pl: 
 
 This script searches through the supplied command line argument file
 and creates one choice file per row in the supplied csv file. 
 
 use: ./MakeOptFiles.pl RunFile.csv
                      
";

# dump help text, if no argument given
if (!@ARGV){
  print $Help_msg;
  die;
}

my @choiceLists;

my $OptListFile = $ARGV[0];

open ( OPTLISTFILE, "$OptListFile") or fatalerror("Could not read $OptListFile!");

my $linecount;
my @choiceAttKeys;
my @choiceAttValues;
my %choiceHash = ();

my $NumFiles = 0; 
my $ChoiceFileList =""; 


my %upgrade_packages = (

                        "as-found" => ["as-found"],   # Original definitions from the .csv file 
  
);


#my @upgrades= ( "as-found") ; 

while ( my $line = <OPTLISTFILE> ){

  # Gobble or process items that may be incorrectly formatted / named 
  $line =~ s/Small SFD/BC-Step-SmallSFD/g; 
  $line =~ s/Medium SFD/BC-Step-MediumSFD/g; 
  $line =~ s/Large SFD/BC-Step-LargeSFD/g; 
  $line =~ s/Summerland/SUMMERLAND/g; 
  $line =~ s/Cranbrook/CRANBROOK/g; 
  $line =~ s/Cranbrook/CRANBROOK/g; 
  $line =~ s/Archetype/Opt-Archetype/g; 
  $line =~ s/GOtag://g; 

  
  
  
  $line =~ s/\!.*$//g; 
  $line =~ s/\s*//g;
  
  
 
  $line =~ s/under_slab,/under,/; 
  
  $linecount++;

  

  
  
  
  # First record is header with choice file attribute names
  if($linecount == 1) {
    @choiceAttKeys = split /,/, $line;
  } elsif ( $line =~ /^#/ ) {
    # do nothing 
  } else {
    @choiceAttValues = split /,/, $line;
  
    
    
    # Hash created for current record, write the corresponding choice file
       
    #foreach my $upgrade ( @upgrades ){
    foreach my $upgrades_name (keys %upgrade_packages) {
    my $upgrade_package_is_valid = 0;
    my $upgrade_is_valid = 0;
      # Populate choice hash - do this on every upgrade because it gets overwritten
      my $count = 0;
      foreach (@choiceAttKeys){
        $choiceHash{ $choiceAttKeys[$count] } = $choiceAttValues[$count];
        $count++;
      }

      my $Scenario = $choiceHash{"Scenario"} ; 
      my $ID       = $choiceHash{"ID"} ;
      # extra keys that weren't part of the original spreadsheet - "as-found condition"
      $choiceHash{"Opt-DWHRandSDHW"} = "none"; 
      $choiceHash{"Opt-ElecLoadScale"} = "NGERSNoReduction19"; 
      $choiceHash{"Opt-DHWLoadScale"} = "No-Reduction"; 
      $choiceHash{"Opt-HRV_ctl"} = "EightHRpDay"; 
      $choiceHash{"Opt-StandoffPV"} = "NoPV";

      foreach my $upgrade (@{$upgrade_packages{$upgrades_name}}) {

        $upgrade_is_valid = UpgradeRuleSet($upgrade);
    
        if(($upgrade_is_valid == 1) && ($upgrade_package_is_valid == 0)){
      $upgrade_package_is_valid = 1;
    }
      }
      
      # Call upgrade rule set to see if this upgrade can be applied 
      if($upgrade_package_is_valid == 1) {     
        my $choiceFilename = "./".$Scenario."~".$choiceHash{"ID"} ."~".$upgrades_name.".choices";
      
        print ( "> $ID : Generating scenario: $upgrades_name   \n"); 
      
        # Generate corresponding Choice File
        #WriteChoiceFile($choiceFilename); 
      
        push @choiceLists, $choiceFilename; 
        
        $NumFiles++;
      
        # Append name to list of choice files to be run. 
    
      }
    }
  }
}



close (OPTLISTFILE);



$ChoiceFileList = ""; 

my $files = 0; 

my $TemplateTxt = ""; 
open(CMDTEMPLATE, "../BC-Step-Codes/Genopt-BC-rerun-template.GO-cmd") or die ("could not open ../BC-Step-Codes/Genopt-BC-rerun-template.GO-cmd") ; 
while ( my $Line = <CMDTEMPLATE> ){
  $TemplateTxt .= $Line;   
}
close (CMDTEMPLATE); 

my $TemplateIniTxt = ""; 
open(INITEMPLATE, "../BC-Step-Codes/Genopt-BC-rerun-template.GO-ini") or die ("could not open ../BC-Step-Codes/Genopt-BC-rerun-template.GO-ini") ; 
while ( my $Line = <INITEMPLATE> ){
  $TemplateIniTxt .= $Line;   
}
close (INITEMPLATE); 




my $outputFile = 0; 
my $BatchCmds = ""; 

foreach my $ChoiceFile (@choiceLists){ 
  $ChoiceFileList .= " $ChoiceFile , ";
  $files++; 
  
  if ( $files > 1000 ){
    $outputFile++; 
    
    
    $ChoiceFileList =~ s/\s*,\s*$//g; 
    $ChoiceFileList =~ s/\.\///g; 
    
    my $OutputTxt =  $TemplateTxt;
    $OutputTxt =~ s/___FILES_GO_HERE___/$ChoiceFileList/g; 
    
    
    
    open( OUTPUTCMD, ">../BC-Step-Codes/Genopt-BC-rerun-auto-$outputFile++.GO-cmd" ) ; 
    print OUTPUTCMD $OutputTxt; 
    close (OUTPUTCMD) ; 
    
    my $IniTxt = $TemplateIniTxt; 
    $IniTxt =~ s/___CMD_FILE_GOES_HERE___/Genopt-BC-rerun-auto-$outputFile++.GO-cmd/g; 
    
    open( OUTPUTINI, ">../BC-Step-Codes/Genopt-BC-rerun-auto-$outputFile++.GO-ini" ) ; 
    print OUTPUTINI $IniTxt; 
    close (OUTPUTINI) ; 
    
    $BatchCmds .= "java -classpath genopt.jar genopt.GenOpt BC-Step-Codes\\Genopt-BC-rerun-auto-$outputFile++.GO-ini\n"; 
    $BatchCmds .= "timeout /t 10 \n";
    $BatchCmds .= "copy BC-Step-Codes\\OutputListingAll.txt C:\\Ruby4HTAP\\BC-Step-Codes\\Gdrive-res\\\AwsSync\\TempResultsBatch$outputFile.txt\n"; 
    $BatchCmds .= "del BC-Step-Codes\\OutputListingAll.txt\n";
    
    
    $files = 0; 
    $ChoiceFileList = ""; 
  
  
  
  }
  
}

    open( OUTPUTBATCH, ">../Java-Runs.bat" ) ; 
    print OUTPUTBATCH $BatchCmds; 
    close (OUTPUTBATCH) ; 






 

$outputFile++; 


$ChoiceFileList =~ s/\s*,\s*$//g; 
$ChoiceFileList =~ s/\.\///g; 

my $OutputTxt =  $TemplateTxt;
$OutputTxt =~ s/___FILES_GO_HERE___/$ChoiceFileList/g; 

open( OUTPUTCMD, ">../BC-Step-Codes/Genopt-BC-rerun-auto-$outputFile++.GO.cmd" ) ; 

print OUTPUTCMD $OutputTxt; 

close (OUTPUTCMD) ; 

$files = 0; 
$ChoiceFileList = ""; 
  
  


print "\n\n CHOICE LIST ->$ChoiceFileList<- \n"; 

print " =============================\n";
print " UPGRADES CONSIDERED:\n";
#foreach my $upgrade ( @upgrades ){
foreach my $upgrade_name ( keys %upgrade_packages){
      print "   -> %upgrade_packages{$upgrade_name} \n"; 
}



#--------------------------------------------------------------------
# Upgrade rule sets:
#--------------------------------------------------------------------
sub UpgradeRuleSet($){


  my ($upgrade) = @_; 

  my $validupgrade = 0; 
  
  
  SWITCH:{
  
    #=========================================================================
    # Ignore 2019+ scenarios for the time being. 
    #=========================================================================
    #if ( $choiceHash{"ID"} =~ /2020-2024.*/  ||  
    #if ( $choiceHash{"ID"} =~ /2025-onwards.*/ ){
         
         #Do nothing. 
    #     last SWITCH; 
           
    #}
  
  
    #=========================================================================
    # Load conservation options 
    #=========================================================================
    if ( $upgrade =~ /Validate-with-OldSOP/ ){
      
      # As found condition - no changes needed.
            
      $choiceHash{"Opt-ElecLoadScale"} = "NoReduction"; 
      $choiceHash{"Opt-DHWLoadScale"} = "OldERS"; 
      $choiceHash{"Opt-HRV_ctl"} = "ERSp3ACH"; 
      $validupgrade = 1; 
      last SWITCH; 
  
    }
  
  
    #=========================================================================
    # Baseline: Leave choices alone. 
    #=========================================================================
    
    if ( $upgrade =~ /as-found/ ){
      
      # As found condition - no changes needed.
      
      $validupgrade = 1; 
      last SWITCH; 
  
    }
    #=========================================================================
    # EMMC regs 
    #=========================================================================
        if ( $upgrade =~ /oee-EMMC-regs-2016/ ){
      
      # As found condition - no changes needed.
      
      $choiceHash{"Opt-CasementWindows"} = "Upgrade-U-2_0";
      
      
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Oil/){ 
      
        $choiceHash{"Opt-GhgHeatingCooling"} = "oee-oil-ref"
        
      } 
      
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Gas/){ 
      
        $choiceHash{"Opt-GhgHeatingCooling"} = "oee-gas-ref"
        
      } 
      
      
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Elect/){ 
      
        $choiceHash{"Opt-GhgHeatingCooling"} = "oee-elec-ref"
        
      }       
      
      
      $validupgrade = 1; 
      last SWITCH; 
  
    }
    
    #=========================================================================
    # EMMC regs 
    #=========================================================================
        if ( $upgrade =~ /oee-EMMC-regs-2025/ ){
      
      # As found condition - no changes needed.
      
      $choiceHash{"Opt-CasementWindows"} = "Upgrade-U-1_2";
      
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Oil/){ 
      
        $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2025-oil"
        
      } 
      
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Gas/){ 
      
        $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2025-gas"
        
      } 
      
      
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Elect/){ 
      
        $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2025-elec-b"
        
      }       
      
      
      $validupgrade = 1; 
      last SWITCH; 
  
    }
    


    
    
    
    
    
    #=========================================================================
    # Load conservation options 
    #=========================================================================
    if ( $upgrade =~ /LoadConservation-basic/ ){
      
      # As found condition - no changes needed.
      
      
      $choiceHash{"Opt-ElecLoadScale"} = "NGERSReducedA16"; 
      $choiceHash{"Opt-DHWLoadScale"} = "EStar"; 
      
      $validupgrade = 1; 
      last SWITCH; 
  
    }
  
      #=========================================================================
    # Load conservation options 
    #=========================================================================
    if ( $upgrade =~ /LoadConservation-aggressive/ ){
      
      # As found condition - no changes needed.
      
      
      $choiceHash{"Opt-ElecLoadScale"} = "NGERSBestInClass14p8"; 
      $choiceHash{"Opt-DHWLoadScale"}  = "Low-Flow"; 
      
      $validupgrade = 1; 
      last SWITCH; 
  
    }
  
  
  
    #=========================================================================
    # Fuel switching: 
    #     Oil -> Gas to electric heat pumps,
    #     Oil -> gas 
    #     Elect -> Gas
    #=========================================================================
   
    # Oil -> ASHP 
    if ( $upgrade =~ /switch-oil-to-electricity.*/ ){
    
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Oil/){
        
        #         # Switch oil to ASHP
        if ( $upgrade =~ /.*-ASHP/ ){
          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-ASHP-ref"  ;
          $choiceHash{"Opt-DHWSystem"}         = "oee-elecstorage-ref" ; 
        }
        if ( $upgrade =~ /.*-CCASHP/ ){
          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-CCASHP-ref"  ;
          $choiceHash{"Opt-DHWSystem"}         = "oee-elecstorage-ref" ; 
        }
        if ( $upgrade =~ /.*-GSHP/ ){
          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-GSHP-ref"  ;
          $choiceHash{"Opt-DHWSystem"}         = "oee-elecstorage-ref" ; 
        }
      
        $validupgrade = 1;
      }
      last SWITCH; 
    }
    
    
    # Oil & GAS  -> ASHP 
    if ( $upgrade =~ /switch-gas-to-electricity.*/ ){
    
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Gas/  ){
        
        # Switch oil & gas to ASHP
        if ( $upgrade =~ /.*-ASHP/ ){
          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-ASHP-ref"  ;
          $choiceHash{"Opt-DHWSystem"}         = "oee-elecstorage-ref" ; 
        }
        if ( $upgrade =~ /.*-CCASHP/ ){
          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-CCASHP-ref"  ;
          $choiceHash{"Opt-DHWSystem"}         = "oee-elecstorage-ref" ; 
        }
        if ( $upgrade =~ /.*-GSHP/ ){
          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-GSHP-ref"  ;
          $choiceHash{"Opt-DHWSystem"}         = "oee-elecstorage-ref" ; 
        }
      
        $validupgrade = 1;
        
      }
      
      last SWITCH; 
    }
    
    
    # Oil -> GAS  
    if ( $upgrade =~ /switch-oil-to-gas.*/ ){
    
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Oil/ ){

          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-gas-ref"  ;
          $choiceHash{"Opt-DHWSystem"}         = "oee-gasdhw-ref" ; 
          
          $validupgrade = 1;
          
      }

      
      last SWITCH; 
    }
    
    
    # Electricity -> GAS  
    if ( $upgrade =~ /switch-electricity-to-gas/ ){
    
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Elect/ || 
           $choiceHash{"Opt-GhgHeatingCooling"} =~ /CCHP/ ){

          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-gas-ref"  ;
          $choiceHash{"Opt-DHWSystem"}         = "oee-gasdhw-ref" ; 
          
          $validupgrade = 1;
          
      }

      
      last SWITCH; 
    }
    
    #=========================================================================
    # MINO Scenarios: Heating with Heat Pumps and so forth
    #=========================================================================     
    
    if ( $upgrade =~ /HeatWHP-UpgradeTo-EStar/ ) {
      
       if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Gas/ ) {
       
         $choiceHash{"Opt-GhgHeatingCooling"} = "oee-gas-ref"  ;
         $validupgrade = 1; 
         
       }
       
             
       if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Oil/ ) {
       
         $choiceHash{"Opt-GhgHeatingCooling"} = "oee-oil-ref"  ;
         $validupgrade = 1; 
         
       }
       
       last SWITCH; 
     }
    
        
     if ( $upgrade =~ /HeatWHP-UpgradeTo-AllElecASHP/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-ASHP-ref"  ;
       $validupgrade = 1; 
         
       last SWITCH; 
     }

    
    
     if ( $upgrade =~ /HeatWHP-UpgradeTo-AllElecCCASHP/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-CCASHP-ref"  ;
       $validupgrade = 1; 
         
       last SWITCH; 
     }

  
     
     if ( $upgrade =~ /HeatWHP-UpgradeTo-aspire-CCASHP-a/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-CCASHP-asp-a"  ;
       $validupgrade = 1; 
         
       last SWITCH; 
     }
    
         if ( $upgrade =~ /HeatWHP-UpgradeTo-aspire-CCASHP-b/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-CCASHP-asp-b"  ;
       $validupgrade = 1; 
         
       last SWITCH; 
     }
     
     
          if ( $upgrade =~ /HeatWHP-UpgradeTo-aspire-CCASHP-c/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-CCASHP-asp-c"  ;
       $validupgrade = 1; 
         
       last SWITCH; 
     }
    

     
    
     if ( $upgrade =~ /HeatWHP-UpgradeTo-AllElecGSHP/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-GSHP-ref"  ;
       $validupgrade = 1; 
         
       last SWITCH; 
     }  


     
     
#                    "EMMC-elec-reg-2016" => ["EMMC-elec-reg-2016"],
#                    "EMMC-gas-reg-2016"  => ["EMMC-gas-reg-2016"],
#                    "EMMC-oil-reg-2016"  => ["EMMC-oil-reg-2016"],
#                    
#                    "EMMC-elec-reg-2025" => ["EMMC-elec-reg-2025"],
#                    "EMMC-gas-reg-2025"  => ["EMMC-gas-reg-2025"],
#                    "EMMC-oil-reg-2025"  => ["EMMC-oil-reg-2025"],
#                    
#                    "EMMC-ElecOil-asp-ccashp-a"      => ["EMMC-Elec-asp-ccashp-a"],
#                    "EMMC-ElecOil-asp-ccashp-b"      => ["EMMC-Elec-asp-ccashp-b"],
#                    "EMMC-ElecOil-asp-ccashp-c"      => ["EMMC-Elec-asp-ccashp-c"],
#                    
#                    "EMMC-Gas-Hp-a"      => ["EMMC-SH-gas-UpgradeTo-GFHP-a"],
#                    "EMMC-Gas-Hp-b"      => ["EMMC-SH-gas-UpgradeTo-GFHP-b"],
#                    "EMMC-Gas-Hp-c"      => ["EMMC-SH-gas-UpgradeTo-GFHP-c"],
#                    "EMMC-Gas-Hp-d"      => ["EMMC-SH-gas-UpgradeTo-GFHP-d"]     
#    
     

     
     # 2016 regs
     if ( $upgrade =~ /EMMC-elec-reg-2016/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2016-elec"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }

     if ( $upgrade =~ /EMMC-gas-reg-2016/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2016-gas"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }
     

     if ( $upgrade =~ /EMMC-oil-reg-2016/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2016-oil"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }     

     
     # 2025 regs 
     if ( $upgrade =~ /EMMC-elec-reg-2025a/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2016-elec"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }
     
     if ( $upgrade =~ /EMMC-elec-reg-2025b/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2025-elec-b"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }
     
    if ( $upgrade =~ /EMMC-elec-reg-2025c/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2025-elec-c"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }
     
     
     

     if ( $upgrade =~ /EMMC-gas-reg-2025/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2025-gas"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }
     

     if ( $upgrade =~ /EMMC-oil-reg-2025/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-reg-2025-oil"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }          
     
     
     # Electric HP targets 
     if ( $upgrade =~ /EMMC-Elec-asp-ccashp-a/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-asp-2025-elec-a"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }
     
     if ( $upgrade =~ /EMMC-Elec-asp-ccashp-b/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-asp-2025-elec-b"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }
     
     if ( $upgrade =~ /EMMC-Elec-asp-ccashp-c/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-asp-2025-elec-c"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }
     
     
     
     # Gas HP targets. 
     if ( $upgrade =~ /EMMC-SH-asp-GFHP-a/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-asp-2025-gashp-a"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }

     
     if ( $upgrade =~ /EMMC-SH-asp-GFHP-b/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-asp-2025-gashp-b"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }
     
     if ( $upgrade =~ /EMMC-SH-asp-GFHP-c/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-asp-2025-gashp-c"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }

     
     if ( $upgrade =~ /EMMC-SH-asp-GFHP-d/ ) {

       $choiceHash{"Opt-GhgHeatingCooling"} = "oee-asp-2025-gashp-d"  ;
       $validupgrade = 1;  
       last SWITCH;      
     
     }
          
     
     
     
     
    
     if ( $upgrade =~ /HeatWHP-UpgradeTo-GasFired-HP/ ) {
     
       if ($choiceHash{"ID"} =~ /2020-2024.*/ ||
           $choiceHash{"ID"} =~ /2006-2011.*/ ||
           $choiceHash{"ID"} =~ /2012-2019*/ ){
     
           $choiceHash{"Opt-GhgHeatingCooling"} = "test-HP-gas-a-HRV"  ;
               
        }else{
           $choiceHash{"Opt-GhgHeatingCooling"} = "test-HP-gas-a-noHRV";
       }            
       $validupgrade = 1;  
       last SWITCH;      
     
     }
    

    #=========================================================================
    # HVAC upgrade - heating: Upgrade baseline to high-efficiency hvac
    #                         (with no fuel switch )
    #=========================================================================    
    
    # Oil scenario
    if ( $upgrade =~ /retrofit-oil-heating-high-effciency/ ){
    
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Oil/ ){

          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-oil-ref"  ;
                   
          $validupgrade = 1;
          
      }

      
      last SWITCH; 
    }    
    
    
    # Gas scenario
    if ( $upgrade =~ /retrofit-gas-heating-high-effciency/ ){
    
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Gas/ ){

          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-gas-ref"  ;
                   
          $validupgrade = 1;
          
      }

      
      last SWITCH; 
    }       
    

    # Elec baseboard->CCASHP
    if ( $upgrade =~ /retrofit-elec-heating-CCASHP/ ){
    
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Elect/ ){

          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-CCASHP-ref"  ;
                   
          $validupgrade = 1;
          
      }

      
      last SWITCH; 
    }         
    
    
    # Elec Baseboard -> GSHP. 
    if ( $upgrade =~ /retrofit-elec-heating-GSHP/ ){
    
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /Elect/ ){

          $choiceHash{"Opt-GhgHeatingCooling"} = "oee-GSHP-ref"  ;
                   
          $validupgrade = 1;
          
      }

      
      last SWITCH; 
    }         
    
        
    if ( $upgrade =~ /retrofit-minisplit/ ){

      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /ghg-hvac-..-Oil/ ){
    
         $choiceHash{"Opt-GhgHeatingCooling"} =~ s/ghg-hvac-/ghg-hvac-CCASHPDisp-/g; 
         $validupgrade = 1;   
      
      }

      
      if ( $choiceHash{"Opt-GhgHeatingCooling"} =~ /ghg-hvac-..-Elect/ ){
    
         $choiceHash{"Opt-GhgHeatingCooling"} =~ s/ghg-hvac-/ghg-hvac-CCASHPDisp-/g; 
         $validupgrade = 1;   
      
      }
      
      last SWITCH;
    
    }
  
    
    
    
    
    

    
    
    
    
    
    
    #=========================================================================
    # DHW upgrade - Upgrade baseline to high-efficiency water heater
    #               (with no fuel switch )
    #=========================================================================    
    
    # Oil scenario
    if ( $upgrade =~ /retrofit-oil-dhw-high-effciency/ ){
    
      if ( $choiceHash{"Opt-DHWSystem"} =~ /Oil/ ){

          $choiceHash{"Opt-DHWSystem"} = "oee-oildhw-ref"  ;
                   
          $validupgrade = 1;
          
      }

      
      last SWITCH; 
    }    
    
    # Gas scenario
    if ( $upgrade =~ /retrofit-gas-dhw-high-effciency/ ){
    
      if ( $choiceHash{"Opt-DHWSystem"} =~ /Gas/ ){

          $choiceHash{"Opt-DHWSystem"} = "oee-gasdhw-ref"  ;
                   
          $validupgrade = 1;
          
      }

      
      last SWITCH; 
    }    
    
    # Elec storage scenario
    if ( $upgrade =~ /retrofit-elec-dhw-storage/ ){
    
      if ( $choiceHash{"Opt-DHWSystem"} =~ /Elect/ ){

          $choiceHash{"Opt-DHWSystem"} = "oee-elecstorage-ref"  ;
                   
          $validupgrade = 1;
          
      }

      
      last SWITCH; 
    }    
    
    
    # Elec storage scenario
    if ( $upgrade =~ /retrofit-elec-dhw-hp/ ){
    

      if ( $choiceHash{"Opt-DHWSystem"} =~ /Elect/ || $choiceHash{"Opt-DHWSystem"} =~ /Gas/ ){

     # if ( $choiceHash{"Opt-DHWSystem"} =~ /Elect/ ){

#          $choiceHash{"Opt-DHWSystem"} = "oee-elecHP-ref"  ;
        if     ( $upgrade =~ /retrofit-elec-dhw-hp-1_4/ ){$choiceHash{"Opt-DHWSystem"} = "elec-HPWH-ref1_4"; }
        elsif  ( $upgrade =~ /retrofit-elec-dhw-hp-1_6/ ){$choiceHash{"Opt-DHWSystem"} = "elec-HPWH-ref1_6"; }
        elsif  ( $upgrade =~ /retrofit-elec-dhw-hp-1_8/ ){$choiceHash{"Opt-DHWSystem"} = "elec-HPWH-ref1_8"; }
        elsif  ( $upgrade =~ /retrofit-elec-dhw-hp-2_0/ ){$choiceHash{"Opt-DHWSystem"} = "elec-HPWH-ref2_0"; }
        elsif  ( $upgrade =~ /retrofit-elec-dhw-hp-2_2/ ){$choiceHash{"Opt-DHWSystem"} = "elec-HPWH-ref2_2"; }
        elsif  ( $upgrade =~ /retrofit-elec-dhw-hp-2_4/ ){$choiceHash{"Opt-DHWSystem"} = "elec-HPWH-ref2_4"; }
        elsif  ( $upgrade =~ /retrofit-elec-dhw-hp-2_6/ ){$choiceHash{"Opt-DHWSystem"} = "elec-HPWH-ref2_6"; }
        elsif  ( $upgrade =~ /retrofit-elec-dhw-hp-3_5/ ){$choiceHash{"Opt-DHWSystem"} = "elec-HPWH-ref3_5"; }
        else{$choiceHash{"Opt-DHWSystem"} = "oee-elecHP-ref"  ;}

                   
          $validupgrade = 1;
          
      }
      last SWITCH; 
    }    
        
    # Gas HP-wh scenario
    if ( $upgrade =~ /retrofit-gas-hpwh/ ){
    
     #if ( $choiceHash{"Opt-DHWSystem"} =~ /Elect/ ){
     #
     #    $choiceHash{"Opt-DHWSystem"} = "gas-HPWH-ref"  ;
     #             
     #    $validupgrade = 1;
     #    
     #}else{ 
      
      

        if     ( $upgrade =~ /retrofit-gas-hpwh-0_5/ ){$choiceHash{"Opt-DHWSystem"} = "gas-HPWH-ref0_5"; }
        elsif  ( $upgrade =~ /retrofit-gas-hpwh-0_8/ ){$choiceHash{"Opt-DHWSystem"} = "gas-HPWH-ref0_8"; }
        elsif  ( $upgrade =~ /retrofit-gas-hpwh-1_0/ ){$choiceHash{"Opt-DHWSystem"} = "gas-HPWH-ref1_0"; }
        elsif  ( $upgrade =~ /retrofit-gas-hpwh-1_2/ ){$choiceHash{"Opt-DHWSystem"} = "gas-HPWH-ref1_2"; }
        elsif  ( $upgrade =~ /retrofit-gas-hpwh-1_4/ ){$choiceHash{"Opt-DHWSystem"} = "gas-HPWH-ref1_4"; }
        elsif  ( $upgrade =~ /retrofit-gas-hpwh-1_6/ ){$choiceHash{"Opt-DHWSystem"} = "gas-HPWH-ref1_6"; }
        else{$choiceHash{"Opt-DHWSystem"} = "gas-HPWH-ref"  ;}
                   
        $validupgrade = 1;      
      
      #}
      
      last SWITCH; 
    }

        
    
    #=========================================================================
    # Envelope insulation : Main Walls, Retrofit A
    #=========================================================================
        
    if ( $upgrade =~ /retrofit-main-wall-a/ ){
    
      if ( $choiceHash{"ID"} =~ /Pre-1946.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-17-eff"  ;
                   
          $validupgrade = 1;
          
      }
      
      if ( $choiceHash{"ID"} =~ /1946-1983.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-24-eff"  ;
                   
          $validupgrade = 1;
          
      }
      
      # .........
      # 1984-1995
      if ( $choiceHash{"ID"} =~ /1984-1995_Gas/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-23-eff"  ;
                   
          $validupgrade = 1;
          
      }            

      if ( $choiceHash{"ID"} =~ /1984-1995_Elect/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-24-eff"  ;
                   
          $validupgrade = 1;
          
      }            
      
      if ( $choiceHash{"ID"} =~ /1984-1995_Oil/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-23-eff"  ;
                   
          $validupgrade = 1;
          
      }        
      
      
      # .........
      # 1996-2005
      if ( $choiceHash{"ID"} =~ /1996-2005_Gas/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-24-eff"  ;
                   
          $validupgrade = 1;
          
      }            
 
      if ( $choiceHash{"ID"} =~ /1996-2005_Elect/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-25-eff"  ;
                   
          $validupgrade = 1;
          
      }            
      
      if ( $choiceHash{"ID"} =~ /1996-2005_Oil/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-24-eff"  ;
                   
          $validupgrade = 1;
          
      }        
            
      
      # .........
      # 2006-2011 - same as prior.
      if ( $choiceHash{"ID"} =~ /2006-2011_Gas/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-24-eff"  ;
                   
          $validupgrade = 1;
          
      }            

      if ( $choiceHash{"ID"} =~ /2006-2011_Elect/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-25-eff"  ;
                   
          $validupgrade = 1;
          
      }            
      
      if ( $choiceHash{"ID"} =~ /2006-2011_Oil/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-24-eff"  ;
                   
          $validupgrade = 1;
          
      }  
      
      # New construction Rulesets go here. 
      
      
      
      last SWITCH;  
    }    
           
    
    
    #=========================================================================
    # Envelope insulation : Main Walls, Retrofit B
    #=========================================================================
        
    if ( $upgrade =~ /retrofit-main-wall-b/ ){
    
      if ( $choiceHash{"ID"} =~ /Pre-1946.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-30-eff"  ;
                   
          $validupgrade = 1;
          
      }
      
      if ( $choiceHash{"ID"} =~ /1946-1983.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-30-eff"  ;
                   
          $validupgrade = 1;
          
      }
      


      # .........
      # 1984-1995 (b)
      if ( $choiceHash{"ID"} =~ /1984-1995_Gas/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-33-eff"  ;
                   
          $validupgrade = 1;
          
      }            

      if ( $choiceHash{"ID"} =~ /1984-1995_Elect/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-34-eff"  ;
                   
          $validupgrade = 1;
          
      }            
      
      if ( $choiceHash{"ID"} =~ /1984-1995_Oil/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-33-eff"  ;
                   
          $validupgrade = 1;
          
      }        
      
      
      # .........
      # 1996-2005 (b)
      if ( $choiceHash{"ID"} =~ /1996-2005_Gas/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-34-eff"  ;
                   
          $validupgrade = 1;
          
      }            

      if ( $choiceHash{"ID"} =~ /1996-2005_Elect/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-35-eff"  ;
                   
          $validupgrade = 1;
          
      }            
      
      if ( $choiceHash{"ID"} =~ /1996-2005_Oil/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-34-eff"  ;
                   
          $validupgrade = 1;
          
      }        
            
      
      # .........
      # 2006-2011 - same as prior.
      if ( $choiceHash{"ID"} =~ /2006-2011_Gas/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-34-eff"  ;
                   
          $validupgrade = 1;
          
      }            

      if ( $choiceHash{"ID"} =~ /2006-2011_Elect/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-35-eff"  ;
                   
          $validupgrade = 1;
          
      }            
      
      if ( $choiceHash{"ID"} =~ /2006-2011_Oil/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-34-eff"  ;
                   
          $validupgrade = 1;
          
      }  
      
      # New construction Rulesets go here. 
      
      
      
      
      

      
      last SWITCH; 
    }    
    
   
    #=========================================================================
    # Envelope insulation : Attic, Retrofit A (6in-cellulous)
    #=========================================================================
        
    if ( $upgrade =~ /retrofit-Ceil-add-06in-cellulous/ ){
    
      if ( $choiceHash{"ID"} =~ /Pre-1946.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR40"  ;
                   
          $validupgrade = 1;
          
      }
      
      if ( $choiceHash{"ID"} =~ /1946-1983.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR50"  ;
                   
          $validupgrade = 1; 
          
      }
      


      # .........
      # 1984-1995
      if ( $choiceHash{"ID"} =~ /1984-1995.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR50"  ;
                   
          $validupgrade = 1;
          
      }            

      
      # .........
      # 1996-2005
      if ( $choiceHash{"ID"} =~ /1996-2005.*/ ){
          $choiceHash{"Opt-Ceilings"} = "CeilR60"  ;
          $validupgrade = 1;
          
      }            


      # .........
      # 2006-2011 - same as prior.
      if ( $choiceHash{"ID"} =~ /2006-2011.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR60"  ;
                   
          $validupgrade = 1;
          
      }   

      # .........
      # 2006-2011 - same as prior.
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR70"  ;  # Can we get to R70?
          $validupgrade = 1;
          
      }   
      
      
      # New construction Rulesets go here. 
      
        
      last SWITCH; 
    }    
      
  
    #=========================================================================
    # Envelope insulation : Attic, Retrofit B (12in-cellulous)
    #=========================================================================
        
    if ( $upgrade =~ /retrofit-Ceil-add-12in-cellulous/ ){
    
      if ( $choiceHash{"ID"} =~ /Pre-1946.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR60"  ;
                   
          $validupgrade = 1;
          
      }
      
      if ( $choiceHash{"ID"} =~ /1946-1983.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR70"  ;  # Can we go this high?
                   
          $validupgrade = 1;
          
      }
      


      # .........
      # 1984-1995
      if ( $choiceHash{"ID"} =~ /1984-1995.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR70"  ;
                   
          $validupgrade = 1;
          
      }            

      
      # .........
      # 1996-2005
      if ( $choiceHash{"ID"} =~ /1996-2005.*/ ){
          $choiceHash{"Opt-Ceilings"} = "CeilR80"  ; # Can we get to R70
          $validupgrade = 1;
          
      }            


      # .........
      # 2006-2011 - same as prior.
      if ( $choiceHash{"ID"} =~ /2006-2011.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR80"  ;   # Can we get to R70?
                   
          $validupgrade = 1;
          
      }   

      # .........
      # 2006-2011 - same as prior.
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR90"  ;  # Can we get to R70?
          $validupgrade = 0;  # Can't get to R90./
          
      }   
      
      
      # New construction Rulesets go here. 
      
        
      last SWITCH; 
    }    
      
      
 
    #=========================================================================
    # Envelope Air-sealing : Retrofit 
    #=========================================================================    
    
    
            
    if ( $upgrade =~ /retrofit-airseal-level-a/ ){
    
      my ( $junk1,$junk2,$oldACH ) = split /_/,  $choiceHash{"Opt-ACH"}; 
      
      my $achImp = 0;   my $newACH = 0;  
    
      if ( $choiceHash{"ID"} =~ /Pre-1946.*/ ){

          $achImp = 0.12;
                            
          $validupgrade = 1;
          
      }
      
      if ( $choiceHash{"ID"} =~ /1946-1983.*/ ){

          $achImp = 0.07;    
                   
          $validupgrade = 1;
          
      }
      


      # .........
      # 1984-1995
      if ( $choiceHash{"ID"} =~ /1984-1995.*/ ){

          $achImp = 0.05;    
                   
          $validupgrade = 1;
          
      }            

      
      # .........
      # 1996-2005
      if ( $choiceHash{"ID"} =~ /1996-2005.*/ ){
          
          $achImp = 0.04;   
          $validupgrade = 1;
          
      }            


      # .........
      # 2006-2011 - same as prior.
      if ( $choiceHash{"ID"} =~ /2006-2011.*/ ){
     
     
          $achImp = 0.02; 
          $validupgrade = 1;
          
      }   

      # .........
      # 2006-2011 - same as prior.
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ){

          $achImp = 0.02; 
          $validupgrade = 1;
          
      }   
      
      if ( $validupgrade ){
      
        $newACH =  (int(( $oldACH * ( 1.0 - $achImp ) ) * 10.0))/10.0; 
      
        $choiceHash{"Opt-ACH"} = "retro_ACH_$newACH";  
      
      }
      
      last SWITCH;  
    }    
      
      
 
    #=========================================================================
    # Windows: Same spec, different costs depending on new/retrofit. 
    #=========================================================================    
    
          
      
    if (         
         ( $upgrade =~ /NewCodes-Windows.*/ && $choiceHash{"ID"} =~ /2012-2019.*/ ) ||
         ( $upgrade =~ /retrofit-Windows.*/ ) 
        ){ 
    
        if ( $upgrade =~ /Windows-HG-Double/ )
           { $choiceHash{"Opt-CasementWindows"} =  "BCLEEP-LG-Double" ; $validupgrade = 1; }

        if ( $upgrade =~ /Windows-HG-Double/ )
           { $choiceHash{"Opt-CasementWindows"} =  "BCLEEP-HG-Double" ; $validupgrade = 1; }
           
        if ( $upgrade =~ /Windows-LGi89-Triple/ )
           { $choiceHash{"Opt-CasementWindows"} =  "BCLEEP-LGi89-Triple" ; $validupgrade = 1; }           
           
        if ( $upgrade =~ /Windows-HGi89-Triple-b/ )
           { $choiceHash{"Opt-CasementWindows"} =  "BCLEEP-HGi89-Triple-b" ; $validupgrade = 1; }        		   
           
       
      last SWITCH; 
    
    }elsif($upgrade =~ /NewCodes-Windows.*/ ){
      # do nothing
      last SWITCH; 
    }
    
    
    
    
    #=========================================================================
    # New construction: Envelope Air-sealing -> 1.5 / 1.0 / 0.6 ACH
    #=========================================================================    

    if ( $upgrade =~ /NewCodes-ACH-1.5/ ){
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ){

           $choiceHash{"Opt-ACH"} = "retro_ACH_1.5";
           $validupgrade = 1;
          
      } 
      last SWITCH; 
    }
    
    if ( $upgrade =~ /NewCodes-ACH-1.0/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ){
    
           $choiceHash{"Opt-ACH"} = "retro_ACH_1";
           $validupgrade = 1;
          
      } 
      last SWITCH; 
    }

    if ( $upgrade =~ /NewCodes-ACH-0.6/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ){
    
           $choiceHash{"Opt-ACH"} = "retro_ACH_0.6";
           $validupgrade = 1; 
          
      } 
      last SWITCH; 
    } 
    
    
 
    #=========================================================================
    # New Construction: Attic insulation :  -> R70, R80, R90
    #=========================================================================

        
    if ( $upgrade =~ /NewCodes-ceilR60/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR60"  ;
                   
          $validupgrade = 1; 
          
      }
      last SWITCH; 
    }

    
    if ( $upgrade =~ /NewCodes-ceilR70/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR70"  ;
                   
          $validupgrade = 1; 
          
      }
      last SWITCH; 
    }
    
        
    if ( $upgrade =~ /NewCodes-ceilR80/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  || 
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR80"  ;
                   
          $validupgrade = 1;
          
      }
      last SWITCH; 
    }    
    
    if ( $upgrade =~ /NewCodes-ceilR90/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  || 
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-Ceilings"} = "CeilR90"  ;
                   
          $validupgrade = 1;
          
      }
      last SWITCH; 
    }     
    
    
    #=========================================================================
    # New Construction: main wall 
    #=========================================================================
        
        
    # LEEP Stud_2x6_1in_XPS_R-23
   
    if ( $upgrade =~ /NewCodes-MainWallInsulation-R23/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-23-eff"  ;
                   
          $validupgrade = 1; 
          
      }
      last SWITCH; 
    }

    # LEEP Stud_2x6_1.5in_XPS_R-25


    if ( $upgrade =~ /NewCodes-MainWallInsulation-R25/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-25-eff"  ;
                   
          $validupgrade = 1; 
          
      }
      last SWITCH; 
    }
 
 
    # LEEP Stud_2x6_2in_XPS_R-29

    if ( $upgrade =~ /NewCodes-MainWallInsulation-R29/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-29-eff"  ;
                   
          $validupgrade = 1; 
          
      }
      last SWITCH; 
    }
 
  
    # LEEP Stud_2x6_3in_XPS_R-34

    if ( $upgrade =~ /NewCodes-MainWallInsulation-R34/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-34-eff"  ;
                   
          $validupgrade = 1; 
          
      }
      last SWITCH; 
    }
 
   
    # LEEP Stud_2x6_4in_XPS_R-39

    if ( $upgrade =~ /NewCodes-MainWallInsulation-R39/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-39-eff"  ;
                   
          $validupgrade = 1; 
          
      }
      last SWITCH; 
    }
 
 
     # LEEP DblStud_10in_cell_R-34

    if ( $upgrade =~ /NewCodes-MainWallDblStd-R34/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-34-eff"  ;
                   
          $validupgrade = 1; 
          
      }
      last SWITCH; 
    }
 
      # LEEP DblStud_10in_cell_R-41

    if ( $upgrade =~ /NewCodes-MainWallDblStd-R41/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){

          $choiceHash{"Opt-GenericWall_1Layer_definitions"} = "Generic_Wall_R-41-eff"  ;
                   
          $validupgrade = 1; 
          
      }
      last SWITCH; 
    }
                
    
    #=========================================================================
    # New Construction: Below-grade wall/slab
    #=========================================================================
          
    if ( $upgrade =~ /NewCodes-Foundation-RSI3.73/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){      
    
            $choiceHash{"Opt-BasementConfiguration"}= "GHG-bsm-19-RSI_3.73";
            $validupgrade = 1; 
      
      }
      last SWITCH;
      
    }     

    if ( $upgrade =~ /NewCodes-Foundation-RSI5.46/ ){
    
      if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){      
    
            $choiceHash{"Opt-BasementConfiguration"}= "GHG-bsm-22-RSI_5.46";
            $validupgrade = 1; 
      
      }
      last SWITCH;
      
    }   

      
    #=========================================================================
    # New codes / update Heating and hot water if / as appropriate
    #=========================================================================
    
    
    if ( $upgrade =~ /NewCodes-oil-heating-high-effciency/ ||
           $upgrade =~ /NewCodes-gas-heating-high-effciency/ || 
           $upgrade =~ /NewCodes-elec-heating-CCASHP/        ||
           $upgrade =~ /NewCodes-elec-heating-GSHP/          || 
           $upgrade =~ /NewCodes-elec-dhw-hp/                ||      
           $upgrade =~ /NewCodes-oil-dhw-high-effciency/     ||      
           $upgrade =~ /NewCodes-gas-dhw-high-effciency/     ||      
           $upgrade =~ /NewCodes-elec-dhw-storage/           ||     
           $upgrade =~ /NewCodes-elec-dhw-hp/                   ){
           
        if ( $choiceHash{"ID"} =~ /2012-2019.*/ ||
           $choiceHash{"ID"} =~ /2020-2024.*/  ||  
           $choiceHash{"ID"} =~ /2025-onwards.*/ ){              
      
          
            $validupgrade = 1  ; 
           
           
            #Heating 
            if ( $upgrade =~ /NewCodes-gas-heating-high-effciency/ && 
                 $choiceHash{"ID"} =~ /Gas/ ) {
            
              $choiceHash{"Opt-GhgHeatingCooling"} =  "oee-gas-ref" ;           
                 
            }
            
            
            if ( $upgrade =~ /NewCodes-oil-heating-high-effciency/ && 
                 $choiceHash{"ID"} =~ /Oil/ ) {
            
              $choiceHash{"Opt-GhgHeatingCooling"} =  "oee-oil-ref" ;           
                 
            }
               

            if ( $upgrade =~ /NewCodes-elec-heating-CCASHP/ && 
                 $choiceHash{"ID"} =~ /Elect/ ) {
            
              $choiceHash{"Opt-GhgHeatingCooling"} =  "oee-CCASHP-ref" ;           
                 
            }
               
            if ( $upgrade =~ /NewCodes-elec-heating-GSHP/ && 
                 $choiceHash{"ID"} =~ /Elect/ ) {
            
              $choiceHash{"Opt-GhgHeatingCooling"} =  "oee-CCASHP-ref" ;           
                 
            }               
      
            # DHW 
            if ( $upgrade =~ /NewCodes-gas-heating-high-effciency/ && 
                 $choiceHash{"ID"} =~ /Gas/ ) {
            
              $choiceHash{"Opt-DHWSystem"} =  "oee-gasdhw-ref" ;           
                 
            }
            
            
            if ( $upgrade =~ /NewCodes-gas-dhw-high-effciency/ && 
                 $choiceHash{"ID"} =~ /Oil/ ) {
            
              $choiceHash{"Opt-DHWSystem"} =  "oee-oildhw-ref" ;           
                 
            }
               

            if ( $upgrade =~ /NewCodes-elec-dhw-storage/ && 
                 $choiceHash{"ID"} =~ /Elect/ ) {
            
              $choiceHash{"Opt-DHWSystem"} =  "oee-elecstorage-ref" ;           
                 
            }
               
            if ( $upgrade =~ /NewCodes-elec-dhw-hp/ && 
                 $choiceHash{"ID"} =~ /Elect/ ) {
            
              $choiceHash{"Opt-DHWSystem"} =  "oee-elecHP-ref" ;            
                 
            }         
      
      
        }
        
        last SWITCH;
      
    }
      
    
    
    
     
    #=========================================================================
    # Renewable energy systems: Similar costs / specs for new/retrofit.
    #=========================================================================
            
    
    if ( $upgrade =~ /Renewables-DWHR-4-60/ ){
    
      $choiceHash{"Opt-DWHRandSDHW"} = "DWHR-4-60";
      $validupgrade = 1; 
      last SWITCH;
    }
    
    
    if ( $upgrade =~ /Renewables-SDHW-2-plate/ ){
    
      $choiceHash{"Opt-DWHRandSDHW"} = "2-plate";
      $validupgrade = 1; 
      last SWITCH;
    }    
    
    if ( $upgrade =~ /Renewables-SDHW-2-plate+DWHR-60/ ){
    
      $choiceHash{"2-plate-DWHR-4-60"} = "";
      $validupgrade = 1; 
      last SWITCH;
    }    
        
    if ( $upgrade =~ /Renewables-5kW-PV/ ){
    
      $choiceHash{"Opt-StandoffPV"} = "SizedPV|5kW";
      $validupgrade = 1; 
      last SWITCH;
    }    
   
    #=========================================================================
    # EMMC Rulesets for new/retrofit windows
    #=========================================================================
        
#   if (         
#         ( $upgrade =~ /NewCodes-Windows.*/  ||
#         ( $upgrade =~ /retrofit-Windows.*/ ) 
#        ){ 
    
        if ( $upgrade =~ /Windows-EMMC-Upgrade-1-low-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-1-low-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }

        if ( $upgrade =~ /Windows-EMMC-Upgrade-1-mid-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-1-mid-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }

        if ( $upgrade =~ /Windows-EMMC-Upgrade-1-high-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-1-high-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }
	
        if ( $upgrade =~ /Windows-EMMC-Upgrade-1-hg-on-S/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-1-hg-on-S" ; $validupgrade = 1; 
		   last SWITCH;
		   }
    
	     if ( $upgrade =~ /Windows-EMMC-Upgrade-2-low-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-2-low-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }

        if ( $upgrade =~ /Windows-EMMC-Upgrade-2-mid-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-2-mid-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }

        if ( $upgrade =~ /Windows-EMMC-Upgrade-2-high-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-2-high-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }
	
        if ( $upgrade =~ /Windows-EMMC-Upgrade-2-hg-on-S/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-2-hg-on-S" ; $validupgrade = 1; 
		   last SWITCH;
		   }
	
	     if ( $upgrade =~ /Windows-EMMC-Upgrade-3-low-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-3-low-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }

        if ( $upgrade =~ /Windows-EMMC-Upgrade-3-mid-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-3-mid-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }

        if ( $upgrade =~ /Windows-EMMC-Upgrade-3-high-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-3-high-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }
	
        if ( $upgrade =~ /Windows-EMMC-Upgrade-3-hg-on-S/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-3-hg-on-S" ; $validupgrade = 1; 
		   last SWITCH;
		   }
	
	    if ( $upgrade =~ /Windows-EMMC-Upgrade-4-low-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-4-low-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }

        if ( $upgrade =~ /Windows-EMMC-Upgrade-4-mid-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-4-mid-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }

        if ( $upgrade =~ /Windows-EMMC-Upgrade-4-high-gain/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-4-high-gain" ; $validupgrade = 1; 
		   last SWITCH;
		   }
	
        if ( $upgrade =~ /Windows-EMMC-Upgrade-4-hg-on-S/ )
           { $choiceHash{"Opt-CasementWindows"} =  "EMMC-Upgrade-4-hg-on-S" ; $validupgrade = 1; 
		   last SWITCH;
		   }
	

        if ( $upgrade =~ /Upgrade-U-0_8/ )
           { $choiceHash{"Opt-CasementWindows"} =  "Upgrade-U-0_8" ; $validupgrade = 1; 
		   last SWITCH;
		   }             

        if ( $upgrade =~ /Upgrade-U-1_2/ )
           { $choiceHash{"Opt-CasementWindows"} =  "Upgrade-U-1_2" ; $validupgrade = 1; 
		   last SWITCH;
		   }             

	   if ( $upgrade =~ /Upgrade-U-1_6/ )
           { $choiceHash{"Opt-CasementWindows"} =  "Upgrade-U-1_6" ; $validupgrade = 1; 
		   last SWITCH;
		   }             

	   if ( $upgrade =~ /Upgrade-U-2_0/ )
           { $choiceHash{"Opt-CasementWindows"} =  "Upgrade-U-2_0" ; $validupgrade = 1; 
		   last SWITCH;
		   }      
    # < New rulesets go here: >  


    
    die ("\n\nUnsupported upgrade (\"$upgrade\")!\n\n"); 

  }    

  return $validupgrade; 
 
  
 #my %UpgradeTable  = ( "Opt-All"               => "as-found" , 
 #                      "Opt-GhgHeatingCooling" => "oee-gas-ref",
 #                      "Opt-GhgHeatingCooling" => "oee-CCASHP-ref",
 #                      "Opt-GhgHeatingCooling" => "oee-ASHP-ref",
 #               "Opt-GhgHeatingCooling" => "oee-GSHP-ref",
 #               "Opt-DHWSystem"         => "2025-onwards-Gas-dhw", 
 #               "Opt-DHWSystem"         => "2025-onwards-Oil-dhw", 
 #               "Opt-DHWSystem"         => "2025-onwards-Elect-dhw", 
 #               "Opt-DWHRandSDHW"       => "DWHR-4-36",
 #               "Opt-DWHRandSDHW"       => "DWHR-4-60",
 #               "Opt-DWHRandSDHW"       => "1-plate",
 #               "Opt-DWHRandSDHW"       => "2-plate"
 #               
 #               
 #              ); 
 #



}

sub WriteChoiceFile($){

   my ($FileName) = @_;
     
   my $encoding = ":encoding(UTF-8)";
   
   #HOT2000 - definitions 
   
   open(OPTIONSOUT, ">$FileName")
       || die "$0: Can't open $FileName in write-open mode: $!";    
  
   print OPTIONSOUT "! Choice file $FileName generated for GHG work.\n";
 
   
  
   # Start H2k definitions. 
  
   # if locations are to be spec'd by GenOpt
   print OPTIONSOUT "Opt-Location         : <LOCATION>\n";  
   
   # if locations are to be drawn from csv file:
   print OPTIONSOUT "Opt-Location         : ".$choiceHash{"Opt-Location"}."\n"; 
   
   print OPTIONSOUT "Opt-DBFiles          : H2KCodeLibFile\n"; 
   print OPTIONSOUT "Opt-FuelCost         : rates2016\n"; 
   
   print OPTIONSOUT "Opt-ACH              : ".$choiceHash{"Opt-ACH"}."\n";
   print OPTIONSOUT "Opt-MainWall         : GenericWall_1Layer\n";
   print OPTIONSOUT "Opt-GenericWall_1Layer_definitions : ".$choiceHash{"Opt-GenericWall_1Layer_definitions"}."\n";
   print OPTIONSOUT "Opt-Ceilings         : ".$choiceHash{"Opt-Ceilings"}."\n";
   
   
   # Added for H2k: 
   print OPTIONSOUT "Opt-H2KFoundation    : ".$choiceHash{"Opt-H2KFoundation"}."\n"; 
   
   
   print OPTIONSOUT "Opt-ExposedFloor     : ".$choiceHash{"Opt-ExposedFloor"}."\n";
   print OPTIONSOUT "Opt-CasementWindows  :  ".$choiceHash{"Opt-CasementWindows"}."\n";

   # Added for H2K 
   #print OPTIONSOUT "Opt-H2K-PV           : ".$choiceHash{"Opt-H2K-PV"}."\n"; 
   print OPTIONSOUT "Opt-H2K-PV           : NA \n"; 
   
   print OPTIONSOUT "Opt-DWHRandSDHW      : NA \n";
   
   print OPTIONSOUT "Opt-RoofPitch        : NA \n";
   
   print OPTIONSOUT "Opt-DHWSystem        : ".$choiceHash{"Opt-DHWSystem"}."\n";
   
   # Added for h2k
   print OPTIONSOUT "Opt-DWHRSystem       : ".$choiceHash{"Opt-DWHRSystem"}."\n";
   
      
   print OPTIONSOUT "Opt-HVACSystem       : ".$choiceHash{"Opt-HVACSystem"}."\n"; 
   
   print OPTIONSOUT "Opt-HRVspec          : ".$choiceHash{"Opt-HRVSpec"}."\n"; 
   
   # Parameters not yet implemented
   print OPTIONSOUT "Opt-ElecLoadScale    : NGERSNoReduction19 \n"; 
   print OPTIONSOUT "Opt-DHWLoadScale     : No-Reduction \n"; 
   print OPTIONSOUT "!GOconfig_rotate      : NA \n"; 
   print OPTIONSOUT "!Opt-OverhangWidth    : NA \n"; 
   print OPTIONSOUT "!Opt-InfilMethod      : NA\n"; 
   print OPTIONSOUT "!Opt-ExtraDrywall    : NA\n"; 
   print OPTIONSOUT "!Opt-FloorSurface    : NA\n"; 
   print OPTIONSOUT "!OPT-OPR-SCHED        : NA\n";
   print OPTIONSOUT "Opt-Archetype        : ".$choiceHash{"Opt-Archetype"}."\n";    
   
   
   
  
   close(OPTIONSOUT);
     




}




#-------------------------------------------------------------------
# Display a fatal error and quit.
#-------------------------------------------------------------------

sub fatalerror($){
  my ($err_msg) = @_;

  #if ( $gTest_params{"verbosity"} eq "very_verbose" ){
  #  #print echo_config();
  #}
  #if ($gTest_params{"logfile"}){
  #  print LOG "\nsubstitute.pl -> Fatal error: \n"; 
  #  print LOG "$err_msg\n"; 
  #}
  print "\n=========================================================\n"; 
  print "MakeOptFiles.pl -> Fatal error: \n\n";
  print "$err_msg \n";
  print "\n\n"; 
  print "MakeOptFiles.pl -> Error and warning messages:\n\n";
  #print "$ErrorBuffer \n"; 
  die "Run stopped";
}
