# TODO optimiziación: cachear listas de parámetros de los blocks, para no tener que obtenerlas y esquematizarlas cada vez
# TODO optimización: multithreading
# TODO optimizar: eliminar ** si mejora rendimiento

module Musa
	class Variatio
		def initialize instance_name, parameters:, &block
			
			raise ArgumentError, "instance_name should be a symbol" unless instance_name.is_a?(Symbol)
			raise ArgumentError, "parameters should be an array of symbols" unless parameters.is_a?(Array) && !parameters.find {|p| !(p.is_a? Symbol) }
			raise ArgumentError, "block is needed" unless block

			@instance_name = instance_name
			@parameters = parameters

			main_context = MainContext.new &block

			@constructor = main_context._constructor
			@fieldset = main_context._fieldset
			@finalize = main_context._finalize
		end

		def on **values
			tree_A = Variatio::generate_eval_tree_A @fieldset
			tree_B = Variatio::generate_eval_tree_B @fieldset


			#puts "tree_B = #{tree_B}"

			parameters_set = tree_A.calc_parameters
			combinations = []

			parameters_set.each do |parameters_with_depth|

				parameters_with_depth.merge! values

				instance = @constructor.call **Tool::make_hash_key_parameters(@constructor, **parameters_with_depth)

				parameters_with_depth[@instance_name] = instance

				tree_B.run parameters_with_depth

				if @finalize
					@finalize.call **Tool::make_hash_key_parameters(@finalize, **parameters_with_depth)
				end

				combinations << instance

				return combinations if combinations.size > 0
			end

			combinations
		end

		private

		def self.generate_eval_tree_A fieldset
			root = nil
			current = nil

			fieldset.components.each do |component|

				if component.is_a? Field

					a = A1.new component.name, component.options

				elsif component.is_a? Fieldset

					first = last = nil

					component.options.each do |option|
						a = A2.new component.name, option, generate_eval_tree_A(component)

						last.inner = a if last
						first = a unless first

						last = a
					end

					a = first
				end

				current.inner = a if current
				root = a unless root
				
				current = a.last_inner
			end

			root
		end

		class A
			def last_inner
				i = self

				while i
					last = i
					i = i.inner
				end

				last
			end
		end

		private_constant :A

		class A1 < A
			attr_reader :parameter_name, :options
			attr_accessor :inner

			def initialize parameter_name, options
				@parameter_name = parameter_name
				@options = options
			end

			def calc_parameters
				if inner
					inner_parameters_set = @inner.calc_parameters
					result_parameters_set = []

					@options.collect do |option|
						inner_parameters_set.each do |inner_parameters|
							actual_parameters = inner_parameters.clone
							actual_parameters[@parameter_name] = option

							result_parameters_set << actual_parameters
						end
					end
				else
					result_parameters_set = @options.collect { |option|	{ @parameter_name => option } }
				end

				result_parameters_set
			end

			def inspect
				"A1 (name: #{@parameter_name} options: [#{@options}] inner: [#{@inner}])"
			end

			alias to_s inspect 
		end

		private_constant :A1

		class A2 < A
			attr_reader :parameter_name, :options
			attr_accessor :inner

			def initialize parameter_name, option, subcomponents
				@parameter_name = parameter_name
				@option = option
				@subcomponents = subcomponents
			end

			def calc_parameters
				if inner
					result_parameters_set = []
					inner_parameters_set = @inner.calc_parameters

					@subcomponents.calc_parameters.collect { |parameters| { @option => parameters } }.each do |parameters|

						inner_parameters_set.each do |inner_parameters|

							result_parameters_set << { @parameter_name => parameters.merge(inner_parameters) }
						end
					end
				else
					result_parameters_set = @subcomponents.calc_parameters.collect { |parameters| { @option => parameters } }
				end

				result_parameters_set
			end

			def inspect
				"A2 (name: #{@parameter_name} option: #{@option} subcomponents: [#{@subcomponents}] inner: [#{@inner}])"
			end

			alias to_s inspect 
		end

		private_constant :A2

		def self.generate_eval_tree_B fieldset, affected_fields = nil
			affected_field_names = []
			inner = []

			fieldset.components.each do |component|
				if component.is_a? Fieldset
					inner << generate_eval_tree_B(component, affected_fields)
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
				@blocks = blocks
			end

			def run parameters_with_depth
				puts "B.run: parameters_with_depth = #{parameters_with_depth}"
				puts "B = #{self}"


				parameters_with_depth.select_keys..................................



			end

			def inspect
				"B (name: #{@parameter_name} options: #{@options} affected_field_names: #{@affected_field_names} blocks.size: #{@blocks.size} inner: #{@inner})"
			end

			alias to_s inspect 

			private

		end

		class FieldsetContext
			attr_reader :_fieldset

			def initialize name, options, &block
				@_fieldset = Fieldset.new name, options

				self.instance_exec_nice &block
			end

			def field name, options
				@_fieldset.components << Field.new(name, options)
			end

			def fieldset name, options, &block
				fieldset_context = FieldsetContext.new name, options, &block
				@_fieldset.components << fieldset_context._fieldset
			end

			def with_attributes &block
				@_fieldset.with_attributes << block
			end
		end

		private_constant :FieldsetContext

		class MainContext < FieldsetContext
			attr_reader :_constructor, :_finalize

			def initialize &block
				@_constructor = nil
				@_finalize = nil

				super :_maincontext, [nil], &block
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
			attr_reader :name, :options

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
			attr_reader :name, :options, :with_attributes, :components

			def inspect
				"Fieldset #{@name} options: #{@options} components: (#{@components})"
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