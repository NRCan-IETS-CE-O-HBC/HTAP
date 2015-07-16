#!/usr/bin/env ruby
# methinks_meta.rb

require 'methinks'

class Hash

  def get_child()
    new_hash = {}
    each_pair do |k,v|
      new_hash[k] = (rand(v) + (v/2))
    end
    new_hash[:display_filter] = 5
    return new_hash
  end

end # Hash

###

class Meta_Mutator

  NEW_TARGET   = 'ruby'
  MAX_ATTEMPTS = 2
  TARGET = NEW_TARGET || String::TARGET

  def initialize()
    @params_by_number_of_mutations = {}
  end

  def mutate_mutations!(
      params, 
      did_no_better_count=0
    )
    return if did_no_better_count > MAX_ATTEMPTS

    num = update_params_by_number_of_mutations!(params)
    
    return mutate_mutations!(
      @params_by_number_of_mutations[best_num],
      get_no_better_count(num, did_no_better_count)
    )

  end
 
  def report()
    @params_by_number_of_mutations.sort.each do |pair|
      num, params = pair
      puts sprintf("%0#{digits_needed}d", num) + 
        " generations with #{params.inspect}"
    end
  end

  private

  def best_num()
    @params_by_number_of_mutations.keys.sort[0] || nil
  end

  def digits_needed()
    @params_by_number_of_mutations.keys.max.to_s.size
  end

  def get_children(params, number_of_children = 10)
    (0..number_of_children).to_a.map do |i|
      params.get_child()
    end
  end

  def get_no_better_count(num, did_no_better_count)
    return 0 if (num == best_num)
    did_no_better_count + 1
  end

  def update_params_by_number_of_mutations!(params)
    children = get_children(params)
    number_of_mutations = nil
    children.each do |params|
      candidate = String.new.scramble!(TARGET)
      number_of_mutations = candidate.mutate_until_matches!(TARGET, params)
      @params_by_number_of_mutations[number_of_mutations] = params.dup
    end
    return number_of_mutations
  end

end # Meta_Mutator

###

params = {
  :generation_size => 200, 
  :mutation_rate   => 30, 
  :display_filter  => 5,
  :mutation_amp    => 7
}

mm = Meta_Mutator.new()
mm.mutate_mutations!(params)
mm.report()
