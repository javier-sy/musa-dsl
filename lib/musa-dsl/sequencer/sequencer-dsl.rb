require 'forwardable'

class Musa::Sequencer
	extend Forwardable

	def_delegators :@sequencer, :reset, :tick, :on_debug_at, :on_fast_forward, :position, :position=, :log, :to_s, :inspect

	def initialize quarter_notes_by_bar = nil, quarter_note_divisions = nil, sequencer: nil, &block
		@sequencer ||= sequencer
		@sequencer ||= Musa::BaseSequencer.new quarter_notes_by_bar, quarter_note_divisions if quarter_notes_by_bar && quarter_note_divisions

		raise ArgumentError, 'Missing sequencer' unless @sequencer

		@context = ProtectedSequencer.new @sequencer

		with &block if block
	end

	def with &block
		@context.as_context_run &block
	end

	def wait bdelay, with: nil, &block
		@sequencer.wait bdelay, with: with do
			@context.as_context_run &block
		end
	end

	def at bar_position, with: nil, debug: nil, &block
		@sequencer.at bar_position, with: with, debug: debug do |*value_args, **key_args|
			@context.as_context_run value_args, key_args, &block
		end
	end

	def_delegators :@sequencer, :theme

	def play serie, mode: nil, parameter: nil, **mode_args, &block
		@sequencer.play serie, mode: mode, parameter: parameter, **mode_args do |*value_args, **key_args|
			@context.as_context_run value_args, key_args, &block
		end
	end

	def every binterval, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil, &block
		@sequencer.every binterval, duration: duration, till: till, condition: condition, on_stop: on_stop, after_bars: after_bars, after: after do |*value_args, **key_args|
			@context.as_context_run value_args, key_args, &block
		end
	end

	def move every: nil, from: nil, to: nil, diff: nil, using_init: nil, using: nil, step: nil, duration: nil, till: nil, on_stop: nil, after_bars: nil, after: nil, &block
		@sequencer.move every: every, from: from, to: to, diff: diff, using_init: using_init, using: using, step: step, duration: duration, till: till, on_stop: on_stop, after_bars: after_bars, after: after do |*value_args, **key_args|
			@context.as_context_run value_args, key_args, &block
		end
	end

	class ProtectedSequencer
		extend Forwardable

		def initialize sequencer
			@sequencer = sequencer
		end

		def_delegators :@sequencer, :position, :log, :to_s, :inspect, :with, :wait, :at, :theme, :play, :every, :move
	end

	private_constant :ProtectedSequencer
end
