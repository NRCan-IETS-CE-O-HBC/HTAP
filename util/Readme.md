HTAP/util
=========

This file contans numerous utility scripts to aid management of HTAP data. 
While none of these are core to HTAP functions, but they are useful for examining and maintaining files and databases.

- `examine-options.rb` script that parses an HTAP-options.json file and reports interesting info
- `geth2kinfo.rb`: script that parses an H2k file and reports info about its geometry, hvac...
- `import-nrcan-cost-sheets.rb`: script that parses a set of unit cost sheets (in .cvs format) and generates a HTAPUnitCosts.json file.
- `manage_options.rb`:	script that performs some simple operations on the HTAP-options.json file
- `wall-def-import.rb`:	parses a text file containing different wall definitions, and imports them into the HTAP-options.json file.


Files that should be relocated somewhere else: 
- `wall-defs.txt`: List of wall definitions imported from CWC wall assembly database.
