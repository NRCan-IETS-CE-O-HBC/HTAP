#!/usr/bin/env ruby
# els_parser.rb

require 'palindrome2.rb' 
# I want all Strings to have the private letters_only 
# method from this file

class String

=begin rdoc
This provides a public method to access the private letters_only 
method we required from palindrome2.rb.
=end
  def just_letters(case_matters)
    letters_only(case_matters)
  end

end

=begin rdoc
A text-processing parser that does ASCII-only 
Equidistant Letter Sequence analyses similar to that described at 
http://en.wikipedia.org/wiki/Equidistant_letter_sequencing

For my example, I use Moby Dick taken from 
Project Gutenberg, gutenberg.org.
=end
class ELS_Parser

=begin book prose
I used values found at Brendan McKay's page at 
http://cs.anu.edu.au/~bdm/dilugim/moby.html as starting points to 
test my own program.
  
Note some subtle differences - my values are 0-based (where a skip of 0 means 
"go to the next letter"), whereas Prof. McKay defines that as a skip of 1. 
There is a similar difference with regard to starting points. He also 
accomplishes searches for backward terms using a negative skip value, while 
I do a "positive skip" search for a reversed term.
=end

  DEFAULT_SEARCH_PARAMS = {
    :start_pt => 4500,
    :end_pt   => nil, # assumes the end of the String to search when nil
    :min_skip => 126995,
    :max_skip => 127005,
    :term     => 'ssirhan',
  }

  def initialize(filename, search_params=nil)
    @contents = prepare(filename)
    @filename = filename
    reset_params(search_params || DEFAULT_SEARCH_PARAMS)
  end

  def reset_params(search_params)
    @search_params            = search_params
    @search_params[:end_pt] ||= (@contents.size-1)
    # ||= for :end_pt allows nil for 'end of file'
    return self # return self so we can chain methods
  end

=begin rdoc
Performs an ELS analysis on the <i>filename</i> argument, searching for 
the term argument, falling back to the default.
=end
  def search(term=@search_params[:term])
    @search_params[:term] = term
    reversed_term = term.reverse
    warn "Starting search within #{@filename} " + 
      "using #{@search_params.inspect}" if ($DEBUG)
    final_start_pt = @search_params[:end_pt] - @search_params[:term].size
    @search_params[:start_pt].upto(final_start_pt) do |index|
      @search_params[:min_skip].upto(@search_params[:max_skip]) do |skip|
        candidate = construct_candidate(index, skip)
        
        if (candidate == @search_params[:term])
          return report_match(skip, index)
        end
        
        if (candidate == reversed_term)
          return report_match(skip, index, 'reversed ')
        end

      end
    end
    return report_match(false, false)
  end

  private

=begin rdoc
We could get a significant speed increase here by checking against the 
term as we go, returning the empty string whenever it fails to match - 
an application of the 'return guard' notion within the construction of 
the candidate.
=end
  def construct_candidate(index, skip)
    output = ''
    0.upto(@search_params[:term].size-1) do |char_index|
      new_index = (index + (char_index * (skip + 1)))
      return '' if (new_index >= @contents.size)
      output += @contents[new_index].chr
    end
    return output
  end

=begin rdoc
Creates a 'letters only' version of the contents of a <i>filename</i> 
argument in preparation for ELS analysis. Assumes case-insensitivity.
=end
  def prepare(filename, case_matters=false)
    File.open(filename, 'r').readlines.to_s.just_letters(case_matters) 
  end

=begin
Either report the variables at which a match was found, or report 
failure for this set of search params.
=end
  def report_match(skip, index, reversed='')
    return "No match within #{@filename} using " + 
      @search_params.inspect unless index
    return "Match for #{@search_params[:term]} " + 
      "#{reversed}within #{@filename} " + 
      "at index #{index}, using skip #{skip}"
  end

end # ELS_Parser
