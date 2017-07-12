require 'topaz'
require 'unimidi'
require 'midi-message'

require_relative 'topaz-midi-clock-input-mods'

module Musa
	class Transport

		attr_reader :clock, :sequencer
		attr_accessor :before_begin, :after_stop

	 	def initialize(input, quarter_notes_by_bar, quarter_note_divisions, before_begin: nil, after_stop: nil, &block)
			@input = input

			@quarter_notes_by_bar = quarter_notes_by_bar
			@quarter_note_divisions = quarter_note_divisions

			@before_begin = before_begin
			@after_stop = after_stop

			@block = block

			@sequencer = Sequencer.new @quarter_notes_by_bar, @quarter_note_divisions
			@clock = Topaz::Clock.new(@input, midi_transport: true, interval: @quarter_note_divisions * 4) { @sequencer.tick }

			@clock.source.after_stop &after_stop

			@clock.source.after_song_position_pointer do |message|

				data = message[:message].data

				position = Rational(data[0] & 0x7F | ((data[1] & 0x7F) << 7), 16) + 1

				tick_before_position = position - Rational(1, @quarter_note_divisions * @quarter_notes_by_bar) 

				puts "Transport: received message position change to #{position} (data: #{data})"

				if @sequencer.position > tick_before_position
					puts "Transport: reseting sequencer"
					@sequencer.reset
					@before_begin.call if @before_begin
				end

				puts "Transport: setting sequencer position to #{tick_before_position}"
				@sequencer.position = tick_before_position
			end 
		end

		def start
			@before_begin.call if @before_begin
			@clock.start
		end
	end
end