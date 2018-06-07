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
				on_start: nil,
				after_stop: nil,
				before_each_tick: nil,
				on_position_change: nil

			quarter_notes_by_bar ||= 4
			quarter_note_divisions ||= 24

	 		@clock = clock

			@before_begin = []
			@before_begin << KeyParametersProcedureBinder.new(before_begin) if before_begin

			@on_start = []
			@on_start << KeyParametersProcedureBinder.new(on_start) if on_start

			@before_each_tick = []
			@before_each_tick << KeyParametersProcedureBinder.new(before_each_tick) if before_each_tick

			@on_position_change = []
			@on_position_change << KeyParametersProcedureBinder.new(on_position_change) if on_position_change

			@after_stop = []
			@after_stop << KeyParametersProcedureBinder.new(after_stop) if after_stop

			@sequencer = Sequencer.new quarter_notes_by_bar, quarter_note_divisions

			@clock.on_start do
				do_on_start
			end

			@clock.on_stop do
				do_stop
			end

			@clock.on_song_position_pointer do |midi_beat_position|

				position = Rational(midi_beat_position, 4 * quarter_notes_by_bar) + 1
				tick_before_position = position - Rational(1, quarter_notes_by_bar * quarter_note_divisions)

				puts "Transport: received message position change to #{position}"

				start_again_later = false
				
				if @sequencer.position > tick_before_position
					do_stop
					start_again_later = true
				end

				puts "Transport: setting sequencer position #{tick_before_position}"
				@sequencer.position = tick_before_position

				@sequencer.raw_at position, force_first: true do
					@on_position_change.each { |block| block.call @sequencer }
				end

				do_on_start if start_again_later
			end
		end

		def before_begin &block
			@before_begin << KeyParametersProcedureBinder.new(block)
		end

		def on_start &block
			@on_start << KeyParametersProcedureBinder.new(block)
		end

		def before_each_tick &block
			@before_each_tick << KeyParametersProcedureBinder.new(block)
		end

		def after_stop &block
			@after_stop << KeyParametersProcedureBinder.new(block)
		end

		def on_position_change &block
			@on_position_change << KeyParametersProcedureBinder.new(block)
		end

		def start
			do_before_begin

			@clock.run do
				@before_each_tick.each { |block| block.call @sequencer }
				@sequencer.tick
			end
		end

		private

		def do_before_begin
			puts "Transport: doing before_begin initialization..."
			@before_begin.each { |block| block.call @sequencer }
			puts "Transport: doing before_begin initialization... done"
		end

		def do_on_start
			puts "Transport: starting..."
			@on_start.each { |block| block.call @sequencer }
			puts "Transport: starting... done"
		end

		def do_stop
			puts "Transport: stoping..."
			@after_stop.each { |block| block.call @sequencer }
			puts "Transport: stoping... done"

			puts "Transport: resetting sequencer..."
			@sequencer.reset
			puts "Transport: resetting sequencer... done"

			do_before_begin
		end
	end
end
