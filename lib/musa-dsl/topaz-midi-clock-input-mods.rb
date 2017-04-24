class Topaz::MIDIClockInput

  def after_stop(&block)
		@after_stop = block
	end

	def after_song_position_pointer(&block)
		@after_song_position_pointer = block
	end

	private

	def initialize_listener(input)
		@listener = MIDIEye::Listener.new(input)

      	@listener.listen_for(name: 'Song Position Pointer') { |message| handle_song_position_pointer_message(message) }
      	@listener.listen_for(name: 'Clock') { |message| handle_clock_message(message) }
      	@listener.listen_for(name: 'Start') { alt_handle_start_message }
      	@listener.listen_for(name: 'Stop') { alt_handle_stop_message }
      	
      	@listener
    end

	def alt_handle_start_message
		handle_start_message
  end	

  def alt_handle_stop_message
  	if running?
  		handle_stop_message
  		@after_stop.call if @after_stop
  	else
  		handle_start_message
  	end
  end

  def handle_song_position_pointer_message(message)
  	@after_song_position_pointer.call(message) if @after_song_position_pointer
 	end
end
