module Musa
	class Darwin

		def initialize &block
			
			raise ArgumentError, "block is needed" unless block

			main_context = MainContext.new &block

			@measures = main_context._measures
			@selection = main_context._selection
		end

		def select population
			
			measured_objects = population.collect do |object|
				context = MeasuresEvalContext.new 
				context.instance_exec_nice object, &measures

				{ object: object, measure: context._measure }
			end

			limits = {}

			measured_objects.each do |measured_object|

				measure = measured_object[:measure]
				
				if !measure.died?
					measure.dimensions.each do |measure_name, value|
						limits[measure_name] ||= { min: nil, max: nil }

						limits[measure_name][:min] = value.to_f if limits[measure_name][:min].nil? || limits[measure_name][:min] > value
						limits[measure_name][:max] = value.to_f if limits[measure_name][:max].nil? || limits[measure_name][:max] < value

						limits[measure_name][:range] = limits[measure_name][:max] - limits[measure_name][:min]
					end
				end
			end

			measured_objects.each do |measured_object|

				measure = measured_object[:measure]
				
				if !measure.died?
					measure.dimensions.each do |dimension_name, value|
						measure.normalized_dimension[dimension_name] = ( value - limits[measure_name][:min] ) / limits[measure_name][:range]
					end
				end
			end


			### seguir aquí

		end

		class MainContext
			attr_reader :_measures, :_selection

			def initialize &block
				self.instance_exec_nice &block
			end

			def measures &block
				@_measures = block
			end

			def selection &block
				@_selection = SelectionContext.new &block
			end

			class SelectionContext
				def initialize &block
					@_selection = Selection.new
					self.instance_exec_nice &block
				end

				def feature feature_name, better_than:, as:
					@_selection.features[as] = Feature.new as, feature_name, better_than
				end

				def dimension dimension_name, better_than:, by: 1.0, as:
					@_selection.dimensions[as] = Dimension.new as, dimension_name, better_than, by
				end

				def weight **feature_or_dimension_weights
					feature_or_dimension_weights.each do |name, value|
						@_selection.weight[name] = value
					end
				end

				def resurrect ratio = 0
					@selection.resurrections << ratio
				end
			end
		end

		class Selection
			attr_accessor :features, :dimensions, :weight, :resurrections

			def initialize
				@features = {}
				@dimensions = {}
				@weight = {}
				@resurrections = []
			end

			class Dimension
				attr_reader :name, :dimension_name, :better_than, :by

				def initialize name, dimension_name, better_than, by
					@name = name
					@dimension_name = dimension_name
					@better_than = better_than
					@by = by
				end
			end

			class Feature
				attr_reader :name, :feature_name, :better_than

				def initialize name, feature_name, better_than
					@name = name
					@dimension_name = feature_name
					@better_than = better_than
				end
			end
		end

		class MeasuresEvalContext
			def initialize
				@_features = []
				@_dimensions = {}
				@_died = false
			end

			def _measure
				Measure.new _features, _dimensions, _died

			def feature feature_name
				@_features << feature_name
			end

			def dimension dimension_name, value
				@_dimensions[dimension_name] = value
			end

			def die
				@_died = true
			end
		end

		class Measure
			attr_reader :features, :dimensions, :normalized_dimensions

			def initialize(features, dimensions, died)
				@features = features
				@dimensions = dimensions
				@died = died

				@normalized_dimensions = {}
			end

			def died?
				@died
			end
		end
	end
end
