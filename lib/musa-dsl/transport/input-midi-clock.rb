require 'nibbler'

module Musa
	class InputMidiClock
		def initialize input
			@input = input
			@nibbler = Nibbler.new
		end

		def on_start &block
			@on_start = block
		end

		def on_stop &block
			@on_stop = block
		end

		def on_song_position_pointer &block
			@on_song_position_pointer = block
		end

		def run
			@run = true

			while @run
				@messages = @input.gets

				@messages.each do |message|
					m = @nibbler.parse message[:data]

					case m.name 
					when 'Start'
						@on_start.call if @on_start
					
					when 'Stop'
						@on_stop.call if @on_stop

					when 'Clock'
						yield if block_given?

					when 'Song Position Pointer'
						position = Rational(message[:data][1] & 0x7F | ((message[:data][2] & 0x7F) << 7), 16) + 1

						@on_song_position_pointer.call position if @on_song_position_pointer
					end
				end

				sleep 0.0001
				Thread.pass
			end
		end

		def terminate
			@run = false
		end
	end
end