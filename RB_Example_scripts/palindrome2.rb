#!/usr/bin/env ruby
# palindrome2.rb

=begin rdoc
Gives every <b>String</b> the ability to identify whether it is a 
palindrome. This version ignores all non-alphabetic characters, making 
it suitable for longer text items.
=end

class String

  DUAL_CASE_ALPHABET = ('a'..'z').to_a + ('A'..'Z').to_a

=begin rdoc
Contrast this with some other languages, involving iterating through 
each string index and comparing with the same index from the opposite 
end. Takes 1 optional Boolean, which indicates whether case matters. 
Assumed to be true.
=end
  def palindrome?(case_matters=true)
    letters_only(case_matters) == letters_only(case_matters).reverse
  end

  private

=begin rdoc
Takes 1 optional Boolean, which indicates whether case matters. 
Assumed to be false.
=end
  def letters_only(case_matters=false)
    just_letters = split('').find_all do |char| 
      DUAL_CASE_ALPHABET.include?(char) 
    end.join('')
    return just_letters if (case_matters)
    return just_letters.downcase
  end

end
