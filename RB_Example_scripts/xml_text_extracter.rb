#!/usr/bin/env ruby
# xml_text_extractor.rb

CHOMP_TAG = lambda { |tag| tag.to_s.chomp }

=begin rdoc
This script uses the Rexml parser, which is written in Ruby itself.
Find out more at http://www.germane-software.com/software/rexml
=end
require 'rexml/document'

=begin rdoc
Returns DOM elements of a given filename.
=end
def get_elements_from_filename(filename)
  REXML::Document.new(File.open(filename)).elements()
end

=begin rdoc
Returns a <b>String</b> consisting of the text of a given XML document 
with the tags stripped.
=end
def strip_tags(elements)
  return '' unless (elements.size > 0)
  return elements.to_a.map do |tag|
    tag.texts.map(&CHOMP_TAG).join('') + strip_tags(tag.elements)
  end.join(' ') 
end

puts strip_tags(get_elements_from_filename(ARGV[0]))
