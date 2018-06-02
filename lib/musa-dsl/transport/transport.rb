# TODO allow several kinds of clocks: midi-input-clock, topaz-auto-generated-clock, etc

require 'musa-dsl/transport/input-midi-clock'
require 'musa-dsl/transport/dummy-clock'
require 'musa-dsl/sequencer'

require 'musa-dsl/mods/key-parameters-procedure-binder'

module Musa
	class Transport

		attr_reader :sequencer

	 	def initialize clock,
				quarter_notes_by_bar = nil,
				quarter_note_divisions = nil,
				before_begin: nil,
				after_stop: nil,
				before_each_tick: nil,
				on_position_change: nil

			quarter_notes_by_bar ||= 4
			quarter_note_divisions ||= 24

	 		@clock = clock

			@before_begin = []
			@before_begin << KeyParametersProcedureBinder.new(before_begin) if before_begin

			@before_each_tick = []
			@before_each_tick << KeyParametersProcedureBinder.new(before_each_tick) if before_each_tick

			@on_position_change = []
			@on_position_change << KeyParametersProcedureBinder.new(on_position_change) if on_position_change

			@sequencer = Sequencer.new quarter_notes_by_bar, quarter_note_divisions

			@clock.on_stop &after_stop if after_stop

			@clock.on_song_position_pointer do |midi_beat_position|

				position = Rational(midi_beat_position, 4 * quarter_notes_by_bar) + 1
				tick_before_position = position - Rational(1, quarter_notes_by_bar * quarter_note_divisions)

				puts "Transport: received message position change to #{position}"

				if @sequencer.position > tick_before_position
					puts "Transport: reseting sequencer"
					@sequencer.reset
					@before_begin.each { |block| block.call @sequencer }
				end

				puts "Transport: setting sequencer position to #{tick_before_position}"
				@sequencer.position = tick_before_position

				@sequencer.raw_at position, force_first: true do
					@on_position_change.each { |block| block.call @sequencer }
				end
			end
		end

		def before_begin &block
			@before_begin << KeyParametersProcedureBinder.new(block)
		end

		def before_each_tick &block
			@before_each_tick << KeyParametersProcedureBinder.new(block)
		end

		def after_stop &block
			@clock.on_stop &block
		end

		def on_position_change &block
			@on_position_change << KeyParametersProcedureBinder.new(block)
		end

		def start
			@before_begin.each { |block| block.call @sequencer }

			@clock.run do
				@before_each_tick.each { |block| block.call @sequencer }
				@sequencer.tick
			end
		end
	end
end
