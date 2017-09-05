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
		@position = @ticks_per_bar - 1
	end

	def tick
		position_to_run = (@position += 1)

		if @score[position_to_run]
			@score[position_to_run].each do |command|

				command[:block].call *command[:value_parameters], **command[:key_parameters]
			end

			@score.delete position_to_run
		end
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

		@on_fast_forward.each { |block| block.call(true) }

		while @position < position
			tick
		end

		@on_fast_forward.each { |block| block.call(false) }
	end

	# TODO implementar series como parámetros (bdelay sería el wait respecto al evento programado anterior?)
	def wait bdelay, with: nil, &block
		_numeric_at position + bdelay.rationalize, with: with, &block
	end

	def at bar_position, with: nil, debug: nil, &block

		debug ||= false

		if bar_position.is_a? Numeric
			_numeric_at bar_position, with: with, debug: debug, &block
		else
			bar_position = Series::S(*bar_position) if bar_position.is_a? Array
			with = Series::S(*with).repeat if with.is_a? Array

			_serie_at bar_position, with: with, debug: debug, &block
		end
	end

	def theme theme, at:, debug: nil, **parameters

		debug ||= false

		_theme theme, at: at, debug: debug, **parameters
	end

	def play serie, mode: nil, parameter: nil, after: nil, **mode_args, &block

		mode ||= :wait

		raise ArgumentError, "Sequencer.play: mode #{mode} not allowed. Only :wait or :at available" unless mode == :wait || mode == :at

		control = PlayControl.new after: after

		_play serie, control, mode: mode, parameter: parameter, **mode_args, &block
	end

	def every binterval, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil, &block

		binterval = binterval.rationalize

		control = EveryControl.new duration: duration, till: till, condition: condition, on_stop: on_stop, after_bars: after_bars, after: after

		_every binterval, control, &block
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
end