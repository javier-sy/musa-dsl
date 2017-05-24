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
			parameters = @fieldset.calculate_combinations(**values)

			parameters.collect do |combination|

				instance = @constructor.call **Tool::make_hash_key_parameters(@constructor, **combination[:parameters])

				combination[:blocks].each do |block|
					block.call **Tool::make_hash_key_parameters(
						block, 
						**{ @instance_name => instance },
						**combination[:parameters])
				end

				process_fieldsets combination

				if @finalize
					@finalize.call **Tool::make_hash_key_parameters(
						@finalize, 
						**{ @instance_name => instance },
						**combination[:parameters])
				end

				instance
			end
		end

		private

		def process_fieldsets combination



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

			def calculate_combinations
				options.collect do |option| 
					{ name => option }
				end
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

			def calculate_combinations **parent_parameters
				if @name
					calculate_combinations_of(@components).collect do |inner_parameters|
						{ @name => 
							@options.collect do |option|
								{ parameters: { **{ @name => option }, **parent_parameters, **inner_parameters }, blocks: @with_attributes }
							end
						}
						
					end
				else
					result = []

					calculate_combinations_of(@components).each do |inner_parameters|
						@options.each do |option|
							result << { parameters: { **parent_parameters, **inner_parameters }, blocks: @with_attributes }
						end
					end

					result
				end
			end

			def inspect
				"Fieldset #{@name} options: #{@options} components: #{@components}"
			end

			alias to_s inspect

			private

			def calculate_combinations_of components, **parent_parameters

				components = components.clone

				first = components.shift

				result = []

				first.calculate_combinations.each do |inner_parameters|
					if components.empty?
						result << { **parent_parameters, **inner_parameters }
					else
						result.push *calculate_combinations_of(components, **parent_parameters, **inner_parameters)
					end
				end

				result
			end

			def initialize name, options
				@name = name
				@options = options || [0]
				@components = []
				@with_attributes = []
			end
		end

		private_constant :Fieldset
	end
end