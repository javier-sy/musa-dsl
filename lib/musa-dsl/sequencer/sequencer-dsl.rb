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

		attr_reader :sequencer, :event_handler

		def_delegators :@sequencer, :position, :log, :to_s, :inspect
		def_delegators :@event_handler, :launch, :on

		def initialize sequencer, parent = nil
			@sequencer = sequencer
			@event_handler = EventHandler.new(parent)
		end

		def with &block
			as_context_run block
		end

		def at bar_position, with: nil, debug: nil, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.at bar_position, with: with, debug: debug do |*value_args, **key_args|
				context.as_context_run block, value_args, key_args
			end

			context.event_handler
		end

		def wait bdelay, event_handler: nil, with: nil, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.wait bdelay, with: with do
				context.as_context_run block
			end

			context.event_handler
		end

		def theme theme, at:, debug: nil, **parameters
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.theme theme, context: context, at: at, debug: debug, **parameters

			context.event_handler
		end

		def play serie, mode: nil, parameter: nil, **mode_args, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.play serie, mode: mode, parameter: parameter, **mode_args do |*value_args, **key_args|
				context.as_context_run block, value_args, key_args
			end

			context.event_handler
		end

		def every binterval, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.every binterval, duration: duration, till: till, condition: condition, on_stop: on_stop, after_bars: after_bars, after: after do |*value_args, **key_args|
				context.as_context_run block, value_args, KeyParametersProcedureBinder.new(block).apply(key_args)
			end

			context.event_handler
		end

		def move every: nil, from: nil, to: nil, diff: nil, using_init: nil, using: nil, step: nil, duration: nil, till: nil, on_stop: nil, after_bars: nil, after: nil, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.move every: every, from: from, to: to, diff: diff, using_init: using_init, using: using, step: step, duration: duration, till: till, on_stop: on_stop, after_bars: after_bars, after: after do |*value_args, **key_args|
				context.as_context_run block, value_args, key_args
			end

			context.event_handler
		end
	end

	private_constant :DSLContext

	class EventHandler
		def initialize parent = nil
			@parent = parent
			@handlers = {}
		end

		def make_subhandler
			EventHandler.new self
		end

		def on event, &block
			@handlers[event] ||= []
			@handlers[event] << KeyParametersProcedureBinder.new(block)
		end

		def launch event, *value_parameters, **key_parameters
			if @handlers.has_key? event
				@handlers[event].each do |handler|
					handler.call *value_parameters, **key_parameters
				end
			end

			@parent.launch event, *value_parameters, **key_parameters if @parent
		end

		def inspect
			"EventHandler #{self.__id__} parent: #{@parent}"
		end

		alias to_s inspect
	end

	private_constant :EventHandler
end

module Musa::Theme

	def initialize context
		@context = context
	end

	def at_position p, **parameters
		p
	end

	def run
	end

	private

	def method_missing method_name, *args, **key_args, &block
		if @context.respond_to? method_name
			@context.send_nice method_name, *args, **key_args, &block
		else
			super
		end
	end

	def respond_to_missing? method_name, include_private
		@context.respond_to?(method_name, include_private) || super
	end
end	

