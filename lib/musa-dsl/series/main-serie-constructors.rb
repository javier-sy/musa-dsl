require_relative '../core-ext/arrayfy'
require_relative '../core-ext/smart-proc-binder'

require_relative 'base-series'

module Musa
  # Series constructor methods for creating series from various sources.
  #
  # Provides factory methods for common serie types:
  #
  # ## Basic Constructors
  #
  # - **UNDEFINED** - Undefined serie (unresolved state)
  # - **NIL** - Serie that always returns nil
  # - **S** - Serie from array of values
  # - **E** - Serie from evaluation block
  #
  # ## Collection Constructors
  #
  # - **H/HC** - Hash of series (hash/combined mode)
  # - **A/AC** - Array of series (array/combined mode)
  # - **MERGE** - Sequential merge of multiple series
  #
  # ## Numeric Generators
  #
  # - **FOR** - For-loop style numeric sequence
  # - **RND** - Random values (from array or range)
  # - **RND1** - Single random value
  # - **SIN** - Sine wave function
  # - **FIBO** - Fibonacci sequence
  #
  # ## Musical Generators
  #
  # - **HARMO** - Harmonic note series
  #
  # ## Usage Patterns
  #
  # ### Array Serie
  #
  # ```ruby
  # notes = S(60, 64, 67, 72)
  # notes.i.next_value  # => 60
  # ```
  #
  # ### Evaluation Block
  #
  # ```ruby
  # counter = E(1) { |v, last_value:| last_value + 1 unless last_value == 10 }
  # counter.i.to_a  # => [1, 2, 3, ..., 10]
  # ```
  #
  # ### Random Values
  #
  # ```ruby
  # dice = RND(1, 2, 3, 4, 5, 6)
  # dice.i.next_value  # => random 1-6
  # ```
  #
  # ### Numeric Sequences
  #
  # ```ruby
  # sequence = FOR(from: 0, to: 10, step: 2)
  # sequence.i.to_a  # => [0, 2, 4, 6, 8, 10]
  # ```
  #
  # ### Combining Series
  #
  # ```ruby
  # melody = MERGE(S(60, 64), S(67, 72))
  # melody.i.to_a  # => [60, 64, 67, 72]
  # ```
  #
  # @see Musa::Series::Operations Serie transformation operations
  #
  # @api public
  module Series::Constructors
    using Musa::Extension::ExplodeRanges

    # Creates undefined serie.
    #
    # Returns serie in undefined state. Useful as placeholder that will
    # be resolved later (e.g., in PROXY).
    #
    # @return [UndefinedSerie] serie in undefined state
    #
    # @example Undefined placeholder
    #   proxy = PROXY()  # Uses UNDEFINED internally
    #   proxy.undefined?  # => true
    #
    # @api public
    def UNDEFINED
      UndefinedSerie.new
    end

    # Creates serie that always returns nil.
    #
    # Returns nil on every next_value call. Useful for padding or as
    # placeholder in composite structures.
    #
    # @return [NilSerie] serie returning nil
    #
    # @example Nil serie
    #   s = NIL().i
    #   s.next_value  # => nil
    #   s.next_value  # => nil
    #
    # @api public
    def NIL
      NilSerie.new
    end

    # Creates serie from array of values.
    #
    # Most common constructor. Values can include ranges which will be
    # expanded automatically via ExplodeRanges extension.
    #
    # @param values [Array] values to iterate (supports ranges)
    #
    # @return [FromArray] serie from array
    #
    # @example Basic array
    #   notes = S(60, 64, 67, 72)
    #   notes.i.to_a  # => [60, 64, 67, 72]
    #
    # @example With ranges
    #   scale = S(60..67)
    #   scale.i.to_a  # => [60, 61, 62, 63, 64, 65, 66, 67]
    #
    # @api public
    def S(*values)
      FromArray.new values.explode_ranges
    end

    # Creates hash-mode serie from hash of series.
    #
    # Combines multiple series into hash-structured values. Returns hash
    # with same keys, values from respective series. Stops when first
    # serie exhausts.
    #
    # @param series_hash [Hash] hash of series (key => serie)
    #
    # @return [FromHashOfSeries] combined hash serie
    #
    # @example Hash of series
    #   h = H(pitch: S(60, 64, 67), velocity: S(96, 80, 64))
    #   h.i.next_value  # => {pitch: 60, velocity: 96}
    #   h.i.next_value  # => {pitch: 64, velocity: 80}
    #
    # @api public
    def H(**series_hash)
      FromHashOfSeries.new series_hash, false
    end

    # Creates hash-mode combined serie from hash of series.
    #
    # Like H but cycles all series. When a serie exhausts, it restarts from
    # the beginning, continuing until all series complete their cycles.
    #
    # @param series_hash [Hash] hash of series (key => serie)
    #
    # @return [FromHashOfSeries] combined hash serie that cycles all series
    #
    # @example Combined cycling all series
    #   hc = HC(a: S(1, 2), b: S(10, 20, 30))
    #   hc.max_size(6).i.to_a  # => [{a:1, b:10}, {a:2, b:20}, {a:1, b:30},
    #                           #     {a:2, b:10}, {a:1, b:20}, {a:2, b:30}]
    #
    # @api public
    def HC(**series_hash)
      FromHashOfSeries.new series_hash, true
    end

    # Creates array-mode serie from array of series.
    #
    # Combines multiple series into array-structured values. Returns array
    # of values from respective series. Stops when first serie exhausts.
    #
    # @param series [Array] array of series
    #
    # @return [FromArrayOfSeries] combined array serie
    #
    # @example Array of series
    #   a = A(S(1, 2, 3), S(10, 20, 30))
    #   a.i.next_value  # => [1, 10]
    #   a.i.next_value  # => [2, 20]
    #
    # @api public
    def A(*series)
      FromArrayOfSeries.new series, false
    end

    # Creates array-mode combined serie from array of series.
    #
    # Like A but cycles all series. When a serie exhausts, it restarts from
    # the beginning, continuing until all series complete their cycles.
    #
    # @param series [Array] array of series
    #
    # @return [FromArrayOfSeries] combined array serie that cycles all series
    #
    # @example Combined cycling all series
    #   ac = AC(S(1, 2), S(10, 20, 30))
    #   ac.max_size(6).i.to_a  # => [[1, 10], [2, 20], [1, 30],
    #                           #     [2, 10], [1, 20], [2, 30]]
    #
    # @api public
    def AC(*series)
      FromArrayOfSeries.new series, true
    end

    # Creates serie from evaluation block.
    #
    # Calls block repeatedly with parameters and last_value. Block returns
    # next value or nil to stop. Enables stateful generators and algorithms.
    #
    # ## Block Parameters
    #
    # - **value_args**: Initial positional parameters
    # - **last_value**: Previous return value (nil on first call)
    # - **caller**: Serie instance (access to parameters attribute)
    # - **key_args**: Initial keyword parameters
    #
    # @param value_args [Array] initial positional parameters
    # @param key_args [Hash] initial keyword parameters
    # @yield block called for each value
    # @yieldparam value_args [Array] current positional parameters
    # @yieldparam last_value [Object, nil] previous return value
    # @yieldparam caller [FromEvalBlockWithParameters] serie instance
    # @yieldparam key_args [Hash] current keyword parameters
    # @yieldreturn [Object, nil] next value or nil to stop
    #
    # @return [FromEvalBlockWithParameters] evaluation-based serie
    #
    # @example Counter
    #   counter = E(1) { |v, last_value:| last_value + 1 unless last_value == 5 }
    #   counter.i.to_a  # => [1, 2, 3, 4, 5]
    #
    # @example Fibonacci
    #   fib = E { |last_value:, caller:|
    #     a, b = caller.parameters
    #     caller.parameters = [b, a + b]
    #     a
    #   }
    #   fib.parameters = [0, 1]
    #   fib.i.to_a(limit: 10)  # => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
    #
    # @api public
    def E(*value_args, **key_args, &block)
      FromEvalBlockWithParameters.new *value_args, **key_args, &block
    end

    # Creates for-loop style numeric sequence.
    #
    # Generates sequence from `from` to `to` (inclusive) with `step` increment.
    # Automatically adjusts step sign based on from/to relationship.
    #
    # @param from [Numeric, nil] starting value (default: 0)
    # @param to [Numeric, nil] ending value (nil for infinite)
    # @param step [Numeric, nil] increment (default: 1, sign auto-adjusted)
    #
    # @return [ForLoop] numeric sequence serie
    #
    # @example Ascending sequence
    #   s = FOR(from: 0, to: 10, step: 2)
    #   s.i.to_a  # => [0, 2, 4, 6, 8, 10]
    #
    # @example Descending sequence
    #   s = FOR(from: 10, to: 0, step: 2)
    #   s.i.to_a  # => [10, 8, 6, 4, 2, 0]
    #
    # @example Infinite sequence
    #   s = FOR(from: 0, step: 1)  # to: nil
    #   s.infinite?  # => true
    #
    # @api public
    def FOR(from: nil, to: nil, step: nil)
      from ||= 0
      step ||= 1
      ForLoop.new from, to, step
    end

    # Creates random value serie from array or range.
    #
    # Two modes:
    # - **Array mode**: Random values from provided array
    # - **Range mode**: Random numbers from range (from, to, step)
    #
    # Infinite serie - never exhausts.
    #
    # @param _values [Array] values to choose from (positional)
    # @param values [Array, nil] values to choose from (named)
    # @param from [Numeric, nil] range start (range mode)
    # @param to [Numeric, nil] range end (range mode, required)
    # @param step [Numeric, nil] range step (default: 1)
    # @param random [Random, Integer, nil] Random instance or seed
    #
    # @return [RandomValuesFromArray, RandomNumbersFromRange] random serie
    #
    # @raise [ArgumentError] if using both positional and named values
    # @raise [ArgumentError] if mixing array and range parameters
    #
    # @example Random from array
    #   dice = RND(1, 2, 3, 4, 5, 6)
    #   dice.i.next_value  # => random 1-6
    #
    # @example Random from range
    #   rand = RND(from: 0, to: 100, step: 10)
    #   rand.i.next_value  # => random 0, 10, 20, ..., 100
    #
    # @example With seed
    #   rnd = RND(1, 2, 3, random: 42)  # Reproducible
    #
    # @api public
    def RND(*_values, values: nil, from: nil, to: nil, step: nil, random: nil)
      raise ArgumentError, "Can't use both direct values #{_values} and values named parameter #{values} at the same time." if values && !_values.empty?

      random = Random.new random if random.is_a?(Integer)
      random ||= Random.new

      values ||= _values

      if !values.empty? && from.nil? && to.nil? && step.nil?
        RandomValuesFromArray.new values.explode_ranges, random
      elsif values.empty? && !to.nil?
        from ||= 0
        step ||= 1
        RandomNumbersFromRange.new from, to, step, random
      else
        raise ArgumentError, 'cannot use values and from:/to:/step: together'
      end
    end

    # Merges multiple series sequentially.
    #
    # Plays series in sequence: first serie until exhausted, then second,
    # etc. Restarts each serie (except first) before playing.
    #
    # @param series [Array<Serie>] series to merge sequentially
    #
    # @return [Sequence] sequential merge serie
    #
    # @example Merge sequences
    #   merged = MERGE(S(1, 2, 3), S(10, 20, 30))
    #   merged.i.to_a  # => [1, 2, 3, 10, 20, 30]
    #
    # @example Melodic phrases
    #   phrase1 = S(60, 64, 67)
    #   phrase2 = S(72, 69, 65)
    #   melody = MERGE(phrase1, phrase2)
    #
    # @api public
    def MERGE(*series)
      Sequence.new(series)
    end

    # Creates single random value serie from array or range.
    #
    # Like RND but returns only one random value then exhausts.
    # Two modes: array mode and range mode.
    #
    # @param _values [Array] values to choose from (positional)
    # @param values [Array, nil] values to choose from (named)
    # @param from [Numeric, nil] range start (range mode)
    # @param to [Numeric, nil] range end (range mode, required)
    # @param step [Numeric, nil] range step (default: 1)
    # @param random [Random, Integer, nil] Random instance or seed
    #
    # @return [RandomValueFromArray, RandomNumberFromRange] single random value serie
    #
    # @raise [ArgumentError] if using both positional and named values
    # @raise [ArgumentError] if mixing array and range parameters
    #
    # @example Single random value
    #   rnd = RND1(1, 2, 3, 4, 5)
    #   rnd.i.next_value  # => random 1-5
    #   rnd.i.next_value  # => nil (exhausted)
    #
    # @example Random seed selection
    #   seed = RND1(10, 20, 30, random: 42)
    #
    # @api public
    def RND1(*_values, values: nil, from: nil, to: nil, step: nil, random: nil)
      raise ArgumentError, "Can't use both direct values #{_values} and values named parameter #{values} at the same time." if values && !_values.empty?

      random = Random.new random if random.is_a?(Integer)
      random ||= Random.new

      values ||= _values

      if !values.empty? && from.nil? && to.nil? && step.nil?
        RandomValueFromArray.new values.explode_ranges, random
      elsif values.empty? && !to.nil?
        from ||= 0
        step ||= 1
        RandomNumberFromRange.new from, to, step, random
      else
        raise ArgumentError, 'cannot use values and from:/to:/step: parameters together'
      end
    end

    # Creates sine wave function serie.
    #
    # Generates values following sine curve. Useful for smooth oscillations,
    # LFO-style modulation, and periodic variations.
    #
    # ## Wave Parameters
    #
    # - **start_value**: Initial value (default: center)
    # - **steps**: Period in steps (nil for continuous)
    # - **amplitude**: Wave amplitude (default: 1.0)
    # - **center**: Center/offset value (default: 0.0)
    #
    # Wave equation: `center + amplitude * sin(progress)`
    #
    # @param start_value [Numeric, nil] initial value
    # @param steps [Numeric, nil] full period in steps
    # @param amplitude [Numeric, nil] wave amplitude (default: 1.0)
    # @param center [Numeric, nil] center offset (default: 0.0)
    #
    # @return [SinFunction] sine wave serie
    #
    # @example Basic sine wave
    #   wave = SIN(steps: 8, amplitude: 10, center: 50)
    #   wave.i.to_a  # => oscillates around 50 ± 10
    #
    # @example LFO modulation
    #   lfo = SIN(steps: 16, amplitude: 0.5, center: 0.5)
    #   # Use for amplitude modulation
    #
    # @api public
    def SIN(start_value: nil, steps: nil, amplitude: nil, center: nil)
      amplitude ||= 1.0
      center ||= 0.0
      start_value ||= center
      SinFunction.new start_value, steps, amplitude, center
    end

    # Creates Fibonacci sequence serie.
    #
    # Generates classic Fibonacci sequence: 0, 1, 1, 2, 3, 5, 8, 13, 21, ...
    # Infinite serie.
    #
    # @return [Fibonacci] Fibonacci sequence serie
    #
    # @example Fibonacci numbers
    #   fib = FIBO()
    #   fib.infinite?  # => true
    #   inst = fib.i
    #   10.times.map { inst.next_value }
    #   # => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
    #
    # @example Rhythmic proportions
    #   durations = FIBO().i.map { |n| Rational(n, 16) }
    #
    # @api public
    def FIBO()
      Fibonacci.new
    end

    # Creates harmonic notes serie from fundamental.
    #
    # Generates MIDI note numbers for harmonic series based on listened
    # fundamental. Approximates harmonics to nearest semitone within error
    # tolerance.
    #
    # ## Parameters
    #
    # - **error**: Maximum cents deviation to accept harmonic (default: 0.5)
    # - **extended**: Include extended harmonics beyond audible range
    #
    # @param error [Numeric, nil] maximum deviation in semitones (default: 0.5)
    # @param extended [Boolean, nil] include extended harmonics (default: false)
    #
    # @return [HarmonicNotes] harmonic series serie
    #
    # @example Harmonic series
    #   # Listen to fundamental, serie returns harmonic notes
    #   harmonics = HARMO(error: 0.5)
    #   harmonics.i  # Waits for fundamental input
    #
    # @example Extended harmonics
    #   harm = HARMO(error: 0.3, extended: true)
    #
    # @api public
    def HARMO(error: nil, extended: nil)
      error ||= 0.5
      extended ||= false
      HarmonicNotes.new error, extended
    end

    ###
    ### Implementation
    ###

    class UndefinedSerie
      include Series::Serie::Base

      def initialize
        mark_as_undefined!
      end
    end

    # UndefinedSerie is not private because is used in Composer
    # private_constant :UndefinedSerie

    class NilSerie
      include Series::Serie::Base

      def initialize
        mark_as_prototype!
      end

      def _next_value; nil; end
    end

    private_constant :NilSerie

    # Serie constructor that creates a serie from an array of values.
    #
    # Iterates through array elements, returning nil when exhausted.
    # Supports optional module extensions for enhanced functionality.
    #
    # @example Basic array serie
    #   serie = FromArray.new([1, 2, 3, 4, 5])
    #   serie.next_value  # => 1
    #   serie.next_value  # => 2
    #
    # @example With extensions
    #   serie = FromArray.new([60, 62, 64], [SomeExtension])
    #
    # @api private
    class FromArray
      include Series::Serie::Base

      using Musa::Extension::Arrayfy

      def initialize(values = nil, extends = nil)
        @values = values
        mark_as_prototype!

        x = self
        extends.arrayfy.each do |e|
          x.extend(e)
        end

        init
      end

      attr_accessor :values

      private def _init
        @index = 0
      end

      private def _next_value
        if @values && @index < @values.size
          value = @values[@index]
          @index += 1
        else
          value = nil
        end

        value
      end
    end

    # private_constant :FromArray

    class Sequence
      include Series::Serie::Base
      include Series::Serie::WithSources

      def initialize(series)
        self.sources = series
        init
      end

      attr_reader :sources

      private def _init
        @index = 0
        @restart_sources = false
      end

      private def _restart
        @sources[0].restart
        @restart_sources = true
      end

      private def _next_value
        value = nil

        if @index < @sources.size
          value = @sources[@index].next_value

          if value.nil?
            @index += 1
            if @index < @sources.size
              @sources[@index].restart if @restart_sources
              value = next_value
            end
          end
        end

        value
      end

      def infinite?
        !!@sources.find(&:infinite?)
      end
    end

    private_constant :Sequence

    class FromEvalBlockWithParameters
      include Series::Serie::Base
      include Series::Serie::WithSmartBlock

      using Extension::DeepCopy

      def initialize(*parameters, **key_parameters, &block)
        raise ArgumentError, 'Yield block is undefined' unless block

        @original_value_parameters = parameters
        @original_key_parameters = key_parameters

        self.proc = block

        mark_as_prototype!

        init
      end

      def parameters
        @original_value_parameters
      end

      def parameters=(values)
        @original_value_parameters = values
      end

      def key_parameters
        @original_key_parameters
      end

      def key_parameters=(key_values)
        @original_key_parameters = key_values
      end

      private def _init
        @value_parameters = @original_value_parameters.clone(deep: true)
        @key_parameters = @original_key_parameters.clone(deep: true)

        @first = true
        @value = nil
      end

      private def _next_value
        @value = if !@value.nil? || @value.nil? && @first
                   @value = @block.call(*@value_parameters, last_value: @value, caller: self, **@key_parameters)
                 else
                   nil
                 end

        @first = false
        @value
      end
    end

    private_constant :FromEvalBlockWithParameters

    class ForLoop
      include Series::Serie::Base

      def initialize(from, to, step)
        @from = from
        @to = to
        @step = step

        sign_adjust_step

        mark_as_prototype!

        init
      end

      attr_reader :from, :to, :step

      def from=(value)
        @from = value
        sign_adjust_step
      end

      def to=(value)
        @to = value
        sign_adjust_step
      end

      def step=(value)
        @step = value
        sign_adjust_step
      end

      private def _init
        @value = @from - @step
      end

      private def _next_value
        if @value
          @value += @step
          value = @value
        end

        @value = nil if @to && @value && (@value >= @to && @step.positive? || @value <= @to && @step.negative?)

        value
      end

      def infinite?
        @to.nil?
      end

      private def sign_adjust_step
        @step = (-@step if @to && (@from < @to && @step < 0 || @from > @to && @step > 0)) || @step
      end
    end

    private_constant :ForLoop

    class RandomValueFromArray
      include Series::Serie::Base

      def initialize(values, random)
        @values = values
        @random = random

        mark_as_prototype!

        init
      end

      attr_accessor :values, :random

      private def _init
        @value = nil
      end

      private def _next_value
        if @value
          nil
        else
          @value = @values[@random.rand(0...@values.size)]
        end
      end
    end

    private_constant :RandomValueFromArray

    class RandomNumberFromRange
      include Series::Serie::Base

      def initialize(from, to, step, random)
        @from = from
        @to = to
        @step = step

        adjust_step

        @random = random

        mark_as_prototype!

        init
      end

      attr_reader :from

      def from=(value)
        @from = value
        sign_adjust_step
      end

      attr_reader :to

      def to=(value)
        @to = value
        sign_adjust_step
      end

      attr_reader :step

      def step=(value)
        @step = value
        sign_adjust_step
      end

      attr_accessor :random

      private def _init
        @value = nil
      end

      private def _next_value
        if @value
          nil
        else
          @value = @from + @random.rand(0..@step_count) * @step
        end
      end

      private def adjust_step
        @step = (-@step if @from < @to && @step < 0 || @from > @to && @step > 0) || @step
        @step_count = ((@to - @from) / @step).to_i
      end
    end

    private_constant :RandomNumberFromRange

    class RandomValuesFromArray
      include Series::Serie::Base

      def initialize(values, random)
        @values = values.clone.freeze
        @random = random

        mark_as_prototype!

        init
      end

      attr_accessor :values
      attr_accessor :random

      private def _init
        @available_values = @values.dup
      end

      private def _next_value
        value = nil
        unless @available_values.empty?
          i = @random.rand(0...@available_values.size)
          value = @available_values[i]
          @available_values.delete_at i
        end
        value
      end
    end

    private_constant :RandomValuesFromArray

    class RandomNumbersFromRange
      include Series::Serie::Base

      def initialize(from, to, step, random)
        @from = from
        @to = to
        @step = step

        adjust_step

        @random = random

        mark_as_prototype!

        init
      end

      attr_reader :from

      def from=(value)
        @from = value
        adjust_step
      end

      attr_reader :to

      def to=(value)
        @to = value
        adjust_step
      end

      attr_reader :step

      def step=(value)
        @step = value
        adjust_step
      end

      attr_accessor :random

      private def _init
        @available_steps = (0..@step_count).to_a
      end

      private def _next_value
        value = nil
        unless @available_steps.empty?
          i = @random.rand(0...@available_steps.size)
          value = @from + @available_steps[i] * @step unless @value
          @available_steps.delete_at i
        end
        value
      end

      private def adjust_step
        @step = (-@step if @from < @to && @step < 0 || @from > @to && @step > 0) || @step
        @step_count = ((@to - @from) / @step).to_i
      end
    end

    private_constant :RandomNumbersFromRange

    class FromHashOfSeries
      include Series::Serie::Base
      include Series::Serie::WithSources

      def initialize(hash_of_series, cycle_all_series)
        self.sources = hash_of_series
        self.cycle = cycle_all_series

        init
      end

      attr_accessor :cycle

      private def _init
        @have_current = false
        @value = nil
      end

      private def _restart
        @sources.values.each(&:restart)
      end

      private def _next_value
        unless @have_current && @value.nil?
          pre_value = @sources.collect { |key, serie| [key, serie.peek_next_value] }.to_h

          nils = 0
          pre_value.each do |key, value|
            if value.nil?
              @sources[key].next_value
              nils += 1
            end
          end

          if nils.zero?
            @value = @sources.collect { |key, serie| [key, serie.next_value] }.to_h

          elsif nils < @sources.size && @cycle
            _soft_restart
            @value = next_value

          else
            @value = nil
          end

          @have_current = true
        end

        @value
      end

      private def _soft_restart
        @sources.each do |_key, serie|
          serie.restart if serie.current_value.nil?
        end
      end
    end

    private_constant :FromHashOfSeries

    class FromArrayOfSeries
      include Series::Serie::Base
      include Series::Serie::WithSources

      def initialize(series_array, cycle_all_series)
        self.sources = series_array
        self.cycle = cycle_all_series

        init
      end

      attr_accessor :cycle

      private def _init
        @have_current = false
        @value = nil
      end

      private def _restart
        @sources.each(&:restart)
      end

      private def _next_value
        unless @sources.empty? || @have_current && @value.nil?
          pre_value = @sources.collect(&:peek_next_value)

          nils = 0
          pre_value.each_index do |i|
            if pre_value[i].nil?
              @sources[i].next_value
              nils += 1
            end
          end

          if nils.zero?
            @value = @sources.collect(&:next_value)

          elsif nils < @sources.size && @cycle
            _soft_restart
            @value = next_value

          else
            @value = nil
          end

          @have_current = true
        end

        @value
      end

      private def _soft_restart
        @sources.each do |serie|
          serie.restart if serie.current_value.nil?
        end
      end
    end

    private_constant :FromArrayOfSeries

    class SinFunction
      include Series::Serie::Base

      def initialize(start, steps, amplitude, center)
        @start = start.to_f

        @steps = steps
        @amplitude = amplitude.to_f
        @center = center.to_f

        update

        mark_as_prototype!

        init
      end

      attr_reader :start

      def start=(value)
        @start = value.to_f
        update
      end

      attr_reader :steps

      def steps=(value)
        @steps = value
        update
      end

      attr_reader :amplitude

      def amplitude=(value)
        @amplitude = value
        update
      end

      attr_reader :center

      def center=(value)
        @center = value
        update
      end

      private def _init
        @position = 0
      end

      private def _next_value
        value = nil
        unless @position >= @steps
          value = Math.sin(@offset + @step_size * @position) * (@amplitude / 2.0) + @center
          @position += 1
        end
        value
      end

      private def update
        y = 2 * (@start - @center) / @amplitude
        warn "WARNING: value for offset calc #{y} is outside asin range" if y < -1 || y > 1
        y = 1.0 if y > 1.0 # por los errores de precisión infinitesimal en el cálculo de y cuando es muy próximo a 1.0
        y = -1.0 if y < -1.0

        @offset = Math.asin(y)
        @step_size = 2.0 * Math::PI / @steps
      end

      def to_s
        "offset: #{@offset.round(3)}rd amplitude: #{@amplitude.round(3)} center: #{@center.round(3)} length: #{@length} step_size: #{@step_size.round(6)}"
      end
    end

    private_constant :SinFunction

    class Fibonacci
      include Series::Serie::Base

      def initialize
        mark_as_prototype!
        init
      end

      private def _init
        @a = 0
        @b = 1
      end

      private def _next_value
        initial_b = @b
        @b = @a + @b
        @a = initial_b

        @a
      end

      def infinite?
        true
      end
    end

    private_constant :Fibonacci

    class HarmonicNotes
      include Series::Serie::Base

      def initialize(error, extended)
        @error = error
        @extended = extended

        mark_as_prototype!

        init
      end

      attr_reader :error

      def error=(value)
        @error = value
      end

      attr_reader :extended

      def extended=(value)
        @extended = value
      end

      def _init
        @harmonic = 0
      end

      def _next_value
        begin
          @harmonic += 1

          candidate_note = 12 * Math::log(@harmonic, 2)

          lo = candidate_note.floor
          hi = candidate_note.ceil

          best = (candidate_note - lo) <= (hi - candidate_note) ? lo : hi

          error = candidate_note - best

        end until error.abs <= @error

        if @extended
          { pitch: best, error: error }
        else
          best
        end
      end

      def infinite?
        true
      end
    end

    private_constant :HarmonicNotes
  end
end
