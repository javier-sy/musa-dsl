require 'pp'

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
			tree_A = generate_eval_tree_A @fieldset

			puts tree_A

			return []

			tree_B = generate_eval_tree_B @fieldset

			combinations = []

			tree_A.run(values) do |parameters|
				instance = @constructor.call **Tool::make_hash_key_parameters(@constructor, **parameters)

				tree_B.run parameters, @instance_name, instance

				if @finalize
					@finalize.call **Tool::make_hash_key_parameters(@finalize, **{ @instance_name => instance }, **parameters)
				end

				combinations << instance
			end

			combinations
		end

		private

		def generate_eval_tree_A fieldset
			root = nil
			current = nil

			fieldset.options.each do |option|

				fieldset.components.each do |component|

					if component.is_a? Field
						a = A.new component.name, option, component.options
					elsif component.is_a? Fieldset
						a = generate_eval_tree_A component
					end

					current.inner = a if current
					root = a unless root
					
					current = a.last_inner
				end
			end
					
			root
		end

		def generate_eval_tree_B fieldset
			b = B.new fieldset.name, fieldset.options, fieldset.with_attributes

			fieldset.components.each do |component|
				if component.is_a? Fieldset
					b.inner << generate_eval_tree_B(component)
				end
			end

			b
		end

		class A
			attr_reader :parameter_name, :parameter_depth, :options
			attr_accessor :inner

			def initialize parameter_name, parameter_depth, options
				@parameter_name = parameter_name
				@parameter_depth = parameter_depth
				@options = options
			end

			def last_inner
				i = self

				while i
					last = i
					i = i.inner
				end

				last
			end

			def run in_parameters = nil, &block
				in_parameters ||= {}

				parameters = in_parameters.deep_clone

				@options.each do |value|
					parameters[@parameter_name] ||= {}
					parameters[@parameter_name][@parameter_depth] = value

					if inner
						inner.run parameters, &block
					else
						block.call parameters
					end
				end

			end

			def inspect
				"name: #{@parameter_name} depth: #{@parameter_depth} options: #{@options} inner: (#{@inner})"
			end

			alias to_s inspect 
		end

		class B
			attr_reader :parameter_name, :options, :blocks, :inner

			def initialize parameter_name, options, blocks
				@parameter_name = parameter_name
				@options = options
				@blocks = blocks
				@inner = []
			end

			def run in_parameters = nil, instance_name, instance
				in_parameters ||= {}

				parameters = in_parameters.deep_clone

				@options.each do |value|
					parameters[@parameter_name] = value

					@blocks.each do |block|
						block.call **Tool::make_hash_key_parameters(block, **{ instance_name => instance }, **parameters)
					end

					@inner.each do |inner|
						inner.run parameters, instance_name, instance
					end
				end
			end

			def inspect
				"name: #{@parameter_name} options: #{@options} blocks.size: #{@blocks.size} inner: (#{@inner})"
			end

			alias to_s inspect 
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