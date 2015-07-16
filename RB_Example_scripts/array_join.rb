#!/usr/bin/env ruby
# array_join.rb

class Array

  def my_join(separator1=', ', separator2=' and ')
    modified_join(separator1, separator2)
  end

  protected

  def modified_join(separator1, separator2)
    dup.modified_join!(separator1, separator2)
  end
  
  def modified_join!(separator1, separator2)
    last_one = pop()
    join(separator1) + separator2 + last_one.to_s
  end
  
end
