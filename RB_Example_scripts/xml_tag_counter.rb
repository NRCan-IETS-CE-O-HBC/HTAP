#!/usr/bin/env ruby
# xml_tag_counter.rb

=begin rdoc
This script uses the Rexml parser, which is written in Ruby itself.
Find out more at http://www.germane-software.com/software/rexml
=end
require 'rexml/document'

class Hash

=begin rdoc
Given that <b>self</b> is a <b>Hash</b> with keys of
XML tags and values of their respective counts in an 
XML source file, sort by the tag count, descending.
Fall back to an ascending srt of the tag itself, 
weighted half as strongly.
=end
  def sort_by_tag_count()
    self.sort do |a, b| 
      ( (b[1] <=> a[1]) * 2 ) + (a[0] <=> b[0])
    end
  end

  def sorted_by_tag_count()
    # sort_by_tag_count returns an Array of Arrays...
    sort_by_tag_count.inject({}) do |memo,pair|
      tag, count = pair
      memo.merge( { tag => count } )
    end
    # so we can re-Hash it with inject
  end

=begin rdoc
Merge with another <b>Hash</b>, but add values rather
than simply overwriting duplicate keys.
=end
  def merge_totals(other_hash)
    other_hash.keys.each do |key|
      self[key] += other_hash[key]
    end
  end 

=begin rdoc
Your basic pretty formatter, returns a <b>String</b>.
=end
  def pretty_report()
    output = ''
    sort_by_tag_count.each do |pair|
      tag, count = pair
      output += "#{tag}: #{count}\n"
    end
    return output
  end 
 
end # Hash

=begin rdoc
Returns DOM elements of a given filename.
=end
def get_elements_from_filename(filename)
  REXML::Document.new(File.open(filename)).elements()
end

=begin rdoc
Returns a <b>Hash</b> with keys of XML tags and values 
of those tags' counts within a given XML document. 
Calls itself recursively on each tag's elements.
=end
def tag_count(elements)
  count_of = Hash.new(0) # note the default value of 0
  elements.to_a.each do |tag|
    count_of[tag.name()] += 1
    count_of.merge_totals(tag_count(tag.elements))
  end
  return count_of
end 

puts tag_count(get_elements_from_filename(ARGV[0])).pretty_report()
