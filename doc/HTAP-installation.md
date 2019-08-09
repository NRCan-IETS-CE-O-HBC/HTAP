

INSTALLING HTAP
===============

# 1. Required software

HTAP depends on the following third-party components:
   
- Ruby: http://rubyinstaller.org/ 
- Git: https://git-scm.com/downloads  
   
In addition to these, you may find the following tools useful: 
   
   • A text file editor, such as notepad++
   • A data analysis program, such as Matlab, tableau or excel. 


# 2. Installation
 
   
HTAP consists of two parts:

1.  HOT2000 (including command-line client) 
2.  HTAP scripts and configuration files. 

To download HOT2000, visit (==change address==), 
and install these files in the following order:
   1. vc_redist.x86.exe (install this one first)
   2. HOT2000 v11.3b90 Setup.exe (if you don't already have it)
   3. HOT2000-CLI Setup.exe - When prompted, set the destination location to `C:\H2K-CLI-Min` 

To Install the HTAP scripts and configuration files, checkout the files from GitHub:
    
        C:\> git clone https://github.com/NRCan-IETS-CE-O-HBC/HTAP.git
    
 Before you can run HTAP simulations, you must first copy the archetype files to the 
 `C:\H2K-CLI-Min\User\ directory`. HTAP includes a ruby script to do this for you:

    PS C:\> cd .\HTAP\Archetypes
    PS C:\HTAP\Archetypes> ruby .\CopyToH2K.rb
