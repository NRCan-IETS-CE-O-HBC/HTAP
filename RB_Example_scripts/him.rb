#!/usr/bin/env ruby -w
# him.rb

class Him

  EPISODE_NAME = 'Him'
  BASE         = 'love spell'
  
  ANTIDOTE_FOR = lambda { |input| "anti-(#{input}) spell" }

  def Him.describe()
    return <<DONE_WITH_HEREDOC

In #{EPISODE_NAME},
  Willow refers to an "#{ANTIDOTE_FOR[BASE]}".
  Anya mentions an "#{ANTIDOTE_FOR[ANTIDOTE_FOR[BASE]]}".
  Xander mentioning an "#{ANTIDOTE_FOR[ANTIDOTE_FOR[ANTIDOTE_FOR[BASE]]]}" might have been too much.
    
DONE_WITH_HEREDOC
  end

end
