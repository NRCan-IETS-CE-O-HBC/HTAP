#!/usr/bin/env ruby
# xml_well_formedness_checker.rb

=begin rdoc
This script uses the xml/dom/builder, written by YoshidaM.
=end
require 'xml/dom/builder'

class File

  def well_formed_xml?()
    read.well_formed_xml?
  end

end

class String

  def well_formed_xml?()
    builder = XML::DOM::Builder.new(0)
    builder.setBase("./")

    begin
      builder.parse(self, true)
    rescue XMLParserError
      return false
    end

    return true
  end

end

def well_formed?(filename)
  return unless filename
  return File.open(filename, 'r').well_formed_xml?
end

puts well_formed?(ARGV[0])
