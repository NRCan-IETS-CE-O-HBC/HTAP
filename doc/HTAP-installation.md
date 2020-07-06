

INSTALLING HTAP
===============

## 1. Required software

HTAP depends on the following third-party components:

- Ruby: http://rubyinstaller.org/ 
- Git: https://git-scm.com/downloads  
  

In addition to these, you may find the following tools useful: 

-  A text file editor, such as notepad++

-  A data analysis program, such as Matlab, tableau or excel. 


## 2. Installation


HTAP consists of two parts:

1.  HOT2000 (including command-line client) 
2.  HTAP scripts and configuration files. 

To download HOT2000, visit NRCan's HOT2000 portal (https://www.nrcan.gc.ca/energy-efficiency/energy-efficiency-homes/professional-opportunities/tools-industry-professionals/20596#training) and to download the energy-advisor software , 
and install these files in the following order:

   2. HOT2000 Setup.exe (if you don't already have it)
   3. HOT2000-CLI Setup.exe - When prompted, set the destination location to `C:\H2K-CLI-Min` 

To Install the HTAP scripts and configuration files, checkout the files from GitHub:
    
        C:\> git clone https://github.com/NRCan-IETS-CE-O-HBC/HTAP.git

 Before you can run HTAP simulations, you must first copy the library files to the 
 `C:\H2K-CLI-Min\User\` directory. HTAP includes a ruby script to do this for you:

    PS C:\> cd .\HTAP\lib
    PS C:\HTAP\lib> ruby .\CopyToH2K.rb

## 3. Next steps ##

If you are new to HTAP, have a look at the [Quick-Start](./HTAP-quick-start.md) Guide.