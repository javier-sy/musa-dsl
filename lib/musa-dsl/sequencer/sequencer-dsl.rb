require 'forwardable'

class Musa::Sequencer

	extend Forwardable

	def_delegators :@sequencer, :reset, :tick, :on_debug_at, :on_fast_forward, :ticks_per_bar, :position=

	def_delegators :@context, :position, :log, :to_s, :inspect
	def_delegators :@context, :with, :at, :wait, :theme, :play, :every, :move
	def_delegators :@context, :launch, :on

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

		def with *value_parameters, **key_parameters, &block
			as_context_run block, value_parameters, key_parameters
		end

		def now *value_parameters, **key_parameters, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.now *value_parameters, **key_parameters do |*value_args, **key_args|
				context.as_context_run block, value_args, key_args
			end

			context.event_handler
		end

		def at *value_parameters, **key_parameters, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.at *value_parameters, **key_parameters do |*value_args, **key_args|
				context.as_context_run block, value_args, key_args
			end

			context.event_handler
		end

		def wait *value_parameters, **key_parameters, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.wait *value_parameters, **key_parameters do
				context.as_context_run block
			end

			context.event_handler
		end

		def theme *value_parameters, **key_parameters
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.theme *value_parameters, context: context, **key_parameters

			context.event_handler
		end

		def play *value_parameters, **key_parameters, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.play *value_parameters, **key_parameters do |*value_args, **key_args|
				context.as_context_run block, value_args, key_args
			end

			context.event_handler
		end

		def every *value_parameters, **key_parameters, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.every *value_parameters, **key_parameters do |*value_args, **key_args|
				context.as_context_run block, value_args, KeyParametersProcedureBinder.new(block).apply(key_args)
			end

			context.event_handler
		end

		def move *value_parameters, **key_parameters, &block
			context = DSLContext.new @sequencer, @event_handler

			context.sequencer.move *value_parameters, **key_parameters do |*value_args, **key_args|
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

