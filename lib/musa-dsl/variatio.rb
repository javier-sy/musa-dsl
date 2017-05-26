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

			puts "tree = #{generate_eval_tree @fieldset, @constructor, @finalize}"

			[]
		end

		private

		def generate_eval_tree fieldset, constructor, finalize

			root = nil
			current = nil

			fieldset.options.each do |option|

				fieldset.components.each do |component|

					if component.is_a? Field
						a = A.new component.name, option, component.options
					elsif component.is_a? Fieldset
						a = generate_eval_tree component, constructor, finalize
					end

					current.inner = a if current
					root = a unless root
					current = a
				end
			end
					
			root
		end

		class A
			attr_accessor :inner

			def initialize parameter_name, parameter_depth, options
				@parameter_name = parameter_name
				@parameter_depth = parameter_depth
				@options = options
			end

			def inspect
				"name: #{@parameter_name} depth: #{@parameter_depth} options: #{@options} inner = (#{@inner})"
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

				super nil, nil, &block
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