#!/usr/bin/env ruby
# line_num.rb

def get_lines(filename)
  return File.open(filename, 'r').readlines
end

def get_format(lines)
  return "%0#{lines.size.to_s.size}d"
end

def get_output(lines)
  format = get_format(lines)
  output = ''
  lines.each_with_index do |line,i| 
    output += "#{sprintf(format, i+1)}: #{line}"
  end
  return output
end

print get_output(get_lines(ARGV[0]))
