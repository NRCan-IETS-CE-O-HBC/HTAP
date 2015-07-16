#!/usr/bin/env ruby
# simple_cgi.rb

require 'cgi'

class Simple_CGI

  EMPTY_STRING = ''
  TITLE = 'A simple CGI script'

  def display()
    cgi = CGI.new('html4')
    output = cgi.html do
      cgi.head do
        cgi.title { TITLE }
      end + 
      cgi.body do 
        cgi.h1 { TITLE } + 
        show_def_list(cgi)
      end
    end
    cgi.out { output.gsub('><', ">\n<") }
  end

  private

  def get_items_hash()
    {
      'script'   => ENV['SCRIPT_NAME'],
      'server'   => ENV['SERVER_NAME'] || %x{hostname} || EMPTY_STRING,
      'software' => ENV['SERVER_SOFTWARE'],
      'time'     => Time.now,
    }
  end

  def show_def_list(cgi)
    cgi.dl do 
      items = get_items_hash.merge(cgi.params)
      items.keys.sort.map do |term|
        definition = items[term]
        "<dt>#{term}</dt><dd>#{definition}</dd>\n"
      end.join( EMPTY_STRING )
    end
  end

end

Simple_CGI.new.display()
