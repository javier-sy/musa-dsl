require 'musa-dsl/mods/arrayfy'
require 'musa-dsl/mods/key-parameters-procedure-binder'

class Musa::BaseSequencer

	private

	def _numeric_at(bar_position, control = nil, next_bar_position: nil, with: nil, debug: nil, &block)

		raise ArgumentError, 'Block is mandatory' if !block

		position = bar_position.rationalize * @ticks_per_bar

		if position != position.round
			original_position = position
			position = position.round.rationalize
			# FIXME sublime text syntax highlight bug
			#_log "Sequencer.numeric_at: warning: rounding position #{bar_position} (#{original_position}) to tick precision: #{position / @ticks_per_bar} (#{position})"
		end

		value_parameters = []
		value_parameters << with if !with.nil? && !with.is_a?(Hash)

		block_key_parameters_binder = KeyParametersProcedureBinder.new block

		key_parameters = {}
		key_parameters.merge! block_key_parameters_binder.apply with if with.is_a? Hash

		key_parameters[:next_position] = next_bar_position if next_bar_position && block_key_parameters_binder.has_key?(:next_position)
		key_parameters[:control] = control if block_key_parameters_binder.has_key?(:control)

		if position == @position
			@debug_at.call if debug && @debug_at
			block.call *value_parameters, **key_parameters

		elsif position > @position
			@score[position] = [] if !@score[position]

			@score[position] << { parent_control: control, block: @on_debug_at } if debug && @on_debug_at
			@score[position] << { parent_control: control, block: block, value_parameters: value_parameters, key_parameters: key_parameters }
		else
			_log "Sequencer.numeric_at: warning: ignoring past at command for #{Rational(position, @ticks_per_bar)}"
		end

		nil
	end

	def _serie_at(bar_position_serie, control = nil, with: nil, debug: nil, &block)

		bar_position = bar_position_serie.next_value
		next_bar_position = bar_position_serie.peek_next_value
		
		if with.respond_to? :next_value
			with_value = with.next_value 
		else
			with_value = with
		end

		if bar_position
			_numeric_at bar_position, control, next_bar_position: next_bar_position, with: with_value, debug: debug, &block

			_numeric_at bar_position, debug: false do
				_serie_at bar_position_serie, control, with: with, debug: debug, &block
			end
		else
			# serie finalizada
		end

		nil
	end

	def _theme(theme, at:, debug: nil, **parameters)

		theme_constructor_parameters = {}

		run_method = theme.instance_method(:run)
		at_position_method = theme.instance_method(:at_position)
		at_position_method_parameter_binder = KeyParametersProcedureBinder.new at_position_method
		
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

		theme_instance = theme.new **theme_constructor_parameters

		with_serie_at = H(run_parameters)
		with_serie_run = with_serie_at.slave

		_serie_at at.eval(with: with_serie_at) { 
					|p, **parameters| 
					if !parameters.empty?
						effective_parameters = at_position_method_parameter_binder.apply parameters
						theme_instance.at_position p, **effective_parameters
					else
						_log "Warning: parameters serie for theme #{theme} is finished. Theme finished before at: serie is finished."
						nil
					end
				}, 
			with: with_serie_run, 
			debug: debug do
				|**parameters|
				# TODO optimizar inicialización KeyParamtersProcedureBinder
				effective_parameters = KeyParametersProcedureBinder.new(run_method).apply parameters
				theme_instance.run **effective_parameters
		end

		nil
	end

	# TODO si la serie es de tipo hash (los elementos son un hash), se podría hacer que el block se llamara bindeándole los parámetros por nombre simbólico

	def _play(serie, control, mode:, parameter: nil, **mode_args, &block)

		if parameter.is_a? Proc
			parameter_block = parameter

		elsif mode == :at
			parameter_block = Proc.new do |element|
				value = nil

				value = { operation_name: :at, parameter: element[:at] } if element.is_a? Hash
				value ||= { operation_name: :at, parameter: position }
			end

		elsif mode == :wait
			parameter_block = Proc.new do |element|
				value = nil
			
				if element.is_a? Hash
					value = { operation_name: :wait, parameter: element[:duration] } if element.key? :duration
					value = { operation_name: :on, parameter: element[:until_event] } if element.key? :until_event
				end

				value ||= { operation_name: :wait, parameter: 0 }
			end
		else
			raise ArgumentError, "Sequencer.play: mode #{mode} not allowed. Only :wait or :at available"
		end

		element = serie.next_value

		if element
			# TODO optimizar inicialización KeyParamtersProcedureBinder
			block.call element, **(KeyParametersProcedureBinder.new(block).apply( { control: control } ))
			
			operation = parameter_block.call(element)

			case operation[:operation_name]
			when :at, :wait
				self.send operation[:operation_name], operation[:parameter], **mode_args, 
					&(proc { _play serie, control, mode: mode, parameter: parameter_block, **mode_args, &block })
			when :on
				self.send :on, operation[:parameter], 
					&(proc { _play serie, control, mode: mode, parameter: parameter_block, **mode_args, &block })
			end
		else
			control.do_after.each do |do_after|
				control2 = EventHandler.new @event_handlers.last
				@event_handlers.push control2

				_numeric_at position, control2, &do_after

				@event_handlers.pop
			end
		end

		nil
	end	

	# TODO every queda substituido por un at con una Serie periódica?
	def _every(binterval, control, &block)
		
		_numeric_at position do

			control._start ||= position

			# TODO optimizar inicialización KeyParamtersProcedureBinder
			KeyParametersProcedureBinder.new(block).call( { control: control } )

			duration_exceeded = (control._start + control.duration_value - binterval) <= position if control.duration_value
			till_exceeded = control.till_value - binterval <= position if control.till_value
			condition_failed = !instance_eval(&control.condition_block) if control.condition_block

			if !control.stopped? && !duration_exceeded && !till_exceeded && !condition_failed
				_numeric_at position + binterval do
					_every binterval, control, &block
				end
			else
				control.do_on_stop.each do |do_on_stop|
					do_on_stop.call
				end

				control.do_after.each do |do_after|
					_numeric_at position + binterval + do_after[:bars], &do_after[:block]
				end
			end
		end

		nil
	end

	def _move(every:, from: nil, to: nil, diff: nil, using_init: nil, using: nil, step: nil, duration: nil, till: nil, on_stop: nil, after_bars: nil, after: nil, &block)
		
		array_mode = from.is_a?(Array) || to.is_a?(Array)

		from = from.arrayfy
		diff = diff.arrayfy if diff
		to = to.arrayfy if to

		step ||= Float::MIN
		step = step.arrayfy

		size = [from.size, step.size].max
		size = [size, to.size].max if to

		from.collect! {|v| v.rationalize }
		diff.collect! {|v| v.rationalize } if diff
		to.collect! {|v| v.rationalize } if to
		step.collect! {|v| v.rationalize }

		till = till.rationalize if till
		duration = duration.rationalize if duration

		from = from.repeat_to_size size
		diff = diff.repeat_to_size size if diff
		to = to.repeat_to_size size if to
		step = step.repeat_to_size size

		start_position = position

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

		control = EveryControl.new @event_handlers.last, duration: duration, till: till, on_stop: on_stop, after_bars: after_bars, after: after
		@event_handlers.push control

		_numeric_at start_position do

			adjusted_value = []
			previous_adjusted_value = []
			size.times { adjusted_value << nil; previous_adjusted_value << nil }

			if using_init && using_init.is_a?(Proc)
				# TODO optimizar inicialización de KeyParametersProcedureBinder
				parameters = KeyParametersProcedureBinder.new(using_init).apply every: every, from: from, step: step, steps: steps, start_position: start_position, position: position - start_position, abs_position: position

				if parameters.empty?
					from_candidate = instance_exec &using_init
				else
					from_candidate = instance_exec **parameters, &using_init
				end

				from = from_candidate.arrayfy if from_candidate
			end

			_every every, control do

				new_value = []

				if using && using.is_a?(Proc)
					# TODO optimizar inicialización de KeyParametersProcedureBinder
					key_parameters = KeyParametersProcedureBinder.new(using).apply every: every, from: from, step: step, steps: steps, start_position: start_position, position: position - start_position, abs_position: position

					adjusted_value = using.call(**key_parameters).arrayfy

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

				parameters = KeyParametersProcedureBinder.new(block).apply( { control: MoveControl.new(control) } )

				if array_mode
					block.call new_value, **parameters
				else
					new_value.compact.each { |v| block.call v, **parameters }
				end
			end
		end

		@event_handlers.pop

		control
	end

	def _log msg = nil
		m = "..." unless msg
		m = ": #{msg}" if msg

		puts "#{self.position}#{m}"
	end

	class PlayControl < EventHandler

		attr_reader :do_after

		def initialize parent, after: nil

			super parent

			@do_after = []

			if after
				self.after &after
			end
		end

		def after bars = nil, &block
			@do_after << block
		end
	end

	private_constant :PlayControl

	class EveryControl < EventHandler
		
		attr_reader :duration_value, :till_value, :condition_block, :do_on_stop, :do_after

		attr_accessor :_start

		def initialize parent, duration: nil, till: nil, condition: nil, on_stop: nil, after_bars: nil, after: nil

			super parent

			@duration_value = duration
			@till_value = till
			@condition_block = condition

			@do_on_stop = []
			@do_after = []

			@do_on_stop << on_stop if on_stop

			if after
				self.after after_bars, &after
			end

			@stop = false
		end

		def stop
			@stop = true
		end

		def stopped?
			@stop
		end

		def duration value
			@duration_value = value.rationalize
		end

		def till value
			@till_value = value.rationalize
		end

		def condition &block
			@condition_block = block
		end

		def on_stop &block
			@do_on_stop << block
		end

		def after bars = nil, &block
			bars ||= 0
			@do_after << { bars: bars.rationalize, block: block }
		end
	end

	private_constant :EveryControl

	class MoveControl
	
		extend Forwardable

		def initialize every_control
			@every_control = every_control
		end

		def_delegators :@every_control, :on_stop, :after, :on, :launch
	end

	private_constant :MoveControl
end
