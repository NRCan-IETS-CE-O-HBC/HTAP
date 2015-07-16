#a/usr/bin/env ruby
# radio_player1.rb

PLAY_FILE_PROC = lambda do |filename| 
  puts "I'm playing #{filename}."
end

DONT_PLAY_FILE_PROC = lambda do |filename| 
  puts "I'm not playing #{filename}. So there."
end

class RadioPlayer

  DIRS_TO_IGNORE = ['.', '..', 'CVS']
  
  PICK_FROM_DIR_PROC = lambda do |dir, callback_proc, dir_filter|

    puts "I'm inside #{dir}" if $DEBUG
    (Dir.open(dir).entries - DIRS_TO_IGNORE).sort.each do |filename|
      
      if ((filename =~ dir_filter) or not dir_filter)
        item = "#{dir}/#{filename}"
        puts "#{item} passes the filter" if $DEBUG
        
        if File.directory?(item)
          puts "#{item} is a directory" if $DEBUG
          PICK_FROM_DIR_PROC.call(
            item, callback_proc, dir_filter
          )
        else
          puts "#{item} is a file" if $DEBUG
          callback_proc.call(item)
        end
      
      end
    
    end
  
  end

  def self.walk(dir, callback_proc, dir_filter=nil)
    puts
    puts "I'm walking #{dir} using filter #{dir_filter.inspect}" if $DEBUG
    PICK_FROM_DIR_PROC.call(dir, callback_proc, dir_filter)
  end

end

dir = 'extras/soundfiles'
callback   = (ARGV[0] == 'play') ? PLAY_FILE_PROC : DONT_PLAY_FILE_PROC
dir_filter = ARGV[1] ? Regexp.new(ARGV[1]) : nil
RadioPlayer.walk(dir, callback, dir_filter)
puts
