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

			puts "Variatio.on: tree_A ="
			pp eval(tree_A.inspect)
			puts
			puts "Variatio.on: tree_B ="
			pp eval(tree_B.inspect)
			puts

			combinations = []

			parameters_set = tree_A.calc_parameters

			parameters_set.each do |parameters_with_depth|

				parameters_with_depth.merge! values

				puts "Variatio.on: parameters_with_depth = #{parameters_with_depth}"
				puts "Variatio.on: Tool::make_hash_key_parameters(@constructor, **parameters_with_depth) = #{Tool::make_hash_key_parameters(@constructor, **parameters_with_depth)}"

				instance = @constructor.call **Tool::make_hash_key_parameters(@constructor, **parameters_with_depth)

				tree_B.run parameters_with_depth, { @instance_name => instance }

				if @finalize
					@finalize.call **Tool::make_hash_key_parameters(@finalize, **parameters_with_depth, @instance_name => instance)
				end

				combinations << instance

				#return combinations if combinations.size > 0
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
			attr_reader :parameter_name
			attr_accessor :inner

			def initialize parameter_name
				@parameter_name = parameter_name
				@inner = nil
			end

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
			attr_reader :options

			def initialize parameter_name, options
				super parameter_name
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
				"{ type: :A1, name: :#{@parameter_name}, options: #{@options}, inner: #{@inner ? @inner: 'nil'} }"
			end

			alias to_s inspect 
		end

		private_constant :A1

		class A2 < A
			def initialize parameter_name, option, subcomponents
				super parameter_name

				@option = option
				@subcomponents = subcomponents
			end

			def calc_parameters
				puts
				puts "A2.calc_parameters: self = #{self}"

				if inner
					result_parameters_set = []
					inner_parameters_set = @inner.calc_parameters

					@subcomponents.calc_parameters.collect { |parameters| { @option => parameters } }.each do |parameters|

						inner_parameters_set.each do |inner_parameters|

							puts "A2.calc_parameters (with inner): inner_parameters = #{inner_parameters}"
							puts "A2.calc_parameters (with inner): @parameter_name = #{@parameter_name}"
							puts "A2.calc_parameters (with inner): inner_parameters[@parameter_name] = #{inner_parameters[@parameter_name]}"

							result_parameters_set << { @parameter_name => parameters.merge(inner_parameters[@parameter_name]) }
						end
					end
				else
					puts "A2.calc_parameters (without inner): "
					result_parameters_set = @subcomponents.calc_parameters.collect { |parameters| { @parameter_name => { @option => parameters } } } 
				end

				result_parameters_set
			end

			def inspect
				"{ type: :A2, name: :#{@parameter_name}, option: #{@option}, subcomponents: #{@subcomponents}, inner: #{@inner ? @inner : 'nil'} }"
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
				@blocks = blocks
			end

			def run parameters_with_depth, parent_parameters = nil

				parent_parameters ||= {}

				puts
				puts "B = #{self}"
				puts "B.run: parameters_with_depth = #{parameters_with_depth}"

				@options.each do |option|

					base = (@parameter_name == :_maincontext) ? parameters_with_depth : parameters_with_depth[@parameter_name][option]
					
					puts "B.run: base = #{base}"

					parameters = base.select { |k, v| @affected_field_names.include? k }.merge(parent_parameters)
					parameters[@parameter_name] = option

					puts "B.run: parameters = #{parameters}"

					@blocks.each do |block|

						effective_parameters = Tool::make_hash_key_parameters(block, **parameters)

						puts "B.run: effective_parameters = #{effective_parameters}"

						block.call **effective_parameters
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
				"{ type: :B, name: :#{@parameter_name}, options: #{@options}, affected_field_names: #{@affected_field_names}, blocks_size: #{@blocks.size}, inner: #{@inner} }"
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