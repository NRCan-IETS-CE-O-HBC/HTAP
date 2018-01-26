

NBC936-AW-ruleset:
==================
These files can be used to test calling the NRC's NBC 936 ruleset from the 
HTAP parallel run manager (htap-prm.rb). 

INSTALLATION
------------

To use these scripts, you need to install the NRC perl scripts, which 
are not presently in the git repository. TO do so: 

1) Obtain the modified NRC analysis scripts (currently in the #htap 
   slack channel under the name "Modified NRC-scripts.zip") 
  
2) Install those scripts by unzipping them in your HTAP directory 
   (C:\HTAP\)
   
USAGE
-----
       
To run these files, navigate to C:\HTAP\applications\NBC936-AW-ruleset> &  execute: 

   C:\HTAP\htap-prm.rb -o .\HOT2000.options -r .\DemoAW936Ruleset.run -v 


CONFIGURATION 
-------------
Application of the rulesets is presently configured in the .run file. Within the 
RunScope section, the ruleset tag indicates which rules should be applied to 
models, along with applied upgrades. Rulesets are specified as a comma-separated list:

   rulesets   = rule1, rule2, rule3 ...

Currently the following rule sets are supported 

    as-found:         .h2k & choice files files are run as is, along with combinations 
                       from the upgrades section.
                       
    936_2015_AW_HRV:  .h2k & choice files are modified to meet the requirements of 9.36,
                       for homes with an HRV     

    936_2015_AW_noHRV:.h2k & choice files are modified to meet the requirements of 9.36,
                       for homes without an HRV     
                       
Note upgrades specified in the Upgrades section of the .run file will supersede the baseline. 
To ensure that the baseline ruleset appears unaltered in the results, add NA to all envelope/
hvac/mechanical upgrade specs. 
                 