
Housing Technology Assessment Platform (HTAP)
=============================================

HTAP is a collection of data and tools that automate and extend the HOT2000
residential energy simulation tool. The HOT2000 software suite can be obtained
directly from [Natural ResourcesCanada](https://www.nrcan.gc.ca/energy/efficiency/homes/20596). 

HTAP has been used to:
 -  Optimize the design of Net-Zero Energy and Net-Zero-Ready Housing,  and deep
    energy retrofits
 -  Investigate the impact potential of different heating technologies 
    in the Canadian housing stock
 -  Estimate costs and benefits associated with changes in the building 
    code

Natural Resources Canada (NRCan) developed HTAP to support research and program
development. While HTAP is published in the hope others will find it useful,
NRCan provides no warranty or support  for the software or its users. 

Installing HTAP
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


## Versions ##

The `master` branch contains the most stable version of HTAP. New features are
regularly integrated  into the `general-dev` branch. Other branches include new
features under development for future versions of HTAP.

## Documentation ##

 - [Introduction to HTAP](./doc/Introduction%20to%20HTAP.docx): a summary of 
   HTAP features and use
 - [HTAP-input-and-output.md](./doc/HTAP-input-and-output.md): Documentation 
   for HTAP input & output

## Contributors ##

HTAP is developed and maintained by CanmetENERGY-Ottawa, a division of Natural
Resources Canada. HTAP's current capabilities reflect contributions from the 
National Research Council and other third-party contributors. 

#### Natural Resources Canada / CanmetENERGY Ottawa ####

 - Alex Ferguson
 - Jeff Blake 
 - Julia Purdy 
 - Rasoul Asaee

#### National Research Council ####

 - Adam Wills 

#### StepWin ####

 - Arman Mottaghi

## Contact ##

Direct inquiries about HTAP and related projects to Alex.Ferguson@canada.ca

