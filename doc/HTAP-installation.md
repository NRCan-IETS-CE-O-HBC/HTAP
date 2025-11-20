

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

   1. HOT2000 Setup.exe (if you don't already have it)
   2. HOT2000-CLI Setup.exe - When prompted, set the destination location to `C:\H2K-CLI-Min` 

To Install the HTAP scripts and configuration files, checkout the files from GitHub using the following command in the Power Shewll (PS):
    
        C:\> git clone https://github.com/NRCan-IETS-CE-O-HBC/HTAP.git

Before HTAP simulations can be run , archetype files must be copied to the 
C:\H2K-CLI-Min

The path to the library of archetypes is as follows:
C:\> cd .\HTAP\lib

HTAP includes a ruby script to do this:

    PS C:\HTAP\lib> ruby .\CopyToH2K.rb

## 3. Syncing up to the most recent version

sync with the most recent version using the git pull command in the Power Shell:
C:\Users> cd: C:\HTAP
C:\HTAP> git pull
Already up to date.
C:\HTAP>

## 4. Next steps ##

If you are new to HTAP, have a look at the [Quick-Start](./HTAP-quick-start.md) Guide.

For training excercises look at HTAP-Training/[HTAP-training.md](https://github.com/NRCan-IETS-CE-O-HBC/HTAP-Training/blob/master/HTAP-training.md)
