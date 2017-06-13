module Musa
	class Darwin

		def initialize &block
			
			raise ArgumentError, "block is needed" unless block

			main_context = MainContext.new &block

			@measures = main_context._measures
			@weights = main_context._weights
		end

		def select population
			
			measured_objects = []

			population.each do |object|
				context = MeasuresEvalContext.new 
				context.instance_exec_nice object, &measures
				measure = context._measure

				measured_objects << { object: object, measure: context._measure } unless measure.died?
			end

			limits = {}

			measured_objects.each do |measured_object|

				measure = measured_object[:measure]
				
				measure.dimensions.each do |measure_name, value|
					limit = limits[measure_name] ||= { min: nil, max: nil }

					limit[:min] = value.to_f if limit[:min].nil? || limit[:min] > value
					limit[:max] = value.to_f if limit[:max].nil? || limit[:max] < value

					limit[:range] = limit[:max] - limit[:min]
				end
			end

			measured_objects.each do |measured_object|

				measure = measured_object[:measure]
				
				measure.dimensions.each do |dimension_name, value|
					limit = limits[measure_name]
					measure.normalized_dimensions[dimension_name] = ( value - limit[:min] ) / limit[:range]
				end
			end

			measured_objects.sort! { |a, b|	evaluate_weights a.measure, b.measure }

			return measured_objects
		end

		def evaluate_weights measure_a, measure_b
			measure_a.evaluate_weights(@weights) <=> measure_b.evaluate_weights(@weights)
		end

		class MainContext
			attr_reader :_measures, :_weights

			def initialize &block
				@_weights = {}
				self.instance_exec_nice &block
			end

			def measures &block
				@_measures = block
			end

			def weight **feature_or_dimension_weights
				feature_or_dimension_weights.each do |name, value|
					@_weights[name] = value
				end
			end
		end

		class MeasuresEvalContext
			def initialize
				@_features = {}
				@_dimensions = {}
				@_died = false
			end

			def _measure
				Measure.new _features, _dimensions, _died

			def feature feature_name
				@_features[feature_name] = true
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

			def evaluate_weight weights
				total = 0.0

				unless @died
					weights.each do |name, weight|
						total += @normalized_dimensions[name] * weight if @normalized_dimensions.has_key? name
						total += weight if @features[name]
					end
				end

				return total
			end
		end
	end
end
