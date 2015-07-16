#!/usr/bin/env ruby
# matching_members.rb

=begin rdoc
Extend the built-in <b>Array</b> class.
=end
class Array

=begin rdoc
Takes a <b>Proc</b> as an argument, and returns all members
matching the criteria defined by that <b>Proc</b>.
=end
  def matching_members(some_proc)
    find_all { |i| some_proc.call(i) }
  end

end

digits = (0..9).to_a
lambdas = Hash.new()
lambdas['five+']   = lambda { |i| i >= 5 }
lambdas['is_even'] = lambda { |i| (i % 2).zero? }

lambdas.keys.sort.each do |lambda_name|
  lambda_proc  = lambdas[lambda_name]
  lambda_value = digits.matching_members(lambda_proc).join(',')
  puts "#{lambda_name}\t[#{lambda_value}]\n"
end
