#!/usr/bin/env ruby
# random_sig-windows.rb

home = "#{ENV['HOMEDRIVE']}" + "#{ENV['HOMEPATH']}"
filename = ARGV[0] || (home + '\\Documents\\Ruby\\RBE_scripts\\extras\\Einstein_quotes.txt')
quotations_file = File.new(filename, 'r')
file_lines = quotations_file.readlines()
quotations_file.close()
quotations      = file_lines.to_s.split('\n')
random_index    = rand(quotations.size)
quotation       = quotations[random_index]
sig_file_name   = home + '\\Documents\\Ruby\\RBE_scripts\\.signature'
signature_file  = File.new(sig_file_name, 'w')
signature_file.puts 'Jeff Blake |   jblake@nrcan.gc.ca |   http://nrcan.gc.ca/'
signature_file.puts quotation
signature_file.close()
