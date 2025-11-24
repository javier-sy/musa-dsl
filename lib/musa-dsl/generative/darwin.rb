require_relative '../core-ext/with'

module Musa
  # Evolutionary selection algorithm based on fitness evaluation.
  #
  # Darwin implements a selection algorithm inspired by natural selection,
  # evaluating and ranking a population of objects based on defined measures
  # (features and dimensions) and weights. Objects are measured, scored, and
  # sorted by fitness for evolutionary algorithms or optimization.
  #
  # ## Core Concepts
  #
  # - **Population**: Collection of objects to evaluate
  # - **Measures**: Evaluation criteria for each object
  #   - **Features**: Boolean flags (present/absent)
  #   - **Dimensions**: Numeric values (continuous)
  #   - **Die**: Mark object as non-viable (eliminated)
  # - **Weights**: Importance multipliers for features/dimensions
  # - **Fitness**: Calculated score from normalized dimensions and features
  # - **Selection**: Population sorted by fitness (highest first)
  #
  # ## Evaluation Process
  #
  # 1. **Measure**: Evaluate each object with measures block
  # 2. **Normalize**: Scale dimension values to 0-1 range
  # 3. **Weight**: Apply weights to dimensions and features
  # 4. **Score**: Calculate total fitness for each object
  # 5. **Sort**: Order population by fitness (descending)
  #
  # ## Musical Applications
  #
  # - Select best harmonic progressions from generated candidates
  # - Rank melodic variations by aesthetic criteria
  # - Optimize rhythmic patterns for complexity/simplicity
  # - Evolve musical structures through iterative selection
  #
  # @example Basic selection with features and dimensions
  #   darwin = Musa::Darwin::Darwin.new do
  #     measures do |object|
  #       # Kill objects with unwanted property
  #       die if object[:bad_property]
  #
  #       # Binary features
  #       feature :has_alpha if object[:type] == :alpha
  #       feature :has_beta if object[:type] == :beta
  #
  #       # Numeric dimension (negative to prefer lower values)
  #       dimension :complexity, -object[:complexity].to_f
  #     end
  #
  #     # Weight contributions to fitness
  #     weight complexity: 2.0, has_alpha: 1.0, has_beta: -0.5
  #   end
  #
  #   population = generate_candidates()
  #   selected = darwin.select(population)
  #   # Returns population sorted by fitness (best first)
  #
  # @example Musical chord progression selection
  #   darwin = Musa::Darwin::Darwin.new do
  #     measures do |progression|
  #       # Eliminate progressions with parallel fifths
  #       die if has_parallel_fifths?(progression)
  #
  #       # Prefer smooth voice leading
  #       dimension :voice_leading, -total_voice_leading_distance(progression)
  #
  #       # Prefer certain cadences
  #       feature :authentic_cadence if ends_with_V_I?(progression)
  #       feature :plagal_cadence if ends_with_IV_I?(progression)
  #
  #       # Penalize excessive chromaticism
  #       dimension :chromaticism, -count_chromatic_notes(progression)
  #     end
  #
  #     weight voice_leading: 3.0,
  #            authentic_cadence: 2.0,
  #            plagal_cadence: 1.0,
  #            chromaticism: 1.5
  #   end
  #
  #   candidates = generate_progressions()
  #   best = darwin.select(candidates).first(10)  # Top 10 progressions
  #
  # @see Darwin Main evolutionary selector class
  # @see Musa::Extension::With DSL context management for evaluation blocks
  # @see https://en.wikipedia.org/wiki/Evolutionary_algorithm Evolutionary algorithm (Wikipedia)
  # @see https://en.wikipedia.org/wiki/Fitness_function Fitness function (Wikipedia)
  module Darwin
    # Evolutionary selector for population-based optimization.
    #
    # Evaluates population using measures and weights, returning sorted
    # population by fitness score.
    class Darwin
      # Creates Darwin selector with evaluation rules.
      #
      # @yield evaluation DSL block
      # @yieldreturn [void]
      #
      # @raise [ArgumentError] if no block given
      #
      # @example
      #   darwin = Darwin.new do
      #     measures { |obj| dimension :value, obj[:score] }
      #     weight value: 1.0
      #   end
      def initialize(&block)
        raise ArgumentError, 'block is needed' unless block

        main_context = MainContext.new &block

        @measures = main_context._measures
        @weights = main_context._weights
      end

      # Selects and ranks population by fitness.
      #
      # Evaluates each object with measures, normalizes dimensions across
      # population, applies weights, and returns population sorted by fitness
      # (highest first). Objects marked as died are excluded.
      #
      # @param population [Array] objects to evaluate
      #
      # @return [Array] population sorted by fitness (descending)
      #
      # @example
      #   candidates = [obj1, obj2, obj3, ...]
      #   ranked = darwin.select(candidates)
      #   best = ranked.first      # Highest fitness
      #   worst = ranked.last      # Lowest fitness
      #   top10 = ranked.first(10) # Top 10
      def select(population)
        measured_objects = []

        population.each do |object|
          context = MeasuresEvalContext.new

          context.with object, **{}, &@measures
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

        # warn "Darwin.select: weights #{@weights}"

        measured_objects.each do |measured_object|
          measure = measured_object[:measure]

          measure.dimensions.each do |dimension_name, value|
            limit = limits[dimension_name]
            measure.normalized_dimensions[dimension_name] =
              limit[:range].zero? ? 0.5 : (value - limit[:min]) / limit[:range]
          end

          # warn "Darwin.select: #{measured_object[:object]} #{measured_object[:measure]} weight=#{measured_object[:measure].evaluate_weight(@weights).round(2)}"
        end

        measured_objects.sort! { |a, b| evaluate_weights a[:measure], b[:measure] }

        measured_objects.collect { |measured_object| measured_object[:object] }
      end

      def evaluate_weights(measure_a, measure_b)
        measure_b.evaluate_weight(@weights) <=> measure_a.evaluate_weight(@weights)
      end

      # DSL context for Darwin configuration.
      #
      # @api private
      class MainContext
        include Musa::Extension::With

        # @return [Proc] measures evaluation block
        # @return [Hash] weight assignments
        attr_reader :_measures, :_weights

        # @api private
        def initialize(&block)
          @_weights = {}
          with &block
        end

        # Defines measures evaluation block.
        #
        # @yield [object] measures DSL block
        # @api private
        def measures(&block)
          @_measures = block
        end

        # Assigns weights to features/dimensions.
        #
        # @param feature_or_dimension_weights [Hash] name => weight pairs
        # @api private
        def weight(**feature_or_dimension_weights)
          feature_or_dimension_weights.each do |name, value|
            @_weights[name] = value
          end
        end
      end

      # DSL context for object measurement.
      #
      # @api private
      class MeasuresEvalContext
        include Musa::Extension::With

        # @api private
        def initialize
          @_features = {}
          @_dimensions = {}
          @_died = false
        end

        # Returns measure result.
        #
        # @return [Measure] measurement
        # @api private
        def _measure
          Measure.new @_features, @_dimensions, @_died
        end

        # Marks object as having a feature.
        #
        # @param feature_name [Symbol] feature identifier
        # @api private
        def feature(feature_name)
          @_features[feature_name] = true
        end

        # Records dimensional measurement.
        #
        # @param dimension_name [Symbol] dimension identifier
        # @param value [Numeric] measured value
        # @api private
        def dimension(dimension_name, value)
          @_dimensions[dimension_name] = value
        end

        # Marks object as non-viable (to be excluded).
        #
        # @api private
        def die
          @_died = true
        end

        # Checks if object marked as died.
        #
        # @return [Boolean]
        # @api private
        def died?
          @_died
        end
      end

      # Measurement result for an object.
      #
      # Contains features, dimensions, and viability status.
      #
      # @attr_reader features [Hash{Symbol => Boolean}] feature flags
      # @attr_reader dimensions [Hash{Symbol => Numeric}] raw dimension values
      # @attr_reader normalized_dimensions [Hash{Symbol => Float}] normalized (0-1) dimensions
      #
      # @api private
      class Measure
        attr_reader :features, :dimensions, :normalized_dimensions

        # @api private
        def initialize(features, dimensions, died)
          @features = features
          @dimensions = dimensions
          @died = died

          @normalized_dimensions = {}
        end

        # Checks if object is non-viable.
        #
        # @return [Boolean]
        # @api private
        def died?
          @died
        end

        # Calculates weighted fitness score.
        #
        # Sums weighted normalized dimensions and features.
        #
        # @param weights [Hash{Symbol => Numeric}] weight assignments
        #
        # @return [Float] total fitness score
        #
        # @api private
        def evaluate_weight(weights)
          total = 0.0

          unless @died
            weights.each do |name, weight|
              total += @normalized_dimensions[name] * weight if @normalized_dimensions.key? name
              total += weight if @features[name]
            end
          end

          total
        end

        def inspect
          "Measure features=#{@features.collect { |k, _v| k }} dimensions=#{@normalized_dimensions.collect { |k, v| [k, [@dimensions[k].round(5), v.round(2)]] }.to_h}"
        end

        alias to_s inspect
      end
    end
  end
end
