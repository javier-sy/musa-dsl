require 'musa-dsl/mods/arrayfy'
require 'musa-dsl/mods/key-parameters-procedure-binder'

class Musa::BaseSequencer

	private

	def _numeric_at(bar_position, control, next_bar_position: nil, with: nil, debug: nil, &block)

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

	def _serie_at(bar_position_serie, control, with: nil, debug: nil, &block)

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

	def _theme(theme, control, at:, debug: nil, **parameters)

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
			control,
			with: with_serie_run, 
			debug: debug do
				|**parameters|
				# TODO optimizar inicialización KeyParamtersProcedureBinder
				effective_parameters = KeyParametersProcedureBinder.new(run_method).apply parameters
				theme_instance.run **effective_parameters
		end

		nil
	end



	class PlayEval
		def value_eval element, decoder, nl_context
			raise NotImplementedError
		end

		def run_eval element, decoder, nl_context
			raise NotImplementedError
		end
	end

	class AtModePlayEval < PlayEval
		def run_eval element, decoder, nl_context
			value = nil

			value = { 	current_operation: :block,
						current_block: block_procedure_binder, 
						current_parameter: element, 
						continue_operation: :at, 
						continue_parameter: element[:at] } if element.is_a? Hash
			
			value ||= { current_operation: block_procedure_binder, 
						current_parameter: element, 
						continue_operation: :at, 
						continue_parameter: position }
		end
	end

	class WaitModePlayEval < PlayEval
		def run_eval element, decoder, nl_context
			value = nil
		
			if element.is_a? Hash
				value = { 	current_operation: :block,
							current_block: block_procedure_binder, 
							current_parameter: element, 
							continue_operation: :wait, 
							continue_parameter: element[:duration] } if element.key? :duration

				value = { 	current_operation: :block,
							current_block: block_procedure_binder, 
							current_parameter: element, 
							continue_operation: :on, 
							continue_parameter: element[:wait_event] } if element.key? :wait_event
			end

			value ||= { current_operation: :block,
						current_block: block_procedure_binder, 
						current_parameter: element, 
						continue_operation: :now }
		end
	end

	class NeumalangModePlayEval < PlayEval

		def value_eval element, decoder, nl_context
			value = nil
		
			case element[:kind]
			when :value
				
				value = element[:value]

			when :neuma

				value = decoder.decode element

			when :serie

				value = S(*(element[:serie].collect { |e| value_eval e }))

			when :parallel

				value = element[:parallel].collect { |e| S(*e[:serie]) }

			when :assign_to

				_value = nil

				element[:assign_to].each do |var_name|
					nl_context.instance_variable_set var_name, _value = element[:assign_value]
				end

				value = value_eval _value

			when :use_variable

				if nl_context.instance_variable_defined? element[:use_variable]
					value = value_eval nl_context.instance_variable_get(element[:use_variable])
				else
					raise NameError, "Variable #{element[:use_variable]} is not defined in #{element}"
				end

			when :command

				value = nl_context.instance_eval &element[:command]

			when :reference_command

				value = element[:reference_command]

			end

			value
		end


		def run_eval element, decoder, nl_context

			case element[:kind]
			when :value

				if element[:value].key? :duration
					{ 	current_operation: :block,
						current_parameter: element[:value],
						continue_operation: :wait, 
						continue_parameter: element[:value][:duration] }
				else
					{ 	current_operation: :block,
						current_parameter: element[:value],
						continue_operation: :now }
				end

			when :neuma

				_value = decoder.decode element

				{ 	current_operation: :block,
					current_parameter: _value,
					continue_operation: :wait, 
					continue_parameter: _value[:duration] }

			when :serie

				{ 	current_operation: :play, 
					current_parameter: S(*element[:serie]) }

			when :parallel

				{ 	current_operation: :parallel_play, 
					current_parameter: element[:parallel].collect { |e| S(*e[:serie]) } }

			when :assign_to

				element[:assign_to].each do |var_name|
					nl_context.instance_variable_set var_name, element[:assign_value]
				end

				{  	current_operation: :none, 
					continue_operation: :now }

			when :use_variable

				run_eval_block.call nl_context.instance_variable_get(element[:use_variable])

			when :event

				{ 	current_operation: :event,
					current_event: element[:event],
					current_value_parameters: element[:value_parameters].collect { |e| value_eval e },
					current_key_parameters: element[:key_parameters].collect { |k, e| [ k, value_eval(e) ] }.to_h,
					continue_operation: :now }

			when :command

				__translate nl_context.instance_eval(&element[:command])

			when :call_methods

				_value = value_eval element[:on]

				if _value.is_a? Array

					values = _value.collect do |_value|
						element[:call_methods].each do |methd|
							value_parameters = methd[:value_parameters].collect { |e| value_eval e } if methd[:value_parameters]
							key_parameters = methd[:key_parameters].collect { |k, e| [ k, value_eval(e) ] }.to_h if methd[:key_parameters]

							_value = _value._send_nice methd[:method], value_parameters, key_parameters
						end
						 _value
					end

					__translate values

				else
					element[:call_methods].each do |methd|
						value_parameters = methd[:value_parameters].collect { |e| value_eval e } if methd[:value_parameters]
						key_parameters = methd[:key_parameters].collect { |k, e| [ k, value_eval(e) ] }.to_h if methd[:key_parameters]

						_value = _value._send_nice methd[:method], value_parameters, key_parameters
					end

					__translate _value
				end
			end			
		end
	end

	def _play(serie, control, nl_context = nil, mode: nil, decoder: nil, eval_block: nil, run_eval_block: nil, block_procedure_binder: nil, **mode_args, &block)

		block_procedure_binder ||= KeyParametersProcedureBinder.new block

		if run_eval_block.nil?
			
			case mode
			when :at

				run_eval_block = proc do |element|
					value = nil

					value = { 	current_operation: :block,
								current_block: block_procedure_binder, 
								current_parameter: element, 
								continue_operation: :at, 
								continue_parameter: element[:at] } if element.is_a? Hash
					
					value ||= { current_operation: block_procedure_binder, 
								current_parameter: element, 
								continue_operation: :at, 
								continue_parameter: position }
				end

			when :wait

				run_eval_block = proc do |element|
					value = nil
				
					if element.is_a? Hash
						value = { 	current_operation: :block,
									current_block: block_procedure_binder, 
									current_parameter: element, 
									continue_operation: :wait, 
									continue_parameter: element[:duration] } if element.key? :duration

						value = { 	current_operation: :block,
									current_block: block_procedure_binder, 
									current_parameter: element, 
									continue_operation: :on, 
									continue_parameter: element[:wait_event] } if element.key? :wait_event
					end

					value ||= { current_operation: :block,
								current_block: block_procedure_binder, 
								current_parameter: element, 
								continue_operation: :now }
				end

			when :neumalang

				nl_context ||= Object.new

				eval_block = proc do |element|
					value = nil
				
					case element[:kind]
					when :value
						
						value = element[:value]

					when :neuma

						value = decoder.decode element

					when :serie

						value = S(*(element[:serie].collect { |e| eval_block.call(e) }))

					when :parallel

						value = element[:parallel].collect { |e| S(*e[:serie]) }

					when :assign_to

						_value = nil

						element[:assign_to].each do |var_name|
							nl_context.instance_variable_set var_name, _value = element[:assign_value]
						end

						value = eval_block.call _value

					when :use_variable

						if nl_context.instance_variable_defined? element[:use_variable]
							value = eval_block.call nl_context.instance_variable_get(element[:use_variable])
						else
							raise NameError, "Variable #{element[:use_variable]} is not defined in #{element}"
						end

					when :command

						value = nl_context.instance_eval &element[:command]

					when :reference_command

						value = element[:reference_command]

					end

					value
				end

				run_eval_block = proc do |element|

					case element[:kind]
					when :value

						if element[:value].key? :duration
							{ 	current_operation: :block,
								current_parameter: element[:value],
								continue_operation: :wait, 
								continue_parameter: element[:value][:duration] }
						else
							{ 	current_operation: :block,
								current_parameter: element[:value],
								continue_operation: :now }
						end

					when :neuma

						_value = decoder.decode element

						{ 	current_operation: :block,
							current_parameter: _value,
							continue_operation: :wait, 
							continue_parameter: _value[:duration] }

					when :serie

						{ 	current_operation: :play, 
							current_parameter: S(*element[:serie]) }

					when :parallel

						{ 	current_operation: :parallel_play, 
							current_parameter: element[:parallel].collect { |e| S(*e[:serie]) } }

					when :assign_to

						element[:assign_to].each do |var_name|
							nl_context.instance_variable_set var_name, element[:assign_value]
						end

						{  	current_operation: :none, 
							continue_operation: :now }

					when :use_variable

						run_eval_block.call nl_context.instance_variable_get(element[:use_variable])

					when :event

						{ 	current_operation: :event,
							current_event: element[:event],
							current_value_parameters: element[:value_parameters].collect { |e| eval_block.call(e) },
							current_key_parameters: element[:key_parameters].collect { |k, e| [ k, eval_block.call(e) ] }.to_h,
							continue_operation: :now }

					when :command

						__translate nl_context.instance_eval(&element[:command])

					when :call_methods

						_value = eval_block.call element[:on]

						if _value.is_a? Array

							values = _value.collect do |_value|
								element[:call_methods].each do |methd|
									value_parameters = methd[:value_parameters].collect { |e| eval_block.call(e) } if methd[:value_parameters]
									key_parameters = methd[:key_parameters].collect { |k, e| [ k, eval_block.call(e) ] }.to_h if methd[:key_parameters]

									_value = _value._send_nice methd[:method], value_parameters, key_parameters
								end
								 _value
							end

							__translate values

						else
							element[:call_methods].each do |methd|
								value_parameters = methd[:value_parameters].collect { |e| eval_block.call(e) } if methd[:value_parameters]
								key_parameters = methd[:key_parameters].collect { |k, e| [ k, eval_block.call(e) ] }.to_h if methd[:key_parameters]

								_value = _value._send_nice methd[:method], value_parameters, key_parameters
							end

							__translate _value
						end
					end
				end
			else
				raise ArgumentError, "Sequencer.play: mode #{mode} not allowed. Allowed modes are :wait, :at or :neumalang"
			end
		end

		element = serie.next_value

		if element

			operation = run_eval_block.call element

			case operation[:current_operation]
			
			when :none

			when :block

				block_procedure_binder.call operation[:current_parameter], control: control

			when :event

				control._launch operation[:current_event], operation[:current_value_parameters], operation[:current_key_parameters]
			
			when :play

				control2 = PlayControl.new control
				control3 = PlayControl.new control2
				control3.after { control3.launch :sync }

				_play operation[:current_parameter], control3, nl_context, eval_block: eval_block, run_eval_block: run_eval_block, block_procedure_binder: block_procedure_binder, **mode_args

				control2.on :sync do
					_play serie, control, nl_context, eval_block: eval_block, run_eval_block: run_eval_block, block_procedure_binder: block_procedure_binder, **mode_args
				end

			when :parallel_play

				control2 = PlayControl.new control

				operation[:current_parameter].each do |current_parameter|

					control3 = PlayControl.new control2
					control3.after { control3.launch :sync }

					_play current_parameter, control3, nl_context, eval_block: eval_block, run_eval_block: run_eval_block, block_procedure_binder: block_procedure_binder, **mode_args
				end

				counter = operation[:current_parameter].size

				control2.on :sync do
					counter -= 1
					_play serie, control, nl_context, eval_block: eval_block, run_eval_block: run_eval_block, block_procedure_binder: block_procedure_binder, **mode_args if counter == 0
				end
			end

			case operation[:continue_operation]
			when :now
				now do
					_play serie, control, nl_context, eval_block: eval_block, run_eval_block: run_eval_block, block_procedure_binder: block_procedure_binder, **mode_args
				end

			when :at
				at operation[:continue_parameter] do
					_play serie, control, nl_context, eval_block: eval_block, run_eval_block: run_eval_block, block_procedure_binder: block_procedure_binder, **mode_args
				end

			when :wait
				wait operation[:continue_parameter] do
					_play serie, control, nl_context, eval_block: eval_block, run_eval_block: run_eval_block, block_procedure_binder: block_procedure_binder, **mode_args
				end

			when :on
				control.on operation[:continue_parameter], only_once: true do
					_play serie, control, nl_context, eval_block: eval_block, run_eval_block: run_eval_block, block_procedure_binder: block_procedure_binder, **mode_args
				end
			end
		else
			control2 = EventHandler.new control

			control.do_after.each do |do_after|
				_numeric_at position, control2, &do_after
			end
		end

		nil
	end	

	def __translate value
		if value
			if value.is_a? Musa::Serie 
				# If value is a Serie, it's a "native" serie, not a tokens serie of kind: :neuma. 
				# For this reason it needs to be converted to something interpretable by _play (i.e., kind: :value, similar to interpreted :neuma)

				{ current_operation: :play, current_parameter: value.eval { |e| { kind: :value, value: e } } }

			elsif value.is_a? Array

				{ current_operation: :parallel_play, current_parameter: value }

			elsif value.is_a? Hash

				if value.key? :duration

					{ 	current_operation: :block,
						current_parameter: value,
						continue_operation: :wait, 
						continue_parameter: value[:duration] }
				else
					{ 	current_operation: :block,
						current_parameter: value,
						continue_operation: :now }
				end
			end
		else
			{ current_operation: :none, continue_operation: :now }
		end
	end

	private :__translate

	def _every(binterval, control, block_procedure_binder: nil, &block)
		
		block_procedure_binder ||= KeyParametersProcedureBinder.new block

		_numeric_at position, control do

			control._start ||= position

			block_procedure_binder.call( { control: control } )

			duration_exceeded = (control._start + control.duration_value - binterval) <= position if control.duration_value
			till_exceeded = control.till_value - binterval <= position if control.till_value
			condition_failed = !instance_eval(&control.condition_block) if control.condition_block

			if !control.stopped? && !duration_exceeded && !till_exceeded && !condition_failed
				_numeric_at position + binterval, control do
					_every binterval, control, block_procedure_binder: block_procedure_binder
				end
			else
				control.do_on_stop.each do |do_on_stop|
					do_on_stop.call
				end

				control.do_after.each do |do_after|
					_numeric_at position + binterval + do_after[:bars], control, &do_after[:block]
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

		_numeric_at start_position, control do

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
