#!/usr/bin/perl
# This script takes two csv files containing D and E audit data, and 
# identifies matching rows (by house ID  so that the D and E data appear on a single row. 


use IO::Handle qw( );  # For flush
 
my $file_D = "split-results_D_audit.txt";
my $file_E = "split-results_E_audit.txt";
my $file_out = "D_E_combined_2016-10-18-forR.csv";
my @file_E;
my @file_D;


# Open files 
# INPUT: 
open (FILEIN_D, $file_D) or die     ("could not open $file_D\n");
open (FILEIN_E, $file_E) or die     ("could not open $file_E\n");
# OUTPUT:    
open (FILEOUT, ">$file_out") or die ("could not open $file_out\n");

# Load file D into memory.
print "Parsing file D... \n"; 
while ( my $line = <FILEIN_D> ){
    push @file_D, $line ;
    
}

# Load file E into memory and index locations of all house IDs'
my %FileEIndex = {}; 
my $HeaderRead = 0; 
my $FileERow = 0; 
print "Parsing file E...\n";
while ( my $line = <FILEIN_E> ){
  
  push @file_E, $line ;
  my @columns = split /,/, $line ; 
    
  # For first row:
  if ( ! $HeaderRead ) { 
    my $colindex = 0; 
    # Loop through columns and find 'HOUSE_ID'. Save column location as house_ID_index
    foreach my $column (@columns) {
      if ( $column =~ /HOUSE_ID/) { $house_ID_index =  $colindex;  } 
      $colindex++; 
    }
    $HeaderRead = 1; 
  }
 
  # Now we know where HOUSE_ID is saved. Use hash FileEIndex to store a pointer 
  # from the HOUSE ID # to the row it can be found at. (At every row, @file_E will 
  # store a house ID # and associated data; for every house ID #, $FileEIndex will 
  # store the corresponding row from file_E
  my $HouseID = @columns[$house_ID_index ]; 
  $FileEIndex{$HouseID} = $FileERow ; 
  $FileERow++; 
 
}


# Close input files 
close (FILEIN_E);  
close (FILEIN_D);  
  
# How many lines are there? Use the smaller of the length of the two files. 
my $numLines = scalar @file_D > scalar @file_E ? scalar @file_E : scalar @file_D ; 

$HeaderRead = 0; 
$d_count = 0; 
my $house_ID_index = 0;
my $colindex_E = 0; 

my $MatchCount = 0; 
my $MisMatchCount = 0; 
# Now loop through D:
# 1. Figure out which columns we should keep.
# 2. For each line, find the corresponding record in E
# 3. Splice both together and save the result.

print "Matching $numLines lines between files D and E...\n"; 

foreach my $line_D ( @file_D ){

  my $colindex = 0; 
  my @columns = split /,/, $line_D ; 


  if ($HeaderRead == 0) {
  
    foreach my $column (@columns) {
	  push @keep_col_index, $colindex;
	  #if ( $column =~ /EVAL_TYP/)     { push @keep_col_index, $colindex; }
    if ( $column =~ /HOUSE_ID/)     { $house_ID_index =   $colindex; }
	  #if ( $column =~ /PROVINCE/)     { push @keep_col_index, $colindex; }	
	  #if ( $column =~ /DECADEBUILT/)  { push @keep_col_index, $colindex; }
 	  #if ( $column =~ /FLOORAREA/)    { push @keep_col_index, $colindex; }
	  #if ( $column =~ /FOOTPRINT/)    { push @keep_col_index, $colindex; }
	  #if ( $column =~ /TYPEOFHOUSE/)  { push @keep_col_index, $colindex; }	
	  #if ( $column =~ /STOREYS/)      { push @keep_col_index, $colindex; }
	  #if ( $column =~ /\"FURSSEFF/)   { push @keep_col_index, $colindex; }
	  #if ( $column =~ /\"FURNACEFUEL/){ push @keep_col_index, $colindex; }	 
	  #if ( $column =~ /\"PDHWEF/)     { push @keep_col_index, $colindex; }	
	  #if ( $column =~ /\"PDHWFUEL/)   { push @keep_col_index, $colindex; }	
      #if ( $column =~ /\"CEILINS/)    { push @keep_col_index, $colindex; }	 
	  #if ( $column =~ /\"FNDWALLINS/) { push @keep_col_index, $colindex; }	
	  #if ( $column =~ /\"MAINWALLINS/){ push @keep_col_index, $colindex; }	
 	  #if ( $column =~ /\"WINDOWCODE/) { push @keep_col_index, $colindex; }	
      #if ( $column =~ /\"AIR50P/)     { push @keep_col_index, $colindex; }  
      #if ( $column =~ /EINCENTIVE/)   { push @keep_col_index, $colindex; }  	 	  
      $colindex++;
    }
       
  }
  # Get the ID number of the current row (will = HOUSE_ID for header row) 
  my $keep_D_house_ID = $columns[$house_ID_index] ;   	 	  
  
  # Build a counter to report progress to screen.
  my $percent = int($d_count/$numLines*100); 
  print " $d_count of $numLines ($percent%) | Searching for ID $keep_D_house_ID ? " ;
  $d_count++; 
  
  # Look up the row in file E that matches the file D house # we're working with. 
  # First, check if it exists in 'e'
  if ( defined ( $FileEIndex{$keep_D_house_ID} ) ){ 
    # Found it! Get the row #.
    my $FileERow = $FileEIndex{$keep_D_house_ID}; 
        
    # Recover the entire row from @file_E.
    my $line_E = $file_E[$FileERow]; 
        
    if ( ! $HeaderRead ) {
      # append '-D' and '-E' to header row fields to keep them straight. 
      $line_D =~ s/,/-D,/g; 
      $line_E =~ s/,/-E,/g; 
      $HeaderRead = 1;  
    }
    
    # Now save output. 
    $output = "$line_D,$line_E";
    $output =~ s/\n//g; 
    $output =~ s/\r//g; 
    print FILEOUT "$output  \n " ;
    
    # Finish progress report 
    print "Found ! at row $FileERow in E. \n" ; 
    $MatchCount++; 
  }else{
    print "Not found ! \n"; 
    $MisMatchCount++; 
  } 
   
  STDOUT ->flush(); 
  FILEOUT -> flush(); 
 
 # debug: use this statement to limit the number tested. 
 # if ( $MatchCount > 10 ) {die();}

}	
    

    
#foreach my $column ( @keep_col_index ){
# print "$column | "; 
#}

close (FILEOUT); 

# Results:
print "\n\n DONE! \n\n";  
print " .................................................\n"; 
print " combine_D_E_lickity_split.pl : Results \n";
print " Files combined into $file_out \n"; 
print " Contents: \n"; 
print "  - File D : ". scalar @file_D . " lines \n"; 
print "  - File E : ". scalar @file_E . " lines \n\n"; 
print " Successfully matched $MatchCount lines.\n"; 
print " ( $MisMatchCount lines from file D \n"; 
print "   were not found in file E. )\n\n";
print " Happy number crunching.\n"; 
print " .................................................\n"; 
    

