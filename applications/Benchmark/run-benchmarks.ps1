#
$testNum = 0 

$Times = @()
$Evals = @()
$Failures = @()
$Threads = @()
$RunDefs = @()
#
#
#
#
#rm -Force htap-thread-test-results.csv

$rand = Get-Random 

$batchTxt = $args[0]

$batch= "$($batchTxt)-$($rand)"


Write-Output "--- HTAP batch test - $($batch) ---"

$run10   = 0 
$run20   = 1 
$run40   = 1 
$run60   = 1 
$run80   = 1 
$run300  = 1 
$run600  = 1 
$run2400 = 1

if ($run10 -eq 1) {
for ( $i = 1; $i -le 10; $i++ ){
  # 1/2/3/4/5..10
  $threadcount = $i

  
  $Threads  += $threadcount
  $RunDefs  += ".\Benchmark-e10.run" 
  $Failures += -1
  $Times    += -1
  $Evals    += -1 

  Write-Output "+  Config # $($i) |  Threads : $($Threads[$testNum]) | Run file : $($RunDefs[$TestNum]) "
  
  $testNum++ 
  
} 
}

if ($run20 -eq 1) {
for ( $i = 1; $i -le 20; $i++ ){
  # 1/2/3/4/5/6/7/8/9/10..20
  $threadcount = $i
  
  
  $Threads  += $threadcount
  $RunDefs  += ".\Benchmark-e20.run" 
  $Failures += -1
  $Times    += -1
  $Evals    += -1 

  Write-Output "+  Config # $($i) |  Threads : $($Threads[$testNum]) | Run file : $($RunDefs[$TestNum]) "
  
  $testNum++ 
  
} 
}

if ($run40 -eq 1) {
for ( $i = 0; $i -le 22; $i++ ){
  #5/10/15/20..40
  $threadcount = $i * 2
    if ( $i -eq 0 ) {
    $threadcount = 1
  }
  
  
  
  $Threads  += $threadcount
  $RunDefs  += ".\Benchmark-e40.run" 
  $Failures += -1
  $Times    += -1
  $Evals    += -1 

  Write-Output "+  Config # $($TestNum) |  Threads : $($Threads[$testNum]) | Run file : $($RunDefs[$TestNum]) "
  
  $testNum++ 
  
} 
}


if ($run60 -eq 1) { 
for ( $i = 0; $i -le 24; $i++ ){
  #5/10/15/20/25/30/35/40/46
  $threadcount = $i * 2
    if ( $i -eq 0 ) {
    $threadcount = 1
  }

  
  
  $Threads  += $threadcount
  $RunDefs  += ".\Benchmark-e60.run" 
  $Failures += -1
  $Times    += -1
  $Evals    += -1 

  Write-Output "+  Config # $($TestNum) |  Threads : $($Threads[$testNum]) | Run file : $($RunDefs[$TestNum]) "
  
  $testNum++ 
  
} 
}

if ($run80 -eq 1) {
for ( $i = 0; $i -le 24; $i++ ){
  #5/10/15/20..40
  $threadcount = $i * 2

      if ( $i -eq 0 ) {
    $threadcount = 1
  }
  
  
  
  
  $Threads  += $threadcount
  $RunDefs  += ".\Benchmark-e80.run" 
  $Failures += -1
  $Times    += -1
  $Evals    += -1 

  Write-Output "+  Config # $($TestNum) |  Threads : $($Threads[$testNum]) | Run file : $($RunDefs[$TestNum]) "
  
  $testNum++ 
  
} 
}


if ($run300 -eq 1) {
for ( $i = 0; $i -le 24; $i++ ){
  #10/15/20/25/30/35/40
  $threadcount = $i * 2

    
  if ( $i -eq 0 ) {
    $threadcount = 1
  }
  
  
  
  $Threads  += $threadcount
  $RunDefs  += ".\Benchmark-e300.run" 
  $Failures += -1
  $Times    += -1
  $Evals    += -1 

  Write-Output "+  Config # $($TestNum) |  Threads : $($Threads[$testNum]) | Run file : $($RunDefs[$TestNum]) "
  
  $testNum++ 
  
} 
}
if ($run600 -eq 1) {
for ( $i = 0; $i -le 24; $i++ ){
  #10/15/20/25/30/35/40
  $threadcount = $i * 2

  if ( $i -eq 0 ) {
    $threadcount = 1
  }
  
  
  $Threads  += $threadcount
  $RunDefs  += ".\Benchmark-e600.run" 
  $Failures += -1
  $Times    += -1
  $Evals    += -1 

  Write-Output "+  Config # $($TestNum) |  Threads : $($Threads[$testNum]) | Run file : $($RunDefs[$TestNum]) "
  
  $testNum++ 
  
} 
}

if ($run2400 -eq 1) {
for ( $i = 0; $i -le 24; $i++ ){
  #10/15/20/25/30/35/40
  $threadcount = $i * 2

  if ( $i -eq 0 ) {
    $threadcount = 1
  }
  
  
  $Threads  += $threadcount
  $RunDefs  += ".\Benchmark-e2400.run" 
  $Failures += -1
  $Times    += -1
  $Evals    += -1 

  Write-Output "+  Config # $($TestNum) |  Threads : $($Threads[$testNum]) | Run file : $($RunDefs[$TestNum]) "
  
  $testNum++ 
  
} 
}



# Run tests 

#"Test#, RunFile, Threads, Time, Evaluations, Failures" >  htap-thread-test-results.csv 


for ( $i = 0;  $i -lt $TestNum ; $i++ ){


  Write-Output " ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  Write-Output " TEST# $($i) |  Threads : $($Threads[$i]) | Run file : $($RunDefs[$i]) "
  Write-Output " ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  
  
  rm -r .\HTAP-work-*
  rm -r .\HTAP-sim-*  
  
  
  $sw = [Diagnostics.Stopwatch]::StartNew()
  ruby E:\HTAP\htap-prm.rb -o C:\HTAP\HOT2000.options -r $RunDefs[$i] -t $Threads[$i] -j
  $sw.Stop()
  
  $a = Get-Content HTAP-prm-output.csv
  $Evals[$i] = $a.count - 1 

  $a = Get-Content HTAP-prm-failures.txt
  $Failures[$i] = $a.count 

  $Times[$i] = $sw.ElapsedMilliseconds/1000
  
  "$($batch):$($i),  $($RunDefs[$i]), $($Threads[$i]), $($Times[$i]), $($Evals[$i]), $($Failures[$i]) " >> C:\HTAP\applications\Benchmark\htap-thread-test-results.csv 

  if ( $a.count -gt 0 ) {
  
    exit
    
  } 
  
}


