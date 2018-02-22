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

		def eval_value element
			raise NotImplementedError
		end

		def eval_operation element
			raise NotImplementedError
		end
	end

	private_constant :PlayEval

	class AtModePlayEval < PlayEval

		def initialize block_procedure_binder
			@block_procedure_binder = block_procedure_binder
		end

		def eval_operation element
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

		def eval_operation element
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
	
		def eval_value element
			value = nil
		
			case element[:kind]
			when :serie

				value = S(*element[:serie])

			when :parallel

				value = element[:parallel].collect { |e| S(*e[:serie]) }

			when :assign_to

				_value = nil

				element[:assign_to].each do |var_name|
					@nl_context.instance_variable_set var_name, _value = element[:assign_value]
				end

				value = eval_value _value

			when :use_variable

				if @nl_context.instance_variable_defined? element[:use_variable]
					value = eval_value @nl_context.instance_variable_get(element[:use_variable])
				else
					raise NameError, "Variable #{element[:use_variable]} is not defined in #{element}"
				end

			when :command

				value = @nl_context.instance_eval &element[:command]

			when :reference_command

				value = element[:reference_command]

			when :value

				value = element[:value]

			when :neuma

				value = @decoder.decode element

			when :call_methods

				play_eval = subcontext

				_value = play_eval.eval_value element[:on]

				result = nil

				if _value.is_a? Array # Array means the origin is a parallel

					values = _value.collect do |_value|
						element[:call_methods].each do |methd|
							value_parameters = methd[:value_parameters].collect { |e| play_eval.subcontext.eval_value(e) } if methd[:value_parameters]
							key_parameters = methd[:key_parameters].collect { |k, e| [ k, play_eval.subcontext.eval_value(e) ] }.to_h if methd[:key_parameters]

							_value = _value._send_nice methd[:method], value_parameters, key_parameters
						end
						 _value
					end

					value = values

				else
					element[:call_methods].each do |methd|
						value_parameters = methd[:value_parameters].collect { |e| play_eval.subcontext.eval_value(e) } if methd[:value_parameters]
						key_parameters = methd[:key_parameters].collect { |k, e| [ k, play_eval.subcontext.eval_value(e) ] }.to_h if methd[:key_parameters]

						_value = _value._send_nice methd[:method], value_parameters, key_parameters
					end

					value = _value
				end

				result

			else
				raise ArgumentError, "Don't know how to process #{element}"
			end

			value
		end

		def eval_operation element

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

				_value = @decoder.decode element

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
					@nl_context.instance_variable_set var_name, element[:assign_value]
				end

				{  	current_operation: :none, 
					continue_operation: :now }

			when :use_variable

				eval_operation @nl_context.instance_variable_get(element[:use_variable])

			when :event

				value_parameters = key_parameters = nil

				value_parameters = element[:value_parameters].collect { |e| subcontext.eval_value(e) } if element[:value_parameters]
				key_parameters = element[:key_parameters].collect { |k, e| [ k, subcontext.eval_value(e) ] }.to_h if element[:key_parameters]

				{ 	current_operation: :event,
					current_event: element[:event],
					current_value_parameters: value_parameters,
					current_key_parameters: key_parameters,
					continue_operation: :now }

			when :command

				to_operation @nl_context.instance_eval(&element[:command])

			when :call_methods

				to_operation eval_value(element)
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