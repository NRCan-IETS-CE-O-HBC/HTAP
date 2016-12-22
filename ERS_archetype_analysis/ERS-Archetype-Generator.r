
# R-Start: draft housing stock analysis script. 

DebugConn <- file("debug-msgs.txt","wt")

# Standard output
stream_out <- function(msgs=c()){
  for (i in 1:length(msgs) ){
    cat(msgs[i])
  }
}

# Debugging output
debug_out <- function(msgs=c()){
    if ( debug ){   
	  writeLines(msgs, sep=" " ,DebugConn)
    }
}

debug_vector <- function(myVector=c()){
    if ( debug ){

	  i=0
	  OutVector = c("")
	  for (i in 1:length(myVector) ){
	    OutVector[i+1] = paste("   - ",myVector[i], sep="")
      }
	  OutVector[i+2] = "\n"
	  
      writeLines(OutVector, DebugConn )
	 
	}
}


# Header 
sayHello <- function(){ 
  debug_out(c('(ERS-archetype-Generator.R debugging output) \n\n'))
  stream_out(c('This is the draft housing stock analysis script. \n \n\n'))
}


#============= Configuration ========================

# should be a cmd-line arguement
debug = 1

# Location of the CEUD data source. Also could be a cmd line arguement
#gPathToCEUD = "C:\\Users\\jpurdy\\Google Drive\\NRCan-Optimization-Results\\EIP-Technology-Forecasting\\CEUD-Data\\CEUD-translator-txt.csv"

gPathToCEUD = "C:\\Users\\aferguso\\Google Drive\\NRCan work\\NRCan-Optimization-Results\\EIP-Technology-Forecasting\\CEUD-Data\\CEUD-translator-txt.csv"

#gPathToERS  = "C:\\cygwin64\\home\\aferguso\\ERS_Database\\D_E_combined_2016-10-18-forR.csv"
#gPathToERS  = "C:\\Ruby4HTAP\\ERS_archetype_analysis\\ERS_combined_forR.csv"

gPathToERS   = "C:\\Users\\aferguso\\Google Drive\\NRCan work\\NRCan-Optimization-Results\\EIP-Technology-Forecasting\\CEUD-Data\\D_E_combined_2016-10-18-forR.csv"

# General parameters

# Number of archetypes to be defined: 
gTotalArchetypes = 3000 

# year for model
gStockYear = 2013


#==============
# Start of script. 
sayHello()

#==============
# CEUD: Parse and pre-process data. 
# Parse CEUD data from csv file. 
stream_out(c(" - About to parse CEUD data (",gPathToCEUD, ")..."))

mydata <- read.csv (file=gPathToCEUD, header=TRUE, sep = ",")
stream_out (c("  done (",nrow(mydata), " rows) \n\n"))


if (debug){
  debug_out (c("raw data contains ",nrow(mydata), " rows.\n"))
  debug_out (c("I found the following columns in mydata : \n"))
  debug_vector( colnames(mydata) )
  debug_out(c("\n"))
}



# Currently,  CEUD-translator-txt.csv contains a couple of duplicate 1990 rows - these are
# flagged by 'Filter_extra_1990 = true

CEUD <- subset( mydata, FilterExtra1990 == FALSE )
mydata <- c()
# compute number of homes (Number_static is in '1000s')
CEUD$NumHomes = CEUD$Number_static * 1000


if(debug){

  debug_out (c("After duplicate 1990 rows were removed, I found ", nrow(CEUD), " rows.\n"))
}



# List of all 'topologies's, which define the aggregations in CEUD tables
CEUDTopologies =  unique( as.vector(CEUD$Metric))


if (debug) {
  debug_out(c("\n","Topology list in CEUD data. - \n"))
  debug_vector( CEUDTopologies )
  
}



# ==============
# Create separate topologies 
# Get subsets that contain housing stock by aggregations of interest. 
CEUDProvFormVintageYr <- subset( CEUD, Year == gStockYear & Metric == "Province|Form|Vintage|Year") 
CEUDProvFormEquipYr   <- subset( CEUD, Year == gStockYear & Metric == "Province|Form|Equipment|Year") 
CEUDProvFormYr        <- subset( CEUD, Year == gStockYear & Metric == "Province|Form|Year") 




### ==============  Consider if the following is really necessary. 
### Perform substitutions on 'Equipment' toplogies - map to simpler definitions for now.  
##if (debug){
##  debug_out ("Equipment keyword replacement (pre)\n")
##  cat( unique( as.vector(CEUDProvFormEquipYr$Equipment) ) )
##  debug_out ("/Equipment keyword replacement (pre)\n")
##}
##CEUDProvFormEquipYr$Equipment <- as.character(CEUDProvFormEquipYr$Equipment)
##
##CEUDProvFormEquipYr$Equipment[ CEUDProvFormEquipYr$Equipment == "Gas-Medium" ] <- "Gas"
##CEUDProvFormEquipYr$Equipment[ CEUDProvFormEquipYr$Equipment == "Gas-High"   ] <- "Gas"
##CEUDProvFormEquipYr$Equipment[ CEUDProvFormEquipYr$Equipment == "Gas-Normal" ] <- "Gas"
##
##CEUDProvFormEquipYr$Equipment[ CEUDProvFormEquipYr$Equipment == "Oil-Medium" ] <- "Oil"
##CEUDProvFormEquipYr$Equipment[ CEUDProvFormEquipYr$Equipment == "Oil-High"   ] <- "Oil"
##CEUDProvFormEquipYr$Equipment[ CEUDProvFormEquipYr$Equipment == "Oil-Normal" ] <- "Oil"
##
##CEUDProvFormEquipYr$Equipment <- as.factor(CEUDProvFormEquipYr$Equipment)
##
##if ( debug ){
##  debug_out ("Equipment keyword replacement (post)\n")
##  cat (paste(c(unique( as.character(CEUDProvFormEquipYr$Equipment))), sep="\n" ))
##  debug_out ("Equipment keyword replacement (post)\n")
##}



CEUDTotalHomes=sum(CEUDProvFormYr$NumHomes) 


# How many homes will each archetype represent? 
gNumHomesEachArchRepresents = CEUDTotalHomes / gTotalArchetypes

debug_out (c( "CEUD Data for", gStockYear, ":\n"))
debug_out (c( "  - Total homes      :",CEUDTotalHomes,"\n"))
debug_out (c( "  - If I generate", gTotalArchetypes, "archetypes, each archetype will represent ", gNumHomesEachArchRepresents," homes\n\n"))



#=
# Pre-processing on CEUD data to pull 'Archetype descriptors' 

#=============ERS 
stream_out (c("\n - About to parse the ERS data at", gPathToERS,"..."))

#=ERS data gets parsed here. 



myERSdata <- read.csv (file=gPathToERS, nrows=50000, header=TRUE, sep = ",")

#myERSdata <- read.csv (file=gPathToERS, header=TRUE, sep = ",")


# show the columns that we pulled - 
debug_out("List of columns in ERS database:\n")
debug_vector(sort(colnames(myERSdata)))

# randomize the ERS data 
myRandomERSdata <- myERSdata[sample(nrow(myERSdata)), ]

#stream_out (c("The ERS database is now randomized"))
# set myERSdata to randomized data frame
myERSdata <- myRandomERSdata

stream_out (c(" - ... done.(",nrow(myERSdata)," rows)\n\n"))

debug_out (c( "ERS Data:\n"))
debug_out (c( "  - Total rows      :",nrow(myERSdata),"\n"))
debug_out (c( "  - Total cols      :",ncol(myERSdata),"\n"))
debug_out (c( "\n\n"))


# ============= Flag bad data 
# 
# myERSdata$dataOK <- TRUE
# myERSdata$dataOK[ myERSdata$FURSSEFF.E<0  ] <- FALSE 
#

#unique(as.character(myERSdata$SHEU.vintage.E))



#====================================
# Create new records in ERS data that map to CEUD

# Vintage

stream_out("\n\n - Mapping vintage to CEUD definitions... ")
debug_out(c("\n\n =============== Vintage analysis ====================\n\n"))

debug_out (c(" Vintages used in CEUD:\n"))
debug_vector(c(unique(as.character(CEUD$Vintage))))
debug_out (c("\n\n"))

# Set all vintage tags in ERS as error; as we identify ones that are valid, flip them 
# to our common keywords. 
myERSdata$CEUDVintage <- "error"
myERSdata$CEUDVintage[ myERSdata$YEARBUILT.E < 1946 ] <- "Before 1946"
myERSdata$CEUDVintage[ myERSdata$YEARBUILT.E > 1945 & myERSdata$YEARBUILT.E < 1961 ] <- "1946-1960"
myERSdata$CEUDVintage[ myERSdata$YEARBUILT.E > 1960 & myERSdata$YEARBUILT.E < 1978 ] <- "1961-1977"
myERSdata$CEUDVintage[ myERSdata$YEARBUILT.E > 1977 & myERSdata$YEARBUILT.E < 1984 ] <- "1978-1983"
myERSdata$CEUDVintage[ myERSdata$YEARBUILT.E > 1983 & myERSdata$YEARBUILT.E < 1996 ] <- "1984-1995"
myERSdata$CEUDVintage[ myERSdata$YEARBUILT.E > 1995 & myERSdata$YEARBUILT.E < 2001 ] <- "1996-2000"
myERSdata$CEUDVintage[ myERSdata$YEARBUILT.E > 2000 & myERSdata$YEARBUILT.E < 2006 ] <- "2001-2005"
myERSdata$CEUDVintage[ myERSdata$YEARBUILT.E > 2005 & myERSdata$YEARBUILT.E < 2011 ] <- "2006-2010"
myERSdata$CEUDVintage[ myERSdata$YEARBUILT.E > 2010 & myERSdata$YEARBUILT.E < 2014 ] <- "2011-2013"
myERSdata$CEUDVintage[ myERSdata$YEARBUILT.E > 2014 & myERSdata$YEARBUILT.E < 1977 ] <- "After 2014"

myERSdata$CEUDVintage <- as.factor(myERSdata$CEUDVintage)

debug_out (c("Vintages set in ERS for valid rows:\n"))
debug_vector(c(unique(as.character(myERSdata$CEUDVintage))))
debug_out (c("\n\n"))

debug_out ("Vintage Codes that weren't set properly:\n")
debug_vector(c(unique(as.character(myERSdata$YEARBUILT.E[myERSdata$CEUDVintage == "error"]))))
debug_out (c("(",nrow(myERSdata[myERSdata$CEUDVintage == "error",])," rows in total)\n"))

stream_out(c("done.\n"))


# Province 

stream_out(c(" - Mapping province to CEUD definitions..."))


debug_out(c("\n\n =============== Province analysis ====================\n\n"))

debug_out (c(" Provinces used in CEUD:\n"))
debug_vector(c(unique(as.character(CEUD$Province))))
debug_out (c("\n\n"))

debug_out (c(" Provinces used in ERS:\n"))
debug_vector(c(unique(as.character(myERSdata$PROVINCE.D))))
debug_out (c("\n\n"))


myERSdata$CEUDProvince <- "error"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "QC" ] <- "QC"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "BC" ] <- "BC"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "ON" ] <- "ON"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "SK" ] <- "SK"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "MB" ] <- "MB"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "NF" ] <- "NF"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "AB" ] <- "AB"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "NS" ] <- "NS"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "NB" ] <- "NB"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "PE" ] <- "PEI"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "NT" ] <- "TR"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "YK" ] <- "TR"
myERSdata$CEUDProvince[ myERSdata$PROVINCE.D == "NU" ] <- "TR" 
 

debug_out (c("Provinces set in ERS for valid rows:\n"))
debug_vector(c(unique(as.character(myERSdata$CEUDProvince[myERSdata$CEUDProvince != "error"]))))
debug_out (c("\n\n"))

debug_out ("Province Codes that weren't set properly:\n")
debug_vector(c(unique(as.character(myERSdata$PROVINCE.D[myERSdata$CEUDProvince == "error"]))))
debug_out (c("(",nrow(myERSdata[myERSdata$CEUDProvince == "error",])," rows in total)\n"))

stream_out(c("done.\n"))



#========Type of house 

stream_out(" - Mapping house type to CEUD definitions...")

debug_out(c("\n\n =============== House type analysis ====================\n\n"))

debug_out (c("Housing Forms used in CEUD:\n"))
debug_vector(c(unique(as.character(CEUD$Form))))
debug_out (c("\n\n"))

debug_out (c("Housing types used in ERS:\n"))
debug_vector(c(unique(as.character(myERSdata$TYPEOFHOUSE.D))))
debug_out (c("\n\n"))


  myERSdata$CEUDForm <- "error"
  myERSdata$CEUDForm[ myERSdata$TYPEOFHOUSE.D == "Single^detached" ] <- "SD"
  myERSdata$CEUDForm[ myERSdata$TYPEOFHOUSE.D == "Mobile^home" ] <- "MH"
  myERSdata$CEUDForm[ myERSdata$TYPEOFHOUSE.D == "Double/Semi-detached" |  
                      myERSdata$TYPEOFHOUSE.D == "Attached^Duplex" |  
                      myERSdata$TYPEOFHOUSE.D == "Duplex^(non-MURB)"  |  
                      myERSdata$TYPEOFHOUSE.D == "Attached^Triplex"   |
                      myERSdata$TYPEOFHOUSE.D == "Row^house_^end^unit" |
                      myERSdata$TYPEOFHOUSE.D == "Detached^Duplex"  |
                      myERSdata$TYPEOFHOUSE.D == "Detached^Triplex"  |
                      myERSdata$TYPEOFHOUSE.D == "Triplex^(non-MURB)"  | 
                      myERSdata$TYPEOFHOUSE.D == "Row^house_^middle^unit"  ] <- "SA"
  myERSdata$CEUDForm[ myERSdata$TYPEOFHOUSE.D == "Apartment" |  
                      myERSdata$TYPEOFHOUSE.D == "Apartment^Row" ] <- "AP"
 
  
debug_out (c("House types set in ERS for valid rows:\n"))
debug_vector(c(unique(as.character(myERSdata$CEUDForm[myERSdata$CEUDForm != "error"]))))
debug_out (c("\n\n"))

debug_out ("House Type Codes that weren't set properly:\n")
debug_vector(c(unique(as.character(myERSdata$TYPEOFHOUSE.D[myERSdata$CEUDForm == "error"]))))
debug_out (c("(",nrow(myERSdata[myERSdata$CEUDForm == "error",])," rows in total)\n"))

stream_out(c("done.\n"))
  
  
  
  

# Heating fuel  

stream_out(" - Mapping heating fuel  to CEUD definitions...")


debug_out(c("\n\n =============== Heating fuel/equipment analysis ====================\n\n"))
debug_out (" Equipment types used in CEUD:\n")
debug_vector(c(unique(as.character(CEUD$Equipment))))

  debug_out (" Furnace fuel used in ERS:\n")
  

  
  debug_vector(c(unique(as.character(myERSdata$FURNACEFUEL.D))))
 
  
  debug_out ("\n")
  debug_out (" Furnace efficiencies used in ERS:\n")
  debug_vector(c(unique(as.character(myERSdata$FURSSEFF.D))))
  debug_out (" Heat pump types used in ERS:\n")
  debug_vector(c(unique(as.character(myERSdata$HPSOURCE.D[ as.numeric(myERSdata$COP.D) > 1.1 ] ))))
  debug_out (" Heat pump COPS types used in ERS:\n")
  debug_vector(c(unique(as.character(myERSdata$COP.D))))
  

  

  # 1: Classify dual fuel systems
 # Recode
  myERSdata$CEUDSHCode <- "Code0"
  myERSdata$SHFuel1    <- "Fuel1"
  myERSdata$SHFuel2    <- "Fuel2"
  myERSdata$SHFuel3    <- "Fuel3"
  
  #myERSdata$FURNACEFUEL.D   <- as.character(myERSdata$FURNACEFUEL.D)
  #myERSdata$SUPPHTGFUEL1.D  <- as.character(myERSdata$SUPPHTGFUEL1.D)
  #myERSdata$SUPPHTGFUEL2.D  <- as.character(myERSdata$SUPPHTGFUEL2.D )
  
  myERSdata$SHFuel1 <- as.character(myERSdata$FURNACEFUEL.D)
  myERSdata$SHFuel2 <- as.character(myERSdata$SUPPHTGFUEL1.D)
  myERSdata$SHFuel3 <- as.character(myERSdata$SUPPHTGFUEL2.D)
  
  
  # Set NA to none. 
  myERSdata$SHFuel2[ myERSdata$SUPPHTGFUEL1.D == "N/A" ] <- "none"
  myERSdata$SHFuel3[ myERSdata$SUPPHTGFUEL2.D == "N/A" ] <- "none"
  
  # Rename wood variants 
  myERSdata$SHFuel1[ myERSdata$FURNACEFUEL.D == "Mixed^wood" |
                     myERSdata$FURNACEFUEL.D == "Hardwood" |  
                     myERSdata$FURNACEFUEL.D == "Softwood" |
                     myERSdata$FURNACEFUEL.D == "Wood^Pellets"   ] <- "Wood"
    
  myERSdata$SHFuel2[ myERSdata$SUPPHTGFUEL1.D  == "Mixed^wood" |
                     myERSdata$SUPPHTGFUEL1.D  == "Hardwood" |  
                     myERSdata$SUPPHTGFUEL1.D  == "Softwood" |
                     myERSdata$SUPPHTGFUEL1.D  == "Wood^Pellets"   ] <- "Wood"
  
  myERSdata$SHFuel3[ myERSdata$SUPPHTGFUEL2.D  == "Mixed^wood" |
                     myERSdata$SUPPHTGFUEL2.D  == "Hardwood" |  
                     myERSdata$SUPPHTGFUEL2.D  == "Softwood" |
                     myERSdata$SUPPHTGFUEL2.D  == "Wood^Pellets"   ] <- "Wood"  

                     
                     
  if (debug){ 
  pre_combinations0 = paste( as.character(myERSdata$CEUDSHCode) , " + "  )
  pre_combinations1 = paste( as.character(myERSdata$SHFuel1) , " + "  )
  pre_combinations2 = paste( as.character(myERSdata$SHFuel2) , " + "  )
  pre_combinations3 = paste( as.character(myERSdata$SHFuel3) , " + "  )
  }       
                     
                                          
 
 # if fuel3 is a duplicate, eliminate it. 

   myERSdata$SHFuel3[     myERSdata$SHFuel3 == myERSdata$SHFuel2 ] <- "none"
   myERSdata$SHFuel3[     myERSdata$SHFuel3 == myERSdata$SHFuel1 ] <- "none"                    

 # if fuel2 is a duplicate, eliminate it. 

   myERSdata$SHFuel2[     myERSdata$SHFuel2 == myERSdata$SHFuel1 ] <- "none"

 
                     
  # if fuel2 is none, use fuel 3.If fuel1 is none, use fuel 2.
  myERSdata$SHFuel2[     myERSdata$SHFuel2 == "none" ] <-  myERSdata$SHFuel3[  myERSdata$SHFuel2 == "none" ]
  myERSdata$SHFuel1[     myERSdata$SHFuel1 == "none" ] <-  myERSdata$SHFuel2[  myERSdata$SHFuel1 == "none" ]

   # We may have made more duplicates. lets eliminate them again.  

   myERSdata$SHFuel3[     myERSdata$SHFuel3 == myERSdata$SHFuel2 ] <- "none"
   myERSdata$SHFuel3[     myERSdata$SHFuel3 == myERSdata$SHFuel1 ] <- "none"                    

 # if fuel2 is a duplicate, eliminate it. 

   myERSdata$SHFuel2[     myERSdata$SHFuel2 == myERSdata$SHFuel1 ] <- "none"
  
  
  

   
#
#  myERSdata$SHFuel3[     myERSdata$SHFuel1 == myERSdata$SHFuel3 ] <- "none"
#                         
#
#  myERSdata$SHFuel3[     myERSdata$SHFuel2 == myERSdata$SHFuel3 ] <- "none"
#
#
#                         
# 
#  # When fuel2 & 3 are none, use fuel 1 only   
  myERSdata$CEUDSHCode[  myERSdata$SHFuel2 == "none" & 
                         myERSdata$SHFuel3 == "none" ]   <- "Code1"
                                                                                

 
  # First priority = code 1/2. Set fuel flags based on elec/gas
  myERSdata$SHHasElec[ myERSdata$SHFuel1 == "Electricity" | myERSdata$SHFuel2 == "Electricity" ] = TRUE
  myERSdata$SHHasGas[ myERSdata$SHFuel1 == "Natural^Gas" | myERSdata$SHFuel2 == "Natural^Gas" ] = TRUE
  myERSdata$SHHasOil[ myERSdata$SHFuel1 == "Oil" | myERSdata$SHFuel2 == "Oil" ] = TRUE
  myERSdata$SHHasWood[ myERSdata$SHFuel1 == "Wood" | myERSdata$SHFuel2 == "Wood" ] = TRUE  
  
  
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & myERSdata$SHHasElec &  myERSdata$SHHasGas  ] = "Dual: gas/electric"
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & myERSdata$SHHasElec &  myERSdata$SHHasOil  ] = "Dual: (oil/electric)"  
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & myERSdata$SHHasElec &  myERSdata$SHHasWood ] = "Dual: wood/electric"  
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & myERSdata$SHHasWood &  myERSdata$SHHasOil  ] = "Dual: wood/oil"    
  
  # expand to code 3, and recleass remaining 
  myERSdata$SHHasElec[ myERSdata$SHFuel3 == "Electricity" ] = TRUE
  myERSdata$SHHasGas[ myERSdata$SHFuel3 == "Natural^Gas"  ] = TRUE
  myERSdata$SHHasOil[ myERSdata$SHFuel3 == "Oil"          ] = TRUE
  myERSdata$SHHasWood[ myERSdata$SHFuel3 == "Wood"        ] = TRUE  
  
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & myERSdata$SHHasElec &  myERSdata$SHHasGas  ] = "Dual: gas/electric"
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & myERSdata$SHHasElec &  myERSdata$SHHasOil  ] = "Dual: (oil/electric)"  
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & myERSdata$SHHasElec &  myERSdata$SHHasWood ] = "Dual: wood/electric"  
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & myERSdata$SHHasWood &  myERSdata$SHHasOil  ] = "Dual: wood/oil"    
    
  
#
#
#
#                                                                                
#  myERSdata$FURNACEFUEL.D   <- as.factor(myERSdata$FURNACEFUEL.D)
#  myERSdata$SUPPHTGFUEL1.D  <- as.factor(myERSdata$SUPPHTGFUEL1.D)
#  myERSdata$SUPPHTGFUEL2.D  <- as.factor(myERSdata$SUPPHTGFUEL2.D ) 
#    
#  
  
  
 #if (debug){ 
 #
 #    ers_combinations = sort( paste( as.character(myERSdata$CEUDSHCode), " <- ",
 #                              as.character(myERSdata$SHFuel1),  " + ", 
 #                              as.character(myERSdata$SHFuel2) , " + ", 
 #                              as.character(myERSdata$SHFuel3) ) )
 #    
 #    as.data.frame(table( ers_combinations))
 #    
 #    
 #    ers_combinations0 = paste( as.character(myERSdata$CEUDSHCode) , " + "  )
 #    
 #    
 #    ers_combinations1 = paste( as.character(myERSdata$SHFuel1) , " + "  )
 #
 #    
 #    ers_combinations2 = paste( as.character(myERSdata$SHFuel2) , " + "  )
 #
 #    
 #    ers_combinations3 = paste( as.character(myERSdata$SHFuel3) , " + "  )
 #
 #    
 #    as.data.frame(table( pre_combinations0))
 #    
 #    as.data.frame(table( ers_combinations0))
 #    
 #    
 #    as.data.frame(table( pre_combinations1))    
 #      as.data.frame(table( ers_combinations1))  
 #    
 #    as.data.frame(table( pre_combinations2))
 #      as.data.frame(table( ers_combinations2))
 #    
 #    
 #    as.data.frame(table( pre_combinations3))  
 #      as.data.frame(table( ers_combinations3))
 #  }
    
    

	
	
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code1" ] <- "Code0"

  

  # Set all gas furnaces to 'medium', and then recode ones for which valid efficiency data exists. 
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Natural^Gas" & 
						is.numeric(myERSdata$FURSSEFF.D) ] <- "Gas-Medium"
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Natural^Gas" & 
                        as.numeric(myERSdata$FURSSEFF.D) > 89 ] <- "Gas-High"
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Natural^Gas" & as.numeric(myERSdata$FURSSEFF.D) > 77 
                                                                        & as.numeric(myERSdata$FURSSEFF.D) < 90 ] <- "Gas-Medium"
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Natural^Gas" & as.numeric(myERSdata$FURSSEFF.D) < 78 ] <- "Gas-Normal"
  
  # Set all oil furnaces to 'medium', and then recode ones for which valid efficiency data exists. 
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Oil" & 
						is.numeric(myERSdata$FURSSEFF.D) ] <- "Oil-Medium"
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Oil" & 
                        as.numeric(myERSdata$FURSSEFF.D) > 85 ] <- "Oil-High"
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Oil" & 
                        as.numeric(myERSdata$FURSSEFF.D) > 77 &
                        as.numeric(myERSdata$FURSSEFF.D) < 85 ] <- "Oil-Medium"
  myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Oil" & 
                        as.numeric(myERSdata$FURSSEFF.D) < 78 ] <- "Oil-Normal"  
  
   # Set all electric to 'electric', and then recode heat pumps as needed 
   myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Electricity" ] <- "Electric"
   myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Electricity" & 
                               ( myERSdata$HPSOURCE.D == "Water" | 
                                 myERSdata$HPSOURCE.D == "Air" | 
                                 myERSdata$HPSOURCE.D == "Ground" ) & 
                        is.numeric(myERSdata$COP.D)	 ] <- "Heat-pump"
                                
   myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                         myERSdata$FURNACEFUEL.D == "Propane" ] <- "Other"
                                
                                
    myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" & 
                        myERSdata$FURNACEFUEL.D == "Mixed^wood" |
                                 myERSdata$FURNACEFUEL.D == "Hardwood" |  
                                 myERSdata$FURNACEFUEL.D == "Softwood" |
                                 myERSdata$FURNACEFUEL.D == "Wood^Pellets"   ] <- "Wood"
    
    myERSdata$CEUDSHCode[ myERSdata$CEUDSHCode == "Code0" ] <- "error"
	

	
	
	
	
    #  # The following code is useful for inspecting classifications     
    #  ers_combinations = sort( paste( as.character(myERSdata$CEUDSHCode), " <- ",
    #                                  as.character(myERSdata$SHFuel1),  " + ", 
    #                                  as.character(myERSdata$SHFuel2) , " + ", 
    #                                  as.character(myERSdata$SHFuel3) ) )
    #    
    #  as.data.frame(table( ers_combinations))
    #    
    #    
    #  ers_combinations0 = paste( as.character(myERSdata$CEUDSHCode) , " + "  )
    #    
    #    
    #  ers_combinations1 = paste( as.character(myERSdata$SHFuel1) , " + "  )
    #  
    #    
    #  ers_combinations2 = paste( as.character(myERSdata$SHFuel2) , " + "  )
    #  
    #    
    #  ers_combinations3 = paste( as.character(myERSdata$SHFuel3) , " + "  )
    #  
    #    
    #  as.data.frame(table( pre_combinations0))
    #  as.data.frame(table( ers_combinations0))
    #  as.data.frame(table( pre_combinations1))    
    #  as.data.frame(table( ers_combinations1))  
    #    
    #  as.data.frame(table( pre_combinations2))
    #  as.data.frame(table( ers_combinations2))
    #    
    #    
    #  as.data.frame(table( pre_combinations3))  
    #  as.data.frame(table( ers_combinations3))
    
  
  debug_out (" Heating Equipment set in ERS according to CEUD definitions :\n")
  debug_vector(c(unique(as.character(myERSdata$CEUDSHCode[myERSdata$CEUDSHCode != "error"]))))
  
  if (nrow(myERSdata[myERSdata$CEUDSHCode== "error",]) > 0 ) {
    debug_out (c("I found that ",nrow(myERSdata[myERSdata$CEUDSHCode == "error",])," rows with the following equip codes rows couldn't be coded:\n"))
    debug_vector(c(unique(as.character(myERSdata$FURNACEFUEL.D[myERSdata$CEUDSHCode == "error"]))))
  }
  
      
  stream_out("done.\n")
    
# Cooling 



debug_out(c("\n\n =============== AC analysis ====================\n\n"))

stream_out(" - Mapping AC to CEUD definitions...")




  debug_out (" AC definitions used in ERS:\n")
  debug_vector(c(unique(as.character(myERSdata$AIRCONDTYPE.D))))
  debug_out ("\n")



 # Recode
   
  myERSdata$CEUDAirCon <- "error"
  myERSdata$CEUDAirCon [ myERSdata$AIRCONDTYPE.D == "N/A"  |
                         myERSdata$AIRCONDTYPE.D == "Not^installed"    ] <- "none"
                         
  myERSdata$CEUDAirCon [ myERSdata$AIRCONDTYPE.D == "Conventional^A/C" |
                         myERSdata$AIRCONDTYPE.D == "Conventional^A/C:^with^vent.^cooling"  |
                         myERSdata$AIRCONDTYPE.D == "A/C^with^economizer"  ] <- "AC-Central"                         

  myERSdata$CEUDAirCon [ myERSdata$AIRCONDTYPE.D == "Window^A/C" |
                         myERSdata$AIRCONDTYPE.D == "Window^A/C^w/economizer"    |
                         myERSdata$AIRCONDTYPE.D == "Window^A/C^w/^economizer"   |
                         myERSdata$AIRCONDTYPE.D == "Window^A/C^w/vent^cooling"    ] <- "AC-Room"    
                         
                         

  debug_out (" \n"); 
  debug_out (" AC Equipment set in ERS according to CEUD definitions :\n")
  debug_vector(c(unique(as.character(myERSdata$CEUDAirCon[myERSdata$CEUDAirCon != "error"]))))
  
  if (nrow(myERSdata[myERSdata$CEUDAirCon== "error",]) > 0 ) {
    debug_out (c("I found that ",nrow(as.character(myERSdata[myERSdata$CEUDAirCon == "error",]))," rows with the following AC codes rows couldn't be coded:\n"))
    debug_vector(c(unique(as.character(myERSdata$AIRCONDTYPE.D[myERSdata$CEUDAirCon == "error"]))))
  }
  
  stream_out("done.\n")
 
    
# Water Heating  


debug_out(c("\n\n =============== Water Heating analysis ====================\n\n"))

stream_out(" - Mapping DHW to CEUD definitions...")

  debug_out (" WH definitions used in ERS:\n")
  debug_vector(c(unique(as.character(myERSdata$PDHWFUEL.D))))
  debug_out ("\n")



 # Recode
   
  myERSdata$CEUDdhw <- "error"
  myERSdata$CEUDdhw[ myERSdata$PDHWFUEL.D == "Natural^Gas"     ] <- "WH-Gas"
  myERSdata$CEUDdhw[ myERSdata$PDHWFUEL.D == "Electricity"     ] <- "WH-Elec"                    
  myERSdata$CEUDdhw[ myERSdata$PDHWFUEL.D == "Oil"     ] <- "WH-Oil"  
  
  myERSdata$CEUDdhw[ myERSdata$PDHWFUEL.D == "Hardwood"       |                   
                     myERSdata$PDHWFUEL.D == "Softwood"       |                   
                     myERSdata$PDHWFUEL.D == "Mixed^wood"     |
                     myERSdata$PDHWFUEL.D == "Wood^Pellets"    ] <- "WH-Wood"     
                         
  myERSdata$CEUDdhw[ myERSdata$PDHWFUEL.D == "Propane"     ] <- "Other"  
  
  
  
  myERSdata$CEUDdhw[ myERSdata$PDHWFUEL.D == "Solar" & myERSdata$SDHWFUEL.D == "Natural^Gas"     ] <- "WH-Gas"
  myERSdata$CEUDdhw[ myERSdata$PDHWFUEL.D == "Solar" &myERSdata$SDHWFUEL.D == "Electricity"     ] <- "WH-Elec"                    
  myERSdata$CEUDdhw[ myERSdata$PDHWFUEL.D == "Solar" &myERSdata$SDHWFUEL.D == "Oil"     ] <- "WH-Oil"  
  
  myERSdata$CEUDdhw[ myERSdata$SDHWFUEL.D == "Solar" & 
                       ( myERSdata$SDHWFUEL.D == "Hardwood"      |                   
                        myERSdata$SDHWFUEL.D == "Softwood"       |                   
                        myERSdata$SDHWFUEL.D == "Mixed^wood"     |
                        myERSdata$SDHWFUEL.D == "Wood^Pellets"  )  ] <- "WH-Wood"     
                         
  myERSdata$CEUDdhw[ myERSdata$PDHWFUEL.D == "Solar" &  myERSdata$PDHWFUEL.D == "Propane"     ] <- "Other"  




  debug_out (" \n"); 
  debug_out (" DHW Equipment set in ERS according to CEUD definitions :\n")
  debug_vector(c(unique(as.character(myERSdata$CEUDdhw[myERSdata$CEUDdhw != "error"]))))
  
  if (nrow(myERSdata[myERSdata$CEUDdhw== "error",]) > 0 ) {
    debug_out (c("I found that ",nrow(myERSdata[myERSdata$CEUDdhw == "error",])," rows with the following DHW codes rows couldn't be coded:\n"))
    debug_vector(c(unique(as.character(myERSdata$PDHWFUEL.D[myERSdata$CEUDdhw == "error"]))))
  }
 
  
  stream_out("done.\n")
    
  
# Set master flag that indicates if mapping was successful or not 
myERSdata$CEUDerror <- FALSE
myERSdata$CEUDerror[ myERSdata$CEUDdhw == "error"  |
                     myERSdata$CEUDProvince == "error"  |
                     myERSdata$CEUDVintage == "error"  |
                     myERSdata$CEUDForm == "error"  |
                     myERSdata$CEUDSHCode == "error"  |
                     myERSdata$CEUDAirCon == "error"   ] <- TRUE
                   
				   
				   
				   
stream_out (c("\n - I processed ",nrow(myERSdata)," rows. ", nrow(myERSdata[myERSdata$CEUDerror,]), " contained errors \n\n"))
    

	
#=============================== PICK the archetypes we need 
# Archetypes now mapped to CEUD tags. Next steps: 

stream_out(c(" - Selecting ",gTotalArchetypes," to represent Canadian Housing Stock\n"))


debug_out(c("\n\n =============== Try picking archetypes. ====================\n\n"))



myERSdata$ArchInclude <- FALSE 

gCount <- 0
NumOfArch <- NULL
ArchProvince <- NULL



debug_out(c("# of archetypes needed for each province. \n"))

arch_run_total <- 0

#--for each Province in the CEUD Database, calculate the size of each archetype bucket; NumOfArch
for (ArchProvince in unique(CEUDProvFormYr$Province)){
  NumOfArch[ArchProvince] <- ((sum(CEUDProvFormYr$NumHomes[CEUDProvFormYr$Province == ArchProvince]))  / CEUDTotalHomes * gTotalArchetypes)
  NumOfArch[ArchProvince] <- round(NumOfArch[ArchProvince])
  
  debug_out(c(" Prov:", ArchProvince, " #: ", NumOfArch[ArchProvince],"\n"))
  
  arch_run_total = arch_run_total + NumOfArch[ArchProvince] 
    
}  

debug_out(c("Total archetypes:", arch_run_total,"\n"))


#dataframe:   province | number of homes in the set| counter
ArchetypeDataFrame  <- data.frame(ArchProvince,NumOfArch,gCount)
#set ArchProvince from row names
ArchetypeDataFrame$ArchProvince <- row.names(ArchetypeDataFrame)


#--for each HouseID in my ERS data, fill the archetype bucket until full 
ERSProvince <- NULL
ID <- NULL
numberofarchetypesforERSProvinceID <- NULL  
CountOfArchPerProv <- NULL


# Set counters for province to zero. 
for (Prov in unique(CEUDProvFormYr$Province) ){

  CountOfArchPerProv[Prov] <- 0

}





#--for each HOUSEID in my ERS data , add a TRUE or FALSE if that ID will be added to the Archetype
for (ID in unique( myERSdata$HOUSE_ID.D[ ! myERSdata$CEUDerror  ] )){
  
  Prov <- myERSdata$CEUDProvince[myERSdata$HOUSE_ID.D == ID ]

  debug_out(c("> ", ID, "PROV:", Prov,"\n"))
  
  if ( CountOfArchPerProv[Prov] < NumOfArch[Prov] ){
     
	 CountOfArchPerProv[Prov] <- CountOfArchPerProv[Prov] + 1
	 myERSdata$ArchInclude[myERSdata$HOUSE_ID.D == ID] <- TRUE 
	 	 
   }
  
}



nrow(myERSdata[myERSdata$ArchInclude,])


stream_out (" - writing out ERS dbs (myERSdata_out.txt)...")
write.csv(myERSdata, file = "myERSdata_out.txt")	  
stream_out (" done.\n")





q()




#write.csv(myERSdata[myERSdata$ArchInclude], file="myERSdata_ArchInclude.txt")

#ArchProvince <- (myERSdata$CEUDProvince[myERSdata$HOUSE_ID.D == HOUSE_ID.D]) 

#}

#write.table(gCount[ArchProvince], file = "CEUDCounter.txt")

               
                   
HouseIDsFOrModel = c()


#CEUD_for_count <- CEUD[CEUD$year] 


close(DebugConn)
stream_out ("\n\n")