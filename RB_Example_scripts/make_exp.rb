#!/usr/bin/ruby -w
# make_exp.rb

digits = (0..9).to_a
make_exp_proc = lambda { |exp| lambda { |x| x ** exp } }
square_proc = make_exp_proc.call(2)
square_proc.call(5)
squares = digits.map { |x| square_proc[x] }
cube_proc = make_exp_proc.call(3)
cube_proc.call(3)
cubes = digits.map { |x| cube_proc[x] }
