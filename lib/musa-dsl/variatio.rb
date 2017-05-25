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
			pp @fieldset

			[]
		end

		private

		class FieldsetContext
			attr_reader :_fieldset

			def initialize name, options, &block
				@_fieldset = Fieldset.new name, options
				@_lastfield = @_fieldset

				self.instance_exec_nice &block
			end

			def field name, options
				@_lastfield = @_lastfield.component = Field.new(name, options)
			end

			def fieldset name, options, &block
				fieldset_context = FieldsetContext.new name, options, &block
				@_lastfield = @_lastfield.component = fieldset_context._fieldset
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
			attr_accessor :component

			def inspect
				"Field #{@name} options: #{@options} component: (#{@component})"
			end

			alias to_s inspect

			private

			def initialize name, options
				@name = name
				@options = options
				@component = nil
			end
		end

		private_constant :Field

		class Fieldset
			attr_reader :name, :options, :with_attributes
			attr_accessor :component

			def inspect
				"Fieldset #{@name} options: #{@options} components: (#{@component})"
			end

			alias to_s inspect

			private

			def initialize name, options
				@name = name
				@options = options || [0]
				@component = nil
				@with_attributes = []
			end
		end

		private_constant :Fieldset
	end
end