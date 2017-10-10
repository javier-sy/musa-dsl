require 'forwardable'

class Musa::Sequencer

	extend Forwardable

	def_delegators :@sequencer, :reset, :tick, :on_debug_at, :on_fast_forward, :ticks_per_bar

	def_delegators :@context, :position, :position=, :log, :to_s, :inspect
	def_delegators :@context, :with, :at, :wait, :theme, :play, :every, :move

	def initialize quarter_notes_by_bar = nil, quarter_note_divisions = nil, sequencer: nil, &block
		@sequencer ||= Musa::BaseSequencer.new quarter_notes_by_bar, quarter_note_divisions if quarter_notes_by_bar && quarter_note_divisions
		@context = DSLContext.new @sequencer

		with &block if block
	end

	class DSLContext
		extend Forwardable

		attr_reader :sequencer, :control

		def_delegators :@sequencer, :position, :log, :to_s, :inspect
		def_delegators :@control, :launch, :on

		def initialize sequencer, parent = nil
			@sequencer = sequencer
			@control = Musa::BaseSequencer::EventHandler.new(parent)
		end

		def with &block
			as_context_run block
		end

		def make_subcontext control = nil
			DSLContext.new @sequencer, control || @control
 		end

		private :make_subcontext

		def at bar_position, control: nil, with: nil, debug: nil, &block
			context = make_subcontext control

			context.sequencer.at bar_position, control: context.control, with: with, debug: debug do |*value_args, **key_args|
				context.as_context_run block, value_args, key_args
			end
		end


		def wait bdelay, with: nil, &block
			context = make_subcontext

			context.sequencer.wait bdelay, with: with do
				context.as_context_run block
			end
		end

		def_delegators :@context, :theme # TODO como context

		def play serie, mode: nil, parameter: nil, **mode_args, &block
			context = make_subcontext

			context.sequencer.play serie, mode: mode, parameter: parameter, **mode_args do |*value_args, **key_args|
				context.as_context_run block, value_args, key_args
			end
		end

		def every binterval, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil, &block
			context = make_subcontext

			context.sequencer.every binterval, duration: duration, till: till, condition: condition, on_stop: on_stop, after_bars: after_bars, after: after do |*value_args, **key_args|
				context.as_context_run block, value_args, KeyParametersProcedureBinder.new(block).apply(key_args)
			end
		end

		def move every: nil, from: nil, to: nil, diff: nil, using_init: nil, using: nil, step: nil, duration: nil, till: nil, on_stop: nil, after_bars: nil, after: nil, &block
			context = make_subcontext

			context.sequencer.move every: every, from: from, to: to, diff: diff, using_init: using_init, using: using, step: step, duration: duration, till: till, on_stop: on_stop, after_bars: after_bars, after: after do |*value_args, **key_args|
				context.as_context_run block, value_args, key_args
			end
		end

	end

	private_constant :DSLContext
end
