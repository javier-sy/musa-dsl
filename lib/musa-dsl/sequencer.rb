require 'musa-dsl/tool'

require 'musa-dsl/themes' 
require 'musa-dsl/series'

module Musa
	class Sequencer
		
		include Series

		# TODO repensar modelo de métodos... basándolos en un sólo método con combinaciones de atributos (at:, after:, do:, etc...)

		attr_accessor :debug

		attr_reader :ticks_per_bar, :running_position, :score

		def initialize(quarter_notes_by_bar, quarter_note_divisions)
			
			@ticks_per_bar = Rational(quarter_notes_by_bar * quarter_note_divisions)
			
			@score = Hash.new

			reset
		end

		def reset
			@score.clear

			@context = Context.new
			@context.push_control SequencerControl.new self

			@position = @ticks_per_bar - 1
		end

		def tick
			position_to_run = (@position += 1)

			if @score[position_to_run]
				@score[position_to_run].each do |command|
					context = command[:context]
					context ||= @context

					context.instance_exec_nice command[:value_parameters], command[:key_parameters], &command[:block]
				end

				@score.delete position_to_run
			end
		end

		def on_debug_at(&block)
			@on_debug_at = block
		end

		def on_fast_forward(&block)
			@on_fast_forward = block
		end

		def position
			Rational(@position, @ticks_per_bar)
		end

		def position=(bposition)

			position = bposition * @ticks_per_bar

			raise ArgumentError, "Sequencer #{self}: cannot move back. current position: #{@position} new position: #{position}" if position < @position

			@on_fast_forward.call(true) if @on_fast_forward

			while @position < position
				tick
			end

			@on_fast_forward.call(false) if @on_fast_forward
		end

		def log(msg = nil)
			m = "..." unless msg
			m = ": #{msg}" if msg

			puts "#{self.position}#{m}"
		end

		def with(*value_args, **key_args, &block)
			@context.instance_exec *value_args, **key_args, &block 
		end

		# TODO implementar series como parámetros (bdelay sería el wait respecto al evento programado anterior?)
		def wait(bdelay, context: nil, with: nil, &block)
			at position + bdelay.rationalize, context: context, with: with, &block
		end

		# TODO añadir control de seguridad: si un bar_position no es válido hacer log
		def at(bar_position, context: nil, with: nil, debug: false, &block)

			if bar_position.is_a? Numeric
				_numeric_at bar_position, context: context, with: with, debug: debug, &block
			else
				bar_position = S(*bar_position) if bar_position.is_a? Array
				with = S(*with).repeat if with.is_a? Array

				_serie_at bar_position, context: context, with: with, debug: debug, &block
			end
		end

		def theme(theme, at:, context: nil, debug: false, **parameters)

			context ||= @context

			theme_constructor_parameters = {}

			run_method = theme.instance_method(:run)
			at_position_method = theme.instance_method(:at_position)
			
			run_parameters = run_method.parameters.collect {|p| [ p[1], nil ] }.compact.to_h
			run_parameters.delete :next_position

			parameters.each do |k, v|
				if run_parameters.include? k
					run_parameters[k] = v
				else
					theme_constructor_parameters[k] = v
				end
			end

			run_parameters[:at] = at.duplicate if run_parameters.include? :at

			theme_instance = theme.new context, **theme_constructor_parameters

			with_serie_at = H(run_parameters)
			with_serie_run = with_serie_at.slave

			self.at at.eval(with: with_serie_at) { 
						|p, **parameters| 
						if !parameters.empty?
							effective_parameters = Tool::make_hash_key_parameters at_position_method, parameters
							theme_instance.at_position p, **effective_parameters
						else
							log "Warning: parameters serie for theme #{theme} is finished. Theme finished before at: serie is finished."
							nil
						end
					}, 
				context: context,
				with: with_serie_run, 
				debug: debug do
					|**parameters|
					effective_parameters = Tool::make_hash_key_parameters run_method, parameters
					theme_instance.run **effective_parameters
			end
		end

		def play(serie, mode: :wait, parameter: nil, context: nil, **mode_args, &block)

			raise ArgumentError, "Sequencer.play: mode #{mode} not allowed. Only :wait or :at available" unless mode == :wait || mode == :at

			if parameter.is_a? Proc
				parameter_block = parameter
			else
				parameter ||= :at if mode == :at
				parameter ||= :duration if mode == :wait
				
				parameter_block = Proc.new { |element| 	element[parameter] }
			end

			context ||= @context

			element = serie.next_value

			if element
				context.instance_exec_nice element, &block 
				
				context.send mode, parameter_block.call(element), context: context, **mode_args, 
					&(Proc.new { play serie, mode: mode, parameter: parameter_block, context: context, **mode_args, &block })
			end
		end	

		def _serie_at(serie_bar_position, context: nil, with: nil, debug:, &block)

			bar_position = serie_bar_position.next_value
			next_bar_position = serie_bar_position.peek_next_value
			
			if with.respond_to? :next_value
				with_value = with.next_value 
			else
				with_value = with
			end

			if bar_position
				_numeric_at bar_position, context: context, next_bar_position: next_bar_position, with: with_value, debug: debug, &block

				_numeric_at bar_position, context: context, debug: false do
					_serie_at serie_bar_position, context: context, with: with, debug: debug, &block
				end
			else
				# serie finalizada
			end

			nil
		end

		def _numeric_at(bar_position, context: nil, next_bar_position: nil, with: nil, debug:, &block)
			position = bar_position.rationalize * @ticks_per_bar

			if position != position.round
				original_position = position
				position = position.round.rationalize
				log "Sequencer._numeric_at: warning: rounding position #{bar_position} (#{original_position}) to tick precision: #{position/@ticks_per_bar} (#{position})"
			end

			context ||= @context

			value_parameters = []
			value_parameters << with if !with.nil? && !with.is_a?(Hash)

			key_parameters = {}
			key_parameters.merge! Tool::make_hash_key_parameters block, with if with.is_a? Hash

			key_parameters[:next_position] = next_bar_position if next_bar_position && Tool::find_hash_parameter(block, :next_position)

			if position == @position
				context.instance_eval @debug_at if debug && @debug_at
				context.instance_exec_nice value_parameters, key_parameters, &block

			elsif position > @position
				@score[position] = [] if !@score[position]

				@score[position] << { block: @on_debug_at } if debug && @on_debug_at
				@score[position] << { block: block, value_parameters: value_parameters, key_parameters: key_parameters, context: context }
			else
				log "Warning: ignoring past at command for #{Rational(position, @ticks_per_bar)}"
			end

			nil
		end

		# TODO every queda substituido por un at con una Serie periódica?
		def every(binterval, context: nil, control: nil, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil, &block)
			
			sequencer = self

			context ||= @context

			binterval = binterval.rationalize
			control ||= EveryControl.new sequencer, duration: duration, till: till, condition: condition, on_stop: on_stop, after_bars: after_bars, after: after

			sequencer.at sequencer.position, context: context do

				# En at ya estaremos dentro de un Context...

				control._start ||= sequencer.position

				push_control control

				context.instance_eval &block

				pop_control

				duration_exceeded = (control._start + control.duration_value - binterval) <= position if control.duration_value
				till_exceeded = control.till_value - binterval <= position if control.till_value
				condition_failed = !instance_eval(&control.condition_block) if control.condition_block

				if !control.stopped? && !duration_exceeded && !till_exceeded && !condition_failed
					sequencer.at sequencer.position + binterval, context: context do
						sequencer.every binterval, control: control, context: context, &block
					end
				else
					control.do_on_stop.each do |do_on_stop|
						instance_eval &do_on_stop
					end

					control.do_after.each do |do_after|
						sequencer.at sequencer.position + binterval + do_after[:bars], context: context, &do_after[:block]
					end
				end
			end

			control
		end

		# TODO estaría bien que from y to pudiera tener un Hash, de modo que el movimiento se realice entre los valores de sus atributos
		# TODO tb estaría bien que pudiera ser un Array de Hash, con la misma semántica en modo polifónico

		def move(context: nil, every: nil, from: nil, to: nil, diff: nil, using_init: nil, using: nil, step: nil, duration: nil, till: nil, on_stop: nil, after_bars: nil, after: nil, &block)
			
			sequencer = self

			context ||= @context

			every ||= Rational(1, @ticks_per_bar)
			every = every.rationalize unless every.is_a?(Rational)

			array_mode = from.is_a?(Array) || to.is_a?(Array)

			from = Tool::grant_array from
			diff = Tool::grant_array diff if diff
			to = Tool::grant_array to if to

			step ||= Float::MIN
			step = Tool::grant_array step

			size = [from.size, step.size].max
			size = [size, to.size].max if to

			from.collect! {|v| v.rationalize }
			diff.collect! {|v| v.rationalize } if diff
			to.collect! {|v| v.rationalize } if to
			step.collect! {|v| v.rationalize }

			till = till.rationalize if till
			duration = duration.rationalize if duration

			from = Tool::fill_with_repeat_array from, size
			diff = Tool::fill_with_repeat_array diff, size if diff
			to = Tool::fill_with_repeat_array to, size if to
			step = Tool::fill_with_repeat_array step, size

			start_position = sequencer.position

			if diff
				if to
					size.times { |i| to[i] = to[i] + diff[i] }
				else
					size.times { |i| to[i] = from[i] + diff[i] }
				end
			end

			size.times { |i| step[i] = -step[i] if from[i] > to[i] } if to

			value = from.dup
			rstep = []

			if duration || till

				# from to duration every
				# from to till every

				eduration = till - position  - every if till
				eduration = duration  - every if duration


				steps = eduration * (1 / every) # número de pasos que habrá en el movimiento

				size.times { |i| rstep[i] = (to[i] - from[i]) / steps } if to
			else
				# TODO from to every (sin till/duration): no cubierto (=> duration = (to - from) / step) if to
				# TODO from to every (sin till/duration): no cubierto (=> using.call retorne true/false continue) if using
			end

			control = EveryControl.new sequencer, duration: duration, till: till, on_stop: on_stop, after_bars: after_bars, after: after

			sequencer.at start_position, context: context do

				adjusted_value = []
				previous_adjusted_value = []
				size.times { adjusted_value << nil; previous_adjusted_value << nil }

				if using_init && using_init.is_a?(Proc)
					parameters = Tool::make_hash_parameters using_init, every: every, from: from, step: step, steps: steps, start_position: start_position, position: sequencer.position - start_position, abs_position: sequencer.position

					if parameters.empty?
						from_candidate = instance_exec &using_init
					else
						from_candidate = instance_exec **parameters, &using_init
					end

					from = Tool::grant_array from_candidate if from_candidate
				end

				sequencer.every every, control: control, context: context do

					new_value = []

					if using && using.is_a?(Proc)
						key_parameters = Tool::make_hash_key_parameters using, every: every, from: from, step: step, steps: steps, start_position: start_position, position: sequencer.position - start_position, abs_position: sequencer.position

						adjusted_value = Tool::grant_array instance_exec_nice([], key_parameters, &using)

					elsif to
						size.times do |i|
							adjusted_value[i] = from[i] + step[i] * ((value[i] - from[i]) / step[i])
							value[i] += rstep[i]
						end
					end

					size.times do |i|
						if adjusted_value[i] != previous_adjusted_value[i]
							new_value[i] = previous_adjusted_value[i] = adjusted_value[i]
						else
							new_value[i] = nil
						end
					end

					# TODO se podría hacer que los parámetros que llegasen aquí tb se parsearan como key_parameters si es posible
					if array_mode
						instance_exec new_value, &block
					else
						new_value.compact.each { |v| instance_exec v, &block }
					end
				end
			end

			control
		end

		def to_s
			super + ": position=#{self.position}"
		end

		alias inspect to_s

		private

		class Context
			def initialize
				@_control = []
			end

			def push_control(control)
				@_control.push control
			end

			def pop_control
				@_control.pop
			end

			def control
				@_control.last
			end

			def method_missing(method_name, *args, **key_args, &block)
				if @_control.last.respond_to? method_name
					@_control.last.send_nice method_name, *args, **key_args, &block
				else
					super
				end
			end

			def respond_to_missing?(method_name, include_private)
				@_control.last.respond_to?(method_name, include_private) || super
			end
		end

		class SequencerControl
			attr_reader :sequencer

			def initialize(sequencer)
				@sequencer = sequencer
			end

			def method_missing(method_name, *args, **key_args, &block)
				if @sequencer.respond_to? method_name
					@sequencer.send_nice method_name, *args, **key_args, &block 
				else
					super
				end
			end

			def respond_to_missing?(method_name, include_private)
				@sequencer.respond_to?(method_name, include_private) || super
			end
		end

		class EveryControl < SequencerControl
			
			attr_reader :duration_value, :till_value, :condition_block, :do_on_stop, :do_after

			attr_accessor :_start

			def initialize(sequencer, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil)
				
				super sequencer

				@duration_value = duration
				@till_value = till
				@condition_block = condition

				@do_on_stop = []
				@do_after = []

				@do_on_stop << on_stop if on_stop

				if after
					self.after after_bars, after
				end

				@stop = false
			end

			def stop
				@stop = true
			end

			def stopped?
				@stop
			end

			def duration(value)
				@duration_value = value.rationalize
			end

			def till(value)
				@till_value = value.rationalize
			end

			def condition(&block)
				@condition_block = block
			end

			def on_stop(&block)
				@do_on_stop << block
			end

			def after(bars = 0, &block)
				@do_after << { bars: bars.rationalize, block: block }
			end
		end
	end
end