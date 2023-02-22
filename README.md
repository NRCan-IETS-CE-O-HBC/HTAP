
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

## Requirements & Installation ##

HTAP requires the following components be installed on your computer:
 -  Ruby (http://rubyinstaller.org/)
 -  Git (https://git-scm.com/downloads)
 -  The HOT2000 command-line client, installed into `C:\H2K-cli-min\` 

In addition to these, you may find the following tools useful: 
 -  A text file editor, such as notepad++ 
 -  A data analysis program, such as Matlab, tableau or excel. 

To install HTAP, check out the files from Git-hub:

    C:\> git clone https://github.com/NRCan-IETS-CE-O-HBC/HTAP.git


Before you can run HTAP simulations, you must first copy the archetype files to the 
`C:\H2K-CLI-Min\User\ directory`. HTAP includes a ruby script to do this for you:

    PS C:\> cd .\HTAP\Archetypes
    PS C:\HTAP\Archetypes> ruby .\CopyToH2K.rb


## Versions ##

The `master` branch contains the most stable version of HTAP. New features are
regularly integrated  into the `general-dev` branch. Other branches include new
features under development for future versions of HTAP.

## Documentation ##

 - [Introduction to HTAP](/doc/Introduction-to-HTAP.md): a summary of 
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

