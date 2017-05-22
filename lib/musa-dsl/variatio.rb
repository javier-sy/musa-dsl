module Musa
	class Variatio
		def initialize instance_name, parameters:, &block
			
			raise ArgumentError, "instance_name should be a symbol" unless instance_name.is_a? Symbol
			raise ArgumentError, "parameters should be an array of symbols" unless parameters.is_a?(Array) && !parameters.find {|p| !(p.is_a? Symbol) }
			raise ArgumentError, "block is needed" unless block

			@instance_name = instance_name
			@parameters = parameters

			main_context = MainContext.new &block

			@constructor = main_context._constructor
			@components = main_context._components
			@with_attributes = main_context._with_attributes
			@finalize = main_context._finalize
		end

		def on **values
			recurse_collect_parameters(@components).collect do |instance_attributes|

				instance = @constructor.call **Tool::make_hash_key_parameters(@constructor, **instance_attributes, **values)

				@with_attributes.each do |with_attributes|
					with_attributes.call **Tool::make_hash_key_parameters(
						with_attributes, 
						**instance_attributes, 
						**values, 
						**{ @instance_name => instance } )
				end

				if @finalize
					@finalize.call **Tool::make_hash_key_parameters(
						@finalize, 
						**instance_attributes, 
						**values, 
						**{ @instance_name => instance } )
				end

				instance
			end
		end

		private

		def recurse_collect_parameters components, parameters = nil
			components = components.clone

			first = components.shift

			result = []

			first.collect_parameters(parameters).each do |inner_parameters|

				if components.empty?
					result << inner_parameters
				else
					result.push *recurse_collect_parameters(components, inner_parameters)
				end
			end

			result
		end

		class MainContext
			attr_reader :_constructor, :_components, :_with_attributes, :_finalize

			def initialize &block
				@_constructor = nil
				@_components = []
				@_with_attributes = []
				@_finalize = nil

				self.instance_exec_nice &block
			end

			def constructor &block
				@_constructor = block
			end

			def field name, options
				@_components << Field.new(name, options)
			end

			def fieldset name, options, &block
				fieldset_context = FieldsetContext.new name, options, &block
				@_components << fieldset_context._fieldset
			end

			def with_attributes &block
				@_with_attributes << block
			end

			def finalize &block
				@_finalize = block
			end
		end

		private_constant :MainContext

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

		private :FieldsetContext

		class Field
			attr_reader :name, :options

			def collect_parameters in_parameters, parent_parameters = nil
				in_parameters ||= {}
				parent_parameters ||= {}

				result = []

				@options.each do |option|
					parameters = in_parameters.deep_clone

					parent_parameters.each { |k, v| parameters[k] = v } 
					parameters[name] = option

					result << parameters
				end

				result
			end

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
			attr_reader :name, :options, :components, :with_attributes

			def collect_parameters in_parameters, parent_parameters = nil
				in_parameters ||= {}
				parent_parameters ||= {}

				result = []

				@options.each do |option|
					parameters = in_parameters.deep_clone

					parent_parameters.each { |k, v| parameters[k] = v } 
					parameters[name] = option

					result << parameters
				end

				result
			end

			def inspect
				"Fieldset #{@name} options: #{@options}"
			end

			alias to_s inspect

			private

			def initialize name, options
				@name = name
				@options = options
				@components = []
				@with_attributes = []
			end
		end

		private_constant :Fieldset
	end
end