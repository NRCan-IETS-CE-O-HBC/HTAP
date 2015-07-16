#!/usr/bin/env ruby
# word_count.rb

class String
  
  def num_matches(thing_to_match)
    return self.split(thing_to_match).size - 1
  end # num_matches

end # String

BAR_LENGTH   = 20
  
# to match these calculations with the output of some word processors
FUDGE_FACTOR = 0.82   

def word_count(files)
  output = ''
  total_word_count = 0
  files.each do |filename|
    file_word_count = word_count_for_file(filename)
    output += "#{filename} has #{file_word_count} words.\n"
    total_word_count += file_word_count
  end # each file
  return output + 
    '-' * BAR_LENGTH + "\n" + 
    "Total word count = #{total_word_count}" +
    " (#{(total_word_count * FUDGE_FACTOR)})"
end # word_count

def word_count_for_file(filename)
  f = File.new(filename, 'r')
  contents = f.read()
  f.close()
  spaces = contents.num_matches(' ')
  breaks = contents.num_matches("\n")
  false_doubles = contents.num_matches(" \n")
  double_spaces = contents.num_matches('  ')
  hyphens = contents.num_matches('-')
  false_doubles += double_spaces + hyphens
  words = spaces + breaks - false_doubles + 1
  return words
end # word_count_for_file

puts word_count(ARGV)
