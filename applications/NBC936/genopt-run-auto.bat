java -classpath genopt.jar genopt.GenOpt Genopt-run-auto-1++.GO-ini
timeout /t 10 
copy OutputListingAll.txt CloudResultsBatch1.txt
del OutputListingAll.txt
java -classpath genopt.jar genopt.GenOpt Genopt-run-auto-2++.GO-ini
timeout /t 10 
copy OutputListingAll.txt CloudResultsBatch2.txt
del OutputListingAll.txt
