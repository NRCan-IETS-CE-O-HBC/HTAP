#a/usr/bin/env ruby
# radio_player2.rb

LOG_FILE = '/tmp/radio_player2.log'

PLAYERS = {
  '.mp3' => 'mpg321',
  '.ogg' => 'ogg123',
  ''     => 'ls'
}

# these are variables, local to Kernel. 
# They work just as well as constants.
play_file_proc = lambda do |filename, time| 
  ext = File.extname(filename)
  system("#{PLAYERS[ext]} #{filename}") if PLAYERS[ext]
  File.open(LOG_FILE, 'a') do |log| 
    log.puts([time, filename].join("\t") + "\n")
  end
end

dont_play_file_proc = lambda do |filename, time| 
  puts "I'm not playing #{filename}. So there."
end

class RadioPlayer

  DIRS_TO_IGNORE = ['.', '..', 'CVS']
  
  PICK_FROM_DIR_PROC = lambda do |dir, callback_proc, dir_filter|
    
    (Dir.open(dir).entries - DIRS_TO_IGNORE).sort.each do |filename|
      
      if ((filename =~ dir_filter) or not dir_filter)
        item = "#{dir}/#{filename}"
        
        if File.directory?(item)
          PICK_FROM_DIR_PROC.call(
            item, callback_proc, dir_filter
          )
        else
          callback_proc.call(item, Time.now)
        end
      
      end
    
    end
  
  end

  def self.walk(dir, callback_proc, dir_filter=nil)
    puts
    PICK_FROM_DIR_PROC.call(dir, callback_proc, dir_filter)
  end

end

dir = 'extras/soundfiles'
callback   = (ARGV[0] == 'play') ? play_file_proc : dont_play_file_proc
dir_filter = ARGV[1] ? Regexp.new(ARGV[1]) : nil
RadioPlayer.walk(dir, callback, dir_filter)
puts

