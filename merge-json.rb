require 'json'

$json = Hash.new 
$json = Dir['./results-*.json'].map { |f| JSON.parse File.read(f) }.flatten


  $JSONoutput  = File.open("merged.json", 'w') 
  $JSONoutput.write(JSON.pretty_generate($json))
  $JSONoutput.close 