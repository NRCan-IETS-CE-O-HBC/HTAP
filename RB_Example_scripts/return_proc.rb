#!/usr/bin/env ruby
# return_proc.rb

def return_proc(criterion, further_criterion=1)

  proc_of_criterion = {
    'div_by?' => lambda { |i| i if (i % further_criterion).zero? },
    'is?'     => lambda { |i| i == further_criterion }
  }

  # allow 'is_even' as an alias for divisible by 2
  return return_proc('div_by?', 2) if criterion == ('is_even')
 
  proc_to_return = proc_of_criterion[criterion]
  fail "I don't understand the criterion #{criterion}" unless proc_to_return
  return proc_to_return
  
end

require 'boolean_golf.rb' 

# Demonstrate calling the proc directly
even_proc = return_proc('is_even') # could have been ('div_by', 2)
div3_proc = return_proc('div_by?', 3)
is10_proc = return_proc('is?', 10)
[4, 5, 6].each do |num|
  puts %Q[Is #{num} even?: #{even_proc[num].true?}]
  puts %Q[Is #{num} divisible by 3?: #{div3_proc[num].true?}]
  puts %Q[Is #{num} 10?: #{is10_proc[num].true?}]
  printf("%d is %s.\n\n", num, even_proc[num].true? ? 'even' : 'not even')
end

# Demonstrate using the proc as a block for a method
digits = (0..9).to_a
even_results = digits.find_all(&(return_proc('is_even')))
div3_results = digits.find_all(&(return_proc('div_by?', 3)))
puts %Q[The even digits are #{even_results.inspect}.]
puts %Q[The digits divisible by 3 are #{div3_results.inspect}.]
puts
