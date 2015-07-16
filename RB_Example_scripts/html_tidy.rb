#!/usr/bin/env ruby
# html_tidy.rb
# cleans up html files

EMPTY_STRING = ''

SIMPLE_TAG_REPLACEMENTS = {
  
  #closers
  /\<\/b\>/i             => '</strong>',
  /\<\/i\>/i             => '</em>',
  /\<\/strong\><\/td\>/i => '</th>',
  /\<\/u\>/i             => '</div>',
  
  #openers
  /\<b\>/i               => '<strong>',
  /\<i\>/i               => '<em>',
  /\<td\>\<strong\>/i    => '<th>',
  /\<u\>/i               => '<div style="text-decoration: underline;">',
  # again, more as appropriate

}

TIDY_EXTENSION = '.tidy'

TIDY_OPTIONS = '-asxml -bc' # possible add -access 3

UNWANTED_REGEXES = [
  /^<meta name=\"GENERATOR\" content=\"Microsoft FrontPage 5.0\">$/,
  /^ *$/,
  /^\n$/,
  # more as appropriate
]

def declare_regexes_and_replacements()
  replacement_of = Hash.new()
  UNWANTED_REGEXES.each do |discard| 
    replacement_of[discard] = EMPTY_STRING
  end
  return replacement_of.merge(SIMPLE_TAG_REPLACEMENTS)
end

=begin rdoc
This lacks a ! suffix, because it duplicates the argument, and 
returns the changes made to that duplicate, rather than overwriting.
=end
def perform_replacements_on_contents(contents)
  output = contents.dup
  replacement_of = declare_regexes_and_replacements()
  replacement_of.keys.sort_by { |r| r.to_s }.each do |regex|
    replace = replacement_of[regex]
    output.each { |line| line.gsub!(regex, replace) }
  end
  return output
end

=begin rdoc
This has the ! suffix, because it destructively writes
into the filename argument provided.
=end
def perform_replacements_on_filename!(filename)
  if (system('which tidy > /dev/null'))
    new_filename = filename + TIDY_EXTENSION
    system("tidy #{TIDY_OPTIONS} #{filename} > #{new_filename} 2> /dev/null") 
    contents = File.open(new_filename, 'r').readlines()
    new_contents = perform_replacements_on_contents(contents)
    File.open(new_filename, 'w') { |f| f.puts(new_contents) }
  else
    puts "Please install tidy.\n"
  end
end

ARGV.each do |filename|
  perform_replacements_on_filename!(filename)
end
