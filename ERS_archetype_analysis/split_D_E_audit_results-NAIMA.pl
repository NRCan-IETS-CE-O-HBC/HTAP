#!/bin/perl
 
# This script parses a ERS database file, and splits it into two; one file contains 
# the D-audit results. and the other contains the E-audit results. It's usually run 
# prior to 'combine_D_E.pl'  
 
use warnings;
use strict;

sub escape_cars($); 

# Source file for raw D-E dump. 
my $file_1 = "evaluations_d_e.csv";


# File to contain D records
my $file_D = "split-results_D_audit.txt";

# File to contain E records. 
my $file_E = "split-results_E_audit.txt";
 


   

my %SHEU_REGION_hash = (
"CALGARY_ALBERTA" => "Alberta",
"COLD^LAKE_ALBERTA" => "Alberta",
"CORONATION_ALBERTA" => "Alberta",
"EDMONTON_ALBERTA" => "Alberta",
"FORT^MCMURRAY_ALBERTA" => "Alberta",
"GRANDE^PRAIRIE_ALBERTA" => "Alberta",
"LETHBRIDGE_ALBERTA" => "Alberta",
"MEDICINE^HAT_ALBERTA" => "Alberta",
"PEACE^RIVER_ALBERTA" => "Alberta",
"RED^DEER_ALBERTA" => "Alberta",
"ROCKY^MOUNTAIN^HOUSE_ALBERTA" => "Alberta",
"SUFFIELD_ALBERTA" => "Alberta",
"ABBOTSFORD_BRITISH^COLUMBIA" => "British Columbia ",
"CASTLEGAR_BRITISH^COLUMBIA" => "British Columbia ",
"COMOX_BRITISH^COLUMBIA" => "British Columbia ",
"CRANBROOK_BRITISH^COLUMBIA" => "British Columbia ",
"FORT^NELSON_BRITISH^COLUMBIA" => "British Columbia ",
"FORT^ST.^JOHN_BRITISH^COLUMBIA" => "British Columbia ",
"KAMLOOPS_BRITISH^COLUMBIA" => "British Columbia ",
"PORT^HARDY_BRITISH^COLUMBIA" => "British Columbia ",
"PRINCE^GEORGE_BRITISH^COLUMBIA" => "British Columbia ",
"PRINCE^RUPERT_BRITISH^COLUMBIA" => "British Columbia ",
"QUESNEL_BRITISH^COLUMBIA" => "British Columbia ",
"SANDSPIT_BRITISH^COLUMBIA" => "British Columbia ",
"SMITHERS_BRITISH^COLUMBIA" => "British Columbia ",
"SUMMERLAND_BRITISH^COLUMBIA" => "British Columbia ",
"TERRACE_BRITISH^COLUMBIA" => "British Columbia ",
"TOFINO_BRITISH^COLUMBIA" => "British Columbia ",
"VANCOUVER_BRITISH^COLUMBIA" => "British Columbia ",
"VICTORIA_BRITISH^COLUMBIA" => "British Columbia ",
"WHISTLER_BRITISH^COLUMBIA" => "British Columbia ",
"WILLIAMS^LAKE_BRITISH^COLUMBIA" => "British Columbia ",
"BRANDON_MANITOBA" => "Manitoba/Saskatchewan",
"CHURCHILL_MANITOBA" => "Manitoba/Saskatchewan",
"DAUPHIN_MANITOBA" => "Manitoba/Saskatchewan",
"PORTAGE^LA^PRAIRIE_MANITOBA" => "Manitoba/Saskatchewan",
"THE^PAS_MANITOBA" => "Manitoba/Saskatchewan",
"THOMPSON_MANITOBA" => "Manitoba/Saskatchewan",
"WINNIPEG_MANITOBA" => "Manitoba/Saskatchewan",
"CHARLO_NEW^BRUNSWICK" => "Atlantic ",
"CHATHAM_NEW^BRUNSWICK" => "Atlantic ",
"FREDERICTON_NEW^BRUNSWICK" => "Atlantic ",
"MONCTON_NEW^BRUNSWICK" => "Atlantic ",
"SAINT^JOHN_NEW^BRUNSWICK" => "Atlantic ",
"BONAVISTA_NEWFOUNDLAND" => "Atlantic ",
"CARTWRIGHT_NEWFOUNDLAND" => "Atlantic ",
"DANIELS^HARBOUR_NEWFOUNDLAND" => "Atlantic ",
"DEER^LAKE_NEWFOUNDLAND" => "Atlantic ",
"GANDER_NEWFOUNDLAND" => "Atlantic ",
"GOOSE^BAY_NEWFOUNDLAND" => "Atlantic ",
"SAINT^JOHN'S_NEWFOUNDLAND" => "Atlantic ",
"STEPHENVILLE_NEWFOUNDLAND" => "Atlantic ",
"WABUSH^LAKE_NEWFOUNDLAND" => "Atlantic ",
"FORT^SMITH_NORTHWEST^TERRITORY" => "North",
"INUVIK_NORTHWEST^TERRITORY" => "North",
"NORMAN^WELLS_NORTHWEST^TERRITORY" => "North",
"YELLOWKNIFE_NORTHWEST^TERRITORY" => "North",
"GREENWOOD_NOVA^SCOTIA" => "Atlantic",
"HALIFAX_NOVA^SCOTIA" => "Atlantic",
"SYDNEY_NOVA^SCOTIA" => "Atlantic",
"TRURO_NOVA^SCOTIA" => "Atlantic",
"YARMOUTH_NOVA^SCOTIA" => "Atlantic",
"BAKER^LAKE_NUNAVUT" => "North",
"CORAL^HARBOUR_NUNAVUT" => "North",
"HALL^BEACH_NUNAVUT" => "North",
"IQALUIT_NUNAVUT" => "North",
"RESOLUTE_NUNAVUT" => "North",
"BIG^TROUT^LAKE_ONTARIO" => "Ontario",
"GORE^BAY_ONTARIO" => "Ontario",
"KAPUSKASING_ONTARIO" => "Ontario",
"KENORA_ONTARIO" => "Ontario",
"KINGSTON_ONTARIO" => "Ontario",
"LONDON_ONTARIO" => "Ontario",
"MUSKOKA_ONTARIO" => "Ontario",
"NORTH^BAY_ONTARIO" => "Ontario",
"OTTAWA_ONTARIO" => "Ontario",
"SAULT^STE.^MARIE_ONTARIO" => "Ontario",
"SIMCOE_ONTARIO" => "Ontario",
"SIOUX^LOOKOUT_ONTARIO" => "Ontario",
"SUDBURY_ONTARIO" => "Ontario",
"THUNDER^BAY_ONTARIO" => "Ontario",
"TIMMINS_ONTARIO" => "Ontario",
"TORONTO_ONTARIO" => "Ontario",
"TORONTO^MET^RES^STN_ONTARIO" => "Ontario",
"TRENTON_ONTARIO" => "Ontario",
"WIARTON_ONTARIO" => "Ontario",
"WINDSOR_ONTARIO" => "Ontario",
"CHARLOTTETOWN_PRINCE^EDWARD^ISLAND" => "Atlantic",
"SUMMERSIDE_PRINCE^EDWARD^ISLAND" => "Atlantic",
"BAGOTVILLE_QUEBEC" => "Quebec",
"BAIE-COMEAU_QUEBEC" => "Quebec",
"KUUJJUAQ_QUEBEC" => "Quebec",
"KUUJJUARAPIK_QUEBEC" => "Quebec",
"LA^GRANDE^RIVIERE_QUEBEC" => "Quebec",
"MONT-JOLI_QUEBEC" => "Quebec",
"MONTREAL_QUEBEC" => "Quebec",
"MONTREAL^MIRABEL_QUEBEC" => "Quebec",
"QUEBEC_QUEBEC" => "Quebec",
"SCHEFFERVILLE_QUEBEC" => "Quebec",
"SEPT^ILES_QUEBEC" => "Quebec",
"SHERBROOKE_QUEBEC" => "Quebec",
"STE-AGATHE-DES-MONTS_QUEBEC" => "Quebec",
"ST-HUBERT_QUEBEC" => "Quebec",
"VAL^D'OR_QUEBEC" => "Quebec",
"BROADVIEW_SASKATCHEWAN" => "Manitoba/Saskatchewan",
"ESTEVAN_SASKATCHEWAN" => "Manitoba/Saskatchewan",
"MOOSE^JAW_SASKATCHEWAN" => "Manitoba/Saskatchewan",
"NORTH^BATTLEFORD_SASKATCHEWAN" => "Manitoba/Saskatchewan",
"PRINCE^ALBERT_SASKATCHEWAN" => "Manitoba/Saskatchewan",
"REGINA_SASKATCHEWAN" => "Manitoba/Saskatchewan",
"SASKATOON_SASKATCHEWAN" => "Manitoba/Saskatchewan",
"SWIFT^CURRENT_SASKATCHEWAN" => "Manitoba/Saskatchewan",
"URANIUM^CITY_SASKATCHEWAN" => "Manitoba/Saskatchewan",
"YORKTON_SASKATCHEWAN" => "Manitoba/Saskatchewan",
"DAWSON^CITY_YUKON^TERRITORY" => "North ",
"WHITEHORSE_YUKON^TERRITORY" => "North"

);  
 
my %HDD_hash = ( 
"CALGARY_ALBERTA" =>  5000,
"COLD^LAKE_ALBERTA" =>  5860,
"CORONATION_ALBERTA" =>  5640,
"EDMONTON_ALBERTA" =>  5120,
"FORT^MCMURRAY_ALBERTA" =>  6250,
"GRANDE^PRAIRIE_ALBERTA" =>  5790,
"LETHBRIDGE_ALBERTA" =>  4500,
"MEDICINE^HAT_ALBERTA" =>  4540,
"PEACE^RIVER_ALBERTA" =>  6050,
"RED^DEER_ALBERTA" =>  5550,
"ROCKY^MOUNTAIN^HOUSE_ALBERTA" =>  5640,
"SUFFIELD_ALBERTA" =>  4770,
"ABBOTSFORD_BRITISH^COLUMBIA" =>  2860,
"CASTLEGAR_BRITISH^COLUMBIA" =>  3580,
"COMOX_BRITISH^COLUMBIA" =>  3100,
"CRANBROOK_BRITISH^COLUMBIA" =>  4400,
"FORT^NELSON_BRITISH^COLUMBIA" =>  6710,
"FORT^ST.^JOHN_BRITISH^COLUMBIA" =>  5750,
"KAMLOOPS_BRITISH^COLUMBIA" =>  3450,
"PORT^HARDY_BRITISH^COLUMBIA" =>  3440,
"PRINCE^GEORGE_BRITISH^COLUMBIA" =>  4720,
"PRINCE^RUPERT_BRITISH^COLUMBIA" =>  3900,
"QUESNEL_BRITISH^COLUMBIA" =>  4650,
"SANDSPIT_BRITISH^COLUMBIA" =>  3450,
"SMITHERS_BRITISH^COLUMBIA" =>  5040,
"SUMMERLAND_BRITISH^COLUMBIA" =>  3350,
"TERRACE_BRITISH^COLUMBIA" =>  4150,
"TOFINO_BRITISH^COLUMBIA" =>  3150,
"VANCOUVER_BRITISH^COLUMBIA" =>  2825,
"VICTORIA_BRITISH^COLUMBIA" =>  2650,
"WHISTLER_BRITISH^COLUMBIA" =>  4180,
"WILLIAMS^LAKE_BRITISH^COLUMBIA" =>  4400,
"BRANDON_MANITOBA" =>  5760,
"CHURCHILL_MANITOBA" =>  8950,
"DAUPHIN_MANITOBA" =>  5900,
"PORTAGE^LA^PRAIRIE_MANITOBA" =>  5600,
"THE^PAS_MANITOBA" =>  6480,
"THOMPSON_MANITOBA" =>  7600,
"WINNIPEG_MANITOBA" =>  5670,
"CHARLO_NEW^BRUNSWICK" =>  5500,
"CHATHAM_NEW^BRUNSWICK" =>  4950,
"FREDERICTON_NEW^BRUNSWICK" =>  4670,
"MONCTON_NEW^BRUNSWICK" =>  4680,
"SAINT^JOHN_NEW^BRUNSWICK" =>  4570,
"BONAVISTA_NEWFOUNDLAND" =>  5000,
"CARTWRIGHT_NEWFOUNDLAND" =>  6440,
"DANIELS^HARBOUR_NEWFOUNDLAND" =>  4760,
"DEER^LAKE_NEWFOUNDLAND" =>  4760,
"GANDER_NEWFOUNDLAND" =>  5110,
"GOOSE^BAY_NEWFOUNDLAND" =>  6670,
"SAINT^JOHN'S_NEWFOUNDLAND" =>  4800,
"STEPHENVILLE_NEWFOUNDLAND" =>  4850,
"WABUSH^LAKE_NEWFOUNDLAND" =>  7710,
"FORT^SMITH_NORTHWEST^TERRITORY" =>  7300,
"INUVIK_NORTHWEST^TERRITORY" =>  9600,
"NORMAN^WELLS_NORTHWEST^TERRITORY" =>  8510,
"YELLOWKNIFE_NORTHWEST^TERRITORY" =>  8170,
"GREENWOOD_NOVA^SCOTIA" =>  4140,
"HALIFAX_NOVA^SCOTIA" =>  4000,
"SYDNEY_NOVA^SCOTIA" =>  4530,
"TRURO_NOVA^SCOTIA" =>  4500,
"YARMOUTH_NOVA^SCOTIA" =>  3990,
"BAKER^LAKE_NUNAVUT" =>  10700,
"CORAL^HARBOUR_NUNAVUT" =>  10720,
"HALL^BEACH_NUNAVUT" =>  10720,
"IQALUIT_NUNAVUT" =>  9980,
"RESOLUTE_NUNAVUT" =>  12360,
"BIG^TROUT^LAKE_ONTARIO" =>  7650,
"GORE^BAY_ONTARIO" =>  4700,
"KAPUSKASING_ONTARIO" =>  6250,
"KENORA_ONTARIO" =>  5630,
"KINGSTON_ONTARIO" =>  4000,
"LONDON_ONTARIO" =>  3900,
"MUSKOKA_ONTARIO" =>  4760,
"NORTH^BAY_ONTARIO" =>  5150,
"OTTAWA_ONTARIO" =>  4500,
"SAULT^STE.^MARIE_ONTARIO" =>  4960,
"SIMCOE_ONTARIO" =>  3700,
"SIOUX^LOOKOUT_ONTARIO" =>  5950,
"SUDBURY_ONTARIO" =>  5180,
"THUNDER^BAY_ONTARIO" =>  5650,
"TIMMINS_ONTARIO" =>  5940,
"TORONTO_ONTARIO" =>  3520,
"TORONTO^MET^RES^STN_ONTARIO" =>  3890,
"TRENTON_ONTARIO" =>  4110,
"WIARTON_ONTARIO" =>  4300,
"WINDSOR_ONTARIO" =>  3400,
"CHARLOTTETOWN_PRINCE^EDWARD^ISLAND" =>  4460,
"SUMMERSIDE_PRINCE^EDWARD^ISLAND" =>  4600,
"BAGOTVILLE_QUEBEC" =>  5700,
"BAIE-COMEAU_QUEBEC" =>  6020,
"KUUJJUAQ_QUEBEC" =>  8550,
"KUUJJUARAPIK_QUEBEC" =>  9150,
"LA^GRANDE^RIVIERE_QUEBEC" =>  8100,
"MONT-JOLI_QUEBEC" =>  5370,
"MONTREAL_QUEBEC" =>  4200,
"MONTREAL^MIRABEL_QUEBEC" =>  4500,
"QUEBEC_QUEBEC" =>  5080,
"SCHEFFERVILLE_QUEBEC" =>  8550,
"SEPT^ILES_QUEBEC" =>  6200,
"SHERBROOKE_QUEBEC" =>  4700,
"STE-AGATHE-DES-MONTS_QUEBEC" =>  5390,
"ST-HUBERT_QUEBEC" =>  4490,
"VAL^D'OR_QUEBEC" =>  6180,
"BROADVIEW_SASKATCHEWAN" =>  5760,
"ESTEVAN_SASKATCHEWAN" =>  5340,
"MOOSE^JAW_SASKATCHEWAN" =>  5270,
"NORTH^BATTLEFORD_SASKATCHEWAN" =>  5900,
"PRINCE^ALBERT_SASKATCHEWAN" =>  6100,
"REGINA_SASKATCHEWAN" =>  5600,
"SASKATOON_SASKATCHEWAN" =>  5700,
"SWIFT^CURRENT_SASKATCHEWAN" =>  5150,
"URANIUM^CITY_SASKATCHEWAN" =>  7500,
"YORKTON_SASKATCHEWAN" =>  6000,
"DAWSON^CITY_YUKON^TERRITORY" =>  8120,
"WHITEHORSE_YUKON^TERRITORY" =>  6580,
);
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
# Oppen files. 
open (FILEIN1, $file_1) or die ("could not open $file_1\n");

open (FILEOUT_D, ">$file_D") or die ("could not open $file_D\n"); 
open (FILEOUT_E, ">$file_E") or die ("could not open $file_E\n"); 

# Counters
my $line_no        = 0; 
my $line_no_buffer = 0; 
my $eval_col_index = 0;
my $colindex; 

# output 
my $output   = ""; 
my $output_D = ""; 
my $output_E = ""; 



my $weatherloc_index;
my $yearbuilt_index;

my @keep_col_index; 

# Loop through file, 
#  1. Find the columns we want to keep, or optionally keep them all, 
#  2. Determine if this is a D or E record,
#  3. Store results in D or E output, 
#  4. Periodically write D or E output to file. 

$colindex = 0;



my @ERSColums = ( "POSTALCODE"              ,
               "EVAL_TYP"                ,
               "WEATHERLOC"              ,
               "YEARBUILT"               ,
               "LOCATION_ID"             ,
               "HOUSE_ID"                ,
               "PROVINCE"                ,
               "DECADEBUILT"             ,
               "FLOORAREA"               ,
               "FOOTPRINT"               ,
               "TYPEOFHOUSE"             ,
               "STOREYS"                 ,
               "FURNACETYPE"             ,
               "FURSSEFF"                ,
               "FURNACEFUEL"             ,
               "HPSOURCE"                ,
               "COP"                     ,
               "PDHWTYPE"                ,
               "PDHWEF"                  ,
               "PDHWFUEL"                ,
               "DHWHPTYPE"               ,
               "DHWHPCOP"                ,
               "CEILINS"                 ,
               "FNDWALLINS"              ,
               "MAINWALLINS"             ,
               "EGHFURNACEAEC"           ,
               "CLIENTCITY"              ,
               "WINDOWCODE"              ,
               "AIR50P"                  ,
               "EINCENTIVE"              ,
               "TOTALOCCUPANTS"          ,
               "PLANSHAPE"               ,
               "HSEVOL"                  ,
               "LEAKAR"                  ,
               "CENVENTSYSTYPE"          ,
               "EGHRATING"               ,
               "EGHDESHTLOSS"            ,
               "WINDOWCODE"              ,
               "UNITSMURBS"              ,
               "FURDCMOTOR"              ,
               "AIRCOP"                  ,
               "AIRCONDTYPE"             ,
               "ACWINDESTAR"             ,
               "NUMWINDOWS"              ,
               "CEILINGTYPE"             ,
               "ATTICCEILINGDEF"         ,
               "CAFLACEILINGDEF"         ,
               "FNDTYPE"                 ,
               "FNDDEF"                  ,
               "WALLDEF"                 ,
               "DWHRL1M"                 ,
               "DWHRM1M"                 ,
               "WTHDATA"                 ,
               "SDHWTYPE"                ,
               "SDHWFUEL"                ,
               "SDHWHPCOP"               ,
               "TOTCSIA"                 ,
               "WINDOWCODENUM"           ,
               "SUPPHTGTYPE1"            ,
               "SUPPHTGTYPE2"            ,
               "SUPPHTGFUEL1"            ,
               "SUPPHTGFUEL2"              ) ; 
             








while ( my $line = <FILEIN1> ){ 


  # Escape unnecssary spaces. 
  $line =~ s/([^\"]),([^\"])/$1_$2/g;
  # Convert spaces to '^'
  $line =~ s/\n//g;
  $line =~ s/\r//g;
  $line =~ s/ /^/g;
  $line =~ s/\"//g;
  $colindex = 0; 

  # Take the line and split it into columns
  my @textcont = split /,/, $line ; 
  
  my @columns; 
  my @header; 
  
  foreach my $text (@textcont) {
    $text = $text // "null"; 
    $text = escape_cars($text); 
    push @columns, $text ; 
    
  }
  
  # On the first line, loop through the columns and get the ones we want 
  # to keep. 
  if ($line_no == 0) {
    
    foreach my $column (@columns) {
     #print ">$column\n"; 
	   $colindex++;
	 
     # Store index (Can be tested to produce a subset of the 
     #              current column list )
	   #push @keep_col_index, $colindex-1;
	      
        
     # Also sort the location of the 'eval_type' column - we need this to
     # figure out if it's a d or e audit file
     if ( $column =~ /^EVAL_TYP/   ) { $eval_col_index   =  $colindex - 1  ; }
     if ( $column =~ /^WEATHERLOC/ ) { $weatherloc_index = $colindex  - 1  ; }
     if ( $column =~ /^YEARBUILT/  ) { $yearbuilt_index = $colindex  - 1  ; }
 
     foreach my $KeepCol ( sort( @ERSColums )){
	   
	   
	   if ( $column  =~ /^$KeepCol/ ){ 
	      print " $column | $KeepCol ?  ";
		 print " OK -------------------------------- !\n"; 
		 push @keep_col_index, $colindex-1;
	   }

	 }

    }

  }

  if ( $line_no_buffer > 4999 ){
     
     print "Dumping $line_no_buffer lines ($line_no) \n"; 
     
     
     print FILEOUT_D "$output_D";
     print FILEOUT_E "$output_E";
     
     
     
     $output_D = ""; 
     $output_E = ""; 
     
     $line_no_buffer = 0; 

  }
  
  
  
  $output = ""; 
  # Append good columns to a temp string. 
  
  
  foreach my $column (@keep_col_index){
    #print "LINE: $line_no COL:  $column \n"; 
    if ( @keep_col_index > -1  ){
	  if (defined($columns[$column]) ){ 
	    $output .= $columns[$column].",";
      }else{
	   $output .= " ,"; 
	  }
    }
  }
 
  
  
  #For header row, append SHEU columns (region / vintage ), and 
  # copy output into both D/E columns 
  if ( $columns[$eval_col_index] =~ /EVAL_TYP/ ) { $output .= "Weather-City,Weather-Prov,SHEU-region,SHEU-vintage,HDD,936-bsm-RSI,936-wall-RSI,936-attic-RSI,junk\n"; 
  
  }else{ 
  
    my $weatherloc  = $columns[$weatherloc_index];
    
    if ($weatherloc =~ /MIRABEL_QUEBEC/ ){ $weatherloc = "MONTREAL^MIRABEL_QUEBEC";}
    #if ($weatherloc =~ /YELLOWKNIFE_N\.W\.T/ ) { $weatherloc = #"YELLOWKNIFE_NORTHWEST^TERRITORY"; }
                     
    $weatherloc =~ s/ST\.\^JOHN\'S\_NEWFOUNDLAND/SAINT^JOHN'S_NEWFOUNDLAND/g; 
    $weatherloc =~ s/_N\.W\.T\./_NORTHWEST^TERRITORY/g; 
  

    
    
    my ($city,$prov) = split /_/ , $weatherloc; 
    
    $city =~ s/\^/ /g; 
    $prov =~ s/\^/ /g; 
    
    my $HDD         = $HDD_hash{$weatherloc}; 
    
    #print (" $weatherloc /  $ HDD \n " );
    
    my $SHEU_region = $SHEU_REGION_hash{$weatherloc}; 
    $SHEU_region = $SHEU_region // "null"; 
    my $yearbuilt   = $columns[$yearbuilt_index]; 
    my $SHEU_vintage = "null" ; 
    
    if    ( $yearbuilt < 1946 ) { $SHEU_vintage = "Before 1946";    }
    elsif ( $yearbuilt < 1970 ) { $SHEU_vintage = "1946-1969";      }
    elsif ( $yearbuilt < 1980 ) { $SHEU_vintage = "1970-1979";      }
    elsif ( $yearbuilt < 1990 ) { $SHEU_vintage = "1980-1989";      }
    elsif ( $yearbuilt < 2000 ) { $SHEU_vintage = "1990-1999";      }
    elsif ( $yearbuilt < 2008 ) { $SHEU_vintage = "2000-2007";      }
    elsif ( $yearbuilt < 2015 ) { $SHEU_vintage = "2008 or later";  }
    
    # Basement Walls 
    
    my ($bsmRSI, $wallRSI, $attRSI) = ( 0.,0.,0. ); 
    
    
    if     ( $HDD < 3000 )    { $bsmRSI =  1.99 ;  }
    elsif  ( $HDD < 5000 )    { $bsmRSI =  2.98 ;  }
    elsif  ( $HDD < 7000 )    { $bsmRSI =  3.46 ;  }
    else                      { $bsmRSI =  3.97 ;  }

    if     ( $HDD < 3000 )    { $wallRSI = 2.78 ;  }
    elsif  ( $HDD < 6000 )    { $wallRSI = 3.08 ;  }
    else                      { $wallRSI = 3.85 ;  }    
    
    
    
    if     ( $HDD < 3000 )    { $attRSI =  6.91 ;  }
    elsif  ( $HDD < 5000 )    { $attRSI =  8.67 ;  }      
    else                      { $attRSI = 10.43 ;  }    
    
    
    
    
    
    
    
    
    #print "INDEX: weather : $weatherloc_index \n:"; 
    #print "CONTENT: " . $columns[$weatherloc_index] . "/". $SHEU_REGION_hash{"MONTREAL_QUEBEC"}. "\n"; 
    $output .= "$city,$prov,$SHEU_region,$SHEU_vintage,$HDD,$bsmRSI,$wallRSI,$attRSI,NA\n"; 
    
    
    
    
    
    
    
  }
  
  
  

  # For header row, copy output into both D and E files 
  if ( $columns[$eval_col_index] =~ /EVAL_TYP/ ) {  $output_D .= $output; 
                                                    $output_E .= $output;    }                                  


  
  # determine if this is a D or E string. 
  
  if ( $columns[$eval_col_index] =~ /D/ )        {  $output_D .= $output;  }
  if ( $columns[$eval_col_index] =~ /E/ )        {  $output_E .= $output;  }
    
  # Empty column header. 
  @columns = (); 

  
  # Increment counter. 
  $line_no++; 
  $line_no_buffer++; 
  
}

     print "Dumping $line_no_buffer lines ($line_no) \n"; 
     
     
     print FILEOUT_D "$output_D";
     print FILEOUT_E "$output_E";
     
     
     
     $output_D = ""; 
     $output_E = ""; 


foreach my $column ( @keep_col_index ){
 #print "$column | "; 
}




sub escape_cars($){


  my ($string) = @_;
  $string =~ s/^.EID/EID/g; 
  $string =~ s/POSTAL_CODE/POSTALCODE/g; 
  $string =~ s/\n//g;
  $string =~ s/\r//g;
  $string =~ s/ /_/g;
  #$string =~ s/\"//g;
  $string =~ s/,,/,0,/g; 
  
  return ($string);
}



