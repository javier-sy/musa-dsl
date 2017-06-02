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

			combinations = []

			external_parameters_with_depth = values.collect { |k, v| [k, { nil => v }] }.compact.to_h

			tree_A.run(external_parameters_with_depth) do |parameters_with_depth|

				instance = @constructor.call **Tool::make_hash_key_parameters(@constructor, **parameters_with_depth).transform_values { |v| v[nil] }

				tree_B.run parameters_with_depth, @instance_name, instance

				if @finalize
					parameters = parameters_with_depth.transform_values { |v| v[nil] }
					parameters[@instance_name] = instance

					@finalize.call **Tool::make_hash_key_parameters(@finalize, **parameters)
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

			fieldset.options.each do |option|
				a = generate_eval_tree_A_from_fields option, fieldset.components

				current.inner = a if current
				root = a unless root
				
				current = a.last_inner
			end
					
			root
		end

		def self.generate_eval_tree_A_from_fields option, fields
			root = nil
			current = nil

			fields.each do |component|
				if component.is_a? Field
					a = A.new component.name, option, component.options
				elsif component.is_a? Fieldset
					a = generate_eval_tree_A component
				end

				current.inner = a if current
				root = a unless root
				
				current = a.last_inner
			end

			root
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

			def run parameters = nil, &block
				parameters ||= {}
				parameters = parameters.clone

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

		def self.generate_eval_tree_B fieldset, affected_fields = nil
			affected_fields = []
			inner = []

			fieldset.components.each do |component|
				if component.is_a? Fieldset
					inner << generate_eval_tree_B(component, affected_fields)
				elsif component.is_a? Field
					affected_fields << component
				end
			end

			B.new fieldset.name, fieldset.options, affected_fields, inner, fieldset.with_attributes
		end

		class B
			attr_reader :parameter_name, :options, :affected_fields, :blocks, :inner

			def initialize parameter_name, options, affected_fields, inner, blocks
				@parameter_name = parameter_name
				@options = options
				@affected_fields = affected_fields
				@inner = inner
				@blocks = blocks
			end

			def run parameters_with_depth, instance_name, instance, parent_parameters = {}
				parameters_with_depth = parameters_with_depth.deep_clone
				parent_parameters = parent_parameters.clone

				@options.each do |value|

					#puts
					#puts "parameter_depths: #{parameter_depths}"
					#puts "parameters_with_depth: #{parameters_with_depth.select { |k, v| k != :object } }"

#=begin


					parameter_indexes = {}

					@affected_fields.each do |field|
						parameter_indexes[field.name] = value
					end

					@blocks.each do |block|

						# TODO 1o indexar los parameter_with_depth, después seleccionar los que van al block según sus parámetros

						real_parameters = make_parameters(block, parameters_with_depth, parameter_indexes)
						
						real_parameters[instance_name] = instance

						parent_parameters.each do |k, v|
							real_parameters[k] = v
						end

						parent_parameters[@parameter_name] = real_parameters[@parameter_name] = value unless @parameter_name == :_maincontext

						puts "real_parameters: #{real_parameters.select { |k, v| k != :object } }"

						block.call **real_parameters
					end


					@inner.each do |inner|
						inner.run parameters_with_depth, instance_name, instance, parent_parameters
					end
#=end
				end

			end

			def inspect
				"name: #{@parameter_name} options: #{@options} blocks.size: #{@blocks.size} inner: (#{@inner})"
			end

			alias to_s inspect 

			private

			def make_parameters(proc, parameters_with_depth, parameter_indexes)

				parameters = proc.parameters.collect do |parameter| 
					parameter_type = parameter[0]
					parameter_name = parameter[1]

					if parameter_type == :key || parameter_type == :keyreq
						if parameter_indexes.has_key? parameter_name
							result = [ parameter_name, parameters_with_depth[parameter_name][parameter_indexes[parameter_name]] ]
						else
							result = [ parameter_name, parameter_indexes[parameter_name] ]
						end
					end

					result
				end

				parameters =  parameters.compact.to_h

				if proc.parameters.find { |parameter| parameter[0] == :keyrest }

					parameters_with_depth.each do |k, v|

						if parameters[k].nil?
							parameters[k] = v[parameter_indexes[k]]
						end
					end
				end

				parameters
			end
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