#!/usr/bin/env ruby
# softwrap.rb

=begin rdoc
"Softwrap" a filename argument, preserving "\n\n"
between paragraphs but compressing "\n" and other
whitespace within each paragraph into a single space.
=end
def softwrap(filename)
  File.open(filename, 'r').readlines.inject('') do |output,line| 
    output += softwrap_line(line)
  end.gsub(/\t+/, ' ').gsub(/ +/, ' ')
end # softwrap

=begin rdoc
Return "\n\n" if the <b>String</b> argument
has no length after being chomped (signifying that it
was a blank line separating paragraphs), otherwise 
return the chomped line with a trailing space for 
padding.
=end
def softwrap_line(line)
  return "\n\n" if line == "\n"
  return line.chomp + ' '
end # softwrap_line

puts softwrap(ARGV[0])
