require 'musa-dsl/transport/clock'
require 'nibbler'

module Musa
	class InputMidiClock < Clock
		def initialize input
			super()

			@input = input
			@nibbler = Nibbler.new
		end

		def run
			@run = true

			while @run
				raw_messages = @input.gets

				messages = []
				stop_index = nil

				raw_messages.each do |message|
					mm = @nibbler.parse message[:data]
					if mm.is_a? Array
						mm.each do |m|
							stop_index = messages.size if m.name == 'Stop' && !stop_index
							messages << m
						end
					else
						stop_index = messages.size if mm.name == 'Stop' && !stop_index
						messages << mm
					end
				end

				size = messages.size
				index = 0
				while index < size
					if index == stop_index && size >= index + 3 &&
						messages[index + 1].name == 'Song Position Pointer' &&
						messages[index + 2].name == 'Continue'

						puts "InputMidiClock: processing Stop + Song Position Pointer + Continue"

						if !@started
							process_start
						end

						process_message messages[index + 1] do
							yield if block_given?
						end

						index += 2

					else
						process_message messages[index] do
							yield if block_given?
						end
					end

					index += 1
				end

				sleep 0.0001
				Thread.pass
			end
		end

		def terminate
			@run = false
		end

		private

		def process_message m
			case m.name
			when 'Start'
				process_start

			when 'Stop'
				puts "InputMidiClock: processing Stop"

				@on_stop.each { |block| block.call }
				@started = false

			when 'Continue'
				puts "InputMidiClock: processing Continue"

			when 'Clock'
				yield if block_given? && @started

			when 'Song Position Pointer'
				midi_beat_position =
					m.data[0] & 0x7F | ((m.data[1] & 0x7F) << 7)

				puts "InputMidiClock: processing Song Position Pointer midi_beat_position #{midi_beat_position}"

				@on_song_position_pointer.each { |block| block.call midi_beat_position }
			end
		end

		def process_start
			puts "InputMidiClock: processing Start"

			@on_start.each { |block| block.call }
			@started = true
		end
	end
end
