require 'unimidi'

require 'musa-dsl/transport/input-midi-clock'
require 'musa-dsl/sequencer'

module Musa
	class Transport

		attr_reader :sequencer
		attr_accessor :before_begin, :after_stop

	 	def initialize(input, before_begin: nil, after_stop: nil, &block)
			@input = input

			@before_begin = before_begin
			@after_stop = after_stop

			@block = block

			@sequencer = Sequencer.new 4, 24
			
			@clock = InputMidiClock.new @input

			@clock.on_stop &after_stop

			@clock.on_song_position_pointer do |position|

				tick_before_position = position - Rational(1, 96) 

				puts "Transport: received message position change to #{position}"

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
			
			@clock.run do 
				@sequencer.tick
			end
		end
	end
end