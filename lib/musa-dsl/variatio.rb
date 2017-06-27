require 'active_support/core_ext/object/deep_dup'


# TODO optimizar: multithreading, ruby no tiene multicore!!!!

# TODO permitir definir un variatio a través de llamadas a métodos y/o atributos, además de a través del block del constructor

module Musa
	class Variatio

		@@threads = 4

		def self.threads
			@@threads
		end

		def self.threads= threads
			@@threads = threads
		end

		def initialize instance_name, &block

			raise ArgumentError, "instance_name should be a symbol" unless instance_name.is_a?(Symbol)
			raise ArgumentError, "block is needed" unless block

			@instance_name = instance_name

			main_context = MainContext.new block

			@constructor = main_context._constructor
			@fieldset = main_context._fieldset
			@finalize = main_context._finalize
		end

		def on **values

			constructor_binder = Tool::KeyParametersProcedureBinder.new @constructor
			finalize_binder = Tool::KeyParametersProcedureBinder.new @finalize if @finalize

			run_fieldset = @fieldset.deep_dup

			run_fieldset.components.each do |component|
				if values.has_key? component.name
					component.options = Tool::make_array_of values[component.name]
				end
			end

			tree_A = Variatio::generate_eval_tree_A run_fieldset
			tree_B = Variatio::generate_eval_tree_B run_fieldset

			parameters_set = tree_A.calc_parameters

			parameters_set_slices = []
			slice_size = parameters_set.size / @@threads
			slice_position = 0

			@@threads.times do |i|
				parameters_set_slices[i] = parameters_set.slice slice_position, slice_size
				slice_position += slice_size
			end

			threads = []

			parameters_set_slices.each do |parameters_set|

				threads << Thread.new do 

					puts "En Thread"

					combinations = []

					parameters_set.each do |parameters_with_depth|

						instance = @constructor.call constructor_binder.apply(parameters_with_depth)

						tree_B.run parameters_with_depth, { @instance_name => instance }

						if @finalize
							finalize_parameters = finalize_binder.apply parameters_with_depth
							finalize_parameters[@instance_name] = instance

							@finalize.call finalize_parameters
						end

						combinations << instance
					end

					combinations
				end
			end


			merged_combinations = []

			threads.each do |thread|
				merged_combinations += thread.value
			end

			merged_combinations
		end

		def run 
			on
		end

		private

		def self.generate_eval_tree_A fieldset
			root = nil
			current = nil

			fieldset.components.each do |component|

				if component.is_a? Field
					a = A1.new component.name, component.options
				elsif component.is_a? Fieldset
					a = A2.new component.name, component.options, generate_eval_tree_A(component)
				end

				current.inner = a if current
				root = a unless root
				
				current = a
			end

			root
		end

		class A
			attr_reader :parameter_name, :options
			attr_accessor :inner

			def initialize parameter_name, options
				@parameter_name = parameter_name
				@options = options
				@inner = nil
			end

			def calc_parameters
				if !@calc_parameters
					if inner
						@calc_parameters = Tool::list_of_hashes_product(calc_own_parameters, @inner.calc_parameters)
					else
						@calc_parameters = calc_own_parameters
					end
				end

				@calc_parameters
			end
		end

		private_constant :A

		class A1 < A
			def initialize parameter_name, options
				super parameter_name, options

				@own_parameters = @options.collect { |option| { @parameter_name => option } }
			end

			def calc_own_parameters
				@own_parameters # TODO .clone??????
			end

			def inspect
				"A1 name: #{@parameter_name}, options: #{@options}, inner: #{@inner ? @inner: 'nil'}"
			end

			alias to_s inspect 
		end

		private_constant :A1

		class A2 < A
			def initialize parameter_name, options, subcomponent
				super parameter_name, options

				@subcomponent = subcomponent



				# extraído de calc_own_parameters

				sub_parameters_set = @subcomponent.calc_parameters
				result = nil

				@options.each do |option|
					if result.nil?
						result = sub_parameters_set.collect { |v| { option => v } }
					else
						result = Tool::list_of_hashes_product result, sub_parameters_set.collect { |v| { option => v } }
					end
				end

				result = result.collect { |v| { @parameter_name => v } }

				@own_parameters = result


			end

			def calc_own_parameters
				@own_parameters # .clone????
			end

			def inspect
				"A2 name: #{@parameter_name}, options: #{@options}, subcomponent: #{@subcomponent}, inner: #{@inner ? @inner : 'nil'}"
			end

			alias to_s inspect 
		end

		private_constant :A2

		def self.generate_eval_tree_B fieldset
			affected_field_names = []
			inner = []

			fieldset.components.each do |component|
				if component.is_a? Fieldset
					inner << generate_eval_tree_B(component)
				elsif component.is_a? Field
					affected_field_names << component.name
				end
			end

			B.new fieldset.name, fieldset.options, affected_field_names, inner, fieldset.with_attributes
		end

		class B
			attr_reader :parameter_name, :options, :affected_field_names, :blocks, :inner

			def initialize parameter_name, options, affected_field_names, inner, blocks
				@parameter_name = parameter_name
				@options = options
				@affected_field_names = affected_field_names
				@inner = inner

				@procedures = blocks.collect { |proc| Tool::KeyParametersProcedureBinder.new proc }
			end

			def run parameters_with_depth, parent_parameters = nil

				parent_parameters ||= {}

				@options.each do |option|

					base = (@parameter_name == :_maincontext) ? parameters_with_depth : parameters_with_depth[@parameter_name][option]
					
					parameters = base.select { |k, v| @affected_field_names.include? k }.merge(parent_parameters)
					parameters[@parameter_name] = option

					@procedures.each do |procedure_binder|
						procedure_binder.call parameters
					end

					if @parameter_name == :_maincontext
						@inner.each do |inner|
							inner.run parameters_with_depth, parameters
						end
					else
						@inner.each do |inner|
							inner.run parameters_with_depth[@parameter_name][option], parameters
						end
					end
				end
			end

			def inspect
				 "B name: #{@parameter_name}, options: #{@options}, affected_field_names: #{@affected_field_names}, blocks_size: #{@blocks.size}, inner: #{@inner}"
			end

			alias to_s inspect 

			private

		end

		class FieldsetContext
			attr_reader :_fieldset

			def initialize name, options = nil, block
				@_fieldset = Fieldset.new name, Tool::make_array_of(options)

				self.as_context_run block
			end

			def field name, options = nil
				@_fieldset.components << Field.new(name, Tool::make_array_of(options))
			end

			def fieldset name, options = nil, &block
				fieldset_context = FieldsetContext.new name, options, block
				@_fieldset.components << fieldset_context._fieldset
			end

			def with_attributes &block
				@_fieldset.with_attributes << block
			end
		end

		private_constant :FieldsetContext

		class MainContext < FieldsetContext
			attr_reader :_constructor, :_finalize

			def initialize block
				@_constructor = nil
				@_finalize = nil

				super :_maincontext, [nil], block
			end

			def constructor &block
				@_constructor = block
			end

			def finalize &block
				@_finalize = block
			end
		end

		private_constant :MainContext

		class Field
			attr_reader :name
			attr_accessor :options

			def inspect
				"Field #{@name} options: #{@options}"
			end

			alias to_s inspect

			private

			def initialize name, options
				@name = name
				@options = options
			end
		end

		private_constant :Field

		class Fieldset
			attr_reader :name, :with_attributes, :components
			attr_accessor :options

			def inspect
				"Fieldset #{@name} options: #{@options} components: #{@components}"
			end

			alias to_s inspect

			private

			def initialize name, options
				@name = name
				@options = options || [nil]
				@components = []
				@with_attributes = []
			end
		end

		private_constant :Fieldset
	end
end