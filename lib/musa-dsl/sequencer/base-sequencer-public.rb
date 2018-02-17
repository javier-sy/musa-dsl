require 'musa-dsl/mods/arrayfy'
require 'musa-dsl/mods/key-parameters-procedure-binder'

require 'musa-dsl/series'

class Musa::BaseSequencer

	attr_reader :ticks_per_bar, :running_position

	def initialize quarter_notes_by_bar, quarter_note_divisions
		
		@on_debug_at = []
		@on_fast_forward = []

		@ticks_per_bar = Rational(quarter_notes_by_bar * quarter_note_divisions)
		
		@score = Hash.new

		reset
	end

	def reset
		@score.clear
		@event_handlers = [ EventHandler.new ]

		@position = @ticks_per_bar - 1
	end

	def tick
		position_to_run = (@position += 1)

		if @score[position_to_run]
			@score[position_to_run].each do |command|

				@event_handlers.push command[:parent_control]
				
				command[:block].call *command[:value_parameters], **command[:key_parameters]

				@event_handlers.pop
			end

			@score.delete position_to_run
		end
	end
	
	def size
		@score.size
	end

	def event_handler
		@event_handlers.last
	end

	def on_debug_at &block
		@on_debug_at << block
	end

	def on_fast_forward &block
		@on_fast_forward << block
	end

	def position
		Rational(@position, @ticks_per_bar)
	end

	def position= bposition

		position = bposition * @ticks_per_bar

		raise ArgumentError, "Sequencer #{self}: cannot move back. current position: #{@position} new position: #{position}" if position < @position

		if position > @position
			@on_fast_forward.each { |block| block.call(true) }

			while @position < position
				tick
			end

			@on_fast_forward.each { |block| block.call(false) }
		end
	end

	def on event, &block
		@event_handlers.last.on event, &block
	end

	def launch event, *value_parameters, **key_parameters
		@event_handlers.last.launch event, *value_parameters, **key_parameters
	end

	# TODO implementar series como parámetros (bdelay sería el wait respecto al evento programado anterior?)
	def wait bdelay, with: nil, &block

		control = EventHandler.new @event_handlers.last
		@event_handlers.push control

		_numeric_at position + bdelay.rationalize, control, with: with, &block

		@event_handlers.pop

		control
	end

	def now with: nil, &block
		control = EventHandler.new @event_handlers.last
		@event_handlers.push control

		_numeric_at position, control, with: with, &block

		@event_handlers.pop

		control
	end

	def at bar_position, with: nil, debug: nil, &block

		debug ||= false

		control = EventHandler.new @event_handlers.last
		@event_handlers.push control

		if bar_position.is_a? Numeric
			_numeric_at bar_position, control, with: with, debug: debug, &block
		else
			bar_position = Series::S(*bar_position) if bar_position.is_a? Array
			with = Series::S(*with).repeat if with.is_a? Array

			_serie_at bar_position, control, with: with, debug: debug, &block
		end

		@event_handlers.pop

		control
	end

	def theme theme, at:, debug: nil, **parameters

		debug ||= false

		control = EventHandler.new @event_handlers.last
		@event_handlers.push control

		_theme theme, control, at: at, debug: debug, **parameters

		@event_handlers.pop

		control
	end

	def play serie, mode: nil, parameter: nil, after: nil, **mode_args, &block

		mode ||= :wait

		control = PlayControl.new @event_handlers.last, after: after
		@event_handlers.push control

		_play serie, control, mode: mode, parameter: parameter, **mode_args, &block

		@event_handlers.pop

		control
	end

	def every binterval, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil, &block

		binterval = binterval.rationalize

		control = EveryControl.new @event_handlers.last, duration: duration, till: till, condition: condition, on_stop: on_stop, after_bars: after_bars, after: after
		@event_handlers.push control

		_every binterval, control, &block

		@event_handlers.pop

		control
	end

	# TODO estaría bien que from y to pudiera tener un Hash, de modo que el movimiento se realice entre los valores de sus atributos
	# TODO tb estaría bien que pudiera ser un Array de Hash, con la misma semántica en modo polifónico
	def move every: nil, from: nil, to: nil, diff: nil, using_init: nil, using: nil, step: nil, duration: nil, till: nil, on_stop: nil, after_bars: nil, after: nil, &block

		every ||= Rational(1, @ticks_per_bar)
		every = every.rationalize unless every.is_a?(Rational)

		_move every: every, from: from, to: to, diff: diff, using_init: using_init, using: using, step: step, duration: duration, till: till, on_stop: on_stop, after_bars: after_bars, after: after, &block
	end

	def log msg = nil
		_log msg
	end

	def to_s
		super + ": position=#{self.position}"
	end

	alias inspect to_s

	class EventHandler
		@@counter = 0

		def initialize parent = nil
			@id = (@@counter += 1)
			
			@parent = parent
			@handlers = {}
		end

		def on event, only_once: nil, &block
			only_once ||= false

			@handlers[event] ||= []
			@handlers[event] << { block: KeyParametersProcedureBinder.new(block), only_once: only_once }
		end

		def launch event, *value_parameters, **key_parameters
			_launch event, value_parameters, key_parameters
		end

		def _launch event, value_parameters = nil, key_parameters = nil
			processed = false

			if @handlers.has_key? event
				@handlers[event].each_index do |i|
					handler = @handlers[event][i]
					if handler
						handler[:block]._call value_parameters, key_parameters
						@handlers[event][i] = nil if handler[:only_once]
						processed = true
					end
				end
			end

			@parent._launch event, value_parameters, key_parameters if @parent && !processed
		end

		def inspect
			"EventHandler #{id}"
		end

		def id
			if @parent
				"#{@parent.id}.#{@id}"
			else
				"#{@id}"
			end
		end

		alias to_s inspect
	end

	private_constant :EventHandler
end

module Musa::BaseTheme
	def at_position p, **parameters
		p
	end

	def run
	end
end
