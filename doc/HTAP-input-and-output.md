
Input and Output in HTAP
========================

Input/Output model 
------------------

To be written

Inputs - 
------

### 1) `Opt-Location`

* **Description** : Defines weather file location to be used in the HTAP run.
* **Typical values**: Municipal location corresponding to valid HOT2000 weather file 
  (e.g. `Calgary`, `Toronto`, `Vancouver` ...)
* **HOT2000 bindings**:  Based on the specified `Opt-Location`, __substitute-h2k.rb__ will set the 
  weather database (typically `Wth110.dir`, the weather region and the weather file location. 
* **Other things you should know**: 
  - By design, HOT2000 will also attempt to match the weather location to 
    a valid set of fuel cost data in the fuel library. This feature has proven temperamental, 
    and should be used with care. Note that HOT2000 will not generate errors or warnings if 
    the location is not successfully matched to a fuel library. 
  - Setting `Opt-Location = NA` will cause  __substitute-h2k.rb__  to run the h2k file with 
    whatever weather location was defined in the original file. 
  
#### Sample `.choice` definition for  `Opt-Location`  
         Opt-Location = Toronto 
         
#### Sample `.options` definition for  `Opt-Location`

         *attribute:start 
         *attribute:name  = Opt-Location
         *attribute:tag:1 = OPT-H2K-WTH-FILE
         *attribute:tag:2 = OPT-H2K-Region
         *attribute:tag:3 = OPT-H2K-Location
         *attribute:default = Ottawa 
         
         *option:NA:value:1 = NA
         *option:NA:value:2 = NA
         *option:NA:value:3 = NA
         *option:NA:cost:total    = 0
         
         *option:Whitehorse:value:1 = Wth110.dir
         *option:Whitehorse:value:2 = 11
         *option:Whitehorse:value:3 = 69
         *option:Whitehorse:cost:total    = 0
           
         *option:Toronto:value:1 = Wth110.dir
         *option:Toronto:value:2 = 5
         *option:Toronto:value:3 = 42
         *option:Toronto:cost:total    = 0
         






