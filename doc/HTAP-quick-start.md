# A Quick start guide for using HTAP #

Before following this guide, you must first install HTAP using the 
instructions in `HTAP-installation.md`.

## HOW TO: use `htap-prm.rb` for batch processing

`HTAP-prm.rb` is a parallel run manager that can configure and dispatch multiple HOT2000 
simulaitons over cocurrent threads, and recover their output. For input, you must 
supply `htap-prm.rb` with a `.run` file, which contains pointers to other databases 
that HTAP should use, configuration options for the analysis, and instructions for 
how hot2000 files should be changed. 

To start an HTAP run, use the following command:

    htap-prm.rb -r [run-file] -v -j -t 10 -c

## HOW TO: change the  ##

