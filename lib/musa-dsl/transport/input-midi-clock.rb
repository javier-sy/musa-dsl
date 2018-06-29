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
					if mm
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
				end

				size = messages.size
				index = 0
				while index < size
					if index == stop_index && size >= index + 3 &&
						messages[index + 1].name == 'Song Position Pointer' &&
						messages[index + 2].name == 'Continue'

						warn "InputMidiClock: processing Stop + Song Position Pointer + Continue..."

						if !@started
							process_start
						end

						process_message messages[index + 1] do
							yield if block_given?
						end

						index += 2

						warn "InputMidiClock: processing Stop + Song Position Pointer + Continue... done"

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
				warn "InputMidiClock: processing Stop..."

				@on_stop.each { |block| block.call }
				@started = false

				warn "InputMidiClock: processing Stop... done"

			when 'Continue'
				warn "InputMidiClock: processing Continue..."
				warn "InputMidiClock: processing Continue... done"

			when 'Clock'
				yield if block_given? && @started

			when 'Song Position Pointer'
				midi_beat_position =
					m.data[0] & 0x7F | ((m.data[1] & 0x7F) << 7)

				warn "InputMidiClock: processing Song Position Pointer midi_beat_position #{midi_beat_position}..."
				@on_song_position_pointer.each { |block| block.call midi_beat_position }
				warn "InputMidiClock: processing Song Position Pointer midi_beat_position #{midi_beat_position}... done"
			end
		end

		def process_start
			warn "InputMidiClock: processing Start..."

			@on_start.each { |block| block.call }
			@started = true

			warn "InputMidiClock: processing Start... done"
		end
	end
end
