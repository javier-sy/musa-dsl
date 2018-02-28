class Musa::BaseSequencer

	class PlayEval
		def self.create mode, block_procedure_binder, decoder, nl_context
			case mode
			when :at
				AtModePlayEval.new block_procedure_binder
			when :wait
				WaitModePlayEval.new block_procedure_binder
			when :neumalang
				NeumalangModePlayEval.new block_procedure_binder, decoder, nl_context
			else
				raise ArgumentError, "Mode #{mode} not allowed"
			end
		end

		attr_reader :block_procedure_binder
		
		def subcontext
			self
		end

		def eval_element element
			raise NotImplementedError
		end

		def run_operation element
			raise NotImplementedError
		end
	end

	private_constant :PlayEval

	class AtModePlayEval < PlayEval

		def initialize block_procedure_binder
			@block_procedure_binder = block_procedure_binder
		end

		def run_operation element
			value = nil

			value = { 	current_operation: :block,
						current_block: @block_procedure_binder, 
						current_parameter: element, 
						continue_operation: :at, 
						continue_parameter: element[:at] } if element.is_a? Hash
			
			value ||= { current_operation: @block_procedure_binder, 
						current_parameter: element, 
						continue_operation: :at, 
						continue_parameter: position }
		end
	end

	private_constant :AtModePlayEval

	class WaitModePlayEval < PlayEval

		def initialize block_procedure_binder
			@block_procedure_binder = block_procedure_binder
		end

		def run_operation element
			value = nil
		
			if element.is_a? Hash
				value = { 	current_operation: :block,
							current_block: @block_procedure_binder, 
							current_parameter: element, 
							continue_operation: :wait, 
							continue_parameter: element[:duration] } if element.key? :duration

				value = { 	current_operation: :block,
							current_block: @block_procedure_binder, 
							current_parameter: element, 
							continue_operation: :on, 
							continue_parameter: element[:wait_event] } if element.key? :wait_event
			end

			value ||= { current_operation: :block,
						current_block: @block_procedure_binder, 
						current_parameter: element, 
						continue_operation: :now }
		end
	end

	private_constant :WaitModePlayEval

	class NeumalangModePlayEval < PlayEval

		module Parallel
		end

		@@id = 0

		attr_reader :nl_context

		def initialize block_procedure_binder, decoder, nl_context, parent: nil
			@id = @@id += 1
			@parent = parent

			@block_procedure_binder = block_procedure_binder
			@decoder = decoder
			@nl_context = nl_context
			@nl_context ||= Object.new
		end

		def subcontext
			NeumalangModePlayEval.new @block_procedure_binder, @decoder.subcontext, @nl_context, parent: self
		end

		def eval_element element, decode_neumas: nil
			decode_neumas ||= false
			
			case element[:kind]
			when :serie 		then eval_serie element[:serie]
			when :parallel 		then eval_parallel element[:parallel]
			when :assign_to 	then eval_assign_to element[:assign_to], element[:assign_value]
			when :use_variable 	then eval_use_variable element[:use_variable]
			when :command 		then eval_command element[:command], element[:value_parameters], element[:key_parameters]
			when :value 		then eval_value element[:value]
			when :neuma 		then eval_neuma element[:neuma], decode_neumas
			when :call_methods 	then eval_call_methods element[:on], element[:call_methods]
			when :eval 			then eval_eval element[:eval], element[:level]
			when :reference 	then eval_reference element[:reference], element[:level]
			else
				raise ArgumentError, "Don't know how to process #{element}"
			end
		end

		def eval_value value
			value
		end

		def eval_neuma neuma, decode = nil
			if decode
				@decoder.decode neuma
			else
				neuma
			end
		end

		def eval_serie serie
			serie.tap { |s| s.restart }
		end

		def eval_parallel series
			series.collect { |e| eval_serie e[:serie] }.extend Parallel
		end

		def eval_assign_to variable_names, value, eval_value = true
			_value = nil

			variable_names.each do |var_name|
				@nl_context.instance_variable_set var_name, _value = value
			end

			eval_element _value
		end

		def eval_use_variable variable_name
			if @nl_context.instance_variable_defined? variable_name
				eval_element @nl_context.instance_variable_get(variable_name)
			else
				raise NameError, "Variable #{element[:use_variable]} is not defined in #{element}"
			end
		end

		def eval_command block, value_parameters, key_parameters
			_value_parameters = value_parameters.collect { |e| subcontext.eval_element(e) } if value_parameters
			_key_parameters = key_parameters.collect { |k, e| [ k, subcontext.eval_element(e) ] }.to_h if key_parameters

			@nl_context.as_context_run block, _value_parameters, _key_parameters
		end

		def eval_call_methods on, call_methods

			play_eval = subcontext

			value = play_eval.eval_element on

			if value.is_a? Array # Array means the origin is a parallel

				value.collect do |_value|
					call_methods.each do |methd|
						value_parameters = methd[:value_parameters].collect { |e| play_eval.subcontext.eval_element(e) } if methd[:value_parameters]
						key_parameters = methd[:key_parameters].collect { |k, e| [ k, play_eval.subcontext.eval_element(e) ] }.to_h if methd[:key_parameters]

						_value = _value._send_nice methd[:method], value_parameters, key_parameters
					end

					_value
				end
			else
				call_methods.each do |methd|
					value_parameters = methd[:value_parameters].collect { |e| play_eval.subcontext.eval_element(e) } if methd[:value_parameters]
					key_parameters = methd[:key_parameters].collect { |k, e| [ k, play_eval.subcontext.eval_element(e) ] }.to_h if methd[:key_parameters]

					value = value._send_nice methd[:method], value_parameters, key_parameters
				end

				value
			end
		end

		def eval_eval element, level
			raise ArgumentError, "Don't know how to process level #{level} for element #{element}" if level != 1 && level != 2

			if element.is_a?(Hash) && element.key?(:kind)
				if element[:kind] == :reference
					level -= element[:level]

					if level < 0
						eval_reference element[:reference], -level
					elsif level > 0
						eval_eval element[:reference], level
					else
						element[:reference]
					end
				else
					if level == 2

						_element = eval_element element, decode_neumas: true

						case _element
						when Musa::Serie
							_element.eval { |e| eval_element e, decode_neumas: true }

						when Parallel
							_element.collect { |s| s.eval { |e| eval_element e, decode_neumas: true } }

						else
							_element
						end
					else
						_element = eval_element element

						case _element
						when Musa::Serie
							_element.eval { |e| eval_element e }

						when Parallel
							_element.collect { |s| s.eval { |e| eval_element e } }.extend Parallel

						else
							_element
						end
					end
				end
			else
				raise ArgumentError, "Don't know how to process element #{element}"
			end
		end

		def eval_reference element, level
			if element.is_a?(Hash)
				case element[:kind]
				when :eval
					level -= element[:level]

					if level < 0
						eval_eval element[:eval], -level
					elsif level > 0
						eval_reference element[:eval], level
					else
						element[:eval]
					end
				when :command
					if level == 1
						element[:command]
					else
						raise ArgumentError, "Don't know how to process level #{level} for kind: :command"
					end
				else
					eval_reference eval_element(element), level
				end 
			else
				if level == 2

					if element.is_a? Musa::Serie
						{ kind: :serie, serie: element.eval { |e| { kind: :neuma, neuma: e.to_neuma(hash: true) } } }
					else
						{ kind: :neuma, neuma: element.to_neuma(hash: true) }
					end

				elsif level == 1

					if element.is_a? Musa::Serie
						# Aquí habría que retornar kind: :neuma o :value según si el element es un neuma o cualquier otra cosa
						{ kind: :serie, serie: element.eval { |e| { kind: :value, value: e } } }
					else
						# Aquí habría que retornar kind: :neuma o :value según si el element es un neuma o cualquier otra cosa
						{ kind: :value, value: element }
					end

				else
					raise ArgumentError, "Don't know how to process level #{level}"
				end
			end
		end

		private :eval_serie, :eval_parallel, :eval_assign_to, :eval_use_variable # TODO falta poner el resto de privates

		def run_operation element

			case element[:kind]
			when :value

				_value = eval_value element[:value]

				if _value.is_a?(Hash) && _value.key?(:duration)
					{ 	current_operation: :block,
						current_parameter: _value,
						continue_operation: :wait, 
						continue_parameter: _value[:duration] }
				else
					{ 	current_operation: :block,
						current_parameter: _value,
						continue_operation: :now }
				end

			when :neuma

				_value = eval_neuma element[:neuma], true

				{ 	current_operation: :block,
					current_parameter: _value,
					continue_operation: :wait, 
					continue_parameter: _value[:duration] }

			when :serie

				{ 	current_operation: :play, 
					current_parameter: eval_serie(element[:serie]) }

			when :parallel

				{ 	current_operation: :parallel_play, 
					current_parameter: eval_parallel(element[:parallel]) }

			when :assign_to

				eval_assign_to element[:assign_to], element[:assign_value], false

				{  	current_operation: :none, 
					continue_operation: :now }

			when :use_variable

				run_operation @nl_context.instance_variable_get(element[:use_variable])

			when :event

				value_parameters = key_parameters = nil

				value_parameters = element[:value_parameters].collect { |e| subcontext.eval_element(e) } if element[:value_parameters]
				key_parameters = element[:key_parameters].collect { |k, e| [ k, subcontext.eval_element(e) ] }.to_h if element[:key_parameters]

				{ 	current_operation: :event,
					current_event: element[:event],
					current_value_parameters: value_parameters,
					current_key_parameters: key_parameters,
					continue_operation: :now }

			when :command

				to_operation eval_command(element[:command], element[:value_parameters], element[:key_parameters])

			when :call_methods

				to_operation eval_call_methods(element[:on], element[:call_methods])

			when :eval

				run_operation eval_eval(element[:eval], element[:level])

			when :reference

				run_operation eval_reference(element[:reference], element[:level])

			else
				raise ArgumentError, "Don't know how to process #{element}"
			end			
		end

		def to_operation value

			if value
				if value.is_a? Musa::Serie 
					# If value is a Serie, it's a "native" serie, not a tokens serie of kind: :neuma. 
					# For this reason it needs to be converted to something interpretable by _play (i.e., kind: :value, similar to interpreted :neuma)

					{ current_operation: :play, current_parameter: value }

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

		private :to_operation

		def inspect
			"NeumalangModePlayEval #{id} #{@decoder}"
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

	private_constant :NeumalangModePlayEval

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