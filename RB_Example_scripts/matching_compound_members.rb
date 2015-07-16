#!/usr/bin/env ruby
# matching_compound_members.rb

=begin rdoc
Extend the built-in <b>Array</b> class.
=end
class Array

=begin rdoc
Takes a block as an argument, and returns a list of 
members matching the criteria defined by that block.
=end
  def matching_members(&some_block)
    find_all(&some_block)
  end

=begin rdoc
Takes an <b>Array</b> of <b>Proc</b>s as an argument, 
and returns all members matching the criteria defined 
by each <b>Proc</b> via <b>Array.matching_members</b>. 
Note that it uses the ampersand to convert from 
<b>Proc</b> to block.
=end
  def matching_compound_members(procs_array)
    procs_array.map do |some_proc|
      # collect each proc operation
      matching_members(&some_proc)
    end.inject(self) do |memo,matches| 
      # find all the intersections, starting with self
      # and whittling down until we only have members 
      # that have matched every proc
      memo & matches
    end
  end

end

# Now use these methods in some operations.
digits = (0..9).to_a
lambdas = Hash.new()
lambdas['five+']   = lambda { |i| i if i >= 5 }
lambdas['is_even'] = lambda { |i| i if (i % 2).zero? }
lambdas['div_by3'] = lambda { |i| i if (i % 3).zero? }

lambdas.keys.sort.each do |lambda_name|
  lambda_proc   = lambdas[lambda_name]
  lambda_values = digits.matching_members(&lambda_proc).join(',')
  puts "#{lambda_name}\t[#{lambda_values}]\n"
end

puts "ALL\t[#{digits.matching_compound_members(lambdas.values).join(',')}]"
