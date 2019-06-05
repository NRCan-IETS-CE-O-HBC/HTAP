# TRAINING NOTES:

1) single-cmd-line run
----------------------

*** commands: 

```powershell
cd C:\HTAP\applications\training\single-cmd-line-run
C:\HTAP\applications\training\single-cmd-line-run> C:\HTAP\substitute-h2k.rb -c .\HOT2000.choices -o C:\HTAP\HTAP-options.json  -v
```


a) Run command. Talk about what is happening. 

substitute-h2k is reading the specifications in the .choice file, and for each choice, the associated parameters from the options file. Based on that data, substitute-h2k.rb will:

   - open a hot2000 file, 
- manipulate it to match the specifications from the .choice file,
- invoke hot2000 to evaluate energy use 
- parse hot2000 output.
- write out results.

Note that results are shown on screen. They are also written to:
   - a token-value file. 
- the browse.rpt file in the sim-output directory
- the modified .h2k file 



b) Open up the choice file - Look at contents 

- Choice file is in token-value format and is used to spec how a hot2000 file should be modified and invoked for the simulation.

  - Some choices define how hot2000 should be invoked (archetype, result mode) while others define how a .h2k file should be modified. 
    



c) Open up the options file - look at contents        

- The .options file defines the valid choices that can be set for each parameter, and also contain info that substitute-h2k uses to determine how the .h2k file should be modified accordingly

- Note that there is info in the .options file that pertains to an earlier ESP-r implementation - not all of the data is relevant to hot2000. The best (not very good) way to determine which is which ? Look at the tags at the top of an options definition.

  

d) Talk about defaults: Not all of the options need to be set in the .choice file. If an option is omitted, substitute-h2k will attempt to use the default.    


e) Talk about NA - 

Throughout HTAP, "NA" is used as a code for 'leave the file alone' Whatever parameters exist in the original file will be left in the HTAP run


f) Change some parameters in the .choice file:

Substitute : 

         Opt-Archetype : SmallSFD  to LargeSFD
         Opt-Location  : NA        to CALGARY
         Opt-ACH       : NA        to ACH_0_6


g) Demonstrate a typical error - misspell Calggary