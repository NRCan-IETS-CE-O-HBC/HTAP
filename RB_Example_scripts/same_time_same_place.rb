#!/usr/bin/env ruby -w
# same_time_same_place.rb

class SameTimeSamePlace

  EPISODE_NAME = 'Same Time, Same Place'
 
=begin rdoc 
This Hash holds various procedure objects. One is formed by the generally 
preferred Kernel.lambda method. Others are created with the older Proc.new 
method, which has the benefit of allowing more flexibility in its argument 
stack.
=end
  QUESTIONS = {
    
    :ternary => Proc.new do |args|
      state    = args ? args[0] : 'what'
      location = args ? args[1] : 'what'
      "Spike's #{state} in the #{location}ment?"
    end,

    :unless0th => Proc.new do |*args|
      args = %w/what what/ unless args[0]
      "Spike's #{args[0]} in the #{args[1]}ment?"
    end,

    :nitems => Proc.new do |*args|
      args.nitems >= 2 || args.replace(['what', 'what'])
      "Spike's #{args[0]} in the #{args[1]}ment?"
    end,

    :second_or => Proc.new do |*args|
      args[1] || args.replace(['what', 'what'])
      "Spike's #{args[0]} in the #{args[1]}ment?"
    end,

    :needs_data => lambda do |args|
      "Spike's #{args[0]} in the #{args[1]}ment?"
    end

  }

  DATA_FROM_ANYA = ['insane', 'base']

  def SameTimeSamePlace.describe()

    same_as_procs = [
      SameTimeSamePlace.yield_block(&QUESTIONS[:nitems]),
      QUESTIONS[:second_or].call(),
      QUESTIONS[:unless0th].call(),
      SameTimeSamePlace.willow_ask,
    ]
  
		return <<DONE
In #{EPISODE_NAME},
  Willow asks "#{QUESTIONS[:ternary].call(nil)}",
  #{same_as_procs.map do |proc_output| 
    'which is the same as "' + proc_output + '"'
	end.join("\n  ") 
  }
  Anya provides "#{DATA_FROM_ANYA.join(', ')}", which forms the full question
  "#{SameTimeSamePlace.yield_block(DATA_FROM_ANYA, &QUESTIONS[:needs_data])}".

DONE
  end

=begin rdoc
Wrapping a lambda call within a function can provide 
default values for arguments
=end
  def SameTimeSamePlace.willow_ask(args = ['what', 'what'])
    QUESTIONS[:needs_data][args]
  end

=begin rdoc
Passing a block as an argument to a method
=end
  def SameTimeSamePlace.yield_block(*args, &block)
    # yield with any necessary args is the same as calling block.call(*args)
		yield(*args)
  end

end
