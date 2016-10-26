#!/bin/perl
 
 
use warnings;
use strict; 
 
 
sub escape_cars($) ; 

# File to contain D records
my $file_Da = "split-results_D_audit.txt";

# File to contain E records. 
my $file_Db = "split-results_E_audit.txt";
 
 
# Oppen files. 
open (FILEIN_Da, $file_Da) or die ("could not open $file_Da\n");
open (FILEIN_Db, $file_Db) or die ("could not open $file_Db\n");

my $OutputFile = "All-d-audits.csv"; 

open (FILEOUT,">$OutputFile" ) or die ( "could not open $OutputFile \n"); 


#open (FILEOUT_D, ">$file_D") or die ("could not open $file_D\n"); 
#open (FILEOUT_E, ">$file_E") or die ("could not open $file_E\n"); 

# Counters
my $line_no        = 0; 
my $line_no_buffer = 0; 
my $eval_col_index = 0;

# output 
my $output   = ""; 

# Loop through file, 
#  1. Find the columns we want to keep, or optionally keep them all, 
#  2. Determine if this is a D or E record,
#  3. Store results in D or E output, 
#  4. Periodically write D or E output to file. 


#my $header_Da = <FILEIN_Da>;
#my $header_Db = <FILEIN_Db>;


# Escape unnecssary spaces. 

my $header_Da = escape_cars(<FILEIN_Da>);
my $header_Db = escape_cars(<FILEIN_Db>);

#$header_Da =~ s/\"([^\"])+,([^\"])+\"/$1_$2/g;


my $col_index_a  = 0; 
my $match = 0;  

my %column_map; 
my %header; 
my @columns_to_save; 
my $header_row = "";  
print "PARSING HEADER \n"; 
 

 
 
foreach my $col_a (split /,/ , $header_Da ){

  $col_a =~ s/\s*//g;   

  $match = 0; 
  my $col_index_b  = 0; 
  
  

  foreach my $col_b ( split /,/ , $header_Db ){
  
    
    if ( $col_a =~ /^$col_b$/ && $col_index_a < 300 ){  
    
      if ( $col_a =~ /HOUSE_ID/        ||
           $col_a =~ /POSTALCODE/      ||
           $col_a =~ /EGHDESHTLOSS/    ||
           $col_a =~ /FLOORAREA/       ||
           $col_a =~ /TYPEOFHOUSE/     ||
           $col_a =~ /YEARBUILT/       || 
           $col_a =~ /EGHSPACEENERGY/  ||
           $col_a =~ /EGHFCON.*/       ||
           $col_a =~ /EGHRATING/       ||
           $col_a =~ /FURNACEFUEL/     ||
           $col_a =~ /PDHWFUEL/        ||
           $col_a =~ /DRYERFUEL/       ||
           $col_a =~ /AIR50P/          ||
           $col_a =~ /CEILINS/         ||
           $col_a =~ /FNDWALLINS/      ||
           $col_a =~ /MAINWALLINS/     ||
           $col_a =~ /FURSSEFF/        ||
           $col_a =~ /PDHWEF/          ||
           $col_a =~ /HOUSEREGION/     ||
           $col_a =~ /WEATHERLOC/      ||
           $col_a =~ /EGHFCOSTELEC/    ||
           $col_a =~ /EGHFCOSTNGAS/    ||
           $col_a =~ /EGHFCOSTOIL/     ||
           $col_a =~ /EGHFCOSTPROP/    ||
           $col_a =~ /EGHFCOSTTOTAL/

         
           
           
           
           #$col_a =~ // ||
           #$col_a =~ // ||
           #$col_a =~ // ||
           #$col_a =~ // ||
           #$col_a =~ // ||
           #$col_a =~ // ||
           #$col_a =~ // ||
           #$col_a =~ // ||
           #$col_a =~ // ||
           #$col_a =~ // ||           
               
      ){
    
        print " - $col_index_a : |$col_a| ?" ; 
        $match = 1;       
        
        push @columns_to_save, $col_index_a; 
        
        $column_map{$col_index_a} = $col_index_b ; 
        $header{$col_index_a} = $col_a; 
        
        print " matches |$col_b|  ( $col_index_a ->" .$column_map{$col_index_a}.") !\n " ; 
      
      
        $header_row .= "$col_a,"; 
      }
      
    }
    
    $col_index_b++;
    
        
  
  }
  
  #print " ($match) \n"; 

  
  #if ( !  $match ) { print " does not match ! "}

  $col_index_a++;

}

print ("0: $columns_to_save[0] \n"); 
print ("1: $columns_to_save[1] \n");
print ("2: $columns_to_save[2] \n");

print ("SIZE: $#columns_to_save \n" ); 

# now parse file A and report output

$output = "src-file,$header_row\n"; 

my $dumpflag = 0; 
my $totallines = 0; 

if ( 1== 1 ){

while ( my $b_line = escape_cars(<FILEIN_Db>) ) {

  $output .= "file-b,"; 
  
  my @cols_from_b = ( split /,/ ,  $b_line );
  
  foreach( @columns_to_save ){
  
    my $index_col_a = $_; 
    my $index_col_b = $column_map{$index_col_a}; 
    my $value_from_b = $cols_from_b[$index_col_b];
    
    
    
    #die ( " Save $cols_from_a ? " );
    #die ( " Save $cols_from_a ? " );
    
    
    
    #my $col_b = $column_map{$cols_from_a}; 
    
    #print " $totallines PARSING $index_col_a ->  ($index_col_b) | ".$header{$index_col_a}." = " .$value_from_b. " \n  "; 
    
    $output .=  $value_from_b.","; 
  
  }
   
 
  $output .= "\n";  
  if ( $dumpflag > 4999 ){
     print "Dumping $dumpflag lines from b ($totallines total!)\n "; 
     print FILEOUT $output ; 
     $dumpflag = 0; 
     $output = ""; 
  

  }
  
  $dumpflag++;
  $totallines++; 

}


}

print "Dumping $dumpflag lines from b ($totallines total!)\n "; 
print FILEOUT $output ; 


while (my $a_line = escape_cars(<FILEIN_Da>) )  {
 
  $output .= "file-a,"; 
  
  my @cols_from_a = ( split /,/ ,  $a_line );
  
  #print " SIZE OF A: $#cols_from_a \n"; 
  
  if ( $#cols_from_a < $#columns_to_save ) { die ("$totallines:  Line arrys don't match !"); }
  
  
  foreach( @columns_to_save ){
  
    my $index_col_a = $_; 
    my $value_from_a = $cols_from_a[$index_col_a];
    
    
    
    #die ( " Save $cols_from_a ? " );
    #die ( " Save $cols_from_a ? " );
    
    
    
    #my $col_b = $column_map{$cols_from_a}; 
    
    #print " $totallines PARSING $index_col_a ->  | ".$header{$index_col_a}." = " .$value_from_a . " \n  "; 
    
    
    
    $output .=  $value_from_a.","; 
  
    #if ($totallines > 50 ) {die()}; 
  }
   
  
  $output .= "\n";  
  if ( $dumpflag > 4999 ){
     print "Dumping $dumpflag lines from a ($totallines total!)\n "; 
     print FILEOUT $output ; 
     $dumpflag = 0; 
     $output = ""; 
  
  
  }
  
  $dumpflag++;
  $totallines++; 

}

print "Dumping $dumpflag lines from a ($totallines total!)\n "; 
print FILEOUT $output ; 




die(); 





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













